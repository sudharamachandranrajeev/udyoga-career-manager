// Role path insight, "Approach this role" (role search plan U4): the
// device's part needs no AI, AI parts are marked, insights are saved and
// reopen without AI, stepping stones open role search, keyed career data is
// never asked without a key, and "Study for this role" sends Vidya the gaps
// with the role's criteria. Made-up data only; no keys anywhere.
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_data.dart';
import 'package:udyoga/domain/job_identity.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/occupations.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/role_family.dart';
import 'package:udyoga/domain/role_insight.dart';
import 'package:udyoga/domain/vidya_link.dart';
import 'package:udyoga/ui/role_insight_page.dart';
import 'package:udyoga/ui/role_search_view.dart';

import 'app_harness.dart';
import 'support.dart';

const today = '2026-11-21';
const role = 'IT Trainer';

/// The sample profile, aiming at IT trainer roles.
final profile = CandidateProfile.fromJson({
  ...sampleProfile.toJson(),
  'targets': {
    ...sampleProfile.targets.toJson(),
    'roles': [role, 'Digital Nurse Specialist'],
  },
});

// A made-up ESCO occupation for IT trainers, in the ESCO API's shape.
const _trainerUri = 'http://data.europa.eu/esco/occupation/trainer-example';

/// A web stand-in: made-up ESCO answers; records every request.
class _Web {
  final requests = <http.Request>[];

  late final http.Client client = MockClient((r) async {
    requests.add(r);
    if (r.url.host == 'ec.europa.eu' && r.url.path.endsWith('/search')) {
      return http.Response(
        jsonEncode({
          '_embedded': {
            'results': [
              {'title': 'ICT trainer', 'code': '2356.1', 'uri': _trainerUri},
            ],
          },
        }),
        200,
      );
    }
    if (r.url.queryParameters['uri'] == _trainerUri) {
      return http.Response(
        jsonEncode({
          'uri': _trainerUri,
          'title': 'ICT trainer',
          'code': '2356.1',
          'preferredLabel': {'en': 'ICT trainer'},
          'alternativeLabel': {
            'en': ['ICT instructor'],
          },
          '_links': {
            'hasEssentialSkill': [
              {'title': 'ensure patient safety'},
              {'title': 'create training materials'},
            ],
            'hasOptionalSkill': [
              {'title': 'online moderation techniques'},
            ],
          },
        }),
        200,
      );
    }
    return http.Response('{}', 404);
  });

  Iterable<Uri> to(String host) => requests.where((r) => r.url.host.contains(host)).map((r) => r.url);
}

/// An AI that answers [answer] and counts how often it is asked.
class _FakeAi implements Ai {
  _FakeAi(this.answer);
  final Json answer;
  var asked = 0;
  Json? schema;

  @override
  String get model => 'fake-model';

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
    asked++;
    this.schema = schema;
    return AiResult(answer, sources: [(title: 'Example careers page', url: 'https://careers.example.org/it-trainer')]);
  }
}

/// A made-up answer in the shape of [RoleInsight.aiSchema].
final Json aiAnswer = {
  'summary': 'Teaches staff to use computer systems, in classrooms and on the ward.',
  'fit': 55,
  'gaps': [
    {
      'gap': 'Formal teaching qualification',
      'severity': 'major',
      'howToClose': 'Take a short Level 3 award in education and training.',
      'criterion': 'Teaching qualification',
    },
    {
      'gap': 'Create training materials',
      'severity': 'minor',
      'howToClose': 'Write a one-page guide for the e-observations system.',
      'criterion': 'create training materials',
    },
  ],
  'waysIn': [
    {'kind': 'internal', 'title': 'Super-user role on a system roll-out', 'detail': 'Ask your ward manager.', 'url': ''},
    {'kind': 'secondment', 'title': 'Secondment to the digital team', 'detail': 'Six months.', 'url': ''},
  ],
  'steppingStones': [
    {
      'role': 'Clinical Systems Trainer',
      'why': 'Trains clinical staff on the same systems.',
      'exampleTitles': ['EPR Trainer', 'Digital Systems Trainer'],
      'timeframe': '12-18 months',
    },
    {
      'role': 'Digital Champion',
      'why': 'Shows you can lead others on new systems.',
      'exampleTitles': ['Digital Ward Champion'],
      'timeframe': '6-12 months',
    },
  ],
  'pay': {
    'nhsBand': 'Band 5',
    'figures': [
      {'label': 'Starter', 'amount': '£30,000 a year', 'source': 'Example pay survey', 'asOf': '2026'},
    ],
    'progression': ['Senior trainer or training lead after 2-3 years.'],
  },
  'howPeopleGotIn': ['Check whether they were super-users first.'],
  'firstMoves': [
    {'move': 'Ask to be a super-user on the next roll-out.', 'criterion': 'Create training materials'},
    {'move': 'Book the Level 3 award.', 'criterion': 'Formal teaching qualification'},
  ],
  'cvWording': [
    {'experience': 'Trained 40 staff', 'inTargetTerms': 'Delivered system training to 40 clinical staff'},
  ],
  'path': [
    {'role': 'Staff Nurse', 'stage': 'now', 'timeframe': 'now', 'likelihood': 100},
    {'role': 'Clinical Systems Trainer', 'stage': 'stepping_stone', 'timeframe': '1 year', 'likelihood': 70},
    {'role': role, 'stage': 'target', 'timeframe': '2 years', 'likelihood': 55},
    {'role': 'Training Lead', 'stage': 'beyond', 'timeframe': '4 years', 'likelihood': 30},
  ],
  'sources': [
    {'title': 'Example careers page', 'url': 'https://careers.example.org/it-trainer'},
  ],
};

