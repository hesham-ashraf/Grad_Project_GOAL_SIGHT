import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state_management/app_providers.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamMembers = ref.watch(teamMembersProvider);
    final matches = teamMembers.where((item) => item.id == playerId);
    final player = matches.isEmpty ? null : matches.first;

    return Scaffold(
      backgroundColor: const Color(0xFF040B1E),
      appBar: AppBar(
        title: const Text('Player Profile'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF040B1E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040B1E), Color(0xFF081632), Color(0xFF040B1E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: player == null
              ? const Center(
                  child: Text(
                    'Player not found',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13243F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2C406D)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x446F58F5),
                        blurRadius: 18,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Position: ${player.position}',
                          style: const TextStyle(color: Color(0xFF8EA3CD)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Performance Snapshot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '- Sprint speed: 8.9 m/s',
                          style: TextStyle(color: Color(0xFFD4DFFF)),
                        ),
                        const Text(
                          '- Pass completion: 84%',
                          style: TextStyle(color: Color(0xFFD4DFFF)),
                        ),
                        const Text(
                          '- Stamina index: 90/100',
                          style: TextStyle(color: Color(0xFFD4DFFF)),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
