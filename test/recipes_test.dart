import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/assist_fill.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/page_reader.dart';
import 'package:udyoga/domain/polite.dart';
import 'package:udyoga/domain/recipes.dart';

import 'support.dart';

String fixture(String name) => File('test/fixtures/pages/$name').readAsStringSync();

Map<String, Object?> fetchRecipe({String site = 'jobs.example.org', Map<String, Object?> extra = const {}}) =>
    {
      'id': 'example-jobs',
      'site': site,
      'urlPatterns': ['https://$site/vacancy/*'],
      'mode': 'fetch',
      'rate': 20,
      'dailyCap': 30,
      'robots': true,
      'list': {'url': 'https://$site/search?q={terms}', 'item': 'a.vacancy-link'},
      'detail': {
        'jsonLd': 'JobPosting',
        'fields': {
          'title': 'h1.vacancy-title',
          'company': '.employer-name',
          'location': '.vacancy-location',
          'salary': '.vacancy-salary',
          'closing': '.closing-date',
          'reference': '.vacancy-ref',
          'description': '#vacancy-description',
        },
      },
      ...extra,
    };

Map<String, Object?> fillRecipe({
  String site = 'jobs.example.org',
  int cap = 10,
  Map<String, Object?> fill = const {},
}) => {
  'id': 'example-message',
  'site': site,
  'urlPatterns': ['https://$site/messages/*'],
  'mode': 'assist-fill',
  'rate': 30,
  'dailyCap': cap,
  'fill': {
    'targetSelector': 'textarea#message-body',
    'templateSource': 'draft',
    'maxLength': 40,
    'neverClick': true,
    ...fill,
  },
};

Matcher refused(String why) =>
    throwsA(isA<RecipeException>().having((e) => e.message, 'message', contains(why)));

