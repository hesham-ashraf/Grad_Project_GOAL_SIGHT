import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/fan_mock_providers.dart';
import '../../widgets/fan/standings_row.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _zoneFade;
  late final Animation<Offset> _zoneSlide;
  late final Animation<double> _tableFade;

  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(_headerFade);

    _zoneFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOutCubic),
    );
    _zoneSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(_zoneFade);

    _tableFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await HapticService.refresh();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final standings = ref.watch(mockStandingsProvider);
    final hPad = context.rs(20, min: 16, max: 28);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Premium Page Header ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, context.rs(20, min: 16, max: 28), hPad, 0),
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Container(
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
                                      'LEAGUE TABLE',
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
                                      color: AppColors.accentGreen.withValues(alpha: 0.1),
                                      borderRadius: AppRadius.chip,
                                      border: Border.all(
                                        color: AppColors.accentGreen.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'LIVE',
                                      style: AppTextStyles.caption(color: AppColors.accentGreen).copyWith(
                                        fontSize: context.rs(10, min: 9, max: 11),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rs(10, min: 8, max: 14)),
                              Text(
                                'Standings',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                                  fontSize: context.rs(30, min: 26, max: 36),
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: context.rs(4, min: 3, max: 6)),
                              Text(
                                'GoalSight Premier League · 2026 Season',
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
                        Container(
                          width: context.rs(52, min: 44, max: 58),
                          height: context.rs(52, min: 44, max: 58),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.brand,
                            boxShadow: AppShadows.buttonGlow,
                          ),
                          child: Icon(
                            Icons.leaderboard_rounded,
                            size: context.rs(24, min: 20, max: 28),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: context.rs(14, min: 10, max: 18)),

            // ── Zone Legend ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: FadeTransition(
                opacity: _zoneFade,
                child: SlideTransition(
                  position: _zoneSlide,
                  child: _ZoneLegend(),
                ),
              ),
            ),

            SizedBox(height: context.rs(10, min: 8, max: 14)),

            // ── Pinned Table Header ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(4, min: 0, max: 8),
                0,
                context.rs(4, min: 0, max: 8),
                0,
              ),
              child: const StandingsHeaderRow(),
            ),

            // ── Scrollable Table ─────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _tableFade,
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.accentCyan,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 2.5,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      context.rs(4, min: 2, max: 6),
                      hPad,
                      context.rs(100, min: 80, max: 120),
                    ),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: standings.length,
                    itemBuilder: (context, index) {
                      final team = standings[index];
                      // Zone separator: between 3 and 4 (relegation zone start)
                      final bool showRelegationDivider = index == standings.length - 2;
                      final bool showEuropeDivider = index == 3;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (index == 0)
                            const _ZoneDividerLabel(
                              label: 'Championship Zone',
                              color: AppColors.accentCyan,
                              icon: Icons.emoji_events_rounded,
                            ),
                          if (showEuropeDivider)
                            const _ZoneDividerLabel(
                              label: 'Mid Table',
                              color: AppColors.textMuted,
                              icon: Icons.remove_rounded,
                            ),
                          if (showRelegationDivider)
                            const _ZoneDividerLabel(
                              label: 'Danger Zone',
                              color: AppColors.danger,
                              icon: Icons.keyboard_double_arrow_down_rounded,
                            ),
                          _AnimatedStandingsRow(
                            key: ValueKey(team.rank),
                            team: team,
                            delay: Duration(milliseconds: 60 * index),
                            onTap: () => HapticService.selection(),
                          ),
                        ],
                      );
                    },
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

// ─── Animated Row Wrapper ────────────────────────────────────────────────────

class _AnimatedStandingsRow extends StatefulWidget {
  const _AnimatedStandingsRow({
    super.key,
    required this.team,
    required this.delay,
    this.onTap,
  });

  final StandingTeamData team;
  final Duration delay;
  final VoidCallback? onTap;

  @override
  State<_AnimatedStandingsRow> createState() => _AnimatedStandingsRowState();
}

class _AnimatedStandingsRowState extends State<_AnimatedStandingsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(_fade);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: StandingsRow(team: widget.team, onTap: widget.onTap),
      ),
    );
  }
}

// ─── Zone Divider Label ───────────────────────────────────────────────────────

class _ZoneDividerLabel extends StatelessWidget {
  const _ZoneDividerLabel({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rs(6, min: 4, max: 8)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: color.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(width: context.rs(10, min: 8, max: 12)),
          Icon(icon, size: context.rs(13, min: 11, max: 15), color: color.withValues(alpha: 0.7)),
          SizedBox(width: context.rs(5, min: 4, max: 6)),
          Text(
            label,
            style: AppTextStyles.caption(color: color.withValues(alpha: 0.7)).copyWith(
              fontSize: context.rs(11, min: 10, max: 12),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(width: context.rs(10, min: 8, max: 12)),
          Expanded(
            child: Container(
              height: 1,
              color: color.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zone Legend ──────────────────────────────────────────────────────────────

class _ZoneLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LegendDot(color: AppColors.accentCyan, label: 'Champions'),
        SizedBox(width: context.rs(16, min: 12, max: 20)),
        const _LegendDot(color: AppColors.textMuted, label: 'Mid Table'),
        SizedBox(width: context.rs(16, min: 12, max: 20)),
        const _LegendDot(color: AppColors.danger, label: 'Relegation'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.rs(8, min: 6, max: 10),
          height: context.rs(8, min: 6, max: 10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.rs(6, min: 4, max: 8)),
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
            fontSize: context.rs(11, min: 10, max: 12),
          ),
        ),
      ],
    );
  }
}
