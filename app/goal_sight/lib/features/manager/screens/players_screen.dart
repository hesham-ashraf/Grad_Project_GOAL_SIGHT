// ---------------------------------------------------------------------------
// GoalSight — Players Screen (Intelligence Edition)
//
// Displays squad with risk indicators, fatigue rankings, search, and
// advanced filters. Navigates to full intelligence profile.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_sight/core/services/haptic_service.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/data/models/player_profile_model.dart';
import 'package:goal_sight/features/manager/widgets/manager_bottom_navigation_bar.dart';
import 'package:goal_sight/providers/manager_players_provider.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  String _selectedPosition = 'All';
  String _sortMode = 'Rating'; // Rating | Fatigue | Risk
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fades = List.generate(3, (i) {
      final start = (i * 0.2).clamp(0.0, 0.65);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _slides = _fades.map((f) =>
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(f)).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openPlayerProfile(PlayerProfileModel player) {
    HapticService.selection();
    context.push('/manager-player-profile', extra: player);
  }

  List<PlayerProfileModel> _buildFilteredList(List<PlayerProfileModel> allPlayers) {
    var list = allPlayers.where((p) {
      final matchPos = _selectedPosition == 'All' || p.position.contains(_selectedPosition);
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.position.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchPos && matchSearch;
    }).toList();

    switch (_sortMode) {
      case 'Rating':
        list.sort((a, b) => b.currentRating.compareTo(a.currentRating));
      case 'Fatigue':
        list.sort((a, b) => b.fatigue.compareTo(a.fatigue));
      case 'Risk':
        // Use fatigue as a proxy for risk
        list.sort((a, b) => b.fatigue.compareTo(a.fatigue));
    }
    return list;
  }

  Widget _reveal(int i, Widget child) {
    return FadeTransition(opacity: _fades[i], child: SlideTransition(position: _slides[i], child: child));
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers = ref.watch(managerPlayersProvider);
    final filteredPlayers = _buildFilteredList(allPlayers);

    final avgRating = allPlayers.isEmpty
        ? 0.0
        : allPlayers.map((p) => p.currentRating).reduce((a, b) => a + b) / allPlayers.length;
    final highFatigueCount = allPlayers.where((p) => p.fatigue > 75).length;

    final hPad = context.rs(20, min: 16, max: 28);
    final bottomPad = ManagerBottomNavigationBar.totalHeight(context) +
        context.rs(10, min: 6, max: 14);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Premium Page Header ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, context.rs(20, min: 16, max: 28), hPad, 0),
              child: _reveal(0, Container(
                padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.cardLarge,
                  color: AppColors.surfaceElevated.withValues(alpha: 0.72),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rs(12, min: 10, max: 14),
                                  vertical: context.rs(6, min: 5, max: 8),
                                ),
                                decoration: const BoxDecoration(
                                  gradient: AppGradients.brand,
                                  borderRadius: AppRadius.chip,
                                ),
                                child: Text(
                                  'SQUAD INTEL',
                                  style: AppTextStyles.caption(color: Colors.white).copyWith(
                                    fontSize: context.rs(10, min: 9, max: 11),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              SizedBox(width: context.rs(10, min: 8, max: 12)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rs(10, min: 8, max: 12),
                                  vertical: context.rs(5, min: 4, max: 7),
                                ),
                                decoration: BoxDecoration(
                                  color: highFatigueCount > 0
                                      ? AppColors.warning.withValues(alpha: 0.1)
                                      : AppColors.accentGreen.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.chip,
                                  border: Border.all(
                                    color: highFatigueCount > 0
                                        ? AppColors.warning.withValues(alpha: 0.3)
                                        : AppColors.accentGreen.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  highFatigueCount > 0
                                      ? '$highFatigueCount AT RISK'
                                      : 'ALL FIT',
                                  style: AppTextStyles.caption(
                                    color: highFatigueCount > 0
                                        ? AppColors.warning
                                        : AppColors.accentGreen,
                                  ).copyWith(
                                    fontSize: context.rs(10, min: 9, max: 11),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rs(10, min: 8, max: 14)),
                          Text(
                            'Squad',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                              fontSize: context.rs(30, min: 26, max: 36),
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: context.rs(4, min: 3, max: 6)),
                          Text(
                            '${allPlayers.length} players · Avg ${avgRating.toStringAsFixed(1)} rating',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                              fontSize: context.rs(13, min: 12, max: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.rs(10, min: 8, max: 12)),
                    // Sort menu + icon
                    Column(
                      children: [
                        Container(
                          width: context.rs(52, min: 44, max: 58),
                          height: context.rs(52, min: 44, max: 58),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.brand,
                            boxShadow: AppShadows.buttonGlow,
                          ),
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.people_rounded,
                              size: context.rs(24, min: 20, max: 28),
                              color: Colors.white,
                            ),
                            color: AppColors.surfaceElevated,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.card,
                              side: BorderSide(color: AppColors.outlineSubtle),
                            ),
                            onSelected: (v) => setState(() => _sortMode = v),
                            itemBuilder: (_) => ['Rating', 'Fatigue', 'Risk'].map((s) {
                              return PopupMenuItem<String>(
                                value: s,
                                child: Row(
                                  children: [
                                    if (_sortMode == s)
                                      const Icon(Icons.check_rounded, color: AppColors.accentCyan, size: 14)
                                    else
                                      const SizedBox(width: 14),
                                    const SizedBox(width: 8),
                                    Text('Sort by $s', style: AppTextStyles.body(color: AppColors.textPrimary)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ),

            SizedBox(height: context.rs(12, min: 10, max: 16)),

            // ── Search & Filters ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1 — Search bar
                  _reveal(1, _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onClear: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                  )),
                  SizedBox(height: context.rs(10, min: 8, max: 12)),

                  // Position Filter Chips
                  _reveal(1, _PositionFilterRow(
                    selected: _selectedPosition,
                    onSelect: (pos) => setState(() => _selectedPosition = pos),
                  )),
                  SizedBox(height: context.rs(8, min: 6, max: 10)),

                  // Sort mode + count indicator
                  _reveal(1, Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredPlayers.length} player${filteredPlayers.length == 1 ? '' : 's'}',
                        style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                          fontSize: context.sp(12, min: 11, max: 13),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(8, min: 6, max: 10),
                          vertical: context.rs(3, min: 2, max: 4),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadius.chip,
                          border: Border.all(color: AppColors.outlineSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort_rounded, color: AppColors.textMuted,
                                size: context.rs(12, min: 10, max: 14)),
                            const SizedBox(width: 4),
                            Text('by $_sortMode',
                                style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
                                  fontSize: context.sp(11, min: 10, max: 12),
                                )),
                          ],
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),

            SizedBox(height: context.rs(8, min: 6, max: 10)),

            // ── Player list ───────────────────────────────────────────────
            Expanded(
              child: _reveal(2, filteredPlayers.isEmpty
                  ? _EmptyState(query: _searchQuery, position: _selectedPosition)
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: filteredPlayers.length,
                      itemBuilder: (context, index) {
                        final player = filteredPlayers[index];
                        return _EnhancedPlayerCard(
                          player: player,
                          onTap: () => _openPlayerProfile(player),
                        );
                      },
                    )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search players...',
          hintStyle: AppTextStyles.body(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Position Filter Row ──────────────────────────────────────────────────────

class _PositionFilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PositionFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ['All', 'GK', 'DEF', 'MID', 'ATT'].map((pos) {
          final isSelected = selected == pos;
          return GestureDetector(
            onTap: () => onSelect(pos),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: context.rs(AppSpacing.md), vertical: context.rs(AppSpacing.sm)),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.18) : AppColors.surfaceElevated,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.6) : AppColors.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                pos,
                style: AppTextStyles.button(
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                ).copyWith(fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Enhanced Player Card ─────────────────────────────────────────────────────

class _EnhancedPlayerCard extends StatelessWidget {
  final PlayerProfileModel player;
  final VoidCallback onTap;
  const _EnhancedPlayerCard({required this.player, required this.onTap});

  Color get _ratingColor {
    if (player.currentRating >= 8.0) return AppColors.accentGreen;
    if (player.currentRating >= 7.0) return AppColors.accentCyan;
    if (player.currentRating >= 6.0) return AppColors.warning;
    return AppColors.danger;
  }

  Color get _fatigueColor {
    if (player.fatigue > 80) return AppColors.danger;
    if (player.fatigue > 60) return AppColors.warning;
    return AppColors.accentGreen;
  }

  bool get _isHighFatigue => player.fatigue > 75;
  bool get _isElite => player.currentRating >= 8.5;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _isHighFatigue
                ? AppColors.warning.withValues(alpha: 0.3)
                : AppColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceRaised,
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: AppTextStyles.title(color: AppColors.primaryPurple),
                  ),
                ),
                if (_isHighFatigue)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: _fatigueColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceElevated, width: 1.5),
                      ),
                      child: const Icon(Icons.local_fire_department, size: 7, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: AppTextStyles.body(color: AppColors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isElite)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text('ELITE', style: TextStyle(color: AppColors.accentGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          player.position,
                          style: AppTextStyles.caption(color: AppColors.primaryPurple).copyWith(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Trend indicator
                      Icon(
                        player.trend == PerformanceTrend.improving
                            ? Icons.trending_up
                            : player.trend == PerformanceTrend.declining
                                ? Icons.trending_down
                                : Icons.trending_flat,
                        color: player.trend == PerformanceTrend.improving
                            ? AppColors.accentGreen
                            : player.trend == PerformanceTrend.declining
                                ? AppColors.danger
                                : AppColors.textMuted,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fatigue bar
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_outlined, color: _fatigueColor, size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: player.fatigue / 100,
                            backgroundColor: AppColors.surfaceRaised,
                            valueColor: AlwaysStoppedAnimation<Color>(_fatigueColor),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${player.fatigue}%',
                          style: AppTextStyles.caption(color: _fatigueColor).copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Rating badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _ratingColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: _ratingColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    player.currentRating.toStringAsFixed(1),
                    style: AppTextStyles.title(color: _ratingColor).copyWith(fontSize: 16),
                  ),
                  Text('Rating', style: AppTextStyles.caption(color: _ratingColor).copyWith(fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  final String position;
  const _EmptyState({required this.query, required this.position});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'No results for "$query"'
                  : position != 'All'
                      ? 'No $position players found'
                      : 'No players found',
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text('Try adjusting your filters', style: AppTextStyles.caption(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
