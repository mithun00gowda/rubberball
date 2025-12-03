import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/providers/scoring_provider.dart';

class ScoreUpdateScreen extends StatefulWidget {
  // Pass matchId or object. Passing ID is safer for deep linking/reloads.
  final String matchId;

  const ScoreUpdateScreen({super.key, required this.matchId});

  @override
  State<ScoreUpdateScreen> createState() => _ScoreUpdateScreenState();
}

class _ScoreUpdateScreenState extends State<ScoreUpdateScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider with the specific match ID
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
          final score = provider.score;
          final canUpdate = provider.canScore;

          return Column(
            children: [
              // 1. Main Score Header
              _ScoreboardHeader(match: match, score: score),

              // 2. Player Cards (Crease)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (match.isPlayerBasedOvers)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group_add, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Dynamic Overs: ${match.oversPerPlayer} per player",
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    _CreaseSection(provider: provider),
                  ],
                ),
              ),

              // 3. Controls (Bottom Sheet style)
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

class _ScoreboardHeader extends StatelessWidget {
  final MatchLobbyModel match;
  final dynamic score;

  const _ScoreboardHeader({required this.match, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final battingTeam = match.tossDecision == 'BAT' && match.tossWinnerTeam == 'A'
        ? match.teamAName : match.teamBName;

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
                    battingTeam.toUpperCase(),
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
                      match.isPlayerBasedOvers ? "DYNAMIC OVERS" : "TARGET: --",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${score.overs}.${score.balls}",
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "OVERS (${match.totalOvers})",
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
    // Ensure strict type casting
    return Map<String, dynamic>.from(rawStats);
  }

  void _showPlayerPicker(BuildContext context, String role) {
    final match = provider.matchData!;

    bool isTeamABatting = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');

    List<dynamic> targetList;
    String teamName;

    if (role == 'Bowler') {
      targetList = isTeamABatting ? match.teamBPlayers : match.teamAPlayers;
      teamName = isTeamABatting ? match.teamBName : match.teamAName;
    } else {
      targetList = isTeamABatting ? match.teamAPlayers : match.teamBPlayers;
      teamName = isTeamABatting ? match.teamAName : match.teamBName;
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
              // Option for Single Wicket (No Non-Striker)
              if (role == 'NonStriker')
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person_off, color: Colors.white, size: 20)),
                  title: const Text("Single Wicket / None"),
                  subtitle: const Text("Play without a non-striker"),
                  onTap: () {
                    provider.setNonStriker('NONE');
                    Navigator.pop(context);
                  },
                ),
              if (role == 'NonStriker') const Divider(),
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

    final striker = _getPlayer(score.strikerId);
    final bowler = _getPlayer(score.bowlerId);

    final sStats = _getStats(score.strikerId);
    final bStats = _getStats(score.bowlerId);

    // Check if Single Wicket
    final isSingleWicket = score.nonStrikerId == 'NONE';
    final nonStriker = isSingleWicket ? null : _getPlayer(score.nonStrikerId);

    // Explicitly type the empty map for non-striker stats
    final nsStats = isSingleWicket ? <String, dynamic>{} : _getStats(score.nonStrikerId);

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
        if (isSingleWicket)
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
                  Text("Single Wicket Mode", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
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
              _ScoreBtn("0", () => provider.addRun(0)),
              const SizedBox(width: 8),
              _ScoreBtn("1", () => provider.addRun(1)),
              const SizedBox(width: 8),
              _ScoreBtn("2", () => provider.addRun(2)),
              const SizedBox(width: 8),
              _ScoreBtn("3", () => provider.addRun(3)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ScoreBtn("4", () => provider.addRun(4), color: Colors.purple.shade50, textColor: Colors.purple),
              const SizedBox(width: 8),
              _ScoreBtn("6", () => provider.addRun(6), color: Colors.purple.shade50, textColor: Colors.purple),
              const SizedBox(width: 8),
              _ScoreBtn("WD", () => provider.addExtra("WD"), color: Colors.orange.shade50, textColor: Colors.orange, fontSize: 14),
              const SizedBox(width: 8),
              _ScoreBtn("NB", () => provider.addExtra("NB"), color: Colors.orange.shade50, textColor: Colors.orange, fontSize: 14),
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
                      () => provider.recordWicket("Out"),
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