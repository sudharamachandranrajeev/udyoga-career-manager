import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/insights.dart';
import '../domain/pay.dart';
import 'common.dart';
import 'kit/kit.dart';

String _pounds(int n) {
  final s = n.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${n < 0 ? '-' : ''}£$s';
}

String _signed(int n) => n >= 0 ? '+${_pounds(n)}' : _pounds(n);

/// What the job pays against the candidate's current pay: gross, an
/// estimated take-home and the rent difference.
class PayChangeCard extends ConsumerWidget {
  const PayChangeCard(this.job, {super.key});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(payBaselineProvider).value;
    if (base == null) return const SizedBox.shrink();
    final band = bandIn('${job.salaryText} ${job.title}');
    // On promotion the pay starts at the band's entry point, which is the
    // advert's lower figure.
    final next = job.salaryMin ?? englandEntry(band);
    final change = base.isSet && next != null && next > 0
        ? PayChange(now: base.pay, next: next, rentNow: base.rentNow, rentNext: base.rentNext)
        : null;
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Pay change',
      trailing: TextButton(
        onPressed: () => editPayBaseline(context, ref, base),
        child: Text(base.isSet ? 'Your pay' : 'Add your pay'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!base.isSet)
            const Text(
              'Add your current basic pay (and rent, if you are moving) to see what this job changes each '
              'month, after tax, National Insurance and pension.',
            )
          else if (change == null)
            const Text('The advert gives no salary to compare with.')
          else ...[
            // The headline figure rolls to its value as the page opens.
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RollingNumber(
                  change.grossYear,
                  prefix: '£',
                  suffix: ' a year',
                  showSign: true,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                StatusPill(
                  '${change.grossPercent >= 0 ? '+' : ''}${change.grossPercent.toStringAsFixed(1)}%',
                  status: change.grossYear >= 0 ? Status.good : Status.serious,
                  icon: change.grossYear >= 0 ? Icons.trending_up : Icons.trending_down,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${base.label.isEmpty ? _pounds(base.pay) : '${base.label} (${_pounds(base.pay)})'} to '
              '${_pounds(next!)}${band.isEmpty ? '' : ', Band $band'}${job.salaryMin == null ? ', entry point' : ''}.',
            ),
            if (change.takeHomeMonth case final t?)
              Text('About ${_signed(t)} a month after tax, NI and pension.'),
            if (change.rentMonth case final r?)
              Text(
                'Rent ${_signed(r)} a month, leaving about '
                '${change.afterRentMonth == null ? 'an unknown amount' : _signed(change.afterRentMonth!)} a month.',
              ),
            const SizedBox(height: 4),
            Text(
              'Full-time basic pay; part-time is pro rata. Estimates use 2026/27 tax for England, Wales and '
              'Northern Ireland and the NHS Pension tiers.',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Sets the candidate's current pay, from the built-in Agenda for Change
/// points or typed, and the rents.
Future<void> editPayBaseline(BuildContext context, WidgetRef ref, PayBaseline b) async {
  final pay = TextEditingController(text: b.isSet ? '${b.pay}' : '');
  final label = TextEditingController(text: b.label);
  final rentNow = TextEditingController(text: b.rentNow?.toString() ?? '');
  final rentNext = TextEditingController(text: b.rentNext?.toString() ?? '');
  await showFormDialog(
    context,
    title: 'Your current pay',
    fields: (setState) => [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in afcPoints)
            ChoiceChip(
              label: Text(p.label),
              selected: pay.text == '${p.pay}',
              onSelected: (_) => setState(() {
                pay.text = '${p.pay}';
                label.text = p.label;
              }),
            ),
        ],
      ),
      Field(pay, 'Basic pay a year, full time', number: true, prefix: '£ '),
      Field(label, 'What it is', hint: 'e.g. NI Band 3 entry'),
      Field(rentNow, 'Rent a month now', number: true, prefix: '£ '),
      Field(rentNext, 'Rent a month after moving', number: true, prefix: '£ '),
    ],
    onSave: () async {
      final p = intIn(pay) ?? 0;
      if (p <= 0) return 'Your basic pay, please.';
      await ref.mutate(
        (s) => s.book.setPayBaseline(
          PayBaseline(pay: p, label: label.text.trim(), rentNow: intIn(rentNow), rentNext: intIn(rentNext)),
        ),
      );
      return null;
    },
  );
}

/// What it is like to work for the job's employer, researched with sources.
class EmployerCard extends ConsumerWidget {
  const EmployerCard(this.job, {super.key});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job.company.isEmpty) return const SizedBox.shrink();
    final hasAi = ref.watch(advisorProvider).value != null;
    final brief = ref.watch(employerBriefProvider(job.company)).value;
    return SectionCard(
      title: 'Working at ${job.company}',
      trailing: hasAi
          ? TextButton(
              onPressed: () => _research(context, ref),
              child: Text(brief == null ? 'Research' : 'Redo'),
            )
          : null,
      child: brief == null
          ? Text(
              hasAi
                  ? 'The systems its staff use, staff survey and inspection results with their sources, and '
                        'anything to watch, such as a restructure.'
                  : 'Add a free Gemini key or a Claude API key in Settings to research the employer.',
            )
          : EmployerView(brief),
    );
  }

  Future<void> _research(BuildContext context, WidgetRef ref) async {
    final p = await ref.read(profileProvider.future);
    if (!context.mounted) return;
    final r = await runAi(
      context,
      title: 'Researching ${job.company}',
      task: (progress) async =>
          (await requireAdvisor(ref))
              .researchEmployer(p, job.company, place: job.location, onProgress: progress),
    );
    if (r == null) return;
    await ref.mutate((s) => s.book.saveEmployerBrief(job.company, r, at: DateTime.now().toIso8601String()));
  }
}

class EmployerView extends StatelessWidget {
  const EmployerView(this.b, {super.key});
  final EmployerBrief b;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (b.summary.isNotEmpty) SelectableText(b.summary),
      if (b.systems.isNotEmpty) ...[
        const Subhead('Systems'),
        for (final s in b.systems) Text('• ${s['name'] ?? ''}: ${s['detail'] ?? ''}'),
      ],
      if (b.culture.isNotEmpty) ...[
        const Subhead('Culture evidence'),
        for (final c in b.culture)
          InkWell(
            onTap: '${c['source'] ?? ''}'.startsWith('http')
                ? () => openLink(context, '${c['source']}')
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${c['point'] ?? ''}'),
            ),
          ),
      ],
      if (b.watch.isNotEmpty) ...[const Subhead('To watch'), for (final w in b.watch) Text('• $w')],
      if (b.askAtInterview.isNotEmpty) ...[
        const Subhead('Ask the panel'),
        for (final q in b.askAtInterview) Text('• $q'),
      ],
      if (b.researched.length >= 10)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Researched ${b.researched.substring(0, 10)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      SourcesList(SourcesList.of(b.sources)),
    ],
  );
}
