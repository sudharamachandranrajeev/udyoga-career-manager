import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';

// Conversations: every thread with every person, on every channel, in one
// place, with the channel always shown. Udyoga never sends on LinkedIn: the
// user sends each message by hand and logs it here. Channels Udyoga can send
// on (e-mail, Bluesky) come later through [ChannelSender].
//
// The person record (career_contacts) also says where they were found and
// on what lawful basis they may be contacted, and can be forgotten or marked
// "do not contact" in one step.

/// The channels a thread can be on, as the list names them.
const channelNames = {
  'linkedin': 'LinkedIn message',
  'email': 'Email',
  'phone': 'Phone',
  'in_person': 'In person',
  'bluesky': 'Bluesky DM',
  'other': 'Other',
};

/// "LinkedIn message", or "Email · you@example.org" with the account.
String channelLabel(String channel, {String account = ''}) {
  final name = channelNames[channel] ?? channel;
  return account.isEmpty ? name : '$name · $account';
}

/// Where a thread stands.
const threadStatuses = {
  'draft': 'Draft',
  'to_send': 'To send',
  'awaiting_reply': 'Sent, awaiting reply',
  'replied': 'Replied',
  'follow_up': 'Follow-up due',
  'closed': 'Closed',
};

/// Where a thread's record came from: "is this the real record or my note?"
const threadSources = {'api': 'Synced', 'import': 'Imported', 'manual': 'Logged by you'};

/// Where a person was found.
const sourceKinds = {
  'advert': 'Job advert',
  'team_page': 'Team page',
  'speaker': 'Speaker list',
  'register': 'Public register',
  'met': 'Met in person',
  'archive': 'LinkedIn archive',
  'inbound': 'They got in touch',
  'referral': 'Referred to you',
  'other': 'Other',
};

/// The lawful basis for contacting a person (UK GDPR Article 6).
const lawfulBases = {
  'legitimate_interest': 'Legitimate interest',
  'they_contacted': 'They contacted you first',
  'consent': 'They agreed to be contacted',
};

/// "Keep in touch every N weeks" choices; null is off.
const keepInTouchChoices = <int?, String>{
  null: 'Off',
  2: 'Every 2 weeks',
  4: 'Every 4 weeks',
  8: 'Every 8 weeks',
  12: 'Every 12 weeks',
  26: 'Every 6 months',
};

/// A channel Udyoga can send on by itself once the user connects an account
/// (e-mail over SMTP, Bluesky). LinkedIn never gets one. Returns the
/// provider's message id.
abstract interface class ChannelSender {
  String get channel;
  String get account;
  Future<String> send(Conversation thread, Lead contact, String body, {String subject = ''});
}

/// Thrown when something would message a person marked "do not contact".
class DoNotContactException implements Exception, UserFacingError {
  DoNotContactException(this.name);
  final String name;
  @override
  String get message => '${name.isEmpty ? 'This person' : name} asked not to be contacted.';
  @override
  String toString() => message;
}

// ---- e-mail address kinds (PECR) ----

/// Free and ISP mail services: an address on one of these is a person's own.
const personalMailDomains = {
  'gmail.com',
  'googlemail.com',
  'outlook.com',
  'hotmail.com',
  'live.com',
  'msn.com',
  'yahoo.com',
  'ymail.com',
  'rocketmail.com',
  'icloud.com',
  'me.com',
  'mac.com',
  'aol.com',
  'proton.me',
  'protonmail.com',
  'pm.me',
  'btinternet.com',
  'btopenworld.com',
  'sky.com',
  'virginmedia.com',
  'ntlworld.com',
  'blueyonder.co.uk',
  'talktalk.net',
  'tiscali.co.uk',
  'plus.net',
  'gmx.com',
  'gmx.co.uk',
  'mail.com',
  'zoho.com',
  'fastmail.com',
  'tutanota.com',
  'tuta.io',
  'yandex.com',
};

/// Services with a domain per country (yahoo.co.uk, hotmail.fr).
const _personalPrefixes = ['yahoo.', 'hotmail.', 'outlook.', 'live.', 'aol.', 'gmx.'];

