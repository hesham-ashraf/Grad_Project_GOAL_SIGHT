import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/club_model.dart';
import '../../state_management/clubs_provider.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allClubs = ref.watch(mockClubsProvider);
    final filteredClubs = allClubs.where((club) {
      return club.name.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header & Search
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(16, min: 12, max: 20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clubs Hub',
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.rs(32, min: 28, max: 36),
                    ),
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    'Discover teams, squads, and stadiums',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: context.rs(20, min: 16, max: 24)),

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
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: context.rs(14, min: 12, max: 16),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.input,
                        borderSide: const BorderSide(color: AppColors.outlineSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.input,
                        borderSide: const BorderSide(color: AppColors.outlineSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.input,
                        borderSide: const BorderSide(color: AppColors.primaryPurple),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid View
            Expanded(
              child: filteredClubs.isEmpty
                  ? Center(
                      child: Text(
                        'No clubs found.',
                        style: AppTextStyles.body(color: AppColors.textMuted),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                            context.rs(20, min: 16, max: 24),
                            context.rs(8, min: 4, max: 12),
                            context.rs(20, min: 16, max: 24),
                            context.rs(100, min: 80, max: 120),
                          ),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: context.rs(16, min: 12, max: 20),
                            mainAxisSpacing: context.rs(16, min: 12, max: 20),
                          ),
                          itemCount: filteredClubs.length,
                          itemBuilder: (context, index) {
                            final club = filteredClubs[index];
                            return ClubCard(
                              club: club,
                              onTap: () {
                                context.push('/fan-club-details', extra: club);
                              },
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
