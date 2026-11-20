import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/background.dart';
import 'app/providers.dart';
import 'app/session.dart';
import 'domain/background.dart';
import 'domain/update.dart';
import 'ui/look.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // `udyoga --refresh-once`: the systemd timer or Task Scheduler entry from
  // Settings. The runner keeps the window hidden; this refreshes and exits.
  if (args.contains(refreshOnceFlag)) exit(await refreshOnce());
  // The in-app site window's title bar (back, forward, reload) runs as its
  // own Flutter engine started through main.
  if (runWebViewTitleBarWidget(args)) return;
  await _start();
}

Future<void> _start() async {
  try {
    final session = await AppSession.open(KeyVault(const DeviceSecretStore(), udyogaIdentity));
    runApp(
      ProviderScope(
        overrides: udyogaOverrides(session, updater: await _updater()),
        // Failures are shown with a retry button; silent retries would hide them.
        retry: (_, _) => null,
        child: const UdyogaApp(),
      ),
    );
  } catch (e) {
    // Also in release builds' logs, where smoke tests look for it.
    debugPrint('Udyoga startup failed: $e');
    runApp(StartupFailure(e, appName: udyogaIdentity.name, theme: udyogaTheme, onRetry: _start));
  }
}

/// Release builds on the platforms the releases publish for update themselves.
Future<Updater?> _updater() async {
  if (!kReleaseMode || !const {'android', 'windows', 'linux'}.contains(Platform.operatingSystem)) return null;
  return Updater(
    http.Client(),
    current: (await PackageInfo.fromPlatform()).version,
    os: Platform.operatingSystem,
    // Android's FileProvider shares the APK from here (res/xml/file_paths.xml).
    dir: Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}updates'),
  );
}
