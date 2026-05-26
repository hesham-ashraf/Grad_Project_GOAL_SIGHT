import 'package:flutter/animation.dart';

class GoalSightMotion {
  const GoalSightMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 360);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration shimmer = Duration(milliseconds: 1450);
  static const Duration pulse = Duration(milliseconds: 1800);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve entrance = Cubic(0.16, 1, 0.3, 1);
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);
}
