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

  // Basic Settings
  int _overs = 10;
  int _teamSize = 11;
  String _matchType = 'LIMITED_OVERS';

  // Advanced Gully Rules
  int _ballsPerOver = 6;
  bool _rebowlWideNoBall = true;
  int _runsPerExtra = 1;

  // New Dynamic Rule
  bool _isPlayerBasedOvers = false;
  int _oversPerPlayer = 1;

  bool _isLoading = false;

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
        teamAName: _teamANameCtrl.text.trim(), // Pass custom name
        teamBName: _teamBNameCtrl.text.trim(), // Pass custom name
        overs: _overs,
        matchType: _matchType,
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
      appBar: AppBar(title: const Text("Match Configuration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Venue ---
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

            // --- Section 2: Team Names (NEW) ---
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

            // --- Section 3: Match Type ---
            const Text("FORMAT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeChip(
                    label: "Limited Overs",
                    icon: Icons.sports_cricket,
                    isSelected: _matchType == 'LIMITED_OVERS',
                    onTap: () => setState(() {
                      _matchType = 'LIMITED_OVERS';
                      _ballsPerOver = 6;
                      _rebowlWideNoBall = true;
                    }),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: "Box Cricket",
                    icon: Icons.inbox,
                    isSelected: _matchType == 'BOX_CRICKET',
                    onTap: () => setState(() {
                      _matchType = 'BOX_CRICKET';
                      _ballsPerOver = 5;
                      _rebowlWideNoBall = false;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Section 4: Overs Logic ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Person Based Overs (Dynamic)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Total overs increase as players join"),
              value: _isPlayerBasedOvers,
              activeColor: theme.primaryColor,
              onChanged: (val) => setState(() => _isPlayerBasedOvers = val),
            ),

            const SizedBox(height: 12),

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
                Expanded(
                  child: _CounterCard(
                    label: "PLAYERS (Per Team)",
                    value: _teamSize,
                    onChanged: (val) => setState(() => _teamSize = val),
                    min: 1,
                    max: 15,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // --- Section 5: Advanced Rules ---
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text("Advanced / Gully Rules", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Balls per over, Extras logic, etc."),
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

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
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