import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/book.dart';
import '../domain/pipeline.dart';
import 'common.dart';

/// How a check's due date reads today: late, due today, or fine. Done and
/// not-needed checks are never late.
Status checkStatus(JobCheck c, String today) {
  if (c.status == 'done' || c.status == 'not_needed') return Status.good;
  final due = c.due;
  if (due == null) return Status.info;
  final d = due.compareTo(today);
  return d < 0
      ? Status.serious
      : d == 0
      ? Status.warning
      : Status.info;
}

/// The checks still to do on or before [before], across applications,
/// soonest first (for Today).
List<JobCheck> checksDue(List<JobCheck> all, String before) =>
    all
        .where(
          (c) => (c.status == 'todo' || c.status == 'sent') && c.due != null && c.due!.compareTo(before) <= 0,
        )
        .toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));

/// The offer-to-start checklist: identity, references, DBS or AccessNI,
/// occupational health, forms, contract, notice and start date, each with
/// its status and due date.
class ChecksSection extends ConsumerWidget {
  const ChecksSection(this.application, {super.key});
  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = application;
    final now = today();
    final list = CareerBook.sortChecks(
      (ref.watch(checksProvider).value ?? const <JobCheck>[]).where((c) => c.applicationId == a.id).toList(),
    );
    final stage = Stage.of(a.stage);
    final offered = stage.index >= Stage.offer.index && stage.index <= Stage.accepted.index;
    if (list.isEmpty && !offered) return const SizedBox.shrink();
    final settled = list.where((c) => c.status == 'done' || c.status == 'not_needed').length;
    return SectionCard(
      title: 'Offer and checks',
      trailing: list.isEmpty
          ? null
          : TextButton(onPressed: () => _add(context, ref, a), child: const Text('Add')),
      child: list.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NHS and HSC offers are conditional on checks: identity and right to work, references, '
                  'DBS or AccessNI, occupational health and qualifications. HSC wants the forms within '
                  '5 working days.',
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => ref.mutate((s) => s.book.startChecks(a.id, now)),
                  icon: const Icon(Icons.checklist),
                  label: const Text('Start the checklist'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('$settled of ${list.length} done'),
                for (final c in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(switch (c.status) {
                      'done' => Icons.check_circle,
                      'not_needed' => Icons.remove_circle_outline,
                      'sent' => Icons.hourglass_top,
                      _ => Icons.radio_button_unchecked,
                    }, color: checkStatus(c, now) == Status.info ? null : checkStatus(c, now).color),
                    title: Text(c.title),
                    subtitle: StatusLabel(
                      checkStatus(c, now),
                      [
                        checkStatuses[c.status] ?? c.status,
                        if (c.status == 'done' && c.done != null)
                          niceDate(c.done!)
                        else if (c.due != null && c.status != 'not_needed')
                          'due ${niceDate(c.due!)} (${relativeDay(c.due!, now)})',
                        if (c.notes.isNotEmpty) c.notes,
                      ].join(' · '),
                    ),
                    onTap: () => _edit(context, ref, c),
                  ),
              ],
            ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, JobCheck c) {
    var status = c.status;
    var dated = c.due != null;
    var due = c.due ?? addDays(today(), 7);
    final notes = TextEditingController(text: c.notes);
    return showFormDialog(
      context,
      title: c.title,
      fields: (setState) => [
        Choice<String>(
          label: 'Status',
          value: status,
          options: checkStatuses,
          onChanged: (v) => setState(() => status = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Has a deadline'),
          value: dated,
          onChanged: (v) => setState(() => dated = v),
        ),
        if (dated) DateField(value: due, label: 'Due', onChanged: (v) => setState(() => due = v)),
        const SizedBox(height: 12),
        Field(notes, 'Notes', lines: 2, hint: 'Appointment time, documents to bring, who to chase'),
      ],
      onSave: () async {
        await ref.mutate(
          (s) => s.book.setCheck(c, status, today: today(), due: dated ? due : '', notes: notes.text.trim()),
        );
        return null;
      },
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, JobApplication a) {
    final title = TextEditingController();
    var dated = false;
    var due = addDays(today(), 5);
    return showFormDialog(
      context,
      title: 'Add a check',
      action: 'Add',
      fields: (setState) => [
        Field(title, 'What', autofocus: true, hint: 'Smart card photo, uniform fitting, induction booking'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Has a deadline'),
          value: dated,
          onChanged: (v) => setState(() => dated = v),
        ),
        if (dated) DateField(value: due, label: 'Due', onChanged: (v) => setState(() => due = v)),
      ],
      onSave: () async {
        if (title.text.trim().isEmpty) return 'Say what the check is.';
        await ref.mutate(
          (s) => s.book.addCheck(a.id, kind: 'other', title: title.text.trim(), due: dated ? due : null),
        );
        return null;
      },
    );
  }
}

/// Copies of the advert and of the application as sent. NHS Jobs deletes
/// both 400 days after closing, so Udyoga keeps its own.
class KeptCopiesSection extends ConsumerWidget {
  const KeptCopiesSection(this.applicationId, {super.key});
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kept = (ref.watch(archiveProvider).value ?? const <Archived>[])
        .where((k) => k.applicationId == applicationId)
        .toList();
    return SectionCard(
      title: 'Kept copies',
      child: kept.isEmpty
          ? const Text(
              'Open the site from this application to keep a copy of the advert. '
              'Udyoga keeps your answers when you mark it sent.',
            )
          : Column(
              children: [
                for (final k in kept)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(k.kind == 'application' ? Icons.outbox_outlined : Icons.article_outlined),
                    title: Text(k.kind == 'application' ? 'Application as sent' : 'Advert'),
                    subtitle: Text([k.title, niceDateTime(k.at)].where((s) => s.isNotEmpty).join(' · ')),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => KeptCopyPage(k))),
                  ),
              ],
            ),
    );
  }
}

class KeptCopyPage extends StatelessWidget {
  const KeptCopyPage(this.copy, {super.key});
  final Archived copy;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: copy.kind == 'application' ? 'Application as sent' : 'Advert',
    actions: [
      IconButton(
        icon: const Icon(Icons.copy),
        tooltip: 'Copy the text',
        onPressed: () => copyText(context, copy.content, what: 'Copied.'),
      ),
      if (copy.url.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Open the original',
          onPressed: () => openLink(context, copy.url),
        ),
    ],
    children: [
      SectionCard(
        title: copy.title.ifEmpty('Kept ${niceDateTime(copy.at)}'),
        child: SelectableText(copy.content),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Kept ${niceDateTime(copy.at)}${copy.url.isEmpty ? '' : ' from ${copy.url}'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}
