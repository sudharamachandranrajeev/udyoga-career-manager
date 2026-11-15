import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/book.dart';
import '../domain/post_plan.dart';
import 'check_in_reminder.dart';
import 'providers.dart';

/// Reminds the user on the device when a planned post's time comes. The
/// reminder only says it is time; the user posts.
abstract class PostReminderScheduler {
  /// Whether this platform can schedule reminders (Android).
  bool get supported;

  /// Replaces every pending post reminder with [items].
  Future<void> replaceAll(List<({DateTime at, String body})> items);
}

class LocalPostReminders implements PostReminderScheduler {
  final _reminders = LocalReminders.instance;

  @override
  bool get supported => _reminders.supported;

  @override
  Future<void> replaceAll(List<({DateTime at, String body})> items) => _reminders.replaceBlock(
    // Clear of the check-ins (0-99) and mail alerts (1000 and up, shown at
    // once).
    base: 200000,
    size: 50,
    items: items,
    details: const AndroidNotificationDetails(
      'post_plan',
      'Post plan',
      channelDescription: 'A reminder at the times you planned to post.',
    ),
  );
}

final postReminderSchedulerProvider = Provider<PostReminderScheduler>((ref) => LocalPostReminders());

/// Brings the scheduled reminders in line with the plan. Run at start and
/// after the plan changes.
Future<void> syncPostReminders(PostReminderScheduler scheduler, CareerBook book, {DateTime? now}) async {
  if (!scheduler.supported) return;
  await scheduler.replaceAll(postReminders(await book.plannedPosts(), now ?? DateTime.now()));
}

extension PostReminders on WidgetRef {
  Future<void> syncPostPlanReminders() =>
      syncPostReminders(read(postReminderSchedulerProvider), read(sessionProvider).book).catchError((_) {});
}
