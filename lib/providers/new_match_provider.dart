import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rubberball/models/team_model.dart';
import 'package:uuid/uuid.dart'; // Add uuid to pubspec.yaml for IDs

class NewMatchProvider with ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // --- Step 1: Team Details ---
  final TextEditingController teamANameController = TextEditingController();
  final TextEditingController teamBNameController = TextEditingController();
  final TextEditingController teamACaptainController = TextEditingController();
  final TextEditingController teamBCaptainController = TextEditingController();

  // --- Step 2: Squads ---
  List<String> _teamAPlayers = [];
  List<String> _teamBPlayers = [];

  List<String> get teamAPlayers => _teamAPlayers;
  List<String> get teamBPlayers => _teamBPlayers;

  // --- Step 3: Toss ---
  bool _isTossing = false;
  String? _tossWinner; // 'Team A' or 'Team B'
  String? _decision; // 'Bat' or 'Bowl'

  bool get isTossing => _isTossing;
  String? get tossWinner => _tossWinner;
  String? get decision => _decision;

  // --- Logic ---

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // Add player to local list
  void addPlayer(String name, bool isTeamA) {
    if (name.isEmpty) return;
    if (isTeamA) {
      _teamAPlayers.add(name);
    } else {
      _teamBPlayers.add(name);
    }
    notifyListeners();
  }

  void removePlayer(int index, bool isTeamA) {
    if (isTeamA) {
      _teamAPlayers.removeAt(index);
    } else {
      _teamBPlayers.removeAt(index);
    }
    notifyListeners();
  }

  // Random Toss Logic
  Future<void> performToss() async {
    _isTossing = true;
    _tossWinner = null;
    notifyListeners();

    // Simulate animation delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    // 50-50 chance
    bool teamAWins = random.nextBool();

    _tossWinner = teamAWins ? teamANameController.text : teamBNameController.text;
    if (_tossWinner!.isEmpty) _tossWinner = teamAWins ? "Team A" : "Team B";

    _isTossing = false;
    notifyListeners();
  }

  void setDecision(String choice) {
    _decision = choice;
    notifyListeners();
  }

  // Finalize Match Data for Firebase
  Future<void> startMatch(BuildContext context) async {
    // 1. Create Team Models
    final teamA = TeamModel(
      id: const Uuid().v4(),
      name: teamANameController.text,
      captainName: teamACaptainController.text,
      playerNames: _teamAPlayers,
    );

    final teamB = TeamModel(
      id: const Uuid().v4(),
      name: teamBNameController.text,
      captainName: teamBCaptainController.text,
      playerNames: _teamBPlayers,
    );

    // 2. Create Match Object (Simulated here, would map to MatchModel)
    Map<String, dynamic> matchData = {
      'teamA': teamA.toMap(),
      'teamB': teamB.toMap(),
      'tossWinner': _tossWinner,
      'tossDecision': _decision,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'LIVE',
    };

    print("Match Started: $matchData");

    // 3. Clear controllers for next time
    _reset();

    // 4. Navigate to Scoreboard (Pop for now)
    Navigator.pop(context);
  }

  void _reset() {
    _currentStep = 0;
    teamANameController.clear();
    teamBNameController.clear();
    teamACaptainController.clear();
    teamBCaptainController.clear();
    _teamAPlayers = [];
    _teamBPlayers = [];
    _tossWinner = null;
    _decision = null;
  }
}