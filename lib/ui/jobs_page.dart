import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/ai.dart';
import '../domain/countries.dart';
import '../domain/feeds.dart';
import '../domain/json.dart';
import '../domain/listing_check.dart';
import '../domain/pipeline.dart';
import '../domain/profile.dart';
import '../domain/saved_searches.dart';
import 'common.dart';
import 'eligibility_view.dart';
import 'employers_page.dart';
import 'job_page.dart';
import 'kit/kit.dart';
import 'look.dart';
import 'role_search_view.dart';
import 'saved_searches_view.dart';
import 'site_page.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  var status = 'new';
  var byFit = true;
  final search = TextEditingController();

  /// The search box asks the job sites for a role, rather than filtering
  /// the jobs already saved.
  var siteSearch = false;

  /// The role search, so a saved search can be run in it.
  final _roleSearch = GlobalKey<RoleSearchViewState>();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refresh = ref.watch(refreshProvider);
    final hasAi = ref.watch(advisorProvider).value != null;
    return PageScaffold(
      title: 'Jobs',
      banner: 'page.jobs',
      actions: [
        HintIconButton(
          'jobs.portals',
          icon: Icons.travel_explore,
          label: 'Search job sites',
          onPressed: () => showPortals(context, ref),
        ),
        HintIconButton(
          'jobs.employers',
          icon: Icons.apartment_outlined,
          label: 'Employers you watch',
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmployersPage())),
        ),
        HintIconButton(
          'jobs.ai',
          icon: Icons.auto_awesome,
          label: 'AI job search',
          onPressed: refresh.running ? null : () => _run(ai: true, hasAi: hasAi),
        ),
        HintIconButton(
          'jobs.refresh',
          icon: Icons.refresh,
          label: 'Refresh',
          onPressed: refresh.running ? null : () => _run(),
        ),
      ],
      fab: Hint(
        'jobs.add',
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => addJob(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add job'),
        ),
      ),
      children: [
        if (refresh.running)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Expanded(child: Text(refresh.status)),
              ],
            ),
          )
        else if (refresh.last != null || refresh.status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StatusLabel(
              refresh.last?.problems.isEmpty ?? false ? Status.good : Status.warning,
              refresh.last?.summary ?? refresh.status,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Filter my jobs')),
              ButtonSegment(value: true, label: Text('Search job sites')),
            ],
            selected: {siteSearch},
            onSelectionChanged: (s) => setState(() => siteSearch = s.first),
          ),
        ),
        SavedSearchesRow(onOpen: _openSearch),
        const SizedBox(height: 12),
        // Kept while hidden, so switching back and forth keeps the search.
        Offstage(
          offstage: !siteSearch,
          child: RoleSearchView(key: _roleSearch),
        ),
        if (!siteSearch) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final e in jobStatuses.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: status == e.key,
                  onSelected: (_) => setState(() => status = e.key),
                ),
              const SizedBox(width: 8),
              Hint(
                'jobs.fit',
                child: FilterChip(
                  label: const Text('Best fit first'),
                  selected: byFit,
                  onSelected: (v) => setState(() => byFit = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filter by title, employer or place',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AsyncList(
            ref.watch(jobsProvider),
            builder: (everything) {
              final q = search.text.trim().toLowerCase();
              // The user's exclusions are a hard rule: those jobs never show.
              final all = notExcluded(everything, ref.watch(profileProvider).value);
              final hidden =
                  everything.where((j) => j.status == status).length -
                  all.where((j) => j.status == status).length;
              final jobs = all
                  .where((j) => j.status == status)
                  .where(
                    (j) => q.isEmpty || '${j.title} ${j.company} ${j.location}'.toLowerCase().contains(q),
                  )
                  .toList();
              if (byFit) jobs.sort((a, b) => (b.fit ?? -1).compareTo(a.fit ?? -1));
              if (jobs.isEmpty) {
                // One next step that fits the list on show.
                if (q.isNotEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No jobs match "${search.text.trim()}"',
                    actions: [
                      TextButton(
                        onPressed: () => setState(search.clear),
                        child: const Text('Clear the filter'),
                      ),
                    ],
                  );
                }
                return EmptyState(
                  icon: Icons.work_outline,
                  title: status == 'new' ? 'No new jobs' : 'No ${jobStatuses[status]?.toLowerCase()} jobs',
                  message: status == 'new'
                      ? 'Udyoga checks the job sites for your target roles every few hours.'
                      : 'Jobs you mark ${jobStatuses[status]?.toLowerCase()} show here.',
                  actions: [
                    if (status == 'new')
                      FilledButton.icon(
                        onPressed: refresh.running ? null : () => _run(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check the job sites now'),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() => status = 'new'),
                        child: const Text('See new jobs'),
                      ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final j in jobs) JobTile(j), if (hidden > 0) _HiddenNote(hidden)],
              );
            },
          ),
        ],
      ],
    );
  }

  /// Runs saved search [s] in "Search job sites".
  void _openSearch(SavedSearch s) {
    setState(() => siteSearch = true);
    _roleSearch.currentState?.open(s);
  }

  Future<void> _run({bool ai = false, bool hasAi = true}) async {
    if (ai && !hasAi) {
      return showMessage(context, needsAiKey);
    }
    try {
      final r = await ref.read(refreshProvider.notifier).run(force: true, ai: ai);
      if (r != null && mounted) showMessage(context, r.summary);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}

class JobTile extends StatelessWidget {
  const JobTile(this.job, {super.key, this.list = 'jobs'});
  final Job job;

  /// Which list the tile is in; it keeps the logo's hero tag unique when
  /// the same job shows on two pages at once.
  final String list;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final tag = 'logo-$list-${j.id}';
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final now = today();
    final pay = shortSalary(j);
    final closingSoon =
        j.closing != null && j.closing!.compareTo(addDays(now, 7)) <= 0 && j.closing!.compareTo(now) >= 0;
    final check = checkListing(j, today: now);
    final closes = j.closing;
    final closed = closes != null && closes.compareTo(now) < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tilt(
        child: SpotlightCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobPage(j.id, heroTag: tag))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(tag: tag, child: OrgLogo(j.company.ifEmpty(j.title))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                j.title,
                                style: t.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [j.company, j.location].where((s) => s.isNotEmpty).join(' · '),
                                style: t.bodyMedium?.copyWith(color: muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Hint('jobs.fit', child: FitBadge(j.fit, ai: j.assessment.isNotEmpty)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (j.remote) const StatusPill('Remote', icon: Icons.public),
                        if (j.country.isNotEmpty) StatusPill(Country.nameOf(j.country)),
                        if (SourceCredit.needed(j.source))
                          SourceCredit(j.source)
                        else
                          StatusPill('via ${sourceName(j.source)}'),
                        EligibilityPill(j),
                        SponsorBadge(j.company, country: j.country, short: true),
                        if (check.official)
                          const StatusPill(
                            'Official site',
                            status: Status.good,
                            icon: Icons.verified_outlined,
                          ),
                        if (check.problems.isNotEmpty)
                          const StatusPill('Closed', status: Status.serious, icon: Icons.event_busy)
                        else if (check.cautions.isNotEmpty)
                          const StatusPill(
                            'Check it first',
                            status: Status.warning,
                            icon: Icons.warning_amber_rounded,
                          ),
                        if (j.status == 'applied')
                          const StatusPill('Applied', status: Status.good, icon: Icons.send),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Pay, the closing date and when it was found: what to weigh
                    // before opening it.
                    // On a narrow card the closing date drops below the pay
                    // rather than cutting either short.
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          pay.isEmpty ? 'Pay not given' : pay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pay.isEmpty
                              ? t.bodyMedium?.copyWith(color: muted)
                              : t.titleMedium?.copyWith(fontFamily: headingFont, fontWeight: FontWeight.w800),
                        ),
                        if (closes == null || closed)
                          Text(
                            'Found ${relativeDay(j.found, now)}',
                            style: t.bodySmall?.copyWith(color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Tooltip(
                            message: 'Closes ${niceDate(closes)}',
                            child: StatusPill(
                              'Closes ${relativeDay(closes, now)}',
                              status: closingSoon ? Status.serious : null,
                              icon: Icons.event_outlined,
                            ),
                          ),
                      ],
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

/// How many jobs the user's exclusions keep off the list.
class _HiddenNote extends StatelessWidget {
  const _HiddenNote(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      '$count ${count == 1 ? 'job' : 'jobs'} hidden by your exclusions (Profile, Targets).',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// Pay in a few characters ("£32k–38k"), else the advert's own short wording.
String shortSalary(Job j) =>
    shortPay(currency: j.currency, min: j.salaryMin, max: j.salaryMax, text: j.salaryText);

/// [shortSalary] from the parts, for an advert not saved yet.
String shortPay({required String currency, int? min, int? max, String text = ''}) {
  // 1.3m, 45k, 38.5k: short enough for a card at any size of pay.
  String k(int v) => switch (v) {
    >= 1000000 => '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}m',
    >= 1000 => '${(v / 1000).toStringAsFixed(v % 1000 == 0 || v >= 100000 ? 0 : 1)}k',
    _ => '$v',
  };
  final sym = switch (currency.toUpperCase()) {
    'GBP' => '£',
    'EUR' => '€',
    'USD' || 'CAD' || 'AUD' => r'$',
    'INR' => '₹',
    '' => '',
    final c => '$c ',
  };
  if (max != null || min != null) {
    final lo = min ?? max!, hi = max ?? min!;
    return lo == hi ? '$sym${k(lo)}' : '$sym${k(lo)}–${k(hi)}';
  }
  return text.length <= 24 ? text : '';
}

String sourceName(String source) => switch (source) {
  'adzuna' => 'Adzuna',
  'reed' => 'Reed',
  'nhs' => 'NHS Jobs',
  'remotive' => 'Remotive',
  'jobicy' => 'Jobicy',
  'arbeitnow' => 'Arbeitnow',
  'jobtech' => 'Platsbanken',
  'nav' => 'arbeidsplassen.no',
  'usajobs' => 'USAJOBS',
  'jooble' => 'Jooble',
  'unvacancies' => 'unvacancies.org',
  'greenhouse' => 'Greenhouse',
  'lever' => 'Lever',
  'ashby' => 'Ashby',
  'smartrecruiters' => 'SmartRecruiters',
  'workday' => 'Workday',
  'careers' => 'the careers page',
  'page' => 'a page you read',
  'recipe' => 'a site recipe',
  'ai' => 'AI search',
  _ => 'you',
};

/// Searches for the profile's roles on every job site for each target
/// country, opened in the browser.
Future<void> showPortals(BuildContext context, WidgetRef ref) async {
  final p = await ref.read(profileProvider.future);
  if (!context.mounted) return;
  final terms = p.searchTerms;
  if (terms.isEmpty) {
    return showMessage(context, 'Add your current role or target roles to your profile first.');
  }
  var term = terms.first;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Search job sites', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in terms)
                  ChoiceChip(
                    label: Text(t),
                    selected: t == term,
                    onSelected: (_) => setState(() => term = t),
                  ),
              ],
            ),
            for (final c in p.searchCountries.isEmpty ? [''] : p.searchCountries) ...[
              Subhead(c.isEmpty ? 'Anywhere' : Country.nameOf(c)),
              for (final portal in portalsFor(c))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.open_in_new, size: 18),
                  title: Text(portal.name),
                  subtitle: portal.note.isEmpty ? null : Text(portal.note),
                  onTap: () =>
                      openSite(context, url: '${portal.link(term, _place(p, c))}', title: portal.name),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

String _place(CandidateProfile p, String country) {
  if (country == p.country && p.targets.locations.isNotEmpty) return p.targets.locations.first;
  return Country.nameOf(country);
}

/// A job from its advert: read by the AI when one is set up (null when it
/// finds no advert there), otherwise from what the user typed or the page
/// title.
Future<Posting?> readPosting(
  WidgetRef ref, {
  required String url,
  required String text,
  String title = '',
  String company = '',
  String location = '',
}) async {
  final p = await ref.read(profileProvider.future);
  final sourceId = url.isNotEmpty ? url : newId();
  if (await ref.read(advisorProvider.future) != null && (url.isNotEmpty || text.isNotEmpty)) {
    final advisor = await requireAdvisor(ref);
    final a = await advisor.readAdvert(url: url, text: text);
    if (str(a['title']).isEmpty) return null;
    final (low, high) = salaryIn(str(a['salaryText']).isNotEmpty ? str(a['salaryText']) : text);
    return Posting(
      source: 'manual',
      sourceId: sourceId,
      title: str(a['title']),
      company: str(a['company']),
      location: str(a['location']),
      country: str(a['country']).toUpperCase(),
      remote: a['remote'] == true,
      salaryText: str(a['salaryText']),
      salaryMin: low,
      salaryMax: high,
      currency: low == null ? '' : 'GBP',
      url: url,
      description: str(a['description']).isNotEmpty ? str(a['description']) : text,
      posted: str(a['posted']).length == 10 ? str(a['posted']) : null,
      // The page's own words when the AI missed the date.
      closing: str(a['closing']).length == 10 ? str(a['closing']) : closingIn(text),
    );
  }
  final (low, high) = salaryIn(text);
  return Posting(
    source: 'manual',
    sourceId: sourceId,
    title: title,
    company: company,
    location: location,
    country: p.country,
    salaryMin: low,
    salaryMax: high,
    currency: low == null ? '' : 'GBP',
    url: url,
    description: text,
    closing: closingIn(text),
  );
}

/// Saves [posting] to the user's jobs. Returns its id, or null when it is
/// already on the list.
Future<String?> saveAdvert(WidgetRef ref, Posting posting) async {
  final p = await ref.read(profileProvider.future);
  final added = await ref.mutate((s) => s.book.importPostings([posting], p, today: today()));
  final id = added.firstOrNull;
  if (id != null) await ref.mutate((s) => s.book.setJobStatus(id, 'saved'));
  return id;
}

/// Adds a job from its link or advert text (read by the AI), or typed in.
Future<void> addJob(BuildContext context, WidgetRef ref) async {
  final url = TextEditingController();
  final advert = TextEditingController();
  final title = TextEditingController();
  final company = TextEditingController();
  final location = TextEditingController();
  final hasAi = await ref.read(advisorProvider.future) != null;
  if (!context.mounted) return;
  String? id;
  final ok = await showFormDialog(
    context,
    title: 'Add a job',
    action: 'Add',
    width: 600,
    fields: (_) => [
      Field(url, 'Link to the advert', hint: 'https://…', autofocus: true),
      Field(
        advert,
        'Advert text',
        lines: 4,
        helper: hasAi
            ? 'Paste the advert, or leave it empty and the AI reads the link.'
            : 'Paste the job description, responsibilities and person specification.',
      ),
      if (!hasAi) ...[Field(title, 'Job title'), Field(company, 'Employer'), Field(location, 'Location')],
    ],
    onSave: () async {
      final link = url.text.trim();
      final text = advert.text.trim();
      if (link.isNotEmpty && !(Uri.tryParse(link)?.hasScheme ?? false)) {
        return 'The link starts with https://';
      }
      if (!hasAi && title.text.trim().isEmpty) return 'Enter the job title.';
      final posting = await readPosting(
        ref,
        url: link,
        text: text,
        title: title.text.trim(),
        company: company.text.trim(),
        location: location.text.trim(),
      );
      if (posting == null) return 'The AI could not read a job advert there. Paste the text instead.';
      id = await saveAdvert(ref, posting);
      return id == null ? 'That job is already on your list.' : null;
    },
  );
  if (ok && id != null && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobPage(id!)));
  }
}
