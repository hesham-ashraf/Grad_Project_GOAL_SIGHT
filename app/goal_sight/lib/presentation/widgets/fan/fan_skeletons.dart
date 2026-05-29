import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/animations/gs_shimmer.dart';

// ─── Generic card skeleton ────────────────────────────────────────────────────

class FanCardSkeleton extends StatelessWidget {
  const FanCardSkeleton({super.key, this.height, this.borderRadius = 20});

  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GsShimmer.card(height: height ?? 80, radius: borderRadius);
  }
}

// ─── Grid skeleton ────────────────────────────────────────────────────────────

class FanHighlightsGridSkeleton extends StatelessWidget {
  const FanHighlightsGridSkeleton({
    super.key,
    required this.crossAxisCount,
  });

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final ratio = context.isPhone ? 1.1 : 1.3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: crossAxisCount * 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemBuilder: (_, __) => const FanCardSkeleton(borderRadius: 16),
    );
  }
}

// ─── Match list item skeleton ─────────────────────────────────────────────────

class MatchListSkeleton extends StatelessWidget {
  const MatchListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GsShimmer(
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Vs section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score section
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Player card skeleton ─────────────────────────────────────────────────────

class PlayerCardSkeleton extends StatelessWidget {
  const PlayerCardSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GsShimmer(
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceRaised,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 70,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge
                  Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats row skeleton ───────────────────────────────────────────────────────

class StatsRowSkeleton extends StatelessWidget {
  const StatsRowSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? 10 : 0),
            child: GsShimmer.card(height: 80, radius: 16),
          ),
        );
      }),
    );
  }
}

// ─── Full-page loading skeleton ───────────────────────────────────────────────

class FanHomeLoadingSkeleton extends StatelessWidget {
  const FanHomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Hero card
          GsShimmer.card(height: 180),
          const SizedBox(height: 20),
          // Stats row
          const StatsRowSkeleton(count: 3),
          const SizedBox(height: 20),
          // Section title
          GsShimmer.bar(width: 120, height: 14),
          const SizedBox(height: 14),
          // List items
          const MatchListSkeleton(itemCount: 3),
        ],
      ),
    );
  }
}
