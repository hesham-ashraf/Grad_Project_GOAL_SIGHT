import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
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
          padding: context.padAll(16),
          child: player == null
              ? const Center(
                  child: Text(
                    'Player not found',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF13243F),
                      borderRadius: BorderRadius.circular(context.rs(16, min: 12, max: 22)),
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
                      padding: context.padAll(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(30, min: 22, max: 38),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: context.rs(8, min: 5, max: 12)),
                          Text(
                            'Position: ${player.position}',
                            style: TextStyle(
                              color: const Color(0xFF8EA3CD),
                              fontSize: context.sp(14, min: 12, max: 18),
                            ),
                          ),
                          SizedBox(height: context.rs(14, min: 10, max: 20)),
                          Text(
                            'Performance Snapshot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(18, min: 14, max: 24),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: context.rs(8, min: 5, max: 12)),
                          Text(
                            '- Sprint speed: 8.9 m/s',
                            style: TextStyle(
                              color: const Color(0xFFD4DFFF),
                              fontSize: context.sp(14, min: 12, max: 18),
                            ),
                          ),
                          Text(
                            '- Pass completion: 84%',
                            style: TextStyle(
                              color: const Color(0xFFD4DFFF),
                              fontSize: context.sp(14, min: 12, max: 18),
                            ),
                          ),
                          Text(
                            '- Stamina index: 90/100',
                            style: TextStyle(
                              color: const Color(0xFFD4DFFF),
                              fontSize: context.sp(14, min: 12, max: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
