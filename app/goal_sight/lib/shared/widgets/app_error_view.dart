// ---------------------------------------------------------------------------
// GoalSight — Reusable Error View
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_theme.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final appError = AppError.from(error);
    final (icon, color) = _iconForError(appError);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                appError.message,
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: Text('Retry',
                    style: AppTextStyles.body(color: AppColors.accentCyan)),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              appError.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.accentCyan,
                  side: const BorderSide(color: AppColors.outline),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (IconData, Color) _iconForError(AppError error) {
    return switch (error) {
      NetworkError() => (Icons.wifi_off_rounded, AppColors.warning),
      PermissionError() => (Icons.lock_outline_rounded, AppColors.danger),
      NotFoundError() => (Icons.search_off_rounded, AppColors.textMuted),
      StorageError() => (Icons.cloud_off_rounded, AppColors.warning),
      DatabaseError() => (Icons.storage_rounded, AppColors.danger),
      AuthError() => (Icons.person_off_outlined, AppColors.danger),
      UnknownError() => (Icons.error_outline_rounded, AppColors.textMuted),
    };
  }
}
