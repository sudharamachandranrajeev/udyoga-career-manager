/// Role path insight ("Approach this role", role search plan U4): for one
/// role, what it is, how the person fits, the ways in, stepping-stone roles,
/// pay, how people got in, first moves and a career path timeline.
///
/// Built in layers, each piece marked with where it came from:
/// 1. Shipped and cached data, no AI: the role's other titles (role
///    families, U1), the skills ESCO lists for it checked against the
///    profile, example titles for stepping stones, and NHS Agenda for
///    Change pay points where NHS pay applies.
/// 2. Optional keyed sources (lib/domain/career_data.dart): the National
///    Careers Service and Skills England, only with the person's own key.
/// 3. The AI advisor (any provider, local ones too): the rest. Every part
///    the AI wrote is marked [InsightFrom.ai], so the screen labels it "AI".
///
/// Each section keeps its sources with a date, and the whole insight is
/// saved (synced table career_role_insights), so it opens again without AI.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'advisor.dart';
import 'book.dart';
import 'career_data.dart';
import 'countries.dart';
import 'feeds.dart';
import 'job_identity.dart';
import 'json.dart';
import 'occupations.dart';
import 'pay.dart';
import 'profile.dart';
import 'role_family.dart';
import 'role_search.dart';
import 'schema.dart';

/// Where a piece of an insight came from.
enum InsightFrom {
  /// The person's own profile.
  profile,

  /// The ONS SOC 2020 coding index (shipped).
  soc,

  /// Udyoga's head-noun synonym map (shipped).
  synonym,

  /// ESCO (European Commission), cached on the device.
  esco,

  /// Udyoga's built-in NHS Agenda for Change pay points.
  afc,

  /// The National Careers Service job profiles API (own key).
  ncs,

  /// Skills England's occupational maps API (own key).
  skillsEngland,

  /// An AI model. Always shown with an "AI" label.
  ai,

  /// Udyoga's own fixed wording (the people-search checklist).
  udyoga;

  bool get isAi => this == InsightFrom.ai;

  static InsightFrom of(String name) => InsightFrom.values.asNameMap()[name] ?? InsightFrom.udyoga;
}

/// Where a family title's source puts it as an insight source.
InsightFrom fromFamily(FamilySource s) => switch (s) {
  FamilySource.typed => InsightFrom.profile,
  FamilySource.soc => InsightFrom.soc,
  FamilySource.synonym => InsightFrom.synonym,
  FamilySource.esco => InsightFrom.esco,
  FamilySource.ai => InsightFrom.ai,
};

/// A source behind one section, with the date it was read or written.
class InsightSource {
  const InsightSource(this.from, {required this.label, this.url = '', required this.date});
  final InsightFrom from;
  final String label, url;

  /// yyyy-MM-dd.
  final String date;

  Json toJson() => {'from': from.name, 'label': label, 'url': url, 'date': date};

  factory InsightSource.fromJson(Json j) => InsightSource(
    InsightFrom.of(str(j['from'])),
    label: str(j['label']),
    url: str(j['url']),
    date: str(j['date']),
  );
}

/// The sections of an insight, in the order shown, with their headings.
const insightSections = {
  'about': 'What the role is',
  'fit': 'Fit and gaps',
  'waysIn': 'Ways in',
  'stones': 'Stepping stones',
  'pay': 'Pay and progression',
  'people': 'How people got in',
  'moves': 'First moves (next 30 days)',
  'path': 'Career path',
};

/// A line of text and where it came from.
class Line {
  const Line(this.text, this.from);
  final String text;
  final InsightFrom from;

  Json toJson() => {'text': text, 'from': from.name};
  factory Line.fromJson(Json j) => Line(str(j['text']), InsightFrom.of(str(j['from'])));
}

/// Something the role asks for: an ESCO skill, or a requirement the AI or
/// a keyed source named. Gaps and study topics point at these by [id].
class RoleCriterion {
  const RoleCriterion({
    required this.id,
    required this.text,
    required this.essential,
    this.kind = 'skill',
    required this.from,
    this.shown,
    this.evidence = '',
  });
  final String id, text;

  /// Essential (ESCO "essential", or a blocker or major gap) or optional.
  final bool essential;

  /// skill | knowledge | requirement.
  final String kind;
  final InsightFrom from;

  /// Whether the profile shows it: true or false when checked on the
  /// device, null when not checked (named by the AI or a keyed source).
  final bool? shown;

  /// The profile line that shows it.
  final String evidence;

  Json toJson() => {
    'id': id,
    'text': text,
    'essential': essential,
    'kind': kind,
    'from': from.name,
    'shown': shown,
    'evidence': evidence,
  };

  factory RoleCriterion.fromJson(Json j) => RoleCriterion(
    id: str(j['id']),
    text: str(j['text']),
    essential: j['essential'] == true,
    kind: str(j['kind']).isEmpty ? 'skill' : str(j['kind']),
    from: InsightFrom.of(str(j['from'])),
    shown: j['shown'] is bool ? j['shown'] as bool : null,
    evidence: str(j['evidence']),
  );
}

/// How serious a gap is.
const gapSeverities = ['blocker', 'major', 'minor'];

/// Something the role asks for that the profile does not show yet.
class Gap {
  const Gap({
    required this.text,
    required this.severity,
    this.howToClose = '',
    this.criterion = '',
    required this.from,
  });
  final String text;

  /// blocker | major | minor.
  final String severity;
  final String howToClose;

  /// The [RoleCriterion.id] it falls short of.
  final String criterion;
  final InsightFrom from;

  Json toJson() => {
    'text': text,
    'severity': severity,
    'howToClose': howToClose,
    'criterion': criterion,
    'from': from.name,
  };

