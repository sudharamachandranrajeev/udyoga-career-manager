/// The practice loop with Vidya, the learning app, through sync:
///
/// - Vidya asks Udyoga to practise one of its interview drills in the voice
///   simulator (a `bridge_study_progress` row, [practiseRequestsId]).
/// - Udyoga runs it as a one-question round, scores it its own way and
///   sends the score back (a `bridge_study_plans` row, [practiseResultsId]).
/// - Vidya's readiness per role plan (the `readiness` list on that plan's
///   progress row) comes back as drill cards in the next drills plan.
///
/// Neither row is a study plan or a progress report: Udyoga's readers of
/// those look rows up by their own plan ids ([studyPlanId], [drillsPlanId],
/// role plans), so these two rows are never mistaken for one.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';
import 'package:interview_engine/interview_engine.dart';

import '../db/database.dart';
import 'book.dart';
import 'insights.dart';
import 'interview_book.dart';
import 'json.dart';
import 'vidya_link.dart' show rolePlanId;

// ---- requests from Vidya ----

/// The progress row Vidya writes with the drills it wants practised here.
const practiseRequestsId = 'vidya.practise-requests';

/// The `format` of [practiseRequestsId]'s JSON.
const practiseRequestsFormat = 'vidya-practise-requests';

/// The plan row Udyoga writes with its scores for those drills.
const practiseResultsId = 'udyoga.practise-results';

/// The `format` of [practiseResultsId]'s JSON.
const practiseResultsFormat = 'udyoga-practise-results';

/// At most this many results are kept, newest first.
const maxPractiseResults = 50;

/// The key a round's question carries the Vidya drill id under, so the
/// score finds its way back.
const vidyaDrillKey = 'vidyaDrill';

/// The prefix of the role plans' ids ([rolePlanId]).
const rolePlanPrefix = 'udyoga.role.';

/// A drill Vidya asked Udyoga to practise.
class PractiseRequest {
  const PractiseRequest({
    required this.id,
    required this.question,
    this.asked = '',
    this.ref = '',
    this.criterion = '',
    this.role = '',
    this.topic = '',
    this.story = '',
  });

  /// Vidya's row id for the drill; the result names it back.
  final String id;

  /// The plan's id for the drill, '' for one the learner wrote.
  final String ref;
  final String question;

  /// What it tests, in words; '' when Vidya did not say.
  final String criterion;
  final String role, topic;

  /// A Udyoga story id linked to the drill, ''.
  final String story;

  /// When Vidya asked (UTC, ISO 8601).
  final String asked;

  /// The local day it was asked (yyyy-MM-dd), '' when unreadable.
  String get askedDay {
    final t = DateTime.tryParse(asked);
    return t == null ? (asked.length >= 10 ? asked.substring(0, 10) : '') : isoDate(t.toLocal());
  }

  static PractiseRequest? fromJson(Json j) {
    final id = str(j['id']), question = str(j['question']);
    if (id.isEmpty || question.isEmpty) return null;
    return PractiseRequest(
      id: id,
      question: question,
      asked: str(j['asked']),
      ref: str(j['ref']),
      criterion: str(j['criterion']),
      role: str(j['role']),
      topic: str(j['topic']),
      story: str(j['story']),
    );
  }
}

/// The requests in Vidya's [practiseRequestsId] progress JSON, newest first.
/// Any other progress JSON (an ordinary report) gives none.
List<PractiseRequest> parsePractiseRequests(String progressJson) {
  final j = decodeObject(progressJson);
  if (j['format'] != practiseRequestsFormat) return const [];
  final seen = <String>{};
  return [
    for (final r in objs(j['requests']))
      if (PractiseRequest.fromJson(r) case final req? when seen.add(req.id)) req,
  ];
}

// ---- results for Vidya ----

/// One score from the simulator, as Vidya reads it.
class PractiseResult {
  const PractiseResult({
    required this.id,
    required this.day,
    required this.score,
    required this.max,
    this.summary = '',
  });

  /// Vidya's drill row id.
  final String id;

