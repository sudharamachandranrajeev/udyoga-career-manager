import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/ats.dart';
import '../domain/discovery.dart';
import '../domain/employers.dart';
import '../domain/feeds.dart';
import '../domain/profile.dart';
import 'common.dart';
import 'job_page.dart';

/// The employers the user watches: where each one's jobs come from, its
/// new openings, and a helper that suggests employers near home.
class EmployersPage extends ConsumerWidget {
  const EmployersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchedEmployersProvider).value ?? const <WatchedEmployer>[];
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    return PageScaffold(
      title: 'Employers you watch',
      actions: [
        IconButton(
          tooltip: 'Find employers near you',
          icon: const Icon(Icons.travel_explore),
          onPressed: () => showDiscovery(context, ref),
        ),
      ],
      fab: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => editEmployer(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Watch an employer'),
      ),
      children: [
        if (watched.isEmpty)
          const EmptyState(
            icon: Icons.apartment_outlined,
            title: 'No employers yet',
            message:
                'Add the employers you would like to work for. NHS employers are matched on NHS Jobs; others '
                'are read from their job board or careers page. Their new openings show on Today. The career '
                'file\'s watchEmployers list adds them too.',
          ),
        for (final e in watched)
          SectionCard(
            title: e.name,
            trailing: TextButton(onPressed: () => editEmployer(context, ref, e), child: const Text('Edit')),
            child: _EmployerView(
              e,
              jobs: [
                for (final j in jobs)
                  if (!j.deleted && e.matches(j.company)) j,
              ],
            ),
          ),
      ],
    );
  }
}

/// Where an employer's jobs come from, in words.
List<String> sourceLines(WatchedEmployer e) => [
  if (e.nhs) 'NHS Jobs, by name${e.aliases.isEmpty ? '' : ' and ${e.aliases.length} other names'}',
  for (final u in e.urls)
    switch (atsFromUrl(u)) {
      final b? => '${b.kind.label} board "${b.token}"',
      null => 'Careers page ${Uri.parse(u).host} (its job board, or its job markup, read once a day)',
    },
];

class _EmployerView extends StatelessWidget {
  const _EmployerView(this.e, {required this.jobs});
  final WatchedEmployer e;
  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final sources = sourceLines(e);
    final open = jobs.where((j) => j.status != 'dismissed').toList()
      ..sort((a, b) => b.found.compareTo(a.found));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e.why.isNotEmpty) Text(e.why),
        Text(
          sources.isEmpty
              ? 'Matched by name in every job feed. Add "nhs" or a careers link to check it directly.'
              : 'Checked on: ${sources.join('; ')}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (e.keywords.isNotEmpty)
          Text('Jobs that say: ${e.keywords.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        if (open.isEmpty)
          const Text('No openings saved yet.')
        else
          for (final j in open.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(j.status == 'new' ? Icons.fiber_new_outlined : Icons.work_outline),
              title: Text(j.title),
              subtitle: Text(
                [j.location, 'found ${niceDate(j.found)}'].where((t) => t.isNotEmpty).join(' · '),
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobPage(j.id))),
            ),
      ],
    );
  }
}

/// Adds ([e] null) or edits a watched employer.
Future<void> editEmployer(BuildContext context, WidgetRef ref, WatchedEmployer? e) {
  final name = TextEditingController(text: e?.name ?? '');
  final aliases = TextEditingController(text: e?.aliases.join('\n') ?? '');
  final why = TextEditingController(text: e?.why ?? '');
  final sources = TextEditingController(text: e?.sources.join('\n') ?? '');
  final keywords = TextEditingController(text: e?.keywords.join('\n') ?? '');
  return showFormDialog(
    context,
    title: e == null ? 'Watch an employer' : e.name,
    fields: (_) => [
      Field(name, 'Name', hint: 'Example Health Trust', autofocus: e == null),
      Field(aliases, 'Other names its adverts use', lines: 2, helper: 'One per line'),
      Field(why, 'Why you are watching it', lines: 2),
      Field(
        sources,
        'Where its jobs are',
        lines: 3,
        helper:
            'One per line: "nhs" for NHS Jobs, or a link to its careers page or job board (Greenhouse, Lever, '
            'Ashby, SmartRecruiters, Workday).',
      ),
      Field(keywords, 'Only jobs that say', lines: 2, helper: 'One per line. Empty: your search terms.'),
      if (e != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Stop watching ${e.name}?',
                message: 'Its saved jobs stay on the Jobs page.',
                action: 'Stop watching',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await ref.mutate((s) => s.book.removeWatchedEmployer(e.id));
              if (context.mounted) Navigator.of(context).pop(false);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Stop watching'),
          ),
        ),
    ],
    onSave: () async {
      final n = name.text.trim();
      if (n.isEmpty) return 'Give the employer a name.';
      final id = e?.id ?? employerId(n);
      if (id.isEmpty) return 'Give the employer a name with letters or digits.';
      await ref.mutate(
        (s) => s.book.saveWatchedEmployer(
          WatchedEmployer(
            id: id,
            name: n,
            aliases: linesIn(aliases),
            why: why.text.trim(),
            sources: linesIn(sources),
            keywords: linesIn(keywords),
            seed: e?.seed ?? '',
          ),
        ),
      );
      return null;
    },
  );
}

