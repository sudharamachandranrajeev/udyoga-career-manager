/// The career file on every device: the device that has the career folder
/// publishes its app-relevant files into synced rows ([CareerFileDocs]);
/// every device applies them from there when it has no folder of its own,
/// or when the synced copy is newer. The rows travel only inside Brahma's
/// end-to-end-encrypted sync, like every other synced row.
///
/// Only an allow-list travels: `settings/udyoga.json`,
/// `settings/vidya-*.json` and `recipes/*.json`, each at most
/// [careerFileMaxBytes]. Documents, CVs, PDFs, notes and research never do.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'career_file.dart';

/// The largest file that is synced; a bigger one is skipped and reported.
const careerFileMaxBytes = 512 * 1024;

/// The Vidya plan rows made from the career file's plans start with this,
/// so Vidya can tell them from Udyoga's own plans.
const careerFilePlanPrefix = 'udyoga.career-file.';

final _plan = RegExp(r'^settings/vidya-[A-Za-z0-9._-]+\.json$');
final _recipe = RegExp(r'^recipes/[A-Za-z0-9._-]+\.json$');

/// Kinds of synced career-file rows.
abstract final class CareerFileKinds {
  static const settings = 'settings';
  static const vidyaPlan = 'vidya-plan';
  static const recipe = 'recipe';
}

/// The kind of the file at [path] (relative, forward slashes), or null when
/// it is not on the allow-list.
String? careerFileKind(String path) {
  if (path == CareerFile.relativePath) return CareerFileKinds.settings;
  if (_plan.hasMatch(path)) return CareerFileKinds.vidyaPlan;
  if (_recipe.hasMatch(path)) return CareerFileKinds.recipe;
  return null;
}

/// The Vidya plan row id for the plan at [path]: stable, so a changed file
/// updates the same plan in Vidya.
String careerFilePlanId(String path) {
  final name = path.split('/').last;
  return '$careerFilePlanPrefix${name.substring(0, name.length - '.json'.length)}';
}

String _sha(String text) => crypto.sha256.convert(utf8.encode(text)).toString();

/// What [CareerFileSync.publish] did. Paths only, never content.
class CareerFilePublish {
  CareerFilePublish({this.folder});

  /// The career folder found, or null when no folder has one.
  final String? folder;
  final List<String> sent = [], removed = [];
  int unchanged = 0;

  /// "path: why" for a file left out (too large, not text).
  final List<String> skipped = [];

  /// Files older than the synced copy another device sent, left alone.
  final List<String> keptNewer = [];
}

/// Where the settings in force came from.
enum CareerFileOrigin { none, folder, sync }

/// What the Settings page shows about the career file.
typedef CareerFileStatus = ({
  CareerFileOrigin origin,
  bool sharing,
  int files,
  String? updated,
  String device,
});

/// Device-only: where the settings last applied here came from.
const careerFileOriginKey = 'udyoga.careerfile.origin';

/// Synced: false once the candidate removed the career file from sync, so
/// no device publishes it again until they turn sharing back on.
const careerFileSharePref = 'udyoga.careerfile.share';

class CareerFileSync {
  CareerFileSync(this.book, {String? device}) : device = device ?? _deviceName();
  final CareerBook book;

  /// This device's name, stored with what it publishes.
  final String device;

  AppDatabase get db => book.db;

  static String _deviceName() {
    try {
      return Platform.isAndroid ? 'Android' : Platform.localHostname;
    } on Object {
      return Platform.operatingSystem;
    }
  }

  /// The allowed files in [dir], by relative path: direct children of
  /// `settings/` and `recipes/`, never links or anything deeper.
  static Future<Map<String, File>> allowedFiles(Directory dir) async {
    final out = <String, File>{};
    for (final sub in const ['settings', 'recipes']) {
      final d = Directory('${dir.path}${Platform.pathSeparator}$sub');
      if (!await d.exists()) continue;
      await for (final e in d.list(followLinks: false)) {
        if (e is! File) continue;
        final path = '$sub/${e.uri.pathSegments.last}';
        if (careerFileKind(path) != null) out[path] = e;
      }
    }
    return out;
  }

  /// The first of [folders] that holds any allowed file, with its files.
  static Future<(Directory, Map<String, File>)?> folderIn(List<String> folders) async {
    for (final f in folders) {
      final dir = Directory(f);
      if (!await dir.exists()) continue;
      final files = await allowedFiles(dir);
      if (files.isNotEmpty) return (dir, files);
    }
    return null;
  }

