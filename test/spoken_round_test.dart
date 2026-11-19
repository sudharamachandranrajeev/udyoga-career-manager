import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' show Store;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/delivery.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/voice/lab.dart' show Pcm;
import 'package:udyoga/voice/lexicon.dart';
import 'package:udyoga/voice/round.dart';
import 'package:udyoga/voice/round_engines.dart';
import 'package:udyoga/voice/worker.dart';

import 'support.dart';

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// A fictional answer: started 2 s after the question, three stretches with
/// gaps of 0.6 s and 3.2 s, 60 words over 30 s.
final fixtureSegments = [
  SpokenSegment(
    s(2),
    s(12),
    'Um, at the time I ran the weekend rota for a small team at Example Clinic, and two people were off.',
  ),
  SpokenSegment(
    s(12.6),
    s(20),
    'So I, like, rang the bank staff, uh, moved the training day and told the manager the same morning.',
  ),
  SpokenSegment(s(23.2), s(32), 'Every shift was covered and we used the plan again the next winter.'),
];

class FakeVoice implements InterviewerVoice {
  final prepared = <String>[];
  final said = <String>[];
  var stops = 0;
  var closed = false;
  Completer<void>? hold;

  @override
  void prepare(String text) => prepared.add(text);

  @override
  Future<void> say(String text) async {
    said.add(text);
    if (hold case final h?) await h.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    hold?.complete();
    hold = null;
  }

  @override
  Future<void> close() async => closed = true;
}

class FakeCapture implements AnswerCapture {
  FakeCapture(this.answer);
  final CapturedAnswer answer;
  final end = Completer<void>();
  final statuses = StreamController<ListenStatus>.broadcast();
  var cancelled = false;

  @override
  Stream<ListenStatus> get status => statuses.stream;
  @override
  Future<void> get heardEnd => end.future;
  @override
  Future<CapturedAnswer> finish() async => answer;
  @override
  Future<void> cancel() async => cancelled = true;
}

class FakeListener implements AnswerListener {
  /// Answers handed out in turn; the last repeats.
  FakeListener(this.answers);
  final List<CapturedAnswer> answers;
  final captures = <FakeCapture>[];
  final endSilences = <Duration?>[];
  var fail = false;

  @override
  Future<AnswerCapture> listen({Duration? endSilence}) async {
    endSilences.add(endSilence);
    if (fail) throw StateError('no microphone');
    final c = FakeCapture(answers[captures.length.clamp(0, answers.length - 1)]);
    captures.add(c);
    return c;
  }

  @override
  Future<void> close() async {}
}

class MemoryTakes implements TakeStore {
  final kept = <String, Pcm>{};
  final removed = <String>[];

  @override
  Future<String> save(int question, int take, Pcm audio) async {
    final key = 'q$question-t$take';
    kept[key] = audio;
    return key;
  }

  @override
  Future<void> remove(String key) async {
    removed.add(key);
    kept.remove(key);
  }

  @override
  Future<void> removeAll() async => kept.clear();
}

class ListSink implements AnswerSink {
  final saved = <(int, String)>[];
  @override
  Future<void> saveTranscript(int question, String text) async => saved.add((question, text));
}

class FakeCoach implements ContentCoach {
  final asked = <String>[];
  @override
  Future<ContentNote> feedback(int question, RoundQuestion q, String answer) async {
    asked.add(answer);
    return const ContentNote('A clear example with a result.', 'Say what you yourself did first.');
  }
}

CapturedAnswer spoken(String text, {double seconds = 4}) =>
    CapturedAnswer(Pcm(Float32List((seconds * 16000).round())), [SpokenSegment(s(1), s(seconds), text)]);

const questions = [
  RoundQuestion(
    'Tell us about a time you covered a gap at short notice.',
    tests: 'Problem solving under pressure.',
  ),
  RoundQuestion('How do you decide what to do first?', tests: 'Organisation.'),
];

