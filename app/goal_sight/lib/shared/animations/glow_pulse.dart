import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/theme/app_theme.dart';

class GoalSightGlowPulse extends StatefulWidget {
  const GoalSightGlowPulse({
    super.key,
    required this.child,
    this.color = AppColors.accentCyan,
    this.enabled = true,
    this.minOpacity = 0.08,
    this.maxOpacity = 0.22,
    this.blurRadius = 24,
    this.borderRadius = AppRadius.cardLarge,
  });

  final Widget child;
  final Color color;
  final bool enabled;
  final double minOpacity;
  final double maxOpacity;
  final double blurRadius;
  final BorderRadius borderRadius;

  @override
  State<GoalSightGlowPulse> createState() => _GoalSightGlowPulseState();
}

class _GoalSightGlowPulseState extends State<GoalSightGlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GoalSightMotion.pulse,
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GoalSightGlowPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = widget.enabled
            ? widget.minOpacity +
                ((widget.maxOpacity - widget.minOpacity) * _controller.value)
            : widget.minOpacity;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity),
                blurRadius: widget.blurRadius,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
