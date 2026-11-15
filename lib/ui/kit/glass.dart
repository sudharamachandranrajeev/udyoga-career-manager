import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../look.dart';

/// Frosted glass: blurs what is behind it and lays a see-through surface
/// with a hairline edge on top. For things that float over content.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = Radii.pill, this.padding = EdgeInsets.zero});
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = palette(Theme.of(context).brightness);
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.72),
            borderRadius: shape,
            border: Border.all(color: p.hairline),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
