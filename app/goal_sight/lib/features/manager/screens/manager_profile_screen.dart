import 'package:flutter/material.dart';

import '../widgets/manager_screen_placeholder.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManagerScreenPlaceholder(
      title: 'Profile',
      subtitle: 'Manager account settings, club details, and preferences will appear here.',
    );
  }
}
