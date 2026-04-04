import 'package:flutter/material.dart';

import '../../../features/user/team_member_model.dart';

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({
    super.key,
    required this.player,
    this.onTap,
  });

  final TeamMemberModel player;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 176,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF13243F),
          borderRadius: BorderRadius.circular(16),
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
                  radius: 17,
                  backgroundColor: const Color(0xFF2A3D65),
                  child: Text(
                    '#${player.shirtNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${player.position} • ${player.age} yrs',
              style: const TextStyle(
                color: Color(0xFF9DB0D8),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _MiniStat(label: 'Rt', value: player.rating.toStringAsFixed(1)),
                const SizedBox(width: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E50),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8EA3CD), fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
