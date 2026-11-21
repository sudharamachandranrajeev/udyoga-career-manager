import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/explore_providers.dart';
import '../app/providers.dart';
import '../db/database.dart';
import '../domain/ai.dart';
import '../domain/avenues.dart';
import '../domain/explore.dart';
import '../domain/feeds.dart';
import '../domain/json.dart';
import '../domain/occupations.dart';
import '../domain/profile.dart';
import '../domain/route_refresh.dart';
import '../domain/routes.dart';
import '../domain/tracks.dart';
import '../domain/world.dart';
import 'common.dart';
import 'job_page.dart';
import 'kit/status_bridge.dart';

Status tierStatus(Tier t) => switch (t) {
  Tier.ready => Status.good,
  Tier.possible => Status.info,
  Tier.later => Status.warning,
  Tier.blocked => Status.serious,
};

IconData tierIcon(Tier t) => switch (t) {
  Tier.ready => Icons.check_circle_outline,
  Tier.possible => Icons.flight_takeoff,
  Tier.later => Icons.schedule,
  Tier.blocked => Icons.block,
};

/// Where the person could work: every country screened, and the route
/// tracks they are working on.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  var _tracks = false;
  Tier? _tier;
  var _withData = false;
  var _query = '';
  var _shown = 40;

  @override
  Widget build(BuildContext context) {
    final screens = ref.watch(screensProvider);
    final tracks = ref.watch(tracksProvider).value ?? const <RouteTrack>[];
    return PageScaffold(
      title: 'Explore',
      banner: 'page.explore',
      actions: [
        IconButton(
          tooltip: 'Read the UK and Canada rules again',
          icon: const Icon(Icons.refresh),
          onPressed: _refreshRules,
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SegmentedButton<bool>(
            segments: [
              const ButtonSegment(value: false, label: Text('Countries'), icon: Icon(Icons.public)),
              ButtonSegment(
                value: true,
                label: Text('Tracks (${tracks.length})'),
                icon: const Icon(Icons.route),
              ),
            ],
            selected: {_tracks},
            onSelectionChanged: (s) => setState(() => _tracks = s.first),
          ),
        ),
        if (_tracks)
          TracksView(tracks)
        else
          ...switch (screens) {
            AsyncData(:final value) => _countries(value),
            AsyncError(:final error) => [
              StatusLabel(Status.serious, 'Could not screen the countries: $error'),
            ],
            _ => const [Center(child: CircularProgressIndicator())],
          },
      ],
    );
  }

  List<Widget> _countries(List<CountryScreen> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((s) {
      if (_tier != null && s.tier != _tier) return false;
      if (_withData && !s.hasRoutes && s.basis == null) return false;
      if (q.isEmpty) return true;
      return s.country.name.toLowerCase().contains(q) || s.code.toLowerCase() == q;
    }).toList();
    final counts = {for (final t in Tier.values) t: all.where((s) => s.tier == t).length};
    return [
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search countries'),
        onChanged: (v) => setState(() {
          _query = v;
          _shown = 40;
        }),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final t in Tier.values)
            FilterChip(
              label: Text('${t.label} (${counts[t]})'),
              tooltip: t.meaning,
              avatar: Icon(tierIcon(t), size: 18, color: tierStatus(t).color),
              selected: _tier == t,
              onSelected: (on) => setState(() => _tier = on ? t : null),
            ),
          FilterChip(
            label: const Text('With route data'),
            tooltip: 'Only countries Udyoga has sourced rules for, or where you may already work.',
            selected: _withData,
            onSelected: (on) => setState(() => _withData = on),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No country matches.')),
      for (final s in list.take(_shown)) CountryTile(s),
      if (list.length > _shown)
        TextButton(
          onPressed: () => setState(() => _shown += 60),
          child: Text('Show more (${list.length - _shown} left)'),
        ),
    ];
  }

  Future<void> _refreshRules() async {
    final s = ref.read(sessionProvider);
    final refresh = RouteRefresh(ref.read(httpClientProvider), s.db);
    final problems = <String>[];
    try {
      await refresh.refreshUk(force: true);
    } on FeedException catch (e) {
      problems.add('UK: $e');
    }
    try {
      await refresh.refreshRounds(force: true);
    } on FeedException catch (e) {
      problems.add('Canada: $e');
    }
    ref.invalidate(ukRulesProvider);
    ref.invalidate(expressEntryProvider);
    if (!mounted) return;
    showToast(
      context,
      problems.isEmpty ? 'Rules read again' : 'Some rules could not be read',
      description: problems.isEmpty
          ? 'From GOV.UK and IRCC.'
          : '${problems.join('. ')}. Using the last good copy.',
      status: problems.isEmpty ? Status.good : Status.warning,
    );
  }
}

