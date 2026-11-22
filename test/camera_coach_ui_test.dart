import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:interview_engine/testing.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/ui/camera_coach_ui.dart';
import 'package:udyoga/ui/spoken_round_page.dart';

import 'app_harness.dart';
import 'spoken_round_ui_test.dart' show FakeEngines;

void main() {
  /// Runs a one-question spoken round, with the camera coach on and fed
  /// [frames] before the start when [camera] is set, and returns what the
  /// round saved: every answer's text, review and score, the round's score
  /// and debrief, and the outbox (what sync would send).
  Future<(List<Object?>, String)> round(
    WidgetTester tester, {
    FakeCamera? camera,
    List<FrameMeasure>? frames,
  }) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (b) async => id = await b.startPractice(
        role: 'Common questions',
        mode: 'standard',
        questions: commonQuestions.take(1).toList(),
        at: '2026-11-19T10:00',
      ),
    );
    await app.run(
      home: SpokenRoundPage(id),
      overrides: [
        spokenEnginesProvider.overrideWith((ref) async => FakeEngines()),
        coachCameraProvider.overrideWith((ref) async => camera ?? FakeCamera()),
      ],
    );
    // Off at the start: no pill, the offer to turn it on.
    expect(find.text('Camera on'), findsNothing);
    expect(find.text('Turn the camera on'), findsOneWidget);
    if (frames != null) {
      await app.tapText('Turn the camera on');
      expect(find.text('Camera on'), findsOneWidget);
      for (final f in frames) {
        camera!.feeds.last.value.value = f;
      }
      await tester.pump();
    }
    await app.tapText('Start the round');
    if (frames != null) expect(find.text('Camera on'), findsOneWidget, reason: 'the pill stays in the round');
    await app.tapText('Ask me');
    await app.tapText('Done');
    if (find.text('Move on').evaluate().isNotEmpty) await app.tapText('Move on');
    await app.tapText('Finish');
    expect(find.textContaining('You answered 1 of 1'), findsOneWidget);
    final db = app.book.db;
    final saved = await tester.runAsync(() async {
      final answers = await db.select(db.careerAnswers).get();
      final r = await (db.select(db.careerPractice)..where((r) => r.id.equals(id))).getSingle();
      final out = await db.select(db.outbox).get();
      return (
        [
          for (final a in answers) (a.question, a.answer, a.review, a.score),
          (r.score, r.debrief, r.nervesBefore, r.nervesAfter),
        ],
        out.map((o) => o.toString()).join('\n'),
      );
    });
    await app.close();
    return saved!;
  }

  testWidgets('the camera is off by default, and the round runs fully without it', (tester) async {
    final camera = FakeCamera();
    final (saved, _) = await round(tester, camera: camera);
    expect(saved, isNotEmpty);
    expect(camera.feeds, isEmpty, reason: 'never opened');
  });

  testWidgets(
    'setup tips, one-tap off, self-view, notes at the end; nothing saved and the debrief unchanged',
    (tester) async {
      final (without, _) = await round(tester);

      final camera = FakeCamera();
      final backlit = List.generate(15, (_) => frameMeasure(face: 60, back: 200));
      final (withCamera, outbox) = await round(tester, camera: camera, frames: backlit);
      expect(
        withCamera,
        without,
        reason: 'nothing from the camera reaches an answer, a score or the debrief',
      );
      for (final word in ['light is behind', 'Camera', 'camera', 'luma', 'FaceBox', 'setup']) {
        expect(outbox, isNot(contains(word)), reason: 'nothing about the camera goes to sync');
      }
      expect(camera.feeds.single.closed, isTrue, reason: 'the camera goes off when the round ends');
    },
  );

  testWidgets('the setup card shows each check, the self-view switch and the one-tap off', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    final camera = FakeCamera();
    await app.run(
      home: const CameraSetupPage(),
      overrides: [coachCameraProvider.overrideWith((ref) async => camera)],
    );
    expect(find.text('Camera on'), findsNothing);
    expect(find.textContaining('never saved, sent or synced'), findsOneWidget);
    await app.tapText('Turn the camera on');
    for (final f in List.generate(15, (_) => frameMeasure(face: 60, back: 200))) {
      camera.feeds.last.value.value = f;
    }
    await tester.pump();
    expect(find.text('Light'), findsOneWidget);
    expect(find.textContaining('Move the light in front of you'), findsOneWidget);
    expect(find.text('In the middle.'), findsOneWidget);
    expect(
      find.text('Tell me if I leave the picture'),
      findsNothing,
      reason: 'round hints only before a round',
    );

    // Self-view on by default once the camera is on; one switch hides it.
    final selfView = find.widgetWithText(SwitchListTile, 'Show my picture');
    expect(tester.widget<SwitchListTile>(selfView).value, isTrue);
    await app.tap(selfView);
    expect(tester.widget<SwitchListTile>(selfView).value, isFalse);

    for (final f in List.generate(15, (_) => frameMeasure())) {
      camera.feeds.last.value.value = f;
    }
    await tester.pump();
    expect(find.text('All set for a video interview.'), findsOneWidget);

    await app.tap(find.text('Camera on'));
    expect(find.text('Camera on'), findsNothing);
    expect(find.text('Turn the camera on'), findsOneWidget);
    expect(camera.feeds.single.closed, isTrue);
    await app.close();
  });

  testWidgets('the face-box model is offered for download before the first check', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    final camera = FakeCamera(ready: false);
    await app.run(
      home: const CameraSetupPage(),
      overrides: [coachCameraProvider.overrideWith((ref) async => camera)],
    );
    await app.tapText('Turn the camera on');
    expect(find.textContaining('Download Face finder'), findsWidgets);
    await app.tap(find.text('Download 230 kB').last);
    expect(camera.downloads, 1);
    expect(find.text('Camera on'), findsOneWidget);
    await app.close();
  });

  testWidgets('the self-view and hint switches are remembered on this device; the camera is not', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    final camera = FakeCamera();
    final overrides = [coachCameraProvider.overrideWith((ref) async => camera)];
    await app.run(home: const CameraSetupPage(), overrides: overrides);
    await app.tapText('Turn the camera on');
    await app.tap(find.widgetWithText(SwitchListTile, 'Show my picture'));

    // Leave and come back: the camera is off again, the switch is as left.
    await tester.pumpWidget(const SizedBox());
    await app.run(home: const CameraSetupPage(), overrides: overrides);
    expect(find.text('Camera on'), findsNothing);
    expect(find.text('Turn the camera on'), findsOneWidget);
    expect(camera.feeds.where((f) => !f.closed), isEmpty);
    await app.tapText('Turn the camera on');
    expect(
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Show my picture')).value,
      isFalse,
    );

    final (local, outbox) = (await tester.runAsync(() async {
      final db = app.book.db;
      return (await db.localSetting(LocalKeys.coachPrefs), (await db.select(db.outbox).get()).join('\n'));
    }))!;
    expect(local, contains('"selfView":false'), reason: 'a local setting: settings only');
    expect(outbox, isNot(contains('selfView')), reason: 'never synced');
    await app.close();
  });

  testWidgets('the round hints come back switched on in the next round, with the camera off', (tester) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (b) async {
        await b.setCoachPrefs(const CoachPrefs(selfView: false, roundHints: true, lensHint: true));
        id = await b.startPractice(
          role: 'Common questions',
          mode: 'standard',
          questions: commonQuestions.take(1).toList(),
          at: '2026-11-19T10:00',
        );
      },
    );
    final camera = FakeCamera();
    await app.run(
      home: SpokenRoundPage(id),
      overrides: [
        coachCameraProvider.overrideWith((ref) async => camera),
        spokenEnginesProvider.overrideWith((ref) async => FakeEngines()),
      ],
    );
    expect(find.text('Turn the camera on'), findsOneWidget);
    expect(camera.feeds, isEmpty, reason: 'off at the start of every session');
    await app.tapText('Turn the camera on');
    bool on(String title) => tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title)).value;
    expect(on('Show my picture'), isFalse);
    expect(on('Tell me if I leave the picture'), isTrue);
    expect(on('"Looking at the lens" hint'), isTrue);
    await app.close();
  });
}
