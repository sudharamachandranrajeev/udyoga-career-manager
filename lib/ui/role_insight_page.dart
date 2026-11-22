import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/career_data.dart';
import '../domain/feeds.dart';
import '../domain/job_identity.dart';
import '../domain/occupations.dart';
import '../domain/pay.dart';
import '../domain/profile.dart';
import '../domain/role_family.dart';
import '../domain/role_insight.dart';
import '../domain/vidya_link.dart';
import 'career_page.dart';
import 'common.dart';
import 'role_search_view.dart';
import 'vidya_practice_ui.dart';

/// The most roles approached at once.
const maxInsightRoles = 3;

/// Opens "Approach this role" with [roles] picked (up to three).
Future<void> openRoleInsights(BuildContext context, {List<String> roles = const []}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RoleInsightPage(roles: roles)));

/// "Approach this role" (role search plan U4): pick one to three roles,
/// each gets a card with the eight sections, and two or three can be
/// compared side by side. The device's part needs no AI; "Ask the AI" fills
/// in the rest, labelled AI. Every result is saved and opens again without AI.
class RoleInsightPage extends ConsumerStatefulWidget {
  const RoleInsightPage({super.key, this.roles = const []});
  final List<String> roles;

  @override
  ConsumerState<RoleInsightPage> createState() => _RoleInsightPageState();
}

class _RoleInsightPageState extends ConsumerState<RoleInsightPage> {
  final typed = TextEditingController();
  final chosen = <String>[];
  final insights = <String, RoleInsight>{};
  final busy = <String>{};
  var compare = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final r in widget.roles.take(maxInsightRoles)) {
        _pick(r);
      }
    });
  }

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  RoleInsightBuilder _builder({bool withAi = false}) {
    final s = ref.read(sessionProvider);
    final client = ref.read(httpClientProvider);
    return RoleInsightBuilder(
      families: RoleFamilies(client, s.db),
      advisor: withAi ? ref.read(advisorProvider).value : null,
      keyed: careerDataSources(
        client,
        ref.read(careerDataKeysProvider).value ?? const CareerDataKeys(),
        today: today(),
      ),
      today: today(),
    );
  }

  /// Adds [role]: its saved insight, else the device's part built now (and
  /// saved). The AI is only asked when the person presses the button.
  Future<void> _pick(String role) async {
    final r = role.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (r.isEmpty) return;
    final id = roleInsightId(r);
    if (chosen.any((c) => roleInsightId(c) == id)) return;
    if (chosen.length >= maxInsightRoles) {
      showMessage(context, 'Up to $maxInsightRoles roles at a time. Take one off first.');
      return;
    }
    setState(() {
      chosen.add(r);
      busy.add(id);
    });
    try {
      final book = ref.read(sessionProvider).book;
      var i = await book.roleInsight(r);
      if (i == null) {
        await loadSocIndex();
        await ref.read(careerDataKeysProvider.future);
        final p = await ref.read(profileProvider.future);
        i = await _builder().build(r, p, useAi: false);
        await ref.mutate((s) => s.book.saveRoleInsight(i!));
      }
      if (mounted) setState(() => insights[id] = i!);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  void _unpick(String role) => setState(() {
    chosen.remove(role);
    insights.remove(roleInsightId(role));
    if (chosen.length < 2) compare = false;
  });

  /// Builds [role] again: the device's part, keyed sources, then the AI.
  Future<void> _ask(RoleInsight had) async {
    final p = await ref.read(profileProvider.future);
    await ref.read(careerDataKeysProvider.future);
    await ref.read(advisorProvider.future);
    if (!mounted) return;
    final r = await runAi(
      context,
      title: 'Approaching ${had.role}',
      task: (progress) async {
        await requireAdvisor(ref);
        await loadSocIndex();
        return _builder(withAi: true).build(had.role, p, created: had.created, onProgress: progress);
      },
    );
    if (r == null) return;
    await ref.mutate((s) => s.book.saveRoleInsight(r));
    if (mounted) setState(() => insights[r.id] = r);
  }

  Future<void> _study(RoleInsight i) async {
    await ref.mutate((s) => s.book.sendRoleToVidya(i, now: DateTime.now().toUtc().toIso8601String()));
    if (mounted) {
      showMessage(
        context,
        'Sent to Vidya. Open Vidya to add "Approach: ${i.role}" with its gaps and criteria.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAi = ref.watch(advisorProvider).value != null;
    final p = ref.watch(profileProvider).value ?? const CandidateProfile();
    final searches = ref.watch(savedSearchesProvider).value ?? const [];
    final saved = ref.watch(roleInsightsProvider).value ?? const <RoleInsight>[];
    final picked = {for (final c in chosen) normalJobTitle(c)};
    final suggestions = <String>{
      ...p.targets.roles,
      for (final s in searches) s.role,
      for (final i in saved) i.role,
    }.where((r) => r.trim().isNotEmpty && !picked.contains(normalJobTitle(r))).toList();
    final shown = [for (final c in chosen) ?insights[roleInsightId(c)]];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approach this role'),
        actions: [
          if (shown.length >= 2)
            TextButton.icon(
              key: const ValueKey('insight.compare'),
              onPressed: () => setState(() => compare = !compare),
              icon: Icon(compare ? Icons.view_agenda_outlined : Icons.compare_arrows),
              label: Text(compare ? 'Cards' : 'Compare'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pick up to $maxInsightRoles roles: your targets, saved searches, or type one in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in chosen)
                  InputChip(label: Text(c), selected: true, onDeleted: () => _unpick(c)),
                for (final s in suggestions.take(10))
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(s),
                    onPressed: () => _pick(s),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('insight.role'),
              controller: typed,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Another role, such as Clinical Systems Trainer',
                suffixIcon: IconButton(
                  tooltip: 'Add this role',
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _pick(typed.text);
                    typed.clear();
                  },
                ),
              ),
              onSubmitted: (v) {
                _pick(v);
                typed.clear();
              },
            ),
            const SizedBox(height: 12),
            if (!hasAi) const NeedsKey(what: 'Ways in, stepping stones, first moves and the career path'),
            for (final c in chosen)
              if (busy.contains(roleInsightId(c)))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Reading the titles and skills for $c…')),
                    ],
                  ),
                ),
            if (compare && shown.length >= 2)
              RoleCompare(shown)
            else
              for (final i in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoleInsightCard(
                    i,
                    hasAi: hasAi,
                    onAsk: () => _ask(i),
                    onStudy: () => _study(i),
                    onClose: () =>
                        _unpick(chosen.firstWhere((c) => roleInsightId(c) == i.id, orElse: () => i.role)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// A small "AI" label for anything the AI wrote.
class AiTag extends StatelessWidget {
  const AiTag({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Written by AI',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.tertiary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: scheme.tertiary),
            const SizedBox(width: 3),
            Text('AI', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.tertiary)),
          ],
        ),
      ),
    );
  }
}

