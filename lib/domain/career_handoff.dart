/// The career hand-off folder: career items that a helper app on this
/// computer writes for Udyoga (for example recruiter messages from a
/// social network the user reads in that app). Udyoga reads the folder,
/// imports what it understands into Conversations and files each read file
/// away. The format is in docs/handoff.md. Nothing here goes online; once
/// imported, the threads travel with Udyoga's own sync.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'conversations.dart';
import 'json.dart';
import 'linkedin_messages.dart' show closeInTime, similarText;

/// The format version this Udyoga reads. Lines of other versions are
/// skipped (left in the read file under done/), never guessed at.
const handoffVersion = 1;

/// Record kinds. Only messages are imported for now; the others are
/// reserved and skipped until Udyoga reads them.
const handoffKinds = {'message', 'job_alert', 'application_status', 'invite_accepted', 'profile_view'};

/// How long read files (done/) and refused lines (rejected/) are kept.
const handoffKeep = Duration(days: 30);

/// The hand-off folder for this computer's user, shared by Brahma apps:
/// `${XDG_DATA_HOME:-~/.local/share}/brahma/handoff/career` on Linux,
/// `%APPDATA%\brahma\handoff\career` on Windows and
/// `~/Library/Application Support/brahma/handoff/career` on macOS. Null on
/// phones, where there is no helper app.
String? defaultHandoffFolder({Map<String, String>? environment, String? os}) {
  final env = environment ?? Platform.environment;
  final system = os ?? Platform.operatingSystem;
  String join(String base, List<String> parts) => [base, ...parts].join(system == 'windows' ? r'\' : '/');
  switch (system) {
    case 'windows':
      final appData = env['APPDATA'];
      return appData == null || appData.isEmpty ? null : join(appData, ['brahma', 'handoff', 'career']);
    case 'macos':
      final home = env['HOME'];
      return home == null
          ? null
          : join(home, ['Library', 'Application Support', 'brahma', 'handoff', 'career']);
    case 'linux':
      final xdg = env['XDG_DATA_HOME'];
      final home = env['HOME'];
      final base = xdg != null && xdg.isNotEmpty ? xdg : (home == null ? null : '$home/.local/share');
      return base == null ? null : join(base, ['brahma', 'handoff', 'career']);
  }
  return null;
}

/// The other side of a helper's item.
class HandoffPeer {
  const HandoffPeer({this.name = '', this.headline = '', this.profileUrl = '', this.company = ''});
  final String name, headline, profileUrl, company;
}

/// A helper's scam check: none, caution or high, and the signs it found.
class HandoffScam {
  const HandoffScam({this.level = 'none', this.signs = const []});
  final String level;
  final List<String> signs;

  bool get flagged => level == 'caution' || level == 'high';

  static int _rank(String l) => switch (l) {
    'high' => 2,
    'caution' => 1,
    _ => 0,
  };

  /// The more severe level, with the signs of both, each once.
  HandoffScam merge(HandoffScam o) => HandoffScam(
    level: _rank(o.level) > _rank(level) ? o.level : level,
    signs: [
      ...{...signs, ...o.signs},
    ],
  );

  String toJson() => flagged ? jsonEncode({'level': level, 'signs': signs}) : '';

  /// Reads a thread's scam column ('' = none).
  static HandoffScam parse(String s) {
    final j = decodeObject(s);
    return HandoffScam(level: str(j['level']).isEmpty ? 'none' : str(j['level']), signs: strs(j['signs']));
  }
}

/// A thread's scam check, from its scam column.
HandoffScam threadScam(Conversation t) => HandoffScam.parse(t.scam);

/// Why a helper picked a thread, from its reasons column.
List<String> threadReasons(Conversation t) {
  return [for (final x in decodeList(t.reasons)) '$x'];
}

/// One line of a hand-off file that Udyoga can import.
class HandoffRecord {
  const HandoffRecord({
    required this.kind,
    required this.source,
    required this.id,
    required this.threadId,
    this.threadTitle = '',
    this.peer = const HandoffPeer(),
    this.subject = '',
    this.text = '',
    required this.sentAt,
    required this.direction,
    this.reasons = const [],
    this.scam = const HandoffScam(),
  });

  final String kind, source, id, threadId, threadTitle, subject, text, direction;
  final HandoffPeer peer;
  final DateTime sentAt;
  final List<String> reasons;
  final HandoffScam scam;

  /// Reads a record of [handoffVersion]; throws [FormatException] with the
  /// reason when a field is missing or wrong.
  factory HandoffRecord.fromJson(Map<String, dynamic> j) {
    String need(String k) {
      final v = j[k];
      if (v is! String || v.trim().isEmpty) throw FormatException('"$k" is missing');
      return v.trim();
    }

    String opt(Map<String, dynamic> m, String k) => m[k] is String ? (m[k] as String).trim() : '';
    final kind = need('kind');
    final direction = need('direction');
    if (direction != 'in' && direction != 'out') {
      throw const FormatException('"direction" must be "in" or "out"');
    }
    final at = DateTime.tryParse(need('sentAt'));
    if (at == null) throw const FormatException('"sentAt" is not an ISO 8601 time');
    final p = j['peer'] is Map ? (j['peer'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    final s = j['scam'] is Map ? (j['scam'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    final level = opt(s, 'level').isEmpty ? 'none' : opt(s, 'level');
    if (!{'none', 'caution', 'high'}.contains(level)) throw FormatException('unknown scam level "$level"');
    final text = opt(j, 'text');
    final subject = opt(j, 'subject');
    if (text.isEmpty && subject.isEmpty) throw const FormatException('no "text" or "subject"');
    return HandoffRecord(
      kind: kind,
      source: need('source'),
      id: need('id'),
      threadId: need('threadId'),
      threadTitle: opt(j, 'threadTitle'),
      peer: HandoffPeer(
        name: opt(p, 'name'),
        headline: opt(p, 'headline'),
        profileUrl: opt(p, 'profileUrl'),
        company: opt(p, 'company'),
      ),
      subject: subject,
      text: text,
      sentAt: at,
      direction: direction,
      reasons: strs(j['reasons']),
      scam: HandoffScam(level: level, signs: strs(s['signs'])),
    );
  }
}

/// What one pass over the folder did.
class HandoffReport {
  const HandoffReport({this.files = 0, this.imported = 0, this.skipped = 0, this.rejected = 0});
  final int files, imported, skipped, rejected;

  HandoffReport operator +(HandoffReport o) => HandoffReport(
    files: files + o.files,
    imported: imported + o.imported,
    skipped: skipped + o.skipped,
    rejected: rejected + o.rejected,
  );

  @override
  String toString() =>
      '$imported imported, $skipped skipped, $rejected refused from $files file${files == 1 ? '' : 's'}';
}

/// A line read from a file: a record to import, one to skip, or one to
/// refuse with its reason.
sealed class HandoffLine {
  const HandoffLine(this.number, this.raw);
  final int number;
  final String raw;
}

class GoodLine extends HandoffLine {
  const GoodLine(super.number, super.raw, this.record);
  final HandoffRecord record;
}

class SkippedLine extends HandoffLine {
  const SkippedLine(super.number, super.raw, this.why);
  final String why;
}

class BadLine extends HandoffLine {
  const BadLine(super.number, super.raw, this.reason);
  final String reason;
}

/// Sorts the lines of one hand-off file.
List<HandoffLine> readHandoffLines(String content) {
  final out = <HandoffLine>[];
  final lines = const LineSplitter().convert(content);
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    if (raw.trim().isEmpty) continue;
    final n = i + 1;
    Object? j;
    try {
      j = jsonDecode(raw);
    } on FormatException {
      out.add(BadLine(n, raw, 'not JSON'));
      continue;
    }
    if (j is! Map<String, dynamic>) {
      out.add(BadLine(n, raw, 'not a JSON object'));
      continue;
    }
    final v = j['v'];
    if (v is! int) {
      out.add(BadLine(n, raw, 'no format version "v"'));
      continue;
    }
    if (v != handoffVersion) {
      out.add(SkippedLine(n, raw, 'format version $v is not read by this Udyoga'));
      continue;
    }
    if (j['kind'] is String && j['kind'] != 'message') {
      out.add(
        SkippedLine(
          n,
          raw,
          handoffKinds.contains(j['kind'])
              ? 'kind "${j['kind']}" is not imported yet'
              : 'unknown kind "${j['kind']}"',
        ),
      );
      continue;
    }
    try {
      out.add(GoodLine(n, raw, HandoffRecord.fromJson(j)));
    } on FormatException catch (e) {
      out.add(BadLine(n, raw, e.message));
    }
  }
  return out;
}

String _minute(DateTime d) => d.toLocal().toIso8601String().substring(0, 16);

String _name(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

extension CareerHandoffBook on CareerBook {
  /// Imports a helper's message records into Conversations. Each helper
  /// thread is one thread (mode `helper`, the helper's thread id as its
  /// external id) and each message is stored once (its id as the
  /// message's external id); a message the user already logged by hand is
  /// not doubled. The person is found by profile link, then by a unique
  /// name; anyone else waits in the Screener. People marked "do not
  /// contact" are skipped. The helper's scam check and reasons are kept on
  /// the thread, the most severe check winning. Returns (imported,
  /// skipped).
  Future<({int imported, int skipped})> importHandoffRecords(
    List<HandoffRecord> records, {
    required String today,
  }) async {
    final people = await (db.select(db.careerContacts)..where((c) => c.deleted.not())).get();
    final handles = await (db.select(db.contactHandles)..where((h) => h.deleted.not())).get();
    final blocked = suppressionKeys(people, handles);
    final byId = {for (final p in people) p.id: p};
    final byUrl = <String, Lead>{
      for (final p in people)
        if (p.linkedin.trim().isNotEmpty) handleKey('linkedin', p.linkedin): p,
    };
    for (final h in handles) {
      if (byId[h.contactId] != null && h.handle.trim().isNotEmpty) {
        byUrl.putIfAbsent(handleKey(h.channel, h.handle), () => byId[h.contactId]!);
      }
    }
    final byName = <String, List<Lead>>{};
    for (final p in people) {
      (byName[_name(p.name)] ??= []).add(p);
    }

    var imported = 0, skipped = 0;
    final touched = <String>{};
    for (final r in records) {
      if (r.kind != 'message') {
        skipped++;
        continue;
      }
      final channel = channelNames.containsKey(r.source) ? r.source : 'other';
      final url = r.peer.profileUrl;
      final named = byName[_name(r.peer.name)];
      final c =
          (url.isEmpty ? null : byUrl[handleKey(channel, url)]) ??
          (r.peer.name.isNotEmpty && named?.length == 1 ? named!.single : null);
      if ((c?.doNotContact ?? false) || (url.isNotEmpty && blocked.contains(handleKey(channel, url)))) {
        skipped++;
        continue;
      }
      final at = _minute(r.sentAt);
      var t = await threadByExternalId(channel, r.threadId);
      if (t == null && c != null) {
        // A thread with this person logged by hand takes the helper's id.
        final mine = (await conversationsOf(c.id))
            .where((t) => t.channel == channel && t.externalId == null && t.mode == 'manual')
            .firstOrNull;
        if (mine != null) {
          t = mine.copyWith(externalId: Value(r.threadId));
          await save(db.conversations, t, t.id);
        }
      }
      final id =
          t?.id ??
          await startConversation(
            contactId: c?.id,
            channel: channel,
            mode: 'helper',
            // An unknown sender's thread is named after them, as imports are.
            subject: c == null ? (r.peer.name.isEmpty ? r.threadTitle : r.peer.name) : r.subject,
            peer: c == null ? (url.isEmpty ? r.peer.name : url) : '',
            externalId: r.threadId,
            at: at,
          );
      final thread = await conversation(id);
      final logged = [
        for (final m in await messagesIn(id))
          if (m.source != 'helper') m,
      ];
      var body = r.text;
      if (r.subject.isNotEmpty && thread.subject != r.subject) {
        body = body.isEmpty ? r.subject : '${r.subject}\n\n$body';
      }
      final dup = logged.any(
        (l) => l.direction == r.direction && closeInTime(l.sentAt, at) && similarText(l.body, r.text),
      );
      final put = dup
          ? null
          : await addMessage(
              id,
              direction: r.direction,
              body: body,
              at: at,
              source: 'helper',
              externalId: r.id,
            );
      if (put != null) {
        imported++;
        touched.add(id);
      } else {
        skipped++;
      }
      // The thread keeps the most severe scam check and every reason.
      final fresh = await conversation(id);
      final scam = threadScam(fresh).merge(r.scam).toJson();
      final reasons = [
        ...{...threadReasons(fresh), ...r.reasons},
      ];
      final reasonsJson = reasons.isEmpty ? '' : jsonEncode(reasons);
      if (scam != fresh.scam || reasonsJson != fresh.reasons) {
        await save(db.conversations, fresh.copyWith(scam: scam, reasons: reasonsJson), id);
      }
    }
    for (final id in touched) {
      final t = await conversation(id);
      if (t.contactId != null) await refreshContact(t.contactId!, today: today);
    }
    return (imported: imported, skipped: skipped);
  }
}

/// The hand-off folder on this computer: reads inbox/, files each read file
/// under done/, refused lines under rejected/ (with the reason), and drops
/// both after [handoffKeep].
class HandoffFolder {
  HandoffFolder(this.path);
  final String path;

  String _p(String sub, [String? name]) => [path, sub, ?name].join(Platform.pathSeparator);

  /// Imports every file waiting in inbox/, oldest first.
  Future<HandoffReport> run(CareerBook book, {required String today, DateTime? now}) async {
    final inbox = Directory(_p('inbox'));
    var report = const HandoffReport();
    if (await inbox.exists()) {
      final files = [
        await for (final e in inbox.list())
          if (e is File && e.path.endsWith('.jsonl')) e,
      ]..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        report += await _one(book, f, today: today);
      }
    }
    await _prune(now ?? DateTime.now());
    return report;
  }

  Future<HandoffReport> _one(CareerBook book, File f, {required String today}) async {
    final name = f.uri.pathSegments.last;
    final String content;
    try {
      content = await f.readAsString();
    } on FileSystemException {
      return const HandoffReport(); // gone (another reader) or still locked: next time
    } on FormatException {
      await _reject(name, [BadLine(0, '', 'the file is not UTF-8')]);
      await _move(f, name);
      return const HandoffReport(files: 1, rejected: 1);
    }
    final lines = readHandoffLines(content);
    final good = [for (final l in lines.whereType<GoodLine>()) l.record];
    final bad = lines.whereType<BadLine>().toList();
    final skippedLines = lines.whereType<SkippedLine>().length;
    final r = await book.importHandoffRecords(good, today: today);
    if (bad.isNotEmpty) await _reject(name, bad);
    await _move(f, name);
    return HandoffReport(
      files: 1,
      imported: r.imported,
      skipped: r.skipped + skippedLines,
      rejected: bad.length,
    );
  }

  Future<void> _reject(String name, List<BadLine> bad) async {
    await Directory(_p('rejected')).create(recursive: true);
    final out = File(_p('rejected', name));
    await out.writeAsString(
      '${bad.map((b) => jsonEncode({'line': b.number, 'reason': b.reason, 'text': b.raw})).join('\n')}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<void> _move(File f, String name) async {
    await Directory(_p('done')).create(recursive: true);
    var target = _p('done', name);
    if (await File(target).exists()) target = _p('done', '${DateTime.now().microsecondsSinceEpoch}-$name');
    try {
      await f.rename(target);
    } on FileSystemException {
      // Another reader moved it first; its lines are stored once anyway.
    }
  }

  Future<void> _prune(DateTime now) async {
    for (final sub in ['done', 'rejected']) {
      final d = Directory(_p(sub));
      if (!await d.exists()) continue;
      await for (final e in d.list()) {
        if (e is! File) continue;
        try {
          if (now.difference(await e.lastModified()) > handoffKeep) await e.delete();
        } on FileSystemException {
          // Left for the next pass.
        }
      }
    }
  }
}
