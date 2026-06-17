import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/animations/gs_shimmer.dart';
import '../manager_dashboard_models.dart';
import '../widgets/insight_card.dart';
import '../widgets/manager_bottom_navigation_bar.dart';
import '../widgets/match_summary_card.dart';
import '../widgets/player_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/manager_dashboard_advanced_widgets.dart';

class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  ConsumerState<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen>
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
    ref.invalidate(managerDashboardProvider);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(managerDashboardProvider);

    final horizontalPadding = context.rs(20, min: 14, max: 28);
    final sectionSpacing = context.rs(18, min: 14, max: 24);
    final bottomPadding = ManagerBottomNavigationBar.totalHeight(context) +
        context.rs(10, min: 6, max: 14);

    return asyncData.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            context.rs(12, min: 10, max: 18),
            horizontalPadding,
            bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GsShimmer.card(height: context.rs(90, min: 80, max: 100), radius: AppRadius.cardLarge.topLeft.x),
              SizedBox(height: sectionSpacing),
              Row(children: [
                Expanded(child: GsShimmer.card(height: context.rs(155, min: 135, max: 175), radius: AppRadius.card.topLeft.x)),
                SizedBox(width: context.rs(10, min: 8, max: 14)),
                Expanded(child: GsShimmer.card(height: context.rs(155, min: 135, max: 175), radius: AppRadius.card.topLeft.x)),
              ]),
              SizedBox(height: sectionSpacing),
              GsShimmer.card(height: context.rs(130, min: 115, max: 148)),
              SizedBox(height: sectionSpacing),
              GsShimmer.card(height: context.rs(100, min: 88, max: 112)),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: context.padAll(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Could not load dashboard',
                  style: AppTextStyles.title(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => ref.invalidate(managerDashboardProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (data) {
    final stats = data.keyStats;
    final players = data.topPerformers;
    final insights = data.insights;

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
                    child: const _SectionTitle(
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

                  // ── Primary CTA: Upload Match ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.22,
                    end: 0.42,
                    child: _UploadMatchCtaBanner(),
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
                    child: const _SectionTitle(
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
                    child: const _SectionTitle(
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
                    child: const TacticalRecommendationsSection(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Underperforming Players ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.76,
                    end: 0.90,
                    child: const UnderperformingPlayersSection(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Tactical Identity Overview ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.80,
                    end: 0.94,
                    child: const TacticalIdentityOverview(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Club Analytics Dashboard ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.84,
                    end: 0.97,
                    child: const ClubAnalyticsDashboard(),
                  ),
                  SizedBox(height: sectionSpacing),

                  // ── NEW: Performance Trend Charts ──
                  _StaggeredReveal(
                    controller: _controller,
                    start: 0.88,
                    end: 1.00,
                    child: const PerformanceTrendSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
      }, // end data:
    ); // end asyncData.when
  }
}

// ─── Upload Match CTA Banner ──────────────────────────────────────────────────

class _UploadMatchCtaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.medium();
        context.push('/manager/upload-match');
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(18, min: 14, max: 22),
          vertical: context.rs(14, min: 12, max: 18),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withValues(alpha: 0.22),
              AppColors.accentCyan.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: AppRadius.cardLarge,
          border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadows.buttonGlow,
              ),
              child: const Icon(Icons.upload_file_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload New Match',
                      style: AppTextStyles.title(color: Colors.white)
                          .copyWith(fontSize: context.sp(15, min: 13, max: 17))),
                  const SizedBox(height: 2),
                  Text('Get AI tactical analysis in minutes',
                      style: AppTextStyles.caption(color: AppColors.textMuted)
                          .copyWith(fontSize: context.sp(12, min: 10, max: 14))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.accentCyan, size: 16),
          ],
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
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Text content ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge row
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
                        'MANAGER HUB',
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
                        color: AppColors.primaryPurple.withValues(alpha: 0.12),
                        borderRadius: AppRadius.chip,
                        border: Border.all(
                          color: AppColors.primaryPurple.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'AI ACTIVE',
                        style: AppTextStyles.caption(color: AppColors.primaryPurple).copyWith(
                          fontSize: context.rs(10, min: 9, max: 11),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(10, min: 8, max: 14)),
                // Club name headline
                Text(
                  clubName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                    fontSize: context.rs(28, min: 22, max: 34),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: context.rs(4, min: 3, max: 6)),
                // Subtitle
                Text(
                  subtitle,
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
          // ── Icon avatar ────────────────────────────────────────────────────
          Container(
            width: context.rs(52, min: 44, max: 58),
            height: context.rs(52, min: 44, max: 58),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.brand,
              boxShadow: AppShadows.buttonGlow,
            ),
            child: Icon(
              Icons.analytics_rounded,
              size: context.rs(24, min: 20, max: 28),
              color: Colors.white,
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
        Icon(icon, size: context.rs(18, min: 16, max: 20), color: AppColors.accentCyan),
        SizedBox(width: context.rs(8, min: 6, max: 10)),
        Text(
          title,
          style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
            fontSize: context.sp(17, min: 15, max: 21),
            fontWeight: FontWeight.w600,
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
