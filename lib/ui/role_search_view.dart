import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/job_identity.dart';
import '../domain/occupations.dart';
import '../domain/role_family.dart';
import '../domain/role_search.dart';
import '../domain/saved_searches.dart';
import 'common.dart';
import 'eligibility_view.dart';
import 'jobs_page.dart';
import 'kit/kit.dart';
import 'look.dart';
import 'site_page.dart';

/// "Search job sites for a role" on the Jobs page: type a role, see the
/// titles the same work goes by as chips (close ones on, the rest off),
/// choose, and search every job site that covers the person's places. The
/// results are ranked by title match, then fit, and the same job on several
/// boards is one card with each board's link. "Save this search" keeps the
/// role, the chosen titles and the exclusions as a saved search, which the
/// routine refresh then runs.
class RoleSearchView extends ConsumerStatefulWidget {
  const RoleSearchView({super.key, this.initial});

  /// A search to fill in and run at once (a stepping stone's "Search these
  /// jobs"); null starts empty.
  final RoleQuery? initial;

  @override
  ConsumerState<RoleSearchView> createState() => RoleSearchViewState();
}

/// The role search's state; the Jobs page calls [open] to run a saved
/// search here.
class RoleSearchViewState extends ConsumerState<RoleSearchView> {
  final role = TextEditingController();
  final notWords = TextEditingController();
  final notEmployers = TextEditingController();

  RoleFamily? family;
  var finding = false;

  /// Keys ([normalJobTitle]) of the family titles switched on.
  final on = <String>{};
  var exactOnly = false;

  /// Tasks and tools from ESCO; null hides the chips (offline, or a role
  /// the shipped data does not know).
  List<String>? skills;
  final skillsOn = <String>{};
  var askingAi = false;

  RoleSearch? _search;
  var searching = false;
  List<FeedRun> runs = const [];
  RoleSearchResult? result;
  RoleQuery? asked;
  var showOther = false;

  /// Results saved this time, by board and id.
  final saved = <String>{};

