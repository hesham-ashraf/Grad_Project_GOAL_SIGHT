import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state_management/app_providers.dart';

class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailsProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Match Details')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load match: $error'),
          ),
        ),
        data: (match) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score: ${match.score}'),
                      const SizedBox(height: 8),
                      Text('Status: ${match.status}'),
                      const SizedBox(height: 8),
                      const Text('AI Insights:'),
                      const SizedBox(height: 4),
                      const Text('- High press intensity detected'),
                      const Text('- Midfield passing accuracy: 82%'),
                      const Text('- Defensive line compactness: good'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
