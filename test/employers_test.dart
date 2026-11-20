import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/ats.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_file.dart';
import 'package:udyoga/domain/discovery.dart';
import 'package:udyoga/domain/employers.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/refresh.dart';

import 'support.dart';

const today = '2026-11-19';

Json fixtureJson(String name) => obj(jsonDecode(File('test/fixtures/$name').readAsStringSync()));
Object? fixtureAny(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync());

http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200);

/// A careers page with its jobs in schema.org markup.
const careersPage = '''
<html><head>
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[
 {"@type":"Organization","name":"Example Health Trust"},
 {"@type":"JobPosting","title":"Clinical Informatics Nurse","identifier":{"value":"EHT-1"},
  "datePosted":"2026-11-18","validThrough":"2026-12-10T23:59:00Z","url":"/jobs/eht-1",
  "description":"<p>Lead the EPR roll-out.</p>",
  "hiringOrganization":{"name":"Example Health Trust"},
  "jobLocation":{"address":{"addressLocality":"Exampletown","addressCountry":"GB"}},
  "baseSalary":{"currency":"GBP","value":{"minValue":38000,"maxValue":45000,"unitText":"YEAR"}}},
 {"@type":"JobPosting","title":"Porter","identifier":"EHT-2","description":"Moving patients."}
]}
</script></head><body></body></html>
''';

const nhsXml = '''
<nhsJobs>
<vacancyDetails><id>201</id><title>Clinical Informatics Nurse</title><employer>Example Health Trust</employer>
<description>EPR work</description><salary>£38,000 to £45,000 a year</salary></vacancyDetails>
<vacancyDetails><id>202</id><title>Clinical Informatics Nurse</title><employer>Sample Care Trust</employer>
<description>EPR work</description></vacancyDetails>
</nhsJobs>
''';

