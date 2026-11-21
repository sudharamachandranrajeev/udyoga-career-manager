/// The confidence loop (interview plan I4): how nervous the candidate felt
/// before and after each round, drills that go to Vidya to rehearse, what
/// Vidya says was rehearsed, and what they are ready for, shown before the
/// gaps.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'companion_book.dart';
import 'interview_book.dart';
import 'interview_scoring.dart';
import 'json.dart';
import 'vidya_link.dart' show studyPlanId;
import 'vidya_practice.dart';
export 'vidya_link.dart' show storyCardId;

// ---- nerves ----

/// The one-tap scale. Words, not a score: it is the candidate's own feeling.
const nervesLabels = {1: 'Calm', 2: 'A little nervous', 3: 'Nervous', 4: 'Very nervous', 5: 'Overwhelmed'};

/// One round's ratings, when the candidate gave any.
typedef NervesPoint = ({String day, String roundId, int? before, int? after});

/// The rated rounds, oldest first.
List<NervesPoint> nervesTrend(Iterable<PracticeSession> rounds) {
  final rated = [
    for (final r in rounds)
      if (!r.deleted && (r.nervesBefore != null || r.nervesAfter != null))
        (
          day: r.started.length >= 10 ? r.started.substring(0, 10) : r.started,
          roundId: r.id,
          before: r.nervesBefore,
          after: r.nervesAfter,
        ),
  ];
  rated.sort((a, b) => a.day.compareTo(b.day));
  return rated;
}

/// The trend in plain words, or '' with too few ratings to say.
String nervesSummary(List<NervesPoint> points) {
  final before = [for (final p in points) ?p.before];
  final lines = <String>[];
  if (before.length >= 2) {
    final first = before.first, last = before.last;
    lines.add(
      last < first
          ? 'Before a round you went from ${nervesLabels[first]!.toLowerCase()} to '
                '${nervesLabels[last]!.toLowerCase()}.'
          : last == first
          ? 'Before a round you feel about the same as at the start: ${nervesLabels[last]!.toLowerCase()}.'
          : 'Your latest round started more nervous than your first. That is normal before a harder '
                'level: it settles with repetition.',
    );
  }
  final pairs = [
    for (final p in points)
      if (p.before != null && p.after != null) p.before! - p.after!,
  ];
  if (pairs.isNotEmpty) {
    final calmer = pairs.where((d) => d > 0).length;
    if (calmer > 0) {
      lines.add('You felt calmer after $calmer of ${pairs.length} round${pairs.length == 1 ? '' : 's'} than before.');
    }
  }
  return lines.join(' ');
}

// ---- drills for Vidya ----

/// The plan row the drills go out on; sending again replaces it.
const drillsPlanId = 'udyoga.interview-drills';

/// The Vidya deck the drill cards go in.
const drillsDeck = 'Interview drills';

/// Card ids are stable, so Vidya updates a changed card in place.
const drillIdPrefix = 'udyoga.drill.';
String storyDrillId(String storyId) => '${drillIdPrefix}story.$storyId';

/// Generic questions to ask a panel, by stage (methodology 2.5); the
/// candidate keeps their own set, starting from these.
const questionsForThemBank = {
  'Screening': [
    'What are the next steps, and when should I expect to hear?',
    'What does a typical week look like in this role?',
  ],
  'Panel': [
    'What would success look like at six months?',
    'What are the biggest pressures on the team right now?',
    'How does the team share learning when something goes wrong?',
  ],
  'Senior': [
    'What are the organisation\'s priorities for the next year?',
    'How would you describe the culture you want this role to build?',
  ],
};

/// The set a new candidate starts with: the panel questions.
final defaultQuestionsForThem = questionsForThemBank['Panel']!;

/// Lines to say in the room when an answer goes wrong, and when to use them.
const recoveryDrills = {
  'better-example': ('Your example felt weak as you finished it', Recovery.betterExample),
  'own-part': ('You said "we" all through and the panel cannot tell what you did', Recovery.ownPart),
  'outcome': ('You stopped before saying how it turned out', Recovery.outcome),
  'sum-up': ('You lost the thread of a long answer', Recovery.sumUp),
  'honest': ('You have not done exactly what they asked about', Recovery.honest),
  'repeat': ('You did not catch the question', 'Sorry, could you say the question again?'),
  'pause': ('Your mind went blank', 'Can I take a moment to think about that?'),
};

