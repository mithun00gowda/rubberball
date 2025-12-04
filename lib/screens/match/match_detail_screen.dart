import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:intl/intl.dart';

class MatchDetailScreen extends StatelessWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Match data not found")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final lobby = MatchLobbyModel.fromMap(data);
        final score = data['score'] as Map<String, dynamic>? ?? {};
        final playerStats = score['playerStats'] as Map<String, dynamic>? ?? {};

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text("Match Scorecard"),
              elevation: 0,
              backgroundColor: Theme.of(context).primaryColor,
              bottom: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: lobby.teamAName),
                  Tab(text: lobby.teamBName),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildMatchHeader(lobby, data),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Team A Batting / Team B Bowling
                      _TeamScorecardView(
                        battingTeamName: lobby.teamAName,
                        battingPlayers: lobby.teamAPlayers,
                        bowlingPlayers: lobby.teamBPlayers,
                        stats: playerStats,
                      ),
                      // Tab 2: Team B Batting / Team A Bowling
                      _TeamScorecardView(
                        battingTeamName: lobby.teamBName,
                        battingPlayers: lobby.teamBPlayers,
                        bowlingPlayers: lobby.teamAPlayers,
                        stats: playerStats,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchHeader(MatchLobbyModel match, Map<String, dynamic> data) {
    String winnerText = "Match Drawn";
    Color resultColor = Colors.grey;

    if (data['winner'] == 'A') {
      winnerText = "${match.teamAName} Won";
      resultColor = Colors.green;
    } else if (data['winner'] == 'B') {
      winnerText = "${match.teamBName} Won";
      resultColor = Colors.green;
    }

    final date = match.createdAt;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(match.location, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            winnerText.toUpperCase(),
            style: TextStyle(color: resultColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          if (match.tossWinnerTeam != null)
            Text(
              "Toss: ${match.tossWinnerTeam == 'A' ? match.teamAName : match.teamBName} chose to ${match.tossDecision}",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _TeamScorecardView extends StatelessWidget {
  final String battingTeamName;
  final List<LobbyPlayer> battingPlayers;
  final List<LobbyPlayer> bowlingPlayers;
  final Map<String, dynamic> stats;

  const _TeamScorecardView({
    required this.battingTeamName,
    required this.battingPlayers,
    required this.bowlingPlayers,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filter Batters
    final activeBatters = battingPlayers.where((p) {
      final pStat = stats[p.uid] as Map<String, dynamic>?;
      // Show if they have runs OR faced balls
      return pStat != null && (pStat.containsKey('runs') || pStat.containsKey('balls'));
    }).toList();

    // 2. Filter Bowlers
    final activeBowlers = bowlingPlayers.where((p) {
      final pStat = stats[p.uid] as Map<String, dynamic>?;
      // Show if they bowled any balls
      return pStat != null && (pStat.containsKey('ballsBowled') && pStat['ballsBowled'] > 0);
    }).toList();

    // 3. Calculate Team Total (Sum of individual runs)
    // Note: This excludes extras unless we stored extras separately in the score map.
    // For this view, summing player runs is a good approximation.
    int totalRuns = 0;
    int totalBallsFaced = 0;
    for (var p in activeBatters) {
      final s = stats[p.uid];
      totalRuns += (s['runs'] as int? ?? 0);
      totalBallsFaced += (s['balls'] as int? ?? 0);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BATTING TABLE ---
          _buildSectionHeader("BATTING"),
          Container(
            color: Colors.white,
            width: double.infinity,
            child: DataTable(
              columnSpacing: 12,
              headingRowHeight: 40,
              dataRowHeight: 48,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Expanded(child: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
              ],
              rows: activeBatters.map((p) {
                final s = stats[p.uid];
                final r = s['runs'] ?? 0;
                final b = s['balls'] ?? 0;
                final fours = s['4s'] ?? 0;
                final sixes = s['6s'] ?? 0;
                final sr = b > 0 ? ((r / b) * 100).toStringAsFixed(1) : "0.0";

                return DataRow(cells: [
                  DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text('$r', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('$b')),
                  DataCell(Text('$fours')),
                  DataCell(Text('$sixes')),
                  DataCell(Text(sr)),
                ]);
              }).toList(),
            ),
          ),

          // Total Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Score", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "$totalRuns ($totalBallsFaced balls)",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- BOWLING TABLE ---
          _buildSectionHeader("BOWLING"),
          Container(
            color: Colors.white,
            width: double.infinity,
            child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 40,
              dataRowHeight: 48,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Expanded(child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                DataColumn(label: Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                DataColumn(label: Text('ECO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
              ],
              rows: activeBowlers.map((p) {
                final s = stats[p.uid];
                final balls = s['ballsBowled'] ?? 0;
                final runs = s['runsConceded'] ?? 0;
                final wkts = s['wickets'] ?? 0;

                final overs = "${(balls / 6).floor()}.${balls % 6}";
                final eco = balls > 0 ? ((runs / balls) * 6).toStringAsFixed(1) : "0.0";

                return DataRow(cells: [
                  DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text(overs)),
                  DataCell(Text('$runs')),
                  DataCell(Text('$wkts', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(eco)),
                ]);
              }).toList(),
            ),
          ),

          if (activeBatters.isEmpty && activeBowlers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("No data for this innings", style: TextStyle(color: Colors.grey))),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFE0E0E0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }
}