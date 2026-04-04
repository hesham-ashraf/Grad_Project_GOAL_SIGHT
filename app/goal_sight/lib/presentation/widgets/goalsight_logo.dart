import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class GoalSightLogo extends StatelessWidget {
  const GoalSightLogo({
    super.key,
    this.showSubtitle = true,
    this.iconSize = 72,
  });

  final bool showSubtitle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(iconSize * 0.26),
            gradient: AppTheme.brandGradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D705AF5),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.sports_soccer_rounded,
            color: Colors.white,
            size: iconSize * 0.46,
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.brandGradient.createShader(bounds),
          child: const Text(
            'GOALSIGHT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 38,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          const Text(
            'Football Analytics Platform',
            style: TextStyle(
              color: Color(0xFF617091),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