/// A line of text, with the AI label in front when the AI wrote it.
class _Said extends StatelessWidget {
  const _Said(this.text, this.from, {this.icon});
  final String text;
  final InsightFrom from;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
        if (from.isAi) const Padding(padding: EdgeInsets.only(top: 2), child: AiTag()),
        Expanded(child: SelectableText(text)),
      ],
    ),
  );
}

const _severity = {'blocker': Status.serious, 'major': Status.warning, 'minor': Status.info};

/// One role's insight: the eight sections, each with its source and date,
/// AI parts labelled.
class RoleInsightCard extends ConsumerStatefulWidget {
  const RoleInsightCard(
    this.insight, {
    super.key,
    required this.hasAi,
    required this.onAsk,
    required this.onStudy,
    this.onClose,
  });
  final RoleInsight insight;
  final bool hasAi;
  final VoidCallback onAsk, onStudy;
  final VoidCallback? onClose;

  @override
  ConsumerState<RoleInsightCard> createState() => _RoleInsightCardState();
}

class _RoleInsightCardState extends ConsumerState<RoleInsightCard> {
  var allGaps = false;
  var allCriteria = false;

  RoleInsight get i => widget.insight;

  Widget _section(String key, Widget child) {
    final t = Theme.of(context).textTheme;
    final sources = i.sources[key] ?? const <InsightSource>[];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(insightSections[key]!, style: t.titleSmall)),
              if (i.aiIn(key)) const AiTag(),
            ],
          ),
          if (sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'Source: ${sources.map((s) => '${s.label} · ${s.date}').join('; ')}',
                style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _empty(String text) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));

  String get _needsAi => widget.hasAi
      ? 'Press "Ask the AI" to fill this in.'
      : 'Filled in by the AI once a key is added in Settings, or by a career data key.';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final essential = i.criteria.where((c) => c.essential && c.shown != null).toList();
    final shownEssential = essential.where((c) => c.shown == true).length;
    final gaps = allGaps ? i.gaps : i.gaps.take(8).toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(i.role, style: t.titleLarge)),
                FitBadge(i.fit, ai: i.fitAi != null),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: 'Take this role off',
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
            Text(
              'Made ${niceDate(i.created)}${i.updated != i.created ? ', updated ${niceDate(i.updated)}' : ''}'
              '${i.aiAsked.isEmpty ? ' · no AI yet' : ' · AI parts by ${i.model.isEmpty ? 'the AI' : i.model}, ${niceDate(i.aiAsked)}'}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.hasAi)
                  FilledButton.tonalIcon(
                    key: ValueKey('insight.ask.${i.id}'),
                    onPressed: widget.onAsk,
                    icon: Icon(i.aiAsked.isEmpty ? Icons.auto_awesome : Icons.refresh),
                    label: Text(i.aiAsked.isEmpty ? 'Ask the AI' : 'Refresh'),
                  ),
                OutlinedButton.icon(
                  key: ValueKey('insight.study.${i.id}'),
                  onPressed: i.gaps.isEmpty && i.moves.isEmpty ? null : widget.onStudy,
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Study for this role'),
                ),
              ],
            ),
            RoleReadinessLine(i.role),
            for (final p in i.problems) StatusLabel(Status.warning, p),

            // 1. What the role is.
            _section(
              'about',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (i.summary case final s?) _Said(s.text, s.from),
                  if (i.soc.isNotEmpty)
                    Text(
                      'SOC 2020: ${i.soc.map((m) => '${m.soc} ${m.socTitle}'.trim()).toSet().join('; ')}',
                      style: t.bodySmall,
                    ),
                  if (i.titles.length > 1) ...[
                    const SizedBox(height: 4),
                    const Text('Also advertised as:'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in i.titles.skip(1).take(12))
                          Tooltip(
                            message: f.reason,
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: f.source == FamilySource.ai
                                  ? const Icon(Icons.auto_awesome, size: 14)
                                  : null,
                              label: Text(f.source == FamilySource.ai ? 'AI: ${f.title}' : f.title),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (i.summary == null && i.titles.length <= 1) _empty(_needsAi),
                ],
              ),
            ),

            // 2. Fit and gaps.
            _section(
              'fit',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (essential.isNotEmpty)
                    Text(
                      'Your profile shows $shownEssential of ${essential.length} essential skills ESCO lists.',
                    ),
                  if (i.fitAi != null)
                    Row(
                      children: [
                        const AiTag(),
                        Expanded(child: Text('Ready today: ${i.fitAi}%')),
                      ],
                    ),
                  for (final g in gaps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusLabel(_severity[g.severity] ?? Status.info, g.severity),
                              const SizedBox(width: 8),
                              if (g.from.isAi) const AiTag(),
                              Expanded(child: SelectableText(g.text)),
                            ],
                          ),
                          if (g.howToClose.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Text('How to close it: ${g.howToClose}', style: t.bodySmall),
                            ),
                        ],
                      ),
                    ),
                  if (i.gaps.length > 8)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => allGaps = !allGaps),
                        child: Text(allGaps ? 'Show fewer' : 'Show all ${i.gaps.length} gaps'),
                      ),
                    ),
                  if (i.criteria.any((c) => c.shown == true)) ...[
                    TextButton(
                      onPressed: () => setState(() => allCriteria = !allCriteria),
                      child: Text(
                        allCriteria ? 'Hide what you already show' : 'What your profile already shows',
                      ),
                    ),
                    if (allCriteria)
                      Bullets(
                        [
                          for (final c in i.criteria)
                            if (c.shown == true) '${c.text} (from "${c.evidence}")',
                        ],
                        icon: Icons.check,
                        color: Status.good.color,
                      ),
                  ],
                  if (i.criteria.isEmpty && i.gaps.isEmpty)
                    _empty(
                      'ESCO has no skills for this title yet (or was not reached). ${widget.hasAi ? _needsAi : ''}',
                    ),
                ],
              ),
            ),

            // 3. Ways in.
            _section(
              'waysIn',
              i.waysIn.isEmpty
                  ? _empty(_needsAi)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final w in i.waysIn)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: w.from.isAi ? const AiTag() : const Icon(Icons.login, size: 18),
                            title: Text('${wayInKinds[w.kind] ?? 'Route'}: ${w.title}'),
                            subtitle: w.detail.isEmpty ? null : Text(w.detail),
                            onTap: w.url.startsWith('http') ? () => openLink(context, w.url) : null,
                          ),
                      ],
                    ),
            ),

            // 4. Stepping stones.
            _section(
              'stones',
              i.stones.isEmpty
                  ? _empty(_needsAi)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final s in i.stones) _Stone(s)],
                    ),
            ),

            // 5. Pay and progression.
            _section('pay', _Pay(i, needsAi: _needsAi)),

            // 6. How people got in.
            _section(
              'people',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in i.checklist) _Said(l.text, l.from, icon: Icons.check_box_outline_blank),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: ValueKey('insight.people.${i.id}'),
                      onPressed: () => openUri(context, i.peopleSearch),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('People with this title on LinkedIn'),
                    ),
                  ),
                  Text('Opens in your browser. Udyoga does not read LinkedIn.', style: t.bodySmall),
                ],
              ),
            ),

            // 7. First moves and CV wording.
            _section(
              'moves',
              i.moves.isEmpty && i.cv.isEmpty
                  ? _empty(_needsAi)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final m in i.moves) _Said(m.text, m.from, icon: Icons.directions_run),
                        if (i.cv.isNotEmpty) ...[
                          const Subhead('Your CV in this role\'s words'),
                          for (final c in i.cv)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.experience.isNotEmpty)
                                    Text('You did: ${c.experience}', style: t.bodySmall),
                                  _Said('Say: ${c.inTargetTerms}', c.from),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
            ),

            // 8. Career path.
            _section(
              'path',
              Column(
                children: [
                  for (final (n, s) in i.path.indexed) ...[
                    if (n > 0) MapLine(color: scheme.outlineVariant),
                    MapNode(
                      title: s.role,
                      subtitle: [
                        pathStages[s.stage] ?? '',
                        if (s.timeframe.isNotEmpty) s.timeframe,
                        if (s.likelihood != null) '${s.likelihood}% likely',
                        if (s.from.isAi) 'AI',
                      ].where((x) => x.isNotEmpty).join(' · '),
                      color: s.stage == 'target' ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                      onColor: s.stage == 'target' ? scheme.onPrimaryContainer : scheme.onSurface,
                    ),
                  ],
                  if (!i.path.any((s) => s.from.isAi))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _empty('Timeframes and odds: ${_needsAi.toLowerCase()}'),
                    ),
                ],
              ),
            ),

            for (final k in i.keyed) _Credit(k),
            SourcesList([for (final s in i.web) (title: s.title, url: s.url)]),
          ],
        ),
      ),
    );
  }
}

