import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/models/user_profile_model.dart';
import 'package:rubberball/models/match_lobby_model.dart';

class UserProfileProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfileModel? _user;
  List<Map<String, dynamic>> _recentMatches = [];
  String _lastTeamPlayed = "Free Agent"; // Default

  bool _isLoading = true;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _historySubscription;

  UserProfileModel? get user => _user;
  List<Map<String, dynamic>> get recentMatches => _recentMatches;
  String get lastTeamPlayed => _lastTeamPlayed;
  bool get isLoading => _isLoading;

  UserProfileProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _subscribeToUserProfile(firebaseUser.uid);
        _subscribeToUserHistory(firebaseUser.uid);
      } else {
        _user = null;
        _recentMatches = [];
        _lastTeamPlayed = "Free Agent";
        _isLoading = false;
        _userSubscription?.cancel();
        _historySubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _subscribeToUserProfile(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen(
          (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _user = UserProfileModel.fromMap(snapshot.data() as Map<String, dynamic>, uid);
        } else {
          _user = UserProfileModel(
            id: uid,
            name: _auth.currentUser?.displayName ?? 'Player',
            email: _auth.currentUser?.email ?? '',
            phoneNumber: '',
            role: 'Player',
            jerseyNumber: '--',
            teamName: 'Free Agent',
            profileImageUrl: _auth.currentUser?.photoURL ?? '',
            matchesPlayed: 0,
            totalRuns: 0,
            wicketsTaken: 0,
            manOfTheMatchCount: 0,
          );
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // --- Real-time User History & Last Team Logic ---
  void _subscribeToUserHistory(String uid) {
    _historySubscription?.cancel();
    _historySubscription = _firestore
        .collection('matches')
        .where('status', isEqualTo: 'SESSION_ENDED')
        .orderBy('createdAt', descending: true)
    // Fetch more than 5 to ensure we find valid ones, but limit for performance
        .limit(20)
        .snapshots()
        .listen((snapshot) {

      final List<Map<String, dynamic>> userMatches = [];
      String? latestTeamName;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lobby = MatchLobbyModel.fromMap(data);

        // Check participation
        bool inTeamA = lobby.teamAPlayers.any((p) => p.uid == uid);
        bool inTeamB = lobby.teamBPlayers.any((p) => p.uid == uid);

        if (inTeamA || inTeamB) {
          // Capture the most recent team name (first iteration match is latest)
          if (latestTeamName == null) {
            latestTeamName = inTeamA ? lobby.teamAName : lobby.teamBName;
          }

          String result = "Draw";
          if (data['winner'] == 'A') result = inTeamA ? "WON" : "LOST";
          else if (data['winner'] == 'B') result = inTeamB ? "WON" : "LOST";
          else if (data['winner'] == 'DRAW') result = "DRAW";

          final date = lobby.createdAt;

          userMatches.add({
            'title': "${lobby.teamAName} vs ${lobby.teamBName}",
            'date': "${date.day}/${date.month}/${date.year}",
            'result': result,
            'isWin': result == "WON",
          });
        }
      }

      _recentMatches = userMatches;
      _lastTeamPlayed = latestTeamName ?? "Free Agent";

      notifyListeners();
    });
  }

  Future<void> updateJerseyNumber(String newNumber) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser.uid).update({'jerseyNumber': newNumber});
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}