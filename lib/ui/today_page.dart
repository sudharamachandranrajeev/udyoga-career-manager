import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation.dart';
import '../app/providers.dart';
import '../db/database.dart';
import '../domain/pipeline.dart';
import '../domain/profile.dart';
import 'applications_page.dart';
import 'coach_page.dart';
import 'common.dart';
import 'contacts_page.dart';
import 'job_page.dart';
import 'jobs_page.dart';
import 'kit/kit.dart';
import 'look.dart';
import 'offer_checks.dart';
import 'today_hero.dart';

/// Next steps, from setting up to the day's chasing.
List<({IconData icon, String text})> nextSteps({
  required CandidateProfile profile,
  required bool hasAi,
  required bool assessed,
  required bool mapped,
  required int jobs,
  required int applications,
  required int practice,
  String? update,
}) => [
  if (update != null)
    (icon: Icons.system_update_outlined, text: 'Udyoga $update is out: update it in Settings.'),
  if (!hasAi)
    (
      icon: Icons.key_outlined,
      text: 'Add a free Gemini key (or a Claude key) in Settings to turn on the AI features.',
    ),
  if (profile.isEmpty)
    (
      icon: Icons.upload_file,
      text: 'Import your CV on the Profile page, or add the folder with your documents on the Coach page.',
    ),
  if (!profile.isEmpty && profile.searchCountries.isEmpty)
    (icon: Icons.public, text: 'Choose the countries to search in on the Profile page.'),
  if (!profile.isEmpty && hasAi && !assessed)
    (icon: Icons.insights, text: 'Run the assessment on the Career page to see where you stand.'),
  if (!profile.isEmpty && hasAi && !mapped)
    (icon: Icons.account_tree_outlined, text: 'Build your career map on the Career page.'),
  if (!profile.isEmpty && jobs == 0) (icon: Icons.refresh, text: 'Refresh the Jobs page to find openings.'),
  if (jobs > 0 && applications == 0)
    (icon: Icons.send_outlined, text: 'Pick your best match, tailor your CV to it and apply.'),
  if (applications > 0 && practice == 0 && hasAi)
    (icon: Icons.record_voice_over_outlined, text: 'Practise an interview before you need one.'),
];

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = today();
    final profile = ref.watch(profileProvider).value ?? const CandidateProfile();
    final hasAi = ref.watch(advisorProvider).value != null;
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    final apps = ref.watch(applicationsProvider).value ?? const <JobApplication>[];
    final leads = ref.watch(leadsProvider).value ?? const <Lead>[];
    final events = ref.watch(eventsProvider).value ?? const <JobEvent>[];
    final practice = ref.watch(practiceProvider).value ?? const <PracticeSession>[];
    final assessed = ref.watch(latestReportProvider('assessment')).value != null;
    final mapped = ref.watch(latestReportProvider('career_map')).value != null;
    final refresh = ref.watch(refreshProvider);
    final checkIn = (ref.watch(journalProvider).value ?? const <CheckIn>[])
        .where((c) => c.day == now)
        .firstOrNull;
    final toConfirm = (ref.watch(questionsProvider).value ?? const <ProfileQuestion>[])
        .where((q) => q.status == 'open')
        .length;
    final checkInTime = ref.watch(checkInSettingsProvider).value?.time ?? '18:30';
    final eveningNow = nowLocal().substring(11).compareTo(checkInTime) >= 0;

    final open = apps.where((a) => Stage.of(a.stage).open).toList();
    final dueApps = apps.where((a) => a.followUp != null && a.followUp!.compareTo(now) <= 0).toList();
    final dueLeads = leads
        .where((l) => l.followUp != null && l.followUp!.compareTo(now) <= 0 && l.status != 'cold')
        .toList();
    final byId = {for (final a in apps) a.id: a};
    // Offer paperwork has hard deadlines (HSC: 5 working days), so it shows
    // two days ahead.
    final checks = checksDue(
      ref.watch(checksProvider).value ?? const <JobCheck>[],
      addDays(now, 2),
    ).where((c) => byId.containsKey(c.applicationId)).toList();
    final interviews =
        events
            .where(
              (e) =>
                  e.kind == 'interview' &&
                  e.at.substring(0, 10).compareTo(now) >= 0 &&
                  byId.containsKey(e.applicationId),
            )
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    final fresh = jobs.where((j) => j.status == 'new').toList()
      ..sort((a, b) => (b.fit ?? -1).compareTo(a.fit ?? -1));
    // Saved jobs, and jobs with an application still being written.
    final unsent = {
      for (final a in apps)
        if (a.jobId != null && Stage.of(a.stage) == Stage.preparing) a.jobId!,
    };
    final closing = jobs
        .where((j) => j.status == 'saved' || unsent.contains(j.id))
        .where((j) => j.closing != null && j.closing!.compareTo(now) >= 0)
        .where((j) => j.closing!.compareTo(addDays(now, 7)) <= 0)
        .toList();
    final steps = nextSteps(
      profile: profile,
      hasAi: hasAi,
      assessed: assessed,
      mapped: mapped,
      jobs: jobs.length,
      applications: apps.length,
      practice: practice.length,
      update: ref.watch(updateProvider).value?.version,
    );
    // The next deadline: a saved job closing or an offer check due, soonest
    // first.
    final deadlines = <Deadline>[
      for (final j in closing)
        (
          title: j.title,
          detail: j.company,
          date: j.closing!,
          when: relativeDay(j.closing!, now),
          open: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobPage(j.id))),
        ),
      for (final c in checks)
        (
          title: c.title,
          detail: byId[c.applicationId]!.title,
          date: c.due!,
          when: relativeDay(c.due!, now),
          open: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationPage(c.applicationId))),
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final next = deadlines.firstOrNull;
    final followUps = dueApps.length + dueLeads.length;
    // Contacts who have answered and are waiting on you; ones already due a
    // follow-up are listed there instead. (Conversations will add unanswered
    // messages here once it is merged.)
    final replies = leads.where((l) => l.status == 'replied' && !dueLeads.contains(l)).toList();
    final sent = apps.where((a) => a.applied != null).length;
    // Heard back: shortlisted or further, up to accepted.
    final heard = apps.where((a) {
      final i = Stage.of(a.stage).index;
      return a.applied != null && i > Stage.applied.index && i <= Stage.accepted.index;
    }).length;

    return PageScaffold(
      title: 'Today',
      banner: 'page.today',
      actions: [
        HintIconButton(
          'apps.calendar',
          icon: Icons.event_available_outlined,
          label: 'Reminders to calendar',
          onPressed: () => exportReminders(context, ref),
        ),
      ],
      children: [
        _Greeting(profile),
        TodayHero(
          counts: [
            StatTile(
              label: 'Applied',
              icon: Icons.send_outlined,
              value: sent,
              caption: sent == 0 ? 'Nothing sent yet' : 'Applications sent',
            ),
            StatTile(
              label: 'Interviews',
              icon: Icons.record_voice_over_outlined,
              value: interviews.length,
              caption: interviews.isEmpty ? 'None booked' : 'Coming up',
            ),
            StatTile(
              label: 'Follow-ups due',
              icon: Icons.notifications_active_outlined,
              value: followUps,
              caption: followUps == 0 ? 'All caught up' : 'Chase them today',
              status: followUps == 0 ? null : Status.warning,
            ),
            StatTile(
              label: 'In progress',
              icon: Icons.timelapse,
              value: open.length,
              caption: open.isEmpty ? 'No open applications' : 'Open applications',
            ),
            StatTile(
              label: 'New matches',
              icon: Icons.work_outline,
              value: fresh.length,
              caption: fresh.isEmpty ? 'None new yet' : 'To look through',
            ),
            StatTile(
              label: 'Response rate',
              icon: Icons.mark_email_unread_outlined,
              value: sent == 0 ? null : (heard * 100 / sent).round(),
              suffix: '%',
              caption: sent == 0 ? 'No applications sent yet' : '$heard of $sent heard back',
            ),
          ],
          deadline: next == null ? null : _withNiceDate(next),
        ),
        if (refresh.running)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Expanded(child: Text(refresh.status)),
              ],
            ),
          ),
        _NeedsYou(
          [
            if (replies.isNotEmpty)
              SectionCard(
                title: 'Replies waiting',
                child: Column(children: [for (final l in replies) LeadTile(l)]),
              ),
            if (dueApps.isNotEmpty || dueLeads.isNotEmpty)
              SectionCard(
                title: 'Follow up today',
                child: Column(
                  children: [
                    for (final a in dueApps) ApplicationTile(a),
                    for (final l in dueLeads) LeadTile(l),
                  ],
                ),
              ),
            if (checks.isNotEmpty)
              SectionCard(
                title: 'Offer checks due',
                child: Column(
                  children: [
                    for (final c in checks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(checkStatus(c, now).icon, color: checkStatus(c, now).color),
                        title: Text(c.title),
                        subtitle: Text(
                          '${byId[c.applicationId]!.title} · due ${niceDate(c.due!)} (${relativeDay(c.due!, now)})',
                        ),
                        onTap: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => ApplicationPage(c.applicationId))),
                      ),
                  ],
                ),
              ),
            if (closing.isNotEmpty)
              SectionCard(
                title: 'Closing this week',
                child: Column(children: [for (final j in closing) JobTile(j, list: 'closing')]),
              ),
          ],
          count: replies.length + followUps + checks.length + closing.length,
          nothingLabel: fresh.isEmpty ? 'Open Jobs' : 'See new matches',
          onNothing: () => goToPage(ref, 'jobs'),
        ),
        if ((eveningNow && (checkIn == null || checkIn.entry.isEmpty)) || toConfirm > 0)
          SectionCard(
            title: 'Your coach',
            child: Column(
              children: [
                if (eveningNow && (checkIn == null || checkIn.entry.isEmpty))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wb_twilight_outlined),
                    title: const Text('How was your day? Two minutes for today\'s check-in.'),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachPage())),
                  ),
                if (toConfirm > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(
                      toConfirm == 1
                          ? '1 question to confirm your profile.'
                          : '$toConfirm questions to confirm your profile.',
                    ),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachPage())),
                  ),
              ],
            ),
          ),
        if (steps.isNotEmpty)
          SectionCard(
            title: 'Next steps',
            child: Column(
              children: [
                for (final s in steps)
                  ListTile(contentPadding: EdgeInsets.zero, leading: Icon(s.icon), title: Text(s.text)),
              ],
            ),
          ),
        if (interviews.isNotEmpty)
          SectionCard(
            title: 'Upcoming interviews',
            child: Column(
              children: [
                for (final e in interviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.record_voice_over_outlined),
                    title: Text(byId[e.applicationId]!.title),
                    subtitle: Text(
                      '${niceDateTime(e.at)} (${relativeDay(e.at.substring(0, 10), now)}) ${e.summary}',
                    ),
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ApplicationPage(e.applicationId))),
                  ),
              ],
            ),
          ),
        SectionCard(
          title: 'Best new matches',
          child: fresh.isEmpty
              ? const Text('No new matches. Jobs refresh every few hours while Udyoga is open.')
              : Column(children: [for (final j in fresh.take(5)) JobTile(j, list: 'fresh')]),
        ),
      ],
    );
  }
}

