/// Work visa routes by country, dated and sourced. Every figure carries the
/// page it came from and the day it was read; what Udyoga could not check
/// against the official page is marked unverified and shown that way.
///
/// The UK and Canada tables can be refreshed live (route_refresh.dart); the
/// shipped tables are the fallback.
library;

import 'json.dart';

/// Where a rule comes from, and when it was read there.
class RouteSource {
  const RouteSource(this.title, this.url, {required this.asOf, this.verified = true});

  final String title, url;

  /// The day the page was read, yyyy-MM-dd.
  final String asOf;

  /// False when Udyoga could not confirm it on the official page (from a
  /// secondary source, or the page would not load).
  final bool verified;

  Json toJson() => {'title': title, 'url': url, 'asOf': asOf, 'verified': verified};

  factory RouteSource.fromJson(Json j) =>
      RouteSource(str(j['title']), str(j['url']), asOf: str(j['asOf']), verified: j['verified'] != false);
}

/// An amount of pay: a year, a month or an hour.
class Money {
  const Money(this.amount, this.currency, {this.per = 'year'});
  final num amount;

  /// ISO 4217.
  final String currency;

  /// year | month | hour
  final String per;

  /// The yearly amount (12 months; an hour as 37.5 a week, 52 weeks), for
  /// comparing like with like.
  num get yearly => switch (per) {
    'month' => amount * 12,
    'hour' => amount * 37.5 * 52,
    _ => amount,
  };

  static const _symbols = {'GBP': '£', 'EUR': '€', 'USD': r'US$', 'SGD': r'S$', 'CAD': r'C$', 'NZD': r'NZ$'};

  /// "£41,700 a year", "€5,942 a month", "S$5,600 a month".
  String get label {
    final whole = amount == amount.roundToDouble();
    final digits = whole ? amount.round().toString() : amount.toStringAsFixed(2);
    final parts = digits.split('.');
    final grouped = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final n = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
    final sym = _symbols[currency];
    return '${sym ?? '$currency '}$n a $per';
  }

  Json toJson() => {'amount': amount, 'currency': currency, 'per': per};

  static Money? fromJson(Object? v) {
    final j = obj(v);
    final a = numOf(j['amount']);
    if (a == null || str(j['currency']).isEmpty) return null;
    return Money(a, str(j['currency']), per: str(j['per']).isEmpty ? 'year' : str(j['per']));
  }
}

/// How a route decides which jobs qualify.
enum OccupationRule {
  /// The UK's SOC 2020 tables (Appendix Skilled Occupations).
  ukSkilled,

  /// The UK Health and Care visa: the eligible codes, at health or care employers.
  ukHealthCare,

  /// Any job that meets the pay floor (lists of excluded jobs not shipped).
  payFloor,

  /// Points or rounds (Canada's Express Entry); no pay floor.
  points,

  /// Not checked by Udyoga: the AI assessment researches it.
  unchecked,
}

/// A way to get the right to work in a country.
class VisaRoute {
  const VisaRoute({
    required this.id,
    required this.country,
    required this.name,
    required this.summary,
    required this.rule,
    required this.source,
    this.floor,
    this.reducedFloor,
    this.reducedWhen = '',
    this.sponsored = true,
    this.requirements = const [],
    this.notes = const [],
    this.more = const [],
  });

  /// Stable id: "gb.skilled-worker".
  final String id;

  /// ISO alpha-2.
  final String country;
  final String name, summary;
  final OccupationRule rule;

  /// The general pay floor, when the route has one.
  final Money? floor;

  /// A lower floor and when it applies ("new entrants", "under 30").
  final Money? reducedFloor;
  final String reducedWhen;

  /// Needs a job offer from an employer that sponsors or applies.
  final bool sponsored;

  /// What the person must meet, in plain words.
  final List<String> requirements;

  /// Worth knowing, in plain words.
  final List<String> notes;

  /// The main source, and any others.
  final RouteSource source;
  final List<RouteSource> more;

