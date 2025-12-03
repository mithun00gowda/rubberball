class TeamModel {
  final String id;
  final String name;
  final String captainName;
  final List<String> playerNames; // Storing names for Gully cricket flexibility
  final String shortName; // e.g., 'CSK', 'MI'

  TeamModel({
    required this.id,
    required this.name,
    required this.captainName,
    required this.playerNames,
    this.shortName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'captainName': captainName,
      'playerNames': playerNames,
      'shortName': shortName,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      captainName: map['captainName'] ?? '',
      playerNames: List<String>.from(map['playerNames'] ?? []),
      shortName: map['shortName'] ?? '',
    );
  }
}