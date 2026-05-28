import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  // ── Screen metrics ─────────────────────────────────────────────────────────

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ── Breakpoints ────────────────────────────────────────────────────────────

  bool get isCompact => screenWidth < 360;
  bool get isPhone => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  bool get isLandscape => screenWidth > screenHeight;
  bool get isPortrait => !isLandscape;

  /// True on a tablet or desktop running in landscape — ideal for two-column.
  bool get isWideLayout => screenWidth >= 720;

  // ── Scale helpers ──────────────────────────────────────────────────────────

  double get _scaleFactor => (screenWidth / 390).clamp(0.86, 1.28);

  /// Responsive size: scales [value] relative to a 390pt baseline.
  double rs(num value, {double min = 0, double? max}) {
    final scaled = value.toDouble() * _scaleFactor;
    if (max != null) return scaled.clamp(min, max).toDouble();
    return scaled < min ? min : scaled;
  }

  /// Responsive font size — clamps to sensible readability range.
  double sp(num value, {double min = 10, double max = 64}) {
    return rs(value, min: min, max: max);
  }

  // ── Padding helpers ────────────────────────────────────────────────────────

  EdgeInsets padAll(num value) => EdgeInsets.all(rs(value));

  EdgeInsets padSym({num h = 0, num v = 0}) =>
      EdgeInsets.symmetric(horizontal: rs(h), vertical: rs(v));

  /// Horizontal page padding that grows on wider screens.
  EdgeInsets get pagePad => EdgeInsets.symmetric(
        horizontal: rs(isPhone ? 18 : isTablet ? 28 : 36),
      );

  // ── Column helpers ─────────────────────────────────────────────────────────

  int columns({
    int compact = 1,
    int phone = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (screenWidth >= 1200) return desktop;
    if (screenWidth >= 900) return tablet;
    if (screenWidth >= 560) return phone;
    return compact;
  }

  /// Two-column threshold: returns true when we can safely place two side-by-side panels.
  bool get hasTwoColumns => screenWidth >= 720;

  // ── Layout builders ────────────────────────────────────────────────────────

  /// Chooses between a single-column [narrow] layout and a side-by-side
  /// [wide] layout at the [breakpoint] width (default 720).
  Widget adaptiveLayout({
    required Widget narrow,
    required Widget wide,
    double breakpoint = 720,
  }) {
    return screenWidth >= breakpoint ? wide : narrow;
  }

  // ── Tablet card metrics ────────────────────────────────────────────────────

  /// Card width for a horizontal scroll row — larger on tablets.
  double get trendingCardWidth => rs(isPhone ? 220 : isTablet ? 260 : 300,
      min: 200, max: 340);

  /// Content max-width guard so text lines never stretch too wide on desktop.
  double get contentMaxWidth => isDesktop ? 1180 : double.infinity;

  // ── Landscape helpers ──────────────────────────────────────────────────────

  /// Recommended horizontal padding for the current orientation.
  double get hPad => rs(isLandscape ? 28 : 18, min: 14, max: 40);

  /// Recommended vertical spacing between sections.
  double get sectionGap => rs(isTablet ? 22 : 18, min: 14, max: 28);

  /// Recommended card internal padding.
  double get cardPad => rs(isTablet ? 18 : 14, min: 12, max: 22);
}

// ─── ResponsiveCentered ──────────────────────────────────────────────────────

/// Centers and constrains [child] to [maxWidth], applying sensible horizontal
/// padding that adapts to the current device class.
class ResponsiveCentered extends StatelessWidget {
  const ResponsiveCentered({
    super.key,
    required this.child,
    this.maxWidth = 1320,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? context.padSym(h: context.isPhone ? 14 : 20),
          child: child,
        ),
      ),
    );
  }
}

// ─── AdaptiveRow ─────────────────────────────────────────────────────────────

/// Renders [children] in a [Row] when [minWidth] is met, otherwise stacks
/// them in a [Column]. Eliminates duplicated LayoutBuilder boilerplate.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({
    super.key,
    required this.children,
    this.minWidth = 720,
    this.spacing = 16,
    this.runSpacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final double minWidth;
  final double spacing;
  final double runSpacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            children: _spaced(children, SizedBox(width: spacing)),
          );
        }
        return Column(
          crossAxisAlignment: crossAxisAlignment,
          children: _spaced(children, SizedBox(height: runSpacing)),
        );
      },
    );
  }

  static List<Widget> _spaced(List<Widget> items, Widget spacer) {
    if (items.length <= 1) return items;
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(spacer);
    }
    return result;
  }
}

// ─── ResponsiveGrid ──────────────────────────────────────────────────────────

/// A simple responsive grid using [Wrap] with adaptive column counts.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.compactColumns = 1,
    this.phoneColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int compactColumns;
  final int phoneColumns;
  final int tabletColumns;
  final int desktopColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = context.columns(
          compact: compactColumns,
          phone: phoneColumns,
          tablet: tabletColumns,
          desktop: desktopColumns,
        );
        final itemWidth =
            (constraints.maxWidth - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
