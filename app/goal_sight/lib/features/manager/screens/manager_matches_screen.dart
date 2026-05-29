import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import '../manager_matches_mock_data.dart';
import '../widgets/manager_bottom_navigation_bar.dart';
import '../widgets/match_card.dart';

class ManagerMatchesScreen extends StatefulWidget {
  const ManagerMatchesScreen({super.key});

  @override
  State<ManagerMatchesScreen> createState() => _ManagerMatchesScreenState();
}

class _ManagerMatchesScreenState extends State<ManagerMatchesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _filterFade;
  late final Animation<double> _listFade;

  String _filter = 'Recent';
  bool _refreshing = false;

  static const _filters = ['Recent', 'High Intensity', 'Best'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(_headerFade);

    _filterFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.52, curve: Curves.easeOutCubic),
    );

    _listFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.34, 0.72, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<MatchAnalysisModel> get _filteredMatches {
    final list = kManagerMockMatches;
    if (_filter == 'High Intensity') {
      return List<MatchAnalysisModel>.from(list)
        ..sort((a, b) => b.intensity.compareTo(a.intensity));
    }
    if (_filter == 'Best') {
      return List<MatchAnalysisModel>.from(list)
        ..sort((a, b) => b.summary.homeAvgRating.compareTo(a.summary.homeAvgRating));
    }
    return list;
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await HapticService.refresh();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  void _openAnalysis(MatchAnalysisModel m) {
    HapticService.selection();
    context.push('/fan-match-analysis', extra: m);
  }

  void _setFilter(String f) {
    if (_filter == f) return;
    HapticService.selection();
    setState(() => _filter = f);
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;
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
            // ── Premium Page Header ─────────────────────────────────────────
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
                                      'MATCH ARCHIVE',
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
                                      color: AppColors.accentCyan.withValues(alpha: 0.1),
                                      borderRadius: AppRadius.chip,
                                      border: Border.all(
                                        color: AppColors.accentCyan.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${matches.length} MATCHES',
                                      style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(
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
                                'Matches',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                                  fontSize: context.rs(30, min: 26, max: 36),
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: context.rs(4, min: 3, max: 6)),
                              Text(
                                'AI-powered analysis · Performance insights',
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
                            Icons.sports_soccer_rounded,
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

            SizedBox(height: context.rs(12, min: 10, max: 16)),

            // ── Filter chips ─────────────────────────────────────────────────
            FadeTransition(
              opacity: _filterFade,
              child: SizedBox(
                height: context.rs(38, min: 34, max: 44),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => SizedBox(width: context.rs(8, min: 6, max: 10)),
                  itemBuilder: (context, index) {
                    final f = _filters[index];
                    final selected = _filter == f;
                    return GestureDetector(
                      onTap: () => _setFilter(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(16, min: 12, max: 20),
                          vertical: context.rs(8, min: 6, max: 10),
                        ),
                        decoration: BoxDecoration(
                          gradient: selected ? AppGradients.brand : null,
                          color: selected ? null : AppColors.surfaceElevated,
                          borderRadius: AppRadius.button,
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : AppColors.outlineSubtle,
                          ),
                        ),
                        child: Text(
                          f,
                          style: AppTextStyles.caption(
                            color: selected ? Colors.white : AppColors.textSecondary,
                          ).copyWith(
                            fontSize: context.rs(12, min: 11, max: 14),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: context.rs(12, min: 10, max: 16)),

            // ── Match list ───────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _listFade,
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.accentCyan,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 2.5,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final item = matches[index];
                      final isRecent = index == 0 && _filter == 'Recent';
                      return _AnimatedMatchCard(
                        key: ValueKey('${item.matchId}_$_filter'),
                        delay: Duration(milliseconds: 50 * index),
                        child: MatchCard(
                          match: item,
                          isRecent: isRecent,
                          onTap: () => _openAnalysis(item),
                        ),
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

// ── Animated match card wrapper ───────────────────────────────────────────────

class _AnimatedMatchCard extends StatefulWidget {
  const _AnimatedMatchCard({
    super.key,
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_AnimatedMatchCard> createState() => _AnimatedMatchCardState();
}

class _AnimatedMatchCardState extends State<_AnimatedMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(_fade);
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
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