void main() {
  group('delivery metrics', () {
    test('pace, pauses, fillers, delay and length from a fixture answer', () {
      final d = DeliveryMetrics.of(fixtureSegments)!;
      expect(d.responseDelay, s(2));
      expect(d.speaking, s(30));
      expect(d.words, countWords(fixtureSegments.map((x) => x.text).join(' ')));
      expect(d.wordsPerMinute, (d.words / 0.5).round());
      // 0.6 s is a breath, 3.2 s is a pause.
      expect(d.pauses, 1);
      expect(d.longestPause, s(3.2));
      // "Um", "like" (set off by a comma) and "uh".
      expect(d.fillers, 3);
      expect(d.fillersPerMinute, 6);
    });

    test('readings sit against usual ranges and never carry a score', () {
      final r = {for (final x in DeliveryMetrics.of(fixtureSegments)!.readings) x.label: x};
      expect(r.keys, ['Pace', 'Pauses', 'Fillers (approximate)', 'Time before you started', 'Answer length']);
      expect(r['Time before you started']!.place, RangePlace.within);
      expect(r['Answer length']!.place, RangePlace.below);
      expect(r['Answer length']!.value, '0:30 · ${DeliveryMetrics.of(fixtureSegments)!.words} words');
      expect(r['Fillers (approximate)']!.place, RangePlace.within);
      for (final x in r.values) {
        expect(x.usual, startsWith('Usual'));
        expect('${x.value} ${x.note}', isNot(matches(RegExp(r'\d+ ?(/|out of) ?\d+|score|%'))));
      }
    });

    test('a slow start, a long pause and a long answer are noted, kindly', () {
      final d = DeliveryMetrics.of([
        SpokenSegment(s(7), s(100), 'word ' * 230),
        SpokenSegment(s(106), s(200), 'word ' * 230),
      ])!;
      final r = {for (final x in d.readings) x.label: x};
      expect(r['Time before you started']!.place, RangePlace.above);
      expect(r['Pauses']!.place, RangePlace.above);
      expect(r['Answer length']!.place, RangePlace.above);
      expect(r['Pace']!.place, RangePlace.within);
      expect(r['Time before you started']!.note, contains('fine'));
    });

    test('nothing said gives no metrics; a very short answer has no pace', () {
      expect(DeliveryMetrics.of(const []), isNull);
      final d = DeliveryMetrics.of([SpokenSegment(s(1), s(2.5), 'Yes.')])!;
      expect(d.wordsPerMinute, 0);
      expect(d.readings.first.value, 'Too short to measure');
    });

    test('fillers are approximate but skip ordinary words', () {
      expect(countFillers("I'd like to lead the team, and I like data."), 0);
      expect(countFillers('And, like, we rang round. Um, then, uh, erm, it worked.'), 4);
      expect(countFillers('Umm, the umbrella policy, you know, helped.'), 2);
    });
  });

  group('voice word list', () {
    final lexicon = {
      'task': ['t', 'ˈ', 'ɑ', 'ː', 's', 'k'],
      'ask': ['ˈ', 'ɑ', 'ː', 's', 'k'],
      'role': ['ɹ', 'ˈ', 'Q', 'l'],
      'fix': ['f', 'ˈ', 'ɪ', 'k', 's'],
      'need': ['n', 'ˈ', 'i', 'ː', 'd'],
      'plan': ['p', 'l', 'ˈ', 'a', 'n'],
      'prioritise': ['p', 'ɹ', 'I', 'ˈ', 'ɒ', 'ɹ', 'ɪ', 't', 'I', 'z'],
      'priority': ['p', 'ɹ', 'I', 'ˈ', 'ɒ', 'ɹ', 'ɪ', 't', 'i'],
    };

    test('inflections are built from the base word with the English rules', () {
      expect(inflect('tasks', lexicon)!.join(), 'tˈɑːsks');
      expect(inflect('roles', lexicon)!.join(), 'ɹˈQlz');
      expect(inflect('fixes', lexicon)!.join(), 'fˈɪksɪz');
      expect(inflect('asked', lexicon)!.join(), 'ˈɑːskt');
      expect(inflect('needed', lexicon)!.join(), 'nˈiːdɪd');
      expect(inflect('prioritised', lexicon)!.join(), 'pɹIˈɒɹɪtIzd');
      expect(inflect('priorities', lexicon)!.join(), 'pɹIˈɒɹɪtiz');
      expect(inflect('planned', lexicon)!.join(), 'plˈand');
      expect(inflect('planning', lexicon)!.join(), 'plˈanɪŋ');
      expect(inflect('zebra', lexicon), isNull);
    });

    test('only words missing from the list are added', () {
      final text = [for (final e in lexicon.entries) '${e.key} ${e.value.join(' ')}'].join('\n');
      final extra = extraLexicon(text, ['You were asked to plan the tasks.', 'Why this role?']);
      expect(extra.trim().split('\n'), ['asked ˈ ɑ ː s k t', 'tasks t ˈ ɑ ː s k s']);
      expect(extraLexicon(text, ['plan the task']), isEmpty);
    });

    test('questions are read a sentence at a time', () {
      expect(sentencesOf('Thank you for coming in. Tell us about a time you led a change!  Why?'), [
        'Thank you for coming in.',
        'Tell us about a time you led a change!',
        'Why?',
      ]);
    });
  });

  group('engine worker', () {
    test('keeps state between requests, answers in order and reports errors', () async {
      final w = await EngineWorker.start(() {
        var count = 0;
        return (request) {
          if (request == engineCloseRequest) return null;
          if (request == 'boom') throw StateError('engine failed');
          return '${++count}:$request';
        };
      });
      final replies = await Future.wait([w.call<String>('a'), w.call<String>('b'), w.call<String>('c')]);
      expect(replies, ['1:a', '2:b', '3:c']);
      await expectLater(w.call<String>('boom'), throwsA(isA<StateError>()));
      expect(await w.call<String>('d'), '4:d');
      await w.close();
      await expectLater(w.call<String>('e'), throwsA(isA<StateError>()));
    });

    test('a failure while loading is thrown from start', () async {
      await expectLater(
        EngineWorker.start(() => throw StateError('model file missing')),
        throwsA(predicate((e) => '$e'.contains('model file missing'))),
      );
    });
  });

  group('round state machine', () {
    late FakeVoice voice;
    late FakeListener listener;
    late MemoryTakes takes;
    late ListSink sink;
    late FakeCoach coach;
    late SpokenRound round;

    SpokenRound make(List<CapturedAnswer> answers, {bool withCoach = true}) {
      voice = FakeVoice();
      listener = FakeListener(answers);
      takes = MemoryTakes();
      sink = ListSink();
      coach = FakeCoach();
      return round = SpokenRound(
        questions: questions,
        voice: voice,
        listener: listener,
        takes: takes,
        sink: sink,
        coach: withCoach ? coach : null,
      )..start();
    }

    test('live captions: the caption grows as stretches are written down, the draft last', () async {
      make([spoken('I rang the bank staff and covered every shift.')]);
      final heard = <String>[];
      round.changes.listen((_) {
        final c = round.live?.caption;
        if (c != null && (heard.isEmpty || heard.last != c)) heard.add(c);
      });
      voice.hold = Completer<void>();
      final asking = round.ask();
      await pumpEventQueue();
      expect(
        (round.phase, round.saying),
        (RoundPhase.asking, questions[0].text),
        reason: 'the panel line to caption',
      );
      voice.hold!.complete();
      voice.hold = null;
      await asking;
      expect(round.phase, RoundPhase.answering);
      final c = listener.captures.single;
      for (final st in const [
        ListenStatus(elapsed: Duration(seconds: 1)),
        ListenStatus(elapsed: Duration(seconds: 2), heardSpeech: true, partial: 'I rang'),
        ListenStatus(elapsed: Duration(seconds: 3), heardSpeech: true, partial: 'I rang the bank'),
        ListenStatus(elapsed: Duration(seconds: 4), heardSpeech: true, heard: ['I rang the bank staff.']),
        ListenStatus(
          elapsed: Duration(seconds: 5),
          heardSpeech: true,
          heard: ['I rang the bank staff.'],
          partial: 'and covered',
        ),
      ]) {
        c.statuses.add(st);
        await pumpEventQueue();
      }
      expect(heard, [
        '',
        'I rang',
        'I rang the bank',
        'I rang the bank staff.',
        'I rang the bank staff. and covered',
      ]);
      await round.done();
      expect(round.live, isNull, reason: 'the caption goes when the answer is written down');
      expect(round.state.latest!.transcript, 'I rang the bank staff and covered every shift.');
    });

    test('asks aloud, listens, writes down, measures and saves the text', () async {
      make([spoken('I rang the bank staff and, um, covered every shift.')]);
      expect(round.phase, RoundPhase.ready);
      expect(voice.prepared, [questions[0].text]);
      await round.ask();
      expect(voice.said, [questions[0].text]);
      expect(round.phase, RoundPhase.answering);
      // The next question is made while this one is answered.
      expect(voice.prepared.last, questions[1].text);
      await round.done();
      expect(round.phase, RoundPhase.review);
      final take = round.state.latest!;
      expect(take.number, 1);
      expect(take.transcript, 'I rang the bank staff and, um, covered every shift.');
      expect(take.delivery!.fillers, 1);
      expect(take.delivery!.responseDelay, s(1));
      expect(take.audioKey, 'q0-t1');
      expect(sink.saved, [(0, take.transcript)]);
      await round.askCoach();
      expect(round.state.note!.fix, startsWith('Say what you'));
      expect(coach.asked, [take.transcript]);
      round.next();
      expect(round.index, 1);
      expect(round.phase, RoundPhase.ready);
    });

    test('the detector hearing the end finishes the answer by itself', () async {
      make([spoken('A short answer with a result.')]);
      await round.ask();
      listener.captures.single.end.complete();
      await pumpEventQueue();
      expect(round.phase, RoundPhase.review);
    });

    test('re-takes keep take 1 and the latest; the takes between are deleted', () async {
      make([spoken('First go.'), spoken('Second go.'), spoken('Third go.')]);
      for (var i = 0; i < 3; i++) {
        await (i == 0 ? round.ask() : round.retake());
        await round.done();
      }
      final st = round.state;
      expect(st.takes, 3);
      expect(st.first!.transcript, 'First go.');
      expect(st.latest!.transcript, 'Third go.');
      expect(takes.kept.keys, unorderedEquals(['q0-t1', 'q0-t3']));
      expect(takes.removed, ['q0-t2']);
      // The question is read again for each take.
      expect(voice.said, hasLength(3));
      // The latest transcript is the one saved.
      expect(sink.saved.last, (0, 'Third go.'));
    });

    test('type instead stops the recording and saves a typed answer with no delivery', () async {
      make([spoken('never used')]);
      await round.ask();
      await round.typeInstead();
      expect(listener.captures.single.cancelled, isTrue);
      expect(round.phase, RoundPhase.typing);
      await round.submitTyped('   ');
      expect(round.phase, RoundPhase.typing);
      await round.submitTyped('I would list the deadlines and agree the order with my manager.');
      expect(round.phase, RoundPhase.review);
      expect(round.state.latest!.typed, isTrue);
      expect(round.state.latest!.delivery, isNull);
      expect(round.state.latest!.audioKey, isNull);
      expect(takes.kept, isEmpty);
      expect(sink.saved.single.$2, startsWith('I would list'));
    });

    test('typing while the question is read stops the voice', () async {
      make([spoken('x')]);
      voice.hold = Completer<void>();
      final asking = round.ask();
      await pumpEventQueue();
      expect(round.phase, RoundPhase.asking);
      await round.typeInstead();
      await asking;
      expect(voice.stops, 1);
      expect(round.phase, RoundPhase.typing);
      expect(listener.captures, isEmpty);
    });

    test('skip moves on, marks the question, and the round finishes', () async {
      make([spoken('Answer two.')]);
      await round.ask();
      await round.skip();
      expect(listener.captures.single.cancelled, isTrue);
      expect(round.states[0].skipped, isTrue);
      expect(round.index, 1);
      await round.ask();
      await round.done();
      round.next();
      expect(round.phase, RoundPhase.finished);
      expect(sink.saved, [(1, 'Answer two.')]);
    });

    test('silence is not saved; a missing microphone falls back to typing', () async {
      make([CapturedAnswer(Pcm(Float32List(16000)), const [])]);
      await round.ask();
      await round.done();
      expect(round.phase, RoundPhase.ready);
      expect(round.error, contains('No speech'));
      expect(sink.saved, isEmpty);
      expect(takes.kept, isEmpty);
      listener.fail = true;
      await round.ask();
      expect(round.phase, RoundPhase.typing);
      expect(round.error, contains('type'));
    });

    test('delete recordings clears every take but keeps the transcripts', () async {
      make([spoken('One.'), spoken('Two.')]);
      await round.ask();
      await round.done();
      await round.retake();
      await round.done();
      await round.deleteRecordings();
      expect(takes.kept, isEmpty);
      expect(round.state.first!.audioKey, isNull);
      expect(round.state.latest!.audioKey, isNull);
      expect(round.state.latest!.transcript, 'Two.');
      await round.close();
      expect(voice.closed, isTrue);
    });

    test('no coach, no feedback call', () async {
      make([spoken('An answer.')], withCoach: false);
      await round.ask();
      await round.done();
      await round.askCoach();
      expect(round.state.note, isNull);
    });
  });

  group('recordings stay out of the synced tables', () {
    late AppDatabase db;
    late CareerBook book;
    late Directory dir;

    setUp(() async {
      db = memoryDatabase();
      book = CareerBook(await Store.open(db));
      dir = await Directory.systemTemp.createTemp('udyoga-takes-test-');
    });

    tearDown(() async {
      await db.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('a spoken round saves text to the round and audio only to the take folder', () async {
      final id = await book.startPractice(
        role: 'Common questions',
        mode: 'standard',
        questions: commonQuestions.take(2).toList(),
        at: '2026-11-19T10:00',
      );
      final store = FileTakeStore(Directory('${dir.path}/$id'));
      final sink = _BookSinkForTest(book, id);
      final r = SpokenRound(
        questions: [for (final q in commonQuestions.take(2)) RoundQuestion(q.question, tests: q.why)],
        voice: FakeVoice(),
        listener: FakeListener([spoken('I ran the weekend rota at Example Clinic.', seconds: 3)]),
        takes: store,
        sink: sink,
      )..start();
      await r.ask();
      await r.done();
      await r.retake();
      await r.done();
      final files = dir.listSync(recursive: true).whereType<File>().toList();
      expect(files, hasLength(2));
      final keys = [r.state.first!.audioKey!, r.state.latest!.audioKey!];
      expect(String.fromCharCodes(File(keys.first).readAsBytesSync().take(4)), 'RIFF');

      final answers = await db.select(db.careerAnswers).get();
      expect(answers.single.answer, 'I ran the weekend rota at Example Clinic.');
      expect(answers.single.review, '');
      // Every row of every table: no audio, no path to it.
      for (final table in db.allTables) {
        for (final row in await db.select(table).get()) {
          final text = '$row';
          for (final k in keys) {
            expect(text, isNot(contains(k)), reason: table.actualTableName);
          }
          expect(text, isNot(contains('RIFF')));
          expect(text, isNot(contains('.wav')));
          expect(text, isNot(contains('interview-takes')));
        }
      }
      await r.deleteRecordings();
      expect(await Directory('${dir.path}/$id').exists(), isFalse);
    });

    test('a new transcript replaces the text and clears the old review', () async {
      final id = await book.startPractice(
        role: 'Example role',
        mode: 'standard',
        questions: const [
          PracticeQuestion({'question': 'Why this role?'}),
        ],
        at: '2026-11-19T10:00',
      );
      await book.saveAnswer(
        id,
        0,
        'Typed answer.',
        const AnswerReview({'score': 6, 'strengths': [], 'improvements': []}),
        at: '2026-11-19T10:01',
      );
      expect((await db.select(db.careerPractice).getSingle()).score, 6);
      await book.saveTranscript(id, 0, 'Spoken answer.', at: '2026-11-19T10:02');
      final a = await db.select(db.careerAnswers).getSingle();
      expect(a.answer, 'Spoken answer.');
      expect(a.review, '');
      expect(a.score, isNull);
      expect((await db.select(db.careerPractice).getSingle()).score, isNull);
    });
  });
}

class _BookSinkForTest implements AnswerSink {
  _BookSinkForTest(this.book, this.id);
  final CareerBook book;
  final String id;
  @override
  Future<void> saveTranscript(int question, String text) =>
      book.saveTranscript(id, question, text, at: '2026-11-19T10:05');
}
