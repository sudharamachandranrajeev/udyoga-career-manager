// I5 check: runs the camera coach's setup check with the real camera and
// the real face finder, and prints what it found as JSON. Not part of the
// app.
//
//   flutter build linux --release -t tool/camera_coach_check.dart
//   build/linux/x64/release/bundle/udyoga [--seconds 10] [--image picture.jpg] [--out results.json]
//
// The webcam runs for --seconds through the same FaceCamera the app uses,
// each frame measured in memory and dropped; the run reports the checks
// once a second. With --image, a still picture is also fed to the face
// finder as camera frames in five setups made from it: as it is, small in a
// big frame, cropped close, with the light behind it, and an empty frame.
// The BlazeFace model must already be downloaded (the lab does it).
//
// The run lists the app support folder before and after, to show the coach
// wrote nothing.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:path_provider/path_provider.dart';

Map<String, Object?> _results(List<SetupResult> rs) => {
  for (final r in rs) r.item.name: r.ok == null ? '… ${r.tip}' : '${r.ok! ? 'OK' : 'TIP'} ${r.tip}',
};

Map<String, Object?> _measure(FrameMeasure m) => {
  'face': m.face?.toString(),
  'faces': m.faces,
  'faceLuma': m.faceLuma.round(),
  'backLuma': m.backLuma.round(),
};

/// A BGRA frame of [w]x[h] filled with [fill], with [src] (BGRA, sw x sh)
/// drawn scaled by nearest neighbour into the rectangle [dx], [dy], [dw], [dh].
Uint8List _compose(
  Uint8List src,
  int sw,
  int sh,
  int w,
  int h,
  int dx,
  int dy,
  int dw,
  int dh, {
  int fill = 90,
}) {
  final out = Uint8List(w * h * 4);
  for (var i = 0; i < out.length; i += 4) {
    out[i] = out[i + 1] = out[i + 2] = fill;
    out[i + 3] = 255;
  }
  for (var y = 0; y < dh; y++) {
    final ty = dy + y;
    if (ty < 0 || ty >= h) continue;
    final sy = (y * sh) ~/ dh;
    for (var x = 0; x < dw; x++) {
      final tx = dx + x;
      if (tx < 0 || tx >= w) continue;
      final sx = (x * sw) ~/ dw;
      final s = (sy * sw + sx) * 4, t = (ty * w + tx) * 4;
      out[t] = src[s];
      out[t + 1] = src[s + 1];
      out[t + 2] = src[s + 2];
    }
  }
  return out;
}

/// Feeds [frame] [n] times through the detector and the checker, as a
/// camera would; returns the checks and the last frame's numbers.
Map<String, Object?> _setup(
  BlazeFaceDetector d,
  Frame frame, {
  int n = 15,
  FrameMeasure Function(FrameMeasure)? tweak,
}) {
  final c = SetupChecker();
  FrameMeasure? last;
  final t = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    final boxes = d.detect(frame);
    var m = measureFrame(frame, boxes);
    if (tweak != null) m = tweak(m);
    c.add(m);
    last = m;
  }
  return {
    'frame': '${frame.width}x${frame.height}',
    'msPerFrame': (t.elapsedMicroseconds / 1000 / n).toStringAsFixed(1),
    'measure': _measure(last!),
    'checks': _results(c.results),
  };
}

Future<Map<String, Object?>> _image(BlazeFaceDetector d, String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final img = (await codec.getNextFrame()).image;
  final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  for (var i = 0; i < px.length; i += 4) {
    final r = px[i];
    px[i] = px[i + 2];
    px[i + 2] = r;
  }
  final sw = img.width, sh = img.height;
  // A 640x480 "camera" frame, the size the app analyses.
  const w = 640, h = 480;
  final fit = math.min(w / sw, h / sh);
  final fw = (sw * fit).round(), fh = (sh * fit).round();
  Frame frame(Uint8List b) => Frame.bgra(w, h, b, w * 4);

  final asIs = frame(_compose(px, sw, sh, w, h, (w - fw) ~/ 2, (h - fh) ~/ 2, fw, fh));
  final small = frame(_compose(px, sw, sh, w, h, (w - fw ~/ 3) ~/ 2, (h - fh ~/ 3) ~/ 2, fw ~/ 3, fh ~/ 3));
  // Close: the picture scaled up 2.2 times round its middle.
  final cw = (fw * 2.2).round(), ch = (fh * 2.2).round();
  final close = frame(_compose(px, sw, sh, w, h, (w - cw) ~/ 2, (h - ch) ~/ 2 + ch ~/ 10, cw, ch));
  // Backlit: the picture darkened, in a bright frame (a window behind).
  final dark = Uint8List.fromList([for (var i = 0; i < px.length; i++) i % 4 == 3 ? 255 : px[i] * 35 ~/ 100]);
  final backlit = frame(_compose(dark, sw, sh, w, h, (w - fw) ~/ 2, (h - fh) ~/ 2, fw, fh, fill: 235));
  final empty = frame(_compose(px, sw, sh, w, h, 0, 0, 0, 0));

  // Away for more than 3 s: an empty frame for 4 s of camera time, then
  // back; timestamps are those a 15 fps camera would give.
  final away = AwayWatch();
  final t0 = DateTime(2026, 11, 19, 10);
  final hints = <String, String?>{};
  for (var i = 0; i <= 90; i++) {
    final at = t0.add(Duration(milliseconds: i * 1000 ~/ 15));
    final f = i < 15 || i > 75 ? asIs : empty;
    away.add(measureFrame(f, d.detect(f)), at);
    if (i % 15 == 0) hints['${i ~/ 15}s'] = away.hintAt(at);
  }

  return {
    'image': '${sw}x$sh',
    'asIs': _setup(d, asIs),
    'smallInFrame': _setup(d, small),
    'croppedClose': _setup(d, close),
    'backlit': _setup(d, backlit),
    'empty': _setup(d, empty),
    'awayHintEachSecond': hints,
  };
}

