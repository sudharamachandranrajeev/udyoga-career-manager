/// A spoken practice round (interview plan I1): the interviewer reads each
/// question aloud, you answer by voice or by typing, and each answer shows
/// its transcript, how it was delivered and, with an AI, one strength and
/// one fix. Recordings stay on this device and are deleted when you leave;
/// only the transcript is saved with the round.
library;

import 'dart:async';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/delivery.dart';
import '../domain/insights.dart';
import '../domain/json.dart';
import '../voice/models.dart';
import '../voice/round.dart';
import '../voice/spoken_engines.dart';
import 'common.dart';
import 'interview_lab_page.dart' show modelManagerProvider;
import 'kit/kit.dart';

/// The device's speech engines; tests override it with fakes.
final spokenEnginesProvider = FutureProvider<SpokenEngines>((ref) async {
  final mm = await ref.watch(modelManagerProvider.future);
  final base = await getApplicationSupportDirectory();
  return NativeSpokenEngines(mm, Directory('${base.path}/interview-takes'));
});

/// Saves each answer's text with the practice round.
class _BookSink implements AnswerSink {
  _BookSink(this.ref, this.roundId);
  final WidgetRef ref;
  final String roundId;

  @override
  Future<void> saveTranscript(int question, String text) =>
      ref.mutate((s) => s.book.saveTranscript(roundId, question, text, at: nowLocal()));
}

/// The existing AI review, cut to its first strength and first fix. The
/// full review is saved with the round, as for a typed answer.
class _AdvisorCoach implements ContentCoach {
  _AdvisorCoach(this.ref, this.round, this.questions);
  final WidgetRef ref;
  final PracticeSession round;
  final List<PracticeQuestion> questions;

  @override
  Future<ContentNote> feedback(int question, RoundQuestion q, String answer) async {
    final p = await ref.read(profileProvider.future);
    final advisor = await requireAdvisor(ref);
    final review = await advisor.review(
      p,
      role: round.role,
      mode: round.mode,
      question: questions[question],
      answer: answer,
    );
    await ref.mutate((s) => s.book.saveAnswer(round.id, question, answer, review, at: nowLocal()));
    return ContentNote(
      review.strengths.firstOrNull ?? 'No clear strength was found in this answer.',
      review.improvements.firstOrNull ?? 'Nothing specific to fix.',
    );
  }
}

/// Opens the spoken round for [roundId].
Future<void> openSpokenRound(BuildContext context, String roundId) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SpokenRoundPage(roundId)));

class SpokenRoundPage extends ConsumerStatefulWidget {
  const SpokenRoundPage(this.roundId, {super.key});
  final String roundId;

  @override
  ConsumerState<SpokenRoundPage> createState() => _SpokenRoundPageState();
}

class _SpokenRoundPageState extends ConsumerState<SpokenRoundPage> {
  List<SpeechModel>? _missing;
  final _progress = <String, double>{};
  double? _micPeak;
  double _micLevel = -160;
  bool _checkingMic = false;
  bool _opening = false;
  String? _openError;

  SpokenEngines? _engines;
  SpokenRound? _round;
  StreamSubscription<void>? _sub;
  final _typed = TextEditingController();
  String? _playing;

  @override
  void initState() {
    super.initState();
    _refreshModels();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _typed.dispose();
    final round = _round, engines = _engines;
    // Recordings go when the round screen closes.
    unawaited(() async {
      await engines?.stopPlaying();
      await round?.deleteRecordings();
      await round?.close();
    }());
    super.dispose();
  }

  Future<void> _refreshModels() async {
    try {
      final SpokenEngines e = _engines ?? await ref.read(spokenEnginesProvider.future);
      _engines = e;
      final missing = await e.missing();
      if (mounted) setState(() => _missing = missing);
    } on Object catch (e) {
      if (mounted) setState(() => _openError = '$e');
    }
  }

  Future<void> _download(SpeechModel m) async {
    final ok = await confirm(
      context,
      title: 'Download ${m.label}?',
      message:
          '${formatBytes(m.bytes)} from ${Uri.parse(m.url).host} (${m.source}). Licence: ${m.licence}. '
          'It is checked against its published SHA-256 and kept on this device only.',
      action: 'Download ${formatBytes(m.bytes)}',
    );
    if (!ok || !mounted) return;
    setState(() => _progress[m.id] = 0);
    try {
      await _engines!.download(
        m,
        progress: (share) {
          if (mounted) setState(() => _progress[m.id] = share);
        },
      );
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      _progress.remove(m.id);
      await _refreshModels();
    }
  }

