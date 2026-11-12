// Local capability check (2026-11-12): follow-up and tracking for a made-up
// health-sector clerical candidate aiming at Leeds, with Northern Ireland as
// a backup. Each test states what the candidate needs; a failure is a gap.
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/pipeline.dart';
import 'package:udyoga/domain/profile.dart';

import 'app_harness.dart';
import 'support.dart';

const clerk = CandidateProfile(
  name: 'Jordan Example',
  headline: 'Ward clerk and medical receptionist',
  country: 'GB',
  location: 'Leeds',
  currentRole: 'Ward Clerk',
  currentEmployer: 'Example Hospital',
  yearsExperience: 7,
  experience: [
    Experience(title: 'Ward Clerk', organisation: 'Example Hospital', start: '2022-01'),
    Experience(
      title: 'Medical Receptionist',
      organisation: 'Example GP Practice',
      start: '2019-05',
      end: '2021-12',
    ),
    Experience(title: 'Retail Supervisor', organisation: 'Example Stores', start: '2016-02', end: '2019-04'),
  ],
  skills: [
    'Patient administration systems',
    'Appointment booking',
    'Medical terminology',
    'Customer service',
  ],
  targets: Targets(
    roles: ['Ward Clerk', 'Medical Secretary', 'Patient Services Administrator'],
    countries: ['GB'],
  ),
);

