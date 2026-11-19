// Times the panel's opening on this device: how soon the first audio can
// play and when the microphone would open. The opening is made a sentence
// at a time, as the voice makes it; a sentence plays when it is made and
// the one before has finished. Compares the thread count and one engine
// against two making every other sentence. Nothing is played aloud. Not
// part of the app.
//
//   flutter build linux --release -t tool/voice_timing_check.dart
//   build/linux/x64/release/bundle/udyoga

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/interview_process.dart';
import 'package:udyoga/voice/lexicon.dart';
import 'package:udyoga/voice/models.dart';
import 'package:udyoga/voice/native_engines.dart';
import 'package:udyoga/voice/round_engines.dart';
import 'package:udyoga/voice/worker.dart';

Map<String, Object?> _schedule(sherpa.OfflineTts tts, List<String> pieces) {
  final clock = Stopwatch()..start();
  var playEnd = 0.0;
  double? firstAudio;
  final made = <Map<String, Object?>>[];
  for (final p in pieces) {
    final a = tts.generate(text: p, sid: kokoroBritishVoice);
    final ready = clock.elapsedMilliseconds / 1000;
    final length = a.samples.length / a.sampleRate;
    final start = ready > playEnd ? ready : playEnd;
    firstAudio ??= ready;
    playEnd = start + length;
    made.add({'piece': p, 'madeAt': ready, 'seconds': double.parse(length.toStringAsFixed(2))});
  }
  return {'firstAudioAt': firstAudio, 'micOpensAt': double.parse(playEnd.toStringAsFixed(2)), 'pieces': made};
}

Future<Map<String, Object?>> _run() async {
  final base = await getApplicationSupportDirectory();
  final mm = ModelManager(Directory('${base.path}/models'));
  if (!await mm.installed(speechModel(voiceModelId))) throw StateError('Missing model $voiceModelId');
  final folder = mm.folder(speechModel(voiceModelId));
  final stage = nhsStyle.stages[0];
  final text = '${stage.opening(Persona.of(stage.persona))} ${stage.settler.question}';
  final temp = await Directory.systemTemp.createTemp('udyoga-voice-timing-');
  try {
    final extra = extraLexicon(File('$folder/lexicon-gb-en.txt').readAsStringSync(), [text]);
    final extraPath = '${temp.path}/extra.txt';
    File(extraPath).writeAsStringSync(extra);
    sherpa.initBindings();
    final out = <String, Object?>{'text': text};
    for (final threads in [4, 6, 8]) {
      final tts = sherpa.OfflineTts(
        sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            kokoro: sherpa.OfflineTtsKokoroModelConfig(
              model: '$folder/model.int8.onnx',
              voices: '$folder/voices.bin',
              tokens: '$folder/tokens.txt',
              lexicon: ['$folder/lexicon-gb-en.txt', if (extra.isNotEmpty) extraPath].join(','),
            ),
            numThreads: threads,
          ),
        ),
      );
      try {
        tts.generate(text: 'Warm up.', sid: kokoroBritishVoice);
        out['threads$threads'] = _schedule(tts, sentencesOf(text));
      } finally {
        tts.free();
      }
    }
    // Two engines on their own isolates, each making every other piece.
    for (final count in [1, 2]) {
      final workers = [
        for (var i = 0; i < count; i++)
          await EngineWorker.start(() {
            sherpa.initBindings();
            final tts = sherpa.OfflineTts(
              kokoroConfig(folder, extraLexicon: extra.isEmpty ? null : extraPath),
            );
            return (request) {
              if (request == engineCloseRequest) {
                tts.free();
                return null;
              }
              final a = tts.generate(text: request! as String, sid: kokoroBritishVoice);
              return a.samples.length / a.sampleRate;
            };
          }),
      ];
      try {
        await Future.wait([for (final w in workers) w.call<double>('Warm up.')]);
        final pieces = sentencesOf(text);
        final clock = Stopwatch()..start();
        final ready = [
          for (final (i, p) in pieces.indexed)
            workers[i % count].call<double>(p).then((len) => (clock.elapsedMilliseconds / 1000, len)),
        ];
        var playEnd = 0.0;
        double? first;
        for (final r in ready) {
          final (at, len) = await r;
          first ??= at;
          playEnd = (at > playEnd ? at : playEnd) + len;
        }
        out['workers$count'] = {
          'firstAudioAt': first,
          'micOpensAt': double.parse(playEnd.toStringAsFixed(2)),
        };
      } finally {
        for (final w in workers) {
          await w.close();
        }
      }
    }
    return out;
  } finally {
    await temp.delete(recursive: true);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Timing the voice…'))),
    ),
  );
  Map<String, Object?> result;
  try {
    result = await _run();
  } on Object catch (e, st) {
    result = {'error': '$e', 'stack': '$st'};
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  exit(result.containsKey('error') ? 1 : 0);
}
