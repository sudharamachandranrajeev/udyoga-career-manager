/// The refresh that runs while Udyoga is closed: its settings, the lock
/// that keeps it and the open app from refreshing at once, the record of
/// its last run, and the desktop schedulers (a systemd user timer on Linux,
/// a Task Scheduler entry on Windows). Android uses WorkManager instead
/// (app/background.dart). Nothing here needs Flutter, so it is tested
/// directly.
library;

import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;

import 'book.dart';
import 'json.dart';
import 'refresh.dart';
import 'todos.dart';

/// The command-line flag that runs one refresh with no window and exits.
const refreshOnceFlag = '--refresh-once';

/// Device-only keys for the background refresh.
abstract final class BackgroundKeys {
  /// {"on": bool, "minutes": int}
  static const settings = 'udyoga.background';

  /// The last background run (BackgroundRun).
  static const last = 'udyoga.background.last';

  /// The day (yyyy-MM-dd) the due to-dos were last announced, so they are
  /// announced once a day rather than on every run.
  static const todoAlert = 'udyoga.background.todo_alert';
}

/// How often the background refresh may run. Android's WorkManager will
/// not run periodic work more often than every 15 minutes.
const backgroundIntervals = <int, String>{
  15: 'Every 15 minutes',
  60: 'Every hour',
  180: 'Every 3 hours',
  360: 'Every 6 hours',
  720: 'Every 12 hours',
  1440: 'Once a day',
};

const defaultBackgroundMinutes = 360;
const minimumBackgroundMinutes = 15;

/// Whether this device refreshes in the background, and how often.
class BackgroundSettings {
  const BackgroundSettings({required this.on, this.minutes = defaultBackgroundMinutes});

  /// The default for [os]: on for Android, where WorkManager waits for a
  /// network and a battery that is not low; off on a desktop, where it
  /// means adding a timer the user should choose to add.
  factory BackgroundSettings.defaultFor(String os) => BackgroundSettings(on: os == 'android');

  factory BackgroundSettings.fromJson(Json j, {required String os}) => BackgroundSettings(
    on: j['on'] is bool ? j['on'] as bool : BackgroundSettings.defaultFor(os).on,
    minutes: (intOf(j['minutes']) ?? defaultBackgroundMinutes).clamp(minimumBackgroundMinutes, 1440),
  );

  final bool on;
  final int minutes;

  Duration get every => Duration(minutes: minutes);

  Json toJson() => {'on': on, 'minutes': minutes};

  BackgroundSettings copyWith({bool? on, int? minutes}) =>
      BackgroundSettings(on: on ?? this.on, minutes: minutes ?? this.minutes);
}

/// What the last background run did.
class BackgroundRun {
  const BackgroundRun({
    required this.at,
    required this.ok,
    required this.summary,
    this.added = 0,
    this.due = 0,
  });

  final DateTime at;

  /// False when the run itself failed (the database would not open, the
  /// refresh threw); a feed that did not answer is a problem in [summary].
  final bool ok;
  final String summary;
  final int added;
  final int due;

  factory BackgroundRun.fromJson(Json j) => BackgroundRun(
    at: DateTime.tryParse(str(j['at'])) ?? DateTime.fromMillisecondsSinceEpoch(0),
    ok: j['ok'] == true,
    summary: str(j['summary']),
    added: intOf(j['added']) ?? 0,
    due: intOf(j['due']) ?? 0,
  );

  Json toJson() => {'at': at.toIso8601String(), 'ok': ok, 'summary': summary, 'added': added, 'due': due};
}

/// The background settings and record on this device.
extension BackgroundBook on CareerBook {
  Future<BackgroundSettings> backgroundSettings({String? os}) async => BackgroundSettings.fromJson(
    decodeObject(await db.localSetting(BackgroundKeys.settings) ?? ''),
    os: os ?? Platform.operatingSystem,
  );

  Future<void> setBackgroundSettings(BackgroundSettings s) =>
      db.setLocalSetting(BackgroundKeys.settings, jsonEncode(s.toJson()));

