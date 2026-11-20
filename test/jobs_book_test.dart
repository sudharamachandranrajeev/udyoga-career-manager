import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/work_rights.dart';

import 'support.dart';

const today = '2026-11-19';

void main() {
  late CareerBook book;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
  });

  Future<Job> row(String id) => book.job(id);
  Future<String> hlc(String id) async => (await row(id)).hlc;

  group('importing postings', () {
    test('an unchanged posting is not written again', () async {
      final id = (await book.importPostings([samplePosting()], sampleProfile, today: today)).single;
      final before = await hlc(id);
      expect(await book.importPostings([samplePosting()], sampleProfile, today: today), isEmpty);
      expect(await hlc(id), before);
    });

    test('a changed posting is updated, keeping the status and notes', () async {
      final id = (await book.importPostings([samplePosting()], sampleProfile, today: today)).single;
      await book.setJobStatus(id, 'saved');
      final saved = await row(id);
      await book.save(book.db.jobListings, saved.copyWith(notes: 'Call the ward manager'), id);
      await book.importPostings([samplePosting(closing: '2026-12-01')], sampleProfile, today: today);
      final j = await row(id);
      expect(j.closing, '2026-12-01');
      expect(j.status, 'saved');
      expect(j.notes, 'Call the ward manager');
    });

    test('a dismissed job is never rewritten', () async {
      final id = (await book.importPostings([samplePosting()], sampleProfile, today: today)).single;
      await book.setJobStatus(id, 'dismissed');
      final before = await hlc(id);
      await book.importPostings([samplePosting(closing: '2026-12-01')], sampleProfile, today: today);
      final j = await row(id);
      expect(j.status, 'dismissed');
      expect(j.closing, isNull);
      expect(j.hlc, before);
    });

    test('a deleted job stays deleted when a feed finds it again', () async {
      final id = (await book.importPostings([samplePosting()], sampleProfile, today: today)).single;
      await book.remove(book.db.jobListings, id);
      expect(await book.importPostings([samplePosting()], sampleProfile, today: today), isEmpty);
      expect((await row(id)).deleted, isTrue);
      expect(await book.db.select(book.db.jobListings).get(), hasLength(1));
    });

    test('adding a deleted job again by hand makes a new one', () async {
      final id = (await book.importPostings(
        [samplePosting(source: 'manual')],
        sampleProfile,
        today: today,
      )).single;
      await book.remove(book.db.jobListings, id);
      final again = await book.importPostings([samplePosting(source: 'manual')], sampleProfile, today: today);
      expect(again.single, isNot(id));
    });

    test('jobs the exclusions rule out are not added', () async {
      final picky = sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(exclusions: ['bank']));
      final added = await book.importPostings(
        [
          samplePosting(title: 'Bank Staff Nurse'),
          samplePosting(id: '2', title: 'Clinical Informatics Nurse'),
        ],
        picky,
        today: today,
      );
      expect(added, hasLength(1));
      expect((await row(added.single)).title, 'Clinical Informatics Nurse');
    });

    test("the AI's score survives a refresh", () async {
      final id = (await book.importPostings([samplePosting()], sampleProfile, today: today)).single;
      await book.saveAssessment(id, const FitAssessment({'fit': 91, 'verdict': 'Apply'}));
      expect((await row(id)).fitBy, 'ai');
      await book.importPostings([samplePosting(closing: '2026-12-01')], sampleProfile, today: today);
      expect((await row(id)).fit, 91);
    });
  });

  group('rescoring', () {
    test('a profile change rescores local scores only, writing only the changed rows', () async {
      final ids = await book.importPostings(
        [samplePosting(), samplePosting(id: '2', title: 'Data Analyst', description: 'SQL and dashboards')],
        sampleProfile,
        today: today,
      );
      await book.saveTriage({ids[1]: (fit: 55, why: 'AI triage')});
      final nurse = await row(ids[0]);
      final analyst = await row(ids[1]);
      expect(analyst.fitBy, 'triage');

      // Same profile: nothing to rewrite.
      expect(await book.rescoreJobs(today: today), 0);
      expect(await hlc(ids[0]), nurse.hlc);

      await book.saveProfile(
        sampleProfile.copyWith(
          targets: sampleProfile.targets.copyWith(roles: ['Data Analyst']),
          currentRole: 'Analyst',
        ),
      );
      expect((await row(ids[0])).fit, lessThan(nurse.fit!));
      expect((await row(ids[1])).fit, 55);
      expect(await hlc(ids[1]), analyst.hlc);
    });

    test('saving rights rescores against eligibility', () async {
      final id = (await book.importPostings(
        [samplePosting(description: 'EPR systems. Applicants must have the right to work in the UK.')],
        sampleProfile,
        today: today,
      )).single;
      final before = (await row(id)).fit!;
      await book.saveWorkRights(const WorkRights(passports: ['GB']));
      expect((await row(id)).fit, greaterThanOrEqualTo(before));
      expect((await book.profile()).rights.passports, ['GB']);
    });

    test('rights live apart from the profile, so saving a profile keeps them', () async {
      await book.saveWorkRights(const WorkRights(passports: ['IE']));
      await book.saveProfile(sampleProfile.copyWith(headline: 'New headline'));
      expect((await book.profile()).rights.passports, ['IE']);
      expect(sampleProfile.toJson().containsKey('rights'), isFalse);
    });
  });

  group('reports', () {
    test('old reports past the cap are deleted, newest kept', () async {
      for (var i = 0; i < CareerBook.reportCaps['assessment']! + 3; i++) {
        await book.saveReport(
          'assessment',
          {'n': i},
          const [],
          at: '2026-11-${(i + 1).toString().padLeft(2, '0')}T10:00:00',
        );
      }
      final kept = await (book.db.select(book.db.careerReports)..where((r) => r.deleted.not())).get();
      expect(kept, hasLength(CareerBook.reportCaps['assessment']));
      expect(
        (await book.latestReport('assessment'))!.content,
        contains('"n":${CareerBook.reportCaps['assessment']! + 2}'),
      );
    });

    test('employer research keeps the newest per employer', () async {
      await book.saveReport(
        'employer',
        {'employer': 'Example Trust', 'v': 1},
        const [],
        at: '2026-11-01T10:00:00',
      );
      await book.saveReport(
        'employer',
        {'employer': 'Other Ltd', 'v': 1},
        const [],
        at: '2026-11-02T10:00:00',
      );
      await book.saveReport(
        'employer',
        {'employer': 'Example Trust', 'v': 2},
        const [],
        at: '2026-11-03T10:00:00',
      );
      final kept = await (book.db.select(book.db.careerReports)..where((r) => r.deleted.not())).get();
      expect(kept, hasLength(2));
      expect(kept.map((r) => r.content).join(), allOf(contains('"v":2'), contains('Other Ltd')));
    });
  });

  test(
    'a schema 6 database gains fit_by: assessed jobs marked ai, the rest local, and it can run again',
    () async {
      final dir = await Directory.systemTemp.createTemp('udyoga_migrate7');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      final store = await Store.open(db);
      final b = CareerBook(store);
      final ids = await b.importPostings(
        [samplePosting(), samplePosting(id: '2', title: 'Data Analyst')],
        sampleProfile,
        today: today,
      );
      await b.saveAssessment(ids[0], const FitAssessment({'fit': 88}));
      // Back to schema 6: no fit_by column.
      await db.customStatement('ALTER TABLE job_listings DROP COLUMN fit_by');
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();

      Future<Map<String, String>> fitBy() async {
        db = AppDatabase(NativeDatabase(file));
        final rows = await db.select(db.jobListings).get();
        final indexes = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
            .map((r) => r.read<String>('name'))
            .get();
        expect(indexes, containsAll(['job_listings_source', 'career_reports_kind']));
        final out = {for (final j in rows) j.title: j.fitBy};
        await db.close();
        return out;
      }

      expect(await fitBy(), {'Clinical Informatics Nurse': 'ai', 'Data Analyst': 'local'});
      // A half-finished upgrade runs again without failing.
      db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();
      expect(await fitBy(), {'Clinical Informatics Nurse': 'ai', 'Data Analyst': 'local'});
    },
  );
}
