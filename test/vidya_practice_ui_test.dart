import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/vidya_link.dart';
import 'package:udyoga/domain/vidya_practice.dart';
import 'package:interview_engine/interview_engine.dart' show Criterion, RoleProfile;
import 'package:udyoga/ui/applications_page.dart';
import 'package:udyoga/ui/interview_page.dart';
import 'package:udyoga/ui/job_page.dart';
import 'package:udyoga/ui/spoken_round_page.dart';
import 'package:udyoga/ui/today_page.dart';

import 'app_harness.dart';
import 'support.dart';
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

  for (final onApplication in [false, true]) {
    testWidgets(
      'a prepared job${onApplication ? '\'s application' : ''} shows Vidya\'s readiness per criterion',
      (tester) async {
        final app = AppHarness(tester)..phone();
        late String jobId, appId;
        await app.open(
          seed: (b) async {
            await b.saveProfile(sampleProfile);
            jobId = (await b.importPostings([samplePosting()], sampleProfile, today: '2026-11-15')).single;
            await b.saveRoleProfile(
              RoleProfile(
                id: '',
                title: 'Clinical Informatics Nurse',
                jobId: jobId,
                criteria: const [
                  Criterion(id: 'c1', text: 'Train ward staff on the EPR'),
                  Criterion(id: 'c2', text: 'Keep training records', essential: false),
                ],
              ),
              at: '2026-11-21T09:00',
            );
            final j = await (b.db.select(b.db.jobListings)..where((x) => x.id.equals(jobId))).getSingle();
            appId = await b.applyFor(j, today: '2026-11-16');
            await b.sendJobToVidya(j, now: '2026-11-21T09:00:00Z');
            await b.db
                .into(b.db.bridgeStudyProgress)
                .insert(
                  BridgeStudyProgressCompanion.insert(
                    id: jobPlanId(jobId),
                    progress: Value(
                      jsonEncode({
                        'learning': [],
                        'skills': [],
                        'readiness': [
                          {
                            'criterionId': 'c1',
                            'text': 'Train ward staff on the EPR',
                            'status': 'missing',
                            'essential': true,
                          },
                        ],
                      }),
                    ),
                    updated: '2026-11-21T10:00:00Z',
                  ),
                );
          },
        );
        await app.run(home: onApplication ? ApplicationPage(appId) : JobPage(jobId));
        await tester.scrollUntilVisible(
          find.text('Vidya readiness'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('Vidya readiness: 0 weak, 1 missing'), findsOneWidget);
        expect(find.textContaining('1 essential criterion becomes an interview drill'), findsOneWidget);
        expect(find.text('Train ward staff on the EPR (missing, essential)'), findsOneWidget);
        expect(find.text('Keep training records (covered)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await app.close();
      },
    );
  }
}
