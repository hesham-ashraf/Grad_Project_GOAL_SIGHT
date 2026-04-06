import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/responsive.dart';

class FanCardSkeleton extends StatelessWidget {
  const FanCardSkeleton({
    super.key,
    this.height,
    this.borderRadius = 18,
  });

  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF171A2D),
      highlightColor: const Color(0xFF252A45),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF171A2D),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
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
