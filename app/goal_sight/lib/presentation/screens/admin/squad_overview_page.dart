import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/player_analysis_model.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../widgets/admin/admin_squad_widgets.dart';

class SquadOverviewPage extends ConsumerStatefulWidget {
  const SquadOverviewPage({super.key});

  @override
  ConsumerState<SquadOverviewPage> createState() => _SquadOverviewPageState();
}

class _SquadOverviewPageState extends ConsumerState<SquadOverviewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  String _searchQuery = '';
  String _sortMode = 'Risk'; // Risk | Fatigue | Rating | Impact
  String _posFilter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _fades = List.generate(4, (i) {
      final start = (i * 0.18).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _slides = _fades.map((f) =>
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(f)).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PlayerAnalysisModel> _filteredSquad(List<PlayerAnalysisModel> all) {
    var list = all.where((p) {
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchPos = _posFilter == 'All' || p.position.contains(_posFilter);
      return matchSearch && matchPos;
    }).toList();

    switch (_sortMode) {
      case 'Risk':
        list.sort((a, b) => b.injuryRisk.compareTo(a.injuryRisk));
      case 'Fatigue':
        list.sort((a, b) => b.fatigueLevel.compareTo(a.fatigueLevel));
      case 'Rating':
        list.sort((a, b) => b.overallRating.compareTo(a.overallRating));
      case 'Impact':
        list.sort((a, b) => b.tacticalImpact.compareTo(a.tacticalImpact));
    }
    return list;
  }

  Widget _reveal(int i, Widget child) {
    return FadeTransition(opacity: _fades[i], child: SlideTransition(position: _slides[i], child: child));
  }

  @override
  Widget build(BuildContext context) {
    final squadAsync = ref.watch(adminSquadProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.groups_outlined, color: AppColors.accentCyan, size: 20),
            const SizedBox(width: 8),
            Text('Squad Intelligence', style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(fontSize: context.sp(17, min: 15, max: 20))),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Icon(Icons.sort, color: Colors.white, size: 16),
            ),
            color: AppColors.surfaceElevated,
            onSelected: (v) => setState(() => _sortMode = v),
            itemBuilder: (_) => ['Risk', 'Fatigue', 'Rating', 'Impact'].map((s) {
              return PopupMenuItem<String>(
                value: s,
                child: Row(
                  children: [
                    if (_sortMode == s) const Icon(Icons.check, color: AppColors.accentCyan, size: 16),
                    if (_sortMode != s) const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text('Sort by $s', style: AppTextStyles.body(color: Colors.white)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: squadAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentCyan),
        ),
        error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.invalidate(adminSquadProvider),
        ),
        data: (allPlayers) {
          final players = _filteredSquad(allPlayers);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.rs(20, min: 16, max: 28),
              context.rs(4, min: 2, max: 8),
              context.rs(20, min: 16, max: 28),
              context.rs(100, min: 80, max: 120),
            ),
            physics: const BouncingScrollPhysics(),
            children: [
              // 0 — Condition header
              _reveal(0, const SquadConditionHeader()),
              const SizedBox(height: 16),

              // 1 — Search + position filters
              _reveal(1, Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: AppTextStyles.body(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search player...',
                        hintStyle: AppTextStyles.body(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                                onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['All', 'GK', 'CB', 'RB', 'LB', 'CDM', 'CM', 'CAM', 'RW', 'LW', 'ST'].map((pos) {
                        final sel = _posFilter == pos;
                        return GestureDetector(
                          onTap: () => setState(() => _posFilter = pos),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.accentCyan.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: sel ? AppColors.accentCyan.withValues(alpha: 0.5) : AppColors.outline),
                            ),
                            child: Text(
                              pos,
                              style: AppTextStyles.caption(color: sel ? AppColors.accentCyan : AppColors.textSecondary)
                                  .copyWith(fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 16),

              // 2 — Player list
              _reveal(2, players.isEmpty
                  ? _EmptyState(query: _searchQuery)
                  : Column(
                      children: players.map((p) => EnhancedPlayerAnalyticsCard(player: p)).toList(),
                    )),
              const SizedBox(height: 16),

              // 3 — Tactical contribution + strengths
              _reveal(3, const Column(
                children: [
                  SquadTacticalContributionSection(),
                  SizedBox(height: 20),
                  SquadRiskRankingSection(),
                  SizedBox(height: 20),
                  SquadStrengthsGrid(),
                ],
              )),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.person_off_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'No players in squad' : 'No results for "$query"',
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
