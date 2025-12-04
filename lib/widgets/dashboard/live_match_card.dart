import 'package:flutter/material.dart';
import 'package:rubberball/models/match_model.dart';

class LiveMatchCard extends StatelessWidget {
  final MatchModel? match;
  final VoidCallback? onTap;

  // Real-time Data Fields
  final String? status;
  final String? battingTeamName;
  final int? runs;
  final int? wickets;
  final String? overs;
  final int? target; // If > 0, show target

  // Player Stats strings (e.g. "Virat 45(22)", "Bumrah 1-12")
  final String? strikerInfo;
  final String? bowlerInfo;

  const LiveMatchCard({
    super.key,
    this.match,
    this.onTap,
    this.status = 'LIVE',
    this.battingTeamName,
    this.runs,
    this.wickets,
    this.overs,
    this.target,
    this.strikerInfo,
    this.bowlerInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- Empty State ---
    if (match == null) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.sports_cricket, color: Colors.grey.shade300, size: 40),
                const SizedBox(height: 12),
                Text("No Matches Live", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text("Start a new match to see live scores.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    // --- Active State ---
    final isCompleted = status == 'COMPLETED';
    final badgeColor = isCompleted ? Colors.orange : Colors.redAccent;
    final badgeText = isCompleted ? "FINISHED" : "LIVE";

    // Target Text
    String targetText = "";
    if (target != null && target! > 0) {
      targetText = "Target: $target";
    } else {
      targetText = "1st Innings";
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            const Color(0xFF004D38), // Darker green for depth
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Location | Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          match!.location.toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Scoreboard
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          battingTeamName ?? match!.team1,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: (runs != null) ? "$runs" : "0",
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "/${wickets ?? 0}",
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(targetText, style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          (overs != null) ? "$overs ov" : "0.0 ov",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),

                // 3. Mini Player Stats (Striker & Bowler)
                Row(
                  children: [
                    _buildMiniStat(Icons.sports_cricket, strikerInfo ?? "Waiting..."),
                    const SizedBox(width: 16),
                    _buildMiniStat(Icons.sports_baseball, bowlerInfo ?? "Waiting..."),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}