// ---------------------------------------------------------------------------
// GoalSight — Heatmap Image
//
// Renders a model-produced heatmap PNG from a URL with loading, error and
// rounded-frame styling. Used by the match analysis HeatmapCard and the player
// profile's per-match heatmap gallery.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class GsHeatmapImage extends StatelessWidget {
  const GsHeatmapImage({
    super.key,
    required this.url,
    this.height = 200,
    this.width,
  });

  final String url;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: height,
        width: width,
        color: AppColors.surface,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
            );
          },
          errorBuilder: (context, _, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_outlined,
                    color: AppColors.textMuted, size: 26),
                const SizedBox(height: 6),
                Text(
                  'Heatmap unavailable',
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
