/// Role profiles and the panel debrief (interview plan I3).
///
/// A role profile holds the criteria a panel agrees before it meets anyone,
/// read from a pasted advert by the user's AI or typed in, and always
/// editable. The debrief scores a round against those criteria only: coverage
/// first, then each criterion on the framework's scale with its anchor text
/// and the line it rests on, then one strength and one fix per answer, and
/// lines to recover with. Without an AI, coverage comes from the matcher on
/// this device.
library;

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/interview_book.dart';
import '../domain/interview_scoring.dart';
import '../domain/json.dart';
import 'common.dart';
import 'kit/kit.dart';
import 'spoken_round_page.dart';

Future<void> openRoleProfile(BuildContext context, {String? id, Job? job}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => RoleProfilePage(id: id, job: job),
  ),
);

Future<void> openDebrief(BuildContext context, String roundId) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DebriefPage(roundId)));

// ---- role profiles ----

class RoleProfilePage extends ConsumerStatefulWidget {
  const RoleProfilePage({super.key, this.id, this.job});

  /// A saved profile to edit; null for a new one.
  final String? id;

  /// A saved job to start a new profile from.
  final Job? job;

  @override
  ConsumerState<RoleProfilePage> createState() => _RoleProfilePageState();
}

class _RoleProfilePageState extends ConsumerState<RoleProfilePage> {
  final _title = TextEditingController();
  final _employer = TextEditingController();
  final _advert = TextEditingController();
  RoleProfile _profile = const RoleProfile(id: '', title: '');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _employer.dispose();
    _advert.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final book = ref.read(sessionProvider).book;
    final saved = await book.roleProfile(widget.id);
    final job = widget.job;
    if (!mounted) return;
    setState(() {
      if (saved != null) {
        _profile = saved;
      } else if (job != null) {
        _profile = RoleProfile(id: '', title: job.title, employer: job.company, jobId: job.id);
        _advert.text = job.description;
      }
      _title.text = _profile.title;
      _employer.text = _profile.employer;
      _loading = false;
    });
  }

  RoleProfile get _current => _profile.copyWith(title: _title.text.trim(), employer: _employer.text.trim());

  Future<String?> _save() async {
    if (_title.text.trim().isEmpty) {
      showMessage(context, 'Give the role a title.');
      return null;
    }
    final p = _current;
    final id = await ref.mutate((s) => s.book.saveRoleProfile(p, at: nowLocal()));
    if (mounted) {
      setState(
        () => _profile = RoleProfile(
          id: id,
          title: p.title,
          employer: p.employer,
          frameworkId: p.frameworkId,
          criteria: p.criteria,
          jobId: p.jobId,
          source: p.source,
        ),
      );
    }
    return id;
  }

  Future<void> _read() async {
    final advert = _advert.text.trim();
    if (advert.isEmpty) return showMessage(context, 'Paste the advert and person specification first.');
    final data = await runAi(
      context,
      title: 'Reading the criteria',
      status: 'Only the advert is sent to your AI.',
      task: (_) async => (await requireAdvisor(ref)).readCriteria(advert: advert, title: _title.text.trim()),
    );
    if (data == null || !mounted) return;
    final criteria = parseCriteria(data);
    if (criteria.isEmpty) return showMessage(context, 'No criteria were found. Add them by hand.');
    if (_profile.criteria.isNotEmpty &&
        !await confirm(
          context,
          title: 'Replace the criteria?',
          message:
              'The ${_profile.criteria.length} criteria here are replaced by the ${criteria.length} read.',
          action: 'Replace',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      if (_title.text.trim().isEmpty) _title.text = str(data['title']);
      if (_employer.text.trim().isEmpty) _employer.text = str(data['employer']);
      _profile = RoleProfile(
        id: _profile.id,
        title: _title.text.trim(),
        employer: _employer.text.trim(),
        frameworkId: suggestedFramework(data, fallback: _profile.frameworkId),
        criteria: criteria,
        jobId: _profile.jobId,
        source: 'ai',
      );
    });
    showToast(context, 'Check each criterion', description: 'Your AI read them; edit anything it got wrong.');
  }

  Future<void> _editCriterion(Criterion? c) async {
    final text = TextEditingController(text: c?.text ?? '');
    final question = TextEditingController(text: c?.question ?? '');
    var essential = c?.essential ?? true;
    var kind = c?.kind ?? CriterionKind.experience;
    var assess = c?.assessBy.join() ?? '';
    final ok = await showFormDialog(
      context,
      title: c == null ? 'Add a criterion' : 'Edit the criterion',
      fields: (setState) => [
        Field(text, 'Criterion', lines: 2, autofocus: c == null),
        Choice<bool>(
          label: 'Essential or desirable',
          value: essential,
          options: const {true: 'Essential', false: 'Desirable'},
          onChanged: (v) => setState(() => essential = v),
        ),
        Choice<CriterionKind>(
          label: 'Kind',
          value: kind,
          options: {for (final k in CriterionKind.values) k: k.label},
          onChanged: (v) => setState(() => kind = v),
        ),
        Choice<String>(
          label: 'Assessed by',
          value: assess,
          options: {
            '': 'Not stated',
            'I': 'Interview',
            'AI': 'Application and interview',
            'T': 'Test only (not asked aloud)',
            'P': 'Presentation',
            'A': 'Application only',
          }..putIfAbsent(assess, () => assess.split('').map((a) => assessByLabels[a] ?? a).join(' and ')),
          onChanged: (v) => setState(() => assess = v),
        ),
        Field(
          question,
          'Question that tests it (optional)',
          lines: 2,
          helper: 'Left empty, a template is used.',
        ),
      ],
      onSave: () async => text.text.trim().isEmpty ? 'Write the criterion.' : null,
    );
    if (!ok || !mounted) return;
    final next = Criterion(
      id: c?.id ?? _profile.nextId(),
      text: text.text.trim(),
      essential: essential,
      kind: kind,
      assessBy: assess.split(''),
      question: question.text.trim(),
    );
    setState(
      () => _profile = _profile.copyWith(
        criteria: c == null
            ? [..._profile.criteria, next]
            : [for (final x in _profile.criteria) x.id == c.id ? next : x],
      ),
    );
  }

  void _addExamples() {
    final f = _profile.framework;
    final have = {for (final c in _profile.criteria) c.text.toLowerCase()};
    var p = _profile;
    for (final e in f.examples) {
      if (have.contains(e.toLowerCase())) continue;
      p = p.copyWith(
        criteria: [
          ...p.criteria,
          Criterion(id: p.nextId(), text: e, kind: f.exampleKind),
        ],
      );
    }
    setState(() => _profile = p);
  }

  Future<void> _startRound() async {
    final id = await _save();
    if (id == null || !mounted) return;
    if (askedCriteria(_profile).isEmpty) {
      return showMessage(context, 'Add a criterion that is assessed at interview.');
    }
    final p = _profile;
    final roundId = await ref.mutate((s) => s.book.startProfileRound(p, at: nowLocal()));
    if (mounted) await openSpokenRound(context, roundId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const SkeletonCards(count: 2));
    final hasAi = ref.watch(advisorProvider).value != null;
    final f = _profile.framework;
    final muted = Theme.of(context).textTheme.bodySmall;
    final asked = {for (final c in askedCriteria(_profile)) c.id};
    return PageScaffold(
      title: _profile.id.isEmpty ? 'New role profile' : _profile.title,
      actions: [IconButton(icon: const Icon(Icons.save_outlined), tooltip: 'Save', onPressed: _save)],
      children: [
        const Text(
          'The criteria a panel agrees before it meets anyone. Each becomes a question, and the debrief scores '
          'only what you said against them.',
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'The role',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Field(_title, 'Job title'),
              Field(_employer, 'Employer (optional)'),
              Field(
                _advert,
                'Advert and person specification',
                lines: 6,
                helper: 'Paste the text. It stays on this device unless you ask your AI to read it.',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasAi)
                    FilledButton.tonalIcon(
                      onPressed: _read,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Read the criteria with my AI'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _editCriterion(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a criterion by hand'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'How the panel scores',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Choice<String>(
                label: 'Framework',
                value: f.id,
                options: {for (final x in frameworks) x.id: x.name},
                onChanged: (v) => setState(() => _profile = _profile.copyWith(frameworkId: v)),
              ),
              Text(f.about),
              const SizedBox(height: 6),
              ScaleView(f.scale),
              const SizedBox(height: 8),
              Text('Example ${f.dimensions}: ${f.examples.join(', ')}.', style: muted),
              if (f.examplesNote.isNotEmpty) Text(f.examplesNote, style: muted),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addExamples,
                  icon: const Icon(Icons.playlist_add),
                  label: Text('Add these ${f.dimensions} as criteria'),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Criteria (${_profile.criteria.length})',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_profile.criteria.isEmpty)
                const Text('None yet. Read them from the advert, or add them by hand.')
              else if (_profile.source == 'ai')
                Text('Read by your AI: check each one against the advert.', style: muted),
              for (final c in _profile.criteria)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.text),
                  subtitle: Text(
                    [
                      c.essential ? 'Essential' : 'Desirable',
                      c.kind.label,
                      if (c.assessBy.isNotEmpty) c.assessBy.map((a) => assessByLabels[a]).join(', '),
                      if (c.testOnly)
                        'not asked aloud'
                      else if (!asked.contains(c.id))
                        'beyond this round\'s 8',
                    ].join(' · '),
                  ),
                  onTap: () => _editCriterion(c),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(
                      () => _profile = _profile.copyWith(
                        criteria: [
                          for (final x in _profile.criteria)
                            if (x.id != c.id) x,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _profile.criteria.isEmpty ? null : _startRound,
              icon: const Icon(Icons.mic_none),
              label: const Text('Practise these aloud'),
            ),
            OutlinedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ],
    );
  }
}

/// A scale's levels with their anchor text.
class ScaleView extends StatelessWidget {
  const ScaleView(this.scale, {super.key});
  final ScoringScale scale;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Scale: ${scale.name}'),
      subtitle: const Text(scaleCaveat),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final l in scale.levels) Text('${l.code} · ${l.label}: ${l.anchor}'),
        if (scale.passRule.isNotEmpty) ...[const SizedBox(height: 4), Text(scale.passRule)],
        const SizedBox(height: 4),
        Text('Source: ${scale.source}', style: muted),
      ],
    );
  }
}

