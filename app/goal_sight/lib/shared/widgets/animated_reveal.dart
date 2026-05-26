import 'package:flutter/material.dart';

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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayedValue = delay == Duration.zero
            ? value
            : ((value * (duration + delay).inMilliseconds - delay.inMilliseconds) /
                    duration.inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble();

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - delayedValue),
              offset.dy * (1 - delayedValue),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
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
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          GoalSightAnimatedReveal(
            delay: Duration(milliseconds: delayStep.inMilliseconds * i),
            child: children[i],
          ),
          if (i != children.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}
