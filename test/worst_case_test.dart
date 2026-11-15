import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/jobs_page.dart';
import 'package:udyoga/ui/today_hero.dart';

import 'app_harness.dart';
import 'seed.dart';

/// Today and Jobs over the worst a real book could hold (see
/// [seedWorstCase]), at the narrowest phone, a common phone and a desktop.
/// The view is tall so the whole page lays out at once: any text that
/// spills out of its box fails the test with an overflow error.
void main() {
  for (final width in [320.0, 360.0, 1400.0]) {
    testWidgets('worst-case data lays out at $width wide', (tester) async {
      tester.view.physicalSize = Size(width, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(tester);
      await app.open(seed: seedWorstCase);
      await app.run();

      expect(find.byType(TodayHero), findsOneWidget);
      // Each "Needs you" card lists a few and links to the rest, so 32
      // follow-ups don't bury the page.
      expect(find.text('Follow up today'), findsWidgets);
      expect(find.text('See all 32'), findsOneWidget);
      // Pay in the millions reads as millions.
      expect(find.textContaining('£1.3m'), findsWidgets);
      expect(tester.takeException(), isNull);

      await app.go('Jobs');
      expect(find.byType(JobTile), findsWidgets);
      expect(find.text('₹2.5m–4.8m'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await app.close();
    });
  }
}
