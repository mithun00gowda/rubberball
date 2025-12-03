import 'package:flutter/material.dart';
import 'package:rubberball/models/player_model.dart';
import 'package:rubberball/models/match_model.dart';

class DashboardProvider with ChangeNotifier {
  // Flag to track if the provider has been disposed
  bool _isDisposed = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  MatchModel? _liveMatch;
  MatchModel? get liveMatch => _liveMatch;

  PlayerModel? _topPerformer;
  PlayerModel? get topPerformer => _topPerformer;

  DashboardProvider() {
    loadDashboardData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    // Only notify if not disposed
    if (!_isDisposed) notifyListeners();

    try {
      // Simulate Network Delay
      await Future.delayed(const Duration(seconds: 1));

      // Check for disposal AFTER the await
      if (_isDisposed) return;

      // Dummy Live Match Data
      _liveMatch = MatchModel(
        id: 'live_001',
        team1: 'Royal Strikers',
        team2: 'Gully Kings',
        winnerTeamId: '', // Ongoing
        resultDescription: '1st Innings in progress',
        matchDate: DateTime.now(),
        scoresSummary: '142/3 (14.2)',
        location: 'Central Park Ground',
      );

      // Dummy Player Data
      _topPerformer = PlayerModel(
        id: 'p_001',
        name: 'Virat Kumar',
        role: 'Batsman',
        imageUrl: '', // Add a valid URL or handle empty in UI
        stats: {
          'Runs': '450',
          'Avg': '56.2',
          'SR': '145',
        },
      );
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    } finally {
      // Final check before updating UI
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}