  factory Gap.fromJson(Json j) => Gap(
    text: str(j['text']),
    severity: gapSeverities.contains(str(j['severity'])) ? str(j['severity']) : 'minor',
    howToClose: str(j['howToClose']),
    criterion: str(j['criterion']),
    from: InsightFrom.of(str(j['from'])),
  );
}

/// Kinds of way into a role.
const wayInKinds = {
  'apprenticeship': 'Apprenticeship',
  'internal': 'Internal move',
  'qualification': 'Qualification',
  'bank': 'Bank or temporary work',
  'secondment': 'Secondment',
  'volunteering': 'Volunteering',
  'direct': 'Apply directly',
  'other': 'Other route',
};

/// One way into the role.
class WayIn {
  const WayIn({required this.kind, required this.title, this.detail = '', this.url = '', required this.from});
  final String kind, title, detail, url;
  final InsightFrom from;

  Json toJson() => {'kind': kind, 'title': title, 'detail': detail, 'url': url, 'from': from.name};

  factory WayIn.fromJson(Json j) => WayIn(
    kind: wayInKinds.containsKey(str(j['kind'])) ? str(j['kind']) : 'other',
    title: str(j['title']),
    detail: str(j['detail']),
    url: str(j['url']),
    from: InsightFrom.of(str(j['from'])),
  );
}

/// A role on the way to the target, with job titles it is advertised under.
class SteppingStone {
  const SteppingStone({
    required this.role,
    this.why = '',
    this.titles = const [],
    this.timeframe = '',
    required this.from,
  });
  final String role, why;

  /// Example titles to search for, each with its own source.
  final List<FamilyTitle> titles;
  final String timeframe;

  /// Who named the stepping stone itself.
  final InsightFrom from;

  /// The search "Search these jobs" runs (role search, U2): the role and its
  /// example titles, every one switched on and shown as a chip there.
  RoleQuery get query => RoleQuery(role: role, titles: titles);

  Json toJson() => {
    'role': role,
    'why': why,
    'titles': [for (final t in titles) t.toJson()],
    'timeframe': timeframe,
    'from': from.name,
  };

  factory SteppingStone.fromJson(Json j) => SteppingStone(
    role: str(j['role']),
    why: str(j['why']),
    titles: [for (final t in objs(j['titles'])) FamilyTitle.fromJson(t)],
    timeframe: str(j['timeframe']),
    from: InsightFrom.of(str(j['from'])),
  );
}

/// A pay figure with its source and date.
class PayFigure {
  const PayFigure({
    required this.label,
    required this.amount,
    this.source = '',
    this.asOf = '',
    required this.from,
  });
  final String label, amount, source, asOf;
  final InsightFrom from;

  Json toJson() => {'label': label, 'amount': amount, 'source': source, 'asOf': asOf, 'from': from.name};

  factory PayFigure.fromJson(Json j) => PayFigure(
    label: str(j['label']),
    amount: str(j['amount']),
    source: str(j['source']),
    asOf: str(j['asOf']),
    from: InsightFrom.of(str(j['from'])),
  );
}

/// A first move for the next 30 days, and the criterion it works on.
class Move {
  const Move(this.text, {this.criterion = '', required this.from});
  final String text;

  /// The [RoleCriterion.id] it works on; '' when none.
  final String criterion;
  final InsightFrom from;

  Json toJson() => {'text': text, 'criterion': criterion, 'from': from.name};
  factory Move.fromJson(Json j) =>
      Move(str(j['text']), criterion: str(j['criterion']), from: InsightFrom.of(str(j['from'])));
}

/// Something the person did, said honestly in the target role's terms.
class CvLine {
  const CvLine({required this.experience, required this.inTargetTerms, required this.from});
  final String experience, inTargetTerms;
  final InsightFrom from;

  Json toJson() => {'experience': experience, 'inTargetTerms': inTargetTerms, 'from': from.name};
  factory CvLine.fromJson(Json j) => CvLine(
    experience: str(j['experience']),
    inTargetTerms: str(j['inTargetTerms']),
    from: InsightFrom.of(str(j['from'])),
  );
}

/// Where a stop sits on the career path.
const pathStages = {
  'now': 'Now',
  'stepping_stone': 'Stepping stone',
  'target': 'Target',
  'beyond': 'One step beyond',
};

/// One stop on the career path timeline.
class PathStop {
  const PathStop({
    required this.role,
    required this.stage,
    this.timeframe = '',
    this.likelihood,
    required this.from,
  });
  final String role;

  /// now | stepping_stone | target | beyond.
  final String stage;

  /// From now, e.g. "1-2 years"; '' when not known.
  final String timeframe;

  /// 0 to 100 that the person reaches it; null when not known.
  final int? likelihood;
  final InsightFrom from;

  Json toJson() => {
    'role': role,
    'stage': stage,
    'timeframe': timeframe,
    'likelihood': likelihood,
    'from': from.name,
  };

  factory PathStop.fromJson(Json j) => PathStop(
    role: str(j['role']),
    stage: pathStages.containsKey(str(j['stage'])) ? str(j['stage']) : 'stepping_stone',
    timeframe: str(j['timeframe']),
    likelihood: intOf(j['likelihood'])?.clamp(0, 100),
    from: InsightFrom.of(str(j['from'])),
  );
}

/// The id of the insight for [role]: the same on every device, so asking
/// again replaces it.
String roleInsightId(String role) => 'role:${normalJobTitle(role)}';

