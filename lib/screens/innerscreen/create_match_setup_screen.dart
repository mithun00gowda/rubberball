import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/providers/match_lobby_provider.dart';
import 'match_lobby_screen.dart';

class CreateMatchSetupScreen extends StatefulWidget {
  const CreateMatchSetupScreen({super.key});

  @override
  State<CreateMatchSetupScreen> createState() => _CreateMatchSetupScreenState();
}

class _CreateMatchSetupScreenState extends State<CreateMatchSetupScreen> {
  final _locationCtrl = TextEditingController();
  final _teamANameCtrl = TextEditingController();
  final _teamBNameCtrl = TextEditingController();

  // PRIMARY MODE SELECTION
  bool _isSingleWicketMode = false; // False = Standard, True = Single Wicket/1v1

  // Rules
  int _overs = 10;
  int _teamSize = 11;
  String _matchType = 'LIMITED_OVERS';
  int _ballsPerOver = 6;
  bool _rebowlWideNoBall = true;
  int _runsPerExtra = 1;

  // Dynamic Rule (Defaults to true for Single Wicket)
  bool _isPlayerBasedOvers = false;
  int _oversPerPlayer = 1;

  bool _isLoading = false;

  void _toggleGameMode(bool isSingleWicket) {
    setState(() {
      _isSingleWicketMode = isSingleWicket;
      if (isSingleWicket) {
        // Auto-configure for Single Wicket / 1v1 style
        _isPlayerBasedOvers = true;
        _oversPerPlayer = 2; // Usually 2 overs per person in 1v1
        _teamSize = 1; // Start with 1v1 expectation
        _rebowlWideNoBall = false; // Box cricket style default
      } else {
        // Reset to Standard
        _isPlayerBasedOvers = false;
        _teamSize = 11;
        _rebowlWideNoBall = true;
      }
    });
  }

  void _createMatch() async {
    if (_locationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a location")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<MatchLobbyProvider>(context, listen: false);

      final matchId = await provider.createMatchShell(
        location: _locationCtrl.text,
        teamAName: _teamANameCtrl.text.trim(),
        teamBName: _teamBNameCtrl.text.trim(),
        overs: _overs,
        matchType: _matchType,
        isSingleWicketMode: _isSingleWicketMode, // Pass the mode
        teamSize: _teamSize,
        ballsPerOver: _ballsPerOver,
        rebowlWideNoBall: _rebowlWideNoBall,
        runsPerExtra: _runsPerExtra,
        isPlayerBasedOvers: _isPlayerBasedOvers,
        oversPerPlayer: _oversPerPlayer,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MatchLobbyScreen(matchId: matchId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Setup Match")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GAME MODE SELECTION ---
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: "Team Match",
                      subLabel: "11v11, 5v5 etc.",
                      icon: Icons.groups,
                      isSelected: !_isSingleWicketMode,
                      onTap: () => _toggleGameMode(false),
                    ),
                  ),
                  Expanded(
                    child: _ModeButton(
                      label: "Single Wicket",
                      subLabel: "1v1, 2v2 (No Non-striker)",
                      icon: Icons.person,
                      isSelected: _isSingleWicketMode,
                      onTap: () => _toggleGameMode(true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Venue ---
            const Text("VENUE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: "E.g. Central Park / Gully No. 4",
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. Teams ---
            const Text("TEAMS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamANameCtrl,
                    decoration: InputDecoration(
                      labelText: "Home Team",
                      hintText: "Team A",
                      prefixIcon: const Icon(Icons.shield_outlined, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("VS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(
                  child: TextField(
                    controller: _teamBNameCtrl,
                    decoration: InputDecoration(
                      labelText: "Away Team",
                      hintText: "Team B",
                      prefixIcon: const Icon(Icons.shield_outlined, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.red.shade50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 4. Overs Config ---
            if (!_isSingleWicketMode)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Person Based Overs (Dynamic)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Total overs increase as players join"),
                value: _isPlayerBasedOvers,
                activeColor: theme.primaryColor,
                onChanged: (val) => setState(() => _isPlayerBasedOvers = val),
              )
            else
            // For Single Wicket, force display as info
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Dynamic Overs enabled for Single Wicket", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                ]),
              ),

            Row(
              children: [
                Expanded(
                  child: _CounterCard(
                    label: _isPlayerBasedOvers ? "OVERS PER PLAYER" : "TOTAL OVERS",
                    value: _isPlayerBasedOvers ? _oversPerPlayer : _overs,
                    onChanged: (val) => setState(() {
                      if (_isPlayerBasedOvers) {
                        _oversPerPlayer = val;
                      } else {
                        _overs = val;
                      }
                    }),
                    min: 1,
                    max: 50,
                  ),
                ),
                const SizedBox(width: 16),
                if (!_isSingleWicketMode)
                  Expanded(
                    child: _CounterCard(
                      label: "PLAYERS (Limit)",
                      value: _teamSize,
                      onChanged: (val) => setState(() => _teamSize = val),
                      min: 1,
                      max: 15,
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      height: 100, // Match height
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("PLAYERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text("Unlimited", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("(Join anytime)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // --- 5. Gully Rules ---
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text("Advanced / Gully Rules", style: TextStyle(fontWeight: FontWeight.bold)),
                tilePadding: EdgeInsets.zero,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Balls per Over"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [4, 5, 6, 8].map((val) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ChoiceChip(
                            label: Text("$val"),
                            selected: _ballsPerOver == val,
                            onSelected: (b) => setState(() => _ballsPerOver = val),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Re-bowl Wide/No Ball?"),
                    value: _rebowlWideNoBall,
                    activeColor: theme.primaryColor,
                    onChanged: (val) => setState(() => _rebowlWideNoBall = val),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Runs per Wide/NB"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => setState(() {
                            if (_runsPerExtra > 0) _runsPerExtra--;
                          }),
                        ),
                        Text("$_runsPerExtra", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _runsPerExtra++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _createMatch,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code),
                    SizedBox(width: 12),
                    Text("CREATE MATCH LOBBY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(subLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;
  final int min;
  final int max;

  const _CounterCard({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () { if (value > min) onChanged(value - 1); },
                child: const Icon(Icons.remove_circle, color: Colors.grey),
              ),
              Text("$value", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () { if (value < max) onChanged(value + 1); },
                child: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}