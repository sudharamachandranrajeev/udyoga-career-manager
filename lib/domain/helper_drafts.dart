/// LinkedIn messages sent through a helper app on this computer (format v1
/// additions in docs/handoff.md). Udyoga leaves a draft in the hand-off
/// folder's outbox/; the helper app shows it to the user, who checks it and
/// presses Send there (nothing is sent without that). The helper answers in
/// `status/<id>.json`, and keeps status.json with the LinkedIn budget it has
/// left, which Udyoga shows instead of its own count while it is fresh.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha1;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'conversations.dart';
import 'json.dart';

/// Draft ids are the message's id with this prefix, so an answer finds its
/// message again.
const helperDraftPrefix = 'udyoga-';

/// How old status.json may be and still count: the helper rewrites it at
/// least every minute while it runs.
const helperStatusFresh = Duration(minutes: 5);

/// The helper's limit for a LinkedIn message's text.
const helperMaxText = 4000;

/// The job application a draft is about, shown on the helper's card.
class DraftApplication {
  const DraftApplication({this.id = '', this.title = '', this.company = ''});
  final String id, title, company;

  bool get isEmpty => id.isEmpty && title.isEmpty && company.isEmpty;

  Map<String, Object?> toJson() => {
    if (id.isNotEmpty) 'id': id,
    if (title.isNotEmpty) 'title': title,
    if (company.isNotEmpty) 'company': company,
  };
}

/// One outbox file (`outbox/<id>.json`).
class HelperDraft {
  const HelperDraft({
    required this.id,
    required this.createdAt,
    required this.toName,
    required this.profileUrl,
    required this.text,
    this.threadId = '',
    this.application = const DraftApplication(),
  });

  final String id, toName, profileUrl, text, threadId;
  final DateTime createdAt;
  final DraftApplication application;

  /// The file's content: one JSON object, fields in a fixed order, and a
  /// newline.
  String encode() =>
      '${jsonEncode({
        'v': 1,
        'kind': 'message',
        'id': id,
        'source': 'linkedin',
        'createdAt': utcStamp(createdAt),
        'to': {if (toName.isNotEmpty) 'name': toName, 'profileUrl': profileUrl},
        if (threadId.isNotEmpty) 'threadId': threadId,
        'text': text,
        if (!application.isEmpty) 'application': application.toJson(),
      })}\n';
}

/// A time as the hand-off files carry it: UTC, to the second.
String utcStamp(DateTime d) => '${d.toUtc().toIso8601String().substring(0, 19)}Z';

String _join(String folder, List<String> parts) => [folder, ...parts].join(Platform.pathSeparator);

/// Writes [d] to the folder's outbox/ whole: under tmp/ first, then renamed
/// in, so the helper never reads half a file. Writing the same draft again
/// leaves the same file.
Future<void> writeHelperDraft(String folder, HelperDraft d) async {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(d.id)) {
    throw ArgumentError('not a safe draft id: ${d.id}');
  }
  final tmp = Directory(_join(folder, ['tmp']));
  final outbox = Directory(_join(folder, ['outbox']));
  await tmp.create(recursive: true);
  await outbox.create(recursive: true);
  final part = File(_join(folder, ['tmp', '${d.id}.json.${DateTime.now().microsecondsSinceEpoch}.part']));
  try {
    await part.writeAsString(d.encode(), flush: true);
    await part.rename(_join(folder, ['outbox', '${d.id}.json']));
  } finally {
    if (await part.exists()) await part.delete();
  }
}

// ---- the helper's answers ----

/// The helper's state for one network, from status.json.
class HelperChannel {
  const HelperChannel({required this.drafts, required this.state, this.messages, this.invites});
  final bool drafts;

  /// ok | needs-login | halted | none
  final String state;
  final Allowance? messages, invites;
}

/// status.json: the helper is alive, and what it has left.
class HelperStatus {
  const HelperStatus({required this.updatedAt, this.channels = const {}});
  final DateTime updatedAt;
  final Map<String, HelperChannel> channels;

  /// Fresh: written in the last [helperStatusFresh] (and not from the future).
  bool fresh(DateTime now) {
    final age = now.difference(updatedAt);
    return age < helperStatusFresh && age > -helperStatusFresh;
  }

  /// The channel when status.json is fresh and the helper takes drafts for
  /// it; else null.
  HelperChannel? usable(String channel, DateTime now) {
    final c = channels[channel];
    return fresh(now) && c != null && c.drafts ? c : null;
  }

