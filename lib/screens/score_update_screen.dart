import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/providers/scoring_provider.dart';

class ScoreUpdateScreen extends StatefulWidget {
  final String matchId;

  const ScoreUpdateScreen({super.key, required this.matchId});

  @override
  State<ScoreUpdateScreen> createState() => _ScoreUpdateScreenState();
}

class _ScoreUpdateScreenState extends State<ScoreUpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScoringProvider>(context, listen: false).init(widget.matchId);
    });
  }

  void _showLateJoinQR(BuildContext context, String matchId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Late Join / Invite",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: matchId,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 16),
              const Text("Scan to join this match instantly!"),
              const SizedBox(height: 8),
              Text("ID: $matchId", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Live Scoring"),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: "Invite Player (Late Join)",
            onPressed: () => _showLateJoinQR(context, widget.matchId),
          ),
        ],
      ),
      body: Consumer<ScoringProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final match = provider.matchData!;

          // --- HANDLE MATCH COMPLETED STATE (The Loop Hub) ---
          if (match.status == 'COMPLETED') {
            return _MatchFinishedView(match: match, provider: provider);
          }

          // --- HANDLE SESSION ENDED STATE (Final Screen) ---
          if (match.status == 'SESSION_ENDED') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 60, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text("Session Ended", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text("Back to Dashboard"),
                  ),
                ],
              ),
            );
          }

          final score = provider.score;
          final canUpdate = provider.canScore;
          final currentMaxOvers = provider.currentMaxOvers;

          return Column(
            children: [
              // 1. Main Score Header
              _ScoreboardHeader(
                match: match,
                score: score,
                maxOvers: currentMaxOvers,
              ),

              // 2. Player Cards (Crease)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Rule Indicators
                    if (match.isPlayerBasedOvers)
                      _RuleInfoBanner(
                        icon: Icons.group_add,
                        text: "Dynamic Overs: ${match.oversPerPlayer} per player",
                        color: Colors.orange,
                      ),

                    if (match.isSingleWicketMode)
                      _RuleInfoBanner(
                        icon: Icons.person,
                        text: "Single Wicket Mode (1v1 / No Non-Striker)",
                        color: Colors.blue,
                      ),

                    _CreaseSection(provider: provider),
                  ],
                ),
              ),

              // 3. Controls
              if (canUpdate)
                const _ControlPanel()
              else
                _SpectatorView(match: match),
            ],
          );
        },
      ),
    );
  }
}

// --- VIEW: MATCH FINISHED (Decision Hub) ---
class _MatchFinishedView extends StatelessWidget {
  final MatchLobbyModel match;
  final ScoringProvider provider;