/// One country in the list: its tier and the first reason.
class CountryTile extends StatelessWidget {
  const CountryTile(this.s, {super.key});
  final CountryScreen s;

  @override
  Widget build(BuildContext context) {
    final line = s.blockers.isNotEmpty && s.tier != Tier.ready
        ? s.blockers.first
        : s.reasons.firstOrNull ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(s.country.name),
      subtitle: Text(
        [if (s.target) 'On your list', s.country.region, if (line.isNotEmpty) line].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StatusPill(s.tier.label, status: tierStatus(s.tier), icon: tierIcon(s.tier)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CountryPage(s.code))),
    );
  }
}

/// One country in full: its routes and thresholds with sources, blockers,
/// live jobs, the AI assessment, the prep plan and a track.
class CountryPage extends ConsumerWidget {
  const CountryPage(this.code, {super.key});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screens = ref.watch(screensProvider).value;
    final s = screens?.where((x) => x.code == code).firstOrNull;
    final country = worldCountry(code);
    if (country == null) return const Scaffold(body: Center(child: Text('Unknown country')));
    final hasAi = ref.watch(advisorProvider).value != null;
    final p = ref.watch(profileProvider).value ?? const CandidateProfile();
    final occupations = ref.watch(occupationsProvider).value ?? const <OccupationMatch>[];
    final uk = ref.watch(ukRulesProvider).value ?? shippedUkRules;
    final jobs = (ref.watch(jobsProvider).value ?? const <Job>[])
        .where((j) => j.country.toUpperCase() == code && j.status != 'dismissed')
        .take(6)
        .toList();
    final reports = ref.watch(reportsProvider).value ?? const <Report>[];
    Report? latest(String kind) => reports
        .where((r) => r.kind == kind && str(decodeObject(r.content)['country']).toUpperCase() == code)
        .firstOrNull;
    final avenue = latest(avenueKind), plan = latest(avenuePlanKind);
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: Text(country.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return PageScaffold(
      title: country.name,
      actions: [
        IconButton(
          tooltip: 'Track this route',
          onPressed: () => _track(context, ref, s, p),
          icon: const Icon(Icons.add_road),
        ),
      ],
      children: [
        _Summary(s),
        for (final c in s.routes) _RouteCard(c),
        if (code == 'CA') const _Rounds(),
        _Codes(occupations: occupations, uk: code == 'GB' ? uk : null),
        SectionCard(
          title: 'Live jobs',
          hint: 'explore.jobs',
          trailing: p.searchCountries.contains(code)
              ? const Tooltip(message: 'In your target countries', child: Icon(Icons.check_circle_outline))
              : TextButton.icon(
                  onPressed: () async {
                    await ref.mutate((x) => x.book.addTargetCountry(code));
                    if (context.mounted) {
                      showMessage(
                        context,
                        '${country.name} added to your targets. Its jobs come on the next refresh.',
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to targets'),
                ),
          child: jobs.isEmpty
              ? Text(
                  p.searchCountries.contains(code)
                      ? 'No saved openings in ${country.name} yet. The job sites search it on each refresh.'
                      : 'No saved openings in ${country.name} yet. Add it to your targets and the job sites '
                            'search it on the next refresh.',
                )
              : Column(
                  children: [
                    for (final j in jobs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(j.title),
                        subtitle: Text([j.company, j.location].where((t) => t.isNotEmpty).join(' · ')),
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobPage(j.id))),
                      ),
                  ],
                ),
        ),
        if (!hasAi) const NeedsKey(what: 'The avenue assessment and prep plan'),
        SectionCard(
          title: 'AI assessment',
          hint: 'explore.assess',
          trailing: hasAi
              ? TextButton(
                  onPressed: () => _assess(context, ref, p, s, occupations),
                  child: Text(avenue == null ? 'Assess' : 'Redo'),
                )
              : null,
          child: avenue == null
              ? const Text(
                  'The AI checks the screen against official sources and finds live adverts, pay against '
                  'living costs, the route by name, every blocker and where your hopes are unrealistic.',
                )
              : _AvenueView(
                  AvenueAssessment(decodeObject(avenue.content)),
                  created: avenue.created,
                  sources: SourcesList.fromJson(avenue.sources),
                ),
        ),
        SectionCard(
          title: 'Prep plan',
          hint: 'explore.plan',
          trailing: hasAi
              ? TextButton(
                  onPressed: () => _plan(context, ref, p, s, avenue),
                  child: Text(plan == null ? 'Make' : 'Redo'),
                )
              : null,
          child: plan == null
              ? const Text(
                  'Ordered steps timed to your right-to-work end date: getting qualifications recognised, '
                  'tests, certifications with cost and time, CV gaps and applications.',
                )
              : _PlanView(
                  PrepPlan(decodeObject(plan.content)),
                  countryName: country.name,
                  sources: SourcesList.fromJson(plan.sources),
                ),
        ),
      ],
    );
  }

  String? _rightEnds(CandidateProfile p) {
    final ends = [
      for (final r in p.rights.rightToWork)
        if (r.until != null && r.activeOn(today())) r.until!,
    ]..sort();
    return ends.firstOrNull;
  }

  Future<void> _track(BuildContext context, WidgetRef ref, CountryScreen s, CandidateProfile p) async {
    final t = suggestTrack(s, today: today(), rightEnds: _rightEnds(p));
    await ref.mutate(
      (x) => x.book.saveTrack(
        country: s.code,
        title: t.title,
        routeId: t.routeId,
        trigger: t.trigger,
        milestones: t.milestones,
        today: today(),
      ),
    );
    if (context.mounted) {
      showToast(
        context,
        'Track added',
        description: '${t.milestones.length} milestones. See Explore, Tracks.',
      );
    }
  }

  Future<void> _assess(
    BuildContext context,
    WidgetRef ref,
    CandidateProfile p,
    CountryScreen s,
    List<OccupationMatch> occupations,
  ) async {
    final client = ref.read(httpClientProvider);
    final r = await runAi(
      context,
      title: 'Assessing ${s.country.name}',
      task: (progress) async {
        progress('Reading World Bank and ILOSTAT figures');
        final economy = await fetchEconomy(client, s.code);
        return (await requireAdvisor(ref))
            .assessAvenue(p, s, occupations: occupations, economy: economy, onProgress: progress);
      },
    );
    if (r == null) return;
    await ref.mutate(
      (x) => x.book.saveReport(avenueKind, {...r.data, 'country': s.code}, r.sources, at: nowLocal()),
    );
  }

  Future<void> _plan(
    BuildContext context,
    WidgetRef ref,
    CandidateProfile p,
    CountryScreen s,
    Report? avenue,
  ) async {
    final deadline = [?s.deadline, ?_rightEnds(p)]..sort();
    final r = await runAi(
      context,
      title: 'Planning for ${s.country.name}',
      task: (progress) async => (await requireAdvisor(ref)).prepPlan(
        p,
        s,
        assessment: avenue == null ? null : AvenueAssessment(decodeObject(avenue.content)),
        deadline: deadline.firstOrNull,
        options: qualificationOptions[s.code] ?? const [],
        onProgress: progress,
      ),
    );
    if (r == null) return;
    await ref.mutate(
      (x) => x.book.saveReport(avenuePlanKind, {...r.data, 'country': s.code}, r.sources, at: nowLocal()),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.s);
  final CountryScreen s;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Where you stand',
    hint: 'explore.tier',
    trailing: StatusPill(s.tier.label, status: tierStatus(s.tier), icon: tierIcon(s.tier)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.tier.meaning, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final r in s.reasons) _Line(Icons.check, r),
        for (final b in s.blockers) _Line(Icons.warning_amber_rounded, b, status: Status.warning),
        if (s.deadline != null)
          _Line(Icons.event, 'Deadline: ${niceDate(s.deadline!)} (${relativeDay(s.deadline!, today())}).'),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text, {this.status});
  final IconData icon;
  final String text;
  final Status? status;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 18, color: status?.color)),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

