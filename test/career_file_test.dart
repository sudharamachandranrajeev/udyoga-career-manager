import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_file.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/todos.dart';
import 'package:udyoga/domain/visa_clock.dart';
import 'package:udyoga/domain/work_rights.dart';

import 'support.dart';

const today = '2026-11-19';

/// A made-up career file, shaped like the one a candidate keeps.
Map<String, Object?> fixture({List<Map<String, Object?>>? todos}) => {
  'targets': {
    'roles': ['Clinical Informatics Nurse'],
    'keywords': ['EPR'],
    'places': ['Exampletown'],
    'radiusMiles': 20,
    'countries': ['GB'],
    'salaryFloor': 36000,
    'needsSponsorship': false,
  },
  'checkIn': {'time': '19:00'},
  'rightToWork': [
    {
      'country': 'GB',
      'status': 'Example partner visa',
      'until': '2028-03-31',
      'partnerRouteToSettlement': true,
    },
  ],
  'passport': {'country': 'IN', 'confirmed': true},
  'todos':
      todos ??
      [
        {
          'id': 'licence',
          'title': 'Renew the professional licence',
          'notes': 'Online form',
          'due': '2026-12-01',
        },
        {'id': 'cv', 'title': 'Update the CV', 'notes': '', 'due': ''},
      ],
  'watchEmployers': [
    {'id': 'example', 'name': 'Example Health Trust'},
  ],
};

