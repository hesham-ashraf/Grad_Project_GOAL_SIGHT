import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/features/manager/widgets/profile_header.dart';
import 'package:goal_sight/features/manager/widgets/info_tile.dart';
import 'package:goal_sight/features/manager/widgets/action_tile.dart';

import '../../../presentation/state_management/app_providers.dart';

class ManagerProfileScreen extends ConsumerWidget {
  const ManagerProfileScreen({Key? key}) : super(key: key);

  // Mock data; replace with provider when available
  Map<String, dynamic> get _mockManager => {
        'name': 'Alex Morgan',
        'role': 'Manager',
        'club': 'GoalSight FC',
        'email': 'alex.morgan@goalsightfc.com',
        'matchesAnalyzed': 124,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = _mockManager;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundAlt,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.headline(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(AppSpacing.lg), vertical: context.rs(AppSpacing.md)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: context.rs(AppSpacing.lg)),

                    ProfileHeader(
                      avatarInitials: _avatarInitials(manager['name']),
                      name: manager['name'],
                      role: manager['role'],
                      club: manager['club'],
                      subtitle: 'Team Manager',
                    ),

                    SizedBox(height: context.rs(AppSpacing.lg)),

                    // Info cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              InfoTile(
                                title: 'Email',
                                value: manager['email'],
                                icon: Icons.email_outlined,
                              ),
                              SizedBox(height: context.rs(AppSpacing.md)),
                              InfoTile(
                                title: 'Club Assigned',
                                value: manager['club'],
                                icon: Icons.flag_outlined,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.rs(AppSpacing.md)),
                        Expanded(
                          child: Column(
                            children: [
                              InfoTile(
                                title: 'Matches Analyzed',
                                value: '${manager['matchesAnalyzed']}',
                                icon: Icons.timeline,
                              ),
                              SizedBox(height: context.rs(AppSpacing.md)),
                              InfoTile(
                                title: 'Role',
                                value: manager['role'],
                                icon: Icons.person_outline,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.rs(AppSpacing.lg)),

                    // Actions
                    Card(
                      color: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(context.rs(AppSpacing.md)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Actions', style: AppTextStyles.title(color: AppColors.textPrimary)),
                            SizedBox(height: context.rs(AppSpacing.sm)),
                            ActionTile(
                              label: 'Edit Profile',
                              icon: Icons.edit_outlined,
                              onTap: () {},
                            ),
                            Divider(color: AppColors.outline.withOpacity(0.12)),
                            ActionTile(
                              label: 'Settings',
                              icon: Icons.settings_outlined,
                              onTap: () {},
                            ),
                            Divider(color: AppColors.outline.withOpacity(0.12)),
                            ActionTile(
                              label: 'Logout',
                              icon: Icons.logout,
                              destructive: true,
                              onTap: () => ref
                                  .read(authControllerProvider.notifier)
                                  .logout(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: context.rs(AppSpacing.xl)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _avatarInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

