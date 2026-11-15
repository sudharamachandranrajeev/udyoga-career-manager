import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart' show Motion;
import 'package:flutter/material.dart';

import '../look.dart';

/// A short beam of light travelling round its child's rounded border, after
/// Magic UI's Border Beam. Kept for the one card that most needs noticing
/// (the next deadline); under reduced motion the beam stands still.
class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    this.radius = Radii.lg,
    this.width = 1.5,
    this.period = const Duration(seconds: 6),
    this.colors,
  });

  final Widget child;
  final double radius;

  /// The stroke width of the beam.
  final double width;

  /// One full lap.
  final Duration period;

  /// The beam's colours from tail to head; azure into mint by default.
  final List<Color>? colors;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam> with SingleTickerProviderStateMixin {
  late final _lap = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _lap.stop();
    } else if (!_lap.isAnimating) {
      // Constant motion, so linear: easing would make the beam surge.
      _lap.repeat();
    }
  }

  @override
  void dispose() {
    _lap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      foregroundPainter: BeamPainter(
        _lap,
        radius: widget.radius,
        width: widget.width,
        colors: widget.colors ?? [primary, mint],
      ),
      child: widget.child,
    );
  }
}

/// Paints the beam: a sweep gradient, mostly transparent, turned by [lap]
/// and stroked along the rounded rectangle.
class BeamPainter extends CustomPainter {
  BeamPainter(this.lap, {required this.radius, required this.width, required this.colors})
    : super(repaint: lap);
  final Animation<double> lap;
  final double radius, width;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(math.max(0, radius - width / 2)),
    );
    final clear = colors.first.withValues(alpha: 0);
    final shader = SweepGradient(
      colors: [clear, ...colors, clear],
      stops: [0, for (var i = 0; i < colors.length; i++) 0.06 + 0.12 * i / colors.length, 0.2],
      transform: GradientRotation(lap.value * 2 * math.pi),
    ).createShader(rect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(BeamPainter old) =>
      old.radius != radius || old.width != width || old.colors != colors || old.lap != lap;
}
