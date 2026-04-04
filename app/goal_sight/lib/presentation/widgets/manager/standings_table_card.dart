import 'package:flutter/material.dart';

import '../../../features/manager/standing_entry_model.dart';

class StandingsTableCard extends StatelessWidget {
  const StandingsTableCard({
    super.key,
    required this.standings,
  });

  final List<StandingEntryModel> standings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13243F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C406D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'League Standings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFF1A2E50)),
                dataRowColor: WidgetStateProperty.all(const Color(0xFF13243F)),
                columns: const [
                  DataColumn(label: _Th('#')),
                  DataColumn(label: _Th('Team')),
                  DataColumn(label: _Th('P')),
                  DataColumn(label: _Th('W')),
                  DataColumn(label: _Th('D')),
                  DataColumn(label: _Th('L')),
                  DataColumn(label: _Th('GF')),
                  DataColumn(label: _Th('GA')),
                  DataColumn(label: _Th('Pts')),
                ],
                rows: standings
                    .map(
                      (entry) => DataRow(cells: [
                        DataCell(_Td('${entry.rank}')),
                        DataCell(_Td(entry.team)),
                        DataCell(_Td('${entry.played}')),
                        DataCell(_Td('${entry.wins}')),
                        DataCell(_Td('${entry.draws}')),
                        DataCell(_Td('${entry.losses}')),
                        DataCell(_Td('${entry.goalsFor}')),
                        DataCell(_Td('${entry.goalsAgainst}')),
                        DataCell(_Td('${entry.points}', bold: true)),
                      ]),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF93A8D1),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _Td extends StatelessWidget {
  const _Td(this.value, {this.bold = false});

  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: Colors.white,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
