// ---------------------------------------------------------------------------
// GoalSight — Mock Club Repository
//
// Realistic mock implementation with fake network delays and pagination.
// Replace this with SupabaseClubRepository when backend is ready.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../models/club_model.dart';
import '../interfaces/i_club_repository.dart';

final class MockClubRepository implements IClubRepository {
  const MockClubRepository();

  static const _networkDelay = Duration(milliseconds: 480);

  // ── Static dataset ────────────────────────────────────────────────────────

  static final List<ClubModel> _clubs = [
    ClubModel(
      id: 'club_01',
      name: 'GoalSight FC',
      stadium: 'Analytics Arena',
      league: 'Premier League',
      primaryColor: const Color(0xFF705AF5),
      coach: 'Jurgen Klopp',
      foundedYear: 1992,
      country: 'England',
      playingStyle: 'High-Press 4-3-3',
      description: 'An elite intelligence-driven club built on data and pressing.',
      stats: const ClubStats(
        matchesPlayed: 38,
        wins: 24,
        draws: 8,
        losses: 6,
        goalsScored: 72,
        goalsConceded: 31,
        ranking: 2,
        points: 80,
        cleanSheets: 14,
        avgPossession: 62,
        totalShots: 487,
        yellowCards: 52,
        redCards: 3,
      ),
      players: _goalsightSquad,
    ),
    ClubModel(
      id: 'club_02',
      name: 'Falcons United',
      stadium: 'Falcon Park',
      league: 'Premier League',
      primaryColor: const Color(0xFF2DE2E6),
      coach: 'Carlo Ancelotti',
      foundedYear: 1910,
      country: 'England',
      playingStyle: 'Counter-Attack 4-4-2',
      description: 'A resilient defensive unit with lethal counter-attacking pace.',
      stats: const ClubStats(
        matchesPlayed: 38,
        wins: 18,
        draws: 10,
        losses: 10,
        goalsScored: 54,
        goalsConceded: 42,
        ranking: 5,
        points: 64,
        cleanSheets: 10,
        avgPossession: 48,
        totalShots: 392,
        yellowCards: 67,
        redCards: 5,
      ),
      players: _falconsSquad,
    ),
    ClubModel(
      id: 'club_03',
      name: 'City Panthers',
      stadium: 'Panther Stadium',
      league: 'Premier League',
      primaryColor: const Color(0xFF70F59A),
      coach: 'Pep Guardiola',
      foundedYear: 1935,
      country: 'England',
      playingStyle: 'Positional Play 4-2-3-1',
      description: 'Dominant possession maestros with surgical attacking transitions.',
      stats: const ClubStats(
        matchesPlayed: 38,
        wins: 28,
        draws: 6,
        losses: 4,
        goalsScored: 89,
        goalsConceded: 26,
        ranking: 1,
        points: 90,
        cleanSheets: 18,
        avgPossession: 67,
        totalShots: 542,
        yellowCards: 44,
        redCards: 1,
      ),
      players: _panthersSquad,
    ),
    ClubModel(
      id: 'club_04',
      name: 'Red Lions FC',
      stadium: 'Lion Fortress',
      league: 'Championship',
      primaryColor: const Color(0xFFFF6B8A),
      coach: 'Thomas Tuchel',
      foundedYear: 1948,
      country: 'England',
      playingStyle: 'Direct Play 4-4-2',
      description: 'Physical and direct with strong set-piece routines.',
      stats: const ClubStats(
        matchesPlayed: 46,
        wins: 22,
        draws: 12,
        losses: 12,
        goalsScored: 65,
        goalsConceded: 48,
        ranking: 4,
        points: 78,
        cleanSheets: 12,
        avgPossession: 45,
        totalShots: 418,
        yellowCards: 82,
        redCards: 6,
      ),
      players: _redLionsSquad,
    ),
    ClubModel(
      id: 'club_05',
      name: 'Thunder Athletic',
      stadium: 'Thunder Dome',
      league: 'Championship',
      primaryColor: const Color(0xFFFFC857),
      coach: 'Xabi Alonso',
      foundedYear: 1963,
      country: 'England',
      playingStyle: 'High Line 3-4-3',
      description: 'Innovative with a young and dynamic squad pushing boundaries.',
      stats: const ClubStats(
        matchesPlayed: 46,
        wins: 26,
        draws: 10,
        losses: 10,
        goalsScored: 74,
        goalsConceded: 44,
        ranking: 3,
        points: 88,
        cleanSheets: 15,
        avgPossession: 58,
        totalShots: 468,
        yellowCards: 59,
        redCards: 4,
      ),
      players: _thunderSquad,
    ),
  ];

  // ── Squads ────────────────────────────────────────────────────────────────