/// 'personal' for a free or ISP mailbox, 'work' for an employer's domain
/// (nhs.net, nhs.uk, gov.uk and company domains), '' without an address.
/// Marketing-style e-mail to a personal address needs consent (PECR).
String emailKind(String email) {
  final at = email.lastIndexOf('@');
  if (at < 0) return '';
  final domain = email.substring(at + 1).trim().toLowerCase();
  if (domain.isEmpty) return '';
  if (personalMailDomains.contains(domain) || _personalPrefixes.any(domain.startsWith)) return 'personal';
  return 'work';
}

// ---- matching people across channels ----

/// An address, profile or number in one form, so the same person is found
/// however it was typed: "email:jo@example.org", "linkedin:linkedin.com/in/jo".
String handleKey(String channel, String handle) {
  var h = handle.trim().toLowerCase();
  if (h.isEmpty) return '';
  switch (channel) {
    case 'linkedin':
      h = h.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^([a-z]{2,3}|www)\.'), '');
      h = h.split(RegExp(r'[?#]')).first.replaceFirst(RegExp(r'/+$'), '');
    case 'phone':
      h = h.replaceAll(RegExp(r'[^0-9+]'), '').replaceFirst(RegExp(r'^\+44'), '0');
    case 'email':
      h = h.replaceFirst('mailto:', '');
  }
  return '$channel:$h';
}

/// Every identity a contact record carries in its own fields.
List<({String channel, String handle})> fieldHandles(Lead l) => [
  if (l.email.trim().isNotEmpty) (channel: 'email', handle: l.email.trim()),
  if (l.linkedin.trim().isNotEmpty) (channel: 'linkedin', handle: l.linkedin.trim()),
  if (l.phone.trim().isNotEmpty) (channel: 'phone', handle: l.phone.trim()),
];

/// The addresses and profiles of everyone marked "do not contact", as
/// [handleKey]s, so imports can skip them.
Set<String> suppressionKeys(List<Lead> contacts, List<ContactHandle> handles) {
  final blocked = {
    for (final c in contacts)
      if (c.doNotContact && !c.deleted) c.id,
  };
  return {
    for (final c in contacts.where((c) => blocked.contains(c.id)))
      for (final h in fieldHandles(c)) handleKey(h.channel, h.handle),
    for (final h in handles)
      if (blocked.contains(h.contactId) && !h.deleted) handleKey(h.channel, h.handle),
  }..remove('');
}

String _nameKey(String name, String company) =>
    '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${company.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

// ---- what the screens show ----

/// The line the user may add to a first message to say how they found the
/// person (UK GDPR Article 14), or '' when the person knows already (met in
/// person, or they got in touch).
String howIFoundYou(Lead l) {
  if (l.sourceKind == 'met' || l.sourceKind == 'inbound' || l.basis == 'they_contacted') return '';
  final host = Uri.tryParse(l.sourceUrl)?.host ?? '';
  final where = l.source.isNotEmpty && !l.source.startsWith('http')
      ? l.source
      : switch (l.sourceKind) {
          'advert' => 'a job advert',
          'team_page' => 'your organisation\'s team page',
          'speaker' => 'an event speaker list',
          'register' => 'a public professional register',
          'archive' => 'LinkedIn',
          'referral' => 'a colleague\'s recommendation',
          _ => host.isNotEmpty ? host : 'a public professional page',
        };
  return 'I came across your name on $where. If you would rather I did not contact you, say so and I will '
      'remove your details.';
}

/// Where the person was found, for the thread header: "NHS Jobs advert,
/// 10 Nov 2026"; '' when unknown.
String foundOnText(Lead l) {
  final what = l.source.isNotEmpty
      ? l.source
      : l.sourceKind != 'other'
      ? sourceKinds[l.sourceKind] ?? l.sourceKind
      : l.sourceUrl;
  return [
    what,
    if (l.foundOn != null && l.foundOn!.length == 10) niceDate(l.foundOn!),
  ].where((s) => s.isNotEmpty).join(', ');
}

/// The header every thread shows, so who and where are never lost:
/// "To Jordan Example · Practice Manager, Example Health Trust · via
/// LinkedIn message · found on Job advert, 10 Nov 2026". Missing parts are
/// left out.
String threadHeader(Conversation c, Lead? l) {
  final role = l == null ? '' : [l.title, l.company].where((s) => s.isNotEmpty).join(', ');
  final found = l == null ? '' : foundOnText(l);
  return [
    l != null
        ? 'To ${l.name}'
        : c.peer.isEmpty
        ? 'From an unknown sender'
        : 'From ${c.peer}',
    if (role.isNotEmpty) role,
    'via ${channelLabel(c.channel, account: c.account)}',
    if (found.isNotEmpty) 'found on $found',
  ].join(' · ');
}

