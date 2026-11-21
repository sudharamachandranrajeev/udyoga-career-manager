import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/vidya_practice.dart';
import 'package:udyoga/ui/interview_page.dart';
import 'package:udyoga/ui/spoken_round_page.dart';
import 'package:udyoga/ui/today_page.dart';

import 'app_harness.dart';
import 'spoken_round_ui_test.dart' show FakeEngines;

/// Vidya's two requests (its fixture), as they arrive through sync.
Future<void> _requests(CareerBook b) => b.db
    .into(b.db.bridgeStudyProgress)
    .insert(
      BridgeStudyProgressCompanion.insert(
        id: practiseRequestsId,
        progress: Value(File('test/fixtures/vidya-practise-requests.json').readAsStringSync()),
        updated: '2026-11-21T10:00:00Z',
      ),
    );

void main() {
  testWidgets('on a phone the Interview page lists what Vidya asked to practise; a tap starts the round', (
    tester,
  ) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: _requests);
    await app.run(
      home: const InterviewPage(),
      overrides: [spokenEnginesProvider.overrideWith((ref) async => FakeEngines())],
    );
    expect(find.text('From Vidya'), findsOneWidget);
    expect(
      find.text('Vidya asked you to practise: Tell me about a time a learner got angry.'),
      findsOneWidget,
    );
    expect(
      find.text('Vidya asked you to practise: Tell me about a time you taught a new system.'),
      findsOneWidget,
    );
    expect(find.textContaining('Tests: Handle a difficult learner calmly · Example Trainer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await app.tap(find.byKey(const ValueKey('vidya.request.vidya-drill-q2')));
    expect(find.byType(SpokenRoundPage), findsOneWidget);
    expect(find.text('Start the round'), findsOneWidget);
    // Leaving without an answer sends nothing to Vidya and says so.
    await tester.pageBack();
    await app.settle();
    expect(find.textContaining('Nothing was answered, so no score went to Vidya'), findsOneWidget);
    final results = await tester.runAsync(() => app.book.practiseResults());
    expect(results, isEmpty);
    expect(find.text('From Vidya'), findsOneWidget, reason: 'still pending');
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('Today points to the Interview page while Vidya\'s requests wait', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: _requests);
    await app.run(home: const TodayPage());
    expect(find.text('Vidya asked you to practise 2 interview questions aloud.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
