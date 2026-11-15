import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadBorder, ShadCard;

import '../look.dart';

/// A card with a soft glow that follows the mouse, after Magic UI's Magic
/// Card. Only a mouse moves it: on a touch screen the card stays plain.
class SpotlightCard extends StatefulWidget {
  const SpotlightCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = Radii.lg,
    this.glowRadius = 220,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// How far the glow spreads from the pointer.
  final double glowRadius;

  /// The glow's colour; the theme's primary by default.
  final Color? color;

  @override
  State<SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<SpotlightCard> {
  // The last mouse position stays put while the glow fades out.
  Offset? _pointer;
  var _shown = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = (widget.color ?? scheme.primary).withValues(alpha: dark ? 0.16 : 0.1);
    return MouseRegion(
      onHover: (e) {
        if (e.kind != PointerDeviceKind.mouse) return;
        setState(() {
          _pointer = e.localPosition;
          _shown = true;
        });
      },
      onExit: (_) => setState(() => _shown = false),
      child: ShadCard(
        padding: EdgeInsets.zero,
        radius: BorderRadius.circular(widget.radius),
        // An explicit width: shadcn draws no border when it is left null.
        border: ShadBorder.all(color: scheme.outlineVariant, width: 1),
        shadows: const [],
        backgroundColor: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _shown ? 1 : 0,
                  duration: paced(context, Pace.fast),
                  curve: Ease.out,
                  child: CustomPaint(painter: _Glow(_pointer, widget.glowRadius, glow)),
                ),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _Glow extends CustomPainter {
  _Glow(this.at, this.radius, this.color);
  final Offset? at;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = at;
    if (c == null) return;
    final rect = Rect.fromCircle(center: c, radius: radius);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Glow old) => old.at != at || old.color != color || old.radius != radius;
}
