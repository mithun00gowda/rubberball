import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rubberball/models/user_profile_model.dart';
import 'package:rubberball/providers/user_profile_provider.dart';
import 'package:rubberball/services/auth_service.dart';
import 'package:rubberball/screens/match_screen.dart'; // Import History Screen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Consumer<UserProfileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.user == null) {
              return const Center(child: Text("Profile data unavailable"));
            }

            final user = provider.user!;

            return RefreshIndicator(
              onRefresh: () async {
                // Trigger re-fetch logic handled by provider init
              },
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, user),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIdentitySection(context, user),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, "CAREER STATS"),
                          const SizedBox(height: 12),
                          _buildStatsGrid(context, user),
                          const SizedBox(height: 24),

                          if (user.manOfTheMatchCount > 0) ...[
                            _buildSectionTitle(context, "HIGHLIGHTS"),
                            const SizedBox(height: 12),
                            _buildHighlightsCard(context, user),
                            const SizedBox(height: 24),
                          ],

                          _buildSectionTitle(context, "PERSONAL DETAILS"),
                          const SizedBox(height: 12),
                          // Pass provider to access computed lastTeamPlayed
                          _buildInfoCard(context, user, provider),
                          const SizedBox(height: 24),

                          // History Section with View All
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle(context, "MATCH HISTORY", showBar: true),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MatchScreen())
                                  );
                                },
                                child: const Text("View All"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildMatchHistoryList(context, provider),

                          const SizedBox(height: 32),
                          _buildLogoutButton(context),

                          // --- VERSION & CREDITS ---
                          const SizedBox(height: 40),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "v1.0.0",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Design & Developed by Mithun".toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserProfileModel user) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF004D38),
                theme.primaryColor,
                const Color(0xFF008060),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(Icons.sports_cricket, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFFFD700),
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? NetworkImage(user.profileImageUrl)
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildIdentitySection(BuildContext context, UserProfileModel user) {
    return Center(
      child: Column(
        children: [
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(context, user.role, Icons.sports_cricket, Colors.blue),
              const SizedBox(width: 8),
              _buildBadge(context, user.playerLevel, Icons.star, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {bool showBar = true}) {
    return Row(
      children: [
        if (showBar) ...[
          Container(width: 4, height: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserProfileModel user) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard("Matches", "${user.matchesPlayed}", Icons.stadium, Colors.blue),
        _buildStatCard("Runs", "${user.totalRuns}", Icons.sports_cricket, Colors.green),
        _buildStatCard("Wickets", "${user.wicketsTaken}", Icons.sports_baseball, Colors.red),
        _buildStatCard("Average", user.battingAverage.toStringAsFixed(1), Icons.trending_up, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 60, color: color.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                      ),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard(BuildContext context, UserProfileModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF232526), Color(0xFF414345)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("MAN OF THE MATCH", style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${user.manOfTheMatchCount} Times",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.star, color: Color(0xFFFFD700)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserProfileModel user, UserProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Use dynamic last played team from provider
          _buildInfoRow(context, Icons.shield_outlined, "Last Team", provider.lastTeamPlayed),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(
            context,
            Icons.numbers,
            "Jersey Number",
            "#${user.jerseyNumber}",
            onEdit: () => _showEditJerseyDialog(context, provider, user.jerseyNumber),
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.email_outlined, "Email", user.email),
          const Divider(height: 1, indent: 56),
          _buildInfoRow(context, Icons.history, "Last Played",
              user.lastPlayedAt != null ? DateFormat('dd MMM yyyy').format(user.lastPlayedAt!) : "N/A"
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value, {VoidCallback? onEdit}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: onEdit != null
          ? IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: onEdit)
          : null,
    );
  }

  void _showEditJerseyDialog(BuildContext context, UserProfileProvider provider, String currentJersey) {
    final controller = TextEditingController(text: currentJersey.replaceAll('#', ''));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Jersey Number"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 3,
          decoration: const InputDecoration(labelText: "Jersey Number", prefixText: "#", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.updateJerseyNumber(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jersey updated!")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryList(BuildContext context, UserProfileProvider provider) {
    // Show only the last 5 matches
    final matches = provider.recentMatches.take(5).toList();

    if (matches.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("No recent matches found.", style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: matches.map((match) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (match['isWin'] ?? false) ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(Icons.history, color: (match['isWin'] ?? false) ? Colors.green : Colors.red),
            ),
            title: Text(match['title'] ?? "Match Played", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(match['date'] ?? "Unknown Date"),
            trailing: Text(match['result'] ?? "Played", style: TextStyle(fontWeight: FontWeight.bold, color: (match['isWin'] ?? false) ? Colors.green : Colors.red)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Provider.of<AuthService>(context, listen: false).signOut();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red.shade200),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout),
        label: const Text("LOGOUT"),
      ),
    );
  }
}