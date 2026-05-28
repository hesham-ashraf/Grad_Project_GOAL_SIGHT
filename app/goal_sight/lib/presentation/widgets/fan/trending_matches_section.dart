import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import 'match_status_badge.dart';
import 'tap_scale.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class TrendingMatchData {
  const TrendingMatchData({
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    required this.status,
    required this.competition,
    required this.tacticalSummary,
    required this.intensity,
    required this.homeColor,
    required this.awayColor,
    this.trendReason = 'Trending',
  });

  final String homeTeam;
  final String awayTeam;
  final String score;
  final String status;
  final String competition;
  final String tacticalSummary;
  final int intensity;
  final Color homeColor;
  final Color awayColor;
  final String trendReason;
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

const List<TrendingMatchData> kTrendingMatches = [
  TrendingMatchData(
    homeTeam: 'GoalSight FC',
    awayTeam: 'Falcons United',
    score: '3 - 1',
    status: 'FT',
    competition: 'Premier League · MD18',
    tacticalSummary: 'High-press dominance in second half.',
    intensity: 91,
    homeColor: AppColors.accentCyan,
    awayColor: AppColors.primaryPurple,
    trendReason: '🔥 Most Viewed',
  ),
  TrendingMatchData(
    homeTeam: 'Lions City',
    awayTeam: 'GoalSight FC',
    score: '1 - 2',
    status: 'FT',
    competition: 'Premier League · MD16',
    tacticalSummary: 'Late comeback fuelled by pressing intensity.',
    intensity: 88,
    homeColor: AppColors.warning,
    awayColor: AppColors.accentCyan,
    trendReason: '⚡ Top Intensity',
  ),
  TrendingMatchData(
    homeTeam: 'Sharks FC',
    awayTeam: 'Eagles Club',
    score: '0 - 0',
    status: 'FT',
    competition: 'Cup · QF',
    tacticalSummary: 'Tactical stalemate — mid-block battle.',
    intensity: 62,
    homeColor: AppColors.primaryBlue,
    awayColor: AppColors.accentGreen,
    trendReason: '📊 Most Analysed',
  ),
  TrendingMatchData(
    homeTeam: 'Storm United',
    awayTeam: 'Delta FC',
    score: 'LIVE',
    status: 'LIVE',
    competition: 'Champions League · GS',
    tacticalSummary: 'Wide pressing triggers rapid transitions.',
    intensity: 85,
    homeColor: AppColors.success,
    awayColor: AppColors.primaryPurple,
    trendReason: '🔴 LIVE Now',
  ),
];

// ─── Section ─────────────────────────────────────────────────────────────────

class TrendingMatchesSection extends StatelessWidget {
  const TrendingMatchesSection({
    super.key,
    this.matches = kTrendingMatches,
  });