/// Every file under [d] with its size; folders that cannot be read are
/// skipped (the system temp folder holds other users' private folders).
Future<List<String>> _listing(Directory d) async {
  final out = <String>[];
  Future<void> walk(Directory dir) async {
    try {
      await for (final e in dir.list(followLinks: false)) {
        if (e is File) {
          out.add('${e.path} ${await e.length()}');
        } else if (e is Directory) {
          await walk(e);
        }
      }
    } on FileSystemException {
      return;
    }
  }

  if (await d.exists()) await walk(d);
  return out..sort();
}

Future<Map<String, Object?>> _run(List<String> args) async {
  final base = await getApplicationSupportDirectory();
  final mm = ModelManager(Directory('${base.path}/models'));
  final model = speechModel(faceModelId);
  if (!await mm.installed(model)) throw StateError('Download the face finder in the interview lab first.');
  final before = await _listing(base);
  final tmpBefore = await _listing(Directory.systemTemp);
  final out = <String, Object?>{};

  final secAt = args.indexOf('--seconds');
  final seconds = secAt >= 0 ? int.parse(args[secAt + 1]) : 10;
  try {
    final coach = CameraCoach();
    final cam = await FaceCamera.open(mm.path(model));
    coach.attach(_Feed(cam));
    final perSecond = <Map<String, Object?>>[];
    for (var s = 1; s <= seconds; s++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final m = cam.measure.value;
      perSecond.add({
        's': s,
        'fps': cam.fps.value.toStringAsFixed(1),
        'detectMs': cam.detectMs.value.toStringAsFixed(1),
        if (m != null) ..._measure(m),
        'checks': _results(coach.results),
      });
    }
    out['webcam'] = {
      'size': switch (cam.controller.value.previewSize) {
        final z? => '${z.width.round()}x${z.height.round()}',
        null => 'unknown',
      },
      'perSecond': perSecond,
      'setupNotes': coach.checker.notes,
    };
    await coach.turnOff();
    coach.dispose();
  } on Object catch (e) {
    out['webcam'] = {'error': '$e'};
  }

  final imgAt = args.indexOf('--image');
  if (imgAt >= 0) {
    final d = BlazeFaceDetector.open(mm.path(model));
    out['image'] = await _image(d, args[imgAt + 1]);
    d.close();
  }

  final after = await _listing(base);
  final tmpAfter = await _listing(Directory.systemTemp);
  out['filesWritten'] = {
    'appSupport': [
      for (final f in after)
        if (!before.contains(f)) f,
    ],
    'systemTemp': [
      for (final f in tmpAfter)
        if (!tmpBefore.contains(f)) f,
    ],
  };
  return out;
}

class _Feed implements CoachFeed {
  _Feed(this._cam);
  final FaceCamera _cam;
  @override
  ValueNotifier<FrameMeasure?> get measures => _cam.measure;
  @override
  Widget? preview() => null;
  @override
  Future<void> close() => _cam.close();
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Camera coach check running…'))),
    ),
  );
  final outAt = args.indexOf('--out');
  Map<String, Object?> result;
  try {
    result = await _run(args);
  } on Object catch (e, st) {
    result = {'error': '$e', 'stack': '$st'};
  }
  final json = const JsonEncoder.withIndent('  ').convert(result);
  stdout.writeln(json);
  if (outAt >= 0 && outAt + 1 < args.length) await File(args[outAt + 1]).writeAsString(json);
  exit(result.containsKey('error') ? 1 : 0);
}
