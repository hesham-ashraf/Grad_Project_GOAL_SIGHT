import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/match.dart';

const Color _primaryGold = Color(0xFFFFD700);
const Color _accentAmber = Color(0xFFFFA000);
const Color _darkBackground = Color(0xFF0A0A0F);
const Color _cardDark = Color(0xFF1A1A24);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB8B8C8);

class ChartsPage extends StatelessWidget {
  final Match? match;
  final List<Match>? allMatches;

  const ChartsPage({super.key, this.match, this.allMatches});

  @override
  Widget build(BuildContext context) {
    final matches = allMatches ?? (match != null ? [match!] : []);
    
    if (matches.isEmpty) {
      return Scaffold(
        backgroundColor: _darkBackground,
        appBar: AppBar(
          title: const Text('Charts', style: TextStyle(color: _textPrimary)),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text(
            'No match data available',
            style: TextStyle(color: _textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_primaryGold, _accentAmber],
          ).createShader(bounds),
          child: const Text(
            'ADVANCED CHARTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (match != null) _buildSingleMatchCharts(match!),
              if (allMatches != null && allMatches!.isNotEmpty) _buildAllMatchesCharts(allMatches!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleMatchCharts(Match match) {
    return Column(
      children: [
        _buildChartCard(
          title: 'Score Distribution',
          child: SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: match.scoreA.toDouble(),
                    color: _primaryGold,
                    title: '${match.teamA}\n${match.scoreA}',
                    radius: 80,
                    titleStyle: const TextStyle(
                      color: _darkBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PieChartSectionData(
                    value: match.scoreB.toDouble(),
                    color: _accentAmber,
                    title: '${match.teamB}\n${match.scoreB}',
                    radius: 80,
                    titleStyle: const TextStyle(
                      color: _darkBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildChartCard(
          title: 'Score Comparison',
          child: SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (match.scoreA > match.scoreB ? match.scoreA : match.scoreB).toDouble() + 2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == 1) return Text(match.teamA, style: const TextStyle(color: _textSecondary, fontSize: 12));
                        if (value.toInt() == 2) return Text(match.teamB, style: const TextStyle(color: _textSecondary, fontSize: 12));
                        return const Text('', style: TextStyle(color: _textSecondary, fontSize: 12));
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: match.scoreA.toDouble(),
                        color: _primaryGold,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: match.scoreB.toDouble(),
                        color: _accentAmber,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllMatchesCharts(List<Match> matches) {
    // Calculate total goals per team across all matches
    final teamGoals = <String, int>{};
    for (var match in matches) {
      teamGoals[match.teamA] = (teamGoals[match.teamA] ?? 0) + match.scoreA;
      teamGoals[match.teamB] = (teamGoals[match.teamB] ?? 0) + match.scoreB;
    }

    final sortedTeams = teamGoals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildChartCard(
          title: 'Total Goals by Team',
          child: SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sortedTeams.isNotEmpty ? sortedTeams.first.value.toDouble() + 2 : 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt() - 1;
                        if (index >= 0 && index < sortedTeams.length) {
                          final teamName = sortedTeams[index].key.length > 8
                              ? sortedTeams[index].key.substring(0, 8)
                              : sortedTeams[index].key;
                          return Text(teamName, style: const TextStyle(color: _textSecondary, fontSize: 10));
                        }
                        return const Text('', style: TextStyle(color: _textSecondary, fontSize: 10));
                      },
                      reservedSize: 50,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedTeams.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key + 1,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: entry.key % 2 == 0 ? _primaryGold : _accentAmber,
                        width: 30,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildChartCard(
          title: 'Goals Distribution',
          child: SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: sortedTeams.take(5).map((entry) {
                  final index = sortedTeams.indexOf(entry);
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: index % 2 == 0 ? _primaryGold : _accentAmber,
                    title: '${entry.key}\n${entry.value}',
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: _darkBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

