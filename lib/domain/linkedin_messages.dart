import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'conversations.dart';
import 'linkedin_export.dart';

// LinkedIn messages and connection requests from the member's own data
// archive, added as imported threads. Nothing is fetched from LinkedIn: the
// archive is read on the device. Messages the user already logged by hand
// are not added twice, and importing the same archive again adds nothing.
// The connections it brings in also show who the user already knows at the
// employers they are aiming for.

/// The people the user already knows at one target employer.
typedef KnownAt = ({String employer, List<Lead> people});

/// What a messages import added.
typedef LinkedInMessagesImport = ({int messages, int invitations});

/// Whether two texts say the same thing: the same opening, or mostly the
/// same words. A message logged by hand is often tidied before it is sent.
bool similarText(String a, String b) {
  final x = _words(a), y = _words(b);
  if (x.isEmpty || y.isEmpty) return x.isEmpty && y.isEmpty;
  final p = x.join(' '), q = y.join(' ');
  final n = [30, p.length, q.length].reduce((a, b) => a < b ? a : b);
  if (n >= 12 && p.substring(0, n) == q.substring(0, n)) return true;
  final xs = x.toSet(), ys = y.toSet();
  return xs.intersection(ys).length / xs.union(ys).length >= 0.6;
}

List<String> _words(String s) =>
    s.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty).toList();

/// Whether two message times (yyyy-MM-ddTHH:mm) are within [minutes].
bool closeInTime(String a, String b, {int minutes = 5}) {
  final x = DateTime.tryParse(a), y = DateTime.tryParse(b);
  return x != null && y != null && x.difference(y).inMinutes.abs() <= minutes;
}

String _at(DateTime d) => d.toIso8601String().substring(0, 16);

