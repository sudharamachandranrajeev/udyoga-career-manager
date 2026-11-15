import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/countries.dart';
import '../domain/insights.dart';
import '../domain/json.dart';
import '../domain/pipeline.dart';
import 'applications_page.dart';
import '../domain/conversations.dart';
import 'common.dart';
import 'conversations_page.dart';
import 'linkedin_page.dart';
import 'look.dart';

const _kindIcons = {
  'recruiter': Icons.support_agent,
  'hiring_manager': Icons.manage_accounts_outlined,
  'referral': Icons.handshake_outlined,
  'peer': Icons.people_outline,
  'mentor': Icons.psychology_outlined,
  'other': Icons.person_outline,
};

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  var filter = 'due';

  @override
  Widget build(BuildContext context) {
    final hasAi = ref.watch(advisorProvider).value != null;
    final p = ref.watch(profileProvider).value;
    final field = p?.searchTerms.firstOrNull ?? '';
    final place = p == null
        ? ''
        : p.targets.locations.firstOrNull ?? p.location.ifEmpty(Country.nameOf(p.country));
    return PageScaffold(
      title: 'Contacts',
      banner: 'page.contacts',
      actions: [
        IconButton(
          icon: const Icon(Icons.forum_outlined),
          tooltip: 'Conversations',
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ConversationsPage())),
        ),
        if (field.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Recruiters on LinkedIn',
            onPressed: () => openUri(context, linkedInPeople('recruiter $field $place'.trim())),
          ),
        if (hasAi)
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Find contacts with AI',
            onPressed: () => _find(context),
          ),
      ],
      fab: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => editLead(context, ref, null),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add contact'),
      ),
      children: [
        const MergeSuggestions(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in {'due': 'To follow up', 'all': 'All', ...leadStatuses}.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: filter == e.key,
                onSelected: (_) => setState(() => filter = e.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncView(
          ref.watch(leadsProvider),
          builder: (all) {
            final now = today();
            final list = switch (filter) {
              'all' => all,
              'due' =>
                all
                    .where((l) => l.followUp != null && l.followUp!.compareTo(now) <= 0 && l.status != 'cold')
                    .toList(),
              _ => all.where((l) => l.status == filter).toList(),
            };
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.contacts_outlined,
                title: filter == 'due' ? 'Nobody to follow up today' : 'No contacts here',
                message: hasAi
                    ? 'Find recruiters, hiring managers and agencies with the AI, from a job, or add people you know.'
                    : 'Add recruiters, hiring managers and people who could refer you.',
              );
            }
            return Column(children: [for (final l in list) LeadTile(l)]);
          },
        ),
      ],
    );
  }

  Future<void> _find(BuildContext context) async {
    final company = TextEditingController();
    final go = await showFormDialog(
      context,
      title: 'Find contacts',
      action: 'Search',
      fields: (_) => [
        Field(
          company,
          'Employer (optional)',
          autofocus: true,
          helper: 'Leave empty to find recruiters and agencies for your field and area.',
        ),
        const Text(
          'The AI searches public professional pages only: adverts, team pages, agency sites and public '
          'LinkedIn profiles. It never guesses private details.',
        ),
      ],
      onSave: () async => null,
    );
    if (!go || !context.mounted) return;
    final p = await ref.read(profileProvider.future);
    if (!context.mounted) return;
    final r = await runAi(
      context,
      title: 'Finding contacts',
      task: (progress) async =>
          (await requireAdvisor(ref)).findLeads(p, company: company.text.trim(), onProgress: progress),
    );
    if (r == null) return;
    final n = await ref.mutate(
      (s) => s.book.importLeads(objs(r.data['leads']).map(LeadSuggestion.new).toList(), today: today()),
    );
    if (context.mounted) showMessage(context, n == 0 ? 'No new contacts found.' : 'Added $n contacts.');
  }
}

