// The synced career file: the device with the folder publishes the
// allow-listed files into end-to-end-encrypted rows, and a second device
// without the folder applies them. Fictional files only.
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/career_file_sync.dart';
import 'package:udyoga/domain/recipes.dart';
import 'package:udyoga/domain/todos.dart';

import 'support.dart';

const today = '2026-11-20';

/// A marker that must never appear in what the server stores.
const secret = 'Zephyrine-Example-Marker-4417';

/// The server side of sync, in memory: an append-only log per device.
class MemoryRemote implements SyncRemote {
  final log = <String, Map<int, String>>{};

  @override
  Future<bool> push(String device, int seq, String payload) async {
    final d = log.putIfAbsent(device, () => {});
    if (d.containsKey(seq)) return false;
    d[seq] = payload;
    return true;
  }

  @override
  Future<String?> fetch(String device, int seq) async => log[device]?[seq];

  @override
  Future<int> lastSeq(String device) async =>
      (log[device]?.keys ?? const <int>[]).fold<int>(0, (a, b) => a > b ? a : b);

  @override
  Future<List<String>> devices() async => log.keys.toList();

  @override
  Future<List<RemoteChange>> pull(String device, int afterSeq, {int limit = 50}) async => [
    for (final e in (log[device] ?? const <int, String>{}).entries.toList()..sort((a, b) => a.key - b.key))
      if (e.key > afterSeq) RemoteChange(e.key, e.value),
  ].take(limit).toList();
}

Map<String, Object?> settingsFixture({String role = 'Clinical Informatics Nurse'}) => {
  'targets': {
    'roles': [role],
    'places': ['Exampletown'],
    'countries': ['GB'],
    'salaryFloor': 36000,
  },
  'todos': [
    {'id': 'licence', 'title': 'Renew the example licence', 'notes': secret, 'due': '2026-12-01'},
  ],
};

Map<String, Object?> planFixture({String title = 'Example readiness'}) => {
  'format': 'vidya-curriculum',
  'version': 1,
  'program': {'title': title, 'goal': 'Be ready ($secret)'},
  'courses': [
    {
      'title': 'Example course',
      'kind': 'course',
      'topics': [
        {'title': 'First topic', 'minutes': 20},
      ],
    },
  ],
};

Map<String, Object?> recipeFixture() => {
  'id': 'example-board',
  'site': 'jobs.example.org',
  'urlPatterns': ['https://jobs.example.org/job/*'],
  'mode': 'browser-read',
  'record': 'job',
  'rate': 1,
  'dailyCap': 50,
  'detail': {
    'fields': {'title': 'h1'},
  },
};

