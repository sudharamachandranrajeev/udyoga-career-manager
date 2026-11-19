import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/book.dart';
import '../domain/eligibility.dart';
import '../domain/feeds.dart';
import '../domain/matching.dart';
import '../domain/profile.dart';
import '../domain/sponsors.dart';
import 'common.dart';
import 'kit/kit.dart';

// ---- eligibility, worked out once per job and profile ----

final _fingerprints = Expando<String>();
final _checks = <String, EligibilityCheck>{};

String _fingerprint(CandidateProfile p) => _fingerprints[p] ??= jsonEncode([
  p.country,
  p.languages,
  p.currentEmployer,
  [for (final e in p.experience) '${e.organisation}|${e.location}'],
  p.targets.exclusions,
  p.rights.toJson(),
]);

/// What [j]'s advert means for [p] today. Kept until the job, the profile
/// or the day changes, so long lists stay quick.
EligibilityCheck eligibilityOf(Job j, CandidateProfile p) {
  final now = today();
  final key = '${j.id}|${j.hlc}|$now|${_fingerprint(p)}';
  final hit = _checks[key];
  if (hit != null) return hit;
  if (_checks.length > 2000) _checks.clear();
  return _checks[key] = checkEligibility(
    p,
    title: j.title,
    company: j.company,
    description: j.description,
    country: j.country,
    today: now,
  );
}

/// The quick match's reasons for [j], for the job page.
FitResult fitOf(Job j, CandidateProfile p) => scoreFit(p, CareerBook.factsOf(j), today: today());

/// The jobs the user's exclusions do not rule out.
List<Job> notExcluded(List<Job> jobs, CandidateProfile? p) => p == null || p.targets.exclusions.isEmpty
    ? jobs
    : [
        for (final j in jobs)
          if (!eligibilityOf(j, p).excluded) j,
      ];

Status _tone(Severity s) => switch (s) {
  Severity.blocker => Status.serious,
  Severity.caution => Status.warning,
  Severity.info => Status.info,
  Severity.clear => Status.good,
};

IconData _icon(Severity s) => switch (s) {
  Severity.blocker => Icons.block,
  Severity.caution => Icons.warning_amber_rounded,
  Severity.info => Icons.info_outline,
  Severity.clear => Icons.check_circle_outline,
};

/// The one eligibility line worth a pill on a job tile: the worst blocker
/// or caution; nothing when the advert sets no limits that matter.
class EligibilityPill extends ConsumerWidget {
  const EligibilityPill(this.job, {super.key});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).value;
    if (p == null) return const SizedBox.shrink();
    final worst = eligibilityOf(job, p).sorted.firstOrNull;
    if (worst == null || (worst.severity != Severity.blocker && worst.severity != Severity.caution)) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: '"${worst.quote}"${worst.note.isEmpty ? '' : '\n${worst.note}'}',
      child: StatusPill(worst.title, status: _tone(worst.severity), icon: _icon(worst.severity)),
    );
  }
}

/// The advert's eligibility lines on the job page, each with the sentence
/// it came from.
class EligibilityCard extends ConsumerWidget {
  const EligibilityCard(this.job, {super.key});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).value;
    if (p == null) return const SizedBox.shrink();
    final check = eligibilityOf(job, p);
    if (check.findings.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SectionCard(
      title: check.blocked
          ? 'You may not be able to apply'
          : check.cautious
          ? 'Who can apply: check these'
          : 'Who can apply',
      hint: 'job.eligibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in check.sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusLabel(_tone(f.severity), f.title),
                  const SizedBox(height: 4),
                  SelectableText('"${f.quote}"', style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  if (f.note.isNotEmpty) Text(f.note, style: t.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ),
          if (p.rights.isEmpty)
            Text(
              'Add your passports, rights to work and languages on the Profile page and Udyoga checks '
              'these for you.',
              style: t.bodySmall?.copyWith(color: muted),
            ),
        ],
      ),
    );
  }
}

/// "Licensed sponsor" when [employer] is on the UK register (for UK jobs
/// only); nothing otherwise, or before the register is downloaded.
class SponsorBadge extends ConsumerWidget {
  const SponsorBadge(this.employer, {super.key, this.country = 'GB', this.short = false});
  final String employer, country;

  /// "Licensed sponsor" alone, the routes in the tooltip.
  final bool short;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (employer.isEmpty || (country.isNotEmpty && country != 'GB')) return const SizedBox.shrink();
    final s = ref.watch(sponsorRegisterProvider).value?.lookup(employer);
    if (s == null) return const SizedBox.shrink();
    return Tooltip(
      message:
          '${s.name}${s.town.isEmpty ? '' : ', ${s.town}'}: on the UK register of licensed sponsors '
          '(${(s.routes.toList()..sort()).join(', ')}).',
      child: StatusPill(
        short ? 'Licensed sponsor' : s.badge,
        status: Status.good,
        icon: Icons.verified_user_outlined,
      ),
    );
  }
}

/// The credit Adzuna's terms ask for on each of its ads.
class AdzunaCredit extends StatelessWidget {
  const AdzunaCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      link: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => openLink(context, adzunaHome),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            'Jobs by Adzuna',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A sponsor-register entry for [employer], or null.
Sponsor? sponsorOf(WidgetRef ref, String employer) =>
    ref.watch(sponsorRegisterProvider).value?.lookup(employer);