  Future<BackgroundRun?> lastBackgroundRun() async {
    final j = decodeObject(await db.localSetting(BackgroundKeys.last) ?? '');
    return j.isEmpty ? null : BackgroundRun.fromJson(j);
  }

  Future<void> recordBackgroundRun(BackgroundRun r) =>
      db.setLocalSetting(BackgroundKeys.last, jsonEncode(r.toJson()));
}

/// When the next run is likely: [scheduled] when the scheduler said
/// (systemd does), else an interval after the last run, else null.
DateTime? nextBackgroundRun(BackgroundSettings s, BackgroundRun? last, {DateTime? scheduled}) {
  if (!s.on) return null;
  if (scheduled != null) return scheduled;
  return last?.at.add(s.every);
}

/// A lock file shared by every process on the device, so a background run
/// and the open app never refresh at the same time. Taking it is an
/// exclusive create; a lock older than [stale] (a run that crashed or was
/// killed) is broken. A long run keeps it fresh with [renew].
class RefreshLock {
  RefreshLock(this.file, {this.stale = const Duration(minutes: 45)});

  final File file;
  final Duration stale;
  String? _owner;

  /// The lock file in Udyoga's data folder [dir].
  factory RefreshLock.inFolder(String dir) => RefreshLock(File('$dir${Platform.pathSeparator}refresh.lock'));

  /// Takes the lock for [owner] ('app' or 'background'); false when a live
  /// holder has it.
  Future<bool> acquire(String owner, {DateTime? now}) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await file.parent.create(recursive: true);
        await file.create(exclusive: true);
        await file.writeAsString(
          jsonEncode({'owner': owner, 'pid': pid, 'at': (now ?? DateTime.now()).toIso8601String()}),
          flush: true,
        );
        _owner = owner;
        return true;
      } on FileSystemException {
        if (attempt > 0 || !await isStale(now: now)) return false;
        try {
          await file.delete();
        } on FileSystemException {
          // Another process broke it first; try once more.
        }
      }
    }
    return false;
  }

  /// True when the lock file is older than [stale], or unreadable.
  Future<bool> isStale({DateTime? now}) async {
    try {
      return (now ?? DateTime.now()).difference(await file.lastModified()) > stale;
    } on FileSystemException {
      return true;
    }
  }

  /// Who holds the lock ('app', 'background'), or null when nobody does.
  Future<String?> holder() async {
    try {
      final j = decodeObject(await file.readAsString());
      return str(j['owner']).isEmpty ? 'unknown' : str(j['owner']);
    } on FileSystemException {
      return null;
    }
  }

  /// Marks the lock as still in use.
  Future<void> renew() async {
    if (_owner == null) return;
    try {
      await file.setLastModified(DateTime.now());
    } on FileSystemException {
      // Gone: released elsewhere after it went stale; nothing to renew.
    }
  }

  /// Gives the lock up, if this holder still has it.
  Future<void> release() async {
    if (_owner == null) return;
    final mine = await holder() == _owner;
    _owner = null;
    if (!mine) return;
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  /// Runs [body] under the lock; null without running it when held.
  Future<T?> guard<T>(String owner, Future<T> Function() body) async {
    if (!await acquire(owner)) return null;
    try {
      return await body();
    } finally {
      await release();
    }
  }
}

/// Shows one notification: Android's notification shade, notify-send on
/// Linux. Null where there is none.
typedef Notify = Future<void> Function(String title, String body);

/// One background refresh: under the lock, the routine refresh, then a
/// notification for new jobs and (once a day) the to-dos that are due,
/// and the run recorded for Settings.
class HeadlessRefresh {
  HeadlessRefresh({required this.book, required this.refresher, required this.lock, this.notify});

  final CareerBook book;
  final Refresher refresher;
  final RefreshLock lock;
  final Notify? notify;

