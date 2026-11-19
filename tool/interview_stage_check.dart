// Runs one short interview stage (I2) with the real engines: the panel's
// opening, a settler, follow-up questions picked from what an answer
// leaves out, and an interruption with a one-sentence wrap-up. The
// candidate's answers are made with a second Kokoro voice and played into
// the microphone. Prints what happened as JSON. Not part of the app.
//
//   flutter build linux --release -t tool/interview_stage_check.dart
//   PULSE_SOURCE=<sink>.monitor build/linux/x64/release/bundle/udyoga --sink <sink>
//
// --offline runs it as offline interview practice (I6): the app's
// OfflineGuard holds for the whole run, a model download is tried and must
// be refused, the debrief is built with no AI (the matcher on the device),
// and Ollama is asked at its default address on this machine. The counts
// of refused connections and of HTTP clients made are printed.
//
// Make the sink first: pactl load-module module-null-sink sink_name=<sink>.
// Without --sink the answers play through the speakers. Every answer is
// fictional. Recordings and the made answers go to temporary folders that
// are deleted at the end.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/interview_process.dart';
import 'package:udyoga/domain/interview_scoring.dart';
import 'package:udyoga/domain/offline_guard.dart';
import 'package:udyoga/domain/ollama.dart';
import 'package:udyoga/voice/lab.dart' show Pcm;
import 'package:udyoga/voice/lexicon.dart';
import 'package:udyoga/voice/models.dart';
import 'package:udyoga/voice/native_engines.dart';
import 'package:udyoga/voice/round.dart';
import 'package:udyoga/voice/round_engines.dart';

/// The candidate's voice: a different Kokoro speaker from the panel's.
const _candidateVoice = 26;

const _pause = '<pause>';

/// What the candidate says, by what was asked. [_pause] is 3.5 s of
/// silence: a pause to think, under the 5 s that ends an answer.
const _answers = {
  'settler': 'I work on the front desk at a small clinic. I enjoy helping people find their way.',
  'short':
      'At the time our clinic was short of staff one weekend. I rang the bank staff and I moved the training '
      'day. $_pause Then I told the manager, and every shift was covered.',
  'measure': 'We counted the complaints about cover. They fell from six to one that month.',
  'learning': 'I learned to keep a list of bank staff ready, so next time I would ask sooner.',
  'other': 'I asked the team what they needed and I checked in with them each day.',
  'long':
      'Last spring our team had a large backlog of letters to send. I sorted the letters by date and I split '
      'them into three groups. I asked two people to help with the oldest group, and I took the newest group '
      'myself. Each morning we met for five minutes to check where we were. Halfway through, the printer broke, '
      'so I moved the work to the second office and I told the manager what had changed. We kept going like that '
      'for two weeks, and by the end the pile was gone and the letters went out on time.',
  'wrapUp': 'In short, I split the backlog, I kept everyone on track, and the letters went out on time.',
};

final _stage = nhsStyle.stages[0].copyWith(
  answerTime: const Duration(seconds: 30),
  questions: const [
    PracticeQuestion({
      'question': 'Tell us about a time you covered a gap at short notice.',
      'category': 'Behavioural',
      'why': 'Flexibility and organisation under pressure.',
    }),
    PracticeQuestion({
      'question': 'Tell us about a time you cleared a backlog of work.',
      'category': 'Behavioural',
      'why': 'Planning and working with others.',
    }),
  ],
);

class _Sink implements AnswerSink {
  final saved = <int, String>{};
  @override
  Future<void> saveTranscript(int question, String text) async => saved[question] = text;
}

/// The panel's voice, with a log of what it said and when.
class _LoggedVoice implements InterviewerVoice {
  _LoggedVoice(this.inner, this.clock, this.log);
  final KokoroVoice inner;
  final Stopwatch clock;
  final List<String> log;
  @override
  void prepare(String text) => inner.prepare(text);
  @override
  Future<void> say(String text) async {
    log.add('${(clock.elapsedMilliseconds / 1000).toStringAsFixed(1)}s panel: $text');
    await inner.say(text);
  }

  @override
  Future<void> stop() => inner.stop();
  @override
  Future<void> close() => inner.close();
}

