import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state_management/app_providers.dart';

class ManagerPanelScreen extends ConsumerWidget {
  const ManagerPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsSummaryProvider);
    final teamMembers = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040B1E),
      appBar: AppBar(
        title: const Text('Manager Analytics'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF040B1E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040B1E), Color(0xFF081632), Color(0xFF040B1E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _NeonPanel(
                    title: '2025/2026 Season',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'League Goal: 8 / 30',
                          style: TextStyle(color: Color(0xFFA4B5D7)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${analytics.totalGoals} goals',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _NeonPanel(
                    title: 'Last Game Statistics',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CircularStat(label: 'Shots', value: 37),
                        _CircularStat(label: 'Pass', value: 58),
                        _CircularStat(label: 'Discipline', value: 81),
                        _CircularStat(label: 'Possession', value: 74),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _NeonPanel(
              title: 'Standings',
              child: Column(
                children: const [
                  _StandingRow(
                      index: 10,
                      team: 'FC Minsk',
                      played: 7,
                      wins: 1,
                      draws: 4,
                      loses: 2,
                      goals: 7,
                      points: 8),
                  _StandingRow(
                      index: 11,
                      team: 'FC Gomel',
                      played: 6,
                      wins: 1,
                      draws: 4,
                      loses: 1,
                      goals: 7,
                      points: 7),
                  _StandingRow(
                      index: 12,
                      team: 'Naftan',
                      played: 6,
                      wins: 1,
                      draws: 4,
                      loses: 1,
                      goals: 1,
                      points: 7),
                  _StandingRow(
                      index: 13,
                      team: 'Dynamo Brest',
                      played: 5,
                      wins: 1,
                      draws: 0,
                      loses: 6,
                      goals: 0,
                      points: 6),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _NeonPanel(
                    title: 'Personal Characteristics',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamMembers.first.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _Meter(label: 'Speed', value: 88),
                        const _Meter(label: 'Kicking', value: 69),
                        const _Meter(label: 'Reflexes', value: 91),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NeonPanel(
                    title: 'Your Team',
                    child: Column(
                      children: teamMembers
                          .map(
                            (member) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                member.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                member.position,
                                style:
                                    const TextStyle(color: Color(0xFF8EA3CD)),
                              ),
                              trailing: TextButton(
                                onPressed: () =>
                                    context.go('/player/${member.id}'),
                                child: const Text('View'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonPanel extends StatelessWidget {
  const _NeonPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13243F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C406D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x446F58F5),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CircularStat extends StatelessWidget {
  const _CircularStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 5,
                backgroundColor: const Color(0xFF314670),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6F58F5)),
              ),
              Text(
                '$value%',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Color(0xFF8EA3CD))),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.index,
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.loses,
    required this.goals,
    required this.points,
  });

  final int index;
  final String team;
  final int played;
  final int wins;
  final int draws;
  final int loses;
  final int goals;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$index',
                style: const TextStyle(color: Color(0xFF8EA3CD))),
          ),
          Expanded(
            child: Text(team, style: const TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 28, child: _StatNumber('$played')),
          SizedBox(width: 28, child: _StatNumber('$wins')),
          SizedBox(width: 28, child: _StatNumber('$draws')),
          SizedBox(width: 28, child: _StatNumber('$loses')),
          SizedBox(width: 28, child: _StatNumber('$goals')),
          SizedBox(width: 32, child: _StatNumber('$points')),
        ],
      ),
    );
  }
}

class _StatNumber extends StatelessWidget {
  const _StatNumber(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF8EA3CD)),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8EA3CD))),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: value / 100,
                    backgroundColor: const Color(0xFF314670),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6F58F5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$value/100',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
