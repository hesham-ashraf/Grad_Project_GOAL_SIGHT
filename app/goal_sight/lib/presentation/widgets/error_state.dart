import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: context.padAll(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: context.rs(36, min: 28, max: 46),
                color: Colors.redAccent,
              ),
              SizedBox(height: context.rs(8, min: 5, max: 12)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.sp(14, min: 12, max: 18)),
              ),
              if (onRetry != null) ...[
                SizedBox(height: context.rs(12, min: 8, max: 16)),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