/// Makes each fictional answer as a WAV with the candidate's voice.
Future<Map<String, String>> _makeAnswers(String folder, Directory into) async {
  final texts = [for (final t in _answers.values) t.replaceAll(_pause, '')];
  final extra = extraLexicon(File('$folder/lexicon-gb-en.txt').readAsStringSync(), texts);
  final extraPath = '${into.path}/extra-lexicon.txt';
  File(extraPath).writeAsStringSync(extra);
  sherpa.initBindings();
  final tts = sherpa.OfflineTts(kokoroConfig(folder, extraLexicon: extra.isEmpty ? null : extraPath));
  final out = <String, String>{};
  try {
    for (final MapEntry(:key, :value) in _answers.entries) {
      final parts = <double>[];
      var rate = 24000;
      for (final (i, part) in value.split(_pause).indexed) {
        if (i > 0) parts.addAll(List.filled((rate * 3.5).round(), 0));
        final a = tts.generate(text: part.trim(), sid: _candidateVoice);
        rate = a.sampleRate;
        parts.addAll(a.samples);
      }
      final f = File('${into.path}/$key.wav');
      await f.writeAsBytes(wavBytes(Pcm(Float32List.fromList(parts), sampleRate: rate)));
      out[key] = f.path;
    }
  } finally {
    tts.free();
  }
  return out;
}

/// Offline practice's checks before the round: a download must be refused,
/// and a request to another machine must be refused without a packet.
Future<Map<String, Object?>> _offlineBefore(ModelManager mm) async {
  final out = <String, Object?>{'guardActive': OfflineGuard.instance.active};
  try {
    await mm.download(speechModel(vadModelId));
    out['download'] = 'NOT refused';
  } on ModelException catch (e) {
    out['download'] = 'refused: ${e.message}';
  }
  final client = HttpClient();
  try {
    await client.getUrl(Uri.parse('https://example.com/'));
    out['httpToAnotherMachine'] = 'NOT refused';
  } on SocketException catch (e) {
    out['httpToAnotherMachine'] = 'refused: ${e.message}';
  } finally {
    client.close(force: true);
  }
  return out;
}

/// After the round: the debrief with no AI, and the local model's state.
Future<Map<String, Object?>> _offlineAfter(List<PracticeQuestion> questions, Map<int, String> saved) async {
  final d = Debrief.build(
    framework: Framework.of('private'),
    round: DebriefRound.of(questions: questions, answers: saved),
  );
  final ollama = await Ollama(host: ollamaDefaultHost, model: ollamaDefaultModel).check();
  return {
    'debrief': {
      'aiScored': d.aiScored,
      'coverage': [for (final c in d.coverage) '${c.criterion.text}: ${c.status.label}'],
      'notes': [
        for (final n in d.notes) {'question': n.question, 'strength': n.strength, 'fix': n.fix},
      ],
    },
    'ollama': {'host': ollamaDefaultHost, 'state': ollama.state.name, 'message': ollama.message},
    'refused': OfflineGuard.instance.refused,
    'refusedHosts': OfflineGuard.instance.refusedHosts,
    'httpClientsMade': OfflineGuard.instance.clients,
  };
}

