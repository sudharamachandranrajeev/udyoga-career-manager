import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/refresh.dart';
import 'package:udyoga/domain/route_refresh.dart';

import 'support.dart';

const today = '2026-11-19';

/// Answers job searches with [jobs], or throws when [fail] is set; counts
/// the calls.
class _JobFinder implements Ai {
  _JobFinder({this.jobs = const [], this.fail = false});
  final List<Json> jobs;
  bool fail;
  var calls = 0;

  @override
  String get model => 'test';

  @override
  Future<AiResult> ask({
    required String system,
    required List<Json> content,
    required Json schema,
    bool web = false,
    int searches = 8,
    String effort = 'high',
    int maxTokens = 32000,
    void Function(String status)? onProgress,
  }) async {
    calls++;
    if (fail) throw AiException('The model is busy');
    return AiResult({'jobs': jobs, 'paths': <Json>[], 'summary': ''});
  }
}

void main() {
  late CareerBook book;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    // Remote work too, so the JSON feeds that need no key are asked.
    await book.saveProfile(
      sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(workModes: ['remote'])),
    );
  });

  Future<String?> feedsChecked() => book.db.localSetting(LocalKeys.feedsChecked);
  Future<String?> aiChecked() => book.db.localSetting(LocalKeys.aiChecked);
  Future<AiLease> lease() async =>
      AiLease.fromJson(await book.pref<Map<String, Object?>>(PrefKeys.aiLease, const {}));

  group('feeds', () {
    test('when every feed fails, the check is not counted as done', () async {
      final down = MockClient((_) async => throw const SocketException('offline'));
      final r = await Refresher(book, down).run(today: today);
      expect(r.feedsChecked, isFalse);
      expect(await feedsChecked(), isNull);
      expect(r.problems, isNotEmpty);
      expect(r.problems.every((p) => p.endsWith('not reachable')), isTrue, reason: '${r.problems}');
    });

    test('a reply that is not JSON is told apart from no connection', () async {
      final portal = MockClient((_) async => http.Response('<html>Sign in to the Wi-Fi</html>', 200));
      final r = await Refresher(book, portal).run(today: today);
      expect(r.problems.where((p) => p.contains('not job data')), isNotEmpty, reason: '${r.problems}');
      expect(r.problems.where((p) => p.contains('not reachable')), isEmpty);
    });

    test('when one feed answers, the check counts', () async {
      final r = await Refresher(book, quietClient()).run(today: today);
      expect(r.feedsChecked, isTrue);
      expect(await feedsChecked(), isNotNull);
    });

    test('feedProblem names each kind of failure', () {
      expect(feedProblem(FeedException('error 500')), 'error 500');
      expect(feedProblem(const FormatException('x')), contains('could not be read'));
      expect(feedProblem(const SocketException('x')), 'not reachable');
      expect(feedProblem(http.ClientException('x')), 'not reachable');
    });
  });

  group('the AI routine', () {
    Future<void> weekly() => book.setPref(PrefKeys.aiRoutine, 'weekly');

    test('a failed AI search is not counted as done', () async {
      await weekly();
      final ai = _JobFinder(fail: true);
      final r = await Refresher(book, quietClient(), advisor: Advisor(ai, today: today)).run(today: today);
      expect(ai.calls, greaterThan(0));
      expect(r.aiSearched, isFalse);
      expect(await aiChecked(), isNull);
      expect((await lease()).ran, isNull);
      expect(r.problems.where((p) => p.startsWith('AI search')), isNotEmpty);
    });

    test('a run takes the lease for this device and records when it ran', () async {
      await weekly();
      final r = await Refresher(
        book,
        quietClient(),
        advisor: Advisor(_JobFinder(), today: today),
      ).run(today: today);
      expect(r.aiSearched, isTrue);
      expect(await aiChecked(), isNotNull);
      final l = await lease();
      expect(l.device, book.store.deviceId);
      expect(l.ran, isNotNull);
      expect(l.until!.isAfter(DateTime.now().add(const Duration(days: 6))), isTrue);
    });

    test('another device holding the lease keeps the routine', () async {
      await weekly();
      await book.setPref(
        PrefKeys.aiLease,
        AiLease(device: 'other-device', until: DateTime.now().add(const Duration(days: 3))).toJson(),
      );
      final ai = _JobFinder();
      final r = await Refresher(book, quietClient(), advisor: Advisor(ai, today: today)).run(today: today);
      expect(ai.calls, 0);
      expect(r.aiElsewhere, isTrue);
      expect((await lease()).device, 'other-device');
    });

    test('a lapsed lease is taken over', () async {
      await weekly();
      await book.setPref(
        PrefKeys.aiLease,
        AiLease(
          device: 'other-device',
          until: DateTime.now().subtract(const Duration(hours: 1)),
          ran: DateTime.now().subtract(const Duration(days: 8)),
        ).toJson(),
      );
      final ai = _JobFinder();
      await Refresher(book, quietClient(), advisor: Advisor(ai, today: today)).run(today: today);
      expect(ai.calls, greaterThan(0));
      expect((await lease()).device, book.store.deviceId);
    });

    test('a recent run on another device is not repeated here', () async {
      await weekly();
      await book.setPref(
        PrefKeys.aiLease,
        AiLease(
          device: 'other-device',
          until: DateTime.now().subtract(const Duration(minutes: 1)),
          ran: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
      );
      final ai = _JobFinder();
      await Refresher(book, quietClient(), advisor: Advisor(ai, today: today)).run(today: today);
      expect(ai.calls, 0);
    });

    test('a search the user asks for runs even when another device holds the lease', () async {
      await book.setPref(
        PrefKeys.aiLease,
        AiLease(device: 'other-device', until: DateTime.now().add(const Duration(days: 3))).toJson(),
      );
      final ai = _JobFinder(
        jobs: [
          {
            'title': 'Clinical Informatics Nurse',
            'company': 'Example Health Trust',
            'country': 'GB',
            'url': 'https://jobs.example.com/1',
            'fit': 77,
            'why': 'Close match',
          },
        ],
      );
      final r = await Refresher(
        book,
        quietClient(),
        advisor: Advisor(ai, today: today),
      ).run(today: today, ai: true);
      expect(r.aiSearched, isTrue);
      expect(r.added, 1);
      final job = (await book.db.select(book.db.jobListings).get()).single;
      expect(job.fit, 77);
      expect(job.fitBy, 'triage');
    });

    group('a background run (leaseOnly)', () {
      test('does not take a free lease', () async {
        await weekly();
        final ai = _JobFinder();
        final r = await Refresher(
          book,
          quietClient(),
          advisor: Advisor(ai, today: today),
          leaseOnly: true,
        ).run(today: today);
        expect(ai.calls, 0);
        expect(r.aiElsewhere, isTrue);
        expect((await lease()).device, isEmpty);
      });

      test('does not take over a lapsed lease', () async {
        await weekly();
        await book.setPref(
          PrefKeys.aiLease,
          AiLease(device: 'other-device', until: DateTime.now().subtract(const Duration(hours: 1))).toJson(),
        );
        final ai = _JobFinder();
        await Refresher(
          book,
          quietClient(),
          advisor: Advisor(ai, today: today),
          leaseOnly: true,
        ).run(today: today);
        expect(ai.calls, 0);
        expect((await lease()).device, 'other-device');
      });

      test('runs the routine when this device holds the lease', () async {
        await weekly();
        await book.setPref(
          PrefKeys.aiLease,
          AiLease(
            device: book.store.deviceId,
            until: DateTime.now().add(const Duration(days: 3)),
            ran: DateTime.now().subtract(const Duration(days: 8)),
          ).toJson(),
        );
        final ai = _JobFinder();
        final r = await Refresher(
          book,
          quietClient(),
          advisor: Advisor(ai, today: today),
          leaseOnly: true,
        ).run(today: today);
        expect(ai.calls, greaterThan(0));
        expect(r.aiSearched, isTrue);
      });
    });

    test('the lease round-trips through JSON', () {
      final at = DateTime.utc(2026, 11, 19, 10);
      final l = AiLease.fromJson(AiLease(device: 'd', until: at, ran: at).toJson());
      expect((l.device, l.until, l.ran), ('d', at, at));
      expect(l.heldElsewhere('d', at.subtract(const Duration(hours: 1))), isFalse);
      expect(l.heldElsewhere('e', at.subtract(const Duration(hours: 1))), isTrue);
      expect(l.heldElsewhere('e', at.add(const Duration(hours: 1))), isFalse);
    });
  });

  group('route tables', () {
    test('a refresh reads them once a week and reports it', () async {
      final r1 = await Refresher(
        book,
        quietClient(),
        routes: RouteRefresh(quietClient(), book.db),
      ).run(today: today);
      // '{}' is no appendix and no rounds: both are problems, nothing cached.
      expect(r1.routesRead, isFalse);
      expect(r1.problems.where((p) => p.startsWith('GOV.UK route table')), isNotEmpty);
      expect(r1.problems.where((p) => p.startsWith('Express Entry rounds')), isNotEmpty);
    });

    test('a fresh read is reported, and not repeated within the week', () async {
      final aso = File('test/fixtures/skilled_occupations.json').readAsStringSync();
      const rounds =
          '{"rounds":[{"drawNumber":"452","drawDate":"2026-10-20","drawName":"General",'
          '"drawSize":"3,000","drawCRS":"520"}]}';
      var calls = 0;
      final sources = MockClient((req) async {
        calls++;
        return http.Response.bytes(utf8.encode(req.url.host == 'www.gov.uk' ? aso : rounds), 200);
      });
      final r = await Refresher(
        book,
        quietClient(),
        routes: RouteRefresh(sources, book.db),
      ).run(today: today);
      expect(r.routesRead, isTrue, reason: '${r.problems}');
      expect(r.summary, contains('route tables updated'));
      expect(calls, 2);
      final again = await Refresher(
        book,
        quietClient(),
        routes: RouteRefresh(sources, book.db),
      ).run(today: today);
      expect(again.routesRead, isFalse);
      expect(calls, 2);
    });

    test('an unreachable source keeps the problem apart from the feeds', () async {
      final down = MockClient((_) async => throw const SocketException('offline'));
      final r = await Refresher(book, quietClient(), routes: RouteRefresh(down, book.db)).run(today: today);
      expect(r.problems.where((p) => p.startsWith('GOV.UK route table: could not reach')), hasLength(1));
      expect(r.feedsChecked, isTrue);
    });
  });
}
