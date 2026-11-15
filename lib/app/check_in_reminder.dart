import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/companion_book.dart';
import '../domain/book.dart';
import 'providers.dart';

/// Shows the daily check-in reminder on the device itself. Nothing is sent
/// from a server.
abstract class CheckInScheduler {
  /// Whether this platform can schedule reminders (Android). On desktop
  /// the Today page asks instead, once the check-in time has passed.
  bool get supported;

  Future<bool> requestPermission();

  /// Replaces every pending reminder with one at each of [times].
  Future<void> replaceAll(List<DateTime> times);
}

/// Reminders scheduled on the device (Android). Each kind of reminder has
/// its own block of ids and replaces only those, so the check-ins and the
/// post plan never cancel each other.
class LocalReminders {
  LocalReminders._();
  static final instance = LocalReminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  bool get supported => Platform.isAndroid;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Replaces the pending reminders with ids from [base] to [base] + [size]
  /// with one for each of [items] (the first [size]).
  Future<void> replaceBlock({
    required int base,
    required int size,
    required List<({DateTime at, String body})> items,
    required AndroidNotificationDetails details,
  }) async {
    await _init();
    for (final r in await _plugin.pendingNotificationRequests()) {
      if (r.id >= base && r.id < base + size) await _plugin.cancel(id: r.id);
    }
    for (var i = 0; i < items.length && i < size; i++) {
      await _plugin.zonedSchedule(
        id: base + i,
        title: 'Udyoga',
        body: items[i].body,
        // The instant is what matters, so UTC is as good as the local zone;
        // each day is computed in local time, so clock changes are handled.
        scheduledDate: tz.TZDateTime.from(items[i].at, tz.UTC),
        notificationDetails: NotificationDetails(android: details),
        // Inexact: no exact-alarm permission needed for a nudge.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

class LocalCheckInScheduler implements CheckInScheduler {
  final _reminders = LocalReminders.instance;

  @override
  bool get supported => _reminders.supported;

  @override
  Future<bool> requestPermission() => _reminders.requestPermission();

  @override
  Future<void> replaceAll(List<DateTime> times) => _reminders.replaceBlock(
    base: 0,
    size: 100,
    items: [for (final t in times) (at: t, body: 'How was your day? Two minutes for your check-in.')],
    details: const AndroidNotificationDetails(
      'check_in',
      'Daily check-in',
      channelDescription: 'A reminder at the time you chose to answer the day\'s question.',
    ),
  );
}

final checkInSchedulerProvider = Provider<CheckInScheduler>((ref) => LocalCheckInScheduler());

/// The reminder instants for the next [days] days at [time] (HH:mm, local),
/// leaving out today when it has passed or is already answered.
List<DateTime> checkInTimes(DateTime now, String time, {required bool answeredToday, int days = 14}) {
  final parts = time.split(':');
  final hour = int.tryParse(parts.first) ?? 18, minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30;
  return [
    for (var d = 0; d < days; d++)
      if (DateTime(now.year, now.month, now.day + d, hour, minute) case final at
          when at.isAfter(now) && !(d == 0 && answeredToday))
        at,
  ];
}

/// Brings the scheduled reminders in line with the settings and today's
/// check-in. Run at start, after a check-in and when the settings change.
Future<void> syncCheckInReminders(CheckInScheduler scheduler, CareerBook book) async {
  if (!scheduler.supported) return;
  final settings = await book.checkInSettings();
  final now = DateTime.now();
  final day = now.toIso8601String().substring(0, 10);
  final answered = (await book.checkIn(day))?.entry.isNotEmpty ?? false;
  await scheduler.replaceAll(
    settings.remind ? checkInTimes(now, settings.time, answeredToday: answered) : const [],
  );
}

/// After the first check-in, asks once for leave to show the reminder (the
/// phone shows nothing without it), unless reminders are off.
Future<void> askReminderPermissionOnce(CheckInScheduler scheduler, CareerBook book) async {
  if (!scheduler.supported || !(await book.checkInSettings()).remind) return;
  if (await book.db.localSetting(LocalKeys.checkInAsked) != null) return;
  await book.db.setLocalSetting(LocalKeys.checkInAsked, 'yes');
  await scheduler.requestPermission();
}

extension CheckInReminders on WidgetRef {
  Future<void> syncReminders() =>
      syncCheckInReminders(read(checkInSchedulerProvider), read(sessionProvider).book).catchError((_) {});

  Future<void> askForReminderOnce() => askReminderPermissionOnce(
    read(checkInSchedulerProvider),
    read(sessionProvider).book,
  ).catchError((_) {});
}
