/// What the spoken round screen needs from the device: the models, a mic
/// check, the loaded engines, a place for recordings and playback. An
/// interface, so the screen is tested with fakes.
library;

import 'dart:io';
import 'dart:math' as math;

import 'lab.dart' show Pcm;
import 'models.dart';
import 'native_engines.dart';
import 'round.dart';
import 'round_engines.dart';

/// The models a spoken round needs.
const roundModelIds = [voiceModelId, vadModelId, defaultTranscriber];

abstract class SpokenEngines {
  /// Round models not yet on this device.
  Future<List<SpeechModel>> missing();

  /// Downloads [m] (after the user agreed to its size).
  Future<void> download(SpeechModel m, {void Function(double share)? progress});

  /// Records [length] from the microphone and returns the loudest level
  /// heard (dBFS). The audio is thrown away.
  Future<double> micCheck(Duration length, {void Function(double dbfs)? level});

  /// Loads the voice (for [texts], the round's questions) and the listener.
  Future<(InterviewerVoice, AnswerListener)> open(List<String> texts);

  /// Where this round's recordings go.
  Future<TakeStore> takes(String roundId);

  /// Deletes every recording of every round on this device.
  Future<void> deleteAllTakes();

  Future<void> play(String key, {void Function()? onDone});
  Future<void> stopPlaying();
  Future<void> dispose();
}

/// Loudest sample of [p] in dBFS.
double peakDbfs(Pcm p) {
  var peak = 0.0;
  for (final v in p.samples) {
    final a = v.abs();
    if (a > peak) peak = a;
  }
  return peak <= 0 ? -160 : 20 * math.log(peak) / math.ln10;
}

/// The real engines: models under [models], recordings under [takesRoot]
/// (both in the app's own data folder, never synced).
class NativeSpokenEngines implements SpokenEngines {
  NativeSpokenEngines(this.models, this.takesRoot);
  final ModelManager models;
  final Directory takesRoot;
  final _player = TakePlayer();

  @override
  Future<List<SpeechModel>> missing() async => [
    for (final id in roundModelIds)
      if (!await models.installed(speechModel(id))) speechModel(id),
  ];

  @override
  Future<void> download(SpeechModel m, {void Function(double share)? progress}) =>
      models.download(m, onProgress: (got, total) => progress?.call(got / total));

  @override
  Future<double> micCheck(Duration length, {void Function(double dbfs)? level}) async =>
      peakDbfs(await RecordMic().record(length, level: level));

  @override
  Future<(InterviewerVoice, AnswerListener)> open(List<String> texts) async {
    final voice = await KokoroVoice.open(models.folder(speechModel(voiceModelId)), texts: texts);
    try {
      final listener = await LiveListener.open(
        vadModel: models.path(speechModel(vadModelId)),
        transcriberFolder: models.folder(speechModel(defaultTranscriber)),
      );
      return (voice as InterviewerVoice, listener as AnswerListener);
    } on Object {
      await voice.close();
      rethrow;
    }
  }

  @override
  Future<TakeStore> takes(String roundId) async => FileTakeStore(Directory('${takesRoot.path}/$roundId'));

  @override
  Future<void> deleteAllTakes() async {
    if (await takesRoot.exists()) await takesRoot.delete(recursive: true);
  }

  @override
  Future<void> play(String key, {void Function()? onDone}) => _player.play(key, onDone: onDone);

  @override
  Future<void> stopPlaying() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
