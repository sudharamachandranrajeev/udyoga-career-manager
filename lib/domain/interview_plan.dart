/// Follow-up questions picked from what an answer is missing (interview plan
/// I2), the panel's manner and the difficulty ladder.
///
/// Every question in a round has a [QuestionPlan]: the criterion it tests,
/// the elements a full answer has ([AnswerElement]) and probes keyed to
/// those elements. The user's AI may write the plans at the start of the
/// round; without one, [templatePlan] builds them from the question's kind.
/// After each answer, [ProbePicker] checks the transcript on the device with
/// [detectElements] and picks the probe for the first element still
/// missing, never more than two per question and never the same twice.
/// Panels probe this way: one or two follow-ups chosen by the gap in the
/// answer, not at random.
library;

import 'dart:math' as math;

import 'insights.dart';
import 'json.dart';

/// The parts of a full answer that panels listen for.
enum AnswerElement {
  situation('Situation', 'one specific example: when, where and how big'),
  ownAction('Your own action', 'what you yourself did'),
  measure('Measure', 'how you measured it or knew it worked'),
  result('Result', 'what happened in the end'),
  learning('Learning', 'what you learned or would do differently'),
  others('Others involved', 'who else was involved and how you worked with them');

  const AnswerElement(this.label, this.meaning);
  final String label;

  /// Plain words for what the element is, e.g. "what you yourself did".
  final String meaning;

  static AnswerElement? byName(String name) => values.where((e) => e.name == name).firstOrNull;
}

/// The order missing elements are probed in when nothing else decides:
/// your own part first (the most common gap), then the example, the result,
/// how it was measured, the learning, and the people.
const probeOrder = [
  AnswerElement.ownAction,
  AnswerElement.situation,
  AnswerElement.result,
  AnswerElement.measure,
  AnswerElement.learning,
  AnswerElement.others,
];

/// A follow-up question aimed at one missing element.
class Probe {
  const Probe(this.element, this.text);
  final AnswerElement element;
  final String text;

  Json toJson() => {'element': element.name, 'text': text};

  static Probe? fromJson(Json j) {
    final e = AnswerElement.byName(str(j['element']));
    final t = str(j['text']).trim();
    return e == null || t.isEmpty ? null : Probe(e, t);
  }

  @override
  bool operator ==(Object other) => other is Probe && other.element == element && other.text == text;

  @override
  int get hashCode => Object.hash(element, text);

  @override
  String toString() => 'Probe(${element.name}, $text)';
}

/// Probes every round has, with no AI. Generic wording that real panels use.
const builtInProbes = {
  AnswerElement.ownAction: ['What did you yourself do?', 'What was your own part in that, step by step?'],
  AnswerElement.situation: ['Can you give us one specific example of when that happened?'],
  AnswerElement.result: ['What happened in the end?', 'What was the outcome?'],
  AnswerElement.measure: ['How did you measure this?', 'How did you know it had worked?'],
  AnswerElement.learning: ['What did you learn?', 'What would you do differently?'],
  AnswerElement.others: ['Who else was involved?', 'How did you bring the others along with you?'],
};

/// What one question tests, what a full answer has, and the probes for the
/// gaps.
class QuestionPlan {
  const QuestionPlan({required this.criterion, required this.expected, this.probes = const []});

  /// What the question tests, e.g. "Teamwork".
  final String criterion;

  /// The elements a full answer has. Empty for questions that are not
  /// probed (a settler, "any questions for us?", rapid strengths questions).
  final List<AnswerElement> expected;

  /// Wording for the probes, keyed by element; the built-in probes fill
  /// any gap.
  final List<Probe> probes;

  Json toJson() => {
    'criterion': criterion,
    'expected': [for (final e in expected) e.name],
    'probes': [for (final p in probes) p.toJson()],
  };

  factory QuestionPlan.fromJson(Json j) => QuestionPlan(
    criterion: str(j['criterion']),
    expected: {for (final n in strs(j['expected'])) ?AnswerElement.byName(n)}.toList(),
    probes: [for (final p in objs(j['probes'])) ?Probe.fromJson(p)],
  );
}

const _behavioural = [
  AnswerElement.situation,
  AnswerElement.ownAction,
  AnswerElement.result,
  AnswerElement.measure,
  AnswerElement.learning,
  AnswerElement.others,
];

