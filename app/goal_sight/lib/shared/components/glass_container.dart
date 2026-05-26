import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

enum GoalSightGlassShadow { none, soft, glow }

class GoalSightGlass extends StatelessWidget {
  const GoalSightGlass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.opacity = 0.78,
    this.blur = 18,
    this.borderColor,
    this.gradient,
    this.shadow = GoalSightGlassShadow.soft,
    this.onTap,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double opacity;
  final double blur;
  final Color? borderColor;
  final Gradient? gradient;
  final GoalSightGlassShadow shadow;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.cardLarge;
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: opacity),
              gradient: gradient,
              borderRadius: radius,
              border: Border.all(
                color: borderColor ??
                    Colors.white.withValues(alpha: context.isPhone ? 0.07 : 0.1),
              ),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.all(context.rs(16, min: 14, max: 22)),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return content;

    return _Pressable(
      onTap: onTap,
      child: content,
    );
  }

  List<BoxShadow> get _shadows {
    switch (shadow) {
      case GoalSightGlassShadow.none:
        return const [];
      case GoalSightGlassShadow.glow:
        return AppShadows.cardGlow;
      case GoalSightGlassShadow.soft:
        return AppShadows.card;
    }
  }
}

class GoalSightGradientBorder extends StatelessWidget {
  const GoalSightGradientBorder({
    super.key,
    required this.child,
    this.gradient = AppGradients.brand,
    this.radius = AppRadius.xl,
    this.width = 1.2,
    this.padding = const EdgeInsets.all(1.2),
  });

  final Widget child;
  final Gradient gradient;
  final double radius;
  final double width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: padding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - width),
          child: child,
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
