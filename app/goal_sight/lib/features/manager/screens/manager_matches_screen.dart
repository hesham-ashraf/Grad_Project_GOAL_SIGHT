import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import '../../../providers/match_analysis_providers.dart';
import '../../../providers/repository_providers.dart';
import '../widgets/manager_bottom_navigation_bar.dart';
import '../widgets/match_card.dart';

class ManagerMatchesScreen extends ConsumerStatefulWidget {
  const ManagerMatchesScreen({super.key});

  @override
  ConsumerState<ManagerMatchesScreen> createState() => _ManagerMatchesScreenState();
}

class _ManagerMatchesScreenState extends ConsumerState<ManagerMatchesScreen>
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

  List<MatchAnalysisModel> _filteredMatches(List<MatchAnalysisModel> all) {
    if (_filter == 'High Intensity') {
      return List<MatchAnalysisModel>.from(all)
        ..sort((a, b) => b.intensity.compareTo(a.intensity));
    }
    if (_filter == 'Best') {
      return List<MatchAnalysisModel>.from(all)
        ..sort((a, b) => b.summary.homeAvgRating.compareTo(a.summary.homeAvgRating));
    }
    return List.from(all.reversed);
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await HapticService.refresh();
    // Refetch the club's analyses from Supabase (RLS-scoped to the manager's
    // club), then the wrapper provider recomputes off the fresh data.
    ref.invalidate(matchAnalysisListProvider(null));
    await Future.delayed(const Duration(milliseconds: 600));
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
    final allMatches = ref.watch(mockAnalysisMatchesProvider);
    final matches = _filteredMatches(allMatches);
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
                child: matches.isEmpty
                    ? _MatchesEmptyState(
                        onUpload: () {
                          HapticService.selection();
                          context.push('/manager/upload-match');
                        },
                      )
                    : RefreshIndicator(
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

// ── Matches empty state ───────────────────────────────────────────────────────

class _MatchesEmptyState extends StatelessWidget {
  const _MatchesEmptyState({required this.onUpload});
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadows.buttonGlow,
              ),
              child: const Icon(Icons.sports_soccer_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('No matches yet',
                style: AppTextStyles.title(color: Colors.white)
                    .copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Upload your first match video and let\nGoalSight AI generate tactical insights.',
              style: AppTextStyles.body(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: AppRadius.button,
                  boxShadow: AppShadows.buttonGlow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_file_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Upload First Match',
                        style: AppTextStyles.button(color: Colors.white)),
                  ],
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
