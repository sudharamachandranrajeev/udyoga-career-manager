import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/app.dart';
import 'package:udyoga/app/background.dart';
import 'package:udyoga/app/modules.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/app/session.dart';
import 'package:udyoga/domain/background.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/page_reader.dart';
import 'package:udyoga/ui/site_browser.dart';

import 'support.dart';

/// The whole app over a fresh in-memory database, for widget tests.
class AppHarness {
  AppHarness(this.tester);
  final WidgetTester tester;
  late AppSession session;

  /// Stands in for the in-app web view, which needs a real platform.
  final browser = FakeSiteBrowser();

  /// Stands in for WorkManager, systemd and Task Scheduler, so no test
  /// touches the machine's own timers.
  final scheduler = FakeScheduler();

  CareerBook get book => session.book;

  /// Opens the database; [seed] runs before the app starts.
  Future<void> open({Future<void> Function(CareerBook book)? seed}) async {
    await tester.runAsync(() async {
      final store = await Store.open(memoryDatabase());
      session = AppSession(KeyVault(MemorySecretStore(), udyogaIdentity), store, CareerBook(store));
      // Past the first-run choice between this device only and sync.
      await session.db.setLocalSetting('onboarding.sync', 'done');
      await seed?.call(session.book);
    });
  }

  /// Starts the app; [overrides] stand in for more (a fake mail server),
  /// and [home] shows one widget in place of the shell.
  Future<void> run({List<Override> overrides = const [], Widget? home}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...udyogaOverrides(session, client: quietClient()),
          siteBrowserProvider.overrideWithValue(() => browser),
          backgroundSchedulerProvider.overrideWithValue(scheduler),
          ...overrides,
        ],
        retry: (_, _) => null,
        child: home == null ? const UdyogaApp() : UdyogaApp(home: home),
      ),
    );
    await settle();
  }

  Future<void> close() async {
    // Disposing the scope stops the sync and refresh timers.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => session.db.close());
  }

  /// Lets database work (real I/O) and animations finish.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> tap(Finder f) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await settle();
  }

  Future<void> tapText(String text) => tap(find.text(text).last);

  /// Types into the text field labelled [label].
  Future<void> enter(String label, String text) async {
    final f = find.widgetWithText(TextField, label).last;
    await tester.ensureVisible(f);
    await tester.enterText(f, text);
    await tester.pump();
  }

  /// Goes to a page: through the rail (desktop) or the dock (phone) to its
  /// navigation entry and, when the entry groups pages, through the entry's
  /// switch to the page.
  Future<void> go(String page) async {
    final target = allPages.where((p) => p.label == page).firstOrNull;
    final group = target == null ? null : groupOf(target.id);
    await _entry(group?.label ?? page);
    if (group == null) return;
    // On a narrow screen a crowded switch shows icons, named by tooltips.
    final pills = find.byKey(ValueKey('pills.${group.id}'));
    final label = find.descendant(of: pills, matching: find.text(page));
    await tap(
      label.evaluate().isNotEmpty ? label : find.descendant(of: pills, matching: find.byTooltip(page)),
    );
  }

  /// Goes to a navigation entry through the rail or the dock.
  Future<void> _entry(String page) async {
    final rail = find.descendant(of: find.byType(NavigationRail), matching: find.text(page));
    if (rail.evaluate().isNotEmpty) return tap(rail);
    // Phones: the dock holds every screen and scrolls to the one asked for.
    await tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Dock'),
        matching: find.byTooltip(page),
      ),
    );
  }

  void desktop() => _size(const Size(1400, 900));

  void phone() => _size(const Size(390, 844));

  void _size(Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
}

/// A site "open" in its own window, showing [current].
class FakeSiteBrowser implements SiteBrowser {
  final opened = <String>[];
  ({String url, String title, String text})? current;

  @override
  Future<Widget?> open(String url, {required String title}) async {
    opened.add(url);
    return null;
  }

  @override
  Future<({String url, String title, String text})?> page() async => opened.isEmpty ? null : current;

  /// What the page reader sees; built from [current] when not set.
  PageSnapshot? snap;
  Uint8List? canvas;

  /// Each fill asked for, as (selector, text).
  final fills = <(String, String)>[];

  @override
  Future<PageSnapshot?> snapshot() async {
    if (opened.isEmpty) return null;
    final c = current;
    return snap ?? (c == null ? null : PageSnapshot(url: c.url, title: c.title, text: c.text));
  }

  @override
  Future<Uint8List?> canvasImage() async => canvas;

  @override
  Future<Object?> fillTextBox(String selector, String text) async {
    fills.add((selector, text));
    return '{"ok": true}';
  }

  @override
  Future<void> close() async {}
}

/// A background scheduler that only remembers what it was asked.
class FakeScheduler implements BackgroundScheduler {
  final applied = <BackgroundSettings>[];

  @override
  bool get supported => true;

  @override
  String get description => 'Adds a test timer.';

  @override
  Future<bool> installed() async => applied.lastOrNull?.on ?? false;

  @override
  Future<void> apply(BackgroundSettings s) async => applied.add(s);

  @override
  Future<DateTime?> nextRun() async => null;
}
