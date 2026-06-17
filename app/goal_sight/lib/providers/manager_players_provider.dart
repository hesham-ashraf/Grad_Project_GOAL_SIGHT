// ---------------------------------------------------------------------------
// GoalSight — Manager Players Provider
//
// Loads the manager's squad directly from Supabase using the club_id stored
// in UserModel after login. No hardcoded club names.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/player_profile_model.dart';
import 'app_providers.dart';
import 'repository_providers.dart';

/// The club_id of the signed-in manager (or null if not yet loaded).
final managerClubIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.user?.clubId;
});

/// All players for the manager's club, loaded from Supabase.
/// Returns an empty list while loading or if club_id is not set.
final managerPlayersProvider = FutureProvider<List<PlayerProfileModel>>((ref) async {
  final clubId = ref.watch(managerClubIdProvider);
  if (clubId == null || clubId.isEmpty) return const [];
  return ref.watch(squadProvider(clubId).future);
});
