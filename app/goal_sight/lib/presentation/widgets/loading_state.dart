import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: context.rs(28, min: 20, max: 34),
            height: context.rs(28, min: 20, max: 34),
            child: const CircularProgressIndicator(),
          ),
          SizedBox(height: context.rs(12, min: 8, max: 16)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.sp(14, min: 12, max: 18)),
          ),
        ],
      ),
    );
  }
}