// ---- the debrief ----

class DebriefPage extends ConsumerStatefulWidget {
  const DebriefPage(this.roundId, {super.key});
  final String roundId;

  @override
  ConsumerState<DebriefPage> createState() => _DebriefPageState();
}

class _DebriefPageState extends ConsumerState<DebriefPage> {
  ({PracticeSession round, DebriefRound data, RoleProfile? profile})? _loaded;
  bool _gone = false;
  final _saved = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final book = ref.read(sessionProvider).book;
    final rec = await book.roundRecord(widget.roundId);
    if (rec == null) {
      if (mounted) setState(() => _gone = true);
      return;
    }
    final profile = await book.roleProfile(rec.round.profileId);
    final data = DebriefRound.of(questions: rec.questions, answers: rec.answers, profile: profile);
    if (mounted) setState(() => _loaded = (round: rec.round, data: data, profile: profile));
  }

  Debrief _debrief(PracticeSession round, DebriefRound data, RoleProfile? p) =>
      InterviewBook.debriefOf(round, data, p);

  Future<void> _score() async {
    final l = _loaded!;
    final f = l.profile?.framework ?? Framework.of('private');
    final answered = l.data.answered;
    if (answered.isEmpty) return showMessage(context, 'No answers to score yet.');
    final scores = await runAi(
      context,
      title: 'Scoring the round',
      status: 'Only the transcripts and the criteria are sent to your AI.',
      task: (_) async => (await requireAdvisor(ref)).scoreRound(
        role: l.round.role,
        framework: f,
        criteria: l.data.criteria,
        answers: [
          for (final q in answered)
            (index: q.index, question: q.question.question, criteria: q.criteria, answer: q.heard),
        ],
      ),
    );
    if (scores == null || !mounted) return;
    await ref.mutate(
      (s) => s.book.saveScoring(l.round.id, {
        'framework': f.id,
        'answers': [for (final a in scores) a.toJson()],
      }),
    );
    await _load();
  }

  Future<void> _saveStory(DebriefQuestion q, AnswerNote n) async {
    final l = _loaded!;
    final criteria = [
      for (final id in n.evidenced) ?l.data.criteria.where((c) => c.id == id).firstOrNull?.text,
    ];
    final draft = storyFromAnswer(title: q.question.question, answer: q.heard, criteria: criteria);
    final id = await ref.mutate(
      (s) => s.book.saveStoryFromPractice(draft, roundId: l.round.id, criteria: criteria, today: today()),
    );
    if (!mounted) return;
    if (id == null) return showMessage(context, 'A story with that title is already in the bank.');
    setState(() => _saved.add(q.index));
    showToast(
      context,
      'Saved to the story bank',
      description: 'Marked as from practice. Check it on the Coach page before you rely on it.',
      status: Status.good,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) {
      return Scaffold(
        appBar: AppBar(),
        body: const Gone(icon: Icons.record_voice_over_outlined, title: 'This round was removed'),
      );
    }
    final l = _loaded;
    if (l == null) return Scaffold(appBar: AppBar(), body: const SkeletonCards(count: 3));
    final d = _debrief(l.round, l.data, l.profile);
    final hasAi = ref.watch(advisorProvider).value != null;
    final t = Theme.of(context).textTheme;
    final scoreLines = d.scoreLines();
    final qs = {for (final q in l.data.questions) q.index: q};
    return PageScaffold(
      title: 'Debrief: ${l.round.role}',
      children: [
        Text(
          d.aiScored
              ? 'Scored by your AI against the agreed criteria, then checked here: a score stands only when the '
                    'line it quotes is in your transcript.${d.dropped > 0 ? ' ${d.dropped} score${d.dropped == 1 ? ' was' : 's were'} dropped because the quote was not there.' : ''}'
              : 'Coverage from the words on this device. It reads words, not meaning: approximate.',
          style: t.bodySmall,
        ),
        if (!l.data.fromProfile)
          Text(
            'This round has no role profile, so each question\'s aim stands in as a criterion and none is '
            'essential. Make a role profile for the full debrief.',
            style: t.bodySmall,
          ),
        const SizedBox(height: 8),
        if (hasAi && l.data.answered.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _score,
              icon: const Icon(Icons.grading),
              label: Text(d.aiScored ? 'Score again with my AI' : 'Score with my AI'),
            ),
          ),
        SectionCard(
          title: 'Coverage',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.missingEssentials.isNotEmpty)
                StatusLabel(
                  Status.serious,
                  '${d.missingEssentials.length} essential criteri${d.missingEssentials.length == 1 ? 'on' : 'a'} '
                  'with no evidence.',
                ),
              for (final c in d.coverage)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.criterion.text),
                  subtitle: Text(
                    [
                      if (l.data.fromProfile) c.criterion.essential ? 'Essential' : 'Desirable',
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
        if (scoreLines.isNotEmpty)
          SectionCard(
            title: 'Scores: ${d.framework.name}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in scoreLines) ...[
                  const SizedBox(height: 6),
                  Text('${s.criterion.text}: ${s.level.code} · ${s.level.label}', style: t.titleSmall),
                  Text(s.level.anchor),
                  if (s.quote.isNotEmpty) Text('You said: "${s.quote}"', style: t.bodySmall),
                ],
                ScaleView(d.framework.scale),
              ],
            ),
          ),
        for (final n in d.notes)
          SectionCard(
            title: 'Question ${n.question + 1}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(qs[n.question]!.question.question, style: t.bodySmall),
                const SizedBox(height: 6),
                Bullets([n.strength], icon: Icons.check, color: Status.good.color),
                Bullets([n.fix], icon: Icons.arrow_upward),
                if (n.recovery.isNotEmpty)
                  Text('In the room you could say: "${n.recovery}"', style: t.bodySmall),
                if (n.good)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saved.contains(n.question) ? null : () => _saveStory(qs[n.question]!, n),
                      icon: Icon(_saved.contains(n.question) ? Icons.check : Icons.bookmark_add_outlined),
                      label: Text(
                        _saved.contains(n.question) ? 'Saved to the story bank' : 'Save to story bank',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (d.recoveryLines.isNotEmpty)
          SectionCard(
            title: 'Lines to recover with',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Panels allow a short return to an earlier answer. Practise saying these:'),
                Bullets([for (final r in d.recoveryLines) '"$r"'], icon: Icons.replay),
              ],
            ),
          ),
      ],
    );
  }
}
