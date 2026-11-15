// The candidate companion: documents read from the candidate's own folders,
// profile questions, the daily check-in, the story bank and its reminder.
// Every candidate here is made up.
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/check_in_reminder.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/companion_service.dart';
import 'package:udyoga/domain/documents.dart';
import 'package:udyoga/domain/json.dart';

import 'support.dart';

const _story = {
  'title': 'Short-notice clinic slots',
  'situation': 'Clinic cancellations left slots empty.',
  'task': 'Fill them the same day.',
  'action': 'I kept a list of patients happy to come at short notice and rang them.',
  'result': 'Most slots were filled.',
  'competencies': ['prioritising', 'service', 'not-a-competency'],
};

/// Answers each companion request by the shape of its schema, and counts
/// what was asked.
class _FakeAi implements Ai {
  final asked = <String>[];
  var failQuestion = false;

  @override
  String get model => 'test';

  @override
  Future<AiResult> ask({
    required String system,
    required List<Json> content,
    required Json schema,
    bool web = false,
    int searches = 8,
    String effort = 'high',
    int maxTokens = 32000,
    void Function(String status)? onProgress,
  }) async {
    final keys = (schema['properties'] as Map).keys.toSet();
    if (keys.contains('documents')) {
      asked.add('read');
      return const AiResult({
        'documents': [
          {
            'name': 'cv.txt',
            'kind': 'cv',
            'summary': 'A CV.',
            'facts': [
              {'topic': 'Start date', 'statement': 'Started in 2022', 'quote': '2022 – present'},
            ],
            'stories': [_story],
          },
          {
            'name': 'reference.md',
            'kind': 'reference',
            'summary': 'A reference.',
            'facts': [],
            'stories': [],
          },
        ],
      });
    }
    if (keys.contains('questions')) {
      asked.add('questions');
      return const AiResult({
        'questions': [
          {
            'topic': 'Start date',
            'question': 'When did you start?',
            'why': 'CV and reference differ',
            'choices': ['2022', '2023'],
          },
          {'topic': 'start date ', 'question': 'Duplicate topic', 'why': '', 'choices': []},
          {'topic': 'Notice', 'question': 'What is your notice period?', 'why': '', 'choices': []},
        ],
      });
    }
    if (keys.contains('nextQuestion')) {
      asked.add('digest');
      return const AiResult({
        'summary': 'Busy clinic day.',
        'stories': [_story],
        'skills': ['SystmOne'],
        'achievements': ['Filled every cancelled slot'],
        'learning': ['Referral to treatment rules'],
        'nextQuestion': 'How many slots did you fill?',
      });
    }
    if (keys.contains('question')) {
      asked.add('question');
      if (failQuestion) throw Exception('offline');
      return const AiResult({'question': 'What did you sort out today?'});
    }
    asked.add('profile');
    return AiResult(sampleProfile.toJson());
  }
}

class _FakeScheduler implements CheckInScheduler {
  List<DateTime>? times;

  @override
  bool get supported => true;

