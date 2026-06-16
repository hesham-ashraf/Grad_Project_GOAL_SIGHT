// ---------------------------------------------------------------------------
// GoalSight — Clubs Provider (Supabase-backed)
//
// `mockClubsProvider` keeps its name for backward compatibility but now sources
// clubs from Supabase via [clubListProvider] (teams + season stats + squads).
// It exposes a synchronous List so existing consumers keep working: an empty
// list is returned while loading / on error, then dependents rebuild when the
// real data arrives.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/club_model.dart';
import '../presentation/widgets/fan/standings_row.dart';
import 'repository_providers.dart';

/// All clubs, sourced from Supabase. Empty while loading / on error.
final mockClubsProvider = Provider<List<ClubModel>>((ref) {
  return ref.watch(clubListProvider(null)).maybeWhen(
        data: (clubs) => clubs,
        orElse: () => const <ClubModel>[],
      );
});

/// Single club by id (lookup against the Supabase-backed list).
final mockClubByIdProvider = Provider.family<ClubModel?, String>((ref, id) {
  for (final club in ref.watch(mockClubsProvider)) {
    if (club.id == id) return club;
  }
  return null;
});

/// League standings derived from Supabase clubs, sorted by points then GD.
/// Returns [StandingTeamData] list consumed by the standings screen.
final standingsProvider = Provider<List<StandingTeamData>>((ref) {
  return ref.watch(clubListProvider(null)).maybeWhen(
    data: (clubs) {
      if (clubs.isEmpty) return const [];
      final sorted = [...clubs]
        ..sort((a, b) {
          final ptsDiff = b.stats.points - a.stats.points;
          if (ptsDiff != 0) return ptsDiff;
          return b.stats.goalDifference.compareTo(a.stats.goalDifference);
        });
      return [
        for (var i = 0; i < sorted.length; i++)
          StandingTeamData(
            rank: i + 1,
            teamName: sorted[i].name,
            matchesPlayed: sorted[i].stats.matchesPlayed,
            goalDifference: sorted[i].stats.goalDifference,
            points: sorted[i].stats.points,
            teamColor: sorted[i].primaryColor,
            isHighlighted: i == 0,
          ),
      ];
    },
    orElse: () => const [],
  );
});
