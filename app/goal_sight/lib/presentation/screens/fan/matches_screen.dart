import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../state_management/match_analysis_providers.dart';
import '../../widgets/fan/match_list_card.dart';
import '../../widgets/fan/match_status_badge.dart';

// ─── Filter data ─────────────────────────────────────────────────────────────

const _statusFilters = ['All', 'Live', 'Top Matches', 'Recent'];

const _leagueFilters = [
  _LeagueFilter(label: 'All Leagues', icon: Icons.public_rounded),
  _LeagueFilter(label: 'Premier League', icon: Icons.sports_soccer_rounded),
  _LeagueFilter(label: 'La Liga', icon: Icons.sports_soccer_rounded),
  _LeagueFilter(label: 'Champions League', icon: Icons.emoji_events_rounded),
  _LeagueFilter(label: 'Cup', icon: Icons.workspace_premium_rounded),
];

class _LeagueFilter {
  const _LeagueFilter({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with TickerProviderStateMixin {
  // Filters
  String _statusFilter = 'All';
  String _leagueFilter = 'All Leagues';
  DateTime? _dateFilter;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchOpen = false;

  // Animation
  late final AnimationController _searchBarController;
  late final Animation<double> _searchBarFade;
  late final Animation<double> _searchBarWidth;

  // For animated filter chip selection
  late final AnimationController _chipController;

  @override
  void initState() {
    super.initState();

    _searchBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _searchBarFade = CurvedAnimation(
      parent: _searchBarController,
      curve: Curves.easeOutCubic,
    );
    _searchBarWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _searchBarController, curve: Curves.easeOutCubic),
    );

    _chipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1;

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchBarController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  // ── Filtering logic ─────────────────────────────────────────────────────────

  List get _filtered {
    final all = ref.watch(mockAnalysisMatchesProvider);
    return all.where((m) {
      // Status filter
      if (_statusFilter == 'Top Matches' && m.intensity < 80) return false;
      if (_statusFilter == 'Recent' && m.date == 'May 2, 2026 · 20:00') {
        return false;
      }
      if (_statusFilter == 'Live' && m.status != 'LIVE') return false;

      // League filter (basic match against competition strings in mock data)
      if (_leagueFilter != 'All Leagues') {
        final league = _leagueFilter.toLowerCase();
        final home = m.homeTeam.toLowerCase();
        final away = m.awayTeam.toLowerCase();
        // For mock data we match by intensity / team heuristic
        // In production, the model would carry a `competition` field
        final mockLeagueMap = {
          'premier league': m.intensity >= 80,
          'champions league': m.intensity < 70,
          'la liga': m.intensity >= 70 && m.intensity < 80,
          'cup': m.score == '0 - 0',
        };
        final matches = mockLeagueMap[league] ?? true;
        if (!matches) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        if (!m.homeTeam.toLowerCase().contains(q) &&
            !m.awayTeam.toLowerCase().contains(q) &&
            !m.score.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      _searchBarController.forward();
    } else {
      _searchBarController.reverse();
      _searchController.clear();
    }
  }

  void _selectStatus(String f) => setState(() => _statusFilter = f);
  void _selectLeague(String l) => setState(() => _leagueFilter = l);

  bool _refreshing = false;
  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await HapticService.refresh();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? now,
      firstDate: DateTime(2024),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.cardLarge,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateFilter = picked);
  }

  void _clearDate() => setState(() => _dateFilter = null);

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(10, min: 8, max: 14),
              ),
              child: _Header(
                searchOpen: _searchOpen,
                searchController: _searchController,
                searchBarFade: _searchBarFade,
                onToggleSearch: _toggleSearch,
                resultCount: filtered.length,
              ),
            ),

            // ── Search bar (animated slide-in) ──────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _searchOpen
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.rs(20, min: 16, max: 24),
                        0,
                        context.rs(20, min: 16, max: 24),
                        context.rs(10, min: 8, max: 12),
                      ),
                      child: FadeTransition(
                        opacity: _searchBarFade,
                        child: _SearchBar(controller: _searchController),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Status filter chips ─────────────────────────────────────────
            _FilterChipRow(
              filters: _statusFilters,
              selected: _statusFilter,
              onSelect: _selectStatus,
            ),

            SizedBox(height: context.rs(8, min: 6, max: 10)),

            // ── League filter chips ─────────────────────────────────────────
            _LeagueChipRow(
              filters: _leagueFilters,
              selected: _leagueFilter,
              onSelect: _selectLeague,
            ),

            SizedBox(height: context.rs(6, min: 4, max: 8)),

            // ── Date filter ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(20, min: 16, max: 24),
              ),
              child: _DateFilterRow(
                dateFilter: _dateFilter,
                onPick: _pickDate,
                onClear: _clearDate,
              ),
            ),

            SizedBox(height: context.rs(8, min: 6, max: 10)),

            // ── Match list ──────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(query: _searchQuery)
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.accentCyan,
                      backgroundColor: AppColors.surface,
                      strokeWidth: 2.5,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          context.rs(20, min: 16, max: 24),
                          context.rs(4, min: 2, max: 8),
                          context.rs(20, min: 16, max: 24),
                          context.rs(40, min: 20, max: 60),
                        ),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: context.rs(16, min: 12, max: 20)),
                      itemBuilder: (context, index) {
                        final match = filtered[index];
                        return _AnimatedMatchCard(
                          index: index,
                          child: MatchListCard(
                            match: match,
                            onTap: () => context.push(
                              '/fan-match-analysis',
                              extra: match,
                            ),
                          ),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.searchOpen,
    required this.searchController,
    required this.searchBarFade,
    required this.onToggleSearch,
    required this.resultCount,
  });

  final bool searchOpen;
  final TextEditingController searchController;
  final Animation<double> searchBarFade;
  final VoidCallback onToggleSearch;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matches',
                style: AppTextStyles.headline(color: AppColors.textPrimary)
                    .copyWith(fontSize: context.rs(32, min: 28, max: 36)),
              ),
              SizedBox(height: context.rs(4, min: 2, max: 6)),
              Text(
                '$resultCount fixture${resultCount != 1 ? 's' : ''} found',
                style: AppTextStyles.body(color: AppColors.textSecondary)
                    .copyWith(fontSize: context.rs(13, min: 12, max: 14)),
              ),
            ],
          ),
        ),
        // Search toggle button
        _IconBtn(
          icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
          active: searchOpen,
          onTap: onToggleSearch,
        ),
      ],
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.92),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: AppTextStyles.body(color: AppColors.textPrimary),
        cursorColor: AppColors.primaryPurple,
        decoration: InputDecoration(
          hintText: 'Search teams, clubs, matches…',
          hintStyle: AppTextStyles.body(color: AppColors.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryPurple,
            size: context.rs(20, min: 18, max: 22),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: context.rs(18, min: 16, max: 20),
                    color: AppColors.textMuted,
                  ),
                  onPressed: controller.clear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.rs(16, min: 14, max: 18),
            vertical: context.rs(14, min: 12, max: 16),
          ),
          filled: false,
        ),
      ),
    );
  }
}

