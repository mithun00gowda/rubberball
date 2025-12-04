import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/providers/match_lobby_provider.dart';
import 'package:rubberball/screens/score_update_screen.dart';

import 'match_lobby_screen.dart';

class JoinMatchQRScanner extends StatefulWidget {
  const JoinMatchQRScanner({super.key});

  @override
  State<JoinMatchQRScanner> createState() => _JoinMatchQRScannerState();
}

class _JoinMatchQRScannerState extends State<JoinMatchQRScanner> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String matchId = barcodes.first.rawValue!;
      setState(() => _isScanned = true);

      try {
        // 1. Check Match Status
        final doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
        if (doc.exists) {
          final status = doc.data()?['status'];

          // FIXED: If LIVE or COMPLETED, go directly to Scoreboard (Spectator Mode)
          // Do NOT show the Team Selection sheet immediately.
          if (status == 'LIVE' || status == 'COMPLETED') {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ScoreUpdateScreen(matchId: matchId)),
            );
            return;
          }
        }

        // 2. If LOBBY, show team selection
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          builder: (ctx) => _TeamSelectionSheet(matchId: matchId),
        ).then((_) {
          // If sheet closed without action, reset scan to allow rescanning
          // (Ideally navigation handles this, but good for safety)
        });

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          setState(() => _isScanned = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Match QR")),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}

class _TeamSelectionSheet extends StatefulWidget {
  final String matchId;
  const _TeamSelectionSheet({required this.matchId});

  @override
  State<_TeamSelectionSheet> createState() => _TeamSelectionSheetState();
}

class _TeamSelectionSheetState extends State<_TeamSelectionSheet> {
  bool _isJoining = false;

  void _join(String teamSide) async {
    setState(() => _isJoining = true);
    try {
      final provider = Provider.of<MatchLobbyProvider>(context, listen: false);
      await provider.joinTeam(widget.matchId, teamSide);

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MatchLobbyScreen(matchId: widget.matchId)),
      );

    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 250,
      child: Column(
        children: [
          const Text(
            "Match Found!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text("Select your team to join:"),
          const SizedBox(height: 20),
          if (_isJoining)
            const CircularProgressIndicator()
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    onPressed: () => _join('A'),
                    child: const Text("Join Team A"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    onPressed: () => _join('B'),
                    child: const Text("Join Team B"),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}