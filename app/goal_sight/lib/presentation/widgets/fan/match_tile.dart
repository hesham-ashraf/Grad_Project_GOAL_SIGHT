import 'package:flutter/material.dart';

import '../../../data/models/match_model.dart';
import '../../../core/utils/responsive.dart';
import 'tap_scale.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    this.onTap,
  });

  final MatchModel match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = match.status.toLowerCase();
    final badgeColor = status == 'live'
        ? const Color(0xFF24D17E)
        : status == 'finished'
            ? const Color(0xFF7D87A7)
            : const Color(0xFF4DA1FF);

    return TapScale(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.rs(10, min: 6, max: 14)),
        padding: context.padSym(h: 14, v: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF15182B),
          borderRadius: BorderRadius.circular(context.rs(16, min: 12, max: 22)),
          border: Border.all(color: const Color(0xFF272E4F)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;

            final scoreCluster = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    match.score,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.sp(17, min: 14, max: 22),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                SizedBox(width: context.rs(10, min: 6, max: 14)),
                Container(
                  padding: context.padSym(h: 8, v: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(context.rs(24, min: 16, max: 28)),
                    border: Border.all(color: badgeColor.withOpacity(0.45)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: context.sp(10, min: 9, max: 13),
                    ),
                  ),
                ),
              ],
            );

            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.homeTeam} vs ${match.awayTeam}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(14, min: 12, max: 18),
                  ),
                ),
                SizedBox(height: context.rs(4, min: 2, max: 8)),
                Text(
                  status == 'live' ? 'Live now' : 'Latest result',
                  style: TextStyle(
                    color: const Color(0xFF95A0C1),
                    fontSize: context.sp(12, min: 10, max: 15),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  details,
                  SizedBox(height: context.rs(8, min: 6, max: 10)),
                  scoreCluster,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: details),
                SizedBox(width: context.rs(8, min: 6, max: 12)),
                scoreCluster,
              ],
            );
          },
        ),
      ),
    );
  }
}
