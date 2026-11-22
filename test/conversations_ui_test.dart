// The Conversations page, its own navigation entry: the header that always says
// who and where, logging a hand-sent message, drafts from Vidya, and the
// Screener. Every person is made up.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/vidya_drafts.dart';
import 'package:udyoga/ui/conversations_page.dart';
import 'package:udyoga/ui/kit/kit.dart';

import 'app_harness.dart';
import 'seed.dart';

Future<void> openConversations(AppHarness app) async {
  await app.go('Conversations');
  expect(find.byType(ConversationsPage), findsOneWidget);
}

void main() {
  testWidgets('the thread header always says who, the role, the channel and where they were found', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedConversations);
    await app.run();
    await openConversations(app);
    expect(find.text('Needs reply'), findsWidgets);
    expect(find.text('Logged by you'), findsWidgets);
    expect(find.text('LinkedIn message'), findsWidgets);
    await app.tap(find.text('Jordan Example').first);
    expect(
      find.text(
        'To Jordan Example · Practice Manager, Example Health Trust · via LinkedIn message · '
        'found on NHS Jobs advert, 10 Nov 2026',
      ),
      findsOneWidget,
    );
    expect(find.text('Thanks, happy to talk next week.'), findsNWidgets(2), reason: 'the row and the bubble');
    expect(tester.takeException(), isNull);

    // An e-mail to a personal address carries the PECR hint.
    await app.tap(find.text('Sam Sample').first);
    expect(find.textContaining('via Email · you@example.org'), findsOneWidget);
    expect(find.textContaining('PECR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('a draft from Vidya goes into the message box, and nothing is sent', (tester) async {
    // Written by Vidya's tests (test/fixtures/vidya-email-drafts.json there).
    final drafts = File('test/fixtures/vidya-email-drafts.json').readAsStringSync();
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (b) async {
        await seedConversations(b);
        await b.db
            .into(b.db.bridgeStudyProgress)
            .insert(
              BridgeStudyProgressCompanion.insert(
                id: emailDraftsId,
                progress: Value(drafts),
                updated: '2026-12-06T09:00:00Z',
              ),
            );
      },
    );
    await app.run();
    await openConversations(app);
    await app.tap(find.text('Jordan Example').first);
    await app.tap(find.byKey(const Key('composer-from-vidya')));
    expect(find.text('Ask for feedback by criterion'), findsOneWidget);
    expect(find.textContaining('Example Officer at Example Health Trust'), findsWidgets);
    await app.tap(find.byKey(const Key('vidya-draft-fixture-feedback')));
    final box = tester.widget<TextField>(find.widgetWithText(TextField, 'Message'));
    expect(box.controller!.text, 'Dear Hiring Manager,\n\nThank you for interviewing me.');
    final sent = await tester.runAsync(() => app.book.db.select(app.book.db.messages).get());
    expect(sent!.where((m) => m.body.contains('Thank you for interviewing me')), isEmpty);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('Copy & open, then "Did you send it?" logs the message as sent by hand', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedConversations);
    await app.run();
    await openConversations(app);
    await app.tap(find.text('Jordan Example').first);
    expect(find.byKey(const Key('composer-from-vidya')), findsNothing, reason: 'no drafts from Vidya');
    await app.enter('Message', 'Tuesday at ten works for me.');
    await app.tap(find.text('Copy & open'));
    expect(find.text('Did you send it?'), findsOneWidget);
    await app.tapText('Yes, log it');
    expect(find.text('Did you send it?'), findsNothing);

    final logged = await tester.runAsync(() async {
      final db = app.book.db;
      return (await db.select(db.messages).get())
          .where((m) => m.body == 'Tuesday at ten works for me.')
          .toList();
    });
    expect(logged!.single.direction, 'out');
    expect(logged.single.source, 'manual');
    expect(find.text('Tuesday at ten works for me.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('a reply that comes in fades in; what the user sends appears at once', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedConversations);
    await app.run();
    await openConversations(app);
    await app.tap(find.text('Jordan Example').first);
    expect(find.byType(BlurFadeIn), findsNothing, reason: 'the messages already there just show');
    await app.tapText('Log a reply');
    await app.enter('Their reply', 'Tuesday is perfect.');
    await app.tapText('Log it');
    expect(find.text('Tuesday is perfect.'), findsWidgets);
    expect(find.byType(BlurFadeIn), findsOneWidget);

    await app.enter('Message', 'See you then.');
    await app.tap(find.text('Log as sent'));
    expect(find.text('See you then.'), findsOneWidget);
    expect(find.byType(BlurFadeIn), findsOneWidget, reason: 'the sent message does not animate');
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('the Screener holds unknown senders until added or ignored, on a phone', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: seedConversations);
    await app.run();
    await openConversations(app);
    expect(find.text('someone@example.org'), findsNothing);
    await app.tap(find.text('Screener (1)'));
    await app.tapText('someone@example.org');
    expect(find.textContaining('From someone@example.org · via Email'), findsOneWidget);
    expect(find.text('Add as lead'), findsOneWidget);
    await app.tapText('Ignore');
    expect(find.text('Nobody waiting'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // On a phone the thread replaces the list, and Back returns to it.
    await app.tap(find.text('Inbox'));
    await app.tapText('Jordan Example');
    expect(find.textContaining('To Jordan Example · Practice Manager'), findsOneWidget);
    expect(find.text('Copy & open'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.tap(find.byTooltip('All conversations'));
    expect(find.text('Sam Sample'), findsOneWidget);
    await app.close();
  });

  testWidgets('a reply waiting on Today opens its own thread', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedConversations);
    await app.run();
    expect(find.text('Replies waiting'), findsOneWidget);
    await app.tap(find.text('Jordan Example').first);
    expect(find.byType(ConversationsPage), findsOneWidget);
    expect(find.textContaining('To Jordan Example · Practice Manager'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
