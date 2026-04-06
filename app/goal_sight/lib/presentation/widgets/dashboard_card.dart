import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3A60)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4B6B57F5),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 150;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(compact ? 8 : 10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: compact ? 16 : 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFA7B5D4),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 22 : 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
