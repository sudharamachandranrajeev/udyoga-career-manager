import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/avenues.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/explore.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/todos.dart';
import 'package:udyoga/domain/vidya_link.dart';
import 'package:udyoga/domain/work_rights.dart';
import 'package:udyoga/domain/world.dart';

import 'support.dart';

const today = '2026-11-19';

class _Recorder implements Ai {
  _Recorder(this.answer);
  final Json answer;
  late List<Json> content;
  late Json schema;
  late bool web;

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
    this.content = content;
    this.schema = schema;
    this.web = web;
    return AiResult(answer);
  }
}

const plan = PrepPlan({
  'country': 'IE',
  'summary': 'Get an offer at the GEP floor before the deadline.',
  'deadline': '2027-06-30',
  'steps': [
    {
      'order': 2,
      'kind': 'application',
      'title': 'Apply to five roles',
      'why': 'Offers start the permit.',
      'cost': '',
      'time': '6 weeks',
      'due': '2027-02-01',
      'url': '',
      'verified': false,
    },
    {
      'order': 1,
      'kind': 'qualification',
      'title': 'Get a QQI comparability statement',
      'why': 'Employers ask what the degree compares to.',
      'cost': 'Free',
      'time': 'Online',
      'due': '2026-11-25',
      'url': 'https://qhelp.qqi.ie/',
      'verified': true,
    },
  ],
  'qualification': {'needed': true, 'recommendation': 'QQI statement now.', 'options': []},
  'risks': ['No sponsor answers'],
});

