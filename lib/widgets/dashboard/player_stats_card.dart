import 'package:flutter/material.dart';
import 'package:rubberball/models/player_model.dart';

class PlayerStatsCard extends StatelessWidget {
  final PlayerModel? player;

  const PlayerStatsCard({super.key, this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (player == null) return const SizedBox.shrink();

    // Construct stats string safely
    final statsString = player!.stats.entries
        .map((e) => "${e.key}: ${e.value}")
        .join("  |  ");

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Player Image / Avatar
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
                    player!.name.substring(0, 1).toUpperCase(),
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
                    "PLAYER OF THE MONTH",
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
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}