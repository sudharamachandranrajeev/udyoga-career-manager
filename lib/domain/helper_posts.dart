/// LinkedIn posts through a helper app on this computer (format v1
/// additions in docs/handoff.md). A finished post or carousel from the
/// LinkedIn studio goes to the hand-off folder: its files under
/// `files/<id>/`, then the post itself in outbox/. The helper shows it to
/// the user, who checks it and taps Post there (or sets the time there).
/// Nothing is posted without that tap. The helper answers in
/// `status/<id>.json`; the answer goes on the studio draft: posted (with
/// its link), scheduled, waiting or failed (with the reason).
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import 'book.dart';
import 'helper_drafts.dart';
import 'humanizer.dart';
import 'json.dart';
import 'linkedin.dart';

/// Post ids start with this, so an answer finds its studio draft again.
const helperPostPrefix = 'udyoga-post-';

/// LinkedIn's limit for a post's text.
const helperPostMaxText = 3000;

/// One file of a post: a picture or a document (a carousel's PDF).
class HelperPostFile {
  const HelperPostFile({required this.name, required this.type, required this.bytes, this.title = ''});

  /// The file's name inside `files/<id>/`.
  final String name;

  /// image | document
  final String type;
  final String title;
  final Uint8List bytes;
}

/// Which studio draft a post came from, for the helper's card.
class PostReportRef {
  const PostReportRef({required this.id, required this.tool, this.title = ''});
  final String id, tool, title;

  Map<String, Object?> toJson() => {'id': id, 'tool': tool, if (title.isNotEmpty) 'title': title};
}

/// One outbox post (`outbox/<id>.json`, kind "post").
class HelperPost {
  const HelperPost({
    required this.id,
    required this.createdAt,
    required this.text,
    this.visibility = 'anyone',
    this.files = const [],
    this.scheduleAt,
    this.report,
  });

  final String id, text;

  /// anyone | connections
  final String visibility;
  final DateTime createdAt;
  final List<HelperPostFile> files;

  /// When the user would like it out: a wish the helper offers on its card,
  /// never a time anything posts by itself.
  final DateTime? scheduleAt;
  final PostReportRef? report;

  /// The file's content: one JSON object, fields in a fixed order, and a
  /// newline.
  String encode() =>
      '${jsonEncode({
        'v': 1,
        'kind': 'post',
        'id': id,
        'source': 'linkedin',
        'createdAt': utcStamp(createdAt),
        'text': text,
        'visibility': visibility,
        if (files.isNotEmpty) 'attachments': [
            for (final f in files) {'path': 'files/$id/${f.name}', 'type': f.type, if (f.title.isNotEmpty) 'title': f.title},
          ],
        if (scheduleAt != null) 'scheduleAt': utcStamp(scheduleAt!),
        if (report != null) 'report': report!.toJson(),
      })}\n';
}

/// Writes [p] to the hand-off folder: its files first, each whole, then the
/// post, so the helper never sees a post whose files are not there yet.
Future<void> writeHelperPost(String folder, HelperPost p) async {
  if (!safeHandoffName.hasMatch(p.id)) throw ArgumentError('not a safe post id: ${p.id}');
  for (final f in p.files) {
    if (!safeHandoffName.hasMatch(f.name)) throw ArgumentError('not a safe file name: ${f.name}');
    await writeHandoffFile(folder, ['files', p.id, f.name], f.bytes);
  }
  await writeHandoffFile(folder, ['outbox', '${p.id}.json'], utf8.encode(p.encode()));
}

/// One post's answer (`status/<id>.json`, kind "post").
class PostStatus {
  const PostStatus({
    required this.id,
    required this.state,
    this.reason = '',
    this.url = '',
    this.text = '',
    this.postedAt,
    this.scheduledAt,
    this.remindAt,
  });

  /// pending | waiting | posting | scheduled | posted | failed | cancelled
  final String id, state, reason, url, text;
  final DateTime? postedAt, scheduledAt, remindAt;

  static const states = {'pending', 'waiting', 'posting', 'scheduled', 'posted', 'failed', 'cancelled'};

  static PostStatus? parse(String content) {
    final j = decodeObject(content);
    final id = str(j['id']);
    final state = str(j['state']);
    if (j['v'] != 1 || j['kind'] != 'post' || !id.startsWith(helperPostPrefix) || !states.contains(state)) {
      return null;
    }
    final url = str(j['url']);
    return PostStatus(
      id: id,
      state: state,
      reason: str(j['reason']),
      // Only a link to LinkedIn is kept.
      url: RegExp(r'^https://([a-z0-9-]+\.)*linkedin\.com/').hasMatch(url) ? url : '',
      text: str(j['text']),
      postedAt: DateTime.tryParse(str(j['postedAt'])),
      scheduledAt: DateTime.tryParse(str(j['scheduledAt'])),
      remindAt: DateTime.tryParse(str(j['remindAt'])),
    );
  }