  /// The local day it was practised (yyyy-MM-dd).
  final String day;
  final num score, max;
  final String summary;

  Json toJson() => {
    'id': id,
    'day': day,
    'score': score,
    'max': max,
    if (summary.isNotEmpty) 'summary': summary,
  };

  static PractiseResult? fromJson(Json j) {
    final id = str(j['id']), day = str(j['day']);
    final score = j['score'], max = j['max'];
    if (id.isEmpty || day.isEmpty || score is! num || max is! num || max <= 0) return null;
    return PractiseResult(id: id, day: day, score: score, max: max, summary: str(j['summary']));
  }
}

/// The results in a [practiseResultsId] plan JSON, newest first.
List<PractiseResult> parsePractiseResults(String planJson) {
  final j = decodeObject(planJson);
  if (j['format'] != practiseResultsFormat) return const [];
  return [for (final r in objs(j['results'])) ?PractiseResult.fromJson(r)];
}

/// The [practiseResultsId] plan JSON with [r] added at the top. An older
/// result for the same drill on the same day is replaced (Vidya reads one
/// score per drill per day); at most [maxPractiseResults] are kept.
String mergePractiseResults(String? planJson, PractiseResult r) {
  final old = planJson == null ? const <PractiseResult>[] : parsePractiseResults(planJson);
  final results = [
    r,
    for (final o in old)
      if (!(o.id == r.id && o.day == r.day)) o,
  ]..sort((a, b) => b.day.compareTo(a.day));
  return jsonEncode({
    'format': practiseResultsFormat,
    'version': 1,
    'results': [for (final x in results.take(maxPractiseResults)) x.toJson()],
  });
}

/// Whether [r] has a score here from the day it was asked or later.
bool practised(PractiseRequest r, List<PractiseResult> results) {
  final day = r.askedDay;
  return results.any((x) => x.id == r.id && x.day.compareTo(day) >= 0);
}

String _clip(String s, int max) => s.length > max ? '${s.substring(0, max - 1).trimRight()}…' : s;

/// The one question of a round for [r]: what it tests is Vidya's criterion
/// (so the debrief scores that), with the linked story to tell when the
/// story is still in the bank.
PracticeQuestion practiseQuestion(PractiseRequest r, {Story? story}) => PracticeQuestion({
  'question': r.question,
  'category': 'Behavioural',
  'why': r.criterion.isNotEmpty ? r.criterion : 'The question as Vidya asked it',
  'lookFor': [
    'One specific example',
    'What you yourself did',
    'What came of it',
    if (story != null) 'Your story "${story.title}" fits here',
  ],
  vidyaDrillKey: r.id,
});

/// The drill id a round's question came from, '' for an ordinary question.
String vidyaDrillOf(PracticeQuestion q) => str(q.j[vidyaDrillKey]);

/// The score for a one-question Vidya round from its debrief, on Udyoga's
/// own scales: with the AI's checked scoring, the level reached on the
/// framework's scale (rank out of the top rank); otherwise the matcher's
/// coverage (missing 0, thin 1, evidenced 2, out of 2). Null when nothing
/// was answered.
PractiseResult? practiseResultOf(Debrief d, {required String id, required String day}) {
  final c = d.coverage.where((c) => c.asked).firstOrNull;
  final note = d.notes.firstOrNull;
  if (c == null || note == null) return null;
  final scale = d.framework.scale;
  if (d.aiScored) {
    final level = c.best?.level ?? scale.noEvidence;
    return PractiseResult(
      id: id,
      day: day,
      score: scale.rank(level),
      max: scale.levels.length - 1,
      summary: _clip('${level.code} (${level.label}) on the ${scale.name}. ${note.fix}', 200),
    );
  }
  return PractiseResult(
    id: id,
    day: day,
    score: switch (c.status) {
      Coverage.evidenced => 2,
      Coverage.thin => 1,
      Coverage.missing => 0,
    },
    max: 2,
    summary: _clip('${c.status.label}. ${note.fix}', 200),
  );
}

// ---- readiness from Vidya ----

