import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
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
            padding: context.padAll(16),
            children: [
              Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: context.rs(12, min: 8, max: 18)),
              Card(
                child: Padding(
                  padding: context.padAll(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score: ${match.score}'),
                      SizedBox(height: context.rs(8, min: 5, max: 12)),
                      Text('Status: ${match.status}'),
                      SizedBox(height: context.rs(8, min: 5, max: 12)),
                      const Text('AI Insights:'),
                      SizedBox(height: context.rs(4, min: 2, max: 8)),
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