final _askedForExample = RegExp(
  r'^(tell (us|me) about a time|describe a time|give (us |me )?an example|can you think of a time|when have you)',
);

/// The elements a question of [category] calls for, with no AI.
List<AnswerElement> expectedFor(String category, String question) {
  final c = category.toLowerCase();
  final q = question.toLowerCase().trim();
  if (c.contains('settler') ||
      c.contains('closing') ||
      c.contains('strength') ||
      c.contains('motivation') ||
      q.startsWith('do you have any questions')) {
    return const [];
  }
  if (c.contains('presentation')) return const [AnswerElement.measure, AnswerElement.others];
  if (c.contains('value')) {
    return const [AnswerElement.situation, AnswerElement.ownAction, AnswerElement.learning];
  }
  if (c.contains('situational') || c.contains('case')) {
    return const [AnswerElement.ownAction, AnswerElement.others, AnswerElement.result];
  }
  if (c.contains('technical') || c.contains('knowledge')) {
    return const [AnswerElement.ownAction, AnswerElement.measure];
  }
  if (c.contains('behaviour') || c.contains('competenc') || _askedForExample.hasMatch(q)) return _behavioural;
  return const [AnswerElement.ownAction, AnswerElement.result];
}

/// The plan for [q] with no AI: its kind decides the elements, and the
/// built-in probes are used.
QuestionPlan templatePlan(PracticeQuestion q) => QuestionPlan(
  criterion: q.why.isNotEmpty ? q.why : (q.category.isNotEmpty ? q.category : 'General'),
  expected: expectedFor(q.category, q.question),
);

/// Plans from the AI, checked against the round: a missing or empty one is
/// replaced by its template, so a short or broken reply still gives a
/// working round.
List<QuestionPlan> mergePlans(List<PracticeQuestion> questions, List<QuestionPlan> fromAi) => [
  for (final (i, q) in questions.indexed)
    if (i < fromAi.length && (fromAi[i].expected.isNotEmpty || expectedFor(q.category, q.question).isEmpty))
      fromAi[i]
    else
      templatePlan(q),
];

// ---- finding the elements in a transcript ----

