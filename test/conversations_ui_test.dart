// The Conversations page, its own navigation entry: the header that always says
// who and where, logging a hand-sent message, and the Screener. Every person
// is made up.
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/conversations_page.dart';

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

  testWidgets('Copy & open, then "Did you send it?" logs the message as sent by hand', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedConversations);
    await app.run();
    await openConversations(app);
    await app.tap(find.text('Jordan Example').first);
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
}
