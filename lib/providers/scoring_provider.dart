import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/models/match_score_model.dart';

class ScoringProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _matchId;
  MatchLobbyModel? _matchData;
  MatchScoreModel _scoreData = MatchScoreModel();

  // --- Getters ---
  MatchLobbyModel? get matchData => _matchData;
  MatchScoreModel get score => _scoreData;
  bool get isLoading => _matchData == null;

  bool get isCaptainA => _matchData?.captainAId == _auth.currentUser?.uid;
  bool get isCaptainB => _matchData?.captainBId == _auth.currentUser?.uid;
  bool get isHost => _matchData?.hostId == _auth.currentUser?.uid;

  // Strictly check if captains are assigned and current user is authorized
  bool get isAuthorized => isCaptainA || isCaptainB || isHost;

  // Validates if captains exist in the game data
  bool get areCaptainsPresent => (_matchData?.captainAId != null && _matchData?.captainBId != null);

  bool get canScore => isAuthorized && (_matchData?.status == 'LIVE') && areCaptainsPresent;

  void init(String matchId) {
    _matchId = matchId;
    _listenToMatch();
  }

  void _listenToMatch() {
    if (_matchId == null) return;

    _db.collection('matches').doc(_matchId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _matchData = MatchLobbyModel.fromMap(data);

        if (data.containsKey('score')) {
          _scoreData = MatchScoreModel.fromMap(data['score']);
        }

        notifyListeners();
      }
    });
  }

  // --- Dynamic Overs Helper ---
  int get currentMaxOvers {
    if (_matchData == null) return 0;
    int currentInnings = 1;
    if (_scoreData.playerStats.containsKey('currentInnings')) {
      currentInnings = _scoreData.playerStats['currentInnings'] is int ? _scoreData.playerStats['currentInnings'] : 1;
    }
    return _calculateMaxOvers(_matchData!, currentInnings);
  }

  int _calculateMaxOvers(MatchLobbyModel match, int currentInnings) {
    if (!match.isPlayerBasedOvers) return match.totalOvers;

    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');

    bool teamABowls = (currentInnings == 1 && !teamABatsFirst) || (currentInnings == 2 && teamABatsFirst);

    int bowlersCount = teamABowls ? match.teamAPlayers.length : match.teamBPlayers.length;
    return (bowlersCount == 0 ? 1 : bowlersCount) * match.oversPerPlayer;
  }

  // --- ACTIONS ---

  Future<void> addRun(int runs) async => _updateScoreTransaction(runs: runs, isExtra: false, isWicket: false);
  Future<void> addExtra(String type) async {
    int extraRuns = _matchData?.runsPerExtra ?? 1;
    await _updateScoreTransaction(runs: extraRuns, isExtra: true, extraType: type, isWicket: false);
  }
  Future<void> recordWicket(String type) async => _updateScoreTransaction(runs: 0, isExtra: false, isWicket: true);

  // --- UNDO LOGIC ---
  Future<void> undoLastAction() async {
    if (!canScore || _matchId == null) return;

    final docRef = _db.collection('matches').doc(_matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Match not found");

      final data = snapshot.data()!;
      final scoreMap = data['score'] as Map<String, dynamic>;

      // Check if 'lastState' exists to undo to
      if (scoreMap.containsKey('lastState') && scoreMap['lastState'] != null) {
        Map<String, dynamic> previousState = Map<String, dynamic>.from(scoreMap['lastState']);
        // Restore the previous state
        transaction.update(docRef, {'score': previousState});
      } else {
        throw Exception("Nothing to undo");
      }
    });
  }

  // --- CORE TRANSACTION ---
  Future<void> _updateScoreTransaction({
    required int runs,
    required bool isExtra,
    String? extraType,
    required bool isWicket,
  }) async {
    final docRef = _db.collection('matches').doc(_matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Match not found");

      final data = snapshot.data()!;
      if (data['status'] == 'COMPLETED') return;

      final matchLobby = MatchLobbyModel.fromMap(data);
      final scoreMap = data['score'] as Map<String, dynamic>? ?? MatchScoreModel().toMap();
      final currentScore = MatchScoreModel.fromMap(scoreMap);

      // SAVE STATE FOR UNDO (Deep copy necessary parts)
      // We save the *current* scoreMap into 'lastState' before modifying it
      final previousState = Map<String, dynamic>.from(scoreMap);
      // Remove nested lastState to avoid infinite recursion size
      previousState.remove('lastState');

      Map<String, dynamic> stats = Map.from(currentScore.playerStats);
      int currentInnings = stats['currentInnings'] is int ? stats['currentInnings'] : 1;
      int target = stats['target'] is int ? stats['target'] : 0;
      bool isSingleWicketMode = data['isSingleWicketMode'] ?? (matchLobby.teamSize == 1);

      // 1. Calc New Globals
      int newRuns = currentScore.runs + runs;
      int newWickets = currentScore.wickets + (isWicket ? 1 : 0);
      int newBalls = currentScore.balls;
      int newOvers = currentScore.overs;
      List<String> newRecent = List.from(currentScore.recentBalls);

      String ballLabel = isWicket ? "W" : (isExtra ? extraType! : "$runs");
      newRecent.add(ballLabel);
      if (newRecent.length > 12) newRecent.removeAt(0);

      // 2. Ball Counting (Gully Logic Support)
      bool shouldCountBall = !isExtra;
      if (isExtra && !matchLobby.rebowlWideNoBall) shouldCountBall = true;

      if (shouldCountBall) {
        newBalls++;
        int ballsPerOver = data['ballsPerOver'] ?? 6;
        if (newBalls >= ballsPerOver) {
          newBalls = 0;
          newOvers++;
          newRecent.clear();
        }
      }

      // 3. Update Stats
      if (currentScore.strikerId.isNotEmpty && currentScore.strikerId != 'NONE' && !isExtra) {
        final pid = currentScore.strikerId;
        final pStat = Map<String, dynamic>.from(stats[pid] ?? {});
        pStat['runs'] = (pStat['runs'] ?? 0) + runs;
        pStat['balls'] = (pStat['balls'] ?? 0) + 1;
        stats[pid] = pStat;
      }
      if (currentScore.bowlerId.isNotEmpty && currentScore.bowlerId != 'NONE') {
        final bid = currentScore.bowlerId;
        final bStat = Map<String, dynamic>.from(stats[bid] ?? {});
        bStat['runsConceded'] = (bStat['runsConceded'] ?? 0) + runs;
        if (shouldCountBall) bStat['ballsBowled'] = (bStat['ballsBowled'] ?? 0) + 1;
        if (isWicket) bStat['wickets'] = (bStat['wickets'] ?? 0) + 1;
        stats[bid] = bStat;
      }

      // 4. End Conditions
      int maxOversForInnings = _calculateMaxOvers(matchLobby, currentInnings);

      bool teamABatsFirst = (matchLobby.tossWinnerTeam == 'A' && matchLobby.tossDecision == 'BAT') ||
          (matchLobby.tossWinnerTeam == 'B' && matchLobby.tossDecision == 'BOWL');

      bool teamABatsNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);
      int battingTeamCount = teamABatsNow ? matchLobby.teamAPlayers.length : matchLobby.teamBPlayers.length;
      if (battingTeamCount == 0) battingTeamCount = 1;

      int wicketLimit;
      if (isSingleWicketMode || matchLobby.isPlayerBasedOvers) {
        wicketLimit = battingTeamCount;
      } else {
        wicketLimit = battingTeamCount - 1;
        if (wicketLimit < 1) wicketLimit = 1;
      }

      bool isAllOut = newWickets >= wicketLimit;
      bool isOversDone = newOvers >= maxOversForInnings;
      bool isChased = currentInnings == 2 && target > 0 && newRuns >= target;

      Map<String, dynamic> updates = {};

      if (isChased || (currentInnings == 2 && (isAllOut || isOversDone))) {
        // --- MATCH ENDED ---
        updates['status'] = 'COMPLETED';

        String winnerId;
        if (newRuns >= target) winnerId = teamABatsNow ? 'A' : 'B';
        else if (newRuns == target - 1) winnerId = 'DRAW';
        else winnerId = teamABatsNow ? 'B' : 'A';
        updates['winner'] = winnerId;

        // Series Stats
        Map<String, dynamic> seriesStats = Map.from(data['seriesStats'] ?? {'A': 0, 'B': 0, 'draws': 0, 'total': 0});
        if (winnerId == 'A') seriesStats['A'] = (seriesStats['A'] ?? 0) + 1;
        else if (winnerId == 'B') seriesStats['B'] = (seriesStats['B'] ?? 0) + 1;
        else seriesStats['draws'] = (seriesStats['draws'] ?? 0) + 1;
        seriesStats['total'] = (seriesStats['total'] ?? 0) + 1;
        updates['seriesStats'] = seriesStats;

        // Profile Updates
        final allPlayers = [...matchLobby.teamAPlayers, ...matchLobby.teamBPlayers];
        for (var player in allPlayers) {
          if (player.uid.isEmpty) continue;
          int pRuns = 0, pWickets = 0;
          if (stats.containsKey(player.uid)) {
            final pData = stats[player.uid];
            if (pData is Map) {
              pRuns = pData['runs'] ?? 0;
              pWickets = pData['wickets'] ?? 0;
            }
          }
          transaction.update(_db.collection('users').doc(player.uid), {
            'matchesPlayed': FieldValue.increment(1),
            'totalRuns': FieldValue.increment(pRuns),
            'wicketsTaken': FieldValue.increment(pWickets),
            'lastPlayedAt': FieldValue.serverTimestamp(),
          });
        }

        stats['currentInnings'] = 2;
        stats['target'] = target;

        updates['score'] = {
          'runs': newRuns, 'wickets': newWickets, 'overs': newOvers, 'balls': newBalls,
          'strikerId': currentScore.strikerId, 'nonStrikerId': currentScore.nonStrikerId,
          'bowlerId': currentScore.bowlerId, 'recentBalls': newRecent, 'playerStats': stats,
          'lastState': previousState, // Store Undo State
        };

      } else if (currentInnings == 1 && (isAllOut || isOversDone)) {
        // --- INNINGS SWAP ---
        stats['currentInnings'] = 2;
        stats['target'] = newRuns + 1;
        stats['innings1Summary'] = '$newRuns/$newWickets';

        updates['score'] = {
          'runs': 0, 'wickets': 0, 'overs': 0, 'balls': 0,
          'strikerId': '', 'nonStrikerId': isSingleWicketMode ? 'NONE' : '', 'bowlerId': '',
          'recentBalls': [], 'playerStats': stats,
          'lastState': previousState, // Store Undo State
        };
      } else {
        // --- CONTINUE ---
        String nextStriker = currentScore.strikerId;
        String nextNonStriker = currentScore.nonStrikerId;
        bool canSwap = nextNonStriker.isNotEmpty && nextNonStriker != 'NONE' && nextStriker.isNotEmpty;

        if (canSwap) {
          if (shouldCountBall && !isWicket && (runs % 2 != 0)) {
            final temp = nextStriker; nextStriker = nextNonStriker; nextNonStriker = temp;
          }
          if (shouldCountBall && newBalls == 0 && newOvers > currentScore.overs) {
            final temp = nextStriker; nextStriker = nextNonStriker; nextNonStriker = temp;
          }
        }

        stats['currentInnings'] = currentInnings;
        stats['target'] = target;

        updates['score'] = {
          'runs': newRuns, 'wickets': newWickets, 'overs': newOvers, 'balls': newBalls,
          'strikerId': nextStriker, 'nonStrikerId': nextNonStriker, 'bowlerId': currentScore.bowlerId,
          'recentBalls': newRecent, 'playerStats': stats,
          'lastState': previousState, // Store Undo State
        };
      }

      transaction.update(docRef, updates);
    });
  }

  // --- Session Management ---

  Future<void> setSingleWicketMode(bool enable) async {
    if (!isAuthorized || _matchId == null) return;
    await _db.collection('matches').doc(_matchId).update({
      'isSingleWicketMode': enable,
      'score.nonStrikerId': enable ? 'NONE' : '',
    });
  }

  Future<void> startNextMatchInSession(String decision) async {
    if (_matchId == null || !isAuthorized) return;

    final docRef = _db.collection('matches').doc(_matchId);
    final doc = await docRef.get();

    final winner = doc.data()?['winner'] ?? 'A';
    final isSingleWicket = doc.data()?['isSingleWicketMode'] ?? false;

    WriteBatch batch = _db.batch();

    // Archive History
    final historyRef = docRef.collection('history').doc();
    batch.set(historyRef, {
      'score': doc.data()?['score'],
      'winner': winner,
      'matchNumber': (doc.data()?['seriesStats']?['total'] ?? 0),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Reset for New Match
    batch.update(docRef, {
      'status': 'LIVE',
      'tossWinnerTeam': winner == 'DRAW' ? 'A' : winner,
      'tossDecision': decision,
      'winner': FieldValue.delete(),
      'score': {
        'runs': 0, 'wickets': 0, 'overs': 0, 'balls': 0,
        'strikerId': '', 'nonStrikerId': isSingleWicket ? 'NONE' : '', 'bowlerId': '',
        'recentBalls': [], 'playerStats': {},
        'currentInnings': 1, 'target': 0,
        // No lastState on fresh start
      }
    });

    await batch.commit();
  }

  Future<void> endSession() async {
    if (_matchId == null || !isAuthorized) return;
    // Set status to SESSION_ENDED so dashboard stream filters it out
    await _db.collection('matches').doc(_matchId).update({'status': 'SESSION_ENDED'});
  }

  // Player Setters
  Future<void> setStriker(String uid) async {
    if(isAuthorized) await _db.collection('matches').doc(_matchId).update({'score.strikerId': uid});
  }
  Future<void> setNonStriker(String uid) async {
    if(isAuthorized) await _db.collection('matches').doc(_matchId).update({'score.nonStrikerId': uid});
  }
  Future<void> setBowler(String uid) async {
    if(isAuthorized) await _db.collection('matches').doc(_matchId).update({'score.bowlerId': uid});
  }
}