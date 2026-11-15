import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/pay.dart';

import 'support.dart';

void main() {
  test('take-home matches the worked figures for Agenda for Change pay', () {
    // Worked by hand from 2026/27 tax, NI and NHS Pension tiers.
    expect(monthlyTakeHome(24937), closeTo(1682, 1));
    expect(monthlyTakeHome(28392), closeTo(1874, 1));
    expect(monthlyTakeHome(32073), closeTo(2040, 1));
    expect(monthlyTakeHome(60000), isNull);
  });

  test('the pay change from NI Band 3 to England Band 4, with rent', () {
    final c = PayChange(now: 24937, next: 28392, rentNow: 482, rentNext: 779);
    expect(c.grossYear, 3455);
    expect(c.grossPercent, closeTo(13.9, 0.05));
    expect(c.takeHomeMonth, closeTo(192, 2));
    expect(c.rentMonth, 297);
    expect(c.afterRentMonth, c.takeHomeMonth! - 297);
    expect(PayChange(now: 24937, next: 28392).afterRentMonth, isNull);
  });

  test('the band an advert names, and the England entry point', () {
    expect(bandIn('Band 4 £28,392 to £31,157 a year'), '4');
    expect(bandIn('AfC band 8A'), '8a');
    expect(bandIn('Bandwidth engineer'), '');
    expect(englandEntry('5'), 32073);
    expect(englandEntry('7'), isNull);
  });

  test('the pay baseline and employer research are kept', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    expect((await book.payBaseline()).isSet, isFalse);
    await book.setPayBaseline(const PayBaseline(pay: 24937, label: 'NI Band 3 entry', rentNow: 482));
    final b = await book.payBaseline();
    expect((b.pay, b.label, b.rentNow, b.rentNext), (24937, 'NI Band 3 entry', 482, null));

    expect(await book.employerBrief('Example Trust'), isNull);
    await book.saveEmployerBrief(
      'Example Trust',
      const AiResult(
        {
          'employer': 'Example NHS Trust',
          'summary': 'A teaching trust.',
          'systems': [
            {'name': 'PPM+', 'detail': 'Electronic patient record'},
          ],
          'culture': [],
          'watch': [],
          'askAtInterview': [],
        },
        sources: [(title: 'Staff survey', url: 'https://example.org/survey')],
      ),
      at: '2026-11-15T10:00',
    );
    final brief = (await book.employerBrief(' example trust'))!;
    expect(brief.employer, 'Example Trust');
    expect(brief.systems.single['name'], 'PPM+');
    expect(brief.researched, '2026-11-15T10:00');
    expect(brief.sources.single['url'], 'https://example.org/survey');
  });
}
