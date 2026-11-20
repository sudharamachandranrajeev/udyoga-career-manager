/// The real engines of a spoken round, each kept loaded for the whole round
/// on its own isolate:
///
/// - [KokoroVoice]: the interviewer, sentence by sentence, with the next
///   question made while the candidate answers.
/// - [LiveListener]: the microphone through `record`, Silero VAD live (end
///   of answer, pauses) and Moonshine writing each stretch down as soon as
///   it ends, so the transcript is ready moments after the answer. The
///   stretch still being spoken is read again about every second for the
///   live caption.
/// - [FileTakeStore]: recordings as WAV files in the app's own data folder,
///   never synced, deleted when the round screen closes.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../domain/delivery.dart';
import 'lab.dart' show Pcm;
import 'lexicon.dart';
import 'native_engines.dart';
import 'round.dart';
import 'voice_cache.dart';
import 'worker.dart';

/// Splits [text] into sentences, so the first can play while the rest are
/// made.
List<String> sentencesOf(String text) => [
  for (final s in text.trim().split(RegExp(r'(?<=[.!?])\s+')))
    if (s.trim().isNotEmpty) s.trim(),
];

typedef _Clip = (Float32List, int);

/// The interviewer's voice: Kokoro loaded once, on its own isolate.
class KokoroVoice implements InterviewerVoice {
  KokoroVoice._(this._worker, this._temp, this._cache);

  /// Loads the voice from [folder]. [texts] are the round's questions: any
  /// of their words missing from the voice's word list are filled in from
  /// their base words first (lexicon.dart), so none is skipped. With
  /// [cacheDir], the app's fixed sentences (greetings, acknowledgements,
  /// the interrupt lines, built-in follow-ups, template settlers) are kept
  /// there once made, so the next round says them at once ([VoiceCache]).
  static Future<KokoroVoice> open(
    String folder, {
    required List<String> texts,
    int voice = kokoroBritishVoice,
    Directory? cacheDir,
  }) async {
    final temp = await Directory.systemTemp.createTemp('udyoga-voice-');
    final extraPath = '${temp.path}/extra-lexicon.txt';
    try {
      final worker = await EngineWorker.start(() {
        final extra = extraLexicon(File('$folder/lexicon-gb-en.txt').readAsStringSync(), texts);
        File(extraPath).writeAsStringSync(extra.isEmpty ? '' : extra);
        sherpa.initBindings();
        final tts = sherpa.OfflineTts(kokoroConfig(folder, extraLexicon: extra.isEmpty ? null : extraPath));
        return (request) {
          if (request == engineCloseRequest) {
            tts.free();
            return null;
          }
          final a = tts.generate(text: request! as String, sid: voice);
          return (a.samples, a.sampleRate);
        };
      });
      return KokoroVoice._(worker, temp, cacheDir == null ? null : VoiceCache(cacheDir, voice: voice));
    } on Object {
      await temp.delete(recursive: true);
      rethrow;
    }
  }

  final EngineWorker _worker;
  final Directory _temp;
  final VoiceCache? _cache;
  final _made = <String, List<Future<_Clip>>>{};
  AudioPlayer? _player;
  Completer<void>? _playing;
  var _stopped = false;
  var _n = 0;

  List<Future<_Clip>> _make(String text) {
    final have = _made.remove(text);
    // Most recent last; keep a few (the current, the next, a re-ask, a
    // follow-up and an acknowledgement).
    final clips = _made[text] = have ?? [for (final s in sentencesOf(text)) _clip(s)];
    while (_made.length > 5) {
      _made.remove(_made.keys.first);
    }
    for (final c in clips) {
      c.ignore();
    }
    return clips;
  }

  /// One sentence: from the cache when it is a fixed line made before,
  /// otherwise made now (and kept when it is a fixed line).
  Future<_Clip> _clip(String sentence) async {
    final cache = _cache;
    final key = cache?.keyFor(sentence);
    if (cache != null && key != null) {
      final hit = await cache.read(key);
      if (hit != null) return hit;
    }
    final made = await _worker.call<_Clip>(sentence);
    if (cache != null && key != null) {
      try {
        await cache.write(key, made.$1, made.$2);
      } on FileSystemException {
        // A full or read-only disk only costs speed next time.
      }
    }
    return made;
  }

  @override
  void prepare(String text) => _make(text);