  static const List<ClubPlayer> _goalsightSquad = [
    ClubPlayer(id: 'gs_p1', name: 'Mo Salah', position: 'RW', rating: 9.1, nationality: '🇪🇬', age: 31, appearances: 36, goals: 24, assists: 14, tackles: 48, performanceTier: PlayerPerformanceTier.elite, marketValue: '€75M', isCaptain: false, performanceSummary: 'World-class right winger dominating every match with pace and precision.'),
    ClubPlayer(id: 'gs_p2', name: 'Kevin De Bruyne', position: 'CM', rating: 9.3, nationality: '🇧🇪', age: 32, appearances: 30, goals: 8, assists: 22, tackles: 72, performanceTier: PlayerPerformanceTier.elite, marketValue: '€65M', isCaptain: true, performanceSummary: 'Elite playmaker orchestrating every attack with visionary passing.'),
    ClubPlayer(id: 'gs_p3', name: 'Virgil van Dijk', position: 'CB', rating: 8.9, nationality: '🇳🇱', age: 32, appearances: 35, goals: 4, assists: 3, tackles: 112, cleanSheets: 14, performanceTier: PlayerPerformanceTier.elite, marketValue: '€50M', performanceSummary: 'Commanding centre-back with elite aerial and leadership qualities.'),
    ClubPlayer(id: 'gs_p4', name: 'Bukayo Saka', position: 'RW', rating: 8.7, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 22, appearances: 34, goals: 18, assists: 11, tackles: 55, performanceTier: PlayerPerformanceTier.elite, marketValue: '€120M', performanceSummary: 'Dynamic winger with remarkable dribbling and relentless work rate.'),
    ClubPlayer(id: 'gs_p5', name: 'Phil Foden', position: 'CAM', rating: 8.8, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 24, appearances: 32, goals: 15, assists: 13, tackles: 38, performanceTier: PlayerPerformanceTier.elite, marketValue: '€110M', performanceSummary: 'Creative genius with unmatched ball mastery and spatial awareness.'),
    ClubPlayer(id: 'gs_p6', name: 'Declan Rice', position: 'CDM', rating: 8.5, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 25, appearances: 35, goals: 4, assists: 6, tackles: 148, performanceTier: PlayerPerformanceTier.good, marketValue: '€90M', performanceSummary: 'Tireless defensive midfielder with exceptional pressing and interception stats.'),
    ClubPlayer(id: 'gs_p7', name: 'Erling Haaland', position: 'ST', rating: 9.4, nationality: '🇳🇴', age: 23, appearances: 31, goals: 36, assists: 5, tackles: 18, performanceTier: PlayerPerformanceTier.elite, marketValue: '€180M', performanceSummary: 'Unstoppable predator with elite finishing, aerial dominance, and sprint speed.'),
    ClubPlayer(id: 'gs_p8', name: 'Trent Alexander-Arnold', position: 'RB', rating: 8.6, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 25, appearances: 34, goals: 3, assists: 18, tackles: 86, performanceTier: PlayerPerformanceTier.elite, marketValue: '€80M', performanceSummary: 'Elite attacking fullback with a world-class range of passing and set-piece delivery.'),
  ];

  static const List<ClubPlayer> _falconsSquad = [
    ClubPlayer(id: 'f_p1', name: 'Marcus Webb', position: 'GK', rating: 7.9, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 29, appearances: 38, goals: 0, assists: 0, tackles: 0, cleanSheets: 10, performanceTier: PlayerPerformanceTier.good, marketValue: '€12M', performanceSummary: 'Reliable shot-stopper with strong positioning and claim rate.'),
    ClubPlayer(id: 'f_p2', name: 'Jake Morrison', position: 'ST', rating: 8.1, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 26, appearances: 36, goals: 22, assists: 8, tackles: 24, performanceTier: PlayerPerformanceTier.good, marketValue: '€28M', performanceSummary: 'Powerful striker with excellent link-up play and aerial threat.'),
    ClubPlayer(id: 'f_p3', name: 'Carlos Diaz', position: 'CM', rating: 7.8, nationality: '🇨🇴', age: 28, appearances: 32, goals: 5, assists: 9, tackles: 98, performanceTier: PlayerPerformanceTier.good, marketValue: '€18M', performanceSummary: 'Box-to-box midfielder with stamina and an eye for through balls.'),
    ClubPlayer(id: 'f_p4', name: 'Luis Ferreira', position: 'CB', rating: 7.6, nationality: '🇵🇹', age: 27, appearances: 35, goals: 2, assists: 1, tackles: 104, performanceTier: PlayerPerformanceTier.average, marketValue: '€15M', performanceSummary: 'Solid defender known for reading the game and smart positioning.'),
  ];

