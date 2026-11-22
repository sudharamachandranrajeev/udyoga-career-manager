import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';
import 'package:interview_engine/interview_engine.dart';

import '../db/database.dart';
import 'book.dart';
import 'companion.dart' show StoryDraft;
import 'insights.dart';
import 'json.dart';

/// The interview records of plan I3: role profiles, saved processes, the
/// panel scoring of a round and stories saved from practice. All of it is
/// text and syncs like the rounds; recordings never come here.
extension InterviewBook on CareerBook {
  // ---- role profiles ----

  Future<List<RoleProfileRow>> roleProfileRows() =>
      (db.select(db.careerRoleProfiles)
            ..where((p) => p.deleted.not())
            ..orderBy([(p) => OrderingTerm.desc(p.updated)]))
          .get();

  Future<RoleProfile?> roleProfile(String? id) async {
    if (id == null || id.isEmpty) return null;
    final row = await (db.select(
      db.careerRoleProfiles,
    )..where((p) => p.id.equals(id) & p.deleted.not())).getSingleOrNull();
    return row == null ? null : roleProfileOf(row);
  }

  static RoleProfile roleProfileOf(RoleProfileRow r) => RoleProfile(
    id: r.id,
    title: r.title,
    employer: r.employer,
    frameworkId: r.framework,
    criteria: [for (final c in objs(decodeList(r.criteria))) Criterion.fromJson(c)],
    jobId: r.jobId,
    source: r.source,
  );

  /// Saves [p] (new when its id is empty); returns its id.
  Future<String> saveRoleProfile(RoleProfile p, {required String at}) async {
    final existing = p.id.isEmpty
        ? null
        : await (db.select(db.careerRoleProfiles)..where((r) => r.id.equals(p.id))).getSingleOrNull();
    final id = p.id.isEmpty ? newId() : p.id;
    await save(
      db.careerRoleProfiles,
      CareerRoleProfilesCompanion.insert(
        id: id,
        title: p.title,
        employer: Value(p.employer),
        jobId: Value(p.jobId),
        framework: Value(p.frameworkId),
        criteria: Value(jsonEncode([for (final c in p.criteria) c.toJson()])),
        source: Value(p.source),
        added: existing?.added ?? at,
        updated: at,
      ),
      id,
    );
    return id;
  }

  // ---- rounds ----

  /// A practice round from [p]'s criteria.
  Future<String> startProfileRound(RoleProfile p, {required String at, int max = 8}) async {
    final id = await startPractice(
      role: [p.title, if (p.employer.isNotEmpty) p.employer].join(', '),
      mode: 'competency',
      jobId: p.jobId,
      questions: questionsFromProfile(p, max: max),
      at: at,
    );
    await setRoundProfile(id, p.id);
    return id;
  }

  Future<void> setRoundProfile(String roundId, String? profileId) async {
    final s = await (db.select(db.careerPractice)..where((r) => r.id.equals(roundId))).getSingle();
    await save(db.careerPractice, s.copyWith(profileId: Value(profileId)), s.id);
  }

  /// Keeps the AI's scoring of a round (text only), or clears it with ''.
  Future<void> saveScoring(String roundId, Json scoring) async {
    final s = await (db.select(db.careerPractice)..where((r) => r.id.equals(roundId))).getSingle();
    await save(db.careerPractice, s.copyWith(debrief: scoring.isEmpty ? '' : jsonEncode(scoring)), s.id);
  }

  /// The round's questions and each answer's text, by question.
  Future<({PracticeSession round, List<PracticeQuestion> questions, Map<int, String> answers})?> roundRecord(
    String roundId,
  ) async {
    final s = await (db.select(
      db.careerPractice,
    )..where((r) => r.id.equals(roundId) & r.deleted.not())).getSingleOrNull();
    if (s == null) return null;
    final answers = await (db.select(
      db.careerAnswers,
    )..where((a) => a.sessionId.equals(roundId) & a.deleted.not())).get();
    return (
      round: s,
      questions: [for (final q in objs(decodeList(s.questions))) PracticeQuestion(q)],
      answers: {for (final a in answers) a.question: a.answer},
    );
  }

  /// The AI's scoring of a saved round ([debrief], as saved), checked again against the
  /// transcripts: both runs when it was scored twice (the criteria shuffled
  /// each time; where they disagree the lower level shows, marked
  /// uncertain), or the one run a round scored before that kept. Null when
  /// not scored.
  static Verified? verifiedOf(String debrief, DebriefRound data, Framework framework) {
    final saved = decodeObject(debrief);
    if (saved.isEmpty) return null;
    final runs = [
      for (final r in saved['runs'] is List ? saved['runs'] as List : const [])
        [for (final a in objs(r)) AnswerScore.fromJson(a)],
    ];
    if (runs.isNotEmpty) return verifyRuns(runs, framework.scale, data);
    return verifyScores(
      [for (final a in objs(saved['answers'])) AnswerScore.fromJson(a)],
      framework.scale,
      heard: data.heard,
      asked: data.asked,
      situational: data.situational,
    );
  }

