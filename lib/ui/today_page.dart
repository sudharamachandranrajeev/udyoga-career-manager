import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation.dart';
import '../app/explore_providers.dart';
import '../app/providers.dart';
import '../db/database.dart';
import '../domain/conversations.dart';
import '../domain/employers.dart';
import '../domain/pipeline.dart';
import '../domain/profile.dart';
import '../domain/visa_clock.dart';
import 'applications_page.dart';
import 'coach_page.dart';
import 'common.dart';
import 'contacts_page.dart';
import 'eligibility_view.dart';
import 'employers_page.dart';
import 'job_page.dart';
import 'jobs_page.dart';
import 'kit/kit.dart';
import 'look.dart' hide Pace;
import 'offer_checks.dart';
import 'today_hero.dart';
import 'todos.dart';
import '../domain/tracks.dart';

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
    // Jobs the user's exclusions rule out never show.
    final jobs = notExcluded(
      ref.watch(jobsProvider).value ?? const <Job>[],
      ref.watch(profileProvider).value,
    );
    final todos = todosIn(ref.watch(growthProvider).value ?? const <GrowthItem>[]);
    final openTodos = todos.where((t) => t.status != 'done').toList();
    final dueTodos = openTodos.where((t) => isDue(t, now)).length;
    // A right to work that ends: its reminder at 18, 12, 6 and 3 months.
    final visas = [
      for (final c in visaClocks(profile.rights, today: now))
        if (c.current case final m?) (clock: c, milestone: m),
    ];
    final milestones = trackDeadlines(ref.watch(tracksProvider).value ?? const <RouteTrack>[]);
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
    // New openings at the employers the user watches.
    final watched = watchedNewJobs(
      jobs,
      ref.watch(watchedEmployersProvider).value ?? const <WatchedEmployer>[],
    );
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
      for (final t in openTodos)
        if (t.target != null && t.target!.compareTo(now) >= 0 && t.target!.compareTo(addDays(now, 7)) <= 0)
          (
            title: t.title,
            detail: 'To-do',
            date: t.target!,
            when: relativeDay(t.target!, now),
            open: () => goToPage(ref, 'growth'),
          ),
      // Route-track milestones in the next two weeks (or overdue) that are
      // not already on the to-do list.
      for (final d in milestones)
        if (d.milestone.todo == null && d.milestone.due!.compareTo(addDays(now, 14)) <= 0)
          (
            title: d.milestone.title,
            detail: d.track.title,
            date: d.milestone.due!,
            when: relativeDay(d.milestone.due!, now),
            open: () => goToPage(ref, 'explore'),
          ),
      for (final v in visas)
        (
          title: v.milestone.title,
          detail: v.milestone.detail,
          date: v.clock.right.until!,
          when: v.clock.label,
          open: () => goToPage(ref, 'profile'),
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final next = deadlines.firstOrNull;
    // Threads where they wrote last, or that are marked replied.
    final replies = filterThreads(
      ref.watch(threadRowsProvider).value ?? const <ThreadRow>[],
      filter: ThreadFilter.needsReply,
      today: now,
    );
    // People due from a thread's follow-up or a "keep in touch" date, with
    // why and where. Those dates also fill the contact's own follow-up, so
    // they are left out of Follow up today rather than listed twice.
    final keepInTouch = ref.watch(dueFollowUpsProvider).value ?? const <FollowUpDue>[];
    final chaseLeads = dueLeads.where((l) => !keepInTouch.any((d) => d.contact.id == l.id)).toList();
    final followUps = dueApps.length + chaseLeads.length + keepInTouch.length;
    final pace = ref.watch(paceProvider).value;
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
        const PaletteButton(),
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
              caption: followUps == 0 ? 'All caught up' : 'Chase today',
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
                child: _FirstFew([
                  for (final r in replies) _ReplyTile(r, onTap: () => openThread(ref, r.thread.id)),
                ], onMore: () => goToPage(ref, 'conversations')),
              ),
            if (dueApps.isNotEmpty || chaseLeads.isNotEmpty)
              SectionCard(
                title: 'Follow up today',
                child: _FirstFew([
                  for (final a in dueApps) ApplicationTile(a),
                  for (final l in chaseLeads) LeadTile(l),
                ], onMore: () => goToPage(ref, dueApps.isNotEmpty ? 'applications' : 'contacts')),
              ),
            if (keepInTouch.isNotEmpty)
              SectionCard(
                title: 'Keep in touch',
                child: _FirstFew([
                  for (final d in keepInTouch)
                    _KeepInTouchTile(
                      d,
                      onTap: d.thread == null
                          ? () => openConversationWith(context, ref, d.contact)
                          : () => openThread(ref, d.thread!.id),
                    ),
                ], onMore: () => goToPage(ref, 'contacts')),
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
            if (dueTodos > 0) TodoCard(openTodos, limit: 5, onMore: () => goToPage(ref, 'growth')),
            for (final v in visas)
              SectionCard(
                title: 'Visa clock',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.hourglass_bottom),
                  title: Text('${v.milestone.title} (${v.clock.label})'),
                  subtitle: Text(
                    [
                      v.milestone.detail,
                      if (v.clock.next case final n?) 'Next reminder ${niceDate(n.date)}',
                    ].join('\n'),
                  ),
                  onTap: () => goToPage(ref, 'profile'),
                ),
              ),
            if (watched.isNotEmpty)
              SectionCard(
                title: 'From employers you watch',
                hint: 'today.watched',
                child: _FirstFew(
                  [for (final w in watched) JobTile(w.job, list: 'watched')],
                  onMore: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmployersPage())),
                ),
              ),
            if (closing.isNotEmpty)
              SectionCard(
                title: 'Closing this week',
                child: _FirstFew([
                  for (final j in closing) JobTile(j, list: 'closing'),
                ], onMore: () => goToPage(ref, 'jobs')),
              ),
          ],
          count:
              replies.length +
              followUps +
              checks.length +
              closing.length +
              dueTodos +
              visas.length +
              watched.length,
          pace: pace == null || pace.level == PaceLevel.calm ? null : pace,
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
        if (dueTodos == 0 && openTodos.isNotEmpty)
          TodoCard(openTodos, limit: 5, onMore: () => goToPage(ref, 'growth')),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back', style: t.bodyMedium?.copyWith(color: muted)),
                      Text(p.name, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
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
  const _NeedsYou(
    this.cards, {
    required this.count,
    required this.nothingLabel,
    required this.onNothing,
    this.pace,
  });
  final List<Widget> cards;
  final int count;

  /// LinkedIn sending that is busy or past the safe pace; null when calm.
  final Pace? pace;
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
        if (pace case final p?) _PaceHint(p),
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

/// The first few of a long list, with a link to the page holding the rest,
/// so thirty follow-ups don't bury everything below them.
class _FirstFew extends StatelessWidget {
  const _FirstFew(this.tiles, {required this.onMore});
  final List<Widget> tiles;
  final VoidCallback onMore;
  static const shown = 5;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...tiles.take(shown),
      if (tiles.length > shown)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onMore,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text('See all ${tiles.length}'),
          ),
        ),
    ],
  );
}

