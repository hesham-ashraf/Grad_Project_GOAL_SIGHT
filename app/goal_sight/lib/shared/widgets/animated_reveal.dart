import 'package:flutter/material.dart';

import '../animations/reveal_animations.dart';

class GoalSightAnimatedReveal extends StatelessWidget {
  const GoalSightAnimatedReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 14),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return GoalSightReveal(
      delay: delay,
      duration: duration,
      direction: _direction,
      distance: offset.distance,
      child: child,
    );
  }

  GoalSightRevealDirection get _direction {
    if (offset.dx.abs() > offset.dy.abs()) {
      return offset.dx >= 0
          ? GoalSightRevealDirection.left
          : GoalSightRevealDirection.right;
    }
    if (offset.dy == 0) return GoalSightRevealDirection.none;
    return offset.dy >= 0
        ? GoalSightRevealDirection.up
        : GoalSightRevealDirection.down;
  }
}

class GoalSightStaggeredList extends StatelessWidget {
  const GoalSightStaggeredList({
    super.key,
    required this.children,
    this.gap = 12,
    this.delayStep = const Duration(milliseconds: 70),
  });

  final List<Widget> children;
  final double gap;
  final Duration delayStep;

  @override
  Widget build(BuildContext context) {
    return GoalSightStaggeredReveal(
      spacing: gap,
      delayStep: delayStep,
      children: children,
    );
  }
}
