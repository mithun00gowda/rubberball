import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // e.g., 'Batsman', 'Bowler'
  final String jerseyNumber;
  final String teamName;
  final String profileImageUrl;

  // Career Stats
  final int matchesPlayed;
  final int totalRuns;
  final int wicketsTaken;
  final int manOfTheMatchCount;
  final DateTime? lastPlayedAt;

  // Derived Stats
  double get battingAverage {
    if (matchesPlayed == 0) return 0.0;
    return totalRuns / matchesPlayed;
  }

  String get playerLevel {
    if (matchesPlayed < 5) return "Rookie";
    if (totalRuns > 500 || wicketsTaken > 50) return "Pro";
    if (totalRuns > 200 || wicketsTaken > 20) return "Regular";
    return "Amateur";
  }

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.jerseyNumber,
    required this.teamName,
    required this.profileImageUrl,
    required this.matchesPlayed,
    required this.totalRuns,
    required this.wicketsTaken,
    required this.manOfTheMatchCount,
    this.lastPlayedAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> data, String uid) {
    DateTime? lastPlayed;
    if (data['lastPlayedAt'] != null) {
      if (data['lastPlayedAt'] is Timestamp) {
        lastPlayed = (data['lastPlayedAt'] as Timestamp).toDate();
      }
    }

    return UserProfileModel(
      id: uid,
      name: data['name'] ?? 'Unknown Player',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? 'Not set',
      role: data['role'] ?? 'All-Rounder',
      jerseyNumber: data['jerseyNumber'] ?? '--',
      teamName: data['teamName'] ?? 'Free Agent',
      profileImageUrl: data['photoUrl'] ?? '',

      matchesPlayed: data['matchesPlayed'] ?? 0,
      totalRuns: data['totalRuns'] ?? 0,
      wicketsTaken: data['wicketsTaken'] ?? 0,
      manOfTheMatchCount: data['manOfTheMatchCount'] ?? 0,
      lastPlayedAt: lastPlayed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role,
      'jerseyNumber': jerseyNumber,
      'teamName': teamName,
      'photoUrl': profileImageUrl,
    };
  }
}