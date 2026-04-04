import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state_management/app_providers.dart';

class LiveMatchScreen extends ConsumerWidget {
  const LiveMatchScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveState = ref.watch(liveMatchControllerProvider(matchId));

    return Scaffold(
      backgroundColor: const Color(0xFF040B1E),
      appBar: AppBar(
        title: const Text('Live Match'),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: liveState.connected
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  liveState.connected
                      ? 'Connected to live feed'
                      : 'Reconnecting...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Real-time updates from WebSocket stream:',
              style: TextStyle(color: Color(0xFF8EA3CD)),
            ),
            const SizedBox(height: 12),
            if (liveState.updates.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13243F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C406D)),
                ),
                child: const Text(
                  'No live events yet. Waiting for server updates...',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ...liveState.updates.map(
                (update) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13243F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2C406D)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Color(0xFF8AB8FF)),
                    title: Text(
                      update.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      update.timestamp.toLocal().toIso8601String(),
                      style: const TextStyle(color: Color(0xFF8EA3CD)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
