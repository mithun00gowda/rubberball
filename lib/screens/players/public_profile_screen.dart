import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/models/user_profile_model.dart';
// Reuse widgets if you extracted them, or rebuild them here for standalone viewing.
// For simplicity, I'll rebuild simple versions here to avoid circular dependencies if you didn't extract widgets.

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Player not found"));

          final user = UserProfileModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, userId);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                              child: Text(user.role, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("CAREER STATS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildStatsGrid(context, user),
                      const SizedBox(height: 24),
                      if (user.manOfTheMatchCount > 0) ...[
                        const Text("ACHIEVEMENTS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.black87, Colors.black54]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("MAN OF THE MATCH", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                                  Text("${user.manOfTheMatchCount} Times", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserProfileModel user) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF004D38), Theme.of(context).primaryColor])),
          child: Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
              child: user.profileImageUrl.isEmpty ? Text(user.name[0], style: const TextStyle(fontSize: 40)) : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserProfileModel user) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard("Matches", "${user.matchesPlayed}", Icons.stadium, Colors.blue),
        _statCard("Runs", "${user.totalRuns}", Icons.sports_cricket, Colors.green),
        _statCard("Wickets", "${user.wicketsTaken}", Icons.sports_baseball, Colors.red),
        _statCard("Average", user.battingAverage.toStringAsFixed(1), Icons.trending_up, Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}