void main() {
  test('World Bank and ILOSTAT readers take the latest value with its year', () {
    const wb =
        '[{"page":1},[{"countryiso3code":"IRL","date":"2025","value":4.632},{"countryiso3code":"IRL","date":"2024","value":4.3}]]';
    expect(parseWorldBank(wb), (4.632, '2025', 'IRL'));
    expect(parseWorldBank('[{"message":"not found"}]'), isNull);
    const csv =
        '﻿"ref_area","source","indicator","sex","time","obs_value"\n'
        '"GBR","BA:666","EAR_EHRA_SEX_NB","SEX_T","2021",17.696\n'
        '"GBR","BA:666","EAR_EHRA_SEX_NB","SEX_T","2022",18.504\n'
        '"GBR","BA:666","EAR_EHRA_SEX_NB","SEX_M","2023",20.0\n';
    expect(parseIlostatCsv(csv), (18.504, '2022'));
    expect(parseIlostatCsv('"ref_area","time","obs_value"\n'), isNull);
  });

  test('fetching the economy keeps what answers and skips what fails', () async {
    final client = MockClient((r) async {
      if (r.url.host == 'rplumber.ilo.org') return http.Response('down', 500);
      if (r.url.path.contains('SL.UEM')) return http.Response('[{"message":"x"}]', 200);
      return http.Response('[{},[{"countryiso3code":"IRL","date":"2025","value":120000.5}]]', 200);
    });
    final e = await fetchEconomy(client, 'IE');
    expect(e.iso3, 'IRL');
    expect(e.figures, hasLength(2));
    expect(e.figures.first.year, '2025');
  });

  test('the avenue assessment sends the screen and the figures, with web search on', () async {
    final ai = _Recorder({'country': 'IE', 'summary': 'Realistic.', 'confidence': 'medium'});
    const p = CandidateProfile(
      name: 'Alex Example',
      rights: WorkRights(passports: ['IN'], languages: [SpokenLanguage('English', LanguageLevel.native)]),
    );
    final s = screenCountry(worldCountry('IE')!, profile: p, today: today);
    final r = await Advisor(ai, today: today).assessAvenue(
      p,
      s,
      economy: const CountryEconomy(code: 'IE', figures: [(label: 'GDP', value: '1', year: '2025', url: 'u')]),
    );
    expect(ai.web, isTrue);
    final sent = ai.content.map((c) => c['text']).join();
    expect(sent, allOf(contains('<screen>'), contains('General Employment Permit'), contains('<economy>')));
    expect(AvenueAssessment(r.data).confidence, 'medium');
    expect((ai.schema['properties'] as Map).keys, containsAll(['adverts', 'route', 'pushback', 'confidence']));
  });

  test('the prep plan carries the known qualification options and the deadline', () async {
    final ai = _Recorder(plan.j);
    final s = screenCountry(worldCountry('GB')!, profile: sampleProfile, today: today);
    await Advisor(
      ai,
      today: today,
    ).prepPlan(sampleProfile, s, deadline: '2027-09-30', options: qualificationOptions['GB']!);
    final sent = ai.content.map((c) => c['text']).join();
    expect(sent, allOf(contains('2027-09-30'), contains('Statement of Comparability'), contains('£69.60')));
  });

  test('a prep plan orders its steps and becomes a Vidya plan', () {
    expect(plan.steps.map((s) => s.order), [1, 2]);
    final v = avenueVidyaPlan(plan, countryName: 'Ireland', today: today);
    expect(v['format'], 'vidya-curriculum');
    expect(v['version'], 1);
    final courses = objs(v['courses']);
    expect(courses.map((c) => c['title']), ['Get a QQI comparability statement', 'Apply to five roles']);
    expect(courses.first['kind'], 'certification');
    expect((courses.first['startWeek'], courses.first['dueWeek']), (0, 1));
    expect(courses.last['dueWeek'], 11);
    expect(courses.last['startWeek'], 0);
    expect(str(courses.last['summary']), contains('unverified'));
  });

  group('book', () {
    late CareerBook book;
    setUp(() async {
      final db = memoryDatabase();
      addTearDown(db.close);
      book = CareerBook(await Store.open(db));
    });

    test('Send to Vidya writes udyoga.avenue.<country> and leaves the main plan working', () async {
      await book.sendToVidya(now: '2026-11-19T09:00:00');
      final id = await book.sendAvenueToVidya(plan, countryName: 'Ireland', now: '2026-11-19T10:00:00');
      expect(id, 'udyoga.avenue.ie');
      final rows = await book.db.select(book.db.bridgeStudyPlans).get();
      expect(rows.map((r) => r.id), unorderedEquals([studyPlanId, 'udyoga.avenue.ie']));
      final sent = decodeObject(rows.firstWhere((r) => r.id == id).plan);
      expect(sent['program'], containsPair('title', 'Avenue: Ireland'));
      expect((await book.vidyaBridge()).sent, '2026-11-19T09:00:00');
    });

    test('steps become to-dos once, and avenue reports are found by country', () async {
      final step = plan.steps.first;
      final id = await book.stepTodo(plan, step, countryName: 'Ireland', today: today);
      await book.stepTodo(plan, step, countryName: 'Ireland', today: today);
      expect(id, 'todo.avenue.ie.s1');
      final todos = await book.todos();
      expect(todos.single.target, '2026-11-25');
      expect(todos.single.kind, todoKind);

      await book.saveReport(avenueKind, {'country': 'IE', 'summary': 'old'}, const [], at: '2026-11-18T10:00:00');
      await book.saveReport(avenueKind, {'country': 'GB', 'summary': 'uk'}, const [], at: '2026-11-19T10:00:00');
      await book.saveReport(avenueKind, {'country': 'IE', 'summary': 'new'}, const [], at: '2026-11-19T11:00:00');
      final ie = await book.latestAvenue('ie');
      expect(decodeObject(ie!.content)['summary'], 'new');
      expect(await book.latestPrepPlan('IE'), isNull);
    });
  });

  test('every country with options names a source', () {
    for (final e in qualificationOptions.entries) {
      for (final o in e.value) {
        expect(o.source.url, startsWith('https://'), reason: o.name);
        expect(jsonEncode(o.toJson()), contains(o.source.url));
      }
    }
  });
}