String _fitLabel(RouteFit f) => switch (f) {
  RouteFit.fits => 'Fits',
  RouteFit.gap => 'Gap',
  RouteFit.unknown => 'Not checked',
  RouteFit.ineligible => 'Not eligible',
};

Status _fitStatus(RouteFit f) => switch (f) {
  RouteFit.fits => Status.good,
  RouteFit.gap => Status.warning,
  RouteFit.unknown => Status.info,
  RouteFit.ineligible => Status.serious,
};

class _RouteCard extends StatelessWidget {
  const _RouteCard(this.c);
  final RouteCheck c;

  @override
  Widget build(BuildContext context) {
    final r = c.route;
    return SectionCard(
      title: r.name,
      hint: 'explore.route',
      trailing: StatusPill(_fitLabel(c.fit), status: _fitStatus(c.fit)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!r.verified)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: StatusPill('Unverified', status: Status.warning, icon: Icons.help_outline),
            ),
          Text(r.summary),
          if (r.floor != null || r.reducedFloor != null) const Subhead('Pay threshold'),
          if (r.floor != null)
            Text('${r.floor!.label}${r.rule == OccupationRule.ukSkilled ? ' or the going rate' : ''}'),
          if (r.reducedFloor != null) Text('${r.reducedFloor!.label} for ${r.reducedWhen}'),
          if (c.reasons.isNotEmpty) const Subhead('For you'),
          for (final s in c.reasons) _Line(Icons.arrow_right, s),
          if (r.requirements.isNotEmpty) const Subhead('What it needs'),
          for (final s in r.requirements) _Line(Icons.check_box_outline_blank, s),
          if (r.notes.isNotEmpty) const Subhead('Worth knowing'),
          for (final s in r.notes) _Line(Icons.info_outline, s),
          const Subhead('Sources'),
          for (final src in [r.source, ...r.more])
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link, size: 18),
              title: Text(src.title),
              subtitle: Text(
                'As of ${niceDate(src.asOf)}${src.verified ? '' : ' · unverified'}',
                style: src.verified ? null : TextStyle(color: Status.warning.color),
              ),
              onTap: () => openLink(context, src.url),
            ),
        ],
      ),
    );
  }
}