/// The label the reappraisal note always carries (methodology 4, mixed
/// evidence): never claimed to raise a score.
const reappraisalLabel = 'Small effect in studies; try it, keep it if it helps.';

const reappraisalNote =
    'If your heart is racing before you go in, try saying to yourself "I\'m excited" rather than trying to '
    'calm down: a racing heart is your body getting ready. $reappraisalLabel';

const _routine = [
  (
    title: 'The day before',
    details:
        'Check the route, or test the video link, camera and microphone. Read your questions for them. Read '
        'your story cards once. Read the values in the job pack.',
    minutes: 30,
  ),
  (
    title: '30 minutes before',
    details: 'Say two short answers aloud as a warm-up: the settler and one story.',
    minutes: 10,
  ),
  (
    title: '5 minutes before',
    details: 'A few slow breaths. Have your one-line opening ready: who you are and why this role.',
    minutes: 5,
  ),
  (
    title: 'In the room',
    details:
        'It is fine to pause, to ask for a question again, or to jot a note. Panels expect nerves; no-one '
        'answers every question perfectly.',
    minutes: 5,
  ),
];

const _videoSetup = [
  (title: 'Connection', details: 'Use a wired or strong connection; close other apps that use the network.'),
  (title: 'Sound', details: 'Headphones or a headset; test the microphone in the meeting app first.'),
  (title: 'Light and framing', details: 'Light in front of you, not behind; head and shoulders in frame.'),
  (title: 'Eye line', details: 'Camera at eye height. Looking at the camera when you make a point is optional.'),
  (title: 'Notes', details: 'A few keywords near the camera at most: reading a script shows on video.'),
  (title: 'Interruptions', details: 'Phone on silent, door closed, notifications off.'),
  (title: 'If it drops', details: 'Have the panel\'s phone number ready; rejoin, then say where you were up to.'),
];

/// The first sentence of [s], at most [max] characters.
String _gist(String s, {int max = 160}) {
  final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  final m = RegExp(r'^.*?[.!?](?=\s|$)').firstMatch(t);
  final first = m?.group(0) ?? t;
  return first.length > max ? '${first.substring(0, max - 1).trimRight()}…' : first;
}

/// A story as three bullets to say it from: the situation, what you did,
/// and how it turned out.
String threeBullets(Story s) => [
  '- ${_gist(s.situation.isNotEmpty ? s.situation : s.task)}',
  '- I ${_gist(s.action).replaceFirst(RegExp(r'^I\s+', caseSensitive: false), '')}',
  '- ${s.result.isNotEmpty ? _gist(s.result) : 'Say how it turned out.'}',
].join('\n');

