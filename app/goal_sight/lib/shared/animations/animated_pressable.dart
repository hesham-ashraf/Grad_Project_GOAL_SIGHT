import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/theme/app_theme.dart';

class GoalSightAnimatedPressable extends StatefulWidget {
  const GoalSightAnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
    this.glowColor = AppColors.accentCyan,
    this.enableGlow = false,
    this.borderRadius = AppRadius.cardLarge,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Color glowColor;
  final bool enableGlow;
  final BorderRadius borderRadius;

  @override
  State<GoalSightAnimatedPressable> createState() =>
      _GoalSightAnimatedPressableState();
}

class _GoalSightAnimatedPressableState extends State<GoalSightAnimatedPressable> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _pressed || _hovered;

    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
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
          scale: _pressed ? widget.scale : 1,
          duration: GoalSightMotion.instant,
          curve: GoalSightMotion.standard,
          child: AnimatedContainer(
            duration: GoalSightMotion.fast,
            curve: GoalSightMotion.standard,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: widget.enableGlow && active
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: 0.18),
                        blurRadius: 24,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : const [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
