// LinkedIn posts through a helper app (docs/handoff.md, posts): Udyoga
// writes a finished post's files, then the post, into the hand-off folder,
// and reads the helper's answers from status/. The files under
// test/fixtures/handoff/posts are shared with a helper app's own tests: it
// read these outbox files and files/, and wrote these answers. All made up.
//
// UDYOGA_UPDATE_FIXTURES=1 rewrites the outbox side of the fixture (the
// helper app's test rewrites the status side).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/helper_drafts.dart';
import 'package:udyoga/domain/helper_posts.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/linkedin.dart';
import 'package:udyoga/domain/pdf.dart';

import 'support.dart';

const _fixtures = 'test/fixtures/handoff/posts';
const _textReport = 'report-fake-0001', _carouselReport = 'report-fake-0002';
const _textPost = 'udyoga-post-report-fake-0001-20261127100000';
const _carouselPost = 'udyoga-post-report-fake-0002-20261127100100';

/// A tiny two-page carousel PDF, the same bytes every time.
Uint8List _pdf() => imagePdf([
  for (final shade in [0x20, 0xE0])
    (width: 4, height: 5, rgb: Uint8List.fromList(List.filled(4 * 5 * 3, shade))),
]);

Future<void> _report(CareerBook book, String id, LinkedInTool tool, String headline, String text) =>
    book.save(
      book.db.careerReports,
      CareerReportsCompanion.insert(
        id: id,
        kind: tool.kind,
        created: '2026-11-27T09:00',
        content: jsonEncode({
          'headline': headline,
          'sections': [
            {
              'title': 'Post',
              'blocks': [
                {'label': 'Hook #3', 'text': text, 'copy': true},
              ],
            },
          ],
          if (tool == LinkedInTool.carousel)
            'slides': [
              {'title': 'Five records habits', 'body': 'A made-up carousel.'},
            ],
        }),
        sources: const Value('[]'),
      ),
      id,
    );

const _postText =
    'Three things a records audit taught me about small teams.\n\n'
    '1. Write the rule down once.\n2. Name who owns it.\n3. Check it every quarter.\n\n'
    'What would you add?';
const _caption = 'Five records habits from a made-up archive team. Swipe through.';

Future<CareerBook> _book() async {
  final book = CareerBook(await Store.open(memoryDatabase()));
  await _report(book, _textReport, LinkedInTool.post, 'Records audit lessons', _postText);
  await _report(book, _carouselReport, LinkedInTool.carousel, 'Five records habits', _caption);
  return book;
}

Future<Json> _content(CareerBook book, String id) async => decodeObject(
  (await (book.db.select(book.db.careerReports)..where((r) => r.id.equals(id))).getSingle()).content,
);

