import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/models/player_model.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  MatchLobbyModel? _liveMatch;

  // FIXED: Changed from single PlayerModel? to List<PlayerModel>
  List<PlayerModel> _topPerformers = [];

  bool _isLoading = true;

  StreamSubscription<QuerySnapshot>? _matchSub;
  StreamSubscription<QuerySnapshot>? _playerSub;

  MatchLobbyModel? get liveMatch => _liveMatch;

  // FIXED: Getter now returns the list
  List<PlayerModel> get topPerformers => _topPerformers;

  bool get isLoading => _isLoading;

  DashboardProvider() {
    _initStreams();
  }

  void _initStreams() {
    _isLoading = true;
    notifyListeners();

    // 1. Live Match Stream
    _matchSub = _db
        .collection('matches')
        .where('status', whereIn: ['LIVE', 'COMPLETED'])
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _liveMatch = MatchLobbyModel.fromMap(snapshot.docs.first.data());
      } else {
        _liveMatch = null;
      }
      _checkLoadingComplete();
    });

    // 2. Top Performers Stream (Fetch Top 3)
    _playerSub = _db
        .collection('users')
        .orderBy('totalRuns', descending: true)
        .limit(3) // Limit to top 3
        .snapshots()
        .listen((snapshot) {

      // Map documents to PlayerModel list
      _topPerformers = snapshot.docs.map((doc) {
        final data = doc.data();
        return PlayerModel(
          id: data['uid'] ?? '',
          name: data['name'] ?? 'Unknown',
          role: data['role'] ?? 'Player',
          imageUrl: data['photoUrl'] ?? '',
          stats: {
            'Runs': (data['totalRuns'] ?? 0).toString(),
            'Wickets': (data['wicketsTaken'] ?? 0).toString(),
            'Matches': (data['matchesPlayed'] ?? 0).toString(),
          },
        );
      }).toList();

      _checkLoadingComplete();
    });
  }

  void _checkLoadingComplete() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    _playerSub?.cancel();
    super.dispose();
  }
}