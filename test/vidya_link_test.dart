import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart' show Criterion, CriterionKind, RoleProfile;
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/ai.dart' show AiResult;
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/pipeline.dart';
import 'package:udyoga/domain/vidya_link.dart';
import 'package:udyoga/ui/job_page.dart';

import 'app_harness.dart';

import 'support.dart';

/// Vidya's portfolio Markdown, as its Portfolio page copies it.
const _portfolio = '''
# Portfolio

## Skills

- **Interview:** Communication (Proficient)
- **Digital:** SystmOne (Competent), Excel (Learning)

## Learning completed

- Care Certificate (Certification, Skills for Health, 3 Nov 2026)
- RTT rules (Course, 1 Nov 2026)
- A practice round (Practice, 2 Nov 2026)

---

12 hours of study · 4 topics · 2 courses completed
''';

void main() {
  group('job journeys', journeyTests);
  late CareerBook book;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
  });

  test('the Vidya plan carries the weak competencies, job gaps, learning and stories', () async {
    final id = (await book.importPostings([samplePosting()], sampleProfile, today: '2026-11-15')).single;
    await book.saveAssessment(
      id,
      const FitAssessment({
        'fit': 60,
        'gaps': [
          {'requirement': 'SystmOne experience', 'severity': 'major', 'mitigation': 'Do the e-learning.'},
        ],
      }),
    );
    await book.suggestLearning([
      const LearningSuggestion(
        title: 'Care Certificate',
        kind: 'certification',
        provider: 'Skills for Health',
      ),
    ], today: '2026-11-15');
    await book.addStories(
      [
        const StoryDraft(
          title: 'E-obs training',
          action: 'I trained 40 staff.',
          result: 'Live on time.',
          competencies: ['supporting'],
        ),
      ],
      source: 'manual',
      today: '2026-11-15',
    );

    final plan = await book.vidyaPlanNow();
    expect((plan['format'], plan['version']), ('vidya-curriculum', 1));
    expect((plan['program'] as Map)['title'], 'Interview ready: Clinical Informatics Nurse');
    final courses = [for (final c in plan['courses'] as List) c as Map];
    expect(courses.map((c) => c['title']), [
      'Interview stories',
      'Gaps for Clinical Informatics Nurse at Example Health Trust',
      'Care Certificate',
    ]);
    // Every competency is short of a confirmed pair of stories.
    expect((courses.first['topics'] as List).length, competencyNames.length);
    expect(((courses[1]['topics'] as List).single as Map)['details'], 'Severity: major. Do the e-learning.');
    final card = (plan['cards'] as List).single as Map;
    // A stable id, so an edited story updates its Vidya card in place.
    final story = (await book.stories()).single;
    expect(card['id'], 'udyoga.story.${story.id}');
    expect(card['deck'], 'Interview stories');
    expect(card['front'], 'Tell your story: E-obs training (${competencyNames['supporting']})');
    expect(card['back'], 'Action: I trained 40 staff.\nResult: Live on time.');
    expect((plan['skills'] as List).length, competencyNames.length);
    // Plain JSON a file can carry.
    expect(jsonDecode(jsonEncode(plan)), plan);
  });

  test('the Vidya portfolio is read: completed learning and skills rated Competent or better', () {
    final done = parseVidyaPortfolio(_portfolio);
    expect(done.learning, [
      (
        title: 'Care Certificate',
        kind: 'certification',
        provider: 'Skills for Health',
        finished: '3 Nov 2026',
      ),
      (title: 'RTT rules', kind: 'course', provider: '', finished: '1 Nov 2026'),
    ]);
    expect(done.skills, ['SystmOne']);
  });

  test('what Vidya finished marks learning done and adds skills, once', () async {
    await book.suggestLearning([const LearningSuggestion(title: 'Care certificate')], today: '2026-11-10');
    final done = parseVidyaPortfolio(_portfolio);
    expect(await book.importVidya(done, today: '2026-11-15'), (learning: 2, skills: 1));
    final growth = await book.db.select(book.db.careerGrowth).get();
    expect(growth.map((g) => (g.title, g.status)).toSet(), {
      ('Care certificate', 'done'),
      ('RTT rules', 'done'),
    });
    expect((await book.profile()).skills, contains('SystmOne'));
    expect(await book.importVidya(done, today: '2026-11-16'), (learning: 0, skills: 0));
  });

  test('through sync: the plan goes out as one row, Vidya\'s progress comes back to the profile', () async {
    var link = await book.vidyaBridge();
    expect((link.sent, link.added), (null, false));
    expect([...link.done.learning, ...link.done.skills], isEmpty);

    await book.sendToVidya(now: '2026-11-16T09:00:00Z');
    await book.sendToVidya(now: '2026-11-16T10:00:00Z');
    final rows = await book.db.select(book.db.bridgeStudyPlans).get();
    expect(rows.map((r) => (r.id, r.source, r.updated)), [(studyPlanId, 'udyoga', '2026-11-16T10:00:00Z')]);
    expect(jsonDecode(rows.single.plan), containsPair('format', 'vidya-curriculum'));
    expect(await book.db.select(book.db.outbox).get(), isNotEmpty, reason: 'it syncs');

    // As Vidya's reply arrives through sync (Vidya's fixture).
    Future<void> reply(String planUpdated) => book.db
        .into(book.db.bridgeStudyProgress)
        .insertOnConflictUpdate(
          BridgeStudyProgressCompanion.insert(
            id: studyPlanId,
            planUpdated: Value(planUpdated),
            progress: Value(File('test/fixtures/vidya-progress.json').readAsStringSync()),
            updated: 'T',
          ),
        );
    await reply('2026-11-16T09:00:00Z');
    link = await book.vidyaBridge();
    expect(link.added, isFalse, reason: 'Vidya added an older version');
    await reply('2026-11-16T10:00:00Z');
    link = await book.vidyaBridge();
    expect(link.added, isTrue);
    expect(link.done.learning.map((l) => (l.title, l.kind, l.provider)), [
      ('Care Certificate', 'certification', 'Skills for Health'),
    ]);
    expect(link.done.skills, ['SystmOne'], reason: 'Competent or better only');

    expect(await book.vidyaNew(link.done), (learning: 1, skills: 1));
    await book.importVidya(link.done, today: '2026-11-16');
    expect(await book.vidyaNew(link.done), (learning: 0, skills: 0));
  });

  test('the plan fixture shared with Vidya is current', () async {
    // Vidya's tests parse this file, so a change in the plan shows there.
    await book.addStories(
      [
        const StoryDraft(title: 'Fixture story', action: 'I did the thing.', competencies: ['teamwork']),
      ],
      source: 'manual',
      today: '2026-11-15',
    );
    // Story ids are random: the fixture has a fixed one.
    final id = (await book.stories()).single.id;
    final plan = const JsonEncoder.withIndent('  ')
        .convert(await book.vidyaPlanNow())
        .replaceAll(id, 'fixture-story');
    final fixture = File('test/fixtures/udyoga-plan.json');
    if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
      await fixture.parent.create(recursive: true);
      await fixture.writeAsString('$plan\n');
    }
    expect(await fixture.readAsString(), '$plan\n');
  });
}

