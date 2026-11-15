// Local capability check (2026-11-12): follow-up and tracking for a made-up
// health-sector clerical candidate aiming at Leeds, with Northern Ireland as
// a backup. Each test states what the candidate needs; a failure is a gap.
import 'dart:async';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/answer_pack.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/listing_check.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/pipeline.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/ui/applications_page.dart';
import 'package:udyoga/ui/site_page.dart';

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

  test('the answer pack fills the NHS form sections from the profile and referees', () async {
    final referee = Lead(
      id: 'r',
      hlc: '',
      deleted: false,
      name: 'Sam Manager',
      kind: 'referee',
      title: 'Ward Manager',
      company: 'Example Hospital',
      email: 'sam@example.org',
      phone: '',
      linkedin: '',
      source: '',
      status: 'new',
      notes: '',
      sourceUrl: '',
      sourceKind: 'other',
      basis: 'legitimate_interest',
      basisNote: '',
      doNotContact: false,
    );
    final pack = answerPack(clerk, statement: 'I keep ward records accurate.', referees: [referee]);
    final byTitle = {for (final s in pack) s.title: s};
    expect(byTitle['Personal details']!.text, startsWith('Jordan Example'));
    final history = byTitle['Employment history (most recent first)']!.text;
    expect(history.indexOf('Ward Clerk'), lessThan(history.indexOf('Retail Supervisor')));
    expect(history, contains('2022-01 to present'));
    expect(byTitle['Supporting information']!.text, 'I keep ward records accurate.');
    expect(byTitle['References']!.text, contains('Sam Manager\nWard Manager, Example Hospital'));
    expect(byTitle.containsKey('Gaps in employment to explain'), isFalse, reason: 'no gap over 3 months');
    expect(packText(pack), contains('Supporting information\nI keep ward records accurate.'));

    final bare = answerPack(clerk);
    expect(bare.firstWhere((s) => s.title == 'References').ready, isFalse);
    expect(bare.firstWhere((s) => s.title == 'References').missing, contains('Referee'));
  });

  test('employment gaps over three months are listed to explain', () {
    expect(
      employmentGaps(const [
        Experience(title: 'A', start: '2016-02', end: '2019-04'),
        Experience(title: 'B', start: '2014-01', end: '2015-06'),
        Experience(title: 'C', start: '2019-06'),
      ]),
      ['2015-07 to 2016-01'],
    );
  });

  testWidgets('applies on the site in Udyoga: answers beside it, page copy kept, marked sent', (
    tester,
  ) async {
    final h = AppHarness(tester)..desktop();
    late String appId;
    await h.open(
      seed: (b) async {
        await b.saveProfile(clerk);
        final id = (await b.importPostings(
          [nhs('d', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds', closing: addDays(today(), 10))],
          clerk,
          today: today(),
        )).single;
        appId = await b.applyFor(await b.job(id), today: today());
        await b.save(
          b.db.careerContacts,
          const CareerContactsCompanion(id: Value('r'), name: Value('Sam Manager'), kind: Value('referee')),
          'r',
        );
      },
    );
    await h.run();
    h.browser.current = (
      url: 'https://example.org/vacancy/d',
      title: 'Ward Clerk - NHS Jobs',
      text: 'Ward Clerk. Closing date 10 days away.',
    );
    unawaited(
      openSite(
        tester.element(find.byType(Scaffold).first),
        url: 'https://example.org/vacancy/d',
        title: 'Ward Clerk',
        applicationId: appId,
      ),
    );
    await h.settle();
    expect(h.browser.opened, ['https://example.org/vacancy/d']);
    expect(find.text('Employment history (most recent first)'), findsOneWidget);
    expect(find.textContaining('Sam Manager'), findsOneWidget);

    await h.tap(find.byTooltip('Keep a copy of this page'));
    await h.tapText('I have submitted it');
    await h.tapText('It is sent');

    late JobApplication a;
    late List<Archived> kept;
    await tester.runAsync(() async {
      a = await h.book.application(appId);
      kept = await h.book.archived(appId);
    });
    expect(a.stage, 'applied');
    expect(a.applied, today());
    expect(kept.map((k) => k.kind), containsAll(['advert', 'application']));
    expect(
      kept.firstWhere((k) => k.content.startsWith('Ward Clerk. Closing')).url,
      'https://example.org/vacancy/d',
    );
    expect(kept.firstWhere((k) => k.kind == 'application').content, contains('Sam Manager'));
    await h.close();
  });

  testWidgets('saves the HSC job on screen from the in-app browser', (tester) async {
    final h = AppHarness(tester)..desktop();
    await h.open(seed: (b) => b.saveProfile(clerk));
    await h.run();
    h.browser.current = (
      url: 'https://jobs.hscni.net/Job/12345/ward-clerk',
      title: 'Ward Clerk | HSC Jobs',
      text: 'Ward Clerk, Belfast. Band 3. Closing date 1 December 2026.',
    );
    unawaited(
      openSite(
        tester.element(find.byType(Scaffold).first),
        url: 'https://jobs.hscni.net/',
        title: 'HSC Jobs',
      ),
    );
    await h.settle();
    await h.tap(find.byTooltip('Save this job'));
    late List<Job> jobs;
    await tester.runAsync(() async => jobs = await h.book.db.select(h.book.db.jobListings).get());
    final saved = jobs.single;
    expect(saved.title, 'Ward Clerk');
    expect(saved.status, 'saved');
    expect(saved.url, 'https://jobs.hscni.net/Job/12345/ward-clerk');
    expect(saved.description, contains('Belfast'));

    await h.tap(find.byTooltip('Save this job'));
    await tester.runAsync(() async => jobs = await h.book.db.select(h.book.db.jobListings).get());
    expect(jobs, hasLength(1), reason: 'saving the same page twice keeps one job');
    await h.close();
  });

  testWidgets('the offer checklist and kept copies are managed on the application', (tester) async {
    final h = AppHarness(tester)..desktop();
    late String appId;
    final now = today();
    await h.open(
      seed: (b) async {
        await b.saveProfile(clerk);
        final id = (await b.importPostings(
          [nhs('e', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds', closing: addDays(now, 10))],
          clerk,
          today: now,
        )).single;
        appId = await b.applyFor(await b.job(id), today: now, sent: true);
        await b.moveTo(appId, Stage.offer, date: now);
        await b.moveTo(appId, Stage.checks, date: now);
      },
    );
    await h.run();
    // Forms are due in 5 working days: not on Today yet.
    expect(find.text('Offer checks due'), findsNothing);

    unawaited(
      Navigator.of(tester.element(find.byType(Scaffold).first))
          .push(MaterialPageRoute<void>(builder: (_) => ApplicationPage(appId))),
    );
    await h.settle();
    expect(find.text('Offer and checks'), findsOneWidget);
    expect(find.text('0 of 9 done'), findsOneWidget);

    await h.tap(find.textContaining('Identity and right to work').first);
    await h.tap(find.text('To do').last);
    await h.tapText('Done');
    await h.tapText('Save');
    expect(find.text('1 of 9 done'), findsOneWidget);

    await h.tap(find.text('Advert').first);
    expect(find.textContaining('Patient administration, appointment booking'), findsOneWidget);
    expect(find.byTooltip('Copy the text'), findsOneWidget);

    late List<JobCheck> checks;
    await tester.runAsync(() async => checks = await h.book.checks(appId));
    expect(checks.firstWhere((c) => c.kind == 'identity').status, 'done');
    expect(checks.firstWhere((c) => c.kind == 'identity').done, now);
    await h.close();
  });

  testWidgets('Today lists offer checks due in the next two days', (tester) async {
    final h = AppHarness(tester)..desktop();
    final now = today();
    await h.open(
      seed: (b) async {
        final id = (await b.importPostings(
          [nhs('f', 'Medical Secretary', 'Example Leeds Hospitals Trust', 'Leeds')],
          clerk,
          today: now,
        )).single;
        final app = await b.applyFor(await b.job(id), today: now, sent: true);
        await b.addCheck(app, kind: 'other', title: 'Send the FRMPEC4 declaration', due: addDays(now, 1));
        await b.addCheck(app, kind: 'other', title: 'Book the uniform fitting', due: addDays(now, 9));
      },
    );
    await h.run();
    expect(find.text('Offer checks due'), findsOneWidget);
    expect(find.text('Send the FRMPEC4 declaration'), findsOneWidget);
    expect(find.text('Book the uniform fitting'), findsNothing);
    await h.close();
  });

  test('flags closed, stale and suspicious listings, and trusts official sites', () async {
    Future<Job> add(Posting p) async => book.job(await job(p));

    final live = checkListing(
      await add(nhs('g', 'Ward Clerk', 'Example Leeds Hospitals Trust', 'Leeds', closing: '2026-11-20')),
      today: '2026-11-12',
    );
    expect(live.official, isTrue);
    expect(live.clear, isTrue);

    final closed = checkListing(
      await add(nhs('h', 'Medical Secretary', 'Example Trust', 'Leeds', closing: '2026-11-10')),
      today: '2026-11-12',
    );
    expect(closed.problems.single, contains('Closed'));

    final hsc = checkListing(
      await add(
        const Posting(
          source: 'manual',
          sourceId: 'x',
          title: 'Admin Officer',
          company: 'Belfast Trust',
          url: 'https://jobs.hscni.net/Job/1/admin-officer',
          posted: '2026-11-01',
        ),
      ),
      today: '2026-11-12',
    );
    expect(hsc.official, isTrue);

    final stale = checkListing(
      await add(
        const Posting(
          source: 'reed',
          sourceId: 'old',
          title: 'Receptionist',
          company: 'Example Clinic',
          posted: '2026-09-01',
        ),
      ),
      today: '2026-11-12',
    );
    expect(stale.official, isFalse);
    expect(stale.cautions.single, contains('no closing date'));

    final scam = checkListing(
      await add(
        const Posting(
          source: 'adzuna',
          sourceId: 'scam',
          title: 'NHS Admin Assistant, start today',
          company: 'Health Staffing',
          description:
              'No interview. Pay the DBS registration fee and send your bank details '
              'to hr.healthjobs@gmail.com or message us on WhatsApp.',
          posted: '2026-11-10',
        ),
      ),
      today: '2026-11-12',
    );
    expect(scam.cautions, hasLength(5), reason: scam.cautions.join('\n'));
  });
}
