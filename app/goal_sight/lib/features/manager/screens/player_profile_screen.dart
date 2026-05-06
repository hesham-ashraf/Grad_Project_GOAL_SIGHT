/// ---------------------------------------------------------------------------
/// GoalSight — Player Profile Screen
///
/// Detailed performance analysis view for a single player.
/// Features:
/// - Header with player info and status
/// - Performance metrics (rating, fatigue, activity)
/// - Contribution breakdown
/// - Match history with statistics
/// - Performance trend visualization
/// - AI-generated insights
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/data/models/player_profile_model.dart';
import 'package:goal_sight/features/manager/widgets/player_stat_tile.dart';
import 'package:goal_sight/features/manager/widgets/player_match_history_item.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    required this.player,
    Key? key,
  }) : super(key: key);

  final PlayerProfileModel player;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Color _getRatingColor() {
    if (widget.player.currentRating >= 8.0) {
      return AppColors.accentGreen;
    } else if (widget.player.currentRating >= 7.0) {
      return AppColors.accentCyan;
    } else if (widget.player.currentRating >= 6.0) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  Color _getTrendColor() {
    switch (widget.player.trend) {
      case PerformanceTrend.improving:
        return AppColors.accentGreen;
      case PerformanceTrend.declining:
        return AppColors.danger;
      case PerformanceTrend.stable:
        return AppColors.textSecondary;
    }
  }

  String _getTrendIcon() {
    switch (widget.player.trend) {
      case PerformanceTrend.improving:
        return '↗';
      case PerformanceTrend.declining:
        return '↘';
      case PerformanceTrend.stable:
        return '→';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundAlt,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: context.rs(20, min: 18, max: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.player.name,
          style: AppTextStyles.title(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(context),
                  SizedBox(height: context.rs(AppSpacing.xl)),

                  // Performance Overview Section
                  _buildSectionTitle('Performance Overview', context),
                  SizedBox(height: context.rs(AppSpacing.lg)),
                  _buildPerformanceGrid(context),
                  SizedBox(height: context.rs(AppSpacing.xl)),

                  // Contribution Section
                  _buildSectionTitle('Contribution Profile', context),
                  SizedBox(height: context.rs(AppSpacing.lg)),
                  _buildContributionCards(context),
                  SizedBox(height: context.rs(AppSpacing.xl)),

                  // Performance Trend Section
                  _buildSectionTitle('Performance Trend', context),
                  SizedBox(height: context.rs(AppSpacing.lg)),
                  _buildTrendCard(context),
                  SizedBox(height: context.rs(AppSpacing.xl)),

                  // Match History Section
                  _buildSectionTitle(
                    'Recent Matches (${widget.player.matchHistory.length})',
                    context,
                  ),
                  SizedBox(height: context.rs(AppSpacing.lg)),
                  Column(
                    children: widget.player.matchHistory.map((match) {
                      return PlayerMatchHistoryItem(match: match);
                    }).toList(),
                  ),
                  SizedBox(height: context.rs(AppSpacing.xl)),

                  // Insights Section
                  if (widget.player.insights.isNotEmpty) ...[
                    _buildSectionTitle('AI Insights', context),
                    SizedBox(height: context.rs(AppSpacing.lg)),
                    _buildInsightsCards(context),
                    SizedBox(height: context.rs(AppSpacing.xl)),
                  ],

                  // Statistics Section
                  _buildSectionTitle('Season Statistics', context),
                  SizedBox(height: context.rs(AppSpacing.lg)),
                  _buildStatsGrid(context),
                  SizedBox(height: context.rs(AppSpacing.xl)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.surfaceRaised,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.cardGlow,
      ),
      padding: EdgeInsets.all(context.rs(AppSpacing.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name, Position, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.name,
                      style: AppTextStyles.headline(
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.rs(AppSpacing.sm)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rs(AppSpacing.sm),
                            vertical: context.rs(AppSpacing.xs),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.2),
                            border: Border.all(
                              color: AppColors.primaryPurple,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            widget.player.position,
                            style: AppTextStyles.caption(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating Badge
              Container(
                padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
                decoration: BoxDecoration(
                  color: _getRatingColor().withOpacity(0.15),
                  border: Border.all(
                    color: _getRatingColor().withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.player.currentRating.toStringAsFixed(1)}',
                      style: AppTextStyles.headline(
                        color: _getRatingColor(),
                      ),
                    ),
                    Text(
                      'Current',
                      style: AppTextStyles.caption(
                        color: _getRatingColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(AppSpacing.lg)),

          // Status and Trend - Use Wrap to prevent overflow
          Wrap(
            spacing: context.rs(AppSpacing.md),
            runSpacing: context.rs(AppSpacing.sm),
            children: [
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(AppSpacing.md),
                  vertical: context.rs(AppSpacing.sm),
                ),
                decoration: BoxDecoration(
                  color: widget.player.status == 'Explosive Form'
                      ? AppColors.accentGreen.withOpacity(0.15)
                      : widget.player.status == 'Elite Form'
                          ? AppColors.accentCyan.withOpacity(0.15)
                          : widget.player.status.contains('Improvement')
                              ? AppColors.danger.withOpacity(0.15)
                              : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  widget.player.status,
                  style: AppTextStyles.caption(
                    color: widget.player.status == 'Explosive Form'
                        ? AppColors.accentGreen
                        : widget.player.status == 'Elite Form'
                            ? AppColors.accentCyan
                            : widget.player.status.contains('Improvement')
                                ? AppColors.danger
                                : AppColors.warning,
                  ),
                ),
              ),

              // Trend Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(AppSpacing.md),
                  vertical: context.rs(AppSpacing.sm),
                ),
                decoration: BoxDecoration(
                  color: _getTrendColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTrendIcon(),
                      style: AppTextStyles.title(
                        color: _getTrendColor(),
                      ),
                    ),
                    SizedBox(width: context.rs(AppSpacing.xs)),
                    Text(
                      '${widget.player.trendLabel} (${widget.player.improvementRate > 0 ? '+' : ''}${widget.player.improvementRate.toStringAsFixed(1)}%)',
                      style: AppTextStyles.caption(
                        color: _getTrendColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: context.rs(AppSpacing.md),
      mainAxisSpacing: context.rs(AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PlayerStatTile(
          label: 'Average Rating',
          value: widget.player.averageRating,
          unit: '/10',
          icon: Icons.star,
          color: AppColors.warning,
          maxValue: 10,
        ),
        PlayerStatTile(
          label: 'Fatigue Level',
          value: widget.player.fatigue.toDouble(),
          unit: '%',
          icon: Icons.local_fire_department,
          color: AppColors.danger,
          maxValue: 100,
        ),
        PlayerStatTile(
          label: 'Activity Level',
          value: widget.player.activityLevel.toDouble(),
          unit: '%',
          icon: Icons.bolt,
          color: AppColors.accentGreen,
          maxValue: 100,
        ),
        PlayerStatTile(
          label: 'Matches Played',
          value: widget.player.totalMatches.toDouble(),
          unit: '',
          icon: Icons.sports_soccer,
          color: AppColors.accentCyan,
          maxValue: 20,
        ),
      ],
    );
  }

  Widget _buildContributionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.outline.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppColors.accentGreen,
                      size: context.rs(18),
                    ),
                    SizedBox(width: context.rs(AppSpacing.sm)),
                    Text(
                      'Primary',
                      style: AppTextStyles.caption(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(AppSpacing.md)),
                Text(
                  widget.player.primaryContribution,
                  style: AppTextStyles.title(
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.rs(AppSpacing.md)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.outline.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_down,
                      color: AppColors.accentCyan,
                      size: context.rs(18),
                    ),
                    SizedBox(width: context.rs(AppSpacing.sm)),
                    Text(
                      'Secondary',
                      style: AppTextStyles.caption(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(AppSpacing.md)),
                Text(
                  widget.player.secondaryContribution,
                  style: AppTextStyles.title(
                    color: AppColors.accentCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard(BuildContext context) {
    final ratings = widget.player.ratingsHistory;
    final maxRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a > b ? a : b) : 10.0;
    final minRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a < b ? a : b) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rating Progress',
                style: AppTextStyles.body(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.player.trendLabel,
                style: AppTextStyles.caption(
                  color: _getTrendColor(),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(AppSpacing.lg)),

          // Mini Line Chart (simplified)
          SizedBox(
            height: context.rs(60),
            child: CustomPaint(
              painter: _TrendChartPainter(
                ratings: ratings,
                maxRating: maxRating,
                minRating: minRating,
                color: _getTrendColor(),
              ),
              size: Size.infinite,
            ),
          ),
          SizedBox(height: context.rs(AppSpacing.md)),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '${minRating.toStringAsFixed(1)}',
                    style: AppTextStyles.caption(
                      color: AppColors.danger,
                    ),
                  ),
                  Text(
                    'Lowest',
                    style: AppTextStyles.caption(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${widget.player.averageRating.toStringAsFixed(1)}',
                    style: AppTextStyles.caption(
                      color: AppColors.accentCyan,
                    ),
                  ),
                  Text(
                    'Average',
                    style: AppTextStyles.caption(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${maxRating.toStringAsFixed(1)}',
                    style: AppTextStyles.caption(
                      color: AppColors.accentGreen,
                    ),
                  ),
                  Text(
                    'Highest',
                    style: AppTextStyles.caption(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCards(BuildContext context) {
    return Column(
      children: widget.player.insights.map((insight) {
        return Container(
          margin: EdgeInsets.only(bottom: context.rs(AppSpacing.md)),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppColors.primaryBlue,
                size: context.rs(20),
              ),
              SizedBox(width: context.rs(AppSpacing.md)),
              Expanded(
                child: Text(
                  insight,
                  style: AppTextStyles.body(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: context.rs(AppSpacing.md),
      mainAxisSpacing: context.rs(AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatBox(
          context,
          label: 'Goals',
          value: '${widget.player.totalGoals}',
          icon: Icons.sports_soccer,
          color: AppColors.accentGreen,
          subtext: '${widget.player.goalsPerMatch.toStringAsFixed(2)}/match',
        ),
        _buildStatBox(
          context,
          label: 'Assists',
          value: '${widget.player.totalAssists}',
          icon: Icons.sports_basketball,
          color: AppColors.accentCyan,
          subtext: '${widget.player.assistsPerMatch.toStringAsFixed(2)}/match',
        ),
        _buildStatBox(
          context,
          label: 'Tackles',
          value: '${widget.player.totalTackles}',
          icon: Icons.shield,
          color: AppColors.warning,
          subtext: '${widget.player.tacklesPerMatch.toStringAsFixed(2)}/match',
        ),
        _buildStatBox(
          context,
          label: 'Matches',
          value: '${widget.player.totalMatches}',
          icon: Icons.sports_score,
          color: AppColors.primaryPurple,
          subtext: 'Season Total',
        ),
      ],
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: context.rs(24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.title(
                  color: color,
                ).copyWith(
                  fontSize: context.sp(20),
                ),
              ),
              SizedBox(height: context.rs(AppSpacing.xs)),
              Text(
                label,
                style: AppTextStyles.caption(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: context.rs(AppSpacing.xxs)),
              Text(
                subtext,
                style: AppTextStyles.caption(
                  color: AppColors.textMuted,
                ).copyWith(
                  fontSize: context.sp(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.title(
        color: AppColors.textPrimary,
      ),
    );
  }
}

// Custom Painter for Trend Chart
class _TrendChartPainter extends CustomPainter {
  final List<double> ratings;
  final double maxRating;
  final double minRating;
  final Color color;

  _TrendChartPainter({
    required this.ratings,
    required this.maxRating,
    required this.minRating,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final range = maxRating - minRating;
    if (range == 0) return;

    final points = <Offset>[];
    for (int i = 0; i < ratings.length; i++) {
      final x = (i / (ratings.length - 1)) * size.width;
      final normalizedRating = (ratings[i] - minRating) / range;
      final y = size.height * (1 - normalizedRating);
      points.add(Offset(x, y));
    }

    // Draw filled area
    final pathFill = Path();
    pathFill.moveTo(0, size.height);
    for (final point in points) {
      pathFill.lineTo(point.dx, point.dy);
    }
    pathFill.lineTo(size.width, size.height);
    pathFill.close();
    canvas.drawPath(pathFill, fillPaint);

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) {
    return oldDelegate.ratings != ratings || oldDelegate.color != color;
  }
}
