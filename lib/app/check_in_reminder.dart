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

class LocalCheckInScheduler implements CheckInScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  @override
  bool get supported => Platform.isAndroid;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> replaceAll(List<DateTime> times) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    for (var i = 0; i < times.length; i++) {
      await _plugin.zonedSchedule(
        id: i,
        title: 'Udyoga',
        body: 'How was your day? Two minutes for your check-in.',
        // The instant is what matters, so UTC is as good as the local zone;
        // each day is computed in local time, so clock changes are handled.
        scheduledDate: tz.TZDateTime.from(times[i], tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'check_in',
            'Daily check-in',
            channelDescription: 'A reminder at the time you chose to answer the day\'s question.',
          ),
        ),
        // Inexact: no exact-alarm permission needed for a daily nudge.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
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

extension CheckInReminders on WidgetRef {
  Future<void> syncReminders() =>
      syncCheckInReminders(read(checkInSchedulerProvider), read(sessionProvider).book).catchError((_) {});
}
