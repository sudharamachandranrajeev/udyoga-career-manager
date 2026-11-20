import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/countries.dart';
import '../domain/json.dart';
import '../domain/profile.dart';
import '../domain/visa_clock.dart';
import '../domain/work_rights.dart';
import 'common.dart';
import 'kit/kit.dart';

/// Passports, rights to work (with the clock on any that end) and
/// languages, on the Profile page.
class RightsCard extends ConsumerWidget {
  const RightsCard(this.p, {super.key});
  final CandidateProfile p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = p.rights;
    final now = today();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SectionCard(
      title: 'Right to work and languages',
      hint: 'profile.rights',
      trailing: TextButton(onPressed: () => _editBasics(context, ref, r), child: const Text('Edit')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.passports.isEmpty
                ? 'Passports: not set'
                : 'Passports: ${r.passports.map(Country.nameOf).join(', ')}',
          ),
          Text(
            r.languages.isEmpty
                ? 'Languages: not set${p.languages.isEmpty ? '' : ' (your CV lists ${p.languages.join(', ')})'}'
                : 'Languages: ${r.languages.map((l) => '${l.language} (${l.level.label.toLowerCase()})').join(', ')}',
          ),
          const SizedBox(height: 8),
          for (final (i, w) in r.rightToWork.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: Text([Country.nameOf(w.country), if (w.status.isNotEmpty) w.status].join(': ')),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (w.until == null) 'Does not end' else 'Until ${niceDate(w.until!)}',
                      if (w.notes.isNotEmpty) w.notes,
                    ].join('\n'),
                  ),
                  if (w.until != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _Countdown(VisaClock(w, today: now)),
                    ),
                ],
              ),
              onTap: () => _editRight(context, ref, r, i),
            ),
          if (r.rightToWork.isEmpty)
            Text(
              'No right to work recorded. Add one so Udyoga can tell which adverts you can apply for.',
              style: TextStyle(color: muted),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _editRight(context, ref, r, null),
              icon: const Icon(Icons.add),
              label: const Text('Add a right to work'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editBasics(BuildContext context, WidgetRef ref, WorkRights r) {
    final passports = TextEditingController(text: r.passports.map(Country.nameOf).join(', '));
    final languages = TextEditingController(
      text: r.languages.map((l) => '${l.language}: ${l.level.label.toLowerCase()}').join('\n'),
    );
    return showFormDialog(
      context,
      title: 'Passports and languages',
      fields: (_) => [
        Field(passports, 'Passports', hint: 'India, Ireland', helper: 'Countries, comma-separated'),
        Field(
          languages,
          'Languages',
          lines: 4,
          hint: 'English: fluent\nHindi: native',
          helper: 'One per line: basic, conversational, professional, fluent or native (or A2 to C2).',
        ),
      ],
      onSave: () async {
        final codes = [for (final s in linesIn(passports)) countryCode(s)];
        if (codes.contains('')) {
          return 'A passport country was not recognised. Use its name or 2-letter code.';
        }
        final langs = <SpokenLanguage>[];
        for (final line in linesIn(languages)) {
          final parts = line.split(RegExp(r'\s*[:(\-–]\s*'));
          final name = parts.first.trim();
          if (name.isEmpty) continue;
          final level = LanguageLevel.parse(line.substring(name.length));
          langs.add(
            SpokenLanguage(name[0].toUpperCase() + name.substring(1), level ?? LanguageLevel.professional),
          );
        }
        await ref.mutate(
          (s) => s.book.saveWorkRights(r.copyWith(passports: codes.toSet().toList(), languages: langs)),
        );
        return null;
      },
    );
  }

  Future<void> _editRight(BuildContext context, WidgetRef ref, WorkRights r, int? index) {
    final w = index == null ? null : r.rightToWork[index];
    final country = TextEditingController(text: w == null ? '' : Country.nameOf(w.country));
    final status = TextEditingController(text: w?.status ?? '');
    final until = TextEditingController(text: w?.until ?? '');
    final notes = TextEditingController(text: w?.notes ?? '');
    List<RightToWork> without() => [...r.rightToWork]..removeAt(index!);
    return showFormDialog(
      context,
      title: index == null ? 'Add a right to work' : 'Right to work',
      fields: (_) => [
        Field(country, 'Country', hint: 'United Kingdom'),
        Field(status, 'Status', hint: 'Skilled Worker visa, settled, citizen'),
        Field(until, 'Ends on', hint: '2028-03-31', helper: 'yyyy-mm-dd; empty when it does not end'),
        Field(notes, 'Notes', lines: 2),
        if (index != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                await ref.mutate((s) => s.book.saveWorkRights(r.copyWith(rightToWork: without())));
                if (context.mounted) Navigator.of(context, rootNavigator: true).pop(false);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ),
      ],
      onSave: () async {
        final code = countryCode(country.text);
        if (code.isEmpty) return 'Enter the country, by name or 2-letter code.';
        final end = until.text.trim();
        if (end.isNotEmpty && !isDay(end)) {
          return 'Write the end date as yyyy-mm-dd.';
        }
        final entry = RightToWork(
          country: code,
          status: status.text.trim(),
          until: end.isEmpty ? null : end,
          notes: notes.text.trim(),
        );
        final list = [...r.rightToWork];
        if (index == null) {
          list.add(entry);
        } else {
          list[index] = entry;
        }
        await ref.mutate((s) => s.book.saveWorkRights(r.copyWith(rightToWork: list)));
        return null;
      },
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown(this.clock);
  final VisaClock clock;

  @override
  Widget build(BuildContext context) {
    final months = clock.monthsLeft;
    return StatusPill(
      clock.label,
      icon: Icons.hourglass_bottom,
      status: clock.ended || months < 6
          ? Status.serious
          : months < 12
          ? Status.warning
          : null,
    );
  }
}
