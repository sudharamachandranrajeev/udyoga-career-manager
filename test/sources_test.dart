import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/matching.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/refresh.dart';

import 'support.dart';

const today = '2026-11-19';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();
Json fixtureJson(String name) => obj(jsonDecode(fixture(name)));

http.Response json(Object body, {int status = 200}) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('JobTech (Sweden)', () {
    test('reads a /search reply', () {
      final jobs = JobTechFeed.parse(fixtureJson('jobtech.json'));
      expect(jobs, hasLength(2));
      final j = jobs.first;
      expect(j.source, 'jobtech');
      expect(j.title, 'Sjuksköterska till Exempelby vårdcentral');
      expect(j.country, 'SE');
      expect(j.company, isNotEmpty);
      expect(j.url, startsWith('https://arbetsformedlingen.se/platsbanken/annonser/'));
      expect(j.posted, '2026-11-19');
      expect(j.closing, '2026-12-03');
    });

    test('covers Sweden only, and sends each term', () async {
      final asked = <Uri>[];
      final feed = JobTechFeed(
        MockClient((r) async {
          asked.add(r.url);
          return http.Response.bytes(utf8.encode(fixture('jobtech.json')), 200);
        }),
      );
      expect(feed.covers(const FeedQuery(terms: ['x'], country: 'NO')), isFalse);
      final jobs = await feed.search(const FeedQuery(terms: ['sjuksköterska', 'informatik'], country: 'SE'));
      expect(asked.map((u) => u.queryParameters['q']), ['sjuksköterska', 'informatik']);
      expect(jobs, hasLength(4));
    });
  });

  group('NAV (Norway)', () {
    test('finds the token on the public token page', () {
      expect(
        NavFeed.tokenIn('Current public token:\naaaaaaaaaaaa.bbbbbbbbbbbb.cccccccccccc\n'),
        'aaaaaaaaaaaa.bbbbbbbbbbbb.cccccccccccc',
      );
      expect(NavFeed.tokenIn('nothing here'), '');
    });

    test('keeps only open ads whose title matches', () {
      final hits = NavFeed.matching(fixtureJson('nav_feed.json'), ['sykepleiere']);
      expect(hits, hasLength(1));
      expect(NavFeed.matching(fixtureJson('nav_feed.json'), ['...']), isEmpty, reason: 'masked, inactive ad');
    });

    test('reads one ad in full, without its contacts', () {
      final j = NavFeed.parseEntry(fixtureJson('nav_entry.json'));
      expect(j.title, 'Sykepleiere til Eksempelby sykehjem');
      expect(j.country, 'NO');
      expect(j.location, 'Eksempelby');
      expect(j.closing, '2026-12-06');
      expect(j.url, startsWith('https://arbeidsplassen.nav.no/stillinger/stilling/'));
      expect(j.description, isNot(contains('@')));
    });

    test('asks with the public token, from two days back, and reads matches in full', () async {
      final seen = <http.Request>[];
      final feed = NavFeed(
        MockClient((r) async {
          seen.add(r);
          if (r.url.path == '/api/publicToken') {
            return http.Response('Current public token:\naaaaaaaaaaaa.bbbbbbbbbbbb.cccccccccccc\n', 200);
          }
          if (r.url.path.startsWith('/api/v1/feedentry/')) {
            return http.Response.bytes(utf8.encode(fixture('nav_entry.json')), 200);
          }
          final page = fixtureJson('nav_feed.json');
          // The last page: no next one.
          return json({...page, 'next_url': null});
        }),
        clock: () => DateTime.utc(2026, 11, 19, 12),
      );
      final jobs = await feed.search(const FeedQuery(terms: ['sykepleiere'], country: 'NO'));
      expect(jobs.single.title, 'Sykepleiere til Eksempelby sykehjem');
      final first = seen.firstWhere((r) => r.url.path == '/api/v1/feed');
      expect(first.headers['authorization'], 'Bearer aaaaaaaaaaaa.bbbbbbbbbbbb.cccccccccccc');
      expect(first.headers['if-modified-since'], 'Tue, 17 Nov 2026 12:00:00 GMT');
    });
  });

  group('USAJOBS', () {
    test('reads a search reply', () {
      final j = UsaJobsFeed.parse(fixtureJson('usajobs.json')).single;
      expect(j.title, 'IT SPECIALIST (EXAMPLE SYSTEMS)');
      expect(j.salaryMin, 92108);
      expect(j.currency, 'USD');
      expect(j.country, 'US');
      expect(j.closing, '2016-12-01');
    });

    test('needs a key and the e-mail, and sends them as its rules ask', () async {
      late http.Request sent;
      final feed = UsaJobsFeed(
        MockClient((r) async {
          sent = r;
          return http.Response.bytes(utf8.encode(fixture('usajobs.json')), 200);
        }),
        key: 'k',
        email: 'alex@example.com',
      );
      expect(
        UsaJobsFeed(quietClient(), key: 'k', email: '').covers(const FeedQuery(terms: [], country: 'US')),
        isFalse,
      );
      expect(feed.covers(const FeedQuery(terms: [], country: 'GB')), isFalse);
      await feed.search(
        const FeedQuery(terms: ['nurse'], country: 'US', place: 'Exampleville', radiusMiles: 25),
      );
      expect(sent.headers['authorization-key'], 'k');
      expect(sent.headers['user-agent'], 'alex@example.com');
      expect(sent.url.queryParameters['Radius'], '25');
      expect(sent.url.queryParameters['LocationName'], 'Exampleville');
    });
  });

  group('Jooble', () {
    test('reads a reply', () {
      final j = JoobleFeed.parse(fixtureJson('jooble.json'), country: 'UA').single;
      expect(j.title, 'Sales Manager');
      expect(j.company, 'Example Trading Ltd');
      expect(j.salaryText, '17,600 UAH');
      expect(j.posted, '2023-09-15');
    });

    test('uses the key for the country, on that country site, with an allowed radius', () async {
      late http.Request sent;
      final feed = JoobleFeed(
        MockClient((r) async {
          sent = r;
          return http.Response.bytes(utf8.encode(fixture('jooble.json')), 200);
        }),
        keys: {'GB': 'gbkey'},
      );
      expect(feed.covers(const FeedQuery(terms: [], country: 'US')), isFalse);
      await feed.search(
        const FeedQuery(terms: ['nurse'], country: 'GB', place: 'Exampletown', radiusMiles: 20),
      );
      expect(sent.url.toString(), 'https://uk.jooble.org/api/gbkey');
      expect(obj(jsonDecode(sent.body))['radius'], '40');
      expect(obj(jsonDecode(sent.body))['location'], 'Exampletown');
    });

    test('a used-up day is said plainly', () async {
      final feed = JoobleFeed(MockClient((_) async => http.Response('', 429)), keys: {'GB': 'k'});
      await expectLater(
        feed.search(const FeedQuery(terms: ['x'], country: 'GB')),
        throwsA(isA<FeedException>().having((e) => e.message, 'message', contains('calls'))),
      );
    });

    test('keys are written one per country', () {
      expect(joobleKeysIn('GB: abc\nUnited States = def\nnonsense\n'), {'GB': 'abc', 'US': 'def'});
    });
  });

  group('unvacancies.org (UN jobs)', () {
    test('reads its RSS feed', () {
      final jobs = UnVacanciesFeed.parse(fixture('unvacancies.xml'));
      expect(jobs, hasLength(3));
      expect(jobs.first.title, 'Example Programme Officer');
      expect(jobs.first.company, 'EXAMPLE-AGENCY');
      expect(jobs.first.posted, '2026-11-19');
      expect(jobs.first.sourceId, 'example-programme-officer-X-000001');
    });

    test('answers the country-less query, filtered by the terms', () async {
      final feed = UnVacanciesFeed(
        MockClient((_) async => http.Response.bytes(utf8.encode(fixture('unvacancies.xml')), 200)),
      );
      expect(feed.covers(const FeedQuery(terms: [], country: 'GB')), isFalse);
      final jobs = await feed.search(const FeedQuery(terms: ['cataloguer'], country: ''));
      expect(jobs.single.title, 'Cataloguer');
    });

    test('a page that is not a feed is a feed problem', () {
      expect(() => UnVacanciesFeed.parse('<html'), throwsA(isA<FeedException>()));
    });
  });

  test('every source whose terms ask for credit has one', () {
    for (final s in ['adzuna', 'jooble', 'usajobs', 'jobtech', 'nav', 'unvacancies']) {
      expect(feedCredits[s], isNotNull, reason: s);
    }
    expect(feedCredits['usajobs']!.label, contains('not endorsed'));
  });

  group('device-only keys', () {
    test('USAJOBS and Jooble keys live in the keychain, not the synced pref', () async {
      final store = MemorySecretStore();
      await FeedKeys.saveSecrets(
        store,
        usajobsKey: 'k',
        usajobsEmail: 'alex@example.com',
        jooble: {'GB': 'j'},
      );
      final keys = await const FeedKeys(reed: 'r').withSecrets(store);
      expect(keys.usajobsKey, 'k');
      expect(keys.jooble, {'GB': 'j'});
      expect(keys.toJson().keys, isNot(contains('usajobsKey')));
      await FeedKeys.saveSecrets(store, usajobsKey: '', usajobsEmail: '', jooble: {});
      expect(store.values, isEmpty);
    });
  });

  group('local radar', () {
    const areas = [
      HomeArea(place: 'Exampletown', radiusMiles: 10, commuteTowns: ['Sampleby']),
      HomeArea(place: 'Testford', radiusMiles: 25),
    ];
    final p = sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(areas: areas));

    test('each home area is its own query, with its radius', () {
      final qs = Refresher.queries(p);
      final gb = qs.where((q) => q.country == 'GB').toList();
      expect(gb.map((q) => (q.place, q.radiusMiles)), [('Exampletown', 10), ('Testford', 25)]);
      expect(qs.where((q) => q.country == 'IE').single.place, '');
      expect(qs.last.country, '', reason: 'the query for remote work and UN jobs');
    });

    test('a feed that takes a town is asked per area; one that does not, once', () async {
      final asked = <String>[];
      final client = MockClient((r) async {
        asked.add('${r.url.host}${r.url.path}?${r.url.queryParameters['location'] ?? ''}');
        return http.Response('{}', 200);
      });
      final book = CareerBook(await Store.open(memoryDatabase()));
      await book.saveProfile(
        p.copyWith(
          targets: p.targets.copyWith(countries: ['GB', 'SE'], keywords: ['nurse']),
        ),
      );
      await Refresher(book, client).run(today: today, force: true);
      final nhs = asked.where((a) => a.startsWith('www.jobs.nhs.uk')).toSet();
      expect(nhs, {
        'www.jobs.nhs.uk/api/v1/search_xml?Exampletown',
        'www.jobs.nhs.uk/api/v1/search_xml?Testford',
      });
      expect(asked.where((a) => a.startsWith('jobsearch.api.jobtechdev.se')), hasLength(1));
      expect(asked.where((a) => a.startsWith('unvacancies.org')), hasLength(1));
    });

    test('a job in a commute town counts as local', () {
      final near = scoreFit(
        p,
        const JobFacts(title: 'Nurse', description: '', location: 'Sampleby', country: 'GB'),
        today: today,
      ).factors.firstWhere((f) => f.name == 'Location');
      expect(near.score, 1);
      final far = scoreFit(
        p,
        const JobFacts(title: 'Nurse', description: '', location: 'Faraway', country: 'GB'),
        today: today,
      ).factors.firstWhere((f) => f.name == 'Location');
      expect(far.score, lessThan(1));
    });

    test('areas are written and read as lines', () {
      final a = HomeArea.parse('Exampletown | 20 | Sampleby, Testford')!;
      expect(a.radiusMiles, 20);
      expect(a.commuteTowns, ['Sampleby', 'Testford']);
      expect(HomeArea.parse(a.line)!.line, a.line);
      expect(HomeArea.parse('Exampletown')!.line, 'Exampletown');
      expect(HomeArea.parse('  '), isNull);
    });

    test('the default radius fills areas that do not set one', () {
      const t = Targets(locations: ['Exampletown'], radiusMiles: 15);
      expect(t.homeAreas.single.radiusMiles, 15);
      expect(Targets.fromJson(t.toJson()).homeAreas.single.radiusMiles, 15);
    });
  });

  group('refresh rules for the new sources', () {
    test('a failing new source is a problem and nothing is counted as checked when all fail', () async {
      final book = CareerBook(await Store.open(memoryDatabase()));
      await book.saveProfile(
        sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(countries: ['SE', 'NO'])),
      );
      final down = MockClient((_) async => throw const SocketException('offline'));
      final r = await Refresher(book, down).run(today: today);
      expect(r.feedsChecked, isFalse);
      expect(await book.db.localSetting(LocalKeys.feedsChecked), isNull);
      expect(r.problems.where((p) => p.startsWith('Platsbanken')), isNotEmpty);
      expect(r.problems.where((p) => p.startsWith('NAV')), isNotEmpty);
      expect(r.problems.where((p) => p.startsWith('UN jobs')), isNotEmpty);
    });

    test('a second run with the same jobs writes no rows', () async {
      final book = CareerBook(await Store.open(memoryDatabase()));
      await book.saveProfile(
        sampleProfile.copyWith(
          targets: sampleProfile.targets.copyWith(countries: ['SE'], keywords: ['nurse']),
        ),
      );
      final client = MockClient((r) async {
        if (r.url.host == 'jobsearch.api.jobtechdev.se') {
          return http.Response.bytes(utf8.encode(fixture('jobtech.json')), 200);
        }
        return http.Response('{}', 200);
      });
      final first = await Refresher(book, client).run(today: today, force: true);
      expect(first.added, 2);
      final outbox = await book.db.customSelect('SELECT COUNT(*) AS n FROM outbox').getSingle();
      final second = await Refresher(book, client).run(today: today, force: true);
      expect(second.added, 0);
      final after = await book.db.customSelect('SELECT COUNT(*) AS n FROM outbox').getSingle();
      expect(after.read<int>('n'), outbox.read<int>('n'));
    });
  });
}
