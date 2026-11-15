import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/communities.dart';
import '../domain/lead_finder.dart';
import '../domain/pipeline.dart';
import 'common.dart';

// Network: the people the user already knows at the employers they want,
// searches for people like them, people named in saved adverts, and the
// communities and events worth turning up to. Every search opens in the
// user's own browser; Udyoga never reads the results.

/// The Network tools on a page of their own.
class LeadFinderPage extends StatelessWidget {
  const LeadFinderPage({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(title: 'Network', children: [NetworkTools()]);
}

/// The Network sections, for a page or a tab.
class NetworkTools extends StatelessWidget {
  const NetworkTools({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [KnownAtTargets(), FindPeople(), AdvertLeads(), CommunityDirectory()],
  );
}

// ---- who you already know ----

/// First-degree connections at the employers the user is applying to or
/// has saved jobs at.
class KnownAtTargets extends ConsumerWidget {
  const KnownAtTargets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: 'Who you already know at your target employers',
    hint: 'Your LinkedIn connections at employers you have applied to or saved jobs at.',
    child: AsyncView(
      ref.watch(knownAtTargetsProvider),
      builder: (groups) => groups.isEmpty
          ? const Text(
              'Nobody yet. Save jobs or add applications, then import your LinkedIn data on the Growth page: '
              'your connections at those employers show here.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in groups) ...[Subhead(g.employer), for (final l in g.people) _PersonTile(l)],
              ],
            ),
    ),
  );
}

class _PersonTile extends StatelessWidget {
  const _PersonTile(this.l);
  final Lead l;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: const Icon(Icons.person_outline),
    title: Text(l.name),
    subtitle: l.title.isEmpty ? null : Text(l.title),
    trailing: l.linkedin.isEmpty
        ? null
        : IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open ${l.name} on LinkedIn',
            onPressed: () => openLink(context, l.linkedin),
          ),
  );
}

// ---- similar professionals ----

/// Role, employer and place build search links; the user saves the people
/// they find by pasting their name and link.
class FindPeople extends ConsumerStatefulWidget {
  const FindPeople({super.key});

  @override
  ConsumerState<FindPeople> createState() => _FindPeopleState();
}

class _FindPeopleState extends ConsumerState<FindPeople> {
  final role = TextEditingController();
  final employer = TextEditingController();
  final place = TextEditingController();
  var filled = false;

  @override
  void initState() {
    super.initState();
    for (final c in [role, employer, place]) {
      c.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final c in [role, employer, place]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider).value;
    final employers = ref.watch(targetEmployersProvider).value ?? const <String>[];
    final roles = p?.targets.roles ?? const <String>[];
    if (!filled && p != null) {
      // Prefilled once from the profile; the user's edits stay.
      filled = true;
      role.text = roles.firstOrNull ?? p.currentRole;
      place.text = p.targets.locations.firstOrNull ?? p.location;
    }
    final searches = role.text.trim().isEmpty && employer.text.trim().isEmpty
        ? const <LeadSearch>[]
        : leadSearches(role: role.text, employer: employer.text, place: place.text);
    return SectionCard(
      title: 'Find people in roles like yours',
      hint: 'Each search opens in your browser. Save the people you find here, with where you found them.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Field(role, 'Role'),
          if (roles.length > 1) _Picks(roles, onPick: (r) => role.text = r),
          Field(employer, 'Employer'),
          if (employers.isNotEmpty) _Picks(employers, onPick: (e) => employer.text = e),
          Field(place, 'Place'),
          for (final s in searches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.travel_explore),
              title: Text(s.label),
              subtitle: Text(s.why),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => openUri(context, s.uri),
            ),
          if (searches.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => _save(context, searches),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Save a person you found'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, List<LeadSearch> searches) async {
    final name = TextEditingController();
    final title = TextEditingController();
    final url = TextEditingController();
    var through = searches.first.label;
    var kind = 'peer';
    final saved = await showFormDialog(
      context,
      title: 'Save as lead',
      fields: (setState) => [
        Choice<String>(
          label: 'Found through',
          value: through,
          options: {for (final s in searches) s.label: s.label},
          onChanged: (v) => setState(() => through = v),
        ),
        Field(name, 'Name', autofocus: true),
        Field(title, 'Job title'),
        Field(url, 'Link to their profile or page', hint: 'https://'),
        Choice<String>(
          label: 'Who',
          value: kind,
          options: leadKinds,
          onChanged: (v) => setState(() => kind = v),
        ),
      ],
      onSave: () async {
        if (name.text.trim().isEmpty) return 'Enter a name.';
        final link = url.text.trim();
        if (link.isNotEmpty && !RegExp(r'^https?://').hasMatch(link)) {
          return 'Paste the full link, from https://';
        }
        final s = searches.firstWhere((s) => s.label == through);
        final added = await ref.mutate(
          (x) => x.book.saveFoundLead(
            name: name.text,
            title: title.text,
            company: employer.text,
            kind: kind,
            sourceKind: s.sourceKind,
            source: s.source,
            sourceUrl: link,
            today: today(),
          ),
        );
        return added ? null : 'They are already in your contacts, or marked do not contact.';
      },
    );
    if (saved && context.mounted) showMessage(context, 'Saved ${name.text.trim()} to Contacts.');
  }
}

class _Picks extends StatelessWidget {
  const _Picks(this.items, {required this.onPick});
  final List<String> items;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final i in items.take(8)) ActionChip(label: Text(i), onPressed: () => onPick(i))],
    ),
  );
}

