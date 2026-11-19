/// A spoken practice round (interview plan I1 and I2): the interviewer reads
/// each question aloud, you answer by voice or by typing, and each answer
/// shows its transcript, how it was delivered and, with an AI, one strength
/// and one fix. The interviewer follows up on what an answer leaves out, in
/// the manner of the chosen panel and level, and may stop an answer that
/// runs over time. Recordings stay on this device and are deleted when you
/// leave; only the transcript is saved with the round.
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
import '../domain/interview_book.dart';
import '../domain/interview_confidence.dart';
import '../domain/interview_plan.dart';
import '../domain/interview_process.dart';
import '../domain/interview_scoring.dart';
import '../domain/json.dart';
import '../voice/models.dart';
import '../voice/round.dart';
import '../voice/spoken_engines.dart';
import 'common.dart';
import 'interview_confidence_ui.dart' show NervesRating;
import 'interview_debrief_page.dart' show openDebrief;
import 'interview_lab_page.dart' show modelManagerProvider;
import 'kit/kit.dart';

/// The device's speech engines; tests override it with fakes.
final spokenEnginesProvider = FutureProvider<SpokenEngines>((ref) async {
  final mm = await ref.watch(modelManagerProvider.future);
  final base = await getApplicationSupportDirectory();
  return NativeSpokenEngines(
    mm,
    Directory('${base.path}/interview-takes'),
    voiceCache: Directory('${base.path}/voice-cache'),
  );
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
    // Task-level wording only: the first of each with no talk of scores.
    String first(List<String> items, String none) =>
        items.map(taskLevelText).where((t) => t.isNotEmpty).firstOrNull ?? none;
    return ContentNote(
      first(review.strengths, 'No clear strength was found in this answer.'),
      first(review.improvements, 'Nothing specific to fix.'),
    );
  }
}

/// Opens the spoken round for [roundId]. As a [stage] of a process it
/// returns what each answer covered, for the next stage.
Future<List<QuestionOutcome>?> openSpokenRound(
  BuildContext context,
  String roundId, {
  InterviewStage? stage,
  CarryForward carry = CarryForward.none,
  String notes = '',
}) => Navigator.of(context).push<List<QuestionOutcome>>(
  MaterialPageRoute(
    builder: (_) => SpokenRoundPage(roundId, stage: stage, carry: carry, notes: notes),
  ),
);

/// The question plans for a round: the templates, or the user's AI when
/// there is one and they want it (checked, with the templates filling any
/// gap). Returns the plans and where they came from.
Future<(List<QuestionPlan>, String)> planRound(
  WidgetRef ref, {
  required String role,
  required List<PracticeQuestion> questions,
  required bool useAi,
}) async {
  final templates = [for (final q in questions) templatePlan(q)];
  if (!useAi) return (templates, 'Built-in follow-ups');
  try {
    final advisor = await requireAdvisor(ref);
    final fromAi = await advisor
        .questionPlan(role: role, questions: questions)
        .timeout(const Duration(seconds: 120));
    return (mergePlans(questions, fromAi), 'Follow-ups planned by your AI');
  } on Object catch (e) {
    return (templates, 'Built-in follow-ups (your AI did not answer: ${describeError(e)})');
  }
}

class SpokenRoundPage extends ConsumerStatefulWidget {
  const SpokenRoundPage(
    this.roundId, {
    super.key,
    this.stage,
    this.carry = CarryForward.none,
    this.notes = '',
  });
  final String roundId;

  /// Set when the round is a stage of a process.
  final InterviewStage? stage;

  /// What the earlier stages missed.
  final CarryForward carry;

  /// Presentation notes, kept in memory only.
  final String notes;

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
  String _openingStep = '';
  String? _openError;
  RoundSettings _settings = const RoundSettings();
  String _planSource = '';

  SpokenEngines? _engines;
  SpokenRound? _round;
  StreamSubscription<void>? _sub;
  final _typed = TextEditingController();
  String? _playing;

  @override
  void initState() {
    super.initState();
    _refreshModels();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saved = await ref.read(sessionProvider).book.roundSettings();
    final stage = widget.stage;
    if (mounted) setState(() => _settings = stage == null ? saved : saved.copyWith(persona: stage.persona));
  }

