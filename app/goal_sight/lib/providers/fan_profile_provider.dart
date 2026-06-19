// ---------------------------------------------------------------------------
// GoalSight — Fan Profile Provider
//
// Loads the signed-in fan's gamification + favourites data from Supabase
// (fan_stats, achievements, user_achievements, user_favorite_teams) and exposes
// it as [FanProfileData] for the fan profile screen.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/fan_profile_model.dart';

/// Maps an `achievements.icon` string to a Material icon.
IconData _achievementIcon(String key) {
  switch (key) {
    case 'login':
      return Icons.login_rounded;
    case 'sports_soccer':
      return Icons.sports_soccer_rounded;
    case 'analytics':
      return Icons.analytics_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'dark_mode':
      return Icons.dark_mode_rounded;
    case 'workspace_premium':
      return Icons.workspace_premium_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}

Color _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF705AF5);
  var cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? const Color(0xFF705AF5) : Color(value);
}

/// Everything the fan profile screen needs, for the signed-in user.
final fanProfileProvider =
    FutureProvider.autoDispose<FanProfileData>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return FanProfileData.empty;

  // Run the independent reads concurrently.
  final results = await Future.wait([
    client.from('fan_stats').select().eq('user_id', uid).maybeSingle(),
    client.from('achievements').select().order('sort_order'),
    client.from('user_achievements').select('achievement_id').eq('user_id', uid),
    client
        .from('user_favorite_teams')
        .select('team_id, teams(name, primary_color)')
        .eq('user_id', uid),
    client.from('saved_matches').select('id').eq('user_id', uid),
  ]);

  final stats = results[0] as Map<String, dynamic>?;
  final catalog = (results[1] as List).cast<Map<String, dynamic>>();
  final unlockedRows = (results[2] as List).cast<Map<String, dynamic>>();
  final favRows = (results[3] as List).cast<Map<String, dynamic>>();
  final savedRows = results[4] as List;

  final unlockedIds = {
    for (final r in unlockedRows) r['achievement_id'].toString(),
  };

  final achievements = catalog
      .map((a) => FanAchievement(
            id: a['id'].toString(),
            title: (a['title'] ?? '').toString(),
            description: (a['description'] ?? '').toString(),
            icon: _achievementIcon((a['icon'] ?? '').toString()),
            unlocked: unlockedIds.contains(a['id'].toString()),
          ))
      .toList();

  final favoriteClubs = favRows.map((r) {
    final team = r['teams'] as Map<String, dynamic>?;
    return FanFavoriteClub(
      id: r['team_id'].toString(),
      name: (team?['name'] ?? 'Club').toString(),
      color: _parseHexColor(team?['primary_color']?.toString()),
    );
  }).toList();

  return FanProfileData(
    xp: (stats?['xp'] as num? ?? 0).toInt(),
    xpToNext: (stats?['xp_to_next'] as num? ?? 1000).toInt(),
    tier: (stats?['level_tier'] ?? 'Bronze').toString(),
    matchesViewed: (stats?['matches_viewed'] as num? ?? 0).toInt(),
    analysesRead: (stats?['analyses_read'] as num? ?? 0).toInt(),
    savedMatches: savedRows.length,
    favoriteClubs: favoriteClubs,
    achievements: achievements,
  );
});
