import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:udyoga/app/app.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/domain/book.dart';

import 'app_harness.dart';

import 'package:udyoga/ui/hints.dart';

import 'seed.dart';
import 'support.dart';

/// Hides the first-run tip banners and skips the start-up job refresh, so
/// the shots show the pages as a regular user sees them.
Future<void> settledLook(AppHarness app) => app.tester.runAsync(
  () => app.session.db.setLocalSetting(
    'ui.hints.dismissed',
    jsonEncode([...coreHints.keys, ...udyogaHints.keys]),
  ),
);

List<Override> shotOverrides(AppHarness app) => [
  ...udyogaOverrides(app.session, client: quietClient()),
  refreshTickerProvider.overrideWithValue(null),
];

/// Renders the main pages with the real fonts to PNG files, for checking
/// the look and for the README. Runs only when UDYOGA_SHOTS names an
/// output folder: `UDYOGA_SHOTS=/tmp/shots flutter test test/screenshots_test.dart`.
void main() {
  final out = Platform.environment['UDYOGA_SHOTS'];

  Future<void> loadFonts() async {
    Future<void> family(String name, List<String> files) async {
      final loader = FontLoader(name);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
      }
      await loader.load();
    }

    await family('Inter', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Inter-$w.ttf',
    ]);
    await family('PlusJakartaSans', [
      for (final w in ['Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/PlusJakartaSans-$w.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
  }

  testWidgets('screenshots', skip: out == null, (tester) async {
    await tester.runAsync(loadFonts);
    // Tests draw elevation as black outlines unless told otherwise.
    debugDisableShadows = false;
    final key = GlobalKey();
    var n = 0;

    Future<void> shot(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$out/${(++n).toString().padLeft(2, '0')}-$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      final app = AppHarness(tester);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      await app.open(seed: seedBook);
      await settledLook(app);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: shotOverrides(app),
            retry: (_, _) => null,
            child: const UdyogaApp(),
          ),
        ),
      );
      await app.settle();
      final mode = dark ? 'dark' : 'light';
      await shot('today-$mode');
      await app.go('Jobs');
      await shot('jobs-$mode');
      if (!dark) {
        await app.tapText('Nursing Informatics Lead');
        await shot('job-$mode');
        await tester.pageBack();
        await app.settle();
        await app.go('Applications');
        await shot('applications-$mode');
        await app.go('Interview');
        await shot('interview-$mode');
        await app.go('Career');
        await shot('career-$mode');
        await app.go('Contacts');
        await shot('contacts-$mode');
      }
      await app.close();
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    tester.view.reset();

    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      final mode = dark ? 'dark' : 'light';
      final app = AppHarness(tester)..desktop();
      await app.open(seed: seedBook);
      await settledLook(app);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: shotOverrides(app),
            retry: (_, _) => null,
            child: const UdyogaApp(),
          ),
        ),
      );
      await app.settle();
      await shot('today-desktop-$mode');
      await app.go('Jobs');
      await shot('jobs-desktop-$mode');
      await app.go('Applications');
      await shot('applications-desktop-$mode');
      await app.go('Growth');
      await shot('growth-desktop-$mode');
      await app.go('Settings');
      await shot('settings-desktop-$mode');
      await app.close();
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    debugDisableShadows = true;
  });

  /// Each of [pages] (Today first) at each of [sizes], light and dark, over
  /// [seed], drawn on a tall view so each page shows whole, into
  /// [folder]. Contacts is shown with every contact, not only those due.
  Future<void> pageShots(
    WidgetTester tester,
    String folder,
    Future<void> Function(CareerBook book) seed,
    List<(double, double)> sizes,
    List<String> pages,
  ) async {
    await tester.runAsync(loadFonts);
    debugDisableShadows = false;
    final key = GlobalKey();

    Future<void> shot(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$out/$folder/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    for (final (width, height) in sizes) {
      for (final dark in [false, true]) {
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        tester.view.physicalSize = Size(width * 2, height * 2);
        tester.view.devicePixelRatio = 2;
        final app = AppHarness(tester);
        await app.open(seed: seed);
        await settledLook(app);
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ProviderScope(
              overrides: shotOverrides(app),
              retry: (_, _) => null,
              child: const UdyogaApp(),
            ),
          ),
        );
        await app.settle();
        final tag = '${width.round()}-${dark ? 'dark' : 'light'}';
        for (final page in pages) {
          if (page != 'Today') await app.go(page);
          if (page == 'Contacts') await app.tap(find.widgetWithText(ChoiceChip, 'All'));
          await shot('${page.toLowerCase().replaceAll(' ', '-')}-$tag');
        }
        await app.close();
      }
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    tester.view.reset();
    debugDisableShadows = true;
  }

  // The worst a real book could hold (see seedWorstCase): long names, huge
  // counts and pay, a one-letter employer, non-Latin text.
  testWidgets(
    'worst-case screenshots',
    skip: out == null,
    (tester) => pageShots(
      tester,
      'worst',
      seedWorstCase,
      [(320, 2600), (360, 2600), (1400, 2200)],
      ['Today', 'Jobs', 'Contacts', 'Find people', 'LinkedIn'],
    ),
  );

  // The people pages and Today with replies waiting and someone to keep in
  // touch with.
  testWidgets(
    'people screenshots',
    skip: out == null,
    (tester) => pageShots(
      tester,
      'people',
      seedPeople,
      [(390, 1700), (1400, 1300)],
      ['Today', 'Contacts', 'Find people', 'LinkedIn'],
    ),
  );
}