  /// What the studio draft keeps (content['helper']).
  Json toJson() => {
    'id': id,
    'state': state,
    if (reason.isNotEmpty) 'reason': reason,
    if (url.isNotEmpty) 'url': url,
    if (postedAt != null) 'postedAt': utcStamp(postedAt!),
    if (scheduledAt != null) 'scheduledAt': utcStamp(scheduledAt!),
    if (remindAt != null) 'remindAt': utcStamp(remindAt!),
  };
}

/// The text a studio draft posts: its first block to paste, as the Copy
/// button gives it (the human check's clean text).
String postTextOf(Json content) {
  final b = objs(content['sections'])
      .expand((s) => objs(s['blocks']))
      .where((b) => b['copy'] == true)
      .firstOrNull;
  return humanize(str(b?['text'])).text.trim();
}

/// A studio draft's hand-off state (content['helper']), or null.
Json? helperPostOf(Json content) =>
    content['helper'] is Map ? Map<String, Object?>.from(content['helper'] as Map) : null;

extension HelperPostsBook on CareerBook {
  /// Leaves the studio draft [reportId] for the helper app to post, after
  /// the user checks it there. [pdf] is a carousel's document. Returns the
  /// post's id.
  Future<String> sendPostViaHelper(
    String folder,
    String reportId, {
    required DateTime now,
    String visibility = 'anyone',
    DateTime? scheduleAt,
    Uint8List? pdf,
    String pdfTitle = '',
  }) async {
    final r = await (db.select(
      db.careerReports,
    )..where((r) => r.id.equals(reportId) & r.deleted.not())).getSingle();
    final tool = LinkedInTool.ofKind(r.kind);
    if (tool != LinkedInTool.post && tool != LinkedInTool.carousel) {
      throw StateError('Only posts and carousels go to the helper app.');
    }
    final content = decodeObject(r.content);
    final text = postTextOf(content);
    if (text.isEmpty && pdf == null) throw StateError('This draft has no text to post.');
    if (text.runes.length > helperPostMaxText) throw StateError('LinkedIn posts are up to 3,000 characters.');
    if (visibility != 'anyone' && visibility != 'connections') throw ArgumentError('visibility: $visibility');
    final stamp = utcStamp(now).replaceAll(RegExp(r'[^0-9]'), '');
    final id = '$helperPostPrefix$reportId-$stamp';
    final title = pdfTitle.trim();
    final post = HelperPost(
      id: id,
      createdAt: now,
      text: text,
      visibility: visibility,
      scheduleAt: scheduleAt,
      files: [
        if (pdf != null) HelperPostFile(name: 'carousel.pdf', type: 'document', title: title, bytes: pdf),
      ],
      report: PostReportRef(id: reportId, tool: tool!.name, title: str(content['headline'])),
    );
    await writeHelperPost(folder, post);
    await save(
      db.careerReports,
      r.copyWith(
        content: jsonEncode({...content, 'helper': PostStatus(id: id, state: 'pending').toJson()}),
      ),
      r.id,
    );
    return id;
  }

  /// Reads the helper's answers to posts in status/ and puts each on its
  /// studio draft; a post that went live is marked posted, with its link.
  /// Returns how many drafts changed.
  Future<int> importHelperPostStatuses(String folder) async {
    final dir = Directory([folder, 'status'].join(Platform.pathSeparator));
    if (!await dir.exists()) return 0;
    final answers = <String, PostStatus>{};
    await for (final e in dir.list()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      final name = e.uri.pathSegments.last;
      if (!name.startsWith(helperPostPrefix)) continue;
      try {
        final s = PostStatus.parse(await e.readAsString());
        if (s != null && '${s.id}.json' == name) answers[s.id] = s;
      } on FileSystemException {
        continue;
      } on FormatException {
        continue;
      }
    }
    if (answers.isEmpty) return 0;
    var changed = 0;
    final rows =
        await (db.select(db.careerReports)..where(
              (r) => r.kind.isIn([LinkedInTool.post.kind, LinkedInTool.carousel.kind]) & r.deleted.not(),
            ))
            .get();
    for (final r in rows) {
      final content = decodeObject(r.content);
      final s = answers[str(helperPostOf(content)?['id'])];
      if (s == null) continue;
      final next = {...content, 'helper': s.toJson()};
      if (s.state == 'posted') {
        final at = (s.postedAt ?? DateTime.now()).toLocal().toIso8601String().substring(0, 10);
        if (str(content['posted']).isEmpty) next['posted'] = at;
        if (s.url.isNotEmpty) next['postedUrl'] = s.url;
      }
      final raw = jsonEncode(next);
      if (raw == r.content) continue;
      await save(db.careerReports, r.copyWith(content: raw), r.id);
      changed++;
    }
    return changed;
  }
}
