class PlayerModel {
  final String id;
  final String name;
  final String role; // e.g., Batsman, Bowler, All-Rounder
  final String imageUrl;
  final Map<String, String> stats; // e.g., {'Runs': '450', 'Avg': '56.2'}

  PlayerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.stats,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Player',
      role: json['role'] ?? 'Player',
      imageUrl: json['imageUrl'] ?? '',
      stats: Map<String, String>.from(json['stats'] ?? {}),
    );
  }
}