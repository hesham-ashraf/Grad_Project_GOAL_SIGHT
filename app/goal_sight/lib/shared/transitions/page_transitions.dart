import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/motion_tokens.dart';

enum GoalSightPageTransition {
  fade,
  sharedAxis,
  slideUp,
  slideLeft,
  modal,
}

CustomTransitionPage<T> goalSightTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
  GoalSightPageTransition transition = GoalSightPageTransition.sharedAxis,
  Duration duration = GoalSightMotion.normal,
  bool fullscreenDialog = false,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: GoalSightMotion.fast,
    fullscreenDialog: fullscreenDialog,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transition) {
        case GoalSightPageTransition.fade:
          return FadeTransition(opacity: animation, child: child);
        case GoalSightPageTransition.slideUp:
        case GoalSightPageTransition.modal:
          return _fadeSlide(
            animation,
            child,
            begin: const Offset(0, 0.08),
            curve: GoalSightMotion.entrance,
          );
        case GoalSightPageTransition.slideLeft:
          return _fadeSlide(
            animation,
            child,
            begin: const Offset(0.05, 0),
            curve: GoalSightMotion.entrance,
          );
        case GoalSightPageTransition.sharedAxis:
          return _sharedAxis(animation, secondaryAnimation, child);
      }
    },
  );
}

Widget _fadeSlide(
  Animation<double> animation,
  Widget child, {
  required Offset begin,
  required Curve curve,
}) {
  final curved = CurvedAnimation(parent: animation, curve: curve);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
      child: child,
    ),
  );
}

Widget _sharedAxis(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final primary = CurvedAnimation(
    parent: animation,
    curve: GoalSightMotion.entrance,
    reverseCurve: GoalSightMotion.exit,
  );
  final secondary = CurvedAnimation(
    parent: secondaryAnimation,
    curve: GoalSightMotion.standard,
    reverseCurve: GoalSightMotion.exit,
  );

  return FadeTransition(
    opacity: Tween<double>(begin: 0, end: 1).animate(primary),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.035, 0),
        end: Offset.zero,
      ).animate(primary),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.88).animate(secondary),
        child: child,
      ),
    ),
  );
}
