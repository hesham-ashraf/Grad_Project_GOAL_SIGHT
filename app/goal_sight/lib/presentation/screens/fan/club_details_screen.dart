import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/club_model.dart';
import '../../widgets/fan/club_detail_widgets.dart';
import '../../widgets/fan/club_analytics_widgets.dart';

class ClubDetailsScreen extends StatefulWidget {
  const ClubDetailsScreen({super.key, required this.club});

  final ClubModel club;

  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _headerFade;
  late final Animation<double> _statsFade;
  late final Animation<double> _squadFade;
  late final Animation<double> _analyticsFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _statsSlide;
  late final Animation<Offset> _squadSlide;
  late final Animation<Offset> _analyticsSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    CurvedAnimation makeCurve(double start, double end) => CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

    _headerFade = makeCurve(0.0, 0.3);
    _statsFade = makeCurve(0.15, 0.5);
    _squadFade = makeCurve(0.35, 0.7);
    _analyticsFade = makeCurve(0.55, 0.9);

    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_headerFade);
    _statsSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_statsFade);
    _squadSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_squadFade);
    _analyticsSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_analyticsFade);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final stats = club.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, club),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Header ───────────────────────────────────────────────
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _ClubHeroHeader(club: club),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(24, min: 20, max: 32),
                context.rs(20, min: 16, max: 24),
                context.rs(32, min: 24, max: 48),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Club Info Chips ──────────────────────────────────────
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Wrap(
                        spacing: context.rs(10, min: 8, max: 12),
                        runSpacing: context.rs(8, min: 6, max: 10),
                        children: [
                          _InfoChip(icon: Icons.stadium_rounded, label: club.stadium),
                          _InfoChip(icon: Icons.flag_rounded, label: club.country),
                          if (club.foundedYear > 0)
                            _InfoChip(
                              icon: Icons.history_rounded,
                              label: 'Est. ${club.foundedYear}',
                            ),
                          _InfoChip(
                            icon: Icons.sports_rounded,
                            label: 'Coach: ${club.coach}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Season Stats ─────────────────────────────────────────
                  FadeTransition(
                    opacity: _statsFade,
                    child: SlideTransition(
                      position: _statsSlide,
                      child: _SeasonStatsSection(club: club, stats: stats),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Tactical Identity ────────────────────────────────────
                  FadeTransition(
                    opacity: _analyticsFade,
                    child: SlideTransition(
                      position: _analyticsSlide,
                      child: ClubTacticalIdentityCard(club: club),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Analytics Dashboard ──────────────────────────────────
                  FadeTransition(
                    opacity: _analyticsFade,
                    child: SlideTransition(
                      position: _analyticsSlide,
                      child: ClubAnalyticsDashboard(club: club),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Performance Trends ───────────────────────────────────
                  FadeTransition(
                    opacity: _analyticsFade,
                    child: SlideTransition(
                      position: _analyticsSlide,
                      child: PerformanceTrendCard(club: club),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── AI Tactical Summary ──────────────────────────────────
                  FadeTransition(
                    opacity: _analyticsFade,
                    child: SlideTransition(
                      position: _analyticsSlide,
                      child: ClubTacticalSummaryCard(club: club),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Recent Analyses ──────────────────────────────────────
                  FadeTransition(
                    opacity: _analyticsFade,
                    child: SlideTransition(
                      position: _analyticsSlide,
                      child: RecentAnalysesCard(
                          clubName: club.name, primaryColor: club.primaryColor),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Top Performers ───────────────────────────────────────
                  FadeTransition(
                    opacity: _analyticsFade,
                    child: SlideTransition(
                      position: _analyticsSlide,
                      child: TopPlayersCard(club: club),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 20, max: 32)),

                  // ── Squad ────────────────────────────────────────────────
                  FadeTransition(
                    opacity: _squadFade,
                    child: SlideTransition(
                      position: _squadSlide,
                      child: _SquadSection(club: club),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ClubModel club) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      club.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: club.isFavorite
                          ? AppColors.warning
                          : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      club.isFavorite ? 'Favorited' : 'Follow',
                      style: AppTextStyles.caption(
                        color: club.isFavorite
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _ClubHeroHeader extends StatelessWidget {
  const _ClubHeroHeader({required this.club});
  final ClubModel club;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.rs(260, min: 220, max: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            club.primaryColor.withValues(alpha: 0.22),
            AppColors.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background orb
          Positioned(
            top: -60,
            left: MediaQuery.of(context).size.width / 2 - 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  club.primaryColor.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Content
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.rs(28, min: 20, max: 36)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Club Logo
                  Container(
                    width: context.rs(88, min: 72, max: 104),
                    height: context.rs(88, min: 72, max: 104),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          club.primaryColor.withValues(alpha: 0.35),
                          club.primaryColor.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: club.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: club.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        club.abbreviation,
                        style: AppTextStyles.headline(color: Colors.white).copyWith(
                          fontSize: context.rs(30, min: 24, max: 36),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.rs(14, min: 12, max: 18)),
                  Text(
                    club.name,
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.rs(26, min: 22, max: 30),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    club.league,
                    style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ───────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(12, min: 10, max: 14),
        vertical: context.rs(7, min: 5, max: 9),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.rs(14, min: 12, max: 16), color: AppColors.textMuted),
          SizedBox(width: context.rs(6, min: 4, max: 8)),
          Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Season Stats Section ────────────────────────────────────────────────────

class _SeasonStatsSection extends StatelessWidget {
  const _SeasonStatsSection({required this.club, required this.stats});
  final ClubModel club;
  final ClubStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Season Stats',
          badge: '${stats.matchesPlayed} Played',
          color: club.primaryColor,
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),

        // Big 3 stats
        Row(
          children: [
            Expanded(
              child: _BigStatCard(
                value: '${stats.points}',
                label: 'Points',
                icon: Icons.emoji_events_rounded,
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: context.rs(12, min: 8, max: 16)),
            Expanded(
              child: _BigStatCard(
                value: '#${stats.ranking}',
                label: 'Rank',
                icon: Icons.leaderboard_rounded,
                color: club.primaryColor,
              ),
            ),
            SizedBox(width: context.rs(12, min: 8, max: 16)),
            Expanded(
              child: _BigStatCard(
                value: stats.goalDifference >= 0
                    ? '+${stats.goalDifference}'
                    : '${stats.goalDifference}',
                label: 'Goal Diff',
                icon: Icons.sports_soccer_rounded,
                color: stats.goalDifference >= 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
          ],
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),

        // Form bar
        Container(
          padding: EdgeInsets.all(context.rs(18, min: 14, max: 22)),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(color: AppColors.outlineSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Win Rate',
                style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.rs(12, min: 8, max: 16)),
              FormBar(
                wins: stats.wins,
                draws: stats.draws,
                losses: stats.losses,
                total: stats.matchesPlayed,
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(12, min: 8, max: 16)),

        // Detail stats
        Container(
          padding: EdgeInsets.all(context.rs(18, min: 14, max: 22)),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(color: AppColors.outlineSubtle),
          ),
          child: Column(
            children: [
              ClubStatRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Wins',
                value: '${stats.wins}',
                color: AppColors.success,
              ),
              _Divider(),
              ClubStatRow(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Draws',
                value: '${stats.draws}',
                color: AppColors.warning,
              ),
              _Divider(),
              ClubStatRow(
                icon: Icons.cancel_outlined,
                label: 'Losses',
                value: '${stats.losses}',
                color: AppColors.danger,
              ),
              _Divider(),
              ClubStatRow(
                icon: Icons.sports_soccer_rounded,
                label: 'Goals Scored',
                value: '${stats.goalsScored}',
                color: AppColors.accentCyan,
              ),
              _Divider(),
              ClubStatRow(
                icon: Icons.shield_outlined,
                label: 'Goals Conceded',
                value: '${stats.goalsConceded}',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(12, min: 8, max: 16),
        vertical: context.rs(16, min: 12, max: 20),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: context.rs(22, min: 18, max: 26)),
          SizedBox(height: context.rs(8, min: 6, max: 10)),
          Text(
            value,
            style: AppTextStyles.headline(color: color).copyWith(
              fontSize: context.rs(22, min: 18, max: 26),
            ),
          ),
          SizedBox(height: context.rs(4, min: 2, max: 6)),
          Text(
            label,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      height: 1,
      color: AppColors.outlineSubtle,
    );
  }
}

// ─── Squad Section ────────────────────────────────────────────────────────────

class _SquadSection extends StatelessWidget {
  const _SquadSection({required this.club});
  final ClubModel club;

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...club.players]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Squad',
          badge: '${sortedPlayers.length} Players',
          color: club.primaryColor,
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),
        ...sortedPlayers.asMap().entries.map((entry) => PlayerListTile(
              player: entry.value,
              index: entry.key,
            )),
      ],
    );
  }
}

