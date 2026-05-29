// ---------------------------------------------------------------------------
// GoalSight — Club Data Models
//
// These models mirror the exact JSON shape the backend returns.
// When Supabase is connected, replace the mock provider with a real
// AsyncNotifierProvider calling [ClubModel.fromJson] — zero UI changes needed.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

// ─── Club Player ──────────────────────────────────────────────────────────────

/// Performance tier assigned by the AI after each match cycle.
enum PlayerPerformanceTier { elite, good, average, poor, critical }

class ClubPlayer {
  const ClubPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.rating,
    this.nationality = '',
    this.age = 0,
    this.appearances = 0,
    this.goals = 0,
    this.assists = 0,
    this.tackles = 0,
    this.cleanSheets = 0,
    this.performanceSummary = '',
    this.performanceTier = PlayerPerformanceTier.average,
    this.marketValue = '',
    this.isCaptain = false,
  });

  final String id;
  final String name;

  /// Short position code — e.g. "ST", "CAM", "CB", "GK"
  final String position;

  /// Season-average AI rating (0–10)
  final double rating;

  /// Nationality flag emoji — e.g. "🇪🇬"
  final String nationality;
  final int age;
  final int appearances;
  final int goals;
  final int assists;
  final int tackles;
  final int cleanSheets;

  /// Short AI-generated performance summary for the season.
  final String performanceSummary;

  final PlayerPerformanceTier performanceTier;

  /// Display market value — e.g. "€4.5M"
  final String marketValue;
  final bool isCaptain;

  // ── Convenience ────────────────────────────────────────────────────────────

  String get tierLabel {
    switch (performanceTier) {
      case PlayerPerformanceTier.elite:
        return 'Elite';
      case PlayerPerformanceTier.good:
        return 'Good';
      case PlayerPerformanceTier.average:
        return 'Average';
      case PlayerPerformanceTier.poor:
        return 'Poor';
      case PlayerPerformanceTier.critical:
        return 'Critical';
    }
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory ClubPlayer.fromJson(Map<String, dynamic> json) {
    return ClubPlayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      nationality: json['nationality']?.toString() ?? '',
      age: (json['age'] as num? ?? 0).toInt(),
      appearances: (json['appearances'] as num? ?? 0).toInt(),
      goals: (json['goals'] as num? ?? 0).toInt(),
      assists: (json['assists'] as num? ?? 0).toInt(),
      tackles: (json['tackles'] as num? ?? 0).toInt(),
      cleanSheets: (json['clean_sheets'] as num? ?? 0).toInt(),
      performanceSummary: json['performance_summary']?.toString() ?? '',
      performanceTier: PlayerPerformanceTier.values.firstWhere(
        (e) => e.name == json['performance_tier'],
        orElse: () => PlayerPerformanceTier.average,
      ),
      marketValue: json['market_value']?.toString() ?? '',
      isCaptain: json['is_captain'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position,
        'rating': rating,
        'nationality': nationality,
        'age': age,
        'appearances': appearances,
        'goals': goals,
        'assists': assists,
        'tackles': tackles,
        'clean_sheets': cleanSheets,
        'performance_summary': performanceSummary,
        'performance_tier': performanceTier.name,
        'market_value': marketValue,
        'is_captain': isCaptain,
      };
}

// ─── Club Stats ───────────────────────────────────────────────────────────────

class ClubStats {
  const ClubStats({
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsScored,
    required this.goalsConceded,
    required this.ranking,
    required this.points,
    this.cleanSheets = 0,
    this.avgPossession = 0,
    this.totalShots = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsScored;
  final int goalsConceded;
  final int ranking;
  final int points;
  final int cleanSheets;

  /// Average possession % across all matches
  final int avgPossession;
  final int totalShots;
  final int yellowCards;
  final int redCards;

  // ── Computed ───────────────────────────────────────────────────────────────

  int get goalDifference => goalsScored - goalsConceded;
  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory ClubStats.fromJson(Map<String, dynamic> json) {
    return ClubStats(
      matchesPlayed: (json['matches_played'] as num? ?? 0).toInt(),
      wins: (json['wins'] as num? ?? 0).toInt(),
      draws: (json['draws'] as num? ?? 0).toInt(),
      losses: (json['losses'] as num? ?? 0).toInt(),
      goalsScored: (json['goals_scored'] as num? ?? 0).toInt(),
      goalsConceded: (json['goals_conceded'] as num? ?? 0).toInt(),
      ranking: (json['ranking'] as num? ?? 0).toInt(),
      points: (json['points'] as num? ?? 0).toInt(),
      cleanSheets: (json['clean_sheets'] as num? ?? 0).toInt(),
      avgPossession: (json['avg_possession'] as num? ?? 0).toInt(),
      totalShots: (json['total_shots'] as num? ?? 0).toInt(),
      yellowCards: (json['yellow_cards'] as num? ?? 0).toInt(),
      redCards: (json['red_cards'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'matches_played': matchesPlayed,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goals_scored': goalsScored,
        'goals_conceded': goalsConceded,
        'ranking': ranking,
        'points': points,
        'clean_sheets': cleanSheets,
        'avg_possession': avgPossession,
        'total_shots': totalShots,
        'yellow_cards': yellowCards,
        'red_cards': redCards,
      };
}

// ─── Club Model ───────────────────────────────────────────────────────────────

class ClubModel {
  const ClubModel({
    required this.id,
    required this.name,
    required this.stadium,
    required this.league,
    required this.primaryColor,
    required this.players,
    required this.stats,
    this.logo,
    this.foundedYear = 0,
    this.country = '',
    this.isFavorite = false,
    this.coach = '',
    this.playingStyle = '',
    this.description = '',
  });

  final String id;
  final String name;
  final String stadium;
  final String league;

  /// Brand color used across the UI for club theming
  final Color primaryColor;

  final List<ClubPlayer> players;
  final ClubStats stats;

  /// URL or asset path. Null = fall back to [abbreviation] initials.
  final String? logo;

  final int foundedYear;
  final String country;
  final bool isFavorite;
  final String coach;

  /// E.g. "High Press 4-3-3", "Counter-attack 4-4-2"
  final String playingStyle;

  /// Short club description or motto
  final String description;

  // ── Convenience ────────────────────────────────────────────────────────────

  /// Two-letter initials for the logo placeholder.
  String get abbreviation =>
      name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase();

  ClubPlayer? get captain {
    try {
      return players.firstWhere((p) => p.isCaptain);
    } catch (_) {
      return null;
    }
  }

  double get squadAvgRating {
    if (players.isEmpty) return 0;
    return players.fold(0.0, (sum, p) => sum + p.rating) / players.length;
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory ClubModel.fromJson(Map<String, dynamic> json, {Color primaryColor = Colors.grey}) {
    return ClubModel(
      id: json['club_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      stadium: json['stadium']?.toString() ?? '',
      league: json['league']?.toString() ?? '',
      primaryColor: primaryColor, // color comes from UI theme, not JSON
      players: (json['players'] as List? ?? [])
          .map((p) => ClubPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      stats: ClubStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      logo: json['logo']?.toString(),
      foundedYear: (json['founded_year'] as num? ?? 0).toInt(),
      country: json['country']?.toString() ?? '',
      coach: json['coach']?.toString() ?? '',
      playingStyle: json['playing_style']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'club_id': id,
        'name': name,
        'stadium': stadium,
        'league': league,
        'logo': logo,
        'founded_year': foundedYear,
        'country': country,
        'coach': coach,
        'playing_style': playingStyle,
        'description': description,
        'stats': stats.toJson(),
        'players': players.map((p) => p.toJson()).toList(),
      };
}