class _Stone extends StatelessWidget {
  const _Stone(this.s);
  final SteppingStone s;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (s.from.isAi) const AiTag(),
            Expanded(child: Text(s.role, style: Theme.of(context).textTheme.titleSmall)),
            if (s.timeframe.isNotEmpty) Text(s.timeframe, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        if (s.why.isNotEmpty) Text(s.why),
        if (s.titles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in s.titles)
                  Tooltip(
                    message: t.reason,
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(t.source == FamilySource.ai ? 'AI: ${t.title}' : t.title),
                    ),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: ValueKey('stone.search.${normalJobTitle(s.role)}'),
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => RoleSearchPage(query: s.query))),
            icon: const Icon(Icons.travel_explore, size: 18),
            label: const Text('Search these jobs'),
          ),
        ),
      ],
    ),
  );
}

class _Pay extends StatelessWidget {
  const _Pay(this.i, {required this.needsAi});
  final RoleInsight i;
  final String needsAi;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final band = i.band?.text.toLowerCase() ?? '';
    final bands = <String, List<PayPoint>>{};
    for (final p in i.afc) {
      (bands['${p.scale}|${p.band}'] ??= []).add(p);
    }
    String money(int n) => '£${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (i.band case final b?) _Said('Usually NHS Agenda for Change Band ${b.text}', b.from),
        for (final f in i.pay)
          _Said(
            '${f.label.isEmpty ? '' : '${f.label}: '}${f.amount}'
            '${[f.source, f.asOf].where((x) => x.isNotEmpty).isEmpty ? '' : ' (${[f.source, f.asOf].where((x) => x.isNotEmpty).join(', ')})'}',
            f.from,
          ),
        if (bands.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Agenda for Change pay points built into Udyoga:', style: t.bodySmall),
          for (final e in bands.entries)
            Text(
              '${e.key.split('|').first}, Band ${e.value.first.band}: '
              '${e.value.map((p) => '${p.step} ${money(p.pay)}').join(', ')}'
              '${band.isNotEmpty && band.split(RegExp('[^0-9a-d]')).contains(e.value.first.band) ? '  (this role)' : ''}',
              style: t.bodySmall,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openLink(context, nhsCareersPayPage),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('All Agenda for Change rates (NHS Health Careers)'),
            ),
          ),
        ],
        for (final l in i.progression) _Said(l.text, l.from, icon: Icons.trending_up),
        if (i.pay.isEmpty && i.band == null && i.progression.isEmpty && i.afc.isEmpty) Text(needsAi),
      ],
    );
  }
}

