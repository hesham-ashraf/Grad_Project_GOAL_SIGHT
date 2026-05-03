import 'package:flutter/material.dart';

import '../widgets/manager_screen_placeholder.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManagerScreenPlaceholder(
      title: 'Players',
      subtitle: 'Squad list, player profiles, and performance snapshots will live here.',
    );
  }
}
