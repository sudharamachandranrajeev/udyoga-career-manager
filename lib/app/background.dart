/// The refresh that runs while Udyoga is closed, on each platform:
/// WorkManager on Android, a systemd user timer on Linux and a Task
/// Scheduler entry on Windows, each running [refreshOnce] with no window.
/// The parts that need no platform are in domain/background.dart.
library;

import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../domain/advisor.dart';
import '../domain/ats.dart';
import '../domain/background.dart';
import '../domain/refresh.dart';
import '../domain/route_refresh.dart';
import '../domain/sponsors.dart';
import 'providers.dart';
import 'session.dart';

/// WorkManager's name for the periodic refresh.
const backgroundTaskName = 'udyoga.refresh';

/// Android runs this in a fresh engine when WorkManager starts the job,
/// whether or not the app is open.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async => await refreshOnce() == 0);
}

/// One refresh with no window: opens the database with the key from the
/// system keychain, runs the routine refresh under the refresh lock,
/// notifies and records the run. Returns the process exit code.
Future<int> refreshOnce() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppSession session;
  try {
    session = await AppSession.open(KeyVault(const DeviceSecretStore(), udyogaIdentity));
  } on Object catch (e) {
    // Nothing to record into; the system log keeps it.
    debugPrint('Udyoga background refresh: could not open the database: $e');
    return 2;
  }
  final client = http.Client();
  try {
    final dir = (await getApplicationSupportDirectory()).path;
    final book = session.book;
    Advisor? advisor;
    try {
      advisor = await advisorFor(book, client);
    } on Object {
      // No usable AI: the feeds still run.
    }
    final run = await HeadlessRefresh(
      book: book,
      refresher: Refresher(
        book,
        client,
        advisor: advisor,
        sponsors: SponsorStore(Directory('$dir${Platform.pathSeparator}sponsors'), client, session.db),
        secrets: session.keys.store,
        watch: EmployerWatch(book, client),
        routes: RouteRefresh(client, session.db),
        leaseOnly: true,
      ),
      lock: RefreshLock.inFolder(dir),
      notify: platformNotify(),
    ).run(today: today());
    debugPrint('Udyoga background refresh: ${run.summary}');
    return run.ok ? 0 : 1;
  } on Object catch (e) {
    debugPrint('Udyoga background refresh failed: $e');
    return 1;
  } finally {
    client.close();
    await session.db.close();
  }
}

/// This platform's notification: the shade on Android, notify-send on
/// Linux when it is installed; null elsewhere (Windows records the run in
/// Settings only).
Notify? platformNotify() {
  if (Platform.isAndroid) return _androidNotify;
  if (Platform.isLinux) return _linuxNotify;
  return null;
}

Future<void> _androidNotify(String title, String body) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  await plugin.show(
    // Clear of the check-in reminders and the mail alerts (1000 and up).
    id: 900,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'refresh',
        'New jobs and to-dos',
        channelDescription: 'What the background refresh found while Udyoga was closed.',
      ),
    ),
  );
}

Future<void> _linuxNotify(String title, String body) async {
  final which = await Process.run('which', ['notify-send']);
  if (which.exitCode != 0) return;
  await Process.run('notify-send', ['--app-name=Udyoga', title, body]);
}

/// The path the desktop schedulers start: the AppImage itself when Udyoga
/// runs from one (its mount point changes each run), else this program.
String launcherPath([Map<String, String>? env]) {
  final appImage = (env ?? Platform.environment)['APPIMAGE'] ?? '';
  return appImage.isNotEmpty ? appImage : Platform.resolvedExecutable;
}

/// Puts this device's background refresh in place, or takes it away.
abstract class BackgroundScheduler {
  /// Whether this platform can refresh while Udyoga is closed.
  bool get supported;

  /// What turning it on does, in a few words for Settings.
  String get description;

  /// Whether the schedule is in place now (a desktop entry can be removed
  /// by hand); always true on Android, where WorkManager holds it.
  Future<bool> installed();

  /// Registers or removes the schedule to match [s].
  Future<void> apply(BackgroundSettings s);

  /// When the scheduler says the next run is, or null when it does not.
  Future<DateTime?> nextRun();
}

class AndroidScheduler implements BackgroundScheduler {
  var _ready = false;

  @override
  bool get supported => true;

