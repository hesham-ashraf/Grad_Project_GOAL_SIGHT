import 'package:flutter/material.dart';

import '../widgets/manager_screen_placeholder.dart';

class ManagerMatchesScreen extends StatelessWidget {
  const ManagerMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManagerScreenPlaceholder(
      title: 'Matches & Analysis',
      subtitle: 'Recent uploaded matches and AI analysis results will be shown here.',
    );
  }
}
