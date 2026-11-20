/// Panel scoring and the debrief (interview plan I3).
///
/// A [RoleProfile] holds the criteria a panel agrees before it meets anyone:
/// essential and desirable, read from the advert and person specification
/// (by the user's AI, or typed in) and always editable. The criteria become
/// the round's questions and probes.
///
/// After the round each answer is scored against those criteria only, on
/// the scale of the chosen [Framework]. Panels can only score what was
/// said, so every score the AI gives must quote the line of the transcript
/// it rests on; [verifyScores] drops any score whose quote is not in the
/// transcript, and a criterion with no evidence stays at the scale's "not
/// observed" level, never guessed. Without an AI the [Debrief] still shows
/// coverage, from the element matcher of interview_plan.dart.
///
/// The frameworks describe how panels commonly score, from public sources
/// (see each [ScoringScale.source]); employers differ, and the anchor text
/// is written for practice, not copied from any employer's pack.
library;

import 'companion.dart' show StoryDraft, competencyNames;
import 'insights.dart';
import 'interview_plan.dart';
import 'json.dart';
import 'schema.dart';

// ---- criteria and role profiles ----

/// What kind of thing a criterion asks for; it decides the question's shape.
enum CriterionKind {
  experience('Experience'),
  skill('Skill'),
  knowledge('Knowledge'),
  value('Value'),
  behaviour('Behaviour'),
  qualification('Qualification');

  const CriterionKind(this.label);
  final String label;

  static CriterionKind byName(String n) => values.where((k) => k.name == n).firstOrNull ?? experience;
}

/// How a criterion is assessed, as person specifications commonly tag it.
const assessByLabels = {'A': 'Application', 'I': 'Interview', 'T': 'Test', 'P': 'Presentation'};

/// One criterion the panel agreed before the interview.
class Criterion {
  const Criterion({
    required this.id,
    required this.text,
    this.essential = true,
    this.kind = CriterionKind.experience,
    this.assessBy = const [],
    this.question = '',
  });

  final String id;

  /// The criterion in the person specification's own words.
  final String text;
  final bool essential;
  final CriterionKind kind;

  /// Codes from [assessByLabels]; empty when the advert does not say.
  final List<String> assessBy;

  /// A question that tests it, when one was suggested or written; empty
  /// means the template wording is used.
  final String question;

  /// Assessed at interview (or not stated, so it may be).
  bool get atInterview => assessBy.isEmpty || assessBy.contains('I') || assessBy.contains('P');

  /// Assessed only by a test: the spoken round does not ask about it.
  bool get testOnly => assessBy.isNotEmpty && assessBy.every((a) => a == 'T');

  Criterion copyWith({
    String? text,
    bool? essential,
    CriterionKind? kind,
    List<String>? assessBy,
    String? question,
  }) => Criterion(
    id: id,
    text: text ?? this.text,
    essential: essential ?? this.essential,
    kind: kind ?? this.kind,
    assessBy: assessBy ?? this.assessBy,
    question: question ?? this.question,
  );

  Json toJson() => {
    'id': id,
    'text': text,
    'essential': essential,
    'kind': kind.name,
    'assessBy': assessBy,
    'question': question,
  };

  factory Criterion.fromJson(Json j) => Criterion(
    id: str(j['id']),
    text: str(j['text']),
    essential: j['essential'] != false,
    kind: CriterionKind.byName(str(j['kind'])),
    assessBy: [
      for (final a in strs(j['assessBy']))
        if (assessByLabels.containsKey(a.toUpperCase())) a.toUpperCase(),
    ],
    question: str(j['question']),
  );
}

/// A role to practise for: its criteria and the framework its panel uses.
class RoleProfile {
  const RoleProfile({
    required this.id,
    required this.title,
    this.employer = '',
    this.frameworkId = 'private',
    this.criteria = const [],
    this.jobId,
    this.source = 'manual',
  });

  final String id;
  final String title;
  final String employer;

  /// A [frameworks] id.
  final String frameworkId;
  final List<Criterion> criteria;

  /// The saved job it came from, if any.
  final String? jobId;

  /// ai (read from the advert, then checked by the user) | manual
  final String source;

  Framework get framework => Framework.of(frameworkId);

  List<Criterion> get essentials => [
    for (final c in criteria)
      if (c.essential) c,
  ];

  Criterion? criterion(String id) => criteria.where((c) => c.id == id).firstOrNull;

  RoleProfile copyWith({String? title, String? employer, String? frameworkId, List<Criterion>? criteria}) =>
      RoleProfile(
        id: id,
        title: title ?? this.title,
        employer: employer ?? this.employer,
        frameworkId: frameworkId ?? this.frameworkId,
        criteria: criteria ?? this.criteria,
        jobId: jobId,
        source: source,
      );

  /// The next free criterion id.
  String nextId() {
    var n = criteria.length + 1;
    final used = {for (final c in criteria) c.id};
    while (used.contains('c$n')) {
      n++;
    }
    return 'c$n';
  }
}

/// The AI's reading of an advert and person specification.
final criteriaSchema = object({
  'title': string('The job title, as the advert gives it'),
  'employer': string('The employer, or "" when not named'),
  'framework': oneOf([
    'nhs_values',
    'hsc_ni',
    'civil_service',
    'hse_ie',
    'private',
  ], 'The scoring framework this kind of employer most likely uses'),
  'criteria': array(
    object({
      'text': string('The criterion in the advert\'s own words, short'),
      'essential': boolean('True for essential, false for desirable'),
      'kind': oneOf([for (final k in CriterionKind.values) k.name]),
      'assessBy': array(oneOf(assessByLabels.keys.toList()), description: 'How it is assessed, when stated'),
      'question': string('One interview question that tests it, open and neutral'),
    }),
  ),
});

/// Reads the AI's criteria: blank and repeated criteria are dropped, unknown
/// kinds read as experience, ids are given in order (c1, c2, …). Nothing
/// the reply lacks is invented.
List<Criterion> parseCriteria(Json data) {
  final seen = <String>{};
  final out = <Criterion>[];
  for (final j in objs(data['criteria'])) {
    final text = str(j['text']).replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) continue;
    final key = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (key.isEmpty || !seen.add(key)) continue;
    out.add(
      Criterion.fromJson({
        ...j,
        'id': 'c${out.length + 1}',
        'text': text.length > 240 ? '${text.substring(0, 239)}…' : text,
      }),
    );
  }
  return out;
}

