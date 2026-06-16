// ---------------------------------------------------------------------------
// GoalSight — Supabase Player Repository
//
// Reads players from Supabase (players + player_intelligence) and maps them
// to PlayerProfileModel / RiskAnalysisModel. Falls back to sensible defaults
// when enriched intelligence rows are not yet seeded.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../models/player_profile_model.dart';
import '../../models/risk_analysis_model.dart';
import '../interfaces/i_player_repository.dart';

final class SupabasePlayerRepository implements IPlayerRepository {
  const SupabasePlayerRepository();

  SupabaseClient get _client => Supabase.instance.client;

  static const _playerCols =
      'id, full_name, position, team_id, season_rating, season_goals, '
      'season_assists, season_tackles, appearances, '
      'player_intelligence(current_rating, average_rating, fatigue, '
      'activity_level, primary_contribution, secondary_contribution, '
      'trend, status, improvement_rate, insights, ratings_history, '
      'total_matches, total_goals, total_assists, total_tackles)';

  static const _cacheTtl = Duration(minutes: 8);

  // ── IPlayerRepository ─────────────────────────────────────────────────────

  @override
  Future<List<PlayerProfileModel>> fetchSquad({String? clubId}) async {
    final cacheKey = 'squad:${clubId ?? 'all'}';
    final cached = CacheService.get<List<PlayerProfileModel>>(cacheKey);
    if (cached != null) return cached;

    var query = _client.from('players').select(_playerCols);
    if (clubId != null && clubId.isNotEmpty) {
      query = query.eq('team_id', clubId);
    }
    final rows = await query.order('season_rating', ascending: false);
    final result = (rows as List)
        .map((r) => _mapPlayer(r as Map<String, dynamic>))
        .toList();
    CacheService.set(cacheKey, result, ttl: _cacheTtl);
    return result;
  }

  @override
  Future<PlayerProfileModel> fetchPlayerById(String id) async {
    final cacheKey = 'player:$id';
    final cached = CacheService.get<PlayerProfileModel>(cacheKey);
    if (cached != null) return cached;

    final row = await _client
        .from('players')
        .select(_playerCols)
        .eq('id', id)
        .maybeSingle();
    if (row == null) throw Exception('Player not found: $id');
    final result = _mapPlayer(row);
    CacheService.set(cacheKey, result, ttl: _cacheTtl);
    return result;
  }

  @override
  Future<RiskAnalysisModel> fetchRiskAnalysis(String playerId) async {
    final row = await _client
        .from('player_risk_analysis')
        .select('*, players(full_name, position)')
        .eq('player_id', playerId)
        .order('analyzed_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row != null) return _mapRisk(row);

    // Fall back: derive from player_intelligence when no snapshot exists.
    final intel = await _client
        .from('player_intelligence')
        .select('*, players(id, full_name, position)')
        .eq('player_id', playerId)
        .maybeSingle();

    if (intel != null) return _deriveRiskFromIntel(intel, playerId);
    throw Exception('No risk data for player: $playerId');
  }

  @override
  Future<List<RiskAnalysisModel>> fetchSquadRiskAnalysis(
      {String? clubId}) async {
    List<dynamic> rows;

    if (clubId != null && clubId.isNotEmpty) {
      // Step 1: collect player IDs for this club.
      final playerRows = await _client
          .from('players')
          .select('id')
          .eq('team_id', clubId);
      final ids = (playerRows as List)
          .map((r) => (r as Map<String, dynamic>)['id'].toString())
          .toList();
      if (ids.isEmpty) return [];

      rows = await _client
          .from('player_risk_analysis')
          .select('*, players(full_name, position)')
          .inFilter('player_id', ids)
          .order('analyzed_at', ascending: false);
    } else {
      rows = await _client
          .from('player_risk_analysis')
          .select('*, players(full_name, position)')
          .order('analyzed_at', ascending: false);
    }

    // De-duplicate: keep only the latest snapshot per player.
    final seen = <String>{};
    final results = <RiskAnalysisModel>[];
    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      final pid = (map['player_id'] ?? '').toString();
      if (seen.contains(pid)) continue;
      seen.add(pid);
      results.add(_mapRisk(map));
    }
    return results
      ..sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
  }