/// The insight for one role.
class RoleInsight {
  const RoleInsight({
    required this.id,
    required this.role,
    required this.created,
    String? updated,
    this.current = '',
    this.model = '',
    this.aiAsked = '',
    this.summary,
    this.titles = const [],
    this.soc = const [],
    this.criteria = const [],
    this.gaps = const [],
    this.fitOffline,
    this.fitAi,
    this.waysIn = const [],
    this.stones = const [],
    this.nhs = false,
    this.afc = const [],
    this.band,
    this.pay = const [],
    this.progression = const [],
    this.checklist = const [],
    this.moves = const [],
    this.cv = const [],
    this.path = const [],
    this.sources = const {},
    this.web = const [],
    this.keyed = const [],
    this.problems = const [],
  }) : updated = updated ?? created;

  final String id, role;

  /// When made and last changed (yyyy-MM-dd).
  final String created, updated;

  /// The person's current role when made (the path's start); '' if none.
  final String current;

  /// The AI model that wrote the AI parts, and when; '' when none has.
  final String model, aiAsked;

  // 1. What the role is.
  final Line? summary;
  final List<FamilyTitle> titles;
  final List<OccupationMatch> soc;

  // 2. Fit and gaps.
  final List<RoleCriterion> criteria;
  final List<Gap> gaps;

  /// Share of the ESCO skills the profile shows (essential weigh more),
  /// 0 to 100; null without ESCO skills.
  final int? fitOffline;

  /// The AI's judgement of readiness, 0 to 100; null until asked.
  final int? fitAi;

  // 3 and 4.
  final List<WayIn> waysIn;
  final List<SteppingStone> stones;

  // 5. Pay and progression.
  /// NHS pay (Agenda for Change) applies to the person.
  final bool nhs;

  /// The built-in Agenda for Change points, shown for reference when [nhs].
  final List<PayPoint> afc;

  /// The Agenda for Change band(s) the role is usually on ("6", "6-7").
  final Line? band;
  final List<PayFigure> pay;
  final List<Line> progression;

  // 6, 7 and 8.
  final List<Line> checklist;
  final List<Move> moves;
  final List<CvLine> cv;
  final List<PathStop> path;

  /// Each section's sources, by key of [insightSections].
  final Map<String, List<InsightSource>> sources;

  /// Web pages the AI said it relied on.
  final List<({String title, String url})> web;

  /// The keyed sources used ([InsightFrom.ncs], [InsightFrom.skillsEngland]),
  /// whose attribution the card shows.
  final List<InsightFrom> keyed;

  /// What could not be fetched, in plain words ("ESCO not reached").
  final List<String> problems;

  /// The fit to show: the AI's when asked, else the device's.
  int? get fit => fitAi ?? fitOffline;

  /// True when any part of [section] was written by the AI.
  bool aiIn(String section) => (sources[section] ?? const []).any((s) => s.from.isAi);

  /// The target's timeframe on the path, '' when not known.
  String get timeToReach => path.where((s) => s.stage == 'target').firstOrNull?.timeframe ?? '';

  /// The first of the first moves, '' when none.
  String get firstMove => moves.firstOrNull?.text ?? '';

  /// One line on pay: the first figure, else the NHS band.
  String get payLine {
    final f = pay.firstOrNull;
    if (f != null) return '${f.label.isEmpty ? '' : '${f.label}: '}${f.amount}';
    final b = band;
    return b == null || b.text.isEmpty ? '' : 'NHS Band ${b.text}';
  }

  /// The LinkedIn people search for the role's title, opened in the
  /// browser only. Udyoga never reads LinkedIn pages.
  Uri get peopleSearch => linkedInPeople(role);

  RoleCriterion? criterion(String id) => criteria.where((c) => c.id == id).firstOrNull;

  RoleInsight copyWith({
    String? updated,
    String? model,
    String? aiAsked,
    Line? summary,
    List<FamilyTitle>? titles,
    List<RoleCriterion>? criteria,
    List<Gap>? gaps,
    int? fitAi,
    List<WayIn>? waysIn,
    List<SteppingStone>? stones,
    Line? band,
    List<PayFigure>? pay,
    List<Line>? progression,
    List<Line>? checklist,
    List<Move>? moves,
    List<CvLine>? cv,
    List<PathStop>? path,
    Map<String, List<InsightSource>>? sources,
    List<({String title, String url})>? web,
    List<InsightFrom>? keyed,
    List<String>? problems,
  }) => RoleInsight(
    id: id,
    role: role,
    created: created,
    updated: updated ?? this.updated,
    current: current,
    model: model ?? this.model,
    aiAsked: aiAsked ?? this.aiAsked,
    summary: summary ?? this.summary,
    titles: titles ?? this.titles,
    soc: soc,
    criteria: criteria ?? this.criteria,
    gaps: gaps ?? this.gaps,
    fitOffline: fitOffline,
    fitAi: fitAi ?? this.fitAi,
    waysIn: waysIn ?? this.waysIn,
    stones: stones ?? this.stones,
    nhs: nhs,
    afc: afc,
    band: band ?? this.band,
    pay: pay ?? this.pay,
    progression: progression ?? this.progression,
    checklist: checklist ?? this.checklist,
    moves: moves ?? this.moves,
    cv: cv ?? this.cv,
    path: path ?? this.path,
    sources: sources ?? this.sources,
    web: web ?? this.web,
    keyed: keyed ?? this.keyed,
    problems: problems ?? this.problems,
  );

