import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/app/background.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/background.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/refresh.dart';
import 'package:udyoga/domain/todos.dart';

import 'support.dart';

const today = '2026-11-19';

/// A refresh that adds [added] jobs, or throws.
class _FakeRefresher extends Refresher {
  _FakeRefresher(CareerBook book, {this.added = 0, this.fail = false})
    : super(book, MockClient((_) async => http.Response('{}', 200)));
  final int added;
  final bool fail;
  var runs = 0;

  @override
  Future<RefreshReport> run({
    required String today,
    bool force = false,
    bool ai = false,
    Progress? onProgress,
  }) async {
    runs++;
    onProgress?.call('Checking job sites…');
    if (fail) throw StateError('the feeds exploded');
    return RefreshReport()..added = added;
  }
}

/// Records each program run instead of running it.
class _Runs {
  _Runs({this.exitCode = 0, this.stdout = ''});
  final int exitCode;
  final String stdout;
  final calls = <String>[];

  Future<ProcessResult> call(String exe, List<String> args) async {
    calls.add([exe, ...args].join(' '));
    return ProcessResult(0, exitCode, stdout, exitCode == 0 ? '' : 'Unit not found.');
  }
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('udyoga-bg'));
  tearDown(() async => tmp.delete(recursive: true));

  group('the refresh lock', () {
    test('one holder at a time, and free again once released', () async {
      final a = RefreshLock.inFolder(tmp.path), b = RefreshLock.inFolder(tmp.path);
      expect(await a.acquire('app'), isTrue);
      expect(await a.holder(), 'app');
      expect(await b.acquire('background'), isFalse);
      await a.release();
      expect(await a.holder(), isNull);
      expect(await b.acquire('background'), isTrue);
      await b.release();
    });

    test('a stale lock (a run that died) is broken', () async {
      final dead = RefreshLock.inFolder(tmp.path);
      expect(await dead.acquire('background'), isTrue);
      await dead.file.setLastModified(DateTime.now().subtract(const Duration(hours: 2)));
      final app = RefreshLock.inFolder(tmp.path);
      expect(await app.isStale(), isTrue);
      expect(await app.acquire('app'), isTrue);
      expect(await app.holder(), 'app');
      // The dead run's late release leaves the new holder's lock alone.
      await dead.release();
      expect(await app.holder(), 'app');
    });

    test('a fresh lock is not broken, and renew keeps a long run fresh', () async {
      final run = RefreshLock.inFolder(tmp.path);
      await run.acquire('background');
      await run.file.setLastModified(DateTime.now().subtract(const Duration(minutes: 44)));
      await run.renew();
      final later = DateTime.now().add(const Duration(minutes: 30));
      expect(await RefreshLock.inFolder(tmp.path).acquire('app', now: later), isFalse);
    });

    test('guard runs the body only with the lock', () async {
      final held = RefreshLock.inFolder(tmp.path);
      await held.acquire('background');
      final other = RefreshLock.inFolder(tmp.path);
      expect(await other.guard('app', () async => 'ran'), isNull);
      await held.release();
      expect(await other.guard('app', () async => 'ran'), 'ran');
      expect(await other.holder(), isNull);
    });
  });

  group('the headless refresh', () {
    late CareerBook book;
    late List<String> shown;
    setUp(() async {
      book = CareerBook(await Store.open(memoryDatabase()));
      shown = [];
    });

    Future<void> notify(String title, String body) async => shown.add(body);

    test('refreshes, notifies about new jobs and records the run', () async {
      final r = await HeadlessRefresh(
        book: book,
        refresher: _FakeRefresher(book, added: 3),
        lock: RefreshLock.inFolder(tmp.path),
        notify: notify,
      ).run(today: today);
      expect(r.ok, isTrue);
      expect(r.added, 3);
      expect(shown, ['3 new jobs to look at.']);
      final last = await book.lastBackgroundRun();
      expect((last!.ok, last.added, last.summary), (true, 3, '3 new jobs'));
      expect(await RefreshLock.inFolder(tmp.path).holder(), isNull, reason: 'the lock is released');
    });

    test('due to-dos are announced once a day', () async {
      await book.saveTodo(title: 'Renew the visa paperwork', due: '2026-11-18', today: today);
      await book.saveTodo(title: 'Later', due: '2026-12-30', today: today);
      Future<BackgroundRun> run() => HeadlessRefresh(
        book: book,
        refresher: _FakeRefresher(book),
        lock: RefreshLock.inFolder(tmp.path),
        notify: notify,
      ).run(today: today);
      expect((await run()).due, 1);
      expect(shown, ['1 to-do is due.']);
      await run();
      expect(shown, hasLength(1), reason: 'not again the same day');
    });

    test('nothing new, nothing shown', () async {
      await HeadlessRefresh(
        book: book,
        refresher: _FakeRefresher(book),
        lock: RefreshLock.inFolder(tmp.path),
        notify: notify,
      ).run(today: today);
      expect(shown, isEmpty);
    });

    test('skips while the open app holds the lock', () async {
      final app = RefreshLock.inFolder(tmp.path);
      await app.acquire('app');
      final refresher = _FakeRefresher(book, added: 2);
      final r = await HeadlessRefresh(
        book: book,
        refresher: refresher,
        lock: RefreshLock.inFolder(tmp.path),
        notify: notify,
      ).run(today: today);
      expect(refresher.runs, 0);
      expect(r.summary, contains('Skipped'));
      expect(await app.holder(), 'app', reason: "the app's lock stays");
    });

    test('a refresh that throws is recorded as failed and frees the lock', () async {
      final r = await HeadlessRefresh(
        book: book,
        refresher: _FakeRefresher(book, fail: true),
        lock: RefreshLock.inFolder(tmp.path),
        notify: notify,
      ).run(today: today);
      expect(r.ok, isFalse);
      expect(r.summary, contains('exploded'));
      expect((await book.lastBackgroundRun())!.ok, isFalse);
      expect(await RefreshLock.inFolder(tmp.path).holder(), isNull);
    });

    test('a notifier that fails does not fail the run', () async {
      final r = await HeadlessRefresh(
        book: book,
        refresher: _FakeRefresher(book, added: 1),
        lock: RefreshLock.inFolder(tmp.path),
        notify: (_, _) async => throw const ProcessException('notify-send', []),
      ).run(today: today);
      expect(r.ok, isTrue);
    });

    test('the flag the schedulers pass', () {
      expect(refreshOnceFlag, '--refresh-once');
      expect(
        SystemdTimer.service('/opt/udyoga/udyoga'),
        contains('ExecStart=/opt/udyoga/udyoga --refresh-once'),
      );
      expect(
        WindowsTask.createArgs(r'C:\Udyoga\udyoga.exe', const Duration(hours: 6)).last,
        endsWith(' --refresh-once'),
      );
    });
  });

  group('settings and status', () {
    test('on by default on Android only; the interval is 6 h and never under 15 min', () {
      expect(BackgroundSettings.defaultFor('android').on, isTrue);
      expect(BackgroundSettings.defaultFor('linux').on, isFalse);
      expect(BackgroundSettings.defaultFor('windows').minutes, 360);
      expect(BackgroundSettings.fromJson({'minutes': 5}, os: 'linux').minutes, 15);
      expect(BackgroundSettings.fromJson({'on': true, 'minutes': 60}, os: 'linux').toJson(), {
        'on': true,
        'minutes': 60,
      });
      expect(backgroundIntervals.keys.reduce((a, b) => a < b ? a : b), minimumBackgroundMinutes);
    });

    test('settings and the last run are kept on this device', () async {
      final book = CareerBook(await Store.open(memoryDatabase()));
      expect((await book.backgroundSettings(os: 'linux')).on, isFalse);
      await book.setBackgroundSettings(const BackgroundSettings(on: true, minutes: 180));
      expect((await book.backgroundSettings(os: 'linux')).minutes, 180);
      expect(await book.lastBackgroundRun(), isNull);
    });

    test('the next run: the scheduler, else an interval after the last run', () {
      const on = BackgroundSettings(on: true, minutes: 360);
      final last = BackgroundRun(at: DateTime(2026, 11, 19, 9), ok: true, summary: '');
      expect(nextBackgroundRun(on, last), DateTime(2026, 11, 19, 15));
      expect(nextBackgroundRun(on, last, scheduled: DateTime(2026, 11, 19, 12)), DateTime(2026, 11, 19, 12));
      expect(nextBackgroundRun(on, null), isNull);
      expect(nextBackgroundRun(on.copyWith(on: false), last), isNull);
    });

    test('the alert text', () {
      expect(HeadlessRefresh.alertText(added: 0, due: 0), isNull);
      expect(HeadlessRefresh.alertText(added: 1, due: 2), '1 new job to look at and 2 to-dos are due.');
    });

    test('an AppImage is started by its own path, not its mount point', () {
      expect(
        launcherPath({'APPIMAGE': '/home/someone/Apps/Udyoga.AppImage'}),
        '/home/someone/Apps/Udyoga.AppImage',
      );
      expect(launcherPath(const {}), Platform.resolvedExecutable);
    });
  });

  group('the systemd user timer (Linux)', () {
    test('the unit files', () {
      final service = SystemdTimer.service('/home/someone/.local/share/udyoga/udyoga');
      expect(service, contains('Type=oneshot'));
      expect(service, contains('ExecStart=/home/someone/.local/share/udyoga/udyoga --refresh-once'));
      final timer = SystemdTimer.timer(const Duration(hours: 6));
      expect(timer, contains('OnUnitActiveSec=360min'));
      expect(timer, contains('OnActiveSec=2min'));
      expect(timer, contains('RandomizedDelaySec=5min'));
      expect(timer, contains('WantedBy=timers.target'));
      expect(SystemdTimer.timer(const Duration(minutes: 1)), contains('OnUnitActiveSec=15min'));
    });

    test('a path with spaces or % is quoted for ExecStart', () {
      expect(systemdQuote('/opt/udyoga/udyoga'), '/opt/udyoga/udyoga');
      expect(systemdQuote('/home/a b/udyoga'), '"/home/a b/udyoga"');
      expect(systemdQuote('/opt/100%/udyoga'), '/opt/100%%/udyoga');
    });

    test('lives under XDG_CONFIG_HOME, else ~/.config', () {
      expect(
        SystemdTimer.forUser(env: {'HOME': '/home/someone'}).unitDir,
        '/home/someone/.config/systemd/user',
      );
      expect(
        SystemdTimer.forUser(env: {'HOME': '/home/someone', 'XDG_CONFIG_HOME': '/cfg'}).unitDir,
        '/cfg/systemd/user',
      );
    });

    test('install writes both units and starts the timer; remove undoes it', () async {
      final runs = _Runs();
      final t = SystemdTimer(unitDir: '${tmp.path}/systemd/user', run: runs.call);
      expect(await t.installed(), isFalse);
      await t.install('/opt/udyoga/udyoga', const Duration(hours: 3));
      expect(await t.installed(), isTrue);
      expect(await t.timerFile.readAsString(), contains('OnUnitActiveSec=180min'));
      expect(runs.calls, [
        'systemctl --user daemon-reload',
        'systemctl --user enable --now udyoga-refresh.timer',
      ]);
      runs.calls.clear();
      await t.remove();
      expect(await t.installed(), isFalse);
      expect(await t.serviceFile.exists(), isFalse);
      expect(runs.calls, [
        'systemctl --user disable --now udyoga-refresh.timer',
        'systemctl --user daemon-reload',
      ]);
    });

    test('a systemctl failure is reported', () async {
      final t = SystemdTimer(unitDir: tmp.path, run: _Runs(exitCode: 1).call);
      await expectLater(
        t.install('/opt/udyoga/udyoga', const Duration(hours: 6)),
        throwsA(isA<BackgroundSetupException>()),
      );
    });

    test('reads the next run from systemd', () async {
      final t = SystemdTimer(
        unitDir: tmp.path,
        run: _Runs(stdout: '@1763578800\n').call,
      );
      expect(await t.nextRun(), DateTime.fromMillisecondsSinceEpoch(1763578800 * 1000));
      expect(parseSystemdTimestamp('n/a'), isNull);
    });
  });

  group('the Task Scheduler entry (Windows)', () {
    const exe = r'C:\Program Files\Udyoga\udyoga.exe';

    test('the schedule matches the interval', () {
      expect(WindowsTask.createArgs(exe, const Duration(minutes: 15)), [
        '/Create',
        '/F',
        '/TN',
        r'Udyoga\Background refresh',
        '/SC',
        'MINUTE',
        '/MO',
        '15',
        '/TR',
        r'"C:\Program Files\Udyoga\udyoga.exe" --refresh-once',
      ]);
      expect(WindowsTask.createArgs(exe, const Duration(hours: 6)).sublist(4, 8), [
        '/SC',
        'HOURLY',
        '/MO',
        '6',
      ]);
      expect(WindowsTask.createArgs(exe, const Duration(days: 1)).sublist(4, 8), [
        '/SC',
        'DAILY',
        '/MO',
        '1',
      ]);
    });

    test('delete and query name the same entry', () {
      expect(WindowsTask.deleteArgs(), ['/Delete', '/F', '/TN', r'Udyoga\Background refresh']);
      expect(WindowsTask.queryArgs(), ['/Query', '/TN', r'Udyoga\Background refresh']);
    });

    test('a path too long for schtasks is refused', () {
      expect(
        () => WindowsTask.createArgs('C:\\${'x' * 300}\\udyoga.exe', const Duration(hours: 6)),
        throwsA(isA<BackgroundSetupException>()),
      );
    });

    test('install and remove run schtasks', () async {
      final runs = _Runs();
      final task = WindowsTask(run: runs.call);
      await task.install(exe, const Duration(hours: 12));
      await task.remove();
      expect(
        runs.calls.first,
        startsWith(r'schtasks /Create /F /TN Udyoga\Background refresh /SC HOURLY /MO 12'),
      );
      expect(runs.calls.skip(1), [
        r'schtasks /Query /TN Udyoga\Background refresh',
        r'schtasks /Delete /F /TN Udyoga\Background refresh',
      ]);
    });

    test('removing an entry that is not there does nothing', () async {
      final runs = _Runs(exitCode: 1);
      await WindowsTask(run: runs.call).remove();
      expect(runs.calls, [r'schtasks /Query /TN Udyoga\Background refresh']);
    });
  });

  test('the uninstaller removes the Task Scheduler entry', () {
    final iss = File('windows/installer/udyoga.iss').readAsStringSync();
    expect(iss, contains('[UninstallRun]'));
    expect(iss, contains('/Delete /F /TN ""${WindowsTask.name}""'));
  });
}