  bool get verified => source.verified;
}

/// A UK SOC 2020 occupation code as Appendix Skilled Occupations lists it.
class UkOccupation {
  const UkOccupation({
    required this.soc,
    required this.title,
    required this.table,
    this.goingRate,
    this.newEntrantRate,
    this.careRate,
    this.careNewEntrantRate,
    this.tsl = false,
    this.tslJobs = const [],
    this.healthCare,
  });

  final String soc, title;

  /// '1' (eligible), '1a' (only for those sponsored before 22 July 2025,
  /// or on the Temporary Shortage List), '6' (not eligible).
  final String table;

  /// Table 1 or 1a going rate, and its 70% new-entrant rate, a year in GBP.
  final int? goingRate, newEntrantRate;

  /// Table 2 (or 2aa) going rate, used for Health and Care ASHE jobs, and
  /// its new-entrant rate.
  final int? careRate, careNewEntrantRate;

  /// On the Temporary Shortage List (SW 6.1A); for some codes only the named
  /// [tslJobs].
  final bool tsl;
  final List<String> tslJobs;

  /// On the Health and Care visa list; null when Udyoga has not checked.
  final bool? healthCare;

  Json toJson() => {
    'soc': soc,
    'title': title,
    'table': table,
    'goingRate': goingRate,
    'newEntrantRate': newEntrantRate,
    'careRate': careRate,
    'careNewEntrantRate': careNewEntrantRate,
    'tsl': tsl,
    'tslJobs': tslJobs,
    'healthCare': healthCare,
  };

  factory UkOccupation.fromJson(Json j) => UkOccupation(
    soc: str(j['soc']),
    title: str(j['title']),
    table: str(j['table']),
    goingRate: intOf(j['goingRate']),
    newEntrantRate: intOf(j['newEntrantRate']),
    careRate: intOf(j['careRate']),
    careNewEntrantRate: intOf(j['careNewEntrantRate']),
    tsl: j['tsl'] == true,
    tslJobs: strs(j['tslJobs']),
    healthCare: j['healthCare'] is bool ? j['healthCare'] as bool : null,
  );

  UkOccupation copyWith({
    String? title,
    String? table,
    int? goingRate,
    int? newEntrantRate,
    int? careRate,
    int? careNewEntrantRate,
    bool? tsl,
    List<String>? tslJobs,
  }) => UkOccupation(
    soc: soc,
    title: title ?? this.title,
    table: table ?? this.table,
    goingRate: goingRate ?? this.goingRate,
    newEntrantRate: newEntrantRate ?? this.newEntrantRate,
    careRate: careRate ?? this.careRate,
    careNewEntrantRate: careNewEntrantRate ?? this.careNewEntrantRate,
    tsl: tsl ?? this.tsl,
    tslJobs: tslJobs ?? this.tslJobs,
    healthCare: healthCare,
  );
}

/// A rule that keeps some jobs for a country's own citizens.
class NationalsOnly {
  const NationalsOnly({
    required this.country,
    required this.name,
    required this.detail,
    required this.iscoPrefixes,
    required this.source,
  });
  final String country, name, detail;

  /// ISCO-08 codes (or their first digits) the rule covers.
  final List<String> iscoPrefixes;
  final RouteSource source;

  bool covers(String isco) => isco.isNotEmpty && iscoPrefixes.any(isco.startsWith);
}

/// The UK rules that change with each Statement of Changes, as one value so
/// a live refresh can replace them together.
class UkRules {
  const UkRules({
    required this.generalFloor,
    required this.newEntrantFloor,
    required this.careFloor,
    required this.careNewEntrantFloor,
    required this.tslCutoff,
    required this.occupations,
    required this.source,
    this.live = false,
  });

  /// Option A (£41,700), option E (£33,400), option F (£31,300) and the
  /// Table 2 new-entrant floor (£25,000), a year in GBP.
  final int generalFloor, newEntrantFloor, careFloor, careNewEntrantFloor;