  Json toJson() => {
    'id': id,
    'role': role,
    'created': created,
    'updated': updated,
    'current': current,
    'model': model,
    'aiAsked': aiAsked,
    'summary': summary?.toJson(),
    'titles': [for (final t in titles) t.toJson()],
    'soc': [for (final m in soc) m.toJson()],
    'criteria': [for (final c in criteria) c.toJson()],
    'gaps': [for (final g in gaps) g.toJson()],
    'fitOffline': fitOffline,
    'fitAi': fitAi,
    'waysIn': [for (final w in waysIn) w.toJson()],
    'stones': [for (final s in stones) s.toJson()],
    'nhs': nhs,
    'afc': [
      for (final p in afc) {'scale': p.scale, 'band': p.band, 'step': p.step, 'pay': p.pay},
    ],
    'band': band?.toJson(),
    'pay': [for (final f in pay) f.toJson()],
    'progression': [for (final l in progression) l.toJson()],
    'checklist': [for (final l in checklist) l.toJson()],
    'moves': [for (final m in moves) m.toJson()],
    'cv': [for (final c in cv) c.toJson()],
    'path': [for (final s in path) s.toJson()],
    'sources': {
      for (final e in sources.entries) e.key: [for (final s in e.value) s.toJson()],
    },
    'web': [
      for (final s in web) {'title': s.title, 'url': s.url},
    ],
    'keyed': [for (final k in keyed) k.name],
    'problems': problems,
  };

  factory RoleInsight.fromJson(Json j) {
    Line? line(Object? v) => v is Map && str(v['text']).isNotEmpty ? Line.fromJson(obj(v)) : null;
    return RoleInsight(
      id: str(j['id']),
      role: str(j['role']),
      created: str(j['created']),
      updated: str(j['updated']),
      current: str(j['current']),
      model: str(j['model']),
      aiAsked: str(j['aiAsked']),
      summary: line(j['summary']),
      titles: [for (final t in objs(j['titles'])) FamilyTitle.fromJson(t)],
      soc: [for (final m in objs(j['soc'])) OccupationMatch.fromJson(m)],
      criteria: [for (final c in objs(j['criteria'])) RoleCriterion.fromJson(c)],
      gaps: [for (final g in objs(j['gaps'])) Gap.fromJson(g)],
      fitOffline: intOf(j['fitOffline']),
      fitAi: intOf(j['fitAi']),
      waysIn: [for (final w in objs(j['waysIn'])) WayIn.fromJson(w)],
      stones: [for (final s in objs(j['stones'])) SteppingStone.fromJson(s)],
      nhs: j['nhs'] == true,
      afc: [
        for (final p in objs(j['afc']))
          PayPoint(str(p['scale']), str(p['band']), str(p['step']), intOf(p['pay']) ?? 0),
      ],
      band: line(j['band']),
      pay: [for (final f in objs(j['pay'])) PayFigure.fromJson(f)],
      progression: [for (final l in objs(j['progression'])) Line.fromJson(l)],
      checklist: [for (final l in objs(j['checklist'])) Line.fromJson(l)],
      moves: [for (final m in objs(j['moves'])) Move.fromJson(m)],
      cv: [for (final c in objs(j['cv'])) CvLine.fromJson(c)],
      path: [for (final s in objs(j['path'])) PathStop.fromJson(s)],
      sources: {
        for (final e in obj(j['sources']).entries)
          e.key: [for (final s in objs(e.value)) InsightSource.fromJson(s)],
      },
      web: [
        for (final s in objs(j['web']))
          if (str(s['url']).isNotEmpty) (title: str(s['title']), url: str(s['url'])),
      ],
      keyed: [for (final k in strs(j['keyed'])) ?InsightFrom.values.asNameMap()[k]],
      problems: strs(j['problems']),
    );
  }

  // The JSON shape the AI answers in, PathStep-like for the path.
  static final aiSchema = object({
    'summary': string('What the role is and does day to day, in two or three plain sentences'),
    'fit': integer(
      '0 to 100: how ready the candidate is for this role today. 70+ only if they meet nearly all essentials',
    ),
    'gaps': array(
      object({
        'gap': string('What the role needs that the CV does not show yet'),
        'severity': oneOf(gapSeverities, 'blocker: rules them out (a registration or licence); major; minor'),
        'howToClose': string('A concrete way to close or honestly address it'),
        'criterion': string(
          'The skill or requirement it falls short of, copied from known_criteria when it is one',
        ),
      }),
      description: 'Most serious first',
    ),
    'waysIn': array(
      object({
        'kind': oneOf(wayInKinds.keys.toList()),
        'title': string('The route, e.g. a named apprenticeship standard or qualification'),
        'detail': string('Who it suits, how long it takes, cost if any'),
        'url': string("An official page, or ''"),
      }),
      description: 'Real entry routes in the candidate\'s country: apprenticeship, internal move, qualification, bank or temporary work, secondment',
    ),
    'steppingStones': array(
      object({
        'role': string('A real job title one step before the target'),
        'why': string('Why it leads to the target, in one sentence'),
        'exampleTitles': strings('Two to four real titles it is advertised under'),
        'timeframe': string('Typical time in it before moving on, e.g. "12-18 months"'),
      }),
      description: 'Two or three concrete roles, not generic advice',
    ),
    'pay': object({
      'nhsBand': string(
        'The Agenda for Change band or bands the role is usually on, e.g. "6" or "6-7"; \'\' when not NHS',
      ),
      'figures': array(
        object({
          'label': string('e.g. "Starter", "Experienced"'),
          'amount': string('With currency and period'),
          'source': string('Where the figure comes from'),
          'asOf': string('The year or date of the figure'),
        }),
      ),
      'progression': strings('Where the role leads and typical timelines, with the source'),
    }),
    'howPeopleGotIn': strings('A checklist for studying people who hold this title now: what to look for'),
    'firstMoves': array(
      object({
        'move': string('Something to do in the next 30 days'),
        'criterion': string('The gap or requirement it works on, as written in gaps'),
      }),
      description: 'Three to five',
    ),
    'cvWording': array(
      object({
        'experience': string('Something the candidate really did, from the CV'),
        'inTargetTerms': string('The same thing, honestly, in the target role\'s words'),
      }),
      description: 'Never claim anything the CV does not show',
    ),
    'path': array(
      object({
        'role': string(),
        'stage': oneOf(pathStages.keys.toList()),
        'timeframe': string('From now, e.g. "1-2 years"'),
        'likelihood': integer('0 to 100 that the candidate reaches it on this path'),
      }),
      description: 'From the current role, through the stepping stones, to the target and one step beyond',
    ),
    'sources': sourcesSchema,
  });
}

