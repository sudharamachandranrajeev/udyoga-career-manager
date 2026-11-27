// "Send via LinkedIn helper" in the composer: shown only while the hand-off
// is on and the helper app's status.json is fresh, never for a connection
// note; otherwise Copy & open, as before. While it shows, the pace notice
// gives the helper's budget. Every person is made up.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/domain/helper_drafts.dart';

import 'app_harness.dart';
import 'seed.dart';

HelperStatus _status(DateTime at, {bool drafts = true}) => HelperStatus(
  updatedAt: at,
  channels: {
    'linkedin': HelperChannel(
      drafts: drafts,
      state: 'ok',
      messages: (dayLeft: 37, dayLimit: 40, weekLeft: 147, weekLimit: 150),
      invites: (dayLeft: 15, dayLimit: 15, weekLeft: 80, weekLimit: 80),
    ),
  },
);

Future<AppHarness> _open(
  WidgetTester tester, {
  required bool on,
  HelperStatus? status,
  String? folder,
}) async {
  final app = AppHarness(tester)..desktop();
  await app.open(seed: seedConversations);
  await app.run(
    overrides: [
      handoffEnabledProvider.overrideWith((ref) async => on),
      handoffFolderProvider.overrideWithValue(folder ?? '/nonexistent/handoff'),
      helperStatusProvider.overrideWith((ref) async => on ? status : null),
      handoffProvider.overrideWith(_NoHandoff.new),
    ],
  );
  await app.go('Conversations');
  await app.tap(find.text('Jordan Example').first);
  return app;
}

/// The folder reader stays out of widget tests.
class _NoHandoff extends HandoffController {
  @override
  String build() => '';

  @override
  Future<Null> run() async => null;
}

const _helper = Key('composer-send-via-helper');
const _copy = Key('composer-copy-open');

void main() {
  testWidgets('with a fresh helper status: Send via LinkedIn helper and its budget', (tester) async {
    final app = await _open(tester, on: true, status: _status(DateTime.now()));
    expect(find.byKey(_helper), findsOneWidget);
    expect(find.byKey(_copy), findsNothing);
    expect(
      find.textContaining('The helper app\'s LinkedIn budget: 37 of 40 messages left today'),
      findsOneWidget,
    );

    // A connection note still goes by hand.
    await app.tap(find.text('Connection note'));
    expect(find.byKey(_helper), findsNothing);
    expect(find.byKey(_copy), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('pressing it leaves the draft in the outbox and a queued message in the thread', (
    tester,
  ) async {
    final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('udyoga-helper-ui-'));
    final app = await _open(tester, on: true, status: _status(DateTime.now()), folder: dir!.path);
    await app.enter('Message', 'Tuesday at ten works for me.');
    await tester.runAsync(() async {
      await tester.tap(find.byKey(_helper));
      for (var i = 0; i < 50 && !Directory('${dir.path}/outbox').existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await app.settle();
    final files = await tester.runAsync(() async => Directory('${dir.path}/outbox').listSync());
    expect(files, hasLength(1));
    final sent = await tester.runAsync(() async {
      final db = app.book.db;
      return (await db.select(db.messages).get())
          .where((m) => m.body == 'Tuesday at ten works for me.')
          .toList();
    });
    expect([sent!.single.source, sent.single.status], ['helper', 'queued']);
    expect(find.textContaining('In the helper app: check it and press Send there'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
    await tester.runAsync(() => dir.delete(recursive: true));
  });

  testWidgets('a stale status, a helper that takes no drafts, or the hand-off off: Copy & open', (
    tester,
  ) async {
    for (final (on, status) in [
      (true, _status(DateTime.now().subtract(const Duration(minutes: 10)))),
      (true, _status(DateTime.now(), drafts: false)),
      (true, null),
      (false, _status(DateTime.now())),
    ]) {
      final app = await _open(tester, on: on, status: status);
      expect(find.byKey(_helper), findsNothing, reason: '$on $status');
      expect(find.byKey(_copy), findsOneWidget);
      expect(find.textContaining('helper app\'s LinkedIn budget'), findsNothing);
      expect(tester.takeException(), isNull);
      await app.close();
    }
  });
}
