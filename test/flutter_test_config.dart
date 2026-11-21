import 'dart:async';
import 'dart:io';

import 'package:udyoga/domain/occupations.dart';

/// Runs before every test file: loads the shipped SOC coding index from the
/// asset on disk, as the app does at first use, so the synchronous SOC
/// lookups work in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useSocIndex(SocIndex.fromGzip(File(socIndexAsset).readAsBytesSync()));
  await testMain();
}
