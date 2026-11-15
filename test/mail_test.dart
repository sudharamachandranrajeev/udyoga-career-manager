// E-mail from the user's own account: reading messages (headers, HTML,
// quoted replies), keeping only mail with saved contacts, threading it, and
// sending replies with the right headers. A fake server stands in for IMAP
// and SMTP; no test touches the network. Every address is made up.
import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/mail.dart';
import 'package:udyoga/domain/mail_sync.dart';

import 'fake_mail.dart';
import 'support.dart';

/// A plain-text message as a server would hold it.
String mail({
  required String id,
  required String from,
  String to = me,
  String subject = 'Digital lead role',
  String body = 'Hello',
  String date = 'Tue, 10 Nov 2026 09:00:00 +0000',
  String inReplyTo = '',
  String references = '',
}) => [
  'From: $from',
  'To: $to',
  'Subject: $subject',
  'Date: $date',
  'Message-ID: $id',
  if (inReplyTo.isNotEmpty) 'In-Reply-To: $inReplyTo',
  if (references.isNotEmpty) 'References: $references',
  'MIME-Version: 1.0',
  'Content-Type: text/plain; charset=utf-8',
  '',
  body,
  '',
].join('\r\n');

Future<String> person(CareerBook book, String name, {String email = ''}) async {
  final id = newId();
  await book.save(
    book.db.careerContacts,
    CareerContactsCompanion.insert(
      id: id,
      name: name,
      email: Value(email),
      company: const Value('Example Trust'),
    ),
    id,
  );
  return id;
}

