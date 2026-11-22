import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion.dart' show practiceStory;
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/interview_book.dart';

import 'support.dart';

const at = '2026-11-19T10:00';

/// A fictional role profile, self-written: no real advert.
const profile = RoleProfile(
  id: 'p1',
  title: 'Patient services administrator',
  employer: 'Example Health Board',
  frameworkId: 'nhs_values',
  criteria: [
    Criterion(id: 'c1', text: 'Experience of managing a busy appointments diary', assessBy: ['A', 'I']),
    Criterion(id: 'c2', text: 'Working together', kind: CriterionKind.value),
    Criterion(id: 'c3', text: 'Typing at 40 words a minute', kind: CriterionKind.skill, assessBy: ['T']),
    Criterion(id: 'c4', text: 'Experience of a patient records system', essential: false),
  ],
);

/// A full answer: an example, own actions, a result and a measure.
const fullAnswer =
    'In my last role the clinic diary was double-booked most Mondays. I rang each patient on the list, '
    'I moved the overflow to a Tuesday session and I told the consultant. As a result the double bookings '
    'fell from nine a week to one.';

/// A claim with nothing behind it.
const bareClaim = 'I am a very good team player and I value working together.';

// Criteria, scales, quote checks and the debrief are tested in the interview
// engine package. These tests check what Udyoga keeps: stories, processes,
// role profiles and scoring in its database.

void main() {
  group('records', () {
    late CareerBook book;
    setUp(() async {
      final db = memoryDatabase();
      addTearDown(db.close);
      book = CareerBook(await Store.open(db));
    });

    test('a good practice answer saves to the story bank, marked as from practice', () async {
      final d = practiceStory(
        title: 'Practice: clearing a double-booked diary',
        answer: fullAnswer,
        criteria: [profile.criteria[0].text],
      );
      expect(d.situation, startsWith('In my last role'));
      expect(d.action, contains('I rang each patient'));
      expect(d.result, contains('fell from nine a week to one'));
      final id = await book.saveStoryFromPractice(
        d,
        roundId: 'r1',
        criteria: [profile.criteria[0].text],
        today: '2026-11-19',
      );
      expect(id, isNotNull);
      final s = (await book.stories()).single;
      expect(s.source, 'practice');
      expect(s.sourceId, 'r1');
      expect(s.confirmed, isFalse);
      expect(jsonDecode(s.criteria), [profile.criteria[0].text]);
      // The same story twice is one story.
      expect(
        await book.saveStoryFromPractice(d, roundId: 'r1', criteria: const [], today: '2026-11-19'),
        isNull,
      );
    });

    test('a process and its carry-forward are saved and picked up again', () async {
      final process = nhsStyle.withStage(2, nhsStyle.stages[2].copyWith(included: true));
      const outcomes = [
        QuestionOutcome(
          expected: [AnswerElement.ownAction, AnswerElement.result],
          heard: {AnswerElement.ownAction},
          interrupted: true,
        ),
      ];
      final carry = CarryForward.from([outcomes]);
      var progress = const ProcessProgress().withStage(
        0,
        StageProgress(roundId: 'r1', finished: true, outcomes: outcomes, carry: carry),
      );
      progress = progress.withStage(1, const StageProgress(roundId: 'r2'));
      final id = await book.saveProcess('', process, progress, profileId: 'p1', at: at);

      final back = (await book.savedProcess(id))!;
      expect(back.profileId, 'p1');
      expect(back.process.stages[2].included, isTrue);
      expect(back.process.stages[0].questions.length, process.stages[0].questions.length);
      expect(back.progress.finished(0), isTrue);
      expect(back.progress.finished(1), isFalse);
      expect(back.progress.stages[1]!.roundId, 'r2');
      expect(back.progress.next(back.process), 1);
      final again = back.progress.carryFor(back.process, 1);
      expect(again.fixes, carry.fixes);
      expect(again.focus, [AnswerElement.result]);
      expect(back.progress.stages[0]!.carry!.fixes, carry.fixes);
      expect(back.progress.stages[0]!.outcomes.single.interrupted, isTrue);

      // Saving again keeps one row and its start time.
      await book.saveProcess(
        id,
        back.process,
        back.progress.withStage(1, const StageProgress(roundId: 'r2', finished: true)),
        at: '2026-11-20T09:00',
      );
      final rows = await book.processRows();
      expect(rows.single.started, at);
      expect((await book.savedProcess(id))!.progress.next(back.process), 2);
    });

    test('role profiles and a round\'s scoring are kept as text', () async {
      final id = await book.saveRoleProfile(
        const RoleProfile(
          id: '',
          title: 'Ward clerk',
          frameworkId: 'hsc_ni',
          criteria: [Criterion(id: 'c1', text: 'Compassion', kind: CriterionKind.value)],
        ),
        at: at,
      );
      final p = (await book.roleProfile(id))!;
      expect(p.framework.name, 'NI HSC values-based');
      expect(p.criteria.single.kind, CriterionKind.value);
      final round = await book.startProfileRound(p, at: at);
      final rec = (await book.roundRecord(round))!;
      expect(rec.round.profileId, id);
      expect(criteriaOf(rec.questions[1]), ['c1']);
      await book.saveScoring(round, {'answers': []});
      expect((await book.roundRecord(round))!.round.debrief, contains('answers'));
    });

    test('a schema 8 database gains the I3 tables and columns, and the upgrade can run again', () async {
      final dir = await Directory.systemTemp.createTemp('udyoga_migrate9');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.customStatement('DROP TABLE career_role_profiles');
      await db.customStatement('DROP TABLE career_processes');
      await db.customStatement('ALTER TABLE career_practice DROP COLUMN profile_id');
      await db.customStatement('ALTER TABLE career_practice DROP COLUMN debrief');
      await db.customStatement('ALTER TABLE career_stories DROP COLUMN criteria');
      await db.customStatement('PRAGMA user_version = 8');
      await db.close();

      Future<void> upgrade() async {
        db = AppDatabase(NativeDatabase(file));
        final b = CareerBook(await Store.open(db));
        await b.saveProcess('', nhsStyle, const ProcessProgress(), at: at);
        final r = await b.startProfileRound(profile, at: at);
        await b.saveScoring(r, {'answers': []});
        expect(await b.processRows(), isNotEmpty);
        await db.close();
      }

      await upgrade();
      db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.customStatement('PRAGMA user_version = 8');
      await db.close();
      await upgrade();
    });
  });
}
