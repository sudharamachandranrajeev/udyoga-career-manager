import 'dart:io';

import 'package:brahma_core/brahma_core.dart' show Store;
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:interview_engine/testing.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/insights.dart';

import 'support.dart';

// The spoken round itself is tested in the interview engine package. These
// tests check what Udyoga keeps of a round: text in its tables, audio only
// in the take folder.

void main() {
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
        listener: FakeListener([spokenAnswer('I ran the weekend rota at Example Clinic.', seconds: 3)]),
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