/// The framework the AI suggested, or [fallback] when it named none we know.
String suggestedFramework(Json data, {String fallback = 'private'}) {
  final id = str(data['framework']);
  return frameworks.any((f) => f.id == id) ? id : fallback;
}

// ---- frameworks, scales and anchors ----

/// One level of a scale, with the anchor text a panel reads against.
class ScaleLevel {
  const ScaleLevel(this.code, this.label, this.anchor);

  /// As written on a score sheet: "N/O", "0", "4".
  final String code;
  final String label;
  final String anchor;
}

/// A rating scale as panels commonly use it.
class ScoringScale {
  const ScoringScale({
    required this.id,
    required this.name,
    required this.levels,
    required this.thinFrom,
    required this.evidencedFrom,
    required this.source,
    this.passRule = '',
  });

  final String id;
  final String name;

  /// Lowest first. The first level is "no evidence".
  final List<ScaleLevel> levels;

  /// Rank (index into [levels]) from which a criterion counts as touched
  /// on but thin, and from which it counts as evidenced.
  final int thinFrom, evidencedFrom;

  /// Where the scale was seen (public sources only).
  final String source;

  /// The bar panels commonly apply, in plain words.
  final String passRule;

  ScaleLevel get noEvidence => levels.first;

  List<String> get codes => [for (final l in levels) l.code];

  /// The level for [code] as the AI or a person wrote it ("n/o", "Level 3",
  /// " 4 "), or null when it is not on this scale.
  ScaleLevel? level(String code) {
    final c = code.trim().toUpperCase().replaceFirst(RegExp(r'^LEVEL\s*'), '').replaceAll(' ', '');
    final norm = c == 'NO' || c == 'N.O.' || c == 'NOTOBSERVED' ? 'N/O' : c;
    return levels.where((l) => l.code.toUpperCase() == norm).firstOrNull;
  }

  int rank(ScaleLevel l) => levels.indexOf(l);

  Coverage coverageOf(ScaleLevel? l) {
    if (l == null) return Coverage.missing;
    final r = rank(l);
    return r >= evidencedFrom
        ? Coverage.evidenced
        : r >= thinFrom
        ? Coverage.thin
        : Coverage.missing;
  }
}

/// Shown with every scale: these describe common practice, not any one
/// employer's rules.
const scaleCaveat = 'How panels commonly score. Employers differ: check your invitation or pack.';

const _notObserved = ScaleLevel(
  'N/O',
  'Not observed',
  'Not heard, or only mentioned in passing: a claim such as "I am a good communicator" with nothing behind it.',
);

/// N/O, then 1 to 4 per question or value.
const nhsScale = ScoringScale(
  id: 'nhs_no_1to4',
  name: 'N/O, then 1 to 4',
  levels: [
    _notObserved,
    ScaleLevel(
      '1',
      'Limited',
      'A few relevant points, but no real example, or no sign of how it was put into practice.',
    ),
    ScaleLevel(
      '2',
      'Good',
      'A relevant example that says what you did and how, ideally with a sign that it worked.',
    ),
    ScaleLevel(
      '3',
      'Very good',
      'Most of what the panel listens for, with breadth and depth: they are left in no doubt.',
    ),
    ScaleLevel(
      '4',
      'Outstanding',
      'Everything they listen for, at a high level throughout, with depth, range and some sophistication.',
    ),
  ],
  thinFrom: 1,
  evidencedFrom: 2,
  source:
      'A published NHS board interview pack (2025) scores each question N/O, then 1 to 4. Trusts differ: '
      'another trust\'s guide scores 0 to 3 against key elements agreed before the interview.',
);

/// 0 to 3 against the key elements agreed for each question.
const keyElementScale = ScoringScale(
  id: 'key_elements_0to3',
  name: '0 to 3 against agreed key elements',
  levels: [
    ScaleLevel('0', 'No evidence', 'No example, or nothing that touches the criterion.'),
    ScaleLevel('1', 'Limited', 'A few relevant points, with little detail of what you did.'),
    ScaleLevel('2', 'Good', 'A clear, detailed example that covers several of the agreed key elements.'),
    ScaleLevel('3', 'Strong', 'A confident example that covers three or more of the agreed key elements.'),
  ],
  thinFrom: 1,
  evidencedFrom: 2,
  source:
      'A published NHS trust interview guide (2023) scores 0 to 3 against at least three key elements per '
      'question. Bands and pass marks vary by employer.',
);

/// Civil Service Success Profiles: behaviours, experience and technical
/// skills on 1 to 7.
const civilServiceScale = ScoringScale(
  id: 'cs_1to7',
  name: '1 to 7 per behaviour',
  levels: [
    ScaleLevel('1', 'Not demonstrated', 'No evidence of the behaviour was heard.'),
    ScaleLevel('2', 'Minimal', 'Very little positive evidence, and what there is raises concerns.'),
    ScaleLevel('3', 'Moderate', 'Some positive evidence, but gaps or concerns remain.'),
    ScaleLevel(
      '4',
      'Acceptable',
      'Enough positive evidence, and nothing negative that would worry the panel.',
    ),
    ScaleLevel('5', 'Good', 'Good positive evidence, with clear examples at the level of the grade.'),
    ScaleLevel('6', 'Strong', 'Strong evidence across the behaviour, in places beyond what the grade needs.'),
    ScaleLevel('7', 'Outstanding', 'Exceptional evidence throughout, well beyond the grade.'),
  ],
  thinFrom: 1,
  evidencedFrom: 3,
  passRule:
      'Departments commonly look for 4 or more on every behaviour; some accept one 3 if the rest are high.',
  source:
      'UK Civil Service Success Profiles guidance (gov.uk) and a department\'s published assessment page: '
      'behaviours, experience and technical skills are scored 1 to 7.',
);