// --- Built on the device ---------------------------------------------------

const _stop = {
  'and', 'the', 'of', 'to', 'for', 'with', 'in', 'on', 'a', 'an', 'or', 'at', 'by', 'from', 'use', 'using', //
  'apply', 'perform', 'work', 'other', 'others', 'such', 'as', 'its', 'their',
};

String _stem(String w) {
  for (final end in const ['ings', 'ing', 'ions', 'ion', 'ers', 'er', 'ed', 'es', 's']) {
    if (w.endsWith(end) && w.length - end.length >= 4) return w.substring(0, w.length - end.length);
  }
  return w;
}

Set<String> _words(String text) => {
  for (final w in text.toLowerCase().split(RegExp('[^a-z0-9]+')))
    if (w.length > 2 && !_stop.contains(w)) _stem(w),
};

/// The lines of the profile a skill could be shown in.
List<String> profileLines(CandidateProfile p) => [
  ...p.skills,
  ...p.certifications,
  ...p.achievements,
  for (final e in p.experience) ...[e.title, ...e.highlights],
  for (final e in p.education) e.qualification,
  if (p.currentRole.isNotEmpty) p.currentRole,
  ...p.summary.split(RegExp(r'(?<=[.!?])\s+')),
].where((l) => l.trim().isNotEmpty).toList();

/// The profile line that shows [skill] (at least half of its words, any
/// form), or null.
String? shownIn(String skill, List<String> lines) {
  final want = _words(skill);
  if (want.isEmpty) return null;
  final need = (want.length / 2).ceil();
  String? best;
  var most = 0;
  for (final l in lines) {
    final n = _words(l).intersection(want).length;
    if (n >= need && n > most) {
      most = n;
      best = l;
    }
  }
  return best;
}

/// True when NHS (Agenda for Change) pay applies: the person is in the UK
/// and works for, or aims at, the NHS or Health and Social Care.
bool nhsApplies(CandidateProfile p, String role) {
  if (p.country.isNotEmpty && p.country.toUpperCase() != 'GB') return false;
  final nhs = RegExp(
    r'\b(nhs|hsc|health and social care|health (board|trust)|foundation trust|agenda for change|band [2-9])\b',
    caseSensitive: false,
  );
  return [
    role,
    p.currentEmployer,
    p.currentRole,
    p.headline,
    for (final e in p.experience) e.organisation,
    ...p.targets.roles,
  ].any(nhs.hasMatch);
}

/// The fixed checklist for studying people who hold the title, from what
/// job seekers say works (research, Reddit): look at their last role and
/// how long the move took.
const peopleChecklist = [
  'Open the people search and read the profiles of 10 people who hold this title now.',
  'For each, note the job they had just before and how long it took them to move.',
  'Note any qualification, course or registration they added on the way.',
  'Look for the pattern: an internal move, a secondment, a course or a stepping-stone title.',
  'Note the words they use for the work, to use honestly on your own CV.',
];

/// The sources shipped with Udyoga, for the section lines.
InsightSource socSource() => InsightSource(
  InsightFrom.soc,
  label: 'ONS SOC 2020 coding index v14 (Open Government Licence v3.0)',
  url: socIndexSource.url,
  date: socIndexSource.asOf,
);

InsightSource escoInsightSource(String date) =>
    InsightSource(InsightFrom.esco, label: escoCredit, url: escoSource.url, date: date);

const afcPayPage = 'https://www.nhsemployers.org/articles/pay-scales-202627';

InsightSource afcSource() => const InsightSource(
  InsightFrom.afc,
  label: 'NHS Employers pay scales 2026/27; DoH NI circular HSC (AfC) 06/2025 (built into Udyoga)',
  url: afcPayPage,
  date: '2026-11-16',
);

InsightSource aiSource(String model, String date) =>
    InsightSource(InsightFrom.ai, label: 'AI${model.isEmpty ? '' : ' ($model)'}', date: date);

