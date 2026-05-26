import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../widgets/admin/manager_list_card.dart';

class ManagersPage extends StatelessWidget {
  const ManagersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final managers = AdminMockData.managers;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Managers'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search managers...',
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
              itemCount: managers.length,
              itemBuilder: (context, index) {
                return ManagerListCard(manager: managers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
