import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/job_identity.dart';
import 'package:udyoga/domain/refresh.dart';
import 'package:udyoga/domain/role_family.dart';
import 'package:udyoga/domain/role_search.dart';

import 'app_harness.dart';
import 'support.dart';

const today = '2026-11-21';
const role = 'Digital Training Facilitator';

/// A job feed that records what it is asked and answers with [answer].
class _FakeFeed extends JobFeed {
  _FakeFeed(this.id, {this.answer = const [], this.most = 6});
  @override
  final String id;
  final List<Posting> answer;
  final int? most;
  final asked = <FeedQuery>[];

  @override
  String get name => 'Fake $id';
  @override
  bool get usesPlace => true;
  @override
  int? get maxTerms => most;
  @override
  bool covers(FeedQuery q) => q.country == 'GB';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    asked.add(q);
    return answer;
  }
}

Posting _post(
  String title, {
  String source = 'reed',
  String? id,
  String company = 'Example Health Trust',
  String location = 'Exampletown',
  String url = '',
  String? closing,
  String description = '',
}) => Posting(
  source: source,
  sourceId: id ?? '$source-$title-$company-$location',
  title: title,
  company: company,
  location: location,
  country: 'GB',
  url: url,
  description: description,
  closing: closing,
);

/// Made-up NHS Jobs answer: one trainer job and one nurse job.
const _nhsXml = '''<?xml version='1.0' encoding='UTF-8'?><nhsJobs>
<vacancyDetails><id>501</id><title>Clinical Systems Trainer</title><employer>Example Hospitals Trust</employer>
<salary>£31049.00 to £37796.00</salary><closeDate>2026-12-05</closeDate>
<url>https://www.jobs.nhs.uk/candidate/jobadvert/X1-26-501</url>
<locations><location>Exampletown, EX1 1AA</location></locations></vacancyDetails>
<vacancyDetails><id>502</id><title>Staff Nurse</title><employer>Example Hospitals Trust</employer>
<url>https://www.jobs.nhs.uk/candidate/jobadvert/X1-26-502</url></vacancyDetails>
</nhsJobs>''';

http.Client _nhsClient() => MockClient((r) async {
  if (r.url.host == 'www.jobs.nhs.uk') return http.Response.bytes(utf8.encode(_nhsXml), 200);
  return http.Response('{}', 200);
});

