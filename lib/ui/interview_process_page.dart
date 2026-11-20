/// Rehearse a whole interview process, stage by stage (interview plan I2):
/// a screening call, a test or exercise, a panel, a presentation and a
/// final interview, from an editable template. Each stage opens with what
/// the stage before it left to fix.
library;

import 'dart:async';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/delivery.dart';
import '../domain/insights.dart';
import '../domain/interview_book.dart';
import '../domain/interview_plan.dart';
import '../domain/interview_process.dart';
import '../domain/interview_scoring.dart';
import '../domain/process_summary.dart';
import 'common.dart';
import 'interview_device_ui.dart' show OfflineBadge;
import 'interview_debrief_page.dart' show openDebrief, openRoleProfile;
import 'kit/kit.dart';
import 'spoken_round_page.dart';

Future<void> openProcess(BuildContext context, InterviewProcess template, {String? savedId}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProcessPage(template, savedId: savedId)));

class ProcessPage extends ConsumerStatefulWidget {
  const ProcessPage(this.template, {super.key, this.savedId});
  final InterviewProcess template;

  /// A process saved earlier, to pick up where it was left.
  final String? savedId;

  @override
  ConsumerState<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends ConsumerState<ProcessPage> {
  late InterviewProcess _process = widget.template;

  /// Empty until the process is first saved: when a stage starts.
  late String _id = widget.savedId ?? '';
  ProcessProgress _progress = const ProcessProgress();
  String? _profileId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.savedId;
    final saved = id == null ? null : await ref.read(sessionProvider).book.savedProcess(id);
    if (!mounted) return;
    setState(() {
      if (saved != null) {
        _process = saved.process;
        _progress = saved.progress;
        _profileId = saved.profileId;
      }
      _loading = false;
    });
  }

  /// Saves the process with its progress (text only, synced like rounds).
  Future<void> _save({bool force = false}) async {
    if (_id.isEmpty && !force) return;
    final process = _process, progress = _progress, profileId = _profileId;
    final id = await ref.mutate(
      (s) => s.book.saveProcess(_id, process, progress, profileId: profileId, at: nowLocal()),
    );
    _id = id;
  }

  void _change(VoidCallback f) {
    setState(f);
    unawaited(_save());
  }

  /// What the earlier finished stages leave for stage [i].
  CarryForward _carryFor(int i) => _progress.carryFor(_process, i);

  Future<void> _run(int i) async {
    final stage = _process.stages[i];
    final nav = Navigator.of(context);
    if (stage.exercises.isNotEmpty) {
      final done = await nav.push<bool>(MaterialPageRoute(builder: (_) => ExercisePage(stage)));
      if (done != true || !mounted) return;
    }
    var notes = '';
    if (stage.presents) {
      final ready = await nav.push<String>(MaterialPageRoute(builder: (_) => PresentationPrepPage(stage)));
      if (ready == null || !mounted) return;
      notes = ready;
    }
    final book = ref.read(sessionProvider).book;
    // The panel asks the role profile's criteria when one is chosen.
    final profile = stage.kind == StageKind.panel ? await book.roleProfile(_profileId) : null;
    // A stage started and left unfinished goes on in the same round.
    final was = _progress.stages[i];
    final reuse = was != null && !was.finished && (await book.roundRecord(was.roundId)) != null;
    final String id;
    if (reuse) {
      id = was.roundId;
    } else {
      id = await ref.mutate(
        (s) => s.book.startPractice(
          role: '${_process.name}: ${stage.title}',
          mode: 'standard',
          questions: profile != null && profile.criteria.isNotEmpty
              ? questionsFromProfile(profile)
              : stage.roundQuestions(),
          at: nowLocal(),
        ),
      );
      if (profile != null) await ref.mutate((s) => s.book.setRoundProfile(id, profile.id));
    }
    _progress = _progress.withStage(i, StageProgress(roundId: id));
    await _save(force: true);
    if (!mounted) return;
    final out = await openSpokenRound(context, id, stage: stage, carry: _carryFor(i), notes: notes);
    if (out == null || !mounted) return;
    final done = _progress.withStage(i, StageProgress(roundId: id, finished: true, outcomes: out));
    _change(
      () => _progress = done.withStage(
        i,
        StageProgress(roundId: id, finished: true, outcomes: out, carry: done.carryFor(_process, i + 1)),
      ),
    );
  }