  static const List<ClubPlayer> _panthersSquad = [
    ClubPlayer(id: 'cp_p1', name: 'Rodri Manzano', position: 'CDM', rating: 9.2, nationality: '🇪🇸', age: 27, appearances: 35, goals: 8, assists: 12, tackles: 168, performanceTier: PlayerPerformanceTier.elite, marketValue: '€120M', isCaptain: true, performanceSummary: 'Best midfielder in the world — complete domination in every phase.'),
    ClubPlayer(id: 'cp_p2', name: 'Jamal Wright', position: 'LW', rating: 8.9, nationality: '🇩🇪', age: 21, appearances: 33, goals: 20, assists: 16, tackles: 42, performanceTier: PlayerPerformanceTier.elite, marketValue: '€150M', performanceSummary: 'Explosive left winger with devastating pace and technical brilliance.'),
    ClubPlayer(id: 'cp_p3', name: 'Nathan Stones', position: 'CB', rating: 8.6, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 24, appearances: 36, goals: 3, assists: 2, tackles: 132, performanceTier: PlayerPerformanceTier.elite, marketValue: '€60M', performanceSummary: 'Modern centre-back combining defensive solidity with progressive passing.'),
    ClubPlayer(id: 'cp_p4', name: 'Bernardo Costa', position: 'CAM', rating: 8.8, nationality: '🇵🇹', age: 29, appearances: 34, goals: 11, assists: 19, tackles: 58, performanceTier: PlayerPerformanceTier.elite, marketValue: '€70M', performanceSummary: 'Intelligent creative midfielder with exceptional touch and work rate.'),
  ];

  static const List<ClubPlayer> _redLionsSquad = [
    ClubPlayer(id: 'rl_p1', name: 'Diego Santos', position: 'ST', rating: 8.0, nationality: '🇧🇷', age: 28, appearances: 44, goals: 26, assists: 6, tackles: 22, performanceTier: PlayerPerformanceTier.good, marketValue: '€32M', performanceSummary: 'Physical targetman with excellent hold-up play and heading ability.'),
    ClubPlayer(id: 'rl_p2', name: 'Sam Clarke', position: 'CM', rating: 7.7, nationality: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', age: 26, appearances: 42, goals: 6, assists: 11, tackles: 118, performanceTier: PlayerPerformanceTier.good, marketValue: '€14M', performanceSummary: 'Consistent midfielder linking defence and attack with efficiency.'),
    ClubPlayer(id: 'rl_p3', name: 'Ahmed Hassan', position: 'RW', rating: 7.9, nationality: '🇪🇬', age: 24, appearances: 40, goals: 14, assists: 9, tackles: 66, performanceTier: PlayerPerformanceTier.good, marketValue: '€22M', performanceSummary: 'Quick and tricky winger capable of beating defenders on the outside.'),
  ];

  static const List<ClubPlayer> _thunderSquad = [
    ClubPlayer(id: 'th_p1', name: 'Luca Romano', position: 'CAM', rating: 8.3, nationality: '🇮🇹', age: 22, appearances: 43, goals: 17, assists: 20, tackles: 44, performanceTier: PlayerPerformanceTier.elite, marketValue: '€48M', performanceSummary: 'Elegant number 10 with elite vision and an electric dribbling style.'),
    ClubPlayer(id: 'th_p2', name: 'Erik Larsson', position: 'CB', rating: 8.1, nationality: '🇸🇪', age: 25, appearances: 45, goals: 5, assists: 3, tackles: 142, performanceTier: PlayerPerformanceTier.good, marketValue: '€25M', performanceSummary: 'Ball-playing centre-back comfortable under pressure from high press.'),
    ClubPlayer(id: 'th_p3', name: 'Omar Ndiaye', position: 'ST', rating: 8.4, nationality: '🇸🇳', age: 24, appearances: 42, goals: 28, assists: 7, tackles: 28, performanceTier: PlayerPerformanceTier.elite, marketValue: '€55M', performanceSummary: 'Rapid striker with exceptional movement and clinical finishing.'),
  ];

  // ── IClubRepository ───────────────────────────────────────────────────────

  @override
  Future<List<ClubModel>> fetchClubs({String? query}) async {
    await Future.delayed(_networkDelay);
    if (query == null || query.isEmpty) return List.unmodifiable(_clubs);
    final lower = query.toLowerCase();
    return _clubs
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            c.league.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<ClubModel> fetchClubById(String id) async {
    await Future.delayed(_networkDelay);
    return _clubs.firstWhere(
      (c) => c.id == id,
      orElse: () => throw RepositoryException('Club not found: $id'),
    );
  }

  @override
  Future<List<ClubModel>> fetchClubsPaged({
    required int page,
    int pageSize = 20,
    String? query,
    String sortBy = 'name',
  }) async {
    await Future.delayed(_networkDelay);
    var list = await fetchClubs(query: query);

    // Sorting
    switch (sortBy) {
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
      case 'ranking':
        list.sort((a, b) => a.stats.ranking.compareTo(b.stats.ranking));
      case 'points':
        list.sort((a, b) => b.stats.points.compareTo(a.stats.points));
    }

    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }
}

// ---------------------------------------------------------------------------
// Shared exception used by all mock repositories
// ---------------------------------------------------------------------------

class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;

  @override
  String toString() => 'RepositoryException: $message';
}