class LeadTile extends ConsumerWidget {
  const LeadTile(this.lead, {super.key});
  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = lead;
    final now = today();
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tilt(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _actions(context, ref, l),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  OrgLogo(l.name.ifEmpty(l.company), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name, style: t.titleMedium),
                        Text(
                          [l.title, l.company].where((s) => s.isNotEmpty).join(' · '),
                          style: t.bodyMedium?.copyWith(color: muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Pill(leadKinds[l.kind] ?? l.kind, icon: _kindIcons[l.kind]),
                            if (l.doNotContact)
                              const Pill('Do not contact', status: Status.serious, icon: Icons.block),
                            if (l.sourceKind != 'other') Pill(sourceKinds[l.sourceKind] ?? l.sourceKind),
                            if (l.followUp != null && l.status != 'cold')
                              Pill(
                                '${leadStatuses[l.status] ?? l.status} · follow up ${relativeDay(l.followUp!, now)}',
                                status: followUpStatus(l.followUp!, now),
                              )
                            else
                              Pill(leadStatuses[l.status] ?? l.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _actions(BuildContext context, WidgetRef ref, Lead l) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.name, style: Theme.of(sheet).textTheme.titleLarge),
            Text([l.title, l.company].where((s) => s.isNotEmpty).join(', ')),
            if (l.notes.isNotEmpty) ...[const SizedBox(height: 8), SelectableText(l.notes)],
            const SizedBox(height: 4),
            if (foundOnText(l).isNotEmpty || l.sourceUrl.isNotEmpty)
              InkWell(
                onTap: l.sourceUrl.isNotEmpty || l.source.startsWith('http')
                    ? () => openLink(context, l.sourceUrl.ifEmpty(l.source))
                    : null,
                child: Text(
                  'Found on ${foundOnText(l).ifEmpty(l.sourceUrl)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Text('Where you found them is not recorded. Add it with Edit.'),
            Text(
              'Basis: ${[lawfulBases[l.basis] ?? l.basis, l.basisNote].where((s) => s.isNotEmpty).join(': ')}',
            ),
            if (l.email.isNotEmpty && emailKind(l.email) == 'personal')
              const Text('Personal e-mail address: PECR consent rules apply to marketing-style e-mail.'),
            if (l.lastContact != null) Text('Last contact ${niceDate(l.lastContact!)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!l.doNotContact)
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheet);
                      await openConversationWith(context, ref, l);
                    },
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Conversation'),
                  ),
                if (l.linkedin.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openLink(context, l.linkedin),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('LinkedIn'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => openUri(context, linkedInPeople('${l.name} ${l.company}'.trim())),
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Find on LinkedIn'),
                  ),
                if (l.email.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openUri(context, Uri(scheme: 'mailto', path: l.email)),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('E-mail'),
                  ),
                if (l.phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openUri(context, Uri(scheme: 'tel', path: l.phone)),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                if (ref.read(advisorProvider).value != null)
                  OutlinedButton.icon(
                    onPressed: () => _draft(context, ref, l),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Draft a message'),
                  ),
                if (ref.read(advisorProvider).value != null)
                  OutlinedButton.icon(
                    onPressed: () => _linkedInNote(context, ref, l),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('LinkedIn note'),
                  ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await ref.mutate((s) => s.book.contacted(l, today: today()));
                    if (sheet.mounted) Navigator.pop(sheet);
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('Contacted today'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await ref.mutate(
                      (s) => s.book.save(
                        s.db.careerContacts,
                        l.copyWith(status: 'replied', followUp: const Value(null)),
                        l.id,
                      ),
                    );
                    if (sheet.mounted) Navigator.pop(sheet);
                  },
                  child: const Text('They replied'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await ref.mutate(
                      (s) => s.book.save(
                        s.db.careerContacts,
                        l.copyWith(status: 'cold', followUp: const Value(null)),
                        l.id,
                      ),
                    );
                    if (sheet.mounted) Navigator.pop(sheet);
                  },
                  child: const Text('Gone cold'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    editLead(context, ref, l);
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
            const Divider(height: 24),
            ComplianceActions(l, onForgotten: () => Navigator.pop(sheet)),
          ],
        ),
      ),
    ),
  );

  Future<void> _linkedInNote(BuildContext context, WidgetRef ref, Lead l) async {
    final job = l.jobId == null
        ? null
        : (await ref.read(jobsProvider.future)).where((j) => j.id == l.jobId).firstOrNull;
    if (context.mounted) await linkedInNoteFor(context, ref, l, job: job);
  }

  Future<void> _draft(BuildContext context, WidgetRef ref, Lead l) async {
    final p = await ref.read(profileProvider.future);
    final job = l.jobId == null
        ? null
        : (await ref.read(jobsProvider.future)).where((j) => j.id == l.jobId).firstOrNull;
    if (!context.mounted) return;
    final d = await runAi(
      context,
      title: 'Drafting',
      task: (_) async => (await requireAdvisor(ref)).draft(
        p,
        purpose: l.status == 'new'
            ? 'a first message (short enough for a LinkedIn connection note, under 300 characters, unless e-mail '
                  'is the channel) introducing the candidate and asking a specific, easy question'
            : 'a brief, friendly follow-up to an earlier message, adding something useful',
        context: [
          'To: ${l.name}, ${l.title} at ${l.company} (${leadKinds[l.kind] ?? l.kind})',
          if (l.email.isNotEmpty) 'Channel: e-mail' else 'Channel: LinkedIn',
          if (l.notes.isNotEmpty) 'Notes: ${l.notes}',
          if (l.lastContact != null) 'Last contact: ${l.lastContact}',
          if (job != null) 'About the job: ${job.title} at ${job.company}, ${job.url}',
        ].join('\n'),
      ),
    );
    if (d == null || !context.mounted) return;
    await showDraft(context, d.subject, d.message);
  }
}

Future<void> editLead(BuildContext context, WidgetRef ref, Lead? l) async {
  final name = TextEditingController(text: l?.name);
  final title = TextEditingController(text: l?.title);
  final company = TextEditingController(text: l?.company);
  final email = TextEditingController(text: l?.email);
  final phone = TextEditingController(text: l?.phone);
  final linkedin = TextEditingController(text: l?.linkedin);
  final notes = TextEditingController(text: l?.notes);
  final source = TextEditingController(text: l?.source);
  final sourceUrl = TextEditingController(text: l?.sourceUrl);
  final basisNote = TextEditingController(text: l?.basisNote);
  var sourceKind = l?.sourceKind ?? 'other';
  var foundOn = l?.foundOn ?? today();
  // An older contact with no date keeps none unless the user picks one.
  var foundOnPicked = l == null || l.foundOn != null;
  var basis = l?.basis ?? 'legitimate_interest';
  var keepInTouch = l?.keepInTouchWeeks ?? 0;
  var kind = l?.kind ?? 'recruiter';
  var status = l?.status ?? 'new';
  var followUp = l?.followUp ?? today();
  await showFormDialog(
    context,
    title: l == null ? 'New contact' : 'Contact',
    fields: (setState) => [
      Field(name, 'Name', autofocus: l == null),
      Choice<String>(
        label: 'Who',
        value: kind,
        options: leadKinds,
        onChanged: (v) => setState(() => kind = v),
      ),
      Field(title, 'Job title'),
      Field(company, 'Organisation'),
      Field(email, 'E-mail'),
      Field(phone, 'Phone'),
      Field(linkedin, 'LinkedIn profile', hint: 'https://www.linkedin.com/in/…'),
      Choice<String>(
        label: 'Status',
        value: status,
        options: leadStatuses,
        onChanged: (v) => setState(() => status = v),
      ),
      DateField(value: followUp, label: 'Follow up on', onChanged: (v) => setState(() => followUp = v)),
      const SizedBox(height: 12),
      Choice<int>(
        label: 'Keep in touch',
        value: keepInTouch,
        options: {for (final e in keepInTouchChoices.entries) e.key ?? 0: e.value},
        onChanged: (v) => setState(() => keepInTouch = v),
      ),
      Field(notes, 'Notes', lines: 3),
      const Subhead('Where you found them'),
      Choice<String>(
        label: 'Found on',
        value: sourceKind,
        options: sourceKinds,
        onChanged: (v) => setState(() => sourceKind = v),
      ),
      Field(source, 'Source', hint: 'e.g. NHS Jobs advert for a Practice Manager'),
      Field(sourceUrl, 'Source link', hint: 'https://…'),
      DateField(
        value: foundOn,
        label: 'Found on (date)',
        onChanged: (v) => setState(() {
          foundOn = v;
          foundOnPicked = true;
        }),
      ),
      const SizedBox(height: 12),
      Choice<String>(
        label: 'Basis for contacting them',
        value: basis,
        options: lawfulBases,
        onChanged: (v) => setState(() => basis = v),
      ),
      Field(basisNote, 'Why (optional)', hint: 'e.g. recruits for the roles I am applying for'),
      if (l != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Forget ${l.name}?',
                message:
                    'This deletes ${l.name}, every address and profile you hold for them, and every conversation '
                    'and message, on all your devices. It cannot be undone.',
                action: 'Forget',
                destructive: true,
              );
              if (!ok) return;
              await ref.mutate((s) => s.book.forgetContact(l.id));
              if (context.mounted) Navigator.of(context, rootNavigator: true).pop(false);
            },
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Forget this person'),
          ),
        ),
    ],
    onSave: () async {
      if (name.text.trim().isEmpty) return 'Enter a name.';
      final id = l?.id ?? newId();
      await ref.mutate(
        (s) => s.book.save(
          s.db.careerContacts,
          CareerContactsCompanion.insert(
            id: id,
            name: name.text.trim(),
            kind: Value(kind),
            title: Value(title.text.trim()),
            company: Value(company.text.trim()),
            email: Value(email.text.trim()),
            phone: Value(phone.text.trim()),
            linkedin: Value(linkedin.text.trim()),
            source: Value(source.text.trim()),
            status: Value(status),
            lastContact: Value(l?.lastContact),
            followUp: Value(status == 'cold' ? null : followUp),
            jobId: Value(l?.jobId),
            notes: Value(notes.text.trim()),
            sourceUrl: Value(sourceUrl.text.trim()),
            sourceKind: Value(sourceKind),
            foundOn: Value(foundOnPicked ? foundOn : null),
            basis: Value(basis),
            basisNote: Value(basisNote.text.trim()),
          ),
          id,
        ),
      );
      final weeks = keepInTouch == 0 ? null : keepInTouch;
      if (weeks != l?.keepInTouchWeeks) {
        await ref.mutate((s) => s.book.setKeepInTouch(id, weeks, today: today()));
      }
      final saved = await ref.read(sessionProvider).book.contact(id);
      if (saved != null) await ref.mutate((s) => s.book.syncHandles(saved));
      return null;
    },
  );
}

