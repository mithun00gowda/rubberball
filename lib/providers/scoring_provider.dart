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

  // --- Helper: Dynamic Max Overs Calculation ---
  // Calculates strictly based on "Players Available to Bowl" * "Overs Per Person"
  int get currentMaxOvers {
    if (_matchData == null) return 0;

    // Check current innings from map (default to 1)
    int currentInnings = _scoreData.playerStats.containsKey('currentInnings')
        ? _scoreData.playerStats['currentInnings']
        : 1; // Fallback helper since model field might be missing in older version

    return _calculateMaxOvers(_matchData!, currentInnings);
  }

  int _calculateMaxOvers(MatchLobbyModel match, int currentInnings) {
    // If not using dynamic overs, return the fixed total
    if (!match.isPlayerBasedOvers) return match.totalOvers;

    // 1. Determine who batted first
    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');

    // 2. Identify Bowling Team for this innings
    // Innings 1: If A Batting -> B Bowling
    // Innings 2: If A Batting -> B Bowling (Wait, in Innings 2, roles swap)

    bool teamABowls;
    if (currentInnings == 1) {
      teamABowls = !teamABatsFirst;
    } else {
      teamABowls = teamABatsFirst; // In 2nd innings, the team that batted first is now bowling
    }

    // 3. Count Players in Bowling Team
    int bowlersCount = teamABowls ? match.teamAPlayers.length : match.teamBPlayers.length;

    // 4. Calculate: Players * OversPerPlayer
    // e.g., 1 player * 1 over = 1 over total.
    int calculated = (bowlersCount == 0 ? 1 : bowlersCount) * match.oversPerPlayer;
    return calculated;
  }

  // --- Scoring Actions ---

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

      // 2. Ball Counting
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

      // 3. Stats Update (Striker/Bowler)
      Map<String, dynamic> stats = Map.from(currentScore.playerStats);
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
        if (isLegal) bStat['ballsBowled'] = (bStat['ballsBowled'] ?? 0) + 1;
        if (isWicket) bStat['wickets'] = (bStat['wickets'] ?? 0) + 1;
        stats[bid] = bStat;
      }

      // 4. CHECK END CONDITIONS (Crucial Logic)

      // A. Calculate Max Overs based on ACTUAL players present now
      int maxOversForInnings = _calculateMaxOvers(matchLobby, currentInnings);

      // B. Calculate Wicket Limit based on ACTUAL players
      bool teamABatsFirst = (matchLobby.tossWinnerTeam == 'A' && matchLobby.tossDecision == 'BAT') ||
          (matchLobby.tossWinnerTeam == 'B' && matchLobby.tossDecision == 'BOWL');
      bool teamABatsNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);

      // Get the list of players currently batting
      int battingTeamCount = teamABatsNow ? matchLobby.teamAPlayers.length : matchLobby.teamBPlayers.length;
      if (battingTeamCount == 0) battingTeamCount = 1; // Safety

      // Limit Logic:
      // If 1v1 (Single Wicket), 1 wicket = All Out.
      // If Gully Mode (Last Man Standing), N players = N wickets.
      // If Standard, N players = N-1 wickets.
      int wicketLimit;
      if (isSingleWicketMode || matchLobby.isPlayerBasedOvers) {
        // In gully cricket "Player Based", usually every player gets to bat.
        // So if 2 players, 2 wickets allowed (Last man standing logic is common).
        wicketLimit = battingTeamCount;
      } else {
        wicketLimit = battingTeamCount - 1; // Standard
        if (wicketLimit < 1) wicketLimit = 1;
      }

      bool isAllOut = newWickets >= wicketLimit;
      bool isOversDone = newOvers >= maxOversForInnings;
      bool isChased = currentInnings == 2 && newRuns >= target;

      Map<String, dynamic> updates = {};

      // --- MATCH ENDED ---
      if (isChased || (currentInnings == 2 && (isAllOut || isOversDone))) {
        updates['status'] = 'COMPLETED';

        String winnerId;
        if (newRuns >= target) {
          winnerId = teamABatsNow ? (teamABatsNow ? 'A' : 'B') : (teamABatsFirst ? 'B' : 'A');
          // Logic correction: If chasing team (current batting) has >= target, they win.
          winnerId = teamABatsNow ? (teamABatsFirst ? 'B' : 'A') : 'DRAW'; // Wait, simpler:
          // If currentInnings == 2 (Chasing), and newRuns >= target, Batting Team Wins.
          winnerId = teamABatsNow ? 'A' : 'B'; // Whichever team is batting now wins
        } else if (newRuns == target - 1) {
          winnerId = 'DRAW';
        } else {
          // Defending team won
          winnerId = teamABatsNow ? 'B' : 'A'; // Whichever team is NOT batting wins
        }
        updates['winner'] = winnerId;

        updates['score'] = {
          'runs': newRuns, 'wickets': newWickets, 'overs': newOvers, 'balls': newBalls,
          'strikerId': currentScore.strikerId, 'nonStrikerId': currentScore.nonStrikerId,
          'bowlerId': currentScore.bowlerId, 'recentBalls': newRecent, 'playerStats': stats,
          'currentInnings': 2, 'target': target,
        };

      }
      // --- SWAP TEAMS (INNINGS END) ---
      else if (currentInnings == 1 && (isAllOut || isOversDone)) {
        updates['score'] = {
          'runs': 0,
          'wickets': 0,
          'overs': 0,
          'balls': 0,
          'strikerId': '', // Force re-select for new batting team
          // If Single Wicket mode is ON, default Non-Striker to 'NONE' immediately
          'nonStrikerId': isSingleWicketMode ? 'NONE' : '',
          'bowlerId': '',
          'recentBalls': [],
          'playerStats': stats,
          'currentInnings': 2,
          'target': newRuns + 1,
          'innings1Score': '$newRuns/$newWickets ($newOvers.$newBalls)',
        };
      }
      // --- CONTINUE ---
      else {
        // Normal ball update logic (Swap strike etc)
        String nextStriker = currentScore.strikerId;
        String nextNonStriker = currentScore.nonStrikerId;
        bool noSwapNeeded = nextNonStriker == 'NONE';

        if (!noSwapNeeded) {
          if (isLegal && !isWicket && (runs % 2 != 0)) {
            final temp = nextStriker; nextStriker = nextNonStriker; nextNonStriker = temp;
          }
          if (isLegal && newBalls == 0 && newOvers > currentScore.overs) {
            final temp = nextStriker; nextStriker = nextNonStriker; nextNonStriker = temp;
          }
        }

        updates['score'] = {
          'runs': newRuns, 'wickets': newWickets, 'overs': newOvers, 'balls': newBalls,
          'strikerId': nextStriker, 'nonStrikerId': nextNonStriker, 'bowlerId': currentScore.bowlerId,
          'recentBalls': newRecent, 'playerStats': stats,
          'currentInnings': currentInnings, 'target': target,
        };
      }

      transaction.update(docRef, updates);
    });
  }

  // --- Session Management ---

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

    // Auto-rotate: Winner usually gets choice, or we just keep rotation.
    // Logic: If 'decision' is passed (e.g. Winner chose BAT), set that.

    await docRef.update({
      'status': 'LIVE',
      'tossWinnerTeam': doc.data()?['winner'] ?? 'A', // Previous winner decides
      'tossDecision': decision,
      'winner': FieldValue.delete(),
      'score': {
        'runs': 0, 'wickets': 0, 'overs': 0, 'balls': 0,
        'strikerId': '', 'nonStrikerId': '', 'bowlerId': '',
        'recentBalls': [], 'playerStats': {},
        'currentInnings': 1, 'target': 0,
      }
    });
  }

  Future<void> endSession() async {
    if (_matchId == null || !canScore) return;
    await _db.collection('matches').doc(_matchId).update({'status': 'SESSION_ENDED'});
  }

  // Player Setters
  Future<void> setStriker(String uid) async {
    if(canScore) await _db.collection('matches').doc(_matchId).update({'score.strikerId': uid});
  }
  Future<void> setNonStriker(String uid) async {
    if(canScore) await _db.collection('matches').doc(_matchId).update({'score.nonStrikerId': uid});
  }
  Future<void> setBowler(String uid) async {
    if(canScore) await _db.collection('matches').doc(_matchId).update({'score.bowlerId': uid});
  }
}