/// A row of the conversation list: the thread, its person (null in the
/// Screener) and its newest message.
class ThreadRow {
  const ThreadRow(this.thread, this.contact, this.last);
  final Conversation thread;
  final Lead? contact;
  final ThreadMessage? last;

  /// Their message is the newest, or the thread says they replied.
  bool get needsReply =>
      thread.status != 'closed' &&
      (thread.unread > 0 || thread.status == 'replied' || last?.direction == 'in');

  bool followUpDue(String today) =>
      thread.status != 'closed' &&
      ((thread.followUp != null && thread.followUp!.compareTo(today) <= 0) ||
          (thread.status == 'follow_up' && thread.followUp == null));
}

enum ThreadFilter { all, needsReply, followUpDue }

/// The rows to show, newest first. The Screener holds threads with no
/// person yet; every other view leaves them out.
List<ThreadRow> filterThreads(
  List<ThreadRow> rows, {
  ThreadFilter filter = ThreadFilter.all,
  required String today,
  String? channel,
  String? jobId,
  bool screener = false,
}) =>
    rows
        .where((r) => (r.thread.contactId == null) == screener)
        .where(
          (r) => switch (filter) {
            ThreadFilter.all => true,
            ThreadFilter.needsReply => r.needsReply,
            ThreadFilter.followUpDue => r.followUpDue(today),
          },
        )
        .where((r) => channel == null || r.thread.channel == channel)
        .where((r) => jobId == null || r.thread.jobId == jobId)
        .toList()
      ..sort((a, b) => b.thread.lastAt.compareTo(a.thread.lastAt));

// ---- the pace guard ----

/// LinkedIn restricts accounts that invite or message too fast. These are
/// the counts at which Udyoga says to slow down, well under LinkedIn's own
/// limits (about 100 invitations a week). Two thirds of them is "busy".
abstract final class PaceLimits {
  static const invitesDay = 15;
  static const invitesWeek = 80;
  static const messagesDay = 40;
  static const messagesWeek = 150;
}

enum PaceLevel { calm, busy, slowDown }

/// What the user has sent by hand on LinkedIn in the last day and week. It
/// only advises: nothing is ever blocked.
class Pace {
  const Pace({this.invitesDay = 0, this.invitesWeek = 0, this.messagesDay = 0, this.messagesWeek = 0});
  final int invitesDay, invitesWeek, messagesDay, messagesWeek;

  /// Each count as a share of its limit.
  double get _load => [
    invitesDay / PaceLimits.invitesDay,
    invitesWeek / PaceLimits.invitesWeek,
    messagesDay / PaceLimits.messagesDay,
    messagesWeek / PaceLimits.messagesWeek,
  ].reduce((a, b) => a > b ? a : b);

  PaceLevel get level => _load >= 1
      ? PaceLevel.slowDown
      : _load >= 2 / 3
      ? PaceLevel.busy
      : PaceLevel.calm;

  String get summary =>
      'Sent by hand on LinkedIn: $invitesDay invitation${invitesDay == 1 ? '' : 's'} and $messagesDay '
      'message${messagesDay == 1 ? '' : 's'} today; $invitesWeek and $messagesWeek this week.';

  String get advice => switch (level) {
    PaceLevel.calm => '',
    PaceLevel.busy => 'A busy day. LinkedIn watches for bursts; spread the rest over the week.',
    PaceLevel.slowDown =>
      'Time to slow down. LinkedIn restricts accounts that send this many; wait a day or two before more.',
  };
}

/// A person to get back to: a thread's follow-up or their "keep in touch"
/// date has come.
class FollowUpDue {
  const FollowUpDue(this.contact, this.due, this.why, {this.thread});
  final Lead contact;
  final String due;
  final String why;
  final Conversation? thread;
}

/// Two records that look like one person.
class MergeSuggestion {
  const MergeSuggestion(this.keep, this.other, this.why);
  final Lead keep, other;
  final String why;
}

/// When "keep in touch every N weeks" next comes due for [l], or null.
String? keepInTouchDue(Lead l, String today) {
  final weeks = l.keepInTouchWeeks;
  if (weeks == null || weeks <= 0) return null;
  return addDays(l.lastContact ?? l.foundOn ?? today, weeks * 7);
}