void main() {
  group('validation', () {
    test('a good fetch recipe loads', () {
      final r = Recipe.fromJson(fetchRecipe());
      expect((r.mode, r.rate, r.dailyCap, r.robots), (RecipeMode.fetch, 20, 30, true));
      expect(r.matches('https://jobs.example.org/vacancy/12'), isTrue);
      expect(r.matches('https://jobs.example.org/about'), isFalse);
    });

    test('unknown modes and fields, and a missing rate or cap, are refused', () {
      expect(() => Recipe.fromJson({...fetchRecipe(), 'mode': 'crawl'}), refused('mode must be'));
      expect(() => Recipe.fromJson({...fetchRecipe(), 'clicks': true}), refused('unknown field clicks'));
      expect(() => Recipe.fromJson({...fetchRecipe()}..remove('rate')), refused('rate'));
      expect(() => Recipe.fromJson({...fetchRecipe()}..remove('dailyCap')), refused('dailyCap'));
      expect(() => Recipe.fromJson({...fetchRecipe(), 'dailyCap': 0}), refused('dailyCap'));
      expect(() => Recipe.fromJson({...fetchRecipe(), 'rate': 2}), refused('at least 5 seconds'));
      expect(
        () => Recipe.fromJson({
          ...fetchRecipe(),
          'detail': {
            'fields': {'salaryBand': 'p'},
          },
        }),
        refused('no field "salaryBand"'),
      );
    });

    test('fetch must obey robots.txt', () {
      expect(() => Recipe.fromJson({...fetchRecipe()}..remove('robots')), refused('"robots": true'));
      expect(() => Recipe.fromJson({...fetchRecipe(), 'robots': false}), refused('"robots": true'));
    });

    test('fetch is refused on LinkedIn, Indeed and Glassdoor, any ending or subdomain', () {
      for (final site in [
        'linkedin.com',
        'www.linkedin.com',
        'indeed.com',
        'uk.indeed.com',
        'indeed.co.uk',
        'glassdoor.co.uk',
        'www.glassdoor.com',
      ]) {
        expect(
          () => Recipe.fromJson(fetchRecipe(site: site)),
          refused('does not allow programs'),
          reason: site,
        );
      }
      // Lookalikes are not caught by the rule.
      expect(isFetchDenied('notindeed.com'), isFalse);
      expect(isFetchDenied('linkedin.com.example.org'), isFalse);
      // Reading a page the user opens is allowed there.
      final read = Recipe.fromJson({
        'id': 'li-profile',
        'site': 'www.linkedin.com',
        'urlPatterns': ['https://www.linkedin.com/in/*'],
        'mode': 'browser-read',
        'record': 'person',
        'rate': 1,
        'dailyCap': 50,
        'detail': {
          'fields': {'name': 'h1'},
        },
      });
      expect(read.mode, RecipeMode.browserRead);
    });

    test('pages must be on the recipe\'s site', () {
      expect(
        () => Recipe.fromJson({
          ...fetchRecipe(),
          'urlPatterns': ['https://other.example.net/*'],
        }),
        refused('is not on jobs.example.org'),
      );
    });

    test('LinkedIn fills are capped at 15 a day whatever the recipe says', () {
      final li = Recipe.fromJson({
        ...fillRecipe(site: 'www.linkedin.com', cap: 80),
        'urlPatterns': ['https://www.linkedin.com/in/*'],
      });
      expect(li.dailyCap, 80);
      expect(li.effectiveCap, linkedInDailyCeiling);
      expect(linkedInDailyCeiling, 15);
      expect(
        Recipe.fromJson({
          ...fillRecipe(site: 'www.linkedin.com', cap: 5),
          'urlPatterns': ['https://www.linkedin.com/*'],
        }).effectiveCap,
        5,
      );
      expect(Recipe.fromJson(fillRecipe(cap: 80)).effectiveCap, 80);
    });

    test('a fill must never click and must target a text box', () {
      expect(
        () => Recipe.fromJson(fillRecipe(fill: {'neverClick': false})),
        refused('neverClick must be true'),
      );
      expect(
        () => Recipe.fromJson(
          fillRecipe()..['fill'] = ({...fillRecipe()['fill']! as Map}..remove('neverClick')),
        ),
        refused('neverClick'),
      );
      expect(
        () => Recipe.fromJson(fillRecipe(fill: {'targetSelector': 'button.send'})),
        refused('not a button'),
      );
      expect(
        () => Recipe.fromJson(fillRecipe(fill: {'targetSelector': 'input[type=submit]'})),
        refused('not a button'),
      );
      expect(() => Recipe.fromJson(fillRecipe(fill: {'templateSource': 'recipe'})), refused('fill.template'));
      expect(() => Recipe.fromJson(fillRecipe(fill: {'onSend': 'click'})), refused('unknown fill field'));
    });

    test('a folder: good files load, bad ones are listed with the reason', () async {
      final dir = await Directory.systemTemp.createTemp('udyoga-recipes');
      addTearDown(() => dir.delete(recursive: true));
      await File('${dir.path}/a.json').writeAsString(jsonEncode([fetchRecipe(), fillRecipe()]));
      await File('${dir.path}/b.json').writeAsString(jsonEncode(fetchRecipe(site: 'uk.indeed.com')));
      await File('${dir.path}/c.json').writeAsString('{not json');
      await File('${dir.path}/d.json').writeAsString(jsonEncode(fetchRecipe()));
      await File('${dir.path}/notes.txt').writeAsString('ignored');
      final set = await RecipeSet.load(dir);
      expect(set.recipes.map((r) => r.id), ['example-jobs', 'example-message']);
      expect(set.problems, [
        startsWith('b.json: uk.indeed.com does not allow programs'),
        startsWith('c.json: not valid JSON'),
        'd.json: id example-jobs is used twice; the first is kept',
      ]);
      expect(
        set.forPage('https://jobs.example.org/messages/new', RecipeMode.assistFill).single.id,
        'example-message',
      );
    });

    test('the documented example loads', () async {
      final doc = File('docs/recipes.md').readAsStringSync();
      final json = RegExp(r'```json\n(.*?)```', dotAll: true).firstMatch(doc)![1]!;
      final dir = await Directory.systemTemp.createTemp('udyoga-recipes');
      addTearDown(() => dir.delete(recursive: true));
      await File('${dir.path}/example.json').writeAsString(json);
      final set = await RecipeSet.load(dir);
      expect(set.problems, isEmpty);
      expect(set.recipes.map((r) => r.mode), [
        RecipeMode.fetch,
        RecipeMode.browserRead,
        RecipeMode.assistFill,
      ]);
      expect(set.recipes.every((r) => r.site == 'jobs.example.org'), isTrue);
    });
  });

  group('extraction', () {
    final recipe = Recipe.fromJson(fetchRecipe());

    test('selectors read a detail page into a job', () {
      final r = recipe.recordFrom(fixture('detail.html'), url: 'https://jobs.example.org/vacancy/102')!;
      expect(r.kind, RecordKind.job);
      expect(r['title'], 'Ward Clerk');
      expect(r['company'], 'Example Community Hospital');
      expect(r['location'], 'Sampleford');
      expect(r['closing'], '5 December 2026');
      expect(r['reference'], 'EX-2001');
      final p = r.toPosting();
      expect((p.closing, p.salaryMin, p.salaryMax), ('2026-12-05', 23500, 25000));
    });

    test('JSON-LD fills what the selectors leave, and ld: paths read it', () {
      final r = Recipe.fromJson({
        ...fetchRecipe(),
        'detail': {
          'jsonLd': 'JobPosting',
          'fields': {
            'title': 'h1.vacancy-title',
            'company': 'ld:hiringOrganization.name',
            'location': '.missing',
          },
        },
      }).recordFrom(fixture('job_ld.html'), url: 'https://jobs.example.org/vacancy/1042')!;
      expect(r['company'], 'Example Health Trust');
      expect(r['location'], contains('Exampleton'));
      expect(r['closing'], '2026-12-01');
    });

    test('list links are absolute and kept to the recipe\'s pages', () {
      expect(
        recipe.linksIn(fixture('list.html'), base: Uri.parse('https://jobs.example.org/search?q=clerk')),
        ['https://jobs.example.org/vacancy/101', 'https://jobs.example.org/vacancy/102'],
      );
    });

    test('a browser-read recipe wins over the page\'s own reading', () {
      final html = fixture('detail.html');
      final r = Recipe.fromJson({
        'id': 'ex-read',
        'site': 'jobs.example.org',
        'urlPatterns': ['https://jobs.example.org/vacancy/*'],
        'mode': 'browser-read',
        'rate': 1,
        'dailyCap': 50,
        'detail': {
          'fields': {'title': 'h1.vacancy-title', 'company': '.employer-name', 'reference': '.apply@href'},
        },
      });
      final page = PageSnapshot(url: 'https://jobs.example.org/vacancy/102', html: html, text: 'Ward Clerk');
      final records = readPage(page, first: [?r.recordFrom(html, url: page.url)]);
      expect(records.first.from, 'recipe jobs.example.org');
      expect(records.first['reference'], '/apply/2001');
    });
  });

  group('polite fetch', () {
    late CareerBook book;
    setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));

    http.Response page(String body) => http.Response.bytes(utf8.encode(body), 200);

    test('reads the list then each new job, waiting the rate between requests', () async {
      final asked = <String>[];
      final waits = <Duration>[];
      var now = DateTime.utc(2026, 11, 19, 9);
      final client = MockClient((r) async {
        asked.add(r.url.path);
        expect(r.headers['user-agent'], contains('Udyoga'));
        now = now.add(const Duration(seconds: 1));
        return switch (r.url.path) {
          '/robots.txt' => page('User-agent: *\nDisallow: /private'),
          '/search' => page(fixture('list.html')),
          _ => page(fixture('detail.html')),
        };
      });
      final fetcher = PoliteFetcher(
        book.db,
        client,
        clock: () => now,
        sleep: (d) async {
          waits.add(d);
          now = now.add(d);
        },
      );
      final run = await RecipeFetch(book.db, fetcher, [Recipe.fromJson(fetchRecipe())]).run(sampleProfile);
      expect(run.problems, isEmpty);
      expect(asked, ['/robots.txt', '/search', '/vacancy/101', '/vacancy/102']);
      expect(run.postings.map((p) => (p.source, p.url)), [
        ('recipe', 'https://jobs.example.org/vacancy/101'),
        ('recipe', 'https://jobs.example.org/vacancy/102'),
      ]);
      expect(waits, hasLength(2));
      expect(waits.every((w) => w > const Duration(seconds: 18)), isTrue);
      expect(await DailyCounter(book.db, clock: () => now).used('recipe.example-jobs'), 3);

      // Pages read this week are not read again.
      asked.clear();
      await RecipeFetch(book.db, fetcher, [Recipe.fromJson(fetchRecipe())]).run(sampleProfile);
      expect(asked, ['/search']);
    });

    test('robots.txt that disallows the search stops it', () async {
      final client = MockClient(
        (r) async => r.url.path == '/robots.txt' ? page('User-agent: *\nDisallow: /search') : page('x'),
      );
      final run = await RecipeFetch(book.db, PoliteFetcher(book.db, client), [
        Recipe.fromJson(fetchRecipe()),
      ]).run(sampleProfile);
      expect(run.postings, isEmpty);
      expect(run.problems.single, contains('robots.txt asks programs not to read /search'));
    });

    test('the daily cap stops the run quietly', () async {
      var n = 0;
      final client = MockClient((r) async {
        if (r.url.path != '/robots.txt') n++;
        return r.url.path == '/search' ? page(fixture('list.html')) : page(fixture('detail.html'));
      });
      final capped = Recipe.fromJson(fetchRecipe(extra: {'dailyCap': 2}));
      final run = await RecipeFetch(book.db, PoliteFetcher(book.db, client, sleep: (_) async {}), [
        capped,
      ]).run(sampleProfile);
      expect(n, 2);
      expect(run.postings, hasLength(1));
      expect(run.problems, isEmpty);
    });

    test('a denied site is skipped even when built by hand', () async {
      final sneaky = Recipe(
        id: 'sneaky',
        site: 'uk.indeed.com',
        urlPatterns: const ['https://uk.indeed.com/*'],
        mode: RecipeMode.fetch,
        rate: 10,
        dailyCap: 10,
        robots: true,
        list: const RecipeList(url: 'https://uk.indeed.com/jobs?q={terms}', item: 'a'),
      );
      var asked = 0;
      final client = MockClient((r) async {
        asked++;
        return page('');
      });
      final run = await RecipeFetch(book.db, PoliteFetcher(book.db, client), [sneaky]).run(sampleProfile);
      expect((asked, run.asked), (0, 0));
    });
  });

  group('assist-fill', () {
    late CareerBook book;
    var now = DateTime.utc(2026, 11, 19, 9);
    setUp(() async {
      book = CareerBook(await Store.open(memoryDatabase()));
      now = DateTime.utc(2026, 11, 19, 9);
    });

    test('the dry run shows the exact text, cut to the box, and changes nothing', () async {
      final fill = AssistFill(book.db, clock: () => now);
      final r = Recipe.fromJson(fillRecipe());
      final plan = await fill.plan(
        r,
        pageUrl: 'https://jobs.example.org/messages/new',
        draft: 'Hello, I would like to ask about the Ward Clerk post.',
      );
      expect(plan.ready, isTrue);
      expect(plan.text.length, lessThanOrEqualTo(40));
      expect(plan.cut, isTrue);
      expect((plan.used, plan.cap, plan.left), (0, 10, 10));
      expect(await DailyCounter(book.db, clock: () => now).used(r.use), 0);

      final wrong = await fill.plan(r, pageUrl: 'https://jobs.example.org/vacancy/1', draft: 'Hi');
      expect(wrong.problems.single, contains('not one of'));
      final empty = await fill.plan(r, pageUrl: 'https://jobs.example.org/messages/new');
      expect(empty.problems.single, contains('no approved draft'));
    });

    test('a fill goes through the one fill call and counts; LinkedIn stops at 15', () async {
      final fill = AssistFill(book.db, clock: () => now);
      final li = Recipe.fromJson({
        ...fillRecipe(site: 'www.linkedin.com', cap: 100),
        'rate': 1,
        'urlPatterns': ['https://www.linkedin.com/in/*'],
      });
      final calls = <(String, String)>[];
      Future<Object?> box(String selector, String text) async {
        calls.add((selector, text));
        return '{"ok":true}';
      }

      for (var i = 0; i < 15; i++) {
        now = now.add(const Duration(seconds: 2));
        final plan = await fill.plan(
          li,
          pageUrl: 'https://www.linkedin.com/in/someone-example',
          draft: 'Hi $i',
        );
        expect(await fill.apply(plan, box), isNull, reason: 'fill $i');
      }
      expect(calls.first, ('textarea#message-body', 'Hi 0'));
      now = now.add(const Duration(seconds: 2));
      final over = await fill.plan(li, pageUrl: 'https://www.linkedin.com/in/someone-example', draft: 'Hi');
      expect(over.ready, isFalse);
      expect(over.problems.single, contains('limit of 15'));
      expect(await fill.apply(over, box), contains('limit of 15'));
      expect(calls, hasLength(15));
    });

    test('fills wait the recipe\'s rate', () async {
      final fill = AssistFill(book.db, clock: () => now);
      final r = Recipe.fromJson(fillRecipe());
      final plan = await fill.plan(r, pageUrl: 'https://jobs.example.org/messages/1', draft: 'Hi');
      await fill.apply(plan, (_, _) async => '{"ok":true}');
      now = now.add(const Duration(seconds: 5));
      final soon = await fill.plan(r, pageUrl: 'https://jobs.example.org/messages/1', draft: 'Hi');
      expect(soon.problems.single, contains('Wait'));
    });

    test('a page that refuses the text is not counted', () async {
      final fill = AssistFill(book.db, clock: () => now);
      final r = Recipe.fromJson(fillRecipe());
      final plan = await fill.plan(r, pageUrl: 'https://jobs.example.org/messages/1', draft: 'Hi');
      expect(
        await fill.apply(plan, (_, _) async => '{"ok":false,"reason":"That is not a text box."}'),
        'That is not a text box.',
      );
      expect(await DailyCounter(book.db, clock: () => now).used(r.use), 0);
    });

    test('templates fill names and leave unknown placeholders empty', () {
      expect(
        fillTemplate('Hi {firstName}, about {jobTitle} at {company}{x}.', {
          'name': 'Alex Example',
          'company': 'Example Trust',
          'jobTitle': 'Porter',
        }),
        'Hi Alex, about Porter at Example Trust.',
      );
    });

    test('the fill path has no way to click, submit or press keys', () {
      final script = fillScript('textarea#a", alert(1), "', 'Send now\n</script>');
      // The selector and text are JSON strings, so they cannot break out.
      expect(script, contains(jsonEncode('textarea#a", alert(1), "')));
      final banned = RegExp(
        r'click|submit\s*\(|requestSubmit|KeyboardEvent|MouseEvent|PointerEvent|keydown|keypress|keyup|\.form\b',
        caseSensitive: false,
      );
      expect(banned.hasMatch(script), isFalse, reason: script);
      expect(script, contains("new Event('input'"));

      // The whole fill path, and the browser's fill call, in source.
      final code = [
        File('lib/domain/assist_fill.dart').readAsStringSync(),
        File('lib/ui/site_browser.dart').readAsStringSync(),
      ].map((s) => s.split('\n').where((l) => !l.trim().startsWith('//')).join('\n')).join('\n');
      expect(
        RegExp(
          r'\.click\(|click\s*:|\bclick\w*\s*\(|requestSubmit|\.submit\(|KeyboardEvent|MouseEvent|dispatchKey',
          caseSensitive: false,
        ).hasMatch(code),
        isFalse,
      );
    });
  });
}
