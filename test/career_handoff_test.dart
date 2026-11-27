// Career items from a helper app, through the hand-off folder
// (docs/handoff.md): messages land in Conversations once, unknown senders
// wait in the Screener, bad lines are refused with a reason, other versions
// and kinds are skipped, and read files are filed away. The sample file was
// written by a helper app's own test from made-up conversations; every
// person and company in it is invented.
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_handoff.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/ui/conversations_page.dart';

import 'support.dart';

Future<String> _contact(
  CareerBook book,
  String name, {
  String linkedin = '',
  bool doNotContact = false,
}) async {
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

Map<String, Object?> _rec({
  String id = 'linkedin:m1',
  String thread = 'linkedin:t1',
  String name = 'Sol Example',
  String url = 'https://www.linkedin.com/in/sol-example-fake',
  String text = 'We have a records officer role you may like.',
  String direction = 'in',
  String at = '2026-11-20T09:00:00Z',
  String level = 'none',
  List<String> signs = const [],
  List<String> reasons = const ['InMail'],
}) => {
  'v': 1,
  'kind': 'message',
  'source': 'linkedin',
  'id': id,
  'threadId': thread,
  'peer': {
    'name': name,
    'headline': 'Recruiter at Example Agency',
    'profileUrl': url,
    'company': 'Example Agency',
  },
  'subject': '',
  'text': text,
  'sentAt': at,
  'direction': direction,
  'reasons': reasons,
  'scam': {'level': level, 'signs': signs},
};

List<HandoffRecord> _good(List<Map<String, Object?>> rs) => [
  for (final l in readHandoffLines(rs.map(jsonEncode).join('\n')).whereType<GoodLine>()) l.record,
];

void main() {
  late Directory dir;
  late CareerBook book;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('udyoga-handoff-');
    book = CareerBook(await Store.open(memoryDatabase()));
  });
  tearDown(() async {
    await book.db.close();
    await dir.delete(recursive: true);
  });

  Future<File> drop(String name, String content) async {
    final inbox = Directory('${dir.path}/inbox')..createSync(recursive: true);
    return File('${inbox.path}/$name').writeAsString(content);
  }

  test('the folder per system', () {
    expect(
      defaultHandoffFolder(environment: {'HOME': '/home/a'}, os: 'linux'),
      '/home/a/.local/share/brahma/handoff/career',
    );
    expect(
      defaultHandoffFolder(environment: {'HOME': '/home/a', 'XDG_DATA_HOME': '/data'}, os: 'linux'),
      '/data/brahma/handoff/career',
    );
    expect(
      defaultHandoffFolder(environment: {'APPDATA': r'C:\Users\a\AppData\Roaming'}, os: 'windows'),
      r'C:\Users\a\AppData\Roaming\brahma\handoff\career',
    );
    expect(defaultHandoffFolder(environment: {}, os: 'android'), isNull);
  });

  test('the sample from a helper app: known people matched, strangers to the Screener, once only', () async {
    // Wren is a contact (profile typed another way); Ines is known by name.
    final wren = await _contact(
      book,
      'Wren Hollowby',
      linkedin: 'https://uk.linkedin.com/in/wren-hollowby-fake/',
    );
    final ines = await _contact(book, 'Ines Oldhire');
    final sample = File('test/fixtures/handoff/sample.jsonl').readAsStringSync();
    await drop('20261127T090000.000Z-0a1b2c3d.jsonl', sample);

    final r = await HandoffFolder(dir.path).run(book, today: '2026-11-27');
    expect((r.files, r.imported, r.skipped, r.rejected), (1, 6, 0, 0));
    expect(Directory('${dir.path}/inbox').listSync(), isEmpty);
    expect(File('${dir.path}/done/20261127T090000.000Z-0a1b2c3d.jsonl').existsSync(), isTrue);
    expect(Directory('${dir.path}/rejected').existsSync(), isFalse);

    final w = (await book.conversationsOf(wren)).single;
    expect((w.channel, w.mode), ('linkedin', 'helper'));
    expect(w.externalId, startsWith('linkedin:urn:li:msg_conversation:'));
    final wm = await book.messagesIn(w.id);
    expect(wm.map((m) => (m.direction, m.source)), [('in', 'helper'), ('out', 'helper')]);
    expect(wm.every((m) => m.externalId!.startsWith('linkedin:urn:li:msg_message:')), isTrue);
    expect(threadReasons(w), contains('sender works at a target employer: Bramblewick Health'));
    expect(threadScam(w).flagged, isFalse);
    expect((await book.conversationsOf(ines)).single.mode, 'helper');

    final screener = await (book.db.select(book.db.conversations)..where((c) => c.contactId.isNull())).get();
    expect(screener.map(senderName).toSet(), {'Rex Talentmore', 'Quill Fennick', 'Odo Newcontact'});
    final quill = screener.firstWhere((t) => senderName(t) == 'Quill Fennick');
    expect(quill.peer, 'https://www.linkedin.com/in/quill-fennick-fake');
    final scam = threadScam(quill);
    expect(scam.level, 'high');
    expect(scam.signs.join('|'), allOf(contains('WhatsApp'), contains('bank details'), contains('fee')));

    // The same file again (a helper wrote it twice): nothing doubles.
    await drop('20261127T100000.000Z-0a1b2c3e.jsonl', sample);
    final again = await HandoffFolder(dir.path).run(book, today: '2026-11-27');
    expect((again.imported, again.skipped), (0, 6));
    expect(await book.db.select(book.db.messages).get(), hasLength(6));
  });

  test('bad lines refused with the reason; other versions and kinds skipped', () async {
    await drop(
      'mixed.jsonl',
      [
        jsonEncode(_rec()),
        'not json at all',
        jsonEncode({..._rec(id: 'linkedin:m2'), 'id': null}),
        jsonEncode({..._rec(id: 'linkedin:m3'), 'direction': 'sideways'}),
        jsonEncode({..._rec(id: 'linkedin:m4'), 'v': 2}),
        jsonEncode({..._rec(id: 'linkedin:m5'), 'kind': 'calendar_invite'}),
        '',
      ].join('\n'),
    );
    final r = await HandoffFolder(dir.path).run(book, today: '2026-11-27');
    expect((r.imported, r.skipped, r.rejected), (1, 2, 3));
    final refused = File('${dir.path}/rejected/mixed.jsonl')
        .readAsLinesSync()
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
    expect(refused.map((l) => (l['line'], l['reason'])), [
      (2, 'not JSON'),
      (3, '"id" is missing'),
      (4, '"direction" must be "in" or "out"'),
    ]);
    expect(refused.first['text'], 'not json at all');
    expect(File('${dir.path}/done/mixed.jsonl').existsSync(), isTrue);
  });

  test('a thread logged by hand takes the helper id; a logged message is not doubled', () async {
    final sol = await _contact(book, 'Sol Example', linkedin: 'linkedin.com/in/sol-example-fake');
    final at = DateTime.utc(2026, 11, 20, 9).toLocal().toIso8601String().substring(0, 16);
    final mine = await book.startConversation(contactId: sol, channel: 'linkedin', at: at);
    await book.addMessage(
      mine,
      direction: 'in',
      body: 'We have a records officer role you may like!',
      at: at,
    );

    final r = await book.importHandoffRecords(
      _good([_rec(), _rec(id: 'linkedin:m2', text: 'Would Tuesday suit?', at: '2026-11-21T10:00:00Z')]),
      today: '2026-11-27',
    );
    expect((r.imported, r.skipped), (1, 1));
    final t = (await book.conversationsOf(sol)).single;
    expect((t.id, t.externalId, t.mode), (mine, 'linkedin:t1', 'manual'));
    expect((await book.messagesIn(mine)).map((m) => m.source), ['manual', 'helper']);
  });

  test('do not contact is respected; the scam check only gets more severe', () async {
    await _contact(
      book,
      'Ash Blocked',
      linkedin: 'https://www.linkedin.com/in/ash-blocked-fake',
      doNotContact: true,
    );
    final r = await book.importHandoffRecords(
      _good([
        _rec(thread: 'linkedin:t9', name: 'Ash Blocked', url: 'https://www.linkedin.com/in/ash-blocked-fake'),
        _rec(level: 'high', signs: ['asks you to pay a fee']),
        _rec(
          id: 'linkedin:m2',
          level: 'caution',
          signs: ['asks to move to WhatsApp'],
          reasons: ['recruiter'],
        ),
      ]),
      today: '2026-11-27',
    );
    expect((r.imported, r.skipped), (2, 1));
    final t = (await book.db.select(book.db.conversations).get()).single;
    expect(t.contactId, isNull);
    expect(threadScam(t).level, 'high');
    expect(threadScam(t).signs, ['asks you to pay a fee', 'asks to move to WhatsApp']);
    expect(threadReasons(t), ['InMail', 'recruiter']);
  });

  test('read files and refused lines are kept 30 days', () async {
    final old = File('${dir.path}/done/old.jsonl')..createSync(recursive: true);
    old.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 31)));
    final fresh = File('${dir.path}/rejected/fresh.jsonl')..createSync(recursive: true);
    await HandoffFolder(dir.path).run(book, today: '2026-11-27');
    expect(old.existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
  });

  group('scam banner', () {
    Widget host(HandoffScam s) => MaterialApp(home: Scaffold(body: ScamBanner(s)));

    testWidgets('high: the warning, each sign and how to check', (tester) async {
      await tester.pumpWidget(
        host(const HandoffScam(level: 'high', signs: ['asks for bank details', 'asks to move to WhatsApp'])),
      );
      expect(find.text('This looks like a job scam'), findsOneWidget);
      expect(find.text('• asks for bank details'), findsOneWidget);
      expect(find.text('• asks to move to WhatsApp'), findsOneWidget);
      expect(find.textContaining('How to check'), findsOneWidget);
    });

    testWidgets('caution is worded more softly', (tester) async {
      await tester.pumpWidget(host(const HandoffScam(level: 'caution', signs: ['a personal email address'])));
      expect(find.text('Some signs of a job scam'), findsOneWidget);
    });

    testWidgets('nothing for none', (tester) async {
      await tester.pumpWidget(host(const HandoffScam()));
      expect(find.textContaining('scam'), findsNothing);
    });
  });
}
