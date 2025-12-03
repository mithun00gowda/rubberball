import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/providers/dashboard_provider.dart';
import 'package:rubberball/widgets/dashboard/live_match_card.dart';
import 'package:rubberball/widgets/dashboard/quick_actions_grid.dart';
import 'package:rubberball/widgets/dashboard/player_stats_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using ChangeNotifierProvider here to instantiate logic locally.
    // In a larger app, you might provide this at the MultiProvider root in main.dart.
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RUBBERBALL BOARD',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.7),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Dashboard'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Board Announcements',
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.tertiary,
              radius: 16,
              child: Text(
                'A',
                style: TextStyle(
                    color: theme.colorScheme.onTertiary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Match Section
                  _buildSectionHeader(context, "LIVE ACTION", Icons.live_tv, isLive: true),
                  const SizedBox(height: 12),
                  LiveMatchCard(match: provider.liveMatch),

                  const SizedBox(height: 30),

                  // 2. Quick Actions
                  _buildSectionHeader(context, "MANAGEMENT", Icons.grid_view),
                  const SizedBox(height: 12),
                  const QuickActionsGrid(),

                  const SizedBox(height: 30),

                  // 3. Player Stats
                  _buildSectionHeader(context, "TOP PERFORMERS", Icons.star_outline),
                  const SizedBox(height: 12),
                  PlayerStatsCard(player: provider.topPerformer),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon,
      {bool isLive = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: isLive ? Colors.redAccent : theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 1.0,
          ),
        ),
        if (isLive) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "LIVE",
              style: TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        ]
      ],
    );
  }
}