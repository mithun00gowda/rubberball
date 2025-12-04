import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rubberball/models/match_lobby_model.dart';
import 'package:rubberball/providers/scoring_provider.dart';
import 'package:rubberball/providers/match_lobby_provider.dart'; // Needed for Late Join logic

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

  void _confirmEndSession(BuildContext context, ScoringProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("End Session?"),
        content: const Text("This will stop the current match and finalize the series. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.endSession();
            },
            child: const Text("End Session", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerRef = Provider.of<ScoringProvider>(context, listen: false);

    return Consumer<ScoringProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || provider.matchData == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final match = provider.matchData!;
        final isAuthorized = provider.isAuthorized;

        if (match.status == 'SESSION_ENDED') {
          return _SessionEndedView();
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text("Live Scoring"),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code),
                tooltip: "Invite Player",
                onPressed: () => _showLateJoinQR(context, widget.matchId),
              ),
              if (isAuthorized)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'end') _confirmEndSession(context, provider);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'end',
                      child: Row(
                        children: [
                          Icon(Icons.stop_circle_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Text('End Session Now', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: match.status == 'COMPLETED'
              ? _MatchFinishedView(match: match, provider: provider)
              : _buildLiveScoringBody(provider, match),
        );
      },
    );
  }

  Widget _buildLiveScoringBody(ScoringProvider provider, MatchLobbyModel match) {
    final score = provider.score;
    final canUpdate = provider.canScore;
    final currentMaxOvers = provider.currentMaxOvers;

    return Column(
      children: [
        _ScoreboardHeader(match: match, score: score, maxOvers: currentMaxOvers),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (match.isPlayerBasedOvers) _RuleInfoBanner(icon: Icons.group, text: "Dynamic Overs", color: Colors.orange),
              if (match.isSingleWicketMode) _RuleInfoBanner(icon: Icons.person, text: "Single Wicket", color: Colors.blue),
              _CreaseSection(provider: provider),
            ],
          ),
        ),
        // If canUpdate (Host/Captain) show controls, else show Spectator View which now includes Join Button
        if (canUpdate)
          const _ControlPanel()
        else
          _SpectatorView(match: match, matchId: widget.matchId),
      ],
    );
  }
}

class _SpectatorView extends StatelessWidget {
  final MatchLobbyModel match;
  final String matchId;
  const _SpectatorView({required this.match, required this.matchId});

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Join this Match"),
        content: const Text("Select a team to play for:"),
        actions: [
          TextButton(
            onPressed: () => _joinTeam(context, 'A'),
            child: Text("Join ${match.teamAName}"),
          ),
          TextButton(
            onPressed: () => _joinTeam(context, 'B'),
            child: Text("Join ${match.teamBName}"),
          ),
        ],
      ),
    );
  }

  void _joinTeam(BuildContext context, String teamSide) async {
    final nav = Navigator.of(context);
    final lobbyProvider = Provider.of<MatchLobbyProvider>(context, listen: false);
    nav.pop(); // Close dialog

    try {
      await lobbyProvider.joinTeam(matchId, teamSide);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You have joined the match!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error joining: $e")));
    }
  }

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
          const Text("You are watching this match.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          // Late Join Button
          OutlinedButton.icon(
            onPressed: () => _showJoinDialog(context),
            icon: const Icon(Icons.person_add_alt),
            label: const Text("Request to Join / Play"),
          ),
        ],
      ),
    );
  }
}

class _SessionEndedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            const Text("Session Ended", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text("Back to Dashboard")),
          ],
        ),
      ),
    );
  }
}

class _MatchFinishedView extends StatelessWidget {
  final MatchLobbyModel match;
  final ScoringProvider provider;
  const _MatchFinishedView({required this.match, required this.provider});
  @override
  Widget build(BuildContext context) {
    final canControl = provider.isAuthorized;
    String winnerText = "Winner: ";
    if (match.winner == 'A') winnerText += match.teamAName; else if (match.winner == 'B') winnerText += match.teamBName; else winnerText = "Match Drawn";

    return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
      const SizedBox(height: 24),
      const Text("MATCH COMPLETED", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(winnerText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 48),
      if (canControl) ...[
        ElevatedButton.icon(icon: const Icon(Icons.sports_cricket), label: const Text("START NEXT: WINNER BATS"), onPressed: () => provider.startNextMatchInSession('BAT')),
        const SizedBox(height: 12),
        ElevatedButton.icon(icon: const Icon(Icons.sports_baseball), label: const Text("START NEXT: WINNER BOWLS"), onPressed: () => provider.startNextMatchInSession('BOWL')),
        const SizedBox(height: 32),
        OutlinedButton(onPressed: () => provider.endSession(), child: const Text("END SESSION")),
      ] else const Text("Waiting for captain...", style: TextStyle(color: Colors.grey)),
    ])));
  }
}

