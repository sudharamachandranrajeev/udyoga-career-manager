/// A spoken practice round: the interviewer reads each question aloud, the
/// candidate answers by voice (or types), and each answer gets a transcript
/// and delivery measures. Re-takes are allowed; take 1 and the latest take
/// are kept for playback.
///
/// The engines are interfaces so the state machine is tested with fakes;
/// round_engines.dart has the real ones. Recordings go to a [TakeStore] on
/// the device only. The only thing that leaves the round is the transcript
/// text, through [AnswerSink], so audio can never reach a synced table.
library;

import 'dart:async';

import '../domain/delivery.dart';
import 'lab.dart' show Pcm;

/// One question of the round and what it tests (plan rule 2: shown before
/// the answer).
class RoundQuestion {
  const RoundQuestion(this.text, {this.tests = '', this.lookFor = const []});
  final String text;
  final String tests;
  final List<String> lookFor;
}

/// The interviewer's voice, kept loaded for the whole round.
abstract class InterviewerVoice {
  /// Starts making the audio for [text] so [say] can start at once.
  void prepare(String text);

  /// Reads [text] aloud, a sentence at a time, and returns when it has
  /// finished (or [stop] was called).
  Future<void> say(String text);

  Future<void> stop();
  Future<void> close();
}

/// What the microphone heard while an answer was being given.
class ListenStatus {
  const ListenStatus({
    required this.elapsed,
    this.level = -160,
    this.heardSpeech = false,
    this.silence = Duration.zero,
  });

  final Duration elapsed;

  /// Input level, dBFS.
  final double level;

  /// True once any speech was detected.
  final bool heardSpeech;

  /// Silence since the last speech.
  final Duration silence;
}

/// A finished answer: the audio and the transcript, stretch by stretch.
class CapturedAnswer {
  const CapturedAnswer(this.audio, this.segments);
  final Pcm audio;
  final List<SpokenSegment> segments;
  String get transcript => segments.map((s) => s.text.trim()).where((t) => t.isNotEmpty).join(' ');
}

/// One answer being recorded.
abstract class AnswerCapture {
  Stream<ListenStatus> get status;

  /// Completes when the speech detector hears the end of the answer.
  Future<void> get heardEnd;

  /// Stops recording and returns the answer.
  Future<CapturedAnswer> finish();

  /// Stops recording and throws the audio away.
  Future<void> cancel();
}

abstract class AnswerListener {
  Future<AnswerCapture> listen();
  Future<void> close();
}

/// Where recordings are kept: the device only, never synced.
abstract class TakeStore {
  /// Saves [audio] as take [take] of question [question]; returns its key.
  Future<String> save(int question, int take, Pcm audio);
  Future<void> remove(String key);
  Future<void> removeAll();
}

/// Where a finished answer's text goes (the practice round's answers).
/// Text only: there is no way to hand it audio.
abstract class AnswerSink {
  Future<void> saveTranscript(int question, String text);
}

/// One strength and one task-level fix (plan rule 6).
class ContentNote {
  const ContentNote(this.strength, this.fix);
  final String strength;
  final String fix;
}

/// Content feedback on the transcript (the AI, when the user has one).
abstract class ContentCoach {
  Future<ContentNote> feedback(int question, RoundQuestion q, String answer);
}

/// One go at a question.
class Take {
  Take({required this.number, required this.transcript, this.delivery, this.audioKey, this.typed = false});
  final int number;
  final String transcript;
  final DeliveryMetrics? delivery;

  /// The recording in the [TakeStore]; null when typed or deleted.
  String? audioKey;
  final bool typed;
}

/// What happened at one question.
class QuestionState {
  /// The first take and the latest; a middle take is dropped when a newer
  /// one comes in.
  Take? first, latest;
  int takes = 0;
  bool skipped = false;
  ContentNote? note;
  String? noteError;
}

enum RoundPhase {
  /// The question and what it tests are on screen; nothing is playing.
  ready,

  /// The interviewer is reading the question.
  asking,

  /// Recording the answer.
  answering,

  /// Writing the answer down.
  transcribing,

  /// The answer box is open for a typed answer.
  typing,

  /// Transcript, delivery and feedback are shown.
  review,

  /// Every question has been answered or skipped.
  finished,
}

class SpokenRound {
  SpokenRound({
    required this.questions,
    required this.voice,
    required this.listener,
    required this.takes,
    required this.sink,
    this.coach,
  }) : states = [for (final _ in questions) QuestionState()];

  final List<RoundQuestion> questions;
  final InterviewerVoice voice;
  final AnswerListener listener;
  final TakeStore takes;
  final AnswerSink sink;
  final ContentCoach? coach;
  final List<QuestionState> states;

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;

  RoundPhase _phase = RoundPhase.ready;
  RoundPhase get phase => _phase;
  int _index = 0;
  int get index => _index;
  RoundQuestion get question => questions[_index];
  QuestionState get state => states[_index];

  /// The live microphone while answering.
  ListenStatus? live;
  String? error;
  bool coaching = false;

  AnswerCapture? _capture;

  /// Bumped by anything that interrupts the interviewer.
  var _turn = 0;
  StreamSubscription<ListenStatus>? _liveSub;
  bool _closed = false;

  void _set(RoundPhase p) {
    _phase = p;
    _changed();
  }

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Gets the first question ready to be read.
  void start() {
    if (questions.isEmpty) {
      _set(RoundPhase.finished);
      return;
    }
    voice.prepare(question.text);
    _set(RoundPhase.ready);
  }