  Future<BackgroundRun> run({required String today, DateTime? now}) async {
    final at = now ?? DateTime.now();
    if (!await lock.acquire('background', now: at)) {
      final r = BackgroundRun(at: at, ok: true, summary: 'Skipped: Udyoga was already refreshing.');
      await book.recordBackgroundRun(r);
      return r;
    }
    try {
      final RefreshReport report;
      try {
        report = await refresher.run(today: today, onProgress: (_) => lock.renew().ignore());
      } on Object catch (e) {
        final r = BackgroundRun(at: at, ok: false, summary: describeError(e));
        await book.recordBackgroundRun(r);
        return r;
      }
      final due = [
        for (final t in await book.todos())
          if (t.status != 'done' && (t.target ?? '').isNotEmpty && t.target!.compareTo(today) <= 0) t,
      ];
      final announceDue = due.isNotEmpty && await book.db.localSetting(BackgroundKeys.todoAlert) != today;
      final body = alertText(added: report.added, due: announceDue ? due.length : 0);
      if (body != null && notify != null) {
        try {
          await notify!('Udyoga', body);
          if (announceDue) await book.db.setLocalSetting(BackgroundKeys.todoAlert, today);
        } on Object {
          // A missing notifier does not fail the refresh.
        }
      }
      final r = BackgroundRun(
        at: at,
        ok: true,
        summary: report.summary,
        added: report.added,
        due: due.length,
      );
      await book.recordBackgroundRun(r);
      return r;
    } finally {
      await lock.release();
    }
  }

  /// The notification's text, or null when there is nothing to say.
  static String? alertText({required int added, required int due}) {
    final parts = [
      if (added > 0) '$added new ${added == 1 ? 'job' : 'jobs'} to look at',
      if (due > 0) '$due ${due == 1 ? 'to-do is' : 'to-dos are'} due',
    ];
    return parts.isEmpty ? null : '${parts.join(' and ')}.';
  }
}

/// Runs a program; tests pass a fake.
typedef RunProcess = Future<ProcessResult> Function(String exe, List<String> args);

Future<ProcessResult> _processRun(String exe, List<String> args) => Process.run(exe, args);

/// Quotes [path] for a systemd ExecStart line: '%' is a specifier there,
/// and a path with spaces or quotes needs double quotes.
String systemdQuote(String path) {
  final escaped = path.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('%', '%%');
  return RegExp(r'[\s"\\]').hasMatch(path) ? '"$escaped"' : escaped;
}

/// A systemd user timer and service that run `udyoga --refresh-once`.
/// Written to ~/.config/systemd/user only when the user turns the option
/// on, and removed when they turn it off.
class SystemdTimer {
  SystemdTimer({required this.unitDir, RunProcess? run}) : _run = run ?? _processRun;

  /// $XDG_CONFIG_HOME/systemd/user, or ~/.config/systemd/user.
  factory SystemdTimer.forUser({Map<String, String>? env, RunProcess? run}) {
    final e = env ?? Platform.environment;
    final config = (e['XDG_CONFIG_HOME'] ?? '').isNotEmpty ? e['XDG_CONFIG_HOME']! : '${e['HOME']}/.config';
    return SystemdTimer(unitDir: '$config/systemd/user', run: run);
  }

  static const name = 'udyoga-refresh';

  final String unitDir;
  final RunProcess _run;

  File get serviceFile => File('$unitDir/$name.service');
  File get timerFile => File('$unitDir/$name.timer');

  static String service(String exe) =>
      '''
# Written by Udyoga (Settings > Background refresh); removed when that is
# turned off.
[Unit]
Description=Udyoga background refresh (job sites, employers, route tables)
After=graphical-session.target network-online.target

[Service]
Type=oneshot
ExecStart=${systemdQuote(exe)} $refreshOnceFlag
Nice=10
IOSchedulingClass=idle
TimeoutStartSec=30min
''';

  static String timer(Duration every) {
    final minutes = every.inMinutes.clamp(minimumBackgroundMinutes, 1440);
    // Spread the start a little, up to a tenth of the interval (at most 5 min).
    final jitter = (minutes ~/ 10).clamp(1, 5);
    return '''
# Written by Udyoga (Settings > Background refresh); removed when that is
# turned off.
[Unit]
Description=Run the Udyoga background refresh every $minutes minutes

[Timer]
OnActiveSec=2min
OnUnitActiveSec=${minutes}min
RandomizedDelaySec=${jitter}min
AccuracySec=1min

[Install]
WantedBy=timers.target
''';
  }

