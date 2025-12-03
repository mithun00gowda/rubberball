import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:uuid/uuid.dart';

class MatchLobbyProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ... (Keep existing createMatchShell, joinTeam, assignCaptain) ...

  Future<String> createMatchShell({
    required String location,
    required String teamAName,
    required String teamBName,
    required int overs,
    required String matchType,
    required int teamSize,
    required int ballsPerOver,
    required bool rebowlWideNoBall,
    required int runsPerExtra,
    required bool isPlayerBasedOvers,
    required int oversPerPlayer,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final matchId = const Uuid().v4();

    final hostPlayer = LobbyPlayer(
        uid: user.uid,
        name: user.displayName ?? 'Host',
        photoUrl: user.photoURL
    );

    int initialOvers = isPlayerBasedOvers ? oversPerPlayer : overs;

    final newMatch = MatchLobbyModel(
      matchId: matchId,
      hostId: user.uid,
      location: location,
      createdAt: DateTime.now(),
      teamAPlayers: [hostPlayer],
      teamAName: teamAName.isNotEmpty ? teamAName : "Team A",
      teamBName: teamBName.isNotEmpty ? teamBName : "Team B",
      totalOvers: initialOvers,
      matchType: matchType,
      teamSize: teamSize,
      ballsPerOver: ballsPerOver,
      rebowlWideNoBall: rebowlWideNoBall,
      runsPerExtra: runsPerExtra,
      isPlayerBasedOvers: isPlayerBasedOvers,
      oversPerPlayer: oversPerPlayer,
    );

    await _db.collection('matches').doc(matchId).set(newMatch.toMap());
    return matchId;
  }

  Future<void> joinTeam(String matchId, String teamSide) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final player = LobbyPlayer(
        uid: user.uid,
        name: user.displayName ?? 'Player',
        photoUrl: user.photoURL
    );

    final docRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Match not found");

      final data = snapshot.data()!;
      final bool isDynamic = data['isPlayerBasedOvers'] ?? false;
      final int perPlayer = data['oversPerPlayer'] ?? 1;
      final int currentOvers = data['totalOvers'] ?? 0;

      if (teamSide == 'A') {
        transaction.update(docRef, {
          'teamAPlayers': FieldValue.arrayUnion([player.toMap()])
        });
      } else {
        transaction.update(docRef, {
          'teamBPlayers': FieldValue.arrayUnion([player.toMap()])
        });
      }

      if (isDynamic) {
        transaction.update(docRef, {
          'totalOvers': currentOvers + perPlayer
        });
      }
    });
  }

  Future<void> assignCaptain(String matchId, String teamSide, String userId) async {
    final field = teamSide == 'A' ? 'captainAId' : 'captainBId';
    await _db.collection('matches').doc(matchId).update({
      field: userId,
    });
  }

  // --- TOSS LOGIC ---

  // 1. Move from Lobby to Toss Screen
  Future<void> proceedToToss(String matchId) async {
    await _db.collection('matches').doc(matchId).update({
      'status': 'TOSS',
    });
  }

  // 2. Save the Toss Result
  Future<void> saveTossWinner(String matchId, String winningTeamSide) async {
    // winningTeamSide is 'A' or 'B'
    await _db.collection('matches').doc(matchId).update({
      'tossWinnerTeam': winningTeamSide,
    });
  }

  // 3. Save Decision and Start Match
  Future<void> startMatch(String matchId, String decision) async {
    // decision is 'BAT' or 'BOWL'
    await _db.collection('matches').doc(matchId).update({
      'tossDecision': decision,
      'status': 'LIVE',
    });
  }

  Stream<MatchLobbyModel> matchStream(String matchId) {
    return _db.collection('matches').doc(matchId).snapshots().map((snapshot) {
      if (!snapshot.exists) throw Exception("Match not found");
      return MatchLobbyModel.fromMap(snapshot.data()!);
    });
  }
}