// ─── Status Filter Chip Row ───────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.rs(40, min: 36, max: 46),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(20, min: 16, max: 24),
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: context.rs(8, min: 6, max: 10)),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter;
          final isLive = filter == 'Live';

          return GestureDetector(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(14, min: 12, max: 18),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isLive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primaryPurple.withValues(alpha: 0.15))
                    : AppColors.surfaceElevated,
                borderRadius: AppRadius.chip,
                border: Border.all(
                  color: isSelected
                      ? (isLive
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.primaryPurple.withValues(alpha: 0.5))
                      : AppColors.outlineSubtle,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isLive
                                  ? AppColors.success
                                  : AppColors.primaryPurple)
                              .withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLive && isSelected) ...[
                    _MiniLiveDot(),
                    SizedBox(width: context.rs(5, min: 4, max: 6)),
                  ],
                  Text(
                    filter,
                    style: AppTextStyles.button(
                      color: isSelected
                          ? (isLive ? AppColors.success : AppColors.textPrimary)
                          : AppColors.textSecondary,
                    ).copyWith(
                      fontSize: context.rs(13, min: 12, max: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── League Filter Chip Row ───────────────────────────────────────────────────

class _LeagueChipRow extends StatelessWidget {
  const _LeagueChipRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<_LeagueFilter> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.rs(36, min: 32, max: 42),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(20, min: 16, max: 24),
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: context.rs(6, min: 5, max: 8)),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = selected == f.label;

          return GestureDetector(
            onTap: () => onSelect(f.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(12, min: 10, max: 14),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentCyan.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: AppRadius.chip,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentCyan.withValues(alpha: 0.45)
                      : AppColors.outlineSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.icon,
                    size: context.rs(12, min: 11, max: 14),
                    color: isSelected
                        ? AppColors.accentCyan
                        : AppColors.textMuted,
                  ),
                  SizedBox(width: context.rs(5, min: 4, max: 6)),
                  Text(
                    f.label,
                    style: AppTextStyles.caption(
                      color: isSelected
                          ? AppColors.accentCyan
                          : AppColors.textSecondary,
                    ).copyWith(
                      fontSize: context.rs(11, min: 10, max: 12),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Date Filter Row ──────────────────────────────────────────────────────────

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.dateFilter,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dateFilter;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasDate = dateFilter != null;
    final label = hasDate
        ? '${dateFilter!.day}/${dateFilter!.month}/${dateFilter!.year}'
        : 'Filter by date';

    return Row(
      children: [
        GestureDetector(
          onTap: onPick,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(12, min: 10, max: 14),
              vertical: context.rs(7, min: 6, max: 8),
            ),
            decoration: BoxDecoration(
              color: hasDate
                  ? AppColors.primaryBlue.withValues(alpha: 0.12)
                  : AppColors.surfaceElevated,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: hasDate
                    ? AppColors.primaryBlue.withValues(alpha: 0.45)
                    : AppColors.outlineSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: context.rs(12, min: 11, max: 14),
                  color:
                      hasDate ? AppColors.primaryBlue : AppColors.textMuted,
                ),
                SizedBox(width: context.rs(6, min: 5, max: 7)),
                Text(
                  label,
                  style: AppTextStyles.caption(
                    color: hasDate
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                  ).copyWith(
                    fontSize: context.rs(11, min: 10, max: 12),
                    fontWeight:
                        hasDate ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasDate) ...[
          SizedBox(width: context.rs(8, min: 6, max: 10)),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: EdgeInsets.all(context.rs(6, min: 5, max: 7)),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                size: context.rs(12, min: 11, max: 14),
                color: AppColors.danger,
              ),
            ),
          ),
        ],
        const Spacer(),
        // Live matches badge
        MatchStatusBadge(
          status: MatchStatus.live,
          compact: true,
        ),
        SizedBox(width: context.rs(6, min: 4, max: 8)),
        MatchStatusBadge(
          status: MatchStatus.analysisReady,
          compact: true,
        ),
      ],
    );
  }
}

// ─── Animated match card entry ────────────────────────────────────────────────

class _AnimatedMatchCard extends StatefulWidget {
  const _AnimatedMatchCard({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedMatchCard> createState() => _AnimatedMatchCardState();
}

class _AnimatedMatchCardState extends State<_AnimatedMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 60).clamp(0, 400);
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
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

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.rs(64, min: 56, max: 72),
            height: context.rs(64, min: 56, max: 72),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Icon(
              query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.sports_soccer_rounded,
              size: context.rs(28, min: 24, max: 32),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          Text(
            query.isNotEmpty ? 'No matches for "$query"' : 'No matches found',
            style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
              fontSize: context.rs(16, min: 14, max: 18),
            ),
          ),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(
            'Try adjusting your filters or search query.',
            style: AppTextStyles.body(color: AppColors.textMuted).copyWith(
              fontSize: context.rs(13, min: 12, max: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.active, required this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: context.rs(40, min: 36, max: 44),
        height: context.rs(40, min: 36, max: 44),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.primaryPurple.withValues(alpha: 0.16)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: active
                ? AppColors.primaryPurple.withValues(alpha: 0.45)
                : AppColors.outlineSubtle,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: context.rs(20, min: 18, max: 22),
          color: active ? AppColors.primaryPurple : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MiniLiveDot extends StatefulWidget {
  @override
  State<_MiniLiveDot> createState() => _MiniLiveDotState();
}

class _MiniLiveDotState extends State<_MiniLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: _opacity.value),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: _opacity.value * 0.6),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