  /// Whether the unit files are in place.
  Future<bool> installed() async => await timerFile.exists() && await serviceFile.exists();

  /// Writes the units for [exe] and starts the timer.
  Future<void> install(String exe, Duration every) async {
    await Directory(unitDir).create(recursive: true);
    await serviceFile.writeAsString(service(exe));
    await timerFile.writeAsString(timer(every));
    await _check(['--user', 'daemon-reload']);
    await _check(['--user', 'enable', '--now', '$name.timer']);
  }

  /// Stops the timer and deletes the unit files.
  Future<void> remove() async {
    // Not loaded (never installed, or removed by hand) is fine here.
    await _run('systemctl', ['--user', 'disable', '--now', '$name.timer']);
    for (final f in [timerFile, serviceFile]) {
      if (await f.exists()) await f.delete();
    }
    await _check(['--user', 'daemon-reload']);
  }

  /// When systemd will next start the refresh, or null.
  Future<DateTime?> nextRun() async {
    try {
      final r = await _run('systemctl', [
        '--user',
        'show',
        '--timestamp=unix',
        '--property=NextElapseUSecRealtime',
        '--value',
        '$name.timer',
      ]);
      return parseSystemdTimestamp(str(r.stdout));
    } on Object {
      return null;
    }
  }

  Future<void> _check(List<String> args) async {
    final r = await _run('systemctl', args);
    if (r.exitCode != 0) {
      throw BackgroundSetupException('systemctl ${args.join(' ')} failed: ${str(r.stderr).trim()}');
    }
  }
}

/// systemd's `--timestamp=unix` form, "@1763578800"; null otherwise.
DateTime? parseSystemdTimestamp(String s) {
  final m = RegExp(r'^@(\d+)$').firstMatch(s.trim());
  return m == null ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(m[1]!) * 1000);
}

/// A Task Scheduler entry that runs `Udyoga.exe --refresh-once`, made with
/// schtasks when the user turns the option on.
class WindowsTask {
  WindowsTask({RunProcess? run}) : _run = run ?? _processRun;

  final RunProcess _run;

  static const name = r'Udyoga\Background refresh';

  /// schtasks limits the command it runs to 261 characters.
  static const maxCommand = 261;

  /// The arguments that create (or replace) the entry.
  static List<String> createArgs(String exe, Duration every) {
    final m = every.inMinutes.clamp(minimumBackgroundMinutes, 1440);
    final schedule = m % 1440 == 0
        ? ['/SC', 'DAILY', '/MO', '${m ~/ 1440}']
        : m % 60 == 0
        ? ['/SC', 'HOURLY', '/MO', '${m ~/ 60}']
        : ['/SC', 'MINUTE', '/MO', '$m'];
    final command = '"$exe" $refreshOnceFlag';
    if (command.length > maxCommand) {
      throw BackgroundSetupException('The path to Udyoga is too long for Task Scheduler ($exe).');
    }
    return ['/Create', '/F', '/TN', name, ...schedule, '/TR', command];
  }

  static List<String> deleteArgs() => ['/Delete', '/F', '/TN', name];
  static List<String> queryArgs() => ['/Query', '/TN', name];

  Future<bool> installed() async {
    try {
      return (await _run('schtasks', queryArgs())).exitCode == 0;
    } on Object {
      return false;
    }
  }

  Future<void> install(String exe, Duration every) async {
    final r = await _run('schtasks', createArgs(exe, every));
    if (r.exitCode != 0) throw BackgroundSetupException('schtasks failed: ${str(r.stderr).trim()}');
  }

  Future<void> remove() async {
    if (!await installed()) return;
    final r = await _run('schtasks', deleteArgs());
    if (r.exitCode != 0) throw BackgroundSetupException('schtasks failed: ${str(r.stderr).trim()}');
  }
}

class BackgroundSetupException implements Exception {
  BackgroundSetupException(this.message);
  final String message;
  @override
  String toString() => message;
}
