// Career signals from a helper app, through the hand-off folder
// (docs/handoff.md, "Career signals"): job alerts become jobs, statuses
// become timeline entries on the application they are about (or wait as
// suggestions when the match is not sure), and people become contacts. The
// sample file was written by a helper app's own test from made-up data;
// every person, employer and job in it is invented.
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_handoff.dart';
import 'package:udyoga/domain/handoff_signals.dart';
import 'package:udyoga/domain/pipeline.dart';
import 'package:udyoga/ui/jobs_page.dart' show sourceName;

import 'support.dart';

Future<String> _app(
  CareerBook book,
  String title,
  String company, {
  String url = '',
  Stage stage = Stage.applied,
}) async {
  final id = newId();
  await book.save(
    book.db.jobApplications,
    JobApplicationsCompanion.insert(
      id: id,
      title: title,
      company: Value(company),
      url: Value(url),
      stage: Value(stage.id),
      updated: '2026-11-01',
    ),
    id,
  );
  return id;
}

Future<String> _contact(
  CareerBook book,
  String name, {
  String linkedin = '',
  bool doNotContact = false,
}) async {
  final id = newId();
  await book.save(
    book.db.careerContacts,
    CareerContactsCompanion.insert(
      id: id,
      name: name,
      linkedin: Value(linkedin),
      doNotContact: Value(doNotContact),
    ),
    id,
  );
  return id;
}

Future<List<JobEvent>> _events(CareerBook book, String appId) =>
    (book.db.select(book.db.jobEvents)..where((e) => e.applicationId.equals(appId))).get();

