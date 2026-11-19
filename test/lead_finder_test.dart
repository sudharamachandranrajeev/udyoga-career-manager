// The lead finder: search links, people named in adverts, saving who the
// user found with where they found them, and the communities directory.
// Every person is made up.
import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/communities.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/lead_finder.dart';

import 'support.dart';

void main() {
  test('role, employer and place build the searches the user opens', () {
    final s = leadSearches(role: 'Practice Manager', employer: 'Example Health Trust', place: 'Exampleton');
    expect(s.map((s) => s.label), [
      'LinkedIn people search',
      'Google X-ray of LinkedIn',
      'Team and staff pages',
      'NHS Jobs adverts',
    ]);
    expect(s[0].uri.queryParameters, {
      'keywords': 'Practice Manager Exampleton',
      'company': 'Example Health Trust',
    });
    expect(s[1].uri.host, 'www.google.com');
    expect(
      s[1].uri.queryParameters['q'],
      'site:linkedin.com/in "Practice Manager" "Example Health Trust" "Exampleton"',
    );
    expect(s[2].uri.queryParameters['q'], startsWith('"Example Health Trust" ("meet the team"'));
    expect(s[2].sourceKind, 'team_page');
    expect(s[3].uri.host, 'www.jobs.nhs.uk');
    expect(s[3].uri.queryParameters, {
      'keyword': 'Practice Manager Example Health Trust',
      'location': 'Exampleton',
    });
    expect(s[3].sourceKind, 'advert');

    // With no employer or place there is no team page to look for.
    expect(
      leadSearches(role: 'Practice Manager').map((s) => s.label),
      isNot(contains('Team and staff pages')),
    );
  });

  group('people named in adverts', () {
    test('the sentence form', () {
      const advert =
          'We are looking for a Digital Lead to join us.\n\n'
          'For informal enquiries please contact Jordan Example, Head of Digital Services, on 0113 496 0000 '
          'or jordan.example@example.org.\n\nInterviews will be held in December.';
      expect(advertContacts(advert), [
        (
          name: 'Jordan Example',
          title: 'Head of Digital Services',
          email: 'jordan.example@example.org',
          phone: '0113 496 0000',
        ),
      ]);
    });

    test("NHS Jobs' contact block, and the same person not twice", () {
      const advert =
          '<p>For further information about the role contact Sam Sample.</p>'
          '<h3>Employer details</h3>\n'
          'Name\nSam Sample\nJob title\nPractice Manager\nEmail address\nsam.sample@example.org\n'
          'Telephone number\n0113 496 0001\n';
      expect(advertContacts(advert), [
        (
          name: 'Sam Sample',
          title: 'Practice Manager',
          email: 'sam.sample@example.org',
          phone: '0113 496 0001',
        ),
      ]);
    });

    test('an address with no name, and adverts with nobody named', () {
      expect(advertContacts('Any questions? Email recruitment@example.org.'), [
        (name: '', title: '', email: 'recruitment@example.org', phone: ''),
      ]);
      expect(advertContacts('Informal Enquiries Welcome. Please apply online.'), isEmpty);
      expect(advertContacts('A great team in a great place.'), isEmpty);
    });
  });

  test('a person found by hand keeps where, how and when they were found', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    final s = leadSearches(role: 'Practice Manager', employer: 'Example Health Trust').first;
    expect(
      await book.saveFoundLead(
        name: 'Jordan Example',
        title: 'Practice Manager',
        company: 'Example Health Trust',
        sourceKind: s.sourceKind,
        source: s.source,
        sourceUrl: 'https://www.linkedin.com/in/jordan-example',
        today: '2026-11-15',
      ),
      isTrue,
    );
    final l = (await book.db.select(book.db.careerContacts).get()).single;
    expect(
      (l.sourceKind, l.source, l.sourceUrl, l.foundOn),
      ('other', 'LinkedIn', 'https://www.linkedin.com/in/jordan-example', '2026-11-15'),
    );
    expect(l.linkedin, 'https://www.linkedin.com/in/jordan-example');
    expect(howIFoundYou(l), startsWith('I came across your name on LinkedIn.'));

    // Saved again: not doubled.
    expect(
      await book.saveFoundLead(
        name: 'Jordan Example',
        company: 'Example Health Trust',
        sourceKind: 'other',
        today: '2026-11-15',
      ),
      isFalse,
    );

    // From an advert: the job, its link and the phone number come along.
    final job = newId();
    await book.save(
      book.db.jobListings,
      JobListingsCompanion.insert(
        id: job,
        title: 'Digital Lead',
        found: '2026-11-10',
        url: const Value('https://www.jobs.nhs.uk/candidate/jobadvert/X1'),
      ),
      job,
    );
    await book.saveFoundLead(
      name: 'Sam Sample',
      email: 'sam.sample@example.org',
      phone: '0113 496 0001',
      kind: 'hiring_manager',
      sourceKind: 'advert',
      source: 'the advert for Digital Lead',
      sourceUrl: 'https://www.jobs.nhs.uk/candidate/jobadvert/X1',
      jobId: job,
      today: '2026-11-15',
    );
    final sam = (await book.db.select(book.db.careerContacts).get()).singleWhere(
      (c) => c.name == 'Sam Sample',
    );
    expect(
      (sam.jobId, sam.phone, sam.sourceKind, sam.kind),
      (job, '0113 496 0001', 'advert', 'hiring_manager'),
    );
    expect(sam.linkedin, isEmpty);

    // Someone marked "do not contact" is not saved again, under any name.
    await book.setDoNotContact(sam.id, true, today: '2026-11-15');
    expect(
      await book.saveFoundLead(
        name: 'S. Sample',
        email: 'Sam.Sample@example.org',
        sourceKind: 'advert',
        today: '2026-11-15',
      ),
      isFalse,
    );
  });

  test('met in person: no "how I found you" line is needed', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    final c = communities.first;
    await book.saveFoundLead(
      name: 'Kim Peer',
      sourceKind: 'met',
      source: c.name,
      sourceUrl: c.url,
      note: 'Met at ${c.name}.',
      today: '2026-11-15',
    );
    final l = (await book.db.select(book.db.careerContacts).get()).single;
    expect((l.sourceKind, l.source, l.notes), ('met', c.name, 'Met at ${c.name}.'));
    expect(howIFoundYou(l), isEmpty);
    expect(foundOnText(l), '${c.name}, 15 Nov 2026');
  });

  test('the communities directory is well formed', () {
    expect(communities.map((c) => c.name).toSet(), hasLength(communities.length));
    for (final c in communities) {
      expect(Uri.parse(c.url).scheme, 'https', reason: c.name);
      expect(communityKinds, contains(c.kind), reason: c.name);
      expect(c.why, isNotEmpty);
    }
    expect(
      communities.map((c) => c.name),
      containsAll([
        'FutureNHS',
        'NHS Networks',
        'Shuri Network',
        'AMSPAR',
        'HL7 UK',
        'HDR UK',
        'IHRIM',
        'FEDIP',
      ]),
    );
    // Regional events span the UK, not one city.
    final regions = {for (final c in communities) c.region}..remove('');
    expect(regions.length, greaterThanOrEqualTo(5));
    expect(regions, containsAll(['London', 'Scotland', 'Wales']));
  });
}
