import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/match_analysis_model.dart';
import '../widgets/match_card.dart';
import '../manager_matches_mock_data.dart';

class ManagerMatchesScreen extends StatefulWidget {
  const ManagerMatchesScreen({super.key});

  @override
  State<ManagerMatchesScreen> createState() => _ManagerMatchesScreenState();
}

class _ManagerMatchesScreenState extends State<ManagerMatchesScreen> {
  String _filter = 'Recent';

  List<MatchAnalysisModel> get _filteredMatches {
    final list = kManagerMockMatches;
    if (_filter == 'Recent') return list;
    if (_filter == 'High Intensity') {
      final copy = List<MatchAnalysisModel>.from(list);
      copy.sort((a, b) => b.intensity.compareTo(a.intensity));
      return copy;
    }
    if (_filter == 'Best') {
      final copy = List<MatchAnalysisModel>.from(list);
      copy.sort((a, b) =>
          b.summary.homeAvgRating.compareTo(a.summary.homeAvgRating));
      return copy;
    }
    return list;
  }

  void _openAnalysis(MatchAnalysisModel m) {
    context.push('/fan-match-analysis', extra: m);
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Matches & Analysis'),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            children: [
              // Filters
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Recent'),
                    selected: _filter == 'Recent',
                    onSelected: (s) => setState(() => _filter = 'Recent'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('High Intensity'),
                    selected: _filter == 'High Intensity',
                    onSelected: (s) =>
                        setState(() => _filter = 'High Intensity'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Best'),
                    selected: _filter == 'Best',
                    onSelected: (s) => setState(() => _filter = 'Best'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: matches.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final item = matches[index];
                    final isRecent = index == 0 && _filter == 'Recent';
                    return MatchCard(
                      match: item,
                      isRecent: isRecent,
                      onTap: () => _openAnalysis(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
