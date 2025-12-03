import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/providers/match_lobby_provider.dart';
import 'package:rubberball/services/auth_service.dart';
import 'package:rubberball/screens/match/toss_coin_screen.dart'; // Import Toss Screen

class MatchLobbyScreen extends StatelessWidget {
  final String matchId;

  const MatchLobbyScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    final lobbyProvider = Provider.of<MatchLobbyProvider>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;

    return StreamBuilder<MatchLobbyModel>(
      stream: lobbyProvider.matchStream(matchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final match = snapshot.data!;
        final isHost = match.hostId == currentUser?.uid;

        // Redirect if status changes to TOSS
        if (match.status == 'TOSS') {
          // Use addPostFrameCallback to navigate after the build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check if we are already on the toss screen to avoid loop (simple check)
            // But since we use pushReplacement, this widget is disposed, stopping the stream listener.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TossCoinScreen(match: match)),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Match Lobby"),
            actions: [
              if (isHost)
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text("START TOSS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: (match.captainAId != null && match.captainBId != null)
                      ? () => lobbyProvider.proceedToToss(matchId)
                      : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please assign both captains first (Long press player)"))
                    );
                  },
                )
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // --- QR Code Section ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: matchId, // Simple string match ID is enough
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Scan to Join Team",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Text("ID: ${matchId.substring(0, 4)}...", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Team Lists ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TEAM A
                      Expanded(
                        child: _TeamListWidget(
                          teamName: match.teamAName,
                          players: match.teamAPlayers,
                          captainId: match.captainAId,
                          isHost: isHost,
                          color: Colors.blue.shade50,
                          headerColor: Colors.blue,
                          onAssignCaptain: (pid) => lobbyProvider.assignCaptain(matchId, 'A', pid),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // TEAM B
                      Expanded(
                        child: _TeamListWidget(
                          teamName: match.teamBName,
                          players: match.teamBPlayers,
                          captainId: match.captainBId,
                          isHost: isHost,
                          color: Colors.red.shade50,
                          headerColor: Colors.red,
                          onAssignCaptain: (pid) => lobbyProvider.assignCaptain(matchId, 'B', pid),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeamListWidget extends StatelessWidget {
  final String teamName;
  final List<LobbyPlayer> players;
  final String? captainId;
  final bool isHost;
  final Color color;
  final Color headerColor;
  final Function(String) onAssignCaptain;

  const _TeamListWidget({
    required this.teamName,
    required this.players,
    this.captainId,
    required this.isHost,
    required this.color,
    required this.headerColor,
    required this.onAssignCaptain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: headerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              "$teamName (${players.length})",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final player = players[index];
              final isCaptain = player.uid == captainId;

              return InkWell(
                onLongPress: isHost
                    ? () => onAssignCaptain(player.uid)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isCaptain ? Border.all(color: Colors.orange, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
                        child: player.photoUrl == null ? Text(player.name[0]) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isCaptain)
                              const Text("CAPTAIN", style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (players.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Waiting for players...", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}