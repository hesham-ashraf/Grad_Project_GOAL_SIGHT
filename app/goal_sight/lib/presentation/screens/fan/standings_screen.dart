import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../state_management/fan_mock_providers.dart';
import '../../widgets/fan/standings_row.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {

  bool _refreshing = false;
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(8, min: 4, max: 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'League Table',
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.rs(32, min: 28, max: 36),
                    ),
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    'Current standings for the 2026 Season',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Pinned Table Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(4, min: 0, max: 8)),
              child: const StandingsHeaderRow(),
            ),
            
            // Scrollable Table Rows
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.accentCyan,
                backgroundColor: AppColors.surface,
                strokeWidth: 2.5,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    context.rs(20, min: 16, max: 24),
                    0, // Header has bottom padding
                    context.rs(20, min: 16, max: 24),
                    context.rs(100, min: 80, max: 120), // Bottom padding for FanBottomNavigationBar
                  ),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: standings.length,
                  itemBuilder: (context, index) {
                    final team = standings[index];
                    return StandingsRow(
                      team: team,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing ${team.teamName} details...'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
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