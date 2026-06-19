import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

// ─── Background decoration ────────────────────────────────────────────────────

/// Full-screen dark background with subtle gradient orbs.
class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Purple orb — top-left
          Positioned(
            top: -140,
            left: -100,
            child: _AuthOrb(
              size: 380,
              color: AppColors.primaryPurple.withValues(alpha: 0.11),
            ),
          ),
          // Cyan orb — bottom-right
          Positioned(
            bottom: -80,
            right: -100,
            child: _AuthOrb(
              size: 300,
              color: AppColors.accentCyan.withValues(alpha: 0.07),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _AuthOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Glassmorphism card ───────────────────────────────────────────────────────

/// Premium dark glassmorphism auth card.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.padSym(h: 24, v: 26),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(context.rs(24, min: 18, max: 30)),
        border: Border.all(
          color: AppColors.outline,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 48,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Gradient title ───────────────────────────────────────────────────────────

/// Auth screen title with brand gradient.
class AuthGradientTitle extends StatelessWidget {
  final String text;
  final double? fontSize;
  const AuthGradientTitle({super.key, required this.text, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? context.sp(28, min: 22, max: 36);
    return ShaderMask(
      shaderCallback: (b) => AppGradients.brand.createShader(b),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: AppTextStyles.headline(color: Colors.white).copyWith(
          fontSize: size,
        ),
      ),
    );
  }
}

// ─── Error box ────────────────────────────────────────────────────────────────

/// Styled error state for auth screens.
class AuthErrorBox extends StatelessWidget {
  final String message;
  const AuthErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(color: AppColors.danger).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success box ──────────────────────────────────────────────────────────────

/// Styled success/info state for auth screens.
class AuthSuccessBox extends StatelessWidget {
  final String message;
  const AuthSuccessBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(color: AppColors.accentGreen).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section divider ─────────────────────────────────────────────────────────

/// Horizontal divider with center label.
class AuthDividerLabel extends StatelessWidget {
  final String label;
  const AuthDividerLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outline, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outline, thickness: 1)),
      ],
    );
  }
}

// ─── Demo login section ───────────────────────────────────────────────────────

/// Quick role-based demo login chips.
class DemoLoginSection extends StatelessWidget {
  final bool loading;
  final void Function(String email, String password) onLogin;

  const DemoLoginSection({
    super.key,
    required this.loading,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.primaryPurple, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Demo Access',
                style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DemoChip(
                label: 'Fan View',
                icon: Icons.sports_soccer_rounded,
                color: AppColors.accentCyan,
                loading: loading,
                onTap: () => onLogin('fan@goalsight.ai', '123456'),
              ),
              _DemoChip(
                label: 'Admin (Ahmed Sameh)',
                icon: Icons.shield_outlined,
                color: AppColors.accentGreen,
                loading: loading,
                onTap: () => onLogin('ahmed.sameh@alahly.com', 'Ahmed123'),
              ),
              _DemoChip(
                label: 'Manager (Mohamed Wael)',
                icon: Icons.analytics_outlined,
                color: AppColors.primaryPurple,
                loading: loading,
                onTap: () => onLogin('mohamed.wael@alahly.com', 'Ahmed123'),
              ),
              _DemoChip(
                label: 'Manager (Karim Hassan)',
                icon: Icons.analytics_outlined,
                color: AppColors.primaryPurple,
                loading: loading,
                onTap: () => onLogin('karim.hassan@alahly.com', 'Ahmed123'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _DemoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption(color: color).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Password visibility toggle ───────────────────────────────────────────────

/// Eye icon for toggling password visibility.
class PasswordToggleIcon extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;

  const PasswordToggleIcon({
    super.key,
    required this.obscure,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
    );
  }
}