  /// Completes when every sentence of [text] is made (for measuring).
  Future<void> ready(String text) => Future.wait(_make(text));

  @override
  Future<void> say(String text) async {
    _stopped = false;
    for (final clip in _make(text)) {
      final (samples, rate) = await clip;
      if (_stopped) return;
      if (samples.isEmpty || rate <= 0) continue;
      await _play(samples, rate);
      if (_stopped) return;
    }
  }

  Future<void> _play(Float32List samples, int rate) async {
    final wav = File('${_temp.path}/${_n++}.wav');
    await wav.writeAsBytes(wavBytes(Pcm(samples, sampleRate: rate)));
    final player = _player ??= AudioPlayer();
    final done = _playing = Completer<void>();
    final sub = player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await player.play(DeviceFileSource(wav.path));
      final length = Duration(microseconds: samples.length * 1000000 ~/ rate);
      await done.future.timeout(length + const Duration(seconds: 3), onTimeout: () {});
    } finally {
      await sub.cancel();
      _playing = null;
      if (await wav.exists()) await wav.delete();
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    final p = _playing;
    if (p != null && !p.isCompleted) p.complete();
    await _player?.stop();
  }

  @override
  Future<void> close() async {
    await stop();
    await _player?.dispose();
    _player = null;
    await _worker.close();
    if (await _temp.exists()) await _temp.delete(recursive: true);
  }
}

/// Whether an answer is over: something was said (at least 1.5 s from the
/// first speech to the last), then [endSilence] of silence. A pause to
/// think shorter than [endSilence], however many, never ends it. Times are
/// milliseconds from the microphone opening; -1 is no speech yet.
bool answerEnded({
  required int heardMs,
  required int firstSpeechMs,
  required int lastSpeechMs,
  required Duration endSilence,
}) =>
    firstSpeechMs >= 0 &&
    lastSpeechMs - firstSpeechMs >= 1500 &&
    heardMs - lastSpeechMs >= endSilence.inMilliseconds;

/// What the listening isolate reports after each piece of audio: the
/// times, the stretches written down since the last report, and the words
/// so far of the stretch still being spoken (the live caption).
typedef _Heard = (
  int totalMs,
  int firstVoiceMs,
  int lastVoiceMs,
  List<(int, int, String)> segments,
  String partial,
);

/// How much new speech (in samples at 16 kHz) comes between two readings
/// of the stretch still being spoken: about every 1.2 s.
const partialEvery = 19200;

/// The longest tail of an open stretch read for the caption (the speech
/// detector cuts a stretch at 20 s anyway).
const partialMax = 16000 * 20;

