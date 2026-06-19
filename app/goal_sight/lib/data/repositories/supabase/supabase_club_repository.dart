// ---------------------------------------------------------------------------
// GoalSight — Supabase Club Repository
//
// Reads clubs from Supabase (teams + team_season_stats + players) and maps
// them into the ClubModel view-model the UI already consumes. Drop-in
// replacement for MockClubRepository behind IClubRepository.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../models/club_model.dart';
import '../interfaces/i_club_repository.dart';

final class SupabaseClubRepository implements IClubRepository {
  const SupabaseClubRepository();

  SupabaseClient get _client => Supabase.instance.client;

  // `players` has two FKs to `teams` (team_id + owner_club_id), so the embed
  // must name one explicitly or PostgREST returns a 300 ambiguity error. We use
  // the team_id relationship (the squad roster). For fans this resolves to an
  // empty list (players are club-private under RLS), which is expected.
  static const _columns =
      'id, name, stadium, league, country, founded_year, coach, '
      'playing_style, primary_color, description, '
      'team_season_stats(*), players!players_team_id_fkey(*)';

  static const _allClubsCacheKey = 'clubs:all';
  static const _clubCacheTtl = Duration(minutes: 10);

  @override
  Future<List<ClubModel>> fetchClubs({String? query}) async {
    // Serve from cache when no filter is applied.
    if (query == null || query.isEmpty) {
      final cached = CacheService.get<List<ClubModel>>(_allClubsCacheKey);
      if (cached != null) return cached;
    }

    final rows = await _client.from('teams').select(_columns);
    var clubs = (rows as List)
        .map((r) => _mapClub(r as Map<String, dynamic>))
        // Only real clubs (those with a season-stats row); skips stray teams.
        .whereType<ClubModel>()
        .toList();

    clubs.sort((a, b) => a.stats.ranking.compareTo(b.stats.ranking));

    if (query == null || query.isEmpty) {
      CacheService.set(_allClubsCacheKey, clubs, ttl: _clubCacheTtl);
    } else {
      final lower = query.toLowerCase();
      clubs = clubs
          .where((c) =>
              c.name.toLowerCase().contains(lower) ||
              c.league.toLowerCase().contains(lower))
          .toList();
    }
    return clubs;
  }

  @override
  Future<ClubModel> fetchClubById(String id) async {
    final cacheKey = 'clubs:$id';
    final cached = CacheService.get<ClubModel>(cacheKey);
    if (cached != null) return cached;

    final row = await _client
        .from('teams')
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    final club = row == null ? null : _mapClub(row);
    if (club == null) throw Exception('Club not found: $id');
    CacheService.set(cacheKey, club, ttl: _clubCacheTtl);
    return club;
  }

  @override
  Future<List<ClubModel>> fetchClubsPaged({
    required int page,
    int pageSize = 20,
    String? query,
    String sortBy = 'name',
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final rows = query != null && query.isNotEmpty
        ? await _client
            .from('teams')
            .select(_columns)
            .ilike('name', '%$query%')
            .order('name')
            .range(start, end)
        : await _client
            .from('teams')
            .select(_columns)
            .order('name')
            .range(start, end);

    final clubs = (rows as List)
        .map((r) => _mapClub(r as Map<String, dynamic>))
        .whereType<ClubModel>()
        .toList();

    switch (sortBy) {
      case 'ranking':
        clubs.sort((a, b) => a.stats.ranking.compareTo(b.stats.ranking));
      case 'points':
        clubs.sort((a, b) => b.stats.points.compareTo(a.stats.points));
      case 'name':
      default:
        clubs.sort((a, b) => a.name.compareTo(b.name));
    }
    return clubs;
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  /// Returns null for teams without a season-stats row (not real clubs yet).
  ClubModel? _mapClub(Map<String, dynamic> row) {
    final statsList = (row['team_season_stats'] as List?) ?? const [];
    if (statsList.isEmpty) return null;
    final stats = statsList.first as Map<String, dynamic>;

    final players = ((row['players'] as List?) ?? const [])
        .map((p) => _mapPlayer(p as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        if (a.isCaptain != b.isCaptain) return a.isCaptain ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });

    return ClubModel(
      id: row['id'].toString(),
      name: (row['name'] ?? '').toString(),
      stadium: (row['stadium'] ?? '').toString(),
      league: (row['league'] ?? '').toString(),
      primaryColor: _parseHexColor(row['primary_color']?.toString()),
      coach: (row['coach'] ?? '').toString(),
      foundedYear: (row['founded_year'] as num? ?? 0).toInt(),
      country: (row['country'] ?? '').toString(),
      playingStyle: (row['playing_style'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      stats: _mapStats(stats),
      players: players,
    );
  }

  ClubStats _mapStats(Map<String, dynamic> s) => ClubStats(
        matchesPlayed: (s['matches_played'] as num? ?? 0).toInt(),
        wins: (s['wins'] as num? ?? 0).toInt(),
        draws: (s['draws'] as num? ?? 0).toInt(),
        losses: (s['losses'] as num? ?? 0).toInt(),
        goalsScored: (s['goals_scored'] as num? ?? 0).toInt(),
        goalsConceded: (s['goals_conceded'] as num? ?? 0).toInt(),
        ranking: (s['ranking'] as num? ?? 0).toInt(),
        points: (s['points'] as num? ?? 0).toInt(),
        cleanSheets: (s['clean_sheets'] as num? ?? 0).toInt(),
        avgPossession: (s['avg_possession'] as num? ?? 0).toInt(),
        totalShots: (s['total_shots'] as num? ?? 0).toInt(),
        yellowCards: (s['yellow_cards'] as num? ?? 0).toInt(),
        redCards: (s['red_cards'] as num? ?? 0).toInt(),
      );

  ClubPlayer _mapPlayer(Map<String, dynamic> p) => ClubPlayer(
        id: p['id'].toString(),
        name: (p['full_name'] ?? '').toString(),
        position: (p['position'] ?? '').toString(),
        rating: (p['season_rating'] as num? ?? 0).toDouble(),
        nationality: (p['nationality'] ?? '').toString(),
        age: (p['age'] as num? ?? 0).toInt(),
        appearances: (p['appearances'] as num? ?? 0).toInt(),
        goals: (p['season_goals'] as num? ?? 0).toInt(),
        assists: (p['season_assists'] as num? ?? 0).toInt(),
        tackles: (p['season_tackles'] as num? ?? 0).toInt(),
        cleanSheets: (p['season_clean_sheets'] as num? ?? 0).toInt(),
        performanceSummary: (p['performance_summary'] ?? '').toString(),
        performanceTier: PlayerPerformanceTier.values.firstWhere(
          (e) => e.name == p['performance_tier'],
          orElse: () => PlayerPerformanceTier.average,
        ),
        marketValue: (p['market_value'] ?? '').toString(),
        isCaptain: p['is_captain'] == true,
      );

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF705AF5);
    var cleaned = hex.replaceFirst('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? const Color(0xFF705AF5) : Color(value);
  }
}
