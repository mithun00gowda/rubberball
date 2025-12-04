import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/providers/dashboard_provider.dart';
import 'package:rubberball/screens/score_update_screen.dart';
import 'package:rubberball/screens/match_screen.dart'; // Import History Screen
import '../../screens/innerscreen/create_match_setup_screen.dart';
import '../../screens/innerscreen/scanner_join_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  void _showMatchOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Start Playing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue),
                title: const Text("Host a Match"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateMatchSetupScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.orange),
                title: const Text("Join Match"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinMatchQRScanner()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLiveScoringTap(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final match = provider.liveMatch;

    if (match != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreUpdateScreen(matchId: match.matchId)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No live match found."), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var availableWidth = screenWidth - (16 * 2) - 12;
    var dynamicAspectRatio = (availableWidth / 2) / 110.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: dynamicAspectRatio,
      children: [
        _buildActionCard(context, title: "New Match", icon: Icons.sports_cricket, color: Theme.of(context).primaryColor, isPrimary: true, onTap: () => _showMatchOptions(context)),
        _buildActionCard(context, title: "Live Scoring", icon: Icons.scoreboard, color: Colors.redAccent, onTap: () => _handleLiveScoringTap(context)),
        _buildActionCard(context, title: "Tournaments", icon: Icons.emoji_events_outlined, color: Colors.purple.shade700, onTap: () {}),

        // Linked History
        _buildActionCard(context, title: "History", icon: Icons.history, color: Colors.blue.shade700, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchScreen()));
        }),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap, bool isPrimary = false}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isPrimary ? color : Colors.grey.shade200)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            ],
          ),
        ),
      ),
    );
  }
}