  @override
  Future<List<PlayerProfileModel>> fetchPlayersPaged({
    required int page,
    int pageSize = 20,
    String? query,
    String? position,
    String sortBy = 'rating',
    bool descending = true,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    var q = _client.from('players').select(_playerCols);
    if (query != null && query.isNotEmpty) {
      q = q.ilike('full_name', '%$query%');
    }
    if (position != null && position.isNotEmpty) {
      q = q.ilike('position', '%$position%');
    }

    final colMap = {
      'rating': 'season_rating',
      'goals': 'season_goals',
      'assists': 'season_assists',
      'tackles': 'season_tackles',
    };
    final col = colMap[sortBy] ?? 'season_rating';

    final rows = await q
        .order(col, ascending: !descending)
        .range(start, end);
    return (rows as List)
        .map((r) => _mapPlayer(r as Map<String, dynamic>))
        .toList();
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  PlayerProfileModel _mapPlayer(Map<String, dynamic> row) {
    final intelList = row['player_intelligence'];
    final intel = (intelList is List && intelList.isNotEmpty)
        ? intelList.first as Map<String, dynamic>
        : null;

    final id = (row['id'] ?? '').toString();
    final name = (row['full_name'] ?? '').toString();
    final position = (row['position'] ?? '').toString();
    final baseRating = (row['season_rating'] as num? ?? 7.0).toDouble();
    final goals = (row['season_goals'] as num? ?? 0).toInt();
    final assists = (row['season_assists'] as num? ?? 0).toInt();
    final tackles = (row['season_tackles'] as num? ?? 0).toInt();
    final appearances = (row['appearances'] as num? ?? 0).toInt();

    if (intel != null) {
      final insightsJson = (intel['insights'] as List?) ?? const [];
      final ratingsJson = (intel['ratings_history'] as List?) ?? const [];

      return PlayerProfileModel(
        id: id,
        name: name,
        position: position,
        currentRating:
            (intel['current_rating'] as num? ?? baseRating).toDouble(),
        averageRating:
            (intel['average_rating'] as num? ?? baseRating).toDouble(),
        fatigue: (intel['fatigue'] as num? ?? 50).toInt(),
        activityLevel: (intel['activity_level'] as num? ?? 80).toInt(),
        primaryContribution:
            (intel['primary_contribution'] ?? 'Balanced').toString(),
        secondaryContribution:
            (intel['secondary_contribution'] ?? 'Balanced').toString(),
        status: (intel['status'] ?? 'Stable').toString(),
        improvementRate:
            (intel['improvement_rate'] as num? ?? 0.0).toDouble(),
        trend: _parseTrend(intel['trend']?.toString()),
        totalMatches:
            (intel['total_matches'] as num? ?? appearances).toInt(),
        totalGoals: (intel['total_goals'] as num? ?? goals).toInt(),
        totalAssists: (intel['total_assists'] as num? ?? assists).toInt(),
        totalTackles:
            (intel['total_tackles'] as num? ?? tackles).toInt(),
        insights: insightsJson.map((e) => e.toString()).toList(),
        ratingsHistory:
            ratingsJson.map((e) => (e as num).toDouble()).toList(),
        matchHistory: const [],
      );
    }

    // No intelligence row yet — map basic season stats with defaults.
    return PlayerProfileModel(
      id: id,
      name: name,
      position: position,
      currentRating: baseRating,
      averageRating: baseRating,
      fatigue: 50,
      activityLevel: 80,
      primaryContribution: _inferContribution(position),
      secondaryContribution: 'Balanced',
      status: 'Stable',
      improvementRate: 0.0,
      trend: PerformanceTrend.stable,
      totalMatches: appearances,
      totalGoals: goals,
      totalAssists: assists,
      totalTackles: tackles,
      insights: const [],
      ratingsHistory: [baseRating],
      matchHistory: const [],
    );
  }

  RiskAnalysisModel _mapRisk(Map<String, dynamic> row) {
    final playerData = row['players'];
    final p = playerData is Map<String, dynamic> ? playerData : null;

    final recommendations = (row['recommendations'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();

    return RiskAnalysisModel(
      playerId: (row['player_id'] ?? '').toString(),
      playerName: (p?['full_name'] ?? '').toString(),
      position: (p?['position'] ?? '').toString(),
      fatigueRisk: (row['fatigue_risk'] as num? ?? 0).toDouble(),
      injuryRisk: (row['injury_risk'] as num? ?? 0).toDouble(),
      consistencyRisk: (row['consistency_risk'] as num? ?? 0).toDouble(),
      tacticalRisk: (row['tactical_risk'] as num? ?? 0).toDouble(),
      workloadScore: (row['workload_score'] as num? ?? 0).toDouble(),
      riskLevel: _parseRiskLevel(row['risk_level']?.toString()),
      recommendations: recommendations,
      analyzedAt:
          DateTime.tryParse((row['analyzed_at'] ?? '').toString()) ??
              DateTime.now(),
      nextMatchRiskFactor:
          (row['next_match_risk_factor'] as num? ?? 0).toDouble(),
      daysUntilFullRecovery:
          (row['days_until_full_recovery'] as num? ?? 0).toInt(),
    );
  }

  RiskAnalysisModel _deriveRiskFromIntel(
      Map<String, dynamic> intel, String playerId) {
    final fatigue = (intel['fatigue'] as num? ?? 50).toDouble();
    final injuryRisk = (intel['injury_risk'] ?? 20).toDouble();
    final p = intel['players'];
    final playerMap = p is Map<String, dynamic> ? p : null;

    return RiskAnalysisModel(
      playerId: playerId,
      playerName: (playerMap?['full_name'] ?? '').toString(),
      position: (playerMap?['position'] ?? '').toString(),
      fatigueRisk: fatigue,
      injuryRisk: injuryRisk.toDouble(),
      consistencyRisk: 20,
      tacticalRisk: 15,
      workloadScore: fatigue * 0.9,
      riskLevel: injuryRisk >= 70
          ? RiskLevel.critical
          : injuryRisk >= 50
              ? RiskLevel.high
              : injuryRisk >= 30
                  ? RiskLevel.medium
                  : RiskLevel.low,
      recommendations: const [
        'Monitor player condition before next fixture.',
      ],
      analyzedAt: DateTime.now(),
      nextMatchRiskFactor: injuryRisk / 100,
      daysUntilFullRecovery: injuryRisk > 50 ? 3 : 1,
    );
  }

  PerformanceTrend _parseTrend(String? value) => switch (value) {
        'improving' => PerformanceTrend.improving,
        'declining' => PerformanceTrend.declining,
        _ => PerformanceTrend.stable,
      };

  RiskLevel _parseRiskLevel(String? value) => switch (value) {
        'critical' => RiskLevel.critical,
        'high' => RiskLevel.high,
        'medium' => RiskLevel.medium,
        _ => RiskLevel.low,
      };

  String _inferContribution(String position) {
    final pos = position.toUpperCase();
    if (pos.contains('GK') ||
        pos.contains('CB') ||
        pos.contains('DEF') ||
        pos.contains('RB') ||
        pos.contains('LB')) {
      return 'Defense';
    }
    if (pos.contains('ST') ||
        pos.contains('ATT') ||
        pos.contains('FWD') ||
        pos.contains('RW') ||
        pos.contains('LW')) {
      return 'Attack';
    }
    return 'Balanced';
  }
}