  Future<bool> sharing() => book.pref<bool>(careerFileSharePref, true);

  /// Every row, deleted ones included.
  Future<List<CareerFileDoc>> allDocs() => db.select(db.careerFileDocs).get();

  /// The live rows, by path.
  Future<Map<String, CareerFileDoc>> docs() async => {
    for (final d in await (db.select(db.careerFileDocs)..where((d) => d.deleted.not())).get()) d.path: d,
  };

  /// Writes the allowed files of the career folder among [folders] into
  /// synced rows: new or changed files (by SHA-256) only, and a row whose
  /// file is gone is tombstoned. A file older than a synced copy another
  /// device sent since is left out, so a stale clone does not undo a newer
  /// edit. Does nothing while sharing is off.
  Future<CareerFilePublish> publish(List<String> folders, {required String now}) async {
    if (!await sharing()) return CareerFilePublish();
    final found = await folderIn(folders);
    if (found == null) return CareerFilePublish();
    final (dir, files) = found;
    final report = CareerFilePublish(folder: dir.path);
    final rows = {for (final d in await allDocs()) d.path: d};
    for (final MapEntry(key: path, value: file) in files.entries) {
      final stat = await file.stat();
      if (stat.size > careerFileMaxBytes) {
        report.skipped.add('$path: larger than ${careerFileMaxBytes ~/ 1024} KB');
        continue;
      }
      final String text;
      try {
        text = await file.readAsString();
      } on FileSystemException {
        report.skipped.add('$path: not a text file');
        continue;
      }
      final sha = _sha(text);
      final row = rows[path];
      if (row != null && !row.deleted && row.sha256 == sha) {
        report.unchanged++;
        continue;
      }
      if (row != null &&
          !row.deleted &&
          row.device != device &&
          row.updated.compareTo(stat.modified.toUtc().toIso8601String()) > 0) {
        report.keptNewer.add(path);
        continue;
      }
      await book.save(
        db.careerFileDocs,
        CareerFileDocsCompanion.insert(
          id: path,
          path: path,
          kind: careerFileKind(path)!,
          sha256: sha,
          content: Value(text),
          updated: now,
          device: Value(device),
          deleted: const Value(false),
        ),
        path,
      );
      report.sent.add(path);
    }
    for (final row in rows.values) {
      if (row.deleted || files.containsKey(row.path)) continue;
      await _tombstone(row, now: now);
      report.removed.add(row.path);
    }
    return report;
  }

  /// Clears a row's content and tombstones it.
  Future<void> _tombstone(CareerFileDoc row, {required String now}) => book.save(
    db.careerFileDocs,
    row.copyWith(content: '', sha256: '', updated: now, deleted: true),
    row.id,
  );

  /// "Remove career file from sync": tombstones every row and the Vidya
  /// plans made from them, and stops every device publishing it again
  /// until [share] is turned back on. Returns how many files were removed.
  Future<int> removeAll({required String now}) async {
    await book.setPref(careerFileSharePref, false);
    var n = 0;
    for (final row in await allDocs()) {
      if (row.deleted) continue;
      await _tombstone(row, now: now);
      n++;
    }
    await syncPlans(now: now);
    return n;
  }

  /// Turns sharing back on; the next read of the folder publishes it.
  Future<void> share() => book.setPref(careerFileSharePref, true);

  /// Keeps the Vidya plan rows (bridge_study_plans) in step with the synced
  /// plans: one row per `settings/vidya-*.json`, written only when its plan
  /// differs, so devices that all run this write nothing twice; a removed
  /// file's plan row is tombstoned. Returns how many rows changed.
  Future<int> syncPlans({required String now}) async {
    var changed = 0;
    final plans = {
      for (final d in (await allDocs()).where((d) => d.kind == CareerFileKinds.vidyaPlan))
        careerFilePlanId(d.path): d,
    };
    final bridge = {
      for (final r in await db.select(db.bridgeStudyPlans).get())
        if (r.id.startsWith(careerFilePlanPrefix)) r.id: r,
    };
    for (final MapEntry(key: id, value: doc) in plans.entries) {
      final row = bridge[id];
      if (doc.deleted) {
        if (row != null && !row.deleted) {
          await book.save(db.bridgeStudyPlans, row.copyWith(plan: '{}', updated: now, deleted: true), id);
          changed++;
        }
        continue;
      }
      if (row != null && !row.deleted && row.plan == doc.content) continue;
      await book.save(
        db.bridgeStudyPlans,
        BridgeStudyPlansCompanion.insert(
          id: id,
          source: 'udyoga',
          plan: doc.content,
          updated: doc.updated,
          deleted: const Value(false),
        ),
        id,
      );
      changed++;
    }
    // A plan row whose career-file row is gone altogether.
    for (final row in bridge.values) {
      if (row.deleted || plans.containsKey(row.id)) continue;
      await book.save(db.bridgeStudyPlans, row.copyWith(plan: '{}', updated: now, deleted: true), row.id);
      changed++;
    }
    return changed;
  }

