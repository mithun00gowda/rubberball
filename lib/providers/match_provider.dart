import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/models/match_model.dart';
import 'package:rubberball/models/match_lobby_model.dart';

class MatchesProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<MatchModel> _matches = [];
  List<MatchModel> get matches => _matches;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription<QuerySnapshot>? _historySub;

  MatchesProvider() {
    _initHistoryStream();
  }

  void _initHistoryStream() {
    _isLoading = true;
    notifyListeners();

    // Listen to ALL finalized sessions ordered by date
    // Note: Ensure the Composite Index is created in Firebase Console
    _historySub = _db
        .collection('matches')
        .where('status', isEqualTo: 'SESSION_ENDED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {

      _matches = snapshot.docs.map((doc) {
        final data = doc.data();
        final lobby = MatchLobbyModel.fromMap(data);

        final scoreData = data['score'] as Map<String, dynamic>? ?? {};
        final runs = scoreData['runs'] ?? 0;
        final wickets = scoreData['wickets'] ?? 0;
        final overs = "${scoreData['overs']}.${scoreData['balls']}";

        String resultDesc = "Match Drawn";
        if (data['winner'] == 'A') resultDesc = "${lobby.teamAName} Won";
        if (data['winner'] == 'B') resultDesc = "${lobby.teamBName} Won";

        return MatchModel(
          id: lobby.matchId,
          team1: lobby.teamAName,
          team2: lobby.teamBName,
          winnerTeamId: data['winner'] == 'A' ? lobby.teamAName : (data['winner'] == 'B' ? lobby.teamBName : "Draw"),
          resultDescription: resultDesc,
          matchDate: lobby.createdAt,
          scoresSummary: "$runs/$wickets ($overs)",
          location: lobby.location,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error streaming history: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }
}