Future<CareerBook> _book() async => CareerBook(await Store.open(memoryDatabase()));

RoleInsightBuilder _builder(CareerBook b, _Web web, {Ai? ai, List<CareerDataSource> keyed = const []}) =>
    RoleInsightBuilder(
      families: RoleFamilies(web.client, b.db),
      advisor: ai == null ? null : Advisor(ai, today: today),
      keyed: keyed,
      today: today,
    );

/// A fixed insight for the fixture and widget tests: no web, no clock.
RoleInsight fixedInsight({String target = role, bool withAiParts = true}) {
  final base = offlineInsight(
    target,
    profile,
    family: offlineFamily(target),
    skills: const RoleSkills(
      role: role,
      occupation: EscoOccupation(uri: _trainerUri, title: 'ICT trainer'),
      essential: ['ensure patient safety', 'create training materials'],
      optional: ['online moderation techniques'],
    ),
    today: today,
  );
  return withAiParts ? withAi(base, aiAnswer, model: 'fake-model', today: today) : base;
}

// Made-up Skills England answers in the shape of its OpenAPI file.
final _seOccupation = {
  'stdCode': 'OCC9001',
  'name': 'Learning and skills teacher',
  'level': 5,
  'summary': 'Made-up summary: teaches adults at work.',
  'medianAnnualSalaryinGBP': 31000,
  'typicalJobTitles': [
    {'name': 'IT trainer', 'isGreen': false},
  ],
  'products': [
    {'name': 'Example teacher apprenticeship', 'level': 5, 'typeName': 'Apprenticeship', 'productCode': 'ST9001'},
  ],
};
final _seProgression = {
  'keyStdCode': 'OCC9001',
  'occupations': [
    _seOccupation,
    {
      'stdCode': 'OCC9000',
      'name': 'Teaching assistant',
      'typicalJobTitles': [
        {'name': 'classroom assistant'},
      ],
    },
    {'stdCode': 'OCC9002', 'name': 'Training manager'},
  ],
  'progressions': [
    {'stdCodeFrom': 'OCC9000', 'stdCodeTo': 'OCC9001'},
    {'stdCodeFrom': 'OCC9001', 'stdCodeTo': 'OCC9002'},
  ],
};

