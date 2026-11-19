import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/route_refresh.dart';
import 'package:udyoga/domain/routes.dart';

import 'support.dart';

/// Rows of the real GOV.UK page (Open Government Licence), trimmed.
final aso = File('test/fixtures/skilled_occupations.json').readAsStringSync();

const rounds =
    '{"classes":[],"rounds":['
    '{"drawNumber":"452","drawDate":"2026-10-20","drawName":"Canadian Experience Class","drawSize":"3,000","drawCRS":"520"},'
    '{"drawNumber":"453","drawDate":"2026-10-28","drawName":"Transport Occupations","drawSize":"150","drawCRS":"477"},'
    '{"drawNumber":"x","drawDate":"soon"}]}';

/// Shipped rules with made-up rates, so the parser has to change them.
final stale = UkRules(
  generalFloor: 41700,
  newEntrantFloor: 33400,
  careFloor: 31300,
  careNewEntrantFloor: 25000,
  tslCutoff: '2026-12-31',
  occupations: {
    for (final o in shippedUkRules.occupations.values)
      o.soc: o.copyWith(goingRate: 1, newEntrantRate: 1, careRate: 1, careNewEntrantRate: 1),
  },
  source: shippedUkRules.source,
);

void main() {
  test('the GOV.UK appendix gives each table its rates', () {
    final r = parseSkilledOccupations(aso, base: stale, today: '2026-11-19')!;
    expect(r.live, isTrue);
    expect(r.source.title, contains('2025-11-11'));
    final it = r.occupations['2133']!;
    expect((it.table, it.goingRate, it.newEntrantRate), ('1', 54900, 38400));
    expect((it.careRate, it.careNewEntrantRate), (42400, 29600));
    final coder = r.occupations['3549']!;
    expect((coder.table, coder.goingRate, coder.careRate), ('1a', 33400, 25500));
    expect(coder.tslJobs, contains('Clinical coders'));
    // 3133 is in 2aa and 2b: the 2aa rate wins.
    expect(r.occupations['3133']!.careRate, 29200);
    expect(r.occupations['4211']!.table, '6');
    // Codes the page did not give keep the base rates.
    expect(r.occupations['2134']!.goingRate, 1);
  });

  test('a changed or broken page falls back', () {
    expect(parseSkilledOccupations('nope', base: stale, today: '2026-11-19'), isNull);
    expect(
      parseSkilledOccupations('{"details":{"body":"<p>moved</p>"}}', base: stale, today: '2026-11-19'),
      isNull,
    );
  });

  test('Express Entry rounds: newest first, broken rows skipped', () {
    final r = parseExpressEntryRounds(rounds);
    expect(r.map((e) => e.number), [453, 452]);
    expect((r.first.name, r.first.crs, r.first.size), ('Transport Occupations', 477, 150));
    expect(r.last.size, 3000);
    expect(parseExpressEntryRounds('[]'), isEmpty);
  });

  test('refresh caches for a week and keeps the last good copy', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    var calls = 0;
    var up = true;
    final client = MockClient((req) async {
      calls++;
      if (!up) return http.Response('down', 503);
      return http.Response.bytes(
        utf8.encode(req.url.host == 'www.gov.uk' ? aso : rounds),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final refresh = RouteRefresh(client, db);
    expect((await refresh.ukRules()).live, isFalse);
    final now = DateTime(2026, 11, 19);
    await refresh.refreshUk(now: now);
    expect((await refresh.ukRules()).live, isTrue);
    expect((await refresh.ukRules()).occupations['2133']!.goingRate, 54900);
    await refresh.refreshUk(now: now.add(const Duration(days: 2)));
    expect(calls, 1);
    up = false;
    await expectLater(
      refresh.refreshUk(now: now.add(const Duration(days: 9))),
      throwsA(isA<FeedException>()),
    );
    expect((await refresh.ukRules()).live, isTrue);

    up = true;
    final ee = await refresh.refreshRounds(now: now);
    expect(ee.rounds.first.number, 453);
    expect(ee.checked, '2026-11-19');
    expect((await refresh.rounds())!.rounds, hasLength(2));
  });
}
