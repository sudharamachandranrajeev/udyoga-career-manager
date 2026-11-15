import 'package:flutter/material.dart';

/// A quiet grid of dots behind content, after Magic UI's Dot Pattern: for
/// empty states and hero areas. It fades out towards the edges so it never
/// ends on a hard line. Static: it never moves.
class DotGrid extends StatelessWidget {
  const DotGrid({super.key, this.child, this.spacing = 18, this.dotRadius = 1, this.color, this.fade = true});
  final Widget? child;

  /// Distance between dot centres.
  final double spacing;
  final double dotRadius;

  /// The dots' colour; a faint version of the text colour by default.
  final Color? color;

  /// Fades the grid out from the centre to the edges.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dots = color ?? (dark ? const Color(0x24FFFFFF) : const Color(0x1F0B1020));
    Widget grid = CustomPaint(
      painter: DotGridPainter(spacing: spacing, radius: dotRadius, color: dots),
      size: Size.infinite,
    );
    if (fade) {
      grid = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const RadialGradient(
          radius: 0.75,
          colors: [Color(0xFF000000), Color(0x00000000)],
        ).createShader(r),
        child: grid,
      );
    }
    return Stack(
      children: [
        Positioned.fill(child: IgnorePointer(child: grid)),
        ?child,
      ],
    );
  }
}

class DotGridPainter extends CustomPainter {
  DotGridPainter({required this.spacing, required this.radius, required this.color});
  final double spacing, radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.spacing != spacing || old.radius != radius || old.color != color;
}
