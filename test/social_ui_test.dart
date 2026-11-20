// The post planner and Bluesky search widgets, in the LinkedIn studio and
// Find people, and the Bluesky card on Connected
// accounts. A fake Bluesky server answers; every handle is made up.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/domain/bluesky.dart';
import 'package:udyoga/domain/post_plan.dart';
import 'package:udyoga/ui/accounts_page.dart';
import 'package:udyoga/ui/bluesky_search.dart';
import 'package:udyoga/ui/post_planner.dart';

import 'app_harness.dart';
import 'fake_bluesky.dart';

void main() {
  testWidgets('post planner: a slot, a planned week, copy and open LinkedIn, posted', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    // Wednesday noon.
    final now = DateTime(2026, 11, 11, 12);
    await app.run(
      home: Scaffold(
        body: ListView(children: [PostPlanner(clock: () => now)]),
      ),
    );
    expect(find.text('Add a weekly slot, then plan the week.'), findsOneWidget);

    await app.tapText('Add slot');
    await app.tapText('Tuesday');
    await app.tapText('Thursday');
    await app.enter('Time', '08:30');
    await app.tapText('Add');
    expect(find.text('Thu 08:30'), findsOneWidget);

    await app.tapText('Plan this week');
    expect(find.text('Planned'), findsOneWidget);
    await app.tapText('Edit');
    await app.enter('Draft', 'Three things our records team learned in the first EPR month.');
    await app.tapText('Save');
    expect(find.textContaining('Three things'), findsOneWidget);

    await app.tapText('Copy & open LinkedIn');
    expect(app.browser.opened, isEmpty); // the system browser, not the in-app one
    await app.tapText('Mark posted');
    await app.enter('Link to the post (optional)', 'https://www.linkedin.com/posts/example-1');
    await app.tap(find.widgetWithText(FilledButton, 'Mark posted'));
    expect(find.text('Posted'), findsOneWidget);
    expect(find.text('Open the post'), findsOneWidget);
    await tester.runAsync(() async {
      final p = (await app.book.postsBetween('2026-11-09', '2026-11-16')).single;
      expect((p.status, p.postUrl), ('posted', 'https://www.linkedin.com/posts/example-1'));
      expect(postText(p), startsWith('Three things'));
    });
    await app.close();
  });

  testWidgets('Bluesky: connect with an app password, search a topic, save a person', (tester) async {
    final server = FakeBluesky()
      ..actors.add({
        'did': 'did:plc:jordan',
        'handle': 'jordan.example.com',
        'displayName': 'Jordan Example',
        'description': 'Health informatics in Exampleshire.',
      });
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run(
      overrides: [
        blueskyProvider.overrideWith(
          (ref) => Bluesky(app.session.book, server.client, app.session.keys.store),
        ),
      ],
      home: const Scaffold(
        body: SingleChildScrollView(child: Column(children: [BlueskyAccountCard(), BlueskySearch()])),
      ),
    );
    expect(find.text('Connect Bluesky'), findsNWidgets(2));
    await app.tap(find.text('Connect Bluesky').first);
    await app.enter('Handle', myHandle);
    await app.enter('App password', appPassword);
    await app.tapText('Sign in');
    expect(find.text('@$myHandle'), findsOneWidget);
    expect(find.text('Search, posting and direct messages.'), findsOneWidget);

    await app.tapText('health informatics');
    expect(find.text('Jordan Example'), findsOneWidget);
    expect(find.textContaining('Health informatics in Exampleshire.'), findsOneWidget);
    await app.tapText('Save');
    expect(find.byTooltip('Saved'), findsOneWidget);
    await tester.runAsync(() async {
      final c = (await app.book.db.select(app.book.db.careerContacts).get()).single;
      expect((c.name, c.basis, c.sourceKind), ('Jordan Example', 'legitimate_interest', 'other'));
    });
    await app.close();
  });

  testWidgets('the planner, Bluesky search and accounts sit where people look for them', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run();
    await app.go('LinkedIn');
    expect(find.byType(PostPlanner), findsOneWidget);
    await app.go('Find people');
    expect(find.byType(BlueskySearch), findsOneWidget);
    await app.go('Settings');
    await app.tap(find.text('Manage'));
    expect(find.byType(AccountsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
