import 'package:cloud_firestore/cloud_firestore.dart';

class MatchLobbyModel {
  final String matchId;
  final String hostId;
  final String location;
  final String status;
  final String teamAName;
  final String teamBName;
  final List<LobbyPlayer> teamAPlayers;
  final List<LobbyPlayer> teamBPlayers;
  final String? captainAId;
  final String? captainBId;
  final DateTime createdAt;

  // --- New Field ---
  final DateTime lastActivityTime; // Tracks idleness

  // --- Toss Details ---
  final String? tossWinnerTeam;
  final String? tossDecision;
  final String? winner;

  // --- Rules ---
  final String matchType;
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
    required this.lastActivityTime, // Required
    this.tossWinnerTeam,
    this.tossDecision,
    this.winner,
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
      'createdAt': createdAt, // Firestore handles DateTime automatically usually, or convert to ISO
      'lastActivityTime': lastActivityTime, // Save this
      'tossWinnerTeam': tossWinnerTeam,
      'tossDecision': tossDecision,
      'winner': winner,
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
    // Helper to parse timestamps
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

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
      createdAt: parseTime(map['createdAt']),
      lastActivityTime: parseTime(map['lastActivityTime']), // Load this
      tossWinnerTeam: map['tossWinnerTeam'],
      tossDecision: map['tossDecision'],
      winner: map['winner'],
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