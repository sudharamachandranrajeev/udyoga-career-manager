// Bluesky with an app password: sign-in and token refresh, search, saving a
// person as a contact, posting, and the user's DMs in Conversations. A fake
// server answers every call; no test touches the network. Every handle and
// DID is made up.
import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/bluesky.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/conversations.dart';

import 'fake_bluesky.dart';
import 'support.dart';

void main() {
  late CareerBook book;
  late FakeBluesky server;
  late MemorySecretStore secrets;
  late Bluesky bluesky;

  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    server = FakeBluesky();
    secrets = MemorySecretStore();
    bluesky = Bluesky(book, server.client, secrets, clock: () => DateTime.utc(2026, 11, 12, 9));
  });
  tearDown(() => book.db.close());

  Future<BlueskyAccount> signIn() =>
      bluesky.signIn(identifier: '@Alex.Example.com', appPassword: appPassword);

  group('sign-in', () {
    test('an app password signs in; the tokens go to the keychain, not the settings', () async {
      final a = await signIn();
      expect((a.handle, a.did, a.pds, a.dms), (myHandle, myDid, 'https://pds.example.com', true));
      expect(await secrets.read('udyoga.bluesky.access'), 'access-1');
      expect(await secrets.read('udyoga.bluesky.refresh'), 'refresh-1');
      final stored = await book.db.localSetting(blueskyAccountKey);
      expect(stored, isNot(contains('access-1')));
      expect(stored, isNot(contains(appPassword)));
      expect(jsonDecode(server.requests.first.body), {'identifier': myHandle, 'password': appPassword});
      // After sign-in, calls go to the PDS the DID document names.
      expect(server.requests.last.url.host, 'pds.example.com');
    });

    test('the main password is refused before it is sent; a wrong app password says what to do', () async {
      await expectLater(
        bluesky.signIn(identifier: myHandle, appPassword: 'my main password'),
        throwsA(isA<BlueskyException>().having((e) => e.message, 'message', contains('app password'))),
      );
      expect(server.requests, isEmpty);
      await expectLater(
        bluesky.signIn(identifier: myHandle, appPassword: 'zzzz-zzzz-zzzz-zzzz'),
        throwsA(isA<BlueskyException>().having((e) => e.message, 'message', contains('would not sign in'))),
      );
    });

    test('an app password without DM access still searches and posts', () async {
      server.dms = false;
      final a = await signIn();
      expect(a.dms, isFalse);
      expect((await bluesky.syncMessages()).added, 0);
      expect(server.requests.where((r) => r.url.path.contains('getMessages')), isEmpty);
    });

    test('an expired token is refreshed once and the call made again', () async {
      await signIn();
      server.actors.add({'did': 'did:plc:kim', 'handle': 'kim.example.com', 'displayName': 'Kim Peer'});
      server.expireNext = true;
      final found = await bluesky.searchPeople('NHS digital');
      expect(found.single.name, 'Kim Peer');
      expect(server.refreshes, 1);
      expect(await secrets.read('udyoga.bluesky.access'), 'access-2');
      expect(await secrets.read('udyoga.bluesky.refresh'), 'refresh-2');

      // When the refresh token has ended too, the user signs in again.
      server.refreshWorks = false;
      server.expireNext = true;
      await expectLater(
        bluesky.searchPeople('NHS digital'),
        throwsA(
          isA<BlueskyException>().having((e) => e.message, 'message', contains('Connect the account again')),
        ),
      );
      expect(server.refreshes, 1);
    });

    test('sign out forgets the tokens', () async {
      await signIn();
      await bluesky.signOut();
      expect(await bluesky.account(), isNull);
      expect(await secrets.read('udyoga.bluesky.access'), isNull);
      await expectLater(bluesky.searchPeople('x'), throwsA(isA<BlueskyException>()));
    });
  });

  group('search and save', () {
    setUp(signIn);

    test('people and posts by topic, saved with handle, DID, source and basis', () async {
      server.actors.add({
        'did': 'did:plc:jordan',
        'handle': 'jordan.example.com',
        'displayName': 'Jordan Example',
        'description': 'Digital lead at an example NHS trust.',
      });
      server.posts.add({
        'uri': 'at://did:plc:sam/app.bsky.feed.post/3kabc',
        'author': {'did': 'did:plc:sam', 'handle': 'sam.example.com', 'displayName': ''},
        'record': {
          'text': 'Our clinical informatics meetup is on Thursday.',
          'createdAt': '2026-11-10T09:00:00Z',
        },
      });
      final people = await bluesky.searchPeople('clinical informatics');
      expect(server.requests.last.url.queryParameters, {'q': 'clinical informatics', 'limit': '25'});
      expect(
        (people.single.name, people.single.description),
        ('Jordan Example', 'Digital lead at an example NHS trust.'),
      );
      final posts = await bluesky.searchPosts('clinical informatics');
      expect(server.requests.last.url.queryParameters['sort'], 'latest');
      final post = posts.single;
      expect(post.url, 'https://bsky.app/profile/sam.example.com/post/3kabc');
      expect(post.author.name, 'sam.example.com');

      final jo = await saveBlueskyPerson(
        book,
        people.single,
        topic: 'clinical informatics',
        today: '2026-11-12',
      );
      final c = (await book.contact(jo))!;
      expect(
        (c.name, c.sourceKind, c.basis, c.sourceUrl, c.foundOn),
        (
          'Jordan Example',
          'other',
          'legitimate_interest',
          'https://bsky.app/profile/jordan.example.com',
          '2026-11-12',
        ),
      );
      expect(c.source, 'Bluesky search: clinical informatics');
      expect([
        for (final h in await book.handlesOf(jo)) (h.channel, h.handle),
      ], containsAll([('bluesky', '@jordan.example.com'), ('bluesky', 'did:plc:jordan')]));
      // Saving again finds the same person.
      expect(await saveBlueskyPerson(book, people.single, today: '2026-11-12'), jo);

      final sam = await saveBlueskyPerson(book, post.author, sourceUrl: post.url, today: '2026-11-12');
      expect((await book.contact(sam))!.sourceUrl, post.url);
    });
  });

  group('posting', () {
    setUp(signIn);

    test('a post goes out with link facets in UTF-8 bytes', () async {
      const text = 'Café notes from the NHS digital day: https://example.org/notes.';
      final url = await bluesky.post(text);
      expect(url, 'https://bsky.app/profile/$myHandle/post/3kpost');
      final body = server.created.single;
      expect((body['repo'], body['collection']), (myDid, 'app.bsky.feed.post'));
      final record = body['record'] as Map;
      expect(record['text'], text);
      final facet = (record['facets'] as List).single as Map;
      final index = facet['index'] as Map;
      final bytes = utf8.encode(text);
      expect(
        utf8.decode(bytes.sublist(index['byteStart'] as int, index['byteEnd'] as int)),
        'https://example.org/notes',
      );
      expect(((facet['features'] as List).single as Map)['uri'], 'https://example.org/notes');
    });

    test('too long or empty posts are refused before sending', () async {
      await expectLater(bluesky.post('x' * 301), throwsA(isA<BlueskyException>()));
      await expectLater(bluesky.post('  '), throwsA(isA<BlueskyException>()));
      expect(server.created, isEmpty);
    });
  });

  group('direct messages', () {
    setUp(signIn);

    test(
      'saved contacts\' convos come in, strangers who wrote wait in the Screener, the rest is left',
      () async {
        final jo = await saveBlueskyPerson(
          book,
          const BskyPerson(
            did: 'did:plc:jordan',
            handle: 'jordan.example.com',
            displayName: 'Jordan Example',
          ),
          today: '2026-11-12',
        );
        server.convos['c-jordan'] = (
          view: FakeBluesky.convoView(
            'c-jordan',
            'did:plc:jordan',
            'jordan.example.com',
            rev: '5',
            lastFrom: 'did:plc:jordan',
          ),
          messages: [
            FakeBluesky.message('m1', myDid, 'Hi Jordan, loved your EPR post.', '2026-11-10T09:00:00Z'),
            FakeBluesky.message('m2', 'did:plc:jordan', 'Thanks! Happy to chat.', '2026-11-10T10:00:00Z'),
          ],
        );
        server.convos['c-stranger'] = (
          view: FakeBluesky.convoView(
            'c-stranger',
            'did:plc:recruiter',
            'recruiter.example.com',
            rev: '2',
            lastFrom: 'did:plc:recruiter',
          ),
          messages: [
            FakeBluesky.message(
              'm3',
              'did:plc:recruiter',
              'An exciting opportunity!',
              '2026-11-11T09:00:00Z',
            ),
          ],
        );
        server.convos['c-mine'] = (
          view: FakeBluesky.convoView(
            'c-mine',
            'did:plc:friend',
            'friend.example.com',
            rev: '1',
            lastFrom: myDid,
          ),
          messages: [FakeBluesky.message('m4', myDid, 'Dinner?', '2026-11-11T09:00:00Z')],
        );

        final r = await bluesky.syncMessages();
        expect(r.added, 3);
        expect([for (final a in r.alerts) a.name], ['Jordan Example']);
        final t = (await book.threadByExternalId('bluesky', 'c-jordan'))!;
        expect((t.contactId, t.mode, t.peer, t.account), (jo, 'api', '@jordan.example.com', myHandle));
        expect(
          [for (final m in await book.messagesIn(t.id)) (m.direction, m.body, m.source)],
          [('out', 'Hi Jordan, loved your EPR post.', 'api'), ('in', 'Thanks! Happy to chat.', 'api')],
        );
        final screener = (await book.threadByExternalId('bluesky', 'c-stranger'))!;
        expect(screener.contactId, isNull);
        expect(await book.threadByExternalId('bluesky', 'c-mine'), isNull);
        // Only the convos that matter were read in full.
        expect(
          [
            for (final q in server.requests.where((q) => q.url.path.endsWith('getMessages')))
              q.url.queryParameters['convoId'],
          ],
          ['c-jordan', 'c-stranger'],
        );

        // Nothing new: unchanged convos are not read again.
        server.requests.clear();
        expect((await bluesky.syncMessages()).added, 0);
        expect(server.requests.where((q) => q.url.path.endsWith('getMessages')), isEmpty);

        // A new message: only it is added.
        server.convos['c-jordan']!.messages.add(
          FakeBluesky.message('m5', 'did:plc:jordan', 'Thursday at 10?', '2026-11-11T12:00:00Z'),
        );
        server.convos['c-jordan'] = (
          view: FakeBluesky.convoView(
            'c-jordan',
            'did:plc:jordan',
            'jordan.example.com',
            rev: '6',
            lastFrom: 'did:plc:jordan',
          ),
          messages: server.convos['c-jordan']!.messages,
        );
        expect((await bluesky.syncMessages()).added, 1);
        expect(await book.messagesIn(t.id), hasLength(3));
      },
    );

    test('a hand-logged Bluesky thread takes the DMs without doubling them', () async {
      final jo = await saveBlueskyPerson(
        book,
        const BskyPerson(did: 'did:plc:jordan', handle: 'jordan.example.com'),
        today: '2026-11-12',
      );
      final t = await book.startConversation(contactId: jo, channel: 'bluesky', at: '2026-11-10T08:00');
      final at = DateTime.parse('2026-11-10T09:00:00Z').toLocal().toIso8601String().substring(0, 16);
      await book.logSent(t, 'Hi Jordan', at: at);
      server.convos['c1'] = (
        view: FakeBluesky.convoView('c1', 'did:plc:jordan', 'jordan.example.com', rev: '1', lastFrom: myDid),
        messages: [FakeBluesky.message('m1', myDid, 'Hi Jordan', '2026-11-10T09:00:00Z')],
      );
      await bluesky.syncMessages();
      expect((await book.conversation(t)).externalId, 'c1');
      expect(await book.messagesIn(t), hasLength(1));
    });

    test('sending: in the convo, or a new one found by DID', () async {
      final jo = await saveBlueskyPerson(
        book,
        const BskyPerson(did: 'did:plc:jordan', handle: 'jordan.example.com'),
        today: '2026-11-12',
      );
      final sender = BlueskySender(bluesky, (await bluesky.account())!);
      final t = await book.startConversation(contactId: jo, channel: 'bluesky', at: '2026-11-12T09:00');
      expect(senderFor(await book.conversation(t), [sender]), sender);
      await book.sendVia(sender, t, 'Hello from Udyoga', at: '2026-11-12T09:05');
      expect(server.sent.single, (convoId: 'convo-did:plc:jordan', text: 'Hello from Udyoga'));
      final thread = await book.conversation(t);
      expect((thread.externalId, thread.account), ('convo-did:plc:jordan', myHandle));
      final m = (await book.messagesIn(t)).single;
      expect((m.status, m.externalId), ('sent', 'm-sent-1'));

      // The sync that follows does not add it twice.
      server.convos['convo-did:plc:jordan']!.messages.add(
        FakeBluesky.message('m-sent-1', myDid, 'Hello from Udyoga', '2026-11-12T09:05:00Z'),
      );
      await bluesky.syncMessages();
      expect(await book.messagesIn(t), hasLength(1));

      // Do-not-contact stops the send.
      await book.setDoNotContact(jo, true, today: '2026-11-12');
      await expectLater(
        book.sendVia(sender, t, 'Again', at: '2026-11-12T10:00'),
        throwsA(isA<DoNotContactException>()),
      );
      expect(server.sent, hasLength(1));
    });

    test('checks are only made when due', () async {
      expect((await bluesky.syncDue()).added, 0);
      final calls = server.requests.length;
      await bluesky.syncDue();
      expect(server.requests.length, calls);
    });
  });
}
