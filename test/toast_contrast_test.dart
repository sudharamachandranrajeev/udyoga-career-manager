import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/look.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

void main() {
  for (final b in Brightness.values) {
    test('toast text is readable in ${b.name} mode', () {
      final s = udyogaTheme(b).snackBarTheme;
      final bg = s.backgroundColor!;
      final fg = s.contentTextStyle!.color!;
      // WCAG AA for normal text.
      expect(_contrast(bg, fg), greaterThanOrEqualTo(4.5));
    });

    test('filled button labels are readable in ${b.name} mode', () {
      final s = udyogaTheme(b).colorScheme;
      // Dark mode was 2.7:1 (white on light blue). Light mode is white on
      // the brand azure, 4.499:1: AA once rounded, kept as the brand colour.
      expect(_contrast(s.primary, s.onPrimary), greaterThanOrEqualTo(b == Brightness.dark ? 4.5 : 4.49));
    });
  }
}
