import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../state_management/fan_mock_providers.dart';
import '../../widgets/fan/match_list_card.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  static const List<String> _filters = ['All', 'Live', 'Top Matches', 'Recent'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(mockMatchesProvider);
    
    // Basic filtering mock logic
    final filteredMatches = matches.where((m) {
      if (_selectedFilter == 'Top Matches') return m.isTopMatch;
      if (_selectedFilter == 'Recent') return m.date != 'Today, 20:00';
      if (_selectedFilter == 'Live') return false; // Mocking no live matches right now
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header & Filters
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(12, min: 8, max: 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matches',
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.rs(32, min: 28, max: 36),
                    ),
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    'Browse past and upcoming fixtures',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Filter Chips
            SizedBox(
              height: context.rs(48, min: 40, max: 56),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(20, min: 16, max: 24),
                ),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => SizedBox(
                  width: context.rs(10, min: 8, max: 12),
                ),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(16, min: 14, max: 20),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPurple.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: AppRadius.chip,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPurple.withValues(alpha: 0.5)
                              : AppColors.outlineSubtle,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: AppTextStyles.button(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ).copyWith(
                          fontSize: context.rs(13, min: 12, max: 14),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: context.rs(8, min: 4, max: 12)),
            
            // Matches List
            Expanded(
              child: filteredMatches.isEmpty
                  ? Center(
                      child: Text(
                        'No matches found.',
                        style: AppTextStyles.body(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        context.rs(20, min: 16, max: 24),
                        context.rs(12, min: 8, max: 16),
                        context.rs(20, min: 16, max: 24),
                        context.rs(40, min: 20, max: 60), // Extra padding at bottom
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredMatches.length,
                      separatorBuilder: (context, index) => SizedBox(
                        height: context.rs(16, min: 12, max: 20),
                      ),
                      itemBuilder: (context, index) {
                        return MatchListCard(
                          match: filteredMatches[index],
                          onTap: () {
                            context.push('/fan-match-analysis', extra: filteredMatches[index]);
                          },
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