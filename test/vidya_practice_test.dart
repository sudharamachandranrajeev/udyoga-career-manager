import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_file_sync.dart';
import 'package:udyoga/domain/companion.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/interview_confidence.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/vidya_drafts.dart';
import 'package:udyoga/domain/vidya_link.dart';
import 'package:udyoga/domain/vidya_practice.dart';

import 'support.dart';

/// A fictional story, self-written.
const story = StoryDraft(
  title: 'Clinic diary clash',
  situation: 'The clinic diary was double-booked most Mondays.',
  action: 'I rang each patient on the list and moved the overflow to a Tuesday session.',
  result: 'Double bookings fell from nine a week to one.',
);

/// A full answer: one example, the speaker's own actions and the outcome.
const goodAnswer =
    'In my last role a learner shouted at me in front of the group during a system training session. '
    'I paused the session, I took him aside and I listened to what was worrying him. I agreed a one-to-one '
    'catch-up for the next day. As a result he finished the course and thanked me afterwards.';

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));

  // Written by Vidya's tests (test/fixtures/vidya-practise-requests.json there).
  final requestsJson = File('test/fixtures/vidya-practise-requests.json').readAsStringSync();

  Future<void> vidyaWrites(String id, String progress, {String planUpdated = ''}) => book.db
      .into(book.db.bridgeStudyProgress)
      .insertOnConflictUpdate(
        BridgeStudyProgressCompanion.insert(
          id: id,
          planUpdated: Value(planUpdated),
          progress: Value(progress),
          updated: '2026-11-21T10:00:00Z',
        ),
      );

  group('requests from Vidya', () {
    test('Vidya\'s requests row reads as requests, newest first, with every field', () {
      final r = parsePractiseRequests(requestsJson);
      expect(r.map((x) => x.id), ['vidya-drill-q2', 'vidya-drill-q1']);
      final q2 = r.first;
      expect(
        (q2.ref, q2.question, q2.criterion, q2.role, q2.topic, q2.story),
        (
          'q2',
          'Tell me about a time a learner got angry.',
          'Handle a difficult learner calmly',
          'Example Trainer',
          'Difficult moments',
          'fixture-story',
        ),
      );
      expect(q2.asked, '2026-11-21T10:00:00.000Z');
      expect(r.last.story, '');
    });

    test('an ordinary progress report is not a request row, and junk is skipped', () {
      expect(parsePractiseRequests(File('test/fixtures/vidya-progress.json').readAsStringSync()), isEmpty);
      expect(
        parsePractiseRequests(File('test/fixtures/vidya-drills-progress.json').readAsStringSync()),
        isEmpty,
      );
      expect(parsePractiseRequests('not json'), isEmpty);
      expect(
        parsePractiseRequests(
          jsonEncode({
            'format': 'vidya-practise-requests',
            'requests': [
              {'id': '', 'question': 'No id'},
              {'id': 'a'},
              'junk',
              {'id': 'b', 'question': 'Kept'},
              {'id': 'b', 'question': 'A twin'},
            ],
          }),
        ).map((r) => (r.id, r.question)),
        [('b', 'Kept')],
      );
    });

    test('the request row leaves the existing readers of Vidya\'s progress alone', () async {
      await vidyaWrites(practiseRequestsId, requestsJson);
      final link = await book.vidyaBridge();
      expect((link.sent, link.added), (null, false));
      expect([...link.done.learning, ...link.done.skills], isEmpty);
      expect(await book.drillResults(), isEmpty);
      expect((await book.drillsSent()).added, isFalse);
      expect(await book.vidyaReadiness(), isEmpty);
      // Read as a study progress, it is an empty one.
      final p = StudyProgress.parse(requestsJson);
      expect([...p.learning, ...p.skills], isEmpty);
      expect((await book.practiseRequests()).length, 2);
    });

    test('a request is pending until a score from the day it was asked or later', () async {
      await vidyaWrites(practiseRequestsId, requestsJson);
      expect((await book.pendingPractiseRequests()).map((r) => r.id), ['vidya-drill-q2', 'vidya-drill-q1']);
      final q1 = (await book.practiseRequests()).last;
      // An older score (before Vidya asked) does not count.
      expect(practised(q1, [PractiseResult(id: q1.id, day: '2026-11-01', score: 2, max: 2)]), isFalse);
      expect(practised(q1, [PractiseResult(id: q1.id, day: q1.askedDay, score: 0, max: 2)]), isTrue);
    });
  });

  group('the round and its result', () {
    Future<PractiseRequest> request() async {
      await book.addStories([story], source: 'manual', today: '2026-11-19');
      final storyId = (await book.stories()).single.id;
      await vidyaWrites(practiseRequestsId, requestsJson.replaceAll('fixture-story', storyId));
      return (await book.practiseRequests()).first;
    }

    test('a request runs as one question that tests Vidya\'s criterion, with the linked story', () async {
      final r = await request();
      final id = await book.startVidyaPractice(r, at: '2026-11-21T11:00');
      final rec = (await book.roundRecord(id))!;
      expect(rec.round.role, 'Example Trainer');
      final q = rec.questions.single;
      expect(q.question, 'Tell me about a time a learner got angry.');
      expect(q.why, 'Handle a difficult learner calmly');
      expect(q.lookFor, contains('Your story "Clinic diary clash" fits here'));
      expect(vidyaDrillOf(q), 'vidya-drill-q2');
      // A story id that no longer resolves is simply left out.
      final gone = PractiseRequest(id: 'x', question: 'Q?', story: 'deleted-story');
      final other = await book.startVidyaPractice(gone, at: '2026-11-21T11:00');
      final q2 = (await book.roundRecord(other))!.questions.single;
      expect(q2.lookFor.any((l) => l.contains('story')), isFalse);
      expect((await book.roundRecord(other))!.round.role, 'Vidya drill');
    });

    test(
      'after the round the score goes back in exactly Vidya\'s shape (fixture shared with Vidya)',
      () async {
        final r = await request();
        final id = await book.startVidyaPractice(r, at: '2026-11-21T11:00');
        expect(
          await book.recordVidyaPractice(id, now: '2026-11-21T11:05:00Z', day: '2026-11-21'),
          isNull,
          reason: 'nothing answered yet',
        );
        await book.saveTranscript(id, 0, goodAnswer, at: '2026-11-21T11:03');
        final result = (await book.recordVidyaPractice(id, now: '2026-11-21T11:05:00Z', day: '2026-11-21'))!;
        expect((result.id, result.day, result.score, result.max), ('vidya-drill-q2', '2026-11-21', 2, 2));

        final row = await (book.db.select(
          book.db.bridgeStudyPlans,
        )..where((p) => p.id.equals(practiseResultsId))).getSingle();
        expect((row.source, row.updated, row.deleted), ('udyoga', '2026-11-21T11:05:00Z', false));
        final j = jsonDecode(row.plan) as Map<String, Object?>;
        expect(j.keys, ['format', 'version', 'results']);
        expect((j['format'], j['version']), ('udyoga-practise-results', 1));
        final entry = (j['results'] as List).single as Map;
        expect(entry.keys.toSet(), {'id', 'day', 'score', 'max', 'summary'});
        expect((entry['summary'] as String).length, lessThanOrEqualTo(200));
        expect(entry['summary'], startsWith('Evidenced.'));

        final fixture = File('test/fixtures/udyoga-practise-results.json');
        final text = const JsonEncoder.withIndent('  ').convert(j);
        if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
          await fixture.writeAsString('$text\n');
        }
        expect(await fixture.readAsString(), '$text\n');

        // Practised now, so no longer pending.
        expect((await book.pendingPractiseRequests()).map((x) => x.id), ['vidya-drill-q1']);
        // An ordinary round sends nothing.
        final plain = await book.startPractice(
          role: 'Common questions',
          mode: 'standard',
          questions: const [
            PracticeQuestion({'question': 'Why this role?'}),
          ],
          at: '2026-11-21T12:00',
        );
        await book.saveTranscript(plain, 0, goodAnswer, at: '2026-11-21T12:01');
        expect(await book.recordVidyaPractice(plain, now: 'T'), isNull);
      },
    );

    test('a thin answer scores 1 of 2 on the matcher', () async {
      final r = await request();
      final id = await book.startVidyaPractice(r, at: '2026-11-21T11:00');
      await book.saveTranscript(
        id,
        0,
        'I set up the records system and I updated it every day.',
        at: '2026-11-21T11:03',
      );
      final result = (await book.recordVidyaPractice(id, now: 'N', day: '2026-11-21'))!;
      expect((result.score, result.max), (1, 2));
      expect(result.summary, startsWith('Thin.'));
    });

    test('results merge: newest first, one per drill and day, at most 50', () {
      PractiseResult res(String id, String day, num score) =>
          PractiseResult(id: id, day: day, score: score, max: 2);
      var plan = mergePractiseResults(null, res('a', '2026-11-20', 1));
      plan = mergePractiseResults(plan, res('b', '2026-11-21', 2));
      plan = mergePractiseResults(plan, res('a', '2026-11-21', 0));
      plan = mergePractiseResults(plan, res('a', '2026-11-21', 2)); // the same day again: replaces
      expect(parsePractiseResults(plan).map((r) => (r.id, r.day, r.score)), [
        ('a', '2026-11-21', 2),
        ('b', '2026-11-21', 2),
        ('a', '2026-11-20', 1),
      ]);
      for (var i = 0; i < 60; i++) {
        plan = mergePractiseResults(
          plan,
          res('d$i', '2026-12-${(i % 28 + 1).toString().padLeft(2, '0')}', 1),
        );
      }
      final all = parsePractiseResults(plan);
      expect(all.length, maxPractiseResults);
      expect([for (final r in all) r.day], [for (final r in all) r.day]..sort((a, b) => b.compareTo(a)));
      expect(all.any((r) => r.day == '2026-11-20'), isFalse, reason: 'the oldest go first');
      expect(parsePractiseResults('{"format":"vidya-curriculum","results":[]}'), isEmpty);
    });

    test('Udyoga\'s own readers of its plan rows ignore the results row', () async {
      await book.save(
        book.db.bridgeStudyPlans,
        BridgeStudyPlansCompanion.insert(
          id: practiseResultsId,
          source: 'udyoga',
          plan: File('test/fixtures/udyoga-practise-results.json').readAsStringSync(),
          updated: '2026-11-21T11:05:00Z',
        ),
        practiseResultsId,
      );
      expect((await book.vidyaBridge()).sent, isNull);
      expect((await book.drillsSent()).sent, isNull);
      expect(await CareerFileSync(book, device: 'laptop').syncPlans(now: '2026-11-21T12:00:00Z'), 0);
      final row = await (book.db.select(
        book.db.bridgeStudyPlans,
      )..where((p) => p.id.equals(practiseResultsId))).getSingle();
      expect(row.deleted, isFalse, reason: 'the career-file sync only manages its own plan rows');
    });
  });

  group('readiness from Vidya', () {
    const role = 'Clinical Systems Trainer';
    final planId = rolePlanId(role);

    Future<void> sendRolePlan() => book.save(
      book.db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(
        id: planId,
        source: 'udyoga',
        plan: jsonEncode({'format': 'vidya-curriculum', 'version': 1, 'role': role, 'courses': []}),
        updated: '2026-11-20T09:00:00Z',
      ),
      planId,
    );

    String progress(List<Map<String, Object>>? readiness) =>
        jsonEncode({'learning': [], 'skills': [], 'readiness': ?readiness});

    final weakAndMissing = [
      {'criterionId': 'e2', 'text': 'Handle a difficult learner calmly', 'status': 'weak', 'essential': true},
      {'criterionId': 'e3', 'text': 'Keep training records.', 'status': 'missing', 'essential': true},
      {'criterionId': 'd1', 'text': 'Write short guides', 'status': 'weak', 'essential': false},
      {'criterionId': '', 'text': 'Full UK driving licence', 'status': 'missing', 'essential': true},
    ];

    test('the readiness list reads as rows; older progress rows have none', () {
      expect(parseVidyaReadiness(File('test/fixtures/vidya-progress.json').readAsStringSync()), isNull);
      expect(parseVidyaReadiness(progress(const [])), isEmpty);
      final rows = parseVidyaReadiness(progress(weakAndMissing))!;
      expect(rows.map((r) => (r.criterionId, r.status, r.essential)), [
        ('e2', 'weak', true),
        ('e3', 'missing', true),
        ('d1', 'weak', false),
        ('', 'missing', true),
      ]);
      expect(
        parseVidyaReadiness(
          jsonEncode({
            'readiness': [
              {'text': 'Covered', 'status': 'covered'},
              {'text': '', 'status': 'weak'},
              'junk',
            ],
          }),
        ),
        isEmpty,
      );
    });

    test('the role shows "Vidya readiness: N weak, M missing" once Vidya reports on its plan', () async {
      expect(await book.roleReadiness(role), isNull);
      await sendRolePlan();
      await vidyaWrites(planId, progress(null), planUpdated: '2026-11-20T09:00:00Z');
      expect(await book.roleReadiness(role), isNull, reason: 'a plan without criteria has no readiness');
      await vidyaWrites(planId, progress(weakAndMissing), planUpdated: '2026-11-20T09:00:00Z');
      final r = (await book.roleReadiness('clinical systems trainer'))!;
      expect((r.role, r.weak, r.missing), (role, 2, 2));
      expect(r.text, 'Vidya readiness: 2 weak, 2 missing');
      await vidyaWrites(planId, progress(const []), planUpdated: '2026-11-20T09:00:00Z');
      expect((await book.roleReadiness(role))!.text, 'Vidya readiness: every criterion covered');
    });

    test('weak and missing essentials become drill cards with stable ids; covered ones retire', () async {
      await sendRolePlan();
      await vidyaWrites(planId, progress(weakAndMissing));
      List<Map> gapCards(Json plan) => [
        for (final c in (plan['cards'] as List).cast<Map>())
          if ((c['id'] as String).startsWith('udyoga.drill.readiness.')) c,
      ];
      var cards = gapCards(await book.drillsPlanNow());
      expect(cards.map((c) => c['id']), [
        'udyoga.drill.readiness.clinical-systems-trainer.e2',
        'udyoga.drill.readiness.clinical-systems-trainer.e3',
        startsWith('udyoga.drill.readiness.clinical-systems-trainer.t'),
      ], reason: 'essential only; the desirable d1 stays in Vidya');
      final typedId = cards.last['id'];
      expect(
        cards[1]['front'],
        'This role needs keep training records. Tell us about a time you showed this.',
      );
      expect(cards[1]['back'], contains('Vidya readiness for $role: missing'));
      expect((cards.first['deck'], cards.first['course']), (drillsDeck, 'Interview drills'));

      // e3 now weak and the typed row still missing: same ids, new text.
      await vidyaWrites(
        planId,
        progress([
          {'criterionId': 'e3', 'text': 'Keep training records.', 'status': 'weak', 'essential': true},
          {'criterionId': '', 'text': 'Full UK driving licence', 'status': 'missing', 'essential': true},
        ]),
      );
      cards = gapCards(await book.drillsPlanNow());
      expect(cards.map((c) => c['id']), ['udyoga.drill.readiness.clinical-systems-trainer.e3', typedId]);
      expect(cards.first['back'], contains(': weak.'));

      // Sent on the existing drills path.
      await book.sendDrills(now: '2026-11-21T09:00:00Z');
      final row = await (book.db.select(
        book.db.bridgeStudyPlans,
      )..where((p) => p.id.equals(drillsPlanId))).getSingle();
      final sent = jsonDecode(row.plan) as Json;
      expect(gapCards(sent).length, 2);
      expect(
        ((sent['notes'] as List).single as Map)['body'],
        contains('2 cards come from your Vidya readiness'),
      );

      // All covered: the cards drop out (Vidya sets them aside).
      await vidyaWrites(planId, progress(const []));
      expect(gapCards(await book.drillsPlanNow()), isEmpty);
      // And a role plan taken back takes its readiness with it.
      await vidyaWrites(planId, progress(weakAndMissing));
      final plan = await (book.db.select(
        book.db.bridgeStudyPlans,
      )..where((p) => p.id.equals(planId))).getSingle();
      await book.save(book.db.bridgeStudyPlans, plan.copyWith(deleted: true), planId);
      expect(gapCards(await book.drillsPlanNow()), isEmpty);
    });

    test('ids stay the same for the same role and criterion', () {
      const row = VidyaReadinessRow(criterionId: '', text: 'Full UK driving licence', status: 'missing');
      final a = readinessDrillId(planId, row);
      expect(
        readinessDrillId(
          planId,
          const VidyaReadinessRow(criterionId: '', text: ' full uk driving licence ', status: 'weak'),
        ),
        a,
      );
      expect(
        readinessDrillId(
          planId,
          const VidyaReadinessRow(criterionId: 'esco/skill:1 2', text: 'x', status: 'weak'),
        ),
        'udyoga.drill.readiness.clinical-systems-trainer.esco-skill-1-2',
      );
    });
  });

  group('email drafts from Vidya', () {
    // Written by Vidya's tests (test/fixtures/vidya-email-drafts.json there).
    final draftsJson = File('test/fixtures/vidya-email-drafts.json').readAsStringSync();

    test('Vidya\'s drafts row reads newest first, every field kept; other rows are not drafts', () async {
      final d = parseVidyaDrafts(draftsJson);
      expect(d.map((x) => x.template), ['feedback', 'chase']);
      final f = d.first;
      expect(
        (f.id, f.title, f.subject, f.employer, f.role, f.at),
        (
          'fixture-feedback',
          'Ask for feedback by criterion',
          'Feedback on my interview for Example Officer',
          'Example Health Trust',
          'Example Officer',
          '2026-12-06T09:00:00Z',
        ),
      );
      expect(f.body, 'Dear Hiring Manager,\n\nThank you for interviewing me.');
      expect(parseVidyaDrafts(requestsJson), isEmpty);
      expect(parseVidyaDrafts('not json'), isEmpty);
      expect(
        parseVidyaDrafts(
          jsonEncode({
            'format': 'vidya-email-drafts',
            'drafts': [
              {'id': 'a', 'body': ''},
              {'id': '', 'body': 'x'},
              {'id': 'b', 'body': 'x' * 6000},
            ],
          }),
        ).single.body.length,
        maxDraftBody,
      );
      expect(await book.vidyaDrafts(), isEmpty);
      await vidyaWrites(emailDraftsId, draftsJson);
      expect((await book.vidyaDrafts()).map((x) => x.id), ['fixture-feedback', 'fixture-chase']);
    });
  });
}