/// A four-point competency rubric.
const rubricScale = ScoringScale(
  id: 'rubric_1to4',
  name: '1 to 4 per competency',
  levels: [
    ScaleLevel('1', 'Not shown', 'No example, or an example that does not touch the competency.'),
    ScaleLevel('2', 'Partly', 'Some relevant points, but thin on what you did or how it ended.'),
    ScaleLevel('3', 'Solid', 'A clear example of what you did and what came of it.'),
    ScaleLevel(
      '4',
      'Strong',
      'A clear, measured result, your own judgement explained, and what you learned.',
    ),
  ],
  thinFrom: 1,
  evidencedFrom: 2,
  source:
      'Structured-interview guides (for example Google re:Work) recommend a rubric for every competency. '
      'Points and labels vary by employer.',
);

/// A scoring framework: its scale, what it scores, and example dimensions
/// to add as criteria.
class Framework {
  const Framework({
    required this.id,
    required this.name,
    required this.about,
    required this.scale,
    required this.dimension,
    required this.examples,
    this.examplesNote = '',
  });

  final String id;
  final String name;
  final String about;
  final ScoringScale scale;

  /// What one scored thing is called: value, behaviour, competency.
  final String dimension;

  /// Generic dimensions to start from; the employer's own list wins.
  final List<String> examples;
  final String examplesNote;

  /// [dimension] in the plural.
  String get dimensions =>
      dimension.endsWith('y') ? '${dimension.substring(0, dimension.length - 1)}ies' : '${dimension}s';

  /// The kind of criterion the examples become.
  CriterionKind get exampleKind => dimension == 'value' ? CriterionKind.value : CriterionKind.behaviour;

  static Framework of(String id) => frameworks.where((f) => f.id == id).firstOrNull ?? frameworks.last;
}

const frameworks = [
  Framework(
    id: 'nhs_values',
    name: 'NHS values',
    about: 'Values and competency questions, each scored N/O, then 1 to 4.',
    scale: nhsScale,
    dimension: 'value',
    examples: ['Working together', 'Respect and dignity', 'Compassion', 'Improving quality'],
    examplesNote: 'Examples only: every trust or board has its own values. Use the wording in its pack.',
  ),
  Framework(
    id: 'hsc_ni',
    name: 'NI HSC values-based',
    about:
        'Health and Social Care in Northern Ireland: values and essential criteria scored on evidence. Failing to '
        'show an essential area means a candidate cannot be appointed.',
    scale: keyElementScale,
    dimension: 'value',
    examples: ['Working together', 'Excellence', 'Openness and honesty', 'Compassion'],
    examplesNote: 'Examples only: use the values in the trust\'s own pack.',
  ),
  Framework(
    id: 'civil_service',
    name: 'Civil Service Success Profiles',
    about: 'Behaviour questions scored 1 to 7; quick strengths questions are scored apart and not rehearsed.',
    scale: civilServiceScale,
    dimension: 'behaviour',
    examples: [
      'Seeing the big picture',
      'Changing and improving',
      'Making effective decisions',
      'Leadership',
      'Communicating and influencing',
      'Working together',
      'Developing self and others',
      'Managing a quality service',
      'Delivering at pace',
    ],
    examplesNote: 'The advert names the behaviours for the post, usually no more than four. Add only those.',
  ),
  Framework(
    id: 'hse_ie',
    name: 'HSE Ireland competencies',
    about:
        'The job specification lists the competencies, each with "Demonstrates" indicators; each board '
        'member scores each one on interview evidence.',
    scale: keyElementScale,
    dimension: 'competency',
    examples: [
      'Professional knowledge and experience',
      'Planning and managing resources',
      'Working with and through others',
      'Communication and interpersonal skills',
      'Problem solving and decision making',
      'Commitment to a quality service',
    ],
    examplesNote: 'Headings differ by grade: use the ones in the job specification. Marks vary by campaign.',
  ),
  Framework(
    id: 'private',
    name: 'Private-sector competencies',
    about: 'Behavioural and situational questions scored against a rubric for each competency.',
    scale: rubricScale,
    dimension: 'competency',
    examples: [
      'Ownership',
      'Solving problems',
      'Communication',
      'Working with others',
      'Delivering results',
      'Customer focus',
    ],
  ),
];

// ---- from criteria to questions and probes ----

String _lowerFirst(String s) =>
    s.length > 1 && s[1] == s[1].toLowerCase() ? s[0].toLowerCase() + s.substring(1) : s;

String _category(CriterionKind k) => switch (k) {
  CriterionKind.value => 'Values',
  CriterionKind.knowledge || CriterionKind.qualification => 'Technical',
  _ => 'Behavioural',
};

/// The template question for [c] when it has none of its own.
String templateQuestion(Criterion c) {
  final t = c.text.replaceAll(RegExp(r'[.;:]+$'), '');
  return switch (c.kind) {
    CriterionKind.value =>
      'One of our values is ${_lowerFirst(t)}. What does it mean to you, and when have you shown '
          'it at work?',
    CriterionKind.knowledge || CriterionKind.qualification =>
      'This role needs ${_lowerFirst(t)}. Talk us through how you have used it in your work.',
    _ =>
      'This role needs ${_lowerFirst(t)}. Tell us about a time you showed this. What did you do, and what was '
          'the outcome?',
  };
}

/// The settler the profile's round opens with: not scored.
const profileSettler = PracticeQuestion({
  'question': 'Could you start by telling us a little about your current role?',
  'category': 'Settler',
  'why': 'Nothing is scored here: it is to help you settle in.',
});

/// The criteria a round of at most [max] questions asks about: those
/// assessed at interview (or not said), essentials first. Criteria assessed
/// only by the application or a test are left to those.
List<Criterion> askedCriteria(RoleProfile p, {int max = 8}) => [
  for (final c in p.criteria)
    if (c.atInterview && c.essential) c,
  for (final c in p.criteria)
    if (c.atInterview && !c.essential) c,
].take(max).toList();

/// The round's questions for [p]: the settler, then one question per asked
/// criterion, each tagged with its criterion id and showing what it tests
/// (plan rule 2).
List<PracticeQuestion> questionsFromProfile(RoleProfile p, {int max = 8}) => [
  profileSettler,
  for (final c in askedCriteria(p, max: max))
    PracticeQuestion({
      'question': c.question.isNotEmpty ? c.question : templateQuestion(c),
      'category': _category(c.kind),
      'why': '${c.text} (${c.essential ? 'essential' : 'desirable'})',
      'lookFor': const ['One specific example', 'What you yourself did', 'What came of it'],
      'criteria': [c.id],
    }),
];

