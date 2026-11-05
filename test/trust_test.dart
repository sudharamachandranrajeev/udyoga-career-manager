import 'package:brahma_core/brahma_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/pipeline.dart';

import 'support.dart';

Posting _post({String id = '1', String? posted = '2026-10-20', String url = ''}) => Posting(
  source: 'reed',
  sourceId: id,
  title: 'Clinical Informatics Nurse',
  company: 'Example Health Trust',
  url: url,
  posted: posted,
);

void main() {
  group('listing trust', () {
    const today = '2026-11-05';
    ListingTrust trust({String found = '2026-11-01', String? posted, String? closing, String? reposted}) =>
        listingTrust(today: today, found: found, posted: posted, closing: closing, reposted: reposted);

    test('recent adverts are fresh', () {
      expect(trust(posted: '2026-10-30'), ListingTrust.fresh);
      expect(trust(), ListingTrust.fresh);
    });

    test('old adverts are stale, from posted date else found date', () {
      expect(trust(posted: '2026-09-01'), ListingTrust.stale);
      expect(trust(found: '2026-09-01'), ListingTrust.stale);
    });

    test('a closing date in the past is stale; a reposted advert is reposted', () {
      expect(trust(posted: '2026-11-01', closing: '2026-11-04'), ListingTrust.stale);
      expect(trust(posted: '2026-11-01', reposted: '2026-11-02'), ListingTrust.reposted);
    });
  });

  group('repost detection', () {
    late CareerBook book;
    setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
    tearDown(() => book.db.close());

    Future<String?> reposted() async => (await book.db.select(book.db.jobListings).getSingle()).reposted;

    test('the same fetch again is not a repost', () async {
      await book.importPostings([_post()], sampleProfile, today: '2026-10-24');
      await book.importPostings([_post()], sampleProfile, today: '2026-10-25');
      expect(await reposted(), isNull);
    });

    test('a new id and link on the same board is a repost, and it sticks', () async {
      await book.importPostings([_post(url: 'a')], sampleProfile, today: '2026-10-24');
      await book.importPostings([_post(id: '2', url: 'b')], sampleProfile, today: '2026-10-30');
      expect(await reposted(), '2026-10-30');
      await book.importPostings([_post(id: '2', url: 'b')], sampleProfile, today: '2026-11-02');
      expect(await reposted(), '2026-10-30');
    });

    test('a later posted date is a repost', () async {
      await book.importPostings([_post()], sampleProfile, today: '2026-10-24');
      await book.importPostings([_post(posted: '2026-10-29')], sampleProfile, today: '2026-10-30');
      expect(await reposted(), '2026-10-30');
    });
  });
}
