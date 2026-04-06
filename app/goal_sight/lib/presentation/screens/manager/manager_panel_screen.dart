import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive.dart';
import '../../../features/user/team_member_model.dart';
import '../../state_management/app_providers.dart';

class ManagerPanelScreen extends ConsumerWidget {
  const ManagerPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsSummaryProvider);
    final teamMembers = ref.watch(teamMembersProvider);
    const standings = [
      _StandingEntry(
        rank: 10,
        team: 'FC Minsk',
        played: 7,
        wins: 1,
        draws: 4,
        losses: 2,
        goals: 7,
        points: 8,
      ),
      _StandingEntry(
        rank: 11,
        team: 'FC Gomel',
        played: 6,
        wins: 1,
        draws: 4,
        losses: 1,
        goals: 7,
        points: 7,
      ),
      _StandingEntry(
        rank: 12,
        team: 'Naftan',
        played: 6,
        wins: 1,
        draws: 4,
        losses: 1,
        goals: 1,
        points: 7,
      ),
      _StandingEntry(
        rank: 13,
        team: 'Dynamo Brest',
        played: 5,
        wins: 1,
        draws: 0,
        losses: 6,
        goals: 0,
        points: 6,
      ),
    ];

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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ResponsiveCentered(
              maxWidth: 1280,
              padding: context.padSym(h: context.isPhone ? 12 : 18, v: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = context.rs(14, min: 10, max: 20);
                  final topColumns = constraints.maxWidth >= 980 ? 2 : 1;
                  final bottomColumns = constraints.maxWidth >= 980 ? 2 : 1;
                  final topCardWidth =
                      (constraints.maxWidth - (spacing * (topColumns - 1))) /
                          topColumns;
                  final bottomCardWidth =
                      (constraints.maxWidth - (spacing * (bottomColumns - 1))) /
                          bottomColumns;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: topCardWidth,
                            child: _SeasonPanel(totalGoals: analytics.totalGoals),
                          ),
                          SizedBox(
                            width: topCardWidth,
                            child: const _StatsPanel(),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      _StandingsPanel(entries: standings),
                      SizedBox(height: spacing),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: bottomCardWidth,
                            child: _PersonalCharacteristicsPanel(
                              playerName: teamMembers.isEmpty
                                  ? 'No player selected'
                                  : teamMembers.first.name,
                            ),
                          ),
                          SizedBox(
                            width: bottomCardWidth,
                            child: _TeamListPanel(teamMembers: teamMembers),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
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
        borderRadius: BorderRadius.circular(context.rs(16, min: 12, max: 24)),
        border: Border.all(color: const Color(0xFF2C406D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x446F58F5),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: context.padAll(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.sp(18, min: 14, max: 24),
            ),
          ),
          SizedBox(height: context.rs(12, min: 8, max: 18)),
          child,
        ],
      ),
    );
  }
}

class _SeasonPanel extends StatelessWidget {
  const _SeasonPanel({required this.totalGoals});

  final int totalGoals;

  @override
  Widget build(BuildContext context) {
    return _NeonPanel(
      title: '2025/2026 Season',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'League Goal: 8 / 30',
            style: TextStyle(
              color: const Color(0xFFA4B5D7),
              fontSize: context.sp(13, min: 11, max: 16),
            ),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$totalGoals goals',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.sp(30, min: 22, max: 40),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    return _NeonPanel(
      title: 'Last Game Statistics',
      child: Wrap(
        spacing: context.rs(10, min: 8, max: 14),
        runSpacing: context.rs(10, min: 8, max: 14),
        children: const [
          _CircularStat(label: 'Shots', value: 37),
          _CircularStat(label: 'Pass', value: 58),
          _CircularStat(label: 'Discipline', value: 81),
          _CircularStat(label: 'Possession', value: 74),
        ],
      ),
    );
  }
}

class _StandingsPanel extends StatelessWidget {
  const _StandingsPanel({required this.entries});

