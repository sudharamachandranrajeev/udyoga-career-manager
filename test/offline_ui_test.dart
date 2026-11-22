import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/app/interview_providers.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/ollama.dart';
import 'package:udyoga/ui/interview_debrief_page.dart';
import 'package:udyoga/ui/spoken_round_page.dart';

import 'app_harness.dart';
import 'interview_device_ui_test.dart' show Cloud;
import 'spoken_round_ui_test.dart' show FakeEngines;

/// Ollama absent: nothing listens.
Ollama _absent(OllamaSetup s) => Ollama(
  host: s.host,
  model: s.model,
  client: MockClient((_) async => throw http.ClientException('Connection refused')),
);

void main() {
  final guard = OfflineGuard.instance;

  testWidgets('offline round: the badge holds the guard, downloads are off, plans are built in, no cloud', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (b) async {
        await b.setInterviewDevice(const InterviewDevice(offline: true));
        id = await b.startPractice(
          role: 'Common questions',
          mode: 'standard',
          questions: commonQuestions.take(1).toList(),
          at: '2026-11-19T10:00',
        );
      },
    );
    final cloud = Cloud();
    var engines = FakeEngines(missingIds: [defaultTranscriber]);
    final overrides = [
      advisorProvider.overrideWith((ref) async => Advisor(cloud, today: '2026-11-19')),
      ollamaFactoryProvider.overrideWithValue(_absent),
      spokenEnginesProvider.overrideWith((ref) async => engines),
    ];
    await app.run(home: SpokenRoundPage(id), overrides: overrides);
    expect(find.text('Offline'), findsOneWidget);
    expect(guard.active, isTrue);
    expect(find.text(offlineDownloadMessage), findsOneWidget);
    expect(find.textContaining('Download '), findsNothing, reason: 'no download button in offline practice');

    await tester.pumpWidget(const SizedBox());
    expect(guard.active, isFalse, reason: 'released when the screen closes');
    engines = FakeEngines();
    await app.run(home: SpokenRoundPage(id), overrides: overrides);
    await app.tapText('Start the round');
    expect(find.textContaining('Built-in follow-ups'), findsOneWidget);
    await app.tapText('Ask me');
    await app.tapText('Done');
    expect(find.textContaining('Offline practice: feedback on what you said needs Ollama'), findsOneWidget);
    expect(find.text('How you said it'), findsOneWidget, reason: 'delivery comes from this device');
    expect(cloud.asked, 0);
    await app.close();
    expect(guard.active, isFalse);
  });

  testWidgets('offline debrief without any AI: coverage from this device, no scoring button', (tester) async {
    final app = AppHarness(tester)..desktop();
    late String round;
    await app.open(
      seed: (book) async {
        await book.setInterviewDevice(const InterviewDevice(offline: true));
        final id = await book.saveRoleProfile(
          const RoleProfile(
            id: '',
            title: 'Practice administrator',
            frameworkId: 'nhs_values',
            criteria: [Criterion(id: 'c1', text: 'Experience of managing a busy diary')],
          ),
          at: '2026-11-19T10:00',
        );
        round = await book.startProfileRound((await book.roleProfile(id))!, at: '2026-11-19T10:00');
        await book.saveTranscript(
          round,
          1,
          'In my last role the diary was double-booked. I rang each patient and I moved the overflow, and as a '
          'result the double bookings fell from nine a week to one.',
          at: '2026-11-19T10:00',
        );
      },
    );
    final cloud = Cloud();
    await app.run(
      home: DebriefPage(round),
      overrides: [
        advisorProvider.overrideWith((ref) async => Advisor(cloud, today: '2026-11-19')),
        ollamaFactoryProvider.overrideWithValue(_absent),
      ],
    );
    expect(find.text('Offline'), findsOneWidget);
    expect(guard.active, isTrue);
    expect(find.textContaining('Coverage from the words on this device'), findsOneWidget);
    expect(find.text('Evidenced'), findsOneWidget);
    expect(
      find.textContaining('Score with my AI'),
      findsNothing,
      reason: 'the cloud AI is never offered offline',
    );
    expect(cloud.asked, 0);
    await app.close();
    expect(guard.active, isFalse);
  });

  testWidgets('the switch on the Interview page turns offline practice on and off, badge with it', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run(overrides: [ollamaFactoryProvider.overrideWithValue(_absent)]);
    await app.go('Interview');
    expect(find.text('Offline'), findsNothing);
    final toggle = find.widgetWithText(SwitchListTile, 'Offline interview practice');
    await app.tap(toggle);
    expect(find.text('Offline'), findsOneWidget);
    expect(guard.active, isTrue);
    expect(find.textContaining('Ollama is not running at http://localhost:11434'), findsWidgets);
    expect((await tester.runAsync(() => app.book.interviewDevice()))!.offline, isTrue);
    await app.tap(toggle);
    expect(find.text('Offline'), findsNothing);
    expect(guard.active, isFalse);
    await app.close();
  });
}