/// The speech detector and the transcriber, on their own isolate. Requests:
/// 'reset' starts a new answer, a Float32List is more audio, 'finish' ends
/// the answer. Each stretch of speech is written down as soon as the
/// detector closes it.
EngineHandler _openEars(String vadModel, String transcriberFolder) {
  sherpa.initBindings();
  final rec = sherpa.OfflineRecognizer(moonshineConfig(transcriberFolder));
  sherpa.VoiceActivityDetector newVad() => sherpa.VoiceActivityDetector(
    config: sherpa.VadModelConfig(
      sileroVad: sherpa.SileroVadModelConfig(
        model: vadModel,
        minSilenceDuration: 0.5,
        // Long monologues are cut so each piece is written down while the
        // candidate is still talking.
        maxSpeechDuration: 20,
      ),
      sampleRate: 16000,
      debug: false,
    ),
    bufferSizeInSeconds: 60,
  );
  var vad = newVad();
  var pending = Float32List(0);
  var done = 0, first = -1, last = -1;
  const window = 512;
  int ms(int samples) => samples ~/ 16;

  // The stretch still being spoken, for the live caption: the windows
  // since speech was detected (with a short lead-in), read again every
  // [partialEvery] samples. A closed stretch replaces it.
  final lead = <Float32List>[];
  final open = <Float32List>[];
  var openSamples = 0, sinceRead = 0;
  var partial = '';
  void clearOpen() {
    open.clear();
    openSamples = 0;
    sinceRead = 0;
    partial = '';
  }

  List<(int, int, String)> drain() {
    final found = <(int, int, String)>[];
    while (!vad.isEmpty()) {
      final s = vad.front();
      found.add((ms(s.start), ms(s.start + s.samples.length), recognise(rec, s.samples)));
      vad.pop();
    }
    if (found.isNotEmpty) clearOpen();
    return found;
  }

  _Heard report(List<(int, int, String)> found) =>
      (ms(done), first < 0 ? -1 : ms(first), last < 0 ? -1 : ms(last), found, partial);

  void readOpen() {
    if (sinceRead < partialEvery || openSamples == 0) return;
    sinceRead = 0;
    var take = math.min(openSamples, partialMax);
    final tail = Float32List(take);
    for (var i = open.length - 1; i >= 0 && take > 0; i--) {
      final w = open[i];
      final n = math.min(w.length, take);
      tail.setRange(take - n, take, w, w.length - n);
      take -= n;
    }
    partial = recognise(rec, tail).trim();
  }

  return (request) {
    switch (request) {
      case engineCloseRequest:
        vad.free();
        rec.free();
        return null;
      case 'reset':
        vad.free();
        vad = newVad();
        pending = Float32List(0);
        done = 0;
        first = last = -1;
        lead.clear();
        clearOpen();
        return null;
      case 'finish':
        if (pending.isNotEmpty) {
          vad.acceptWaveform(Float32List(window)..setRange(0, pending.length, pending));
          done += pending.length;
          pending = Float32List(0);
        }
        vad.flush();
        final found = drain();
        clearOpen();
        return report(found);
      case final Float32List audio:
        final all = Float32List(pending.length + audio.length)
          ..setRange(0, pending.length, pending)
          ..setRange(pending.length, pending.length + audio.length, audio);
        var at = 0;
        final found = <(int, int, String)>[];
        for (; at + window <= all.length; at += window) {
          final w = Float32List.fromList(Float32List.sublistView(all, at, at + window));
          vad.acceptWaveform(w);
          done += window;
          if (vad.isDetected()) {
            if (first < 0) first = done - window;
            last = done;
            if (open.isEmpty) {
              open.addAll(lead);
              openSamples = lead.length * window;
            }
            open.add(w);
            openSamples += window;
            sinceRead += window;
          } else {
            lead.add(w);
            // About 0.25 s of lead-in, so the first word is not clipped.
            if (lead.length > 8) lead.removeAt(0);
          }
          found.addAll(drain());
        }
        pending = Float32List.fromList(Float32List.sublistView(all, at));
        readOpen();
        return report(found);
    }
    throw ArgumentError('Unknown request');
  };
}

/// Listens to answers: the microphone, live speech detection and the
/// transcriber, loaded once for the round.
class LiveListener implements AnswerListener {
  LiveListener._(this._worker, this.endSilence, this.maxLength);

  /// Loads the speech detector from [vadModel] and Moonshine from
  /// [transcriberFolder]. An answer ends by itself after [endSilence] of
  /// silence once something was said (each [listen] may set its own), or
  /// at [maxLength].
  static Future<LiveListener> open({
    required String vadModel,
    required String transcriberFolder,
    Duration endSilence = SpokenRound.defaultEndSilence,
    Duration maxLength = const Duration(minutes: 5),
  }) async => LiveListener._(
    await EngineWorker.start(() => _openEars(vadModel, transcriberFolder)),
    endSilence,
    maxLength,
  );

  final EngineWorker _worker;
  final Duration endSilence, maxLength;

  @override
  Future<AnswerCapture> listen({Duration? endSilence}) async {
    await _worker.call<void>('reset');
    final rec = AudioRecorder();
    try {
      if (!await rec.hasPermission()) {
        throw StateError('Udyoga may not use the microphone. Allow it in the system settings');
      }
      final stream = await rec.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
      );
      return _LiveCapture(rec, stream, _worker, endSilence ?? this.endSilence, maxLength);
    } on Object {
      await rec.dispose();
      rethrow;
    }
  }

  @override
  Future<void> close() => _worker.close();
}

class _LiveCapture implements AnswerCapture {
  _LiveCapture(this._rec, Stream<Uint8List> stream, this._worker, this._endSilence, this._maxLength) {
    _watch.start();
    _audio = stream.listen(_onAudio, onDone: _streamDone.complete, onError: (_) => _streamDone.complete());
    _levels = _rec.onAmplitudeChanged(const Duration(milliseconds: 150)).listen((a) {
      _level = a.current;
      _emit();
    });
  }

