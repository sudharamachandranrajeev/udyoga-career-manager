/// A spoken practice round: the interviewer reads each question aloud, the
/// candidate answers by voice (or types), and each answer gets a transcript
/// and delivery measures. Re-takes are allowed; take 1 and the latest take
/// are kept for playback.
///
/// With an [Interviewer] (plan I2) the round behaves like a panel: after
/// each answer it picks a follow-up from what the answer is missing (at most
/// two), says its persona's acknowledgement after the persona's gap, and at
/// the top of the ladder stops an answer that runs over time and asks for a
/// one-sentence wrap-up.
///
/// The engines are interfaces so the state machine is tested with fakes;
/// round_engines.dart has the real ones. Recordings go to a [TakeStore] on
/// the device only. The only thing that leaves the round is the transcript
/// text, through [AnswerSink], so audio can never reach a synced table.
library;

import 'dart:async';
import 'dart:math' as math;

import '../domain/delivery.dart';
import '../domain/interview_plan.dart';
import '../domain/interview_process.dart' show QuestionOutcome;
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
    this.heard = const [],
    this.partial = '',
  });

  /// The stretches of speech written down so far, in order.
  final List<String> heard;

  /// The words so far of the stretch still being spoken: a draft that the
  /// written-down stretch replaces.
  final String partial;

  /// The live caption: everything written down, then the draft.
  String get caption => [...heard, partial].map((t) => t.trim()).where((t) => t.isNotEmpty).join(' ');

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
  /// Opens the microphone. The answer ends by itself after [endSilence]
  /// of silence once something was said; shorter pauses to think do not
  /// end it.
  Future<AnswerCapture> listen({Duration? endSilence});
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

enum FollowUpKind { probe, wrapUp }

/// A follow-up the interviewer asked about the latest take, and the answer.
class FollowUp {
  const FollowUp({required this.kind, required this.asked, required this.take, this.probe});
  final FollowUpKind kind;

  /// The question as shown ("What did you yourself do?").
  final String asked;
  final Probe? probe;
  final Take take;
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

  /// Follow-ups on the latest take, in order.
  final followUps = <FollowUp>[];

  /// The interviewer stopped the latest take to keep to time.
  bool interrupted = false;

  List<Probe> get probes => [for (final f in followUps) ?f.probe];

  /// Everything said for this question: the take and its follow-ups.
  String get heard =>
      [latest?.transcript ?? '', for (final f in followUps) f.take.transcript].join(' ').trim();

  /// The take and its follow-ups, labelled, as saved with the round.
  String get fullTranscript => [
    ?latest?.transcript,
    for (final f in followUps)
      '${f.kind == FollowUpKind.wrapUp ? 'Wrap-up' : 'Follow-up'}: "${f.asked}"\n${f.take.transcript}',
  ].join('\n\n');
}

/// How the interviewer behaves in a round (plan I2): the persona, the
/// ladder level, each question's plan and time, elements missed at an
/// earlier stage, and what is said before the first question.
class Interviewer {
  const Interviewer({
    required this.persona,
    required this.level,
    required this.plans,
    this.budgets = const [],
    this.focus = const [],
    this.opening = '',
  });

  final Persona persona;
  final Ladder level;

  /// One per question; the round's questions without one are not probed.
  final List<QuestionPlan> plans;

  /// The time for each question's main answer; null is untimed.
  final List<Duration?> budgets;

  /// Elements missed at an earlier stage: probed first.
  final List<AnswerElement> focus;

  /// Said before the first question (greeting and the interrupt script).
  final String opening;

  /// Follow-ups each question may get.
  int get probeLimit =>
      level.probes == 0 ? 0 : math.min(maxProbesPerQuestion, level.probes + (persona.extraProbe ? 1 : 0));

  QuestionPlan? plan(int i) => i < plans.length ? plans[i] : null;
  Duration? budget(int i) => i < budgets.length ? budgets[i] : null;

  /// When the interviewer stops answer [i], or null when they never do.
  Duration? interruptAt(int i) {
    final b = budget(i), after = level.interruptAfter;
    return b == null || after == null ? null : b + after;
  }

  Probe? nextProbe(int i, QuestionState s) {
    final p = plan(i);
    if (p == null) return null;
    return ProbePicker.next(plan: p, heard: s.heard, asked: s.probes, limit: probeLimit, focus: focus);
  }
}

enum _Answering { main, probe, wrapUp }

enum RoundPhase {
  /// The question and what it tests are on screen; nothing is playing.
  ready,

  /// The interviewer is speaking: the question, a follow-up, an
  /// interruption or an acknowledgement ([SpokenRound.saying]).
  asking,

