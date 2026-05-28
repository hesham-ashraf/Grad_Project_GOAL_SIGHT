import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

enum InsightSeverity { info, moderate, critical }

extension InsightSeverityX on InsightSeverity {
  Color get color {
    switch (this) {
      case InsightSeverity.info:
        return AppColors.accentCyan;
      case InsightSeverity.moderate:
        return AppColors.warning;
      case InsightSeverity.critical:
        return AppColors.danger;
    }
  }

  String get label {
    switch (this) {
      case InsightSeverity.info:
        return 'INFO';
      case InsightSeverity.moderate:
        return 'MODERATE';
      case InsightSeverity.critical:
        return 'CRITICAL';
    }
  }

  IconData get icon {
    switch (this) {
      case InsightSeverity.info:
        return Icons.info_outline_rounded;
      case InsightSeverity.moderate:
        return Icons.warning_amber_rounded;
      case InsightSeverity.critical:
        return Icons.error_outline_rounded;
    }
  }
}

class TacticalInsightData {
  const TacticalInsightData({
    required this.category,
    required this.insight,
    required this.severity,
    this.icon,
  });

  final String category;
  final String insight;
  final InsightSeverity severity;
  final IconData? icon;
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

const List<TacticalInsightData> kTacticalInsights = [
  TacticalInsightData(
    category: 'Attacking Pattern',
    insight: 'Team relies heavily on central attacks — 72% of moves route through the #10 channel.',
    severity: InsightSeverity.info,
    icon: Icons.sports_soccer_rounded,
  ),
  TacticalInsightData(
    category: 'Pressing Intensity',
    insight: 'Pressing intensity decreased significantly after the 70th minute, creating defensive vulnerabilities.',
    severity: InsightSeverity.moderate,
    icon: Icons.local_fire_department_rounded,
  ),
  TacticalInsightData(
    category: 'Wide Opportunities',
    insight: 'Wide attacking channels on the left flank remain under-exploited — only 3 crosses attempted.',
    severity: InsightSeverity.info,
    icon: Icons.open_in_full_rounded,
  ),
  TacticalInsightData(
    category: 'Defensive Risk',
    insight: 'High defensive line exposed 4 times to counter-attacks in the final 15 minutes.',
    severity: InsightSeverity.critical,
    icon: Icons.shield_outlined,
  ),
];

// ─── Section ─────────────────────────────────────────────────────────────────

class TacticalInsightsSection extends StatefulWidget {
  const TacticalInsightsSection({
    super.key,
    this.insights = kTacticalInsights,
  });

  final List<TacticalInsightData> insights;

  @override
  State<TacticalInsightsSection> createState() =>
      _TacticalInsightsSectionState();
}

class _TacticalInsightsSectionState extends State<TacticalInsightsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _itemFades;
  late final List<Animation<Offset>> _itemSlides;

  @override
  void initState() {
    super.initState();
    final count = widget.insights.length;
    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + count * 110),
    )..forward();

    _itemFades = List.generate(count, (i) {
      final start = i * 0.14;
      final end = (start + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _itemSlides = List.generate(count, (i) {
      return Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(_itemFades[i]);
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.rs(40, min: 36, max: 44),
              height: context.rs(40, min: 36, max: 44),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryPurple, AppColors.accentCyan],
                ),
                borderRadius: AppRadius.chip,
                boxShadow: AppShadows.cardGlow,
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: context.rs(20, min: 18, max: 22),
                color: Colors.white,
              ),
            ),
            SizedBox(width: context.rs(12, min: 10, max: 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tactical Insights',
                    style: AppTextStyles.title(
                      color: AppColors.textPrimary,
                    ).copyWith(
                      fontSize: context.rs(18, min: 16, max: 22),
                    ),
                  ),
                  SizedBox(height: context.rs(3, min: 2, max: 4)),
                  Text(
                    'AI-generated patterns from match data.',
                    style: AppTextStyles.caption(
                      color: AppColors.textMuted,
                    ).copyWith(
                      fontSize: context.rs(11, min: 10, max: 12),
                    ),
                  ),
                ],
              ),
            ),
            // AI badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(8, min: 7, max: 10),
                vertical: context.rs(4, min: 3, max: 5),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.accentCyan],
                ),
                borderRadius: AppRadius.chip,
              ),
              child: Text(
                'AI',
                style: AppTextStyles.caption(color: Colors.white).copyWith(
                  fontSize: context.rs(9, min: 8, max: 10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: context.rs(12, min: 10, max: 14)),

        // Cards
        ...List.generate(widget.insights.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.insights.length - 1
                  ? context.rs(10, min: 8, max: 12)
                  : 0,
            ),
            child: FadeTransition(
              opacity: _itemFades[index],
              child: SlideTransition(
                position: _itemSlides[index],
                child: _InsightCard(data: widget.insights[index]),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.data});

  final TacticalInsightData data;

  @override
  Widget build(BuildContext context) {
    final color = data.severity.color;
    final icon = data.icon ?? data.severity.icon;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.9),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: context.rs(38, min: 34, max: 42),
              height: context.rs(38, min: 34, max: 42),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.chip,
                border: Border.all(color: color.withValues(alpha: 0.24)),
              ),
              child: Icon(
                icon,
                size: context.rs(18, min: 16, max: 20),
                color: color,
              ),
            ),
            SizedBox(width: context.rs(12, min: 10, max: 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondary,
                          ).copyWith(
                            fontSize: context.rs(10, min: 9, max: 11),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: context.rs(8, min: 6, max: 10)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(7, min: 6, max: 9),
                          vertical: context.rs(3, min: 2, max: 4),
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: AppRadius.chip,
                          border:
                              Border.all(color: color.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          data.severity.label,
                          style: AppTextStyles.caption(color: color).copyWith(
                            fontSize: context.rs(8, min: 7, max: 9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    data.insight,
                    style: AppTextStyles.body(
                      color: AppColors.textPrimary,
                    ).copyWith(
                      fontSize: context.rs(13, min: 12, max: 14),
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