// ---- people named in adverts ----

/// "For informal enquiries contact ..." in the adverts of saved jobs,
/// offered as leads with the advert as their source.
class AdvertLeads extends ConsumerWidget {
  const AdvertLeads({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    final known = {
      for (final l in ref.watch(leadsProvider).value ?? const <Lead>[]) ...[
        l.name.toLowerCase().trim(),
        if (l.email.isNotEmpty) l.email.toLowerCase().trim(),
      ],
    };
    final offers = [
      for (final j in jobs)
        if ((j.status == 'saved' || j.status == 'applied') && j.description.isNotEmpty)
          for (final c in advertContacts(j.description))
            if (!known.contains(c.name.toLowerCase()) && !known.contains(c.email)) (job: j, contact: c),
    ];
    return SectionCard(
      title: 'Named in your saved adverts',
      hint: 'People adverts name for informal enquiries. They expect questions about the job.',
      child: offers.isEmpty
          ? const Text('Nobody new. Save jobs whose adverts name a contact, and they show here.')
          : Column(
              children: [
                for (final o in offers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(o.contact.name.ifEmpty(o.contact.email)),
                    subtitle: Text(
                      [
                        if (o.contact.title.isNotEmpty) o.contact.title,
                        '${o.job.title}${o.job.company.isEmpty ? '' : ' at ${o.job.company}'}',
                        if (o.contact.email.isNotEmpty && o.contact.name.isNotEmpty) o.contact.email,
                        if (o.contact.phone.isNotEmpty) o.contact.phone,
                      ].join(' · '),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final c = o.contact;
                        final added = await ref.mutate(
                          (s) => s.book.saveFoundLead(
                            name: c.name.ifEmpty('Enquiries, ${o.job.title}'),
                            title: c.title,
                            company: o.job.company,
                            email: c.email,
                            phone: c.phone,
                            kind: 'hiring_manager',
                            sourceKind: 'advert',
                            source: 'the advert for ${o.job.title}',
                            sourceUrl: o.job.url,
                            jobId: o.job.id,
                            today: today(),
                          ),
                        );
                        if (context.mounted) {
                          showMessage(context, added ? 'Saved to Contacts.' : 'Already in your contacts.');
                        }
                      },
                      child: const Text('Save as lead'),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ---- communities and events ----

class CommunityDirectory extends ConsumerWidget {
  const CommunityDirectory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: 'Communities and events',
    hint: 'Where people in health administration and digital health meet. Turning up is the warmest way in.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in communities)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.name, style: Theme.of(context).textTheme.titleSmall)),
                    Text(
                      communityKinds[c.kind] ?? c.kind,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Text(c.why),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => openLink(context, c.url),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                    TextButton.icon(
                      onPressed: () => logPeopleMet(context, ref, c),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Log people I met'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Saves someone the user met at [c]: met in person, so they know where
/// the user found them.
Future<void> logPeopleMet(BuildContext context, WidgetRef ref, Community c) async {
  final name = TextEditingController();
  final title = TextEditingController();
  final company = TextEditingController();
  final note = TextEditingController();
  final saved = await showFormDialog(
    context,
    title: 'Someone you met at ${c.name}',
    fields: (setState) => [
      Field(name, 'Name', autofocus: true),
      Field(title, 'Job title'),
      Field(company, 'Organisation'),
      Field(note, 'What you talked about', lines: 3),
    ],
    onSave: () async {
      if (name.text.trim().isEmpty) return 'Enter a name.';
      final added = await ref.mutate(
        (s) => s.book.saveFoundLead(
          name: name.text,
          title: title.text,
          company: company.text,
          sourceKind: 'met',
          source: c.name,
          sourceUrl: c.url,
          note: ['Met at ${c.name}.', note.text.trim()].where((s) => s.isNotEmpty).join(' '),
          today: today(),
        ),
      );
      return added ? null : 'They are already in your contacts, or marked do not contact.';
    },
  );
  if (saved && context.mounted) showMessage(context, 'Saved ${name.text.trim()} to Contacts.');
}