/// The local time [d] as yyyy-MM-ddTHH:mm, the form messages are stored in.
String _stamp(DateTime d) => d.toIso8601String().substring(0, 16);

extension ConversationBook on CareerBook {
  // ---- reading ----

  Future<Lead?> contact(String id) =>
      (db.select(db.careerContacts)..where((c) => c.id.equals(id) & c.deleted.not())).getSingleOrNull();

  Future<Conversation> conversation(String id) =>
      (db.select(db.conversations)..where((c) => c.id.equals(id))).getSingle();

  /// A person's threads on every channel, newest first.
  Future<List<Conversation>> conversationsOf(String contactId) =>
      (db.select(db.conversations)
            ..where((c) => c.contactId.equals(contactId) & c.deleted.not())
            ..orderBy([(c) => OrderingTerm.desc(c.lastAt)]))
          .get();

  /// The thread with a channel's own id, so a fetch or an import adds to it.
  Future<Conversation?> threadByExternalId(String channel, String externalId) =>
      (db.select(db.conversations)
            ..where((c) => c.channel.equals(channel) & c.externalId.equals(externalId) & c.deleted.not())
            ..limit(1))
          .getSingleOrNull();

  /// A thread's messages and notes, oldest first.
  Future<List<ThreadMessage>> messagesIn(String conversationId) =>
      (db.select(db.messages)
            ..where((m) => m.conversationId.equals(conversationId) & m.deleted.not())
            ..orderBy([(m) => OrderingTerm(expression: m.sentAt)]))
          .get();

  Future<List<ContactHandle>> handlesOf(String contactId) =>
      (db.select(db.contactHandles)
            ..where((h) => h.contactId.equals(contactId) & h.deleted.not())
            ..orderBy([(h) => OrderingTerm(expression: h.channel)]))
          .get();

  /// Every thread with its person and newest message, newest first.
  Future<List<ThreadRow>> threadRows() async {
    final threads =
        await (db.select(db.conversations)
              ..where((c) => c.deleted.not())
              ..orderBy([(c) => OrderingTerm.desc(c.lastAt)]))
            .get();
    final people = {
      for (final c in await (db.select(db.careerContacts)..where((c) => c.deleted.not())).get()) c.id: c,
    };
    final last = <String, ThreadMessage>{};
    final all =
        await (db.select(db.messages)
              ..where((m) => m.deleted.not())
              ..orderBy([(m) => OrderingTerm(expression: m.sentAt)]))
            .get();
    for (final m in all) {
      last[m.conversationId] = m;
    }
    return [
      for (final t in threads)
        // A thread whose person was deleted elsewhere waits in the Screener.
        ThreadRow(t, t.contactId == null ? null : people[t.contactId], last[t.id]),
    ];
  }

  /// [threadRows] narrowed as [filterThreads] does.
  Future<List<ThreadRow>> threads({
    ThreadFilter filter = ThreadFilter.all,
    required String today,
    String? channel,
    String? jobId,
    bool screener = false,
  }) async => filterThreads(
    await threadRows(),
    filter: filter,
    today: today,
    channel: channel,
    jobId: jobId,
    screener: screener,
  );

  // ---- writing ----

  /// Starts a thread with a person (or, with no [contactId], an unknown
  /// sender for the Screener) and records their identity on that channel.
  Future<String> startConversation({
    String? contactId,
    required String channel,
    String account = '',
    String mode = 'manual',
    String subject = '',
    String peer = '',
    String? jobId,
    String? externalId,
    required String at,
  }) => db.transaction(() async {
    final id = newId();
    await save(
      db.conversations,
      ConversationsCompanion.insert(
        id: id,
        contactId: Value(contactId),
        channel: channel,
        account: Value(account),
        mode: Value(mode),
        externalId: Value(externalId),
        peer: Value(peer),
        subject: Value(subject),
        jobId: Value(jobId),
        lastAt: at,
      ),
      id,
    );
    if (contactId != null) {
      final c = await contact(contactId);
      if (c != null) await syncHandles(c);
    }
    return id;
  });

