import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../widgets/admin/player_analytics_card.dart';

class SquadOverviewPage extends StatelessWidget {
  const SquadOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final squad = AdminMockData.squad;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Squad Overview'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search player...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
              itemCount: squad.length,
              itemBuilder: (context, index) {
                return PlayerAnalyticsCard(player: squad[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