  /// A Temporary Shortage List job needs a certificate of sponsorship issued
  /// before this day, yyyy-MM-dd.
  final String tslCutoff;
  final Map<String, UkOccupation> occupations;
  final RouteSource source;

  /// Read from GOV.UK on this device, rather than shipped.
  final bool live;

  Json toJson() => {
    'generalFloor': generalFloor,
    'newEntrantFloor': newEntrantFloor,
    'careFloor': careFloor,
    'careNewEntrantFloor': careNewEntrantFloor,
    'tslCutoff': tslCutoff,
    'occupations': [for (final o in occupations.values) o.toJson()],
    'source': source.toJson(),
  };

  factory UkRules.fromJson(Json j) => UkRules(
    generalFloor: intOf(j['generalFloor']) ?? shippedUkRules.generalFloor,
    newEntrantFloor: intOf(j['newEntrantFloor']) ?? shippedUkRules.newEntrantFloor,
    careFloor: intOf(j['careFloor']) ?? shippedUkRules.careFloor,
    careNewEntrantFloor: intOf(j['careNewEntrantFloor']) ?? shippedUkRules.careNewEntrantFloor,
    tslCutoff: isDay(str(j['tslCutoff'])) ? str(j['tslCutoff']) : shippedUkRules.tslCutoff,
    occupations: {
      for (final o in objs(j['occupations']).map(UkOccupation.fromJson))
        if (o.soc.isNotEmpty) o.soc: o,
    },
    source: RouteSource.fromJson(obj(j['source'])),
    live: true,
  );
}

// ---- the shipped tables ----

/// The day the shipped tables were read from their sources.
const routesAsOf = '2026-11-19';

const _aso = RouteSource(
  'Immigration Rules Appendix Skilled Occupations (GOV.UK, updated 11 Nov 2025)',
  'https://www.gov.uk/guidance/immigration-rules/immigration-rules-appendix-skilled-occupations',
  asOf: routesAsOf,
);

const _asw = RouteSource(
  'Immigration Rules Appendix Skilled Worker (GOV.UK, updated 8 Oct 2026)',
  'https://www.gov.uk/guidance/immigration-rules/immigration-rules-appendix-skilled-worker',
  asOf: routesAsOf,
);

const _hcwJob = RouteSource(
  'Health and Care Worker visa: your job (GOV.UK)',
  'https://www.gov.uk/health-care-worker-visa/your-job',
  asOf: routesAsOf,
);

const _ukEnglish = RouteSource(
  'Skilled Worker visa: knowledge of English (GOV.UK)',
  'https://www.gov.uk/skilled-worker-visa/knowledge-of-english',
  asOf: routesAsOf,
);

