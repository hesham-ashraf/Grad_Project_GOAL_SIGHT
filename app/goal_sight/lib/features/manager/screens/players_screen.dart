/// ---------------------------------------------------------------------------
/// GoalSight — Players Screen
///
/// Displays a list of all players under the manager's club.
/// Features: filtering by position, sorting by rating, navigation to profiles.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/data/models/player_profile_model.dart';
import 'package:goal_sight/features/manager/players_mock_data.dart';
import 'package:goal_sight/features/manager/widgets/player_list_card.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({Key? key}) : super(key: key);

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late String _selectedPosition;
  late List<PlayerProfileModel> _allPlayers;
  late List<PlayerProfileModel> _filteredPlayers;

  @override
  void initState() {
    super.initState();
    _allPlayers = List.from(kManagerMockPlayers);
    _selectedPosition = 'All';
    _applyFilter();
  }

  void _applyFilter() {
    if (_selectedPosition == 'All') {
      _filteredPlayers = List.from(_allPlayers);
    } else {
      _filteredPlayers = _allPlayers
          .where((p) => p.position.contains(_selectedPosition))
          .toList();
    }
    // Sort by current rating (highest first)
    _filteredPlayers.sort((a, b) => b.currentRating.compareTo(a.currentRating));
  }

  void _setPositionFilter(String position) {
    setState(() {
      _selectedPosition = position;
      _applyFilter();
    });
  }

  void _openPlayerProfile(PlayerProfileModel player) {
    context.push('/manager-player-profile', extra: player);
  }

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.all(AppSpacing.lg.rs(context)),
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
                        SizedBox(height: AppSpacing.xs.rs(context)),
                        Text(
                          '${_filteredPlayers.length} players',
                          style: AppTextStyles.body(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md.rs(context),
                        vertical: AppSpacing.sm.rs(context),
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
                            size: 16.rs(context),
                          ),
                          SizedBox(width: AppSpacing.xs.rs(context)),
                          Text(
                            'Avg: ${(_allPlayers.map((p) => p.currentRating).reduce((a, b) => a + b) / _allPlayers.length).toStringAsFixed(2)}',
                            style: AppTextStyles.caption(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.rs(context)),

                // Position Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedPosition == 'All'),
                      SizedBox(width: AppSpacing.sm.rs(context)),
                      _buildFilterChip('DEF', _selectedPosition == 'DEF'),
                      SizedBox(width: AppSpacing.sm.rs(context)),
                      _buildFilterChip('MID', _selectedPosition == 'MID'),
                      SizedBox(width: AppSpacing.sm.rs(context)),
                      _buildFilterChip('ATT', _selectedPosition == 'ATT'),
                      SizedBox(width: AppSpacing.sm.rs(context)),
                      _buildFilterChip('GK', _selectedPosition == 'GK'),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg.rs(context)),

                // Players List
                if (_filteredPlayers.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl.rs(context),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            color: AppColors.textMuted,
                            size: 48.rs(context),
                          ),
                          SizedBox(height: AppSpacing.md.rs(context)),
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
                    children: _filteredPlayers.map((player) {
                      return PlayerListCard(
                        player: player,
                        onTap: () => _openPlayerProfile(player),
                      );
                    }).toList(),
                  ),
                SizedBox(height: AppSpacing.lg.rs(context)),
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
          horizontal: AppSpacing.md.rs(context),
          vertical: AppSpacing.sm.rs(context),
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
