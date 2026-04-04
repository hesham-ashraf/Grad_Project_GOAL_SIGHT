import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/match_model.dart';
import '../../../features/fan/fan_highlight_model.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/fan/dashboard_card.dart';
import '../../widgets/fan/fan_skeletons.dart';
import '../../widgets/fan/highlight_card.dart';
import '../../widgets/fan/match_tile.dart';
import '../../widgets/fan/tap_scale.dart';

class FanDashboardScreen extends ConsumerStatefulWidget {
  const FanDashboardScreen({super.key});

  @override
  ConsumerState<FanDashboardScreen> createState() => _FanDashboardScreenState();
}

class _FanDashboardScreenState extends ConsumerState<FanDashboardScreen> {
  Future<void> _refresh() async {
    ref.invalidate(fanLiveMatchesProvider);
    ref.invalidate(fanHighlightsProvider);

    try {
      await Future.wait([
        ref.read(fanLiveMatchesProvider.future),
        ref.read(fanHighlightsProvider.future),
      ]);
    } catch (_) {
      // Errors are rendered in section UI with retry actions.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final liveAsync = ref.watch(fanLiveMatchesProvider);
    final highlightsAsync = ref.watch(fanHighlightsProvider);
    final featuredMatch = ref.watch(fanFeaturedMatchProvider);
    final todayMatches = ref.watch(fanTodayMatchesProvider);
    final recentResults = ref.watch(fanRecentResultsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Fan Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0F1A), Color(0xFF101326), Color(0xFF0D0F1A)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _AmbientGlow()),
            RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF4DA1FF),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1080;
                  final content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 12,
                                    child: _MainColumn(
                                      userName: authState.user?.name ?? 'Fan',
                                      liveAsync: liveAsync,
                                      featuredMatch: featuredMatch,
                                      todayMatches: todayMatches,
                                      recentResults: recentResults,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 8,
                                    child: _HighlightsColumn(
                                      highlightsAsync: highlightsAsync,
                                      fixedColumns: 2,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _MainColumn(
                                    userName: authState.user?.name ?? 'Fan',
                                    liveAsync: liveAsync,
                                    featuredMatch: featuredMatch,
                                    todayMatches: todayMatches,
                                    recentResults: recentResults,
                                  ),
                                  const SizedBox(height: 18),
                                  _HighlightsColumn(
                                      highlightsAsync: highlightsAsync),
                                ],
                              ),
                      ),
                    ),
                  );

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [content],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatefulWidget {
  const _AmbientGlow();

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -120 + (t * 20),
                right: -70,
                child: _GlowOrb(
                  size: 260,
                  color: const Color(0xFF7B61FF).withOpacity(0.17 + (t * 0.06)),
                ),
              ),
              Positioned(
                left: -90,
                bottom: -120 + ((1 - t) * 30),
                child: _GlowOrb(
                  size: 300,
                  color: const Color(0xFF4DA1FF).withOpacity(0.13 + (t * 0.06)),
                ),
              ),
            ],
          ),
        );
      },
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

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.userName,
    required this.liveAsync,
    required this.featuredMatch,
    required this.todayMatches,
    required this.recentResults,
  });

  final String userName;
  final AsyncValue<List<MatchModel>> liveAsync;
  final MatchModel? featuredMatch;
  final List<MatchModel> todayMatches;
  final List<MatchModel> recentResults;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Reveal(
          delay: 70,
          child: _Header(userName: userName),
        ),
        const SizedBox(height: 14),
        _Reveal(
          delay: 130,
          child: _LiveMatchesSection(liveAsync: liveAsync),
        ),
        const SizedBox(height: 14),
        _Reveal(
          delay: 190,
          child: _FeaturedMatchCard(match: featuredMatch),
        ),
        const SizedBox(height: 14),
        _Reveal(
          delay: 250,
          child: _TodayMatchesSection(todayMatches: todayMatches),
        ),
        const SizedBox(height: 14),
        _Reveal(
          delay: 310,
          child: _RecentResultsSection(recentResults: recentResults),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final initial = userName.isEmpty ? 'F' : userName.trim().toUpperCase()[0];

    return DashboardCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Stay updated with the latest football action',
                  style: TextStyle(color: Color(0xFF9CA8C8)),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B61FF), Color(0xFF4DA1FF)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D7B61FF),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMatchesSection extends ConsumerWidget {
  const _LiveMatchesSection({required this.liveAsync});

  final AsyncValue<List<MatchModel>> liveAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Live Matches',
            trailing: TapScale(
              onTap: () => ref.invalidate(fanLiveMatchesProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF4DA1FF)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          liveAsync.when(
            loading: () => const Column(
              children: [
                FanCardSkeleton(height: 84),
                SizedBox(height: 10),
                FanCardSkeleton(height: 84),
              ],
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x2EEA4D5A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66EA4D5A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF8D96)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Failed to load live matches. Please try again.',
                      style: TextStyle(color: Color(0xFFFFB6BD)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(fanLiveMatchesProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
            data: (matches) {
              final live = matches
                  .where((match) => match.status.toLowerCase() == 'live')
                  .toList();

              if (live.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13162A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF262D4D)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.live_tv_outlined, color: Color(0xFF98A3C2)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No live matches at the moment. Check highlights below.',
                          style: TextStyle(color: Color(0xFF9CA8C8)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: live
                    .map((match) => MatchTile(match: match, onTap: () {}))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedMatchCard extends StatelessWidget {
  const _FeaturedMatchCard({required this.match});

  final MatchModel? match;

  @override
  Widget build(BuildContext context) {
    if (match == null) {
      return const FanCardSkeleton(height: 160, borderRadius: 22);
    }

    final scoreParts =
        match!.score.split('-').map((part) => part.trim()).toList();
    final homeScore = scoreParts.isNotEmpty ? scoreParts.first : '0';
    final awayScore = scoreParts.length > 1 ? scoreParts.last : '0';

    return DashboardCard(
      glow: true,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B61FF), Color(0xFF4DA1FF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Featured Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const _LivePill(),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Premier League',
              style: TextStyle(color: Color(0xFFE4E8FF), fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    match!.homeTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _AnimatedScore(homeScore: homeScore, awayScore: awayScore),
                Expanded(
                  child: Text(
                    match!.awayTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Old Trafford, 74:30',
              style: TextStyle(color: Color(0xFFE6E9FF), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePill extends StatefulWidget {
  const _LivePill();

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final glow = 0.2 + (t * 0.45);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x66FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9FFFC1).withOpacity(glow),
                blurRadius: 12 + (t * 8),
                spreadRadius: 0.5 + t,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.9 + (t * 0.25),
                child: const Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF9FFFC1),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({
    required this.homeScore,
    required this.awayScore,
  });

  final String homeScore;
  final String awayScore;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: !_ready
          ? Container(
              key: const ValueKey('score-placeholder'),
              width: 72,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x44FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
            )
          : Container(
              key: const ValueKey('score-value'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: Text(
                '${widget.homeScore} : ${widget.awayScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
    );
  }
}

class _TodayMatchesSection extends StatelessWidget {
  const _TodayMatchesSection({required this.todayMatches});

  final List<MatchModel> todayMatches;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: "Today's Matches",
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFBFD2FF),
              ),
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: 10),
          if (todayMatches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111428),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF262D4D)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 36,
                    color: Color(0xFF7B88AD),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No matches today',
                    style: TextStyle(
                      color: Color(0xFFB7C3E2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Come back later for fresh fixtures.',
                    style: TextStyle(color: Color(0xFF8692B3), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: todayMatches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final match = todayMatches[index];
                  return _TodayMatchChip(match: match);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayMatchChip extends StatelessWidget {
  const _TodayMatchChip({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111428),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF262D4D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.status.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9CA8C8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${match.homeTeam} vs ${match.awayTeam}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.score,
              style: const TextStyle(
                color: Color(0xFFBFD2FF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentResultsSection extends StatelessWidget {
  const _RecentResultsSection({required this.recentResults});

  final List<MatchModel> recentResults;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Recent Results'),
          const SizedBox(height: 10),
          if (recentResults.isEmpty)
            const Text(
              'No recent results available.',
              style: TextStyle(color: Color(0xFF94A0C1)),
            )
          else
            Column(
              children: recentResults
                  .map((match) => MatchTile(match: match, onTap: () {}))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _HighlightsColumn extends StatelessWidget {
  const _HighlightsColumn({
    required this.highlightsAsync,
    this.fixedColumns,
  });

  final AsyncValue<List<FanHighlightModel>> highlightsAsync;
  final int? fixedColumns;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = fixedColumns ?? (width > 860 ? 2 : 1);

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Video Highlights'),
          const SizedBox(height: 12),
          highlightsAsync.when(
            loading: () => FanHighlightsGridSkeleton(
              crossAxisCount: crossAxisCount,
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x2EEA4D5A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66EA4D5A)),
              ),
              child: const Text(
                'Failed to load highlights. Pull to refresh and try again.',
                style: TextStyle(color: Color(0xFFFFB6BD)),
              ),
            ),
            data: (items) => GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final highlight = items[index];
                return HighlightCard(
                  highlight: highlight,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing: ${highlight.title}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.child,
    this.delay = 0,
  });

  final Widget child;
  final int delay;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}
