import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/models/match_model.dart';
import '../providers/match_provider.dart';
import 'match/match_detail_screen.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchesProvider(), // Init stream
      child: Scaffold(
        appBar: AppBar(title: const Text('Match History')),
        body: Consumer<MatchesProvider>(
          builder: (context, matchesData, child) {
            if (matchesData.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (matchesData.matches.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: matchesData.matches.length,
              itemBuilder: (ctx, i) => MatchSummaryCard(match: matchesData.matches[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No history found!', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

class MatchSummaryCard extends StatelessWidget {
  final MatchModel match;
  const MatchSummaryCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = "${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}";

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailScreen(matchId: match.id)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(match.location.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Text(dateStr, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.team1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("VS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                        const SizedBox(height: 4),
                        Text(match.team2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.primaryColor.withOpacity(0.1))),
                    child: Text(match.scoresSummary, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 18, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Flexible(child: Text('${match.winnerTeamId} Won', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}