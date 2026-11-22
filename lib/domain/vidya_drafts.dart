/// Email drafts from Vidya's job journey (its stage packs: chase,
/// feedback request, accept, decline, notice and the rest). Vidya writes
/// them to its own `bridge_study_progress` row, [emailDraftsId]; the
/// Conversations composer offers them under "From Vidya", and picking one
/// only puts its text in the message box. Nothing is ever sent from here
/// without the candidate pressing send.
///
/// Like the practise requests, the row is not a progress report: Udyoga's
/// readers of those look rows up by their own plan ids.
library;

import 'package:drift/drift.dart';

import 'book.dart';
import 'json.dart';

/// The progress row Vidya writes its email drafts to.
const emailDraftsId = 'vidya.email-drafts';

/// The `format` of [emailDraftsId]'s JSON.
const emailDraftsFormat = 'vidya-email-drafts';

/// At most this many characters of a draft's body are read.
const maxDraftBody = 5000;

/// One draft from Vidya, for one template and one job.
class VidyaDraft {
  const VidyaDraft({
    required this.id,
    required this.body,
    this.template = '',
    this.title = '',
    this.subject = '',
    this.employer = '',
    this.role = '',
    this.at = '',
  });

  final String id, body;

  /// Vidya's template id and title, e.g. "feedback", "Ask for feedback by criterion".
  final String template, title;
  final String subject, employer, role;

  /// When Vidya wrote it (UTC, ISO 8601).
  final String at;

  static VidyaDraft? fromJson(Json j) {
    final id = str(j['id']), body = str(j['body']);
    if (id.isEmpty || body.isEmpty) return null;
    return VidyaDraft(
      id: id,
      body: body.length > maxDraftBody ? body.substring(0, maxDraftBody) : body,
      template: str(j['template']),
      title: str(j['title']),
      subject: str(j['subject']),
      employer: str(j['employer']),
      role: str(j['role']),
      at: str(j['at']),
    );
  }
}

/// The drafts in Vidya's [emailDraftsId] progress JSON, newest first.
List<VidyaDraft> parseVidyaDrafts(String progressJson) {
  final j = decodeObject(progressJson);
  if (j['format'] != emailDraftsFormat) return const [];
  final seen = <String>{};
  return [
    for (final d in objs(j['drafts']))
      if (VidyaDraft.fromJson(d) case final draft? when seen.add(draft.id)) draft,
  ]..sort((a, b) => b.at.compareTo(a.at));
}

extension VidyaDrafts on CareerBook {
  /// Vidya's email drafts, newest first; empty until it sends one.
  Future<List<VidyaDraft>> vidyaDrafts() async {
    final row = await (db.select(
      db.bridgeStudyProgress,
    )..where((p) => p.id.equals(emailDraftsId) & p.deleted.not())).getSingleOrNull();
    return row == null ? const [] : parseVidyaDrafts(row.progress);
  }
}