String _name(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

extension LinkedInMessagesBook on CareerBook {
  /// Adds the archive's conversations and connection requests to
  /// Conversations. Each conversation is one thread, with the contact found
  /// by profile link and then by name; a LinkedIn thread the user logged by
  /// hand with that person takes the import. People with no contact record
  /// wait in the Screener, unless their last word is older than [days] days.
  /// People marked "do not contact" are skipped.
  Future<LinkedInMessagesImport> importLinkedInMessages(
    LinkedInExport x, {
    required String today,
    int days = 365,
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
      if (h.channel == 'linkedin' && byId[h.contactId] != null) {
        byUrl.putIfAbsent(handleKey('linkedin', h.handle), () => byId[h.contactId]!);
      }
    }
    final byName = <String, List<Lead>>{};
    for (final p in people) {
      (byName[_name(p.name)] ??= []).add(p);
    }
    Lead? find(String name, String url) {
      final named = byName[_name(name)];
      return byUrl[handleKey('linkedin', url)] ?? (named?.length == 1 ? named!.single : null);
    }

    bool skip(String url, Lead? c) =>
        (c?.doNotContact ?? false) || blocked.contains(handleKey('linkedin', url));
    final since = addDays(today, -days);
    bool old(DateTime d) => _at(d).substring(0, 10).compareTo(since) < 0;

    // A thread the import added to that went quiet long ago is history, not
    // something to chase.
    Future<void> settle(String id) async {
      final t = await conversation(id);
      if (t.followUp != null && t.lastAt.substring(0, 10).compareTo(addDays(today, -30)) < 0) {
        await save(db.conversations, t.copyWith(followUp: const Value(null)), id);
      }
      if (t.contactId != null) await refreshContact(t.contactId!, today: today);
    }

    var messages = 0;
    for (final th in x.threads()) {
      final match = [for (final p in th.people) (person: p, contact: find(p.name, p.url))];
      final hit = match.where((m) => m.contact != null).firstOrNull;
      final c = hit?.contact;
      final first = hit?.person ?? th.people.first;
      if (match.any((m) => skip(m.person.url, m.contact))) continue;
      if (c == null && old(th.messages.last.at)) continue;

      var t = await threadByExternalId('linkedin', th.id);
      if (t == null && c != null) {
        final mine = (await conversationsOf(c.id))
            .where((t) => t.channel == 'linkedin' && t.externalId == null)
            .firstOrNull;
        if (mine != null) {
          t = mine.copyWith(externalId: Value(th.id));
          await save(db.conversations, t, t.id);
        }
      }
      final id =
          t?.id ??
          await startConversation(
            contactId: c?.id,
            channel: 'linkedin',
            mode: 'import',
            subject: c == null ? th.people.map((p) => p.name).join(', ') : th.title,
            peer: c == null ? (first.url.isEmpty ? first.name : first.url) : '',
            externalId: th.id,
            at: _at(th.messages.first.at),
          );
      final logged = [
        for (final m in await messagesIn(id))
          if (m.source != 'import') m,
      ];
      var added = 0;
      for (final m in th.messages) {
        final direction = m.out ? 'out' : 'in';
        final at = _at(m.at);
        if (logged.any(
          (l) => l.direction == direction && closeInTime(l.sentAt, at) && similarText(l.body, m.body),
        )) {
          continue;
        }
        final put = await addMessage(
          id,
          direction: direction,
          body: m.body,
          at: at,
          source: 'import',
          externalId: m.key,
        );
        if (put != null) added++;
      }
      if (added > 0) await settle(id);
      messages += added;
    }

    var invitations = 0;
    for (final i in x.invites()) {
      final c = find(i.name, i.url);
      if (skip(i.url, c) || (c == null && old(i.at))) continue;
      final peer = i.url.isEmpty ? i.name : i.url;
      final rows = c == null
          ? (await threads(today: today, channel: 'linkedin', screener: true))
                .map((r) => r.thread)
                .where(
                  (t) =>
                      handleKey('linkedin', t.peer) == handleKey('linkedin', peer) ||
                      (t.subject.isNotEmpty && _name(t.subject) == _name(i.name)),
                )
          : (await conversationsOf(c.id)).where((t) => t.channel == 'linkedin');
      final id =
          rows.firstOrNull?.id ??
          await startConversation(
            contactId: c?.id,
            channel: 'linkedin',
            mode: 'import',
            subject: c == null ? i.name : '',
            peer: c == null ? peer : '',
            externalId: 'invite:${handleKey('linkedin', peer)}',
            at: _at(i.at),
          );
      final direction = i.out ? 'out' : 'in';
      final at = _at(i.at);
      final logged = await messagesIn(id);
      if (logged.any(
        (l) =>
            l.source != 'import' &&
            l.direction == direction &&
            l.status == 'invite' &&
            closeInTime(l.sentAt, at) &&
            (i.body.isEmpty || l.body.isEmpty || similarText(l.body, i.body)),
      )) {
        continue;
      }
      final put = await addMessage(
        id,
        direction: direction,
        body: i.body.isEmpty ? 'Connection request' : i.body,
        at: at,
        source: 'import',
        status: 'invite',
        externalId: i.key,
      );
      if (put != null) {
        invitations++;
        await settle(id);
      }
    }
    return (messages: messages, invitations: invitations);
  }

  /// The employers the user is aiming for: those of their applications and
  /// saved jobs, each once.
  Future<List<String>> targetEmployers() async {
    final applied = await (db.select(db.jobApplications)..where((a) => a.deleted.not())).get();
    final saved = await (db.select(
      db.jobListings,
    )..where((j) => j.deleted.not() & j.status.isIn(['saved', 'applied']))).get();
    final seen = <String>{};
    return [
      for (final c in [...applied.map((a) => a.company), ...saved.map((j) => j.company)])
        if (c.trim().isNotEmpty && seen.add(employerKey(c))) c.trim(),
    ];
  }

  /// First-degree LinkedIn connections (from the data archive) who work at a
  /// target employer, employer by employer: the warmest leads there are.
  /// People marked "do not contact" are left out.
  Future<List<KnownAt>> knownAtTargets() async {
    final employers = await targetEmployers();
    final connections = await (db.select(
      db.careerContacts,
    )..where((c) => c.deleted.not() & c.doNotContact.not() & c.sourceKind.equals('archive'))).get();
    return [
      for (final e in employers)
        if (connections.where((c) => sameEmployer(c.company, e)).toList() case final people
            when people.isNotEmpty)
          (employer: e, people: people),
    ];
  }
}
