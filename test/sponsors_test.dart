import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/sponsors.dart';

import 'support.dart';

final csv = File('test/fixtures/sponsors.csv').readAsStringSync();

void main() {
  group('names', () {
    test('legal endings, "The", "&" and punctuation do not matter', () {
      expect(sponsorKey('The Example Health NHS Foundation Trust'), 'example health');
      expect(sponsorKey('Example Health'), 'example health');
      expect(sponsorKey('Example Care Group Ltd.'), 'example care group');
      expect(sponsorKey('Smith and Daughters'), sponsorKey('Smith & Daughters PLC'));
      expect(sponsorKey("St. Example's Hospice Limited"), 'st examples hospice');
    });
  });

  group('the register', () {
    final register = SponsorRegister.fromCsv(csv);

    test('reads one organisation per name, routes merged', () {
      final trust = register.lookup('Example Health NHS Foundation Trust')!;
      expect(trust.routes, {'Skilled Worker', 'Government Authorised Exchange'});
      expect(trust.town, 'Exampletown');
      expect(trust.badge, 'Licensed sponsor (Skilled Worker / Health and Care)');
    });

    test("matches the job's way of naming the employer", () {
      expect(register.lookup('Example Health'), isNotNull);
      expect(register.lookup('Example Care Group'), isNotNull);
      expect(register.lookup('Smith and Daughters'), isNotNull);
      expect(register.lookup('Quote "Marks"'), isNotNull);
    });

    test('a trading name counts', () {
      final s = register.lookup('Sample Data')!;
      expect(s.skilledWorker, isFalse);
      expect(s.badge, 'Licensed sponsor (Global Business Mobility: Senior or Specialist Worker)');
      expect(register.lookup('Sample Analytics Ltd')!.name, s.name);
    });

    test('never matches part of a name', () {
      expect(register.lookup('Example Care'), isNull);
      expect(register.lookup('Example'), isNull);
      expect(register.lookup(''), isNull);
    });

    test('round-trips through the cache', () {
      final again = SponsorRegister.fromTsv(register.toTsv());
      expect(again.length, register.length);
      expect(again.lookup('Example Health')!.routes, register.lookup('Example Health')!.routes);
    });

    test('a file without the organisation column is refused', () {
      expect(() => SponsorRegister.fromCsv('a,b\n1,2'), throwsFormatException);
    });

    test('CSV quoting: commas, doubled quotes and line breaks in fields', () {
      expect(parseCsv('a,"b, c","d ""e"""\r\n"f\ng",h\n'), [
        ['a', 'b, c', 'd "e"'],
        ['f\ng', 'h'],
      ]);
    });
  });

  group('the store', () {
    late AppDatabase db;
    late Directory dir;
    var gets = <String>[];
    var csvName = 'Worker_and_Temporary_Worker-2026-11-19.csv';

    http.Client govUk() => MockClient((r) async {
      gets.add(r.url.path);
      if (r.url.toString() == sponsorRegisterApi) {
        return http.Response(
          jsonEncode({
            'details': {
              'attachments': [
                {
                  'url': 'https://assets.publishing.service.gov.uk/media/x/guide.pdf',
                  'content_type': 'application/pdf',
                },
                {
                  'url': 'https://assets.publishing.service.gov.uk/media/y/$csvName',
                  'content_type': 'text/csv',
                },
              ],
            },
          }),
          200,
        );
      }
      if (r.url.path.endsWith('.csv')) return http.Response(csv, 200);
      return http.Response('not found', 404);
    });

    setUp(() async {
      db = memoryDatabase();
      dir = await Directory.systemTemp.createTemp('udyoga-sponsors');
      addTearDown(() => dir.delete(recursive: true));
      gets = [];
      csvName = 'Worker_and_Temporary_Worker-2026-11-19.csv';
    });

    test('finds the CSV through the GOV.UK content API', () async {
      final url = await SponsorStore(dir, govUk(), db).csvUrl();
      expect(url.path, endsWith(csvName));
    });

    test('downloads once a day at most, and only when the file changed', () async {
      final store = SponsorStore(dir, govUk(), db);
      final now = DateTime(2026, 11, 19, 9);
      expect(await store.load(), isNull);
      expect(await store.refreshIfDue(now: now), isTrue);
      expect((await store.load())!.lookup('Example Health'), isNotNull);

      gets = [];
      expect(await store.refreshIfDue(now: now.add(const Duration(hours: 5))), isFalse);
      expect(gets, isEmpty, reason: 'within a day nothing is fetched');

      expect(await store.refreshIfDue(now: now.add(const Duration(days: 1))), isFalse);
      expect(gets.where((p) => p.endsWith('.csv')), isEmpty, reason: 'same file name: not downloaded again');

      csvName = 'Worker_and_Temporary_Worker-2026-11-21.csv';
      expect(await store.refreshIfDue(now: now.add(const Duration(days: 2))), isTrue);
    });

    test('a page without a CSV is an error, not an empty register', () async {
      final empty = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'details': {'attachments': []},
          }),
          200,
        ),
      );
      expect(() => SponsorStore(dir, empty, db).refreshIfDue(), throwsA(isA<FeedException>()));
    });
  });
}
