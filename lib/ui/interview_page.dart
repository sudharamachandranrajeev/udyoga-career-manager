import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation.dart';
import '../app/interview_providers.dart';
import '../app/providers.dart';
import '../db/database.dart';
import '../domain/answer_metrics.dart';
import '../domain/common_questions.dart';
import '../domain/insights.dart';
import '../domain/interview_confidence.dart';
import '../domain/interview_process.dart';
import '../domain/interview_scoring.dart' show Framework;
import '../domain/json.dart';
import 'camera_coach_ui.dart';
import 'common.dart';
import 'interview_confidence_ui.dart';
import 'interview_debrief_page.dart';
import 'interview_device_ui.dart';
import 'interview_process_page.dart';
import 'kit/kit.dart';
import 'look.dart';
import 'spoken_round_page.dart';
import 'vidya_practice_ui.dart';

const _ratings = {
  'outstanding': Status.good,
  'strong': Status.good,
  'adequate': Status.info,
  'weak': Status.warning,
  'poor': Status.serious,
};

Status scoreStatus(double score) => score >= 8
    ? Status.good
    : score >= 6
    ? Status.info
    : score >= 4
    ? Status.warning
    : Status.serious;

/// Asks for the round's settings, prepares the questions and opens it.
Future<void> startPractice(BuildContext context, WidgetRef ref, {String role = '', Job? job}) async {
  final p = await ref.read(profileProvider.future);
  if (!context.mounted) return;
  final roleField = TextEditingController(
    text: role.isNotEmpty ? role : p.targets.roles.firstOrNull ?? p.currentRole,
  );
  var mode = 'standard';
  var count = 8;
  final go = await showFormDialog(
    context,
    title: job == null ? 'Practice interview' : 'Practise for ${job.title}',
    action: 'Start',
    fields: (setState) => [
      Field(roleField, 'Role', autofocus: role.isEmpty),
      Hint(
        'interview.mode',
        child: Choice<String>(
          label: 'Kind of interview',
          value: mode,
          options: practiceModes,
          onChanged: (v) => setState(() => mode = v),
        ),
      ),
      Choice<int>(
        label: 'Questions',
        value: count,
        options: const {5: '5 questions', 8: '8 questions', 12: '12 questions'},
        onChanged: (v) => setState(() => count = v),
      ),
    ],
    onSave: () async => roleField.text.trim().isEmpty ? 'Enter the role.' : null,
  );
  if (!go || !context.mounted) return;
  final r = await runAi(
    context,
    title: 'Preparing your interview',
    task: (progress) async => (await requireInterviewAdvisor(ref)).practiceQuestions(
      p,
      role: roleField.text.trim(),
      mode: mode,
      job: job,
      count: count,
      onProgress: progress,
    ),
  );
  if (r == null || !context.mounted) return;
  final questions = objs(r.data['questions']).map(PracticeQuestion.new).toList();
  if (questions.isEmpty) return showMessage(context, 'No questions came back. Try again.');
  final id = await ref.mutate(
    (s) => s.book.startPractice(
      role: roleField.text.trim(),
      mode: mode,
      jobId: job?.id,
      questions: questions,
      at: nowLocal(),
    ),
  );
  if (context.mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PracticePage(id)));
}

/// A spoken round of [commonQuestions], which needs no AI.
Future<void> startCommonRound(BuildContext context, WidgetRef ref) async {
  final id = await ref.mutate(
    (s) => s.book.startPractice(
      role: 'Common questions',
      mode: 'standard',
      questions: commonQuestions,
      at: nowLocal(),
    ),
  );
  if (context.mounted) await openSpokenRound(context, id);
}