void journeyTests() {
  late CareerBook book;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
  });

  Future<Job> job() async {
    final id = (await book.importPostings(
      [samplePosting(url: 'https://example.org/jobs/123', closing: '2026-12-10')],
      sampleProfile,
      today: '2026-11-15',
    )).single;
    return (await (book.db.select(book.db.jobListings)..where((j) => j.id.equals(id))).getSingle());
  }

  test('the sector guess reads the interview framework, then the employer\'s name', () {
    expect(journeySector(framework: 'nhs_values'), 'nhs');
    expect(journeySector(framework: 'hsc_ni', employer: 'Example Ltd'), 'nhs');
    expect(journeySector(framework: 'civil_service'), 'civil-service');
    expect(journeySector(employer: 'Example Health Trust'), 'nhs');
    expect(journeySector(employer: 'NHS Example'), 'nhs');
    expect(journeySector(employer: 'Example Trust'), 'other');
    expect(journeySector(employer: 'University of Exampleton'), 'university');
    expect(journeySector(employer: 'Department for Examples'), 'civil-service');
    expect(journeySector(employer: 'Example Widgets Ltd'), 'private');
    expect(journeySector(employer: 'Exampleton'), 'other');
  });

  test(
    '"Prepare this job" sends only the job\'s data: role, employer, criteria, sector, advert, closing date',
    () async {
      final j = await job();
      // Without a role profile the AI fit assessment's requirements are the criteria.
      await book.saveAssessment(
        j.id,
        const FitAssessment({
          'fit': 60,
          'matched': [
            {'requirement': 'Registered nurse'},
          ],
          'gaps': [
            {'requirement': 'SystmOne experience', 'severity': 'major'},
          ],
        }),
      );
      final fresh = await (book.db.select(book.db.jobListings)..where((x) => x.id.equals(j.id))).getSingle();
      final id = await book.sendJobToVidya(fresh, now: '2026-11-21T09:00:00Z');
      expect(id, jobPlanId(j.id));
      var plan = decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan);
      expect((plan['format'], plan['version']), ('vidya-curriculum', 1));
      expect(plan['journey'], {
        'role': 'Clinical Informatics Nurse',
        'employer': 'Example Health Trust',
        'sector': 'nhs',
        'advertUrl': 'https://example.org/jobs/123',
        'closes': '2026-12-10',
        'advertText': 'Support EPR systems and patient safety training across wards.',
      });
      expect(
        [for (final c in plan['criteria'] as List) (c as Map)['text']],
        ['Registered nurse', 'SystmOne experience'],
      );
      // Nothing to teach: the templates live in Vidya.
      expect(plan['courses'], isEmpty);
      expect(jsonEncode(plan), isNot(contains('teach')));
      expect((plan['notes'] as List).single.toString(), contains('Closes: 10 Dec 2026'));

      // A checked role profile wins over the AI's list, and its framework sets the sector.
      await book.saveRoleProfile(
        RoleProfile(
          id: '',
          title: 'Clinical Informatics Nurse',
          frameworkId: 'civil_service',
          jobId: j.id,
          criteria: const [
            Criterion(id: 'c1', text: 'Excellent written communication'),
            Criterion(id: 'c2', text: 'Knowledge of NHS systems', essential: false),
          ],
        ),
        at: '2026-11-21T09:00',
      );
      await book.sendJobToVidya(j, now: '2026-11-21T10:00:00Z');
      plan = decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan);
      expect((plan['journey'] as Map)['sector'], 'civil-service');
      expect(
        [for (final c in plan['criteria'] as List) ((c as Map)['id'], c['essential'])],
        [('c1', true), ('c2', false)],
      );
    },
  );

  test('moving the application on sends the journey again, only once it was sent', () async {
    final j = await job();
    final app = await book.applyFor(j, today: '2026-11-15');
    await book.moveTo(app, Stage.applied, date: '2026-11-16');
    expect(await book.db.select(book.db.bridgeStudyPlans).get(), isEmpty);

    await book.sendJobToVidya(j, now: '2026-11-21T09:00:00Z');
    Future<Object?> sent() async =>
        (decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan)['journey']
            as Map)['applicationStage'];
    expect(await sent(), 'applied');
    await book.moveTo(app, Stage.interview, date: '2026-11-25');
    expect(await sent(), 'interview');
    expect(await book.db.select(book.db.bridgeStudyPlans).get(), hasLength(1));
  });

  test('employer research reaches Vidya as proposed facts, with their sources', () async {
    expect(employerFacts(null), isEmpty);
    expect(
      employerFacts(
        const EmployerBrief({
          'culture': [
            {'point': 'Rated good by the regulator (2024).', 'source': 'https://example.org/report'},
            {'point': 'Rated good by the regulator (2024).', 'source': 'https://example.org/report'},
            {'point': 'No address.', 'source': 'example.org/report'},
            {'point': '', 'source': 'https://example.org/empty'},
          ],
          'sources': [
            {'title': 'Example inspection report', 'url': 'https://example.org/report'},
          ],
        }),
      ),
      [
        {
          'claim': 'Rated good by the regulator (2024).',
          'url': 'https://example.org/report',
          'title': 'Example inspection report',
        },
      ],
    );

    // Research saved after the job was sent goes out with the plan again.
    final j = await job();
    await book.sendJobToVidya(j, now: '2026-11-21T09:00:00Z');
    Future<Map> journey() async =>
        decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan)['journey'] as Map;
    expect((await journey())['facts'], isNull);
    expect((await journey())['advertText'], 'Support EPR systems and patient safety training across wards.');
    await book.saveEmployerBrief(
      'example health trust',
      const AiResult({
        'culture': [
          {'point': 'A new day surgery unit opens in 2027.', 'source': 'https://example.org/strategy'},
        ],
      }),
      at: '2026-11-22T09:00',
    );
    expect((await journey())['facts'], [
      {'claim': 'A new day surgery unit opens in 2027.', 'url': 'https://example.org/strategy'},
    ]);
    // Research on another employer leaves it alone.
    await book.saveEmployerBrief(
      'Another Example Trust',
      const AiResult({'culture': []}),
      at: '2026-11-23T09:00',
    );
    expect((await journey())['facts'], hasLength(1));
  });

  test('the offer-to-start checks ride in the journey and are sent again when one changes', () async {
    final j = await job();
    final app = await book.applyFor(j, today: '2026-11-15');
    await book.sendJobToVidya(j, now: '2026-11-21T09:00:00Z');
    Future<Map> journey() async =>
        decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan)['journey'] as Map;
    expect((await journey())['checks'], isNull);
    await book.moveTo(app, Stage.offer, date: '2026-12-20');
    await book.moveTo(app, Stage.checks, date: '2026-12-21');
    var checks = (await journey())['checks'] as List;
    expect(checks.map((c) => (c as Map)['kind']), [for (final s in CareerBook.offerSteps) s.$1]);
    expect((checks.first as Map)['status'], 'todo');
    expect((checks.first as Map)['due'], '2026-12-28', reason: '5 working days after the checks began');
    final id = (await book.checks(app)).first;
    await book.setCheck(id, 'done', today: '2026-12-22', notes: 'Passport number 123 (never sent)');
    checks = (await journey())['checks'] as List;
    expect(checks.first, {
      'kind': 'identity',
      'title': CareerBook.offerSteps.first.$2,
      'status': 'done',
      'due': '2026-12-28',
      'done': '2026-12-22',
    });
    expect(jsonEncode(await journey()), isNot(contains('Passport')), reason: 'notes stay in Udyoga');
  });

  test('the checks plan fixture shared with Vidya is current', () async {
    // Vidya's tests parse this file for its checks stage.
    final j = await job();
    final app = await book.applyFor(j, today: '2026-11-15');
    await book.moveTo(app, Stage.offer, date: '2026-12-20');
    await book.moveTo(app, Stage.checks, date: '2026-12-21');
    final all = await book.checks(app);
    await book.setCheck(all.firstWhere((c) => c.kind == 'identity'), 'done', today: '2026-12-22');
    await book.setCheck(all.firstWhere((c) => c.kind == 'references'), 'sent', today: '2026-12-22');
    await book.setCheck(all.firstWhere((c) => c.kind == 'contract'), 'not_needed', today: '2026-12-22');
    await book.sendJobToVidya(j, now: '2026-12-22T09:00:00Z');
    final plan = const JsonEncoder.withIndent('  ')
        .convert(decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan))
        .replaceAll(j.id, 'fixture-job');
    final fixture = File('test/fixtures/udyoga-checks-plan.json');
    if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
      await fixture.parent.create(recursive: true);
      await fixture.writeAsString('$plan\n');
    }
    expect(await fixture.readAsString(), '$plan\n');
  });

  test('the job plan fixture shared with Vidya is current', () async {
    // Vidya's tests parse this file. Job ids are random: the fixture has a fixed one.
    final j = await job();
    final app = await book.applyFor(j, today: '2026-11-15');
    await book.moveTo(app, Stage.applied, date: '2026-11-16');
    final id = await book.saveRoleProfile(
      RoleProfile(
        id: '',
        title: 'Clinical Informatics Nurse',
        frameworkId: 'nhs_values',
        jobId: j.id,
        criteria: const [
          Criterion(id: 'c1', text: 'Excellent written communication'),
          Criterion(id: 'c2', text: 'Experience of managing a diary'),
          Criterion(id: 'c3', text: 'Working together', kind: CriterionKind.value, essential: false),
        ],
      ),
      at: '2026-11-21T09:00',
    );
    expect(id, isNotEmpty);
    await book.saveEmployerBrief(
      'Example Health Trust',
      const AiResult(
        {
          'employer': 'Example Health Trust',
          'summary': 'A made-up hospital trust.',
          'culture': [
            {
              'point': '64% of staff would recommend the trust as a place to work (2025).',
              'source': 'https://example.org/staff-survey',
            },
            {'point': 'A point with no web address is left out.', 'source': ''},
          ],
        },
        sources: [(title: 'Example staff survey 2025', url: 'https://example.org/staff-survey')],
      ),
      at: '2026-11-20T09:00',
    );
    await book.sendJobToVidya(j, now: '2026-11-21T09:00:00Z');
    final plan = const JsonEncoder.withIndent('  ')
        .convert(decodeObject((await book.db.select(book.db.bridgeStudyPlans).get()).single.plan))
        .replaceAll(j.id, 'fixture-job');
    final fixture = File('test/fixtures/udyoga-job-plan.json');
    if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
      await fixture.parent.create(recursive: true);
      await fixture.writeAsString('$plan\n');
    }
    expect(await fixture.readAsString(), '$plan\n');
  });

  testWidgets('a saved job\'s page has "Prepare this job", which sends it to Vidya', (tester) async {
    final app = AppHarness(tester)..phone();
    late String id;
    await app.open(
      seed: (b) async {
        await b.saveProfile(sampleProfile);
        id = (await b.importPostings([samplePosting()], sampleProfile, today: '2026-11-15')).single;
      },
    );
    await app.run(home: JobPage(id));
    expect(find.byKey(const Key('job-prepare')), findsNothing, reason: 'not saved yet');
    await app.tapText('Save');
    await app.tap(find.byKey(const Key('job-prepare')));
    expect(find.textContaining('Vidya'), findsWidgets);
    final rows = await tester.runAsync(() => app.book.db.select(app.book.db.bridgeStudyPlans).get());
    expect(rows!.single.id, jobPlanId(id));
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
