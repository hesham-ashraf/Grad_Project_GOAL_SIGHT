import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

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
    final responsiveIconSize =
        (iconSize * (context.isCompact ? 0.86 : context.isTablet ? 1.08 : 1))
            .clamp(52.0, 96.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: responsiveIconSize,
          height: responsiveIconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsiveIconSize * 0.26),
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
            size: responsiveIconSize * 0.46,
          ),
        ),
        SizedBox(height: context.rs(12, min: 8, max: 16)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.brandGradient.createShader(bounds),
            child: Text(
              'GOALSIGHT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: context.sp(38, min: 26, max: 46),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        if (showSubtitle) ...[
          SizedBox(height: context.rs(4, min: 2, max: 8)),
          Text(
            'Football Analytics Platform',
            style: TextStyle(
              color: Color(0xFF617091),
              fontWeight: FontWeight.w500,
              fontSize: context.sp(13, min: 11, max: 16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