class InterviewPage extends ConsumerWidget {
  const InterviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAi = ref.watch(interviewAdvisorProvider).value != null;
    final answers = ref.watch(answersProvider).value ?? const <PracticeAnswer>[];
    return PageScaffold(
      title: 'Interview',
      banner: 'page.interview',
      actions: const [OfflineBadge()],
      fab: hasAi
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => startPractice(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Practise'),
            )
          : null,
      children: [
        if (!hasAi) const InterviewNoAi(),
        // Confidence first (plan I4): what is ready, then what to work on.
        const ReadyForCard(),
        const PractiseRequestsCard(),
        SectionCard(
          title: 'Answer aloud',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The interviewer reads each question aloud and you answer by voice, or type. You see what each '
                'question tests first, then your transcript and how you said it. It runs on this device; '
                'recordings never leave it.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => startCommonRound(context, ref),
                    icon: const Icon(Icons.mic_none),
                    label: const Text('Common questions, aloud'),
                  ),
                  if (hasAi)
                    TextButton(
                      onPressed: () => startPractice(context, ref),
                      child: const Text('Or prepare questions for a role first'),
                    ),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const CameraSetupPage())),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Check my video setup'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const InterviewDeviceCard(),
        SectionCard(
          title: 'Rehearse a whole process',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Stage by stage: a screening call, a test or exercise, the panel, a presentation, a final '
                'interview. Each stage has its own clock and opens with what the last one left to fix. Every '
                'template can be edited to match your invitation.',
              ),
              for (final row in ref.watch(processesProvider).value ?? const <ProcessRow>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text('Carry on: ${row.name}'),
                  subtitle: Text(_processProgress(row)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openProcess(
                    context,
                    processTemplates.where((t) => t.id == row.template).firstOrNull ?? processTemplates.first,
                    savedId: row.id,
                  ),
                ),
              for (final p in processTemplates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: Text(p.stages.map((s) => s.title).join(' → ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openProcess(context, p),
                ),
            ],
          ),
        ),
        const DrillsCard(),
        SectionCard(
          title: 'Role profiles',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste an advert and person specification, or type the criteria. Each becomes a question, and '
                'the debrief scores only what you said against them, essentials first.',
              ),
              for (final p in ref.watch(roleProfilesProvider).value ?? const <RoleProfileRow>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.title),
                  subtitle: Text(
                    [
                      if (p.employer.isNotEmpty) p.employer,
                      Framework.of(p.framework).name,
                      '${decodeList(p.criteria).length} criteria',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openRoleProfile(context, id: p.id),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => openRoleProfile(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New role profile'),
                ),
              ),
            ],
          ),
        ),
        AsyncList(
          ref.watch(practiceProvider),
          builder: (rounds) {
            if (rounds.isEmpty) {
              return EmptyState(
                icon: Icons.record_voice_over_outlined,
                title: 'No practice yet',
                message:
                    'Pick a role and a kind of interview. The AI researches how that employer or sector interviews '
                    'now, asks the questions, and scores each answer strictly on seven dimensions.',
                actions: [
                  if (hasAi)
                    FilledButton.icon(
                      onPressed: () => startPractice(context, ref),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Practise an interview'),
                    )
                  else
                    TextButton(
                      onPressed: () => goToPage(ref, 'settings'),
                      child: const Text('Add an AI key in Settings'),
                    ),
                ],
              );
            }
            final scored = rounds.where((r) => r.score != null).toList();
            final recent = scored.take(5).map((r) => r.score!).toList();
            final avg = recent.isEmpty ? null : recent.reduce((a, b) => a + b) / recent.length;
            final best = scored.isEmpty ? null : scored.map((r) => r.score!).reduce((a, b) => a > b ? a : b);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatGrid(
                  children: [
                    StatTile(label: 'Rounds', value: rounds.length, icon: Icons.history),
                    StatTile(
                      label: 'Answers scored',
                      value: answers.where((a) => a.score != null).length,
                      icon: Icons.fact_check_outlined,
                    ),
                    StatTile(
                      label: 'Recent average',
                      value: avg,
                      fractionDigits: 1,
                      suffix: '/10',
                      icon: Icons.trending_up,
                      caption: recent.isEmpty ? 'No scored rounds yet' : 'Last ${recent.length} rounds',
                      status: avg == null ? null : scoreStatus(avg),
                    ),
                    StatTile(
                      label: 'Best round',
                      value: best,
                      fractionDigits: 1,
                      suffix: '/10',
                      icon: Icons.emoji_events_outlined,
                    ),
                  ],
                ),
                for (final r in rounds) _RoundTile(r, answers.where((a) => a.sessionId == r.id).length),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// How far a saved process has got, in a line.
String _processProgress(ProcessRow row) {
  final process = InterviewProcess.fromJson(decodeObject(row.process));
  final progress = ProcessProgress.fromJson(decodeObject(row.progress));
  final included = [
    for (final (i, s) in process.stages.indexed)
      if (s.included) i,
  ];
  final done = included.where(progress.finished).length;
  final next = progress.next(process);
  return [
    '$done of ${included.length} stages done',
    if (next != null) 'next: ${process.stages[next].title}',
    'saved ${niceDateTime(row.updated)}',
  ].join(' · ');
}

class _RoundTile extends StatelessWidget {
  const _RoundTile(this.round, this.answered);
  final PracticeSession round;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final total = decodeList(round.questions).length;
    final score = round.score;
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tilt(
        child: SpotlightCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PracticePage(round.id))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    OrgLogo(round.role, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(round.role, style: t.titleMedium),
                          Text(
                            '${(practiceModes[round.mode] ?? round.mode).split(':').first} · '
                            '${niceDateTime(round.started)}',
                            style: t.bodyMedium?.copyWith(color: muted),
                          ),
                          const SizedBox(height: 8),
                          StatusPill('$answered of $total answered', icon: Icons.check_circle_outline),
                        ],
                      ),
                    ),
                    if (score != null)
                      Text(
                        score.toStringAsFixed(1),
                        style: t.headlineSmall?.copyWith(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          color: scoreStatus(score).color,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One round: each question with an answer box, live measures and the review.
class PracticePage extends ConsumerStatefulWidget {
  const PracticePage(this.id, {super.key});
  final String id;

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  final _answers = <int, TextEditingController>{};
  final _hints = <int>{};
  final _busy = <int>{};

  @override
  void dispose() {
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _answer(int i, String saved) =>
      _answers.putIfAbsent(i, () => TextEditingController(text: saved));

  @override
  Widget build(BuildContext context) {
    final rounds = ref.watch(practiceProvider);
    final round = rounds.value?.where((r) => r.id == widget.id).firstOrNull;
    if (round == null) {
      return Scaffold(
        appBar: AppBar(),
        body: rounds.isLoading
            ? const Padding(padding: EdgeInsets.all(16), child: SkeletonCards(count: 2))
            : Gone(icon: Icons.record_voice_over_outlined, title: 'This round was removed'),
      );
    }
    final questions = objs(decodeList(round.questions)).map(PracticeQuestion.new).toList();
    final saved = {
      for (final a in ref.watch(answersProvider).value ?? const <PracticeAnswer>[])
        if (a.sessionId == round.id) a.question: a,
    };
    return PageScaffold(
      title: round.role,
      actions: [
        IconButton(
          icon: const Icon(Icons.mic_none),
          tooltip: 'Answer aloud',
          onPressed: () => openSpokenRound(context, round.id),
        ),
        IconButton(
          icon: const Icon(Icons.fact_check_outlined),
          tooltip: 'Debrief',
          onPressed: () => openDebrief(context, round.id),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete this round',
          onPressed: () => _delete(round, saved.values.toList()),
        ),
      ],
      children: [
        Text(
          [
            practiceModes[round.mode] ?? round.mode,
            if (round.score != null) 'Average ${round.score!.toStringAsFixed(1)} out of 10',
          ].join('\n'),
        ),
        const SizedBox(height: 4),
        const Text(
          'Answer as you would speak in the room. About two minutes (250 to 350 words) suits most questions.',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => openSpokenRound(context, round.id),
            icon: const Icon(Icons.mic_none),
            label: const Text('Answer these aloud'),
          ),
        ),
        const SizedBox(height: 12),
        NervesRating(
          label: 'Before you start: how nervous do you feel?',
          value: round.nervesBefore,
          onChanged: (n) => ref.mutate((s) => s.book.saveNerves(round.id, before: n)),
        ),
        const SizedBox(height: 16),
        for (final (i, q) in questions.indexed) _question(round, i, q, saved[i]),
        SectionCard(
          title: 'After the round',
          child: NervesRating(
            label: 'How nervous do you feel now?',
            value: round.nervesAfter,
            onChanged: (n) => ref.mutate((s) => s.book.saveNerves(round.id, after: n)),
          ),
        ),
      ],
    );
  }

  Widget _question(PracticeSession round, int i, PracticeQuestion q, PracticeAnswer? saved) {
    final c = _answer(i, saved?.answer ?? '');
    final review = saved == null || saved.review.isEmpty ? null : AnswerReview(decodeObject(saved.review));
    return SectionCard(
      title: 'Question ${i + 1}',
      trailing: review == null
          ? Text([q.category, q.difficulty].where((s) => s.isNotEmpty).join(' · '))
          : StatusLabel(scoreStatus(review.score), '${review.score.toStringAsFixed(1)}/10'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(q.question, style: Theme.of(context).textTheme.titleMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _hints.contains(i) ? _hints.remove(i) : _hints.add(i)),
              icon: Icon(_hints.contains(i) ? Icons.visibility_off_outlined : Icons.lightbulb_outline),
              label: Text(_hints.contains(i) ? 'Hide what they look for' : 'What are they testing?'),
            ),
          ),
          if (_hints.contains(i)) ...[
            Text(q.why),
            if (q.lookFor.isNotEmpty) ...[const Subhead('A top answer includes'), Bullets(q.lookFor)],
            const SizedBox(height: 8),
          ],
          TextField(
            controller: c,
            minLines: 5,
            maxLines: 16,
            decoration: const InputDecoration(labelText: 'Your answer', alignLabelWithHint: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (c.text.trim().isNotEmpty) Hint('interview.metrics', child: _Metrics(AnswerMetrics.of(c.text))),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: c.text.trim().isEmpty || _busy.contains(i)
                  ? null
                  : () => _evaluate(round, i, q, c.text.trim()),
              icon: _busy.contains(i)
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.grading),
              label: Text(review == null ? 'Evaluate' : 'Evaluate again'),
            ),
          ),
          if (review != null) ...[const Divider(height: 32), ReviewView(review)],
        ],
      ),
    );
  }

  Future<void> _evaluate(PracticeSession round, int i, PracticeQuestion q, String answer) async {
    setState(() => _busy.add(i));
    try {
      final p = await ref.read(profileProvider.future);
      final advisor = await requireInterviewAdvisor(ref);
      final review = await advisor.review(p, role: round.role, mode: round.mode, question: q, answer: answer);
      await ref.mutate((s) => s.book.saveAnswer(round.id, i, answer, review, at: nowLocal()));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(i));
    }
  }

  Future<void> _delete(PracticeSession round, List<PracticeAnswer> answers) async {
    if (!await confirm(
      context,
      title: 'Delete this round?',
      message: 'Its questions, answers and reviews are removed from every device.',
      action: 'Delete',
      destructive: true,
    )) {
      return;
    }
    await ref.mutate((s) async {
      for (final a in answers) {
        await s.book.remove(s.db.careerAnswers, a.id);
      }
      await s.book.remove(s.db.careerPractice, round.id);
    });
    if (mounted) Navigator.of(context).maybePop();
  }
}

