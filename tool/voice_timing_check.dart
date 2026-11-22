// Times the panel's opening on this device: how soon the first audio can
// play and when the microphone would open. The opening is made a sentence
// at a time, as the voice makes it; a sentence plays when it is made and
// the one before has finished. Compares the I2 opening with the shorter
// I4 one, first with nothing cached ("cold"), then with the fixed
// sentences read from the voice cache ("warm"), as a second round does.
// Nothing is played aloud. Not part of the app.
//
//   flutter build linux --release -t tool/voice_timing_check.dart
//   build/linux/x64/release/bundle/udyoga

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Makes or reads each sentence of [text] in turn and works out when the
/// microphone would open. With [cache], fixed sentences come from it when
/// there, and are written to it after being made.
Future<Map<String, Object?>> _schedule(sherpa.OfflineTts tts, String text, {VoiceCache? cache}) async {
  final clock = Stopwatch()..start();
  var playEnd = 0.0;
  double? firstAudio;
  final made = <Map<String, Object?>>[];
  for (final p in sentencesOf(text)) {
    final key = cache?.keyFor(p);
    (Float32List, int)? clip = key == null ? null : await cache!.read(key);
    final fromCache = clip != null;
    if (clip == null) {
      final a = tts.generate(text: p, sid: kokoroBritishVoice);
      clip = (a.samples, a.sampleRate);
      if (key != null) await cache!.write(key, clip.$1, clip.$2);
    }
    final ready = clock.elapsedMilliseconds / 1000;
    final length = clip.$1.length / clip.$2;
    final start = ready > playEnd ? ready : playEnd;
    firstAudio ??= ready;
    playEnd = start + length;
    made.add({
      'piece': p,
      'cached': fromCache,
      'madeAt': ready,
      'seconds': double.parse(length.toStringAsFixed(2)),
    });
  }
  return {
    'firstAudioAt': firstAudio,
    'micOpensAt': double.parse(playEnd.toStringAsFixed(2)),
    'speechSeconds': double.parse(
      made.fold(0.0, (a, m) => a + (m['seconds']! as double)).toStringAsFixed(2),
    ),
    'pieces': made,
  };
}

Future<Map<String, Object?>> _run() async {
  final base = await getApplicationSupportDirectory();
  final mm = ModelManager(Directory('${base.path}/models'));
  if (!await mm.installed(speechModel(voiceModelId))) throw StateError('Missing model $voiceModelId');
  final folder = mm.folder(speechModel(voiceModelId));
  final stage = nhsStyle.stages[0];
  final persona = Persona.of(stage.persona);
  final settler = stage.settler.question;
  final texts = {
    // As I2/I3 said it, at every level.
    'before': '${persona.greeting} This is the ${stage.title.toLowerCase()}. $mayInterruptScript $settler',
    'level3': '${stage.opening(persona, Ladder.of(3))} $settler',
    'level5': '${stage.opening(persona, Ladder.of(5))} $settler',
  };
  final temp = await Directory.systemTemp.createTemp('udyoga-voice-timing-');
  try {
    final extra = extraLexicon(File('$folder/lexicon-gb-en.txt').readAsStringSync(), texts.values.toList());
    final extraPath = '${temp.path}/extra.txt';
    File(extraPath).writeAsStringSync(extra);
    sherpa.initBindings();
    final tts = sherpa.OfflineTts(kokoroConfig(folder, extraLexicon: extra.isEmpty ? null : extraPath));
    final cache = VoiceCache(Directory('${temp.path}/cache'), voice: kokoroBritishVoice);
    final out = <String, Object?>{};
    try {
      tts.generate(text: 'Warm up.', sid: kokoroBritishVoice);
      out['before'] = await _schedule(tts, texts['before']!);
      for (final level in ['level3', 'level5']) {
        await cache.clear();
        out['${level}Cold'] = await _schedule(tts, texts[level]!, cache: cache);
        out['${level}Warm'] = await _schedule(tts, texts[level]!, cache: cache);
      }
    } finally {
      tts.free();
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