class _Rounds extends ConsumerWidget {
  const _Rounds();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ee = ref.watch(expressEntryProvider).value;
    return SectionCard(
      title: 'Latest Express Entry rounds',
      hint: 'explore.rounds',
      child: ee == null
          ? const Text('IRCC could not be reached. Use the refresh button to try again.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in ee.rounds.take(5))
                  _Line(
                    Icons.how_to_vote_outlined,
                    '${niceDate(r.date)}: ${r.name}, CRS ${r.crs}, ${r.size} invited',
                  ),
                Text(
                  'Read from IRCC on ${niceDate(ee.checked)}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _Codes extends ConsumerWidget {
  const _Codes({required this.occupations, this.uk});
  final List<OccupationMatch> occupations;
  final UkRules? uk;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: 'Your job codes',
    hint: 'explore.codes',
    trailing: TextButton(onPressed: () => _lookUp(context, ref), child: const Text('Look up ISCO')),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (occupations.isEmpty)
          const Text('Add target roles or your current role on the Profile page to code them.'),
        for (final o in occupations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(o.title),
            subtitle: Text(
              [
                if (o.soc.isNotEmpty) 'SOC 2020 ${o.soc} ${o.socTitle}${o.exact ? '' : ' (closest match)'}',
                if (o.isco.isNotEmpty)
                  'ISCO-08 ${o.isco}${o.iscoTitle.isEmpty ? '' : ' (ESCO: ${o.iscoTitle})'}',
                if (uk != null && o.soc.isNotEmpty) _ukLine(o.soc, uk!),
              ].join('\n'),
            ),
          ),
        Text(
          'SOC from the ONS coding index; ISCO from ESCO. The employer or sponsor decides the code in the end.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  String _ukLine(String soc, UkRules uk) {
    final t = ukThreshold(soc, uk);
    if (t == null) return 'No UK rate shipped for this code';
    if (t.floor == null) return 'Not eligible for Skilled Worker (Table 6)';
    return 'UK threshold £${t.floor} (new entrant £${t.newEntrantFloor}), Table ${t.occupation.table}';
  }

  Future<void> _lookUp(BuildContext context, WidgetRef ref) async {
    final p = await ref.read(profileProvider.future);
    final titles = titlesOf(p);
    final esco = EscoLookup(ref.read(httpClientProvider), ref.read(sessionProvider).db);
    await loadSocIndex();
    final out = await esco.complete(titles, codeTitles(titles));
    ref.invalidate(occupationsProvider);
    if (context.mounted) {
      showToast(
        context,
        'Looked up in ESCO',
        description: '${out.where((o) => o.isco.isNotEmpty).length} coded.',
      );
    }
  }
}

class _AvenueView extends StatelessWidget {
  const _AvenueView(this.a, {required this.created, required this.sources});
  final AvenueAssessment a;
  final String created;
  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    final route = a.route, pay = a.pay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            StatusPill(
              'Confidence: ${a.confidence.isEmpty ? 'not given' : a.confidence}',
              status: switch (a.confidence) {
                'high' => Status.good,
                'low' => Status.warning,
                _ => Status.info,
              },
            ),
            StatusPill('As of ${niceDateTime(created)}', quiet: true),
          ],
        ),
        const SizedBox(height: 8),
        Text(a.summary),
        if (a.confidenceWhy.isNotEmpty) Text(a.confidenceWhy, style: Theme.of(context).textTheme.bodySmall),
        if (str(route['name']).isNotEmpty) ...[
          const Subhead('Route'),
          Text('${str(route['name'])} (${str(route['fits'])}). ${str(route['threshold'])}'),
          if (str(route['why']).isNotEmpty) Text(str(route['why'])),
          if (str(route['officialUrl']).startsWith('http'))
            TextButton(
              onPressed: () => openLink(context, str(route['officialUrl'])),
              child: const Text('Official page'),
            ),
        ],
        if (a.roleFamilies.isNotEmpty) const Subhead('Role families'),
        for (final f in a.roleFamilies)
          _Line(
            Icons.work_outline,
            '${str(f['title'])}${str(f['occupationCode']).isEmpty ? '' : ' (${str(f['occupationCode'])})'}: '
            '${str(f['demand'])} demand. ${str(f['payRange'])} ${str(f['fit'])}',
          ),
        if (str(pay['typical']).isNotEmpty) ...[
          const Subhead('Pay and cost of living'),
          Text(str(pay['typical'])),
          Text(str(pay['costOfLiving'])),
          Text(str(pay['verdict'])),
        ],
        if (a.adverts.isNotEmpty) const Subhead('Live adverts'),
        for (final ad in a.adverts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('${str(ad['title'])}, ${str(ad['employer'])}'),
            subtitle: Text(
              [
                str(ad['location']),
                str(ad['salary']),
                str(ad['sponsorship']),
              ].where((t) => t.isNotEmpty).join(' · '),
            ),
            onTap: str(ad['url']).startsWith('http') ? () => openLink(context, str(ad['url'])) : null,
          ),
        if (a.blockers.isNotEmpty) const Subhead('Blockers'),
        for (final b in a.blockers)
          _Line(
            Icons.warning_amber_rounded,
            '${str(b['blocker'])} (${str(b['severity'])}). ${str(b['fix'])}',
            status: str(b['severity']) == 'stops' ? Status.serious : Status.warning,
          ),
        if (a.pushback.isNotEmpty) const Subhead('Pushback'),
        for (final x in a.pushback) _Line(Icons.record_voice_over_outlined, x),
        if (a.nextSteps.isNotEmpty) const Subhead('Next steps'),
        for (final (i, x) in a.nextSteps.indexed) _Line(Icons.arrow_right, '${i + 1}. $x'),
        SourcesList(sources),
      ],
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView(this.plan, {required this.countryName, required this.sources});
  final PrepPlan plan;
  final String countryName;
  final List<Source> sources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = plan.qualification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.summary),
        if (isDay(plan.deadline)) Text('Works back from ${niceDate(plan.deadline)}.'),
        const Subhead('Steps'),
        for (final s in plan.steps)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${s.order}. ${s.title}'),
            subtitle: Text(
              [
                s.why,
                [
                  if (s.cost.isNotEmpty) s.cost,
                  if (s.time.isNotEmpty) s.time,
                  if (s.due != null) 'by ${niceDate(s.due!)}',
                  if (!s.verified) 'unverified',
                ].join(' · '),
              ].where((t) => t.isNotEmpty).join('\n'),
            ),
            trailing: IconButton(
              tooltip: 'Make a to-do from "${s.title}"',
              icon: const Icon(Icons.add_task),
              onPressed: () async {
                await ref.mutate((x) => x.book.stepTodo(plan, s, countryName: countryName, today: today()));
                if (context.mounted) showToast(context, 'Added to your to-dos');
              },
            ),
            onTap: s.url.startsWith('http') ? () => openLink(context, s.url) : null,
          ),
        if (q.isNotEmpty) ...[
          const Subhead('Qualification planner'),
          Text(
            q['needed'] == true
                ? 'Recognition or checks are likely needed.'
                : 'Recognition is probably not needed for the route.',
          ),
          if (str(q['recommendation']).isNotEmpty) Text(str(q['recommendation'])),
          for (final o in plan.qualificationOptions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(str(o['name'])),
              subtitle: Text(
                [
                  str(o['what']),
                  [
                    str(o['cost']),
                    str(o['time']),
                    'university must respond: ${str(o['needsUniversity'])}',
                    str(o['when']),
                  ].where((t) => t.isNotEmpty).join(' · '),
                ].join('\n'),
              ),
              onTap: str(o['url']).startsWith('http') ? () => openLink(context, str(o['url'])) : null,
            ),
        ],
        if (plan.risks.isNotEmpty) const Subhead('Risks'),
        for (final r in plan.risks) _Line(Icons.warning_amber_rounded, r, status: Status.warning),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.school_outlined),
              label: const Text('Send to Vidya'),
              onPressed: () async {
                await ref.mutate(
                  (x) => x.book.sendAvenueToVidya(plan, countryName: countryName, now: nowLocal()),
                );
                if (context.mounted) {
                  showToast(context, 'Sent to Vidya', description: 'It arrives when both apps sync.');
                }
              },
            ),
          ],
        ),
        SourcesList(sources),
      ],
    );
  }
}