  void _setSettings(RoundSettings r) {
    setState(() => _settings = r);
    unawaited(ref.read(sessionProvider).book.setRoundSettings(r));
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
    final hasAi = ref.read(advisorProvider).value != null;
    final settings = _settings;
    setState(() {
      _opening = true;
      _openingStep = hasAi && settings.aiPlan ? 'Planning the follow-ups…' : 'Loading the voice…';
      _openError = null;
    });
    try {
      final e = _engines!;
      final (planned, source) = await planRound(
        ref,
        role: session.role,
        questions: questions,
        useAi: hasAi && settings.aiPlan,
      );
      // A round from a role profile tests the profile's criteria, whatever
      // the plan called them.
      final profile = await ref.read(sessionProvider).book.roleProfile(session.profileId);
      final plans = withCriteria(questions, planned, profile);
      if (mounted) setState(() => _openingStep = 'Loading the voice…');
      final persona = Persona.of(settings.persona);
      final level = Ladder.of(settings.level);
      final opening = widget.stage?.opening(persona, level) ?? roundOpening(persona, level);
      final interviewer = Interviewer(
        persona: persona,
        level: level,
        plans: plans,
        budgets: [for (final q in questions) answerBudget(q, level)],
        focus: widget.carry.focus,
        opening: opening,
      );
      // Everything the voice may say, so its word list covers every word.
      final (voice, listener) = await e.open([
        opening,
        for (final q in questions) q.question,
        for (final p in plans) ...p.probes.map((x) => x.text),
        for (final list in builtInProbes.values) ...list,
        ...persona.acknowledgements,
        persona.probeLead,
        interruptLine,
      ]);
      final round = SpokenRound(
        questions: [for (final q in questions) RoundQuestion(q.question, tests: q.why, lookFor: q.lookFor)],
        voice: voice,
        listener: listener,
        takes: await e.takes(session.id),
        sink: _BookSink(ref, session.id),
        coach: hasAi ? _AdvisorCoach(ref, session, questions) : null,
        interviewer: interviewer,
        endSilence: settings.endSilence,
      );
      _planSource = source;
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
        if (round == null) ...[
          if (widget.stage case final st?) _stageNote(st),
          _settingsCard(),
          _before(session, questions),
        ] else
          ..._during(round, session),
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
          NervesRating(
            label: 'How nervous do you feel right now?',
            value: session.nervesBefore,
            onChanged: (n) => ref.mutate((s) => s.book.saveNerves(session.id, before: n)),
          ),
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
              label: Text(_opening ? _openingStep : 'Start the round'),
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

  /// What this stage is, and what the last stage left to fix.
  Widget _stageNote(InterviewStage st) {
    final carry = widget.carry;
    return SectionCard(
      title: st.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(st.about),
          if (!carry.isEmpty) ...[
            const Subhead('From the last stage'),
            if (carry.keep.isNotEmpty) Bullets(carry.keep, icon: Icons.check, color: Status.good.color),
            if (carry.fixes.isNotEmpty) Bullets(carry.fixes, icon: Icons.arrow_upward),
            if (carry.focus.isNotEmpty)
              Text(
                'The follow-ups in this stage look for ${carry.focus.first.meaning} first.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }

  /// The panel's manner, the level and when an answer ends.
  Widget _settingsCard() {
    final r = _settings;
    final persona = Persona.of(r.persona);
    final level = Ladder.of(r.level);
    final hasAi = ref.watch(advisorProvider).value != null;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SectionCard(
      title: 'Round settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Choice<PersonaKind>(
            key: ValueKey('persona-${r.persona.name}'),
            label: 'Panel',
            value: r.persona,
            options: {for (final p in personas.values) p.kind: p.label},
            onChanged: (v) => _setSettings(r.copyWith(persona: v)),
          ),
          Text(persona.about, style: muted),
          if (persona.silenceNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            StatusLabel(Status.info, 'Silence is normal'),
            Text(persona.silenceNote),
          ],
          const SizedBox(height: 12),
          Choice<int>(
            key: ValueKey('level-${r.level}'),
            label: 'Level',
            value: r.level,
            options: {for (final l in ladder) l.level: '${l.level} · ${l.label}'},
            onChanged: (v) => _setSettings(r.copyWith(level: v)),
          ),
          Text(level.about, style: muted),
          const SizedBox(height: 12),
          Text('End an answer after ${r.endSilence.inSeconds} s of silence'),
          Slider(
            value: r.endSilence.inSeconds.toDouble(),
            min: RoundSettings.minSilence.inSeconds.toDouble(),
            max: RoundSettings.maxSilence.inSeconds.toDouble(),
            divisions: RoundSettings.maxSilence.inSeconds - RoundSettings.minSilence.inSeconds,
            label: '${r.endSilence.inSeconds} s',
            semanticFormatterCallback: (v) => '${v.round()} seconds of silence',
            onChanged: (v) => _setSettings(r.copyWith(endSilence: Duration(seconds: v.round()))),
          ),
          Text(
            'Pauses to think that are shorter than this never end your answer. You can always press Done.',
            style: muted,
          ),
          if (hasAi)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Plan the follow-ups with my AI'),
              subtitle: const Text(
                'Only the questions are sent. The follow-up itself is chosen on this device from what your '
                'answer leaves out. Off: built-in follow-ups.',
              ),
              value: r.aiPlan,
              onChanged: (v) => _setSettings(r.copyWith(aiPlan: v)),
            ),
        ],
      ),
    );
  }

  static double _levelShare(double dbfs) => ((dbfs + 60) / 60).clamp(0.0, 1.0);

  List<Widget> _during(SpokenRound r, PracticeSession session) {
    if (r.phase == RoundPhase.finished) return [_finished(r, session)];
    final q = r.question;
    final t = Theme.of(context).textTheme;
    final iv = r.interviewer;
    return [
      Text('Question ${r.index + 1} of ${r.questions.length}', style: t.labelLarge),
      if (iv != null)
        Text(
          '${iv.persona.label} panel · Level ${iv.level.level}, ${iv.level.label}'
          '${_planSource.isEmpty ? '' : ' · $_planSource'}',
          style: t.bodySmall,
        ),
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
      if (widget.notes.trim().isNotEmpty)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Your presentation notes'),
          children: [SelectableText(widget.notes)],
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
    final moveOn = TextButton(onPressed: r.moveOn, child: const Text('Move on'));
    final muted = Theme.of(context).textTheme.bodySmall;
    // The follow-up being answered, above the microphone or the box.
    final followUp = [
      if (r.followingUp) ...[
        Text(r.wrappingUp ? 'Wrap-up' : 'Follow-up', style: Theme.of(context).textTheme.labelLarge),
        SelectableText(r.followUpQuestion, style: Theme.of(context).textTheme.titleSmall),
        if (r.wrappingUp) Text('One sentence: the result, and what it shows about you.', style: muted),
        const SizedBox(height: 8),
      ],
    ];
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
        final said = r.saying;
        return [
          Row(
            children: [
              const Icon(Icons.volume_up_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  said != null && said != r.question.text
                      ? '"$said"'
                      : 'The interviewer is asking… the microphone opens when the question ends.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          row([typeInstead, if (r.followingUp) moveOn, skip]),
        ];
      case RoundPhase.pausing:
        final quiet = r.interviewer?.persona.kind == PersonaKind.quiet;
        return [
          Row(
            children: [
              const Icon(Icons.edit_note),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quiet ? 'The panel is writing notes. Silence is normal.' : 'The panel is making a note…',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          row([skip]),
        ];
      case RoundPhase.answering:
        final live = r.live;
        final budget = r.budget;
        final elapsed = live?.elapsed ?? Duration.zero;
        return [
          ...followUp,
          Row(
            children: [
              const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                'Listening · ${DeliveryMetrics.clock(elapsed)}'
                '${budget == null ? '' : ' of about ${DeliveryMetrics.clock(budget)}'}',
              ),
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
                : 'Stops by itself after ${r.endSilence.inSeconds} s of silence, or press Done.',
            style: muted,
          ),
          if (budget != null && elapsed > budget)
            Text('Over the time: sum up and finish.', style: TextStyle(color: Status.warning.color)),
          const SizedBox(height: 8),
          row([
            FilledButton.icon(onPressed: r.done, icon: const Icon(Icons.stop), label: const Text('Done')),
            typeInstead,
            if (r.followingUp) moveOn,
          ]),
        ];
      case RoundPhase.transcribing:
        return [const LinearProgressIndicator(), const SizedBox(height: 4), const Text('Writing it down…')];
      case RoundPhase.typing:
        return [
          ...followUp,
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
            if (r.followingUp) moveOn else skip,
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
      if (s.followUps.isNotEmpty || s.interrupted)
        SectionCard(
          title: s.interrupted ? 'Stopped to keep to time' : 'Follow-ups',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.interrupted)
                const Text(
                  'The interviewer stopped the answer at the time limit, as real panels do. The wrap-up is '
                  'the skill: one sentence with the result.',
                ),
              for (final f in s.followUps) ...[
                const SizedBox(height: 8),
                Text(
                  f.kind == FollowUpKind.wrapUp ? 'Wrap-up: ${f.asked}' : f.asked,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (f.probe case final p?)
                  Text(
                    'Asked because the answer did not yet say ${p.element.meaning}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                SelectableText(f.take.transcript),
              ],
            ],
          ),
        ),
      // A spoken follow-up keeps its own delivery, as the main answer does.
      for (final (i, f) in s.followUps.indexed)
        if (f.take.delivery case final d?)
          DeliveryPanel(
            d,
            title: f.kind == FollowUpKind.wrapUp
                ? 'How you said the wrap-up'
                : s.followUps.length > 1
                ? 'How you said follow-up ${i + 1}'
                : 'How you said the follow-up',
          ),
      if (r.coverage(r.index) case final c? when c.expected.isNotEmpty)
        SectionCard(
          title: 'What your answer covered',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Found in your words on this device, including the follow-ups. Approximate: it reads words, '
                'not meaning.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in c.expected)
                    StatusPill(
                      c.heard.contains(e) ? '${e.label}: heard' : '${e.label}: not heard',
                      status: c.heard.contains(e) ? Status.good : Status.warning,
                    ),
                ],
              ),
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

  Widget _finished(SpokenRound r, PracticeSession session) {
    final answered = r.states.where((s) => s.latest != null).length;
    final skipped = r.states.where((s) => s.skipped).length;
    final outcomes = r.outcomes();
    final next = CarryForward.from([outcomes]);
    final stage = widget.stage;
    return SectionCard(
      title: stage == null ? 'Round finished' : '${stage.title} finished',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You answered $answered of ${r.questions.length}'
            '${skipped > 0 ? ' and skipped $skipped' : ''}. The transcripts are saved with the round, where you '
            'can edit them or ask for a full review.',
          ),
          const SizedBox(height: 8),
          NervesRating(
            label: 'And now, how nervous do you feel?',
            value: session.nervesAfter,
            onChanged: (n) => ref.mutate((s) => s.book.saveNerves(session.id, after: n)),
          ),
          if (!next.isEmpty) ...[
            const Subhead('For next time'),
            if (next.keep.isNotEmpty) Bullets(next.keep, icon: Icons.check, color: Status.good.color),
            if (next.fixes.isNotEmpty) Bullets(next.fixes, icon: Icons.arrow_upward),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(outcomes),
                child: Text(stage == null ? 'Back to the round' : 'Back to the process'),
              ),
              OutlinedButton.icon(
                onPressed: () => openDebrief(context, widget.roundId),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('See the debrief'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Delivery, apart from content: each measure beside its usual range,
/// never a score (plan rules 5 and 6).
class DeliveryPanel extends StatelessWidget {
  const DeliveryPanel(this.d, {super.key, this.before, this.title = 'How you said it'});
  final DeliveryMetrics d;
  final String title;

  /// Take 1's measures, when this is a later take.
  final DeliveryMetrics? before;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final earlier = before?.readings;
    return SectionCard(
      title: title,
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
