import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/fan/ai_recommendations_section.dart';
import '../../widgets/fan/fan_home_widgets.dart';
import '../../widgets/fan/live_indicators.dart';
import '../../widgets/fan/tactical_insights_section.dart';
import '../../widgets/fan/trending_matches_section.dart';

class FanHomeScreen extends ConsumerStatefulWidget {
  const FanHomeScreen({super.key});

  @override
  ConsumerState<FanHomeScreen> createState() => _FanHomeScreenState();
}

class _FanHomeScreenState extends ConsumerState<FanHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Static data ─────────────────────────────────────────────────────────────
  static const FeaturedMatchData _featuredMatch = FeaturedMatchData(
    homeTeam: 'GoalSight FC',
    awayTeam: 'Falcons United',
    score: '3 - 1',
    highlight: 'Dominated by GoalSight FC with a ruthless second-half press.',
    competition: 'Premier League · Matchday 18',
    statusLabel: 'FULL TIME',
    homeColor: AppColors.accentCyan,
    awayColor: AppColors.primaryPurple,
  );

  static const List<PlayerPerformance> _topPlayers = [
    PlayerPerformance(
      name: 'Hassan Ali',
      rating: 8.9,
      position: 'Playmaker',
      club: 'GoalSight FC',
      tintColor: AppColors.primaryPurple,
      isBestPlayer: true,
    ),
    PlayerPerformance(
      name: 'Ziad Hamdy',
      rating: 8.6,
      position: 'Midfield',
      club: 'GoalSight FC',
      tintColor: AppColors.accentCyan,
    ),
    PlayerPerformance(
      name: 'Mostafa Samir',
      rating: 8.4,
      position: 'Forward',
      club: 'GoalSight FC',
      tintColor: AppColors.accentGreen,
    ),
  ];

  static const List<QuickStatData> _quickStats = [
    QuickStatData(
      label: 'Possession',
      value: '63%',
      subtitle: 'Controlled tempo and shape throughout the match.',
      icon: Icons.pie_chart_rounded,
      tintColor: AppColors.accentCyan,
    ),
    QuickStatData(
      label: 'Team rating',
      value: '8.7',
      subtitle: 'High execution across all phases of play.',
      icon: Icons.star_rounded,
      tintColor: AppColors.primaryPurple,
    ),
    QuickStatData(
      label: 'Match intensity',
      value: '91',
      subtitle: 'Fast transitions, pressure, and high-energy duels.',
      icon: Icons.local_fire_department_rounded,
      tintColor: AppColors.accentGreen,
    ),
  ];

  // ── Animation controller ─────────────────────────────────────────────────────
  late final AnimationController _controller;

  // Section animations (each is a fade + matching slide)
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _liveFade;
  late final Animation<Offset> _liveSlide;
  late final Animation<double> _featuredFade;
  late final Animation<Offset> _featuredSlide;
  late final Animation<double> _trendingFade;
  late final Animation<Offset> _trendingSlide;
  late final Animation<double> _playersFade;
  late final Animation<Offset> _playersSlide;
  late final Animation<double> _statsFade;
  late final Animation<Offset> _statsSlide;
  late final Animation<double> _insightsFade;
  late final Animation<Offset> _insightsSlide;
  late final Animation<double> _recsFade;
  late final Animation<Offset> _recsSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _headerFade = _interval(0.00, 0.22);
    _headerSlide = _slideOf(_headerFade);
    _liveFade = _interval(0.08, 0.30);
    _liveSlide = _slideOf(_liveFade);
    _featuredFade = _interval(0.16, 0.42);
    _featuredSlide = _slideOf(_featuredFade);
    _trendingFade = _interval(0.28, 0.52);
    _trendingSlide = _slideOf(_trendingFade);
    _playersFade = _interval(0.38, 0.62);
    _playersSlide = _slideOf(_playersFade);
    _statsFade = _interval(0.50, 0.74);
    _statsSlide = _slideOf(_statsFade);
    _insightsFade = _interval(0.60, 0.84);
    _insightsSlide = _slideOf(_insightsFade);
    _recsFade = _interval(0.72, 1.00);
    _recsSlide = _slideOf(_recsFade);
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slideOf(Animation<double> fade) {
    return Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(fade);
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
    final userName =
        ref.watch(authControllerProvider.select((s) => s.user?.name)) ?? 'Fan';

    final isTablet = context.isTablet || context.isDesktop;
    final hPad = context.rs(18, min: 14, max: isTablet ? 32 : 24);
    final vPad = context.rs(16, min: 12, max: 20);
    final gap = context.rs(18, min: 14, max: 22);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.backgroundAlt,
              AppColors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _FanBackdrop()),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.accentCyan,
                backgroundColor: AppColors.surface,
                strokeWidth: 2.5,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                child: ResponsiveCentered(
                  maxWidth: 1180,
                  padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header
                      _Reveal(
                        opacity: _headerFade,
                        position: _headerSlide,
                        child: _HomeHeader(userName: userName),
                      ),
                      SizedBox(height: gap),

                      // 2. Live Match Banner
                      _Reveal(
                        opacity: _liveFade,
                        position: _liveSlide,
                        child: LiveMatchBanner(
                          liveMatchCount: 1,
                          matchDescription: 'Storm United vs Delta FC — Champions League',
                        ),
                      ),
                      SizedBox(height: gap),

                      // 3. Featured Match Card
                      _Reveal(
                        opacity: _featuredFade,
                        position: _featuredSlide,
                        child: const FeaturedMatchCard(match: _featuredMatch),
                      ),
                      SizedBox(height: gap),

                      // 4. Trending Matches — horizontal scroll
                      _Reveal(
                        opacity: _trendingFade,
                        position: _trendingSlide,
                        child: const TrendingMatchesSection(),
                      ),
                      SizedBox(height: gap),

                      // 5. Top 3 Players
                      _Reveal(
                        opacity: _playersFade,
                        position: _playersSlide,
                        child: _PlayersSection(players: _topPlayers),
                      ),
                      SizedBox(height: gap),

                      // 6. Animated Quick Stats
                      _Reveal(
                        opacity: _statsFade,
                        position: _statsSlide,
                        child: _QuickStatsSection(stats: _quickStats),
                      ),
                      SizedBox(height: gap),

                      // 7. Tactical Insights
                      _Reveal(
                        opacity: _insightsFade,
                        position: _insightsSlide,
                        child: const TacticalInsightsSection(),
                      ),
                      SizedBox(height: gap),

                      // 8. AI Recommendations
                      _Reveal(
                        opacity: _recsFade,
                        position: _recsSlide,
                        child: const AIRecommendationsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Header ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        vertical: context.rs(7, min: 6, max: 8),
                      ),
                      decoration: const BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: AppRadius.chip,
                      ),
                      child: Text(
                        'FAN HOME',
                        style: AppTextStyles.caption(color: Colors.white).copyWith(
                          fontSize: context.rs(10, min: 9, max: 11),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(width: context.rs(10, min: 8, max: 12)),
                    const LiveAnalysisIndicator(),
                  ],
                ),
                SizedBox(height: context.rs(12, min: 8, max: 14)),
                Text(
                  'Welcome back, $userName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline(color: AppColors.textPrimary)
                      .copyWith(
                    fontSize: context.rs(30, min: 26, max: 36),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: context.rs(6, min: 4, max: 8)),
                Text(
                  'A premium read-only feed for live insights, star performers, and match control.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                    fontSize: context.rs(14, min: 13, max: 16),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rs(12, min: 10, max: 14)),
          Container(
            width: context.rs(54, min: 48, max: 60),
            height: context.rs(54, min: 48, max: 60),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.brand,
              boxShadow: AppShadows.buttonGlow,
            ),
            child: Center(
              child: Text(
                _initials(userName),
                style: AppTextStyles.title(color: Colors.white).copyWith(
                  fontSize: context.rs(18, min: 16, max: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Players Section ─────────────────────────────────────────────────────────

class _PlayersSection extends StatelessWidget {
  const _PlayersSection({required this.players});

  final List<PlayerPerformance> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'Top 3 Players',
          subtitle: 'Highest rated performers from the featured match.',
          icon: Icons.emoji_events_rounded,
        ),
        SizedBox(height: context.rs(12, min: 10, max: 14)),
        LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 980;

            if (useRow) {
              return Row(
                children: [
                  Expanded(
                    child: PlayerCard(player: players[0], onTap: () {}),
                  ),
                  SizedBox(width: context.rs(12, min: 10, max: 14)),
                  Expanded(
                    child: PlayerCard(player: players[1], onTap: () {}),
                  ),
                  SizedBox(width: context.rs(12, min: 10, max: 14)),
                  Expanded(
                    child: PlayerCard(player: players[2], onTap: () {}),
                  ),
                ],
              );
            }

            final cardWidths = <double>[
              context.rs(188, min: 172, max: 208),
              context.rs(168, min: 154, max: 190),
              context.rs(168, min: 154, max: 190),
            ];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  PlayerCard(
                    player: players[0],
                    width: cardWidths[0],
                    onTap: () {},
                  ),
                  SizedBox(width: context.rs(12, min: 10, max: 14)),
                  PlayerCard(
                    player: players[1],
                    width: cardWidths[1],
                    onTap: () {},
                  ),
                  SizedBox(width: context.rs(12, min: 10, max: 14)),
                  PlayerCard(
                    player: players[2],
                    width: cardWidths[2],
                    onTap: () {},
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Quick Stats Section ─────────────────────────────────────────────────────

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({required this.stats});

  final List<QuickStatData> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'Live Stats',
          subtitle: 'Animated match metrics with real-time progress.',
          icon: Icons.insights_rounded,
        ),
        SizedBox(height: context.rs(12, min: 10, max: 14)),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 960
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            final spacing = context.rs(12, min: 10, max: 14);
            final width =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: stats
                  .map(
                    (stat) => SizedBox(
                      width: width,
                      child: StatCard(stat: stat),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.rs(40, min: 36, max: 44),
          height: context.rs(40, min: 36, max: 44),
          decoration: const BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: AppRadius.chip,
            boxShadow: AppShadows.cardGlow,
          ),
          child: Icon(
            icon,
            size: context.rs(20, min: 18, max: 22),
            color: Colors.white,
          ),
        ),
        SizedBox(width: context.rs(12, min: 10, max: 14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                  fontSize: context.rs(18, min: 16, max: 22),
                ),
              ),
              SizedBox(height: context.rs(4, min: 2, max: 6)),
              Text(
                subtitle,
                style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                  fontSize: context.rs(11, min: 10, max: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reveal Wrapper ───────────────────────────────────────────────────────────

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.opacity,
    required this.position,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<Offset> position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: position, child: child),
    );
  }
}

// ─── Fan Backdrop ─────────────────────────────────────────────────────────────

class _FanBackdrop extends StatelessWidget {
  const _FanBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -80,
            child: _GlowOrb(
              size: 280,
              color: AppColors.primaryPurple.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            left: -110,
            bottom: 80,
            child: _GlowOrb(
              size: 320,
              color: AppColors.accentCyan.withValues(alpha: 0.12),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.3,
                  colors: [
                    Colors.transparent,
                    Color(0x90050816),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) return 'F';

  if (parts.length == 1) {
    final word = parts.first;
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }

  final first = parts.first.characters.first;
  final last = parts.last.characters.first;
  return '$first$last'.toUpperCase();
}
