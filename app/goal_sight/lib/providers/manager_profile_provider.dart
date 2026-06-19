// ---------------------------------------------------------------------------
// GoalSight — Manager Profile Provider
//
// Real, DB-derived stats for the manager profile screen (club name, matches
// analysed, players tracked, win rate) — replacing the previously hard-coded
// "GoalSight FC / 124 / 28 / 71%" values. Everything is RLS-scoped to the
// signed-in manager's club.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_providers.dart';

class ManagerProfileStats {
  const ManagerProfileStats({
    required this.clubName,
    required this.matchesAnalyzed,
    required this.playersTracked,
    required this.winRate,
  });

  final String clubName;
  final int matchesAnalyzed;
  final int playersTracked;
  final int winRate; // percentage 0-100

  static const empty = ManagerProfileStats(
    clubName: 'My Club',
    matchesAnalyzed: 0,
    playersTracked: 0,
    winRate: 0,
  );
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

final managerProfileStatsProvider =
    FutureProvider.autoDispose<ManagerProfileStats>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id ?? '';

  // Club name from the manager's profile → teams join.
  String clubName = 'My Club';
  try {
    final profile = await client
        .from('profiles')
        .select('club_id, teams(name)')
        .eq('id', uid)
        .maybeSingle();
    final teamMap = profile?['teams'] as Map<String, dynamic>?;
    if (teamMap != null) clubName = (teamMap['name'] as String?) ?? clubName;
  } catch (_) {}

  // RLS-scoped to the manager's club.
  final analyses = await ref.watch(matchAnalysisListProvider(null).future);
  final squad = await ref.watch(squadProvider(null).future);

  final clubKey = _normalize(clubName);
  var decided = 0;
  var wins = 0;
  for (final a in analyses) {
    final parts = a.score.split('-');
    if (parts.length != 2) continue;
    final homeGoals = int.tryParse(parts[0].trim());
    final awayGoals = int.tryParse(parts[1].trim());
    if (homeGoals == null || awayGoals == null) continue;

    final homeIsClub = _normalize(a.homeTeam) == clubKey;
    final awayIsClub = _normalize(a.awayTeam) == clubKey;
    if (!homeIsClub && !awayIsClub) continue;

    decided++;
    final clubGoals = homeIsClub ? homeGoals : awayGoals;
    final oppGoals = homeIsClub ? awayGoals : homeGoals;
    if (clubGoals > oppGoals) wins++;
  }

  final winRate = decided == 0 ? 0 : ((wins / decided) * 100).round();

  return ManagerProfileStats(
    clubName: clubName,
    matchesAnalyzed: analyses.length,
    playersTracked: squad.length,
    winRate: winRate,
  );
});