Posting nhs(String id, String title, String employer, String place, {String? closing}) => Posting(
  source: 'nhs',
  sourceId: id,
  title: title,
  company: employer,
  location: place,
  country: 'GB',
  salaryText: 'Band 3',
  url: 'https://example.org/vacancy/$id',
  description: 'Patient administration, appointment booking, medical records.',
  posted: '2026-11-01',
  closing: closing,
);

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
  tearDown(() => book.db.close());

  Future<String> job(Posting p) async => (await book.importPostings([p], clerk, today: '2026-11-02')).single;

  test('finds the clerical role as a good local fit', () async {
    final id = await job(nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds'));
    expect((await book.job(id)).fit, greaterThan(50));
  });

  test('a started (unsent) application keeps its closing-date reminder', () async {
    final id = await job(
      nhs('a', 'Medical Secretary', 'Example Leeds Hospitals Trust', 'Leeds', closing: '2026-11-06'),
    );
    final app = await book.applyFor(await book.job(id), today: '2026-11-03');
    final a = await book.application(app);
    expect(a.stage, Stage.preparing.id);
    // NHS adverts close early when they get enough applicants: an
    // application still being written must be chased before the closing date.
    final j = await book.job(id);
    final remindedByJob = j.status == 'saved' && j.closing != null;
    final remindedByApp = a.followUp != null && a.followUp!.compareTo('2026-11-06') < 0;
    expect(
      remindedByJob || remindedByApp,
      isTrue,
      reason: 'job status ${j.status}, application follow-up ${a.followUp}',
    );
  });

  test('the full Leeds journey: apply, chase, shortlist, interview, offer, accept', () async {
    final id = await job(nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds'));
    final app = await book.applyFor(await book.job(id), today: '2026-11-03', sent: true);
    var a = await book.application(app);
    expect((a.stage, a.applied, a.followUp), ('applied', '2026-11-03', '2026-11-13'));

    await book.logEvent(app, 'followup', at: '2026-11-13T09:30', summary: 'Emailed recruitment team');
    expect((await book.application(app)).followUp, '2026-11-20');

    await book.logEvent(app, 'reply', at: '2026-11-18T11:00', summary: 'Shortlisted');
    a = await book.application(app);
    expect((a.stage, a.followUp), ('screening', '2026-11-25'));

    await book.logEvent(app, 'interview', at: '2026-11-27T14:30', summary: 'Panel interview, Leeds');
    a = await book.application(app);
    expect((a.stage, a.followUp), ('interview', '2026-12-02'));

    await book.logEvent(app, 'offer', at: '2026-12-01T16:00', summary: 'Conditional offer');
    a = await book.application(app);
    expect((a.stage, a.followUp), ('offer', '2026-12-04'));

    await book.logEvent(app, 'accepted', at: '2026-12-03T10:00');
    a = await book.application(app);
    expect((a.stage, a.followUp), ('accepted', null));

    final events = await (book.db.select(book.db.jobEvents)..where((e) => e.applicationId.equals(app))).get();
    expect(
      events.map((e) => e.kind).toList()..sort(),
      ['accepted', 'applied', 'followup', 'interview', 'offer', 'reply']..sort(),
    );
  });

  test('an interview keeps the time it was booked for', () async {
    final id = await job(nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds'));
    final app = await book.applyFor(await book.job(id), today: '2026-11-03', sent: true);
    await book.logEvent(app, 'interview', at: '2026-11-27T14:30');
    final e = (await (book.db.select(
      book.db.jobEvents,
    )..where((e) => e.kind.equals('interview'))).get()).single;
    expect(e.at, '2026-11-27T14:30');
  });

  test('fresh word from the employer stops an application being marked No reply', () async {
    final id = await job(nhs('b', 'Patient Services Administrator', 'Example HSC Trust', 'Belfast'));
    final app = await book.applyFor(await book.job(id), today: '2026-09-01', sent: true);
    await book.logEvent(
      app,
      'reply',
      at: '2026-09-10T10:00',
      summary: 'Shortlisted, interviews to be arranged',
    );
    // A second message at the same stage: the employer is still in touch.
    await book.logEvent(app, 'reply', at: '2026-10-15T10:00', summary: 'Interview dates delayed to November');
    await book.markGhosted('2026-11-01');
    expect((await book.application(app)).stage, Stage.screening.id);
  });

  test('a rejection after interview keeps a reminder to ask for feedback', () async {
    final id = await job(nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds'));
    final app = await book.applyFor(await book.job(id), today: '2026-11-03', sent: true);
    await book.logEvent(app, 'interview', at: '2026-11-20T10:00');
    await book.logEvent(app, 'rejected', at: '2026-11-25T10:00');
    final a = await book.application(app);
    expect(a.stage, Stage.rejected.id);
    expect(a.followUp, isNotNull, reason: 'nothing prompts the candidate to ask for interview feedback');
  });

  test('accepting one offer flags the other open applications', () async {
    final leeds = await job(nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds'));
    final belfast = await job(nhs('b', 'Admin Officer', 'Example HSC Trust', 'Belfast'));
    final won = await book.applyFor(await book.job(leeds), today: '2026-11-03', sent: true);
    final other = await book.applyFor(await book.job(belfast), today: '2026-11-03', sent: true);
    await book.logEvent(won, 'offer', at: '2026-11-20T10:00');
    await book.logEvent(won, 'accepted', at: '2026-11-21T10:00');
    final o = await book.application(other);
    expect(
      o.followUpNote.toLowerCase(),
      contains('withdraw'),
      reason: 'the other application is left as it was: ${o.stage}, "${o.followUpNote}"',
    );
  });

  test('a lead is chased weekly until they reply', () async {
    await book.importLeads([
      const LeadSuggestion({
        'name': 'Sam Recruiter',
        'company': 'Example Leeds Hospitals Trust',
        'kind': 'recruiter',
      }),
    ], today: '2026-11-03');
    final l = (await book.db.select(book.db.careerContacts).get()).single;
    expect(l.followUp, '2026-11-03');
    await book.contacted(l, today: '2026-11-03');
    final after = (await book.db.select(book.db.careerContacts).get()).single;
    expect((after.status, after.followUp), ('contacted', '2026-11-10'));
  });

  test('an HSC waiting-list offer must be answered within two working days', () async {
    final id = await job(nhs('b', 'Admin Officer', 'Example HSC Trust', 'Belfast'));
    final app = await book.applyFor(await book.job(id), today: '2026-11-03', sent: true);
    await book.logEvent(app, 'interview', at: '2026-11-17T10:00');
    await book.logEvent(app, 'waitlist', at: '2026-11-20T09:00', summary: 'Ranked 3rd');
    expect((await book.application(app)).stage, Stage.waitingList.id);
    // Not chased as silent while waiting on the list.
    expect(await book.markGhosted('2027-03-01'), 0);
    // Friday offer: the deadline skips the weekend.
    await book.logEvent(app, 'offer', at: '2027-01-08T15:00');
    final a = await book.application(app);
    expect((a.stage, a.followUp), ('offer', '2027-01-12'));
    expect(a.followUpNote, contains('12 noon'));
  });

  test('accepting a conditional offer starts the pre-employment checklist', () async {
    final id = await job(nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds'));
    final app = await book.applyFor(await book.job(id), today: '2026-11-03', sent: true);
    await book.logEvent(app, 'offer', at: '2026-11-20T10:00');
    await book.logEvent(app, 'checks', at: '2026-11-20T12:00');
    final checks = await book.checks(app);
    expect(checks.map((c) => c.kind), CareerBook.offerSteps.map((s) => s.$1));
    expect(checks.first.due, '2026-11-27');
    expect(checks.last.due, isNull);
    // Moving to checks again does not duplicate the list.
    await book.moveTo(app, Stage.checks, date: '2026-11-21');
    expect(await book.checks(app), hasLength(CareerBook.offerSteps.length));
    await book.setCheck(checks.first, 'done', today: '2026-11-24');
    expect((await book.checks(app)).first.done, '2026-11-24');
  });

  test('the advert and the sent application are kept', () async {
    final id = await job(
      nhs('a', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds', closing: '2026-11-20'),
    );
    final app = await book.applyFor(await book.job(id), today: '2026-11-03');
    await book.markSent(app, today: '2026-11-05', sent: 'Supporting statement: ...');
    final a = await book.application(app);
    expect((a.stage, a.applied), ('applied', '2026-11-05'));
    final kept = await book.archived(app);
    expect(kept.map((k) => k.kind), ['advert', 'application']);
    expect(kept.first.content, contains('Closes 2026-11-20'));
    expect(kept.last.content, 'Supporting statement: ...');
  });

  test('a schema 1 database gains the checks and archive tables', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('DROP TABLE job_checks');
    await db.customStatement('DROP TABLE job_archive');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'job_%'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, containsAll(['job_checks', 'job_archive']));
    await db.close();
  });

  testWidgets('Today lists a started application whose advert closes this week', (tester) async {
    final h = AppHarness(tester)..desktop();
    final now = today();
    await h.open(
      seed: (b) async {
        final id = (await b.importPostings(
          [nhs('c', 'Medical Secretary', 'Example Leeds Hospitals Trust', 'Leeds', closing: addDays(now, 3))],
          clerk,
          today: now,
        )).single;
        await b.applyFor(await b.job(id), today: now);
      },
    );
    await h.run();
    expect(
      find.textContaining('Medical Secretary'),
      findsWidgets,
      reason: 'Today should warn that the advert closes before the application is sent',
    );
    await h.close();
  });
}
