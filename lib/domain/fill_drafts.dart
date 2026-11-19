/// The drafts Udyoga has already written that a text-box fill can start
/// from: the LinkedIn studio's connection notes and messages, and the
/// drafts written for a conversation or a first (intro) message to a
/// contact. Picking one only puts it in the draft box; the user still
/// approves it and sees the dry run before anything is filled.
library;

import 'package:drift/drift.dart';

import 'book.dart';
import 'json.dart';
import 'linkedin.dart';

/// Synced pref: the conversation and intro drafts kept for filling, newest
/// first, as [{kind, ref, to, text, at}].
const savedDraftsKey = 'udyoga.drafts.saved';

/// How many conversation and intro drafts are kept.
const savedDraftsCap = 30;

/// The studio tools whose paste-ready blocks are notes or messages.
const _studioKinds = {LinkedInTool.outreach, LinkedInTool.inbox};

/// One draft to choose from.
class FillDraft {
  const FillDraft({required this.label, required this.text, required this.from, this.at = ''});

  /// What it is, such as "Connection note: Sam Example".
  final String label;
  final String text;

  /// Where it came from: "LinkedIn studio", "Conversation" or "Intro".
  final String from;

  /// When it was written (ISO), for sorting.
  final String at;
}

const _draftKinds = {'conversation': 'Conversation', 'intro': 'Intro'};

extension FillDrafts on CareerBook {
  /// Keeps a conversation draft ([kind] "conversation", [ref] the thread
  /// id) or an intro message ([kind] "intro", [ref] the contact id) to
  /// [to]. A newer draft for the same thread or contact replaces the older.
  Future<void> keepDraft({
    required String kind,
    required String ref,
    required String to,
    required String text,
    required String at,
  }) async {
    if (!_draftKinds.containsKey(kind)) throw ArgumentError.value(kind, 'kind');
    final body = text.trim();
    if (body.isEmpty) return;
    final old = objs(await pref<List<Object?>>(savedDraftsKey, const []));
    await setPref(
      savedDraftsKey,
      [
        {'kind': kind, 'ref': ref, 'to': to, 'text': body, 'at': at},
        ...old.where((d) => !(str(d['kind']) == kind && str(d['ref']) == ref)),
      ].take(savedDraftsCap).toList(),
    );
  }

  /// Every saved draft a fill can use, newest first: the paste-ready notes
  /// and messages from the LinkedIn studio's [studioReports] latest
  /// connection-note and inbox results, then the kept conversation and
  /// intro drafts.
  Future<List<FillDraft>> fillDrafts({int studioReports = 10}) async {
    final out = <FillDraft>[];
    final reports =
        await (db.select(db.careerReports)
              ..where((r) => r.kind.isIn([for (final t in _studioKinds) t.kind]) & r.deleted.not())
              ..orderBy([(r) => OrderingTerm.desc(r.created)])
              ..limit(studioReports))
            .get();
    for (final r in reports) {
      final data = decodeObject(r.content);
      final who = str(obj(data['input'])['who']).split(',').first.trim();
      for (final b in objs(data['sections']).expand((s) => objs(s['blocks']))) {
        final text = str(b['text']).trim();
        if (b['copy'] != true || text.isEmpty) continue;
        final label = str(b['label']).ifEmpty('Message');
        out.add(
          FillDraft(
            label: who.isEmpty ? label : '$label: $who',
            text: text,
            from: 'LinkedIn studio',
            at: r.created,
          ),
        );
      }
    }
    for (final d in objs(await pref<List<Object?>>(savedDraftsKey, const []))) {
      final text = str(d['text']).trim();
      if (text.isEmpty) continue;
      final from = _draftKinds[str(d['kind'])] ?? 'Draft';
      final to = str(d['to']);
      out.add(FillDraft(label: to.isEmpty ? from : '$from: $to', text: text, from: from, at: str(d['at'])));
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
