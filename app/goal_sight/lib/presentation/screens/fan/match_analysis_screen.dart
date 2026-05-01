import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/fan/match_analysis_widgets.dart';

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({super.key});

  @override
  State<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends State<MatchAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _overviewFade;
  late final Animation<Offset> _overviewSlide;
  late final Animation<double> _playersFade;
  late final Animation<Offset> _playersSlide;
  late final Animation<double> _tacticalFade;
  late final Animation<Offset> _tacticalSlide;
  late final Animation<double> _listFade;
  late final Animation<Offset> _listSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _overviewFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
    );
    _overviewSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_overviewFade);

    _playersFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
    );
    _playersSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_playersFade);

    _tacticalFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
    );
    _tacticalSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_tacticalFade);

    _listFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
    );
    _listSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_listFade);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.rs(20, min: 16, max: 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Match Overview
            FadeTransition(
              opacity: _overviewFade,
              child: SlideTransition(
                position: _overviewSlide,
                child: const MatchOverviewCard(
                  homeTeam: 'GoalSight FC',
                  awayTeam: 'Falcons United',
                  score: '3 - 1',
                  summary:
                      'GoalSight FC dominated the midfield with quick passing transitions, overpowering Falcons United who struggled to break the high press.',
                  dominantTeam: 'GoalSight FC',
                  homeColor: AppColors.accentCyan,
                  awayColor: AppColors.primaryPurple,
                ),
              ),
            ),
            SizedBox(height: context.rs(24, min: 20, max: 32)),

            // Key Players
            FadeTransition(
              opacity: _playersFade,
              child: SlideTransition(
                position: _playersSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Performers',
                      style: AppTextStyles.title(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: context.rs(16, min: 12, max: 20)),
                    Row(
                      children: [
                        const Expanded(
                          child: KeyPlayerCard(
                            title: 'Man of the Match',
                            playerName: 'Hassan Ali',
                            rating: 8.9,
                            insight: 'Controlled the tempo and provided 2 key assists.',
                            isBest: true,
                          ),
                        ),
                        SizedBox(width: context.rs(12, min: 8, max: 16)),
                        const Expanded(
                          child: KeyPlayerCard(
                            title: 'Needs Improvement',
                            playerName: 'Tariq Ziad',
                            rating: 5.4,
                            insight: 'Lost possession 6 times in dangerous areas.',
                            isBest: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.rs(24, min: 20, max: 32)),

            // Tactical Analysis
            FadeTransition(
              opacity: _tacticalFade,
              child: SlideTransition(
                position: _tacticalSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tactical Breakdown',
                      style: AppTextStyles.title(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: context.rs(16, min: 12, max: 20)),
                    const TacticalRow(
                      possessionHome: 64,
                      styleHome: 'Possession-based',
                      pressureHome: 'High Press',
                      styleAway: 'Counter-attack',
                      pressureAway: 'Low Block',
                      homeColor: AppColors.accentCyan,
                      awayColor: AppColors.primaryPurple,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.rs(24, min: 20, max: 32)),

            // Player Performances
            FadeTransition(
              opacity: _listFade,
              child: SlideTransition(
                position: _listSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Squad Ratings',
                      style: AppTextStyles.title(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: context.rs(16, min: 12, max: 20)),
                    const PlayerListItem(
                      name: 'Hassan Ali',
                      rating: 8.9,
                      insight: 'Exceptional vision and passing accuracy.',
                      isHighRated: true,
                    ),
                    const PlayerListItem(
                      name: 'Mostafa Samir',
                      rating: 8.4,
                      insight: 'Constant threat on the wing. 1 Goal.',
                      isHighRated: true,
                    ),
                    const PlayerListItem(
                      name: 'Ziad Hamdy',
                      rating: 7.6,
                      insight: 'Solid defensive work rate.',
                      isHighRated: false,
                    ),
                    const PlayerListItem(
                      name: 'Omar Fathy',
                      rating: 7.1,
                      insight: 'Quiet game, minimal impact in final third.',
                      isHighRated: false,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.rs(24, min: 20, max: 32)),

            // AI Recommendations
            FadeTransition(
              opacity: _listFade,
              child: SlideTransition(
                position: _listSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach Recommendations',
                      style: AppTextStyles.title(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: context.rs(16, min: 12, max: 20)),
                    const RecommendationCard(
                      recommendation: 'Maintain high pressing intensity to exploit Falcons United\'s weak build-up play.',
                    ),
                    const RecommendationCard(
                      recommendation: 'Consider resting Hassan Ali in the 70th minute to prevent fatigue injuries.',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.rs(40, min: 24, max: 60)), // Bottom padding
          ],
        ),
      ),
    );
  }
}