  /// Adds a message or note to a thread and moves the thread on: an
  /// outgoing message waits for a reply (chase in a week), an incoming one
  /// needs an answer. With an [externalId] already in the thread nothing is
  /// added and null comes back.
  Future<String?> addMessage(
    String conversationId, {
    required String direction,
    required String body,
    required String at,
    String source = 'manual',
    String? status,
    String? externalId,
    String? inReplyTo,
    String? draftOf,
  }) => db.transaction(() async {
    final t = await conversation(conversationId);
    if (direction == 'out' && t.contactId != null) {
      final c = await contact(t.contactId!);
      if (c != null && c.doNotContact) throw DoNotContactException(c.name);
    }
    if (externalId != null) {
      final seen =
          await (db.select(db.messages)..where(
                (m) =>
                    m.conversationId.equals(conversationId) &
                    m.externalId.equals(externalId) &
                    m.deleted.not(),
              ))
              .get();
      if (seen.isNotEmpty) return null;
    }
    final id = newId();
    await save(
      db.messages,
      MessagesCompanion.insert(
        id: id,
        conversationId: conversationId,
        direction: direction,
        body: Value(body.trim()),
        sentAt: at,
        source: Value(source),
        status: Value(status ?? (direction == 'in' ? 'received' : 'logged')),
        externalId: Value(externalId),
        inReplyTo: Value(inReplyTo),
        draftOf: Value(draftOf),
      ),
      id,
    );
    final day = at.substring(0, 10);
    await save(
      db.conversations,
      t.copyWith(
        lastAt: at.compareTo(t.lastAt) > 0 ? at : t.lastAt,
        status: switch (direction) {
          'out' => 'awaiting_reply',
          'in' => 'replied',
          _ => t.status,
        },
        followUp: switch (direction) {
          'out' => Value(addDays(day, 7)),
          'in' => const Value(null),
          _ => Value(t.followUp),
        },
        unread: direction == 'in' && source == 'api' ? t.unread + 1 : t.unread,
      ),
      t.id,
    );
    if (t.contactId != null) await refreshContact(t.contactId!, today: day);
    return id;
  });

  /// Logs a message the user sent by hand (on LinkedIn, by phone...). A
  /// LinkedIn connection note is an [invite], which the pace guard counts
  /// apart.
  Future<String> logSent(
    String conversationId,
    String body, {
    required String at,
    bool invite = false,
  }) async => (await addMessage(
    conversationId,
    direction: 'out',
    body: body,
    at: at,
    status: invite ? 'invite' : 'logged',
  ))!;

  /// Logs a reply the user pasted in.
  Future<String> logReply(String conversationId, String body, {required String at}) async =>
      (await addMessage(conversationId, direction: 'in', body: body, at: at))!;

  Future<String> addNote(String conversationId, String body, {required String at}) async =>
      (await addMessage(conversationId, direction: 'note', body: body, at: at))!;

  /// Sets a thread's status and, when given, its follow-up date (null
  /// clears it). A follow-up date with no status marks it to follow up.
  Future<void> setThread(
    String id, {
    String? status,
    Value<String?> followUp = const Value.absent(),
    required String today,
  }) => db.transaction(() async {
    final t = await conversation(id);
    final date = followUp.present ? followUp.value : t.followUp;
    await save(
      db.conversations,
      t.copyWith(
        status: status ?? (followUp.present && date != null ? 'follow_up' : t.status),
        followUp: Value(status == 'closed' ? null : date),
        unread: status == 'closed' ? 0 : t.unread,
      ),
      id,
    );
    if (t.contactId != null) await refreshContact(t.contactId!, today: today);
  });

  /// Links a thread to the job it is about (null unlinks it).
  Future<void> linkJob(String id, String? jobId) async {
    final t = await conversation(id);
    await save(db.conversations, t.copyWith(jobId: Value(jobId)), id);
  }

  /// Marks a thread read.
  Future<void> markRead(String id) async {
    final t = await conversation(id);
    if (t.unread != 0) await save(db.conversations, t.copyWith(unread: 0), id);
  }