  @override
  String get description =>
      'Android runs it when there is a network and the battery is not low, so it can be late.';

  @override
  Future<bool> installed() async => true;

  @override
  Future<void> apply(BackgroundSettings s) async {
    final wm = Workmanager();
    if (!_ready) {
      await wm.initialize(backgroundDispatcher);
      _ready = true;
    }
    if (!s.on) return wm.cancelByUniqueName(backgroundTaskName);
    await wm.registerPeriodicTask(
      backgroundTaskName,
      backgroundTaskName,
      frequency: s.every,
      constraints: Constraints(networkType: NetworkType.connected, requiresBatteryNotLow: true),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  @override
  Future<DateTime?> nextRun() async => null;
}

class LinuxScheduler implements BackgroundScheduler {
  LinuxScheduler(this.timer, {String? exe}) : exe = exe ?? launcherPath();
  final SystemdTimer timer;
  final String exe;

  @override
  bool get supported => true;

  @override
  String get description => 'Adds a systemd user timer (${timer.unitDir}/${SystemdTimer.name}.timer).';

  @override
  Future<bool> installed() => timer.installed();

  @override
  Future<void> apply(BackgroundSettings s) => s.on ? timer.install(exe, s.every) : timer.remove();

  @override
  Future<DateTime?> nextRun() => timer.nextRun();
}

class WindowsScheduler implements BackgroundScheduler {
  WindowsScheduler(this.task, {String? exe}) : exe = exe ?? launcherPath();
  final WindowsTask task;
  final String exe;

  @override
  bool get supported => true;

  @override
  String get description => 'Adds a Task Scheduler entry (${WindowsTask.name}).';

  @override
  Future<bool> installed() => task.installed();

  @override
  Future<void> apply(BackgroundSettings s) => s.on ? task.install(exe, s.every) : task.remove();

  @override
  Future<DateTime?> nextRun() async => null;
}

class NoScheduler implements BackgroundScheduler {
  const NoScheduler();
  @override
  bool get supported => false;
  @override
  String get description => '';
  @override
  Future<bool> installed() async => false;
  @override
  Future<void> apply(BackgroundSettings s) async {}
  @override
  Future<DateTime?> nextRun() async => null;
}

/// This platform's scheduler; tests override it.
final backgroundSchedulerProvider = Provider<BackgroundScheduler>((ref) {
  if (Platform.isAndroid) return AndroidScheduler();
  if (Platform.isLinux) return LinuxScheduler(SystemdTimer.forUser());
  if (Platform.isWindows) return WindowsScheduler(WindowsTask());
  return const NoScheduler();
});

/// The background refresh as Settings shows it.
typedef BackgroundStatus = ({
  BackgroundSettings settings,
  BackgroundRun? last,
  bool installed,
  DateTime? next,
});

final backgroundStatusProvider = FutureProvider<BackgroundStatus>((ref) async {
  ref.watch(revisionProvider);
  final book = ref.watch(sessionProvider).book;
  final scheduler = ref.watch(backgroundSchedulerProvider);
  final settings = await book.backgroundSettings();
  final last = await book.lastBackgroundRun();
  final installed = scheduler.supported && await scheduler.installed();
  final scheduled = settings.on && installed ? await scheduler.nextRun() : null;
  return (
    settings: settings,
    last: last,
    installed: installed,
    next: nextBackgroundRun(settings, last, scheduled: scheduled),
  );
});

extension BackgroundControl on WidgetRef {
  /// Saves [s] and puts the schedule in place to match; a scheduler that
  /// fails leaves the setting off and rethrows.
  Future<void> setBackground(BackgroundSettings s) async {
    final book = read(sessionProvider).book;
    try {
      await read(backgroundSchedulerProvider).apply(s);
      await book.setBackgroundSettings(s);
    } on Object {
      if (s.on) await book.setBackgroundSettings(s.copyWith(on: false));
      rethrow;
    } finally {
      changed();
    }
  }

  /// At start on Android: registers the periodic work (on by default) so it
  /// survives an update. Desktop entries change only from Settings.
  Future<void> syncBackground() async {
    final scheduler = read(backgroundSchedulerProvider);
    if (scheduler is! AndroidScheduler) return;
    await scheduler.apply(await read(sessionProvider).book.backgroundSettings()).catchError((_) {});
  }
}