Future<Map<String, Object?>> _run(List<String> args) async {
  final offline = args.contains('--offline');
  if (offline) OfflineGuard.instance.hold();
  final base = await getApplicationSupportDirectory();
  final mm = ModelManager(Directory('${base.path}/models'));
  for (final id in [voiceModelId, vadModelId, defaultTranscriber]) {
    if (!await mm.installed(speechModel(id))) throw StateError('Missing model $id');
  }
  final before = offline ? await _offlineBefore(mm) : null;
  final sinkAt = args.indexOf('--sink');
  final sinkName = sinkAt >= 0 && sinkAt + 1 < args.length ? args[sinkAt + 1] : null;
  final voiceFolder = mm.folder(speechModel(voiceModelId));
  final clips = await Directory.systemTemp.createTemp('udyoga-stage-answers-');
  final temp = await Directory.systemTemp.createTemp('udyoga-stage-check-');
  final out = <String, Object?>{'offlineBefore': ?before};
  try {
    final wavs = await _makeAnswers(voiceFolder, clips);

    const level = 5;
    final ladderLevel = Ladder.of(level);
    final persona = Persona.of(_stage.persona);
    final questions = _stage.roundQuestions();
    final plans = mergePlans(questions, const []);
    final opening = _stage.opening(persona, ladderLevel);
    final interviewer = Interviewer(
      persona: persona,
      level: ladderLevel,
      plans: plans,
      budgets: [for (final q in questions) answerBudget(q, ladderLevel)],
      opening: opening,
    );
    out['stage'] = _stage.title;
    out['persona'] = persona.label;
    out['level'] = '${ladderLevel.level} ${ladderLevel.label}';
    out['budgets'] = [for (var i = 0; i < questions.length; i++) interviewer.budget(i)?.inSeconds];
    out['interruptAt'] = [for (var i = 0; i < questions.length; i++) interviewer.interruptAt(i)?.inSeconds];

    final clock = Stopwatch()..start();
    final log = <String>[];
    final voice = _LoggedVoice(
      await KokoroVoice.open(
        voiceFolder,
        texts: [
          opening,
          for (final q in questions) q.question,
          for (final list in builtInProbes.values) ...list,
          ...persona.acknowledgements,
          persona.probeLead,
          interruptLine,
        ],
      ),
      clock,
      log,
    );
    final listener = await LiveListener.open(
      vadModel: mm.path(speechModel(vadModelId)),
      transcriberFolder: mm.folder(speechModel(defaultTranscriber)),
    );
    final sink = _Sink();
    final round = SpokenRound(
      questions: [for (final q in questions) RoundQuestion(q.question, tests: q.why)],
      voice: voice,
      listener: listener,
      takes: FileTakeStore(temp),
      sink: sink,
      interviewer: interviewer,
    )..start();

    Future<void> until(bool Function() ok, Duration limit) async {
      if (ok()) return;
      final hit = Completer<void>();
      final sub = round.changes.listen((_) {
        if (ok() && !hit.isCompleted) hit.complete();
      });
      try {
        await hit.future.timeout(limit);
      } finally {
        await sub.cancel();
      }
    }

    String clipFor(int i) {
      if (round.wrappingUp) return 'wrapUp';
      if (round.followingUp) {
        final asked = round.followUpQuestion;
        final element = builtInProbes.entries.where((e) => e.value.any(asked.endsWith));
        return switch (element.firstOrNull?.key) {
          AnswerElement.measure => 'measure',
          AnswerElement.learning => 'learning',
          _ => 'other',
        };
      }
      return switch (i) {
        0 => 'settler',
        1 => 'short',
        _ => 'long',
      };
    }

    final perQuestion = <Map<String, Object?>>[];
    for (var i = 0; i < questions.length; i++) {
      unawaited(round.ask());
      final turns = <Map<String, Object?>>[];
      while (true) {
        await until(
          () =>
              round.phase == RoundPhase.answering || round.phase == RoundPhase.review || round.error != null,
          const Duration(seconds: 60),
        );
        if (round.phase != RoundPhase.answering) break;
        final clip = clipFor(i);
        final turn = <String, Object?>{'played': clip, 'micOpenAt': '${clock.elapsedMilliseconds / 1000}s'};
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        final player = await Process.start('pw-play', [
          if (sinkName != null) '--target=$sinkName',
          wavs[clip]!,
        ]);
        var clipDone = false;
        final played = player.exitCode.then((_) {
          clipDone = true;
          return clock.elapsedMilliseconds;
        });
        try {
          await until(() => round.phase != RoundPhase.answering, const Duration(seconds: 70));
        } on TimeoutException {
          await round.done();
          turn['endedBy'] = 'timeout, Done';
        }
        final endedAt = clock.elapsedMilliseconds;
        // The answer ended while the candidate was still talking: only the
        // interviewer stops an answer that way.
        final stoppedEarly = !clipDone;
        if (stoppedEarly) player.kill();
        final finished = await played;
        turn['answerEndedAt'] = '${endedAt / 1000}s';
        turn['clipFinishedAt'] = '${finished / 1000}s';
        turn['endedBy'] ??= stoppedEarly ? 'interviewer interrupted' : 'speech detector';
        if (!stoppedEarly) turn['silenceBeforeEndMs'] = endedAt - finished;
        turns.add(turn);
      }
      final st = round.state;
      perQuestion.add({
        'question': questions[i].question,
        'turns': turns,
        'mainTranscript': st.latest?.transcript,
        'followUps': [
          for (final f in st.followUps) {'kind': f.kind.name, 'asked': f.asked, 'heard': f.take.transcript},
        ],
        'interrupted': st.interrupted,
        'covered': round.coverage(i)?.heard.map((e) => e.label).toList(),
        'error': round.error,
      });
      if (round.phase != RoundPhase.review) break;
      round.next();
    }
    out['said'] = log;
    out['questions'] = perQuestion;
    final carry = CarryForward.from([round.outcomes()]);
    out['carryForward'] = {
      'fixes': carry.fixes,
      'keep': carry.keep,
      'focus': carry.focus.map((e) => e.name).toList(),
    };
    out['savedTranscripts'] = sink.saved.map((k, v) => MapEntry('$k', v));
    if (offline) out['offlineAfter'] = await _offlineAfter(questions, sink.saved);
    out['takeFiles'] = temp.listSync().length;
    await round.deleteRecordings();
    out['takeFolderAfterDelete'] = await temp.exists();
    await round.close();
  } finally {
    if (await clips.exists()) await clips.delete(recursive: true);
    if (await temp.exists()) await temp.delete(recursive: true);
  }
  return out;
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Interview stage check running…'))),
    ),
  );
  Map<String, Object?> result;
  try {
    result = await _run(args);
  } on Object catch (e, st) {
    result = {'error': '$e', 'stack': '$st'};
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  exit(result.containsKey('error') ? 1 : 0);
}