/// The route tracks: each with its trigger and milestones.
class TracksView extends ConsumerWidget {
  const TracksView(this.tracks, {super.key});
  final List<RouteTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return const EmptyState(
        icon: Icons.route,
        title: 'No tracks yet',
        message: 'Open a country and press Track to work on a route with dated milestones. Run several side by side.',
      );
    }
    return Column(children: [for (final t in tracks) _TrackCard(t)]);
  }
}

const _statuses = {'active': 'Active', 'paused': 'Paused', 'done': 'Done', 'dropped': 'Dropped'};

class _TrackCard extends ConsumerWidget {
  const _TrackCard(this.t);
  final RouteTrack t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = today();
    final ms = milestonesOf(t);
    return SectionCard(
      title: t.title,
      hint: 'explore.track',
      trailing: PopupMenuButton<String>(
        tooltip: 'Track options',
        onSelected: (v) async {
          if (v == 'delete') {
            final ok = await confirm(
              context,
              title: 'Delete this track?',
              message: 'Its milestones go too. To-dos made from them stay.',
              action: 'Delete',
              destructive: true,
            );
            if (ok) await ref.mutate((s) => s.book.deleteTrack(t.id));
          } else if (v == 'add') {
            if (context.mounted) await _addMilestone(context, ref);
          } else {
            await ref.mutate(
              (s) => s.book.saveTrack(
                id: t.id,
                country: t.country,
                title: t.title,
                trigger: t.trigger,
                status: v,
                notes: t.notes,
                today: now,
              ),
            );
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'add', child: Text('Add a milestone')),
          for (final e in _statuses.entries)
            if (e.key != t.status) PopupMenuItem(value: e.key, child: Text('Mark ${e.value.toLowerCase()}')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              StatusPill(_statuses[t.status] ?? t.status, status: t.status == 'active' ? Status.good : null),
              StatusPill(worldCountry(t.country)?.name ?? t.country, quiet: true),
            ],
          ),
          if (t.trigger.isNotEmpty) _Line(Icons.bolt, 'Trigger: ${t.trigger}'),
          for (final m in ms)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: m.isDone,
              onChanged: (v) => ref.mutate((s) => s.book.setMilestoneDone(t, m, v ?? false, today: now)),
              title: Text(m.title),
              subtitle: m.due == null
                  ? null
                  : Text(
                      m.isDone
                          ? 'Done ${niceDate(m.done!)}'
                          : 'By ${niceDate(m.due!)} (${relativeDay(m.due!, now)})',
                      style: !m.isDone && m.due!.compareTo(now) < 0
                          ? TextStyle(color: Status.serious.color)
                          : null,
                    ),
              secondary: m.todo != null
                  ? const Tooltip(message: 'On your to-do list', child: Icon(Icons.task_alt))
                  : IconButton(
                      tooltip: 'Make a to-do from "${m.title}"',
                      icon: const Icon(Icons.add_task),
                      onPressed: () => ref.mutate((s) => s.book.milestoneTodo(t, m, today: now)),
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _addMilestone(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController(), due = TextEditingController();
    await showFormDialog(
      context,
      title: 'Add a milestone',
      fields: (_) => [
        Field(title, 'Milestone', autofocus: true),
        Field(due, 'Due (yyyy-mm-dd)', hint: 'Leave empty for no date'),
      ],
      onSave: () async {
        if (title.text.trim().isEmpty) return 'Give the milestone a name.';
        final d = due.text.trim();
        if (d.isNotEmpty && !isDay(d)) return 'Write the date as yyyy-mm-dd.';
        await ref.mutate(
          (s) => s.book.saveMilestone(
            t,
            Milestone(
              id: 'm${DateTime.now().microsecondsSinceEpoch}',
              title: title.text.trim(),
              due: d.isEmpty ? null : d,
            ),
          ),
        );
        return null;
      },
    );
  }
}
