// Conversations (schema 4): threads on every channel, contact provenance
// and the compliance tools. Every person here is made up.
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/insights.dart';

import 'support.dart';

/// Adds a made-up contact and returns its id.
Future<String> person(
  CareerBook book,
  String name, {
  String company = 'Example Health Trust',
  String title = 'Practice Manager',
  String email = '',
  String linkedin = '',
  String source = '',
  String sourceKind = 'other',
  String? foundOn,
}) async {
  final id = newId();
  await book.save(
    book.db.careerContacts,
    CareerContactsCompanion.insert(
      id: id,
      name: name,
      title: Value(title),
      company: Value(company),
      email: Value(email),
      linkedin: Value(linkedin),
      source: Value(source),
      sourceKind: Value(sourceKind),
      foundOn: Value(foundOn),
    ),
    id,
  );
  return id;
}

void main() {
  group('conversations', () {
    late CareerBook book;
    setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
    tearDown(() => book.db.close());

    test('a logged message waits for a reply; a pasted reply needs an answer', () async {
      final jo = await person(
        book,
        'Jordan Example',
        linkedin: 'https://www.linkedin.com/in/jordan-example/',
      );
      final t = await book.startConversation(contactId: jo, channel: 'linkedin', at: '2026-11-10T09:00');
      expect((await book.conversation(t)).status, 'draft');
      expect((await book.handlesOf(jo)).single.channel, 'linkedin');

      await book.logSent(t, 'Hello Jordan', at: '2026-11-10T09:05');
      var c = await book.conversation(t);
      expect((c.status, c.followUp, c.lastAt), ('awaiting_reply', '2026-11-17', '2026-11-10T09:05'));
      var lead = (await book.contact(jo))!;
      expect((lead.status, lead.lastContact, lead.followUp), ('contacted', '2026-11-10', '2026-11-17'));

      await book.logReply(t, 'Happy to talk', at: '2026-11-12T14:00');
      c = await book.conversation(t);
      expect((c.status, c.followUp), ('replied', null));
      lead = (await book.contact(jo))!;
      expect((lead.status, lead.lastContact, lead.followUp), ('replied', '2026-11-12', null));

      await book.addNote(t, 'Prefers mornings', at: '2026-11-12T15:00');
      final ms = await book.messagesIn(t);
      expect(ms.map((m) => (m.direction, m.source, m.status)), [
        ('out', 'manual', 'logged'),
        ('in', 'manual', 'received'),
        ('note', 'manual', 'logged'),
      ]);
      // A note is not contact: the last contact stays the reply.
      expect((await book.contact(jo))!.lastContact, '2026-11-12');
    });

    test('a message with a known provider id is stored once', () async {
      final jo = await person(book, 'Jordan Example', email: 'jordan@example-trust.nhs.uk');
      final t = await book.startConversation(
        contactId: jo,
        channel: 'email',
        mode: 'api',
        externalId: 'thread-1',
        at: '2026-11-10T09:00',
      );
      Future<String?> add() => book.addMessage(
        t,
        direction: 'in',
        body: 'Hi',
        at: '2026-11-10T10:00',
        source: 'api',
        externalId: '<m1@example>',
      );
      expect(await add(), isNotNull);
      expect(await add(), isNull);
      expect(await book.messagesIn(t), hasLength(1));
      expect((await book.conversation(t)).unread, 1);
      expect((await book.threadByExternalId('email', 'thread-1'))?.id, t);
    });

    test('status, follow-up and job link; the contact follows the newest thread', () async {
      final sam = await person(book, 'Sam Sample');
      final job = (await book.importPostings([samplePosting()], sampleProfile, today: '2026-11-01')).single;
      final t = await book.startConversation(contactId: sam, channel: 'email', at: '2026-11-01T09:00');
      await book.logSent(t, 'Hello', at: '2026-11-01T09:00');
      await book.setThread(t, followUp: const Value('2026-11-05'), today: '2026-11-02');
      var c = await book.conversation(t);
      expect((c.status, c.followUp), ('follow_up', '2026-11-05'));
      expect((await book.contact(sam))!.followUp, '2026-11-05');
      await book.linkJob(t, job);
      expect((await book.conversation(t)).jobId, job);
      await book.setThread(t, status: 'closed', today: '2026-11-06');
      c = await book.conversation(t);
      expect((c.status, c.followUp), ('closed', null));
      final lead = (await book.contact(sam))!;
      expect((lead.status, lead.followUp), ('cold', null));
    });

    test('the list sorts by time and filters by reply, follow-up, channel, job and Screener', () async {
      final jo = await person(book, 'Jordan Example');
      final sam = await person(book, 'Sam Sample');
      final job = (await book.importPostings([samplePosting()], sampleProfile, today: '2026-11-01')).single;
      final a = await book.startConversation(contactId: jo, channel: 'linkedin', at: '2026-11-01T09:00');
      await book.logSent(a, 'Hello', at: '2026-11-01T09:00');
      final b = await book.startConversation(
        contactId: sam,
        channel: 'email',
        jobId: job,
        at: '2026-11-02T09:00',
      );
      await book.logReply(b, 'Thanks for your note', at: '2026-11-03T09:00');
      final s = await book.startConversation(
        channel: 'email',
        peer: 'someone@example.org',
        mode: 'api',
        at: '2026-11-04T09:00',
      );

      Future<List<String>> ids({
        ThreadFilter filter = ThreadFilter.all,
        String? channel,
        String? jobId,
        bool screener = false,
      }) async => [
        for (final r in await book.threads(
          filter: filter,
          today: '2026-11-08',
          channel: channel,
          jobId: jobId,
          screener: screener,
        ))
          r.thread.id,
      ];

      expect(await ids(), [b, a]);
      expect(await ids(filter: ThreadFilter.needsReply), [b]);
      expect(await ids(filter: ThreadFilter.followUpDue), [a]);
      expect(await ids(channel: 'linkedin'), [a]);
      expect(await ids(jobId: job), [b]);
      expect(await ids(screener: true), [s]);
      final row = (await book.threadRows()).firstWhere((r) => r.thread.id == b);
      expect((row.contact?.name, row.last?.body), ('Sam Sample', 'Thanks for your note'));
    });

    test('the pace guard counts hand-sent LinkedIn invites and messages and only advises', () async {
      final now = DateTime(2026, 11, 15, 12);
      String at(Duration ago) => now.subtract(ago).toIso8601String().substring(0, 16);
      expect((await book.pace(now)).level, PaceLevel.calm);
      final jo = await person(book, 'Jordan Example');
      final li = await book.startConversation(
        contactId: jo,
        channel: 'linkedin',
        at: at(const Duration(days: 9)),
      );
      final mail = await book.startConversation(
        contactId: jo,
        channel: 'email',
        at: at(const Duration(days: 9)),
      );
      await book.logSent(li, 'Old invite', at: at(const Duration(days: 8)), invite: true);
      for (var i = 0; i < 3; i++) {
        await book.logSent(li, 'Invite $i', at: at(Duration(days: 3, minutes: i)), invite: true);
      }
      for (var i = 0; i < 10; i++) {
        await book.logSent(li, 'Invite today $i', at: at(Duration(hours: 2, minutes: i)), invite: true);
      }
      await book.logSent(li, 'A message', at: at(const Duration(hours: 1)));
      await book.logSent(mail, 'Not LinkedIn', at: at(const Duration(hours: 1)));
      var p = await book.pace(now);
      expect((p.invitesDay, p.invitesWeek, p.messagesDay, p.messagesWeek), (10, 13, 1, 1));
      expect(p.level, PaceLevel.busy);
      expect(p.advice, isNotEmpty);
      for (var i = 0; i < 5; i++) {
        await book.logSent(li, 'More $i', at: at(Duration(minutes: 30 + i)), invite: true);
      }
      p = await book.pace(now);
      expect(p.level, PaceLevel.slowDown);
      // Never a block: the next one still logs.
      await book.logSent(li, 'One more', at: at(const Duration(minutes: 5)), invite: true);
      expect((await book.pace(now)).invitesDay, 16);
    });

    test('keep in touch sets the follow-up and lists who is due', () async {
      final jo = await person(book, 'Jordan Example', foundOn: '2026-09-01');
      final sam = await person(book, 'Sam Sample');
      await book.setKeepInTouch(jo, 4, today: '2026-09-01');
      expect((await book.contact(jo))!.followUp, '2026-09-29');
      expect(await book.dueFollowUps('2026-09-20'), isEmpty);
      final due = await book.dueFollowUps('2026-10-01');
      expect(due.single.contact.id, jo);
      expect(due.single.why, contains('4 weeks'));

      // A message moves "keep in touch" on from the last contact.
      final t = await book.startConversation(contactId: jo, channel: 'phone', at: '2026-10-02T10:00');
      await book.logSent(t, 'Called to catch up', at: '2026-10-02T10:00');
      await book.setThread(t, status: 'closed', today: '2026-10-02');
      expect((await book.contact(jo))!.followUp, '2026-10-30');

      // A thread's own follow-up counts too.
      final u = await book.startConversation(contactId: sam, channel: 'email', at: '2026-10-01T09:00');
      await book.logSent(u, 'Hello', at: '2026-10-01T09:00');
      expect((await book.dueFollowUps('2026-10-08')).map((d) => d.contact.name), ['Sam Sample']);
      expect((await book.dueFollowUps('2026-11-01')).map((d) => d.contact.name), [
        'Sam Sample',
        'Jordan Example',
      ]);
    });
  });

  group('contacts done properly', () {
    late CareerBook book;
    setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
    tearDown(() => book.db.close());

    test('work and personal e-mail addresses', () {
      for (final a in ['a@nhs.net', 'b@leedsth.nhs.uk', 'c@dhsc.gov.uk', 'd@example-health.co.uk']) {
        expect(emailKind(a), 'work', reason: a);
      }
      for (final a in [
        'a@gmail.com',
        'b@outlook.com',
        'c@hotmail.co.uk',
        'd@yahoo.co.uk',
        'e@icloud.com',
        'f@aol.com',
        'g@proton.me',
        'h@btinternet.com',
      ]) {
        expect(emailKind(a), 'personal', reason: a);
      }
      expect(emailKind(''), '');
    });

    test('the header names who, the role, the channel and where they were found', () async {
      final jo = await person(
        book,
        'Jordan Example',
        source: 'NHS Jobs advert',
        sourceKind: 'advert',
        foundOn: '2026-11-10',
      );
      final t = await book.startConversation(
        contactId: jo,
        channel: 'email',
        account: 'you@example.org',
        at: '2026-11-11T09:00',
      );
      expect(
        threadHeader(await book.conversation(t), await book.contact(jo)),
        'To Jordan Example · Practice Manager, Example Health Trust · via Email · you@example.org · '
        'found on NHS Jobs advert, 10 Nov 2026',
      );
      final bare = await person(book, 'Sam Sample', company: '', title: '');
      final u = await book.startConversation(contactId: bare, channel: 'phone', at: '2026-11-11T09:00');
      expect(threadHeader(await book.conversation(u), await book.contact(bare)), 'To Sam Sample · via Phone');
    });

    test('the Article 14 line says where the name was found', () async {
      final jo = (await book.contact(await person(book, 'Jordan Example', sourceKind: 'team_page')))!;
      expect(howIFoundYou(jo), startsWith("I came across your name on your organisation's team page."));
      final met = (await book.contact(await person(book, 'Sam Sample', sourceKind: 'met')))!;
      expect(howIFoundYou(met), '');
    });

    test(
      'forgetting a person deletes them, their handles, threads and messages, and the deletes sync',
      () async {
        final jo = await person(book, 'Jordan Example', email: 'jordan@example.org');
        final keep = await person(book, 'Sam Sample');
        final t = await book.startConversation(contactId: jo, channel: 'email', at: '2026-11-01T09:00');
        await book.logSent(t, 'Private words', at: '2026-11-01T09:00');
        final other = await book.startConversation(contactId: keep, channel: 'phone', at: '2026-11-01T09:00');
        await book.db.customStatement('DELETE FROM outbox');

        await book.forgetContact(jo);
        final db = book.db;
        final contact = await (db.select(db.careerContacts)..where((c) => c.id.equals(jo))).getSingle();
        expect((contact.deleted, contact.name, contact.email), (true, '', ''));
        final threads = await (db.select(db.conversations)..where((c) => c.contactId.equals(jo))).get();
        expect(threads.single.deleted, isTrue);
        final ms = await (db.select(db.messages)..where((m) => m.conversationId.equals(t))).get();
        expect((ms.single.deleted, ms.single.body), (true, ''));
        final hs = await (db.select(db.contactHandles)..where((h) => h.contactId.equals(jo))).get();
        expect(hs.every((h) => h.deleted && h.handle.isEmpty), isTrue);
        final queued = await db
            .customSelect('SELECT entity FROM outbox')
            .map((r) => r.read<String>('entity'))
            .get();
        expect(queued.toSet(), {
          'career_contacts',
          'career_conversations',
          'career_messages',
          'career_handles',
        });
        expect((await book.conversation(other)).deleted, isFalse);
        expect(await book.contact(keep), isNotNull);
      },
    );

    test('do not contact blocks messages and lead imports of the same address or profile', () async {
      final jo = await person(
        book,
        'Jordan Example',
        email: 'Jordan@Example.org',
        linkedin: 'https://uk.linkedin.com/in/jordan-example/',
      );
      final t = await book.startConversation(contactId: jo, channel: 'email', at: '2026-11-01T09:00');
      await book.setDoNotContact(jo, true, today: '2026-11-02');
      final c = (await book.contact(jo))!;
      expect((c.doNotContact, c.followUp), (true, null));
      expect((await book.conversation(t)).status, 'closed');
      await expectLater(
        book.logSent(t, 'Hello', at: '2026-11-02T09:00'),
        throwsA(isA<DoNotContactException>()),
      );
      // A reply can still be logged: they may write to the user.
      await book.logReply(t, 'Please remove me', at: '2026-11-02T10:00');

      final added = await book.importLeads([
        const LeadSuggestion({
          'name': 'J. Example',
          'company': 'Another Trust',
          'email': 'jordan@example.org',
        }),
        const LeadSuggestion({
          'name': 'Jordan E',
          'company': 'Elsewhere',
          'linkedin': 'https://www.linkedin.com/in/jordan-example',
        }),
        const LeadSuggestion({'name': 'Sam Sample', 'company': 'Example Health Trust', 'kind': 'recruiter'}),
      ], today: '2026-11-03');
      expect(added, 1);
      final sam = (await book.db.select(book.db.careerContacts).get()).firstWhere(
        (l) => l.name == 'Sam Sample',
      );
      expect((sam.foundOn, sam.sourceKind, sam.basis), ('2026-11-03', 'other', 'legitimate_interest'));
      expect(
        await book.dueFollowUps('2026-12-01'),
        everyElement(isNot(predicate((FollowUpDue d) => d.contact.id == jo))),
      );
    });

    test('duplicates are suggested and a confirmed merge moves handles, threads and messages', () async {
      final a = await person(book, 'Jordan Example', email: 'jordan@example.org');
      final b = await person(
        book,
        'Jordan Example',
        company: 'Example Health Trust',
        linkedin: 'https://www.linkedin.com/in/jordan-example',
      );
      final c = await person(book, 'Sam Sample', company: 'Sample Care Group', email: 'sam@example.org');
      final d = await person(book, 'Samantha Sample', company: 'Elsewhere', email: 'SAM@example.org');
      final suggestions = await book.mergeSuggestions();
      final pairs = {
        for (final s in suggestions) ({s.keep.id, s.other.id}, s.why),
      };
      expect(
        pairs.map((p) => p.$1),
        containsAll([
          {a, b},
          {c, d},
        ]),
      );
      expect(suggestions.firstWhere((s) => {s.keep.id, s.other.id}.contains(c)).why, 'Same e-mail address');
      expect(
        suggestions.firstWhere((s) => {s.keep.id, s.other.id}.contains(a)).why,
        'Same name and organisation',
      );

      final t = await book.startConversation(contactId: b, channel: 'linkedin', at: '2026-11-01T09:00');
      await book.logSent(t, 'Hello', at: '2026-11-01T09:00');
      await book.mergeContacts(keepId: a, otherId: b, today: '2026-11-02');
      final kept = (await book.contact(a))!;
      expect(
        (kept.email, kept.linkedin, kept.status),
        ('jordan@example.org', 'https://www.linkedin.com/in/jordan-example', 'contacted'),
      );
      expect(await book.contact(b), isNull);
      expect((await book.conversation(t)).contactId, a);
      expect((await book.messagesIn(t)).single.body, 'Hello');
      expect((await book.handlesOf(a)).map((h) => h.channel).toSet(), {'email', 'linkedin'});
      expect(await book.handlesOf(b), isEmpty);
      expect((await book.mergeSuggestions()).where((s) => {s.keep.id, s.other.id}.contains(a)), isEmpty);
    });

    test('a Screener sender becomes a contact who got in touch, or is ignored', () async {
      final s = await book.startConversation(
        channel: 'email',
        peer: 'sam@example.org',
        mode: 'api',
        at: '2026-11-01T09:00',
      );
      await book.addMessage(
        s,
        direction: 'in',
        body: 'Are you open to roles?',
        at: '2026-11-01T09:00',
        source: 'api',
      );
      final id = await book.addFromScreener(
        s,
        name: 'Sam Sample',
        company: 'Sample Care Group',
        today: '2026-11-01',
      );
      final c = (await book.contact(id))!;
      expect(
        (c.email, c.basis, c.sourceKind, c.status),
        ('sam@example.org', 'they_contacted', 'inbound', 'replied'),
      );
      expect((await book.conversation(s)).contactId, id);
      expect(await book.threads(today: '2026-11-01', screener: true), isEmpty);

      final junk = await book.startConversation(
        channel: 'email',
        peer: 'x@example.org',
        at: '2026-11-01T09:00',
      );
      await book.ignoreScreener(junk);
      expect((await book.conversation(junk)).deleted, isTrue);
    });
  });

  test('a schema 3 database gains conversations and keeps its contacts', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    // Back to schema 3: no conversation tables, no provenance columns.
    for (final t in ['career_handles', 'career_conversations', 'career_messages']) {
      await db.customStatement('DROP TABLE $t');
    }
    for (final c in [
      'source_url',
      'source_kind',
      'found_on',
      'basis',
      'basis_note',
      'do_not_contact',
      'keep_in_touch_weeks',
    ]) {
      await db.customStatement('ALTER TABLE career_contacts DROP COLUMN $c');
    }
    await db.customStatement(
      "INSERT INTO career_contacts (id, hlc, deleted, name, kind, title, company, email, phone, linkedin, "
      "source, status, last_contact, follow_up, notes) VALUES ('c1', '', 0, 'Jordan Example', 'recruiter', "
      "'Talent Partner', 'Example Health Trust', 'jordan@example.org', '', '', 'Team page', 'contacted', "
      "'2026-10-01', '2026-10-08', 'Met at a careers fair')",
    );
    await db.customStatement('PRAGMA user_version = 3');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'career_%'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, containsAll(['career_handles', 'career_conversations', 'career_messages']));
    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'career_%'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(
      indexes,
      containsAll([
        'career_handles_contact',
        'career_conversations_contact',
        'career_conversations_last',
        'career_messages_conversation',
      ]),
    );
    final c = await db.select(db.careerContacts).getSingle();
    expect(
      (c.name, c.company, c.email, c.status),
      ('Jordan Example', 'Example Health Trust', 'jordan@example.org', 'contacted'),
    );
    expect((c.lastContact, c.followUp, c.notes), ('2026-10-01', '2026-10-08', 'Met at a careers fair'));
    expect(
      (c.sourceKind, c.basis, c.doNotContact, c.keepInTouchWeeks, c.sourceUrl),
      ('other', 'legitimate_interest', false, null, ''),
    );
    expect(await db.select(db.conversations).get(), isEmpty);
    await db.close();
  });
}
