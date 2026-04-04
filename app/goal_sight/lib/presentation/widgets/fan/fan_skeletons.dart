import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FanCardSkeleton extends StatelessWidget {
  const FanCardSkeleton({
    super.key,
    this.height = 120,
    this.borderRadius = 18,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF171A2D),
      highlightColor: const Color(0xFF252A45),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF171A2D),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class FanHighlightsGridSkeleton extends StatelessWidget {
  const FanHighlightsGridSkeleton({super.key, required this.crossAxisCount});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: crossAxisCount * 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, __) =>
          const FanCardSkeleton(height: 160, borderRadius: 16),
    );
  }
}
