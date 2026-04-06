import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/match/match_state.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/manager/standings_table_card.dart';
import '../../widgets/manager/team_member_card.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchControllerProvider.notifier).loadMatches();
    });
  }

  Future<void> _showUploadDialog() async {
    final homeController = TextEditingController();
    final awayController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Match'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: homeController,
                decoration: const InputDecoration(labelText: 'Home Team'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: awayController,
                decoration: const InputDecoration(labelText: 'Away Team'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(matchControllerProvider.notifier).uploadMatch(
                      homeTeam: homeController.text.trim(),
                      awayTeam: awayController.text.trim(),
                    );
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Save Match'),
            ),
          ],
        );
      },
    );

    homeController.dispose();
    awayController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(matchControllerProvider);
    final teamMembers = ref.watch(teamMembersProvider);
    final standings = ref.watch(leagueStandingsProvider);
    final teamName = ref.watch(coachTeamNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040B1E),
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF040B1E),
        actions: [
          IconButton(
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.add_box_outlined),
            color: Colors.white,
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040B1E), Color(0xFF081632), Color(0xFF040B1E)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(matchControllerProvider.notifier).loadMatches(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Coach View: ${auth.user?.name ?? 'Manager'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Head coach of $teamName • track squad and match performance',
                style: const TextStyle(color: Color(0xFFA2B0CF)),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardCard(
                    title: 'MATCHES',
                    value: '${state.matches.length}',
                    icon: Icons.sports_soccer,
                  ),
                  DashboardCard(
                    title: 'LIVE EVENTS',
                    value:
                        '${state.matches.where((m) => m.status == 'live').length}',
                    icon: Icons.flash_on,
                  ),
                  const DashboardCard(
                    title: 'PASS ACCURACY',
                    value: '83%',
                    icon: Icons.track_changes,
                  ),
                  DashboardCard(
                    title: 'TEAM HEALTH',
                    value:
                        '${(teamMembers.fold<int>(0, (a, b) => a + b.stamina) / teamMembers.length).round()}%',
                    icon: Icons.favorite,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Team Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 172,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: teamMembers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final player = teamMembers[index];
                    return TeamMemberCard(
                      player: player,
                      onTap: () => context.push('/player/${player.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              StandingsTableCard(standings: standings),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _showUploadDialog,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Match'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/manager-panel'),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Open Analytics Panel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF425F94)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Matches Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (state.status == ViewStatus.loading)
                const SizedBox(height: 220, child: LoadingState())
              else if (state.status == ViewStatus.error)
                SizedBox(
                  height: 220,
                  child: ErrorState(
                    message: state.errorMessage ?? 'Failed to load matches',
                    onRetry: () => ref
                        .read(matchControllerProvider.notifier)
                        .loadMatches(),
                  ),
                )
              else
                Container(
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF1A2E50),
                      ),
                      dataRowColor: WidgetStateProperty.all(
                        const Color(0xFF13243F),
                      ),
                      columns: const [
                        DataColumn(label: _TableHeading('HOME TEAM')),
                        DataColumn(label: _TableHeading('AWAY TEAM')),
                        DataColumn(label: _TableHeading('STATUS')),
                        DataColumn(label: _TableHeading('ACTIONS')),
                      ],
                      rows: state.matches
                          .map(
                            (match) => DataRow(
                              cells: [
                                DataCell(_TableCell(match.homeTeam)),
                                DataCell(_TableCell(match.awayTeam)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0x223F84F8),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: const Color(0xFF3F84F8),
                                      ),
                                    ),
                                    child: Text(
                                      match.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF8AB8FF),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            context.push('/match/${match.id}'),
                                        icon: const Icon(Icons.edit_outlined),
                                        color: Colors.white,
                                      ),
                                      IconButton(
                                        onPressed: () => context
                                            .push('/live-match/${match.id}'),
                                        icon: const Icon(Icons.wifi_tethering),
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  const _TableHeading(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF93A8D1),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(color: Colors.white),
    );
  }
}
