// LinkedIn messages and connection requests from the data archive: imported
// threads matched to contacts, never doubled against messages logged by
// hand, and the connections the user has at their target employers. The
// archive is built here; every person in it is made up.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/linkedin_export.dart';
import 'package:udyoga/domain/linkedin_messages.dart';

import 'support.dart';

const _trust = 'Example Teaching Hospitals NHS Foundation Trust';

Uint8List _zip(Map<String, String> files) {
  final archive = Archive();
  for (final e in files.entries) {
    final bytes = utf8.encode(e.value);
    archive.addFile(ArchiveFile('Basic_LinkedInDataExport/${e.key}', bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _messages =
    'CONVERSATION ID,CONVERSATION TITLE,FROM,SENDER PROFILE URL,TO,RECIPIENT PROFILE URLS,DATE,SUBJECT,'
    'CONTENT,FOLDER,IS MESSAGE DRAFT\n'
    'c1,,Alex Example,https://www.linkedin.com/in/alex-example,Jordan Example,'
    'https://www.linkedin.com/in/jordan-example,2026-11-01 09:00:00 UTC,,'
    '"Hi Jordan, I saw the digital lead role and would love to hear more.",INBOX,No\n'
    'c1,,Jordan Example,https://www.linkedin.com/in/jordan-example,Alex Example,'
    'https://www.linkedin.com/in/alex-example,2026-11-02 10:30:00 UTC,,Happy to chat next week.,INBOX,No\n'
    'c2,,Taylor Unknown,https://www.linkedin.com/in/taylor-unknown,Alex Example,'
    'https://www.linkedin.com/in/alex-example,2026-11-05 08:00:00 UTC,,An exciting opportunity!,INBOX,No\n'
    'c3,,Old Sender,https://www.linkedin.com/in/old-sender,Alex Example,'
    'https://www.linkedin.com/in/alex-example,2020-01-01 08:00:00 UTC,,Long ago.,INBOX,No\n'
    'c4,,Spam Sender,https://www.linkedin.com/in/spam-sender,Alex Example,'
    'https://www.linkedin.com/in/alex-example,2026-11-06 08:00:00 UTC,,Buy now,SPAM,No\n'
    'c5,,Alex Example,https://www.linkedin.com/in/alex-example,Jordan Example,'
    'https://www.linkedin.com/in/jordan-example,2026-11-07 08:00:00 UTC,,Unsent draft,INBOX,Yes\n';

const _invitations =
    'From,To,Sent At,Message,Direction,inviterProfileUrl,inviteeProfileUrl\n'
    'Alex Example,Sam Sample,"11/3/26, 2:15 PM",Hello Sam,OUTGOING,https://www.linkedin.com/in/alex-example,'
    'https://www.linkedin.com/in/sam-sample\n'
    'Casey Inbound,Alex Example,"11/4/26, 9:00 AM",,INCOMING,https://www.linkedin.com/in/casey-inbound,'
    'https://www.linkedin.com/in/alex-example\n';

Uint8List _export() => _zip({
  'Profile.csv': 'First Name,Last Name,Headline\nAlex,Example,Practice administrator\n',
  'Connections.csv':
      'Notes:\n"Some e-mail addresses are missing."\n\n'
      'First Name,Last Name,URL,Email Address,Company,Position,Connected On\n'
      'Jordan,Example,https://www.linkedin.com/in/jordan-example,,$_trust,Digital Lead,12 Mar 2024\n'
      'Kim,Peer,https://www.linkedin.com/in/kim-peer,,Example Teaching Hospitals,Records Officer,01 Feb 2023\n'
      'Sam,Sample,https://www.linkedin.com/in/sam-sample,,Agency Example,Talent Partner,01 Feb 2023\n'
      'Lee,Other,https://www.linkedin.com/in/lee-other,,Unrelated Co,Engineer,01 Feb 2023\n',
  'Jobs/Saved Jobs.csv':
      'Saved Date,Job Url,Job Title,Company Name\n10/20/26 8:00 AM,https://example.com/j/1,Digital Lead,$_trust\n',
  'messages.csv': _messages,
  'Invitations.csv': _invitations,
});

String _local(DateTime utc) => utc.toLocal().toIso8601String().substring(0, 16);

void main() {
  group('reading the archive', () {
    test('LinkedIn times, in local time', () {
      expect(linkedInTime('2026-11-01 09:00:00 UTC'), DateTime.utc(2026, 11, 1, 9).toLocal());
      expect(linkedInTime('11/3/26, 2:15 PM'), DateTime(2026, 11, 3, 14, 15));
      expect(linkedInTime('11/3/26, 12:05 AM'), DateTime(2026, 11, 3, 0, 5));
      expect(linkedInTime('12 Mar 2024'), DateTime(2024, 3, 12));
      expect(linkedInTime('soon'), isNull);
    });

    test('conversations: direction, the other people, drafts and spam left out', () {
      final x = LinkedInExport.read(_export());
      expect(x.ownName, 'Alex Example');
      final threads = x.threads();
      expect(threads.map((t) => t.id), ['c3', 'c1', 'c2'], reason: 'oldest last message first');
      final c1 = threads.firstWhere((t) => t.id == 'c1');
      expect(c1.people.single, (name: 'Jordan Example', url: 'https://www.linkedin.com/in/jordan-example'));
      expect(c1.messages.map((m) => m.out), [true, false]);
      expect(
        LinkedInExport.read(_export()).threads().first.messages.first.key,
        threads.first.messages.first.key,
      );

      final invites = x.invites();
      expect(invites.map((i) => (i.out, i.name)), [(true, 'Sam Sample'), (false, 'Casey Inbound')]);
      expect(invites.last.url, 'https://www.linkedin.com/in/casey-inbound');
    });

    test('without a profile, the member is the person in every conversation', () {
      final x = LinkedInExport.read(_zip({'messages.csv': _messages}));
      expect(x.ownName, 'Alex Example');
    });

    test('an archive with only messages is still LinkedIn data', () {
      expect(LinkedInExport.read(_zip({'Invitations.csv': _invitations})).invitations, hasLength(2));
    });
  });

  group('matching', () {
    test('similar text: the same opening, or mostly the same words', () {
      expect(
        similarText('Hi Jordan, I saw the digital lead role!', 'hi jordan i saw the digital lead role'),
        isTrue,
      );
      expect(similarText('Thanks!', 'thanks'), isTrue);
      expect(similarText('Thanks, see you Tuesday', 'Can we move it to Friday?'), isFalse);
      expect(closeInTime('2026-11-01T09:00', '2026-11-01T09:05'), isTrue);
      expect(closeInTime('2026-11-01T09:00', '2026-11-01T09:06'), isFalse);
    });

    test('employers match without "NHS Foundation Trust" and the like', () {
      expect(employerKey(_trust), 'example teaching hospitals');
      expect(sameEmployer('Example Teaching Hospitals', _trust), isTrue);
      expect(
        sameEmployer('The Example Health & Care Partnership', 'Example Health and Care Partnership'),
        isTrue,
      );
      expect(sameEmployer('Example Health', 'Example Health and Care NHS Trust'), isTrue);
      expect(
        sameEmployer('Example', 'Example Community Healthcare'),
        isFalse,
        reason: 'one word is too little',
      );
      expect(sameEmployer('NHS', ''), isFalse);
    });
  });

  group('import', () {
    test(
      'threads per conversation, matched by profile, deduplicated, and nothing doubles on re-import',
      () async {
        final book = CareerBook(await Store.open(memoryDatabase()));
        // Jordan is already a contact, with a LinkedIn thread logged by hand:
        // the first message three minutes after LinkedIn's time, slightly
        // tidied, and a chase a week later.
        final jordan = newId();
        await book.save(
          book.db.careerContacts,
          CareerContactsCompanion.insert(
            id: jordan,
            name: 'Jordan Example',
            company: const Value(_trust),
            linkedin: const Value('https://uk.linkedin.com/in/jordan-example/'),
          ),
          jordan,
        );
        final mine = await book.startConversation(
          contactId: jordan,
          channel: 'linkedin',
          at: _local(DateTime.utc(2026, 11, 1, 9, 3)),
        );
        await book.logSent(
          mine,
          'Hi Jordan, I saw the digital lead role and would love to hear more!',
          at: _local(DateTime.utc(2026, 11, 1, 9, 3)),
        );
        await book.logSent(mine, 'Just following up on this.', at: _local(DateTime.utc(2026, 11, 10, 9)));

        final r = await book.importLinkedIn(LinkedInExport.read(_export()), today: '2026-11-15');
        expect(r.messages, 2, reason: "Jordan's reply and the stranger's message");
        expect(r.invitations, 2);

        final threads = await book.conversationsOf(jordan);
        expect(threads.single.id, mine, reason: 'the hand-logged thread takes the import');
        expect(threads.single.externalId, 'c1');
        final said = await book.messagesIn(mine);
        expect(said.map((m) => (m.direction, m.source)), [
          ('out', 'manual'),
          ('in', 'import'),
          ('out', 'manual'),
        ]);
        expect(
          threads.single.status,
          'awaiting_reply',
          reason: 'an older imported reply does not move the thread on',
        );

        final screener = await book.threads(today: '2026-11-15', screener: true);
        expect(
          screener.map((t) => senderName(t.thread)),
          unorderedEquals(['Taylor Unknown', 'Casey Inbound']),
        );
        final taylor = screener.firstWhere((t) => senderName(t.thread) == 'Taylor Unknown').thread;
        expect(taylor.peer, 'https://www.linkedin.com/in/taylor-unknown');
        expect(taylor.mode, 'import');
        expect(threadHeader(taylor, null), startsWith('From Taylor Unknown'));

        // Sam, a recruiter connection, gets the connection request sent.
        final sam = (await book.db.select(book.db.careerContacts).get()).singleWhere(
          (c) => c.name == 'Sam Sample',
        );
        final samThread = (await book.conversationsOf(sam.id)).single;
        final invite = (await book.messagesIn(samThread.id)).single;
        expect(
          (invite.direction, invite.status, invite.body, invite.source),
          ('out', 'invite', 'Hello Sam', 'import'),
        );

        // Old, spam and draft messages never arrive.
        final all = await book.db.select(book.db.messages).get();
        expect(all.map((m) => m.body), isNot(contains(anyOf('Long ago.', 'Buy now', 'Unsent draft'))));
        // Imports are not the user's hand-sent pace.
        expect((await book.pace(DateTime(2026, 11, 4, 12))).invitesDay, 0);

        final again = await book.importLinkedIn(LinkedInExport.read(_export()), today: '2026-11-15');
        expect((again.messages, again.invitations), (0, 0));
        expect(await book.db.select(book.db.messages).get(), hasLength(all.length));
        expect(await book.db.select(book.db.conversations).get(), hasLength(4));
      },
    );

    test('people marked "do not contact" are left out', () async {
      final book = CareerBook(await Store.open(memoryDatabase()));
      final id = newId();
      await book.save(
        book.db.careerContacts,
        CareerContactsCompanion.insert(
          id: id,
          name: 'Taylor Unknown',
          linkedin: const Value('https://www.linkedin.com/in/taylor-unknown'),
          doNotContact: const Value(true),
        ),
        id,
      );
      final x = LinkedInExport.read(_zip({'messages.csv': _messages}));
      final r = await book.importLinkedInMessages(x, today: '2026-11-15');
      expect(r.messages, 2, reason: 'only the conversation with Jordan');
      expect(await book.conversationsOf(id), isEmpty);
    });

    test('a quiet thread from long ago is history, not a follow-up', () async {
      final book = CareerBook(await Store.open(memoryDatabase()));
      final id = newId();
      await book.save(
        book.db.careerContacts,
        CareerContactsCompanion.insert(
          id: id,
          name: 'Jordan Example',
          linkedin: const Value('https://www.linkedin.com/in/jordan-example'),
        ),
        id,
      );
      final x = LinkedInExport.read(
        _zip({
          'Profile.csv': 'First Name,Last Name\nAlex,Example\n',
          'messages.csv': _messages.split('\n').take(2).join('\n'),
        }),
      );
      await book.importLinkedInMessages(x, today: '2027-06-01');
      final t = (await book.conversationsOf(id)).single;
      expect(t.status, 'awaiting_reply');
      expect(t.followUp, isNull);
      expect(await book.dueFollowUps('2027-06-01'), isEmpty);
    });
  });

  test('who you already know at your target employers', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
    await book.importLinkedIn(LinkedInExport.read(_export()), today: '2026-11-15');
    expect(await book.targetEmployers(), [_trust]);
    final known = await book.knownAtTargets();
    expect(known.single.employer, _trust);
    expect(known.single.people.map((l) => l.name), [
      'Jordan Example',
      'Kim Peer',
    ], reason: 'Kim\'s employer is written without the suffix');
  });
}
