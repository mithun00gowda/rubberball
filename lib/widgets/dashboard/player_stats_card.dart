import 'package:flutter/material.dart';
import 'package:rubberball/models/player_model.dart';

class PlayerStatsCard extends StatelessWidget {
  final PlayerModel? player;

  const PlayerStatsCard({super.key, this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- Empty State ---
    if (player == null) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("No Top Performer Yet", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Play matches to see stats here", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // --- Active State ---
    final statsString = player!.stats.entries
        .map((e) => "${e.key}: ${e.value}")
        .join("  |  ");

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
                image: player!.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(player!.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: player!.imageUrl.isEmpty
                  ? Center(
                child: Text(
                    player!.name.isNotEmpty ? player!.name[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 24)
                ),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MOST RUNS (ALL TIME)",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statsString,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.emoji_events, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}