Future<void> _send(CareerBook book, String folder) async {
  await book.sendPostViaHelper(folder, _textReport, now: DateTime.utc(2026, 11, 27, 10));
  await book.sendPostViaHelper(
    folder,
    _carouselReport,
    now: DateTime.utc(2026, 11, 27, 10, 1),
    visibility: 'connections',
    scheduleAt: DateTime.utc(2026, 11, 28, 8, 30),
    pdf: _pdf(),
    pdfTitle: 'Five records habits',
  );
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('udyoga-posts-'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('"Send to helper" writes the files, then the post, byte for byte as the helper read them', () async {
    final book = await _book();
    await _send(book, dir.path);
    expect(Directory('${dir.path}/tmp').listSync(), isEmpty, reason: 'nothing half-written left behind');
    final files = {
      'outbox/$_textPost.json',
      'outbox/$_carouselPost.json',
      'files/$_carouselPost/carousel.pdf',
    };
    for (final f in files) {
      final got = File('${dir.path}/$f').readAsBytesSync();
      if (Platform.environment['UDYOGA_UPDATE_FIXTURES'] == '1') {
        File('$_fixtures/$f')
          ..createSync(recursive: true)
          ..writeAsBytesSync(got);
      }
      expect(got, File('$_fixtures/$f').readAsBytesSync(), reason: f);
    }
    expect(Directory('${dir.path}/files').listSync(), hasLength(1), reason: 'only the carousel has files');
    final post = jsonDecode(File('${dir.path}/outbox/$_carouselPost.json').readAsStringSync()) as Map;
    expect(post['attachments'], [
      {'path': 'files/$_carouselPost/carousel.pdf', 'type': 'document', 'title': 'Five records habits'},
    ]);
    expect(post['visibility'], 'connections');
    expect(post['scheduleAt'], '2026-11-28T08:30:00Z');

    // The studio draft knows it went to the helper.
    expect(helperPostOf(await _content(book, _textReport)), {'id': _textPost, 'state': 'pending'});

    // Not for other kinds of draft, nor unsafe names.
    await book.save(
      book.db.careerReports,
      CareerReportsCompanion.insert(
        id: 'report-fake-0003',
        kind: LinkedInTool.profile.kind,
        created: '2026',
        content: '{}',
      ),
      'report-fake-0003',
    );
    await expectLater(
      book.sendPostViaHelper(dir.path, 'report-fake-0003', now: DateTime.utc(2026)),
      throwsStateError,
    );
    expect(
      () => writeHelperPost(dir.path, HelperPost(id: '../x', createdAt: DateTime.utc(2026), text: 'x')),
      throwsArgumentError,
    );
  });

  test('the helper\'s answers go on the studio drafts: posted with its link, scheduled', () async {
    final book = await _book();
    await _send(book, dir.path);
    Directory('${dir.path}/status').createSync();
    for (final f in Directory('$_fixtures/status').listSync().whereType<File>()) {
      f.copySync('${dir.path}/status/${f.uri.pathSegments.last}');
    }
    expect(await book.importHelperPostStatuses(dir.path), 2);
    expect(await book.importHelperPostStatuses(dir.path), 0, reason: 'the same answers change nothing');

    final posted = await _content(book, _textReport);
    expect(helperPostOf(posted)?['state'], 'posted');
    expect(posted['postedUrl'], startsWith('https://www.linkedin.com/feed/update/urn:li:activity:'));
    expect(posted['posted'], hasLength(10));
    final scheduled = await _content(book, _carouselReport);
    expect(helperPostOf(scheduled)?['state'], 'scheduled');
    expect(helperPostOf(scheduled)?['scheduledAt'], '2026-11-28T08:30:00Z');
    expect(scheduled['posted'], isNull);

    // The message importer leaves post answers alone.
    expect(await book.importHelperStatuses(dir.path), 0);
  });

  test('answers are checked: version, kind, state, and only LinkedIn links', () {
    expect(PostStatus.parse('{"v":2,"kind":"post","id":"$_textPost","state":"posted"}'), isNull);
    expect(PostStatus.parse('{"v":1,"kind":"message","id":"$_textPost","state":"posted"}'), isNull);
    expect(PostStatus.parse('{"v":1,"kind":"post","id":"$_textPost","state":"sent"}'), isNull);
    expect(PostStatus.parse('{"v":1,"kind":"post","id":"udyoga-x","state":"posted"}'), isNull);
    final s = PostStatus.parse(
      '{"v":1,"kind":"post","id":"$_textPost","state":"posted","url":"https://evil.example/feed/update/x"}',
    )!;
    expect(s.url, '');
    expect(
      HelperStatus.parse(
        '{"v":1,"updatedAt":"2026-11-27T12:00:00Z","channels":{"linkedin":{"drafts":true,"posts":true,"state":"ok",'
        '"budget":{"post":{"dayLeft":1,"dayLimit":2,"weekLeft":6,"weekLimit":7}}}}}',
      )!.channels['linkedin']!.postBudget,
      (dayLeft: 1, dayLimit: 2, weekLeft: 6, weekLimit: 7),
    );
  });
}