void main() {
  late Directory dir;
  late CareerBook book;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('udyoga-signals-');
    book = CareerBook(await Store.open(memoryDatabase()));
  });
  tearDown(() async {
    await book.db.close();
    await dir.delete(recursive: true);
  });

  Future<HandoffReport> drop(String name, String content) async {
    final inbox = Directory('${dir.path}/inbox')..createSync(recursive: true);
    await File('${inbox.path}/$name').writeAsString(content);
    return HandoffFolder(dir.path).run(book, today: '2026-11-27');
  }

  test('the sample from a helper app: jobs, statuses, suggestions and contacts, once only', () async {
    // By the job's link; by employer and title; a sure match that ends it;
    // a weak one (a suggestion with a guess); one with no application.
    final ward = await _app(
      book,
      'Ward Coordinator',
      'Bramblewick Health',
      url: 'https://www.linkedin.com/jobs/view/4100000001/?trk=x',
    );
    final records = await _app(book, 'Records Officer', 'Fictional Records Trust Ltd');
    final rota = await _app(book, 'Rota Planner', 'Pretend Ltd', stage: Stage.interview);
    final clinic = await _app(book, 'Clinic Admin Officer', 'Example Clinics');
    final ines = await _contact(book, 'Ines Oldhire');
    await _contact(
      book,
      'Pell Connward',
      linkedin: 'https://www.linkedin.com/in/pell-connward-fake',
      doNotContact: true,
    );

    final sample = File('test/fixtures/handoff/signals.jsonl').readAsStringSync();
    final r = await drop('20261127T090000.000Z-1a2b3c4d.jsonl', sample);
    // 5 statuses (3 applied, 2 suggestions), 3 jobs, 4 people; Pell is
    // "do not contact".
    expect((r.files, r.imported, r.skipped, r.rejected), (1, 12, 1, 0));

    // Statuses: one timeline entry each.
    final w = await _events(book, ward);
    expect(w.single.summary, 'LinkedIn: Application viewed (via helper app)');
    expect(w.single.kind, 'note');
    expect((await _events(book, records)).single.summary, 'LinkedIn: Resume downloaded (via helper app)');
    expect((await book.application(rota)).stage, Stage.rejected.id);
    expect((await _events(book, rota)).single.kind, 'rejected');
    expect(await _events(book, clinic), isEmpty);

    final sugg = await book.signalSuggestions();
    expect(sugg.map((s) => (s.job.id, s.applicationId, s.state)), [
      ('4100000004', null, 'pending'),
      ('4100000005', clinic, 'pending'),
    ]);
    expect(sugg.last.score, closeTo(2 / 3, 0.01));

    // Job alerts: new jobs from the helper, through the usual import.
    final jobs = await (book.db.select(
      book.db.jobListings,
    )..where((j) => j.source.equals(helperJobSource))).get();
    expect(jobs.map((j) => j.sourceId).toSet(), {'4100000101', '4100000102', '4100000103'});
    expect(sourceName(jobs.first.source), 'LinkedIn alert via helper');
    expect(jobs.every((j) => j.url.startsWith('https://www.linkedin.com/jobs/view/')), isTrue);

    // People: new contacts, the known one updated, Pell left alone.
    final people = {for (final c in await book.db.select(book.db.careerContacts).get()) c.name: c};
    expect(people.keys.toSet(), {
      'Ines Oldhire',
      'Pell Connward',
      'Odile Fakename',
      'Wren Hollowby',
      'Tamsin Viewfield',
    });
    final tamsin = people['Tamsin Viewfield']!;
    expect(
      (tamsin.sourceKind, tamsin.company, tamsin.title),
      ('inbound', 'Bramblewick Health', 'Talent Partner at Bramblewick Health'),
    );
    expect(tamsin.notes, startsWith('Viewed your profile on '));
    expect(people['Ines Oldhire']!.id, ines);
    expect(people['Ines Oldhire']!.linkedin, 'https://www.linkedin.com/in/ines-oldhire-fake');
    expect(people['Ines Oldhire']!.notes, startsWith('Accepted your LinkedIn invitation on '));
    expect(people['Pell Connward']!.notes, isEmpty);
    final handles = await book.db.select(book.db.contactHandles).get();
    expect(handles.where((h) => h.contactId == tamsin.id).single.channel, 'linkedin');

    // The same file again: nothing doubles.
    final again = await drop('20261127T100000.000Z-1a2b3c4e.jsonl', sample);
    expect((again.imported, again.skipped), (0, 13));
    expect(await book.db.select(book.db.jobEvents).get(), hasLength(3));
    expect(await book.signalSuggestions(), hasLength(2));

    // The user answers the suggestions.
    await book.acceptSuggestion(sugg.last.id, clinic);
    expect(
      (await _events(book, clinic)).single.summary,
      'LinkedIn: Your application is with the hiring team (via helper app)',
    );
    final added = await book.addSuggestionAsApplication(sugg.first.id, today: '2026-11-27');
    final a = await book.application(added);
    expect((a.title, a.company, a.stage), ('Data Clerk', 'Sample Systems', Stage.applied.id));
    expect(a.jobId, isNotNull);
    expect((await book.job(a.jobId!)).source, helperJobSource);
    expect((await book.signalSuggestions()).every((s) => s.state == 'dismissed'), isTrue);
    // Answered suggestions are not asked again.
    final third = await drop('20261127T110000.000Z-1a2b3c4f.jsonl', sample);
    expect(third.imported, 0);
  });

  test('applied moves a prepared application on; tolerant lines; bad ones refused with the reason', () async {
    final prep = await _app(
      book,
      'Ward Clerk',
      'Bramblewick Health',
      url: 'https://www.linkedin.com/jobs/view/4100000009/',
      stage: Stage.preparing,
    );
    Map<String, Object?> line(String kind, Map<String, Object?> extra) => {
      'v': 1,
      'kind': kind,
      'source': 'linkedin',
      'id': 'linkedin:test:$kind:${extra.length}',
      'sentAt': '2026-11-26T10:00:00Z',
      'reasons': ['made up'],
      'someFutureField': {'ignored': true},
      ...extra,
    };
    final r = await drop(
      'mixed.jsonl',
      [
        line('application_status', {
          'job': {'id': '4100000009', 'title': 'Ward Clerk', 'company': 'Bramblewick Health'},
          'status': 'applied',
        }),
        line('application_status', {
          'id': 'linkedin:test:odd',
          'job': {'id': '4100000009', 'title': 'Ward Clerk'},
          'status': 'a_new_word',
          'statusText': 'Something new',
        }),
        line('job_alert', {'text': 'no job here'}),
        line('application_status', {
          'job': {'id': '1'},
        }),
        line('profile_view', {
          'peer': {'headline': 'no name'},
        }),
        line('invite_accepted', {
          'sentAt': 'yesterday',
          'peer': {'name': 'A Person'},
        }),
      ].map(jsonEncode).join('\n'),
    );
    expect((r.imported, r.rejected), (2, 4));
    final a = await book.application(prep);
    expect(a.stage, Stage.applied.id);
    expect(a.applied, '2026-11-26');
    final ev = await _events(book, prep);
    expect(ev.map((e) => e.summary).toSet(), {
      'LinkedIn: Applied (via helper app)',
      'LinkedIn: Something new (via helper app)',
    });
    final refused = File('${dir.path}/rejected/mixed.jsonl')
        .readAsLinesSync()
        .map((l) => (jsonDecode(l) as Map<String, dynamic>)['reason'])
        .toList();
    expect(refused, [
      'no "job" with a title',
      '"status" is missing',
      'no "peer" with a name',
      '"sentAt" is not an ISO 8601 time',
    ]);
  });

  test('title likeness and job ids in links', () {
    expect(titleLikeness('Sr Ward Co-ordinator', 'Senior Ward Coordinator'), 1);
    expect(titleLikeness('Rota Planner', 'Data Clerk'), 0);
    expect(jobIdInUrl('https://www.linkedin.com/jobs/view/4100000001/?refId=x'), '4100000001');
    expect(signalRowId('a'), signalRowId('a'));
    expect(signalRowId('a'), isNot(signalRowId('b')));
    expect(
      signalRowId('a'),
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')),
    );
  });
}
