import 'dart:ui' show ImageFilter;

import 'package:brahma_core/brahma_core.dart' show Motion;
import 'package:flutter/material.dart';

import '../look.dart';

/// Brings its child in once, when first built: rising 8 pixels while it
/// fades in and comes into focus, after Magic UI's Blur Fade. [index] staggers
/// a list so items arrive one after another, 40 ms apart, capped so a long
/// list does not keep the last items waiting. Under reduced motion the child
/// simply shows.
class BlurFadeIn extends StatefulWidget {
  const BlurFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 40),
    this.duration = Pace.slow,
    this.rise = 8,
    this.blur = 4,
  });

  final Widget child;

  /// The item's place in a list, for the stagger.
  final int index;
  final Duration stagger, duration;

  /// How far below its place the child starts, in pixels.
  final double rise;

  /// How blurred it starts (the blur's sigma).
  final double blur;

  /// Items after this many arrive together.
  static const maxStagger = 8;

  @override
  State<BlurFadeIn> createState() => _BlurFadeInState();
}

class _BlurFadeInState extends State<BlurFadeIn> with SingleTickerProviderStateMixin {
  AnimationController? _in;
  late Animation<double> _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in != null || Motion.reduced(context)) return;
    // The wait is part of the controller's run (an interval), so there is no
    // timer to outlive the widget.
    final wait = widget.stagger * widget.index.clamp(0, BlurFadeIn.maxStagger);
    final total = wait + widget.duration;
    final c = _in = AnimationController(vsync: this, duration: total)..forward();
    _t = CurvedAnimation(
      parent: c,
      curve: Interval(wait.inMicroseconds / total.inMicroseconds, 1, curve: Ease.out),
    );
  }

  @override
  void dispose() {
    _in?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_in == null) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        if (t >= 1) return child!;
        final sigma = (1 - t) * widget.blur;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.rise),
            child: sigma < 0.05
                ? child
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: child,
                  ),
          ),
        );
      },
    );
  }
}