  /// The interviewer reads the question, then the microphone opens. While
  /// the answer is given, the next question's audio is made.
  Future<void> ask() async {
    if (_phase != RoundPhase.ready && _phase != RoundPhase.review) return;
    error = null;
    final turn = ++_turn;
    _set(RoundPhase.asking);
    try {
      await voice.say(question.text);
    } on Object catch (e) {
      error = 'The interviewer voice failed: $e';
    }
    // Typing, skipping or leaving while the question was read wins.
    if (turn != _turn || _phase != RoundPhase.asking || _closed) return;
    await _listen();
  }

  /// Opens the microphone without reading the question again.
  Future<void> answerNow() async {
    if (_phase != RoundPhase.ready && _phase != RoundPhase.review && _phase != RoundPhase.typing) return;
    await _listen();
  }

  Future<void> _listen() async {
    error = null;
    try {
      final c = _capture = await listener.listen();
      _set(RoundPhase.answering);
      _liveSub = c.status.listen((s) {
        live = s;
        _changed();
      });
      if (_index + 1 < questions.length) voice.prepare(questions[_index + 1].text);
      unawaited(
        c.heardEnd.then((_) {
          if (identical(_capture, c) && _phase == RoundPhase.answering) return done();
        }),
      );
    } on Object catch (e) {
      error = 'The microphone did not open: $e. You can type your answer instead.';
      _set(RoundPhase.typing);
    }
  }

  /// The candidate says the answer is finished (or the detector heard the
  /// end).
  Future<void> done() async {
    final c = _capture;
    if (c == null || _phase != RoundPhase.answering) return;
    _capture = null;
    _set(RoundPhase.transcribing);
    await _liveSub?.cancel();
    _liveSub = null;
    live = null;
    try {
      final answer = await c.finish();
      final text = answer.transcript;
      if (text.isEmpty) {
        error = 'No speech was heard. Try again, or type your answer.';
        _set(RoundPhase.ready);
        return;
      }
      final s = state;
      final number = s.takes + 1;
      final key = await takes.save(_index, number, answer.audio);
      final take = Take(
        number: number,
        transcript: text,
        delivery: DeliveryMetrics.of(answer.segments),
        audioKey: key,
      );
      await _keep(s, take);
      await sink.saveTranscript(_index, text);
      _set(RoundPhase.review);
    } on Object catch (e) {
      error = 'The answer could not be written down: $e';
      _set(RoundPhase.ready);
    }
  }

  /// Take 1 stays; the previous latest goes unless it is take 1.
  Future<void> _keep(QuestionState s, Take take) async {
    s.takes = take.number;
    s.skipped = false;
    s.note = null;
    s.noteError = null;
    if (s.first == null) {
      s.first = take;
      s.latest = take;
      return;
    }
    final old = s.latest;
    if (old != null && !identical(old, s.first) && old.audioKey != null) {
      await takes.remove(old.audioKey!);
      old.audioKey = null;
    }
    s.latest = take;
  }

  /// Answer this question again; take 1 is kept for comparison.
  Future<void> retake() async {
    if (_phase != RoundPhase.review && _phase != RoundPhase.ready) return;
    await ask();
  }

  /// Switches to typing; a recording in progress is thrown away.
  Future<void> typeInstead() async {
    if (_phase == RoundPhase.finished || _phase == RoundPhase.transcribing) return;
    _turn++;
    if (_phase == RoundPhase.asking) await voice.stop();
    await _dropCapture();
    error = null;
    _set(RoundPhase.typing);
  }

  /// A typed answer: transcript only, no delivery measures.
  Future<void> submitTyped(String text) async {
    final t = text.trim();
    if (_phase != RoundPhase.typing || t.isEmpty) return;
    final s = state;
    await _keep(s, Take(number: s.takes + 1, transcript: t, typed: true));
    await sink.saveTranscript(_index, t);
    _set(RoundPhase.review);
  }

  /// One strength and one fix for the latest take's transcript.
  Future<void> askCoach() async {
    final c = coach, take = state.latest;
    if (c == null || take == null || coaching) return;
    coaching = true;
    state.noteError = null;
    _changed();
    try {
      state.note = await c.feedback(_index, question, take.transcript);
    } on Object catch (e) {
      state.noteError = '$e';
    } finally {
      coaching = false;
      _changed();
    }
  }

  /// Moves on without an answer.
  Future<void> skip() async {
    if (_phase == RoundPhase.finished || _phase == RoundPhase.transcribing) return;
    _turn++;
    if (_phase == RoundPhase.asking) await voice.stop();
    await _dropCapture();
    if (state.latest == null) state.skipped = true;
    _advance();
  }

  /// To the next question (after a review).
  void next() {
    if (_phase != RoundPhase.review) return;
    _advance();
  }

  void _advance() {
    error = null;
    if (_index + 1 >= questions.length) {
      _set(RoundPhase.finished);
      return;
    }
    _index++;
    voice.prepare(question.text);
    _set(RoundPhase.ready);
  }

  Future<void> _dropCapture() async {
    final c = _capture;
    _capture = null;
    await _liveSub?.cancel();
    _liveSub = null;
    live = null;
    if (c != null) await c.cancel();
  }

  /// Deletes every recording of this round; transcripts stay.
  Future<void> deleteRecordings() async {
    await takes.removeAll();
    for (final s in states) {
      s.first?.audioKey = null;
      s.latest?.audioKey = null;
    }
    _changed();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _turn++;
    await _dropCapture();
    await voice.stop();
    await voice.close();
    await listener.close();
    await _changes.close();
  }
}
