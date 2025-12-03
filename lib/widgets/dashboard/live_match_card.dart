import 'package:flutter/material.dart';
import 'package:rubberball/models/match_model.dart';

class LiveMatchCard extends StatelessWidget {
  final MatchModel? match;

  const LiveMatchCard({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (match == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(child: Text("No Live Matches", style: theme.textTheme.bodyMedium)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to detailed Scoreboard
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeader(match!),
                const SizedBox(height: 20),
                _buildScoreRow(context, match!),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                _buildMiniStats(),
                const SizedBox(height: 16),
                _buildFooterStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MatchModel match) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            match.location.toUpperCase(), // Using location as tournament name for now
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
        ),
        Text(
          match.resultDescription,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildScoreRow(BuildContext context, MatchModel match) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Batting Team
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.team1,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    match.scoresSummary.split(' ').first, // Extract score "142/3"
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        // VS Icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: const Text("VS", style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ),
        // Bowling Team
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                match.team2,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                "Bowling",
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStats() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MatchStatusChip(label: "Rahul", value: "45*(22)", isHighlight: true),
        MatchStatusChip(label: "Amit", value: "12(8)"),
        MatchStatusChip(label: "Bowler", value: "Vikram 1/24"),
      ],
    );
  }

  Widget _buildFooterStats() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("CRR: 9.90", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("Proj: 198", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class MatchStatusChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const MatchStatusChip({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            if (isHighlight)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(Icons.sports_cricket, size: 10, color: Colors.yellowAccent),
              )
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}