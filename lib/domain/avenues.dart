/// An avenue is one country worked up into a plan: the AI's assessment of
/// it (role families, live adverts, pay against the cost of living, the
/// route by name, blockers and pushback, with a confidence), and a prep
/// plan of ordered steps with the qualification planner, timed against the
/// right-to-work end date. Both are kept as career reports; the prep plan
/// can go to Vidya and its steps can become to-dos.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'book.dart';
import 'explore.dart';
import 'json.dart';
import 'routes.dart';
import 'schema.dart';
import 'todos.dart';

/// Report kinds.
const avenueKind = 'avenue';
const avenuePlanKind = 'avenue_plan';

/// The AI's assessment of one country for the candidate.
class AvenueAssessment {
  const AvenueAssessment(this.j);
  final Json j;

  String get country => str(j['country']).toUpperCase();
  String get summary => str(j['summary']);

  /// high | medium | low
  String get confidence => str(j['confidence']);
  String get confidenceWhy => str(j['confidenceWhy']);
  List<Json> get roleFamilies => objs(j['roleFamilies']);
  List<Json> get adverts => objs(j['adverts']);
  Json get pay => obj(j['pay']);
  Json get route => obj(j['route']);
  List<Json> get blockers => objs(j['blockers']);
  List<String> get pushback => strs(j['pushback']);
  List<String> get nextSteps => strs(j['nextSteps']);

  static final schema = object({
    'country': string('ISO 3166-1 alpha-2 code of the country assessed'),
    'summary': string('Two or three sentences: is this a realistic avenue now, later or not at all, and why'),
    'confidence': oneOf(['high', 'medium', 'low'], 'How sure you are, given the sources found'),
    'confidenceWhy': string('What the confidence rests on, and what you could not confirm'),
    'roleFamilies': array(
      object({
        'title': string('A family of roles the candidate could do there, in local terms'),
        'occupationCode': string('Its ISCO-08 or local code if known, else empty'),
        'demand': oneOf(['strong', 'steady', 'weak', 'unknown']),
        'payRange': string('Current pay range with currency and year, from a source; empty if none found'),
        'fit': string('Why the candidate fits or does not, from their CV only'),
      }),
    ),
    'adverts': array(
      object({
        'title': string(),
        'employer': string(),
        'location': string(),
        'url': string('The advert link; only adverts you actually found'),
        'salary': string('As the advert gives it, else empty'),
        'sponsorship': string('What the advert says about visas or sponsorship, else empty'),
      }),
      description: 'Live example adverts found now, with links. Never invent one.',
    ),
    'pay': object({
      'typical': string('Typical pay for these roles there, with currency and year'),
      'costOfLiving': string('Rent and living costs against that pay, with sources'),
      'verdict': string('Plainly: better off, about the same or worse off than now'),
    }),
    'route': object({
      'name': string('The visa or permit route by its official name'),
      'officialUrl': string('The official page for it'),
      'threshold': string('The pay threshold or points that apply, with the date'),
      'fits': oneOf(['yes', 'partly', 'no', 'unknown']),
      'why': string('Why it fits or not, for this candidate and their roles'),
    }),
    'blockers': array(
      object({
        'blocker': string('Something that stops or slows this avenue'),
        'severity': oneOf(['stops', 'slows', 'minor']),
        'fix': string('How to remove or work around it, if anything can'),
      }),
    ),
    'pushback': strings('Where the candidate\'s assumptions or the screen are likely wrong, said plainly'),
    'nextSteps': strings('The first three things to do, in order'),
  });
}

/// One step in a prep plan.
class PrepStep {
  const PrepStep(this.j);
  final Json j;

  int get order => intOf(j['order']) ?? 0;

  /// qualification | certification | language | cv | application | test | admin
  String get kind => str(j['kind']);
  String get title => str(j['title']);
  String get why => str(j['why']);
  String get cost => str(j['cost']);
  String get time => str(j['time']);

  /// yyyy-MM-dd, or null.
  String? get due => isDay(str(j['due'])) ? str(j['due']) : null;
  String get url => str(j['url']);
  bool get verified => j['verified'] == true;

  /// The stable id within its plan.
  String get id => 's$order';

  static final schema = object({
    'order': integer('1 for the first step'),
    'kind': oneOf(['qualification', 'certification', 'language', 'cv', 'application', 'test', 'admin']),
    'title': string('The step, as a short instruction'),
    'why': string('What it changes for this avenue'),
    'cost': string('Cost with currency, or empty'),
    'time': string('How long it takes'),
    'due': string('yyyy-MM-dd to finish by, before the deadline; empty if undated'),
    'url': string('Official page, else empty'),
    'verified': boolean('True only when the cost and time come from an official source you read'),
  });
}