  /// Reads status.json's content; null when it is not version 1 or is
  /// broken.
  static HelperStatus? parse(String content) {
    final j = decodeObject(content);
    if (j['v'] != 1) return null;
    final at = DateTime.tryParse(str(j['updatedAt']));
    if (at == null) return null;
    Allowance? budget(Object? b) {
      if (b is! Map) return null;
      int n(String k) => b[k] is int ? b[k] as int : -1;
      return (
        dayLeft: n('dayLeft'),
        dayLimit: n('dayLimit'),
        weekLeft: n('weekLeft'),
        weekLimit: n('weekLimit'),
      );
    }

    final chans = <String, HelperChannel>{};
    final cs = j['channels'];
    if (cs is Map) {
      for (final e in cs.entries) {
        final c = e.value;
        if (e.key is! String || c is! Map) continue;
        final b = c['budget'] is Map ? c['budget'] as Map : const {};
        chans[e.key as String] = HelperChannel(
          drafts: c['drafts'] == true,
          state: c['state'] is String ? c['state'] as String : '',
          messages: budget(b['message']),
          invites: budget(b['invite']),
        );
      }
    }
    return HelperStatus(updatedAt: at, channels: chans);
  }
}

/// Reads the folder's status.json, or null when there is none (or it is
/// broken).
Future<HelperStatus?> readHelperStatus(String folder) async {
  try {
    return HelperStatus.parse(await File(_join(folder, ['status.json'])).readAsString());
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

/// One draft's answer (`status/<id>.json`).
class DraftStatus {
  const DraftStatus({
    required this.id,
    required this.state,
    this.reason = '',
    this.sentAt,
    this.text = '',
    this.messageId = '',
    this.threadId = '',
  });

  /// pending | waiting | sending | sent | failed | cancelled
  final String id, state, reason, text, messageId, threadId;
  final DateTime? sentAt;

  static const states = {'pending', 'waiting', 'sending', 'sent', 'failed', 'cancelled'};

  static DraftStatus? parse(String content) {
    final j = decodeObject(content);
    final id = str(j['id']);
    final state = str(j['state']);
    if (j['v'] != 1 || id.isEmpty || !states.contains(state)) return null;
    return DraftStatus(
      id: id,
      state: state,
      reason: str(j['reason']),
      sentAt: DateTime.tryParse(str(j['sentAt'])),
      text: str(j['text']),
      messageId: str(j['messageId']),
      threadId: str(j['threadId']),
    );
  }
}

/// A person's LinkedIn profile link, from their record, the thread or their
/// handles; null when there is none.
String? helperProfileUrl(Conversation t, Lead c, List<ContactHandle> handles) {
  bool profile(String s) => RegExp(r'linkedin\.com/in/[^/?#\s]+', caseSensitive: false).hasMatch(s);
  for (final u in [
    c.linkedin,
    t.peer,
    for (final h in handles)
      if (h.channel == 'linkedin') h.handle,
  ]) {
    final s = u.trim();
    if (profile(s)) return s.startsWith('http') ? s : 'https://$s';
  }
  return null;
}

String _local(DateTime d) => d.toLocal().toIso8601String().substring(0, 16);

String _short(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

extension HelperDraftsBook on CareerBook {
  /// Leaves [body] for the helper app to send on LinkedIn, after the user
  /// checks it there. The message is in the thread at once (from the
  /// helper, queued); the helper's answers move it on.
  Future<String> sendViaHelper(
    String folder,
    String conversationId,
    String body, {
    required DateTime now,
  }) async {
    final t = await conversation(conversationId);
    if (t.channel != 'linkedin') throw StateError('The helper app sends LinkedIn messages only.');
    final c = t.contactId == null ? null : await contact(t.contactId!);
    if (c == null) throw StateError('Add this person to your contacts before writing to them.');
    if (c.doNotContact) throw DoNotContactException(c.name);
    final url = helperProfileUrl(t, c, await handlesOf(c.id));
    if (url == null) {
      throw StateError('Add ${c.name}\'s LinkedIn profile link first; the helper app sends to a profile.');
    }
    final text = body.trim();
    if (text.isEmpty) throw StateError('Write the message first.');
    if (text.runes.length > helperMaxText) {
      throw StateError('Messages through the helper app are up to 4,000 characters.');
    }
    final id = (await addMessage(
      conversationId,
      direction: 'out',
      body: text,
      at: _local(now),
      source: 'helper',
      status: 'queued',
    ))!;
    try {
      await writeHelperDraft(
        folder,
        HelperDraft(
          id: '$helperDraftPrefix$id',
          createdAt: now,
          toName: c.name,
          profileUrl: url,
          threadId: t.externalId ?? '',
          text: text,
          application: await _applicationFor(t.jobId ?? c.jobId),
        ),
      );
    } catch (_) {
      final m = await (db.select(db.messages)..where((m) => m.id.equals(id))).getSingle();
      await save(db.messages, m.copyWith(status: 'failed'), id);
      rethrow;
    }
    return id;
  }

  Future<DraftApplication> _applicationFor(String? jobId) async {
    if (jobId == null) return const DraftApplication();
    final a =
        await (db.select(db.jobApplications)
              ..where((a) => a.jobId.equals(jobId) & a.deleted.not())
              ..limit(1))
            .getSingleOrNull();
    if (a != null) return DraftApplication(id: a.id, title: a.title, company: a.company);
    final j = await (db.select(db.jobListings)..where((j) => j.id.equals(jobId))).getSingleOrNull();
    return j == null
        ? const DraftApplication()
        : DraftApplication(id: j.id, title: j.title, company: j.company);
  }

  /// Reads the helper's answers in status/ and moves each message on: sent
  /// (with the text that went, and LinkedIn's ids so a later hand-off of
  /// the same message is not stored twice), waiting or failed (with a note
  /// giving the reason, once), or cancelled. Returns how many messages
  /// changed.
  Future<int> importHelperStatuses(String folder, {DateTime? now}) async {
    final dir = Directory(_join(folder, ['status']));
    if (!await dir.exists()) return 0;
    var changed = 0;
    final files = [
      await for (final e in dir.list())
        if (e is File && e.path.endsWith('.json')) e,
    ]..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      DraftStatus? s;
      try {
        s = DraftStatus.parse(await f.readAsString());
      } on FileSystemException {
        continue;
      } on FormatException {
        continue;
      }
      if (s == null || !s.id.startsWith(helperDraftPrefix)) continue;
      if (await applyHelperStatus(s, now: now ?? DateTime.now())) changed++;
    }
    return changed;
  }

  /// Applies one answer; true when the message changed.
  Future<bool> applyHelperStatus(DraftStatus s, {required DateTime now}) => db.transaction(() async {
    final id = s.id.substring(helperDraftPrefix.length);
    final m = await (db.select(
      db.messages,
    )..where((m) => m.id.equals(id) & m.deleted.not() & m.source.equals('helper'))).getSingleOrNull();
    if (m == null) return false;
    final status = s.state == 'pending' ? 'queued' : s.state;
    var next = m.copyWith(status: status);
    if (s.state == 'sent') {
      if (s.text.isNotEmpty) next = next.copyWith(body: s.text);
      if (s.sentAt != null) next = next.copyWith(sentAt: _local(s.sentAt!));
      if (s.messageId.isNotEmpty) {
        next = next.copyWith(externalId: Value(s.messageId));
        // The same message handed off as a career item first: kept once.
        final twins =
            await (db.select(db.messages)..where(
                  (x) =>
                      x.conversationId.equals(m.conversationId) &
                      x.externalId.equals(s.messageId) &
                      x.id.equals(m.id).not() &
                      x.deleted.not(),
                ))
                .get();
        for (final x in twins) {
          await remove(db.messages, x.id);
        }
      }
      if (s.threadId.isNotEmpty) {
        final t = await conversation(m.conversationId);
        if (t.externalId == null && await threadByExternalId(t.channel, s.threadId) == null) {
          await save(db.conversations, t.copyWith(externalId: Value(s.threadId)), t.id);
        }
      }
    }
    final moved = next != m;
    if (moved) await save(db.messages, next, m.id);
    // The reason, once per reason, as a note in the thread.
    final note = switch (s.state) {
      'failed' => 'The helper app could not send this: ${s.reason.isEmpty ? 'no reason given' : s.reason}',
      'waiting' when s.reason.isNotEmpty => 'The helper app is holding this: ${s.reason}',
      _ => null,
    };
    if (note != null) {
      await addMessage(
        m.conversationId,
        direction: 'note',
        body: note,
        at: _local(now),
        source: 'helper',
        status: 'logged',
        externalId: 'helper-status:${s.id}:${s.state}:${_short(s.reason)}',
      );
    }
    return moved;
  });
}