void main() {
  late CareerBook book;
  late Directory folder;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
    folder = await Directory.systemTemp.createTemp('udyoga-career-file');
    addTearDown(() => folder.delete(recursive: true));
  });

  Future<void> write(Map<String, Object?> json) async {
    final f = File('${folder.path}/settings/udyoga.json');
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode(json));
  }

  group('the career file', () {
    test('applies targets, rights and to-dos', () async {
      await write(fixture());
      final r = await CareerFile(book).applyFrom([folder.path], today: today);
      expect(r, isNotNull);
      expect((r!.profile, r.rights, r.todos), (true, true, 2));

      final p = await book.profile();
      expect(p.targets.roles, ['Clinical Informatics Nurse']);
      expect(p.targets.locations, ['Exampletown']);
      expect(p.targets.salaryMin, 36000);
      expect(
        p.targets.workModes,
        sampleProfile.targets.workModes,
        reason: 'what the file does not say is kept',
      );
      expect(p.rights.passports, ['IN']);
      final rtw = p.rights.rightToWork.single;
      expect((rtw.country, rtw.status, rtw.until), ('GB', 'Example partner visa', '2028-03-31'));
      expect(rtw.notes, 'partner route to settlement: yes');

      final todos = await book.todos();
      expect(todos.map((t) => t.title), ['Renew the professional licence', 'Update the CV']);
      expect(todos.first.target, '2026-12-01');
      expect(todos.last.target, isNull);
      expect(todos.first.why, 'Online form');
    });

    test('an unchanged file is not applied twice', () async {
      await write(fixture());
      await CareerFile(book).applyFrom([folder.path], today: today);
      // The user edits a target in the app; the same file leaves it alone.
      final p = await book.profile();
      await book.saveProfile(p.copyWith(targets: p.targets.copyWith(roles: ['Digital Nurse'])));
      expect(await CareerFile(book).applyFrom([folder.path], today: today), isNull);
      expect((await book.profile()).targets.roles, ['Digital Nurse']);
    });

    test('a passport not confirmed is left out', () async {
      await write({
        ...fixture(),
        'passport': {'country': 'IN', 'confirmed': false},
      });
      await CareerFile(book).applyFrom([folder.path], today: today);
      expect((await book.workRights()).passports, isEmpty);
    });

    test('no file, no change; a broken file throws', () async {
      expect(await CareerFile(book).applyFrom([folder.path], today: today), isNull);
      final f = File('${folder.path}/settings/udyoga.json');
      await f.parent.create(recursive: true);
      await f.writeAsString('{not json');
      expect(() => CareerFile(book).applyFrom([folder.path], today: today), throwsFormatException);
    });
  });

  group('to-dos from the file', () {
    test('are imported once by id; done ones stay done; deleted ones stay deleted', () async {
      await write(fixture());
      await CareerFile(book).applyFrom([folder.path], today: today);
      final licence = (await book.todos()).firstWhere((t) => t.title.startsWith('Renew'));
      await book.setTodoDone(licence, true, today: today);
      final cv = (await book.todos()).firstWhere((t) => t.title == 'Update the CV');
      await book.remove(book.db.careerGrowth, cv.id);

      // The file changes elsewhere (a new to-do), so it is applied again.
      await write(
        fixture(
          todos: [
            {
              'id': 'licence',
              'title': 'Renew the professional licence',
              'notes': 'Online form',
              'due': '2026-12-01',
            },
            {'id': 'cv', 'title': 'Update the CV', 'notes': '', 'due': ''},
            {'id': 'course', 'title': 'Book a course', 'due': '2027-01-15'},
          ],
        ),
      );
      final r = await CareerFile(book).applyFrom([folder.path], today: today);
      expect(r!.todos, 1);
      final todos = await book.todos();
      expect(todos.map((t) => (t.title, t.status)), [
        ('Book a course', 'planned'),
        ('Renew the professional licence', 'done'),
      ]);
    });

    test("a to-do's text changes only when the file's version changes", () async {
      await book.importTodos(const [SeedTodo(id: 'a', title: 'First', due: '2026-12-01')], today: today);
      final t = (await book.todos()).single;
      await book.saveTodo(id: t.id, title: 'First, my words', due: '2026-12-05', today: today);
      // The same seed again leaves the user's edit.
      expect(
        await book.importTodos(const [SeedTodo(id: 'a', title: 'First', due: '2026-12-01')], today: today),
        0,
      );
      expect((await book.todos()).single.title, 'First, my words');
      // A new version in the file wins, but keeps whether it is done.
      await book.setTodoDone((await book.todos()).single, true, today: today);
      await book.importTodos(const [
        SeedTodo(id: 'a', title: 'First, moved', due: '2027-01-01'),
      ], today: today);
      final after = (await book.todos()).single;
      expect((after.title, after.target, after.status), ('First, moved', '2027-01-01', 'done'));
    });
  });

  group('to-dos', () {
    test('open first, soonest due first, undated last, then done', () async {
      await book.saveTodo(title: 'Undated', today: today);
      await book.saveTodo(title: 'Later', due: '2027-02-01', today: today);
      await book.saveTodo(title: 'Overdue', due: '2026-11-01', today: today);
      final done = await book.saveTodo(title: 'Finished', due: '2026-10-01', today: today);
      await book.setTodoDone((await book.todos()).firstWhere((t) => t.id == done), true, today: today);
      expect((await book.todos()).map((t) => t.title), ['Overdue', 'Later', 'Undated', 'Finished']);
    });

    test('ticking done and undone', () async {
      final id = await book.saveTodo(title: 'Call back', today: today);
      var t = (await book.todos()).single;
      await book.setTodoDone(t, true, today: today);
      t = (await book.todos()).single;
      expect((t.id, t.status, t.done, t.progress), (id, 'done', today, 100));
      await book.setTodoDone(t, false, today: today);
      t = (await book.todos()).single;
      expect(t.status, 'planned');
      expect(t.done, isNull);
    });

    test('dates must be real days', () {
      expect(isDay('2028-02-29'), isTrue);
      expect(isDay('2027-02-29'), isFalse);
      expect(isDay('2027-13-01'), isFalse);
      expect(isDay('1 March 2027'), isFalse);
    });

    test('are kept out of the learning plan', () async {
      await book.saveTodo(title: 'A task', today: today);
      expect(await book.notes(), isEmpty);
    });
  });

  group('the visa clock', () {
    const right = RightToWork(country: 'GB', status: 'Example visa', until: '2028-03-31');

    test('reminders fall 18, 12, 6 and 3 months before the end', () {
      final c = const VisaClock(right, today: today);
      expect(c.milestones.map((m) => (m.months, m.date)), [
        (18, '2026-09-30'),
        (12, '2027-03-31'),
        (6, '2027-09-30'),
        (3, '2027-12-31'),
      ]);
      expect(c.current!.months, 18);
      expect(c.next!.months, 12);
      expect(c.label, '1 year 4 months left');
    });

    test('the last weeks count in days, and an end in the past says so', () {
      expect(const VisaClock(right, today: '2028-03-01').label, '31 days left');
      expect(const VisaClock(right, today: '2028-03-31').label, '1 day left');
      expect(const VisaClock(right, today: '2028-04-01').label, 'Ended 2028-03-31');
      expect(const VisaClock(right, today: '2028-04-01').current, isNull);
    });

    test('only rights that end get a clock', () {
      const rights = WorkRights(
        rightToWork: [
          RightToWork(country: 'IE', until: '2027-06-30'),
          RightToWork(country: 'GB', status: 'Settled'),
          right,
        ],
      );
      expect(visaClocks(rights, today: today).map((c) => c.right.country), ['IE', 'GB']);
    });
  });
}
