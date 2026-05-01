import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import 'tap_scale.dart';

class FeaturedMatchData {
  const FeaturedMatchData({
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    required this.highlight,
    required this.competition,
    required this.statusLabel,
    required this.homeColor,
    required this.awayColor,
  });

  final String homeTeam;
  final String awayTeam;
  final String score;
  final String highlight;
  final String competition;
  final String statusLabel;
  final Color homeColor;
  final Color awayColor;
}

class PlayerPerformance {
  const PlayerPerformance({
    required this.name,
    required this.rating,
    required this.position,
    required this.club,
    required this.tintColor,
    this.isBestPlayer = false,
  });

  final String name;
  final double rating;
  final String position;
  final String club;
  final Color tintColor;
  final bool isBestPlayer;
}

class QuickStatData {
  const QuickStatData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tintColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tintColor;
}

class FeaturedMatchCard extends StatelessWidget {
  const FeaturedMatchCard({super.key, required this.match});

  final FeaturedMatchData match;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            match.homeColor.withValues(alpha: 0.28),
            AppColors.surface,
            match.awayColor.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: [
          BoxShadow(
            color: match.homeColor.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardLarge,
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _GlowOrb(
                size: 250,
                color: match.homeColor.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              left: -100,
              bottom: -120,
              child: _GlowOrb(
                size: 280,
                color: match.awayColor.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.rs(18, min: 16, max: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MatchBadge(
                        icon: Icons.sports_soccer_rounded,
                        label: match.competition,
                        tintColor: match.homeColor,
                      ),
                      const Spacer(),
                      _MatchBadge(
                        icon: Icons.bolt_rounded,
                        label: match.statusLabel,
                        tintColor: match.awayColor,
                      ),
                    ],
                  ),
                  SizedBox(height: context.rs(16, min: 12, max: 18)),
                  Text(
                    '${match.homeTeam} vs ${match.awayTeam}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(color: AppColors.textPrimary)
                        .copyWith(
                      fontSize: context.rs(28, min: 24, max: 38),
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: context.rs(14, min: 10, max: 16)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 560;

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TeamPanel(
                              teamName: match.homeTeam,
                              teamColor: match.homeColor,
                              alignEnd: false,
                            ),
                            SizedBox(height: context.rs(14, min: 10, max: 16)),
                            Center(
                              child: _ScorePanel(
                                score: match.score,
                                tintColor: match.homeColor,
                              ),
                            ),
                            SizedBox(height: context.rs(14, min: 10, max: 16)),
                            _TeamPanel(
                              teamName: match.awayTeam,
                              teamColor: match.awayColor,
                              alignEnd: true,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _TeamPanel(
                              teamName: match.homeTeam,
                              teamColor: match.homeColor,
                              alignEnd: false,
                            ),
                          ),
                          SizedBox(width: context.rs(16, min: 12, max: 20)),
                          _ScorePanel(
                            score: match.score,
                            tintColor: match.homeColor,
                          ),
                          SizedBox(width: context.rs(16, min: 12, max: 20)),
                          Expanded(
                            child: _TeamPanel(
                              teamName: match.awayTeam,
                              teamColor: match.awayColor,
                              alignEnd: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: context.rs(16, min: 12, max: 18)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rs(14, min: 12, max: 16),
                      vertical: context.rs(12, min: 10, max: 14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: AppRadius.card,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: context.rs(18, min: 16, max: 20),
                          color: AppColors.accentCyan,
                        ),
                        SizedBox(width: context.rs(10, min: 8, max: 12)),
                        Expanded(
                          child: Text(
                            match.highlight,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontSize: context.rs(14, min: 13, max: 16),
                              fontWeight: FontWeight.w600,
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
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    this.width,
    this.onTap,
  });

  final PlayerPerformance player;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final innerCard = Container(
      decoration: BoxDecoration(
        gradient: player.isBestPlayer
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  player.tintColor.withValues(alpha: 0.22),
                  AppColors.surfaceElevated.withValues(alpha: 0.96),
                  AppColors.surface.withValues(alpha: 0.92),
                ],
              )
            : null,
        color: player.isBestPlayer
            ? null
            : AppColors.surfaceElevated.withValues(alpha: 0.94),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: player.isBestPlayer
              ? player.tintColor.withValues(alpha: 0.38)
              : AppColors.outlineSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: player.isBestPlayer
                ? player.tintColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.18),
            blurRadius: player.isBestPlayer ? 24 : 20,
            offset: const Offset(0, 10),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(10, min: 8, max: 12),
                    vertical: context.rs(6, min: 5, max: 7),
                  ),
                  decoration: BoxDecoration(
                    color: player.tintColor.withValues(alpha: 0.14),
                    borderRadius: AppRadius.chip,
                    border: Border.all(
                      color: player.tintColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    player.position.toUpperCase(),
                    style: AppTextStyles.caption(
                      color: player.tintColor,
                    ).copyWith(
                      fontSize: context.rs(9, min: 8, max: 10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                const Spacer(),
                if (player.isBestPlayer)
                  Container(
                    padding: EdgeInsets.all(context.rs(6, min: 5, max: 7)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: context.rs(16, min: 14, max: 18),
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.rs(14, min: 10, max: 14)),
            Text(
              player.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                fontSize: context.rs(18, min: 16, max: 22),
                height: 1.12,
              ),
            ),
            SizedBox(height: context.rs(4, min: 2, max: 6)),
            Text(
              player.club,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(color: AppColors.textSecondary)
                  .copyWith(
                fontSize: context.rs(12, min: 11, max: 13),
              ),
            ),
            SizedBox(height: context.rs(14, min: 10, max: 14)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  player.rating.toStringAsFixed(1),
                  style: AppTextStyles.headline(color: AppColors.textPrimary)
                      .copyWith(
                    fontSize: context.rs(28, min: 24, max: 30),
                    height: 0.95,
                  ),
                ),
                SizedBox(width: context.rs(6, min: 4, max: 8)),
                Padding(
                  padding: EdgeInsets.only(bottom: context.rs(2, min: 1, max: 3)),
                  child: Text(
                    'rating',
                    style: AppTextStyles.caption(color: AppColors.textMuted)
                        .copyWith(
                      fontSize: context.rs(10, min: 9, max: 11),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(10, min: 8, max: 10)),
            if (player.isBestPlayer)
              _BestPlayerRibbon(color: player.tintColor)
            else
              Text(
                'Subtle tap animation',
                style: AppTextStyles.caption(color: AppColors.textMuted)
                    .copyWith(
                  fontSize: context.rs(10, min: 9, max: 11),
                ),
              ),
          ],
        ),
      ),
    );

    final card = width == null ? innerCard : SizedBox(width: width, child: innerCard);

    return TapScale(
      onTap: onTap,
      scaleDown: 0.975,
      child: card,
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.stat});

  final QuickStatData stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.92),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: stat.tintColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: stat.tintColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: context.rs(40, min: 36, max: 44),
                  height: context.rs(40, min: 36, max: 44),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        stat.tintColor.withValues(alpha: 0.28),
                        stat.tintColor.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: stat.tintColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    stat.icon,
                    color: Colors.white,
                    size: context.rs(18, min: 16, max: 20),
                  ),
                ),
                const Spacer(),
                Container(
                  width: context.rs(8, min: 6, max: 8),
                  height: context.rs(8, min: 6, max: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stat.tintColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(14, min: 10, max: 14)),
            Text(
              stat.value,
              style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                fontSize: context.rs(26, min: 22, max: 32),
                height: 0.95,
              ),
            ),
            SizedBox(height: context.rs(6, min: 4, max: 8)),
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                fontSize: context.rs(14, min: 13, max: 16),
              ),
            ),
            SizedBox(height: context.rs(4, min: 2, max: 6)),
            Text(
              stat.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                fontSize: context.rs(10, min: 9, max: 11),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({
    required this.icon,
    required this.label,
    required this.tintColor,
  });

  final IconData icon;
  final String label;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(12, min: 10, max: 14),
        vertical: context.rs(8, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
        border: Border.all(color: tintColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.rs(14, min: 12, max: 15),
            color: tintColor,
          ),
          SizedBox(width: context.rs(6, min: 4, max: 8)),
          Text(
            label,
            style: AppTextStyles.caption(color: tintColor).copyWith(
              fontSize: context.rs(10, min: 9, max: 11),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPanel extends StatelessWidget {
  const _TeamPanel({
    required this.teamName,
    required this.teamColor,
    required this.alignEnd,
  });

  final String teamName;
  final Color teamColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          width: context.rs(52, min: 46, max: 56),
          height: context.rs(52, min: 46, max: 56),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                teamColor.withValues(alpha: 0.32),
                teamColor.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: teamColor.withValues(alpha: 0.35)),
          ),
          child: Center(
            child: Text(
              _initials(teamName),
              style: AppTextStyles.title(color: Colors.white).copyWith(
                fontSize: context.rs(17, min: 15, max: 19),
                height: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: context.rs(10, min: 8, max: 10)),
        Text(
          teamName,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
            fontSize: context.rs(16, min: 15, max: 18),
          ),
        ),
        SizedBox(height: context.rs(4, min: 2, max: 6)),
        Text(
          alignEnd ? 'Away side' : 'Home side',
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
            fontSize: context.rs(10, min: 9, max: 11),
          ),
        ),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.score, required this.tintColor});

  final String score;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(14, min: 12, max: 16),
        vertical: context.rs(12, min: 10, max: 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: tintColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            score,
            style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
              fontSize: context.rs(52, min: 44, max: 66),
              letterSpacing: -1.4,
              height: 0.95,
            ),
          ),
          SizedBox(height: context.rs(4, min: 2, max: 6)),
          Text(
            'FINAL',
            style: AppTextStyles.caption(color: tintColor).copyWith(
              fontSize: context.rs(10, min: 9, max: 11),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestPlayerRibbon extends StatelessWidget {
  const _BestPlayerRibbon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10, min: 8, max: 12),
        vertical: context.rs(8, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.18),
            AppColors.warning.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.military_tech_rounded,
            size: context.rs(14, min: 12, max: 15),
            color: AppColors.warning,
          ),
          SizedBox(width: context.rs(8, min: 6, max: 8)),
          Expanded(
            child: Text(
              'Best player performance',
              style: AppTextStyles.caption(color: AppColors.textPrimary)
                  .copyWith(
                fontSize: context.rs(10, min: 9, max: 11),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return 'F';
  }

  if (parts.length == 1) {
    final word = parts.first;
    return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
  }

  final first = parts.first.characters.first;
  final last = parts.last.characters.first;
  return '$first$last'.toUpperCase();
}