/// The drills as a Vidya plan ("vidya-curriculum", version 1). Every card
/// carries a stable id. [readiness] is Vidya's readiness per role plan: each
/// weak or missing essential criterion becomes a drill card, which updates
/// in place while it stays weak and drops out once Vidya says it is covered.
Json interviewDrills({
  required List<Story> stories,
  required List<String> questionsForThem,
  bool reappraisal = false,
  String settler = 'Could you start by telling us a little about your current role?',
  List<VidyaReadiness> readiness = const [],
}) {
  final gapCards = readinessDrillCards(readiness, deck: drillsDeck);
  Json card(String id, String front, String back) => {
    'id': id,
    'deck': drillsDeck,
    'course': 'Interview drills',
    'front': front,
    'back': back,
  };
  return {
    'format': 'vidya-curriculum',
    'version': 1,
    'part': '1 of 1',
    'program': {
      'title': 'Interview drills',
      'goal':
          'Walk in with lines you have already said aloud: the opener, your stories, what to say if an '
          'answer goes wrong, and your questions for them.',
    },
    'courses': [
      {
        'title': 'Interview drills',
        'kind': 'practice',
        'summary': 'Say each card aloud, then rate how it went. Your ratings go back to Udyoga.',
        'topics': const [],
      },
      {
        'title': 'Pre-interview routine',
        'kind': 'practice',
        'summary': 'A checklist for the day before and the last half hour.',
        'topics': [
          for (final r in _routine) {'title': r.title, 'minutes': r.minutes, 'details': r.details},
          if (reappraisal) {'title': 'Optional: "I\'m excited"', 'minutes': 1, 'details': reappraisalNote},
        ],
      },
      {
        'title': 'Video interview setup',
        'kind': 'practice',
        'summary': 'Check each before a video or phone interview.',
        'topics': [
          for (final v in _videoSetup) {'title': v.title, 'minutes': 2, 'details': v.details},
        ],
      },
    ],
    'skills': const [],
    'cards': [
      card(
        '${drillIdPrefix}settler',
        settler,
        'About a minute: your role now, one thing you are proud of in it, and why this job is the next step.',
      ),
      for (final s in stories)
        if (s.action.trim().isNotEmpty)
          card(storyDrillId(s.id), 'Your story in three bullets: ${s.title}', threeBullets(s)),
      for (final MapEntry(key: k, value: (moment, line)) in recoveryDrills.entries)
        card('${drillIdPrefix}recovery.$k', 'Recovery line: $moment', line),
      if (questionsForThem.any((q) => q.trim().isNotEmpty))
        card(
          '${drillIdPrefix}questions',
          'Do you have any questions for us?',
          [
            for (final q in questionsForThem)
              if (q.trim().isNotEmpty) '- ${q.trim()}',
          ].join('\n'),
        ),
      if (reappraisal)
        card('${drillIdPrefix}reappraisal', 'Your heart is racing as you wait to go in', reappraisalNote),
      ...gapCards,
    ],
    'notes': [
      {
        'title': 'From Udyoga: interview drills',
        'body': [
          'Made by Udyoga from your story bank and your questions for them. Sending again updates these cards '
              'and keeps your reviews.',
          if (reappraisal) '\nThe "I\'m excited" card is optional. $reappraisalLabel',
          if (gapCards.isNotEmpty)
            '\n${gapCards.length == 1 ? '1 card comes' : '${gapCards.length} cards come'} from your Vidya readiness: the '
                'essential criteria still weak or missing. Each goes once Vidya counts it covered.',
        ].join('\n'),
        'tags': ['udyoga', 'interview'],
      },
    ],
  };
}

// ---- what Vidya says was rehearsed ----

/// One card or checklist item Vidya reports on.
class DrillResult {
  const DrillResult({required this.id, required this.title, this.done = '', this.rating = '', this.times = 0});

  /// The card id, or 'course/topic' for a checklist item.
  final String id;
  final String title;

  /// The day last rehearsed (yyyy-mm-dd), '' when never.
  final String done;

  /// The candidate's own rating of the last go: again, hard, good or easy.
  final String rating;
  final int times;

  bool get isStory => id.startsWith('udyoga.story.') || id.startsWith('${drillIdPrefix}story.');
  bool get rehearsed => done.isNotEmpty;
}

/// The drill results in Vidya's progress JSON (its "drills" list), most
/// recent first. Unknown or malformed entries are skipped.
List<DrillResult> drillResultsFrom(String progressJson) {
  Object? raw;
  try {
    raw = jsonDecode(progressJson);
  } on FormatException {
    return const [];
  }
  if (raw is! Map) return const [];
  final out = <DrillResult>[];
  for (final d in objs(raw['drills'])) {
    final id = str(d['id']).isNotEmpty ? str(d['id']) : [str(d['course']), str(d['title'])].join('/');
    if (id == '/' || str(d['title']).isEmpty) continue;
    out.add(
      DrillResult(
        id: id,
        title: str(d['title']),
        done: str(d['done']),
        rating: str(d['rating']),
        times: d['times'] is int ? d['times'] as int : 0,
      ),
    );
  }
  out.sort((a, b) => b.done.compareTo(a.done));
  return out;
}

// ---- what you're ready for ----

/// What the candidate can already show, led with on the Interview page.
class ReadyFor {
  const ReadyFor({this.evidenced = const [], this.stories = const [], this.nerves = ''});

  /// Criteria their answers evidenced in recent rounds.
  final List<String> evidenced;

  /// Stories rehearsed in Vidya.
  final List<String> stories;

  /// The nerves trend in words, or ''.
  final String nerves;

  bool get isEmpty => evidenced.isEmpty && stories.isEmpty && nerves.isEmpty;

