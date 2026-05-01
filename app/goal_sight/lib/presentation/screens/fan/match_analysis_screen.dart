import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/fan/match_analysis_widgets.dart';

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({
    super.key,
    required this.match,
  });

  final MatchModel match;

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
    final match = widget.match;
    final bestPlayer = match.players.where((p) => p.isBest).firstOrNull;
    final worstPlayer = match.players.where((p) => p.isWorst).firstOrNull;

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
                child: MatchOverviewCard(
                  homeTeam: match.homeTeam,
                  awayTeam: match.awayTeam,
                  score: match.score,
                  summary: match.summary.isNotEmpty ? match.summary : 'No summary available.',
                  dominantTeam: match.dominantTeam.isNotEmpty ? match.dominantTeam : 'Balanced',
                  homeColor: match.homeColor,
                  awayColor: match.awayColor,
                ),
              ),
            ),
            SizedBox(height: context.rs(24, min: 20, max: 32)),

            // Key Players
            if (bestPlayer != null || worstPlayer != null) ...[
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
                          if (bestPlayer != null)
                            Expanded(
                              child: KeyPlayerCard(
                                title: 'Man of the Match',
                                playerName: bestPlayer.name,
                                rating: bestPlayer.rating,
                                insight: bestPlayer.insight,
                                isBest: true,
                              ),
                            ),
                          if (bestPlayer != null && worstPlayer != null)
                            SizedBox(width: context.rs(12, min: 8, max: 16)),
                          if (worstPlayer != null)
                            Expanded(
                              child: KeyPlayerCard(
                                title: 'Needs Improvement',
                                playerName: worstPlayer.name,
                                rating: worstPlayer.rating,
                                insight: worstPlayer.insight,
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
            ],

            // Tactical Analysis
            if (match.tactics != null) ...[
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
                      TacticalRow(
                        possessionHome: match.tactics!.homePossession,
                        styleHome: match.tactics!.homeStyle,
                        pressureHome: match.tactics!.homePressure,
                        styleAway: match.tactics!.awayStyle,
                        pressureAway: match.tactics!.awayPressure,
                        homeColor: match.homeColor,
                        awayColor: match.awayColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.rs(24, min: 20, max: 32)),
            ],

            // Player Performances
            if (match.players.isNotEmpty) ...[
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
                      ...match.players.map((p) => Padding(
                            padding: EdgeInsets.only(bottom: context.rs(8, min: 4, max: 12)),
                            child: PlayerListItem(
                              name: p.name,
                              rating: p.rating,
                              insight: p.insight,
                              isHighRated: p.rating >= 7.5,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.rs(24, min: 20, max: 32)),
            ],

            // AI Recommendations
            if (match.recommendations.isNotEmpty) ...[
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
                      ...match.recommendations.map((rec) => Padding(
                            padding: EdgeInsets.only(bottom: context.rs(8, min: 4, max: 12)),
                            child: RecommendationCard(
                              recommendation: rec,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: context.rs(40, min: 24, max: 60)), // Bottom padding
          ],
        ),
      ),
    );
  }
}
