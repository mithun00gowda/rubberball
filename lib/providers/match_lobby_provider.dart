import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:uuid/uuid.dart';

class MatchLobbyProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createMatchShell({
    required String location,
    required String teamAName,
    required String teamBName,
    required int overs,
    required String matchType,
    required bool isSingleWicketMode,
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

      isSingleWicketMode: isSingleWicketMode,
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

    // FIXED: joinTeam only adds the player.
    // Overs are calculated dynamically in ScoringProvider, so we don't manually increment 'totalOvers' here.
    if (teamSide == 'A') {
      await docRef.update({
        'teamAPlayers': FieldValue.arrayUnion([player.toMap()])
      });
    } else {
      await docRef.update({
        'teamBPlayers': FieldValue.arrayUnion([player.toMap()])
      });
    }
  }

  Future<void> assignCaptain(String matchId, String teamSide, String userId) async {
    final field = teamSide == 'A' ? 'captainAId' : 'captainBId';
    await _db.collection('matches').doc(matchId).update({
      field: userId,
    });
  }

  Future<void> proceedToToss(String matchId) async {
    await _db.collection('matches').doc(matchId).update({
      'status': 'TOSS',
    });
  }

  Future<void> saveTossWinner(String matchId, String winningTeamSide) async {
    await _db.collection('matches').doc(matchId).update({
      'tossWinnerTeam': winningTeamSide,
    });
  }

  Future<void> startMatch(String matchId, String decision) async {
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