/// The NHS Health Careers page on pay: linked, never copied.
const nhsCareersPayPage =
    'https://www.healthcareers.nhs.uk/working-health/working-nhs/nhs-pay-and-benefits/agenda-change-pay-rates';

/// The attribution a keyed source asks for.
class _Credit extends StatelessWidget {
  const _Credit(this.from);
  final InsightFrom from;

  @override
  Widget build(BuildContext context) {
    final c = switch (from) {
      InsightFrom.ncs => ncsCredit,
      InsightFrom.skillsEngland => skillsEnglandCredit,
      _ => null,
    };
    if (c == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: () => openLink(context, c.licenceUrl.isEmpty ? c.url : c.licenceUrl),
        child: Text('${c.name}: ${c.text}', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

/// Two or three roles side by side: fit, time to reach, pay and the first
/// move. Stacked on a phone.
class RoleCompare extends StatelessWidget {
  const RoleCompare(this.insights, {super.key});
  final List<RoleInsight> insights;

  Widget _column(BuildContext context, RoleInsight i) {
    final t = Theme.of(context).textTheme;
    Widget row(String label, String value, {bool ai = false}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: t.labelMedium),
              if (ai) ...[const SizedBox(width: 6), const AiTag()],
            ],
          ),
          SelectableText(value.isEmpty ? 'Not known yet' : value),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(i.role, style: t.titleMedium),
            row(
              'Fit',
              i.fit == null ? '' : '${i.fit}%${i.fitAi == null ? ' (skills shown in your profile)' : ''}',
              ai: i.fitAi != null,
            ),
            row('Time to reach', i.timeToReach, ai: i.path.any((s) => s.stage == 'target' && s.from.isAi)),
            row('Pay', i.payLine, ai: (i.pay.firstOrNull?.from ?? i.band?.from)?.isAi ?? false),
            row('First move', i.firstMove, ai: i.moves.firstOrNull?.from.isAi ?? false),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final i in insights)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: _column(context, i)),
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (n, i) in insights.indexed) ...[
              if (n > 0) const SizedBox(width: 12),
              Expanded(child: _column(context, i)),
            ],
          ],
        ),
      );
    },
  );
}

