import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mail_sync.dart';

/// Shows a phone alert for new mail from a saved contact. Only mail that
/// sync kept (from people the user saved, or replies in their threads)
/// ever gets here, and only for accounts with alerts on.
abstract class MailNotifier {
  /// Whether this platform shows alerts (Android).
  bool get supported;

  Future<void> show(List<MailAlert> alerts);
}

class LocalMailNotifier implements MailNotifier {
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
  Future<void> show(List<MailAlert> alerts) async {
    if (!supported || alerts.isEmpty) return;
    await _init();
    // One alert per thread: the newest message in it.
    final byThread = {for (final a in alerts) a.conversationId: a};
    for (final a in byThread.values) {
      await _plugin.show(
        // Ids 1000 and up, clear of the check-in reminders.
        id: 1000 + a.conversationId.hashCode.abs() % 100000,
        title: a.name,
        body: a.preview.length > 140 ? '${a.preview.substring(0, 139)}…' : a.preview,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'mail',
            'New mail from contacts',
            channelDescription: 'A new e-mail from someone you saved in Udyoga.',
          ),
        ),
      );
    }
  }
}

final mailNotifierProvider = Provider<MailNotifier>((ref) => LocalMailNotifier());
