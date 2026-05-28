import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import 'tap_scale.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

enum RecommendationPriority { low, medium, high, urgent }

extension RecommendationPriorityX on RecommendationPriority {
  Color get color {
    switch (this) {
      case RecommendationPriority.low:
        return AppColors.accentGreen;
      case RecommendationPriority.medium:
        return AppColors.accentCyan;
      case RecommendationPriority.high:
        return AppColors.warning;
      case RecommendationPriority.urgent:
        return AppColors.danger;
    }
  }

  String get label {
    switch (this) {
      case RecommendationPriority.low:
        return 'LOW';
      case RecommendationPriority.medium:
        return 'MEDIUM';
      case RecommendationPriority.high:
        return 'HIGH';
      case RecommendationPriority.urgent:
        return 'URGENT';
    }
  }

  IconData get icon {
    switch (this) {
      case RecommendationPriority.low:
        return Icons.arrow_downward_rounded;
      case RecommendationPriority.medium:
        return Icons.remove_rounded;
      case RecommendationPriority.high:
        return Icons.arrow_upward_rounded;
      case RecommendationPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}

class AIRecommendationData {
  const AIRecommendationData({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    this.expandedDetail,
  });

  final String title;
  final String description;
  final RecommendationPriority priority;
  final IconData icon;
  final String? expandedDetail;
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

const List<AIRecommendationData> kAIRecommendations = [
  AIRecommendationData(
    title: 'Increase Attacking Width',
    description: 'Deploy wide midfielders higher to stretch the opposition defensive block.',
    priority: RecommendationPriority.high,
    icon: Icons.open_in_full_rounded,
    expandedDetail:
        'Analysis shows 68% of attacks are funnelled centrally. Pushing wingers wide opens diagonal passing lanes and creates 1v1 opportunities on the flanks.',
  ),
  AIRecommendationData(
    title: 'Monitor Player Fatigue',
    description: 'Hassan Ali\'s fatigue index is critical at 87 — rest recommended next fixture.',
    priority: RecommendationPriority.urgent,
    icon: Icons.monitor_heart_outlined,
    expandedDetail:
        'Over two consecutive high-intensity matches, Hassan Ali\'s sprint output has dropped 23%. Injury risk is elevated. A 20-minute rest in the next match is strongly advised.',
  ),
  AIRecommendationData(
    title: 'Improve Defensive Compactness',
    description: 'Reduce the gap between defensive and midfield lines to below 25 metres.',
    priority: RecommendationPriority.medium,
    icon: Icons.shield_outlined,
    expandedDetail:
        'In the 70th–90th minute window the team shape stretched to 32m, allowing counter-attacks through the centre. A more compact 4-4-2 mid-block should close this gap.',
  ),
  AIRecommendationData(
    title: 'Exploit Set Piece Routines',
    description: 'Opposition conceded 3 of last 5 goals from corners — high success rate.',
    priority: RecommendationPriority.low,
    icon: Icons.sports_soccer_rounded,
    expandedDetail:
        'Falcons United concede on average 0.6 goals per corner. Near-post flick-on routines have an 18% conversion rate against their current defensive setup.',
  ),
];

// ─── Section ─────────────────────────────────────────────────────────────────

class AIRecommendationsSection extends StatefulWidget {
  const AIRecommendationsSection({
    super.key,
    this.recommendations = kAIRecommendations,
  });

  final List<AIRecommendationData> recommendations;

  @override
  State<AIRecommendationsSection> createState() =>
      _AIRecommendationsSectionState();
}

class _AIRecommendationsSectionState extends State<AIRecommendationsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    final count = widget.recommendations.length;
    _stagger = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + count * 110),
    )..forward();

    _fades = List.generate(count, (i) {
      final start = i * 0.14;
      final end = (start + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _slides = List.generate(count, (i) {
      return Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(_fades[i]);
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
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
                  colors: [Color(0xFF705AF5), Color(0xFF2DE2E6)],
                ),
                borderRadius: AppRadius.chip,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_fix_high_rounded,
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
                    'AI Recommendations',
                    style: AppTextStyles.title(
                      color: AppColors.textPrimary,
                    ).copyWith(
                      fontSize: context.rs(18, min: 16, max: 22),
                    ),
                  ),
                  SizedBox(height: context.rs(3, min: 2, max: 4)),
                  Text(
                    'Intelligent action items from match analysis.',
                    style: AppTextStyles.caption(
                      color: AppColors.textMuted,
                    ).copyWith(
                      fontSize: context.rs(11, min: 10, max: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: context.rs(12, min: 10, max: 14)),

        // Cards
        ...List.generate(widget.recommendations.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.recommendations.length - 1
                  ? context.rs(10, min: 8, max: 12)
                  : 0,
            ),
            child: FadeTransition(
              opacity: _fades[index],
              child: SlideTransition(
                position: _slides[index],
                child: _RecommendationCard(
                  data: widget.recommendations[index],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({required this.data});

  final AIRecommendationData data;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.data.priority.color;
    final hasDetail = widget.data.expandedDetail != null;

    return TapScale(
      onTap: hasDetail ? _toggle : null,
      scaleDown: hasDetail ? 0.98 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: _expanded ? 0.12 : 0.07),
              AppColors.surfaceElevated.withValues(alpha: 0.94),
            ],
          ),
          borderRadius: AppRadius.cardLarge,
          border: Border.all(
            color: _expanded
                ? color.withValues(alpha: 0.35)
                : color.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: _expanded
                  ? color.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: context.rs(38, min: 34, max: 42),
                    height: context.rs(38, min: 34, max: 42),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: AppRadius.chip,
                      border: Border.all(color: color.withValues(alpha: 0.26)),
                    ),
                    child: Icon(
                      widget.data.icon,
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
                                widget.data.title,
                                style: AppTextStyles.title(
                                  color: AppColors.textPrimary,
                                ).copyWith(
                                  fontSize: context.rs(14, min: 13, max: 16),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.rs(4, min: 2, max: 6)),
                        // Priority badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rs(8, min: 6, max: 10),
                            vertical: context.rs(3, min: 2, max: 4),
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: AppRadius.chip,
                            border: Border.all(
                              color: color.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.data.priority.icon,
                                size: context.rs(10, min: 9, max: 11),
                                color: color,
                              ),
                              SizedBox(width: context.rs(4, min: 3, max: 5)),
                              Text(
                                '${widget.data.priority.label} PRIORITY',
                                style: AppTextStyles.caption(color: color)
                                    .copyWith(
                                  fontSize: context.rs(8, min: 7, max: 9),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasDetail) ...[
                    SizedBox(width: context.rs(8, min: 6, max: 10)),
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: context.rs(20, min: 18, max: 22),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: context.rs(10, min: 8, max: 12)),
              Text(
                widget.data.description,
                style: AppTextStyles.body(
                  color: AppColors.textSecondary,
                ).copyWith(
                  fontSize: context.rs(13, min: 12, max: 14),
                  height: 1.45,
                ),
              ),
              // Expandable detail
              if (hasDetail)
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.rs(12, min: 10, max: 14)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.06),
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: color.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: context.rs(14, min: 12, max: 16),
                              color: AppColors.accentCyan,
                            ),
                            SizedBox(width: context.rs(8, min: 6, max: 10)),
                            Expanded(
                              child: Text(
                                widget.data.expandedDetail!,
                                style: AppTextStyles.body(
                                  color: AppColors.textPrimary,
                                ).copyWith(
                                  fontSize: context.rs(12, min: 11, max: 13),
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