/// A prep plan for one avenue, with the qualification planner.
class PrepPlan {
  const PrepPlan(this.j);
  final Json j;

  String get country => str(j['country']).toUpperCase();
  String get summary => str(j['summary']);

  /// The day everything has to fit before, yyyy-MM-dd, or ''.
  String get deadline => str(j['deadline']);
  List<PrepStep> get steps => objs(j['steps']).map(PrepStep.new).toList()..sort((a, b) => a.order.compareTo(b.order));
  Json get qualification => obj(j['qualification']);
  List<Json> get qualificationOptions => objs(qualification['options']);
  List<String> get risks => strs(j['risks']);

  static final schema = object({
    'country': string('ISO 3166-1 alpha-2'),
    'summary': string('The plan in two sentences'),
    'deadline': string('The date the plan works back from, yyyy-MM-dd, or empty'),
    'steps': array(PrepStep.schema, description: 'Ordered: what must happen first comes first'),
    'qualification': object({
      'needed': boolean('Whether the route or the target jobs need the qualification recognised or checked'),
      'recommendation': string('Which option to take and when, against the deadline'),
      'options': array(
        object({
          'name': string('Service or alternative, by its official name'),
          'what': string('What it proves and to whom'),
          'cost': string(),
          'time': string(),
          'needsUniversity': oneOf(['yes', 'no', 'unknown'], 'Whether the awarding university must respond'),
          'url': string(),
          'when': string('When to start it, given the deadline'),
        }),
      ),
    }),
    'risks': strings('What could break the plan, and the fallback'),
  });
}

/// A recognition or proof option Udyoga knows, with its source.
class QualificationOption {
  const QualificationOption({
    required this.name,
    required this.what,
    required this.cost,
    required this.time,
    required this.needsUniversity,
    required this.source,
  });
  final String name, what, cost, time;

  /// yes | no | unknown
  final String needsUniversity;
  final RouteSource source;

  Json toJson() => {
    'name': name,
    'what': what,
    'cost': cost,
    'time': time,
    'needsUniversity': needsUniversity,
    'url': source.url,
    'verified': source.verified,
  };
}

const _read = '2026-11-19';

/// Ways to get an overseas qualification recognised or the language proved,
/// by country. The AI adds to these; they are its starting facts.
const qualificationOptions = <String, List<QualificationOption>>{
  'GB': [
    QualificationOption(
      name: 'UK ENIC Statement of Comparability',
      what: 'The UK level of an overseas qualification, for employers and colleges. Not a visa document.',
      cost: '£69.60 (e-Statement)',
      time: '15 working days',
      needsUniversity: 'unknown',
      source: RouteSource(
        'UK ENIC: Statement of Comparability cost',
        'https://www.enic.org.uk/individuals/statement-of-comparability/cost',
        asOf: _read,
      ),
    ),
    QualificationOption(
      name: 'UK ENIC Statement of Comparability, Fast Track',
      what: 'The same statement, faster; chosen when ordering.',
      cost: '£223.20 (2 working days) or £284.40 (1 working day)',
      time: '1 to 2 working days once documents are in',
      needsUniversity: 'unknown',
      source: RouteSource('UK ENIC: Fast Track', 'https://enic.org.uk/qualifications/fast-track', asOf: _read),
    ),
    QualificationOption(
      name: 'Ecctis Qualification and Language Service',
      what:
          'For the visa: a degree at UK bachelor\'s level and taught in English. Closed if the university does '
          'not verify within 20 working days.',
      cost: '£210 + VAT',
      time: 'Up to 20 working days',
      needsUniversity: 'yes',
      source: RouteSource(
        'Lewis Silkin: Ecctis Qualification and Language Service (law-firm summary, May 2025)',
        'https://www.lewissilkin.com/insights/2025/05/02/new-ecctis-qualification-and-language-service-includes-increased-fee-and-slower-p-102ka43',
        asOf: _read,
        verified: false,
      ),
    ),
    QualificationOption(
      name: 'Secure English Language Test (SELT) at B2',
      what: 'Proves English for the visa without the university: IELTS for UKVI or PTE Academic UKVI.',
      cost: 'About £195 to £250 (third-party prices)',
      time: 'One day, plus preparation',
      needsUniversity: 'no',
      source: RouteSource(
        'Skilled Worker visa: knowledge of English (GOV.UK)',
        'https://www.gov.uk/skilled-worker-visa/knowledge-of-english',
        asOf: _read,
        verified: false,
      ),
    ),
  ],
  'IE': [
    QualificationOption(
      name: 'QQI NARIC Ireland comparability statement',
      what:
          'A free, general statement of how a foreign qualification compares with the Irish framework. '
          'Employers decide.',
      cost: 'Free',
      time: 'Online, immediately',
      needsUniversity: 'no',
      source: RouteSource(
        'QQI: comparability statements',
        'https://qhelp.qqi.ie/learners/qualifications-recognition-advice/comparability-statements/',
        asOf: _read,
      ),
    ),
  ],
  'CA': [
    QualificationOption(
      name: 'Educational Credential Assessment (for example WES)',
      what: 'Needed for Express Entry points on foreign education.',
      cost: 'About C\$264 plus delivery (WES)',
      time: '4 to 8 weeks',
      needsUniversity: 'yes',
      source: RouteSource(
        'IRCC: educational credential assessment',
        'https://www.canada.ca/en/immigration-refugees-citizenship/services/immigrate-canada/express-entry/documents/education-assessed.html',
        asOf: _read,
        verified: false,
      ),
    ),
  ],
};

