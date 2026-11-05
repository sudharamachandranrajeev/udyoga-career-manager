import 'package:brahma_core/brahma_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/ui/jobs_page.dart';

import 'support.dart';

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
  tearDown(() => book.db.close());

  test('a typed role with no link or advert is added as a manual job', () async {
    final p = manualPosting(title: '  Ward Manager ', company: 'Example Trust', country: 'GB');
    final added = await book.importPostings([p], sampleProfile, today: '2026-11-05');
    expect(added, hasLength(1));
    final job = await book.db.select(book.db.jobListings).getSingle();
    expect((job.title, job.company, job.source), ('Ward Manager', 'Example Trust', 'manual'));
  });

  test('two typed roles without links do not collide; the same link does', () async {
    final a = await book.importPostings(
      [manualPosting(title: 'Nurse'), manualPosting(title: 'Nurse')],
      sampleProfile,
      today: '2026-11-05',
    );
    expect(a, hasLength(2));
    final b = manualPosting(title: 'Analyst', url: 'https://x.example/1');
    await book.importPostings([b], sampleProfile, today: '2026-11-05');
    final again = await book.importPostings([b], sampleProfile, today: '2026-11-05');
    expect(again, isEmpty);
  });
}
