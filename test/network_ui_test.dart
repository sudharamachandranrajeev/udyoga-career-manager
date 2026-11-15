// The Network page, reached from Contacts: connections at target employers,
// the lead finder, people named in saved adverts, and logging people met at
// an event. Every person is made up.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/communities.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/ui/network_page.dart';

import 'app_harness.dart';
import 'support.dart';

Future<void> _seed(CareerBook book) async {
  await book.saveProfile(sampleProfile);
  final ids = await book.importPostings(
    [
      samplePosting(
        title: 'Digital Lead',
        company: 'Example Health NHS Foundation Trust',
        url: 'https://www.jobs.nhs.uk/candidate/jobadvert/X1',
        description:
            'Lead our digital team.\n\nFor informal enquiries please contact Jordan Example, '
            'Head of Digital, on 0113 496 0000.',
      ),
    ],
    sampleProfile,
    today: '2026-11-10',
  );
  await book.setJobStatus(ids.single, 'saved');
  await book.importLeads(
    [
      const LeadSuggestion({
        'name': 'Kim Peer',
        'title': 'Records Officer',
        'company': 'Example Health',
        'kind': 'peer',
        'linkedin': 'https://www.linkedin.com/in/kim-peer',
        'source': 'LinkedIn connection',
        'why': '',
        'approach': '',
      }),
    ],
    today: '2026-11-10',
    chase: false,
    sourceKind: 'archive',
  );
}

void main() {
  testWidgets('who you know, the lead finder, advert contacts and people met', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: _seed);
    await app.run();
    await app.go('Contacts');
    await app.tap(find.byTooltip('Network and lead finder'));
    expect(find.byType(LeadFinderPage), findsOneWidget);

    // A connection at the trust a job is saved at, despite the suffix.
    expect(find.text('Who you already know at your target employers'), findsOneWidget);
    expect(find.text('Kim Peer'), findsOneWidget);

    // Searches build from the prefilled role; the user saves who they found.
    await app.tap(find.widgetWithText(ActionChip, 'Example Health NHS Foundation Trust'));
    expect(find.text('Google X-ray of LinkedIn'), findsOneWidget);
    expect(find.text('NHS Jobs adverts'), findsOneWidget);
    await app.tap(find.text('Save a person you found'));
    await app.enter('Name', 'Sam Sample');
    await app.enter('Link to their profile or page', 'https://www.linkedin.com/in/sam-sample');
    await app.tapText('Save');

    // The advert's named contact, saved as a lead.
    expect(find.text('Jordan Example'), findsOneWidget);
    await app.tap(find.text('Save as lead'));
    expect(find.text('Jordan Example'), findsNothing, reason: 'saved people leave the list');

    // Someone met at an event.
    await app.tap(find.text('Log people I met').first);
    await app.enter('Name', 'Casey Example');
    await app.enter('What you talked about', 'Records digitisation');
    await app.tapText('Save');

    final saved = await tester.runAsync(() async {
      final db = app.book.db;
      return {for (final c in await db.select(db.careerContacts).get()) c.name: c};
    });
    final sam = saved!['Sam Sample']!;
    expect(
      (sam.sourceKind, sam.source, sam.linkedin, sam.company),
      ('other', 'LinkedIn', 'https://www.linkedin.com/in/sam-sample', 'Example Health NHS Foundation Trust'),
    );
    final jordan = saved['Jordan Example']!;
    expect(
      (jordan.sourceKind, jordan.title, jordan.phone, jordan.sourceUrl),
      ('advert', 'Head of Digital', '0113 496 0000', 'https://www.jobs.nhs.uk/candidate/jobadvert/X1'),
    );
    expect(jordan.jobId, isNotNull);
    final casey = saved['Casey Example']!;
    expect((casey.sourceKind, casey.source), ('met', communities.first.name));
    expect(casey.notes, 'Met at ${communities.first.name}. Records digitisation');
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('the Network page fits a phone', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: _seed);
    await app.run();
    await app.go('Contacts');
    await app.tap(find.byTooltip('Network and lead finder'));
    await tester.scrollUntilVisible(
      find.text(communities.last.name),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
