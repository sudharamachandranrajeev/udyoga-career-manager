import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/communities.dart';
import '../domain/lead_finder.dart';
import '../domain/pipeline.dart';
import 'bluesky_search.dart';
import 'common.dart';
import 'kit/kit.dart';
import 'look.dart';

// Network: the people the user already knows at the employers they want,
// searches for people like them, people named in saved adverts, and the
// communities and events worth turning up to. Every search opens in the
// user's own browser; Udyoga never reads the results.

/// The Network tools on a page of their own.
class LeadFinderPage extends StatelessWidget {
  const LeadFinderPage({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(title: 'Find people', children: [NetworkTools()]);
}

/// The Network sections, for a page or a tab.
class NetworkTools extends StatelessWidget {
  const NetworkTools({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [KnownAtTargets(), FindPeople(), BlueskySearch(), AdvertLeads(), CommunityDirectory()],
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
    hint: 'network.known',
    child: AsyncList(
      ref.watch(knownAtTargetsProvider),
      builder: (groups) => groups.isEmpty
          ? const Text(
              'Nobody yet. Save jobs or add applications, then import your LinkedIn data on the Growth page: '
              'your connections at those employers show here.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            g.employer,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(g.people.length == 1 ? '1 person' : '${g.people.length} people'),
                      ],
                    ),
                  ),
                  for (final l in g.people) _PersonTile(l),
                ],
              ],
            ),
    ),
  );
}

class _PersonTile extends StatelessWidget {
  const _PersonTile(this.l);
  final Lead l;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          OrgLogo(l.name, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (l.title.isNotEmpty)
                  Text(
                    l.title,
                    style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (l.linkedin.isNotEmpty) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Open ${l.name} on LinkedIn',
              child: ChannelChip('linkedin', onPressed: () => openLink(context, l.linkedin)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tiles as spotlight cards in columns on a wide screen; on a phone, a flat
/// list, since they already sit inside a card.
class _Tiles extends StatelessWidget {
  const _Tiles(this.children);
  final List<Widget> children;
  static const minWidth = 400.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth >= 2 * minWidth
        ? StatGrid(
            minWidth: minWidth,
            children: [for (final c in children) SpotlightCard(padding: EdgeInsets.zero, child: c)],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, c) in children.indexed) ...[if (i > 0) const Divider(height: 1), c],
            ],
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
      hint: 'network.search',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Field(role, 'Role'),
          if (roles.length > 1) _Picks(roles, onPick: (r) => role.text = r),
          Field(employer, 'Employer'),
          if (employers.isNotEmpty) _Picks(employers, onPick: (e) => employer.text = e),
          Field(place, 'Place'),
          if (searches.isNotEmpty) _Tiles([for (final s in searches) _SearchTile(s)]),
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

/// One search: what it looks in, why, and that it opens in the browser.
class _SearchTile extends StatelessWidget {
  const _SearchTile(this.s);
  final LeadSearch s;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => openUri(context, s.uri),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.travel_explore, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      s.why,
                      style: t.bodySmall?.copyWith(color: muted),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
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
      children: [
        for (final i in items.take(8))
          ActionChip(
            // A long employer name stays on one line inside the chip.
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(i, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            onPressed: () => onPick(i),
          ),
      ],
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
      hint: 'network.adverts',
      child: offers.isEmpty
          ? const Text('Nobody new. Save jobs whose adverts name a contact, and they show here.')
          : _Tiles([
              for (final o in offers)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          OrgLogo(o.contact.name.ifEmpty(o.job.company), size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              o.contact.name.ifEmpty(o.contact.email),
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (o.contact.title.isNotEmpty) o.contact.title,
                          '${o.job.title}${o.job.company.isEmpty ? '' : ' at ${o.job.company}'}',
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (o.contact.email.isNotEmpty && o.contact.name.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: ChannelChip('email', account: o.contact.email),
                            ),
                          if (o.contact.phone.isNotEmpty) ChannelChip('phone', account: o.contact.phone),
                          const StatusPill('Job advert', icon: Icons.place_outlined, quiet: true),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
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
                              showMessage(
                                context,
                                added ? 'Saved to Contacts.' : 'Already in your contacts.',
                              );
                            }
                          },
                          child: const Text('Save as lead'),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
    );
  }
}

// ---- communities and events ----

class CommunityDirectory extends ConsumerWidget {
  const CommunityDirectory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: 'Communities and events',
    hint: 'network.communities',
    child: _Tiles([
      for (final c in communities)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              StatusPill(
                [communityKinds[c.kind] ?? c.kind, if (c.region.isNotEmpty) c.region].join(' · '),
                icon: _communityIcons[c.kind],
              ),
              const SizedBox(height: 6),
              Text(
                c.why,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
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
    ]),
  );
}

const _communityIcons = {
  'community': Icons.groups_outlined,
  'event': Icons.event_outlined,
  'body': Icons.account_balance_outlined,
};

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
