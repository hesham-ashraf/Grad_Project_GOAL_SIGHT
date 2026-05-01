import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/fan/profile_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final name = user?.name ?? 'Guest Fan';
    final email = user?.email.isNotEmpty == true ? user!.email : 'user@example.com';
    final roleLabel = user?.role.label ?? UserRole.fan.label;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            context.rs(24, min: 20, max: 32),
            context.rs(40, min: 32, max: 56),
            context.rs(24, min: 20, max: 32),
            context.rs(100, min: 80, max: 120), // Padding for FanBottomNavigationBar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              ProfileHeader(
                name: name,
                role: roleLabel,
                subtitle: 'Football Enthusiast',
              ),
              SizedBox(height: context.rs(40, min: 32, max: 48)),
              
              // Info Section
              Text(
                'Personal Info',
                style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                  fontSize: context.rs(18, min: 16, max: 20),
                ),
              ),
              SizedBox(height: context.rs(16, min: 12, max: 20)),
              ProfileItem(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: email,
              ),
              const ProfileItem(
                icon: Icons.favorite_border_rounded,
                label: 'Favorite Club',
                value: 'GoalSight FC',
                valueColor: AppColors.accentCyan,
              ),
              SizedBox(height: context.rs(32, min: 24, max: 40)),
              
              // Actions Section
              Text(
                'Account Settings',
                style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                  fontSize: context.rs(18, min: 16, max: 20),
                ),
              ),
              SizedBox(height: context.rs(16, min: 12, max: 20)),
              ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit Profile (Coming Soon)')),
                  );
                },
              ),
              ActionTile(
                icon: Icons.settings_outlined,
                label: 'App Settings',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings (Coming Soon)')),
                  );
                },
              ),
              SizedBox(height: context.rs(16, min: 12, max: 20)),
              ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isDestructive: true,
                onTap: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}