void main() {
  test('the device fills the role, skills, gaps, pay and checklist without AI', () async {
    final b = await _book();
    final web = _Web();
    final i = await _builder(b, web).build(role, profile);
    expect(web.to('ec.europa.eu'), isNotEmpty, reason: 'ESCO gives the skills');
    // 1. Other titles from the shipped SOC index and ESCO.
    expect(i.titles.length, greaterThan(3));
    expect(i.titles.map((t) => t.title), contains('ICT Instructor'));
    expect(i.soc.first.soc, '3573');
    // 2. Skills against the profile.
    final safety = i.criteria.firstWhere((c) => c.text == 'ensure patient safety');
    expect(safety.shown, isTrue);
    expect(safety.evidence, 'Patient safety');
    expect(i.gaps.map((g) => (g.text, g.severity)), [
      ('create training materials', 'major'),
      ('online moderation techniques', 'minor'),
    ]);
    expect(i.fitOffline, 35, reason: 'half the essentials (35 of 70), no optional');
    // 5. NHS pay applies (an NHS-style employer): the built-in points.
    expect(i.nhs, isTrue);
    expect(i.afc, isNotEmpty);
    // 6. The checklist and the people search link.
    expect(i.checklist, hasLength(peopleChecklist.length));
    expect(i.peopleSearch.host, 'www.linkedin.com');
    expect(i.peopleSearch.queryParameters['keywords'], role);
    // Every filled section has a dated source, and nothing is AI.
    for (final s in ['about', 'fit', 'pay', 'people', 'path']) {
      expect(i.sources[s], isNotEmpty, reason: s);
      expect(i.sources[s]!.every((x) => x.date.isNotEmpty), isTrue, reason: s);
      expect(i.aiIn(s), isFalse, reason: s);
    }
    expect(i.sources['about']!.map((s) => s.from), containsAll([InsightFrom.soc, InsightFrom.esco]));
    expect(i.model, isEmpty);
    expect(i.fitAi, isNull);
  });

  test('without ESCO the role still fills from the shipped data, saying what is missing', () async {
    final b = await _book();
    final down = MockClient((_) async => throw const SocketException('offline'));
    final i = await RoleInsightBuilder(families: RoleFamilies(down, b.db), today: today).build(role, profile);
    expect(i.titles.length, greaterThan(1));
    expect(i.criteria, isEmpty);
    expect(i.checklist, isNotEmpty);
  });

  test('the AI fills the rest, every AI part marked, and re-asking replaces only those', () async {
    final b = await _book();
    final ai = _FakeAi(aiAnswer);
    final i = await _builder(b, _Web(), ai: ai).build(role, profile);
    expect(ai.asked, 1);
    expect(ai.schema, RoleInsight.aiSchema);
    expect(i.model, 'fake-model');
    expect(i.aiAsked, today);
    expect(i.fitAi, 55);
    expect(i.fit, 55);
    expect(i.summary!.from, InsightFrom.ai);
    for (final s in ['about', 'fit', 'waysIn', 'stones', 'pay', 'people', 'moves', 'path']) {
      expect(i.aiIn(s), isTrue, reason: s);
    }
    expect(i.waysIn.every((w) => w.from.isAi), isTrue);
    expect(i.path.map((s) => s.stage), ['now', 'stepping_stone', 'target', 'beyond']);
    expect(i.path.every((s) => s.from.isAi), isTrue);
    expect(i.timeToReach, '2 years');
    expect(i.band!.text, '5');
    expect(i.band!.from, InsightFrom.ai);
    // The AI's gap on a known ESCO skill replaces the device's.
    final materials = i.gaps.where((g) => g.text.toLowerCase() == 'create training materials').toList();
    expect(materials.single.from, InsightFrom.ai);
    expect(materials.single.criterion, i.criteria.firstWhere((c) => c.text == 'create training materials').id);
    // A new requirement becomes a criterion, and moves point at gaps' criteria.
    final teaching = i.criteria.firstWhere((c) => c.text == 'Teaching qualification');
    expect(teaching.from, InsightFrom.ai);
    expect(i.moves.map((m) => m.criterion), [materials.single.criterion, teaching.id]);
    // The device's parts stay unmarked.
    expect(i.criteria.firstWhere((c) => c.text == 'ensure patient safety').from, InsightFrom.esco);
    expect(i.checklist.where((l) => !l.from.isAi), hasLength(peopleChecklist.length));
    expect(i.web.single.url, 'https://careers.example.org/it-trainer');

    // Re-asking: no AI part doubles up, the device's parts stay.
    final again = await _builder(b, _Web(), ai: ai).addAi(i, profile);
    expect(ai.asked, 2);
    expect(again.stones.length, i.stones.length);
    expect(again.waysIn.length, i.waysIn.length);
    expect(again.checklist.length, i.checklist.length);
    expect(again.criteria.length, i.criteria.length);
    // And without the AI parts it is the device's insight again.
    final plain = withoutAi(again);
    expect(plain.sources.values.expand((s) => s).where((s) => s.from.isAi), isEmpty);
    expect(plain.stones, isEmpty);
    expect(plain.path.map((s) => s.stage), ['now', 'target']);
  });

  test('a saved insight reopens the same without AI, on one row per role', () async {
    final b = await _book();
    final ai = _FakeAi(aiAnswer);
    final i = await _builder(b, _Web(), ai: ai).build(role, profile);
    await b.saveRoleInsight(i);
    final back = (await b.roleInsight('it trainer'))!;
    expect(jsonEncode(back.toJson()), jsonEncode(i.toJson()));
    expect(ai.asked, 1, reason: 'reading it back asks nothing');
    // Saving again replaces the same row; removing leaves a synced tombstone.
    await b.saveRoleInsight(i.copyWith(updated: '2026-11-22'));
    expect((await b.roleInsights()).single.updated, '2026-11-22');
    expect(await b.db.select(b.db.careerRoleInsights).get(), hasLength(1));
    await b.removeRoleInsight(i.id);
    expect(await b.roleInsights(), isEmpty);
    expect((await b.db.select(b.db.careerRoleInsights).getSingle()).deleted, isTrue);
  });

  test('a stepping stone builds the role search for its titles', () {
    final i = fixedInsight();
    final stone = i.stones.firstWhere((s) => s.role == 'Clinical Systems Trainer');
    final q = stone.query;
    expect(q.role, 'Clinical Systems Trainer');
    final titles = q.titles.map((t) => t.title).toList();
    expect(titles, containsAll(['EPR Trainer', 'Digital Systems Trainer']));
    expect(titles.toSet().length, titles.length);
    expect(stone.titles.firstWhere((t) => t.title == 'EPR Trainer').source, FamilySource.ai);
  });

  test('with no keys, the National Careers Service and Skills England are never asked', () async {
    expect(careerDataSources(quietClient(), const CareerDataKeys(), today: today), isEmpty);
    final store = MemorySecretStore();
    expect((await CareerDataKeys.read(store)).any, isFalse);
    final b = await _book();
    final web = _Web();
    await _builder(
      b,
      web,
      ai: _FakeAi(aiAnswer),
      keyed: careerDataSources(web.client, await CareerDataKeys.read(store), today: today),
    ).build(role, profile);
    expect(web.to('nationalcareers'), isEmpty);
    expect(web.to('skillsengland'), isEmpty);
    expect(web.requests.every((r) => r.url.host == 'ec.europa.eu'), isTrue);

    // Keys saved go to the keychain only; an empty one switches it off.
    await CareerDataKeys.save(store, ncs: 'made-up-ncs', skillsEngland: ' made-up-se ');
    final keys = await CareerDataKeys.read(store);
    expect((keys.ncs, keys.skillsEngland), ('made-up-ncs', 'made-up-se'));
    expect(careerDataSources(quietClient(), keys, today: today), hasLength(2));
    await CareerDataKeys.save(store, ncs: '', skillsEngland: 'made-up-se');
    expect(await store.read(CareerDataSecrets.ncs), isNull);
  });

  test('with a Skills England key, ways in, pay, stones and the credit are added', () async {
    final asked = <http.Request>[];
    final se = MockClient((r) async {
      asked.add(r);
      if (r.url.path.endsWith('/OccupationsBySOC')) return http.Response(jsonEncode([_seOccupation]), 200);
      if (r.url.path.endsWith('/OccupationalProgression/OCC9001')) return http.Response(jsonEncode(_seProgression), 200);
      return http.Response('[]', 404);
    });
    final source = SkillsEnglandMaps(se, key: 'made-up-key', today: today);
    final base = fixedInsight(withAiParts: false);
    final b = await _book();
    final i = await RoleInsightBuilder(families: RoleFamilies(_Web().client, b.db), keyed: [source], today: today)
        .addKeyed(base);
    expect(asked.first.headers['X-API-KEY'], 'made-up-key');
    expect(asked.first.url.queryParameters['SOCCode'], '3573');
    expect(asked.first.url.queryParameters['SOCVersion'], '2020');
    expect(i.keyed, [InsightFrom.skillsEngland]);
    expect(i.waysIn.single.kind, 'apprenticeship');
    expect(i.waysIn.single.title, 'Example teacher apprenticeship (level 5)');
    expect(i.pay.single.amount, '£31,000 a year');
    expect(i.stones.single.role, 'Teaching assistant');
    expect(i.stones.single.titles.single.title, 'Classroom Assistant');
    expect(i.progression.single.text, contains('Training manager'));
    expect(i.sources['waysIn']!.single.label, skillsEnglandCredit.text);
    expect(i.aiIn('waysIn'), isFalse);

    // A rejected key is noted, not thrown.
    final denied = MockClient((_) async => http.Response('{"message":"API Key was not provided."}', 403));
    final failed = await RoleInsightBuilder(
      families: RoleFamilies(_Web().client, b.db),
      keyed: [SkillsEnglandMaps(denied, key: 'made-up-key', today: today)],
      today: today,
    ).addKeyed(base);
    expect(failed.problems.single, contains('rejected the key'));
  });

  test('a National Careers Service profile (made-up shape, not verified) gives routes and pay', () async {
    final asked = <http.Request>[];
    final ncs = MockClient((r) async {
      asked.add(r);
      if (r.url.path.contains('/search/')) {
        return http.Response(
          jsonEncode([
            {'Title': 'IT trainer', 'Url': 'https://example.org/job-profiles/it-trainer'},
          ]),
          200,
        );
      }
      if (r.url.path.endsWith('/it-trainer')) {
        return http.Response(
          jsonEncode({
            'Title': 'IT trainer',
            'Overview': '<p>Made-up overview of the job.</p>',
            'SalaryStarter': 22000,
            'SalaryExperienced': 38000,
            'HowToBecome': {
              'EntryRoutes': {
                'Apprenticeship': ['<p>A made-up apprenticeship route.</p>'],
                'Work': ['Move from a support role.'],
              },
            },
            'CareerPathAndProgression': ['Training manager.'],
          }),
          200,
        );
      }
      return http.Response('', 404);
    });
    final d = (await NcsJobProfiles(ncs, key: 'made-up-key', today: today).lookup(role))!;
    expect(asked.first.headers['Ocp-Apim-Subscription-Key'], 'made-up-key');
    expect(d.summary, 'Made-up overview of the job.');
    expect(d.waysIn.map((w) => w.kind), ['apprenticeship', 'internal']);
    expect(d.pay.map((p) => p.amount), ['£22,000 a year', '£38,000 a year']);
    expect(d.progression, ['Training manager.']);
    final i = withCareerData(fixedInsight(withAiParts: false), d, today: today);
    expect(i.summary!.from, InsightFrom.ncs);
    expect(i.keyed, [InsightFrom.ncs]);
  });

  test('"Study for this role" sends Vidya the gaps and moves, linked to the role\'s criteria', () async {
    final i = fixedInsight();
    final plan = roleVidyaPlan(i);
    expect(plan['format'], 'vidya-curriculum');
    expect(plan['version'], 1);
    expect(plan['role'], role);
    // A job journey with only the role's data; Vidya fills in the stages.
    expect(plan['journey'], {'role': role, 'sector': i.nhs ? 'nhs' : 'other'});
    final criteria = objs(plan['criteria']);
    final ids = {for (final c in criteria) str(c['id'])};
    expect(criteria.map((c) => c['text']), containsAll(['ensure patient safety', 'Teaching qualification']));
    expect(criteria.firstWhere((c) => c['text'] == 'ensure patient safety')['shown'], isTrue);
    final courses = objs(plan['courses']);
    expect(courses.map((c) => c['title']), ['Gaps for $role', 'First moves: $role']);
    final gapTopics = objs(courses.first['topics']);
    expect(gapTopics.map((t) => t['title']), [for (final g in i.gaps) g.text]);
    expect(gapTopics.first['title'], 'Formal teaching qualification');
    for (final t in [...gapTopics, ...objs(courses.last['topics'])]) {
      final linked = strs(t['criteria']);
      expect(linked, isNotEmpty, reason: '${t['title']}');
      expect(ids.containsAll(linked), isTrue, reason: '${t['title']}');
      for (final item in objs(t['items'])) {
        expect(item['type'], 'practice task');
      }
    }
    // Within Vidya's limits; kinds Vidya accepts.
    expect(courses.every((c) => const ['course', 'practice'].contains(c['kind'])), isTrue);
    expect(str(objs(plan['notes']).single['body']), contains('Criteria:'));

    // Its own bridge row beside the main plan, replaced on sending again.
    final b = await _book();
    final id = await b.sendRoleToVidya(i, now: '2026-11-21T09:00:00Z');
    expect(id, 'udyoga.role.it-trainer');
    await b.sendRoleToVidya(i, now: '2026-11-21T10:00:00Z');
    final rows = await b.db.select(b.db.bridgeStudyPlans).get();
    expect(rows.map((r) => r.id), [id]);
    expect(decodeObject(rows.single.plan)['role'], role);
    expect(rows.any((r) => r.id == studyPlanId), isFalse, reason: 'the main plan is untouched');
  });

  test('the role plan fixture shared with Vidya is current', () async {
    final plan = const JsonEncoder.withIndent('  ').convert(roleVidyaPlan(fixedInsight()));
    expect(plan, isNot(contains('made-up-key')));
    final fixture = File('test/fixtures/udyoga-role-plan.json');
    if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
      await fixture.parent.create(recursive: true);
      await fixture.writeAsString('$plan\n');
    }
    expect(await fixture.readAsString(), '$plan\n');
  });

  test('a schema 12 database gains the role insights table without losing data, and can run again', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate13');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var b = CareerBook(await Store.open(db));
    await b.saveProfile(profile);
    await b.importPostings([samplePosting()], profile, today: today);
    await db.customStatement('DROP TABLE career_role_insights');
    await db.customStatement('PRAGMA user_version = 12');
    await db.close();
    for (var n = 0; n < 2; n++) {
      db = AppDatabase(NativeDatabase(file));
      b = CareerBook(await Store.open(db));
      expect((await b.db.select(b.db.jobListings).get()).single.title, samplePosting().title);
      expect((await b.profile()).targets.roles, profile.targets.roles);
      expect(await b.roleInsights(), hasLength(n));
      if (n == 0) await b.saveRoleInsight(fixedInsight());
      await db.customStatement('PRAGMA user_version = 12');
      await db.close();
    }
  });

  testWidgets('on a phone, cards show AI labels and sources, stones open search, and roles compare', (
    tester,
  ) async {
    final h = AppHarness(tester);
    final ai = _FakeAi(aiAnswer);
    await h.open(
      seed: (b) async {
        await b.saveProfile(profile);
        await b.saveRoleInsight(fixedInsight());
        await b.saveRoleInsight(fixedInsight(target: 'Clinical Systems Trainer', withAiParts: false));
      },
    );
    h.phone();
    await h.run(
      home: const RoleInsightPage(roles: [role, 'Clinical Systems Trainer']),
      overrides: [advisorProvider.overrideWith((ref) async => Advisor(ai, today: today))],
    );
    await h.settle();
    expect(tester.takeException(), isNull);
    expect(ai.asked, 0, reason: 'saved insights open without AI');
    expect(find.text(role), findsWidgets);
    expect(find.byType(RoleInsightCard), findsWidgets);
    expect(find.byType(AiTag), findsWidgets);
    expect(find.textContaining('Source: ONS SOC 2020'), findsWidgets);
    expect(find.text('Refresh', skipOffstage: false), findsOneWidget, reason: 'the AI was asked for one role');

    // A stepping stone's "Search these jobs" opens role search, filled in.
    final stone = find.byKey(ValueKey('stone.search.${normalJobTitle('Clinical Systems Trainer')}'));
    await tester.scrollUntilVisible(stone, 300, scrollable: find.byType(Scrollable).first);
    await h.tap(stone);
    await h.settle();
    final page = tester.widget<RoleSearchPage>(find.byType(RoleSearchPage));
    expect(page.query.role, 'Clinical Systems Trainer');
    expect(page.query.titles.map((t) => t.title), contains('EPR Trainer'));
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await h.settle();

    // Further down: the LinkedIn button, and the second role, not asked yet.
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('People with this title on LinkedIn').first, 300, scrollable: scroll);
    await tester.scrollUntilVisible(find.text('Ask the AI'), 300, scrollable: scroll);
    expect(find.text('Ask the AI'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Compare: stacked on a phone, one card per role.
    await h.tap(find.byKey(const ValueKey('insight.compare')));
    await h.settle();
    expect(find.byType(RoleCompare), findsOneWidget);
    expect(find.text('Time to reach'), findsNWidgets(2));
    expect(find.text('2 years'), findsOneWidget);
    expect(find.text('First move'), findsNWidgets(2));
    expect(find.text('Ask to be a super-user on the next roll-out.'), findsOneWidget);
    final cards = find.descendant(of: find.byType(RoleCompare), matching: find.byType(Card));
    expect(tester.getTopLeft(cards.first).dx, tester.getTopLeft(cards.last).dx, reason: 'stacked');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings lists every data source credit', (tester) async {
    final h = AppHarness(tester);
    await h.open();
    h.phone();
    await h.run(home: const DataSourcesPage());
    expect(find.textContaining('Office for National Statistics'), findsWidgets);
    expect(find.textContaining('ESCO'), findsWidgets);
    expect(find.textContaining('National Careers Service · off', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('NHS Health Careers · link only', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Skills England · off'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Skills England · off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
