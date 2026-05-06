import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class ManagerScreenPlaceholder extends StatelessWidget {
  const ManagerScreenPlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: context.padSym(h: 20, v: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: AppColors.outlineSubtle,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Padding(
                  padding: AppSpacing.card,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        color: AppColors.accentCyan,
                        size: context.rs(32, min: 26, max: 40),
                      ),
                      SizedBox(height: context.rs(12, min: 10, max: 16)),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title(),
                      ),
                      SizedBox(height: context.rs(8, min: 6, max: 12)),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