  /// Brings the contact's status, last contact and follow-up in line with
  /// their newest thread, so the Contacts and Today pages read them as they
  /// always have. "Keep in touch" fills the follow-up when no thread sets
  /// one.
  Future<void> refreshContact(String contactId, {required String today}) async {
    final c = await contact(contactId);
    if (c == null) return;
    final threads = await conversationsOf(contactId);
    var lastContact = c.lastContact;
    for (final t in threads) {
      final said =
          await (db.select(db.messages)
                ..where(
                  (m) => m.conversationId.equals(t.id) & m.deleted.not() & m.direction.isIn(['in', 'out']),
                )
                ..orderBy([(m) => OrderingTerm.desc(m.sentAt)])
                ..limit(1))
              .getSingleOrNull();
      final day = said?.sentAt.substring(0, 10);
      if (day != null && (lastContact == null || day.compareTo(lastContact) > 0)) lastContact = day;
    }
    final newest = threads.firstOrNull;
    final status = switch (newest?.status) {
      'replied' => 'replied',
      'awaiting_reply' || 'follow_up' => c.status == 'replied' ? 'replied' : 'contacted',
      'closed' => 'cold',
      _ => c.status,
    };
    final keep = keepInTouchDue(c.copyWith(lastContact: Value(lastContact)), today);
    final followUp = newest == null
        ? keep ?? c.followUp
        : newest.status == 'closed'
        ? keep
        : newest.followUp ?? keep;
    if (status == c.status && lastContact == c.lastContact && followUp == c.followUp) return;
    await save(
      db.careerContacts,
      c.copyWith(status: status, lastContact: Value(lastContact), followUp: Value(followUp)),
      c.id,
    );
  }

  /// Sets "keep in touch every [weeks] weeks" (null for off).
  Future<void> setKeepInTouch(String contactId, int? weeks, {required String today}) async {
    final c = await contact(contactId);
    if (c == null) return;
    await save(db.careerContacts, c.copyWith(keepInTouchWeeks: Value(weeks)), c.id);
    await refreshContact(contactId, today: today);
  }

  /// People to get back to on or before [today]: a thread's follow-up or a
  /// "keep in touch" date, the earliest per person, soonest first. People
  /// marked "do not contact" never appear.
  Future<List<FollowUpDue>> dueFollowUps(String today) async {
    final people = await (db.select(
      db.careerContacts,
    )..where((c) => c.deleted.not() & c.doNotContact.not())).get();
    final threads = await (db.select(
      db.conversations,
    )..where((t) => t.deleted.not() & t.contactId.isNotNull() & t.status.equals('closed').not())).get();
    final due = <String, FollowUpDue>{};
    void offer(FollowUpDue d) {
      final had = due[d.contact.id];
      if (d.due.compareTo(today) <= 0 && (had == null || d.due.compareTo(had.due) < 0)) due[d.contact.id] = d;
    }

    final byId = {for (final p in people) p.id: p};
    for (final t in threads) {
      final p = byId[t.contactId];
      if (p == null || t.followUp == null) continue;
      offer(FollowUpDue(p, t.followUp!, 'Follow up on ${channelLabel(t.channel)}', thread: t));
    }
    for (final p in people) {
      final d = keepInTouchDue(p, today);
      if (d != null) offer(FollowUpDue(p, d, 'Keep in touch: ${keepInTouchChoices[p.keepInTouchWeeks]}'));
    }
    return due.values.toList()..sort((a, b) => a.due.compareTo(b.due));
  }

  // ---- the pace guard ----

  /// What the user sent by hand on LinkedIn in the 24 hours and 7 days
  /// before [now].
  Future<Pace> pace(DateTime now) async {
    final linkedIn = await (db.select(
      db.conversations,
    )..where((c) => c.channel.equals('linkedin') & c.deleted.not())).map((c) => c.id).get();
    if (linkedIn.isEmpty) return const Pace();
    final day = _stamp(now.subtract(const Duration(days: 1)));
    final week = _stamp(now.subtract(const Duration(days: 7)));
    final sent =
        await (db.select(db.messages)..where(
              (m) =>
                  m.conversationId.isIn(linkedIn) &
                  m.deleted.not() &
                  m.direction.equals('out') &
                  m.source.equals('manual') &
                  m.sentAt.isBiggerThanValue(week),
            ))
            .get();
    bool today(ThreadMessage m) => m.sentAt.compareTo(day) > 0;
    final invites = sent.where((m) => m.status == 'invite');
    final messages = sent.where((m) => m.status != 'invite');
    return Pace(
      invitesDay: invites.where(today).length,
      invitesWeek: invites.length,
      messagesDay: messages.where(today).length,
      messagesWeek: messages.length,
    );
  }

  // ---- handles ----

