import 'package:flutter/material.dart';

import '../../../data/models/match_model.dart';
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF15182B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF272E4F)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.homeTeam} vs ${match.awayTeam}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'live' ? 'Live now' : 'Latest result',
                    style: const TextStyle(
                      color: Color(0xFF95A0C1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              match.score,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: badgeColor.withOpacity(0.45)),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
