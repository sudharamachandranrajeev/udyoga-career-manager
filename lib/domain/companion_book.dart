import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'companion.dart';
import 'evidence.dart';
import 'json.dart';

/// The companion's records: documents read, profile questions, check-ins
/// and the story bank.
extension CompanionBook on CareerBook {
  // ---- Documents ----

  /// Document ids come from the content hash, so a file found on two devices
  /// is one row and is read by the AI once.
  static String documentId(String hash) => 'doc-${hash.substring(0, 32)}';

  Future<List<CareerDocument>> documents() =>
      (db.select(db.careerDocuments)
            ..where((d) => d.deleted.not())
            ..orderBy([(d) => OrderingTerm.desc(d.found)]))
          .get();

  /// Records files found in the candidate's folders; returns the ids of the
  /// ones Udyoga has not seen before.
  Future<List<String>> recordFound(
    List<({String hash, String name, String content})> files, {
    required String today,
  }) => db.transaction(() async {
    final known = {for (final d in await db.select(db.careerDocuments).get()) d.id};
    final added = <String>[];
    for (final f in files) {
      final id = documentId(f.hash);
      if (!known.add(id)) continue;
      await save(
        db.careerDocuments,
        CareerDocumentsCompanion.insert(
          id: id,
          hash: f.hash,
          name: f.name,
          content: Value(f.content.length > 60000 ? f.content.substring(0, 60000) : f.content),
          found: today,
        ),
        id,
      );
      added.add(id);
    }
    return added;
  });

  /// Stores what the AI read from a document, and drafts its stories into
  /// the bank (unconfirmed).
  Future<void> saveReading(CareerDocument d, DocumentReading r, {required String today}) =>
      db.transaction(() async {
        await save(
          db.careerDocuments,
          d.copyWith(
            kind: r.kind,
            summary: r.summary,
            facts: jsonEncode(r.facts.map((f) => f.toJson()).toList()),
            analysed: Value(today),
          ),
          d.id,
        );
        await addStories(r.stories, source: 'document', sourceId: d.id, today: today);
      });

  Future<void> setDocumentUse(CareerDocument d, bool use) =>
      save(db.careerDocuments, d.copyWith(use: use), d.id);

  static List<DocumentFact> factsOf(CareerDocument d) =>
      (decodeList(d.facts)).whereType<Map<String, Object?>>().map(DocumentFact.fromJson).toList();

  // ---- Profile questions ----

  Future<List<ProfileQuestion>> questions({String? status}) =>
      (db.select(db.careerQuestions)
            ..where(
              (q) => q.deleted.not() & (status == null ? const Constant(true) : q.status.equals(status)),
            )
            ..orderBy([(q) => OrderingTerm(expression: q.asked)]))
          .get();

  /// Adds new questions, skipping any whose topic is already open or settled.
  Future<int> addQuestions(List<QuestionDraft> drafts, {required String today}) => db.transaction(() async {
    final known = {for (final q in await questions()) q.topic.toLowerCase().trim()};
    var added = 0;
    for (final q in drafts) {
      if (q.question.isEmpty || !known.add(q.topic.toLowerCase().trim())) continue;
      final id = newId();
      await save(
        db.careerQuestions,
        CareerQuestionsCompanion.insert(
          id: id,
          topic: q.topic,
          question: q.question,
          why: Value(q.why),
          choices: Value(jsonEncode(q.choices)),
          asked: today,
        ),
        id,
      );
      added++;
    }
    return added;
  });

  Future<void> answerQuestion(ProfileQuestion q, String answer, {required String today}) => save(
    db.careerQuestions,
    q.copyWith(status: 'answered', answer: answer.trim(), answered: Value(today), applied: false),
    q.id,
  );

  Future<void> dismissQuestion(ProfileQuestion q, {required String today}) =>
      save(db.careerQuestions, q.copyWith(status: 'dismissed', answered: Value(today)), q.id);

  /// Answers not yet written into the profile, as "topic: answer".
  Future<List<ProfileQuestion>> unapplied() async =>
      (await questions(status: 'answered')).where((q) => !q.applied).toList();

  Future<void> markApplied(List<ProfileQuestion> qs) => db.transaction(() async {
    for (final q in qs) {
      await save(db.careerQuestions, q.copyWith(applied: true), q.id);
    }
  });

  /// Every settled point, for the AI: answered ones as facts, dismissed ones
  /// so they are not asked again.
  Future<List<String>> settled() async => [
    for (final q in await questions())
      if (q.status == 'answered')
        '${q.topic}: ${q.answer}'
      else if (q.status == 'dismissed')
        '${q.topic}: not relevant (do not ask)',
  ];

  // ---- Check-ins ----

  Future<CheckIn?> checkIn(String day) =>
      (db.select(db.careerJournal)
            ..where((c) => c.deleted.not() & c.day.equals(day))
            ..limit(1))
          .getSingleOrNull();

  Future<List<CheckIn>> journal({int limit = 60}) =>
      (db.select(db.careerJournal)
            ..where((c) => c.deleted.not())
            ..orderBy([(c) => OrderingTerm.desc(c.day)])
            ..limit(limit))
          .get();

  /// Today's question, kept so every device asks the same one.
  Future<CheckIn> askToday(String day, String prompt, {required String at}) async {
    final existing = await checkIn(day);
    if (existing != null) return existing;
    final id = newId();
    await save(db.careerJournal, CareerJournalCompanion.insert(id: id, day: day, prompt: prompt, at: at), id);
    return (await checkIn(day))!;
  }

