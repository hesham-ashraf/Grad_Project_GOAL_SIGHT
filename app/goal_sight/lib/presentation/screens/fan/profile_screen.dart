import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/user_model.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/fan/fan_section_placeholder.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return FanSectionPlaceholder(
      badgeText: 'ACCOUNT',
      title: user?.name ?? 'Fan Profile',
      subtitle:
          'Review your account details and keep your browsing session tidy with a quick sign out.',
      icon: Icons.person_rounded,
      accentColor: AppColors.primaryPurple,
      highlights: [
        'Read-only access',
        user?.email.isNotEmpty == true ? 'Signed in' : 'Profile pending',
        user?.role.label ?? UserRole.fan.label,
      ],
      body: _ProfileCard(
        user: user,
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onLogout});

  final UserModel? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Guest Fan';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'No email available';
    final roleLabel = user?.role.label ?? UserRole.fan.label;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.9),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(18, min: 16, max: 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.rs(58, min: 54, max: 64),
                  height: context.rs(58, min: 54, max: 64),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.brand,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _buildInitials(name),
                      style: AppTextStyles.title(color: Colors.white).copyWith(
                        fontSize: context.rs(18, min: 16, max: 20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.rs(14, min: 12, max: 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title(color: AppColors.textPrimary)
                            .copyWith(
                          fontSize: context.rs(20, min: 18, max: 24),
                        ),
                      ),
                      SizedBox(height: context.rs(6, min: 4, max: 8)),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles.body(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: context.rs(10, min: 8, max: 12)),
                      Wrap(
                        spacing: context.rs(8, min: 6, max: 10),
                        runSpacing: context.rs(8, min: 6, max: 10),
                        children: [
                          _InfoPill(label: roleLabel),
                          const _InfoPill(label: 'Premium fan access'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(16, min: 12, max: 18)),
            ElevatedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(12, min: 10, max: 14),
        vertical: context.rs(7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
          fontSize: context.rs(10, min: 9, max: 11),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _buildInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (words.isEmpty) {
    return 'F';
  }

  if (words.length == 1) {
    final value = words.first;
    return value.length >= 2 ? value.substring(0, 2).toUpperCase() : value.toUpperCase();
  }

  final first = words.first.isNotEmpty ? words.first[0] : 'F';
  final last = words.last.isNotEmpty ? words.last[0] : first;
  return '$first$last'.toUpperCase();
}