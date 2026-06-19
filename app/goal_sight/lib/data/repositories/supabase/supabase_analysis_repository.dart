// ---------------------------------------------------------------------------
// GoalSight — Supabase Analysis Repository
//
// Reads AI match analyses from Supabase (match_analyses + team_match_analysis
// + match_player_analysis) and rebuilds the nested MatchAnalysisModel the UI
// consumes. Drop-in replacement for MockAnalysisRepository.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/match_analysis_model.dart';
import '../interfaces/i_analysis_repository.dart';

final class SupabaseAnalysisRepository implements IAnalysisRepository {
  const SupabaseAnalysisRepository();

  SupabaseClient get _client => Supabase.instance.client;

  static const _columns =
      '*, team_match_analysis(*), match_player_analysis(*)';

  @override
  Future<List<MatchAnalysisModel>> fetchAnalyses({String? clubId}) async {
    final rows = await _client
        .from('match_analyses')
        .select(_columns)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => _mapAnalysis(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MatchAnalysisModel> fetchAnalysisById(String id) async {
    final row = await _client
        .from('match_analyses')
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    if (row == null) throw Exception('Analysis not found: $id');
    return _mapAnalysis(row);
  }

  @override
  Future<List<MatchAnalysisModel>> fetchAnalysesPaged({
    required int page,
    int pageSize = 20,
    String? clubId,
    String? matchId,
  }) async {
    final all = await fetchAnalyses(clubId: clubId);
    final start = page * pageSize;
    if (start >= all.length) return [];
    final end = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  @override
  Future<MatchAnalysisModel?> fetchLatestAnalysis({String? clubId}) async {
    final all = await fetchAnalyses(clubId: clubId);
    return all.isEmpty ? null : all.last;
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  MatchAnalysisModel _mapAnalysis(Map<String, dynamic> row) {
    final teams = (row['team_match_analysis'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final home = teams.firstWhere(
      (t) => t['side'] == 'home',
      orElse: () => const <String, dynamic>{},
    );
    final away = teams.firstWhere(
      (t) => t['side'] == 'away',
      orElse: () => const <String, dynamic>{},
    );

    final players = (row['match_player_analysis'] as List? ?? const [])
        .map((p) => _mapPlayer(p as Map<String, dynamic>))
        .toList();

    return MatchAnalysisModel(
      matchId: row['id'].toString(),
      homeTeam: (row['home_team_name'] ?? '').toString(),
      awayTeam: (row['away_team_name'] ?? '').toString(),
      score: (row['score'] ?? '').toString(),
      date: (row['date_label'] ?? 'TBD').toString(),
      status: (row['result_status'] ?? 'FT').toString(),
      intensity: (row['intensity'] as num? ?? 0).toInt(),
      highlightText: row['highlight_text']?.toString(),
      recommendations: _stringList(row['recommendations']),
      // The analyzed (model-output) video, when the analysis has produced one.
      analyzedVideoUrl: (row['analyzed_video_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : row['analyzed_video_url'] as String,
      heatmapUrl: (row['heatmap_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : row['heatmap_url'] as String,
      summary: MatchSummaryModel(
        dominantTeam: (row['dominant_team'] ?? '').toString(),
        homeAvgRating: (row['home_avg_rating'] as num? ?? 0).toDouble(),
        awayAvgRating: (row['away_avg_rating'] as num? ?? 0).toDouble(),
        motmPlayerId: (row['motm_player_key'] ?? '').toString(),
        worstPlayerId: (row['worst_player_key'] ?? '').toString(),
        keyMoments: _stringList(row['key_moments']),
        overallNarrative: (row['overall_narrative'] ?? '').toString(),
      ),
      homeAnalysis: _mapTeam(home),
      awayAnalysis: _mapTeam(away),
      players: players,
    );
  }

  TeamAnalysisModel _mapTeam(Map<String, dynamic> t) => TeamAnalysisModel(
        teamName: (t['team_name'] ?? '').toString(),
        possession: (t['possession'] as num? ?? 0).toInt(),
        style: (t['style'] ?? '').toString(),
        pressureStyle: (t['pressure_style'] ?? '').toString(),
        compactness: (t['compactness'] ?? '').toString(),
        attackingZones: _stringList(t['attacking_zones']),
        avgRating: (t['avg_rating'] as num? ?? 0).toDouble(),
        topPlayers: _stringList(t['top_players']),
        worstPlayers: _stringList(t['worst_players']),
      );

  PlayerModel _mapPlayer(Map<String, dynamic> p) => PlayerModel(
        id: (p['player_key'] ?? p['id']).toString(),
        name: (p['player_name'] ?? '').toString(),
        position: (p['player_position'] ?? '').toString(),
        rating: (p['rating'] as num? ?? 0).toDouble(),
        fatigue: (p['fatigue'] as num? ?? 0).toInt(),
        performanceStatus: PerformanceStatus.values.firstWhere(
          (e) => e.name == p['performance_status'],
          orElse: () => PerformanceStatus.average,
        ),
        insight: (p['insight'] ?? '').toString(),
        contribution: ContributionType.values.firstWhere(
          (e) => e.name == p['contribution'],
          orElse: () => ContributionType.balanced,
        ),
        impact: (p['impact'] ?? '').toString(),
        goals: (p['goals'] as num? ?? 0).toInt(),
        assists: (p['assists'] as num? ?? 0).toInt(),
        tackles: (p['tackles'] as num? ?? 0).toInt(),
        keyPasses: (p['key_passes'] as num? ?? 0).toInt(),
        isMOTM: p['is_motm'] == true,
        isWorst: p['is_worst'] == true,
        heatmapUrl: (p['heatmap_url'] as String?)?.trim().isEmpty ?? true
            ? null
            : p['heatmap_url'] as String,
      );

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
