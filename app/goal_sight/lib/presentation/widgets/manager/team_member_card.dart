import 'package:flutter/material.dart';

import '../../../features/user/team_member_model.dart';
import '../../../core/utils/responsive.dart';

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({
    super.key,
    required this.player,
    this.onTap,
    this.width,
  });

  final TeamMemberModel player;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 176,
        padding: context.padAll(12),
        decoration: BoxDecoration(
          color: const Color(0xFF13243F),
          borderRadius: BorderRadius.circular(context.rs(16, min: 12, max: 20)),
          border: Border.all(color: const Color(0xFF2C406D)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2D6F58F5),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: context.rs(17, min: 13, max: 20),
                  backgroundColor: const Color(0xFF2A3D65),
                  child: Text(
                    '#${player.shirtNumber}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.sp(11, min: 10, max: 14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  player.isStarting ? Icons.stars : Icons.person_outline,
                  color: player.isStarting
                      ? const Color(0xFF7EC7FF)
                      : const Color(0xFF8698C2),
                  size: context.rs(18, min: 14, max: 22),
                ),
              ],
            ),
            SizedBox(height: context.rs(10, min: 6, max: 14)),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.sp(14, min: 12, max: 18),
              ),
            ),
            SizedBox(height: context.rs(4, min: 2, max: 8)),
            Text(
              '${player.position} • ${player.age} yrs',
              style: TextStyle(
                color: Color(0xFF9DB0D8),
                fontSize: context.sp(12, min: 10, max: 15),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _MiniStat(label: 'Rt', value: player.rating.toStringAsFixed(1)),
                SizedBox(width: context.rs(10, min: 6, max: 14)),
                _MiniStat(label: 'Stm', value: '${player.stamina}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: context.padSym(h: 8, v: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E50),
          borderRadius: BorderRadius.circular(context.rs(10, min: 8, max: 12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF8EA3CD),
                fontSize: context.sp(10, min: 9, max: 12),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.sp(12, min: 10, max: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