  /// The settings text to apply on this device and where it came from: the
  /// folder's file, unless the synced copy differs and is newer than it;
  /// the synced copy when there is no folder file.
  Future<({String text, CareerFileOrigin origin, String path})?> settingsSource(List<String> folders) async {
    final file = CareerFile.find(folders);
    final doc = (await docs())[CareerFile.relativePath];
    if (file != null) {
      final text = await file.readAsString();
      if (doc != null && doc.sha256 != _sha(text)) {
        final modified = (await file.lastModified()).toUtc().toIso8601String();
        if (doc.updated.compareTo(modified) > 0 && doc.device != device) {
          return (text: doc.content, origin: CareerFileOrigin.sync, path: CareerFile.relativePath);
        }
      }
      return (text: text, origin: CareerFileOrigin.folder, path: file.path);
    }
    if (doc == null) return null;
    return (text: doc.content, origin: CareerFileOrigin.sync, path: CareerFile.relativePath);
  }

  /// What the Settings page shows.
  Future<CareerFileStatus> status() async {
    final live = await docs();
    final settings = live[CareerFile.relativePath];
    final newest = live.values.fold<CareerFileDoc?>(
      null,
      (a, d) => a == null || d.updated.compareTo(a.updated) > 0 ? d : a,
    );
    final origin = switch (await db.localSetting(careerFileOriginKey)) {
      'folder' => CareerFileOrigin.folder,
      'sync' => CareerFileOrigin.sync,
      _ => settings == null ? CareerFileOrigin.none : CareerFileOrigin.sync,
    };
    return (
      origin: origin,
      sharing: await sharing(),
      files: live.length,
      updated: newest?.updated,
      device: newest?.device ?? '',
    );
  }
}

/// The career file, start to end: publishes what the folder in [folders]
/// holds (on a device that has it), applies `settings/udyoga.json` from the
/// folder or from sync, and keeps the Vidya plans in step. Called by Read
/// now, the routine refresh and after a sync brings changes. Null when the
/// settings did not change.
Future<CareerFileResult?> runCareerFile(
  CareerBook book,
  List<String> folders, {
  required String today,
  String? now,
  CareerFileSync? sync,
}) async {
  final at = now ?? DateTime.now().toUtc().toIso8601String();
  final s = sync ?? CareerFileSync(book);
  await s.publish(folders, now: at);
  return (await _applyCareerFile(book, folders, today: today, now: at, sync: s)).settings;
}

/// After a sync brought changes: applies what arrived (settings and Vidya
/// plans) without reading the folder for publishing. True when anything
/// changed here, so the screens load again.
Future<bool> applySyncedCareerFile(
  CareerBook book,
  List<String> folders, {
  required String today,
  String? now,
  CareerFileSync? sync,
}) async {
  final r = await _applyCareerFile(
    book,
    folders,
    today: today,
    now: now ?? DateTime.now().toUtc().toIso8601String(),
    sync: sync ?? CareerFileSync(book),
  );
  return r.settings != null || r.plans > 0;
}

Future<({CareerFileResult? settings, int plans})> _applyCareerFile(
  CareerBook book,
  List<String> folders, {
  required String today,
  required String now,
  required CareerFileSync sync,
}) async {
  CareerFileResult? result;
  var plans = 0;
  try {
    final source = await sync.settingsSource(folders);
    if (source != null) {
      result = await CareerFile(book).applyText(source.text, today: today, path: source.path);
      await book.db.setLocalSetting(careerFileOriginKey, source.origin.name);
    }
  } finally {
    plans = await sync.syncPlans(now: now);
  }
  return (settings: result, plans: plans);
}
