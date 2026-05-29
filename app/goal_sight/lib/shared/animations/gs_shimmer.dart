import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// GsShimmer — premium shimmer loading animation.
///
/// Wraps any widget tree with a sweeping highlight animation that communicates
/// loading state. Works on top of placeholder shapes (boxes, lines, circles).
///
/// Usage:
/// ```dart
/// GsShimmer(child: Container(height: 16, width: 120, color: AppColors.surfaceRaised))
/// GsShimmer.bar(width: 100, height: 14)
/// GsShimmer.line(height: 14)
/// GsShimmer.circle(size: 44)
/// ```
class GsShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;

  const GsShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  /// A fixed-width shimmer bar.
  static Widget bar({
    required double width,
    double height = 13,
    double radius = 8,
    Key? key,
  }) {
    return GsShimmer(
      key: key,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// A full-width shimmer line (expands to parent width).
  static Widget line({double height = 13, double radius = 8, Key? key}) {
    return GsShimmer(
      key: key,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// A circular shimmer placeholder.
  static Widget circle({required double size, Key? key}) {
    return GsShimmer(
      key: key,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// A shimmer card placeholder (rounded rect).
  static Widget card({
    double? width,
    required double height,
    double radius = 20,
    Key? key,
  }) {
    return GsShimmer(
      key: key,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  @override
  State<GsShimmer> createState() => _GsShimmerState();
}

class _GsShimmerState extends State<GsShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _anim = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final base = widget.baseColor ?? AppColors.surfaceElevated;
    final highlight =
        widget.highlightColor ?? AppColors.surfaceRaised.withValues(alpha: 0.9);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _anim.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ─── Convenience skeleton layouts ────────────────────────────────────────────

/// Skeleton for a list item (avatar + 2 text lines).
class GsShimmerListItem extends StatelessWidget {
  final double avatarSize;
  const GsShimmerListItem({super.key, this.avatarSize = 44});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          GsShimmer.circle(size: avatarSize),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GsShimmer.bar(width: 160, height: 13),
                const SizedBox(height: 8),
                GsShimmer.bar(width: 100, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a stat card (title + big number + label row).
class GsShimmerStatCard extends StatelessWidget {
  const GsShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GsShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 60,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page shimmer skeleton with a hero + list items.
class GsShimmerPage extends StatelessWidget {
  final int itemCount;
  const GsShimmerPage({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GsShimmer.card(height: 160),
          const SizedBox(height: 20),
          GsShimmer.bar(width: 120, height: 14),
          const SizedBox(height: 14),
          ...List.generate(itemCount, (i) => const GsShimmerListItem()),
        ],
      ),
    );
  }
}
