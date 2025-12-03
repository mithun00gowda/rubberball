class MatchScoreModel {
  final int runs;
  final int wickets;
  final int overs;
  final int balls; // 0-5 (or more if gully rules)
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  final List<String> recentBalls; // e.g. ["1", "4", "W"]

  // Maps to store individual performance during this match
  // Key: PlayerUID, Value: Map of stats
  final Map<String, dynamic> playerStats;

  MatchScoreModel({
    this.runs = 0,
    this.wickets = 0,
    this.overs = 0,
    this.balls = 0,
    this.strikerId = '',
    this.nonStrikerId = '',
    this.bowlerId = '',
    this.recentBalls = const [],
    this.playerStats = const {},
  });

  factory MatchScoreModel.fromMap(Map<String, dynamic> map) {
    return MatchScoreModel(
      runs: map['runs'] ?? 0,
      wickets: map['wickets'] ?? 0,
      overs: map['overs'] ?? 0,
      balls: map['balls'] ?? 0,
      strikerId: map['strikerId'] ?? '',
      nonStrikerId: map['nonStrikerId'] ?? '',
      bowlerId: map['bowlerId'] ?? '',
      recentBalls: List<String>.from(map['recentBalls'] ?? []),
      playerStats: Map<String, dynamic>.from(map['playerStats'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
      'balls': balls,
      'strikerId': strikerId,
      'nonStrikerId': nonStrikerId,
      'bowlerId': bowlerId,
      'recentBalls': recentBalls,
      'playerStats': playerStats,
    };
  }
}