/// What the device measures as you type.
class _Metrics extends StatelessWidget {
  const _Metrics(this.m);
  final AnswerMetrics m;

  @override
  Widget build(BuildContext context) {
    final secs = m.speakingTime.inSeconds;
    const parts = {'situation': 'S', 'task': 'T', 'action': 'A', 'result': 'R'};
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        StatusPill('${m.words} words · ${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')} spoken'),
        StatusPill(m.lengthVerdict),
        StatusPill('${m.fillers} fillers', status: m.fillers > 3 ? Status.warning : Status.good),
        StatusPill('"I" ${m.iCount} · "we" ${m.weCount}'),
        StatusPill('${m.figures} figures'),
        StatusPill(
          'STAR: ${[for (final e in parts.entries) m.star.contains(e.key) ? e.value : '·'].join(' ')}',
        ),
      ],
    );
  }
}

class ReviewView extends StatelessWidget {
  const ReviewView(this.r, {super.key});
  final AnswerReview r;

  @override
  Widget build(BuildContext context) {
    final rating = _ratings[r.rating] ?? Status.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusLabel(
          rating,
          '${r.rating.isEmpty ? 'Scored' : r.rating[0].toUpperCase() + r.rating.substring(1)}: '
          '${r.score.toStringAsFixed(1)} out of 10',
        ),
        const SizedBox(height: 8),
        for (final d in r.dimensions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(d.name)),
                    Text('${d.score}/10', style: tabular),
                  ],
                ),
                const SizedBox(height: 2),
                Semantics(
                  label: '${d.name} ${d.score} out of 10',
                  child: LinearProgressIndicator(
                    value: d.score / 10,
                    color: scoreStatus(d.score.toDouble()).color,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                if (d.comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(d.comment, style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        if (r.strengths.isNotEmpty) ...[
          const Subhead('Strong'),
          Bullets(r.strengths, icon: Icons.check, color: Status.good.color),
        ],
        if (r.improvements.isNotEmpty) ...[
          const Subhead('Improve'),
          Bullets(r.improvements, icon: Icons.arrow_upward),
        ],
        if (r.redFlags.isNotEmpty) ...[
          const Subhead('Red flags'),
          Bullets(r.redFlags, icon: Icons.flag_outlined, color: Status.serious.color),
        ],
        if (r.followUp.isNotEmpty) ...[
          const Subhead('The follow-up they would ask'),
          SelectableText(r.followUp),
        ],
        if (r.better.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('A stronger answer'),
            children: [
              SelectableText(r.better),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => copyText(context, r.better),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