enum _Finder {
  nhs('NHS trusts'),
  hospitals('Hospitals near you'),
  epic('Epic customers'),
  oracle('Oracle Health customers');

  const _Finder(this.label);
  final String label;
}

/// Suggests employers from public lists, near the profile's home areas.
Future<void> showDiscovery(BuildContext context, WidgetRef ref) => showDialog<void>(
  context: context,
  builder: (_) => const Dialog(child: _Discovery()),
);

class _Discovery extends ConsumerStatefulWidget {
  const _Discovery();

  @override
  ConsumerState<_Discovery> createState() => _DiscoveryState();
}

class _DiscoveryState extends ConsumerState<_Discovery> {
  var _finder = _Finder.nhs;
  var _busy = false;
  String? _error;
  List<EmployerSuggestion>? _found;

  Future<void> _find(CandidateProfile p) async {
    setState(() {
      _busy = true;
      _error = null;
      _found = null;
    });
    final d = EmployerDiscovery(ref.read(httpClientProvider));
    final areas = p.targets.homeAreas;
    final towns = [for (final a in areas) ...a.towns];
    try {
      final found = switch (_finder) {
        _Finder.nhs => await d.nhsTrusts(towns),
        _Finder.hospitals => await d.hospitalsNear(areas, homeCountry: p.country),
        _Finder.epic => await d.epicCustomers(country: p.country, towns: towns),
        _Finder.oracle => await d.oracleCustomers(country: p.country, towns: towns),
      };
      if (mounted) setState(() => _found = found);
    } on Object catch (e) {
      if (mounted) setState(() => _error = feedProblem(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider).value ?? const CandidateProfile();
    final watched = {
      for (final e in ref.watch(watchedEmployersProvider).value ?? const <WatchedEmployer>[]) e.id,
    };
    final areas = p.targets.homeAreas;
    final found = _found;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Find employers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              areas.isEmpty
                  ? 'Add home areas to your profile to narrow these to places near you.'
                  : 'Near ${areas.map((a) => a.place).join(', ')}.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in _Finder.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _finder == f,
                    onSelected: _busy ? null : (_) => setState(() => _finder = f),
                  ),
              ],
            ),
            if (_finder == _Finder.epic || _finder == _Finder.oracle)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _finder == _Finder.epic
                          ? "Epic's public list of organisations on Epic, fetched now and not kept. "
                          : "Oracle's public list of organisations on Oracle Health, fetched now and not kept. ",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => openLink(
                        context,
                        _finder == _Finder.epic ? CustomerLists.epicTerms : CustomerLists.oracleHome,
                      ),
                      child: Text(_finder == _Finder.epic ? "Epic's terms" : 'Source'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : () => _find(p),
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(_busy ? 'Looking…' : 'Look'),
            ),
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text('Could not look: $_error.')),
            if (found != null && found.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('None found near your home areas.'),
              ),
            if (found != null && found.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in found)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
                        subtitle: Text(
                          [s.place, s.website, s.source].where((t) => t.isNotEmpty).join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: watched.contains(employerId(s.name))
                            ? const Icon(Icons.check)
                            : TextButton(
                                onPressed: () => ref.mutate((x) => x.book.saveWatchedEmployer(s.toWatched())),
                                child: const Text('Watch'),
                              ),
                      ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ),
          ],
        ),
      ),
    );
  }
}