/// The criterion ids a question tests.
List<String> criteriaOf(PracticeQuestion q) => strs(q.j['criteria']);

/// The plan for a question that tests [c]: its kind's elements, and a
/// probe for the example worded for the criterion.
QuestionPlan criterionPlan(PracticeQuestion q, Criterion c, {QuestionPlan? base}) {
  final b = base ?? templatePlan(q);
  final t = c.text.replaceAll(RegExp(r'[.;:]+$'), '');
  return QuestionPlan(
    criterion: c.text,
    expected: b.expected.isNotEmpty ? b.expected : expectedFor(q.category, q.question),
    probes: [
      ...b.probes,
      Probe(AnswerElement.situation, 'Can you give us one specific example that shows ${_lowerFirst(t)}?'),
    ],
  );
}

/// The round's plans with the profile's criteria written in: a question
/// tied to a criterion tests that criterion, whatever the AI called it.
List<QuestionPlan> withCriteria(List<PracticeQuestion> questions, List<QuestionPlan> plans, RoleProfile? p) =>
    [for (final (i, q) in questions.indexed) _planWith(q, i < plans.length ? plans[i] : null, p)];

QuestionPlan _planWith(PracticeQuestion q, QuestionPlan? plan, RoleProfile? p) {
  final c = p == null ? null : criteriaOf(q).map(p.criterion).nonNulls.firstOrNull;
  return c != null ? criterionPlan(q, c, base: plan) : plan ?? templatePlan(q);
}

// ---- the transcript ----

/// The candidate's own words from a saved answer: the follow-up and wrap-up
/// labels (which hold the interviewer's question) are taken out.
String candidateWords(String saved) =>
    saved.split('\n').where((l) => !RegExp(r'^(Follow-up|Wrap-up): "').hasMatch(l.trim())).join('\n').trim();

String _plain(String text) {
  var t = text.toLowerCase().replaceAll(RegExp('[’‘`]'), "'").replaceAll(RegExp('[“”]'), '"');
  t = t.replaceAll(RegExp(r"[^a-z0-9%£$€'\s]"), ' ').replaceAll(RegExp(r"(^|\s)'|'(\s|$)"), ' ');
  t = t.replaceAll(RegExp(r'\b(u+m+|u+h+|uhm+|e+r+m+|e+r+|a+h+|h+m+)\b'), ' ');
  return ' ${t.replaceAll(RegExp(r'\s+'), ' ').trim()} ';
}

