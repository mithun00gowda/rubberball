class MatchLobbyModel {
  final String matchId;
  final String hostId;
  final String location;
  final String status; // 'LOBBY', 'TOSS', 'LIVE', 'COMPLETED'
  final String teamAName;
  final String teamBName;
  final List<LobbyPlayer> teamAPlayers;
  final List<LobbyPlayer> teamBPlayers;
  final String? captainAId;
  final String? captainBId;
  final DateTime createdAt;

  // --- Toss & Result ---
  final String? tossWinnerTeam;
  final String? tossDecision;
  final String? winner; // NEW: Added winner field

  // --- Rules ---
  final String matchType; // 'LIMITED_OVERS', 'BOX_CRICKET'
  final bool isSingleWicketMode;
  final int totalOvers;
  final int teamSize;
  final int ballsPerOver;
  final bool rebowlWideNoBall;
  final int runsPerExtra;
  final bool isPlayerBasedOvers;
  final int oversPerPlayer;

  MatchLobbyModel({
    required this.matchId,
    required this.hostId,
    required this.location,
    this.status = 'LOBBY',
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    this.teamAPlayers = const [],
    this.teamBPlayers = const [],
    this.captainAId,
    this.captainBId,
    required this.createdAt,
    this.tossWinnerTeam,
    this.tossDecision,
    this.winner, // Add to constructor
    this.matchType = 'LIMITED_OVERS',
    this.isSingleWicketMode = false,
    required this.totalOvers,
    this.teamSize = 11,
    this.ballsPerOver = 6,
    this.rebowlWideNoBall = true,
    this.runsPerExtra = 1,
    this.isPlayerBasedOvers = false,
    this.oversPerPlayer = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'hostId': hostId,
      'location': location,
      'status': status,
      'teamAName': teamAName,
      'teamBName': teamBName,
      'teamAPlayers': teamAPlayers.map((p) => p.toMap()).toList(),
      'teamBPlayers': teamBPlayers.map((p) => p.toMap()).toList(),
      'captainAId': captainAId,
      'captainBId': captainBId,
      'createdAt': createdAt.toIso8601String(),
      'tossWinnerTeam': tossWinnerTeam,
      'tossDecision': tossDecision,
      'winner': winner, // Save to DB
      'matchType': matchType,
      'isSingleWicketMode': isSingleWicketMode,
      'totalOvers': totalOvers,
      'teamSize': teamSize,
      'ballsPerOver': ballsPerOver,
      'rebowlWideNoBall': rebowlWideNoBall,
      'runsPerExtra': runsPerExtra,
      'isPlayerBasedOvers': isPlayerBasedOvers,
      'oversPerPlayer': oversPerPlayer,
    };
  }

  factory MatchLobbyModel.fromMap(Map<String, dynamic> map) {
    return MatchLobbyModel(
      matchId: map['matchId'] ?? '',
      hostId: map['hostId'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'LOBBY',
      teamAName: map['teamAName'] ?? 'Team A',
      teamBName: map['teamBName'] ?? 'Team B',
      teamAPlayers: (map['teamAPlayers'] as List<dynamic>? ?? []).map((e) => LobbyPlayer.fromMap(e)).toList(),
      teamBPlayers: (map['teamBPlayers'] as List<dynamic>? ?? []).map((e) => LobbyPlayer.fromMap(e)).toList(),
      captainAId: map['captainAId'],
      captainBId: map['captainBId'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      tossWinnerTeam: map['tossWinnerTeam'],
      tossDecision: map['tossDecision'],
      winner: map['winner'], // Read from DB
      matchType: map['matchType'] ?? 'LIMITED_OVERS',
      isSingleWicketMode: map['isSingleWicketMode'] ?? false,
      totalOvers: map['totalOvers'] ?? 10,
      teamSize: map['teamSize'] ?? 11,
      ballsPerOver: map['ballsPerOver'] ?? 6,
      rebowlWideNoBall: map['rebowlWideNoBall'] ?? true,
      runsPerExtra: map['runsPerExtra'] ?? 1,
      isPlayerBasedOvers: map['isPlayerBasedOvers'] ?? false,
      oversPerPlayer: map['oversPerPlayer'] ?? 1,
    );
  }
}

class LobbyPlayer {
  final String uid;
  final String name;
  final String? photoUrl;

  LobbyPlayer({required this.uid, required this.name, this.photoUrl});

  Map<String, dynamic> toMap() => {'uid': uid, 'name': name, 'photoUrl': photoUrl};

  factory LobbyPlayer.fromMap(Map<String, dynamic> map) => LobbyPlayer(
    uid: map['uid'] ?? '',
    name: map['name'] ?? 'Unknown',
    photoUrl: map['photoUrl'],
  );
}