void main() {
  late CareerBook book;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
  });
  tearDown(() => book.db.close());

  final family = offlineFamily(role);
  final close = family.where(Closeness.close);

  group('what the feeds are asked', () {
    test('the chosen family titles reach the feeds, closest first, capped per feed', () async {
      final capped = _FakeFeed('reed');
      final open = _FakeFeed('arbeitnow', most: null);
      final q = RoleQuery(role: role, titles: family.titles);
      await RoleSearch(book, quietClient(), feeds: [capped, open]).run(q, today: today);
      final terms = capped.asked.single.terms;
      expect(terms.first, role);
      expect(terms, hasLength(RoleSearch.maxTitlesPerFeed));
      expect(terms, q.termsFor(RoleSearch.maxTitlesPerFeed));
      // Close titles before related and distant ones.
      expect(
        terms.skip(1).take(close.length - 1),
        [for (final t in close.skip(1)) t.title].take(RoleSearch.maxTitlesPerFeed - 1),
      );
      // A feed that filters one download takes every title at no cost.
      expect(open.asked.single.terms, hasLength(q.searched.length));
      expect(open.asked.single.terms, contains('Clinical Systems Trainer'));
      // NHS Jobs is told to keep any searched title.
      expect(capped.asked.single.keep, contains('Clinical Systems Trainer'));
    });

    test('exact title only sends the typed title alone, with the strict NHS check', () async {
      final feed = _FakeFeed('reed');
      await RoleSearch(book, quietClient(), feeds: [feed]).run(
        RoleQuery(
          role: role,
          titles: family.titles,
          exactOnly: true,
          skills: const ['create training materials'],
        ),
        today: today,
      );
      expect(feed.asked.single.terms, [role]);
      expect(feed.asked.single.keep, isNull);
    });

    test('chosen tasks and tools are searched too, never crowded out by titles', () {
      final q = RoleQuery(role: role, titles: family.titles, skills: const ['plan learning curriculum']);
      expect(q.termsFor(6), hasLength(6));
      expect(q.termsFor(6).last, 'plan learning curriculum');
      expect(q.termsFor(2), [role, 'plan learning curriculum']);
    });

    test('a routine refresh still sends each feed as many terms as before', () {
      const q = FeedQuery(terms: ['a', 'b', 'c', 'd', 'e', 'f'], country: 'GB');
      final c = MockClient((_) async => http.Response('{}', 200));
      expect(Refresher.capped(q, ReedFeed(c, key: 'k'), Refresher.refreshTerms).terms, ['a', 'b', 'c', 'd']);
      expect(Refresher.capped(q, RemotiveFeed(c), Refresher.refreshTerms).terms, ['a', 'b', 'c']);
      expect(Refresher.capped(q, JoobleFeed(c, keys: const {}), Refresher.refreshTerms).terms, ['a', 'b']);
      expect(Refresher.capped(q, ArbeitnowFeed(c), Refresher.refreshTerms).terms, q.terms);
    });
  });

  group('NHS Jobs', () {
    test('keeps a title anywhere in the family, but not with the strict check', () async {
      final feed = NhsJobsFeed(_nhsClient());
      final family = await feed.search(
        FeedQuery(terms: const [role], country: 'GB', keep: [for (final t in close) t.title]),
      );
      expect(family.map((p) => p.title), ['Clinical Systems Trainer']);
      final strict = await feed.search(const FeedQuery(terms: [role], country: 'GB'));
      expect(strict, isEmpty);
    });

    test('a short family title keeps whole words only, not the same letters inside other words', () {
      const keep = ['PA', 'Medical Secretary', "Doctor's Secretary"];
      for (final t in [
        'Medical PA',
        'PA to the Chief Executive',
        'Medical Secretary/PA',
        'Medical Secretaries (Band 4)',
      ]) {
        expect(holdsWords(t, keep), isTrue, reason: t);
      }
      for (final t in [
        'Consultant Histopathologist',
        'Healthcare Technician - Part Time',
        'Trust Grade Doctor Paediatrics',
        'Principal Clinical Scientist',
      ]) {
        expect(holdsWords(t, keep), isFalse, reason: t);
      }
      expect(holdsWords("Doctor's Secretary - Surgery", keep), isTrue);
      expect(holdsWords('IT Trainer', const ['IT Trainer']), isTrue);
      expect(holdsWords('Facilities Trainer', const ['IT Trainer']), isFalse);
    });

    test('a role search finds the clinical systems trainer for the trainer family only', () async {
      final search = RoleSearch(book, _nhsClient(), feeds: [NhsJobsFeed(_nhsClient())]);
      final found = await search.run(
        RoleQuery(role: role, titles: close),
        today: today,
      );
      final hit = found.hits.single;
      expect(hit.main.title, 'Clinical Systems Trainer');
      expect(hit.match, TitleMatch.family);
      expect(hit.matched!.title, 'Clinical Systems Trainer');
      expect(hit.why, contains('3573'));
      final exact = await search.run(
        RoleQuery(role: role, titles: close, exactOnly: true),
        today: today,
      );
      expect(exact.hits, isEmpty);
    });
  });

  test('NOT words, excluded employers and profile exclusions drop results before ranking', () async {
    await book.saveProfile(
      sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(exclusions: ['bank'])),
    );
    final feed = _FakeFeed(
      'reed',
      answer: [
        _post('IT Trainer', company: 'Example Recruitment Ltd'),
        _post('Senior IT Trainer', company: 'Example Council'),
        _post('Bank IT Trainer', company: 'Example Council'),
        _post('IT Trainer', company: 'Example Council'),
      ],
    );
    final r = await RoleSearch(book, quietClient(), feeds: [feed]).run(
      const RoleQuery(role: 'IT Trainer', notWords: ['senior'], notEmployers: ['Example Recruitment']),
      today: today,
    );
    expect(r.hits.map((h) => '${h.main.title} @ ${h.main.company}'), ['IT Trainer @ Example Council']);
    expect(r.leftOut, 3);
  });

  test('ranking: exact title, then family title, then the rest; fit within each', () async {
    const systems = FamilyTitle(
      title: 'Systems Trainer',
      reason: 'Same SOC 2020 group 3573 (IT trainers)',
      closeness: Closeness.related,
      source: FamilySource.soc,
    );
    final feed = _FakeFeed(
      'reed',
      answer: [
        _post('Warehouse Operative', company: 'Example Stores'),
        _post('Systems Trainer', company: 'Example Bank'),
        _post('IT Trainer', company: 'Example Council'),
        _post(
          'Senior IT Trainer',
          company: 'Example Health Trust',
          description: 'Patient safety, EPR systems and training for ward staff.',
        ),
      ],
    );
    final r = await RoleSearch(book, quietClient(), feeds: [feed]).run(
      const RoleQuery(role: 'IT Trainer', titles: [systems]),
      today: today,
    );
    expect(r.hits.map((h) => h.match), [
      TitleMatch.exact,
      TitleMatch.exact,
      TitleMatch.family,
      TitleMatch.other,
    ]);
    expect(r.hits[0].fit, greaterThanOrEqualTo(r.hits[1].fit));
    expect(r.hits[2].main.title, 'Systems Trainer');
    expect(r.hits[2].matched, systems);
    expect(r.hits[2].why, systems.reason);
    expect(r.hits[3].main.title, 'Warehouse Operative');
    expect(r.hits[3].matched, isNull);
  });

  group('duplicates', () {
    test('the same job on two boards is one result with both links', () async {
      final reed = _FakeFeed(
        'reed',
        answer: [
          _post(
            'Clinical Systems Co-ordinator',
            company: 'Example Health Trust Ltd',
            location: 'Exampletown, West Yorkshire',
            url: 'https://reed.example/1',
            closing: '2026-12-01',
          ),
          // The same advert again (asked for another title).
          _post(
            'Clinical Systems Co-ordinator',
            company: 'Example Health Trust Ltd',
            location: 'Exampletown, West Yorkshire',
            url: 'https://reed.example/1',
            closing: '2026-12-01',
          ),
        ],
      );
      final nhs = _FakeFeed(
        'nhs',
        answer: [
          _post(
            'Clinical Systems Coordinator',
            source: 'nhs',
            location: 'Exampletown',
            url: 'https://nhs.example/1',
            closing: '2026-12-01',
            description: 'The longer advert, with the full person specification.',
          ),
          // Same title and employer, another closing date: another job.
          _post(
            'Clinical Systems Coordinator',
            source: 'nhs',
            id: 'later',
            location: 'Exampletown',
            url: 'https://nhs.example/2',
            closing: '2027-02-01',
          ),
        ],
      );
      final r = await RoleSearch(
        book,
        quietClient(),
        feeds: [reed, nhs],
      ).run(const RoleQuery(role: 'Clinical Systems Coordinator'), today: today);
      expect(r.hits, hasLength(2));
      final merged = r.hits.firstWhere((h) => h.postings.length > 1);
      expect(merged.links.map((l) => l.source).toSet(), {'reed', 'nhs'});
      expect(merged.main.source, 'nhs', reason: 'the fullest advert leads');
      expect(merged.toSave().description, contains('https://reed.example/1'));
    });

    test('jobKey ignores case, punctuation, short forms, legal endings and the county', () {
      expect(
        jobKey(
          title: 'Sr. E-Learning Co-ordinator',
          company: 'Example Trust Ltd',
          location: 'Leeds, West Yorkshire',
        ),
        jobKey(title: 'Senior Elearning Coordinator', company: 'example trust', location: 'Leeds LS1 4AP'),
      );
      expect(jobKey(title: 'Trainer', company: ''), isEmpty);
      expect(
        jobKey(title: 'Trainer', company: 'Example', location: 'Leeds'),
        isNot(jobKey(title: 'Trainer', company: 'Example', location: 'York')),
      );
    });

    test('importPostings skips the same job from another board', () async {
      final first = _post(
        'Clinical Systems Co-ordinator',
        company: 'Example Health Trust Ltd',
        url: 'https://reed.example/1',
        closing: '2026-12-01',
      );
      final twin = _post(
        'Clinical Systems Coordinator',
        source: 'nhs',
        company: 'Example Health Trust',
        location: 'Exampletown, EX1 1AA',
        url: 'https://nhs.example/1',
        closing: '2026-12-01',
      );
      final elsewhere = _post(
        'Clinical Systems Coordinator',
        source: 'nhs',
        company: 'Example Health Trust',
        location: 'Othertown',
        url: 'https://nhs.example/2',
      );
      expect(await book.importPostings([first], sampleProfile, today: today), hasLength(1));
      expect(await book.importPostings([twin], sampleProfile, today: today), isEmpty);
      expect(await book.importPostings([elsewhere], sampleProfile, today: today), hasLength(1));
      // Two boards in one batch: one job.
      final fresh = CareerBook(await Store.open(memoryDatabase()));
      addTearDown(fresh.db.close);
      expect(await fresh.importPostings([first, twin], sampleProfile, today: today), hasLength(1));
    });
  });

  testWidgets('search mode shows the family as chips and lists the results on a phone', (tester) async {
    final h = AppHarness(tester);
    await h.open(seed: (b) => b.saveProfile(sampleProfile));
    h.phone();
    await h.run(client: _nhsClient());
    await h.go('Jobs');
    await h.tap(find.text('Search job sites'));
    await tester.enterText(find.byKey(const ValueKey('roleSearch.role')), role);
    await h.tap(find.byTooltip('Find the titles it goes by'));
    final chip = find.widgetWithText(FilterChip, 'Clinical Systems Trainer');
    expect(chip, findsOneWidget);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(find.text('Exact title only'), findsOneWidget);
    await h.tap(find.byKey(const ValueKey('roleSearch.run')));
    await h.settle();
    expect(find.text('Matched: Clinical Systems Trainer'), findsOneWidget);
    expect(find.text('NHS Jobs'), findsWidgets);
    expect(find.text('Save all'), findsOneWidget);
    await h.tap(find.text('Save').first);
    expect(
      (await tester.runAsync(() => h.book.db.select(h.book.db.jobListings).get()))!.single.title,
      'Clinical Systems Trainer',
    );
    await h.close();
  });
}
