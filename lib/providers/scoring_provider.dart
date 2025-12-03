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

  // --- Role Helpers ---
  bool get isCaptainA => _matchData?.captainAId == _auth.currentUser?.uid;
  bool get isCaptainB => _matchData?.captainBId == _auth.currentUser?.uid;
  bool get isHost => _matchData?.hostId == _auth.currentUser?.uid;

  // Allows both captains and host to score
  bool get canScore => isCaptainA || isCaptainB || isHost;

  // --- Initialization ---
  void init(String matchId) {
    _matchId = matchId;
    _listenToMatch();
  }

  void _listenToMatch() {
    if (_matchId == null) return;

    _db.collection('matches').doc(_matchId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _matchData = MatchLobbyModel.fromMap(snapshot.data()!);

        if (snapshot.data()!.containsKey('score')) {
          _scoreData = MatchScoreModel.fromMap(snapshot.data()!['score']);
        }

        notifyListeners();
      }
    });
  }

  // --- Helper: Dynamic Max Overs ---
  int get currentMaxOvers {
    if (_matchData == null) return 0;
    // Estimate innings based on target availability
    int estInnings = (_scoreData.playerStats.containsKey('target') && _scoreData.playerStats['target'] > 0) ? 2 : 1;
    // However, rely on the explicit currentInnings if available in your model or map
    // Since MatchScoreModel doesn't expose it directly as a typed field yet (it's in the map),
    // we use this heuristic or need to update the model.
    // For safety, checking the raw map if needed, but here assuming target logic holds.
    return _calculateMaxOvers(_matchData!, estInnings);
  }

  int _calculateMaxOvers(MatchLobbyModel match, int currentInnings) {
    if (!match.isPlayerBasedOvers) return match.totalOvers;

    // Determine who batted first based on Toss
    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');

    // Logic Fix:
    // Innings 1: If A Bats First -> Team A is Batting, Team B is Bowling.
    // Innings 2: If A Bats First -> Team B is Batting, Team A is Bowling.

    bool teamABowls = (currentInnings == 1 && !teamABatsFirst) || (currentInnings == 2 && teamABatsFirst);

    int bowlersCount = teamABowls ? match.teamAPlayers.length : match.teamBPlayers.length;

    // In 1v1, count is 1. If 2 players join B, count becomes 3.
    // Fallback to 1 if empty to avoid 0 overs.
    return (bowlersCount == 0 ? 1 : bowlersCount) * match.oversPerPlayer;
  }

  // --- Scoring Actions (Transactions) ---

  Future<void> addRun(int runs) async {
    if (!canScore || _matchId == null) return;
    await _updateScoreTransaction(runs: runs, isExtra: false, isWicket: false);
  }

  Future<void> addExtra(String type) async {
    if (!canScore || _matchId == null) return;
    await _updateScoreTransaction(runs: 1, isExtra: true, extraType: type, isWicket: false);
  }

  Future<void> recordWicket(String type) async {
    if (!canScore || _matchId == null) return;
    await _updateScoreTransaction(runs: 0, isExtra: false, isWicket: true);
  }

  // --- The Core Transaction Logic ---
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
      final matchLobby = MatchLobbyModel.fromMap(data);

      final scoreMap = data['score'] as Map<String, dynamic>? ?? MatchScoreModel().toMap();
      final currentScore = MatchScoreModel.fromMap(scoreMap);

      // Extract Extended State
      int currentInnings = scoreMap['currentInnings'] ?? 1;
      int target = scoreMap['target'] ?? 0;
      bool isSingleWicketMode = data['isSingleWicketMode'] ?? (matchLobby.teamSize == 1);

      // 1. Calculate New Globals
      int newRuns = currentScore.runs + runs;
      int newWickets = currentScore.wickets + (isWicket ? 1 : 0);
      int newBalls = currentScore.balls;
      int newOvers = currentScore.overs;
      List<String> newRecent = List.from(currentScore.recentBalls);

      String ballLabel = isWicket ? "W" : (isExtra ? extraType! : "$runs");
      newRecent.add(ballLabel);
      if (newRecent.length > 12) newRecent.removeAt(0);

      // 2. Ball Counting Logic
      bool isLegal = !isExtra;
      if (isLegal) {
        newBalls++;
        int ballsPerOver = data['ballsPerOver'] ?? 6;
        if (newBalls >= ballsPerOver) {
          newBalls = 0;
          newOvers++;
          newRecent.clear();
        }
      }

      // 3. Update Individual Stats
      Map<String, dynamic> stats = Map.from(currentScore.playerStats);

      if (currentScore.strikerId.isNotEmpty && currentScore.strikerId != 'NONE' && !isExtra) {
        final pid = currentScore.strikerId;
        final pStat = Map<String, dynamic>.from(stats[pid] ?? {});
        pStat['runs'] = (pStat['runs'] ?? 0) + runs;
        pStat['balls'] = (pStat['balls'] ?? 0) + 1;
        if (runs == 4) pStat['4s'] = (pStat['4s'] ?? 0) + 1;
        if (runs == 6) pStat['6s'] = (pStat['6s'] ?? 0) + 1;
        stats[pid] = pStat;
      }

      if (currentScore.bowlerId.isNotEmpty && currentScore.bowlerId != 'NONE') {
        final bid = currentScore.bowlerId;
        final bStat = Map<String, dynamic>.from(stats[bid] ?? {});
        bStat['runsConceded'] = (bStat['runsConceded'] ?? 0) + runs;
        if (isLegal) bStat['ballsBowled'] = (bStat['ballsBowled'] ?? 0) + 1;
        if (isWicket) bStat['wickets'] = (bStat['wickets'] ?? 0) + 1;
        stats[bid] = bStat;
      }

      // 4. Check End Conditions
      int maxOversForInnings = _calculateMaxOvers(matchLobby, currentInnings);

      // Dynamic Wicket Limit Calculation:
      // If Single Wicket Mode: Wicket Limit = 1 (Regardless of team size setting)
      // Else: Wicket Limit = Actual Players in Batting Team - 1 (Standard) or Actual Players (Last Man Standing)

      bool teamABatsFirst = (matchLobby.tossWinnerTeam == 'A' && matchLobby.tossDecision == 'BAT') ||
          (matchLobby.tossWinnerTeam == 'B' && matchLobby.tossDecision == 'BOWL');

      // Determine currently batting team list
      bool teamABatsNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);
      int battingTeamCount = teamABatsNow ? matchLobby.teamAPlayers.length : matchLobby.teamBPlayers.length;

      // If dynamic, use actual count. If static, use configured teamSize.
      // For Single Wicket mode, the limit is strictly 1 wicket per innings effectively?
      // User said: "if one wicket gone then bowling team come to bat".
      // If it's a 1v1 match, battingTeamCount is 1. Wicket Limit = 1.

      int wicketLimit;
      if (isSingleWicketMode || battingTeamCount == 1) {
        wicketLimit = 1; // 1 player = 1 wicket allowed
      } else {
        wicketLimit = battingTeamCount - 1; // Standard cricket (10 wickets for 11 players)
        // If playing "Last Man Standing", use battingTeamCount.
        // Assuming standard gully rules often allow last man, let's use battingTeamCount if < 11?
        // Let's stick to standard count for now, but safe fallback.
        if (wicketLimit < 1) wicketLimit = 1;
      }

      bool isAllOut = newWickets >= wicketLimit;
      bool isOversDone = newOvers >= maxOversForInnings;
      bool isChased = currentInnings == 2 && newRuns >= target;

      Map<String, dynamic> updates = {};

      // SCENARIO A: MATCH ENDED
      if (isChased || (currentInnings == 2 && (isAllOut || isOversDone))) {
        updates['status'] = 'COMPLETED';

        String winnerId;
        if (newRuns >= target) {
          winnerId = teamABatsFirst ? 'B' : 'A';
        } else if (newRuns == target - 1) {
          winnerId = 'DRAW';
        } else {
          winnerId = teamABatsFirst ? 'A' : 'B';
        }
        updates['winner'] = winnerId;

        updates['score'] = {
          'runs': newRuns,
          'wickets': newWickets,
          'overs': newOvers,
          'balls': newBalls,
          'strikerId': currentScore.strikerId,
          'nonStrikerId': currentScore.nonStrikerId,
          'bowlerId': currentScore.bowlerId,
          'recentBalls': newRecent,
          'playerStats': stats,
          'currentInnings': 2,
          'target': target,
        };

      }
      // SCENARIO B: INNINGS BREAK
      else if (currentInnings == 1 && (isAllOut || isOversDone)) {
        updates['score'] = {
          'runs': 0,
          'wickets': 0,
          'overs': 0,
          'balls': 0,
          'strikerId': '',
          'nonStrikerId': isSingleWicketMode ? 'NONE' : '',
          'bowlerId': '',
          'recentBalls': [],
          'playerStats': stats,
          'currentInnings': 2,
          'target': newRuns + 1,
          'innings1Score': '$newRuns/$newWickets ($newOvers.$newBalls)',
        };
      }
      // SCENARIO C: BALL COMPLETED
      else {
        String nextStriker = currentScore.strikerId;
        String nextNonStriker = currentScore.nonStrikerId;
        bool noSwapNeeded = nextNonStriker == 'NONE';

        if (!noSwapNeeded) {
          if (isLegal && !isWicket && (runs % 2 != 0)) {
            final temp = nextStriker;
            nextStriker = nextNonStriker;
            nextNonStriker = temp;
          }
          if (isLegal && newBalls == 0 && newOvers > currentScore.overs) {
            final temp = nextStriker;
            nextStriker = nextNonStriker;
            nextNonStriker = temp;
          }
        }

        updates['score'] = {
          'runs': newRuns,
          'wickets': newWickets,
          'overs': newOvers,
          'balls': newBalls,
          'strikerId': nextStriker,
          'nonStrikerId': nextNonStriker,
          'bowlerId': currentScore.bowlerId,
          'recentBalls': newRecent,
          'playerStats': stats,
          'currentInnings': currentInnings,
          'target': target,
        };
      }

      transaction.update(docRef, updates);
    });
  }

  // --- Session / Match Management ---

  Future<void> setSingleWicketMode(bool enable) async {
    if (!canScore || _matchId == null) return;
    await _db.collection('matches').doc(_matchId).update({
      'isSingleWicketMode': enable,
      'score.nonStrikerId': enable ? 'NONE' : '',
    });
  }

  Future<void> startNextMatchInSession(String decision) async {
    if (_matchId == null || !canScore) return;

    final docRef = _db.collection('matches').doc(_matchId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final winner = doc.data()?['winner'] ?? 'A';

    // Check if Single Wicket was active to persist it
    final isSingleWicket = doc.data()?['isSingleWicketMode'] ?? false;

    await docRef.update({
      'status': 'LIVE',
      'tossWinnerTeam': winner == 'DRAW' ? 'A' : winner,
      'tossDecision': decision,
      'winner': FieldValue.delete(),
      'score': {
        'runs': 0,
        'wickets': 0,
        'overs': 0,
        'balls': 0,
        'strikerId': '',
        'nonStrikerId': isSingleWicket ? 'NONE' : '',
        'bowlerId': '',
        'recentBalls': [],
        'playerStats': {},
        'currentInnings': 1,
        'target': 0,
      }
    });
  }

  Future<void> endSession() async {
    if (_matchId == null || !canScore) return;
    await _db.collection('matches').doc(_matchId).update({
      'status': 'SESSION_ENDED',
    });
  }

  Future<void> setStriker(String playerId) async {
    if (!canScore) return;
    await _db.collection('matches').doc(_matchId).update({'score.strikerId': playerId});
  }

  Future<void> setNonStriker(String playerId) async {
    if (!canScore) return;
    await _db.collection('matches').doc(_matchId).update({'score.nonStrikerId': playerId});
  }

  Future<void> setBowler(String playerId) async {
    if (!canScore) return;
    await _db.collection('matches').doc(_matchId).update({'score.bowlerId': playerId});
  }
}