/// Economic context for a country from the World Bank (no key) and
/// ILOSTAT (no key; licence unverified). Every value carries its year.
class CountryEconomy {
  const CountryEconomy({required this.code, this.iso3 = '', this.figures = const []});
  final String code, iso3;

  /// (label, value as text, year, source URL).
  final List<({String label, String value, String year, String url})> figures;

  Json toJson() => {
    'country': code,
    'figures': [
      for (final f in figures) {'label': f.label, 'value': f.value, 'year': f.year, 'source': f.url},
    ],
  };
}

const _worldBank = {
  'NY.GDP.PCAP.PP.CD': 'GDP per person, PPP (current international \$)',
  'PA.NUS.PRVT.PP': 'Price level: household consumption PPP factor (local currency per international \$)',
  'SL.UEM.TOTL.ZS': 'Unemployment, % of labour force (ILO model)',
};

/// The latest World Bank value for one indicator: (value, year, ISO3).
(double, String, String)? parseWorldBank(String body) {
  final Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (j is! List || j.length < 2 || j[1] is! List) return null;
  for (final row in objs(j[1])) {
    final v = numOf(row['value']);
    if (v != null) return (v, str(row['date']), str(row['countryiso3code']));
  }
  return null;
}

/// The latest ILOSTAT row for both sexes: (value, year).
(double, String)? parseIlostatCsv(String body) {
  final lines = body.replaceAll('﻿', '').split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  if (lines.length < 2) return null;
  List<String> cells(String l) => l.split(',').map((c) => c.replaceAll('"', '').trim()).toList();
  final head = cells(lines.first);
  final sex = head.indexOf('sex'), time = head.indexOf('time'), value = head.indexOf('obs_value');
  if (time < 0 || value < 0) return null;
  (double, String)? best;
  for (final l in lines.skip(1)) {
    final c = cells(l);
    if (c.length <= value || (sex >= 0 && c[sex] != 'SEX_T')) continue;
    final v = double.tryParse(c[value]);
    if (v == null) continue;
    if (best == null || c[time].compareTo(best.$2) > 0) best = (v, c[time]);
  }
  return best;
}

/// Reads the figures; any that fail are left out (the AI is told which).
Future<CountryEconomy> fetchEconomy(http.Client client, String code) async {
  final figures = <({String label, String value, String year, String url})>[];
  var iso3 = '';
  for (final e in _worldBank.entries) {
    final url = 'https://api.worldbank.org/v2/country/$code/indicator/${e.key}?format=json&mrnev=1';
    try {
      final r = await client.get(Uri.parse(url));
      if (r.statusCode != 200) continue;
      final v = parseWorldBank(utf8.decode(r.bodyBytes));
      if (v == null) continue;
      if (v.$3.isNotEmpty) iso3 = v.$3;
      figures.add((label: e.value, value: v.$1.toStringAsFixed(1), year: v.$2, url: url));
    } on Exception {
      continue;
    }
  }
  if (iso3.isNotEmpty) {
    final url =
        'https://rplumber.ilo.org/data/indicator/?id=EAR_EHRA_SEX_NB_A&ref_area=$iso3&sex=SEX_T&timefrom=2018&format=.csv';
    try {
      final r = await client.get(Uri.parse(url));
      final v = r.statusCode == 200 ? parseIlostatCsv(utf8.decode(r.bodyBytes)) : null;
      if (v != null) {
        figures.add((
          label: 'Average hourly earnings of employees, local currency (ILOSTAT)',
          value: v.$1.toStringAsFixed(2),
          year: v.$2,
          url: url,
        ));
      }
    } on Exception {
      // ILOSTAT is optional.
    }
  }
  return CountryEconomy(code: code, iso3: iso3, figures: figures);
}

