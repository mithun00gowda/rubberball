import 'package:flutter/material.dart';
import 'package:rubberball/screens/score_update_screen.dart';
import '../../screens/innerscreen/create_match_setup_screen.dart';
import '../../screens/innerscreen/scanner_join_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  // Function to show options when "New Match" is clicked
  void _showMatchOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Allows sheet to resize with keyboard or content
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Start Playing",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              // Option 1: Host
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle, color: Colors.blue),
                ),
                title: const Text("Host a Match", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Create a lobby and generate QR code"),
                onTap: () {
                  Navigator.pop(ctx); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateMatchSetupScreen()),
                  );
                },
              ),
              const Divider(),
              // Option 2: Join
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.orange),
                ),
                title: const Text("Join Match", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Scan Host's QR code to join a team"),
                onTap: () {
                  Navigator.pop(ctx); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JoinMatchQRScanner()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Dynamic Aspect Ratio Logic ---
    // 1. Get total screen width
    var screenWidth = MediaQuery.of(context).size.width;

    // 2. Account for padding (16px left + 16px right + 12px crossAxisSpacing)
    // Adjust this based on your actual parent padding. Assuming standard 16.
    var availableWidth = screenWidth - (16 * 2) - 12;

    // 3. Calculate width of a single item
    var itemWidth = availableWidth / 2;

    // 4. Define the fixed height we NEED for the content (Icon + Text + Padding)
    // 110px is usually safe for this card design
    var requiredHeight = 110.0;

    // 5. Calculate ratio: width / height
    var dynamicAspectRatio = itemWidth / requiredHeight;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: dynamicAspectRatio, // Use the calculated ratio
      children: [
        _buildActionCard(
          context,
          title: "New Match",
          icon: Icons.sports_cricket,
          color: Theme.of(context).primaryColor,
          isPrimary: true,
          onTap: () => _showMatchOptions(context),
        ),
        _buildActionCard(
          context,
          title: "Live Scoring",
          icon: Icons.scoreboard,
          color: Colors.redAccent,
          onTap: () {
            // Navigator.push(
            //   context,
            //   // MaterialPageRoute(builder: (context) => const ScoreUpdateScreen(matchId: matchId)),
            // );
          },
        ),
        _buildActionCard(
          context,
          title: "Tournaments",
          icon: Icons.emoji_events_outlined,
          color: Colors.purple.shade700,
          onTap: () {},
        ),
        _buildActionCard(
          context,
          title: "Statistics",
          icon: Icons.bar_chart,
          color: Colors.blue.shade700,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
        bool isPrimary = false}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPrimary ? color : Colors.grey.shade200,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              // Use Flexible to handle long text on small screens
              Flexible(
                child: Text(
                  title,
                  maxLines: 2, // Allow 2 lines if needed
                  overflow: TextOverflow.ellipsis, // Add dots if still too long
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    height: 1.1, // Tighter line height prevents overflow
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}