  /// The panel's silence before it speaks again (the persona's gap).
  pausing,

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
    this.interviewer,
    this.endSilence = defaultEndSilence,
    Future<void> Function(Duration)? pause,
  }) : pause = pause ?? Future<void>.delayed,
       states = [for (final _ in questions) QuestionState()];

  /// Silence that ends an answer unless the round settings say otherwise.
  static const defaultEndSilence = Duration(seconds: 5);

  final List<RoundQuestion> questions;
  final InterviewerVoice voice;
  final AnswerListener listener;
  final TakeStore takes;
  final AnswerSink sink;
  final ContentCoach? coach;
  final List<QuestionState> states;

  /// Null: the plain I1 round (no follow-ups, nothing said between
  /// questions).
  final Interviewer? interviewer;

  /// Silence that ends a spoken answer.
  final Duration endSilence;

  /// Waits out the panel's gaps; tests pass a recorder.
  final Future<void> Function(Duration) pause;

  /// What the interviewer is saying now, while [phase] is asking.
  String? saying;

  var _answering = _Answering.main;
  String _asked = '';
  Probe? _probe;
  bool _openingSaid = false;
  bool _stopForTime = false;

  /// True while a follow-up or wrap-up is being answered.
  bool get followingUp => _answering != _Answering.main;

  /// True while the one-sentence wrap-up is being answered.
  bool get wrappingUp => _answering == _Answering.wrapUp;

  /// The follow-up being answered, as shown.
  String get followUpQuestion => _asked;

  /// The time for the answer being given, or null when untimed.
  Duration? get budget => switch (_answering) {
    _Answering.main => interviewer?.budget(_index),
    _Answering.wrapUp => wrapUpTime,
    _Answering.probe => null,
  };

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
    voice.prepare(_spoken(0));
    _set(RoundPhase.ready);
  }

  /// The question as said: the first one comes after the opening.
  String _spoken(int i) {
    final opening = interviewer?.opening ?? '';
    return i == 0 && !_openingSaid && opening.isNotEmpty
        ? '$opening ${questions[i].text}'
        : questions[i].text;
  }

  /// The interviewer reads the question, then the microphone opens. While
  /// the answer is given, the next question's audio is made.
  Future<void> ask() async {
    if (_phase != RoundPhase.ready && _phase != RoundPhase.review) return;
    error = null;
    final turn = ++_turn;
    _answering = _Answering.main;
    final text = _spoken(_index);
    if (_index == 0) _openingSaid = true;
    saying = text;
    _set(RoundPhase.asking);
    try {
      await voice.say(text);
    } on Object catch (e) {
      error = 'The interviewer voice failed: $e';
    }
    saying = null;
    // Typing, skipping or leaving while the question was read wins.
    if (turn != _turn || _phase != RoundPhase.asking || _closed) return;
    await _listen();
  }

  /// Opens the microphone without reading the question again.
  Future<void> answerNow() async {
    if (_phase != RoundPhase.ready && _phase != RoundPhase.review && _phase != RoundPhase.typing) return;
    // From the typing box a pending follow-up stays pending.
    if (_phase != RoundPhase.typing) _answering = _Answering.main;
    await _listen();
  }

  Future<void> _listen() async {
    error = null;
    _stopForTime = false;
    try {
      final c = _capture = await listener.listen(endSilence: endSilence);
      _set(RoundPhase.answering);
      final stopAt = _answering == _Answering.main ? interviewer?.interruptAt(_index) : null;
      _liveSub = c.status.listen((s) {
        live = s;
        _changed();
        if (stopAt != null && s.elapsed >= stopAt && identical(_capture, c) && !_stopForTime) {
          _stopForTime = true;
          unawaited(done());
        }
      });
      if (_answering == _Answering.main && _index + 1 < questions.length) {
        voice.prepare(questions[_index + 1].text);
      }
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
        // A follow-up can still be typed or moved past.
        _set(followingUp ? RoundPhase.typing : RoundPhase.ready);
        return;
      }
      final s = state;
      final delivery = DeliveryMetrics.of(answer.segments);
      if (followingUp) {
        s.followUps.add(_followUp(Take(number: s.takes, transcript: text, delivery: delivery)));
      } else {
        final number = s.takes + 1;
        final key = await takes.save(_index, number, answer.audio);
        await _keep(s, Take(number: number, transcript: text, delivery: delivery, audioKey: key));
        s.interrupted = _stopForTime;
      }
      _stopForTime = false;
      await sink.saveTranscript(_index, s.fullTranscript);
      await _afterAnswer();
    } on Object catch (e) {
      error = 'The answer could not be written down: $e';
      _set(RoundPhase.ready);
    }
  }

  FollowUp _followUp(Take take) => FollowUp(
    kind: _answering == _Answering.wrapUp ? FollowUpKind.wrapUp : FollowUpKind.probe,
    asked: _asked,
    probe: _probe,
    take: take,
  );

  /// What the panel does once an answer is in: the wrap-up after an
  /// interruption, else a follow-up for what is missing, else the persona's
  /// acknowledgement and the review.
  Future<void> _afterAnswer() async {
    final iv = interviewer;
    if (iv == null) {
      _answering = _Answering.main;
      _set(RoundPhase.review);
      return;
    }
    final s = state, turn = _turn;
    if (s.interrupted) {
      if (!s.followUps.any((f) => f.kind == FollowUpKind.wrapUp)) {
        return _ask(
          _Answering.wrapUp,
          interruptLine,
          'Could you sum that up in one sentence?',
          null,
          Duration.zero,
          turn,
        );
      }
    } else if (iv.nextProbe(_index, s) case final p?) {
      return _ask(
        _Answering.probe,
        '${iv.persona.probeLead}${p.text}',
        p.text,
        p,
        iv.persona.gapBeforeProbe,
        turn,
      );
    }
    await _closeQuestion(turn);
  }

  /// The interviewer asks a follow-up after [gap], then the answer is
  /// heard (or typed, when the take was typed).
  Future<void> _ask(
    _Answering kind,
    String spoken,
    String shown,
    Probe? probe,
    Duration gap,
    int turn,
  ) async {
    _answering = kind;
    _asked = shown;
    _probe = probe;
    voice.prepare(spoken);
    if (gap > Duration.zero) {
      _set(RoundPhase.pausing);
      await pause(gap);
      if (turn != _turn || _closed) return;
    }
    saying = spoken;
    _set(RoundPhase.asking);
    try {
      await voice.say(spoken);
    } on Object catch (e) {
      error = 'The interviewer voice failed: $e';
    }
    saying = null;
    if (turn != _turn || _phase != RoundPhase.asking || _closed) return;
    if (state.latest?.typed ?? false) {
      _set(RoundPhase.typing);
      return;
    }
    await _listen();
  }

  /// The question is over: the persona's gap, its acknowledgement, then
  /// the review.
  Future<void> _closeQuestion(int turn) async {
    final iv = interviewer!;
    _answering = _Answering.main;
    _probe = null;
    _asked = '';
    final ack = iv.persona.acknowledgement(_index);
    if (ack.isNotEmpty) voice.prepare(ack);
    _set(RoundPhase.pausing);
    await pause(iv.persona.gapAfterAnswer);
    if (turn != _turn || _closed) return;
    if (ack.isNotEmpty) {
      saying = ack;
      _set(RoundPhase.asking);
      try {
        await voice.say(ack);
      } on Object {
        // An unsaid "thank you" is no loss.
      }
      saying = null;
      if (turn != _turn || _phase != RoundPhase.asking || _closed) return;
    }
    _set(RoundPhase.review);
  }

  /// Moves past the follow-up being asked or answered: the question ends.
  Future<void> moveOn() async {
    if (!followingUp || _phase == RoundPhase.transcribing || _phase == RoundPhase.finished) return;
    final turn = ++_turn;
    if (_phase == RoundPhase.asking) await voice.stop();
    await _dropCapture();
    error = null;
    await _closeQuestion(turn);
  }

  /// Take 1 stays; the previous latest goes unless it is take 1.
  Future<void> _keep(QuestionState s, Take take) async {
    s.takes = take.number;
    s.skipped = false;
    s.note = null;
    s.noteError = null;
    s.followUps.clear();
    s.interrupted = false;
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

  /// Switches to typing; a recording in progress is thrown away. A
  /// follow-up being asked stays the one to answer.
  Future<void> typeInstead() async {
    if (_phase == RoundPhase.finished || _phase == RoundPhase.transcribing) return;
    _turn++;
    if (_phase == RoundPhase.asking) await voice.stop();
    saying = null;
    await _dropCapture();
    // Typing from the review starts a new take of the question.
    if (_phase == RoundPhase.review || _phase == RoundPhase.ready) _answering = _Answering.main;
    error = null;
    _set(RoundPhase.typing);
  }

  /// A typed answer: transcript only, no delivery measures.
  Future<void> submitTyped(String text) async {
    final t = text.trim();
    if (_phase != RoundPhase.typing || t.isEmpty) return;
    final s = state;
    if (followingUp) {
      s.followUps.add(_followUp(Take(number: s.takes, transcript: t, typed: true)));
    } else {
      await _keep(s, Take(number: s.takes + 1, transcript: t, typed: true));
    }
    await sink.saveTranscript(_index, s.fullTranscript);
    await _afterAnswer();
  }

  /// One strength and one fix for the latest take's transcript.
  Future<void> askCoach() async {
    final c = coach, take = state.latest;
    if (c == null || take == null || coaching) return;
    coaching = true;
    state.noteError = null;
    _changed();
    try {
      state.note = await c.feedback(_index, question, state.fullTranscript);
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
    saying = null;
    _answering = _Answering.main;
    _probe = null;
    _asked = '';
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

  /// The elements question [i] calls for that its answers covered, from
  /// its plan; null without an interviewer or before an answer.
  ({List<AnswerElement> expected, Set<AnswerElement> heard})? coverage(int i) {
    final plan = interviewer?.plan(i), s = states[i];
    if (plan == null || s.latest == null) return null;
    return (expected: plan.expected, heard: detectElements(s.heard));
  }

  /// What each answered question covered, for the next stage.
  List<QuestionOutcome> outcomes() => [
    for (final (i, s) in states.indexed)
      if (coverage(i) case final c?)
        QuestionOutcome(expected: c.expected, heard: c.heard, interrupted: s.interrupted),
  ];

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
