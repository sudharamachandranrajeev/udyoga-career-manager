/// The lab's real engines: `record` for the mic, sherpa-onnx for Silero VAD,
/// the Kokoro voice and the Moonshine transcriber, audioplayers to play the
/// voice. All run on the device from models the user downloaded; none of
/// them is given a URL. Audio goes to the transcriber as 16 kHz samples in
/// memory: no file and no converter.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'lab.dart';

/// Records PCM16 16 kHz mono from the default mic into memory.
class RecordMic implements MicRecorder {
  @override
  Future<Pcm> record(Duration length, {void Function(double dbfs)? level}) async {
    final rec = AudioRecorder();
    try {
      if (!await rec.hasPermission()) {
        throw StateError('Udyoga may not use the microphone. Allow it in the system settings.');
      }
      final bytes = BytesBuilder(copy: false);
      final stream = await rec.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
      );
      final levels = rec
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((a) => level?.call(a.current));
      final done = Completer<void>();
      final sub = stream.listen(bytes.add, onDone: done.complete, onError: done.completeError);
      await Future<void>.delayed(length);
      await rec.stop();
      await done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
      await sub.cancel();
      await levels.cancel();
      return Pcm(pcm16ToFloat(bytes.takeBytes()));
    } finally {
      await rec.dispose();
    }
  }
}

/// Little-endian PCM16 bytes to -1..1 floats.
Float32List pcm16ToFloat(Uint8List bytes) {
  final n = bytes.length ~/ 2;
  final data = ByteData.sublistView(bytes);
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768;
  }
  return out;
}

/// A 16-bit mono WAV of [pcm].
Uint8List wavBytes(Pcm pcm) {
  final n = pcm.samples.length;
  final b = ByteData(44 + n * 2);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, pcm.sampleRate, Endian.little);
  b.setUint32(28, pcm.sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    b.setInt16(44 + i * 2, (pcm.samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

/// Silero VAD through sherpa-onnx, run off the UI isolate.
class SileroVad implements SpeechDetector {
  SileroVad(this.modelPath);
  final String modelPath;

  @override
  Future<List<SpeechSpan>> spans(Pcm audio) {
    final model = modelPath, samples = audio.samples, rate = audio.sampleRate;
    return Isolate.run(() {
      sherpa.initBindings();
      final vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: model,
            minSilenceDuration: 0.5,
            maxSpeechDuration: 30,
          ),
          sampleRate: rate,
          debug: false,
        ),
        bufferSizeInSeconds: 60,
      );
      final found = <SpeechSpan>[];
      void drain() {
        while (!vad.isEmpty()) {
          final s = vad.front();
          found.add(
            SpeechSpan(
              Duration(microseconds: s.start * 1000000 ~/ rate),
              Duration(microseconds: (s.start + s.samples.length) * 1000000 ~/ rate),
            ),
          );
          vad.pop();
        }
      }

      const window = 512;
      for (var i = 0; i + window <= samples.length; i += window) {
        vad.acceptWaveform(Float32List.sublistView(samples, i, i + window));
        drain();
      }
      vad.flush();
      drain();
      vad.free();
      return found;
    });
  }
}

/// sherpa-onnx's offline recognizer with a Moonshine model, from the
/// folder that holds `encoder_model.ort`.
sherpa.OfflineRecognizerConfig moonshineConfig(String folder, {int threads = 4}) =>
    sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        moonshine: sherpa.OfflineMoonshineModelConfig(
          encoder: '$folder/encoder_model.ort',
          mergedDecoder: '$folder/decoder_model_merged.ort',
        ),
        tokens: '$folder/tokens.txt',
        numThreads: threads,
        debug: false,
      ),
    );

/// Writes down [samples] (16 kHz mono) with a loaded [recognizer].
String recognise(sherpa.OfflineRecognizer recognizer, Float32List samples) {
  final stream = recognizer.createStream();
  try {
    stream.acceptWaveform(samples: samples, sampleRate: 16000);
    recognizer.decode(stream);
    return recognizer.getResult(stream).text.trim();
  } finally {
    stream.free();
  }
}

