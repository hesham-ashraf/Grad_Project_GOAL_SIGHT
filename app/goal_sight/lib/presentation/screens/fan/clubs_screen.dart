import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/repository_providers.dart';
import '../../../shared/widgets/paginated_list_view.dart';
import '../../widgets/fan/club_card.dart';

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _handleRefresh() async {
    await HapticService.refresh();
    await ref.read(clubsPagedProvider(_searchQuery).notifier).refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagedState = ref.watch(clubsPagedProvider(_searchQuery));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Page Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(14, min: 10, max: 18),
              ),
              child: Container(
                padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.cardLarge,
                  color: AppColors.surfaceElevated.withValues(alpha: 0.72),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'CLUBS HUB',
                                  style: AppTextStyles.caption(color: Colors.white).copyWith(
                                    fontSize: context.rs(10, min: 9, max: 11),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              SizedBox(height: context.rs(10, min: 8, max: 12)),
                              Text(
                                'Clubs',
                                style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                                  fontSize: context.rs(30, min: 26, max: 36),
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: context.rs(4, min: 3, max: 6)),
                              Text(
                                'Discover teams, squads, and full analytics',
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
                            Icons.groups_rounded,
                            size: context.rs(24, min: 20, max: 28),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs(14, min: 12, max: 18)),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: AppTextStyles.body(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search clubs...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: context.rs(20, min: 18, max: 24),
                        ),
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.7),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: context.rs(14, min: 12, max: 16),
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.input,
                          borderSide: BorderSide(color: AppColors.outlineSubtle),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: AppRadius.input,
                          borderSide: BorderSide(color: AppColors.outlineSubtle),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: AppRadius.input,
                          borderSide: BorderSide(color: AppColors.primaryPurple),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grid View — server-paginated with infinite scroll.
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: PaginatedListView(
                    state: pagedState,
                    onLoadMore: () =>
                        ref.read(clubsPagedProvider(_searchQuery).notifier).loadMore(),
                    onRefresh: _handleRefresh,
                    padding: EdgeInsets.fromLTRB(
                      context.rs(20, min: 16, max: 24),
                      context.rs(8, min: 4, max: 12),
                      context.rs(20, min: 16, max: 24),
                      context.rs(100, min: 80, max: 120),
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: context.rs(16, min: 12, max: 20),
                      mainAxisSpacing: context.rs(16, min: 12, max: 20),
                    ),
                    emptyBuilder: (_) => _EmptyClubsState(query: _searchQuery),
                    itemBuilder: (context, club, index) => ClubCard(
                      club: club,
                      onTap: () => context.push('/fan-club-details', extra: club),
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

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyClubsState extends StatelessWidget {
  const _EmptyClubsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.rs(32, min: 24, max: 48)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.rs(72, min: 60, max: 80),
              height: context.rs(72, min: 60, max: 80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: Icon(
                query.isNotEmpty ? Icons.search_off_rounded : Icons.groups_outlined,
                size: context.rs(32, min: 26, max: 36),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: context.rs(16, min: 12, max: 20)),
            Text(
              query.isNotEmpty ? 'No clubs match "$query"' : 'No clubs found',
              style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                fontSize: context.rs(16, min: 14, max: 18),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.rs(6, min: 4, max: 8)),
            Text(
              query.isNotEmpty
                  ? 'Try a different search term.'
                  : 'Check back later for club updates.',
              style: AppTextStyles.body(color: AppColors.textMuted).copyWith(
                fontSize: context.rs(13, min: 12, max: 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


