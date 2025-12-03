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

  // Derived Stat
  double get battingAverage {
    if (matchesPlayed == 0) return 0.0;
    return totalRuns / matchesPlayed; // Simplified average logic
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
  });

  // Factory to create from Firestore DocumentSnapshot
  factory UserProfileModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfileModel(
      id: uid,
      name: data['name'] ?? 'Unknown Player',
      email: data['email'] ?? '',
      // Fields that might not be in auth initially
      phoneNumber: data['phoneNumber'] ?? 'Not set',
      role: data['role'] ?? 'Player',
      jerseyNumber: data['jerseyNumber'] ?? '--',
      teamName: data['teamName'] ?? 'Free Agent',
      profileImageUrl: data['photoUrl'] ?? '', // Note: AuthService saves as 'photoUrl'

      // Stats
      matchesPlayed: data['matchesPlayed'] ?? 0,
      totalRuns: data['totalRuns'] ?? 0,
      wicketsTaken: data['wicketsTaken'] ?? 0,
      manOfTheMatchCount: data['manOfTheMatchCount'] ?? 0,
    );
  }

  // To save updates back to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role,
      'jerseyNumber': jerseyNumber,
      'teamName': teamName,
      'photoUrl': profileImageUrl,
      // Stats are usually updated via separate match logic, not profile edit
    };
  }
}