  /// Records an identity for a person unless they have it already. Returns
  /// its id.
  Future<String> addHandle(
    String contactId,
    String channel,
    String handle, {
    String account = '',
    bool primary = false,
  }) async {
    final key = handleKey(channel, handle);
    for (final h in await handlesOf(contactId)) {
      if (handleKey(h.channel, h.handle) == key) return h.id;
    }
    final id = newId();
    await save(
      db.contactHandles,
      ContactHandlesCompanion.insert(
        id: id,
        contactId: contactId,
        channel: channel,
        handle: handle.trim(),
        account: Value(account),
        primary: Value(primary),
      ),
      id,
    );
    return id;
  }

  /// Makes sure the e-mail, LinkedIn profile and phone on a contact record
  /// are among their handles.
  Future<void> syncHandles(Lead l) async {
    final have = await handlesOf(l.id);
    for (final f in fieldHandles(l)) {
      final first = !have.any((h) => h.channel == f.channel);
      await addHandle(l.id, f.channel, f.handle, primary: first);
    }
  }

  // ---- compliance ----

  /// Marks a person "do not contact" (or clears it). Their threads close;
  /// their follow-ups stop.
  Future<void> setDoNotContact(String contactId, bool on, {required String today}) =>
      db.transaction(() async {
        final c = await contact(contactId);
        if (c == null) return;
        await save(
          db.careerContacts,
          c.copyWith(doNotContact: on, followUp: on ? const Value(null) : Value(c.followUp)),
          c.id,
        );
        if (on) {
          for (final t in await conversationsOf(contactId)) {
            await save(db.conversations, t.copyWith(status: 'closed', followUp: const Value(null)), t.id);
          }
        }
      });

  /// Forgets a person: their record, handles, threads and messages are
  /// emptied and deleted, and the deletes sync to every device. Nothing of
  /// what they said stays in the synced copy.
  Future<void> forgetContact(String contactId) => db.transaction(() async {
    final threads = await (db.select(db.conversations)..where((t) => t.contactId.equals(contactId))).get();
    for (final t in threads) {
      for (final m in await (db.select(db.messages)..where((m) => m.conversationId.equals(t.id))).get()) {
        await save(
          db.messages,
          m.copyWith(body: '', externalId: const Value(null), inReplyTo: const Value(null)),
          m.id,
        );
        await remove(db.messages, m.id);
      }
      await save(
        db.conversations,
        t.copyWith(subject: '', peer: '', externalId: const Value(null), followUp: const Value(null)),
        t.id,
      );
      await remove(db.conversations, t.id);
    }
    for (final h in await (db.select(db.contactHandles)..where((h) => h.contactId.equals(contactId))).get()) {
      await save(db.contactHandles, h.copyWith(handle: ''), h.id);
      await remove(db.contactHandles, h.id);
    }
    final c = await (db.select(db.careerContacts)..where((c) => c.id.equals(contactId))).getSingleOrNull();
    if (c == null) return;
    await save(
      db.careerContacts,
      c.copyWith(
        name: '',
        title: '',
        company: '',
        email: '',
        phone: '',
        linkedin: '',
        source: '',
        sourceUrl: '',
        notes: '',
        basisNote: '',
        followUp: const Value(null),
        lastContact: const Value(null),
      ),
      c.id,
    );
    await remove(db.careerContacts, c.id);
  });

  // ---- one person, many records ----

  /// Records that look like the same person: the same e-mail address, the
  /// same LinkedIn profile, or the same name at the same organisation. The
  /// user confirms each merge.
  Future<List<MergeSuggestion>> mergeSuggestions() async {
    final people =
        await (db.select(db.careerContacts)
              ..where((c) => c.deleted.not())
              ..orderBy([(c) => OrderingTerm(expression: c.id)]))
            .get();
    final handles = await (db.select(db.contactHandles)..where((h) => h.deleted.not())).get();
    final groups = <String, List<Lead>>{};
    void put(String key, Lead l) {
      if (key.isEmpty || key.endsWith(':')) return;
      final g = groups.putIfAbsent(key, () => []);
      if (!g.contains(l)) g.add(l);
    }

    final byId = {for (final p in people) p.id: p};
    for (final p in people) {
      for (final h in fieldHandles(p)) {
        if (h.channel != 'phone') put(handleKey(h.channel, h.handle), p);
      }
      if (p.company.trim().isNotEmpty) put('name:${_nameKey(p.name, p.company)}', p);
    }
    for (final h in handles) {
      final p = byId[h.contactId];
      if (p == null || (h.channel != 'email' && h.channel != 'linkedin')) continue;
      put(handleKey(h.channel, h.handle), p);
    }
    final seen = <String>{};
    final out = <MergeSuggestion>[];
    for (final MapEntry(key: key, value: g) in groups.entries) {
      if (g.length < 2) continue;
      final why = key.startsWith('email:')
          ? 'Same e-mail address'
          : key.startsWith('linkedin:')
          ? 'Same LinkedIn profile'
          : 'Same name and organisation';
      for (final other in g.skip(1)) {
        final pair = '${g.first.id}|${other.id}';
        if (seen.add(pair)) out.add(MergeSuggestion(g.first, other, why));
      }
    }
    return out;
  }