  /// The saved search on show, which "Save" updates; null: a new search.
  SavedSearch? editing;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    if (q != null) WidgetsBinding.instance.addPostFrameCallback((_) => openQuery(q));
  }

  @override
  void dispose() {
    role.dispose();
    notWords.dispose();
    notEmployers.dispose();
    super.dispose();
  }

  static List<String> _list(String text) => [
    for (final s in text.split(RegExp('[,;\n]')))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  /// The family of the role typed: the shipped data at once, then ESCO's
  /// titles and skills when it answers.
  Future<void> _findTitles() async {
    final r = role.text.trim();
    if (r.isEmpty) return;
    setState(() {
      // Another role is another search: the saved one's settings go.
      if (editing != null && normalJobTitle(editing!.role) != normalJobTitle(r)) {
        editing = null;
        exactOnly = false;
        notWords.clear();
        notEmployers.clear();
      }
      finding = true;
      result = null;
      skills = null;
      skillsOn.clear();
    });
    try {
      final index = await loadSocIndex();
      if (!mounted || role.text.trim() != r) return;
      final base = offlineFamily(r, index: index);
      setState(() {
        family = base;
        on
          ..clear()
          ..addAll([
            for (final t in base.titles)
              if (t.closeness == Closeness.close) normalJobTitle(t.title),
          ]);
      });
      final s = ref.read(sessionProvider);
      final families = RoleFamilies(ref.read(httpClientProvider), s.db, index: index);
      try {
        final full = await families.family(r);
        if (!mounted || role.text.trim() != r) return;
        final had = {for (final t in base.titles) normalJobTitle(t.title)};
        setState(() {
          family = full;
          for (final t in full.titles) {
            final k = normalJobTitle(t.title);
            if (!had.contains(k) && t.closeness == Closeness.close) on.add(k);
          }
        });
        final found = await families.skills(r);
        if (!mounted || role.text.trim() != r || found == null) return;
        setState(() => skills = {...found.essential.take(8), ...found.optional.take(4)}.toList());
      } on Object {
        // ESCO is extra: the shipped titles stand on their own.
      }
    } finally {
      if (mounted) setState(() => finding = false);
    }
  }

  Future<void> _suggestMore() async {
    final f = family;
    if (f == null) return;
    setState(() => askingAi = true);
    try {
      final advisor = await requireAdvisor(ref);
      final more = await aiFamilyTitles(advisor.ai, f);
      if (!mounted) return;
      setState(() => family = f.plus(more));
      if (more.isEmpty) showMessage(context, 'The AI had no other titles to suggest.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => askingAi = false);
    }
  }

  RoleQuery _query() {
    final f = family!;
    return RoleQuery(
      role: f.role,
      titles: [
        for (final t in f.titles)
          if (on.contains(normalJobTitle(t.title))) t,
      ],
      exactOnly: exactOnly,
      skills: [
        for (final s in skills ?? const <String>[])
          if (skillsOn.contains(s)) s,
      ],
      notWords: _list(notWords.text),
      notEmployers: _list(notEmployers.text),
      places: editing?.places ?? const [],
    );
  }

  /// Fills the search from [s], runs it and marks it looked at, so its
  /// new jobs stop counting as new. A search saved with no titles (moved
  /// from an old profile) starts with the close titles on, for when the
  /// person turns "Exact title only" off.
  Future<void> open(SavedSearch s) async {
    final index = await loadSocIndex();
    if (!mounted) return;
    final base = offlineFamily(s.role, index: index).plus([for (final t in s.titles) t.title]);
    setState(() {
      editing = s;
      role.text = s.role;
      notWords.text = s.notWords.join(', ');
      notEmployers.text = s.notEmployers.join(', ');
      exactOnly = s.exactOnly;
      family = base;
      on
        ..clear()
        ..addAll([
          if (s.titles.isEmpty)
            for (final t in base.titles)
              if (t.closeness == Closeness.close) normalJobTitle(t.title),
          for (final t in s.titles)
            if (t.on) normalJobTitle(t.title.title),
        ]);
      skills = s.skills.isEmpty ? null : List.of(s.skills);
      skillsOn
        ..clear()
        ..addAll(s.skills);
    });
    await ref.mutate((x) => x.book.markLooked(s.id));
    await _run();
  }

  /// Fills the search from [q] (its titles added to the role's family and
  /// switched on, so every one shows as a chip that can be switched off)
  /// and runs it.
  Future<void> openQuery(RoleQuery q) async {
    final index = await loadSocIndex();
    if (!mounted) return;
    final base = offlineFamily(q.role, index: index).plus(q.titles);
    setState(() {
      editing = null;
      role.text = q.role;
      notWords.text = q.notWords.join(', ');
      notEmployers.text = q.notEmployers.join(', ');
      exactOnly = q.exactOnly;
      family = base;
      on
        ..clear()
        ..addAll([
          for (final t in base.titles)
            if (t.closeness == Closeness.close) normalJobTitle(t.title),
          for (final t in q.titles) normalJobTitle(t.title),
        ]);
      skills = q.skills.isEmpty ? null : List.of(q.skills);
      skillsOn
        ..clear()
        ..addAll(q.skills);
    });
    await _run();
  }

  /// Saves the search on show: a new saved search, or the one opened.
  Future<void> _saveSearch() async {
    final f = family;
    if (f == null) return;
    final q = _query();
    final book = ref.read(sessionProvider).book;
    // The stored copy, so a rename made since it was opened is kept.
    final was = editing == null
        ? null
        : (await book.savedSearches()).where((x) => x.id == editing!.id).firstOrNull ?? editing;
    if (!mounted) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final s = SavedSearch(
      id: was?.id ?? newId(),
      name: was?.name ?? f.role,
      role: f.role,
      titles: [
        for (final t in f.titles)
          if (t.source != FamilySource.typed) SearchTitle(t, on: on.contains(normalJobTitle(t.title))),
      ],
      exactOnly: q.exactOnly,
      skills: q.skills,
      notWords: q.notWords,
      notEmployers: q.notEmployers,
      places: was?.places ?? const [],
      created: was?.created ?? now,
      updated: now,
      lastLooked: was?.lastLooked,
      seen: was?.seen ?? const [],
    );
    try {
      final out = await ref.mutate((x) => x.book.saveSearch(s));
      if (!mounted) return;
      setState(() => editing = out);
      showMessage(
        context,
        was == null ? 'Saved. Udyoga checks it with every refresh.' : 'Saved search "${out.name}" updated.',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _run() async {
    if (family == null) await _findTitles();
    if (!mounted || family == null) return;
    final q = _query();
    final s = ref.read(sessionProvider);
    final search = _search ??= RoleSearch(s.book, ref.read(httpClientProvider), secrets: s.keys.store);
    setState(() {
      searching = true;
      result = null;
      runs = const [];
      showOther = false;
    });
    try {
      final r = await search.run(
        q,
        today: today(),
        onProgress: (feeds) {
          if (mounted) setState(() => runs = List.of(feeds));
        },
      );
      if (mounted) {
        setState(() {
          result = r;
          asked = q;
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  static String _id(RoleHit h) => '${h.main.source}:${h.main.sourceId}';

  Future<void> _save(RoleHit h) async {
    final id = await saveAdvert(ref, h.toSave());
    if (!mounted) return;
    setState(() => saved.add(_id(h)));
    showMessage(context, id == null ? 'That job is already on your list.' : 'Saved to your jobs.');
  }

  Future<void> _saveAll(List<RoleHit> hits) async {
    var added = 0;
    for (final h in hits) {
      if (saved.contains(_id(h))) continue;
      if (await saveAdvert(ref, h.toSave()) != null) added++;
      saved.add(_id(h));
    }
    if (!mounted) return;
    setState(() {});
    showMessage(
      context,
      added == 0 ? 'They are all on your list already.' : 'Saved $added ${added == 1 ? 'job' : 'jobs'}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasAi = ref.watch(advisorProvider).value != null;
    final f = family;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('roleSearch.role'),
          controller: role,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.travel_explore),
            hintText: 'A role, such as Digital Training Facilitator',
            suffixIcon: IconButton(
              tooltip: 'Find the titles it goes by',
              icon: const Icon(Icons.arrow_forward),
              onPressed: finding ? null : _findTitles,
            ),
          ),
          onSubmitted: (_) => _findTitles(),
        ),
        if (finding && f == null)
          const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (f != null) ...[
          const SizedBox(height: 8),
          Text(
            'Searches for "${f.role}" and the titles switched on below. Hold or hover a title to see why it is here.',
            style: t.bodySmall?.copyWith(color: muted),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Exact title only'),
            subtitle: Text('Only "${f.role}", and only jobs whose title says it'),
            value: exactOnly,
            onChanged: (v) => setState(() => exactOnly = v),
          ),
          for (final (label, titles) in [
            (
              'Close titles',
              [
                for (final x in f.where(Closeness.close))
                  if (x.source != FamilySource.typed) x,
              ],
            ),
            (
              'Related titles',
              [
                for (final x in f.where(Closeness.related))
                  if (x.source != FamilySource.ai) x,
              ],
            ),
            (
              'Further away',
              [
                for (final x in f.where(Closeness.distant))
                  if (x.source != FamilySource.ai) x,
              ],
            ),
            (
              'AI suggestions (check them)',
              [
                for (final x in f.titles)
                  if (x.source == FamilySource.ai) x,
              ],
            ),
          ])
            if (titles.isNotEmpty) ...[
              Subhead(label),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final x in titles)
                    FilterChip(
                      avatar: x.source == FamilySource.ai ? const Icon(Icons.auto_awesome, size: 16) : null,
                      label: Text(x.source == FamilySource.ai ? 'AI: ${x.title}' : x.title),
                      tooltip: x.reason,
                      selected: !exactOnly && on.contains(normalJobTitle(x.title)),
                      onSelected: exactOnly
                          ? null
                          : (v) => setState(() {
                              final k = normalJobTitle(x.title);
                              v ? on.add(k) : on.remove(k);
                            }),
                    ),
                ],
              ),
            ],
          if (finding) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          if (hasAi)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: askingAi || exactOnly ? null : _suggestMore,
                  icon: askingAi
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Suggest more (AI)'),
                ),
              ),
            ),
          if (skills case final s? when s.isNotEmpty) ...[
            const Subhead('Also search tasks/tools'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final x in s)
                  FilterChip(
                    label: Text(x),
                    selected: !exactOnly && skillsOn.contains(x),
                    onSelected: exactOnly
                        ? null
                        : (v) => setState(() => v ? skillsOn.add(x) : skillsOn.remove(x)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'This service uses the ESCO classification of the European Commission.',
              style: t.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: notWords,
            decoration: const InputDecoration(
              labelText: 'Leave out jobs that say',
              hintText: 'senior, bank, locum',
              helperText: 'Words in the title or employer, separated by commas.',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notEmployers,
            decoration: const InputDecoration(
              labelText: 'Leave out employers or agencies',
              helperText: 'Separated by commas. Your profile exclusions still apply.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const ValueKey('roleSearch.run'),
                onPressed: searching ? null : _run,
                icon: const Icon(Icons.search),
                label: Text(searching ? 'Searching…' : 'Search job sites'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('roleSearch.save'),
                onPressed: _saveSearch,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(editing == null ? 'Save this search' : 'Update saved search'),
              ),
            ],
          ),
        ],
        if (runs.isNotEmpty) ...[const SizedBox(height: 12), for (final r in runs) _FeedLine(r)],
        if (result case final r?) ..._results(context, r),
      ],
    );
  }

  List<Widget> _results(BuildContext context, RoleSearchResult r) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final matched = [
      for (final h in r.hits)
        if (h.match != TitleMatch.other) h,
    ];
    final other = [
      for (final h in r.hits)
        if (h.match == TitleMatch.other) h,
    ];
    final bySkills = asked?.skills.isNotEmpty ?? false;
    final shown = [...matched, if (showOther || bySkills) ...other];
    return [
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            [
              '${matched.length} ${matched.length == 1 ? 'job' : 'jobs'} with a chosen title',
              if (other.isNotEmpty) '${other.length} more',
              if (r.leftOut > 0) '${r.leftOut} left out by your exclusions',
            ].join(' · '),
            style: t.titleSmall,
          ),
          if (shown.isNotEmpty)
            TextButton.icon(
              onPressed: () => _saveAll(shown),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save all'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (r.hits.isEmpty)
        EmptyState(
          icon: Icons.search_off,
          title: 'No jobs found',
          message: exactOnly
              ? 'Try again with "Exact title only" off, so the other titles are searched too.'
              : 'Switch on more titles, or check your countries and home areas on your profile.',
        ),
      for (final h in matched) _HitCard(h, saved: saved.contains(_id(h)), onSave: () => _save(h)),
      if (other.isNotEmpty && bySkills) const Subhead('Found by tasks and tools'),
      if (other.isNotEmpty && !bySkills)
        Center(
          child: TextButton(
            onPressed: () => setState(() => showOther = !showOther),
            child: Text(
              showOther
                  ? 'Hide the ${other.length} whose title is none of the chosen titles'
                  : 'Show ${other.length} more whose title is none of the chosen titles',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      if (showOther || bySkills)
        for (final h in other) _HitCard(h, saved: saved.contains(_id(h)), onSave: () => _save(h)),
      if (matched.isEmpty && other.isNotEmpty && !showOther && !bySkills)
        Text(
          'No result has one of the chosen titles.',
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: muted),
        ),
    ];
  }
}

/// One feed's line in the progress list.
class _FeedLine extends StatelessWidget {
  const _FeedLine(this.run);
  final FeedRun run;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (Widget icon, String state) = switch (run.state) {
      FeedState.waiting => (Icon(Icons.schedule, size: 18, color: muted), 'Waiting'),
      FeedState.running => (
        const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        'Searching…',
      ),
      FeedState.done => (
        Icon(Icons.check_circle_outline, size: 18, color: Status.good.color),
        '${run.found} found${run.problem.isEmpty ? '' : ' (some searches failed: ${run.problem})'}',
      ),
      FeedState.failed => (
        Icon(Icons.error_outline, size: 18, color: Status.warning.color),
        run.problem.isEmpty ? 'Failed' : run.problem,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Center(child: icon)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: run.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '  $state',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
              style: t.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// One result: title, employer, place and pay, the title it matched and
/// why, each board's link, and Save.
class _HitCard extends StatelessWidget {
  const _HitCard(this.hit, {required this.saved, required this.onSave});
  final RoleHit hit;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final j = hit.main;
    final pay = shortPay(currency: j.currency, min: j.salaryMin, max: j.salaryMax, text: j.salaryText);
    final credits = {
      for (final p in hit.postings)
        if (SourceCredit.needed(p.source)) p.source,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SpotlightCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrgLogo(j.company.isEmpty ? j.title : j.company),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        [j.company, j.location].where((s) => s.isNotEmpty).join(' · '),
                        style: t.bodyMedium?.copyWith(color: muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FitBadge(hit.fit),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: hit.why,
                child: StatusPill(
                  switch (hit.match) {
                    TitleMatch.exact => 'Exact title',
                    TitleMatch.family => 'Matched: ${hit.matched!.title}',
                    TitleMatch.other => 'Other result',
                  },
                  status: hit.match == TitleMatch.exact ? Status.good : null,
                  icon: Icons.label_outline,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hit.why,
              style: t.bodySmall?.copyWith(color: muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final l in hit.links)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new, size: 16),
                    label: Text(sourceName(l.source)),
                    tooltip: 'Open on ${sourceName(l.source)}',
                    onPressed: () => openSite(context, url: l.url, title: j.title),
                  ),
                for (final c in credits) SourceCredit(c),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    pay.isEmpty ? 'Pay not given' : pay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pay.isEmpty
                        ? t.bodyMedium?.copyWith(color: muted)
                        : t.titleMedium?.copyWith(fontFamily: headingFont, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: saved ? null : onSave,
                  icon: Icon(saved ? Icons.bookmark_added : Icons.bookmark_add_outlined),
                  label: Text(saved ? 'Saved' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Role search on a page of its own, filled in from [query] and run at
/// once: where a stepping stone's "Search these jobs" goes.
class RoleSearchPage extends StatelessWidget {
  const RoleSearchPage({super.key, required this.query});
  final RoleQuery query;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Jobs: ${query.role}')),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [RoleSearchView(initial: query)]),
    ),
  );
}