void main() {
  late Directory folder;
  late CareerBook a, b;
  late MemoryRemote remote;
  final key = VaultCrypto.newDataKey();

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('udyoga-career-sync');
    addTearDown(() => folder.delete(recursive: true));
    a = CareerBook(await Store.open(memoryDatabase()));
    b = CareerBook(await Store.open(memoryDatabase()));
    await a.saveProfile(sampleProfile);
    await b.saveProfile(sampleProfile);
    remote = MemoryRemote();
  });

  Future<File> write(String path, Object text) async {
    final f = File('${folder.path}/$path');
    await f.parent.create(recursive: true);
    return f.writeAsString(text is String ? text : jsonEncode(text));
  }

  Future<void> sync(CareerBook book) => SyncEngine(book.store, remote, key, 'owner-1').run();

  CareerFileSync laptop() => CareerFileSync(a, device: 'laptop');
  CareerFileSync phone() => CareerFileSync(b, device: 'phone');

  Future<void> writeAll() async {
    await write('settings/udyoga.json', settingsFixture());
    await write('settings/vidya-example.json', planFixture());
    await write('recipes/example-board.json', recipeFixture());
  }

  group('publishing from the folder', () {
    test('only the allow-list becomes rows; the rest stays on the device', () async {
      await writeAll();
      await write('recipes/README.md', '# Recipes');
      await write('settings/other.json', {'x': 1});
      await write('recipes/old/nested.json', recipeFixture());
      await write('profile/cv.md', 'A CV');
      await write('research/notes.json', {'n': secret});
      await write('prep/answers.docx', 'not really a docx');
      final r = await laptop().publish([folder.path], now: '2026-11-20T09:00:00Z');
      expect(r.folder, folder.path);
      expect(r.sent..sort(), [
        'recipes/example-board.json',
        'settings/udyoga.json',
        'settings/vidya-example.json',
      ]);
      final rows = await a.db.select(a.db.careerFileDocs).get();
      expect(
        {for (final d in rows) d.path: d.kind},
        {
          'settings/udyoga.json': 'settings',
          'settings/vidya-example.json': 'vidya-plan',
          'recipes/example-board.json': 'recipe',
        },
      );
      final s = rows.firstWhere((d) => d.path == 'settings/udyoga.json');
      expect(s.content, jsonEncode(settingsFixture()));
      expect((s.device, s.updated, s.id), ('laptop', '2026-11-20T09:00:00Z', 'settings/udyoga.json'));
      expect(s.sha256, hasLength(64));
    });

    test('a file over the size cap is skipped and reported by path only', () async {
      await write('settings/udyoga.json', settingsFixture());
      await write('recipes/huge.json', '[${List.filled(140000, '"$secret"').join(',')}]');
      final r = await laptop().publish([folder.path], now: '2026-11-20T09:00:00Z');
      expect(r.sent, ['settings/udyoga.json']);
      expect(r.skipped, ['recipes/huge.json: larger than 512 KB']);
      expect(r.skipped.join(), isNot(contains(secret)));
    });

    test('an unchanged file (same SHA-256) writes nothing again', () async {
      await writeAll();
      await laptop().publish([folder.path], now: '2026-11-20T09:00:00Z');
      final before = {for (final d in await a.db.select(a.db.careerFileDocs).get()) d.id: d.hlc};
      await a.db.delete(a.db.outbox).go();
      final r = await laptop().publish([folder.path], now: '2026-11-20T10:00:00Z');
      expect(r.sent, isEmpty);
      expect(r.unchanged, 3);
      expect({for (final d in await a.db.select(a.db.careerFileDocs).get()) d.id: d.hlc}, before);
      expect(await a.db.select(a.db.outbox).get(), isEmpty);
    });

    test('a file deleted from the folder is tombstoned, its text cleared, and its Vidya plan goes', () async {
      await writeAll();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T09:00:00Z', sync: laptop());
      expect((await a.db.select(a.db.bridgeStudyPlans).get()).map((p) => (p.id, p.deleted)), [
        ('${careerFilePlanPrefix}vidya-example', false),
      ]);
      await File('${folder.path}/settings/vidya-example.json').delete();
      await File('${folder.path}/recipes/example-board.json').delete();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T10:00:00Z', sync: laptop());
      final gone = await (a.db.select(a.db.careerFileDocs)..where((d) => d.deleted)).get();
      expect(gone.map((d) => d.path).toSet(), {'settings/vidya-example.json', 'recipes/example-board.json'});
      expect(gone.map((d) => d.content).toSet(), {''});
      final plan = (await a.db.select(a.db.bridgeStudyPlans).get()).single;
      expect((plan.deleted, plan.plan), (true, '{}'));
    });

    test('a folder without any allowed file publishes and removes nothing', () async {
      await writeAll();
      await laptop().publish([folder.path], now: '2026-11-20T09:00:00Z');
      final empty = await Directory.systemTemp.createTemp('udyoga-empty');
      addTearDown(() => empty.delete(recursive: true));
      final r = await laptop().publish([empty.path], now: '2026-11-20T10:00:00Z');
      expect(r.folder, isNull);
      expect(r.removed, isEmpty);
      expect((await laptop().docs()).length, 3);
    });

    test('a broken settings file is reported without quoting it', () async {
      await write('settings/udyoga.json', '{"targets": {"roles": ["$secret"');
      await expectLater(
        runCareerFile(a, [folder.path], today: today, sync: laptop()),
        throwsA(
          isA<FormatException>()
              .having((e) => e.toString(), 'text', contains('settings/udyoga.json is not valid JSON'))
              .having((e) => e.toString(), 'text', isNot(contains(secret))),
        ),
      );
    });
  });

  group('a second device, through sync', () {
    test('gets the settings, recipes and Vidya plans with no folder of its own', () async {
      await writeAll();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T09:00:00Z', sync: laptop());
      await sync(a);
      await sync(b);

      expect(await applySyncedCareerFile(b, const [], today: today, sync: phone()), isTrue);
      final p = await b.profile();
      expect(p.targets.roles, ['Clinical Informatics Nurse']);
      expect(p.targets.salaryMin, 36000);
      expect((await b.todos()).map((t) => t.title), contains('Renew the example licence'));
      final status = await phone().status();
      expect((status.origin, status.files, status.device), (CareerFileOrigin.sync, 3, 'laptop'));

      // Recipes: no folder chosen on this device, so the synced ones load.
      final set = await savedRecipes(b.db);
      expect(set.problems, isEmpty);
      expect(set.recipes.map((r) => r.id), ['example-board']);

      // The Vidya plan row came through sync from the laptop as it is.
      final plan = (await b.db.select(b.db.bridgeStudyPlans).get()).single;
      expect((plan.id, plan.source), ('${careerFilePlanPrefix}vidya-example', 'udyoga'));
      expect(jsonDecode(plan.plan), planFixture());

      // Applying again is a no-op: same SHA, same plan.
      final outbox = (await b.db.select(b.db.outbox).get()).length;
      expect(await applySyncedCareerFile(b, const [], today: today, sync: phone()), isFalse);
      expect((await b.db.select(b.db.outbox).get()).length, outbox);
    });

    test('a changed file updates the second device; a removed plan is withdrawn there', () async {
      await writeAll();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T09:00:00Z', sync: laptop());
      await sync(a);
      await sync(b);
      await applySyncedCareerFile(b, const [], today: today, sync: phone());

      await write('settings/udyoga.json', settingsFixture(role: 'Digital Nurse Specialist'));
      await write('settings/vidya-example.json', planFixture(title: 'Example readiness, part two'));
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T10:00:00Z', sync: laptop());
      await sync(a);
      await sync(b);
      expect(await applySyncedCareerFile(b, const [], today: today, sync: phone()), isTrue);
      expect((await b.profile()).targets.roles, ['Digital Nurse Specialist']);
      final plan = (await b.db.select(b.db.bridgeStudyPlans).get()).single;
      expect((jsonDecode(plan.plan) as Map)['program'], containsPair('title', 'Example readiness, part two'));
      expect(plan.updated, '2026-11-20T10:00:00Z');

      await File('${folder.path}/settings/vidya-example.json').delete();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T11:00:00Z', sync: laptop());
      await sync(a);
      await sync(b);
      expect((await b.db.select(b.db.bridgeStudyPlans).get()).single.deleted, isTrue);
    });

    test('a newer synced copy wins over a stale folder file, which is not published over it', () async {
      // The phone also has an old copy of the folder.
      final stale = await Directory.systemTemp.createTemp('udyoga-stale');
      addTearDown(() => stale.delete(recursive: true));
      final old = File('${stale.path}/settings/udyoga.json');
      await old.parent.create(recursive: true);
      await old.writeAsString(jsonEncode(settingsFixture(role: 'Old Role')));
      await old.setLastModified(DateTime.utc(2026, 11, 1));

      await writeAll();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T09:00:00Z', sync: laptop());
      await sync(a);
      await sync(b);
      await runCareerFile(b, [stale.path], today: today, now: '2026-11-20T09:30:00Z', sync: phone());
      expect((await b.profile()).targets.roles, ['Clinical Informatics Nurse']);
      final doc = (await phone().docs())['settings/udyoga.json']!;
      expect((doc.device, doc.content), ('laptop', jsonEncode(settingsFixture())));
      expect(await b.db.localSetting(careerFileOriginKey), 'sync');
    });

    test('the server only ever holds ciphertext: no file text, path or name in clear', () async {
      await writeAll();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T09:00:00Z', sync: laptop());
      await sync(a);
      final payloads = [for (final d in remote.log.values) ...d.values];
      expect(payloads, isNotEmpty);
      for (final p in payloads) {
        expect(p, isNot(contains(secret)));
        expect(p, isNot(contains('career_file_docs')));
        expect(p, isNot(contains('udyoga.json')));
        expect(p, isNot(contains('Exampletown')));
        // Not merely encoded either.
        for (final part in p.split(RegExp(r'[^A-Za-z0-9+/=_-]+'))) {
          for (final decode in [base64.decode, base64Url.decode]) {
            try {
              expect(utf8.decode(decode(part), allowMalformed: true), isNot(contains(secret)));
            } on FormatException {
              // Not base64.
            }
          }
        }
      }
      // With the account's key the rows are there.
      final device = remote.log.keys.single;
      final opened = [
        for (final MapEntry(key: seq, value: p) in remote.log[device]!.entries)
          await VaultCrypto.open(p, key, '${VaultCrypto.version}|owner-1|$device|$seq'),
      ];
      final rows = [
        for (final o in opened)
          for (final r in (o! as Map)['rows'] as List) r as Map,
      ];
      expect(rows.where((r) => r['t'] == 'career_file_docs').length, 3);
      expect(jsonEncode(rows), contains(secret));
      // A wrong key opens nothing.
      await expectLater(
        VaultCrypto.open(
          remote.log[device]![1]!,
          VaultCrypto.newDataKey(),
          '${VaultCrypto.version}|owner-1|$device|1',
        ),
        throwsA(anything),
      );
    });

    test('Remove career file from sync tombstones every row everywhere and stops publishing', () async {
      await writeAll();
      await runCareerFile(a, [folder.path], today: today, now: '2026-11-20T09:00:00Z', sync: laptop());
      await sync(a);
      await sync(b);
      await applySyncedCareerFile(b, const [], today: today, sync: phone());

      // Removed from the phone, which has no folder.
      expect(await phone().removeAll(now: '2026-11-20T12:00:00Z'), 3);
      await sync(b);
      await sync(a);
      final rows = await a.db.select(a.db.careerFileDocs).get();
      expect(rows.map((d) => (d.deleted, d.content)).toSet(), {(true, '')});
      expect((await a.db.select(a.db.bridgeStudyPlans).get()).single.deleted, isTrue);
      expect(await laptop().sharing(), isFalse);

      // The laptop's next read publishes nothing until sharing is back on.
      final r = await runCareerFile(
        a,
        [folder.path],
        today: today,
        now: '2026-11-20T13:00:00Z',
        sync: laptop(),
      );
      expect(r, isNull, reason: 'its own settings were applied already');
      expect((await laptop().docs()), isEmpty);
      expect(await savedRecipes(b.db), isA<RecipeSet>().having((s) => s.recipes, 'recipes', isEmpty));

      await laptop().share();
      await laptop().publish([folder.path], now: '2026-11-20T14:00:00Z');
      expect((await laptop().docs()).length, 3);
    });
  });

  test('a schema 10 database gains the career file table, and the upgrade can run again', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate11');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('DROP TABLE career_file_docs');
    await db.customStatement('PRAGMA user_version = 10');
    await db.close();
    for (var i = 0; i < 2; i++) {
      db = AppDatabase(NativeDatabase(file));
      final book = CareerBook(await Store.open(db));
      await writeAll();
      await CareerFileSync(book, device: 'laptop').publish([folder.path], now: '2026-11-20T09:00:00Z');
      expect((await book.db.select(book.db.careerFileDocs).get()).length, 3);
      await db.customStatement('PRAGMA user_version = 10');
      await db.close();
    }
  });
}
