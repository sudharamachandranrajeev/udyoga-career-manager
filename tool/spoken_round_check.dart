// Runs one spoken round with the real engines and the real microphone, and
// prints what happened as JSON. Not part of the app.
//
//   flutter build linux --release -t tool/spoken_round_check.dart
//   build/linux/x64/release/bundle/udyoga [--download] [--play answer.wav [--sink name]]
//
// With --play, a recorded answer is played once the microphone opens (the
// laptop answers itself): through the speakers, or into the PipeWire sink
// --sink names. To feed the app without the room, make a null sink and run
// the app with PULSE_SOURCE=<sink>.monitor (record uses parecord on Linux).
// Without --play, speak into the mic. Recordings go to a temporary folder
// that is deleted at the end.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:udyoga/voice/models.dart';
import 'package:udyoga/voice/round.dart';
import 'package:udyoga/voice/round_engines.dart';

const _questions = [
  RoundQuestion(
    'Thank you for coming in. Tell us about a time you were asked to take on extra tasks at short notice.',
    tests: 'Flexibility and organisation under pressure.',
  ),
  RoundQuestion('What did you learn from it?', tests: 'Reflection.'),
];

class _Sink implements AnswerSink {
  final saved = <int, String>{};
  @override
  Future<void> saveTranscript(int question, String text) async => saved[question] = text;
}

Future<Map<String, Object?>> _run(List<String> args) async {
  final base = await getApplicationSupportDirectory();
  final mm = ModelManager(Directory('${base.path}/models'));
  for (final id in [voiceModelId, vadModelId, defaultTranscriber]) {
    final m = speechModel(id);
    if (!await mm.installed(m)) {
      if (!args.contains('--download')) throw StateError('Missing model $id');
      stdout.writeln('downloading $id (${formatBytes(m.bytes)})');
      await mm.download(m);
    }
  }
  final playAt = args.indexOf('--play');
  final answerWav = playAt >= 0 && playAt + 1 < args.length ? args[playAt + 1] : null;
  final sinkAt = args.indexOf('--sink');
  final sink0 = sinkAt >= 0 && sinkAt + 1 < args.length ? args[sinkAt + 1] : null;
  final out = <String, Object?>{};
  final w = Stopwatch()..start();
  final voice = await KokoroVoice.open(
    mm.folder(speechModel(voiceModelId)),
    texts: [for (final q in _questions) q.text],
  );
  out['voiceLoadMs'] = w.elapsedMilliseconds;
  w.reset();
  final listener = await LiveListener.open(
    vadModel: mm.path(speechModel(vadModelId)),
    transcriberFolder: mm.folder(speechModel(defaultTranscriber)),
  );
  out['listenerLoadMs'] = w.elapsedMilliseconds;
  final temp = await Directory.systemTemp.createTemp('udyoga-round-check-');
  final sink = _Sink();
  final round = SpokenRound(
    questions: _questions,
    voice: voice,
    listener: listener,
    takes: FileTakeStore(temp),
    sink: sink,
  )..start();
  // The first question is made while the "before you start" screen shows.
  w.reset();
  await voice.ready(_questions[0].text);
  out['firstQuestionReadyMs'] = w.elapsedMilliseconds;

  final perQuestion = <Map<String, Object?>>[];
  for (var i = 0; i < _questions.length; i++) {
    final q = <String, Object?>{};
    final answering = Completer<void>(), reviewed = Completer<void>();
    var peak = -160.0;
    DateTime? endAt;
    final sub = round.changes.listen((_) {
      if (round.phase == RoundPhase.answering && !answering.isCompleted) answering.complete();
      if (round.live case final l? when l.level > peak) peak = l.level;
      if (round.phase == RoundPhase.transcribing) endAt ??= DateTime.now();
      if (round.phase == RoundPhase.review || round.error != null && round.phase == RoundPhase.ready) {
        if (!reviewed.isCompleted) reviewed.complete();
      }
    });
    final askWatch = Stopwatch()..start();
    unawaited(round.ask());
    await answering.future;
    q['askToMicOpenMs'] = askWatch.elapsedMilliseconds;
    if (i + 1 < _questions.length) {
      // Made while this answer is given.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 3)).then((_) async {
          final r = Stopwatch()..start();
          await voice.ready(_questions[i + 1].text);
          q['nextQuestionWaitAfter3sMs'] = r.elapsedMilliseconds;
        }),
      );
    }
    Process? player;
    if (answerWav != null) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      player = await Process.start('pw-play', [if (sink0 != null) '--target=$sink0', answerWav]);
    }
    final auto = await reviewed.future
        .then((_) => true)
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () async {
            await round.done();
            return false;
          },
        );
    player?.kill();
    final reviewAt = DateTime.now();
    q['endedBy'] = auto ? 'speech detector' : 'timeout, Done';
    q['endToTranscriptMs'] = endAt == null ? null : reviewAt.difference(endAt!).inMilliseconds;
    q['peakDbfs'] = peak;
    q['error'] = round.error;
    final take = round.state.latest;
    q['transcript'] = take?.transcript;
    q['delivery'] = take?.delivery == null
        ? null
        : {for (final r in take!.delivery!.readings) r.label: '${r.value} (${r.place.name})'};
    await sub.cancel();
    perQuestion.add(q);
    if (round.phase == RoundPhase.review) {
      round.next();
    } else {
      await round.skip();
    }
  }
  out['questions'] = perQuestion;
  out['savedTranscripts'] = sink.saved.map((k, v) => MapEntry('$k', v));
  out['takeFiles'] = temp.listSync().length;
  await round.deleteRecordings();
  out['takeFolderAfterDelete'] = await temp.exists();
  await round.close();
  return out;
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Spoken round check running…'))),
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
