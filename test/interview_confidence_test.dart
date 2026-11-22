import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/interview_confidence.dart';
import 'package:udyoga/domain/vidya_link.dart' show studyPlanId;

import 'support.dart';

/// A fictional role profile, self-written: no real advert.
const profile = RoleProfile(
  id: 'p1',
  title: 'Patient services administrator',
  frameworkId: 'nhs_values',
  criteria: [Criterion(id: 'c1', text: 'Experience of managing a busy appointments diary')],
);

/// A fictional story, self-written.
const story = StoryDraft(
  title: 'Clinic diary clash',
  situation: 'The clinic diary was double-booked most Mondays. It caused long waits.',
  action: 'I rang each patient on the list and moved the overflow to a Tuesday session.',
  result: 'Double bookings fell from nine a week to one. The consultant kept the change.',
  competencies: ['organising'],
);

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));

  group('nerves', () {
    test('a rating before and after is kept with the round, and can be taken back', () async {
      final r = await book.startProfileRound(profile, at: '2026-11-17T10:00');
      await book.saveNerves(r, before: 4);
      await book.saveNerves(r, after: 2);
      var row = (await book.roundRecord(r))!.round;
      expect((row.nervesBefore, row.nervesAfter), (4, 2));
      // Untapping clears one and leaves the other; out of range is clamped.
      await book.saveNerves(r, before: 0);
      await book.saveNerves(r, after: 9);
      row = (await book.roundRecord(r))!.round;
      expect((row.nervesBefore, row.nervesAfter), (null, 5));
    });

    test('the trend is the rated rounds, oldest first, said in words', () async {
      final a = await book.startProfileRound(profile, at: '2026-11-18T10:00');
      final b = await book.startProfileRound(profile, at: '2026-11-15T10:00');
      final c = await book.startProfileRound(profile, at: '2026-11-19T10:00');
      await book.startProfileRound(profile, at: '2026-11-16T10:00'); // skipped: not rated
      await book.saveNerves(b, before: 5, after: 3);
      await book.saveNerves(a, before: 3, after: 3);
      await book.saveNerves(c, before: 2);
      final trend = nervesTrend(await book.db.select(book.db.careerPractice).get());
      expect(
        [for (final p in trend) (p.day, p.before, p.after)],
        [('2026-11-15', 5, 3), ('2026-11-18', 3, 3), ('2026-11-19', 2, null)],
      );
      expect(
        nervesSummary(trend),
        'Before a round you went from overwhelmed to a little nervous. '
        'You felt calmer after 1 of 2 rounds than before.',
      );
      expect(nervesSummary(const []), '');
    });

    test('a schema 9 database gains the nerves columns, and the upgrade can run again', () async {
      final dir = await Directory.systemTemp.createTemp('udyoga_migrate10');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.customStatement('ALTER TABLE career_practice DROP COLUMN nerves_before');
      await db.customStatement('ALTER TABLE career_practice DROP COLUMN nerves_after');
      await db.customStatement('PRAGMA user_version = 9');
      await db.close();
      for (var i = 0; i < 2; i++) {
        db = AppDatabase(NativeDatabase(file));
        final b = CareerBook(await Store.open(db));
        final r = await b.startProfileRound(profile, at: '2026-11-19T10:00');
        await b.saveNerves(r, before: 3);
        expect((await b.roundRecord(r))!.round.nervesBefore, 3);
        await db.customStatement('PRAGMA user_version = 9');
        await db.close();
      }
    });
  });

  group('drills for Vidya', () {
    test('the drills are a Vidya plan with a stable id on every card', () async {
      await book.addStories([story], source: 'manual', today: '2026-11-19');
      final s = (await book.stories()).single;
      final plan = interviewDrills(
        stories: [s],
        questionsForThem: ['What would success look like at six months?', '  '],
        settler: profileSettler.question,
      );
      expect((plan['format'], plan['version']), ('vidya-curriculum', 1));
      final cards = [for (final c in plan['cards'] as List) c as Map];
      final ids = [for (final c in cards) c['id'] as String];
      expect(ids.toSet().length, ids.length, reason: 'unique');
      expect(ids, everyElement(startsWith('udyoga.')));
      expect(
        ids,
        containsAll(['udyoga.drill.settler', 'udyoga.drill.story.${s.id}', 'udyoga.drill.questions']),
      );
      expect(ids.where((i) => i.startsWith('udyoga.drill.recovery.')).length, recoveryDrills.length);
      expect(ids, isNot(contains('udyoga.drill.reappraisal')), reason: 'off unless asked for');

      // The story as three bullets: the situation, what I did, the result.
      final storyCard = cards.firstWhere((c) => c['id'] == 'udyoga.drill.story.${s.id}');
      expect(storyCard['front'], 'Your story in three bullets: Clinic diary clash');
      expect(
        storyCard['back'],
        '- The clinic diary was double-booked most Mondays.\n'
        '- I rang each patient on the list and moved the overflow to a Tuesday session.\n'
        '- Double bookings fell from nine a week to one.',
      );
      expect(
        cards.firstWhere((c) => c['id'] == 'udyoga.drill.questions')['back'],
        ['- What would success look like at six months?'].join('\n'),
      );
      expect(cards.firstWhere((c) => c['id'] == 'udyoga.drill.settler')['front'], profileSettler.question);

      // The routine and the video setup are checklists.
      final courses = {for (final c in plan['courses'] as List) (c as Map)['title']: c};
      expect(courses.keys, containsAll(['Pre-interview routine', 'Video interview setup']));
      expect((courses['Pre-interview routine']!['topics'] as List).map((t) => (t as Map)['title']), [
        'The day before',
        '30 minutes before',
        '5 minutes before',
        'In the room',
      ]);
      // No feedback talk of scores anywhere in what goes to Vidya.
      for (final c in cards) {
        expect(mentionsScale('${c['front']} ${c['back']}'), isFalse, reason: '${c['id']}');
      }
      expect(jsonDecode(jsonEncode(plan)), plan);
    });

    test('the reappraisal note is optional and always carries its evidence label', () {
      final plan = interviewDrills(stories: const [], questionsForThem: const [], reappraisal: true);
      final card = (plan['cards'] as List).cast<Map>().firstWhere(
        (c) => c['id'] == 'udyoga.drill.reappraisal',
      );
      expect(card['back'], contains(reappraisalLabel));
      expect(reappraisalLabel, 'Small effect in studies; try it, keep it if it helps.');
      final routine = (plan['courses'] as List).cast<Map>().firstWhere(
        (c) => c['title'] == 'Pre-interview routine',
      );
      expect((routine['topics'] as List).cast<Map>().last['details'], contains(reappraisalLabel));
      // No questions set: no empty card.
      expect((plan['cards'] as List).cast<Map>().any((c) => c['id'] == 'udyoga.drill.questions'), isFalse);
    });

    test('the drills go out on their own plan row; the questions set is the candidate\'s', () async {
      expect(await book.questionsForThem(), defaultQuestionsForThem);
      await book.setQuestionsForThem(['How is the team supported in its first month?', '']);
      expect(await book.questionsForThem(), ['How is the team supported in its first month?']);
      await book.setReappraisal(true);
      await book.sendDrills(now: '2026-11-19T10:00');
      final row = await (book.db.select(
        book.db.bridgeStudyPlans,
      )..where((p) => p.id.equals(drillsPlanId))).getSingle();
      expect((row.source, row.updated), ('udyoga', '2026-11-19T10:00'));
      final plan = jsonDecode(row.plan) as Map;
      final questions = (plan['cards'] as List).cast<Map>().firstWhere(
        (c) => c['id'] == 'udyoga.drill.questions',
      );
      expect(questions['back'], '- How is the team supported in its first month?');
      expect((plan['cards'] as List).cast<Map>().any((c) => c['id'] == 'udyoga.drill.reappraisal'), isTrue);
      // The study plan row is not touched.
      expect(
        await (book.db.select(
          book.db.bridgeStudyPlans,
        )..where((p) => p.id.equals(studyPlanId))).getSingleOrNull(),
        isNull,
      );
      expect(await book.drillsSent(), (sent: '2026-11-19T10:00', added: false));
    });

    test('the drills fixture shared with Vidya is current', () async {
      await book.addStories([story], source: 'manual', today: '2026-11-19');
      final id = (await book.stories()).single.id;
      await book.setReappraisal(true);
      final plan = const JsonEncoder.withIndent('  ')
          .convert(await book.drillsPlanNow())
          .replaceAll(id, 'fixture-story');
      final fixture = File('test/fixtures/udyoga-drills.json');
      if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
        await fixture.writeAsString('$plan\n');
      }
      expect(await fixture.readAsString(), '$plan\n');
    });
  });

  group('results back from Vidya', () {
    test('what Vidya rehearsed comes back with the date and the candidate\'s own rating', () async {
      // Written by Vidya's tests (test/fixtures/vidya-drills-progress.json there).
      final progress = File('test/fixtures/vidya-drills-progress.json').readAsStringSync();
      await book.save(
        book.db.bridgeStudyProgress,
        BridgeStudyProgressCompanion.insert(
          id: drillsPlanId,
          planUpdated: const Value('2026-11-19T10:00'),
          progress: Value(progress),
          updated: '2026-11-19T11:00',
        ),
        drillsPlanId,
      );
      final results = await book.drillResults();
      final story = results.firstWhere((r) => r.isStory);
      expect(story.title, 'Your story in three bullets: Clinic diary clash');
      expect((story.done, story.rating, story.times), ('2026-11-19', 'good', 1));
      expect(results.where((r) => r.rehearsed).length, greaterThanOrEqualTo(2));
      // Checklist items count too.
      expect(results.any((r) => r.id.startsWith('Pre-interview routine/') && r.rehearsed), isTrue);
      expect(drillResultsFrom('not json'), isEmpty);
      expect(drillResultsFrom('{"drills": [{"id": "x"}, 3]}'), isEmpty);
    });
  });

  group('what you are ready for', () {
    test('evidenced criteria from the rounds, rehearsed stories and the nerves trend', () async {
      final id = await book.saveRoleProfile(profile, at: '2026-11-18T09:00');
      final r = await book.startProfileRound((await book.roleProfile(id))!, at: '2026-11-18T10:00');
      // Question 1 asks about the diary (question 0 is the settler).
      await book.saveTranscript(
        r,
        1,
        'In my last role the clinic diary was double-booked most Mondays. I rang each patient on the list, '
        'I moved the overflow to a Tuesday session and I told the consultant. As a result the double bookings '
        'fell from nine a week to one.',
        at: '2026-11-18T10:05',
      );
      await book.saveNerves(r, before: 4, after: 2);
      await book.save(
        book.db.bridgeStudyProgress,
        BridgeStudyProgressCompanion.insert(
          id: studyPlanId,
          planUpdated: const Value('x'),
          progress: Value(
            jsonEncode({
              'drills': [
                {
                  'id': 'udyoga.story.s1',
                  'title': 'Tell your story: Clinic diary clash',
                  'done': '2026-11-18',
                  'rating': 'easy',
                  'times': 2,
                },
                {'id': 'udyoga.story.s2', 'title': 'Tell your story: Not yet', 'done': '', 'times': 0},
              ],
            }),
          ),
          updated: 'x',
        ),
        studyPlanId,
      );
      final ready = await book.readyFor();
      expect(ready.evidenced, ['Experience of managing a busy appointments diary']);
      expect(ready.stories, ['Tell your story: Clinic diary clash']);
      expect(ready.nerves, 'You felt calmer after 1 of 1 round than before.');
      expect(ready.isEmpty, isFalse);
      expect(ReadyFor.build(recent: const [], results: const [], nerves: const []).isEmpty, isTrue);
    });
  });
}