/// A weak or missing criterion in Vidya's readiness for a role plan.
class VidyaReadinessRow {
  const VidyaReadinessRow({
    required this.criterionId,
    required this.text,
    required this.status,
    this.essential = false,
  });

  /// The plan's criterion id; '' for one the learner typed in Vidya.
  final String criterionId;
  final String text;

  /// weak or missing.
  final String status;
  final bool essential;

  bool get weak => status == 'weak';
  bool get missing => status == 'missing';
}

/// Vidya's readiness for one role plan.
class VidyaReadiness {
  const VidyaReadiness({required this.planId, required this.role, required this.rows});
  final String planId;
  final String role;

  /// Weak and missing rows only, in plan order; empty when all is covered.
  final List<VidyaReadinessRow> rows;

  int get weak => rows.where((r) => r.weak).length;
  int get missing => rows.where((r) => r.missing).length;

  /// "Vidya readiness: 2 weak, 1 missing", or every criterion covered.
  String get text => rows.isEmpty
      ? 'Vidya readiness: every criterion covered'
      : 'Vidya readiness: $weak weak, $missing missing';

  /// The essential rows, the ones that become drill cards.
  List<VidyaReadinessRow> get essentialGaps => [
    for (final r in rows)
      if (r.essential) r,
  ];
}

/// The `readiness` list in a progress JSON; null when it has none (Vidya
/// leaves the key out when the plan has no criteria).
List<VidyaReadinessRow>? parseVidyaReadiness(String progressJson) {
  final j = decodeObject(progressJson);
  if (j['readiness'] is! List) return null;
  return [
    for (final r in objs(j['readiness']))
      if (str(r['text']).isNotEmpty && const {'weak', 'missing'}.contains(str(r['status'])))
        VidyaReadinessRow(
          criterionId: str(r['criterionId']),
          text: str(r['text']),
          status: str(r['status']),
          essential: r['essential'] == true,
        ),
  ];
}

