import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
  });

  final String message;
  final String? title;
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
              // ── Icon container ──────────────────────────────────────────────
              Container(
                width: context.rs(64, min: 52, max: 76),
                height: context.rs(64, min: 52, max: 76),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: context.rs(30, min: 24, max: 36),
                  color: AppColors.danger,
                ),
              ),

              SizedBox(height: context.rs(16, min: 12, max: 20)),

              // ── Title ───────────────────────────────────────────────────────
              Text(
                title ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                  fontSize: context.sp(16, min: 14, max: 18),
                ),
              ),

              SizedBox(height: context.rs(6, min: 4, max: 8)),

              // ── Message ─────────────────────────────────────────────────────
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                  fontSize: context.sp(13, min: 12, max: 15),
                  height: 1.5,
                ),
              ),

              // ── Retry button ─────────────────────────────────────────────────
              if (onRetry != null) ...[
                SizedBox(height: context.rs(20, min: 14, max: 26)),
                SizedBox(
                  height: context.rs(40, min: 36, max: 46),
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: context.rs(16, min: 14, max: 18),
                      color: AppColors.danger,
                    ),
                    label: Text(
                      'Try Again',
                      style: AppTextStyles.button(color: AppColors.danger).copyWith(
                        fontSize: context.sp(13, min: 12, max: 15),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.button,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(20, min: 16, max: 24),
                      ),
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
