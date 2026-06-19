// ---------------------------------------------------------------------------
// GoalSight — Supabase Player Repository
//
// Reads players from Supabase (players + player_intelligence) and maps them
// to PlayerProfileModel / RiskAnalysisModel. Falls back to sensible defaults
// when enriched intelligence rows are not yet seeded.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../models/player_heatmap_model.dart';
import '../../models/player_profile_model.dart';
import '../../models/risk_analysis_model.dart';
import '../interfaces/i_player_repository.dart';

final class SupabasePlayerRepository implements IPlayerRepository {
  const SupabasePlayerRepository();

  SupabaseClient get _client => Supabase.instance.client;

  static const _playerCols =
      'id, full_name, position, team_id, jersey_number, age, height_cm, '
      'weight_kg, nationality, market_value, is_captain, '
      'season_rating, season_goals, '
      'season_assists, season_tackles, appearances, '
      'player_intelligence(current_rating, average_rating, fatigue, '
      'activity_level, primary_contribution, secondary_contribution, '
      'trend, status, improvement_rate, insights, ratings_history, '
      'total_matches, total_goals, total_assists, total_tackles)';

  static const _cacheTtl = Duration(minutes: 8);

  // ── IPlayerRepository ─────────────────────────────────────────────────────

  @override
  Future<List<PlayerMatchHeatmap>> fetchPlayerHeatmaps(String playerId) async {
    // All of a player's per-match heatmaps, joined to the parent match for a
    // label. RLS scopes this to the caller's club.
    final rows = await _client
        .from('match_player_analysis')
        .select(
            'heatmap_url, match_analyses(home_team_name, away_team_name, date_label, created_at)')
        .eq('player_id', playerId)
        .not('heatmap_url', 'is', null);

    final list = (rows as List).cast<Map<String, dynamic>>().map((r) {
      final m = (r['match_analyses'] as Map?)?.cast<String, dynamic>() ?? const {};
      final home = (m['home_team_name'] ?? '').toString();
      final away = (m['away_team_name'] ?? '').toString();
      final label = (home.isNotEmpty && away.isNotEmpty)
          ? '$home vs $away'
          : 'Match heatmap';
      return (
        heatmap: PlayerMatchHeatmap(
          matchLabel: label,
          dateLabel: (m['date_label'] ?? '').toString(),
          url: (r['heatmap_url'] ?? '').toString(),
        ),
        createdAt: (m['created_at'] ?? '').toString(),
      );
    }).where((e) => e.heatmap.url.isNotEmpty).toList()
      // Newest match first.
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list.map((e) => e.heatmap).toList();
  }

  @override
  Future<List<PlayerMatchHistory>> fetchPlayerMatchHistory(
      String playerId) async {
    // Per-match verdicts for this player, joined to the parent match for
    // teams/date. RLS scopes this to the caller's club.
    final rows = await _client
        .from('match_player_analysis')
        .select(
            'rating, performance_status, goals, assists, tackles, key_passes, '
            'match_analyses(id, home_team_name, away_team_name, date_label, created_at)')
        .eq('player_id', playerId);

    final list = (rows as List).cast<Map<String, dynamic>>().map((r) {
      final m =
          (r['match_analyses'] as Map?)?.cast<String, dynamic>() ?? const {};
      final createdAt = (m['created_at'] ?? '').toString();
      return (
        history: PlayerMatchHistory(
          matchId: (m['id'] ?? '').toString(),
          matchDate: DateTime.tryParse(createdAt) ?? DateTime.now(),
          homeTeam: (m['home_team_name'] ?? '').toString(),
          awayTeam: (m['away_team_name'] ?? '').toString(),
          playerRating: (r['rating'] as num? ?? 0).toDouble(),
          performanceStatus: (r['performance_status'] ?? '').toString(),
          goals: (r['goals'] as num? ?? 0).toInt(),
          assists: (r['assists'] as num? ?? 0).toInt(),
          tackles: (r['tackles'] as num? ?? 0).toInt(),
          keyPasses: (r['key_passes'] as num? ?? 0).toInt(),
        ),
        createdAt: createdAt,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list.map((e) => e.history).toList();
  }

  @override
  Future<List<PlayerProfileModel>> fetchSquad({String? clubId}) async {
    final cacheKey = 'squad:${clubId ?? 'all'}';
    final cached = CacheService.get<List<PlayerProfileModel>>(cacheKey);
    if (cached != null) return cached;

    var query = _client.from('players').select(_playerCols);
    if (clubId != null && clubId.isNotEmpty) {
      // Tenant scope: a club's own squad (RLS also enforces this).
      query = query.eq('owner_club_id', clubId);
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
          .eq('owner_club_id', clubId);
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
  Future<PlayerProfileModel> createPlayer({
    required String fullName,
    required String position,
    required String clubId,
    int? jerseyNumber,
    int? age,
    int? heightCm,
    int? weightKg,
    String? nationality,
    String? marketValue,
    bool isCaptain = false,
  }) async {
    // owner_club_id is stamped automatically by the DB trigger (the caller's
    // club); team_id is set explicitly so the player also belongs to the club
    // roster. RLS guarantees the player is only visible to this club's staff.
    final inserted = await _client
        .from('players')
        .insert({
          'full_name': fullName,
          'position': position,
          'team_id': clubId,
          if (jerseyNumber != null) 'jersey_number': jerseyNumber,
          if (age != null) 'age': age,
          if (heightCm != null) 'height_cm': heightCm,
          if (weightKg != null) 'weight_kg': weightKg,
          if (nationality != null && nationality.isNotEmpty)
            'nationality': nationality,
          if (marketValue != null && marketValue.isNotEmpty)
            'market_value': marketValue,
          'is_captain': isCaptain,
          'season_rating': 6.0,
          'season_goals': 0,
          'season_assists': 0,
          'season_tackles': 0,
          'appearances': 0,
        })
        .select(_playerCols)
        .single();
    CacheService.invalidatePrefix('squad:');
    return _mapPlayer(inserted);
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

    // Player bio / physical attributes (nullable — may be unset).
    final jerseyNumber = (row['jersey_number'] as num?)?.toInt();
    final age = (row['age'] as num?)?.toInt();
    final heightCm = (row['height_cm'] as num?)?.toInt();
    final weightKg = (row['weight_kg'] as num?)?.toInt();
    final nationality = (row['nationality'] as String?)?.trim();
    final marketValue = (row['market_value'] as String?)?.trim();
    final isCaptain = row['is_captain'] == true;

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
        jerseyNumber: jerseyNumber,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        nationality: nationality,
        marketValue: marketValue,
        isCaptain: isCaptain,
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
