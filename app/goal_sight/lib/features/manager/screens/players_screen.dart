/// ---------------------------------------------------------------------------
/// GoalSight — Players Screen
///
/// Displays a list of all players under the manager's club.
/// Features: filtering by position, sorting by rating, navigation to profiles.
/// Loads real player data from club roster (no mock data).
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/data/models/player_profile_model.dart';
import 'package:goal_sight/features/manager/widgets/player_list_card.dart';
import 'package:goal_sight/presentation/state_management/manager_players_provider.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  String _selectedPosition = 'All';

  void _setPositionFilter(String position) {
    setState(() => _selectedPosition = position);
  }

  void _openPlayerProfile(PlayerProfileModel player) {
    context.push('/manager-player-profile', extra: player);
  }

  @override
  Widget build(BuildContext context) {
    // Get all players from manager's club
    final allPlayers = ref.watch(managerPlayersProvider);

    // Compute filtered list locally to avoid late-init state issues
    final List<PlayerProfileModel> filteredPlayers =
        (_selectedPosition == 'All')
            ? List.from(allPlayers)
            : allPlayers
                .where((p) => p.position.contains(_selectedPosition))
                .toList();
    filteredPlayers.sort((a, b) => b.currentRating.compareTo(a.currentRating));
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundAlt,
        elevation: 0,
        title: Text(
          'Players',
          style: AppTextStyles.headline(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Squad Overview',
                          style: AppTextStyles.title(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: context.rs(AppSpacing.xs)),
                        Text(
                          '${filteredPlayers.length} players',
                          style: AppTextStyles.body(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(AppSpacing.md),
                        vertical: context.rs(AppSpacing.sm),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(
                          color: AppColors.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppColors.warning,
                            size: context.rs(16),
                          ),
                          SizedBox(width: context.rs(AppSpacing.xs)),
                          Text(
                            'Avg: ${allPlayers.isEmpty ? '0.00' : (allPlayers.map((p) => p.currentRating).reduce((a, b) => a + b) / allPlayers.length).toStringAsFixed(2)}',
                            style: AppTextStyles.caption(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(AppSpacing.lg)),

                // Position Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedPosition == 'All'),
                      SizedBox(width: context.rs(AppSpacing.sm)),
                      _buildFilterChip('DEF', _selectedPosition == 'DEF'),
                      SizedBox(width: context.rs(AppSpacing.sm)),
                      _buildFilterChip('MID', _selectedPosition == 'MID'),
                      SizedBox(width: context.rs(AppSpacing.sm)),
                      _buildFilterChip('ATT', _selectedPosition == 'ATT'),
                      SizedBox(width: context.rs(AppSpacing.sm)),
                      _buildFilterChip('GK', _selectedPosition == 'GK'),
                    ],
                  ),
                ),
                SizedBox(height: context.rs(AppSpacing.lg)),

                // Players List
                if (filteredPlayers.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.rs(AppSpacing.xxl),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            color: AppColors.textMuted,
                            size: context.rs(48),
                          ),
                          SizedBox(height: context.rs(AppSpacing.md)),
                          Text(
                            'No players found',
                            style: AppTextStyles.body(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: filteredPlayers.map((player) {
                      return PlayerListCard(
                        player: player,
                        onTap: () => _openPlayerProfile(player),
                      );
                    }).toList(),
                  ),
                SizedBox(height: context.rs(AppSpacing.lg)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _setPositionFilter(label),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(AppSpacing.md),
          vertical: context.rs(AppSpacing.sm),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.2)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.outline.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          label,
          style: AppTextStyles.button(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
