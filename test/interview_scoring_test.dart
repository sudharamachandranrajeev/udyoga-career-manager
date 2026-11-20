import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/interview_process.dart';
import 'package:udyoga/domain/interview_scoring.dart';

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

void main() {
  group('reading criteria', () {
    test('blank and repeated criteria are dropped, ids are given in order', () {
      final c = parseCriteria({
        'criteria': [
          {
            'text': '  Experience of  front-desk work ',
            'essential': true,
            'kind': 'experience',
            'assessBy': ['A', 'i'],
          },
          {'text': 'experience of front desk work', 'essential': false, 'kind': 'skill', 'assessBy': []},
          {'text': '', 'essential': true, 'kind': 'skill', 'assessBy': []},
          {
            'text': 'Compassion',
            'essential': true,
            'kind': 'nonsense',
            'assessBy': ['X', 'T'],
            'question': 'Q?',
          },
          {'text': 'A degree', 'essential': false, 'kind': 'qualification', 'assessBy': []},
        ],
      });
      expect(c.map((x) => x.id), ['c1', 'c2', 'c3']);
      expect(c[0].text, 'Experience of front-desk work');
      expect(c[0].assessBy, ['A', 'I']);
      expect(c[1].kind, CriterionKind.experience);
      expect(c[1].assessBy, ['T']);
      expect(c[1].testOnly, isTrue);
      expect(c[1].question, 'Q?');
      expect(c[2].essential, isFalse);
      expect(parseCriteria(const {}), isEmpty);
      expect(suggestedFramework({'framework': 'civil_service'}), 'civil_service');
      expect(suggestedFramework({'framework': 'made_up'}), 'private');
    });

    test('criteria become questions: essentials first, application- and test-only left out', () {
      final qs = questionsFromProfile(profile);
      expect(qs.first.category, 'Settler');
      expect([for (final q in qs.skip(1)) criteriaOf(q).single], ['c1', 'c2', 'c4']);
      // A criterion assessed only by the application is not asked aloud either.
      final appOnly = profile.copyWith(
        criteria: [
          ...profile.criteria,
          const Criterion(id: 'c5', text: 'A typing certificate', assessBy: ['A']),
        ],
      );
      expect(askedCriteria(appOnly).map((c) => c.id), ['c1', 'c2', 'c4']);
      expect(qs[2].question, startsWith('One of our values is working together.'));
      expect(qs[1].why, contains('(essential)'));
      expect(qs[3].why, contains('(desirable)'));
      final plans = withCriteria(qs, const [], profile);
      expect(plans[0].expected, isEmpty);
      expect(plans[1].criterion, profile.criteria[0].text);
      expect(plans[1].probes.single.text, contains('managing a busy appointments diary'));
      // The probe for the example is the criterion's own.
      final p = ProbePicker.next(plan: plans[1], heard: 'I am organised.', asked: const []);
      expect(p, isNotNull);
    });
  });

  group('scales and anchors', () {
    test('codes map to levels and anchors; coverage follows each scale', () {
      final nhs = Framework.of('nhs_values').scale;
      expect(nhs.level('n/o'), nhs.noEvidence);
      expect(nhs.level('Level 3')!.label, 'Very good');
      expect(nhs.level(' 4 ')!.anchor, contains('depth'));
      expect(nhs.level('5'), isNull);
      expect(nhs.coverageOf(nhs.level('N/O')), Coverage.missing);
      expect(nhs.coverageOf(nhs.level('1')), Coverage.thin);
      expect(nhs.coverageOf(nhs.level('2')), Coverage.evidenced);

      final cs = Framework.of('civil_service').scale;
      expect(cs.codes, ['1', '2', '3', '4', '5', '6', '7']);
      expect(cs.noEvidence.label, 'Not demonstrated');
      expect(cs.coverageOf(cs.level('3')), Coverage.thin);
      expect(cs.coverageOf(cs.level('4')), Coverage.evidenced);
      expect(cs.passRule, contains('4 or more'));

      expect(Framework.of('hsc_ni').scale.codes, ['0', '1', '2', '3']);
      expect(Framework.of('unknown').id, 'private');
      for (final f in frameworks) {
        expect(f.scale.source, isNotEmpty, reason: f.id);
        expect(f.examples, isNotEmpty, reason: f.id);
        for (final l in f.scale.levels) {
          expect(l.anchor, isNotEmpty, reason: '${f.id} ${l.code}');
        }
      }
    });
  });

  group('evidence quotes', () {
    test('a quote must be in the transcript, ignoring case, punctuation and fillers', () {
      const said = 'Um, so I rang each patient on the list, and, uh, I moved the overflow to Tuesday.';
      expect(quoteInTranscript('I rang each patient on the list', said), isTrue);
      expect(quoteInTranscript('"i RANG each patient" … moved the overflow to Tuesday', said), isTrue);
      expect(quoteInTranscript('I rang every patient on the list', said), isFalse);
      expect(quoteInTranscript('moved the overflow … I rang each patient', said), isFalse);
      // Too short to be evidence.
      expect(quoteInTranscript('I rang', said), isFalse);
      expect(quoteInTranscript('', said), isFalse);
    });

    test('a fabricated quote is dropped and the criterion reads as not observed', () {
      final scale = Framework.of('nhs_values').scale;
      final raw = parseScoring({
        'answers': [
          {
            'question': 2,
            'scores': [
              {'criterion': 'c1', 'level': '3', 'quote': 'I rang each patient on the list'},
            ],
            'strength': 'A clear example.',
            'fix': 'Say how long it took.',
          },
          {
            'question': 3,
            'scores': [
              {'criterion': 'c2', 'level': '4', 'quote': 'I set up a weekly huddle for the whole team'},
              {'criterion': 'c1', 'level': '2', 'quote': 'I value working together'},
              {'criterion': 'c2', 'level': '9', 'quote': 'I value working together'},
            ],
            'strength': 'Named the value.',
            'fix': 'Give one real example.',
          },
        ],
      });
      expect(raw.map((a) => a.question), [1, 2]);
      final v = verifyScores(
        raw,
        scale,
        heard: {1: fullAnswer, 2: bareClaim},
        asked: {
          1: ['c1'],
          2: ['c2'],
        },
      );
      // Kept: c1 on question 1. c2's invented huddle becomes N/O; c1 is not
      // what question 2 tests; level 9 is not on the scale.
      expect(v.dropped, 3);
      expect(
        [for (final s in v.scores) '${s.question}:${s.criterionId}:${s.level.code}'],
        ['1:c1:3', '2:c2:N/O'],
      );
      expect(v.answers[1]!.fix, 'Say how long it took.');
    });
  });

  group('a claim without an example', () {
    final scale = Framework.of('nhs_values').scale;
    Verified score(String answer, String quote, {String level = '1', ScoringScale? on}) => verifyScores(
      [
        AnswerScore(
          question: 0,
          scores: [CriterionScore(criterionId: 'c2', code: level, quote: quote)],
        ),
      ],
      on ?? scale,
      heard: {0: answer},
      asked: {
        0: ['c2'],
      },
    );

    test('a bare claim reads as no evidence, whatever the provider scored', () {
      final v = score(bareClaim, 'I am a very good team player');
      expect(v.dropped, 0);
      expect(v.scores.single.level.code, 'N/O');
      expect(v.scores.single.quote, '');
      expect(v.scores.single.reason, claimReason);
      // On a scale whose lowest level is a number, the same.
      final ks = Framework.of('hsc_ni').scale;
      expect(score(bareClaim, 'I value working together', on: ks).scores.single.level.code, '0');
      for (final claim in [
        "I'm passionate about patient care and I always give a hundred and ten percent.",
        "I'm a people person.",
        'I always put the team first.',
        'People say I am easy to work with.',
        "I've got really good communication skills.",
      ]) {
        final quote = claim.replaceAll(RegExp(r'[.]$'), '');
        // "a hundred and ten percent" is a number: that one is kept.
        final kept = claim.contains('hundred');
        expect(claimWithoutExample(quote, claim), !kept, reason: claim);
      }
    });

    test('a hypothetical "I would" with nothing done reads as no evidence', () {
      const answer = 'I would talk to the team and I would make sure everyone felt listened to.';
      final v = score(answer, 'I would talk to the team');
      expect(v.scores.single.level.code, 'N/O');
      expect(v.scores.single.claimOnly, isTrue);
    });

    test('a claim with an example behind it keeps its score', () {
      const answer =
          'I am a good team player. When a colleague was off sick last winter, I took over her clinic list and '
          'I rang every patient so nobody missed an appointment.';
      // The quote is the claim, but the answer goes on to a real instance.
      final v = score(answer, 'I am a good team player');
      expect(v.scores.single.level.code, '1');
      expect(v.scores.single.reason, '');
      // A claim sentence followed by its own action is kept.
      const same = "I'm good at working together, I set up a shared rota for the reception team.";
      expect(claimWithoutExample("I'm good at working together", same), isFalse);
      // A past action of the speaker's is evidence.
      final w = score(answer, 'I took over her clinic list');
      expect(w.scores.single.level.code, '1');
    });

    test('a number or a result is kept', () {
      const numbers = 'I am always on time: the clinic list went out by 8am every day for 2 years.';
      expect(score(numbers, 'I am always on time').scores.single.level.code, '1');
      const result = 'I always check the list twice, and as a result the errors stopped.';
      expect(score(result, 'I always check the list twice').scores.single.level.code, '1');
      // An action told in the present, not a self-description, is left to
      // the provider's score.
      const habit = "I check the patient's date of birth before I open a record.";
      expect(score(habit, "I check the patient's date of birth").scores.single.level.code, '1');
    });

    test('the debrief says why a claim scored nothing', () {
      final r = DebriefRound.of(
        questions: questionsFromProfile(profile),
        answers: {2: bareClaim},
        profile: profile,
      );
      final v = verifyScores(
        [
          const AnswerScore(
            question: 2,
            scores: [CriterionScore(criterionId: 'c2', code: '1', quote: 'I am a very good team player')],
          ),
        ],
        scale,
        heard: r.heard,
        asked: r.asked,
      );
      final d = Debrief.build(framework: Framework.of('nhs_values'), round: r, verified: v);
      final c2 = d.coverage.firstWhere((c) => c.criterion.id == 'c2');
      expect(c2.status, Coverage.missing);
      expect(c2.note, claimNote);
    });
  });

  group('feedback wording', () {
    test('a fix that talks about scores is cut back to the action, or dropped', () {
      // Cut back to the task-level part.
      expect(
        taskLevelText('Add how you measured the change, to move toward a 3.'),
        'Add how you measured the change.',
      );
      expect(
        taskLevelText('Say what you yourself did so that the panel can score you higher.'),
        'Say what you yourself did.',
      );
      expect(
        taskLevelText('Name the result. This would lift the answer from a 2 to a 3.'),
        'Name the result.',
      );
      // Nothing task-level left: empty, so the debrief uses its own wording.
      expect(taskLevelText('Aim for a 3 next time.'), '');
      expect(taskLevelText('Move toward level 4.'), '');
      expect(taskLevelText('This scored N/O.'), '');
      expect(taskLevelText('3/4 is within reach.'), '');
      // Task-level fixes with numbers that are not scores are left alone.
      for (final ok in [
        'Lead with the result in the first 30 seconds.',
        'Keep the answer to 2 minutes.',
        'Give three points, each with evidence.',
        'Say how you knew it worked: a number, a check or feedback.',
        'Cut the answer to 2 sentences of background.',
      ]) {
        expect(mentionsScale(ok), isFalse, reason: ok);
        expect(taskLevelText(ok), ok);
      }
      // The app's own fixes and recovery lines pass the check.
      for (final own in [...elementFixes.values, overTimeFix]) {
        expect(mentionsScale(own), isFalse, reason: own);
      }
    });

    test('scored feedback with scale talk is checked before the debrief shows it', () {
      final scale = Framework.of('nhs_values').scale;
      final v = verifyScores(
        parseScoring({
          'answers': [
            {
              'question': 1,
              'scores': [
                {'criterion': 'c1', 'level': '3', 'quote': 'I rang each patient on the list'},
              ],
              'strength': 'A clear example, worth a 3.',
              'fix': 'Move toward a 4.',
            },
          ],
        }),
        scale,
        heard: {0: fullAnswer},
        asked: {
          0: ['c1'],
        },
      );
      expect(v.answers[0], (strength: 'A clear example.', fix: ''));
      // The debrief falls back to its own task-level fix.
      final d = Debrief.build(
        framework: Framework.of('nhs_values'),
        round: DebriefRound.of(
          questions: questionsFromProfile(profile),
          answers: {0: fullAnswer},
          profile: profile,
        ),
        verified: v,
      );
      for (final n in d.notes) {
        expect(mentionsScale(n.fix), isFalse, reason: n.fix);
        expect(n.fix, isNotEmpty);
      }
    });
  });

  group('the debrief', () {
    DebriefRound round(Map<int, String> answers) =>
        DebriefRound.of(questions: questionsFromProfile(profile), answers: answers, profile: profile);

    test('coverage comes first, and a missing essential is flagged', () {
      final r = round({0: 'I work on reception.', 1: fullAnswer, 2: bareClaim});
      final scale = Framework.of('nhs_values').scale;
      final v = verifyScores(
        [
          const AnswerScore(
            question: 1,
            scores: [
              CriterionScore(
                criterionId: 'c1',
                code: '3',
                quote: 'the double bookings fell from nine a week to one',
              ),
            ],
            strength: 'A measured result.',
            fix: 'Say what you learned.',
          ),
          const AnswerScore(
            question: 2,
            scores: [CriterionScore(criterionId: 'c2', code: 'N/O')],
          ),
        ],
        scale,
        heard: r.heard,
        asked: r.asked,
      );
      final d = Debrief.build(framework: Framework.of('nhs_values'), round: r, verified: v);
      expect(d.aiScored, isTrue);
      expect(d.coverage.first.criterion.essential, isTrue);
      final byId = {for (final c in d.coverage) c.criterion.id: c};
      expect(byId['c1']!.status, Coverage.evidenced);
      expect(byId['c1']!.best!.level.label, 'Very good');
      expect(byId['c2']!.status, Coverage.missing);
      // Typing is left to the test: not asked, and not held against you.
      expect(byId['c3']!.asked, isFalse);
      expect(byId['c3']!.note, 'Assessed by the test, not at interview.');
      expect(byId['c3']!.unappointable, isFalse);
      expect(d.missingEssentials.map((c) => c.criterion.id), ['c2']);
      expect(d.recoveryLines, contains(Recovery.addLater('Working together')));
      final scores = {for (final s in d.scoreLines()) s.criterion.id: s};
      expect(scores['c1']!.level.anchor, nhsScale.levels[3].anchor);
      expect(scores['c2']!.level.code, 'N/O');
      final note1 = d.notes.firstWhere((n) => n.question == 1);
      expect(note1.strength, 'A measured result.');
      expect(note1.good, isTrue);
      final note2 = d.notes.firstWhere((n) => n.question == 2);
      expect(note2.good, isFalse);
      expect(note2.recovery, isNotEmpty);
      // One strength and one fix; no percentages anywhere.
      for (final n in d.notes) {
        expect('${n.strength}${n.fix}', isNot(contains('%')));
      }
    });

    test('without an AI, coverage comes from the matcher alone', () {
      final r = round({
        1: fullAnswer,
        2: bareClaim,
        3: 'I set up the records system and I updated it every day.',
      });
      final d = Debrief.build(framework: Framework.of('nhs_values'), round: r);
      expect(d.aiScored, isFalse);
      expect(d.scoreLines(), isEmpty);
      final byId = {for (final c in d.coverage) c.criterion.id: c.status};
      expect(byId['c1'], Coverage.evidenced);
      expect(byId['c2'], Coverage.missing);
      expect(byId['c4'], Coverage.thin);
      expect(d.missingEssentials.first.criterion.id, 'c2');
      final note = d.notes.firstWhere((n) => n.question == 2);
      expect(note.fix, 'Say what you yourself did, with "I", before what the team did.');
      expect(note.recovery, Recovery.betterExample);
      expect(d.notes.firstWhere((n) => n.question == 1).good, isTrue);
    });

    test('a round with no profile is checked against its questions, none essential', () {
      final qs = [
        profileSettler,
        const PracticeQuestion({
          'question': 'Tell us about a time you improved a process.',
          'category': 'Behavioural',
          'why': 'Improving quality',
        }),
      ];
      final r = DebriefRound.of(
        questions: qs,
        answers: {1: 'Follow-up: "What did you yourself do?"\n$fullAnswer'},
      );
      expect(r.fromProfile, isFalse);
      expect(r.heard[1], fullAnswer);
      final d = Debrief.build(framework: Framework.of('private'), round: r);
      expect(d.coverage.single.criterion.text, 'Improving quality');
      expect(d.missingEssentials, isEmpty);
    });
  });

  group('records', () {
    late CareerBook book;
    setUp(() async {
      final db = memoryDatabase();
      addTearDown(db.close);
      book = CareerBook(await Store.open(db));
    });

    test('a good practice answer saves to the story bank, marked as from practice', () async {
      final d = storyFromAnswer(
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