class _RuleInfoBanner extends StatelessWidget {
  final IconData icon; final String text; final MaterialColor color;
  const _RuleInfoBanner({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.shade200)), child: Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 8), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))]));
  }
}

class _ScoreboardHeader extends StatelessWidget {
  final MatchLobbyModel match; final dynamic score; final int maxOvers;
  const _ScoreboardHeader({required this.match, required this.score, required this.maxOvers});
  @override
  Widget build(BuildContext context) {
    final currentInnings = score.playerStats['currentInnings'] ?? 1;
    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') || (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');
    bool teamABattingNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);
    final battingTeamName = teamABattingNow ? match.teamAName : match.teamBName;
    final target = score.playerStats['target'] ?? 0;
    final showTarget = currentInnings == 2 && target > 0;

    return Container(padding: const EdgeInsets.all(24), color: Theme.of(context).primaryColor, child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(battingTeamName.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("${score.runs}/${score.wickets}", style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1.0, color: Colors.white)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)), child: Text(showTarget ? "TARGET: $target" : "1st INNINGS", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          Text("${score.overs}.${score.balls}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600)),
          Text("OVERS ($maxOvers)", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.0)),
        ])
      ]),
      const SizedBox(height: 24),
      SizedBox(height: 34, child: ListView.builder(scrollDirection: Axis.horizontal, reverse: true, itemCount: score.recentBalls.length, itemBuilder: (ctx, i) {
        final ball = score.recentBalls[score.recentBalls.length - 1 - i];
        final isWicket = ball == 'W' || ball == 'Out'; final isBoundary = ball == '4' || ball == '6';
        return Container(width: 34, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: isWicket ? Colors.redAccent : (isBoundary ? Colors.green : Colors.white), shape: BoxShape.circle), alignment: Alignment.center, child: Text(ball, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isWicket || isBoundary ? Colors.white : Colors.black87)));
      }))
    ]));
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

    final currentInnings = score.playerStats['currentInnings'] ?? 1;
    bool teamABatsFirst = (match.tossWinnerTeam == 'A' && match.tossDecision == 'BAT') ||
        (match.tossWinnerTeam == 'B' && match.tossDecision == 'BOWL');
    bool teamABattingNow = (currentInnings == 1 && teamABatsFirst) || (currentInnings == 2 && !teamABatsFirst);

    List<dynamic> targetList;
    String teamName;

    if (role == 'Bowler') {
      targetList = teamABattingNow ? match.teamBPlayers : match.teamAPlayers;
      teamName = teamABattingNow ? match.teamBName : match.teamAName;
    } else {
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
    final statsMap = provider.score.playerStats;
    final currentStriker = provider.score.strikerId;
    final currentNonStriker = provider.score.nonStrikerId;

    final filteredPlayers = players.where((p) {
      if (role == 'Bowler') return true;

      final pStats = statsMap[p.uid];
      final isOut = pStats != null && (pStats['isOut'] == true);

      if (isOut) return false;
      if (role == 'Striker' && p.uid == currentNonStriker) return false;
      if (role == 'NonStriker' && p.uid == currentStriker) return false;

      return true;
    }).toList();

    if (filteredPlayers.isEmpty) {
      return const Center(child: Text("No eligible players available"));
    }

    return ListView.builder(
      itemCount: filteredPlayers.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (c, i) {
        final p = filteredPlayers[i];
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
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [const Icon(Icons.person_off, color: Colors.grey), const SizedBox(width: 16), Text("Non-Striker: None", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)), const Spacer(), if (canEdit) const Icon(Icons.edit, size: 16, color: Colors.grey)]),
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
  final dynamic player; final String role; final bool isOnStrike; final Map<String, dynamic> stats; final double strikeRate; final VoidCallback? onTap;
  const _DetailedPlayerCard({required this.player, required this.role, required this.isOnStrike, required this.stats, required this.strikeRate, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isOnStrike ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isOnStrike ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
        Stack(children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade200, backgroundImage: player?.photoUrl != null ? NetworkImage(player!.photoUrl!) : null, child: player == null ? const Icon(Icons.person_add, color: Colors.grey) : (player!.photoUrl == null ? Text(player!.name[0], style: const TextStyle(fontWeight: FontWeight.bold)) : null)),
          if (isOnStrike) const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 8, backgroundColor: Colors.green, child: Icon(Icons.sports_cricket, size: 10, color: Colors.white))),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(player?.name ?? "Select $role", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          RichText(text: TextSpan(style: const TextStyle(color: Colors.black87), children: [TextSpan(text: "${stats['runs'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), TextSpan(text: "(${stats['balls'] ?? 0})", style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          Text("SR: ${strikeRate.toStringAsFixed(1)}", style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
        ]),
      ]))),
    );
  }
}

