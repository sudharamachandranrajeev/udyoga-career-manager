// I0 spike harness: runs the interview lab's engines with real plugins and
// prints timings as JSON. Not part of the app.
//
//   flutter build linux --release -t tool/interview_spike.dart
//   build/linux/x64/release/bundle/udyoga [--download] [--out results.json]
//       [--face-image picture.jpg]
//
// --download fetches missing models first (the only network use). Without
// it the run needs no network at all, which the network-off check relies on:
// any dart:io HTTP client the app tries to make is counted and refused.
//
// The 10 s "answer" is made by the Kokoro voice itself, so the run needs no
// person at the mic; the mic and camera are still opened for real.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:udyoga/vision/blazeface.dart';
import 'package:udyoga/vision/face_camera.dart';
import 'package:udyoga/voice/lab.dart';
import 'package:udyoga/voice/models.dart';
import 'package:udyoga/voice/native_engines.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Refuses and counts every dart:io HTTP client made during the run.
class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw const SocketException('Network use is not allowed in the offline run.');
  }
}

const _answer =
    'In my last role I led the morning handover on a busy ward. Um, we were missing key details, so I '
    'brought in a short checklist and, like, asked each nurse to read back the plan. Within a month the '
    'number of missed tasks fell by half.';

Future<Pcm> _speechClip(String folder, Duration length) => Isolate.run(() {
  sherpa.initBindings();
  final tts = sherpa.OfflineTts(kokoroConfig(folder));
  final a = tts.generate(text: _answer, sid: kokoroBritishVoice);
  tts.free();
  // Linear resample to 16 kHz, padded or cut to [length].
  final n = length.inMilliseconds * 16;
  final out = Float32List(n);
  final ratio = a.sampleRate / 16000;
  for (var i = 0; i < n; i++) {
    final x = i * ratio, j = x.floor();
    if (j + 1 >= a.samples.length) break;
    out[i] = a.samples[j] + (a.samples[j + 1] - a.samples[j]) * (x - j);
  }
  return Pcm(out);
});

int _ms(Duration d) => d.inMilliseconds;

/// Runs the face finder on a still picture (any format Flutter decodes), to
/// check the detector when nobody sits in front of the camera.
Future<Map<String, Object?>> _faceInImage(String modelPath, String imagePath) async {
  final codec = await ui.instantiateImageCodec(await File(imagePath).readAsBytes());
  final img = (await codec.getNextFrame()).image;
  final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  // RGBA to the BGRA the detector reads from desktop cameras.
  for (var i = 0; i < rgba.length; i += 4) {
    final r = rgba[i];
    rgba[i] = rgba[i + 2];
    rgba[i + 2] = r;
  }
  final d = BlazeFaceDetector.open(modelPath);
  final t = Stopwatch()..start();
  final boxes = d.detect(Frame.bgra(img.width, img.height, rgba, img.width * 4));
  final took = t.elapsedMicroseconds / 1000;
  d.close();
  return {
    'size': '${img.width}x${img.height}',
    'ms': took,
    'boxes': [
      for (final b in boxes)
        {
          'score': b.score.toStringAsFixed(3),
          'ltwh': [b.left, b.top, b.width, b.height].map((v) => v.toStringAsFixed(3)).toList(),
        },
    ],
  };
}

double _rmsDbfs(Pcm p) {
  if (p.samples.isEmpty) return -160;
  var sum = 0.0;
  for (final v in p.samples) {
    sum += v * v;
  }
  final rms = math.sqrt(sum / p.samples.length);
  return rms == 0 ? -160 : 20 * math.log(rms) / math.ln10;
}

