import 'dart:convert';

import '../db/database.dart';
import 'advisor.dart';
import 'book.dart';
import 'career_file.dart';
import 'companion.dart';
import 'companion_book.dart';
import 'documents.dart';
import 'json.dart';

/// What a folder scan did.
class ScanReport {
  const ScanReport({
    this.found = 0,
    this.added = 0,
    this.read = 0,
    this.questions = 0,
    this.profileFilled = false,
  });
  final int found, added, read, questions;
  final bool profileFilled;

  String get summary => [
    '$found documents found',
    if (added > 0) '$added new',
    if (read > 0) '$read read',
    if (profileFilled) 'profile filled in from your CVs',
    if (questions > 0) '$questions questions to confirm',
  ].join(', ');
}

/// Runs the companion: reads the candidate's documents into the profile,
/// asks what needs confirming, and keeps the daily check-in.
class Companion {
  Companion(this.book, {this.advisor});
  final CareerBook book;

  /// Null when no AI is set up: documents are still found and listed, and
  /// the check-in uses its built-in questions.
  final Advisor? advisor;

  /// Finds documents in [folders], reads the new ones, fills an empty
  /// profile from the CVs among them, and asks what needs confirming.
  Future<ScanReport> scan(
    List<String> folders, {
    required String today,
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Looking through your folders…');
    try {
      await CareerFile(book).applyFrom(folders, today: today);
    } on Object {
      // A broken settings file must not stop the documents being read; the
      // routine refresh reports it.
    }
    final files = await scanFolders(folders);
    final byHash = {for (final f in files) f.hash: f};
    final added = await book.recordFound([
      for (final f in byHash.values) (hash: f.hash, name: f.name, content: f.text),
    ], today: today);
    final ai = advisor;
    if (ai == null) return ScanReport(found: byHash.length, added: added.length);

    // Read what has not been read yet, and is on this device to read.
    final waiting = [
      for (final d in await book.documents())
        if (d.use && d.analysed == null && byHash.containsKey(d.hash)) d,
    ];
    var read = 0;
    var profile = await book.profile();
    for (final batch in _batches(waiting, byHash)) {
      onProgress?.call('Reading ${read + 1}–${read + batch.length} of ${waiting.length}…');
      final readings = await ai.readDocuments(profile, [for (final d in batch) _source(byHash[d.hash]!)]);
      for (final d in batch) {
        final r = readings.where((r) => r.name == byHash[d.hash]!.name).firstOrNull;
        if (r != null) await book.saveReading(d, r, today: today);
      }
      read += batch.length;
    }

    // An empty profile is filled from the CVs found (newest few).
    var filled = false;
    if (profile.isEmpty) {
      final cvs = [
        for (final d in await book.documents())
          if (d.use && d.kind == 'cv' && byHash.containsKey(d.hash)) byHash[d.hash]!,
      ].take(4).toList();
      if (cvs.isNotEmpty) {
        onProgress?.call('Filling in your profile from ${cvs.length} CVs…');
        final p = await ai.readCv([for (final f in cvs) _source(f)]);
        await book.saveProfile(p);
        filled = true;
      }
    }

    // What needs the candidate to confirm.
    var asked = 0;
    if (read > 0 || filled) {
      onProgress?.call('Checking your profile against your documents…');
      profile = await book.profile();
      final docs = [
        for (final d in await book.documents())
          if (d.use && d.analysed != null) (name: d.name, kind: d.kind, facts: CompanionBook.factsOf(d)),
      ];
      final drafts = await ai.profileQuestions(profile, documents: docs, settled: await book.settled());
      asked = await book.addQuestions(drafts, today: today);
    }
    return ScanReport(
      found: byHash.length,
      added: added.length,
      read: read,
      questions: asked,
      profileFilled: filled,
    );
  }

  /// Writes the candidate's answers into the profile. Returns how many.
  Future<int> applyAnswers() async {
    final ai = advisor;
    final answers = await book.unapplied();
    if (ai == null || answers.isEmpty) return 0;
    final p = await book.profile();
    final revised = await ai.reviseProfile(p, [for (final q in answers) '${q.topic}: ${q.answer}']);
    await book.saveProfile(revised);
    await book.markApplied(answers);
    return answers.length;
  }

  /// Today's check-in, asking the question once per day across devices.
  Future<CheckIn> today(String day, {required String at}) async {
    final existing = await book.checkIn(day);
    if (existing != null) return existing;
    final counts = await book.storyCounts();
    final weakest = weakestCompetency({
      for (final e in counts.entries) e.key: e.value.confirmed + e.value.drafts,
    }, day: day);
    final recent = await book.journal(limit: 7);
    final followUp = recent
        .map((c) => CheckInDigest.fromJson(decodeObject(c.digest)).nextQuestion)
        .firstWhere((q) => q.isNotEmpty, orElse: () => '');
    var question = followUp.isNotEmpty ? followUp : checkInQuestions[weakest]!;
    final ai = advisor;
    if (ai != null) {
      try {
        final q = await ai.checkInQuestion(
          await book.profile(),
          weakest: weakest,
          recent: [
            for (final c in recent)
              if (c.entry.isNotEmpty) '${c.day}: ${c.prompt} → ${c.entry}',
          ],
          followUp: followUp,
        );
        if (q.isNotEmpty) question = q;
      } catch (_) {
        // The built-in question is a fine fallback; the check-in must not fail.
      }
    }
    return book.askToday(day, question, at: at);
  }

  /// Saves the answer and, with the AI, files what it adds.
  Future<CheckInDigest?> answer(CheckIn c, String entry, {required String today, required String at}) async {
    await book.answerCheckIn(c, entry, at: at);
    final ai = advisor;
    if (ai == null || entry.trim().isEmpty) return null;
    final d = await ai.digestCheckIn(await book.profile(), question: c.prompt, answer: entry);
    final saved = await book.checkIn(c.day);
    await book.saveDigest(saved ?? c, d, today: today);
    return d;
  }

  static CvSource _source(FoundDocument f) =>
      f.isPdf ? PdfCv(f.bytes, name: f.name) : TextCv(f.text, name: f.name);

  /// Up to four documents and about 8 MB per request.
  static Iterable<List<CareerDocument>> _batches(
    List<CareerDocument> docs,
    Map<String, FoundDocument> files,
  ) sync* {
    var batch = <CareerDocument>[];
    var bytes = 0;
    for (final d in docs) {
      final size = files[d.hash]!.isPdf
          ? files[d.hash]!.bytes.length * 4 ~/ 3
          : utf8.encode(d.content).length;
      if (batch.isNotEmpty && (batch.length == 4 || bytes + size > 8 * 1024 * 1024)) {
        yield batch;
        batch = [];
        bytes = 0;
      }
      batch.add(d);
      bytes += size;
    }
    if (batch.isNotEmpty) yield batch;
  }
}
