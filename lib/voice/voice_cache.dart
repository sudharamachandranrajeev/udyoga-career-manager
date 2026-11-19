/// Ready-made audio for the interviewer's fixed lines, so a second round
/// starts at once instead of waiting for the voice to make its opening.
///
/// Only lines written into the app are kept: the panels' greetings and
/// acknowledgements, the interrupt and wrap-up lines, the built-in
/// follow-ups and the template settler questions. A sentence is kept only
/// when it is one of the sentences of those lines, word for word, so
/// nothing the user wrote (an edited question, a role, an answer) is ever
/// written to the cache. The files sit in the app's own support folder,
/// are never synced, and are keyed by a hash of the voice, its speed and
/// the sentence.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../domain/interview_plan.dart';
import '../domain/interview_process.dart';
import '../domain/interview_scoring.dart' show profileSettler;
import 'models.dart' show voiceModelId;
import 'round_engines.dart' show sentencesOf;

/// Every fixed line the interviewer may say: generic, written in the app.
Set<String> fixedVoiceLines() => {
  for (final p in personas.values) ...[
    p.greeting,
    ...p.acknowledgements,
    if (p.probeLead.trim().isNotEmpty) p.probeLead.trim(),
    for (final l in ladder) roundOpening(p, l),
  ],
  mayInterruptScript,
  interruptLine,
  for (final list in builtInProbes.values) ...list,
  profileSettler.question,
  presentationPrompt,
  for (final t in processTemplates)
    for (final s in t.stages) s.settler.question,
};

/// The sentences of [fixedVoiceLines]: the only text the cache keeps.
final Set<String> fixedVoiceSentences = {for (final l in fixedVoiceLines()) ...sentencesOf(l)};

/// Bump to throw away every cached clip (a change in how audio is made).
const _cacheVersion = 1;

/// Audio for fixed sentences in [dir], made by [voice] (a speaker id of
/// [model]) at [speed].
class VoiceCache {
  VoiceCache(this.dir, {required this.voice, this.speed = 1.0, this.model = voiceModelId});

  final Directory dir;
  final int voice;
  final double speed;
  final String model;

  /// The file name for [sentence], or null when it may not be cached: it
  /// is not one of the app's own fixed sentences.
  String? keyFor(String sentence) {
    final s = sentence.trim();
    if (!fixedVoiceSentences.contains(s)) return null;
    return cacheKey(s, voice: voice, speed: speed, model: model);
  }

  /// The hash a cached sentence is stored under.
  static String cacheKey(String sentence, {required int voice, required double speed, required String model}) =>
      sha256.convert(utf8.encode('v$_cacheVersion\n$model\n$voice\n${speed.toStringAsFixed(2)}\n$sentence')).toString();

  File _file(String key) => File('${dir.path}/$key.pcm');

  /// The clip stored under [key], or null when there is none or it is
  /// damaged (it is then made again).
  Future<(Float32List, int)?> read(String key) async {
    final f = _file(key);
    try {
      if (!await f.exists()) return null;
      final bytes = await f.readAsBytes();
      if (bytes.length < 8 || (bytes.length - 4) % 4 != 0) return null;
      final data = ByteData.sublistView(bytes);
      final rate = data.getUint32(0, Endian.little);
      final samples = Float32List((bytes.length - 4) ~/ 4);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = data.getFloat32(4 + i * 4, Endian.little);
      }
      return rate <= 0 ? null : (samples, rate);
    } on FileSystemException {
      return null;
    }
  }

  /// Stores a clip under [key]: the sample rate, then the samples.
  Future<void> write(String key, Float32List samples, int rate) async {
    if (samples.isEmpty || rate <= 0) return;
    await dir.create(recursive: true);
    final out = ByteData(4 + samples.length * 4)..setUint32(0, rate, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      out.setFloat32(4 + i * 4, samples[i], Endian.little);
    }
    // Written aside and renamed, so a half-written clip is never read.
    final tmp = File('${dir.path}/$key.part');
    await tmp.writeAsBytes(out.buffer.asUint8List(), flush: true);
    await tmp.rename(_file(key).path);
  }

  /// Removes every cached clip.
  Future<void> clear() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
