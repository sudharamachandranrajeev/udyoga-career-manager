/// The interview lab (developer only): one run of the speech pipeline the
/// interview simulator will use, with each step timed.
///
/// record 10 s of mic -> find speech (VAD) -> transcribe (Whisper) ->
/// speak a sentence (the Kokoro voice). The camera and face box run beside it.
///
/// The engines are interfaces so the state machine can be tested with
/// fakes; native_engines.dart has the real ones. Audio stays in memory,
/// except for one temporary WAV that the transcriber reads and that is
/// deleted straight after.
library;

import 'dart:async';
import 'dart:typed_data';

/// Mono 16 kHz samples in -1..1.
class Pcm {
  const Pcm(this.samples, {this.sampleRate = 16000});
  final Float32List samples;
  final int sampleRate;
  Duration get length => Duration(microseconds: samples.length * 1000000 ~/ sampleRate);
}

/// A stretch of speech, from the start of the recording.
class SpeechSpan {
  const SpeechSpan(this.start, this.end);
  final Duration start, end;
  Duration get length => end - start;
}

abstract class MicRecorder {
  /// Records [length] from the default microphone. [level] gets the input
  /// level (dBFS) while it records.
  Future<Pcm> record(Duration length, {void Function(double dbfs)? level});
}

abstract class SpeechDetector {
  Future<List<SpeechSpan>> spans(Pcm audio);
}

class Transcript {
  const Transcript(this.text, this.took);
  final String text;
  final Duration took;
}

abstract class Transcriber {
  /// The model it uses, for the timing table.
  String get model;
  Future<Transcript> transcribe(Pcm audio);
}

class SpeechTiming {
  const SpeechTiming({
    required this.firstAudio,
    required this.synthesis,
    required this.audio,
    this.load = Duration.zero,
  });

  /// Loading the voice (once per round in the simulator).
  final Duration load;

  /// From asking (voice loaded) to the first samples being ready to play.
  final Duration firstAudio;

  /// The whole synthesis.
  final Duration synthesis;

  /// Length of the speech produced.
  final Duration audio;
}

abstract class Speaker {
  /// Speaks [text] and returns when it has been handed to the player.
  Future<SpeechTiming> speak(String text);
}

enum LabStep { idle, recording, detecting, transcribing, speaking, done, failed }

/// What one run found, step by step.
class LabResult {
  LabResult();
  Pcm? audio;
  List<SpeechSpan> spans = const [];
  Transcript? transcript;
  SpeechTiming? speech;
  String? error;
  LabStep? failedAt;

  Duration get speechTotal => spans.fold(Duration.zero, (a, s) => a + s.length);
}

/// Runs the speech steps one after another and reports each change.
class InterviewLab {
  InterviewLab({
    required this.recorder,
    required this.detector,
    required this.transcriber,
    required this.speaker,
    this.recordFor = const Duration(seconds: 10),
    this.sentence =
        'Thank you for coming in today. Tell us about a time you made a difference for a patient.',
  });

  final MicRecorder recorder;
  final SpeechDetector detector;
  final Transcriber transcriber;
  final Speaker speaker;
  final Duration recordFor;
  final String sentence;

  final _changes = StreamController<LabStep>.broadcast();

  /// Every step change, as it happens.
  Stream<LabStep> get changes => _changes.stream;

  LabStep _step = LabStep.idle;
  LabStep get step => _step;

  LabResult _result = LabResult();
  LabResult get result => _result;

  /// The last input level while recording (dBFS).
  double level = -160;

  bool get busy => switch (_step) {
    LabStep.recording || LabStep.detecting || LabStep.transcribing || LabStep.speaking => true,
    _ => false,
  };

  void _go(LabStep s) {
    _step = s;
    if (!_changes.isClosed) _changes.add(s);
  }

  /// One full run. A step that throws stops the run at that step; the
  /// steps before it keep their results. Refuses to start while busy.
  Future<LabResult> run() async {
    if (busy) throw StateError('The lab is already running.');
    final r = _result = LabResult();
    Future<void> stepThrough(LabStep s, Future<void> Function() body) async {
      _go(s);
      await body();
    }

    try {
      await stepThrough(LabStep.recording, () async {
        r.audio = await recorder.record(recordFor, level: (db) => level = db);
      });
      await stepThrough(LabStep.detecting, () async => r.spans = await detector.spans(r.audio!));
      if (r.spans.isEmpty) {
        // Nothing said: no transcript, but the voice still runs.
        r.transcript = const Transcript('', Duration.zero);
      } else {
        await stepThrough(
          LabStep.transcribing,
          () async => r.transcript = await transcriber.transcribe(r.audio!),
        );
      }
      await stepThrough(LabStep.speaking, () async => r.speech = await speaker.speak(sentence));
      _go(LabStep.done);
    } on Object catch (e) {
      r
        ..failedAt = _step
        ..error = '$e';
      _go(LabStep.failed);
    }
    return r;
  }

  Future<void> dispose() => _changes.close();
}
