import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/ats.dart';
import 'package:udyoga/domain/employers.dart';
import 'package:udyoga/domain/page_reader.dart';
import 'package:udyoga/domain/recipes.dart';
import 'package:udyoga/ui/site_page.dart';

import 'app_harness.dart';
import 'recipes_test.dart' show fillRecipe;
import 'support.dart';

void main() {
  final html = File('test/fixtures/pages/job_ld.html').readAsStringSync();
  const url = 'https://jobs.example.org/vacancy/1042';

  Future<void> openPage(AppHarness h, WidgetTester tester, {String at = url}) async {
    h.browser
      ..current = (url: at, title: 'Records Clerk | Example Jobs', text: 'Records Clerk')
      ..snap = PageSnapshot(
        url: at,
        title: 'Records Clerk | Example Jobs',
        text: 'Records Clerk',
        ld: ldScriptsIn(html),
        html: html,
      );
    unawaited(openSite(tester.element(find.byType(Scaffold).first), url: at, title: 'Example Jobs'));
    await h.settle();
  }

  testWidgets('Read this page shows what it found and keeps only what is ticked', (tester) async {
    final h = AppHarness(tester)..desktop();
    await h.open(seed: (b) => b.saveProfile(sampleProfile));
    await h.run();
    await openPage(h, tester);
    await h.tap(find.byTooltip('Read this page'));
    expect(find.text('Found on this page'), findsOneWidget);
    expect(find.text('Job: Records Clerk'), findsOneWidget);
    expect(find.text('Person: Sam Placeholder'), findsOneWidget);
    expect(find.text('Employer: Example Health Trust'), findsOneWidget);

    // Nothing is ticked, so Keep does nothing yet.
    final keep = find.widgetWithText(TextButton, 'Keep');
    expect(tester.widget<TextButton>(keep).onPressed, isNull);

    await h.tap(find.bySemanticsLabel('Keep Records Clerk'));
    await h.tap(find.bySemanticsLabel('Keep Example Health Trust'));
    await h.tap(keep);

    late List<Job> jobs;
    late List<Lead> leads;
    late List<WatchedEmployer> watched;
    await tester.runAsync(() async {
      jobs = await h.book.db.select(h.book.db.jobListings).get();
      leads = await h.book.db.select(h.book.db.careerContacts).get();
      watched = await h.book.watchedEmployers();
    });
    expect(jobs.single.title, 'Records Clerk');
    expect(jobs.single.closing, '2026-12-01');
    expect(jobs.single.status, 'saved');
    // The person was not ticked, so is not kept.
    expect(leads, isEmpty);
    expect(watched.single.name, 'Example Health Trust');
  });

  testWidgets('Fill a text box: draft, dry run, then only the text box is filled', (tester) async {
    final dir = Directory.systemTemp.createTempSync('udyoga-recipes');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/fill.json').writeAsStringSync(
      jsonEncode({
        ...fillRecipe(),
        'urlPatterns': ['https://jobs.example.org/*'],
      }),
    );
    final h = AppHarness(tester)..desktop();
    await h.open(
      seed: (b) async {
        await b.saveProfile(sampleProfile);
        await b.db.setLocalSetting(recipesFolderKey, dir.path);
      },
    );
    await h.run();
    await openPage(h, tester);
    await h.settle();
    await h.tap(find.byTooltip('Fill a text box'));
    await tester.enterText(find.byType(TextField).last, 'Hello Sam, a short note.');
    await h.tapText('Preview');
    expect(find.text('Dry run: nothing is filled yet'), findsOneWidget);
    expect(find.text('Fills today: 0 of 10'), findsOneWidget);
    expect(h.browser.fills, isEmpty);
    await h.tapText('Fill it in');
    expect(h.browser.fills, [('textarea#message-body', 'Hello Sam, a short note.')]);
  });
}
