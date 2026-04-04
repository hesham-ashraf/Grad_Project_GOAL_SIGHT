import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_roles.dart';
import '../../../features/match/match_state.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  Future<void> _showAddMatchDialog() async {
    final homeController = TextEditingController();
    final awayController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Match'),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(adminControllerProvider.notifier).addMatch(
                      homeTeam: homeController.text,
                      awayTeam: awayController.text,
                    );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    homeController.dispose();
    awayController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(adminControllerProvider.notifier).loadDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040B1E),
      appBar: AppBar(
        title: const Text('Admin Management'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF040B1E),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF8FA3CC),
          indicatorColor: const Color(0xFF5D73F6),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Matches'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040B1E), Color(0xFF081632), Color(0xFF040B1E)],
          ),
        ),
        child: state.status == ViewStatus.loading
            ? const LoadingState()
            : state.status == ViewStatus.error
                ? ErrorState(
                    message: state.errorMessage ?? 'Failed to load admin data',
                    onRetry: () => ref
                        .read(adminControllerProvider.notifier)
                        .loadDashboard(),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ManagementTable(
                        title: 'Users Management',
                        subtitle: 'Manage platform users and permissions',
                        columns: const [
                          'ID',
                          'NAME',
                          'EMAIL',
                          'ROLE',
                          'STATUS'
                        ],
                        rows: state.users
                            .asMap()
                            .entries
                            .map(
                              (entry) => [
                                '#${entry.key + 1}',
                                entry.value.name,
                                entry.value.email,
                                entry.value.role.label.toUpperCase(),
                                'ACTIVE',
                              ],
                            )
                            .toList(),
                      ),
                      _ManagementTable(
                        title: 'Matches Management',
                        subtitle: 'Schedule and manage football matches',
                        onAddPressed: _showAddMatchDialog,
                        columns: const [
                          'ID',
                          'HOME TEAM',
                          'AWAY TEAM',
                          'STATUS',
                          'SCORE'
                        ],
                        rows: state.matches
                            .asMap()
                            .entries
                            .map(
                              (entry) => [
                                '#${entry.key + 1}',
                                entry.value.homeTeam,
                                entry.value.awayTeam,
                                entry.value.status.toUpperCase(),
                                entry.value.score,
                              ],
                            )
                            .toList(),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ManagementTable extends StatelessWidget {
  const _ManagementTable({
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.onAddPressed,
  });

  final String title;
  final String subtitle;
  final List<String> columns;
  final List<List<String>> rows;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF8EA3CD)),
              ),
              if (onAddPressed != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Match'),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFF1A2E50)),
                    dataRowColor:
                        WidgetStateProperty.all(const Color(0xFF13243F)),
                    columns: columns
                        .map(
                          (column) => DataColumn(
                            label: Text(
                              column,
                              style: const TextStyle(
                                color: Color(0xFF93A8D1),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    rows: rows
                        .map(
                          (row) => DataRow(
                            cells: row
                                .map(
                                  (cell) => DataCell(
                                    Text(
                                      cell,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                                .toList(),
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