class _DetailedBowlerCard extends StatelessWidget {
  final dynamic player; final Map<String, dynamic> stats; final VoidCallback? onTap;
  const _DetailedBowlerCard({required this.player, required this.stats, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
      CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade200, backgroundImage: player?.photoUrl != null ? NetworkImage(player!.photoUrl!) : null, child: player == null ? const Icon(Icons.person_add, color: Colors.grey) : (player!.photoUrl == null ? Text(player!.name[0], style: const TextStyle(fontWeight: FontWeight.bold)) : null)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(player?.name ?? "Select Bowler", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Text("Bowling", style: TextStyle(color: Colors.grey, fontSize: 12))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${stats['wickets'] ?? 0} - ${stats['runsConceded'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text("${stats['ballsBowled'] ?? 0} balls", style: const TextStyle(fontSize: 10, color: Colors.grey))]),
    ]))));
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
    bool isNonStrikerRequired = !match.isSingleWicketMode && score.nonStrikerId != 'NONE';
    bool isNonStrikerSet = !isNonStrikerRequired || score.nonStrikerId.isNotEmpty;
    if (!isStrikerSet || !isBowlerSet || !isNonStrikerSet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Striker, Non-Striker (if applicable), and Bowler first!"), backgroundColor: Colors.red));
      return;
    }
    action();
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScoringProvider>();
    return Container(padding: const EdgeInsets.all(16), color: Colors.white, child: Column(children: [
      Row(children: [
        _Btn("0", () => _safeScoreAction(context, () => provider.addRun(0))), const SizedBox(width:8),
        _Btn("1", () => _safeScoreAction(context, () => provider.addRun(1))), const SizedBox(width:8),
        _Btn("2", () => _safeScoreAction(context, () => provider.addRun(2))), const SizedBox(width:8),
        _Btn("3", () => _safeScoreAction(context, () => provider.addRun(3))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _Btn("4", () => _safeScoreAction(context, () => provider.addRun(4)), color: Colors.purple.shade50), const SizedBox(width:8),
        _Btn("6", () => _safeScoreAction(context, () => provider.addRun(6)), color: Colors.purple.shade50), const SizedBox(width:8),
        _Btn("WD", () => _safeScoreAction(context, () => provider.addExtra("WD")), color: Colors.orange.shade50, fontSize: 14), const SizedBox(width:8),
        _Btn("NB", () => _safeScoreAction(context, () => provider.addExtra("NB")), color: Colors.orange.shade50, fontSize: 14),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _BigBtn("WICKET", Colors.redAccent, Colors.white, () => _safeScoreAction(context, () => provider.recordWicket("Out")))),
        const SizedBox(width: 8),
        Expanded(child: _BigBtn("UNDO", Colors.grey.shade600, Colors.white, () { provider.undoLastAction().catchError((e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Undo failed: $e")))); })),
      ])
    ]));
  }
}

class _Btn extends StatelessWidget {
  final String l; final VoidCallback o; final Color? color; final Color? textColor; final double fontSize;
  const _Btn(this.l, this.o, {this.color, this.textColor, this.fontSize=20});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: InkWell(onTap: o, child: Container(height: 50, decoration: BoxDecoration(color: color ?? Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(l, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.bold)))));
  }
}

class _BigBtn extends StatelessWidget {
  final String l; final Color bg; final Color fg; final VoidCallback o;
  const _BigBtn(this.l, this.bg, this.fg, this.o);
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: o, child: Container(height: 50, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(l, style: TextStyle(color: fg, fontWeight: FontWeight.bold))));
  }
}