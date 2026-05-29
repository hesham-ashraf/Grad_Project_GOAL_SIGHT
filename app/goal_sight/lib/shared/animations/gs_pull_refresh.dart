// ---------------------------------------------------------------------------
// GoalSight — GsPullRefresh
//
// Glassmorphism pull-to-refresh wrapper with haptic feedback.
// Wraps any scrollable child with a custom GoalSight-branded indicator.
//
// Usage:
//   GsPullRefresh(
//     onRefresh: () async { ... },
//     child: ListView(...),
//   )
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';

class GsPullRefresh extends StatelessWidget {
  const GsPullRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color = AppColors.accentCyan,
    this.backgroundColor = AppColors.surface,
    this.displacement = 60.0,
    this.strokeWidth = 2.5,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color color;
  final Color backgroundColor;
  final double displacement;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await HapticService.refresh();
        await onRefresh();
      },
      color: color,
      backgroundColor: backgroundColor,
      displacement: displacement,
      strokeWidth: strokeWidth,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// GsRefreshableBody — Full-page FutureProvider pattern helper
//
// Wraps AsyncValue pattern to show:
//   - Loading state: skeleton shimmer
//   - Error state: styled retry card
//   - Data state: provided builder with pull-to-refresh
// ---------------------------------------------------------------------------

class GsRefreshableBody<T> extends StatelessWidget {
  const GsRefreshableBody({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.builder,
    this.loadingWidget,
    this.errorColor = AppColors.danger,
  });

  /// The AsyncValue from a FutureProvider
  final AsyncSnapshot<T> value;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    if (value.connectionState == ConnectionState.waiting) {
      return loadingWidget ?? const _GsSkeletonLoader();
    }

    if (value.hasError) {
      return _GsErrorRetry(
        error: value.error.toString(),
        onRetry: onRefresh,
        color: errorColor,
      );
    }

    final data = value.data;
    if (data == null) return const _GsSkeletonLoader();

    return GsPullRefresh(
      onRefresh: onRefresh,
      child: builder(data),
    );
  }
}

// ── Internal skeleton ─────────────────────────────────────────────────────

class _GsSkeletonLoader extends StatefulWidget {
  const _GsSkeletonLoader();

  @override
  State<_GsSkeletonLoader> createState() => _GsSkeletonLoaderState();
}

class _GsSkeletonLoaderState extends State<_GsSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: GoalSightMotion.shimmer,
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final base = AppColors.surface;
        final highlight = AppColors.surfaceElevated;
        final shimmerColor = Color.lerp(base, highlight, _shimmer.value)!;

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: AppRadius.card,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Internal error widget ─────────────────────────────────────────────────

class _GsErrorRetry extends StatelessWidget {
  const _GsErrorRetry({
    required this.error,
    required this.onRetry,
    required this.color,
  });

  final String error;
  final VoidCallback onRetry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: AppTextStyles.title(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to retry or tap the button below.',
              style: AppTextStyles.caption(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                await HapticService.medium();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.button,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Retry',
                  style: AppTextStyles.button(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
