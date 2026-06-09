// ---------------------------------------------------------------------------
// GoalSight — AI Match Analysis Providers (Supabase-backed)
//
// These keep their original names for backward compatibility but now source
// data from Supabase via [matchAnalysisListProvider]. They expose synchronous
// values (empty/null while loading) so existing consumers stay unchanged and
// rebuild when the real data arrives.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/match_analysis_model.dart';
import 'repository_providers.dart';

/// Full list of analysed matches (list screen data), sourced from Supabase.
final mockAnalysisMatchesProvider = Provider<List<MatchAnalysisModel>>((ref) {
  return ref.watch(matchAnalysisListProvider(null)).maybeWhen(
        data: (matches) => matches,
        orElse: () => const <MatchAnalysisModel>[],
      );
});

/// Single [MatchAnalysisModel] by id (lookup against the Supabase-backed list).
final mockMatchAnalysisProvider =
    Provider.family<MatchAnalysisModel?, String>((ref, matchId) {
  for (final m in ref.watch(mockAnalysisMatchesProvider)) {
    if (m.matchId == matchId) return m;
  }
  return null;
});