/// The insight from the shipped and cached data only: [family] (U1),
/// [skills] (ESCO, null when unknown or offline) and the profile. No AI.
RoleInsight offlineInsight(
  String role,
  CandidateProfile p, {
  required RoleFamily family,
  RoleSkills? skills,
  required String today,
  String? created,
  List<String> problems = const [],
}) {
  final lines = profileLines(p);
  final criteria = <RoleCriterion>[];
  if (skills != null) {
    for (final (i, s) in skills.essential.indexed) {
      final ev = shownIn(s, lines);
      criteria.add(
        RoleCriterion(
          id: 'e${i + 1}',
          text: s,
          essential: true,
          from: InsightFrom.esco,
          shown: ev != null,
          evidence: ev ?? '',
        ),
      );
    }
    for (final (i, s) in skills.optional.indexed) {
      final ev = shownIn(s, lines);
      criteria.add(
        RoleCriterion(
          id: 'o${i + 1}',
          text: s,
          essential: false,
          from: InsightFrom.esco,
          shown: ev != null,
          evidence: ev ?? '',
        ),
      );
    }
  }
  final gaps = [
    for (final c in criteria)
      if (c.shown == false)
        Gap(text: c.text, severity: c.essential ? 'major' : 'minor', criterion: c.id, from: InsightFrom.esco),
  ];
  int? fit;
  if (criteria.isNotEmpty) {
    double share(bool essential) {
      final all = criteria.where((c) => c.essential == essential).toList();
      return all.isEmpty ? 1 : all.where((c) => c.shown == true).length / all.length;
    }

    fit = ((share(true) * 70) + (share(false) * 30)).round();
  }
  final nhs = nhsApplies(p, role);
  final esco = escoInsightSource(today);
  final aboutSources = <InsightSource>[
    if (family.titles.any((t) => t.source == FamilySource.soc)) socSource(),
    if (family.titles.any((t) => t.source == FamilySource.synonym))
      InsightSource(InsightFrom.synonym, label: 'Udyoga title synonyms', date: today),
    if (family.titles.any((t) => t.source == FamilySource.esco)) esco,
  ];
  return RoleInsight(
    id: roleInsightId(role),
    role: family.role.isEmpty ? role.trim() : family.role,
    created: created ?? today,
    updated: today,
    current: p.currentRole,
    titles: family.titles,
    soc: family.matches,
    criteria: criteria,
    gaps: _sorted(gaps),
    fitOffline: fit,
    nhs: nhs,
    afc: nhs ? afcPoints : const [],
    checklist: [for (final c in peopleChecklist) Line(c, InsightFrom.udyoga)],
    path: [
      if (p.currentRole.isNotEmpty) PathStop(role: p.currentRole, stage: 'now', from: InsightFrom.profile),
      PathStop(
        role: family.role.isEmpty ? role.trim() : family.role,
        stage: 'target',
        from: InsightFrom.profile,
      ),
    ],
    sources: {
      'about': aboutSources,
      'fit': [
        if (skills != null) esco,
        InsightSource(InsightFrom.profile, label: 'Your profile', date: today),
      ],
      'pay': [if (nhs) afcSource()],
      'people': [
        InsightSource(
          InsightFrom.udyoga,
          label: 'Udyoga checklist; LinkedIn opened as a link only',
          date: today,
        ),
      ],
      'path': [InsightSource(InsightFrom.profile, label: 'Your profile', date: today)],
    },
    problems: problems,
  );
}

List<Gap> _sorted(List<Gap> gaps) => [
  for (final sev in gapSeverities) ...gaps.where((g) => g.severity == sev),
];

String _key(String s) => normalJobTitle(s);

/// Example titles for a stepping stone [role] from the shipped data: its
/// close titles (the role itself, SOC siblings, synonyms), at most [max].
List<FamilyTitle> stoneTitles(String role, {int max = 4}) {
  final f = offlineFamily(role);
  return [
    for (final t in f.titles)
      if (t.closeness == Closeness.close) t,
  ].take(max).toList();
}

/// [i] with what keyed source [d] says added (ways in, pay, progression,
/// stepping stones and a summary when there is none yet).
RoleInsight withCareerData(RoleInsight i, CareerData d, {required String today}) {
  final src = InsightSource(
    d.from,
    label: d.credit.text,
    url: d.url.isEmpty ? d.credit.url : d.url,
    date: today,
  );
  Map<String, List<InsightSource>> add(Iterable<String> sections) => {
    ...i.sources,
    for (final s in sections) s: [...?i.sources[s], src],
  };
  final have = {for (final s in i.stones) _key(s.role)};
  return i.copyWith(
    summary: i.summary == null && d.summary.isNotEmpty ? Line(d.summary, d.from) : null,
    waysIn: [...i.waysIn, ...d.waysIn],
    stones: [
      ...i.stones,
      for (final s in d.stones)
        if (have.add(_key(s.role))) s,
    ],
    pay: [...i.pay, ...d.pay],
    progression: [...i.progression, for (final p in d.progression) Line(p, d.from)],
    keyed: {...i.keyed, d.from}.toList(),
    sources: add([
      if (i.summary == null && d.summary.isNotEmpty) 'about',
      if (d.waysIn.isNotEmpty) 'waysIn',
      if (d.stones.isNotEmpty) 'stones',
      if (d.pay.isNotEmpty || d.progression.isNotEmpty) 'pay',
    ]),
  );
}

/// What the AI is told it already knows about [i], so it fills gaps
/// rather than repeating the shipped data.
Json knownForAi(RoleInsight i) => {
  'role': i.role,
  'other_titles': [for (final t in i.titles.take(15)) t.title],
  'soc_2020': [for (final m in i.soc) '${m.soc} ${m.socTitle}'.trim()],
  'known_criteria': [
    for (final c in i.criteria.take(40)) {'text': c.text, 'essential': c.essential, 'shownInCv': c.shown},
  ],
  'nhs_pay_applies': i.nhs,
  if (i.waysIn.isNotEmpty) 'known_ways_in': [for (final w in i.waysIn) w.title],
  if (i.stones.isNotEmpty) 'known_stepping_stones': [for (final s in i.stones) s.role],
  if (i.pay.isNotEmpty) 'known_pay': [for (final f in i.pay) '${f.label} ${f.amount} (${f.source})'],
};

