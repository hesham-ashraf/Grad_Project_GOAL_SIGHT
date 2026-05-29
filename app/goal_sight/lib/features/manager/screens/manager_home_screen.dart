import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../manager_dashboard_mock_data.dart';
import '../manager_dashboard_models.dart';
import '../widgets/insight_card.dart';
import '../widgets/manager_bottom_navigation_bar.dart';
import '../widgets/match_summary_card.dart';
import '../widgets/player_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/manager_dashboard_advanced_widgets.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  bool _refreshing = false;
  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await HapticService.refresh();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = kManagerDashboardMockData;
    final stats = data.keyStats;
    final players = data.topPerformers;
    final insights = data.insights;

    final horizontalPadding = context.rs(20, min: 14, max: 28);
    final sectionSpacing = context.rs(18, min: 14, max: 24);
    final bottomPadding = ManagerBottomNavigationBar.totalHeight(context) +
        context.rs(10, min: 6, max: 14);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.accentCyan,
        backgroundColor: AppColors.surface,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                context.rs(12, min: 10, max: 18),
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0,
                    end: 0.18,
                    child: _DashboardHeader(
                      clubName: data.clubName,
                      subtitle: data.subtitle,
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.1,
                    end: 0.34,
                    child: _SectionTitle(
                      title: 'Key Stats',
                      icon: Icons.query_stats_rounded,
                    ),
                  ),
                  SizedBox(height: context.rs(10, min: 8, max: 12)),
                  _StatsGrid(
                    controller: _controller,
                    stats: stats,
                  ),
                  SizedBox(height: sectionSpacing),
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.26,
                    end: 0.52,
                    child: MatchSummaryCard(summary: data.lastMatch),
                  ),
                  SizedBox(height: sectionSpacing),
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.42,
                    end: 0.62,
                    child: _SectionTitle(
                      title: 'Top Performers',
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ),
                  SizedBox(height: context.rs(10, min: 8, max: 12)),
                  _TopPlayersRow(
                    controller: _controller,
                    players: players,
                  ),
                  SizedBox(height: sectionSpacing),
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.58,
                    end: 0.74,
                    child: _SectionTitle(
                      title: 'Alerts & Insights',
                      icon: Icons.tips_and_updates_rounded,
                    ),
                  ),
                  SizedBox(height: context.rs(10, min: 8, max: 12)),
                  _InsightsColumn(
                    controller: _controller,
                    insights: insights,
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Tactical Recommendations ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.72,
                    end: 0.86,
                    child: TacticalRecommendationsSection(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Underperforming Players ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.76,
                    end: 0.90,
                    child: UnderperformingPlayersSection(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Tactical Identity Overview ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.80,
                    end: 0.94,
                    child: TacticalIdentityOverview(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Club Analytics Dashboard ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.84,
                    end: 0.97,
                    child: ClubAnalyticsDashboard(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Performance Trend Charts ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.88,
                    end: 1.00,
                    child: PerformanceTrendSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.clubName,
    required this.subtitle,
  });

  final String clubName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clubName,
            style: AppTextStyles.headline().copyWith(
              fontSize: context.sp(30, min: 22, max: 36),
            ),
          ),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(
            subtitle,
            style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
              fontSize: context.sp(14, min: 12, max: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.title().copyWith(
            fontSize: context.sp(18, min: 16, max: 22),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.controller,
    required this.stats,
  });

  final AnimationController controller;
  final List<ManagerKeyStat> stats;

  @override
  Widget build(BuildContext context) {
    final spacing = context.rs(10, min: 8, max: 14);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = ((constraints.maxWidth - spacing) / 2).clamp(130.0, 420.0);
        final cardHeight = context.rs(158, min: 138, max: 178);
        final ratio = cardWidth / cardHeight;

        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final start = 0.16 + (index * 0.08);
            final end = (start + 0.24).clamp(0.0, 1.0);
            return _StaggeredReveal(
              controller: controller,
              start: start,
              end: end,
              child: StatCard(stat: stats[index]),
            );
          },
        );
      },
    );
  }
}

class _TopPlayersRow extends StatelessWidget {
  const _TopPlayersRow({
    required this.controller,
    required this.players,
  });

  final AnimationController controller;
  final List<ManagerPlayerPerformance> players;

  @override
  Widget build(BuildContext context) {
    final spacing = context.rs(10, min: 8, max: 12);
    final cardHeight = context.rs(145, min: 128, max: 160);

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: players.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final start = 0.45 + (index * 0.08);
          final end = (start + 0.24).clamp(0.0, 1.0);
          return _StaggeredReveal(
            controller: controller,
            start: start,
            end: end,
            child: PlayerCard(
              player: players[index],
              rank: index + 1,
            ),
          );
        },
      ),
    );
  }
}

class _InsightsColumn extends StatelessWidget {
  const _InsightsColumn({
    required this.controller,
    required this.insights,
  });

  final AnimationController controller;
  final List<ManagerInsight> insights;

  @override
  Widget build(BuildContext context) {
    final spacing = context.rs(10, min: 8, max: 12);

    return Column(
      children: List.generate(insights.length, (index) {
        final start = 0.64 + (index * 0.08);
        final end = (start + 0.24).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.only(bottom: index == insights.length - 1 ? 0 : spacing),
          child: _StaggeredReveal(
            controller: controller,
            start: start,
            end: end,
            child: InsightCard(insight: insights[index]),
          ),
        );
      }),
    );
  }
}

class _StaggeredReveal extends StatelessWidget {
  const _StaggeredReveal({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}
