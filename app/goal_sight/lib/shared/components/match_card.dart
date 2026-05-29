import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'glass_container.dart';
import 'risk_badge.dart';
import 'stat_widgets.dart';

enum GoalSightMatchStatus { live, completed, upcoming, analyzed }
enum GoalSightMatchCardVariant { compact, standard, featured }

class GoalSightMatchCardData {
  const GoalSightMatchCardData({
    required this.homeTeam,
    required this.awayTeam,
    required this.statusLabel,
    this.homeScore,
    this.awayScore,
    this.competition,
    this.tacticalSummary,
    this.homeLogo,
    this.awayLogo,
    this.homePossession,
    this.awayPossession,
    this.aiIntensity = 0,
    this.status = GoalSightMatchStatus.upcoming,
  });

  final String homeTeam;
  final String awayTeam;
  final String statusLabel;
  final int? homeScore;
  final int? awayScore;
  final String? competition;
  final String? tacticalSummary;
  final Widget? homeLogo;
  final Widget? awayLogo;
  final int? homePossession;
  final int? awayPossession;
  final int aiIntensity;
  final GoalSightMatchStatus status;
}

class GoalSightMatchCard extends StatelessWidget {
  const GoalSightMatchCard({
    super.key,
    required this.match,
    this.variant = GoalSightMatchCardVariant.standard,
    this.onTap,
  });

  final GoalSightMatchCardData match;
  final GoalSightMatchCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(match.status);
    final featured = variant == GoalSightMatchCardVariant.featured;
    final compact = variant == GoalSightMatchCardVariant.compact;

    return GoalSightGlass(
      onTap: onTap,
      opacity: 0.82,
      shadow: featured ? GoalSightGlassShadow.glow : GoalSightGlassShadow.soft,
      borderColor: statusColor.withValues(alpha: 0.2),
      padding: EdgeInsets.all(context.rs(compact ? 13 : 17, min: 12, max: 22)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          statusColor.withValues(alpha: featured ? 0.15 : 0.08),
          AppColors.surfaceElevated.withValues(alpha: 0.88),
          AppColors.surface.withValues(alpha: 0.78),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (match.competition != null)
                Expanded(
                  child: Text(
                    match.competition!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Spacer(),
              GoalSightRiskBadge(
                label: match.statusLabel,
                severity: _statusSeverity(match.status),
                icon: _statusIcon(match.status),
                compact: true,
                pulse: match.status == GoalSightMatchStatus.live,
              ),
            ],
          ),
          SizedBox(height: context.rs(compact ? 12 : 16, min: 10, max: 20)),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              if (narrow) {
                return Column(
                  children: [
                    _TeamRow(team: match.homeTeam, logo: match.homeLogo, alignEnd: false),
                    SizedBox(height: context.rs(10, min: 8, max: 12)),
                    _ScoreBlock(match: match, color: statusColor, compact: compact),
                    SizedBox(height: context.rs(10, min: 8, max: 12)),
                    _TeamRow(team: match.awayTeam, logo: match.awayLogo, alignEnd: true),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _TeamColumn(team: match.homeTeam, logo: match.homeLogo, color: AppColors.accentCyan),
                  ),
                  _ScoreBlock(match: match, color: statusColor, compact: compact),
                  Expanded(
                    child: _TeamColumn(
                      team: match.awayTeam,
                      logo: match.awayLogo,
                      color: AppColors.primaryPurple,
                      alignEnd: true,
                    ),
                  ),
                ],
              );
            },
          ),
          if (!compact && match.tacticalSummary != null) ...[
            SizedBox(height: context.rs(15, min: 11, max: 18)),
            Container(
              padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: AppRadius.card,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.accentCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.tacticalSummary!,
                      maxLines: featured ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!compact && match.homePossession != null && match.awayPossession != null) ...[
            SizedBox(height: context.rs(14, min: 10, max: 16)),
            GoalSightComparisonStat(
              label: 'Possession Preview',
              leftLabel: match.homeTeam,
              rightLabel: match.awayTeam,
              leftValue: match.homePossession!,
              rightValue: match.awayPossession!,
            ),
          ],
          if (!compact) ...[
            SizedBox(height: context.rs(12, min: 8, max: 14)),
            _IntensityBar(value: match.aiIntensity, color: statusColor),
          ],
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.team,
    required this.color,
    this.logo,
    this.alignEnd = false,
  });

  final String team;
  final Widget? logo;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _TeamLogo(team: team, logo: logo, color: color),
        SizedBox(height: context.rs(8, min: 6, max: 10)),
        Text(
          team,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
            fontSize: context.sp(15, min: 13, max: 18),
          ),
        ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.team, this.logo, required this.alignEnd});

  final String team;
  final Widget? logo;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final children = [
      _TeamLogo(team: team, logo: logo, color: alignEnd ? AppColors.primaryPurple : AppColors.accentCyan),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          team,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    return Row(children: alignEnd ? children.reversed.toList() : children);
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.team, required this.color, this.logo});

  final String team;
  final Color color;
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(42, min: 34, max: 50),
      height: context.rs(42, min: 34, max: 50),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: logo ??
            Text(
              _initials(team),
              style: AppTextStyles.button(color: Colors.white).copyWith(fontSize: 13),
            ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.match, required this.color, required this.compact});

  final GoalSightMatchCardData match;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final score = match.homeScore == null || match.awayScore == null
        ? 'VS'
        : '${match.homeScore} - ${match.awayScore}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(12, min: 8, max: 18)),
      child: Column(
        children: [
          Text(
            score,
            style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
              fontSize: context.sp(compact ? 24 : 34, min: 22, max: 42),
              letterSpacing: -0.6,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 3),
            Text(
              'AI ${match.aiIntensity}%',
              style: AppTextStyles.caption(color: color).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('AI match intensity', style: AppTextStyles.caption(color: AppColors.textMuted)),
            const Spacer(),
            Text('$clamped%', style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: AppRadius.chip,
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 7,
            color: color,
            backgroundColor: AppColors.outlineSubtle,
          ),
        ),
      ],
    );
  }
}

Color _statusColor(GoalSightMatchStatus status) {
  switch (status) {
    case GoalSightMatchStatus.live:
      return AppColors.accentGreen;
    case GoalSightMatchStatus.completed:
      return AppColors.textMuted;
    case GoalSightMatchStatus.upcoming:
      return AppColors.accentCyan;
    case GoalSightMatchStatus.analyzed:
      return AppColors.primaryPurple;
  }
}

GoalSightSeverity _statusSeverity(GoalSightMatchStatus status) {
  switch (status) {
    case GoalSightMatchStatus.live:
      return GoalSightSeverity.positive;
    case GoalSightMatchStatus.completed:
      return GoalSightSeverity.neutral;
    case GoalSightMatchStatus.upcoming:
      return GoalSightSeverity.neutral;
    case GoalSightMatchStatus.analyzed:
      return GoalSightSeverity.positive;
  }
}

IconData _statusIcon(GoalSightMatchStatus status) {
  switch (status) {
    case GoalSightMatchStatus.live:
      return Icons.radio_button_checked_rounded;
    case GoalSightMatchStatus.completed:
      return Icons.flag_rounded;
    case GoalSightMatchStatus.upcoming:
      return Icons.schedule_rounded;
    case GoalSightMatchStatus.analyzed:
      return Icons.analytics_rounded;
  }
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return 'GS';
  if (words.length == 1) {
    final end = words.first.length < 2 ? words.first.length : 2;
    return words.first.substring(0, end).toUpperCase();
  }
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
