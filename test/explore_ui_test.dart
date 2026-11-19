import 'package:brahma_core/brahma_core.dart' show today, addMonths;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/employers.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/todos.dart';
import 'package:udyoga/domain/tracks.dart';
import 'package:udyoga/domain/work_rights.dart';

import 'app_harness.dart';
import 'support.dart';

void main() {
  final now = today();

  Future<void> seed(CareerBook b) async {
    await b.saveProfile(
      CandidateProfile(
        name: sampleProfile.name,
        country: 'GB',
        currentRole: 'Clinical coder',
        targets: const Targets(roles: ['Business systems analyst'], countries: ['GB', 'IE']),
      ),
    );
    await b.saveWorkRights(
      WorkRights(
        passports: const ['IN'],
        rightToWork: [RightToWork(country: 'GB', status: 'Example work visa', until: addMonths(now, 10))],
        languages: const [SpokenLanguage('English', LanguageLevel.fluent)],
      ),
    );
  }

  testWidgets('Explore at 360dp: screened countries, a country page, a track and its to-do', (tester) async {
    final app = AppHarness(tester);
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await app.open(seed: seed);
    await app.run();
    await app.go('Explore');
    expect(find.text('Countries'), findsOneWidget);
    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('Ready'), findsWidgets);

    // Search, then open Ireland.
    await app.enter('Search countries', 'irel');
    expect(find.text('United Kingdom'), findsNothing);
    await app.tapText('Ireland');
    expect(find.text('General Employment Permit'), findsOneWidget);
    expect(find.textContaining('€36,605'), findsWidgets);
    expect(find.text('Your job codes'), findsOneWidget);
    expect(find.textContaining('SOC 2020 3549'), findsWidgets);

    await app.tap(find.byTooltip('Track this route'));
    final tracks = (await tester.runAsync(app.book.tracks))!;
    expect(tracks.single.country, 'IE');
    expect(milestonesOf(tracks.single), isNotEmpty);

    await tester.pageBack();
    await app.settle();
    await app.tap(find.textContaining('Tracks ('));
    expect(find.text(tracks.single.title), findsOneWidget);
    await app.tap(find.byTooltip('Make a to-do from "${milestonesOf(tracks.single).first.title}"'));
    final todos = (await tester.runAsync(app.book.todos))!;
    expect(todos.single.kind, todoKind);
    expect(todos.single.id, startsWith('todo.track.'));
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('the route-data filter hides countries without rules', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seed);
    await app.run();
    await app.go('Explore');
    expect(find.text('With route data'), findsOneWidget);
    await app.tap(find.text('With route data'));
    expect(find.text('Fiji'), findsNothing);
    await app.close();
  });

  testWidgets('a country page adds the country to the targets', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seed);
    await app.run();
    await app.go('Explore');
    await app.enter('Search countries', 'new zea');
    await app.tapText('New Zealand');
    await app.tap(find.text('Add to targets'));
    final p = (await tester.runAsync(app.book.profile))!;
    expect(p.searchCountries, containsAll(['GB', 'IE', 'NZ']));
    expect(find.text('Add to targets'), findsNothing);
    expect(find.byTooltip('In your target countries'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('employers you watch: added from the Jobs page, their new jobs on Today', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (b) async {
        await seed(b);
        await b.importPostings([samplePosting()], sampleProfile, today: now);
      },
    );
    await app.run();
    await app.go('Jobs');
    await app.tap(find.byIcon(Icons.apartment_outlined));
    expect(find.text('No employers yet'), findsOneWidget);
    await app.tap(find.text('Watch an employer').last);
    await app.enter('Name', 'Example Health Trust');
    await app.enter('Where its jobs are', 'nhs');
    await app.tapText('Save');
    final watched = (await tester.runAsync(app.book.watchedEmployers))!;
    expect(watched.single.nhs, isTrue);
    expect(find.text('Clinical Informatics Nurse'), findsWidgets);

    await tester.pageBack();
    await app.settle();
    await app.go('Today');
    expect(find.text('From employers you watch'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