/// [i] with the AI's answer [data] merged in, every AI part marked as AI.
/// Re-asking replaces the AI parts and keeps the rest.
RoleInsight withAi(
  RoleInsight i,
  Json data, {
  required String model,
  required String today,
  List<({String title, String url})> web = const [],
}) {
  const ai = InsightFrom.ai;
  final base = withoutAi(i);
  final src = aiSource(model, today);

  // Criteria: the AI's gaps map onto known ones by text, else become new ones.
  final criteria = List.of(base.criteria);
  String criterionFor(String text, {required bool essential}) {
    final t = text.trim();
    if (t.isEmpty) return '';
    final k = t.toLowerCase();
    final known = criteria.where((c) => c.text.toLowerCase() == k).firstOrNull;
    if (known != null) return known.id;
    final id = 'a${criteria.where((c) => c.id.startsWith('a')).length + 1}';
    criteria.add(RoleCriterion(id: id, text: t, essential: essential, kind: 'requirement', from: ai));
    return id;
  }

  final aiGaps = <Gap>[];
  for (final g in objs(data['gaps'])) {
    final text = str(g['gap']);
    if (text.isEmpty) continue;
    final sev = gapSeverities.contains(str(g['severity'])) ? str(g['severity']) : 'minor';
    aiGaps.add(
      Gap(
        text: text,
        severity: sev,
        howToClose: str(g['howToClose']),
        criterion: criterionFor(
          str(g['criterion']).isEmpty ? text : str(g['criterion']),
          essential: sev != 'minor',
        ),
        from: ai,
      ),
    );
  }
  final aiFor = {for (final g in aiGaps) g.criterion};
  final gaps = _sorted([
    ...aiGaps,
    for (final g in base.gaps)
      if (!aiFor.contains(g.criterion)) g,
  ]);

  final moves = <Move>[];
  for (final m in objs(data['firstMoves']).take(5)) {
    final text = str(m['move']);
    if (text.isEmpty) continue;
    final c = str(m['criterion']);
    final gapMatch = aiGaps.where((g) => g.text.toLowerCase() == c.toLowerCase()).firstOrNull;
    moves.add(Move(text, criterion: gapMatch?.criterion ?? criterionFor(c, essential: false), from: ai));
  }

  final haveStones = {for (final s in base.stones) _key(s.role)};
  final stones = [
    ...base.stones,
    for (final s in objs(data['steppingStones']).take(3))
      if (str(s['role']).isNotEmpty && haveStones.add(_key(str(s['role']))))
        SteppingStone(
          role: str(s['role']),
          why: str(s['why']),
          timeframe: str(s['timeframe']),
          from: ai,
          titles: _dedupeTitles([
            ...stoneTitles(str(s['role'])),
            for (final t in strs(s['exampleTitles']).take(4))
              FamilyTitle(
                title: t,
                reason: 'AI suggestion',
                closeness: Closeness.related,
                source: FamilySource.ai,
              ),
          ]),
        ),
  ];

  final pay = obj(data['pay']);
  final band = str(pay['nhsBand']).replaceFirst(RegExp('^band\\s*', caseSensitive: false), '');
  final path = [
    for (final s in objs(data['path']))
      if (str(s['role']).isNotEmpty)
        PathStop(
          role: str(s['role']),
          stage: pathStages.containsKey(str(s['stage'])) ? str(s['stage']) : 'stepping_stone',
          timeframe: str(s['timeframe']),
          likelihood: intOf(s['likelihood'])?.clamp(0, 100),
          from: ai,
        ),
  ];
  final summary = str(data['summary']);
  final aiStones = stones.length > base.stones.length;

  Map<String, List<InsightSource>> sources() {
    final out = {for (final e in base.sources.entries) e.key: List.of(e.value)};
    void mark(String section, bool used) {
      if (used) (out[section] ??= []).add(src);
    }

    mark('about', summary.isNotEmpty && base.summary == null);
    mark('fit', aiGaps.isNotEmpty || intOf(data['fit']) != null);
    mark('waysIn', objs(data['waysIn']).isNotEmpty);
    mark('stones', aiStones);
    mark('pay', band.isNotEmpty || objs(pay['figures']).isNotEmpty || strs(pay['progression']).isNotEmpty);
    mark('people', strs(data['howPeopleGotIn']).isNotEmpty);
    mark('moves', moves.isNotEmpty || objs(data['cvWording']).isNotEmpty);
    mark('path', path.isNotEmpty);
    return out;
  }

  return base.copyWith(
    updated: today,
    model: model,
    aiAsked: today,
    summary: base.summary ?? (summary.isEmpty ? null : Line(summary, ai)),
    criteria: criteria,
    gaps: gaps,
    fitAi: intOf(data['fit'])?.clamp(0, 100),
    waysIn: [
      ...base.waysIn,
      for (final w in objs(data['waysIn']))
        if (str(w['title']).isNotEmpty) WayIn.fromJson({...w, 'from': ai.name}),
    ],
    stones: stones,
    band: band.isEmpty ? null : Line(band, ai),
    pay: [
      ...base.pay,
      for (final f in objs(pay['figures']))
        if (str(f['amount']).isNotEmpty) PayFigure.fromJson({...f, 'from': ai.name}),
    ],
    progression: [...base.progression, for (final l in strs(pay['progression'])) Line(l, ai)],
    checklist: [...base.checklist, for (final l in strs(data['howPeopleGotIn']).take(6)) Line(l, ai)],
    moves: moves,
    cv: [
      for (final c in objs(data['cvWording']))
        if (str(c['inTargetTerms']).isNotEmpty)
          CvLine(experience: str(c['experience']), inTargetTerms: str(c['inTargetTerms']), from: ai),
    ],
    path: path.isEmpty ? base.path : path,
    sources: sources(),
    web: _mergeWeb([
      ...web,
      for (final s in objs(data['sources'])) (title: str(s['title']), url: str(s['url'])),
    ]),
  );
}

List<({String title, String url})> _mergeWeb(List<({String title, String url})> all) {
  final seen = <String>{};
  return [
    for (final s in all)
      if (s.url.startsWith('http') && seen.add(s.url)) s,
  ];
}

List<FamilyTitle> _dedupeTitles(List<FamilyTitle> titles) {
  final seen = <String>{};
  return [
    for (final t in titles)
      if (t.title.trim().isNotEmpty && seen.add(_key(t.title))) t,
  ];
}