  final AudioRecorder _rec;
  final EngineWorker _worker;
  final Duration _endSilence, _maxLength;
  final _bytes = BytesBuilder(copy: false);
  final _segments = <SpokenSegment>[];
  final _status = StreamController<ListenStatus>.broadcast();
  final _end = Completer<void>();
  final _streamDone = Completer<void>();
  final _watch = Stopwatch();
  late final StreamSubscription<Uint8List> _audio;
  late final StreamSubscription<Amplitude> _levels;
  Future<void> _feeding = Future.value();
  double _level = -160;
  _Heard _heard = (0, -1, -1, const [], '');
  var _stopped = false;
  int? _odd;

  /// The first error from the speech engine, reported by [finish].
  Object? _error;

  void _onAudio(Uint8List chunk) {
    if (_stopped || chunk.isEmpty) return;
    _bytes.add(chunk);
    // The recorder may split a sample across chunks (on Linux it reads a
    // pipe), so an odd byte waits for the next chunk.
    var bytes = chunk;
    if (_odd case final b?) {
      bytes = Uint8List(chunk.length + 1)
        ..[0] = b
        ..setRange(1, chunk.length + 1, chunk);
      _odd = null;
    }
    if (bytes.length.isOdd) {
      _odd = bytes.last;
      bytes = Uint8List.sublistView(bytes, 0, bytes.length - 1);
    }
    if (bytes.isEmpty) return;
    final floats = pcm16ToFloat(bytes);
    _feeding = _feeding
        .then((_) => _worker.call<_Heard>(floats))
        .then(_take, onError: (Object e) => _error ??= e);
  }

  void _take(_Heard h) {
    _heard = h;
    for (final (start, end, text) in h.$4) {
      _segments.add(SpokenSegment(Duration(milliseconds: start), Duration(milliseconds: end), text));
    }
    _emit();
    final (total, first, last, _, _) = h;
    if (!_end.isCompleted &&
        (answerEnded(heardMs: total, firstSpeechMs: first, lastSpeechMs: last, endSilence: _endSilence) ||
            _watch.elapsed >= _maxLength)) {
      _end.complete();
    }
  }

  void _emit() {
    if (_status.isClosed) return;
    final (total, first, last, _, partial) = _heard;
    _status.add(
      ListenStatus(
        elapsed: _watch.elapsed,
        level: _level,
        heardSpeech: first >= 0,
        silence: last < 0 ? Duration.zero : Duration(milliseconds: total - last),
        heard: [for (final s in _segments) s.text],
        partial: partial,
      ),
    );
  }

  @override
  Stream<ListenStatus> get status => _status.stream;

  @override
  Future<void> get heardEnd => _end.future;

  Future<void> _stop() async {
    if (_stopped) return;
    _stopped = true;
    await _rec.stop();
    await _streamDone.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    await _audio.cancel();
    await _levels.cancel();
    await _rec.dispose();
    await _status.close();
  }

  @override
  Future<CapturedAnswer> finish() async {
    await _stop();
    await _feeding;
    if (_error case final e?) throw StateError('The speech engine failed: $e');
    _take(await _worker.call<_Heard>('finish'));
    return CapturedAnswer(Pcm(pcm16ToFloat(_bytes.takeBytes())), List.unmodifiable(_segments));
  }

  @override
  Future<void> cancel() async {
    await _stop();
    await _feeding;
    _bytes.clear();
  }
}

/// Recordings as WAV files under [dir], in the app's own data folder. Never
/// synced; the round screen deletes them when it closes.
class FileTakeStore implements TakeStore {
  FileTakeStore(this.dir);
  final Directory dir;

  @override
  Future<String> save(int question, int take, Pcm audio) async {
    await dir.create(recursive: true);
    final f = File('${dir.path}/q${question + 1}-take$take.wav');
    await f.writeAsBytes(wavBytes(audio), flush: true);
    return f.path;
  }

  @override
  Future<void> remove(String key) async {
    final f = File(key);
    if (f.parent.path == dir.path && await f.exists()) await f.delete();
  }

  @override
  Future<void> removeAll() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

/// Plays a recorded take.
class TakePlayer {
  AudioPlayer? _player;
  String? playing;

  Future<void> play(String key, {void Function()? onDone}) async {
    final p = _player ??= AudioPlayer();
    await p.stop();
    playing = key;
    p.onPlayerComplete.first.then((_) {
      if (playing == key) playing = null;
      onDone?.call();
    }).ignore();
    await p.play(DeviceFileSource(key));
  }

  Future<void> stop() async {
    playing = null;
    await _player?.stop();
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