  Future<void> answerCheckIn(CheckIn c, String entry, {required String at}) =>
      save(db.careerJournal, c.copyWith(entry: entry.trim(), at: at), c.id);

  /// Stores what the AI took from a check-in and files it: stories into the
  /// bank, achievements as wins, learning as suggestions.
  Future<void> saveDigest(CheckIn c, CheckInDigest d, {required String today}) => db.transaction(() async {
    await save(db.careerJournal, c.copyWith(digest: jsonEncode(d.toJson())), c.id);
    await addStories(d.stories, source: 'checkin', sourceId: c.id, today: today);
    final wins = {for (final n in await notes()) n.title.toLowerCase().trim()};
    for (final a in d.achievements) {
      if (a.isEmpty || !wins.add(a.toLowerCase().trim())) continue;
      await saveNote(kind: 'win', title: a, detail: 'From the check-in of ${c.day}', added: today);
    }
    for (final s in d.skills) {
      if (s.isEmpty || !wins.add(s.toLowerCase().trim())) continue;
      await saveNote(
        kind: 'idea',
        title: 'Skill shown: $s',
        detail: 'From the check-in of ${c.day}',
        added: today,
      );
    }
  });

  // ---- Stories ----

  Future<List<Story>> stories() =>
      (db.select(db.careerStories)
            ..where((s) => s.deleted.not())
            ..orderBy([(s) => OrderingTerm(expression: s.confirmed), (s) => OrderingTerm.desc(s.added)]))
          .get();

  /// Adds drafted stories, skipping titles already in the bank.
  Future<int> addStories(
    List<StoryDraft> drafts, {
    required String source,
    String? sourceId,
    required String today,
  }) async {
    final known = {for (final s in await stories()) s.title.toLowerCase().trim()};
    var added = 0;
    for (final s in drafts) {
      if (s.title.isEmpty || s.action.isEmpty || !known.add(s.title.toLowerCase().trim())) continue;
      final id = newId();
      await save(
        db.careerStories,
        CareerStoriesCompanion.insert(
          id: id,
          title: s.title,
          situation: Value(s.situation),
          task: Value(s.task),
          action: Value(s.action),
          result: Value(s.result),
          competencies: Value(jsonEncode(s.competencies)),
          source: Value(source),
          sourceId: Value(sourceId),
          added: today,
        ),
        id,
      );
      added++;
    }
    return added;
  }

  Future<void> saveStory(Story s) => save(db.careerStories, s, s.id);

  static List<String> competenciesOf(Story s) =>
      decodeList(s.competencies).whereType<String>().where(competencyNames.containsKey).toList();

  /// Stories per competency: confirmed, and drafts awaiting the candidate.
  Future<Map<String, ({int confirmed, int drafts})>> storyCounts() async {
    final counts = <String, ({int confirmed, int drafts})>{};
    for (final s in await stories()) {
      for (final c in competenciesOf(s)) {
        final n = counts[c] ?? (confirmed: 0, drafts: 0);
        counts[c] = s.confirmed
            ? (confirmed: n.confirmed + 1, drafts: n.drafts)
            : (confirmed: n.confirmed, drafts: n.drafts + 1);
      }
    }
    return counts;
  }

  // ---- Story uses (A4) ----

  Future<List<StoryUse>> storyUses() =>
      (db.select(db.careerStoryUses)
            ..where((u) => u.deleted.not())
            ..orderBy([(u) => OrderingTerm.desc(u.at)]))
          .get();

  /// Records that [s] went into an application, a supporting statement or
  /// an interview answer (kinds in storyUseKinds). Returns a warning when
  /// the story was already used with the same employer, else null. The
  /// same story for the same criterion of the same [refId] is logged once.
  Future<String?> useStory(
    Story s, {
    required String kind,
    String refId = '',
    String employer = '',
    String role = '',
    String criterion = '',
    required String at,
  }) async {
    final uses = await storyUses();
    final warning = reuseWarning(uses, storyId: s.id, employer: employer, refId: refId, criterion: criterion);
    final again = uses.any(
      (u) =>
          u.storyId == s.id &&
          u.kind == kind &&
          u.refId == refId &&
          u.criterion == criterion &&
          refId.isNotEmpty,
    );
    if (!again) {
      final id = newId();
      await save(
        db.careerStoryUses,
        CareerStoryUsesCompanion.insert(
          id: id,
          storyId: s.id,
          kind: kind,
          refId: Value(refId),
          employer: Value(employer),
          role: Value(role),
          criterion: Value(criterion),
          at: at,
        ),
        id,
      );
    }
    return warning;
  }

  /// Adds [tag] to [s] if it is not there yet.
  Future<void> tagStory(Story s, StoryTag tag) async {
    final tags = tagsOf(s);
    if (tags.contains(tag)) return;
    await saveStory(s.copyWith(tags: encodeTags([...tags, tag])));
  }

  /// The story bank in one line per story, for the AI.
  static String storyLine(Story s) => [
    '${s.title}${s.confirmed ? '' : ' (draft)'}:',
    if (s.situation.isNotEmpty) s.situation,
    s.action,
    if (s.result.isNotEmpty) 'Result: ${s.result}',
  ].join(' ');
}
