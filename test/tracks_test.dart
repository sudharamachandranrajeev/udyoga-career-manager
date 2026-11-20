import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/explore.dart';
import 'package:udyoga/domain/occupations.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/routes.dart';
import 'package:udyoga/domain/todos.dart';
import 'package:udyoga/domain/tracks.dart';
import 'package:udyoga/domain/work_rights.dart';
import 'package:udyoga/domain/world.dart';

import 'support.dart';

const today = '2026-11-19';

void main() {
  late CareerBook book;
  setUp(() async {
    final db = memoryDatabase();
    addTearDown(db.close);
    book = CareerBook(await Store.open(db));
  });

  test('a suggested track dates its milestones back from the TSL cut-off', () {
    const p = CandidateProfile(
      targets: Targets(countries: ['GB']),
      rights: WorkRights(passports: ['IN'], languages: [SpokenLanguage('English', LanguageLevel.native)]),
    );
    final s = screenCountry(
      worldCountry('GB')!,
      profile: p,
      today: today,
      occupations: socMatches('Clinical coder'),
      pay: const Money(42000, 'GBP'),
    );
    expect(s.tier, Tier.possible);
    final t = suggestTrack(s, today: today);
    expect(t.routeId, 'gb.skilled-worker');
    expect(t.trigger, contains('£41,700'));
    final dues = t.milestones.map((m) => m.due).whereType<String>();
    expect(dues.every((d) => d.compareTo('2026-12-31') <= 0), isTrue);
    expect(t.milestones.last.due, '2026-12-30');
  });

  test('tracks, milestones, to-dos and Today deadlines', () async {
    final id = await book.saveTrack(
      country: 'IE',
      title: 'Ireland: General Employment Permit',
      trigger: 'An offer at €36,605',
      milestones: const [
        Milestone(id: 'm1', title: 'Apply to five roles', due: '2026-12-15'),
        Milestone(id: 'm2', title: 'Undated'),
      ],
      today: today,
    );
    await book.saveTrack(
      country: 'GB',
      title: 'Paused',
      status: 'paused',
      milestones: const [Milestone(id: 'm1', title: 'Hidden', due: '2026-12-01')],
      today: today,
    );
    var tracks = await book.tracks();
    expect(tracks.first.id, id);
    expect(trackDeadlines(tracks).map((d) => d.milestone.title), ['Apply to five roles']);

    final m = milestonesOf(tracks.first).first;
    final todoId = await book.milestoneTodo(tracks.first, m, today: today);
    expect(todoId, 'todo.track.$id.m1');
    tracks = await book.tracks();
    // Asking again does not make a second to-do.
    expect(await book.milestoneTodo(tracks.first, milestonesOf(tracks.first).first, today: today), todoId);
    final todo = (await book.todos()).single;
    expect((todo.title, todo.target), ('Apply to five roles', '2026-12-15'));

    tracks = await book.tracks();
    await book.setMilestoneDone(tracks.first, milestonesOf(tracks.first).first, true, today: today);
    expect((await book.todos()).single.status, 'done');
    tracks = await book.tracks();
    expect(milestonesOf(tracks.first).first.done, today);
    expect(trackDeadlines(tracks), isEmpty);

    await book.deleteTrack(id);
    expect((await book.tracks()).map((t) => t.title), ['Paused']);
  });

  test('a schema 7 database gains career_tracks, and the upgrade can run again', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate8');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('DROP TABLE career_tracks');
    await db.customStatement('PRAGMA user_version = 7');
    await db.close();

    Future<void> upgrade() async {
      db = AppDatabase(NativeDatabase(file));
      final b = CareerBook(await Store.open(db));
      await b.saveTrack(country: 'NL', title: 'Netherlands', today: today);
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .map((r) => r.read<String>('name'))
          .get();
      expect(indexes, contains('career_tracks_country'));
      expect(await b.tracks(), isNotEmpty);
      await db.close();
    }

    await upgrade();
    db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('PRAGMA user_version = 7');
    await db.close();
    await upgrade();
  });

  test('the to-do list still lists only to-dos', () async {
    await book.saveTodo(title: 'Plain', today: today);
    expect((await book.todos()).single.kind, todoKind);
  });
}