/// True when [quote] is in [transcript]: the same words in the same order,
/// ignoring case, punctuation and fillers. A quote may skip words with an
/// ellipsis; each part must then appear, in order. A quote needs three or
/// more words, so "I" or "yes" cannot pass as evidence.
bool quoteInTranscript(String quote, String transcript) {
  final parts = [for (final p in quote.split(RegExp(r'\.\.\.|…'))) ?_plain(p).trim().nullIfEmpty];
  if (parts.isEmpty || parts.fold(0, (n, p) => n + p.split(' ').length) < 3) return false;
  final t = _plain(transcript);
  var from = 0;
  for (final p in parts) {
    final at = t.indexOf(' $p ', from);
    if (at < 0) return false;
    from = at + p.length + 1;
  }
  return true;
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

// ---- scores ----

/// One criterion scored on one answer.
class CriterionScore {
  const CriterionScore({required this.criterionId, required this.code, this.quote = ''});
  final String criterionId;

  /// The scale code ("N/O", "3").
  final String code;

  /// The transcript line it rests on; empty for "no evidence".
  final String quote;

  Json toJson() => {'criterion': criterionId, 'level': code, 'quote': quote};

  factory CriterionScore.fromJson(Json j) =>
      CriterionScore(criterionId: str(j['criterion']), code: str(j['level']), quote: str(j['quote']));
}

/// What the scorer said about one answer.
class AnswerScore {
  const AnswerScore({required this.question, this.scores = const [], this.strength = '', this.fix = ''});

  /// Index into the round's questions.
  final int question;
  final List<CriterionScore> scores;
  final String strength, fix;

  Json toJson() => {
    'question': question,
    'scores': [for (final s in scores) s.toJson()],
    'strength': strength,
    'fix': fix,
  };

  factory AnswerScore.fromJson(Json j) => AnswerScore(
    question: intOf(j['question']) ?? -1,
    scores: [for (final s in objs(j['scores'])) CriterionScore.fromJson(s)],
    strength: str(j['strength']),
    fix: str(j['fix']),
  );
}

/// The AI's scoring reply, for [scale] and the criteria with [criterionIds].
Json scoringSchema(ScoringScale scale, List<String> criterionIds) => object({
  'answers': array(
    object({
      'question': integer('The question number as given'),
      'scores': array(
        object({
          'criterion': oneOf(criterionIds),
          'level': oneOf(scale.codes),
          'quote': string('The candidate\'s exact words this rests on; "" for no evidence'),
        }),
      ),
      'strength': string('One specific strength of this answer, about the task, not the person; no scores'),
      'fix': string(
        'One concrete thing to do in the answer next time, about the task; never a score, level or the scale',
      ),
    }),
  ),
});

// ---- feedback wording (plan rule 6) ----

/// Talk about the scale instead of the task: "move toward a 3", "a score
/// of 2", "level 4", "3/4", "N/O", "the top band". A fix is an action in
/// the answer; the panel's numbers belong on the scores card only.
/// A number followed by one of these is a count, not a score.
const _countUnits =
    r'(?![\s-]*(min|mins|minutes?|sec|secs|seconds?|sentences?|examples?|stories|people|staff|weeks?|days?|'
    r'months?|years?|steps?|points? (each|with)|%|percent|words?|questions?))';

final _scaleTalk = [
  RegExp(r'\b(scores?|scored|scoring|ratings?|rated|grades?|graded|bands?|marks)\b', caseSensitive: false),
  RegExp(r'\b(level|mark|point)s?\s+(of\s+)?(an?\s+)?(\d|N/?O\b)', caseSensitive: false),
  RegExp(
    r'\b(to|towards?|into|up to|reach|reaching|get|getting|achieve|earn|hit|for|worth)\s+(an?\s+)?(\d+|N/?O)\b'
    '$_countUnits',
    caseSensitive: false,
  ),
  // "a 3", "an 4": a bare number with an article is a scale point.
  RegExp(
    r'\b(a|an)\s+\d+\b'
    '$_countUnits',
    caseSensitive: false,
  ),
  RegExp(r'\b\d+\s*(/\s*\d+|out of \d+)', caseSensitive: false),
  RegExp(r'\bN/O\b'),
  RegExp(r'\b(anchors?|the scale|on the scale)\b', caseSensitive: false),
];

/// Whether [text] talks about scores or the scale rather than the task.
bool mentionsScale(String text) => _scaleTalk.any((r) => r.hasMatch(text));

/// [text] (a strength or a fix) with any talk of the scale taken out: a
/// sentence that has it is cut back to the part before it when that part
/// still reads as an action ("Add how you measured it, to move toward a 3"
/// becomes "Add how you measured it."), and dropped otherwise. Returns ''
/// when nothing task-level is left, so the caller uses its own wording.
String taskLevelText(String text) {
  final kept = <String>[];
  for (final raw in text.trim().split(RegExp(r'(?<=[.!?])\s+'))) {
    final s = raw.trim();
    if (s.isEmpty) continue;
    if (!mentionsScale(s)) {
      kept.add(s);
      continue;
    }
    final at = _scaleTalk.map((r) => r.firstMatch(s)?.start).whereType<int>().reduce((a, b) => a < b ? a : b);
    final head = s.substring(0, at);
    final cut = RegExp(r'(,|;|:|—| - |\bso that\b|\bso\b|\bin order to\b|\bto\b|\band\b|\bwhich\b)\s*')
        .allMatches(head)
        .map((m) => m.start)
        .fold<int?>(null, (a, b) => b);
    if (cut == null) continue;
    final prefix = head.substring(0, cut).trim().replaceFirst(RegExp(r'[\s,;:—-]+$'), '');
    if (prefix.split(RegExp(r'\s+')).length < 3 || mentionsScale(prefix)) continue;
    kept.add('$prefix.');
  }
  return kept.join(' ');
}

/// Reads the scoring reply. Question numbers are 1-based in the request.
List<AnswerScore> parseScoring(Json data) => [
  for (final a in objs(data['answers']))
    AnswerScore.fromJson({...a, 'question': (intOf(a['question']) ?? 0) - 1}),
];

/// A score that passed the checks.
class VerifiedScore {
  const VerifiedScore({
    required this.question,
    required this.criterionId,
    required this.level,
    this.quote = '',
    this.reason = '',
  });
  final int question;
  final String criterionId;
  final ScaleLevel level;
  final String quote;

  /// Why a score the AI gave was turned into "no evidence" ([claimReason]),
  /// or ''.
  final String reason;

  bool get claimOnly => reason == claimReason;
}

/// The reason a score with a real quote still reads as "no evidence": the
/// quote describes the candidate, or what they would do, with no instance
/// behind it (plan rule 1).
const claimReason = 'claim without an example';

/// What the debrief says for a criterion whose only evidence was a claim.
const claimNote = 'Claim without an example — add one real instance.';

// A quote that describes the speaker rather than something they did: "I am
// a good team player", "I'm passionate about", "I always", "I value",
// "people say I". Read on [_plain] text.
final _selfDescription = RegExp(
  r"\bi('m| am)\b|\bi (always|really|truly|genuinely)\b|"
  r"\bi (value|believe|love|enjoy|care about|like to think|pride myself|consider myself|see myself|thrive)\b|"
  r"\bi( have| have got|'ve got) (a )?(very |really )?(good|great|strong|excellent)\b|"
  r"\b(people|colleagues|others|my manager) (say|said|describe|would say|would describe)\b|"
  r"\bi would describe myself\b",
);

// A plan rather than an instance: "I would ring", "I'd check", "I will".
final _hypothetical = RegExp(r"\bi (would|will|could|might)\b|\bi'(d|ll)\b");

// Specifics: a number, a day or month, a count in words.
final _specific = RegExp(
  r'\d|\b(two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|twenty|thirty|fifty|hundred|dozen|'
  r'twice|monday|tuesday|wednesday|thursday|friday|saturday|sunday|january|february|march|april|june|july|'
  r'august|september|october|november|december)\b',
);

/// True when [quote] is only a claim: it describes the speaker ("I am a
/// good team player") or what they would do ("I would ring the patient"),
/// and the answer it comes from ([transcript]) holds nothing concrete: no
/// past action of the speaker's, no example, number, time, named thing or
/// result. Kept conservative: when in doubt it is not a claim, and the
/// score stands, so a claim followed by a real instance keeps its score
/// even when the quote is the claim.
bool claimWithoutExample(String quote, String transcript) {
  final q = _plain(quote);
  if (!_selfDescription.hasMatch(q) && !_hypothetical.hasMatch(q)) return false;
  final context = '$quote\n$transcript';
  if (hasOwnPastAction(context)) return false;
  if (_specific.hasMatch(_plain(context))) return false;
  final els = detectElements(context);
  if (els.contains(AnswerElement.situation) ||
      els.contains(AnswerElement.measure) ||
      els.contains(AnswerElement.result)) {
    return false;
  }
  // A name mid-sentence ("the Lorenzo system", "Ward 4") is a specific.
  for (final s in context.split(RegExp(r'(?<=[.!?])\s+|\n+'))) {
    final words = s.trim().split(RegExp(r'\s+'));
    for (final w in words.skip(1)) {
      final bare = w.replaceAll(RegExp(r'^[^A-Za-z]+|[^A-Za-z]+$'), '');
      if (RegExp(r'^[A-Z][a-z]').hasMatch(bare)) return false;
    }
  }
  return true;
}

/// The checked scores and what was dropped.
class Verified {
  const Verified({this.scores = const [], this.dropped = 0, this.answers = const {}});

  /// Every kept score, "no evidence" ones included.
  final List<VerifiedScore> scores;

  /// Scores thrown out: the quote was not in the transcript, the level was
  /// not on the scale, or the criterion was not the question's.
  final int dropped;

  /// The strength and fix per question.
  final Map<int, ({String strength, String fix})> answers;
}

/// Checks the AI's scores against what was said. A score stands only when
/// its level is on [scale], its criterion is one the question tests (from
/// [asked]: question index to criterion ids) and its quote is in that
/// question's transcript ([heard]). Anything else is dropped and the
/// criterion reads as no evidence for that answer: never guessed. A real
/// quote that is only a claim ([claimWithoutExample]) also reads as no
/// evidence, with [claimReason]; it is not counted as dropped.
Verified verifyScores(
  List<AnswerScore> raw,
  ScoringScale scale, {
  required Map<int, String> heard,
  required Map<int, List<String>> asked,
}) {
  final kept = <VerifiedScore>[];
  final answers = <int, ({String strength, String fix})>{};
  var dropped = 0;
  for (final a in raw) {
    final transcript = heard[a.question];
    if (transcript == null || transcript.trim().isEmpty) {
      dropped += a.scores.length;
      continue;
    }
    // No scale talk in the feedback: what is left of it, or the debrief's
    // own task-level wording when nothing is.
    answers[a.question] = (strength: taskLevelText(a.strength), fix: taskLevelText(a.fix));
    final allowed = asked[a.question] ?? const [];
    final done = <String>{};
    for (final s in a.scores) {
      final level = scale.level(s.code);
      if (level == null || !allowed.contains(s.criterionId) || !done.add(s.criterionId)) {
        dropped++;
        continue;
      }
      final none = level == scale.noEvidence;
      if (!none && !quoteInTranscript(s.quote, transcript)) {
        dropped++;
        kept.add(VerifiedScore(question: a.question, criterionId: s.criterionId, level: scale.noEvidence));
        continue;
      }
      if (!none && claimWithoutExample(s.quote, transcript)) {
        kept.add(
          VerifiedScore(
            question: a.question,
            criterionId: s.criterionId,
            level: scale.noEvidence,
            reason: claimReason,
          ),
        );
        continue;
      }
      kept.add(
        VerifiedScore(
          question: a.question,
          criterionId: s.criterionId,
          level: level,
          quote: none ? '' : s.quote,
        ),
      );
    }
  }
  return Verified(scores: kept, dropped: dropped, answers: answers);
}

// ---- the debrief ----

enum Coverage {
  evidenced('Evidenced'),
  thin('Thin'),
  missing('Missing');

  const Coverage(this.label);
  final String label;
}

/// Shown beside a missing essential criterion (plan rule 3).
const unappointableNote =
    'Would likely make you unappointable: a panel cannot appoint without evidence of every '
    'essential criterion.';

/// How one criterion fared across the round.
class CriterionCoverage {
  const CriterionCoverage({
    required this.criterion,
    required this.status,
    required this.note,
    this.asked = true,
    this.best,
  });
  final Criterion criterion;
  final Coverage status;
  final String note;

  /// False when no question in the round tested it.
  final bool asked;

  /// The best verified score, when the AI scored the round.
  final VerifiedScore? best;

  /// An essential criterion assessed at interview with no evidence: a panel
  /// could not appoint (plan rule 3).
  bool get unappointable => criterion.essential && criterion.atInterview && status == Coverage.missing;
}

/// One strength and one task-level fix for an answer (plan rule 6), and a
/// line to recover with when the answer was weak.
class AnswerNote {
  const AnswerNote({
    required this.question,
    required this.strength,
    required this.fix,
    this.recovery = '',
    this.good = false,
    this.evidenced = const [],
  });
  final int question;
  final String strength, fix;

  /// A line to say in the room after an answer like this, or ''.
  final String recovery;

  /// Good enough to keep in the story bank.
  final bool good;

  /// The criteria this answer evidenced.
  final List<String> evidenced;
}

/// Lines that recover a weak moment, by what went wrong. Panels allow it:
/// chairs pick up on missing points.
abstract final class Recovery {
  static const betterExample = 'Can I come back to that with a better example?';
  static const ownPart = 'To be clear about my own part in that: I…';
  static const outcome = 'Could I briefly add how that turned out?';
  static const sumUp = 'To sum up: the result was…, and next time I would…';
  static const honest = 'I have not done exactly that, but the closest I have come is…';

  static String addLater(String criterion) =>
      'Before we finish, could I briefly add an example of ${_lowerFirst(criterion)}?';
}

/// Plain words for each element when it was there.
const elementStrengths = {
  AnswerElement.ownAction: 'You said what you yourself did.',
  AnswerElement.situation: 'You gave one specific example.',
  AnswerElement.result: 'You said how it turned out.',
  AnswerElement.measure: 'You said how you knew it worked.',
  AnswerElement.learning: 'You said what you learned.',
  AnswerElement.others: 'You named who else was involved.',
};

/// What one question of the round brings to the debrief.
class DebriefQuestion {
  const DebriefQuestion({
    required this.index,
    required this.question,
    required this.plan,
    this.criteria = const [],
    this.heard = '',
    this.interrupted = false,
  });
  final int index;
  final PracticeQuestion question;
  final QuestionPlan plan;

  /// Criterion ids it tests.
  final List<String> criteria;

  /// The candidate's words for it (answer and follow-ups); '' if skipped.
  final String heard;
  final bool interrupted;

  bool get scored => plan.expected.isNotEmpty;
}

/// The whole-round debrief: coverage first, then the scores with their
/// anchors, then one strength and one fix per answer, and recovery lines.
class Debrief {
  const Debrief({
    required this.framework,
    required this.coverage,
    required this.notes,
    this.scores = const [],
    this.aiScored = false,
    this.dropped = 0,
    this.fromProfile = true,
  });

  final Framework framework;

  /// Essentials first.
  final List<CriterionCoverage> coverage;
  final List<AnswerNote> notes;
  final List<VerifiedScore> scores;

  /// False: coverage from the matcher on this device only.
  final bool aiScored;
  final int dropped;

  /// False when the criteria came from the questions, not a role profile
  /// (nothing is then marked essential).
  final bool fromProfile;

  List<CriterionCoverage> get missingEssentials => [
    for (final c in coverage)
      if (c.unappointable) c,
  ];

  /// Lines to practise for the weak moments, without repeats.
  List<String> get recoveryLines => {
    for (final n in notes)
      if (n.recovery.isNotEmpty) n.recovery,
    for (final c in missingEssentials.take(1)) Recovery.addLater(c.criterion.text),
  }.toList();

  /// Builds the debrief. [questions] are the round's; [verified] is the
  /// AI's checked scoring, or null for coverage from the matcher alone.
  /// With [wholeProfile] every criterion of [profile] is checked, asked or
  /// not; otherwise only those this round asked about.
  static Debrief build({
    required Framework framework,
    required DebriefRound round,
    Verified? verified,
    bool wholeProfile = true,
  }) {
    final crit = round.criteria;
    final tagged = round.questions;
    final fromProfile = round.fromProfile;
    final scale = framework.scale;
    final matcher = <int, Coverage>{
      for (final q in tagged)
        if (q.scored) q.index: _matcherCoverage(q),
    };
    final coverage = <CriterionCoverage>[];
    for (final c in crit) {
      final asking = [
        for (final q in tagged)
          if (q.criteria.contains(c.id)) q,
      ];
      if (asking.isEmpty) {
        if (!wholeProfile) continue;
        coverage.add(
          CriterionCoverage(
            criterion: c,
            status: Coverage.missing,
            asked: false,
            note: c.atInterview
                ? 'Not asked in this round, so no evidence yet. A panel will look for it: practise it.'
                : 'Assessed by the ${c.assessBy.map((a) => assessByLabels[a]!.toLowerCase()).join(' and ')}, '
                      'not at interview.',
          ),
        );
        continue;
      }
      final answered = asking.any((q) => q.heard.trim().isNotEmpty);
      if (verified != null) {
        final mine = [
          for (final s in verified.scores)
            if (s.criterionId == c.id) s,
        ]..sort((a, b) => scale.rank(b.level).compareTo(scale.rank(a.level)));
        final best = mine.firstOrNull;
        final status = scale.coverageOf(best?.level);
        coverage.add(
          CriterionCoverage(
            criterion: c,
            status: status,
            best: best != null && best.level != scale.noEvidence ? best : null,
            note: switch (status) {
              Coverage.evidenced => 'Scored ${best!.level.code} (${best.level.label}) on what you said.',
              Coverage.thin => 'Touched on, but thin: ${best!.level.label.toLowerCase()} evidence.',
              Coverage.missing =>
                !answered
                    ? 'Not answered.'
                    : mine.any((s) => s.claimOnly)
                    ? claimNote
                    : 'No evidence heard: ${scale.noEvidence.code}.',
            },
          ),
        );
        continue;
      }
      final statuses = [for (final q in asking) matcher[q.index] ?? Coverage.missing];
      final status = statuses.contains(Coverage.evidenced)
          ? Coverage.evidenced
          : statuses.contains(Coverage.thin)
          ? Coverage.thin
          : Coverage.missing;
      coverage.add(
        CriterionCoverage(
          criterion: c,
          status: status,
          note: switch (status) {
            Coverage.evidenced => 'An example with your own actions and how it turned out.',
            Coverage.thin => 'Some of it, but not yet a full example: see the fix below.',
            Coverage.missing =>
              answered ? 'No example heard: a claim with nothing behind it scores nothing.' : 'Not answered.',
          },
        ),
      );
    }
    // Essentials first, gaps first within them; criteria assessed away
    // from the interview last.
    int group(CriterionCoverage c) => !c.criterion.atInterview ? 2 : (c.criterion.essential ? 0 : 1);
    coverage.sort((a, b) {
      final g = group(a).compareTo(group(b));
      return g != 0 ? g : b.status.index.compareTo(a.status.index);
    });

    final notes = <AnswerNote>[];
    for (final q in tagged) {
      if (!q.scored || q.heard.trim().isEmpty) continue;
      final heardEls = detectElements(q.heard);
      final missing = [
        for (final e in probeOrder)
          if (q.plan.expected.contains(e) && !heardEls.contains(e)) e,
      ];
      final ai = verified?.answers[q.index];
      final evidenced = verified != null
          ? [
              for (final s in verified.scores)
                if (s.question == q.index && scale.coverageOf(s.level) == Coverage.evidenced) s.criterionId,
            ]
          : (matcher[q.index] == Coverage.evidenced ? q.criteria : const <String>[]);
      final weak = q.interrupted || missing.length >= 2 || (verified != null && evidenced.isEmpty);
      notes.add(
        AnswerNote(
          question: q.index,
          strength: ai != null && ai.strength.isNotEmpty ? ai.strength : _strength(heardEls, q.plan),
          fix: ai != null && ai.fix.isNotEmpty ? ai.fix : _fix(missing, q.interrupted),
          recovery: weak ? _recovery(heardEls, q) : '',
          good: evidenced.isNotEmpty,
          evidenced: evidenced,
        ),
      );
    }
    return Debrief(
      framework: framework,
      coverage: coverage,
      notes: notes,
      scores: verified?.scores ?? const [],
      aiScored: verified != null,
      dropped: verified?.dropped ?? 0,
      fromProfile: fromProfile,
    );
  }

  /// The best verified score for each scored criterion, with its anchor.
  List<({Criterion criterion, ScaleLevel level, String quote})> scoreLines() => [
    for (final c in coverage)
      if (c.asked && aiScored)
        (
          criterion: c.criterion,
          level: c.best?.level ?? framework.scale.noEvidence,
          quote: c.best?.quote ?? '',
        ),
  ];
}

/// A saved round made ready for scoring and the debrief: each question
/// with its plan, the criteria it tests and the candidate's words.
class DebriefRound {
  const DebriefRound({required this.questions, required this.criteria, required this.fromProfile});
  final List<DebriefQuestion> questions;

  /// The profile's criteria; without a profile, each scored question's
  /// "what it tests" stands in as a criterion and none is essential.
  final List<Criterion> criteria;
  final bool fromProfile;

  /// The candidate's words by question, for checking quotes.
  Map<int, String> get heard => {for (final q in questions) q.index: q.heard};

  /// The criterion ids each question tests.
  Map<int, List<String>> get asked => {for (final q in questions) q.index: q.criteria};

  /// The answered, scored questions, for the scorer.
  List<DebriefQuestion> get answered => [
    for (final q in questions)
      if (q.scored && q.criteria.isNotEmpty && q.heard.trim().isNotEmpty) q,
  ];

  /// From a saved round: its [questions] and the saved text of each answer
  /// ([answers], by question; follow-ups included and labelled).
  factory DebriefRound.of({
    required List<PracticeQuestion> questions,
    required Map<int, String> answers,
    RoleProfile? profile,
  }) {
    final plans = withCriteria(questions, const [], profile);
    final fromProfile = profile != null && profile.criteria.isNotEmpty;
    final qs = <DebriefQuestion>[];
    for (final (i, q) in questions.indexed) {
      final plan = plans[i];
      final saved = answers[i] ?? '';
      final ids = fromProfile
          ? [
              for (final id in criteriaOf(q))
                if (profile.criterion(id) != null) id,
            ]
          : (plan.expected.isNotEmpty ? ['q$i'] : const <String>[]);
      qs.add(
        DebriefQuestion(
          index: i,
          question: q,
          plan: plan,
          criteria: ids,
          heard: candidateWords(saved),
          interrupted: RegExp(r'(^|\n)Wrap-up: "').hasMatch(saved),
        ),
      );
    }
    return DebriefRound(
      questions: qs,
      fromProfile: fromProfile,
      criteria: fromProfile
          ? profile.criteria
          : [
              for (final q in qs)
                if (q.criteria.isNotEmpty)
                  Criterion(
                    id: q.criteria.first,
                    text: q.question.why.isNotEmpty ? q.question.why : q.question.question,
                    essential: false,
                  ),
            ],
    );
  }
}

/// Coverage from the words alone: an example with the speaker's own
/// actions and how it ended is evidence; some of the parts is thin;
/// nothing (or a bare claim) is missing.
Coverage _matcherCoverage(DebriefQuestion q) {
  if (q.heard.trim().isEmpty) return Coverage.missing;
  final heard = detectElements(q.heard);
  final expected = q.plan.expected.toSet();
  final got = heard.intersection(expected);
  if (got.isEmpty) return Coverage.missing;
  bool has(AnswerElement e) => !expected.contains(e) || heard.contains(e);
  final outcome = {
    AnswerElement.result,
    AnswerElement.measure,
    AnswerElement.learning,
  }.intersection(expected);
  final ended = outcome.isEmpty || outcome.any(heard.contains);
  return has(AnswerElement.ownAction) && has(AnswerElement.situation) && ended
      ? Coverage.evidenced
      : Coverage.thin;
}

String _strength(Set<AnswerElement> heard, QuestionPlan plan) {
  for (final e in probeOrder) {
    if (plan.expected.contains(e) && heard.contains(e)) return elementStrengths[e]!;
  }
  return 'You answered the question asked and kept going under the clock.';
}

const _linkFix = 'End with one sentence that links the example back to what the question tests.';

String _fix(List<AnswerElement> missing, bool interrupted) {
  if (interrupted) return 'Lead with the result, then the detail, so the answer fits the time.';
  return missing.isEmpty ? _linkFix : _fixes[missing.first]!;
}

const _fixes = {
  AnswerElement.ownAction: 'Say what you yourself did, with "I", before what the team did.',
  AnswerElement.situation: 'Open with one specific example: when, where and how big.',
  AnswerElement.result: 'End the example with what happened in the end.',
  AnswerElement.measure: 'Say how you knew it worked: a number, a check or feedback.',
  AnswerElement.learning: 'Close with what you learned or would do differently.',
  AnswerElement.others: 'Name who else was involved and how you brought them along.',
};

String _recovery(Set<AnswerElement> heard, DebriefQuestion q) {
  if (q.interrupted) return Recovery.sumUp;
  if (!heard.contains(AnswerElement.situation) && q.plan.expected.contains(AnswerElement.situation)) {
    return heard.isEmpty ? Recovery.honest : Recovery.betterExample;
  }
  if (!heard.contains(AnswerElement.ownAction) && q.plan.expected.contains(AnswerElement.ownAction)) {
    return Recovery.ownPart;
  }
  return Recovery.outcome;
}

// ---- saving to the story bank ----

/// A story drafted from a practice answer, with no AI: each sentence goes
/// to the part it reads as (the example, the result, or what was done).
/// The candidate checks it before it counts.
StoryDraft storyFromAnswer({
  required String title,
  required String answer,
  List<String> criteria = const [],
}) {
  final situation = <String>[], action = <String>[], result = <String>[];
  final sentences = [
    for (final s in candidateWords(answer).split(RegExp(r'(?<=[.!?])\s+|\n+')))
      if (s.trim().isNotEmpty) s.trim(),
  ];
  for (final (i, s) in sentences.indexed) {
    final e = detectElements(s);
    final mine = ownActions(s) > 0;
    if (!mine &&
        (e.contains(AnswerElement.result) ||
            e.contains(AnswerElement.measure) ||
            e.contains(AnswerElement.learning)) &&
        i > 0) {
      result.add(s);
    } else if (!mine && e.contains(AnswerElement.situation) && action.isEmpty) {
      situation.add(s);
    } else {
      action.add(s);
    }
  }
  return StoryDraft(
    title: title.length > 80 ? '${title.substring(0, 79)}…' : title,
    situation: situation.join(' '),
    action: action.join(' '),
    result: result.join(' '),
    competencies: competenciesFor(criteria),
  );
}

const _competencyWords = {
  'prioritising': r'priorit|workload|deadline|organis|organiz|plan',
  'accuracy': r'accura|detail|data quality|records?',
  'communication': r'communicat|explain|influenc|listen',
  'teamwork': r'team|together|collaborat|partner|others',
  'problem_solving': r'problem|decision|analys|judgement',
  'improvement': r'improv|chang|initiative|innovat',
  'service': r'patient|customer|service user|client|quality service',
  'confidentiality': r'confidential|policy|governance|safeguard',
  'systems': r'system|software|digital|technical|excel|spreadsheet',
  'supporting': r'train|develop|support|coach|mentor',
  'pressure': r'pressure|pace|busy|stress',
  'values': r'value|compassion|respect|dignity|honest|integrity',
};

/// The story-bank competencies criteria point to, by their words.
List<String> competenciesFor(List<String> criteria) {
  final text = criteria.join(' ').toLowerCase();
  return [
    for (final e in _competencyWords.entries)
      if (competencyNames.containsKey(e.key) && RegExp(e.value).hasMatch(text)) e.key,
  ].take(3).toList();
}
