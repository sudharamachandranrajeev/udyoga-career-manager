// I5 check: shows the real camera setup card (CameraSetupCard) with the
// webcam turned on, self-view on, for a few seconds, and prints any Flutter
// error and the checks. Not part of the app.
//
//   flutter build linux --release -t tool/camera_setup_live.dart
//   build/linux/x64/release/bundle/udyoga [--seconds 6]

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:udyoga/ui/camera_coach_ui.dart';
import 'package:udyoga/vision/camera_coach.dart';
import 'package:udyoga/voice/models.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final errors = <String>[];
  FlutterError.onError = (d) => errors.add(d.exceptionAsString());
  final base = await getApplicationSupportDirectory();
  final camera = NativeCoachCamera(ModelManager(Directory('${base.path}/models')));
  final coach = CameraCoach();
  runApp(
    ProviderScope(
      overrides: [coachCameraProvider.overrideWith((ref) async => camera)],
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [CameraSetupCard(coach), CameraRoundBar(coach)],
          ),
        ),
      ),
    ),
  );
  final secAt = args.indexOf('--seconds');
  final seconds = secAt >= 0 ? int.parse(args[secAt + 1]) : 6;
  await coach.turnOn(camera);
  await Future<void>.delayed(Duration(seconds: seconds));
  final out = {
    'cameraOn': coach.on,
    'error': coach.error,
    'checks': [for (final r in coach.results) '${r.item.name}: ${r.ok} ${r.tip}'],
    'flutterErrors': errors,
  };
  await coach.turnOff();
  coach.dispose();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(out));
  exit(errors.isEmpty && out['cameraOn'] == true ? 0 : 1);
}