  const _MatchFinishedView({required this.match, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Check if user is Host/Captain to show controls
    final canControl = provider.isAuthorized;

    // Determine winner name safely
    String winnerText = "Match Ended";
    if (match.tossWinnerTeam != null) { // Note: 'winner' field might be stored differently in your model, accessing map safely
      // This logic depends on where 'winner' is stored. Assuming provider updated 'winner' field in DB.
      // For display, we can infer or fetch from provider if needed.
      winnerText = "Waiting for decision...";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              "MATCH COMPLETED",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              "${match.teamAName} vs ${match.teamBName}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 48),

            if (canControl) ...[
              const Text("Captain's Decision for Next Match:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // LOOP OPTION: Start New Match (Winner Bats)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sports_cricket),
                  label: const Text("START NEXT: WINNER BATS"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => provider.startNextMatchInSession('BAT'),
                ),
              ),
              const SizedBox(height: 12),

              // LOOP OPTION: Start New Match (Winner Bowls)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sports_baseball),
                  label: const Text("START NEXT: WINNER BOWLS"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () => provider.startNextMatchInSession('BOWL'),
                ),
              ),
              const SizedBox(height: 32),

              // FINALIZE OPTION: End Series
              OutlinedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text("END SESSION & FINALIZE SERIES"),
                onPressed: () => provider.endSession(),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
                ),
              )
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Waiting for captain to start next match...", style: TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}

class _RuleInfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;

  const _RuleInfoBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ScoreboardHeader extends StatelessWidget {
  final MatchLobbyModel match;
  final dynamic score;
  final int maxOvers;

  const _ScoreboardHeader({required this.match, required this.score, required this.maxOvers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine Batting Team
    final currentInnings = score.playerStats['currentInnings'] ?? 1;
    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');

    bool teamABattingNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);
    final battingTeamName = teamABattingNow ? match.teamAName : match.teamBName;

    // Target Logic
    final target = score.playerStats['target'] ?? 0;
    final showTarget = currentInnings == 2 && target > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    battingTeamName.toUpperCase(),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${score.runs}",
                          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1.0),
                        ),
                        TextSpan(
                          text: "/${score.wickets}",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), height: 1.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      showTarget ? "TARGET: $target" : "1st INNINGS",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${score.overs}.${score.balls}",
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "OVERS ($maxOvers)",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Balls
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: score.recentBalls.length,
              itemBuilder: (ctx, i) {
                final ball = score.recentBalls[score.recentBalls.length - 1 - i];
                final isWicket = ball == 'W' || ball == 'Out';
                final isBoundary = ball == '4' || ball == '6';
                return Container(
                  width: 34,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isWicket ? Colors.redAccent : (isBoundary ? Colors.green : Colors.white),
                    shape: BoxShape.circle,
                    border: isWicket || isBoundary ? null : Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ball,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isWicket || isBoundary ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreaseSection extends StatelessWidget {
  final ScoringProvider provider;
  const _CreaseSection({required this.provider});

  LobbyPlayer? _getPlayer(String uid) {
    if (uid.isEmpty || uid == 'NONE') return null;
    final pA = provider.matchData?.teamAPlayers.where((p) => p.uid == uid).firstOrNull;
    final pB = provider.matchData?.teamBPlayers.where((p) => p.uid == uid).firstOrNull;
    return pA ?? pB;
  }

  Map<String, dynamic> _getStats(String uid) {
    if (uid.isEmpty || uid == 'NONE') return <String, dynamic>{};
    final rawStats = provider.score.playerStats[uid];
    if (rawStats == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(rawStats);
  }

  void _showPlayerPicker(BuildContext context, String role) {
    final match = provider.matchData!;
    final score = provider.score;

    // Determine Batting Team
    final currentInnings = score.playerStats['currentInnings'] ?? 1;
    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');
    bool teamABattingNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);

    List<dynamic> targetList;
    String teamName;

    // Filter players based on role and innings
    if (role == 'Bowler') {
      // Bowling Team
      targetList = teamABattingNow ? match.teamBPlayers : match.teamAPlayers;
      teamName = teamABattingNow ? match.teamBName : match.teamAName;
    } else {
      // Batting Team
      targetList = teamABattingNow ? match.teamAPlayers : match.teamBPlayers;
      teamName = teamABattingNow ? match.teamAName : match.teamBName;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Select $role ($teamName)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              if (role == 'NonStriker' && !match.isSingleWicketMode) ...[
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person_off, color: Colors.white, size: 20)),
                  title: const Text("None / Retired"),
                  onTap: () {
                    provider.setNonStriker('NONE');
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
              ],
              Expanded(
                child: _buildPlayerList(context, targetList, role),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerList(BuildContext context, List<dynamic> players, String role) {
    return ListView.builder(
      itemCount: players.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (c, i) {
        final p = players[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
            child: p.photoUrl == null ? Text(p.name[0]) : null,
          ),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.touch_app, color: Colors.grey),
          onTap: () {
            if (role == 'Striker') provider.setStriker(p.uid);
            if (role == 'NonStriker') provider.setNonStriker(p.uid);
            if (role == 'Bowler') provider.setBowler(p.uid);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = provider.score;
    final canEdit = provider.canScore;
    final match = provider.matchData!;

    final striker = _getPlayer(score.strikerId);
    final bowler = _getPlayer(score.bowlerId);

    final sStats = _getStats(score.strikerId);
    final bStats = _getStats(score.bowlerId);

    // Strict Single Wicket Logic
    final isSingleWicketRule = match.isSingleWicketMode;
    final isSingleWicketState = score.nonStrikerId == 'NONE';
    final hideNonStriker = isSingleWicketRule || isSingleWicketState;

    final nonStriker = hideNonStriker ? null : _getPlayer(score.nonStrikerId);
    final nsStats = hideNonStriker ? <String, dynamic>{} : _getStats(score.nonStrikerId);

    double _calcSR(int r, int b) => b == 0 ? 0.0 : (r / b) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text("BATTING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
        ),

        _DetailedPlayerCard(
          player: striker,
          role: "Striker",
          isOnStrike: true,
          stats: sStats,
          strikeRate: _calcSR(sStats['runs'] ?? 0, sStats['balls'] ?? 0),
          onTap: canEdit ? () => _showPlayerPicker(context, 'Striker') : null,
        ),
        const SizedBox(height: 8),

        if (!isSingleWicketRule)
          if (hideNonStriker)
            InkWell(
              onTap: canEdit ? () => _showPlayerPicker(context, 'NonStriker') : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_off, color: Colors.grey),
                    const SizedBox(width: 16),
                    Text("Non-Striker: None", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (canEdit) const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            )
          else
            _DetailedPlayerCard(
              player: nonStriker,
              role: "Non-Striker",
              isOnStrike: false,
              stats: nsStats,
              strikeRate: _calcSR(nsStats['runs'] ?? 0, nsStats['balls'] ?? 0),
              onTap: canEdit ? () => _showPlayerPicker(context, 'NonStriker') : null,
            ),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text("BOWLING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
        ),
        _DetailedBowlerCard(
          player: bowler,
          stats: bStats,
          onTap: canEdit ? () => _showPlayerPicker(context, 'Bowler') : null,
        ),
      ],
    );
  }
}

class _DetailedPlayerCard extends StatelessWidget {
  final dynamic player;
  final String role;
  final bool isOnStrike;
  final Map<String, dynamic> stats;
  final double strikeRate;
  final VoidCallback? onTap;

  const _DetailedPlayerCard({
    required this.player,
    required this.role,
    required this.isOnStrike,
    required this.stats,
    required this.strikeRate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isOnStrike ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOnStrike ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: player?.photoUrl != null ? NetworkImage(player!.photoUrl!) : null,
                    child: player == null
                        ? const Icon(Icons.person_add, color: Colors.grey)
                        : (player!.photoUrl == null ? Text(player!.name[0], style: const TextStyle(fontWeight: FontWeight.bold)) : null),
                  ),
                  if (isOnStrike)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(radius: 8, backgroundColor: Colors.green, child: Icon(Icons.sports_cricket, size: 10, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player?.name ?? "Select $role", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(text: "${stats['runs'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        TextSpan(text: "(${stats['balls'] ?? 0})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text("SR: ${strikeRate.toStringAsFixed(1)}", style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailedBowlerCard extends StatelessWidget {
  final dynamic player;
  final Map<String, dynamic> stats;
  final VoidCallback? onTap;

  const _DetailedBowlerCard({required this.player, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: player?.photoUrl != null ? NetworkImage(player!.photoUrl!) : null,
                child: player == null
                    ? const Icon(Icons.person_add, color: Colors.grey)
                    : (player!.photoUrl == null ? Text(player!.name[0], style: const TextStyle(fontWeight: FontWeight.bold)) : null),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player?.name ?? "Select Bowler", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("Bowling", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${stats['wickets'] ?? 0} - ${stats['runsConceded'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("${stats['ballsBowled'] ?? 0} balls", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel();

  void _safeScoreAction(BuildContext context, VoidCallback action) {
    final provider = context.read<ScoringProvider>();
    final score = provider.score;
    final match = provider.matchData!;

    bool isStrikerSet = score.strikerId.isNotEmpty;
    bool isBowlerSet = score.bowlerId.isNotEmpty;

    // Check non-striker unless it's Single Wicket mode or manually set to NONE
    bool isNonStrikerRequired = !match.isSingleWicketMode && score.nonStrikerId != 'NONE';
    bool isNonStrikerSet = !isNonStrikerRequired || score.nonStrikerId.isNotEmpty;

    if (!isStrikerSet || !isBowlerSet || !isNonStrikerSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Striker, Non-Striker (if applicable), and Bowler first!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Valid
    action();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScoringProvider>();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ScoreBtn("0", () => _safeScoreAction(context, () => provider.addRun(0))),
              const SizedBox(width: 8),
              _ScoreBtn("1", () => _safeScoreAction(context, () => provider.addRun(1))),
              const SizedBox(width: 8),
              _ScoreBtn("2", () => _safeScoreAction(context, () => provider.addRun(2))),
              const SizedBox(width: 8),
              _ScoreBtn("3", () => _safeScoreAction(context, () => provider.addRun(3))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ScoreBtn("4", () => _safeScoreAction(context, () => provider.addRun(4)), color: Colors.purple.shade50, textColor: Colors.purple),
              const SizedBox(width: 8),
              _ScoreBtn("6", () => _safeScoreAction(context, () => provider.addRun(6)), color: Colors.purple.shade50, textColor: Colors.purple),
              const SizedBox(width: 8),
              _ScoreBtn("WD", () => _safeScoreAction(context, () => provider.addExtra("WD")), color: Colors.orange.shade50, textColor: Colors.orange, fontSize: 14),
              const SizedBox(width: 8),
              _ScoreBtn("NB", () => _safeScoreAction(context, () => provider.addExtra("NB")), color: Colors.orange.shade50, textColor: Colors.orange, fontSize: 14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BigBtn(
                  "WICKET",
                  Colors.redAccent,
                  Colors.white,
                      () => _safeScoreAction(context, () => provider.recordWicket("Out")),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BigBtn(
                  "UNDO",
                  Colors.grey.shade600,
                  Colors.white,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Undo feature needs provider update")),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpectatorView extends StatelessWidget {
  final MatchLobbyModel match;
  const _SpectatorView({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_tv, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Live Spectator Mode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("Waiting for captains to update score...", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScoreBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final double fontSize;

  const _ScoreBtn(this.label, this.onTap, {this.color, this.textColor, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigBtn extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _BigBtn(this.label, this.bg, this.fg, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}