void main() {
  group('job boards from a careers link', () {
    test('each board kind is found from its links', () {
      expect(
        atsFromUrl('https://boards.greenhouse.io/examplehealth'),
        AtsBoard(AtsKind.greenhouse, 'examplehealth'),
      );
      expect(
        atsFromUrl('https://job-boards.eu.greenhouse.io/examplehealth/jobs/123'),
        AtsBoard(AtsKind.greenhouse, 'examplehealth'),
      );
      expect(
        atsFromUrl('https://boards.greenhouse.io/embed/job_board?for=examplehealth'),
        AtsBoard(AtsKind.greenhouse, 'examplehealth'),
      );
      expect(atsFromUrl('https://jobs.lever.co/example'), AtsBoard(AtsKind.lever, 'example'));
      expect(
        atsFromUrl('https://jobs.eu.lever.co/example/abc'),
        AtsBoard(AtsKind.lever, 'example', host: 'api.eu.lever.co'),
      );
      expect(atsFromUrl('https://jobs.ashbyhq.com/Example%20Co'), AtsBoard(AtsKind.ashby, 'Example Co'));
      expect(
        atsFromUrl('https://careers.smartrecruiters.com/ExampleCo'),
        AtsBoard(AtsKind.smartrecruiters, 'ExampleCo'),
      );
      expect(
        atsFromUrl('https://example.wd3.myworkdayjobs.com/en-GB/Careers'),
        AtsBoard(AtsKind.workday, 'example', host: 'example.wd3.myworkdayjobs.com', site: 'Careers'),
      );
      expect(atsFromUrl('https://www.example.org/careers'), isNull);
      expect(atsFromUrl('https://boards.greenhouse.io/embed'), isNull);
    });

    test('a careers page that embeds a board is read as that board', () {
      expect(
        atsInHtml('<a href="https://jobs.lever.co/example?team=x&amp;y=1">Jobs</a>'),
        AtsBoard(AtsKind.lever, 'example'),
      );
      expect(atsInHtml('<p>No board here</p>'), isNull);
    });

    test('a board is kept as JSON', () {
      const b = AtsBoard(AtsKind.workday, 'example', host: 'example.wd3.myworkdayjobs.com', site: 'Careers');
      expect(AtsBoard.fromJson(b.toJson()), b);
    });
  });

  group('board replies', () {
    test('Greenhouse', () {
      final jobs = AtsClient.parseGreenhouse(fixtureJson('ats_greenhouse.json'), employer: 'Example Co');
      expect(jobs.map((j) => (j.source, j.sourceId, j.company)), [
        ('greenhouse', '1000000001', 'Example Co'),
        ('greenhouse', '1000000002', 'Example Co'),
      ]);
      expect(jobs.first.title, 'Data Analyst, Example Insights');
      expect(jobs.first.url, startsWith('https://'));
    });

    test('Lever', () {
      final jobs = AtsClient.parseLever(fixtureAny('ats_lever.json'), employer: 'Example Co');
      expect(jobs.map((j) => j.title), ['Customer Success Lead', 'Dentist']);
      expect(jobs.first.sourceId, '0a0a0a0a-3333-4ccc-9ddd-000000000003');
    });

    test('Ashby', () {
      final jobs = AtsClient.parseAshby(fixtureJson('ats_ashby.json'), employer: 'Example Co');
      expect(jobs.first.title, 'Engineering Manager - Example Region');
      expect(jobs, hasLength(2));
    });

    test('SmartRecruiters', () {
      final j = AtsClient.parseSmartRecruiters(
        fixtureJson('ats_smartrecruiters.json'),
        employer: 'Example Co',
      ).single;
      expect(j.title, 'Senior / Lead Example Operations Manager');
      expect(j.sourceId, '100000000000005');
    });

    test('Workday', () {
      const board = AtsBoard(
        AtsKind.workday,
        'example',
        host: 'example.wd3.myworkdayjobs.com',
        site: 'Careers',
      );
      final jobs = AtsClient.parseWorkday(
        fixtureJson('ats_workday.json'),
        board: board,
        employer: 'Example Co',
      );
      expect(jobs.map((j) => j.sourceId), ['JR-0000101', 'JR-0000102']);
      expect(
        jobs.first.url,
        'https://example.wd3.myworkdayjobs.com/Careers/job/Exampleland-EX-Sampleford/Example-Engineer_JR-0000101',
      );
    });

    test('a careers page’s job markup', () {
      final jobs = jobPostingsIn(
        careersPage,
        pageUrl: 'https://www.example.org/careers',
        employer: 'Example Health Trust',
      );
      expect(jobs, hasLength(2));
      final j = jobs.first;
      expect((j.source, j.sourceId, j.title), ('careers', 'EHT-1', 'Clinical Informatics Nurse'));
      expect(j.url, 'https://www.example.org/jobs/eht-1');
      expect((j.location, j.country), ('Exampletown', 'GB'));
      expect((j.salaryMin, j.salaryMax, j.currency), (38000, 45000, 'GBP'));
      expect((j.posted, j.closing), ('2026-11-18', '2026-12-10'));
      expect(j.description, 'Lead the EPR roll-out.');
      expect(
        jobPostingsIn('<script type="application/ld+json">{broken</script>', pageUrl: 'https://x.org'),
        isEmpty,
      );
    });
  });

  group('robots.txt', () {
    const robots = '''
User-agent: *
Disallow: /private
Allow: /private/jobs

User-agent: Udyoga
Disallow: /careers/search
''';
    test('the group naming Udyoga wins, then the longest rule', () {
      expect(robotsAllows(robots, '/careers'), isTrue);
      expect(robotsAllows(robots, '/careers/search?q=x'), isFalse);
      expect(robotsAllows(robots, '/private', agent: 'other'), isFalse);
      expect(robotsAllows(robots, '/private/jobs', agent: 'other'), isTrue);
      expect(robotsAllows('', '/anything'), isTrue);
      expect(robotsAllows('User-agent: *\nDisallow: /', '/careers'), isFalse);
    });
  });

  group('watched employers', () {
    late CareerBook book;
    setUp(() async {
      book = CareerBook(await Store.open(memoryDatabase()));
      await book.saveProfile(sampleProfile);
    });

    test('match by name or alias, as whole words', () {
      const e = WatchedEmployer(id: 'eht', name: 'Example Health Trust', aliases: ['EHT Hospitals']);
      expect(e.matches('Example Health Trust'), isTrue);
      expect(e.matches('EHT Hospitals & Clinics'), isTrue);
      expect(e.matches('example-health trust'), isTrue);
      expect(e.matches('Sample Example Health Trustees'), isFalse);
      expect(e.matches(''), isFalse);
      expect(const WatchedEmployer(id: 'x', name: 'X', sources: ['NHS Jobs']).nhs, isTrue);
      expect(
        const WatchedEmployer(
          id: 'x',
          name: 'X',
          sources: ['nhs', 'https://www.example.org/careers', 'notes'],
        ).urls,
        ['https://www.example.org/careers'],
      );
    });

    test('are saved, listed by name and removed', () async {
      await book.saveWatchedEmployer(const WatchedEmployer(id: 'b', name: 'Sample Care Trust'));
      await book.saveWatchedEmployer(const WatchedEmployer(id: 'a', name: 'Example Health Trust'));
      expect((await book.watchedEmployers()).map((e) => e.id), ['a', 'b']);
      await book.removeWatchedEmployer('a');
      expect((await book.watchedEmployers()).map((e) => e.id), ['b']);
    });

    test('the file import is idempotent by id; edits and removals stand until the file changes', () async {
      const seed = WatchedEmployer(id: 'eht', name: 'Example Health Trust', keywords: ['nurse']);
      expect(await book.importWatchedEmployers([seed]), 1);
      expect(await book.importWatchedEmployers([seed]), 0);

      final mine = (await book.watchedEmployers()).single;
      await book.saveWatchedEmployer(
        WatchedEmployer(id: mine.id, name: mine.name, keywords: const ['informatics'], seed: mine.seed),
      );
      expect(await book.importWatchedEmployers([seed]), 0);
      expect((await book.watchedEmployers()).single.keywords, ['informatics']);

      const changed = WatchedEmployer(id: 'eht', name: 'Example Health Trust', keywords: ['nurse', 'EPR']);
      expect(await book.importWatchedEmployers([changed]), 1);
      expect((await book.watchedEmployers()).single.keywords, ['nurse', 'EPR']);

      await book.removeWatchedEmployer('eht');
      expect(await book.importWatchedEmployers([changed]), 0);
      expect(await book.watchedEmployers(), isEmpty);
    });

    test('new jobs from them are picked out for Today', () async {
      await book.importPostings(
        [samplePosting(id: '1'), samplePosting(id: '2', company: 'Sample Care Trust')],
        sampleProfile,
        today: today,
      );
      final jobs = await book.db.select(book.db.jobListings).get();
      const watched = [WatchedEmployer(id: 'eht', name: 'Example Health Trust')];
      expect(watchedNewJobs(jobs, watched).map((w) => w.job.sourceId), ['1']);
      final seen = jobs.firstWhere((j) => j.sourceId == '1');
      await book.setJobStatus(seen.id, 'saved');
      expect(watchedNewJobs(await book.db.select(book.db.jobListings).get(), watched), isEmpty);
    });

    test('the career file seeds them', () async {
      final folder = await Directory.systemTemp.createTemp('udyoga-watch');
      addTearDown(() => folder.delete(recursive: true));
      final f = File('${folder.path}/settings/udyoga.json');
      await f.parent.create(recursive: true);
      await f.writeAsString(
        jsonEncode({
          'targets': {
            'places': [
              {
                'name': 'Exampletown',
                'radiusMiles': 10,
                'commute': ['Sampleby'],
              },
              'Testford',
            ],
            'radiusMiles': 25,
          },
          'watchEmployers': [
            {
              'id': 'eht',
              'name': 'Example Health Trust',
              'aliases': 'EHT',
              'sources': ['nhs'],
              'keywords': ['nurse'],
              'why': 'Close to home',
            },
          ],
        }),
      );
      final r = await CareerFile(book).applyFrom([folder.path], today: today);
      expect(r!.employers, 1);
      final e = (await book.watchedEmployers()).single;
      expect((e.name, e.nhs, e.why), ('Example Health Trust', true, 'Close to home'));
      expect(e.aliases, ['EHT']);
      final t = (await book.profile()).targets;
      expect(t.locations, ['Exampletown', 'Testford']);
      expect(t.radiusMiles, 25);
      expect(t.homeAreas.map((a) => a.line), ['Exampletown | 10 | Sampleby', 'Testford | 25']);
    });
  });

  group('the watch run', () {
    late CareerBook book;
    var now = DateTime.utc(2026, 11, 19, 8);
    setUp(() async {
      book = CareerBook(await Store.open(memoryDatabase()));
      now = DateTime.utc(2026, 11, 19, 8);
    });

    test('NHS employers come from NHS Jobs by name, with their keywords', () async {
      final asked = <Uri>[];
      final watch = EmployerWatch(
        book,
        MockClient((r) async {
          asked.add(r.url);
          return ok(nhsXml);
        }),
      );
      final r = await watch.run(sampleProfile, const [
        WatchedEmployer(id: 'eht', name: 'Example Health Trust', sources: ['nhs'], keywords: ['informatics']),
      ]);
      expect(r.postings.map((j) => j.sourceId), ['201']);
      expect((r.asked, r.failed), (1, 0));
      expect(asked.single.host, 'www.jobs.nhs.uk');
      expect(asked.single.queryParameters['keyword'], contains('informatics'));
    });

    test('a board link is asked through its public API', () async {
      final asked = <Uri>[];
      final watch = EmployerWatch(
        book,
        MockClient((r) async {
          asked.add(r.url);
          return ok(File('test/fixtures/ats_greenhouse.json').readAsStringSync());
        }),
      );
      final r = await watch.run(sampleProfile, const [
        WatchedEmployer(
          id: 'co',
          name: 'Example Co',
          sources: ['https://boards.greenhouse.io/exampleco'],
          keywords: ['backend'],
        ),
      ]);
      expect(asked.single.toString(), 'https://boards-api.greenhouse.io/v1/boards/exampleco/jobs');
      expect(r.postings.single.title, 'Backend Engineer, Example Platform');
    });

    test('a careers page is read politely: robots.txt first, once a day, its board remembered', () async {
      final asked = <String>[];
      var page = careersPage;
      final watch = EmployerWatch(
        book,
        MockClient((r) async {
          asked.add(r.url.toString());
          expect(r.headers['user-agent'], politeAgent);
          if (r.url.path == '/robots.txt') return http.Response('User-agent: *\nDisallow: /private', 200);
          if (r.url.host == 'api.lever.co') {
            return ok(File('test/fixtures/ats_lever.json').readAsStringSync());
          }
          return ok(page);
        }),
        clock: () => now,
      );
      const eht = WatchedEmployer(
        id: 'eht',
        name: 'Example Health Trust',
        sources: ['https://www.example.org/careers'],
        keywords: ['nurse'],
      );
      var r = await watch.run(sampleProfile, const [eht]);
      expect(asked, ['https://www.example.org/robots.txt', 'https://www.example.org/careers']);
      expect(r.postings.single.sourceId, 'EHT-1');

      // The same day: nothing is asked.
      asked.clear();
      now = now.add(const Duration(hours: 5));
      r = await watch.run(sampleProfile, const [eht]);
      expect(asked, isEmpty);
      expect(r.asked, 0);

      // Next day the page now embeds a board: it is used, and remembered.
      now = now.add(const Duration(days: 1));
      page = '<iframe src="https://jobs.lever.co/examplehealth"></iframe>';
      r = await watch.run(sampleProfile, const [
        WatchedEmployer(
          id: 'eht',
          name: 'Example Health Trust',
          sources: ['https://www.example.org/careers'],
          keywords: ['dentist'],
        ),
      ]);
      expect(asked, [
        'https://www.example.org/careers',
        'https://api.lever.co/v0/postings/examplehealth?mode=json',
      ]);
      expect(r.postings.single.title, 'Dentist');
      asked.clear();
      await watch.run(sampleProfile, const [eht]);
      expect(asked.single, startsWith('https://api.lever.co/'), reason: 'the board is asked directly now');
    });

    test('a page robots.txt closes is not read, and says why', () async {
      final asked = <String>[];
      final watch = EmployerWatch(
        book,
        MockClient((r) async {
          asked.add(r.url.path);
          return http.Response('User-agent: *\nDisallow: /careers', 200);
        }),
      );
      final r = await watch.run(sampleProfile, const [
        WatchedEmployer(
          id: 'eht',
          name: 'Example Health Trust',
          sources: ['https://www.example.org/careers'],
        ),
      ]);
      expect(asked, ['/robots.txt']);
      expect((r.asked, r.failed), (1, 1));
      expect(r.problems.single, contains('robots.txt'));
    });

    test('in a refresh, a failed watch is not counted as checked', () async {
      await book.saveProfile(
        sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(countries: ['GB'])),
      );
      await book.saveWatchedEmployer(
        const WatchedEmployer(
          id: 'co',
          name: 'Example Co',
          sources: ['https://boards.greenhouse.io/exampleco'],
        ),
      );
      final down = MockClient((_) async => throw const SocketException('offline'));
      final r = await Refresher(book, down, watch: EmployerWatch(book, down)).run(today: today);
      expect(r.feedsChecked, isFalse);
      expect(r.problems.where((p) => p.startsWith('Example Co')), isNotEmpty);
    });

    test('in a refresh, the watched jobs are saved with the rest', () async {
      await book.saveProfile(
        sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(countries: ['GB'])),
      );
      await book.saveWatchedEmployer(
        const WatchedEmployer(
          id: 'co',
          name: 'Example Co',
          sources: ['https://boards.greenhouse.io/exampleco'],
          keywords: ['backend'],
        ),
      );
      final client = MockClient(
        (r) async => r.url.host == 'boards-api.greenhouse.io'
            ? ok(File('test/fixtures/ats_greenhouse.json').readAsStringSync())
            : http.Response('{}', 200),
      );
      final r = await Refresher(
        book,
        client,
        watch: EmployerWatch(book, client),
      ).run(today: today, force: true);
      expect(r.feedsChecked, isTrue);
      final jobs = await book.db.select(book.db.jobListings).get();
      expect(jobs.where((j) => j.source == 'greenhouse').map((j) => j.title), [
        'Backend Engineer, Example Platform',
      ]);
    });
  });

  group('finding employers to watch', () {
    test('NHS trusts from the ODS list, filtered by town', () {
      final body = {
        'Organisations': [
          {'Name': 'EXAMPLETOWN TEACHING HOSPITALS NHS TRUST', 'PostCode': 'EX1 1AA'},
          {'Name': 'SAMPLE COUNTY NHS FOUNDATION TRUST', 'PostCode': 'SA1 1AA'},
        ],
      };
      final all = EmployerDiscovery.parseOds(body);
      expect(all.first.name, 'Exampletown Teaching Hospitals NHS Trust');
      expect(all.first.nhs, isTrue);
      expect(EmployerDiscovery.parseOds(body, towns: ['Sample County']).single.place, 'SA1 1AA');
      final w = all.first.toWatched();
      expect((w.id, w.nhs), ('exampletown-teaching-hospitals-nhs-trust', true));
    });

    test('hospitals near a place from Wikidata', () {
      final q = EmployerDiscovery.hospitalQuery('Exampletown "North"', 'gb', 10);
      expect(q, contains(r'"Exampletown \"North\""@en'));
      expect(q, contains('wikibase:radius "16"'));
      expect(q, contains('wdt:P297 "GB"'));
      final hits = EmployerDiscovery.parseWikidata({
        'results': {
          'bindings': [
            {
              'hLabel': {'value': 'Example General Hospital'},
              'site': {'value': 'https://www.example.org'},
            },
            {
              'hLabel': {'value': 'Q12345'},
            },
          ],
        },
      }, place: 'Exampletown');
      expect(hits.single.website, 'https://www.example.org');
      expect(hits.single.toWatched().urls, ['https://www.example.org']);
    });

    test('EHR customer lists: Organisations and contained ones, by country and town', () {
      final bundle = {
        'entry': [
          {
            'resource': {
              'resourceType': 'Endpoint',
              'contained': [
                {
                  'resourceType': 'Organization',
                  'name': 'Example Health Trust',
                  'address': [
                    {'city': 'Exampletown', 'country': 'GB'},
                  ],
                },
              ],
            },
          },
          {
            'resource': {
              'resourceType': 'Organization',
              'name': 'Sample Medical Center',
              'address': [
                {'city': 'Sampleville', 'state': 'EX', 'country': 'US'},
              ],
            },
          },
          {
            'resource': {'resourceType': 'Organization', 'name': 'Example Health Trust'},
          },
        ],
      };
      final all = EmployerDiscovery.parseFhirOrganisations(bundle, source: 'Epic');
      expect(all.map((s) => s.name), ['Example Health Trust', 'Sample Medical Center']);
      expect(
        EmployerDiscovery.parseFhirOrganisations(bundle, source: 'Epic', country: 'GB').map((s) => s.name),
        ['Example Health Trust'],
      );
      expect(
        EmployerDiscovery.parseFhirOrganisations(bundle, source: 'Epic', towns: ['Sampleville']).single.place,
        'Sampleville, EX',
      );
    });
  });

  test('adding a country to the targets from Explore', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
    expect(await book.addTargetCountry('NZ'), isTrue);
    expect(await book.addTargetCountry('NZ'), isFalse);
    expect((await book.profile()).searchCountries, containsAll(['GB', 'IE', 'NZ']));
  });

  test('area lines read the default radius', () {
    expect(HomeArea.parse('Exampletown | x | Sampleby')!.radiusMiles, isNull);
  });
}