void main() {
  group('reading mail', () {
    test('headers: ids, threading, encoded subject, To and Cc', () {
      final m = parseMail(
        [
          'From: "Jordan Example" <Jordan@Example.org>',
          'To: alex@example.com',
          'Cc: Kim Peer <kim@example.org>',
          'Subject: =?UTF-8?B?Q2Fmw6kgcm9sZQ==?=',
          'Date: Wed, 11 Nov 2026 10:30:00 +0000',
          'Message-ID: <B2@Example.org>',
          'In-Reply-To: <a1@example.com>',
          'References: <root@example.com>\r\n <a1@example.com>',
          'Content-Type: text/plain; charset=utf-8',
          '',
          'Thanks Alex, Thursday works.',
        ].join('\r\n'),
      );
      expect(m.messageId, '<b2@example.org>');
      expect(m.inReplyTo, '<a1@example.com>');
      expect(m.references, ['<root@example.com>', '<a1@example.com>']);
      expect(m.root, '<root@example.com>');
      expect(m.ancestors.first, '<a1@example.com>');
      expect(m.from, 'jordan@example.org');
      expect(m.fromName, 'Jordan Example');
      expect(m.to, ['alex@example.com', 'kim@example.org']);
      expect(m.subject, 'Café role');
      expect(m.date!.toUtc(), DateTime.utc(2026, 11, 11, 10, 30));
      expect(m.body, 'Thanks Alex, Thursday works.');
      expect(messageIds('<a@x> <A@X> junk <b@y>'), ['<a@x>', '<b@y>']);
    });

    test('HTML-only mail becomes plain text', () {
      expect(
        htmlToText(
          '<html><head><style>p{}</style></head><body><p>Hi&nbsp;Alex,</p><p>Can we talk <b>Friday</b>?<br>'
          'Fish &amp; chips &#163;5</p><ul><li>One</li><li>Two</li></ul><script>x()</script></body></html>',
        ),
        'Hi Alex,\nCan we talk Friday?\nFish & chips £5\n• One\n• Two',
      );
      final m = parseMail(
        [
          'From: jordan@example.org',
          'To: alex@example.com',
          'Message-ID: <h1@example.org>',
          'Content-Type: text/html; charset=utf-8',
          '',
          '<div>Interview on <i>Monday</i>.</div>',
        ].join('\r\n'),
      );
      expect(m.body, 'Interview on Monday.');
    });

    test('quoted replies and signatures are trimmed', () {
      expect(
        trimQuoted('Sounds good.\n\nOn Tue, 10 Nov 2026 at 09:00, Alex <alex@example.com> wrote:\n> Hello'),
        'Sounds good.',
      );
      expect(trimQuoted('Yes.\nOn Tue, 10 Nov 2026 at 09:00, Alex Example\nwrote:\n> Hi'), 'Yes.');
      expect(trimQuoted('Fine.\n\n-----Original Message-----\nFrom: Alex'), 'Fine.');
      expect(trimQuoted('Fine.\n\nFrom: Alex Example\nSent: 10 November 2026\nTo: Jordan'), 'Fine.');
      expect(trimQuoted('Thanks\n-- \nJordan Example\nHead of Digital'), 'Thanks');
      expect(trimQuoted('Agreed.\n\n> earlier\n> text'), 'Agreed.');
      // A quote with an answer below it is kept.
      expect(trimQuoted('> Can you do Thursday?\nYes, Thursday.'), '> Can you do Thursday?\nYes, Thursday.');
    });

    test('a written mail carries its thread headers and reads back the same', () {
      final raw = buildMail(
        fromName: 'Alex Example',
        from: me,
        to: 'jordan@example.org',
        subject: replySubject('Café role'),
        body: 'Thursday at 10 suits me.\nThanks, Alex',
        messageId: '<udyoga.1@example.com>',
        inReplyTo: '<b2@example.org>',
        references: ['<root@example.com>', '<b2@example.org>'],
        date: DateTime.utc(2026, 11, 11, 12),
      );
      expect(raw, contains('In-Reply-To: <b2@example.org>\r\n'));
      expect(raw, contains('References: <root@example.com> <b2@example.org>\r\n'));
      expect(raw, contains('Date: Wed, 11 Nov 2026 12:00:00 +0000'));
      final m = parseMail(raw);
      expect(m.subject, 'Re: Café role');
      expect(m.body, 'Thursday at 10 suits me.\nThanks, Alex');
      expect(m.from, me);
      expect(m.root, '<root@example.com>');
      expect(replySubject('RE: x'), 'RE: x');
      expect(newMessageId('Alex@Example.COM'), matches(RegExp(r'^<udyoga\.[a-z0-9]{16}@example\.com>$')));
    });
  });

  group('sync and send', () {
    late CareerBook book;
    late FakeMailServer server;
    late MemorySecretStore secrets;
    late MailService service;
    var now = DateTime.utc(2026, 11, 12, 9);
    final gmail = ChannelAccount.preset('gmail', me, name: 'Alex Example');

    setUp(() async {
      book = CareerBook(await Store.open(memoryDatabase()));
      server = FakeMailServer();
      secrets = MemorySecretStore();
      now = DateTime.utc(2026, 11, 12, 9);
      service = MailService(book, secrets, server, clock: () => now);
      await service.saveAccount(gmail, password: 'abcd abcd abcd abcd');
    });
    tearDown(() => book.db.close());

    test('accounts stay on the device and the password in the keychain', () async {
      expect(await secrets.read(gmail.secretKey), 'abcdabcdabcdabcd');
      final stored = await book.db.localSetting(mailAccountsKey);
      expect(stored, contains(me));
      expect(stored, isNot(contains('abcd')));
      expect((await service.accounts()).single.imapHost, 'imap.gmail.com');
      await service.test(gmail);
      await expectLater(
        service.test(gmail, password: 'my-google-password'),
        throwsA(isA<MailException>().having((e) => e.message, 'message', contains('2-Step Verification'))),
      );
      await service.removeAccount(gmail);
      expect(await service.accounts(), isEmpty);
      expect(await secrets.read(gmail.secretKey), isNull);
    });

    test('keeps only mail with saved contacts and replies in held threads', () async {
      final jo = await person(book, 'Jordan Example', email: 'jordan@example.org');
      await book.addHandle(jo, 'email', 'j.example@example.net');
      final inbox = server.inbox, sent = server.sentFolder;
      inbox.add(
        1,
        mail(id: '<a1@example.org>', from: 'Jordan Example <jordan@example.org>', body: 'Fancy a chat?'),
      );
      inbox.add(2, mail(id: '<spam@example.com>', from: 'deals@example.com', body: 'Buy now'));
      inbox.add(
        3,
        mail(
          id: '<c3@example.org>',
          from: 'Kim Peer <kim@example.org>',
          body: 'Adding myself here.\n\nOn Tue, 10 Nov 2026, Jordan wrote:\n> Fancy a chat?',
          date: 'Tue, 10 Nov 2026 11:00:00 +0000',
          inReplyTo: '<a1@example.org>',
          references: '<a1@example.org>',
        ),
      );
      inbox.add(
        4,
        mail(
          id: '<d4@example.net>',
          from: 'j.example@example.net',
          subject: 'Other address',
          body: 'From home.',
        ),
        thread: '900',
      );
      sent.add(
        10,
        mail(
          id: '<s1@example.com>',
          from: me,
          to: 'jordan@example.org',
          subject: 'Re: Digital lead role',
          body: 'Yes please.',
          date: 'Tue, 10 Nov 2026 10:00:00 +0000',
          inReplyTo: '<a1@example.org>',
          references: '<a1@example.org>',
        ),
      );
      sent.add(11, mail(id: '<s2@example.com>', from: me, to: 'friend@example.com', body: 'Dinner?'));

      final r = await service.sync(gmail);
      expect(r.added, 4);
      // Mail with strangers was read as headers only, never in full.
      expect(server.fullyRead, unorderedEquals([1, 3, 4, 10]));
      final rows = await book.conversationsOf(jo);
      expect(rows, hasLength(2));
      final main = rows.firstWhere((t) => t.externalId == 'mid:<a1@example.org>');
      expect(main.channel, 'email');
      expect(main.account, me);
      expect(main.subject, 'Digital lead role');
      final said = await book.messagesIn(main.id);
      expect(
        [for (final m in said) (m.direction, m.body, m.source)],
        [('in', 'Fancy a chat?', 'api'), ('out', 'Yes please.', 'api'), ('in', 'Adding myself here.', 'api')],
      );
      expect(rows.firstWhere((t) => t.id != main.id).externalId, 'gm:900');
      // Alerts for inbound mail only, and Kim is named as herself.
      expect([for (final a in r.alerts) a.name], containsAll(['Jordan Example', 'Kim Peer']));
      expect(r.alerts.every((a) => a.preview != 'Yes please.'), isTrue);

      // Next time only what is new is asked for, and nothing doubles.
      inbox.add(
        5,
        mail(
          id: '<e5@example.org>',
          from: 'jordan@example.org',
          body: 'Great, Thursday then.',
          date: 'Wed, 11 Nov 2026 09:00:00 +0000',
          references: '<a1@example.org> <s1@example.com>',
        ),
      );
      server.searches.clear();
      final again = await service.sync((await service.accounts()).single);
      expect(again.added, 1);
      expect(server.searches, ['above 4', 'above 11']);
      expect((await book.messagesIn(main.id)).last.body, 'Great, Thursday then.');

      // A new UIDVALIDITY reads the window again; known ids are skipped.
      server.inbox.validity = 8;
      expect((await service.sync((await service.accounts()).single)).added, 0);
    });

    test('Gmail thread ids group mail without reply headers', () async {
      await person(book, 'Jordan Example', email: 'jordan@example.org');
      server.inbox.add(
        1,
        mail(id: '<g1@example.org>', from: 'jordan@example.org', body: 'One'),
        thread: '77',
      );
      server.inbox.add(
        2,
        mail(
          id: '<g2@example.org>',
          from: 'jordan@example.org',
          body: 'Two',
          date: 'Tue, 10 Nov 2026 10:00:00 +0000',
        ),
        thread: '77',
      );
      await service.sync(gmail);
      final t = (await book.threadByExternalId('email', 'gm:77'))!;
      expect([for (final m in await book.messagesIn(t.id)) m.body], ['One', 'Two']);
    });

    test('a hand-logged thread takes the mail, without doubling what was logged', () async {
      final jo = await person(book, 'Jordan Example', email: 'jordan@example.org');
      final t = await book.startConversation(contactId: jo, channel: 'email', at: '2026-11-10T08:00');
      await book.logSent(t, 'Hello Jordan, about the role.', at: '2026-11-10T09:01');
      server.sentFolder.add(
        1,
        mail(
          id: '<s1@example.com>',
          from: me,
          to: 'jordan@example.org',
          body: 'Hello Jordan, about the role.',
        ),
      );
      server.inbox.add(
        2,
        mail(
          id: '<r1@example.org>',
          from: 'jordan@example.org',
          body: 'Hi Alex',
          date: 'Tue, 10 Nov 2026 12:00:00 +0000',
          inReplyTo: '<s1@example.com>',
        ),
      );
      await service.sync(gmail);
      expect(await book.conversationsOf(jo), hasLength(1));
      expect(
        [for (final m in await book.messagesIn(t)) (m.direction, m.source)],
        [('out', 'manual'), ('in', 'api')],
      );
    });

    test('do-not-contact people still arrive, but nothing can be sent to them', () async {
      final jo = await person(book, 'Jordan Example', email: 'jordan@example.org');
      await book.setDoNotContact(jo, true, today: '2026-11-12');
      server.inbox.add(1, mail(id: '<a1@example.org>', from: 'jordan@example.org', body: 'Still here.'));
      expect((await service.sync(gmail)).added, 1);
      final t = (await book.conversationsOf(jo)).single;
      await expectLater(
        book.sendVia(EmailSender(service, gmail), t.id, 'Hi', at: '2026-11-12T10:00'),
        throwsA(isA<DoNotContactException>()),
      );
      expect(server.sent, isEmpty);
    });

    test('sending: a first mail, a threaded reply, and a failure kept for retry', () async {
      final jo = await person(book, 'Jordan Example', email: 'jordan@example.org');
      final sender = EmailSender(service, gmail);
      final t = await book.startConversation(contactId: jo, channel: 'email', at: '2026-11-12T09:00');
      expect(senderFor(await book.conversation(t), [sender]), sender);

      await book.sendVia(sender, t, 'Hello Jordan', at: '2026-11-12T09:05', subject: 'Digital lead role');
      final first = parseMail(server.sent.single.raw);
      expect(server.sent.single.to, ['jordan@example.org']);
      expect(first.subject, 'Digital lead role');
      expect(first.inReplyTo, isEmpty);
      final out = (await book.messagesIn(t)).single;
      expect(out.status, 'sent');
      expect(out.externalId, first.messageId);
      expect((await book.conversation(t)).account, me);

      // Jordan answers; the reply sync brings it into the same thread.
      server.inbox.add(
        1,
        mail(
          id: '<j1@example.org>',
          from: 'jordan@example.org',
          subject: 'Re: Digital lead role',
          body: 'Happy to talk.',
          inReplyTo: first.messageId,
          references: first.messageId,
          date: 'Thu, 12 Nov 2026 10:00:00 +0000',
        ),
      );
      expect((await service.sync(gmail)).added, 1);
      expect((await book.messagesIn(t)).last.body, 'Happy to talk.');

      await book.sendVia(sender, t, 'Great, Thursday?', at: '2026-11-12T10:30');
      final reply = parseMail(server.sent.last.raw);
      expect(reply.subject, 'Re: Digital lead role');
      expect(reply.inReplyTo, '<j1@example.org>');
      expect(reply.references, [first.messageId, '<j1@example.org>']);

      // The server refuses: the message stays, marked failed, and Retry sends it.
      server.refuseSend = true;
      await expectLater(
        book.sendVia(sender, t, 'Are you there?', at: '2026-11-12T11:00'),
        throwsA(isA<MailException>()),
      );
      final failed = (await book.messagesIn(t)).last;
      expect((failed.body, failed.status), ('Are you there?', 'failed'));
      server.refuseSend = false;
      await book.retrySend(sender, failed.id);
      expect((await book.messagesIn(t)).last.status, 'sent');
      expect(server.sent, hasLength(3));
    });

    test('accounts are checked only when due', () async {
      await person(book, 'Jordan Example', email: 'jordan@example.org');
      server.inbox.add(1, mail(id: '<a1@example.org>', from: 'jordan@example.org'));
      expect((await service.syncDue()).added, 1);
      server.inbox.add(2, mail(id: '<a2@example.org>', from: 'jordan@example.org', body: 'Again'));
      now = now.add(const Duration(minutes: 5));
      expect((await service.syncDue()).added, 0);
      now = now.add(const Duration(minutes: 11));
      expect((await service.syncDue()).added, 1);

      // A broken account is reported without stopping the check.
      await secrets.write(gmail.secretKey, 'wrong');
      final r = await service.syncDue(force: true);
      expect(r.failed.single, contains(me));

      // Alerts follow the account's switch.
      await secrets.write(gmail.secretKey, 'abcdabcdabcdabcd');
      await service.saveAccount((await service.accounts()).single.copyWith(notify: false));
      server.inbox.add(3, mail(id: '<a3@example.org>', from: 'jordan@example.org', body: 'Quiet'));
      final quiet = await service.syncDue(force: true);
      expect(quiet.added, 1);
      expect(quiet.alerts, isEmpty);
    });
  });
}
