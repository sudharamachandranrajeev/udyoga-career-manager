import 'package:brahma_core/brahma_core.dart' show Motion;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../look.dart';

/// A placeholder block where content is loading, with a soft light passing
/// over it. Under reduced motion it is a still block.
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({super.key, this.width, this.height = 14, this.radius = Radii.sm});
  final double? width;
  final double height, radius;

  /// A paragraph's worth of lines, the last one shorter.
  static Widget lines(int count, {double height = 12, double gap = 8}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : gap),
          child: FractionallySizedBox(
            widthFactor: i == count - 1 && count > 1 ? 0.6 : 1,
            child: ShimmerSkeleton(height: height),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = palette(Theme.of(context).brightness);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: p.raised, borderRadius: BorderRadius.circular(radius)),
    );
    if (Motion.reduced(context)) return block;
    // A loading state's loop is constant motion, so it runs linearly.
    return block
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          curve: Curves.linear,
          color: dark ? const Color(0x14FFFFFF) : const Color(0x99FFFFFF),
        );
  }
}

/// Cards standing in for a list while it loads: a mark, a title and two
/// lines each, the shape of the job and application cards.
class SkeletonCards extends StatelessWidget {
  const SkeletonCards({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = palette(Theme.of(context).brightness);
    return Semantics(
      label: 'Loading',
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: p.hairline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSkeleton(width: 44, height: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FractionallySizedBox(widthFactor: 0.7, child: ShimmerSkeleton(height: 16)),
                        const SizedBox(height: 10),
                        ShimmerSkeleton.lines(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