Future<Map<String, Object?>> _run(List<String> args) async {
  final download = args.contains('--download');
  final guard = _NoNetwork();
  final base = await getApplicationSupportDirectory();
  final mm = ModelManager(Directory('${base.path}/models'));
  final out = <String, Object?>{'cpu': Platform.numberOfProcessors, 'modelsDir': '${base.path}/models'};

  final missing = [
    for (final m in speechModels)
      if (!await mm.installed(m)) m,
  ];
  if (missing.isNotEmpty) {
    if (!download) throw StateError('Missing models: ${missing.map((m) => m.id).join(', ')}');
    for (final m in missing) {
      stdout.writeln('downloading ${m.id} (${formatBytes(m.bytes)})');
      await mm.download(m);
    }
  }
  out['modelsOnDisk'] = {for (final m in speechModels) m.id: await mm.sizeOnDisk(m)};

  // From here on nothing may use the network.
  HttpOverrides.global = guard;

  final voice = speechModel('kokoro-en-gb-int8');
  final speaker = KokoroSpeaker(mm.folder(voice));
  final tts = <Map<String, int>>[];
  for (var i = 0; i < 3; i++) {
    final t = await speaker.speak('Thank you for coming in. Tell us about a time you improved a process.');
    tts.add({
      'loadMs': _ms(t.load),
      'firstAudioMs': _ms(t.firstAudio),
      'synthMs': _ms(t.synthesis),
      'audioMs': _ms(t.audio),
    });
    await Future<void>.delayed(t.audio + const Duration(milliseconds: 300));
  }
  out['tts'] = tts;

  final clip = await _speechClip(mm.folder(voice), const Duration(seconds: 10));
  final vadWatch = Stopwatch()..start();
  final spans = await SileroVad(mm.path(speechModel('silero-vad'))).spans(clip);
  out['vad'] = {
    'ms': vadWatch.elapsedMilliseconds,
    'spans': [
      for (final s in spans) [_ms(s.start), _ms(s.end)],
    ],
  };

  final stt = <String, Object?>{};
  for (final (id, wm) in [
    ('whisper-base-en', WhisperModel.baseEn),
    ('whisper-small-en', WhisperModel.smallEn),
  ]) {
    final runs = <Map<String, Object?>>[];
    for (var i = 0; i < 2; i++) {
      final t = await WhisperTranscriber(mm.path(speechModel(id)), wm).transcribe(clip);
      runs.add({'ms': _ms(t.took), 'text': t.text});
    }
    stt[id] = runs;
  }
  out['transcribe10s'] = stt;

  // The real microphone, 10 s, then the full lab flow on it.
  final lab = InterviewLab(
    recorder: RecordMic(),
    detector: SileroVad(mm.path(speechModel('silero-vad'))),
    transcriber: WhisperTranscriber(mm.path(speechModel('whisper-base-en')), WhisperModel.baseEn),
    speaker: speaker,
  );
  var peak = -160.0;
  final levels = Timer.periodic(const Duration(milliseconds: 200), (_) {
    if (lab.level > peak) peak = lab.level;
  });
  final r = await lab.run();
  levels.cancel();
  out['labOnMic'] = {
    'step': lab.step.name,
    'error': r.error,
    'recordedMs': r.audio == null ? null : _ms(r.audio!.length),
    'peakDbfs': peak,
    'rmsDbfs': r.audio == null ? null : _rmsDbfs(r.audio!),
    'speechSpans': r.spans.length,
    'transcript': r.transcript?.text,
    'transcribeMs': r.transcript == null ? null : _ms(r.transcript!.took),
    'voiceFirstAudioMs': r.speech == null ? null : _ms(r.speech!.firstAudio),
  };

  // The camera for 10 s with the face finder.
  try {
    final cam = await FaceCamera.open(mm.path(speechModel('blazeface-short-range')));
    final fps = <double>[], ms = <double>[];
    var faces = 0;
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      fps.add(cam.fps.value);
      ms.add(cam.detectMs.value);
      if (cam.boxes.value.isNotEmpty) faces++;
    }
    final size = cam.controller.value.previewSize;
    await cam.close();
    out['camera'] = {
      'frame': size == null ? null : '${size.width.toInt()}x${size.height.toInt()}',
      'fpsPerSecond': fps,
      'detectMsPerSecond': ms,
      'secondsWithAFace': faces,
    };
  } on Object catch (e) {
    out['camera'] = {'error': '$e'};
  }
  final imageAt = args.indexOf('--face-image');
  if (imageAt >= 0 && imageAt + 1 < args.length) {
    out['faceInImage'] = await _faceInImage(mm.path(speechModel('blazeface-short-range')), args[imageAt + 1]);
  }
  await speaker.dispose();
  out['httpClientAttempts'] = guard.attempts;
  return out;
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Interview spike running…'))),
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
