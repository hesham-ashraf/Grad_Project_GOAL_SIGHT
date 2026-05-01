import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/fan/match_list_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  static const List<String> _filters = ['All', 'Live', 'Top Matches', 'Recent'];
  String _selectedFilter = 'All';

  // Mock data for the matches list
  static const List<FanMatchItemData> _mockMatches = [
    FanMatchItemData(
      id: 'm1',
      homeTeam: 'GoalSight FC',
      awayTeam: 'Falcons United',
      score: '3 - 1',
      date: 'Today, 20:00',
      status: 'FT',
      intensity: 91,
      homeColor: AppColors.accentCyan,
      awayColor: AppColors.primaryPurple,
      highlightText: 'High intensity match',
      isTopMatch: true,
    ),
    FanMatchItemData(
      id: 'm2',
      homeTeam: 'Sharks FC',
      awayTeam: 'Eagles Club',
      score: '0 - 0',
      date: 'Yesterday',
      status: 'FT',
      intensity: 65,
      homeColor: AppColors.primaryBlue,
      awayColor: AppColors.danger,
    ),
    FanMatchItemData(
      id: 'm3',
      homeTeam: 'Lions City',
      awayTeam: 'GoalSight FC',
      score: '1 - 2',
      date: 'Oct 12',
      status: 'FT',
      intensity: 85,
      homeColor: AppColors.warning,
      awayColor: AppColors.accentCyan,
      highlightText: 'Last minute winner',
    ),
    FanMatchItemData(
      id: 'm4',
      homeTeam: 'Panthers',
      awayTeam: 'Bulls',
      score: '2 - 2',
      date: 'Oct 10',
      status: 'FT',
      intensity: 88,
      homeColor: AppColors.accentGreen,
      awayColor: AppColors.primaryPurple,
      isTopMatch: true,
    ),
    FanMatchItemData(
      id: 'm5',
      homeTeam: 'Wolves',
      awayTeam: 'GoalSight FC',
      score: '1 - 4',
      date: 'Oct 5',
      status: 'FT',
      intensity: 72,
      homeColor: AppColors.textMuted,
      awayColor: AppColors.accentCyan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Basic filtering mock logic
    final filteredMatches = _mockMatches.where((m) {
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
                            context.push('/fan-match-analysis');
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