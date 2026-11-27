// "Send to helper" on a finished post: shown only while the hand-off is on
// and the helper app's status.json is fresh and says it takes posts;
// otherwise the post is copied by hand, as before. The helper's answer shows
// on the draft. All made up.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/domain/helper_drafts.dart';
import 'package:udyoga/domain/linkedin.dart';

import 'app_harness.dart';

HelperStatus _status(DateTime at, {bool posts = true}) => HelperStatus(
  updatedAt: at,
  channels: {
    'linkedin': HelperChannel(
      drafts: true,
      posts: posts,
      state: 'ok',
      postBudget: (dayLeft: 2, dayLimit: 2, weekLeft: 7, weekLimit: 7),
    ),
  },
);

Map<String, Object?> _post({Map<String, Object?>? helper}) => {
  'headline': 'Records audit lessons',
  'sections': [
    {
      'title': 'Post',
      'blocks': [
        {'label': 'Hook #3', 'text': 'Three made-up things a records audit taught me.', 'copy': true},
      ],
    },
  ],
  'helper': ?helper,
};

Future<AppHarness> _open(
  WidgetTester tester, {
  required bool on,
  HelperStatus? status,
  String? folder,
  Map<String, Object?>? helper,
}) async {
  final app = AppHarness(tester)..desktop();
  await app.open(
    seed: (book) async {
      await book.saveReport(LinkedInTool.post.kind, _post(helper: helper), const [], at: '2026-11-27T09:00');
    },
  );
  await app.run(
    overrides: [
      handoffEnabledProvider.overrideWith((ref) async => on),
      handoffFolderProvider.overrideWithValue(folder ?? '/nonexistent/handoff'),
      helperStatusProvider.overrideWith((ref) async => on ? status : null),
      handoffProvider.overrideWith(_NoHandoff.new),
    ],
  );
  await app.go('LinkedIn');
  await app.tap(find.text('Records audit lessons').first);
  return app;
}

class _NoHandoff extends HandoffController {
  @override
  String build() => '';

  @override
  Future<Null> run() async => null;
}

const _send = Key('send-post-to-helper');

void main() {
  testWidgets('with a fresh helper that takes posts: Send to helper writes the post', (tester) async {
    final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('udyoga-posts-ui-'));
    final app = await _open(tester, on: true, status: _status(DateTime.now()), folder: dir!.path);
    expect(find.byKey(_send), findsOneWidget);
    expect(find.textContaining('Posts left today: 2 of 2'), findsOneWidget);
    await app.tap(find.byKey(_send));
    await app.tap(find.text('Connections'));
    // The dialog's answer runs in the test's zone; file writes need real
    // time, so the two take turns.
    await tester.tap(find.text('Send'));
    bool written() =>
        Directory('${dir.path}/outbox').existsSync() &&
        Directory('${dir.path}/outbox').listSync().any((f) => f.path.endsWith('.json'));
    for (var i = 0; i < 100 && !(await tester.runAsync(() async => written()))!; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await app.settle();
    final files = await tester.runAsync(() async => Directory('${dir.path}/outbox').listSync());
    final post = jsonDecode(await tester.runAsync(() => (files!.single as File).readAsString()) ?? '') as Map;
    expect(
      [post['kind'], post['visibility'], post['text']],
      ['post', 'connections', 'Three made-up things a records audit taught me.'],
    );
    expect(find.text('With the helper app'), findsOneWidget);
    expect(find.byKey(_send), findsNothing, reason: 'sent once');
    expect(tester.takeException(), isNull);
    await app.close();
    await tester.runAsync(() => dir.delete(recursive: true));
  });

  testWidgets('a stale status, a helper that takes no posts, or the hand-off off: no button', (tester) async {
    for (final (on, status) in [
      (true, _status(DateTime.now().subtract(const Duration(minutes: 10)))),
      (true, _status(DateTime.now(), posts: false)),
      (true, null),
      (false, _status(DateTime.now())),
    ]) {
      final app = await _open(tester, on: on, status: status);
      expect(find.byKey(_send), findsNothing, reason: '$on $status');
      expect(find.text('Copy'), findsWidgets, reason: 'copying by hand stays');
      expect(tester.takeException(), isNull);
      await app.close();
    }
  });

  testWidgets('the helper\'s answer shows on the draft', (tester) async {
    final app = await _open(
      tester,
      on: true,
      status: _status(DateTime.now()),
      helper: {'id': 'udyoga-post-x', 'state': 'scheduled', 'scheduledAt': '2026-11-28T08:30:00Z'},
    );
    expect(find.textContaining('In LinkedIn\'s own scheduler'), findsOneWidget);
    expect(find.byKey(_send), findsNothing);
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
