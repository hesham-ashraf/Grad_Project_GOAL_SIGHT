import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  bool get isCompact => screenWidth < 360;

  bool get isPhone => screenWidth < 600;

  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  bool get isDesktop => screenWidth >= 1024;

  double get _scaleFactor => (screenWidth / 390).clamp(0.86, 1.28);

  double rs(num value, {double min = 0, double? max}) {
    final scaled = value.toDouble() * _scaleFactor;
    if (max != null) {
      return scaled.clamp(min, max).toDouble();
    }
    return scaled < min ? min : scaled;
  }

  double sp(num value, {double min = 10, double max = 64}) {
    return rs(value, min: min, max: max);
  }

  EdgeInsets padAll(num value) => EdgeInsets.all(rs(value));

  EdgeInsets padSym({num h = 0, num v = 0}) {
    return EdgeInsets.symmetric(horizontal: rs(h), vertical: rs(v));
  }

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
}

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
