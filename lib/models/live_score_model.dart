class LiveScoreModel {
  final String matchId;

  // Score Details
  final int totalRuns;
  final int wickets;
  final int oversBowled; // Full overs
  final int ballsInCurrentOver; // 0-5 (usually)

  // Crease State
  final String strikerId;
  final String nonStrikerId;
  final String currentBowlerId;
  final String strikerName;
  final String nonStrikerName;
  final String bowlerName;

  // Recent History (for display)
  final List<String> thisOverBalls; // e.g., ['1', '4', 'W', '0']

  LiveScoreModel({
    required this.matchId,
    this.totalRuns = 0,
    this.wickets = 0,
    this.oversBowled = 0,
    this.ballsInCurrentOver = 0,
    this.strikerId = '',
    this.nonStrikerId = '',
    this.currentBowlerId = '',
    this.strikerName = 'Striker',
    this.nonStrikerName = 'Non-Striker',
    this.bowlerName = 'Bowler',
    this.thisOverBalls = const [],
  });

  LiveScoreModel copyWith({
    int? totalRuns,
    int? wickets,
    int? oversBowled,
    int? ballsInCurrentOver,
    String? strikerId,
    String? nonStrikerId,
    String? currentBowlerId,
    String? strikerName,
    String? nonStrikerName,
    String? bowlerName,
    List<String>? thisOverBalls,
  }) {
    return LiveScoreModel(
      matchId: matchId,
      totalRuns: totalRuns ?? this.totalRuns,
      wickets: wickets ?? this.wickets,
      oversBowled: oversBowled ?? this.oversBowled,
      ballsInCurrentOver: ballsInCurrentOver ?? this.ballsInCurrentOver,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      currentBowlerId: currentBowlerId ?? this.currentBowlerId,
      strikerName: strikerName ?? this.strikerName,
      nonStrikerName: nonStrikerName ?? this.nonStrikerName,
      bowlerName: bowlerName ?? this.bowlerName,
      thisOverBalls: thisOverBalls ?? this.thisOverBalls,
    );
  }
}