  Future<void> _edit(int i) async {
    final st = _process.stages[i];
    final title = TextEditingController(text: st.title);
    final settler = TextEditingController(text: st.settler.question);
    final lines = TextEditingController(text: st.questions.map((q) => q.question).join('\n'));
    final brief = TextEditingController(text: st.brief);
    var persona = st.persona;
    var answer = st.answerTime.inSeconds;
    var prep = st.prepTime.inMinutes;
    var deliver = st.deliveryTime.inMinutes;
    var exercise = st.exerciseTime.inMinutes;
    final ok = await showFormDialog(
      context,
      title: 'Edit ${st.title}',
      fields: (setState) => [
        Field(title, 'Stage name'),
        Choice<PersonaKind>(
          label: 'Panel',
          value: persona,
          options: {for (final p in personas.values) p.kind: '${p.label}: ${p.about}'},
          onChanged: (v) => setState(() => persona = v),
        ),
        Choice<int>(
          label: 'Time for each answer',
          value: answer,
          options: const {
            45: '45 seconds',
            60: '1 minute',
            90: '1½ minutes',
            120: '2 minutes',
            150: '2½ minutes',
            180: '3 minutes',
          },
          onChanged: (v) => setState(() => answer = v),
        ),
        if (st.exercises.isNotEmpty)
          Choice<int>(
            label: 'Time for the exercise',
            value: exercise,
            options: const {
              5: '5 minutes',
              8: '8 minutes',
              10: '10 minutes',
              15: '15 minutes',
              20: '20 minutes',
            },
            onChanged: (v) => setState(() => exercise = v),
          ),
        if (st.presents) ...[
          Field(brief, 'Presentation brief', lines: 3),
          Choice<int>(
            label: 'Time to prepare',
            value: prep,
            options: const {
              1: '1 minute',
              5: '5 minutes',
              10: '10 minutes',
              15: '15 minutes',
              30: '30 minutes',
            },
            onChanged: (v) => setState(() => prep = v),
          ),
          Choice<int>(
            label: 'Time to present',
            value: deliver,
            options: const {1: '1 minute', 3: '3 minutes', 5: '5 minutes', 10: '10 minutes'},
            onChanged: (v) => setState(() => deliver = v),
          ),
        ],
        Field(settler, 'Settler question'),
        Field(lines, 'Questions, one per line', lines: 8),
      ],
      onSave: () async {
        if (title.text.trim().isEmpty) return 'Give the stage a name.';
        if (st.presents && brief.text.trim().isEmpty) return 'Write the presentation brief.';
        final kept = {for (final q in st.questions) q.question: q};
        final questions = [
          for (final l in lines.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty))
            kept[l] ??
                PracticeQuestion({
                  'question': l,
                  'category': _guessCategory(l),
                  'why': '',
                  'lookFor': const [],
                }),
        ];
        final settlerText = settler.text.trim();
        _change(
          () => _process = _process.withStage(
            i,
            st.copyWith(
              title: title.text.trim(),
              persona: persona,
              answerTime: Duration(seconds: answer),
              exerciseTime: Duration(minutes: exercise),
              brief: brief.text.trim(),
              prepTime: Duration(minutes: prep),
              deliveryTime: Duration(minutes: deliver),
              settler: settlerText.isEmpty || settlerText == st.settler.question
                  ? st.settler
                  : PracticeQuestion({...st.settler.j, 'question': settlerText}),
              questions: questions,
            ),
          ),
        );
        return null;
      },
    );
    // The controllers are left to the collector, as with the other form
    // dialogs: the closing dialog still reads them.
    if (ok) setState(() {});
  }

  static String _guessCategory(String q) {
    final t = q.toLowerCase();
    if (t.startsWith('do you have any questions')) return 'Closing';
    if (RegExp(r'^(tell (us|me) about a time|describe a time|give (us |me )?an example)').hasMatch(t)) {
      return 'Behavioural';
    }
    if (t.startsWith('what would you do') || t.startsWith('how would you')) return 'Situational';
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const SkeletonCards(count: 3));
    final stages = _process.stages;
    final nextIndex = _progress.next(_process);
    final finished = [
      for (final (i, s) in stages.indexed)
        if (s.included && _progress.finished(i)) _progress.stages[i]!.outcomes,
    ];
    final profiles = ref.watch(roleProfilesProvider).value ?? const [];
    final hasPanel = stages.any((s) => s.kind == StageKind.panel && s.included);
    final anyRun = _progress.stages.isNotEmpty && _id.isNotEmpty;
    return PageScaffold(
      title: _process.name,
      actions: [
        const OfflineBadge(),
        if (anyRun)
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Whole-process summary',
            onPressed: () => openProcessSummary(context, _id, _process.name),
          ),
      ],
      children: [
        Text(_process.about),
        const SizedBox(height: 4),
        Text(
          'Practice only. Employers run their own processes: edit any stage to match your invitation. Your '
          'progress is saved, so you can stop and come back.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (hasPanel)
          SectionCard(
            title: 'Role profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'With a role profile, the panel asks about its criteria and the debrief scores them on its '
                  'framework.',
                ),
                if (profiles.isNotEmpty)
                  Choice<String>(
                    label: 'Profile for the panel',
                    value: profiles.any((p) => p.id == _profileId) ? _profileId! : '',
                    options: {'': 'None: the template questions', for (final p in profiles) p.id: p.title},
                    onChanged: (v) => _change(() => _profileId = v.isEmpty ? null : v),
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
        for (final (i, st) in stages.indexed) _stageCard(i, st, i == nextIndex),
        if (nextIndex == null && finished.isNotEmpty)
          SectionCard(
            title: 'Process finished',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Every stage is done. The transcripts are saved as practice rounds on the Interview page.',
                ),
                if (CarryForward.from(finished) case final c when !c.isEmpty) ...[
                  if (c.keep.isNotEmpty) Bullets(c.keep, icon: Icons.check, color: Status.good.color),
                  if (c.fixes.isNotEmpty) Bullets(c.fixes, icon: Icons.arrow_upward),
                ],
                if (_id.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => openProcessSummary(context, _id, _process.name),
                      icon: const Icon(Icons.summarize_outlined),
                      label: const Text('Whole-process summary'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stageCard(int i, InterviewStage st, bool isNext) {
    final done = _progress.finished(i);
    final started = !done && _progress.stages[i] != null;
    final roundId = _progress.stages[i]?.roundId;
    final muted = Theme.of(context).textTheme.bodySmall;
    final persona = Persona.of(st.persona);
    final carry = isNext ? _carryFor(i) : CarryForward.none;
    final details = [
      '${persona.label} panel',
      if (st.exercises.isNotEmpty)
        '${st.exercises.map((e) => e.label).join(', ')} · ${st.exerciseTime.inMinutes} min',
      if (st.presents)
        '${st.prepTime.inMinutes} min to prepare · ${st.deliveryTime.inMinutes} min to present',
      'About ${DeliveryMetrics.clock(st.answerTime)} an answer',
      '${st.questions.length + 1} questions with the settler',
    ];
    return SectionCard(
      title: '${i + 1}. ${st.title}',
      trailing: done
          ? const StatusPill('Done', status: Status.good)
          : started
          ? const StatusPill('Started', status: Status.info)
          : st.optional
          ? Switch(
              value: st.included,
              onChanged: (v) => _change(() => _process = _process.withStage(i, st.copyWith(included: v))),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(st.about),
          if (st.optional) Text(st.included ? 'Optional: included.' : 'Optional: left out.', style: muted),
          const SizedBox(height: 6),
          Text(details.join(' · '), style: muted),
          Text('Settler: "${st.settler.question}"', style: muted),
          if (!carry.isEmpty) ...[
            const Subhead('From the last stage'),
            if (carry.keep.isNotEmpty) Bullets(carry.keep, icon: Icons.check, color: Status.good.color),
            if (carry.fixes.isNotEmpty) Bullets(carry.fixes, icon: Icons.arrow_upward),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (st.included)
                (isNext ? FilledButton.icon : OutlinedButton.icon)(
                  onPressed: () => _run(i),
                  icon: Icon(done ? Icons.replay : Icons.play_arrow),
                  label: Text(
                    done
                        ? 'Run ${st.title} again'
                        : started
                        ? 'Carry on with ${st.title}'
                        : 'Start ${st.title}',
                  ),
                ),
              if (roundId != null && (done || started))
                OutlinedButton.icon(
                  onPressed: () => openDebrief(context, roundId),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Debrief'),
                ),
              TextButton.icon(
                onPressed: () => _edit(i),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> openProcessSummary(BuildContext context, String processId, String name) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProcessSummaryPage(processId, name: name)));

/// Every stage's debrief in one view: each criterion across the whole
/// process (evidenced in which stage, or missing), then the top three fixes.
class ProcessSummaryPage extends ConsumerStatefulWidget {
  const ProcessSummaryPage(this.processId, {super.key, this.name = 'Process'});
  final String processId;
  final String name;

  @override
  ConsumerState<ProcessSummaryPage> createState() => _ProcessSummaryPageState();
}

class _ProcessSummaryPageState extends ConsumerState<ProcessSummaryPage> {
  ProcessSummary? _summary;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider).book.processSummary(widget.processId).then((s) {
      if (mounted) {
        setState(() {
          _summary = s;
          _loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return Scaffold(appBar: AppBar(), body: const SkeletonCards(count: 2));
    final s = _summary;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Gone(icon: Icons.summarize_outlined, title: 'This process was removed'),
      );
    }
    final muted = Theme.of(context).textTheme.bodySmall;
    return PageScaffold(
      title: 'Summary: ${widget.name}',
      actions: const [OfflineBadge()],
      children: [
        Text(
          s.stages.isEmpty
              ? 'No stage has been run yet.'
              : 'Across ${s.stages.join(', ')}. Each stage\'s debrief counts; open a stage\'s own debrief for '
                    'the scores and the lines you said.',
          style: muted,
        ),
        const SizedBox(height: 8),
        if (s.evidenced.isNotEmpty)
          StatusLabel(
            Status.good,
            '${s.evidenced.length} criteri${s.evidenced.length == 1 ? 'on' : 'a'} evidenced so far.',
          ),
        SectionCard(
          title: 'Top fixes overall',
          child: s.topFixes.isEmpty
              ? const Text('Nothing stands out to fix. Keep doing what you did.')
              : Bullets(s.topFixes, icon: Icons.arrow_upward),
        ),
        SectionCard(
          title: 'Every criterion across the process',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.missingEssentials.isNotEmpty)
                StatusLabel(
                  Status.serious,
                  '${s.missingEssentials.length} essential criteri${s.missingEssentials.length == 1 ? 'on' : 'a'} '
                  'with no evidence in any stage.',
                ),
              if (s.criteria.isEmpty) const Text('No criteria yet: run a stage first.'),
              for (final c in s.criteria)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.criterion.text),
                  subtitle: Text(
                    [
                      c.criterion.essential ? 'Essential' : 'Desirable',
                      c.note,
                      if (c.unappointable) unappointableNote,
                    ].join(' · '),
                  ),
                  trailing: StatusPill(
                    c.status.label,
                    status: switch (c.status) {
                      Coverage.evidenced => Status.good,
                      Coverage.thin => Status.warning,
                      Coverage.missing => c.unappointable ? Status.serious : Status.warning,
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A countdown shown at the top of a timed exercise. It calls [onEnd] once
/// when time runs out, and never stops the user from finishing.
class Countdown extends StatefulWidget {
  const Countdown(this.total, {super.key, this.onEnd, this.label = 'Time left'});
  final Duration total;
  final VoidCallback? onEnd;
  final String label;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late Duration _left = widget.total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = _left - const Duration(seconds: 1);
      setState(() => _left = left.isNegative ? Duration.zero : left);
      if (_left == Duration.zero) {
        t.cancel();
        widget.onEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final share = widget.total.inSeconds == 0 ? 0.0 : _left.inSeconds / widget.total.inSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _left == Duration.zero ? 'Time is up' : '${widget.label}: ${DeliveryMetrics.clock(_left)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Semantics(
          label: widget.label,
          child: LinearProgressIndicator(value: share, minHeight: 6),
        ),
      ],
    );
  }
}

/// A timed test or exercise: an in-tray to put in order, a spreadsheet task
/// described in text, and reasoning questions in a practice format. Pops
/// true when finished.
class ExercisePage extends StatefulWidget {
  const ExercisePage(this.stage, {super.key});
  final InterviewStage stage;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  /// A fixed, jumbled starting order, so the in-tray is the same each time.
  final _order = ['letter', 'awayday', 'password', 'reception', 'lunch', 'fire', 'overtime'];
  final _sheet = [for (final _ in spreadsheetTasks) TextEditingController()];
  final _choices = <int, int>{};
  bool _started = false, _checked = false, _timeUp = false;

  @override
  void dispose() {
    for (final c in _sheet) {
      c.dispose();
    }
    super.dispose();
  }

  void _move(int i, int by) {
    final j = i + by;
    if (j < 0 || j >= _order.length) return;
    setState(() {
      final id = _order.removeAt(i);
      _order.insert(j, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.stage;
    return PageScaffold(
      title: st.title,
      actions: const [OfflineBadge()],
      children: [
        Text(st.about),
        const SizedBox(height: 8),
        if (!_started)
          SectionCard(
            title: 'Before you start',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'You have ${st.exerciseTime.inMinutes} minutes for: ${st.exercises.map((e) => e.label.toLowerCase()).join(', ')}. '
                  'Everything here is made up for practice. When the time is up you can still finish; the clock is '
                  'there to get used to the pressure.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _started = true),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Start the clock'),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (!_checked)
            SectionCard(
              title: 'Clock',
              child: Countdown(st.exerciseTime, onEnd: () => setState(() => _timeUp = true)),
            ),
          if (_timeUp && !_checked)
            Text(
              'Time is up. Finish the item you are on, then check your answers.',
              style: TextStyle(color: Status.warning.color),
            ),
          for (final e in st.exercises)
            switch (e) {
              ExerciseKind.inTray => _inTray(),
              ExerciseKind.spreadsheet => _spreadsheet(),
              ExerciseKind.reasoning => _reasoning(),
            },
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_checked)
                FilledButton(
                  onPressed: () => setState(() => _checked = true),
                  child: const Text('Check my answers'),
                )
              else
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('On to the interview'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _inTray() {
    final byId = {for (final i in inTrayItems) i.id: i};
    return SectionCard(
      title: ExerciseKind.inTray.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'You are the administrator at Example Clinic, back from a day off. Put these in the order you would '
            'deal with them, first at the top. Be ready to explain why.',
          ),
          for (final (i, id) in _order.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text('${i + 1}', style: Theme.of(context).textTheme.titleMedium),
              title: Text(byId[id]!.text),
              subtitle: Text(_checked ? '${byId[id]!.from} · ${byId[id]!.why}' : byId[id]!.from),
              trailing: _checked
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Move up',
                          onPressed: i == 0 ? null : () => _move(i, -1),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Move down',
                          onPressed: i == _order.length - 1 ? null : () => _move(i, 1),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                      ],
                    ),
            ),
          if (_checked) ...[
            const Subhead('One reasonable order'),
            Text(inTrayOrder.map((id) => byId[id]!.from).join(' → ')),
            Text(
              '${inTrayCloseCount(_order)} of ${inTrayOrder.length} of yours are within one place of it. Another '
              'order can be right if you can say why: that is what the panel will ask.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _spreadsheet() => SectionCard(
    title: ExerciseKind.spreadsheet.label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Appointments at four made-up clinics. Row 1 is the heading; North is row 2.'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [for (final c in spreadsheetColumns) DataColumn(label: Text(c))],
            rows: [
              for (final r in spreadsheetRows) DataRow(cells: [for (final v in r) DataCell(Text('$v'))]),
            ],
          ),
        ),
        for (final (i, t) in spreadsheetTasks.indexed) ...[
          const SizedBox(height: 8),
          Text('${i + 1}. ${t.question}'),
          TextField(
            controller: _sheet[i],
            enabled: !_checked,
            decoration: InputDecoration(labelText: 'Answer ${i + 1}'),
          ),
          if (_checked)
            StatusLabel(
              t.check(_sheet[i].text) ? Status.good : Status.warning,
              t.check(_sheet[i].text) ? 'Right: ${t.answer}' : 'The answer is ${t.answer}. ${t.working}',
            ),
        ],
      ],
    ),
  );

  Widget _reasoning() => SectionCard(
    title: ExerciseKind.reasoning.label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusPill(practiceFormatLabel, status: Status.info),
        const SizedBox(height: 4),
        const Text('Self-written questions to get used to working against a clock. Real tests differ.'),
        for (final (i, item) in reasoningItems.indexed) ...[
          const SizedBox(height: 12),
          Text('${i + 1}. ${item.question}', style: Theme.of(context).textTheme.titleSmall),
          RadioGroup<int>(
            groupValue: _choices[i],
            onChanged: (v) {
              if (!_checked && v != null) setState(() => _choices[i] = v);
            },
            child: Column(
              children: [
                for (final (j, o) in item.options.indexed)
                  RadioListTile<int>(contentPadding: EdgeInsets.zero, value: j, title: Text(o)),
              ],
            ),
          ),
          if (_checked)
            StatusLabel(
              _choices[i] == item.answer ? Status.good : Status.warning,
              _choices[i] == item.answer
                  ? 'Right. ${item.working}'
                  : 'The answer is ${item.options[item.answer]}. ${item.working}',
            ),
        ],
      ],
    ),
  );
}

/// The presentation brief with the preparation clock and a notes box. Pops
/// the notes (possibly empty) when the user is ready to present; they stay
/// in memory for the presentation and are never saved.
class PresentationPrepPage extends StatefulWidget {
  const PresentationPrepPage(this.stage, {super.key});
  final InterviewStage stage;

  @override
  State<PresentationPrepPage> createState() => _PresentationPrepPageState();
}

class _PresentationPrepPageState extends State<PresentationPrepPage> {
  final _notes = TextEditingController();
  bool _started = false, _timeUp = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.stage;
    return PageScaffold(
      title: 'Prepare: ${st.title}',
      actions: const [OfflineBadge()],
      children: [
        SectionCard(
          title: 'The brief',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(st.brief, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'You have ${st.prepTime.inMinutes} minutes to prepare and ${st.deliveryTime.inMinutes} to present. '
                'A shape that works: your answer first, three points with evidence, the risks, then next steps.',
              ),
            ],
          ),
        ),
        if (!_started)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => setState(() => _started = true),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Start preparing'),
            ),
          )
        else ...[
          SectionCard(
            title: 'Preparation',
            child: Countdown(
              st.prepTime,
              label: 'Preparation left',
              onEnd: () => setState(() => _timeUp = true),
            ),
          ),
          if (_timeUp) Text('Time to present.', style: TextStyle(color: Status.warning.color)),
          TextField(
            controller: _notes,
            minLines: 5,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Your notes (shown while you present; never saved)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_notes.text),
              icon: const Icon(Icons.record_voice_over_outlined),
              label: const Text('Ready to present'),
            ),
          ),
        ],
      ],
    );
  }
}