/// A thread waiting on the user: where it is, who, and how their last
/// message starts.
class _ReplyTile extends StatelessWidget {
  const _ReplyTile(this.row, {required this.onTap});
  final ThreadRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final last = row.last;
    return _PersonRow(
      name: row.contact?.name ?? senderName(row.thread).ifEmpty('Unknown sender'),
      channel: row.thread.channel,
      onTap: onTap,
      detail: last == null
          ? null
          : Text(
              last.body.replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(color: muted),
            ),
    );
  }
}

/// Someone to get back to: why, and how overdue.
class _KeepInTouchTile extends StatelessWidget {
  const _KeepInTouchTile(this.due, {required this.onTap});
  final FollowUpDue due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = today();
    return _PersonRow(
      name: due.contact.name,
      channel: due.thread?.channel,
      onTap: onTap,
      detail: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          StatusPill(due.why),
          StatusPill(
            due.due == now ? 'Due today' : 'Due ${relativeDay(due.due, now)}',
            status: followUpStatus(due.due, now),
          ),
        ],
      ),
    );
  }
}

/// A person's row in a Needs you card: their initials, name and channel,
/// with a line of detail under them.
class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.name, required this.channel, required this.onTap, this.detail});
  final String name;
  final String? channel;
  final VoidCallback onTap;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrgLogo(name, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (channel case final c?) ...[const SizedBox(width: 8), ChannelChip(c)],
                    ],
                  ),
                  if (detail case final d?) ...[const SizedBox(height: 4), d],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pace guard, when LinkedIn sending is busy or past the safe pace.
class _PaceHint extends StatelessWidget {
  const _PaceHint(this.pace);
  final Pace pace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = pace.level == PaceLevel.slowDown ? Status.serious : Status.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SpotlightCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.speed, color: status.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pace.advice, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    pace.summary,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