/// [i] without the AI's parts: what the device and keyed sources gave.
RoleInsight withoutAi(RoleInsight i) {
  bool keep(InsightFrom f) => !f.isAi;
  final criteria = i.criteria.where((c) => keep(c.from)).toList();
  return RoleInsight(
    id: i.id,
    role: i.role,
    created: i.created,
    updated: i.updated,
    current: i.current,
    summary: i.summary != null && keep(i.summary!.from) ? i.summary : null,
    titles: i.titles,
    soc: i.soc,
    criteria: criteria,
    gaps: [
      for (final g in i.gaps)
        if (keep(g.from)) g,
    ],
    fitOffline: i.fitOffline,
    waysIn: i.waysIn.where((w) => keep(w.from)).toList(),
    stones: i.stones.where((s) => keep(s.from)).toList(),
    nhs: i.nhs,
    afc: i.afc,
    pay: i.pay.where((f) => keep(f.from)).toList(),
    progression: i.progression.where((l) => keep(l.from)).toList(),
    checklist: i.checklist.where((l) => keep(l.from)).toList(),
    moves: i.moves.where((m) => keep(m.from)).toList(),
    cv: i.cv.where((c) => keep(c.from)).toList(),
    path: i.path.any((s) => s.from.isAi) ? _skeletonPath(i) : i.path,
    sources: {
      for (final e in i.sources.entries)
        e.key: [
          for (final s in e.value)
            if (keep(s.from)) s,
        ],
    },
    keyed: i.keyed,
    problems: i.problems,
  );
}

List<PathStop> _skeletonPath(RoleInsight i) => [
  if (i.current.isNotEmpty) PathStop(role: i.current, stage: 'now', from: InsightFrom.profile),
  PathStop(role: i.role, stage: 'target', from: InsightFrom.profile),
];

/// Builds insights: shipped data, then keyed sources (only those given,
/// which means only those with a key), then the AI when there is one.
class RoleInsightBuilder {
  RoleInsightBuilder({required this.families, this.advisor, this.keyed = const [], required this.today});

  final RoleFamilies families;

  /// Null: no AI; the insight is the shipped and keyed data only.
  final Advisor? advisor;

  /// Keyed sources with a key set; empty when none (they are then never asked).
  final List<CareerDataSource> keyed;
  final String today;

  /// The shipped and cached part for [role]: no AI, no keyed sources. With
  /// [offline], ESCO answers come from the device cache only.
  Future<RoleInsight> offline(
    String role,
    CandidateProfile p, {
    bool offline = false,
    String? created,
  }) async {
    final problems = <String>[];
    var family = offlineFamily(role);
    RoleSkills? skills;
    try {
      family = await families.family(role, offline: offline);
      skills = await families.skills(role, offline: offline);
    } on Object {
      problems.add('ESCO could not be reached; skills are left out until it can.');
    }
    return offlineInsight(
      role,
      p,
      family: family,
      skills: skills,
      today: today,
      created: created,
      problems: problems,
    );
  }

  /// [i] with every keyed source's data added. A source that fails is
  /// noted in [RoleInsight.problems] and skipped.
  Future<RoleInsight> addKeyed(RoleInsight i) async {
    var out = i;
    for (final k in keyed) {
      try {
        final d = await k.lookup(i.role, soc: i.soc);
        if (d != null) out = withCareerData(out, d, today: today);
      } on Object catch (e) {
        out = out.copyWith(problems: [...out.problems, '${k.name}: ${feedProblem(e)}']);
      }
    }
    return out;
  }

  /// [i] with the AI's parts asked again (or for the first time).
  Future<RoleInsight> addAi(RoleInsight i, CandidateProfile p, {void Function(String)? onProgress}) async {
    final a = advisor;
    if (a == null) return i;
    final base = withoutAi(i);
    final r = await a.roleInsight(p, role: i.role, known: knownForAi(base), onProgress: onProgress);
    return withAi(base, r.data, model: a.ai.model, today: today, web: r.sources);
  }

  /// The whole insight for [role]: shipped data, keyed sources, then the AI
  /// when [useAi] and there is one.
  Future<RoleInsight> build(
    String role,
    CandidateProfile p, {
    bool useAi = true,
    String? created,
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Reading the titles and skills for $role');
    var i = await offline(role, p, created: created);
    if (keyed.isNotEmpty) {
      onProgress?.call('Asking your career data sources');
      i = await addKeyed(i);
    }
    if (useAi && advisor != null) i = await addAi(i, p, onProgress: onProgress);
    return i;
  }
}

/// Saved insights on the book.
extension RoleInsightBook on CareerBook {
  /// The saved insights, newest first.
  Future<List<RoleInsight>> roleInsights() async => [
    for (final r
        in await (db.select(db.careerRoleInsights)
              ..where((r) => r.deleted.not())
              ..orderBy([(r) => OrderingTerm.desc(r.updated), (r) => OrderingTerm.asc(r.role)]))
            .get())
      RoleInsight.fromJson(decodeObject(r.content)),
  ];

  /// The saved insight for [role], or null.
  Future<RoleInsight?> roleInsight(String role) async {
    final r = await (db.select(
      db.careerRoleInsights,
    )..where((r) => r.id.equals(roleInsightId(role)) & r.deleted.not())).getSingleOrNull();
    return r == null ? null : RoleInsight.fromJson(decodeObject(r.content));
  }

  /// Saves [i] on every device, replacing the one for the same role.
  Future<void> saveRoleInsight(RoleInsight i) => save(
    db.careerRoleInsights,
    CareerRoleInsightsCompanion.insert(
      id: i.id,
      role: i.role,
      content: jsonEncode(i.toJson()),
      created: i.created,
      updated: i.updated,
      deleted: const Value(false),
    ),
    i.id,
  );

  /// Removes the insight [id] from every device.
  Future<void> removeRoleInsight(String id) => remove(db.careerRoleInsights, id);
}