  /// The framework a saved round was scored on, else the profile's.
  static Framework frameworkOf(PracticeSession round, RoleProfile? profile) {
    final saved = decodeObject(round.debrief);
    return Framework.of(
      str(saved['framework']).isNotEmpty ? str(saved['framework']) : profile?.frameworkId ?? 'private',
    );
  }

  /// The debrief of a saved round: its saved scoring checked again against
  /// the transcripts, or coverage from the matcher when it was not scored.
  static Debrief debriefOf(
    PracticeSession round,
    DebriefRound data,
    RoleProfile? profile, {
    bool wholeProfile = true,
  }) {
    final framework = frameworkOf(round, profile);
    final verified = verifiedOf(round.debrief, data, framework);
    return Debrief.build(framework: framework, round: data, verified: verified, wholeProfile: wholeProfile);
  }

  /// The debrief of round [roundId], or null when it is gone.
  Future<Debrief?> roundDebrief(String roundId, {bool wholeProfile = true}) async {
    final rec = await roundRecord(roundId);
    if (rec == null) return null;
    final profile = await roleProfile(rec.round.profileId);
    final data = DebriefRound.of(questions: rec.questions, answers: rec.answers, profile: profile);
    return debriefOf(rec.round, data, profile, wholeProfile: wholeProfile);
  }

  // ---- processes ----

  /// Every stage's debrief of saved process [id] in one view: each
  /// criterion across the process and the top fixes. Stages not started
  /// are left out. Null when the process is gone.
  Future<ProcessSummary?> processSummary(String id) async {
    final saved = await savedProcess(id);
    if (saved == null) return null;
    final stages = <({String stage, Debrief debrief})>[];
    for (final (i, st) in saved.process.stages.indexed) {
      final p = saved.progress.stages[i];
      if (p == null || !st.included) continue;
      final d = await roundDebrief(p.roundId, wholeProfile: false);
      if (d != null) stages.add((stage: st.title, debrief: d));
    }
    return ProcessSummary.build(stages, profile: await roleProfile(saved.profileId));
  }

  Future<List<ProcessRow>> processRows() =>
      (db.select(db.careerProcesses)
            ..where((p) => p.deleted.not())
            ..orderBy([(p) => OrderingTerm.desc(p.updated)]))
          .get();

  Future<({InterviewProcess process, ProcessProgress progress, String? profileId})?> savedProcess(
    String id,
  ) async {
    final r = await (db.select(
      db.careerProcesses,
    )..where((p) => p.id.equals(id) & p.deleted.not())).getSingleOrNull();
    if (r == null) return null;
    return (
      process: InterviewProcess.fromJson(decodeObject(r.process)),
      progress: ProcessProgress.fromJson(decodeObject(r.progress)),
      profileId: r.profileId,
    );
  }

  /// Saves a process and its progress under [id] (new when empty); returns
  /// the id.
  Future<String> saveProcess(
    String id,
    InterviewProcess process,
    ProcessProgress progress, {
    String? profileId,
    required String at,
  }) async {
    final existing = id.isEmpty
        ? null
        : await (db.select(db.careerProcesses)..where((r) => r.id.equals(id))).getSingleOrNull();
    final rowId = id.isEmpty ? newId() : id;
    await save(
      db.careerProcesses,
      CareerProcessesCompanion.insert(
        id: rowId,
        name: process.name,
        template: Value(existing?.template ?? process.id),
        profileId: Value(profileId),
        process: jsonEncode(process.toJson()),
        progress: Value(jsonEncode(progress.toJson())),
        started: existing?.started ?? at,
        updated: at,
      ),
      rowId,
    );
    return rowId;
  }

  // ---- the story bank ----

  /// Saves a practice answer as a draft story, marked as from practice,
  /// with the criteria it evidenced. The candidate checks it before it
  /// counts as ready. Returns the story's id, or null when one of that
  /// title is already in the bank.
  Future<String?> saveStoryFromPractice(
    StoryDraft d, {
    required String roundId,
    required List<String> criteria,
    required String today,
  }) async {
    final known = await (db.select(db.careerStories)..where((s) => s.deleted.not())).get();
    if (known.any((s) => s.title.toLowerCase().trim() == d.title.toLowerCase().trim())) return null;
    final id = newId();
    await save(
      db.careerStories,
      CareerStoriesCompanion.insert(
        id: id,
        title: d.title,
        situation: Value(d.situation),
        task: Value(d.task),
        action: Value(d.action),
        result: Value(d.result),
        competencies: Value(jsonEncode(d.competencies)),
        source: const Value('practice'),
        sourceId: Value(roundId),
        criteria: Value(jsonEncode(criteria)),
        added: today,
      ),
      id,
    );
    return id;
  }
}
