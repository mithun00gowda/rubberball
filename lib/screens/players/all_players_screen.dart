import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/screens/players/public_profile_screen.dart';

class AllPlayersScreen extends StatefulWidget {
  const AllPlayersScreen({super.key});

  @override
  State<AllPlayersScreen> createState() => _AllPlayersScreenState();
}

class _AllPlayersScreenState extends State<AllPlayersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Players")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search players...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('totalRuns', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final filteredDocs = docs.where((doc) {
                  final name = (doc['name'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text("No players found"));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (ctx, i) {
                    final data = filteredDocs[i].data() as Map<String, dynamic>;
                    final uid = filteredDocs[i].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (data['photoUrl'] != null && data['photoUrl'] != '')
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          child: (data['photoUrl'] == null || data['photoUrl'] == '')
                              ? Text((data['name'] ?? 'U')[0].toString().toUpperCase())
                              : null,
                        ),
                        title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['role'] ?? 'Player'} • ${data['matchesPlayed'] ?? 0} Matches"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${data['totalRuns'] ?? 0} Runs", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                            Text("${data['wicketsTaken'] ?? 0} Wkts", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: uid)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}