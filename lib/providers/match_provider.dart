import 'package:flutter/material.dart';
import 'package:rubberball/models/match_model.dart';

class MatchesProvider with ChangeNotifier {
  // Local list acting as a cache or initial state
  List<MatchModel> _matches = [];

  // Getter to access matches in UI
  List<MatchModel> get matches => [..._matches];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Constructor simulates fetching data on initialization
  MatchesProvider() {
    fetchMatches();
  }

  // Simulating a network call or database fetch
  Future<void> fetchMatches() async {
    _isLoading = true;
    notifyListeners();

    // simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy Data - Replace this with Firebase Firestore logic later
    _matches = [
      MatchModel(
        id: '1',
        team1: 'Royal Strikers',
        team2: 'Super Kings',
        winnerTeamId: 'Royal Strikers',
        resultDescription: 'Won by 14 runs',
        matchDate: DateTime.now().subtract(const Duration(days: 1)),
        scoresSummary: '112/4 (8.0) vs 98/6 (8.0)',
        location: 'Central Park Ground',
      ),
      MatchModel(
        id: '2',
        team1: 'Thunder XI',
        team2: 'Gully Boys',
        winnerTeamId: 'Gully Boys',
        resultDescription: 'Won by 4 wickets',
        matchDate: DateTime.now().subtract(const Duration(days: 3)),
        scoresSummary: '85/9 (10.0) vs 86/6 (9.2)',
        location: 'Riverside Turf',
      ),
      MatchModel(
        id: '3',
        team1: 'Night Riders',
        team2: 'Dawn Breakers',
        winnerTeamId: 'Night Riders',
        resultDescription: 'Won by Super Over',
        matchDate: DateTime.now().subtract(const Duration(days: 7)),
        scoresSummary: 'Tied (140/5)',
        location: 'City Sports Complex',
      ),
      MatchModel(
        id: '4',
        team1: 'Spartans',
        team2: 'Titans',
        winnerTeamId: 'Titans',
        resultDescription: 'Won by 50 runs',
        matchDate: DateTime.now().subtract(const Duration(days: 10)),
        scoresSummary: '150/2 (10) vs 100/10 (8.5)',
        location: 'School Ground',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}