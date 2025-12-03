import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubberball/providers/new_match_provider.dart';
import 'package:rubberball/widgets/match/toss_coin_widget.dart';

class CreateMatchScreen extends StatelessWidget {
  const CreateMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewMatchProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Start New Match"),
        ),
        body: Consumer<NewMatchProvider>(
          builder: (context, provider, child) {
            return Stepper(
              type: StepperType.horizontal,
              currentStep: provider.currentStep,
              onStepContinue: () {
                if (provider.currentStep == 2) {
                  provider.startMatch(context);
                } else {
                  provider.nextStep();
                }
              },
              onStepCancel: provider.previousStep,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(provider.currentStep == 2 ? "START MATCH" : "NEXT"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (provider.currentStep > 0)
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text("BACK"),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Team Info
                Step(
                  title: const Text("Teams"),
                  isActive: provider.currentStep >= 0,
                  state: provider.currentStep > 0 ? StepState.complete : StepState.editing,
                  content: _TeamInfoStep(provider: provider),
                ),

                // Step 2: Squads
                Step(
                  title: const Text("Squads"),
                  isActive: provider.currentStep >= 1,
                  state: provider.currentStep > 1 ? StepState.complete : StepState.editing,
                  content: _SquadSelectionStep(provider: provider),
                ),

                // Step 3: Toss
                Step(
                  title: const Text("Toss"),
                  isActive: provider.currentStep >= 2,
                  content: _TossStep(provider: provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- SUB-STEPS WIDGETS ---

class _TeamInfoStep extends StatelessWidget {
  final NewMatchProvider provider;
  const _TeamInfoStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTeamInputGroup(
          context,
          "HOME TEAM",
          provider.teamANameController,
          provider.teamACaptainController,
          Colors.blue.shade50,
        ),
        const SizedBox(height: 16),
        const CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 12,
          child: Text("VS", style: TextStyle(fontSize: 10, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        _buildTeamInputGroup(
          context,
          "AWAY TEAM",
          provider.teamBNameController,
          provider.teamBCaptainController,
          Colors.red.shade50,
        ),
      ],
    );
  }

  Widget _buildTeamInputGroup(BuildContext context, String label,
      TextEditingController nameCtrl, TextEditingController captCtrl, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: "Team Name",
              prefixIcon: Icon(Icons.shield_outlined),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: captCtrl,
            decoration: const InputDecoration(
              labelText: "Captain Name",
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadSelectionStep extends StatelessWidget {
  final NewMatchProvider provider;
  const _SquadSelectionStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab-like switching could be added here, but list is simpler for now
        _buildSquadList(
            context,
            provider.teamANameController.text.isEmpty ? "Team A" : provider.teamANameController.text,
            provider.teamAPlayers,
            true
        ),
        const Divider(height: 32),
        _buildSquadList(
            context,
            provider.teamBNameController.text.isEmpty ? "Team B" : provider.teamBNameController.text,
            provider.teamBPlayers,
            false
        ),
      ],
    );
  }

  Widget _buildSquadList(BuildContext context, String teamName, List<String> players, bool isTeamA) {
    final TextEditingController playerInput = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$teamName Squad (${players.length})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: playerInput,
                decoration: InputDecoration(
                  hintText: "Add Player Name",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onSubmitted: (val) {
                  provider.addPlayer(val, isTeamA);
                  playerInput.clear();
                },
              ),
            ),
            IconButton(
                onPressed: () {
                  provider.addPlayer(playerInput.text, isTeamA);
                  playerInput.clear(); // Clear text field manually if using button
                },
                icon: const Icon(Icons.add_circle, color: Colors.green)
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(players.length, (index) {
            return Chip(
              label: Text(players[index]),
              onDeleted: () => provider.removePlayer(index, isTeamA),
              backgroundColor: Colors.grey.shade200,
            );
          }),
        )
      ],
    );
  }
}

class _TossStep extends StatelessWidget {
  final NewMatchProvider provider;
  const _TossStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          TossCoinWidget(
            isTossing: provider.isTossing,
            onToss: provider.performToss,
          ),
          const SizedBox(height: 30),
          if (provider.tossWinner != null && !provider.isTossing) ...[
            Text(
              "${provider.tossWinner} WON THE TOSS",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor
              ),
            ),
            const SizedBox(height: 16),
            const Text("Elected to:"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text("BAT"),
                  ),
                  selected: provider.decision == 'Bat',
                  onSelected: (val) => provider.setDecision('Bat'),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: provider.decision == 'Bat' ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text("BOWL"),
                  ),
                  selected: provider.decision == 'Bowl',
                  onSelected: (val) => provider.setDecision('Bowl'),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: provider.decision == 'Bowl' ? Colors.white : Colors.black,
                  ),
                ),
              ],
            )
          ] else if (!provider.isTossing) ...[
            const Text("Who will win the toss?"),
          ]
        ],
      ),
    );
  }
}