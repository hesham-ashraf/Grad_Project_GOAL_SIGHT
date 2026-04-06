import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive.dart';
import '../../../features/match/match_state.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Future<void> _showAddMatchDialog() async {
    final homeController = TextEditingController();
    final awayController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Match (Admin)'),
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
              child: const Text('Create Match'),
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
    Future.microtask(() {
      ref.read(adminControllerProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final adminState = ref.watch(adminControllerProvider);
    final systemAlerts = ref.watch(adminSystemAlertsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040B1E),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF040B1E),
        actions: [
          IconButton(
            onPressed: adminState.isSubmittingMatch ? null : _showAddMatchDialog,
            icon: adminState.isSubmittingMatch
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_box_rounded),
            color: Colors.white,
            tooltip: 'Add Match',
          ),
          TextButton.icon(
            onPressed: () => context.push('/admin-panel'),
            icon: const Icon(Icons.manage_accounts, color: Colors.white),
            label: const Text('Manage', style: TextStyle(color: Colors.white)),
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
              ref.read(adminControllerProvider.notifier).loadDashboard(),
          child: ListView(
            padding: context.padAll(20),
            children: [
              Text(
                'Welcome ${auth.user?.name ?? 'Admin'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.sp(28, min: 20, max: 36),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: context.rs(4, min: 2, max: 8)),
              Text(
                'Manage your platform from here',
                style: TextStyle(
                  color: const Color(0xFFA2B0CF),
                  fontSize: context.sp(13, min: 11, max: 17),
                ),
              ),
              SizedBox(height: context.rs(12, min: 8, max: 18)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed:
                        adminState.isSubmittingMatch ? null : _showAddMatchDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Match'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/admin-panel'),
                    icon: const Icon(Icons.table_view),
                    label: const Text('Open Management Tables'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF425F94)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.rs(18, min: 12, max: 24)),
              if (adminState.status == ViewStatus.loading)
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: context.rs(260, min: 200, max: 300)),
                  child: const LoadingState(),
                )
              else if (adminState.status == ViewStatus.error)
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: context.rs(260, min: 200, max: 300)),
                  child: ErrorState(
                    message:
                        adminState.errorMessage ?? 'Failed to load overview',
                    onRetry: () => ref
                        .read(adminControllerProvider.notifier)
                        .loadDashboard(),
                  ),
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      DashboardCard(
                        title: 'TOTAL USERS',
                        value: '${adminState.overview?.totalUsers ?? 0}',
                        icon: Icons.people,
                      ),
                      DashboardCard(
                        title: 'ACTIVE MATCHES',
                        value: '${adminState.overview?.activeMatches ?? 0}',
                        icon: Icons.wifi_tethering,
                      ),
                      DashboardCard(
                        title: 'TOTAL MATCHES',
                        value: '${adminState.overview?.totalMatches ?? 0}',
                        icon: Icons.sports_soccer,
                      ),
                      const DashboardCard(
                        title: 'SYSTEM STATUS',
                        value: 'GOOD',
                        icon: Icons.health_and_safety,
                      ),
                    ];

                    const spacing = 14.0;
                    final maxWidth = constraints.maxWidth;
                    final columns = maxWidth >= 1200
                        ? 4
                        : maxWidth >= 900
                            ? 3
                            : maxWidth >= 560
                                ? 2
                                : 1;
                    final cardWidth =
                        (maxWidth - (spacing * (columns - 1))) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: cards
                          .map(
                            (card) => SizedBox(
                              width: cardWidth,
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                SizedBox(height: context.rs(18, min: 12, max: 24)),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13243F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2C406D)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Alerts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...systemAlerts.map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  color: Color(0xFF8AB8FF),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    alert,
                                    style: const TextStyle(
                                      color: Color(0xFFD0DAF6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.rs(18, min: 12, max: 24)),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...adminState.users.take(6).map(
                              (user) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7257F5),
                                        Color(0xFF3F84F8)
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  '${user.name} registered a new account',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'moments ago',
                                  style: TextStyle(color: Color(0xFF8CA0CA)),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
