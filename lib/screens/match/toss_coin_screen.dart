import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/providers/match_lobby_provider.dart';
import 'package:rubberball/services/auth_service.dart';
import 'package:rubberball/screens/score_update_screen.dart';

class TossCoinScreen extends StatefulWidget {
  final MatchLobbyModel match;
  const TossCoinScreen({super.key, required this.match});

  @override
  State<TossCoinScreen> createState() => _TossCoinScreenState();
}

class _TossCoinScreenState extends State<TossCoinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isFlipping = false;
  // We no longer store local state for winner/decision to ensure sync.
  // We rely on the Stream data from Firebase.

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isFlipping = false);
        _calculateWinnerAndSave();
      }
    });
  }

  void _flipCoin() {
    // Only start animation visually
    setState(() => _isFlipping = true);
    _controller.reset();
    _controller.forward();
  }

  void _calculateWinnerAndSave() {
    // Determine winner locally then save to Cloud
    final random = Random();
    final isTeamA = random.nextBool();
    final winner = isTeamA ? 'A' : 'B';

    Provider.of<MatchLobbyProvider>(context, listen: false)
        .saveTossWinner(widget.match.matchId, winner);
  }

  void _saveDecision(String decision) {
    // decision is 'BAT' or 'BOWL'
    // We don't save immediately to DB for decision until 'Let's Play' is clicked?
    // Or we can save specific field. The previous provider method 'startMatch' saves decision AND sets status to LIVE.
    // Let's keep local decision state until we confirm start.
  }

  // Local state for decision before confirming start
  String? _localDecision;

  void _startGame() async {
    if (_localDecision == null) return;
    try {
      await Provider.of<MatchLobbyProvider>(context, listen: false)
          .startMatch(widget.match.matchId, _localDecision!);
      // Navigation happens automatically via the Stream listener below
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lobbyProvider = Provider.of<MatchLobbyProvider>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final isHost = widget.match.hostId == currentUser?.uid;

    return StreamBuilder<MatchLobbyModel>(
      stream: lobbyProvider.matchStream(widget.match.matchId),
      builder: (context, snapshot) {
        // Use the latest data from stream, or fallback to widget.match
        final matchData = snapshot.data ?? widget.match;

        // Auto-navigate if match goes LIVE
        if (matchData.status == 'LIVE') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) =>  ScoreUpdateScreen(matchId: matchData.matchId,)),
            );
          });
        }

        final tossWinnerTeam = matchData.tossWinnerTeam;
        final winnerName = tossWinnerTeam == 'A' ? matchData.teamAName : matchData.teamBName;

        return Scaffold(
          backgroundColor: theme.primaryColor,
          appBar: AppBar(
            title: const Text("Toss Time", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false, // Prevent going back
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Coin Animation ---
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    // If toss is done (tossWinnerTeam exists), show static result
                    // If flipping, show animation
                    // If waiting, show Question Mark

                    final isDone = tossWinnerTeam != null;
                    final showResult = isDone && !_isFlipping;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_animation.value),
                      alignment: Alignment.center,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.shade400,
                          border: Border.all(color: Colors.amber.shade700, width: 8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isFlipping
                                ? "?"
                                : (showResult
                                ? (tossWinnerTeam == 'A' ? "HEADS" : "TAILS")
                                : "TOSS"),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 50),

                // --- 1. PRE-TOSS STATE ---
                if (tossWinnerTeam == null && !_isFlipping)
                  if (isHost)
                    ElevatedButton.icon(
                      onPressed: _flipCoin,
                      icon: const Icon(Icons.rotate_right),
                      label: const Text("FLIP COIN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    )
                  else
                    const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text("Waiting for Host to flip...", style: TextStyle(color: Colors.white70, fontSize: 18)),
                      ],
                    ),

                // --- 2. FLIPPING STATE ---
                if (_isFlipping)
                  const Text("Flipping...", style: TextStyle(color: Colors.white70, fontSize: 18)),

                // --- 3. POST-TOSS STATE (Winner Declared) ---
                if (tossWinnerTeam != null && !_isFlipping) ...[
                  Text(
                    "$winnerName WON THE TOSS",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Only Host sees controls
                  if (isHost) ...[
                    const Text("Elected to:", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DecisionButton(
                          label: "BAT",
                          icon: Icons.sports_cricket,
                          isSelected: _localDecision == 'BAT',
                          onTap: () => setState(() => _localDecision = 'BAT'),
                        ),
                        const SizedBox(width: 20),
                        _DecisionButton(
                          label: "BOWL",
                          icon: Icons.sports_baseball,
                          isSelected: _localDecision == 'BOWL',
                          onTap: () => setState(() => _localDecision = 'BOWL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (_localDecision != null)
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        ),
                        child: const Text("LET'S PLAY!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                  ] else ...[
                    // Players View
                    const SizedBox(height: 16),
                    const Text("Waiting for Host's decision...", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ]
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DecisionButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.greenAccent, width: 3) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}