  Future<void> _checkMic() async {
    setState(() {
      _checkingMic = true;
      _micPeak = null;
    });
    try {
      final peak = await _engines!.micCheck(
        const Duration(seconds: 3),
        level: (db) {
          if (mounted) setState(() => _micLevel = db);
        },
      );
      if (mounted) setState(() => _micPeak = peak);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _checkingMic = false);
    }
  }

  Future<void> _start(PracticeSession session, List<PracticeQuestion> questions) async {
    setState(() {
      _opening = true;
      _openError = null;
    });
    try {
      final e = _engines!;
      final (voice, listener) = await e.open([for (final q in questions) q.question]);
      final hasAi = ref.read(advisorProvider).value != null;
      final round = SpokenRound(
        questions: [for (final q in questions) RoundQuestion(q.question, tests: q.why, lookFor: q.lookFor)],
        voice: voice,
        listener: listener,
        takes: await e.takes(session.id),
        sink: _BookSink(ref, session.id),
        coach: hasAi ? _AdvisorCoach(ref, session, questions) : null,
      );
      if (!mounted) {
        await round.close();
        return;
      }
      _sub = round.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() => _round = round);
      round.start();
    } on Object catch (e) {
      if (mounted) setState(() => _openError = 'The speech engines did not start: $e');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _deleteAll() async {
    if (!await confirm(
      context,
      title: 'Delete all recordings?',
      message: 'Every recorded answer on this device is deleted. Transcripts stay with the round.',
      action: 'Delete recordings',
      destructive: true,
    )) {
      return;
    }
    await _engines?.stopPlaying();
    await _round?.deleteRecordings();
    await _engines?.deleteAllTakes();
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _play(String key) async {
    final e = _engines;
    if (e == null) return;
    if (_playing == key) {
      await e.stopPlaying();
      setState(() => _playing = null);
      return;
    }
    setState(() => _playing = key);
    await e.play(
      key,
      onDone: () {
        if (mounted && _playing == key) setState(() => _playing = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rounds = ref.watch(practiceProvider);
    final session = rounds.value?.where((r) => r.id == widget.roundId).firstOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Answer aloud')),
        body: rounds.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Gone(icon: Icons.record_voice_over_outlined, title: 'This round was removed'),
      );
    }
    final questions = objs(decodeList(session.questions)).map(PracticeQuestion.new).toList();
    final round = _round;
    return PageScaffold(
      title: 'Answer aloud',
      banner: 'page.spoken',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Delete all recordings',
          onPressed: _deleteAll,
        ),
      ],
      children: [
        Text('${session.role} · ${questions.length} questions'),
        const SizedBox(height: 4),
        Text(
          'Recordings stay on this device and are deleted when you leave this screen. Only the transcript is '
          'saved with the round.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (round == null) _before(session, questions) else ..._during(round),
      ],
    );
  }

  Widget _before(PracticeSession session, List<PracticeQuestion> questions) {
    final missing = _missing;
    final ready = missing != null && missing.isEmpty;
    final peak = _micPeak;
    return SectionCard(
      title: 'Before you start',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Subhead('Speech models'),
          if (missing == null)
            const LinearProgressIndicator()
          else if (missing.isEmpty)
            const Text('The interviewer voice, the speech detector and the transcriber are on this device.')
          else ...[
            const Text(
              'The round needs these on this device. Each downloads only when you ask, from its publisher, '
              'and runs here with no network.',
            ),
            for (final m in missing)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.label),
                subtitle: _progress.containsKey(m.id)
                    ? LinearProgressIndicator(value: _progress[m.id])
                    : Text('${formatBytes(m.bytes)} · ${m.licence}'),
                trailing: _progress.containsKey(m.id)
                    ? null
                    : TextButton(
                        onPressed: () => _download(m),
                        child: Text('Download ${formatBytes(m.bytes)}'),
                      ),
              ),
          ],
          const Subhead('Microphone'),
          const Text('Say a sentence at your normal volume for three seconds.'),
          const SizedBox(height: 8),
          if (_checkingMic) ...[
            Semantics(
              label: 'Input level',
              child: LinearProgressIndicator(value: _levelShare(_micLevel), minHeight: 8),
            ),
            const SizedBox(height: 4),
            const Text('Listening…'),
          ] else if (peak != null)
            StatusLabel(
              peak > -40 ? Status.good : Status.warning,
              peak > -40
                  ? 'We can hear you (peak ${peak.toStringAsFixed(0)} dBFS).'
                  : 'Very quiet (peak ${peak.toStringAsFixed(0)} dBFS): move closer or check the input in the '
                        'system settings.',
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _checkingMic || _engines == null ? null : _checkMic,
              icon: const Icon(Icons.mic_none),
              label: Text(peak == null ? 'Check the microphone' : 'Check again'),
            ),
          ),
          const SizedBox(height: 12),
          if (_openError case final e?) ...[
            Text(e, style: TextStyle(color: Status.serious.color)),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: !ready || _opening ? null : () => _start(session, questions),
              icon: _opening
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(_opening ? 'Loading the voice…' : 'Start the round'),
            ),
          ),
          if (!ready && missing != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Prefer to type? The round\'s own page has an answer box for every question.'),
            ),
        ],
      ),
    );
  }

  static double _levelShare(double dbfs) => ((dbfs + 60) / 60).clamp(0.0, 1.0);

  List<Widget> _during(SpokenRound r) {
    if (r.phase == RoundPhase.finished) return [_finished(r)];
    final q = r.question;
    final t = Theme.of(context).textTheme;
    return [
      Text('Question ${r.index + 1} of ${r.questions.length}', style: t.labelLarge),
      const SizedBox(height: 4),
      LinearProgressIndicator(value: (r.index + 1) / r.questions.length),
      const SizedBox(height: 12),
      SectionCard(
        title: 'What this question tests',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.tests.isEmpty ? 'Not stated for this question.' : q.tests),
            if (q.lookFor.isNotEmpty) ...[const Subhead('A good answer covers'), Bullets(q.lookFor)],
          ],
        ),
      ),
      SectionCard(
        title: 'The question',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(q.text, style: t.titleMedium),
            const SizedBox(height: 12),
            ..._controls(r),
            if (r.error case final e?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(e, style: TextStyle(color: Status.warning.color)),
              ),
          ],
        ),
      ),
      if (r.phase == RoundPhase.review && r.state.latest != null) ..._review(r),
    ];
  }

  List<Widget> _controls(SpokenRound r) {
    Widget row(List<Widget> buttons) => Wrap(spacing: 8, runSpacing: 8, children: buttons);
    final typeInstead = TextButton.icon(
      onPressed: r.typeInstead,
      icon: const Icon(Icons.keyboard_outlined),
      label: const Text('Type instead'),
    );
    final skip = TextButton(onPressed: r.skip, child: const Text('Skip'));
    switch (r.phase) {
      case RoundPhase.ready:
        return [
          row([
            FilledButton.icon(
              onPressed: r.ask,
              icon: const Icon(Icons.volume_up_outlined),
              label: Text(r.state.takes == 0 ? 'Ask me' : 'Ask again'),
            ),
            OutlinedButton.icon(
              onPressed: r.answerNow,
              icon: const Icon(Icons.mic_none),
              label: const Text('Answer without hearing it'),
            ),
            typeInstead,
            skip,
          ]),
        ];
      case RoundPhase.asking:
        return [
          const Row(
            children: [
              Icon(Icons.volume_up_outlined),
              SizedBox(width: 8),
              Expanded(
                child: Text('The interviewer is asking… the microphone opens when the question ends.'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          row([typeInstead, skip]),
        ];
      case RoundPhase.answering:
        final live = r.live;
        return [
          Row(
            children: [
              const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text('Listening · ${DeliveryMetrics.clock(live?.elapsed ?? Duration.zero)}'),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Input level',
            child: LinearProgressIndicator(value: _levelShare(live?.level ?? -160), minHeight: 8),
          ),
          const SizedBox(height: 4),
          Text(
            live == null || !live.heardSpeech
                ? 'Take a moment if you need it; start when you are ready.'
                : 'Stops by itself after a few seconds of silence, or press Done.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          row([
            FilledButton.icon(onPressed: r.done, icon: const Icon(Icons.stop), label: const Text('Done')),
            typeInstead,
          ]),
        ];
      case RoundPhase.transcribing:
        return [const LinearProgressIndicator(), const SizedBox(height: 4), const Text('Writing it down…')];
      case RoundPhase.typing:
        return [
          TextField(
            controller: _typed,
            minLines: 4,
            maxLines: 12,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Your answer', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          row([
            FilledButton(
              onPressed: () async {
                final text = _typed.text;
                await r.submitTyped(text);
                if (r.phase == RoundPhase.review) _typed.clear();
              },
              child: const Text('Save answer'),
            ),
            TextButton.icon(
              onPressed: r.answerNow,
              icon: const Icon(Icons.mic_none),
              label: const Text('Answer by voice instead'),
            ),
            skip,
          ]),
        ];
      case RoundPhase.review:
        final last = r.index + 1 >= r.questions.length;
        return [
          row([
            FilledButton.icon(
              onPressed: r.next,
              icon: Icon(last ? Icons.flag_outlined : Icons.arrow_forward),
              label: Text(last ? 'Finish' : 'Next question'),
            ),
            OutlinedButton.icon(
              onPressed: r.retake,
              icon: const Icon(Icons.replay),
              label: const Text('Re-take'),
            ),
            typeInstead,
          ]),
        ];
      case RoundPhase.finished:
        return const [];
    }
  }

  List<Widget> _review(SpokenRound r) {
    final s = r.state;
    final take = s.latest!;
    final first = s.first!;
    final hasAi = r.coach != null;
    return [
      SectionCard(
        title: take.typed ? 'Your answer (typed)' : 'What you said (take ${take.number})',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(take.transcript),
            if (first.audioKey != null || take.audioKey != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (first.audioKey case final k?)
                    OutlinedButton.icon(
                      onPressed: () => _play(k),
                      icon: Icon(_playing == k ? Icons.stop : Icons.play_arrow),
                      label: Text(identical(first, take) ? 'Play it back' : 'Play take 1'),
                    ),
                  if (!identical(first, take))
                    if (take.audioKey case final k?)
                      OutlinedButton.icon(
                        onPressed: () => _play(k),
                        icon: Icon(_playing == k ? Icons.stop : Icons.play_arrow),
                        label: Text('Play take ${take.number}'),
                      ),
                ],
              ),
            ],
            if (!identical(first, take)) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Take 1, for comparison'),
                children: [SelectableText(first.transcript)],
              ),
            ],
          ],
        ),
      ),
      if (take.delivery case final d?)
        DeliveryPanel(d, before: identical(first, take) ? null : first.delivery),
      SectionCard(
        title: 'What you said: one strength, one fix',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.note case final n?) ...[
              Bullets([n.strength], icon: Icons.check, color: Status.good.color),
              Bullets([n.fix], icon: Icons.arrow_upward),
            ] else if (!hasAi)
              const Text(
                'Add an AI key in Settings for feedback on what you said. Only the transcript is sent.',
              )
            else ...[
              const Text('Only the transcript is sent to your AI, never the recording.'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: r.coaching ? null : r.askCoach,
                  icon: r.coaching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.grading),
                  label: const Text('Get feedback'),
                ),
              ),
            ],
            if (s.noteError case final e?) Text(e, style: TextStyle(color: Status.warning.color)),
          ],
        ),
      ),
    ];
  }

  Widget _finished(SpokenRound r) {
    final answered = r.states.where((s) => s.latest != null).length;
    final skipped = r.states.where((s) => s.skipped).length;
    return SectionCard(
      title: 'Round finished',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You answered $answered of ${r.questions.length}'
            '${skipped > 0 ? ' and skipped $skipped' : ''}. The transcripts are saved with the round, where you '
            'can edit them or ask for a full review.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back to the round'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Delivery, apart from content: each measure beside its usual range,
/// never a score (plan rules 5 and 6).
class DeliveryPanel extends StatelessWidget {
  const DeliveryPanel(this.d, {super.key, this.before});
  final DeliveryMetrics d;

  /// Take 1's measures, when this is a later take.
  final DeliveryMetrics? before;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final earlier = before?.readings;
    return SectionCard(
      title: 'How you said it',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Measured on this device. These are ranges most listeners find easy, not a score.',
            style: t.bodySmall?.copyWith(color: muted),
          ),
          for (final (i, r) in d.readings.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(r.label, style: t.titleSmall)),
                      StatusPill(switch (r.place) {
                        RangePlace.within => 'In the usual range',
                        RangePlace.below => 'Below the usual range',
                        RangePlace.above => 'Above the usual range',
                      }),
                    ],
                  ),
                  Text(r.value),
                  Text(r.usual, style: t.bodySmall?.copyWith(color: muted)),
                  if (earlier != null && i < earlier.length)
                    Text('Take 1: ${earlier[i].value}', style: t.bodySmall?.copyWith(color: muted)),
                  if (r.note.isNotEmpty) Text(r.note, style: t.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
