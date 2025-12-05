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
    final now = DateTime.now();

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
      createdAt: now,
      lastActivityTime: now,
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

    if (teamSide == 'A') {
      await docRef.update({
        'teamAPlayers': FieldValue.arrayUnion([player.toMap()]),
        'lastActivityTime': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'teamBPlayers': FieldValue.arrayUnion([player.toMap()]),
        'lastActivityTime': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- NEW: Add Guest Player ---
  Future<void> addGuestPlayer(String matchId, String teamSide, String name) async {
    // Generate a temporary unique ID for the guest
    final guestId = "guest_${const Uuid().v4().substring(0, 8)}";

    final guest = LobbyPlayer(
      uid: guestId,
      name: "$name (Guest)", // Mark as guest visually
      photoUrl: null, // No photo for guests
    );

    final docRef = _db.collection('matches').doc(matchId);

    if (teamSide == 'A') {
      await docRef.update({
        'teamAPlayers': FieldValue.arrayUnion([guest.toMap()]),
        'lastActivityTime': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'teamBPlayers': FieldValue.arrayUnion([guest.toMap()]),
        'lastActivityTime': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> assignCaptain(String matchId, String teamSide, String userId) async {
    final field = teamSide == 'A' ? 'captainAId' : 'captainBId';
    await _db.collection('matches').doc(matchId).update({
      field: userId,
      'lastActivityTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> proceedToToss(String matchId) async {
    await _db.collection('matches').doc(matchId).update({
      'status': 'TOSS',
      'lastActivityTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveTossWinner(String matchId, String winningTeamSide) async {
    await _db.collection('matches').doc(matchId).update({
      'tossWinnerTeam': winningTeamSide,
      'lastActivityTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startMatch(String matchId, String decision) async {
    await _db.collection('matches').doc(matchId).update({
      'tossDecision': decision,
      'status': 'LIVE',
      'lastActivityTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<MatchLobbyModel> matchStream(String matchId) {
    return _db.collection('matches').doc(matchId).snapshots().map((snapshot) {
      if (!snapshot.exists) throw Exception("Match not found");
      return MatchLobbyModel.fromMap(snapshot.data()!);
    });
  }
}