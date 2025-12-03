class MatchModel {
  final String id;
  final String team1;
  final String team2;
  final String winnerTeamId;
  final String resultDescription; // e.g., "Won by 24 runs"
  final DateTime matchDate;
  final String scoresSummary; // e.g., "156/4 (10) vs 132/8 (10)"
  final String location;

  MatchModel({
    required this.id,
    required this.team1,
    required this.team2,
    required this.winnerTeamId,
    required this.resultDescription,
    required this.matchDate,
    required this.scoresSummary,
    required this.location,
  });

  // Factory constructor for creating a new MatchModel from a map (e.g., from Firebase)
  factory MatchModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MatchModel(
      id: documentId,
      team1: map['team1'] ?? '',
      team2: map['team2'] ?? '',
      winnerTeamId: map['winnerTeamId'] ?? '',
      resultDescription: map['resultDescription'] ?? '',
      matchDate: DateTime.parse(map['matchDate'] ?? DateTime.now().toIso8601String()),
      scoresSummary: map['scoresSummary'] ?? '',
      location: map['location'] ?? 'Unknown Ground',
    );
  }

  // Method to convert MatchModel to a map (e.g., for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'team1': team1,
      'team2': team2,
      'winnerTeamId': winnerTeamId,
      'resultDescription': resultDescription,
      'matchDate': matchDate.toIso8601String(),
      'scoresSummary': scoresSummary,
      'location': location,
    };
  }
}