// LinkedIn messages through a helper app (docs/handoff.md, format v1
// additions): Udyoga writes each draft whole into outbox/, reads the
// helper's answers from status/ and its budget from status.json. The files
// under test/fixtures/handoff/drafts are shared with a helper app's own
// tests: it read these outbox files and wrote these answers, from made-up
// people and companies.
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/helper_drafts.dart';

import 'support.dart';

const _fixtures = 'test/fixtures/handoff/drafts';
String _msg(int n) => '0b5e7c1a-4a6b-4c01-9d00-00000000000$n';
String _draft(int n) => 'udyoga-${_msg(n)}';
const _miraThread = 'linkedin:urn:li:msg_conversation:(urn:li:fsd_profile:ACoAAFakeSelf01,2-AAA=)';

Future<String> _contact(CareerBook book, String name, String linkedin, {bool doNotContact = false}) async {
  final id = newId();
  await book.save(
    book.db.careerContacts,
    CareerContactsCompanion.insert(
      id: id,
      name: name,
      linkedin: Value(linkedin),
      doNotContact: Value(doNotContact),
    ),
    id,
  );
  return id;
}

Future<String> _job(CareerBook book, String id, String title, String company) async {
  await book.save(
    book.db.jobListings,
    JobListingsCompanion.insert(id: id, title: title, company: Value(company), found: '2026-11-20'),
    id,
  );
  return id;
}