/// The UK codes Udyoga ships, for health administration, electronic
/// patient record and IT work. Rates are a year in GBP from Appendix
/// Skilled Occupations Tables 1, 1a, 2 and 2aa; the TSL from Appendix
/// Skilled Worker SW 6.1A; Health and Care from GOV.UK.
const _ukOccupations = [
  UkOccupation(
    soc: '1137',
    title: 'Information technology directors',
    table: '1',
    goingRate: 86000,
    newEntrantRate: 60200,
    careRate: 61200,
    careNewEntrantRate: 42800,
  ),
  UkOccupation(
    soc: '1171',
    title: 'Health services and public health managers and directors',
    table: '1',
    goingRate: 50300,
    newEntrantRate: 35200,
    careRate: 41600,
    careNewEntrantRate: 29100,
    healthCare: true,
  ),
  UkOccupation(
    soc: '1231',
    title: 'Health care practice managers',
    table: '1a',
    goingRate: 40400,
    newEntrantRate: 33400,
    careRate: 32600,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(
    soc: '2133',
    title: 'IT business analysts, architects and systems designers',
    table: '1',
    goingRate: 54900,
    newEntrantRate: 38400,
    careRate: 42400,
    careNewEntrantRate: 29600,
    healthCare: false,
  ),
  UkOccupation(
    soc: '2134',
    title: 'Programmers and software development professionals',
    table: '1',
    goingRate: 54700,
    newEntrantRate: 38300,
    careRate: 40000,
    careNewEntrantRate: 28000,
    healthCare: false,
  ),
  UkOccupation(
    soc: '2135',
    title: 'Cyber security professionals',
    table: '1',
    goingRate: 48500,
    newEntrantRate: 34000,
    careRate: 35300,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(
    soc: '2136',
    title: 'IT quality and testing professionals',
    table: '1',
    goingRate: 41200,
    newEntrantRate: 33400,
    careRate: 34500,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(
    soc: '2137',
    title: 'IT network professionals',
    table: '1',
    goingRate: 45600,
    newEntrantRate: 33400,
    careRate: 38100,
    careNewEntrantRate: 26700,
  ),
  UkOccupation(
    soc: '2139',
    title: 'Information technology professionals not elsewhere classified',
    table: '1',
    goingRate: 52300,
    newEntrantRate: 36600,
    careRate: 38700,
    careNewEntrantRate: 27100,
    healthCare: false,
  ),
  UkOccupation(
    soc: '2431',
    title: 'Management consultants and business analysts',
    table: '1',
    goingRate: 50200,
    newEntrantRate: 35100,
    careRate: 36000,
    careNewEntrantRate: 25200,
  ),
  UkOccupation(
    soc: '2440',
    title: 'Business and financial project management professionals',
    table: '1',
    goingRate: 56500,
    newEntrantRate: 39500,
    careRate: 43300,
    careNewEntrantRate: 30300,
  ),
  UkOccupation(
    soc: '3131',
    title: 'IT operations technicians',
    table: '1a',
    goingRate: 35200,
    newEntrantRate: 33400,
    careRate: 27700,
    careNewEntrantRate: 25000,
    tsl: true,
  ),
  UkOccupation(
    soc: '3132',
    title: 'IT user support technicians',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 27700,
    careNewEntrantRate: 25000,
    tsl: true,
  ),
  UkOccupation(
    soc: '3133',
    title: 'Database administrators and web content technicians',
    table: '1a',
    goingRate: 34600,
    newEntrantRate: 33400,
    careRate: 29200,
    careNewEntrantRate: 25000,
    tsl: true,
  ),
  UkOccupation(
    soc: '3544',
    title: 'Data analysts',
    table: '1a',
    goingRate: 34900,
    newEntrantRate: 33400,
    careRate: 28600,
    careNewEntrantRate: 25000,
    tsl: true,
    healthCare: false,
  ),
  UkOccupation(
    soc: '3549',
    title: 'Business associate professionals not elsewhere classified',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 25500,
    careNewEntrantRate: 25000,
    tsl: true,
    tslJobs: [
      'Business support officers',
      'Business systems analysts',
      'Contract administrators',
      'Clinical coders',
      'Clinical trials administrators',
      'Research coordinators',
    ],
    healthCare: false,
  ),
  UkOccupation(
    soc: '3573',
    title: 'Information technology trainers',
    table: '1a',
    goingRate: 40000,
    newEntrantRate: 33400,
    careRate: 32100,
    careNewEntrantRate: 25000,
    tsl: true,
    healthCare: false,
  ),
  UkOccupation(
    soc: '4112',
    title: 'Local government administrative occupations',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 26000,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(
    soc: '4113',
    title: 'Officers of non-governmental organisations',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 25000,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(soc: '4131', title: 'Records clerks and assistants', table: '6'),
  UkOccupation(
    soc: '4159',
    title: 'Other administrative occupations not elsewhere classified',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 25000,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(soc: '4211', title: 'Medical secretaries', table: '6'),
  UkOccupation(
    soc: '4214',
    title: 'Company secretaries and administrators',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 27100,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(
    soc: '4215',
    title: 'Personal assistants and other secretaries',
    table: '1a',
    goingRate: 33400,
    newEntrantRate: 33400,
    careRate: 27400,
    careNewEntrantRate: 25000,
  ),
  UkOccupation(soc: '4216', title: 'Receptionists', table: '6'),
  UkOccupation(soc: '4217', title: 'Typists and related keyboard occupations', table: '6'),
];

/// The UK rules as shipped (read 19 Nov 2026).
final shippedUkRules = UkRules(
  generalFloor: 41700,
  newEntrantFloor: 33400,
  careFloor: 31300,
  careNewEntrantFloor: 25000,
  tslCutoff: '2026-12-31',
  occupations: {for (final o in _ukOccupations) o.soc: o},
  source: _aso,
);

/// Pay floors as the screen needs them: the UK's from [uk].
List<VisaRoute> ukRoutes(UkRules uk) => [
  VisaRoute(
    id: 'gb.skilled-worker',
    country: 'GB',
    name: 'Skilled Worker visa',
    summary:
        'A licensed sponsor offers a job in an eligible SOC 2020 code. The pay must reach both the general '
        'threshold and the going rate for the code.',
    rule: OccupationRule.ukSkilled,
    floor: Money(uk.generalFloor, 'GBP'),
    reducedFloor: Money(uk.newEntrantFloor, 'GBP'),
    reducedWhen:
        'new entrants (70% of the going rate): under 26, switching from a Student or Graduate visa, or working '
        'towards a recognised professional qualification or registration (SW 12.2)',
    requirements: [
      'A job offer and a certificate of sponsorship from a licensed sponsor. The sponsor picks the SOC code.',
      'The job must be in Table 1, 2 or 3 of Appendix Skilled Occupations, the Immigration Salary List, or the '
          'Temporary Shortage List (certificate issued before ${_day(uk.tslCutoff)}).',
      'English at level B2.',
    ],
    notes: [
      'Codes only on the Temporary Shortage List or Table 1a cannot bring new dependants.',
      'Time as a dependant does not count towards your own Skilled Worker settlement (SW 21.2).',
    ],
    source: uk.live ? uk.source : _asw,
    more: [_aso, _ukEnglish],
  ),
  VisaRoute(
    id: 'gb.health-care',
    country: 'GB',
    name: 'Health and Care Worker visa',
    summary:
        'The Skilled Worker route for eligible health and care codes at the NHS, an NHS supplier or adult social '
        'care. Lower Table 2 going rates apply.',
    rule: OccupationRule.ukHealthCare,
    floor: Money(uk.careFloor, 'GBP'),
    reducedFloor: Money(uk.careNewEntrantFloor, 'GBP'),
    reducedWhen: 'new entrants (options F to J, Table 2 rates)',
    requirements: [
      'An eligible health or care code. None of the IT codes (2133, 2134, 2139, 3544, 3549, 3573) is eligible; '
          '1171 is.',
      'A job with the NHS, an organisation that provides services to the NHS, or adult social care.',
    ],
    source: _hcwJob,
    more: [_asw, _aso],
  ),
];

String _day(String d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final p = d.split('-');
  if (p.length != 3) return d;
  return '${int.parse(p[2])} ${months[int.parse(p[1]) - 1]} ${p[0]}';
}

const _dete = RouteSource(
  'DETE: employment permit salary thresholds from 1 March 2026 (news, 2 Dec 2025)',
  'https://enterprise.gov.ie/en/news-and-events/department-news/2025/december/20251202.html',
  asOf: routesAsOf,
);

const _detePermitTypes = RouteSource(
  'DETE: General Employment Permit',
  'https://enterprise.gov.ie/en/what-we-do/workplace-and-skills/employment-permits/permit-types/general-employment-permit/',
  asOf: routesAsOf,
);

const _irelandRoutes = [
  VisaRoute(
    id: 'ie.general-permit',
    country: 'IE',
    name: 'General Employment Permit',
    summary:
        'An employer offers a job not on the Ineligible Occupations List, paying at least the minimum. A labour '
        'market needs test normally applies.',
    rule: OccupationRule.payFloor,
    floor: Money(36605, 'EUR'),
    reducedFloor: Money(34009, 'EUR'),
    reducedWhen: 'holders of an Irish degree from the last 12 months',
    requirements: [
      'An offer of at least €36,605 a year (from 1 March 2026).',
      'The job is not on the Ineligible Occupations List.',
      'You hold the relevant qualifications, skills or experience. A degree is not required by the permit itself.',
    ],
    notes: [
      'Many clerical and administrative jobs are on the Ineligible Occupations List (unverified: Udyoga has not '
          'read the list; check it before applying).',
    ],
    source: _dete,
    more: [_detePermitTypes],
  ),
  VisaRoute(
    id: 'ie.critical-skills',
    country: 'IE',
    name: 'Critical Skills Employment Permit',
    summary: 'For jobs on the Critical Skills Occupations List, at or above the minimum pay.',
    rule: OccupationRule.payFloor,
    floor: Money(40904, 'EUR'),
    requirements: [
      'An offer of at least €40,904 a year (from 1 March 2026) in an occupation on the Critical Skills '
          'Occupations List.',
    ],
    notes: [
      'A higher threshold applies to eligible jobs not on that list; Udyoga has not verified the 2026 figure '
          '(unverified).',
      'Healthcare assistants and home carers have their own minimum, €32,691.',
    ],
    source: _dete,
  ),
];

const _germanyRoutes = [
  VisaRoute(
    id: 'de.blue-card',
    country: 'DE',
    name: 'EU Blue Card',
    summary: 'For skilled jobs at or above the yearly minimum; lower for shortage occupations and new entrants.',
    rule: OccupationRule.payFloor,
    floor: Money(50700, 'EUR'),
    reducedFloor: Money(45934.20, 'EUR'),
    reducedWhen: 'shortage occupations and new entrants',
    requirements: ['A job offer at or above €50,700 a year in 2026 (€45,934.20 for shortage jobs or new entrants).'],
    notes: [
      'A recognised university degree is normally needed; IT specialists may qualify on experience '
          '(unverified: check with the Federal Employment Agency).',
    ],
    source: RouteSource(
      'Federal Employment Agency (ZAV): EU Blue Card 2026 thresholds, issue 03-2026',
      'https://www.arbeitsagentur.de/vor-ort/zav/working-and-living-in-germany/iss-en/issue-03-2026/blue-card',
      asOf: routesAsOf,
    ),
  ),
];

const _ind = RouteSource(
  'IND: required amounts, income requirements (2026)',
  'https://ind.nl/en/required-amounts-income-requirements',
  asOf: routesAsOf,
);

const _netherlandsRoutes = [
  VisaRoute(
    id: 'nl.highly-skilled-migrant',
    country: 'NL',
    name: 'Highly skilled migrant',
    summary: 'A recognised sponsor employer pays at least the monthly minimum (holiday pay not counted).',
    rule: OccupationRule.payFloor,
    floor: Money(5942, 'EUR', per: 'month'),
    reducedFloor: Money(4357, 'EUR', per: 'month'),
    reducedWhen: 'under 30',
    requirements: ['A gross monthly salary of at least €5,942 at 30 or over, or €4,357 under 30 (2026).'],
    notes: [
      'A reduced amount for recent graduates (€3,122 a month) is unverified.',
      'The employer must be a recognised sponsor with the IND (unverified).',
    ],
    source: _ind,
  ),
  VisaRoute(
    id: 'nl.blue-card',
    country: 'NL',
    name: 'EU Blue Card',
    summary: 'For jobs that need a higher qualification, at or above the monthly minimum.',
    rule: OccupationRule.payFloor,
    floor: Money(5942, 'EUR', per: 'month'),
    reducedFloor: Money(4754, 'EUR', per: 'month'),
    reducedWhen: 'the reduced amount (for example recent graduates)',
    requirements: ['A gross monthly salary of at least €5,942 (2026), or €4,754 where the reduced amount applies.'],
    source: _ind,
  ),
];

const _singaporeRoutes = [
  VisaRoute(
    id: 'sg.employment-pass',
    country: 'SG',
    name: 'Employment Pass',
    summary:
        'For professionals with a job offer at or above the qualifying salary, which rises with age, and a pass '
        'under the COMPASS points framework.',
    rule: OccupationRule.payFloor,
    floor: Money(5600, 'SGD', per: 'month'),
    requirements: [
      'At least S\$5,600 a month (S\$6,200 in financial services), rising with age to S\$10,700 (S\$11,800).',
      'From 1 January 2027, new applications need at least S\$6,000 (S\$6,600 in financial services).',
      'Enough COMPASS points; jobs on the Shortage Occupation List earn a bonus (C5).',
    ],
    source: RouteSource(
      'Ministry of Manpower: Employment Pass eligibility',
      'https://www.mom.gov.sg/passes-and-permits/employment-pass/eligibility',
      asOf: routesAsOf,
    ),
  ),
];

/// Canada's category page (NOC codes per category).
const expressEntryCategories = RouteSource(
  'IRCC: Express Entry category-based selection',
  'https://www.canada.ca/en/immigration-refugees-citizenship/services/immigrate-canada/express-entry/rounds-invitations/category-based-selection.html',
  asOf: routesAsOf,
);

/// Canada's rounds of invitations, as JSON.
const expressEntryRoundsUrl = 'https://www.canada.ca/content/dam/ircc/documents/json/ee_rounds_123_en.json';

const _canadaRoutes = [
  VisaRoute(
    id: 'ca.express-entry',
    country: 'CA',
    name: 'Express Entry (permanent residence)',
    summary:
        'A points-based pool (CRS score). Rounds invite the top scores overall or in a category such as '
        'healthcare and social services. No job offer is needed.',
    rule: OccupationRule.points,
    sponsored: false,
    requirements: [
      'A profile in the pool with a Comprehensive Ranking System score at or above a round\'s cut-off.',
      'Category rounds take only the NOC codes listed for that category.',
    ],
    notes: [
      'A language test and an educational credential assessment (such as WES, about C\$264) are needed '
          '(unverified: confirm on IRCC).',
    ],
    source: RouteSource('IRCC: Express Entry rounds of invitations (JSON)', expressEntryRoundsUrl, asOf: routesAsOf),
    more: [expressEntryCategories],
  ),
];

const _australiaRoutes = [
  VisaRoute(
    id: 'au.employer-sponsored',
    country: 'AU',
    name: 'Employer-sponsored temporary skilled visa',
    summary:
        'An approved sponsor nominates the job against the core skills occupation list and an income threshold. '
        'Udyoga has not verified the current list or threshold.',
    rule: OccupationRule.unchecked,
    source: RouteSource(
      'Department of Home Affairs: visa listing (page would not load)',
      'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing',
      asOf: routesAsOf,
      verified: false,
    ),
  ),
];

const _newZealandRoutes = [
  VisaRoute(
    id: 'nz.accredited-employer',
    country: 'NZ',
    name: 'Accredited Employer Work Visa',
    summary: 'An accredited employer offers a job paying at least the median wage, unless an exemption applies.',
    rule: OccupationRule.payFloor,
    floor: Money(35, 'NZD', per: 'hour'),
    requirements: ['At least NZ\$35.00 an hour from 9 March 2026 (unverified: from a search summary of INZ pages).'],
    notes: ['The Green List gives some occupations a faster route to residence (unverified).'],
    source: RouteSource(
      'Immigration New Zealand (not read directly)',
      'https://www.immigration.govt.nz/',
      asOf: routesAsOf,
      verified: false,
    ),
  ),
];

VisaRoute _gccRoute(String code, String name, String authority, String url) => VisaRoute(
  id: '${code.toLowerCase()}.work-permit',
  country: code,
  name: 'Employer-sponsored work permit',
  summary:
      'An employer in $name applies for the work permit and residence visa. Udyoga has not verified the '
      'rules or fees.',
  rule: OccupationRule.unchecked,
  source: RouteSource(authority, url, asOf: routesAsOf, verified: false),
);

/// Jobs a country keeps for its own citizens. Unverified: the official
/// lists change often and were not readable; the AI assessment checks them.
const nationalsOnlyRules = [
  NationalsOnly(
    country: 'SA',
    name: 'Saudization (Nitaqat)',
    detail:
        'Many administrative, clerical, HR and reception jobs are reserved for Saudi nationals, and employers '
        'must meet Saudi hiring quotas.',
    iscoPrefixes: ['4', '1212', '2423'],
    source: RouteSource(
      'Ministry of Human Resources and Social Development',
      'https://www.hrsd.gov.sa/en',
      asOf: routesAsOf,
      verified: false,
    ),
  ),
  NationalsOnly(
    country: 'OM',
    name: 'Omanisation',
    detail: 'Many administrative, clerical and HR jobs are restricted to Omani nationals, with quotas for the rest.',
    iscoPrefixes: ['4', '1212', '2423'],
    source: RouteSource('Ministry of Labour, Oman', 'https://www.mol.gov.om/', asOf: routesAsOf, verified: false),
  ),
  NationalsOnly(
    country: 'KW',
    name: 'Kuwaitisation',
    detail: 'Government and many administrative jobs are being filled with Kuwaiti nationals.',
    iscoPrefixes: ['4', '1212', '2423'],
    source: RouteSource(
      'Public Authority for Manpower, Kuwait',
      'https://www.manpower.gov.kw/',
      asOf: routesAsOf,
      verified: false,
    ),
  ),
];

/// The routes Udyoga knows for [country] with the UK rules in [uk] (live or
/// shipped); empty for a country it has no data on.
List<VisaRoute> routesFor(String country, {UkRules? uk}) => switch (country.toUpperCase()) {
  'GB' => ukRoutes(uk ?? shippedUkRules),
  'IE' => _irelandRoutes,
  'DE' => _germanyRoutes,
  'NL' => _netherlandsRoutes,
  'SG' => _singaporeRoutes,
  'CA' => _canadaRoutes,
  'AU' => _australiaRoutes,
  'NZ' => _newZealandRoutes,
  'AE' => [_gccRoute('AE', 'the UAE', 'Ministry of Human Resources and Emiratisation', 'https://www.mohre.gov.ae/en')],
  'SA' => [
    _gccRoute('SA', 'Saudi Arabia', 'Ministry of Human Resources and Social Development', 'https://www.hrsd.gov.sa/en'),
  ],
  'QA' => [_gccRoute('QA', 'Qatar', 'Ministry of Interior, Qatar', 'https://portal.moi.gov.qa/')],
  'OM' => [_gccRoute('OM', 'Oman', 'Ministry of Labour, Oman', 'https://www.mol.gov.om/')],
  'KW' => [_gccRoute('KW', 'Kuwait', 'Public Authority for Manpower, Kuwait', 'https://www.manpower.gov.kw/')],
  'BH' => [_gccRoute('BH', 'Bahrain', 'Labour Market Regulatory Authority, Bahrain', 'https://lmra.gov.bh/')],
  _ => const [],
};

/// Countries with route data, for the "has data" filter.
const countriesWithRoutes = ['GB', 'IE', 'DE', 'NL', 'SG', 'CA', 'AU', 'NZ', 'AE', 'SA', 'QA', 'OM', 'KW', 'BH'];

/// The nationals-only rules in [country].
List<NationalsOnly> nationalsOnlyIn(String country) =>
    nationalsOnlyRules.where((r) => r.country == country.toUpperCase()).toList();