/// A short stable hash (FNV-1a, 32 bits, hex), for ids made from text.
String _hash(String s) {
  var h = 0x811c9dc5;
  for (final c in utf8.encode(s)) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

String _slug(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');

/// The stable card id of a readiness drill: the same role and criterion
/// always give the same id, so a re-sent card updates in place in Vidya,
/// and a covered one drops out of the plan (Vidya sets it aside).
String readinessDrillId(String planId, VidyaReadinessRow r) {
  final role = planId.startsWith(rolePlanPrefix) ? planId.substring(rolePlanPrefix.length) : planId;
  final key = r.criterionId.isNotEmpty ? _slug(r.criterionId) : 't${_hash(r.text.toLowerCase().trim())}';
  return 'udyoga.drill.readiness.${_slug(role)}.$key';
}

String _lowerFirst(String s) =>
    s.length > 1 && s[1] == s[1].toLowerCase() ? s[0].toLowerCase() + s.substring(1) : s;

/// Drill cards (Vidya card JSON, deck [deck]) for the weak and missing
/// essential criteria in [readiness].
List<Json> readinessDrillCards(List<VidyaReadiness> readiness, {required String deck}) => [
  for (final r in readiness)
    for (final row in r.essentialGaps)
      {
        'id': readinessDrillId(r.planId, row),
        'deck': deck,
        'course': 'Interview drills',
        'front':
            'This role needs ${_lowerFirst(row.text.replaceAll(RegExp(r'[.;:]+$'), ''))}. Tell us about a time you '
            'showed this.',
        'back': [
          'Vidya readiness for ${r.role}: ${row.missing ? 'missing (nothing linked to it yet)' : 'weak'}.',
          'One specific example: the situation, what you yourself did, and how it turned out. Then link it back '
              'to the criterion.',
        ].join('\n'),
      },
];

// ---- on the candidate's records ----

extension VidyaPractice on CareerBook {
  /// What Vidya asked to practise, newest first; empty until it asks.
  Future<List<PractiseRequest>> practiseRequests() async {
    final row = await (db.select(
      db.bridgeStudyProgress,
    )..where((p) => p.id.equals(practiseRequestsId) & p.deleted.not())).getSingleOrNull();
    return row == null ? const [] : parsePractiseRequests(row.progress);
  }

  /// The scores sent back so far, newest first.
  Future<List<PractiseResult>> practiseResults() async {
    final row = await (db.select(
      db.bridgeStudyPlans,
    )..where((p) => p.id.equals(practiseResultsId) & p.deleted.not())).getSingleOrNull();
    return row == null ? const [] : parsePractiseResults(row.plan);
  }

  /// The requests not practised here since Vidya asked.
  Future<List<PractiseRequest>> pendingPractiseRequests() async {
    final results = await practiseResults();
    return [
      for (final r in await practiseRequests())
        if (!practised(r, results)) r,
    ];
  }

  /// A one-question round for [r] (with its linked story, when it is still
  /// in the bank). Returns the round id.
  Future<String> startVidyaPractice(PractiseRequest r, {required String at}) async {
    final story = r.story.isEmpty
        ? null
        : await (db.select(
            db.careerStories,
          )..where((s) => s.id.equals(r.story) & s.deleted.not())).getSingleOrNull();
    return startPractice(
      role: r.role.isNotEmpty ? r.role : 'Vidya drill',
      mode: 'competency',
      questions: [practiseQuestion(r, story: story)],
      at: at,
    );
  }

  /// After a Vidya round: scores it from its debrief and merges the score
  /// into the results row for Vidya. Returns the result, or null when the
  /// round is not a Vidya one or nothing was answered.
  Future<PractiseResult?> recordVidyaPractice(String roundId, {required String now, String? day}) async {
    final rec = await roundRecord(roundId);
    if (rec == null || rec.questions.length != 1) return null;
    final id = vidyaDrillOf(rec.questions.single);
    if (id.isEmpty) return null;
    final debrief = await roundDebrief(roundId, wholeProfile: false);
    if (debrief == null) return null;
    final result = practiseResultOf(debrief, id: id, day: day ?? today());
    if (result == null) return null;
    final old = await (db.select(
      db.bridgeStudyPlans,
    )..where((p) => p.id.equals(practiseResultsId))).getSingleOrNull();
    await save(
      db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(
        id: practiseResultsId,
        source: 'udyoga',
        plan: mergePractiseResults(old == null || old.deleted ? null : old.plan, result),
        updated: now,
        deleted: const Value(false),
      ),
      practiseResultsId,
    );
    return result;
  }

  /// Vidya's readiness for each role plan it has reported on (plan order
  /// of the sends, newest first).
  Future<List<VidyaReadiness>> vidyaReadiness() async {
    final progress =
        await (db.select(db.bridgeStudyProgress)
              ..where((p) => p.id.like('$rolePlanPrefix%') & p.deleted.not())
              ..orderBy([(p) => OrderingTerm.desc(p.updated), (p) => OrderingTerm.asc(p.id)]))
            .get();
    if (progress.isEmpty) return const [];
    final plans = {
      for (final p in await (db.select(
        db.bridgeStudyPlans,
      )..where((p) => p.id.like('$rolePlanPrefix%') & p.deleted.not())).get())
        p.id: p,
    };
    final out = <VidyaReadiness>[];
    for (final p in progress) {
      final plan = plans[p.id];
      if (plan == null) continue; // A plan taken back: its readiness goes with it.
      final rows = parseVidyaReadiness(p.progress);
      if (rows == null) continue;
      final role = str(decodeObject(plan.plan)['role']);
      out.add(
        VidyaReadiness(
          planId: p.id,
          role: role.isEmpty ? p.id.substring(rolePlanPrefix.length) : role,
          rows: rows,
        ),
      );
    }
    return out;
  }

  /// Vidya's readiness for [role], or null when Vidya has not reported on
  /// its plan.
  Future<VidyaReadiness?> roleReadiness(String role) async {
    final id = rolePlanId(role);
    return (await vidyaReadiness()).where((r) => r.planId == id).firstOrNull;
  }
}
