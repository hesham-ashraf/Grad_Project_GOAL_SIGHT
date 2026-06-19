// ---------------------------------------------------------------------------
// GoalSight — Fan Profile Model
//
// Real, DB-backed gamification data for the fan profile screen, replacing the
// previously hard-coded XP/badge/achievement values. Sourced from the
// `fan_stats`, `achievements`, `user_achievements` and `user_favorite_teams`
// tables (migration 051).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// One achievement and whether the current user has unlocked it.
class FanAchievement {
  const FanAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}

/// A club the user follows (favourite team).
class FanFavoriteClub {
  const FanFavoriteClub({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;

  /// 3-letter abbreviation for chips (e.g. "ALA" for AlAhly).
  String get abbr {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return cleaned.substring(0, cleaned.length >= 3 ? 3 : cleaned.length).toUpperCase();
  }
}

/// Aggregate of everything the fan profile screen needs.
class FanProfileData {
  const FanProfileData({
    required this.xp,
    required this.xpToNext,
    required this.tier,
    required this.matchesViewed,
    required this.analysesRead,
    required this.savedMatches,
    required this.favoriteClubs,
    required this.achievements,
  });

  final int xp;
  final int xpToNext;
  final String tier;
  final int matchesViewed;
  final int analysesRead;
  final int savedMatches;
  final List<FanFavoriteClub> favoriteClubs;
  final List<FanAchievement> achievements;

  int get clubsFollowed => favoriteClubs.length;
  int get unlockedAchievements => achievements.where((a) => a.unlocked).length;
  double get xpProgress =>
      xpToNext <= 0 ? 0 : (xp / xpToNext).clamp(0.0, 1.0);

  static const empty = FanProfileData(
    xp: 0,
    xpToNext: 1000,
    tier: 'Bronze',
    matchesViewed: 0,
    analysesRead: 0,
    savedMatches: 0,
    favoriteClubs: [],
    achievements: [],
  );
}
