import 'dart:ui';

import 'package:flutter/material.dart';

import 'tap_scale.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF15182B).withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A3156)),
            boxShadow: [
              const BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
              if (glow)
                const BoxShadow(
                  color: Color(0x4D7B61FF),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return TapScale(onTap: onTap, child: card);
  }
}