  final List<_StandingEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _NeonPanel(
      title: 'Standings',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1A2E50)),
          dataRowMinHeight: context.rs(44, min: 38, max: 52),
          dataRowMaxHeight: context.rs(52, min: 42, max: 60),
          columnSpacing: context.rs(16, min: 12, max: 22),
          columns: const [
            DataColumn(label: _TableHeader('#')),
            DataColumn(label: _TableHeader('Team')),
            DataColumn(label: _TableHeader('P')),
            DataColumn(label: _TableHeader('W')),
            DataColumn(label: _TableHeader('D')),
            DataColumn(label: _TableHeader('L')),
            DataColumn(label: _TableHeader('GF')),
            DataColumn(label: _TableHeader('Pts')),
          ],
          rows: entries
              .map(
                (entry) => DataRow(
                  cells: [
                    DataCell(_TableValue('${entry.rank}')),
                    DataCell(
                      SizedBox(
                        width: context.rs(140, min: 110, max: 170),
                        child: _TableValue(entry.team),
                      ),
                    ),
                    DataCell(_TableValue('${entry.played}')),
                    DataCell(_TableValue('${entry.wins}')),
                    DataCell(_TableValue('${entry.draws}')),
                    DataCell(_TableValue('${entry.losses}')),
                    DataCell(_TableValue('${entry.goals}')),
                    DataCell(_TableValue('${entry.points}', isBold: true)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _PersonalCharacteristicsPanel extends StatelessWidget {
  const _PersonalCharacteristicsPanel({required this.playerName});

  final String playerName;

  @override
  Widget build(BuildContext context) {
    return _NeonPanel(
      title: 'Personal Characteristics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playerName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.sp(18, min: 14, max: 24),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.rs(10, min: 8, max: 14)),
          const _Meter(label: 'Speed', value: 88),
          const _Meter(label: 'Kicking', value: 69),
          const _Meter(label: 'Reflexes', value: 91),
        ],
      ),
    );
  }
}

class _TeamListPanel extends StatelessWidget {
  const _TeamListPanel({required this.teamMembers});

  final List<TeamMemberModel> teamMembers;

  @override
  Widget build(BuildContext context) {
    return _NeonPanel(
      title: 'Your Team',
      child: teamMembers.isEmpty
          ? Text(
              'No team members available.',
              style: TextStyle(
                color: const Color(0xFF8EA3CD),
                fontSize: context.sp(14, min: 12, max: 18),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teamMembers.length,
              separatorBuilder: (_, __) => Divider(
                color: const Color(0xFF2C406D),
                height: context.rs(1, min: 1, max: 2),
              ),
              itemBuilder: (context, index) {
                final member = teamMembers[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    member.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.sp(14, min: 12, max: 18),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    member.position,
                    style: TextStyle(
                      color: const Color(0xFF8EA3CD),
                      fontSize: context.sp(12, min: 10, max: 15),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: TextButton(
                    onPressed: () => context.push('/player/${member.id}'),
                    child: const Text('View'),
                  ),
                );
              },
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
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: context.rs(88, min: 74, max: 100)),
      child: Column(
        children: [
          SizedBox(
            width: context.rs(56, min: 44, max: 70),
            height: context.rs(56, min: 44, max: 70),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: context.rs(5, min: 4, max: 6),
                  backgroundColor: const Color(0xFF314670),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6F58F5)),
                ),
                Text(
                  '$value%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(11, min: 9, max: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF8EA3CD),
              fontSize: context.sp(12, min: 10, max: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: const Color(0xFF8EA3CD),
        fontWeight: FontWeight.w700,
        fontSize: context.sp(12, min: 10, max: 15),
      ),
    );
  }
}

class _TableValue extends StatelessWidget {
  const _TableValue(this.value, {this.isBold = false});

  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: isBold ? Colors.white : const Color(0xFFD2DDFA),
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        fontSize: context.sp(13, min: 11, max: 16),
      ),
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
      padding: context.padSym(v: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF8EA3CD),
              fontSize: context.sp(12, min: 10, max: 15),
            ),
          ),
          SizedBox(height: context.rs(5, min: 3, max: 8)),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: LinearProgressIndicator(
                    minHeight: context.rs(7, min: 5, max: 9),
                    value: value / 100,
                    backgroundColor: const Color(0xFF314670),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6F58F5)),
                  ),
                ),
              ),
              SizedBox(width: context.rs(10, min: 8, max: 14)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value/100',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(12, min: 10, max: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StandingEntry {
  const _StandingEntry({
    required this.rank,
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.points,
  });

  final int rank;
  final String team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int points;
}