  static ReadyFor build({
    required List<Debrief> recent,
    required List<DrillResult> results,
    required List<NervesPoint> nerves,
  }) {
    final seen = <String>{};
    final evidenced = [
      for (final d in recent)
        for (final c in d.coverage)
          if (c.asked && c.status == Coverage.evidenced && seen.add(c.criterion.text.toLowerCase().trim()))
            c.criterion.text,
    ];
    final titles = <String>{};
    final stories = [
      for (final r in results)
        if (r.isStory && r.rehearsed && titles.add(r.title)) r.title,
    ];
    return ReadyFor(evidenced: evidenced, stories: stories, nerves: nervesSummary(nerves));
  }
}

/// Pref keys for the drills.
abstract final class DrillPrefs {
  static const questions = 'udyoga.interview.questions';
  static const reappraisal = 'udyoga.interview.reappraisal';
}

/// Nerves, drills and the ready-for view on the candidate's records.
extension InterviewConfidence on CareerBook {
  /// Keeps one or both ratings; 0 clears one (the candidate untapped it).
  Future<void> saveNerves(String roundId, {int? before, int? after}) async {
    final s = await (db.select(db.careerPractice)..where((r) => r.id.equals(roundId))).getSingle();
    Value<int?> v(int? n, int? was) => n == null ? Value(was) : Value(n == 0 ? null : n.clamp(1, 5));
    await save(
      db.careerPractice,
      s.copyWith(nervesBefore: v(before, s.nervesBefore), nervesAfter: v(after, s.nervesAfter)),
      s.id,
    );
  }

  Future<List<String>> questionsForThem() async {
    final saved = await pref<List<Object?>>(DrillPrefs.questions, const []);
    final qs = [for (final q in saved) '$q'.trim()].where((q) => q.isNotEmpty).toList();
    return qs.isEmpty ? defaultQuestionsForThem : qs;
  }

  Future<void> setQuestionsForThem(List<String> qs) => setPref(DrillPrefs.questions, [
    for (final q in qs)
      if (q.trim().isNotEmpty) q.trim(),
  ]);

  Future<bool> reappraisal() => pref<bool>(DrillPrefs.reappraisal, false);
  Future<void> setReappraisal(bool on) => setPref(DrillPrefs.reappraisal, on);

  Future<Json> drillsPlanNow() async => interviewDrills(
    stories: await stories(),
    questionsForThem: await questionsForThem(),
    reappraisal: await reappraisal(),
    settler: profileSettler.question,
    readiness: await vidyaReadiness(),
  );

  /// Sends the drills to Vidya through sync, as their own plan row.
  Future<void> sendDrills({required String now}) async {
    final plan = await drillsPlanNow();
    await save(
      db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(id: drillsPlanId, source: 'udyoga', plan: jsonEncode(plan), updated: now),
      drillsPlanId,
    );
  }

  /// When the drills were last sent, and whether Vidya has added them.
  Future<({String? sent, bool added})> drillsSent() async {
    final plan = await (db.select(
      db.bridgeStudyPlans,
    )..where((p) => p.id.equals(drillsPlanId) & p.deleted.not())).getSingleOrNull();
    final progress = await (db.select(
      db.bridgeStudyProgress,
    )..where((p) => p.id.equals(drillsPlanId) & p.deleted.not())).getSingleOrNull();
    return (sent: plan?.updated, added: plan != null && progress?.planUpdated == plan.updated);
  }

  /// What Vidya reports rehearsed, from the drills and the study plan.
  Future<List<DrillResult>> drillResults() async {
    final rows = await (db.select(
      db.bridgeStudyProgress,
    )..where((p) => p.id.isIn([drillsPlanId, studyPlanId]) & p.deleted.not())).get();
    return [for (final r in rows) ...drillResultsFrom(r.progress)]..sort((a, b) => b.done.compareTo(a.done));
  }

  /// What the candidate is ready for: criteria evidenced in the last
  /// [rounds] rounds, stories rehearsed in Vidya, and the nerves trend.
  Future<ReadyFor> readyFor({int rounds = 10}) async {
    final all =
        await (db.select(db.careerPractice)
              ..where((r) => r.deleted.not())
              ..orderBy([(r) => OrderingTerm.desc(r.started)]))
            .get();
    final recent = <Debrief>[];
    for (final r in all.take(rounds)) {
      if (await roundDebrief(r.id, wholeProfile: false) case final d?) recent.add(d);
    }
    return ReadyFor.build(recent: recent, results: await drillResults(), nerves: nervesTrend(all));
  }
}
