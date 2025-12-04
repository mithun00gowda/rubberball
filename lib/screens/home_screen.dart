import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/providers/dashboard_provider.dart';
import 'package:rubberball/screens/score_update_screen.dart';
import 'package:rubberball/widgets/dashboard/live_match_card.dart';
import 'package:rubberball/widgets/dashboard/quick_actions_grid.dart';
import 'package:rubberball/models/match_model.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/models/player_model.dart';
// Import new screens
import 'package:rubberball/screens/players/all_players_screen.dart';
import 'package:rubberball/screens/players/public_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getPlayerName(String uid, MatchLobbyModel lobby) {
    if (uid.isEmpty) return "";
    final pA = lobby.teamAPlayers.where((p) => p.uid == uid).firstOrNull;
    final pB = lobby.teamBPlayers.where((p) => p.uid == uid).firstOrNull;
    return pA?.name ?? pB?.name ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('RUBBERBALL BOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Text('Dashboard', style: TextStyle(fontSize: 16),textAlign: TextAlign.center,),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            const SizedBox(width: 8),
            const CircleAvatar(radius: 16, child: Icon(Icons.person)),
            const SizedBox(width: 16),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());

            final lobby = provider.liveMatch;
            Widget liveCard;

            if (lobby == null) {
              liveCard = const LiveMatchCard(match: null);
            } else {
              liveCard = StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('matches').doc(lobby.matchId).snapshots(),
                  builder: (context, snapshot) {
                    int runs = 0, wickets = 0, target = 0;
                    String overs = "0.0", strikerStr = "Striker", bowlerStr = "Bowler", currentBattingTeam = lobby.teamAName;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final score = data['score'] as Map<String, dynamic>?;
                      if (score != null) {
                        runs = score['runs'] ?? 0;
                        wickets = score['wickets'] ?? 0;
                        overs = "${score['overs']}.${score['balls']}";
                        final stats = score['playerStats'] as Map<String, dynamic>? ?? {};
                        target = stats['target'] ?? 0;
                        int currentInnings = stats['currentInnings'] ?? 1;

                        bool teamABatsFirst = (lobby.tossWinnerTeam == 'A' && lobby.tossDecision == 'BAT') ||
                            (lobby.tossWinnerTeam == 'B' && lobby.tossDecision == 'BOWL');
                        bool teamABattingNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);
                        currentBattingTeam = teamABattingNow ? lobby.teamAName : lobby.teamBName;

                        final sId = score['strikerId'] ?? '';
                        if (sId.isNotEmpty) {
                          final sName = _getPlayerName(sId, lobby);
                          final sStat = stats[sId];
                          strikerStr = sStat != null ? "$sName ${sStat['runs']}(${sStat['balls']})" : sName;
                        }

                        final bId = score['bowlerId'] ?? '';
                        if (bId.isNotEmpty) {
                          final bName = _getPlayerName(bId, lobby);
                          final bStat = stats[bId];
                          bowlerStr = bStat != null ? "$bName ${bStat['wickets']}-${bStat['runsConceded']}" : bName;
                        }
                      }
                    }

                    return LiveMatchCard(
                      match: MatchModel(
                        id: lobby.matchId,
                        team1: lobby.teamAName,
                        team2: lobby.teamBName,
                        winnerTeamId: '',
                        resultDescription: '',
                        matchDate: lobby.createdAt,
                        scoresSummary: '',
                        location: lobby.location,
                      ),
                      status: lobby.status,
                      battingTeamName: currentBattingTeam,
                      runs: runs,
                      wickets: wickets,
                      overs: overs,
                      target: target,
                      strikerInfo: strikerStr,
                      bowlerInfo: bowlerStr,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreUpdateScreen(matchId: lobby.matchId)));
                      },
                    );
                  }
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("LIVE ACTION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  liveCard,
                  const SizedBox(height: 30),

                  const Text("MANAGEMENT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const QuickActionsGrid(),
                  const SizedBox(height: 30),

                  // --- TOP PERFORMERS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOP PERFORMERS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AllPlayersScreen()));
                          },
                          child: const Text("View All")
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (provider.topPerformers.isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.topPerformers.length,
                        itemBuilder: (ctx, i) {
                          final player = provider.topPerformers[i];
                          return _buildTopPlayerCard(context, player, i + 1);
                        },
                      ),
                    )
                  else
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text("No data yet")))),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopPlayerCard(BuildContext context, PlayerModel player, int rank) {
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: player.id)));
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: player.imageUrl.isNotEmpty ? NetworkImage(player.imageUrl) : null,
                    child: player.imageUrl.isEmpty ? Text(player.name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
                    child: Text("#$rank", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${player.stats['Runs']} Runs", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${player.stats['Matches']} Matches", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}