/// Lower case, curly quotes made straight, fillers and punctuation gone
/// (but sentence ends kept as full stops, and with [commas] commas kept as
/// words of their own).
String _normalise(String text, {bool commas = false}) {
  var t = text.toLowerCase().replaceAll(RegExp('[’‘]'), "'");
  // "like" or "you know" set off by commas is a filler.
  t = t.replaceAll(RegExp(r',\s*(like|you know)\s*,'), ',');
  t = t.replaceAll(RegExp(r'[!?;]'), '.');
  if (commas) t = t.replaceAll(',', ' , ');
  t = t.replaceAll(RegExp(commas ? r"[^a-z0-9%'.,£$€\s]" : r"[^a-z0-9%'.£$€\s]"), ' ');
  // A full stop between digits is a decimal point, not a sentence end.
  t = t.replaceAllMapped(RegExp(r'(?<!\d)\.|\.(?!\d)'), (_) => ' . ');
  t = t.replaceAll(RegExp(r'\b(u+m+|u+h+|uhm+|e+r+m+|e+r+|a+h+|h+m+)\b'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

RegExp _words(List<String> phrases) => RegExp('\\b(${phrases.join('|')})\\b');

final _situation = _words([
  'at the time',
  'when i was',
  'while i was',
  "when i'd",
  r'in my (last|previous|current|first|old|second) (role|job|post|team|placement|position)',
  'in my role as',
  r'last (year|month|week|winter|summer|spring|autumn|christmas)',
  r'one (day|morning|afternoon|evening|night|shift|weekend|week|time)',
  'a time when',
  'there was a',
  'there were',
  r'we had (a|an|two|three|four|five|six|no)',
  'i was working',
  'i worked as',
  r'during (the|a|my|our)',
  r'in (19|20)\d\d',
  r'(years|months|weeks) ago',
  'recently',
  'for example',
  'for instance',
  'once ',
]);

final _measure = RegExp(
  r'\d|%|\b(per ?cent|measured|measure|tracked|monitored|audit|audited|survey|feedback|data showed|the data|'
  r'figures|kpis?|metrics?|scores?|baseline|compared|halved|doubled|tripled|fewer|by (half|a third|a quarter)|'
  r'went (down|up) from|dropped from|rose from|fell from|from (one|two|three|four|five|six|seven|eight|nine|ten) to|'
  r'within (a|one|two|three|four|five|six) (minutes?|hours?|days?|weeks?|months?))\b',
);

final _result = _words([
  'as a result',
  'the result',
  'in the end',
  'the outcome',
  'which meant',
  'this meant',
  'that meant',
  'so that',
  'led to',
  'ended up',
  'it worked',
  'worked well',
  r'(was|were|got) (covered|resolved|fixed|sorted|solved|done|completed|approved|delivered)',
  'resolved',
  'solved',
  'succeeded',
  'success',
  'reduced',
  'improved',
  'increased',
  'saved',
  'on time',
  'met the deadline',
  'we met',
  'delivered',
  'completed',
  'achieved',
  r'(was|were) (happy|pleased|satisfied)',
  'thanked',
  'since then',
  'afterwards',
  'by the end',
  'went live',
  'passed',
]);

final _learning = _words([
  r'i (learned|learnt|realised|realized)',
  'learned',
  'learnt',
  'lessons?',
  'taught me',
  'next time',
  'in future',
  'in the future',
  'in hindsight',
  'looking back',
  r"i(?: would|'d) now",
  r'now i (always|check|make|ask|plan|start)',
  r'i now',
  'differently',
  'on reflection',
  'reflect',
  'reflecting',
  r'(it|that|this) showed me',
  r'made me (realise|realize|see)',
  r"(i|i'd|i would) do .{0,20} differently",
  'what i would change',
  'since then i',
]);

final _others = _words([
  'manager',
  'managers',
  'team',
  'teams',
  'colleagues?',
  'staff',
  'stakeholders?',
  'patients?',
  'clients?',
  'customers?',
  'supervisor',
  'consultants?',
  'nurses?',
  'doctors?',
  'clinicians?',
  'director',
  'users?',
  'partners?',
  'suppliers?',
  'families',
  'family',
  'carers?',
  'the board',
  r'head of \w+',
  'hr',
  'together with',
  r'with (my|the|our|a) \w+',
  'everyone',
  'volunteers?',
  'students?',
  'residents?',
  'members?',
  'peers?',
  'contractors?',
  'engineers?',
  'developers?',
  'analysts?',
]);

/// Past-tense verbs that are actions (the irregular ones; regular "-ed"
/// forms are found by their ending).
final _irregularActions = _set('''
  rang ran made set spoke took wrote rewrote built led met sent put found gave told brought began
  chose drew got kept paid read sat sold taught went won broke caught did held sought stood shut split
  cut drove fed fought hid hit let lit overcame oversaw rebuilt redrew rethought sped understood
  undertook wound
''');

/// Base forms after "I would" or "I'll": a plan for a situational question
/// is still the candidate's own action.
final _baseActions = _set('''
  call ring phone speak ask check set make tell talk list agree escalate prioritise prioritize raise
  write plan review contact explain arrange organise organize meet look find put take send flag inform
  document follow start gather map break record report update test build draft email triage sort move
  book give bring lead run use compare work go get keep measure track note confirm reassure listen
  apologise offer support train teach show delegate split divide create design fix
''');

/// Present-tense verbs too vague to count as an action ("I work in a
/// team", "I go to the meeting").
const _vagueBase = {'work', 'go', 'get', 'keep', 'use', 'look', 'start'};

/// "-ed" words that are not actions (feelings and states).
final _notActions = _set('''
  needed wanted liked loved enjoyed worried tired involved based related interested supposed concerned
  surprised pleased excited stressed scared bored used hoped seemed tried expected assumed believed
  noticed felt struggled panicked hated preferred remembered wondered qualified worked 
  joined stayed lived 
''');

/// Words that can sit between "I" and the verb ("I then rang", "I quickly
/// moved").
final _between = _set('''
  then also personally myself first immediately quickly just finally eventually actually basically
  really straight away so and next carefully calmly ,
''');

Set<String> _set(String words) => words.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

bool _pastAction(String w) =>
    _irregularActions.contains(w) || (w.length > 4 && w.endsWith('ed') && !_notActions.contains(w));

/// How many actions the speaker owns: each "I" plus an action and the actions
/// joined to it in the same sentence ("I rang the bank staff, moved the
/// training day and told the manager" is three).
int ownActions(String transcript) => _ownActions(_normalise(transcript, commas: true));

int _ownActions(String t) {
  var count = 0;
  for (final sentence in t.split(' . ')) {
    final w = sentence.trim().split(' ');
    var owning = false;
    for (var i = 0; i < w.length; i++) {
      final word = w[i];
      if (word == 'i' || word == 'myself') {
        // "I would call", "I'll call": a planned action.
        var j = i + 1;
        while (j < w.length && _between.contains(w[j])) {
          j++;
        }
        if (j >= w.length) continue;
        final next = w[j];
        if (next == 'would' || next == 'will') {
          if (j + 1 < w.length && _baseActions.contains(w[j + 1])) {
            count++;
            owning = true;
          }
          continue;
        }
        // "I check the list each morning": an action told in the present.
        if (_pastAction(next) || (_baseActions.contains(next) && !_vagueBase.contains(next))) {
          count++;
          owning = true;
          i = j;
        }
        continue;
      }
      if (word == "i'd" || word == "i'll") {
        if (i + 1 < w.length && _baseActions.contains(w[i + 1])) {
          count++;
          owning = true;
        }
        continue;
      }
      // "we" ends the run of actions that belong to the speaker.
      if (word == 'we' || word == 'they' || word == 'he' || word == 'she') {
        owning = false;
        continue;
      }
      // "..., moved the day and told the manager": more of the same run.
      if (owning && (word == 'and' || word == 'then' || word == ',')) {
        var k = i + 1;
        while (k < w.length && (w[k] == ',' || w[k] == 'and' || w[k] == 'then')) {
          k++;
        }
        if (k < w.length && _pastAction(w[k])) {
          count++;
          i = k;
        }
      }
    }
  }
  return count;
}

/// The elements [transcript] covers. Panels can only score what was said,
/// so this reads the words alone, on the device.
Set<AnswerElement> detectElements(String transcript) {
  final t = _normalise(transcript);
  if (t.isEmpty) return const {};
  return {
    if (_situation.hasMatch(t)) AnswerElement.situation,
    if (ownActions(transcript) >= 2 ||
        RegExp(
          r"\b(my (own )?(role|part|job) was to|i (myself|personally) \w+|i took (the lead|charge|responsibility))\b",
        ).hasMatch(t))
      AnswerElement.ownAction,
    if (_measure.hasMatch(t)) AnswerElement.measure,
    if (_result.hasMatch(t)) AnswerElement.result,
    if (_learning.hasMatch(t)) AnswerElement.learning,
    if (_others.hasMatch(t)) AnswerElement.others,
  };
}

/// The elements [plan] expects that [transcript] lacks, in [probeOrder].
List<AnswerElement> missingElements(QuestionPlan plan, String transcript) {
  final heard = detectElements(transcript);
  return [
    for (final e in probeOrder)
      if (plan.expected.contains(e) && !heard.contains(e)) e,
  ];
}

/// Panels ask one or two follow-ups at most.
const maxProbesPerQuestion = 2;

abstract final class ProbePicker {
  /// The next probe for an answer that so far says [heard] (the answer and
  /// any follow-up answers), or null when nothing is missing, [asked]
  /// already holds [limit] probes (never more than two), or every missing
  /// element has been probed. Elements in [focus] (missed at an earlier
  /// stage) come first. An element is never probed twice and no wording is
  /// repeated.
  static Probe? next({
    required QuestionPlan plan,
    required String heard,
    required List<Probe> asked,
    int limit = maxProbesPerQuestion,
    List<AnswerElement> focus = const [],
  }) {
    if (asked.length >= math.min(limit, maxProbesPerQuestion)) return null;
    final missing = missingElements(plan, heard);
    if (missing.isEmpty) return null;
    final order = [
      for (final e in focus)
        if (missing.contains(e)) e,
      for (final e in missing)
        if (!focus.contains(e)) e,
    ];
    final askedElements = {for (final p in asked) p.element};
    final askedTexts = {for (final p in asked) p.text.toLowerCase()};
    for (final e in order) {
      if (askedElements.contains(e)) continue;
      final wordings = [
        for (final p in plan.probes)
          if (p.element == e) p.text,
        ...?builtInProbes[e],
      ];
      for (final w in wordings) {
        if (!askedTexts.contains(w.toLowerCase())) return Probe(e, w);
      }
    }
    return null;
  }
}

// ---- the panel's manner ----

enum PersonaKind { friendly, neutral, probing, quiet }

/// How the interviewer behaves: what they say after an answer, how long
/// they leave before speaking, and how hard they probe.
class Persona {
  const Persona({
    required this.kind,
    required this.label,
    required this.about,
    required this.greeting,
    required this.acknowledgements,
    required this.gapAfterAnswer,
    required this.gapBeforeProbe,
    this.probeLead = '',
    this.extraProbe = false,
    this.silenceNote = '',
  });

  final PersonaKind kind;
  final String label;
  final String about;

  /// Said at the start of a stage.
  final String greeting;

  /// Said when a question is finished, in turn. Empty: says nothing.
  final List<String> acknowledgements;

  /// The silence after a finished answer before the panel speaks again.
  final Duration gapAfterAnswer;

  /// The silence before a follow-up.
  final Duration gapBeforeProbe;

  /// Said before a follow-up ("Thank you. ").
  final String probeLead;

  /// Probes once more than the ladder level alone would (still at most
  /// two a question).
  final bool extraProbe;

  /// Shown before the round when the panel will be quiet (plan rule 7).
  final String silenceNote;

  /// The line after question [index] is finished, or '' for none.
  String acknowledgement(int index) =>
      acknowledgements.isEmpty ? '' : acknowledgements[index % acknowledgements.length];

  static Persona of(PersonaKind k) => personas[k]!;
}

const personas = {
  PersonaKind.friendly: Persona(
    kind: PersonaKind.friendly,
    label: 'Friendly',
    about: 'A warm chair: thanks you after each answer and leaves short gaps.',
    greeting: 'Hello, and thank you for coming in today.',
    acknowledgements: [
      'Thank you, that is really helpful.',
      'Thanks, that gives us a good picture.',
      'Lovely, thank you.',
    ],
    gapAfterAnswer: Duration(seconds: 1),
    gapBeforeProbe: Duration(seconds: 1),
    probeLead: 'Thank you. ',
  ),
  PersonaKind.neutral: Persona(
    kind: PersonaKind.neutral,
    label: 'Neutral',
    about: 'A note-taker: a plain "thank you", no opinion either way. The usual panel.',
    greeting: 'Thank you for coming.',
    acknowledgements: ['Thank you.', 'Thank you. Moving on.'],
    gapAfterAnswer: Duration(seconds: 2),
    gapBeforeProbe: Duration(milliseconds: 1500),
  ),
  PersonaKind.probing: Persona(
    kind: PersonaKind.probing,
    label: 'Probing',
    about: 'Digs into each answer: asks the follow-ups more often.',
    greeting: 'Thank you for coming. We will ask some follow-up questions as we go.',
    acknowledgements: ['Thank you.'],
    gapAfterAnswer: Duration(milliseconds: 1500),
    gapBeforeProbe: Duration(seconds: 1),
    probeLead: 'I would like to go a little deeper. ',
    extraProbe: true,
  ),
  PersonaKind.quiet: Persona(
    kind: PersonaKind.quiet,
    label: 'Quiet',
    about: 'Poker-faced: no "thank you", no reaction, longer gaps.',
    greeting: 'Thank you. We will begin.',
    acknowledgements: [],
    gapAfterAnswer: Duration(seconds: 4),
    gapBeforeProbe: Duration(seconds: 3),
    silenceNote:
        'This panel stays quiet: no nods, no "thank you", and long gaps. Panels are trained not to react, so '
        'silence does not mean the answer went badly. Finish with a one-line wrap-up, then stop and wait.',
  ),
};

// ---- the difficulty ladder ----

/// Five levels from easy to tough: more probes, interruptions and tighter
/// time as it climbs. You can always step down.
class Ladder {
  const Ladder(
    this.level,
    this.label,
    this.about, {
    required this.probes,
    this.timeFactor,
    this.interruptAfter,
  });

  final int level;
  final String label;
  final String about;

  /// Follow-ups a question may get at this level (before the persona).
  final int probes;

  /// Answer time as a share of the question's usual time; null is untimed.
  final double? timeFactor;

  /// How long past the time budget the interviewer lets an answer run
  /// before interrupting; null never interrupts.
  final Duration? interruptAfter;

  bool get interrupts => interruptAfter != null;

  static Ladder of(int level) => ladder[(level.clamp(1, ladder.length)) - 1];
}

const ladder = [
  Ladder(1, 'Rehearsal', 'No follow-ups, no clock. Get the story straight.', probes: 0),
  Ladder(2, 'Gentle', 'One follow-up at most and a generous clock.', probes: 1, timeFactor: 1.5),
  Ladder(3, 'Standard panel', 'Up to two follow-ups, the usual time.', probes: 2, timeFactor: 1),
  Ladder(
    4,
    'Realistic',
    'Up to two follow-ups; the interviewer may stop an answer that runs well over time.',
    probes: 2,
    timeFactor: 1,
    interruptAfter: Duration(seconds: 15),
  ),
  Ladder(
    5,
    'Tough',
    'Up to two follow-ups, less time, and the interviewer stops you at the time limit.',
    probes: 2,
    timeFactor: 0.75,
    interruptAfter: Duration.zero,
  ),
];

/// The polite interruption at levels 4 and 5.
const interruptLine =
    'Thank you. I am going to stop you there so we keep to time. Could you sum that up in one sentence?';

/// Said at the start of a stage: the panel may interrupt (plan I2).
const mayInterruptScript =
    'Before we start: I may interrupt you now and then to keep us to time. It is not meant to be rude; it just '
    'means we can cover everything.';

/// How long a one-sentence wrap-up may take.
const wrapUpTime = Duration(seconds: 20);

/// The usual answer time for a question of [category] (methodology §3.2:
/// about 90 to 150 s for an example, 30 to 60 s for screening and
/// strengths questions).
Duration usualAnswerTime(String category) {
  final c = category.toLowerCase();
  if (c.contains('strength')) return const Duration(seconds: 45);
  if (c.contains('settler') || c.contains('closing') || c.contains('screen')) {
    return const Duration(seconds: 60);
  }
  if (c.contains('motivation')) return const Duration(seconds: 90);
  if (c.contains('situational') || c.contains('technical') || c.contains('case')) {
    return const Duration(seconds: 120);
  }
  if (c.contains('presentation')) return const Duration(minutes: 5);
  return const Duration(seconds: 150);
}

/// The time an answer to [q] gets at [level]: its own 'seconds' if set,
/// else the usual time for its kind; scaled by the ladder unless the time
/// is fixed (a presentation slot). Null at level 1 (untimed).
Duration? answerBudget(PracticeQuestion q, Ladder level) {
  final factor = level.timeFactor;
  if (factor == null) return null;
  final own = intOf(q.j['seconds']);
  final base = own != null && own > 0 ? Duration(seconds: own) : usualAnswerTime(q.category);
  if (q.j['fixedTime'] == true) return base;
  return Duration(milliseconds: (base.inMilliseconds * factor).round());
}

/// A spoken round's settings, kept on this device.
class RoundSettings {
  const RoundSettings({
    this.persona = PersonaKind.neutral,
    this.level = 3,
    this.endSilence = const Duration(seconds: 5),
    this.aiPlan = true,
  });

  final PersonaKind persona;

  /// 1 to 5 on the [ladder].
  final int level;

  /// Silence that ends an answer: [minSilence] to [maxSilence]. Panels
  /// expect pauses to think, so the default leaves room for one.
  final Duration endSilence;

  /// Let the user's AI write the question plan when there is one.
  final bool aiPlan;

  static const minSilence = Duration(seconds: 3), maxSilence = Duration(seconds: 10);

  RoundSettings copyWith({PersonaKind? persona, int? level, Duration? endSilence, bool? aiPlan}) =>
      RoundSettings(
        persona: persona ?? this.persona,
        level: level ?? this.level,
        endSilence: endSilence ?? this.endSilence,
        aiPlan: aiPlan ?? this.aiPlan,
      );

  Json toJson() => {
    'persona': persona.name,
    'level': level,
    'endSilenceSeconds': endSilence.inSeconds,
    'aiPlan': aiPlan,
  };

  factory RoundSettings.fromJson(Json j) => RoundSettings(
    persona: PersonaKind.values.where((p) => p.name == str(j['persona'])).firstOrNull ?? PersonaKind.neutral,
    level: (intOf(j['level']) ?? 3).clamp(1, ladder.length),
    endSilence: Duration(
      seconds: (intOf(j['endSilenceSeconds']) ?? 5).clamp(minSilence.inSeconds, maxSilence.inSeconds),
    ),
    aiPlan: j['aiPlan'] != false,
  );
}
