import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class GoalSightAdaptiveMetrics {
  const GoalSightAdaptiveMetrics({
    required this.width,
    required this.height,
    required this.orientation,
  });

  final double width;
  final double height;
  final Orientation orientation;

  bool get isPhone => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isCompactLandscape => isPhone && isLandscape;

  int columns({
    int phone = 1,
    int phoneLandscape = 2,
    int tablet = 2,
    int tabletLandscape = 3,
    int desktop = 4,
  }) {
    if (isDesktop) return desktop;
    if (isTablet && isLandscape) return tabletLandscape;
    if (isTablet) return tablet;
    if (isLandscape) return phoneLandscape;
    return phone;
  }

  double get pageMaxWidth {
    if (isDesktop) return 1320;
    if (isTablet) return 1060;
    return double.infinity;
  }

  EdgeInsets pagePadding(BuildContext context) {
    final horizontal = isDesktop
        ? 28
        : isTablet
            ? 24
            : isCompactLandscape
                ? 16
                : 20;
    final vertical = isCompactLandscape ? 12 : 20;
    return EdgeInsets.symmetric(
      horizontal: context.rs(horizontal, min: 12, max: 34),
      vertical: context.rs(vertical, min: 10, max: 26),
    );
  }
}

class GoalSightAdaptiveBuilder extends StatelessWidget {
  const GoalSightAdaptiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, GoalSightAdaptiveMetrics metrics)
      builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        return builder(
          context,
          GoalSightAdaptiveMetrics(
            width: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : media.size.width,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : media.size.height,
            orientation: media.orientation,
          ),
        );
      },
    );
  }
}

class GoalSightResponsiveScaffold extends StatelessWidget {
  const GoalSightResponsiveScaffold({
    super.key,
    required this.child,
    this.backgroundColor = Colors.transparent,
    this.safeArea = true,
    this.scrollable = true,
    this.maxWidth,
    this.padding,
    this.bottomPadding = 96,
  });

  final Widget child;
  final Color backgroundColor;
  final bool safeArea;
  final bool scrollable;
  final double? maxWidth;
  final EdgeInsets? padding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return GoalSightAdaptiveBuilder(
      builder: (context, metrics) {
        final content = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? metrics.pageMaxWidth,
            ),
            child: Padding(
              padding: padding ?? metrics.pagePadding(context),
              child: child,
            ),
          ),
        );

        final body = scrollable
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: context.rs(bottomPadding, min: 72, max: 124),
                ),
                child: content,
              )
            : content;

        return Scaffold(
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: true,
          body: safeArea ? SafeArea(bottom: false, child: body) : body,
        );
      },
    );
  }
}

class GoalSightAdaptiveGrid extends StatelessWidget {
  const GoalSightAdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 210,
    this.spacing = 12,
    this.runSpacing = 12,
    this.maxColumns = 4,
    this.childAspectRatio,
    this.animateLayout = true,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;
  final int maxColumns;
  final double? childAspectRatio;
  final bool animateLayout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            (width / minItemWidth).floor().clamp(1, maxColumns).toInt();
        final itemWidth = (width - (spacing * (columns - 1))) / columns;
        final tiles = Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: childAspectRatio == null
                    ? child
                    : AspectRatio(aspectRatio: childAspectRatio!, child: child),
              ),
          ],
        );

        if (!animateLayout) return tiles;

        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: tiles,
        );
      },
    );
  }
}

class GoalSightResponsiveSplit extends StatelessWidget {
  const GoalSightResponsiveSplit({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 820,
    this.spacing = AppSpacing.md,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
  });

  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final double spacing;
  final int primaryFlex;
  final int secondaryFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              primary,
              SizedBox(height: context.rs(spacing, min: 10, max: 22)),
              secondary,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: context.rs(spacing, min: 12, max: 26)),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

class GoalSightResponsiveChartBox extends StatelessWidget {
  const GoalSightResponsiveChartBox({
    super.key,
    required this.child,
    this.phoneHeight = 220,
    this.tabletHeight = 280,
    this.landscapeHeight = 240,
    this.desktopHeight = 320,
    this.minWidthForHorizontalScroll = 360,
  });

  final Widget child;
  final double phoneHeight;
  final double tabletHeight;
  final double landscapeHeight;
  final double desktopHeight;
  final double minWidthForHorizontalScroll;

  @override
  Widget build(BuildContext context) {
    return GoalSightAdaptiveBuilder(
      builder: (context, metrics) {
        final height = metrics.isDesktop
            ? desktopHeight
            : metrics.isLandscape
                ? landscapeHeight
                : metrics.isTablet
                    ? tabletHeight
                    : phoneHeight;

        return SizedBox(
          height: context.rs(height, min: 170, max: 380),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= minWidthForHorizontalScroll) {
                return child;
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: minWidthForHorizontalScroll,
                  child: child,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