  /// Merges [otherId] into [keepId]: handles, threads and their messages
  /// move across, empty fields fill from the other record, and the other
  /// record is deleted. "Do not contact" on either carries over.
  Future<void> mergeContacts({required String keepId, required String otherId, required String today}) =>
      db.transaction(() async {
        final keep = await contact(keepId);
        final other = await contact(otherId);
        if (keep == null || other == null || keepId == otherId) return;
        String pick(String a, String b) => a.trim().isEmpty ? b : a;
        final found = [keep.foundOn, other.foundOn].whereType<String>().toList()..sort();
        await save(
          db.careerContacts,
          keep.copyWith(
            title: pick(keep.title, other.title),
            company: pick(keep.company, other.company),
            email: pick(keep.email, other.email),
            phone: pick(keep.phone, other.phone),
            linkedin: pick(keep.linkedin, other.linkedin),
            source: pick(keep.source, other.source),
            sourceUrl: pick(keep.sourceUrl, other.sourceUrl),
            sourceKind: keep.sourceKind == 'other' ? other.sourceKind : keep.sourceKind,
            foundOn: Value(found.firstOrNull),
            basisNote: pick(keep.basisNote, other.basisNote),
            jobId: Value(keep.jobId ?? other.jobId),
            keepInTouchWeeks: Value(keep.keepInTouchWeeks ?? other.keepInTouchWeeks),
            doNotContact: keep.doNotContact || other.doNotContact,
            notes: [keep.notes, other.notes].where((n) => n.trim().isNotEmpty).toSet().join('\n'),
          ),
          keep.id,
        );
        final have = {for (final h in await handlesOf(keepId)) handleKey(h.channel, h.handle)};
        for (final h in await handlesOf(otherId)) {
          if (have.add(handleKey(h.channel, h.handle))) {
            await save(db.contactHandles, h.copyWith(contactId: keepId, primary: false), h.id);
          } else {
            await remove(db.contactHandles, h.id);
          }
        }
        for (final t in await conversationsOf(otherId)) {
          await save(db.conversations, t.copyWith(contactId: Value(keepId)), t.id);
        }
        await remove(db.careerContacts, otherId);
        final merged = (await contact(keepId))!;
        await syncHandles(merged);
        await refreshContact(keepId, today: today);
      });

  // ---- the Screener ----

  /// Makes an unknown sender a contact (they got in touch, so that is the
  /// basis) and moves their thread out of the Screener. Returns the new
  /// contact's id.
  Future<String> addFromScreener(
    String conversationId, {
    required String name,
    String title = '',
    String company = '',
    String kind = 'other',
    required String today,
  }) => db.transaction(() async {
    final t = await conversation(conversationId);
    final id = newId();
    await save(
      db.careerContacts,
      CareerContactsCompanion.insert(
        id: id,
        name: name.trim(),
        kind: Value(kind),
        title: Value(title.trim()),
        company: Value(company.trim()),
        email: Value(t.channel == 'email' ? t.peer : ''),
        linkedin: Value(t.channel == 'linkedin' ? t.peer : ''),
        sourceKind: const Value('inbound'),
        foundOn: Value(today),
        basis: const Value('they_contacted'),
      ),
      id,
    );
    await save(db.conversations, t.copyWith(contactId: Value(id)), t.id);
    if (t.peer.isNotEmpty) await addHandle(id, t.channel, t.peer, account: t.account, primary: true);
    await refreshContact(id, today: today);
    return id;
  });

  /// Drops a Screener thread and its messages.
  Future<void> ignoreScreener(String conversationId) => db.transaction(() async {
    for (final m in await messagesIn(conversationId)) {
      await remove(db.messages, m.id);
    }
    await remove(db.conversations, conversationId);
  });
}
