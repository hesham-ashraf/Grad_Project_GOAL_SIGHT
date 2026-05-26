import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';

enum GoalSightRevealDirection { up, down, left, right, none }

class GoalSightReveal extends StatelessWidget {
  const GoalSightReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = GoalSightMotion.normal,
    this.direction = GoalSightRevealDirection.up,
    this.distance = 16,
    this.curve = GoalSightMotion.entrance,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final GoalSightRevealDirection direction;
  final double distance;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds + delay.inMilliseconds;
    final safeTotal = totalMs == 0 ? 1 : totalMs;
    final safeDuration = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: safeTotal),
      curve: Curves.linear,
      builder: (context, value, child) {
        final delayed = ((value * safeTotal - delay.inMilliseconds) / safeDuration)
            .clamp(0.0, 1.0)
            .toDouble();
        final eased = curve.transform(delayed);
        final offset = _offsetFor(direction, distance * (1 - eased));

        return Opacity(
          opacity: eased,
          child: Transform.translate(offset: offset, child: child),
        );
      },
      child: child,
    );
  }

  Offset _offsetFor(GoalSightRevealDirection direction, double value) {
    switch (direction) {
      case GoalSightRevealDirection.up:
        return Offset(0, value);
      case GoalSightRevealDirection.down:
        return Offset(0, -value);
      case GoalSightRevealDirection.left:
        return Offset(value, 0);
      case GoalSightRevealDirection.right:
        return Offset(-value, 0);
      case GoalSightRevealDirection.none:
        return Offset.zero;
    }
  }
}

class GoalSightStaggeredReveal extends StatelessWidget {
  const GoalSightStaggeredReveal({
    super.key,
    required this.children,
    this.axis = Axis.vertical,
    this.spacing = 12,
    this.delayStep = const Duration(milliseconds: 65),
    this.initialDelay = Duration.zero,
    this.direction = GoalSightRevealDirection.up,
    this.wrap = false,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final Axis axis;
  final double spacing;
  final Duration delayStep;
  final Duration initialDelay;
  final GoalSightRevealDirection direction;
  final bool wrap;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final revealed = [
      for (var i = 0; i < children.length; i++)
        GoalSightReveal(
          delay: initialDelay + Duration(milliseconds: delayStep.inMilliseconds * i),
          direction: direction,
          child: children[i],
        ),
    ];

    if (wrap) {
      return Wrap(spacing: spacing, runSpacing: runSpacing, children: revealed);
    }

    if (axis == Axis.horizontal) {
      return Row(
        children: [
          for (var i = 0; i < revealed.length; i++) ...[
            Expanded(child: revealed[i]),
            if (i != revealed.length - 1) SizedBox(width: spacing),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < revealed.length; i++) ...[
          revealed[i],
          if (i != revealed.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class GoalSightAnimatedSwitcher extends StatelessWidget {
  const GoalSightAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = GoalSightMotion.normal,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: GoalSightMotion.entrance,
      switchOutCurve: GoalSightMotion.exit,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}
