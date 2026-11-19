import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/look.dart';
import '../domain/background.dart';
import 'background.dart';
import 'check_in_reminder.dart';
import 'modules.dart';
import 'navigation.dart';
import 'post_reminders.dart';
import 'providers.dart';
import 'settings_page.dart';

class UdyogaApp extends StatelessWidget {
  const UdyogaApp({super.key, this.home = const _Root()});
  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Udyoga',
    debugShowCheckedModeBanner: false,
    theme: udyogaTheme(Brightness.light),
    darkTheme: udyogaTheme(Brightness.dark),
    builder: (context, child) => ShadBridge(
      child: AppLockGate(child: Backdrop(child: child ?? const SizedBox.shrink())),
    ),
    home: home,
  );
}

/// The app, opening the links the platform hands over (a scanned pairing
/// code). There is no onboarding: Today says what to do first. At start it
/// asks to renew lapsed access to a Claude or ChatGPT subscription, then offers a
/// new version when there is one.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPrompts().ignore());
  }

  Future<void> _startPrompts() async {
    for (final MapEntry(key: provider, value: cli) in subscriptionClis.entries) {
      final grant = await ref.read(grantProvider(provider).future);
      if (grant == null || grant.activeAt(DateTime.now()) || !mounted) continue;
      final next = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Renew access to your ${cli.plan} subscription?'),
          content: Text(
            'Udyoga\'s 24-hour access to ${cli.app}${grant.account.isEmpty ? '' : ' (${grant.account})'} has '
            'ended, so the AI features that use it are paused. Reconnect to check the sign-in and allow another '
            '24 hours.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 'forget'), child: const Text('Disconnect')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(context, 'renew'), child: const Text('Reconnect')),
          ],
        ),
      );
      if (!mounted) return;
      if (next == 'renew') await connectSubscription(context, ref, provider);
      if (next == 'forget') await ref.mutate((s) => s.book.setGrant(provider, null));
    }
    await _offerBackground();
    final updater = ref.read(updaterProvider);
    if (updater == null) return;
    final release = await ref.read(updateProvider.future).catchError((_) => null);
    if (release != null && mounted) await offerUpdate(context, updater, release);
  }

  /// Android: once the profile is set up, asks once whether to look for
  /// jobs while Udyoga is closed. It stays off unless the user says yes.
  Future<void> _offerBackground() async {
    final scheduler = ref.read(backgroundSchedulerProvider);
    if (scheduler is! AndroidScheduler) return;
    final book = ref.read(sessionProvider).book;
    if (!await book.shouldOfferBackground() || !mounted) return;
    await book.markBackgroundOffered();
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Look for jobs while Udyoga is closed?'),
        content: const Text(
          'Android can check your job sites every 6 hours when there is a network and the battery is not low, '
          'and tell you about new jobs and to-dos that are due. You can change this in Settings, Background '
          'refresh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Turn it on')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await ref.setBackground(const BackgroundSettings(on: true));
    } on Object catch (e) {
      if (mounted) showMessage(context, 'Could not turn it on: $e');
    }
  }

  @override
  Widget build(BuildContext context) => LinkHandler(
    child: UdyogaPalette(
      child: AppShell(
        destinations: allDestinations,
        floating: true,
        // The routine refresh: at start-up, then hourly while open (it runs
        // only what is due), and
        // the check-in reminders for the next two weeks are rescheduled,
        // with the post plan's.
        onStart: (ref) {
          Future.microtask(() => ref.read(refreshTickerProvider)).ignore();
          ref.syncReminders().ignore();
          ref.syncPostPlanReminders().ignore();
          // Android: the periodic refresh that runs while the app is closed.
          ref.syncBackground().ignore();
        },
      ),
    ),
  );
}
