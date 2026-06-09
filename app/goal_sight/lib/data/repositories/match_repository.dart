import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_model.dart';

/// Supabase-backed match repository. Matches are derived from the AI
/// `match_analyses` rows (the same data that powers the analysis screens),
/// mapped into the lightweight [MatchModel] the fan home/match screens use.
class MatchRepository {
  const MatchRepository();

  SupabaseClient get _client => Supabase.instance.client;

  static const _columns =
      'id, home_team_name, away_team_name, score, date_label, result_status, '
      'intensity, highlight_text, dominant_team, overall_narrative';

  Future<List<MatchModel>> fetchMatches() async {
    final rows = await _client
        .from('match_analyses')
        .select(_columns)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => _mapMatch(r as Map<String, dynamic>))
        .toList();
  }

  Future<MatchModel> fetchMatchDetails(String matchId) async {
    final row = await _client
        .from('match_analyses')
        .select(_columns)
        .eq('id', matchId)
        .maybeSingle();
    if (row == null) throw Exception('Match not found: $matchId');
    return _mapMatch(row);
  }

  Future<void> uploadMatch({
    required String homeTeam,
    required String awayTeam,
  }) async {
    // Manager uploads are handled by the upload workflow; no-op here.
  }

  MatchModel _mapMatch(Map<String, dynamic> row) {
    final intensity = (row['intensity'] as num? ?? 0).toInt();
    return MatchModel(
      id: row['id'].toString(),
      homeTeam: (row['home_team_name'] ?? '').toString(),
      awayTeam: (row['away_team_name'] ?? '').toString(),
      // These analyses are completed matches.
      status: 'finished',
      score: (row['score'] ?? '').toString(),
      date: (row['date_label'] ?? 'TBD').toString(),
      intensity: intensity,
      highlightText: row['highlight_text']?.toString(),
      isTopMatch: intensity >= 85,
      summary: (row['overall_narrative'] ?? '').toString(),
      dominantTeam: (row['dominant_team'] ?? '').toString(),
    );
  }
}