/// Every credit Udyoga shows for the data it uses, on one screen.
class DataSourcesPage extends ConsumerWidget {
  const DataSourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(careerDataKeysProvider).value ?? const CareerDataKeys();
    final t = Theme.of(context).textTheme;
    Widget entry(DataCredit c, {String status = ''}) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(status.isEmpty ? c.name : '${c.name} · $status'),
      subtitle: Text([c.text, if (c.note.isNotEmpty) c.note].join('\n')),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => openLink(context, c.url),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Data sources')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Job titles, skills and pay', style: t.titleMedium),
            entry(onsCredit),
            entry(escoDataCredit),
            entry(afcCredit),
            entry(nhsCareersCredit, status: 'link only'),
            const SizedBox(height: 12),
            Text('Career data with your own key (off by default)', style: t.titleMedium),
            entry(ncsCredit, status: keys.ncs.isEmpty ? 'off' : 'on, your key'),
            entry(skillsEnglandCredit, status: keys.skillsEngland.isEmpty ? 'off' : 'on, your key'),
            const SizedBox(height: 12),
            Text('Job sites', style: t.titleMedium),
            const Text('Ads from these sites carry their credit on each card.'),
            for (final c in feedCredits.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(c.label),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openLink(context, c.url),
              ),
            const SizedBox(height: 12),
            Text(
              'LinkedIn is only opened as a link in your browser; Udyoga never reads its pages. AI-written text is '
              'labelled AI wherever it appears.',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
