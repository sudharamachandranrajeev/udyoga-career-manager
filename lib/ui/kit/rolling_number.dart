import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../look.dart';

/// A number whose digits roll into place when it changes, after NumberFlow:
/// each digit turns on its own wheel, in the direction the number moved, and
/// tabular figures keep every digit the same width so nothing shifts
/// sideways. At rest, and under reduced motion, it is plain text.
class RollingNumber extends StatefulWidget {
  const RollingNumber(
    this.value, {
    super.key,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.showSign = false,
    this.fractionDigits = 0,
    this.duration = Pace.slow,
  });

  final num value;
  final TextStyle? style;

  /// Text before and after the digits, e.g. "£" and " a year".
  final String prefix, suffix;

  /// Shows "+" before a positive number (a negative one always has "−").
  final bool showSign;
  final int fractionDigits;
  final Duration duration;

  /// The text shown at rest, e.g. "+£1,250".
  static String format(
    num value, {
    String prefix = '',
    String suffix = '',
    bool showSign = false,
    int fractionDigits = 0,
  }) {
    final digits = NumberFormat.decimalPatternDigits(locale: 'en_GB', decimalDigits: fractionDigits);
    final sign = value < 0 ? '−' : (showSign && value > 0 ? '+' : '');
    return '$sign$prefix${digits.format(value.abs())}$suffix';
  }

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this);

  /// The text rolled away from, while rolling.
  String? _from;
  var _up = true;

  String _text(RollingNumber w) => RollingNumber.format(
    w.value,
    prefix: w.prefix,
    suffix: w.suffix,
    showSign: w.showSign,
    fractionDigits: w.fractionDigits,
  );

  @override
  void didUpdateWidget(RollingNumber old) {
    super.didUpdateWidget(old);
    final before = _text(old);
    if (before == _text(widget)) return;
    final length = paced(context, widget.duration);
    if (length == Duration.zero) {
      _turn.stop();
      _from = null;
      return;
    }
    // Interrupted mid-roll: the new roll starts from where the digits stand
    // on their way, which is near enough the old value to read as one move.
    _from = before;
    _up = widget.value >= old.value;
    _turn
      ..duration = length
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style).merge(figures);
    final text = _text(widget);
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, _) {
        final from = _from;
        if (from == null || !_turn.isAnimating) return Text(text, style: style, maxLines: 1);
        return Semantics(
          label: text,
          child: ExcludeSemantics(
            child: _rolling(context, from, text, Ease.out.transform(_turn.value), style),
          ),
        );
      },
    );
  }

  Widget _rolling(BuildContext context, String from, String to, double t, TextStyle style) {
    final height = (TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).height;
    // Digits pair up from the right, ignoring separators, so 999 to 1,000
    // turns each wheel rather than sliding the comma.
    final old = [
      for (final ch in from.split('').reversed)
        if (_isDigit(ch)) int.parse(ch),
    ];
    final cells = <Widget>[];
    var k = 0;
    for (final ch in to.split('').reversed) {
      if (!_isDigit(ch)) {
        cells.add(Text(ch, style: style));
        continue;
      }
      final target = int.parse(ch);
      final start = k < old.length ? old[k] : null;
      k++;
      cells.add(
        _Wheel(
          position: _position(start ?? 0, target, t),
          height: height,
          style: style,
          // A digit the old number did not have fades in as it rolls.
          opacity: start == null ? t : 1,
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: cells.reversed.toList());
  }

  /// Where a wheel of two turns (0-9 then 0-9 again) stands: it always moves
  /// the way the number moved, wrapping round rather than reversing.
  double _position(int from, int to, double t) {
    final (start, end) = _up ? (from, to >= from ? to : to + 10) : (from < to ? from + 10 : from, to);
    return start + (end - start) * t;
  }

  static bool _isDigit(String ch) => '0123456789'.contains(ch);
}

/// One digit's wheel, clipped to a single digit's height.
class _Wheel extends StatelessWidget {
  const _Wheel({required this.position, required this.height, required this.style, this.opacity = 1});
  final double position, height, opacity;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity.clamp(0, 1),
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Sizes the cell to one digit; tabular figures are all this wide.
        Opacity(opacity: 0, child: Text('0', style: style)),
        Positioned(
          left: 0,
          right: 0,
          top: -position * height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 20; i++)
                SizedBox(
                  height: height,
                  child: Text('${i % 10}', style: style, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
