import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/models/user_profile_model.dart';
import 'package:rubberball/providers/user_profile_provider.dart';
import 'package:rubberball/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We instantiate the provider here to manage the profile data lifecycle for this screen
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
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
              onRefresh: () => provider.fetchUserProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context, user),
                    _buildStatsSection(context, user),
                    const SizedBox(height: 16),
                    _buildInfoSection(context, user),
                    const SizedBox(height: 24),
                    _buildSettingsSection(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfileModel user) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Green Background
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    // TODO: Implement Edit Profile Page
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Edit Profile',
                ),
              ),
            ),
          ),
        ),

        // Avatar & Name
        Positioned(
          bottom: -60,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.tertiary,
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? NetworkImage(user.profileImageUrl)
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? Text(
                    user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onTertiary,
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${user.role}  •  #${user.jerseyNumber}",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, UserProfileModel user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "CAREER STATISTICS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, "Matches", user.matchesPlayed.toString()),
                  _buildVerticalDivider(),
                  _buildStatItem(context, "Runs", user.totalRuns.toString()),
                  _buildVerticalDivider(),
                  _buildStatItem(context, "Wickets", user.wicketsTaken.toString()),
                  _buildVerticalDivider(),
                  _buildStatItem(context, "Avg", user.battingAverage.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, UserProfileModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _buildListTile(
              context,
              icon: Icons.groups_outlined,
              title: "Current Team",
              value: user.teamName,
              showDivider: true,
            ),
            _buildListTile(
              context,
              icon: Icons.email_outlined,
              title: "Email",
              value: user.email,
              showDivider: true,
            ),
            _buildListTile(
              context,
              icon: Icons.phone_outlined,
              title: "Phone",
              value: user.phoneNumber,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    // Access AuthService from the main tree to handle logout cleanly
    final authService = Provider.of<AuthService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              "SETTINGS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.0,
                fontSize: 12,
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildActionTile(context, Icons.settings_outlined, "App Settings"),
                const Divider(height: 1, indent: 56),
                _buildActionTile(context, Icons.help_outline, "Help & Support"),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  context,
                  Icons.logout,
                  "Logout",
                  isDestructive: true,
                  onTap: () async {
                    // Call signOut from AuthService
                    await authService.signOut();
                    // AuthWrapper will handle the redirection to login
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required String value, required bool showDivider}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade500, size: 22),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 54),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}