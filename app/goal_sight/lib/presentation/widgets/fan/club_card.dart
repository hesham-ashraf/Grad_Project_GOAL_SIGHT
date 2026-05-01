import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/club_model.dart';
import 'tap_scale.dart';

class ClubCard extends StatelessWidget {
  const ClubCard({
    super.key,
    required this.club,
    this.onTap,
  });

  final ClubModel club;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final innerCard = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: club.isFavorite
              ? club.primaryColor.withValues(alpha: 0.4)
              : AppColors.outlineSubtle,
        ),
        boxShadow: club.isFavorite
            ? [
                BoxShadow(
                  color: club.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Subtle background glow based on primary color
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    club.primaryColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          if (club.isFavorite)
            Positioned(
              top: context.rs(12, min: 10, max: 14),
              right: context.rs(12, min: 10, max: 14),
              child: Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: context.rs(18, min: 16, max: 20),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(context.rs(16, min: 12, max: 20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder Logo
                Container(
                  width: context.rs(72, min: 60, max: 80),
                  height: context.rs(72, min: 60, max: 80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        club.primaryColor.withValues(alpha: 0.3),
                        club.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: club.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      club.name.substring(0, 2).toUpperCase(),
                      style: AppTextStyles.headline(color: Colors.white).copyWith(
                        fontSize: context.rs(24, min: 20, max: 28),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.rs(16, min: 12, max: 20)),
                
                Text(
                  club.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                    fontSize: context.rs(16, min: 14, max: 18),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.rs(4, min: 2, max: 6)),
                Text(
                  club.stadium,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return TapScale(
      onTap: onTap,
      scaleDown: 0.95,
      child: innerCard,
    );
  }
}
