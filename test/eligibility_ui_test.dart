import 'package:brahma_core/brahma_core.dart' show today;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/eligibility.dart' show addMonths;
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/todos.dart';
import 'package:udyoga/domain/work_rights.dart';
import 'package:udyoga/ui/job_page.dart';

import 'app_harness.dart';
import 'support.dart';

void main() {
  final now = today();

  Future<void> seedRights(CareerBook b) async {
    await b.saveProfile(sampleProfile);
    await b.saveWorkRights(
      WorkRights(
        passports: const ['IN'],
        rightToWork: [RightToWork(country: 'GB', status: 'Example work visa', until: addMonths(now, 10))],
        languages: const [SpokenLanguage('English', LanguageLevel.fluent)],
      ),
    );
  }

  testWidgets('Today shows due to-dos to tick off, and the visa clock', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (b) async {
        await seedRights(b);
        await b.importTodos([
          SeedTodo(id: 'late', title: 'Send the reference form', due: addMonths(now, -1)),
          SeedTodo(id: 'later', title: 'Book a refresher course', due: addMonths(now, 2)),
        ], today: now);
      },
    );
    await app.run();
    expect(find.text('To-do'), findsWidgets);
    expect(find.text('Send the reference form'), findsOneWidget);
    expect(find.textContaining('Overdue'), findsOneWidget);
    expect(find.text('Book a refresher course'), findsOneWidget);
    expect(find.text('Visa clock'), findsOneWidget);
    expect(find.textContaining('12 months left'), findsWidgets);

    await app.tap(find.byType(Checkbox).first);
    final done = (await tester.runAsync(app.book.todos))!
        .firstWhere((t) => t.title == 'Send the reference form');
    expect(done.status, 'done');
    await app.close();
  });

  testWidgets('a job page quotes the lines that limit who can apply', (tester) async {
    final app = AppHarness(tester)..phone();
    late String id;
    await app.open(
      seed: (b) async {
        await seedRights(b);
        id = (await b.importPostings(
          [
            Posting(
              source: 'adzuna',
              sourceId: 'a1',
              title: 'Clinical Informatics Nurse',
              company: 'Example Clinic Inc',
              country: 'US',
              description:
                  'EPR roll-out. We are unable to sponsor visas for this role. Fluent Spanish is essential.',
            ),
          ],
          await b.profile(),
          today: now,
        )).single;
      },
    );
    await app.run(home: JobPage(id));
    expect(find.text('You may not be able to apply'), findsOneWidget);
    expect(find.text('"We are unable to sponsor visas for this role."'), findsOneWidget);
    expect(find.textContaining('Spanish'), findsWidgets);
    expect(find.text('Jobs by Adzuna'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('jobs the exclusions rule out are hidden, with a count', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (b) async {
        await b.saveProfile(sampleProfile);
        await b.importPostings(
          [samplePosting(), samplePosting(id: '2', title: 'Bank Staff Nurse')],
          sampleProfile,
          today: now,
        );
        await b.saveProfile(
          sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(exclusions: ['bank'])),
        );
      },
    );
    await app.run();
    await app.go('Jobs');
    expect(find.text('Clinical Informatics Nurse'), findsOneWidget);
    expect(find.text('Bank Staff Nurse'), findsNothing);
    expect(find.text('1 job hidden by your exclusions (Profile, Targets).'), findsOneWidget);
    await app.close();
  });

  testWidgets('the profile shows rights to work with their countdown', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: seedRights);
    await app.run();
    await app.go('Profile');
    await tester.ensureVisible(find.text('Right to work and languages'));
    await app.settle();
    expect(find.text('Passports: India'), findsOneWidget);
    expect(find.text('Languages: English (fluent)'), findsOneWidget);
    expect(find.text('United Kingdom: Example work visa'), findsOneWidget);
    expect(find.text('10 months left'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('to-dos are added and edited on the Growth page', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: (b) => b.saveProfile(sampleProfile));
    await app.run();
    await app.go('Growth');
    await app.tapText('Add to-do');
    await app.enter('What to do', 'Ask for a reference');
    await app.enter('Due', '2031-02-30');
    await app.tapText('Save');
    expect(find.text('Write the due date as yyyy-mm-dd.'), findsOneWidget);
    await app.enter('Due', '2031-02-03');
    await app.tapText('Save');
    expect(find.text('Ask for a reference'), findsOneWidget);

    await app.tapText('Ask for a reference');
    await app.enter('What to do', 'Ask two people for a reference');
    await app.tapText('Save');
    expect(find.text('Ask two people for a reference'), findsOneWidget);
    final t = (await tester.runAsync(app.book.todos))!.single;
    expect((t.title, t.target, t.kind), ('Ask two people for a reference', '2031-02-03', 'task'));
    await app.close();
  });
}
