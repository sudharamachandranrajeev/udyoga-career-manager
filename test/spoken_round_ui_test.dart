import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/delivery.dart';
import 'package:udyoga/ui/spoken_round_page.dart';
import 'package:udyoga/voice/lab.dart' show Pcm;
import 'package:udyoga/voice/models.dart';
import 'package:udyoga/voice/round.dart';
import 'package:udyoga/voice/spoken_engines.dart';

import 'app_harness.dart';
import 'spoken_round_test.dart' show FakeListener, FakeVoice, MemoryTakes;

class FakeEngines implements SpokenEngines {
  FakeEngines({this.missingIds = const []});
  final List<String> missingIds;
  final voice = FakeVoice();
  late final listener = FakeListener([
    CapturedAnswer(Pcm(Float32List(16000 * 40)), const [
      SpokenSegment(
        Duration(seconds: 2),
        Duration(seconds: 20),
        'I ran the weekend rota and, um, rang the bank staff.',
      ),
      SpokenSegment(Duration(seconds: 21), Duration(seconds: 35), 'Every shift was covered by the morning.'),
    ]),
  ]);
  final store = MemoryTakes();
  var deletedAll = false;

  @override
  Future<List<SpeechModel>> missing() async => [for (final id in missingIds) speechModel(id)];
  @override
  Future<void> download(SpeechModel m, {void Function(double share)? progress}) async {}
  @override
  Future<double> micCheck(Duration length, {void Function(double dbfs)? level}) async => -20;
  @override
  Future<(InterviewerVoice, AnswerListener)> open(List<String> texts) async => (voice, listener);
  @override
  Future<TakeStore> takes(String roundId) async => store;
  @override
  Future<void> deleteAllTakes() async => deletedAll = true;
  @override
  Future<void> play(String key, {void Function()? onDone}) async {}
  @override
  Future<void> stopPlaying() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('a missing model is offered with its size before the round', (tester) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (b) async => id = await b.startPractice(
        role: 'Common questions',
        mode: 'standard',
        questions: commonQuestions.take(2).toList(),
        at: '2026-11-19T10:00',
      ),
    );
    final engines = FakeEngines(missingIds: [defaultTranscriber]);
    await app.run(
      home: SpokenRoundPage(id),
      overrides: [spokenEnginesProvider.overrideWith((ref) async => engines)],
    );
    expect(find.text('Download ${formatBytes(speechModel(defaultTranscriber).bytes)}'), findsOneWidget);
    expect(find.text('Start the round'), findsOneWidget);
    await app.close();
  });

  testWidgets('a spoken answer, then a typed one, through the round screen', (tester) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (b) async => id = await b.startPractice(
        role: 'Common questions',
        mode: 'standard',
        questions: commonQuestions.take(2).toList(),
        at: '2026-11-19T10:00',
      ),
    );
    final engines = FakeEngines();
    await app.run(
      home: SpokenRoundPage(id),
      overrides: [spokenEnginesProvider.overrideWith((ref) async => engines)],
    );
    // Nerves before, one tap and optional.
    expect(find.text('How nervous do you feel right now?'), findsOneWidget);
    await app.tapText('4 Very nervous');
    await app.tapText('Check the microphone');
    expect(find.textContaining('We can hear you'), findsOneWidget);
    // Thinking pauses: the end-of-answer silence is a setting, 5 s by default.
    expect(find.text('End an answer after 5 s of silence'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    await app.tapText('Start the round');
    // What the question tests comes before the answer.
    expect(find.text('What this question tests'), findsOneWidget);
    expect(find.text(commonQuestions.first.why), findsOneWidget);
    await app.tapText('Ask me');
    // The panel greets once, then asks.
    expect(engines.voice.said, [
      allOf(startsWith(Persona.of(PersonaKind.neutral).greeting), endsWith(commonQuestions.first.question)),
    ]);
    expect(find.text('Done'), findsOneWidget);
    await app.tapText('Done');
    expect(find.text('What you said (take 1)'), findsOneWidget);
    expect(find.text('How you said it'), findsOneWidget);
    expect(find.text('Fillers (approximate)'), findsOneWidget);
    expect(find.textContaining('not a score'), findsOneWidget);
    expect(find.text('Play it back'), findsOneWidget);
    expect(find.textContaining('Add an AI key'), findsOneWidget);
    final saved = await tester.runAsync(() => app.book.db.select(app.book.db.careerAnswers).get());
    expect(saved!.single.answer, startsWith('I ran the weekend rota'));

    await app.tapText('Next question');
    await app.tapText('Type instead');
    await app.enter('Your answer', 'I list what is due and agree the order with my manager.');
    await app.tapText('Save answer');
    // An example question with no own action in it: the panel follows up, in writing too.
    expect(find.text('Follow-up'), findsOneWidget);
    expect(engines.voice.said.last, 'What did you yourself do?');
    // This follow-up is answered aloud: it keeps its own delivery.
    await app.tapText('Answer by voice instead');
    await app.tapText('Done');
    if (find.text('Move on').evaluate().isNotEmpty) await app.tapText('Move on');
    expect(find.text('Your answer (typed)'), findsOneWidget);
    expect(find.text('Follow-ups'), findsOneWidget);
    expect(find.text('What your answer covered'), findsOneWidget);
    expect(find.text('How you said it'), findsNothing);
    expect(find.text('How you said the follow-up'), findsOneWidget);
    await app.tapText('Finish');
    expect(find.textContaining('You answered 2 of 2'), findsOneWidget);
    expect(find.text('For next time'), findsOneWidget);
    // And after.
    await app.tapText('2 A little nervous');
    final round = await tester.runAsync(
      () => (app.book.db.select(app.book.db.careerPractice)..where((r) => r.id.equals(id))).getSingle(),
    );
    expect((round!.nervesBefore, round.nervesAfter), (4, 2));
    await app.close();
  });
}