/// Moonshine through sherpa-onnx, loaded for each call (the lab measures one
/// answer; a spoken round keeps it loaded, see round_engines.dart). [took]
/// on the transcript is the transcription alone, not the loading.
class MoonshineTranscriber implements Transcriber {
  MoonshineTranscriber(this.folder, this.model, {this.threads = 4});
  final String folder;
  @override
  final String model;
  final int threads;

  @override
  Future<Transcript> transcribe(Pcm audio) async {
    final dir = folder, samples = audio.samples, n = threads;
    final (text, us) = await Isolate.run(() {
      sherpa.initBindings();
      final rec = sherpa.OfflineRecognizer(moonshineConfig(dir, threads: n));
      try {
        final watch = Stopwatch()..start();
        final text = recognise(rec, samples);
        return (text, watch.elapsedMicroseconds);
      } finally {
        rec.free();
      }
    });
    return Transcript(text, Duration(microseconds: us));
  }
}

/// The Kokoro voice used for the interviewer: British English, "Emma".
const kokoroBritishVoice = 21;

/// Kokoro-82M through sherpa-onnx with its British English lexicon. Since
/// sherpa-onnx 2.0 there is no espeak-ng inside, so words come from the
/// lexicon only; a word missing from it is skipped or spelt out.
/// [extraLexicon] is an optional second word list (see lexicon.dart).
sherpa.OfflineTtsConfig kokoroConfig(String folder, {String? extraLexicon}) => sherpa.OfflineTtsConfig(
  model: sherpa.OfflineTtsModelConfig(
    kokoro: sherpa.OfflineTtsKokoroModelConfig(
      model: '$folder/model.int8.onnx',
      voices: '$folder/voices.bin',
      tokens: '$folder/tokens.txt',
      lexicon: ['$folder/lexicon-gb-en.txt', ?extraLexicon].join(','),
    ),
    numThreads: 4,
  ),
);

/// The interviewer's voice: Kokoro through sherpa-onnx, played with
/// audioplayers from a temporary WAV that is deleted after playing.
class KokoroSpeaker implements Speaker {
  KokoroSpeaker(this.voiceFolder, {this.voice = kokoroBritishVoice, Directory? temp, this.play = true})
    : temp = temp ?? Directory.systemTemp;

  /// The unpacked voice: model, voices.bin, tokens.txt and the lexicon.
  final String voiceFolder;
  final int voice;
  final Directory temp;

  /// False only for measuring synthesis without the speakers.
  final bool play;

  AudioPlayer? _player;

  @override
  Future<SpeechTiming> speak(String text) async {
    final folder = voiceFolder, sid = voice;
    // Synthesis runs on another isolate; it times loading the voice, the
    // first samples ready to play (the first sentence), and the whole text.
    final (loadUs, firstUs, totalUs, samples, rate) = await Isolate.run(() {
      sherpa.initBindings();
      final loading = Stopwatch()..start();
      final tts = sherpa.OfflineTts(kokoroConfig(folder));
      final load = loading.elapsedMicroseconds;
      final gen = Stopwatch()..start();
      int? first;
      final audio = tts.generateWithCallback(
        text: text,
        sid: sid,
        callback: (chunk) {
          first ??= gen.elapsedMicroseconds;
          return 1;
        },
      );
      tts.free();
      final total = gen.elapsedMicroseconds;
      return (load, first ?? total, total, audio.samples, audio.sampleRate);
    });
    if (samples.isEmpty || rate <= 0) throw StateError('The voice made no sound for that text.');
    final audioLength = Duration(microseconds: samples.length * 1000000 ~/ rate);
    if (play && samples.isNotEmpty) {
      final dir = await temp.createTemp('udyoga-voice-');
      final wav = File('${dir.path}/voice.wav');
      await wav.writeAsBytes(wavBytes(Pcm(samples, sampleRate: rate)));
      final player = _player ??= AudioPlayer();
      await player.play(DeviceFileSource(wav.path));
      unawaited(
        player.onPlayerComplete.first
            .timeout(audioLength + const Duration(seconds: 5))
            .whenComplete(() => dir.delete(recursive: true))
            .catchError((_) {}),
      );
    }
    return SpeechTiming(
      load: Duration(microseconds: loadUs),
      firstAudio: Duration(microseconds: firstUs),
      synthesis: Duration(microseconds: totalUs),
      audio: audioLength,
    );
  }

  Future<void> dispose() async => _player?.dispose();
}