/// Opens the newest conversation with [l], or starts one.
Future<void> openConversationWith(BuildContext context, WidgetRef ref, Lead l) async {
  final threads = await ref.read(sessionProvider).book.conversationsOf(l.id);
  if (!context.mounted) return;
  final id = threads.firstOrNull?.id ?? await startConversationDialog(context, ref, contact: l);
  if (id == null || !context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => ConversationsPage(openThread: id)));
}

/// Records that look like the same person, each with a Merge button.
class MergeSuggestions extends ConsumerWidget {
  const MergeSuggestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(mergeSuggestionsProvider).value ?? const <MergeSuggestion>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Possibly the same person',
      child: Column(
        children: [
          for (final m in list)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_who(m.keep)} and ${_who(m.other)}: ${m.why.toLowerCase()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await confirm(
                      context,
                      title: 'Merge these records?',
                      message:
                          '${_who(m.other)} becomes part of ${_who(m.keep)}: their addresses, profiles and '
                          'conversations move across, and the second record is deleted.',
                      action: 'Merge',
                    );
                    if (!ok) return;
                    await ref.mutate(
                      (s) => s.book.mergeContacts(keepId: m.keep.id, otherId: m.other.id, today: today()),
                    );
                  },
                  child: const Text('Merge'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _who(Lead l) => l.company.isEmpty ? l.name : '${l.name} (${l.company})';
}
