import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/ats.dart';
import 'package:udyoga/domain/ocr.dart';
import 'package:udyoga/domain/page_reader.dart';

String fixture(String name) => File('test/fixtures/pages/$name').readAsStringSync();

void main() {
  group('reading the DOM and JSON-LD', () {
    final html = fixture('job_ld.html');
    final page = PageSnapshot(
      url: 'https://jobs.example.org/vacancy/1042',
      title: 'Records Clerk | Example Jobs',
      text: 'Records Clerk\nExample Health Trust',
      ld: ldScriptsIn(html),
      html: html,
    );

    test('a JobPosting, its employer and a Person become records', () {
      final records = readPage(page);
      final job = records.firstWhere((r) => r.kind == RecordKind.job);
      expect(job['title'], 'Records Clerk');
      expect(job['company'], 'Example Health Trust');
      expect(job['location'], contains('Exampleton'));
      expect(job['closing'], '2026-12-01');
      expect(job['posted'], '2026-11-10');
      expect(job['reference'], 'EX-1042');
      expect(job['description'], contains('patient records'));
      expect(job.from, 'page markup');

      final org = records.firstWhere((r) => r.kind == RecordKind.company);
      expect((org['name'], org['website']), ('Example Health Trust', 'https://careers.example.org'));

      final person = records.firstWhere((r) => r.kind == RecordKind.person);
      expect(person['name'], 'Sam Placeholder');
      expect(person['title'], 'Records Manager');
      expect(person['company'], 'Example Health Trust');
      expect(person['email'], 'sam.placeholder@example.org');
      expect(person['profileUrl'], 'https://www.linkedin.com/in/sam-placeholder-example');
    });

    test('a page with markup is not thin; a canvas page with no words is', () {
      expect(page.thin, isFalse);
      expect(const PageSnapshot(url: 'https://x.example.org', text: 'Loading', canvases: 1).thin, isTrue);
      expect(const PageSnapshot(url: 'https://x.example.org', text: 'Page 1 of 3', pdf: true).thin, isTrue);
    });

    test('the record becomes a posting with its dates and pay', () {
      final job = readPage(page).firstWhere((r) => r.kind == RecordKind.job);
      final p = job.toPosting(country: 'GB');
      expect((p.source, p.title, p.closing, p.country), ('page', 'Records Clerk', '2026-12-01', 'GB'));
      final typed = PageRecord(RecordKind.job, {
        'title': 'Clerk',
        'closing': '5 December 2026',
        'salary': '£23,500 to £25,000',
      }, from: 'x');
      expect(typed.toPosting().closing, '2026-12-05');
      expect((typed.toPosting().salaryMin, typed.toPosting().salaryMax), (23500, 25000));
    });

    test('the reply of the page script decodes, quoted once more or not', () {
      const raw =
          '{"url":"https://jobs.example.org/v/1","title":"T","text":"x","ld":["{}"],"html":"<p>","canvases":2,"pdf":false}';
      for (final r in [raw, '"${raw.replaceAll('"', r'\"')}"']) {
        final s = PageSnapshot.decode(r)!;
        expect((s.url, s.ld.length, s.canvases, s.pdf), ('https://jobs.example.org/v/1', 1, 2, false));
      }
      expect(PageSnapshot.decode('not json'), isNull);
    });

    test('nothing is made up from a page that is not an advert', () {
      expect(
        readPage(const PageSnapshot(url: 'https://example.org', title: 'Home', text: 'Welcome to our site.')),
        isEmpty,
      );
    });
  });

  group('OCR text into records', () {
    test('labelled lines and contacts become a job, an employer and a person', () {
      final records = recordsFromText(
        fixture('ocr.txt'),
        url: 'https://jobs.example.org/v/3307',
        from: 'OCR',
      );
      final job = records.firstWhere((r) => r.kind == RecordKind.job);
      expect(job['title'], 'Outpatient Receptionist');
      expect(job['company'], 'Example Valley Clinic');
      expect(job['location'], 'Sampleford');
      expect(job['salary'], startsWith('£22,800'));
      expect(job['closing'], '2026-12-12');
      expect(job['reference'], 'EX-3307');
      expect(job.from, 'OCR');
      expect(records.where((r) => r.kind == RecordKind.company).single['name'], 'Example Valley Clinic');
      final person = records.firstWhere((r) => r.kind == RecordKind.person);
      expect(person['name'], 'Alex Example');
      expect(person['email'], 'alex.example@example.org');
    });

    test('OCR noise without advert signs gives no job', () {
      expect(recordsFromText('Menu\nSign in\nCookies').where((r) => r.kind == RecordKind.job), isEmpty);
    });

    test('a data URL from the page canvas decodes to bytes', () {
      expect(dataUrlBytes('data:image/png;base64,iVBORw0KGgo='), isNotNull);
      expect(dataUrlBytes(''), isNull);
      expect(dataUrlBytes('data:text/html;base64,PGI+'), isNull);
    });

    test('Tesseract is found on the PATH, or reported missing', () async {
      final found = await TesseractOcr.find(
        run: (_, _) async => ProcessResult(0, 0, '/usr/bin/tesseract\n', ''),
        windows: false,
      );
      expect(found?.exe, '/usr/bin/tesseract');
      final missing = await TesseractOcr.find(
        run: (_, _) async => ProcessResult(0, 1, '', ''),
        windows: false,
      );
      expect(missing, isNull);
    });
  });

  group('AI vision', () {
    test('only providers that read images are offered', () {
      expect(AiProvider.claude.images, isTrue);
      expect(AiProvider.gemini.images, isTrue);
      expect(AiProvider.claudeCode.images, isTrue);
      expect(AiProvider.codex.images, isFalse);
    });

    test('the answer becomes records; unknown kinds and empty ones are dropped', () {
      final r = recordsFromVision({
        'records': [
          {
            'kind': 'job',
            'fields': {'title': 'Porter', 'company': 'Example Trust'},
          },
          {
            'kind': 'pet',
            'fields': {'name': 'Rex'},
          },
          {'kind': 'person', 'fields': <String, Object?>{}},
        ],
      }, url: 'https://jobs.example.org/v/1');
      expect(r.single.headline, 'Porter');
      expect(r.single.from, 'AI');
    });
  });
}