/// The five drafts of the shared fixture, as Udyoga writes them.
final _drafts = [
  HelperDraft(
    id: _draft(1),
    createdAt: DateTime.utc(2026, 11, 27, 10),
    toName: 'Mira Quillfeather',
    profileUrl: 'https://www.linkedin.com/in/mira-quillfeather-fake',
    threadId: _miraThread,
    text: 'Hello Mira, thank you for the chat about the records officer role. I sent my application today.',
    application: const DraftApplication(
      id: 'job-fake-0001',
      title: 'Records Officer',
      company: 'Bramblewick Health',
    ),
  ),
  HelperDraft(
    id: _draft(2),
    createdAt: DateTime.utc(2026, 11, 27, 10, 1),
    toName: 'Rex Talentmore',
    profileUrl: 'https://www.linkedin.com/in/rex-talentmore-fake',
    text: 'Thanks Rex, yes, I am open to a call on Thursday afternoon.',
  ),
  HelperDraft(
    id: _draft(3),
    createdAt: DateTime.utc(2026, 11, 27, 10, 2),
    toName: 'Pell Connward',
    profileUrl: 'https://uk.linkedin.com/in/Pell-Connward-fake/',
    text:
        'Hi Pell, I saw that Lindenfold Archives is hiring a data steward. Could I ask you two quick questions '
        'about the team?',
    application: const DraftApplication(
      id: 'job-fake-0002',
      title: 'Data Steward',
      company: 'Lindenfold Archives',
    ),
  ),
  HelperDraft(
    id: _draft(4),
    createdAt: DateTime.utc(2026, 11, 27, 10, 3),
    toName: 'Tarn Strangely',
    profileUrl: 'https://www.linkedin.com/in/tarn-strangely-fake',
    text: 'Hello Tarn, I would like to learn more about your team.',
  ),
  HelperDraft(
    id: _draft(5),
    createdAt: DateTime.utc(2026, 11, 27, 10, 4),
    toName: 'Mira Quillfeather',
    profileUrl: 'https://www.linkedin.com/in/mira-quillfeather-fake',
    text: 'Also, one more thing: an older draft I will cancel.',
  ),
];

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('udyoga-helper-'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('drafts are written whole, byte for byte as the helper app read them', () async {
    for (final d in _drafts) {
      await writeHelperDraft(dir.path, d);
      await writeHelperDraft(dir.path, d); // again: the same file
    }
    final written = dir.listSync().whereType<Directory>().map(
      (d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last,
    );
    expect(written.toSet(), {'outbox', 'tmp'});
    expect(Directory('${dir.path}/tmp').listSync(), isEmpty, reason: 'nothing half-written left behind');
    for (final d in _drafts) {
      expect(
        File('${dir.path}/outbox/${d.id}.json').readAsStringSync(),
        File('$_fixtures/outbox/${d.id}.json').readAsStringSync(),
        reason: d.id,
      );
    }
    expect(
      () => writeHelperDraft(
        dir.path,
        HelperDraft(
          id: '../escape',
          createdAt: DateTime.utc(2026),
          toName: '',
          profileUrl: 'https://www.linkedin.com/in/x',
          text: 'x',
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    '"Send via helper" leaves a draft and a queued message; never for do-not-contact or without a profile',
    () async {
      final book = CareerBook(await Store.open(memoryDatabase()));
      final job = await _job(book, 'job-fake-0001', 'Records Officer', 'Bramblewick Health');
      final mira = await _contact(
        book,
        'Mira Quillfeather',
        'https://www.linkedin.com/in/mira-quillfeather-fake',
      );
      final t = await book.startConversation(
        contactId: mira,
        channel: 'linkedin',
        externalId: _miraThread,
        jobId: job,
        at: '2026-11-27T09:00',
      );
      final id = await book.sendViaHelper(
        dir.path,
        t,
        '  Hello Mira.  ',
        now: DateTime.utc(2026, 11, 27, 10),
      );
      final m = (await book.messagesIn(t)).single;
      expect([m.id, m.direction, m.source, m.status, m.body], [id, 'out', 'helper', 'queued', 'Hello Mira.']);
      final file = jsonDecode(File('${dir.path}/outbox/udyoga-$id.json').readAsStringSync()) as Map;
      expect(file, {
        'v': 1,
        'kind': 'message',
        'id': 'udyoga-$id',
        'source': 'linkedin',
        'createdAt': '2026-11-27T10:00:00Z',
        'to': {
          'name': 'Mira Quillfeather',
          'profileUrl': 'https://www.linkedin.com/in/mira-quillfeather-fake',
        },
        'threadId': _miraThread,
        'text': 'Hello Mira.',
        'application': {'id': 'job-fake-0001', 'title': 'Records Officer', 'company': 'Bramblewick Health'},
      });

      final dnc = await _contact(
        book,
        'Odo Nocontact',
        'https://www.linkedin.com/in/odo-nocontact-fake',
        doNotContact: true,
      );
      final t2 = await book.startConversation(contactId: dnc, channel: 'linkedin', at: '2026-11-27T09:00');
      await expectLater(
        book.sendViaHelper(dir.path, t2, 'hi', now: DateTime.now()),
        throwsA(isA<DoNotContactException>()),
      );
      final bare = await _contact(book, 'Lin Nolink', '');
      final t3 = await book.startConversation(contactId: bare, channel: 'linkedin', at: '2026-11-27T09:00');
      await expectLater(book.sendViaHelper(dir.path, t3, 'hi', now: DateTime.now()), throwsStateError);
      final t4 = await book.startConversation(contactId: mira, channel: 'email', at: '2026-11-27T09:00');
      await expectLater(book.sendViaHelper(dir.path, t4, 'hi', now: DateTime.now()), throwsStateError);
      expect(Directory('${dir.path}/outbox').listSync(), hasLength(1));
    },
  );

  test('the helper\'s answers move the messages on, once', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    // The five messages as "Send via helper" left them (ids from the fixture).
    final threads = <int, String>{};
    final mira = await _contact(
      book,
      'Mira Quillfeather',
      'https://www.linkedin.com/in/mira-quillfeather-fake',
    );
    threads[1] = threads[5] = await book.startConversation(
      contactId: mira,
      channel: 'linkedin',
      externalId: _miraThread,
      at: '2026-11-27T09:00',
    );
    for (final (n, name, url) in [
      (2, 'Rex Talentmore', 'https://www.linkedin.com/in/rex-talentmore-fake'),
      (3, 'Pell Connward', 'https://uk.linkedin.com/in/Pell-Connward-fake/'),
      (4, 'Tarn Strangely', 'https://www.linkedin.com/in/tarn-strangely-fake'),
    ]) {
      threads[n] = await book.startConversation(
        contactId: await _contact(book, name, url),
        channel: 'linkedin',
        at: '2026-11-27T09:00',
      );
    }
    for (final d in _drafts) {
      final n = _drafts.indexOf(d) + 1;
      await book.save(
        book.db.messages,
        MessagesCompanion.insert(
          id: _msg(n),
          conversationId: threads[n]!,
          direction: 'out',
          body: Value(d.text),
          sentAt: '2026-11-27T10:0${n - 1}',
          source: const Value('helper'),
          status: const Value('queued'),
        ),
        _msg(n),
      );
    }
    // The helper handed Mira's sent message off as a career item first.
    await book.addMessage(
      threads[1]!,
      direction: 'out',
      body: 'Hello Mira, thank you for the chat about the records officer role. I sent my application this morning.',
      at: '2026-11-28T03:20',
      source: 'helper',
      externalId: 'linkedin:urn:li:msg_message:(urn:li:fsd_profile:ACoAAFakeSelf01,draft-1)',
    );

    Directory('${dir.path}/status').createSync(recursive: true);
    for (final f in Directory('$_fixtures/status').listSync().whereType<File>()) {
      f.copySync('${dir.path}/status/${f.uri.pathSegments.last}');
    }
    final now = DateTime(2026, 11, 28, 9);
    expect(await book.importHelperStatuses(dir.path, now: now), 5);

    Future<ThreadMessage> m(int n) =>
        (book.db.select(book.db.messages)..where((x) => x.id.equals(_msg(n)))).getSingle();
    final one = await m(1);
    expect(one.status, 'sent');
    expect(one.body, endsWith('this morning.'), reason: 'the text the user sent after editing it');
    expect(one.externalId, 'linkedin:urn:li:msg_message:(urn:li:fsd_profile:ACoAAFakeSelf01,draft-1)');
    expect(
      (await book.messagesIn(threads[1]!)).where((x) => x.body.endsWith('this morning.')),
      hasLength(1),
      reason: 'the career item of the same message is kept once',
    );
    for (final n in [2, 3]) {
      expect((await m(n)).status, 'sent');
    }
    expect(
      (await book.conversation(threads[2]!)).externalId,
      'linkedin:urn:li:msg_conversation:(urn:li:fsd_profile:ACoAAFakeSelf01,2-BBB=)',
    );
    expect(
      (await book.conversation(threads[3]!)).externalId,
      'linkedin:urn:li:msg_conversation:(urn:li:fsd_profile:ACoAAFakeSelf01,2-PPP=)',
      reason: 'a first message: the thread now knows its LinkedIn conversation',
    );
    expect((await m(4)).status, 'failed');
    expect(
      (await book.messagesIn(threads[4]!)).where((x) => x.direction == 'note').single.body,
      'The helper app could not send this: not a connection: drafts go only to people you already message '
      'or are connected to',
    );
    expect((await m(5)).status, 'cancelled');

    // Read again: nothing changes, no second note.
    expect(await book.importHelperStatuses(dir.path, now: now), 0);
    expect((await book.messagesIn(threads[4]!)).where((x) => x.direction == 'note'), hasLength(1));
  });

  test('waiting answers say why once; unknown and broken answers are left alone', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    final c = await _contact(book, 'Rex Talentmore', 'https://www.linkedin.com/in/rex-talentmore-fake');
    final t = await book.startConversation(contactId: c, channel: 'linkedin', at: '2026-11-27T09:00');
    final id = await book.sendViaHelper(dir.path, t, 'Thanks Rex.', now: DateTime.now());
    Directory('${dir.path}/status').createSync();
    void answer(String state, String reason) => File('${dir.path}/status/udyoga-$id.json').writeAsStringSync(
      jsonEncode({
        'v': 1,
        'id': 'udyoga-$id',
        'state': state,
        'reason': reason,
        'updatedAt': '2026-11-27T10:00:00Z',
      }),
    );
    answer('waiting', 'over the LinkedIn message budget (40 a day); confirm it again later');
    File('${dir.path}/status/udyoga-unknown.json')
        .writeAsStringSync('{"v":1,"id":"udyoga-unknown","state":"sent"}');
    File('${dir.path}/status/broken.json').writeAsStringSync('{not json');
    File('${dir.path}/status/udyoga-v2.json').writeAsStringSync('{"v":2,"id":"udyoga-v2","state":"sent"}');
    expect(await book.importHelperStatuses(dir.path), 1);
    expect(await book.importHelperStatuses(dir.path), 0);
    final notes = (await book.messagesIn(t)).where((m) => m.direction == 'note');
    expect(notes.single.body, startsWith('The helper app is holding this: over the LinkedIn message budget'));
    answer('sending', '');
    expect(await book.importHelperStatuses(dir.path), 1);
    expect((await book.messagesIn(t)).firstWhere((m) => m.id == id).status, 'sending');
  });

  test('status.json: fresh for five minutes, and its budget replaces Udyoga\'s own count', () {
    final s = HelperStatus.parse(File('$_fixtures/status.json').readAsStringSync())!;
    final at = DateTime.parse('2026-11-27T12:00:00Z');
    expect(s.fresh(at.add(const Duration(minutes: 4))), isTrue);
    expect(s.fresh(at.add(const Duration(minutes: 6))), isFalse);
    expect(s.usable('linkedin', at.add(const Duration(minutes: 1))), isNotNull);
    expect(
      s.usable('linkedin', at.add(const Duration(minutes: 10))),
      isNull,
      reason: 'stale: the helper is not running',
    );
    expect(s.usable('bluesky', at), isNull);
    expect(HelperStatus.parse('{"v":2,"updatedAt":"2026-11-27T12:00:00Z"}'), isNull);
    expect(HelperStatus.parse('nonsense'), isNull);

    final li = s.channels['linkedin']!;
    final p = Pace.helper(messages: li.messages, invites: li.invites);
    expect(p.fromHelper, isTrue);
    expect(p.messagesDay, 3);
    expect(p.level, PaceLevel.calm);
    expect(
      p.summary,
      'The helper app\'s LinkedIn budget: 37 of 40 messages left today, 147 of 150 this week; '
      '15 of 15 invitations left today, 80 of 80 this week.',
    );
    final spent = Pace.helper(messages: (dayLeft: 0, dayLimit: 40, weekLeft: 100, weekLimit: 150));
    expect(spent.level, PaceLevel.slowDown);
    expect(spent.advice, contains('budget is used up'));
    expect(
      Pace.helper(messages: (dayLeft: -1, dayLimit: 0, weekLeft: -1, weekLimit: 0)).summary,
      contains('no cap'),
    );
  });
}
