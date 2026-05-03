import 'package:flutter/material.dart';

import '../widgets/manager_screen_placeholder.dart';

class UploadMatchScreen extends StatelessWidget {
  const UploadMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManagerScreenPlaceholder(
      title: 'Upload Match',
      subtitle: 'Upload full match footage to start AI-powered tactical analysis.',
    );
  }
}