  final List<TrendingMatchData> matches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.only(bottom: context.rs(12, min: 10, max: 14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.rs(40, min: 36, max: 44),
                height: context.rs(40, min: 36, max: 44),
                decoration: const BoxDecoration(
                  gradient: AppGradients.live,
                  borderRadius: AppRadius.chip,
                  boxShadow: AppShadows.cardGlow,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
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
                      'Trending Matches',
                      style: AppTextStyles.title(
                        color: AppColors.textPrimary,
                      ).copyWith(
                        fontSize: context.rs(18, min: 16, max: 22),
                      ),
                    ),
                    SizedBox(height: context.rs(3, min: 2, max: 4)),
                    Text(
                      'Most-watched fixtures right now.',
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
        ),

        // Horizontal scroll row
        SizedBox(
          height: context.rs(220, min: 200, max: 248),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(2, min: 0, max: 4),
              vertical: context.rs(2, min: 0, max: 4),
            ),
            itemCount: matches.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: context.rs(12, min: 10, max: 14)),
            itemBuilder: (context, index) {
              return _TrendingCard(
                data: matches[index],
                width: context.rs(220, min: 200, max: 260),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.data, required this.width});

  final TrendingMatchData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isLive = data.status.toUpperCase() == 'LIVE';

    return TapScale(
      scaleDown: 0.97,
      child: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.homeColor.withValues(alpha: isLive ? 0.22 : 0.16),
                AppColors.surfaceElevated.withValues(alpha: 0.95),
                data.awayColor.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: AppRadius.cardLarge,
            border: Border.all(
              color: isLive
                  ? AppColors.success.withValues(alpha: 0.4)
                  : data.homeColor.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: isLive
                    ? AppColors.success.withValues(alpha: 0.14)
                    : data.homeColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardLarge,
            child: Stack(
              children: [
                // Glow orb
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          data.homeColor.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: trend badge + status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.rs(8, min: 6, max: 10),
                                vertical: context.rs(4, min: 3, max: 5),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: AppRadius.chip,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                data.trendReason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(
                                  color: AppColors.textSecondary,
                                ).copyWith(
                                  fontSize: context.rs(9, min: 8, max: 10),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: context.rs(6, min: 4, max: 8)),
                          MatchStatusBadgeFromString(
                            status: data.status,
                            compact: true,
                          ),
                        ],
                      ),

                      SizedBox(height: context.rs(12, min: 10, max: 14)),

                      // Teams row
                      Row(
                        children: [
                          _MiniTeamBadge(
                            name: data.homeTeam,
                            color: data.homeColor,
                            size: context.rs(34, min: 30, max: 38),
                          ),
                          const Spacer(),
                          Text(
                            isLive ? 'VS' : data.score,
                            style: AppTextStyles.title(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontSize: context.rs(18, min: 16, max: 22),
                              letterSpacing: isLive ? 0.5 : 0.3,
                            ),
                          ),
                          const Spacer(),
                          _MiniTeamBadge(
                            name: data.awayTeam,
                            color: data.awayColor,
                            size: context.rs(34, min: 30, max: 38),
                          ),
                        ],
                      ),

                      SizedBox(height: context.rs(6, min: 4, max: 8)),

                      // Team names
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.homeTeam,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(
                                color: AppColors.textSecondary,
                              ).copyWith(
                                fontSize: context.rs(10, min: 9, max: 11),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              data.awayTeam,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.caption(
                                color: AppColors.textSecondary,
                              ).copyWith(
                                fontSize: context.rs(10, min: 9, max: 11),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.rs(10, min: 8, max: 12)),

                      // Competition
                      Text(
                        data.competition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(
                          color: AppColors.textMuted,
                        ).copyWith(
                          fontSize: context.rs(9, min: 8, max: 10),
                          letterSpacing: 0.3,
                        ),
                      ),

                      SizedBox(height: context.rs(10, min: 8, max: 12)),

                      // Tactical summary
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rs(10, min: 8, max: 12),
                            vertical: context.rs(8, min: 6, max: 10),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: AppRadius.card,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: context.rs(12, min: 11, max: 14),
                                color: AppColors.accentCyan,
                              ),
                              SizedBox(width: context.rs(6, min: 4, max: 8)),
                              Expanded(
                                child: Text(
                                  data.tacticalSummary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(
                                    color: AppColors.textPrimary,
                                  ).copyWith(
                                    fontSize: context.rs(10, min: 9, max: 11),
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Intensity bar
                      SizedBox(height: context.rs(10, min: 8, max: 12)),
                      _IntensityBar(intensity: data.intensity),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mini Helpers ─────────────────────────────────────────────────────────────

class _MiniTeamBadge extends StatelessWidget {
  const _MiniTeamBadge({
    required this.name,
    required this.color,
    required this.size,
  });

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final abbr = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Text(
          abbr,
          style: AppTextStyles.caption(color: Colors.white).copyWith(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.intensity});

  final int intensity;

  @override
  Widget build(BuildContext context) {
    final frac = (intensity / 100).clamp(0.0, 1.0);
    final color = intensity >= 80
        ? AppColors.warning
        : intensity >= 60
            ? AppColors.accentCyan
            : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: context.rs(10, min: 9, max: 12),
              color: color,
            ),
            SizedBox(width: context.rs(4, min: 3, max: 5)),
            Text(
              'Intensity $intensity',
              style: AppTextStyles.caption(color: color).copyWith(
                fontSize: context.rs(9, min: 8, max: 10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: context.rs(4, min: 3, max: 5)),
        ClipRRect(
          borderRadius: AppRadius.chip,
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 3,
            backgroundColor: AppColors.outlineSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
