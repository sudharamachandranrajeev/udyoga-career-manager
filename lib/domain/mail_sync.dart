import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'conversations.dart';
import 'linkedin_messages.dart' show closeInTime, similarText;
import 'mail.dart';
import 'mail_transport.dart';

// E-mail that syncs: INBOX and Sent are read from the user's account, and
// only mail to or from a saved contact, or a reply in a thread Udyoga
// already holds, is kept. Everything else is read as headers only, never
// stored, and forgotten. Accounts and their sync state live on this device;
// the passwords live in the system keychain.

/// Where the accounts are kept (local settings, never synced).
const mailAccountsKey = 'udyoga.mail.accounts';

/// A new message from someone who matters, for a phone alert.
typedef MailAlert = ({String conversationId, String name, String preview});

/// What a sync brought in, and the accounts that could not be read.
typedef MailSyncReport = ({int added, List<MailAlert> alerts, List<String> failed});

/// Gmail's Sent folder, and the usual names elsewhere, for servers without
/// SPECIAL-USE.
const _sentNames = ['[Gmail]/Sent Mail', 'Sent', 'Sent Items', 'Sent Messages', 'INBOX.Sent'];

class MailService {
  MailService(this.book, this.secrets, this.transport, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final CareerBook book;
  final SecretStore secrets;
  final MailTransport transport;
  final DateTime Function() clock;

  AppDatabase get db => book.db;

  // ---- accounts ----

  Future<List<ChannelAccount>> accounts() async {
    final raw = await db.localSetting(mailAccountsKey);
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final j in (jsonDecode(raw) as List).whereType<Map<String, Object?>>()) ChannelAccount.fromJson(j),
    ];
  }

  Future<void> _write(List<ChannelAccount> all) =>
      db.setLocalSetting(mailAccountsKey, jsonEncode([for (final a in all) a.toJson()]));

  /// Adds or replaces the account with [a]'s address; with a [password], it
  /// is stored in the keychain.
  Future<void> saveAccount(ChannelAccount a, {String? password}) async {
    if (password != null) await secrets.write(a.secretKey, password.replaceAll(' ', ''));
    final all = [...await accounts()];
    final i = all.indexWhere((x) => x.address.toLowerCase() == a.address.toLowerCase());
    if (i < 0) {
      all.add(a);
    } else {
      all[i] = a;
    }
    await _write(all);
  }

  /// Disconnects an account: its settings and password go; the mail already
  /// in conversations stays.
  Future<void> removeAccount(ChannelAccount a) async {
    await secrets.delete(a.secretKey);
    await _write([
      for (final x in await accounts())
        if (x.address.toLowerCase() != a.address.toLowerCase()) x,
    ]);
  }

  Future<String> _password(ChannelAccount a) async {
    final p = await secrets.read(a.secretKey);
    if (p == null || p.isEmpty) {
      throw MailException('The password for ${a.address} is missing. Connect the account again.');
    }
    return p;
  }

  /// Signs in to IMAP and SMTP with [password] (or the stored one) and out
  /// again. Throws a [MailException] that says what to fix.
  Future<void> test(ChannelAccount a, {String? password}) async {
    if (a.problem case final p?) throw MailException(p);
    final pw = password?.replaceAll(' ', '') ?? await _password(a);
    final s = await transport.imap(a, pw);
    try {
      await s.folders();
    } finally {
      await s.close();
    }
    await transport.checkSmtp(a, pw);
  }

  // ---- sync ----

  /// Syncs every account not synced in the last [every] (all with [force]).
  Future<MailSyncReport> syncDue({Duration every = const Duration(minutes: 15), bool force = false}) async {
    var added = 0;
    final alerts = <MailAlert>[];
    final failed = <String>[];
    for (final a in await accounts()) {
      final last = DateTime.tryParse(a.lastSync ?? '');
      if (!force && last != null && clock().toUtc().difference(last) < every) continue;
      try {
        final r = await sync(a);
        added += r.added;
        alerts.addAll(r.alerts);
      } catch (e) {
        // One account failing does not stop the others.
        failed.add('${a.address}: ${describeError(e)}');
      }
    }
    return (added: added, alerts: alerts, failed: failed);
  }

  /// Reads new mail in INBOX and Sent: the last [days] days the first time,
  /// then only what arrived since.
  Future<MailSyncReport> sync(ChannelAccount a, {int days = 90}) async {
    final me = a.address.toLowerCase();
    final session = await transport.imap(a, await _password(a));
    final kept = <({MailItem item, String? thread})>[];
    final state = {...a.folders};
    try {
      final folders = await session.folders();
      final inbox = folders.where((f) => f.inbox).firstOrNull?.path ?? 'INBOX';
      final sent =
          folders.where((f) => f.sent).firstOrNull?.path ??
          _sentNames.where((n) => folders.any((f) => f.path == n)).firstOrNull;
      final known = await _known();
      for (final path in [inbox, ?sent]) {
        final validity = await session.open(path);
        final had = state[path];
        final uids = had != null && had.validity == validity
            ? await session.uidsAbove(had.uid)
            : await session.uidsSince(clock().subtract(Duration(days: days)));
        if (uids.isEmpty) continue;
        final wanted = <int>[];
        for (var i = 0; i < uids.length; i += 100) {
          for (final f in await session.fetch(
            uids.sublist(i, (i + 100).clamp(0, uids.length)),
            headers: true,
          )) {
            final head = parseMail(f.raw);
            if (!_wanted(head, f.gmailThreadId, me, known)) continue;
            wanted.add(f.uid);
            // Later replies to this one belong too, even in the same sync.
            known.ids.addAll([
              if (head.messageId.isNotEmpty) head.messageId,
              'mid:${head.root}',
              if (f.gmailThreadId != null) 'gm:${f.gmailThreadId}',
            ]);
          }
        }
        for (var i = 0; i < wanted.length; i += 25) {
          for (final f in await session.fetch(wanted.sublist(i, (i + 25).clamp(0, wanted.length)))) {
            final item = parseMail(f.raw);
            if (_wanted(item, f.gmailThreadId, me, known)) kept.add((item: item, thread: f.gmailThreadId));
          }
        }
        state[path] = (validity: validity, uid: uids.reduce((x, y) => x > y ? x : y));
      }
    } finally {
      await session.close();
    }
    kept.sort((x, y) => (x.item.date ?? DateTime(0)).compareTo(y.item.date ?? DateTime(0)));
    var added = 0;
    final alerts = <MailAlert>[];
    for (final k in kept) {
      final r = await _store(a, k.item, k.thread);
      if (r == null) continue;
      added++;
      if (r.alert != null && a.notify) alerts.add(r.alert!);
    }
    await saveAccount(a.copyWith(folders: state, lastSync: clock().toUtc().toIso8601String()));
    return (added: added, alerts: alerts, failed: const <String>[]);
  }

  /// The addresses of saved contacts, and the message and thread ids
  /// Udyoga holds.
  Future<({Map<String, Lead> people, Set<String> ids})> _known() async {
    final people = {
      for (final c in await (db.select(db.careerContacts)..where((c) => c.deleted.not())).get()) c.id: c,
    };
    final byMail = <String, Lead>{
      for (final c in people.values)
        if (c.email.trim().isNotEmpty) c.email.trim().toLowerCase(): c,
    };
    for (final h in await (db.select(
      db.contactHandles,
    )..where((h) => h.deleted.not() & h.channel.equals('email'))).get()) {
      if (people[h.contactId] case final c?) byMail.putIfAbsent(h.handle.trim().toLowerCase(), () => c);
    }
    final threads = await (db.select(
      db.conversations,
    )..where((c) => c.channel.equals('email') & c.deleted.not())).get();
    final ids = {
      for (final t in threads) ?t.externalId,
      for (final m
          in await (db.select(db.messages)..where(
                (m) =>
                    m.conversationId.isIn(threads.map((t) => t.id)) &
                    m.deleted.not() &
                    m.externalId.isNotNull(),
              ))
              .get())
        m.externalId!,
    };
    return (people: byMail, ids: ids);
  }

  /// Mail to or from a saved contact, or a reply in a thread already held.
  bool _wanted(
    MailItem m,
    String? gmailThread,
    String me,
    ({Map<String, Lead> people, Set<String> ids}) known,
  ) {
    final others = m.from == me ? m.to : [m.from];
    return others.any(known.people.containsKey) ||
        m.ancestors.any(known.ids.contains) ||
        known.ids.contains('mid:${m.root}') ||
        (gmailThread != null && known.ids.contains('gm:$gmailThread'));
  }

  /// Adds one message to its thread. Null when it is already there.
  Future<({String id, MailAlert? alert})?> _store(ChannelAccount a, MailItem m, String? gmailThread) async {
    final me = a.address.toLowerCase();
    final out = m.from == me;
    final key = gmailThread != null ? 'gm:$gmailThread' : 'mid:${m.root}';
    final messageId = m.messageId.isNotEmpty
        ? m.messageId
        : '<${m.from}.${m.date?.millisecondsSinceEpoch}@udyoga.invalid>';
    final at = (m.date ?? clock()).toLocal().toIso8601String().substring(0, 16);

    Future<ThreadMessage?> byId(List<String> ids) async => ids.isEmpty
        ? null
        : (await (db.select(db.messages)..where((x) => x.externalId.isIn(ids) & x.deleted.not())).get())
              .where((x) => ids.contains(x.externalId))
              .firstOrNull;

    final same = await byId([messageId]);
    if (same != null) {
      // Sent from Udyoga, now seen in Sent: Gmail's thread id joins the thread.
      final t = await book.conversation(same.conversationId);
      if (gmailThread != null && !(t.externalId ?? '').startsWith('gm:')) {
        await book.save(db.conversations, t.copyWith(externalId: Value(key)), t.id);
      }
      return null;
    }
    final people = (await _known()).people;
    final other = out ? m.to.firstWhere(people.containsKey, orElse: () => m.to.firstOrNull ?? '') : m.from;
    final person = people[other];

    var t = await book.threadByExternalId('email', key);
    if (t == null) {
      final parent = await byId(m.ancestors);
      if (parent != null) t = await book.conversation(parent.conversationId);
    }
    if (t == null && gmailThread != null) t = await book.threadByExternalId('email', 'mid:${m.root}');
    if (t == null && person != null) {
      // A thread the user kept by hand with this person takes the mail.
      t = (await book.conversationsOf(person.id))
          .where(
            (x) =>
                x.channel == 'email' && x.externalId == null && (x.account.isEmpty || x.account == a.address),
          )
          .firstOrNull;
    }
    if (t != null && (t.externalId == null || (gmailThread != null && !t.externalId!.startsWith('gm:')))) {
      t = t.copyWith(externalId: Value(key), account: t.account.isEmpty ? a.address : t.account);
      await book.save(db.conversations, t, t.id);
    }
    if (t == null && person == null) return null;
    final id =
        t?.id ??
        await book.startConversation(
          contactId: person!.id,
          channel: 'email',
          account: a.address,
          mode: 'api',
          subject: m.subject.replaceFirst(RegExp(r'^((re|fwd?|aw):\s*)+', caseSensitive: false), ''),
          peer: other,
          externalId: key,
          at: at,
        );

    final direction = out ? 'out' : 'in';
    final logged = [
      for (final x in await book.messagesIn(id))
        if (x.source == 'manual') x,
    ];
    if (logged.any(
      (x) => x.direction == direction && closeInTime(x.sentAt, at) && similarText(x.body, m.body),
    )) {
      return null;
    }
    final added = await book.addMessage(
      id,
      direction: direction,
      body: m.body,
      at: at,
      source: 'api',
      externalId: messageId,
    );
    if (added == null) return null;
    final thread = await book.conversation(id);
    final who = thread.contactId == null ? null : await book.contact(thread.contactId!);
    return (
      id: added,
      alert: out || who == null
          ? null
          : (
              conversationId: id,
              // A colleague writing in the thread is named as themselves.
              name: person?.name ?? (m.fromName.isNotEmpty ? m.fromName : m.from),
              preview: m.body.replaceAll(RegExp(r'\s+'), ' ').trim(),
            ),
    );
  }

  // ---- send ----

  /// Sends [body] on [thread] from [a], as a reply when the thread has mail
  /// with ids. Returns the new Message-ID.
  Future<String> send(
    ChannelAccount a,
    Conversation thread,
    Lead contact,
    String body, {
    String subject = '',
  }) async {
    final to = contact.email.trim().isNotEmpty ? contact.email.trim() : thread.peer;
    if (to.isEmpty) throw MailException('${contact.name} has no e-mail address.');
    final said = await book.messagesIn(thread.id);
    final ids = [
      for (final m in said)
        if ((m.externalId ?? '').startsWith('<')) m.externalId!,
    ];
    final answered = said.any((m) => m.direction == 'in');
    final messageId = newMessageId(a.address);
    final raw = buildMail(
      fromName: a.name,
      from: a.address,
      to: to,
      subject: answered ? replySubject(subject) : subject,
      body: body,
      messageId: messageId,
      inReplyTo: ids.lastOrNull ?? '',
      references: ids.length > 20 ? [ids.first, ...ids.sublist(ids.length - 19)] : ids,
      date: clock(),
    );
    await transport.send(a, await _password(a), raw: raw, from: a.address, to: [to]);
    return messageId;
  }
}

/// E-mail through a connected account, for the composer.
class EmailSender implements ChannelSender {
  EmailSender(this.service, this.a);
  final MailService service;
  final ChannelAccount a;

  @override
  String get channel => 'email';

  @override
  String get account => a.address;

  @override
  Future<String> send(Conversation thread, Lead contact, String body, {String subject = ''}) =>
      service.send(a, thread, contact, body, subject: subject);
}