/// The deadline with its date written out ("24 Oct 2026").
Deadline _withNiceDate(Deadline d) =>
    (title: d.title, detail: d.detail, date: niceDate(d.date), when: d.when, open: d.open);

class _Greeting extends StatelessWidget {
  const _Greeting(this.p);
  final CandidateProfile p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.name.isNotEmpty) ...[
            Row(
              children: [
                OrgLogo(p.name, size: 46),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back', style: t.bodyMedium?.copyWith(color: muted)),
                    Text(p.name, style: t.titleMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const Headline(["Let's get ", 'you hired', ' for the job you ', 'deserve', '.']),
          if (p.currentRole.isNotEmpty || p.targets.roles.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              p.targets.roles.isNotEmpty ? 'Aiming for ${p.targets.roles.take(3).join(', ')}' : p.currentRole,
              style: t.bodyLarge?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// What needs doing today: replies to answer, follow-ups, offer checks and
/// jobs closing, each group a card arriving in turn. When nothing does, it
/// says so and offers the one useful next step.
class _NeedsYou extends StatelessWidget {
  const _NeedsYou(this.cards, {required this.count, required this.nothingLabel, required this.onNothing});
  final List<Widget> cards;
  final int count;
  final String nothingLabel;
  final VoidCallback onNothing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Flexible(child: Text('Needs you', style: t.titleLarge)),
              if (count > 0) ...[
                const SizedBox(width: 10),
                StatusPill(count == 1 ? '1 thing' : '$count things', status: Status.warning),
              ],
            ],
          ),
        ),
        if (cards.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SpotlightCard(
              child: Row(
                children: [
                  Icon(Icons.task_alt, color: Status.good.color),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Nothing needs you today.')),
                  const SizedBox(width: 8),
                  TextButton(onPressed: onNothing, child: Text(nothingLabel)),
                ],
              ),
            ),
          )
        else
          for (final (i, card) in cards.indexed) BlurFadeIn(index: i, child: card),
      ],
    );
  }
}
