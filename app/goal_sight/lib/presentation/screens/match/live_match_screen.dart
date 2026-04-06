import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
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
          padding: context.padAll(16),
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: context.rs(12, min: 10, max: 14),
                  color: liveState.connected
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                SizedBox(width: context.rs(8, min: 6, max: 12)),
                Expanded(
                  child: Text(
                    liveState.connected
                        ? 'Connected to live feed'
                        : 'Reconnecting...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.sp(16, min: 13, max: 20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(12, min: 8, max: 18)),
            const Text(
              'Real-time updates from WebSocket stream:',
              style: TextStyle(color: Color(0xFF8EA3CD)),
            ),
            SizedBox(height: context.rs(12, min: 8, max: 18)),
            if (liveState.updates.isEmpty)
              Container(
                padding: context.padAll(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13243F),
                  borderRadius: BorderRadius.circular(context.rs(16, min: 12, max: 22)),
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
                  margin: EdgeInsets.only(bottom: context.rs(10, min: 6, max: 14)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13243F),
                    borderRadius: BorderRadius.circular(context.rs(14, min: 10, max: 18)),
                    border: Border.all(color: const Color(0xFF2C406D)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Color(0xFF8AB8FF)),
                    title: Text(
                      update.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