/// What the screen found, for the AI to check and build on.
Json screenForPrompt(CountryScreen s) => {
  'country': s.code,
  'name': s.country.name,
  'tier': s.tier.label,
  'reasons': s.reasons,
  'blockers': s.blockers,
  'deadline': s.deadline,
  'routes': [
    for (final r in s.routes)
      {
        'name': r.route.name,
        'fit': r.fit.name,
        'floor': r.floor?.label,
        'reasons': r.reasons,
        'source': r.route.source.url,
        'asOf': r.route.source.asOf,
        'verified': r.route.verified,
        'requirements': r.route.requirements,
        'notes': r.route.notes,
      },
  ],
};

/// The Vidya plan row id for an avenue.
String avenuePlanId(String country) => 'udyoga.avenue.${country.toLowerCase()}';

/// A prep plan as a Vidya study plan ("vidya-curriculum", version 1): the
/// steps as courses, dated in weeks from [today].
Json avenueVidyaPlan(PrepPlan plan, {required String countryName, required String today}) {
  int week(String? due) {
    if (due == null) return 4;
    final days = DateTime.parse(due).difference(DateTime.parse(today)).inDays;
    // Always at least 1, so a start week (the week before) is never negative.
    return days < 7 ? 1 : (days / 7).ceil();
  }

  final steps = plan.steps;
  return {
    'format': 'vidya-curriculum',
    'version': 1,
    'part': '1 of 1',
    'program': {
      'title': 'Avenue: $countryName',
      'goal': plan.summary.isEmpty ? 'Be ready to move to $countryName.' : plan.summary,
    },
    'courses': [
      for (final (i, s) in steps.indexed)
        {
          'title': s.title,
          'kind': switch (s.kind) {
            'certification' || 'qualification' => 'certification',
            'language' || 'test' => 'course',
            _ => 'practice',
          },
          'startWeek': i == 0 ? 0 : week(steps[i - 1].due) - 1,
          'dueWeek': week(s.due),
          'summary': [
            s.why,
            if (s.cost.isNotEmpty) 'Cost: ${s.cost}.',
            if (s.time.isNotEmpty) 'Time: ${s.time}.',
            if (!s.verified) 'Cost and time unverified.',
          ].where((t) => t.isNotEmpty).join(' '),
          if (s.url.startsWith('http')) 'url': s.url,
          'topics': const [],
        },
    ],
    'skills': const [],
    'cards': const [],
    'notes': [
      {
        'title': 'From Udyoga',
        'body': [
          'Made by Udyoga from the prep plan for $countryName.',
          if (plan.deadline.isNotEmpty) 'Everything is timed to finish before ${plan.deadline}.',
          if (plan.qualification['recommendation'] case final String r when r.isNotEmpty) 'Qualification: $r',
          ...plan.risks.map((r) => '- $r'),
        ].join('\n'),
        'tags': ['udyoga', 'avenue', plan.country.toLowerCase()],
      },
    ],
  };
}

/// Avenue reports, plans and their links.
extension AvenueBook on CareerBook {
  Future<Report?> _latestFor(String kind, String country) async {
    final rows =
        await (db.select(db.careerReports)
              ..where((r) => r.kind.equals(kind) & r.deleted.not())
              ..orderBy([(r) => OrderingTerm.desc(r.created)]))
            .get();
    for (final r in rows) {
      if (str(decodeObject(r.content)['country']).toUpperCase() == country.toUpperCase()) return r;
    }
    return null;
  }

  /// The latest AI assessment of [country], or null.
  Future<Report?> latestAvenue(String country) => _latestFor(avenueKind, country);

  /// The latest prep plan for [country], or null.
  Future<Report?> latestPrepPlan(String country) => _latestFor(avenuePlanKind, country);

  /// Sends a prep plan to Vidya as its own study plan (beside Udyoga's
  /// main one, [studyPlanId], which it does not touch).
  Future<String> sendAvenueToVidya(PrepPlan plan, {required String countryName, required String now}) async {
    final id = avenuePlanId(plan.country);
    await save(
      db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(
        id: id,
        source: 'udyoga',
        plan: jsonEncode(avenueVidyaPlan(plan, countryName: countryName, today: now.substring(0, 10))),
        updated: now,
      ),
      id,
    );
    return id;
  }

  /// Makes a to-do from a prep step (once per step and country).
  Future<String> stepTodo(PrepPlan plan, PrepStep step, {required String countryName, required String today}) =>
      saveTodo(
        id: 'todo.avenue.${plan.country.toLowerCase()}.${step.id}',
        title: step.title,
        notes: [
          'Prep plan for $countryName.',
          step.why,
          if (step.cost.isNotEmpty) 'Cost: ${step.cost}.',
          if (step.url.isNotEmpty) step.url,
        ].where((t) => t.isNotEmpty).join(' '),
        due: step.due,
        today: today,
      );
}
