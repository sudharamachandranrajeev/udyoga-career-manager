import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/occupations.dart';
import 'package:udyoga/domain/routes.dart';

void main() {
  test('the shipped index codes known titles exactly', () {
    final m = socMatches('Clinical Coder');
    expect(m.first.soc, '3549');
    expect(m.first.isco, '3252');
    expect(m.first.exact, isTrue);
    expect(socMatches('Business systems analyst').first.soc, '3549');
    expect(socMatches('Application analyst').first.soc, '2134');
  });

  test('close titles match on shared words; unrelated ones do not', () {
    expect(socMatches('Senior Clinical Systems Trainer').map((m) => m.soc), contains('3573'));
    expect(socMatches('Chief Vibes Wrangler'), isEmpty);
    expect(socMatches(''), isEmpty);
  });

  test('the full index codes titles outside health admin and IT', () {
    final nurse = socMatches('Staff Nurse');
    expect(nurse.single.soc, '2237');
    expect(nurse.single.exact, isTrue);
    expect(loadedSocIndex!.entries.length, greaterThan(25000));
  });

  test('a head-noun synonym matches: a facilitator is a trainer', () {
    final m = socMatches('Digital Training Facilitator');
    expect(m.first.soc, '3573');
    expect(m.every((o) => !o.exact), isTrue);
    // Sharing only the head noun is not a match.
    expect(
      socMatches('Digital Training Facilitator').map((o) => o.socTitle),
      isNot(contains(contains('animal'))),
    );
    // "training" is never "train": a training lead is not rail work.
    expect(socMatches('Training Lead').first.soc, '3574');
  });

  test('the index loads from its asset once', () async {
    final had = loadedSocIndex;
    final bundle = _CountingBundle();
    useSocIndex(null);
    expect(socMatches('Clinical Coder'), isEmpty);
    final first = loadSocIndex(bundle: bundle), second = loadSocIndex(bundle: bundle);
    expect(identical(await first, await second), isTrue);
    expect(bundle.loads, 1);
    expect(socMatches('Clinical Coder').first.soc, '3549');
    useSocIndex(had);
  });

  test('titles to code keep targets first and drop repeats', () {
    expect(
      titlesToCode(targets: ['Data Analyst', 'data analyst'], current: 'Staff Nurse', past: ['Staff nurse']),
      ['Data Analyst', 'Staff Nurse'],
    );
  });

  test('ESCO search results give 4-digit ISCO codes', () {
    const body =
        '{"_embedded":{"results":[{"title":"data analyst","code":"2511.3"},'
        '{"title":"clinical coder","_links":{"broaderIscoGroup":[{"href":"http://data.europa.eu/esco/isco/C3252"}]}},'
        '{"title":"no code"}]}}';
    expect(parseEscoSearch(body), [('data analyst', '2511'), ('clinical coder', '3252')]);
    expect(parseEscoSearch('not json'), isEmpty);
  });

  test('a UK threshold is the higher of the general floor and the going rate', () {
    final it = ukThreshold('2133', shippedUkRules)!;
    expect(it.floor, 54900);
    expect(it.newEntrantFloor, 38400);
    final tester = ukThreshold('2136', shippedUkRules)!;
    expect(tester.floor, 41700);
    expect(tester.newEntrantFloor, 33400);
    final clerk = ukThreshold('4131', shippedUkRules)!;
    expect(clerk.floor, isNull);
    expect(ukThreshold('9999', shippedUkRules), isNull);
  });

  test('every shipped SOC code has a title in the index', () {
    for (final soc in shippedUkRules.occupations.keys) {
      expect(socTitle(soc), isNotEmpty, reason: soc);
    }
  });
}

/// Reads assets from disk and counts the reads.
class _CountingBundle extends CachingAssetBundle {
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    return ByteData.sublistView(File(key).readAsBytesSync());
  }
}