  var asked = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return true;
  }

  @override
  Future<void> replaceAll(List<DateTime> times) async => this.times = times;
}

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));

  test('a schema 2 database gains the companion tables', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    for (final t in ['career_documents', 'career_questions', 'career_journal', 'career_stories']) {
      await db.customStatement('DROP TABLE $t');
    }
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'career_%'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, containsAll(['career_documents', 'career_questions', 'career_journal', 'career_stories']));
    await db.close();
  });

  test('scanFolders finds documents and skips hidden, tooling and lock files', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_docs');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> put(String path) async {
      final f = File('${dir.path}/$path');
      await f.parent.create(recursive: true);
      await f.writeAsString('text of $path');
    }

    for (final p in [
      'cv.txt',
      'sub/notes.md',
      '.hidden/a.txt',
      '.git/b.txt',
      'node_modules/c.md',
      '~\$d.docx',
      'e.exe',
    ]) {
      await put(p);
    }
    final found = await scanFolders([dir.path, '${dir.path}/missing']);
    expect(found.map((f) => f.name).toSet(), {'cv.txt', 'notes.md'});
    expect(found.firstWhere((f) => f.name == 'cv.txt').text, 'text of cv.txt');
    expect(found.first.hash, hashOf(found.first.bytes));
  });

  test('a file found twice is one document', () async {
    final first = await book.recordFound([
      (hash: 'a' * 64, name: 'cv.txt', content: 'x'),
    ], today: '2026-11-15');
    final again = await book.recordFound([
      (hash: 'a' * 64, name: 'cv copy.txt', content: 'x'),
      (hash: 'b' * 64, name: 'ref.md', content: 'y'),
    ], today: '2026-11-16');
    expect(first, [CompanionBook.documentId('a' * 64)]);
    expect(again, [CompanionBook.documentId('b' * 64)]);
    expect((await book.documents()).length, 2);
  });

  test('scan reads new documents, fills an empty profile and asks what to confirm', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_scan');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/cv.txt').writeAsString('Alex Example, Staff Nurse, 2022 – present');
    await File('${dir.path}/reference.md').writeAsString('Alex started with us in 2023.');
    final ai = _FakeAi();
    final companion = Companion(book, advisor: Advisor(ai, today: '2026-11-15'));

    final report = await companion.scan([dir.path], today: '2026-11-15');
    expect(
      (report.found, report.added, report.read, report.questions, report.profileFilled),
      (2, 2, 2, 2, true),
    );
    expect(ai.asked, ['read', 'profile', 'questions']);
    final docs = await book.documents();
    expect(docs.map((d) => d.kind).toSet(), {'cv', 'reference'});
    expect(docs.every((d) => d.analysed == '2026-11-15'), isTrue);
    final cv = docs.firstWhere((d) => d.kind == 'cv');
    expect(CompanionBook.factsOf(cv).single.topic, 'Start date');
    final stories = await book.stories();
    expect(stories.single.source, 'document');
    expect(CompanionBook.competenciesOf(stories.single), ['prioritising', 'service']);
    expect((await book.profile()).name, sampleProfile.name);

    // Nothing new: nothing is read or asked again.
    ai.asked.clear();
    final again = await companion.scan([dir.path], today: '2026-11-16');
    expect((again.added, again.read, again.questions), (0, 0, 0));
    expect(ai.asked, isEmpty);
  });

  test('without the AI, documents are still found and listed', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_scan');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/cv.txt').writeAsString('A CV');
    final report = await Companion(book).scan([dir.path], today: '2026-11-15');
    expect((report.found, report.added, report.read), (1, 1, 0));
    expect((await book.documents()).single.analysed, isNull);
  });

  test('answers are settled, applied once and reach the profile for the AI', () async {
    final added = await book.addQuestions([
      const QuestionDraft(topic: 'Start date', question: 'When did you start?'),
      const QuestionDraft(topic: 'Gap', question: 'What did you do in 2021?'),
    ], today: '2026-11-15');
    expect(added, 2);
    final qs = await book.questions(status: 'open');
    await book.answerQuestion(qs.first, ' June 2024 ', today: '2026-11-15');
    await book.dismissQuestion(qs.last, today: '2026-11-15');
    expect(await book.settled(), ['Start date: June 2024', 'Gap: not relevant (do not ask)']);
    expect((await book.profile()).confirmed, ['Start date: June 2024']);

    final ai = _FakeAi();
    final companion = Companion(book, advisor: Advisor(ai, today: '2026-11-15'));
    expect(await companion.applyAnswers(), 1);
    expect(await companion.applyAnswers(), 0);
    expect(ai.asked, ['profile']);
    // A settled topic is not asked again.
    expect(
      await book.addQuestions([const QuestionDraft(topic: 'gap', question: 'Again?')], today: '2026-11-16'),
      0,
    );
  });

  test('the check-in asks once a day and files what the answer adds', () async {
    final ai = _FakeAi();
    final companion = Companion(book, advisor: Advisor(ai, today: '2026-11-15'));
    final c = await companion.today('2026-11-15', at: '18:30');
    expect(c.prompt, 'What did you sort out today?');
    expect((await companion.today('2026-11-15', at: '19:00')).id, c.id);
    expect(ai.asked, ['question']);

    final d = await companion.answer(
      c,
      'Two clinics cancelled; I rang my short-notice list.',
      today: '2026-11-15',
      at: '18:40',
    );
    expect(d!.nextQuestion, 'How many slots did you fill?');
    final saved = (await book.checkIn('2026-11-15'))!;
    expect(saved.entry, 'Two clinics cancelled; I rang my short-notice list.');
    expect(saved.digest, contains('Busy clinic day.'));
    final story = (await book.stories()).single;
    expect((story.source, story.sourceId, story.confirmed), ('checkin', c.id, false));
    final notes = await book.notes();
    expect(
      notes.map((n) => (n.kind, n.title)),
      containsAll([('win', 'Filled every cancelled slot'), ('idea', 'Skill shown: SystmOne')]),
    );
    expect((await book.profile()).stories.single, startsWith('Short-notice clinic slots (draft):'));

    // The next day follows up yesterday's answer when the AI is unreachable.
    ai.failQuestion = true;
    expect((await companion.today('2026-11-16', at: '18:30')).prompt, 'How many slots did you fill?');
  });

  test('without the AI, the check-in asks about the competency with least evidence', () async {
    await book.addStories(
      [
        const StoryDraft(title: 'A', action: 'did', competencies: ['prioritising']),
      ],
      source: 'manual',
      today: '2026-11-15',
    );
    final c = await Companion(book).today('2026-11-15', at: '18:30');
    expect(checkInQuestions.values, contains(c.prompt));
    expect(c.prompt, isNot(checkInQuestions['prioritising']));
    expect(await Companion(book).answer(c, 'A quiet day.', today: '2026-11-15', at: '18:31'), isNull);
    expect((await book.checkIn('2026-11-15'))!.entry, 'A quiet day.');
  });

  test('stories without an action or with a known title are not added', () async {
    final n = await book.addStories(
      [
        const StoryDraft(title: 'One', action: 'did it', competencies: ['teamwork']),
        const StoryDraft(title: 'one ', action: 'again'),
        const StoryDraft(title: 'Two'),
      ],
      source: 'manual',
      today: '2026-11-15',
    );
    expect(n, 1);
    final s = (await book.stories()).single;
    await book.saveStory(s.copyWith(confirmed: true));
    expect(await book.storyCounts(), {'teamwork': (confirmed: 1, drafts: 0)});
  });

  test('readiness and the weakest competency', () {
    final r = readiness({'teamwork': (confirmed: 1, drafts: 1)});
    expect((r['teamwork'], r['values']), (75, 0));
    expect(readiness({'teamwork': (confirmed: 3, drafts: 0)})['teamwork'], 100);
    expect(readiness({}).keys, competencyNames.keys);
    final all = {for (final c in competencyNames.keys) c: 1}..remove('values');
    expect(weakestCompetency(all, day: '2026-11-15'), 'values');
  });

  group('check-in reminders', () {
    test('the next days at the chosen time, skipping a passed or answered today', () {
      final noon = DateTime(2026, 11, 15, 12);
      expect(checkInTimes(noon, '18:30', answeredToday: false, days: 3), [
        DateTime(2026, 11, 15, 18, 30),
        DateTime(2026, 11, 16, 18, 30),
        DateTime(2026, 11, 17, 18, 30),
      ]);
      expect(checkInTimes(noon, '18:30', answeredToday: true, days: 3).first, DateTime(2026, 11, 16, 18, 30));
      expect(checkInTimes(DateTime(2026, 11, 15, 19), '18:30', answeredToday: false, days: 3).length, 2);
      expect(checkInTimes(noon, 'nonsense', answeredToday: false, days: 1), [DateTime(2026, 11, 15, 18, 30)]);
    });

    test('sync follows the settings and today\'s answer', () async {
      final scheduler = _FakeScheduler();
      await book.setCheckInSettings(time: '23:59');
      await syncCheckInReminders(scheduler, book);
      expect(scheduler.times!.length, inInclusiveRange(13, 14));
      expect(scheduler.times!.every((t) => t.hour == 23 && t.minute == 59), isTrue);

      final day = DateTime.now().toIso8601String().substring(0, 10);
      final c = await book.askToday(day, 'How was it?', at: '12:00');
      await book.answerCheckIn(c, 'Fine', at: '12:01');
      await syncCheckInReminders(scheduler, book);
      expect(scheduler.times!.length, 13);
      expect(scheduler.times!.first.day, isNot(DateTime.now().day));

      expect(scheduler.asked, 0);
      await askReminderPermissionOnce(scheduler, book);
      await askReminderPermissionOnce(scheduler, book);
      expect(scheduler.asked, 1);

      await book.setCheckInSettings(remind: false);
      await syncCheckInReminders(scheduler, book);
      expect(scheduler.times, isEmpty);
    });
  });
}
