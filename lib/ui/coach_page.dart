import 'dart:convert';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/check_in_reminder.dart';
import '../app/providers.dart';
import '../db/database.dart';
import '../domain/companion.dart';
import '../domain/companion_book.dart';
import '../domain/evidence.dart';
import '../domain/json.dart';
import '../domain/vidya_link.dart';
import 'common.dart';
import 'story_editor.dart';

/// The candidate's coach: the daily check-in, questions that keep the
/// profile true, interview readiness from the story bank, and the documents
/// Udyoga reads.
class CoachPage extends ConsumerWidget {
  const CoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = today();
    final journal = ref.watch(journalProvider).value ?? const <CheckIn>[];
    final todays = journal.where((c) => c.day == day).firstOrNull;
    final questions = (ref.watch(questionsProvider).value ?? const <ProfileQuestion>[])
        .where((q) => q.status == 'open')
        .toList();
    final pending = (ref.watch(questionsProvider).value ?? const <ProfileQuestion>[])
        .where((q) => q.status == 'answered' && !q.applied)
        .length;
    final stories = ref.watch(storiesProvider).value ?? const <Story>[];
    return PageScaffold(
      title: 'Coach',
      banner: 'page.coach',
      children: [
        _CheckInCard(todays, key: ValueKey(todays?.id)),
        SectionCard(
          title: 'Confirm your profile',
          trailing: pending == 0
              ? null
              : FilledButton.tonalIcon(
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text('Update profile ($pending)'),
                  onPressed: () => _apply(context, ref),
                ),
          child: questions.isEmpty
              ? const Text(
                  'Nothing to confirm. Questions appear here when your documents disagree with each other or with '
                  'your profile.',
                )
              : Column(children: [for (final q in questions) _QuestionTile(q)]),
        ),
        _Readiness(stories),
        EvidenceCoverage(stories),
        _StoryBank(stories),
        const _Documents(),
        const _VidyaCard(),
        if (journal.any((c) => c.entry.isNotEmpty))
          SectionCard(
            title: 'Past check-ins',
            child: Column(
              children: [
                for (final c in journal.where((c) => c.entry.isNotEmpty).take(14))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.prompt),
                    subtitle: Text(
                      '${niceDate(c.day)}: ${c.entry}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final n = await runAi(
      context,
      title: 'Updating your profile',
      task: (_) async {
        final r = await (await companionOf(ref)).applyAnswers();
        ref.changed();
        return r;
      },
    );
    if (n != null && context.mounted) {
      showMessage(context, n == 0 ? 'Add an AI key in Settings first.' : 'Profile updated with $n answers.');
    }
  }
}

/// Today's question and the answer box.
class _CheckInCard extends ConsumerStatefulWidget {
  const _CheckInCard(this.checkIn, {super.key});
  final CheckIn? checkIn;

  @override
  ConsumerState<_CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<_CheckInCard> {
  late final answer = TextEditingController(text: widget.checkIn?.entry ?? '');
  var busy = false;

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => busy = true);
    try {
      await (await companionOf(ref)).today(today(), at: nowLocal());
      ref.changed();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save(CheckIn c) async {
    if (answer.text.trim().isEmpty) return;
    final digest = await runAi(
      context,
      title: 'Saving your check-in',
      status: 'Looking for stories and wins in your answer…',
      task: (_) async {
        final d = await (await companionOf(ref)).answer(c, answer.text, today: today(), at: nowLocal());
        ref.changed();
        ref.syncReminders().ignore();
        return d ?? const CheckInDigest();
      },
    );
    if (digest == null || !mounted) return;
    showMessage(
      context,
      digest.isEmpty
          ? 'Saved. Thank you.'
          : 'Saved: ${digest.stories.length} stories, ${digest.achievements.length} wins, '
                '${digest.skills.length} skills added for you to check.',
    );
    await ref.askForReminderOnce();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.checkIn;
    final settings = ref.watch(checkInSettingsProvider).value;
    final digest = c == null || c.digest.isEmpty ? null : CheckInDigest.fromJson(decodeObject(c.digest));
    final nudge = captureNudgeDue(ref.watch(storiesProvider).value ?? const [], today: today());
    return SectionCard(
      title: "Today's check-in",
      trailing: settings == null ? null : Text('Every day at ${settings.time}'),
      child: c == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wb_twilight_outlined),
                  label: const Text('How was your day?'),
                  onPressed: busy ? null : _start,
                ),
                if (nudge) CaptureStoryNudge(onTap: () => captureThisMonth(context, ref)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(c.prompt, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Field(
                  answer,
                  'Your answer',
                  lines: 4,
                  helper: 'A few sentences is plenty. Leave out patient and customer names.',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => _save(c),
                    child: Text(c.entry.isEmpty ? 'Save' : 'Save changes'),
                  ),
                ),
                if (digest != null && digest.summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(digest.summary, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (nudge) CaptureStoryNudge(onTap: () => captureThisMonth(context, ref)),
              ],
            ),
    );
  }
}

/// The monthly nudge (plan B5): no story was captured in the last 30 days,
/// so the check-in offers one from this month, while it is fresh. The
/// tile goes once the story is saved, so the page opens the editor from
/// its own context (see captureThisMonth), not the tile's.
class CaptureStoryNudge extends StatelessWidget {
  const CaptureStoryNudge({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: const ValueKey('capture-story-nudge'),
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.auto_stories_outlined),
    title: const Text('Capture a story from this month'),
    subtitle: const Text('No story in the last 30 days. Two minutes now saves an hour before an interview.'),
    onTap: onTap,
  );
}

/// Opens a new story dated this month (yyyy-MM).
Future<bool> captureThisMonth(BuildContext context, WidgetRef ref) =>
    editStory(context, ref, null, happened: today().substring(0, 7));

/// One question about the profile: pick a choice, type an answer or skip.
class _QuestionTile extends ConsumerWidget {
  const _QuestionTile(this.q);
  final ProfileQuestion q;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = decodeList(q.choices).whereType<String>().toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.question, style: Theme.of(context).textTheme.titleSmall),
          if (q.why.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(q.why, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in choices) ActionChip(label: Text(c), onPressed: () => _answer(ref, c)),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Type an answer'),
                onPressed: () => _type(context, ref),
              ),
              TextButton(
                onPressed: () => ref.mutate((s) => s.book.dismissQuestion(q, today: today())),
                child: const Text('Not relevant'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _answer(WidgetRef ref, String answer) =>
      ref.mutate((s) => s.book.answerQuestion(q, answer, today: today()));

  Future<void> _type(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController();
    await showFormDialog(
      context,
      title: q.topic,
      fields: (_) => [
        Text(q.question),
        const SizedBox(height: 12),
        Field(c, 'Answer', autofocus: true, lines: 2),
      ],
      onSave: () async {
        if (c.text.trim().isEmpty) return 'Type your answer, or press Cancel.';
        await _answer(ref, c.text);
        return null;
      },
    );
  }
}

/// How ready the candidate is to answer each competency at interview.
class _Readiness extends StatelessWidget {
  const _Readiness(this.stories);
  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    final counts = <String, ({int confirmed, int drafts})>{};
    for (final s in stories) {
      for (final c in CompanionBook.competenciesOf(s)) {
        final n = counts[c] ?? (confirmed: 0, drafts: 0);
        counts[c] = s.confirmed
            ? (confirmed: n.confirmed + 1, drafts: n.drafts)
            : (confirmed: n.confirmed, drafts: n.drafts + 1);
      }
    }
    final ready = readiness(counts);
    return SectionCard(
      title: 'Interview readiness',
      hint: 'coach.readiness',
      child: Column(
        children: [
          for (final e in ready.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(competencyNames[e.key]!)),
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      label: '${competencyNames[e.key]} ${e.value}% ready',
                      child: LinearProgressIndicator(value: e.value / 100, minHeight: 8),
                    ),
                  ),
                  SizedBox(width: 48, child: Text('${e.value}%', textAlign: TextAlign.end)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The candidate's stories: check each one, edit it, or remove it.
class _StoryBank extends ConsumerWidget {
  const _StoryBank(this.stories);
  final List<Story> stories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uses = ref.watch(storyUsesProvider).value ?? const <StoryUse>[];
    final day = today();
    return SectionCard(
      title: 'Your stories',
      trailing: IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'Capture a story',
        onPressed: () => editStory(context, ref, null),
      ),
      child: stories.isEmpty
          ? const Text(
              'Stories come from your check-ins and documents. Each one is an answer ready for interview.',
            )
          : Column(
              children: [
                for (final s in stories)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      s.confirmed ? Icons.verified_outlined : Icons.pending_outlined,
                      semanticLabel: s.confirmed ? 'Checked' : 'Draft',
                    ),
                    title: Text(s.title),
                    subtitle: Text(
                      [
                        CompanionBook.competenciesOf(s).map((c) => competencyNames[c]).join(', '),
                        if ((s.happened ?? '').isNotEmpty) niceDate(s.happened!),
                        if (tagsOf(s).isNotEmpty) '${tagsOf(s).length} standards',
                        if (s.source == 'practice') 'From practice',
                        if (decodeList(s.criteria).isNotEmpty)
                          'Evidenced: ${strs(decodeList(s.criteria)).join('; ')}',
                        if (usedInLines(uses, s.id) case final u when u.isNotEmpty) 'Used in: ${u.first}',
                        if (needsRefresh(s, today: day)) 'Over a year old: refresh the details',
                        if (!s.confirmed) 'Draft: check it is true as written',
                      ].where((t) => t.isNotEmpty).join(' · '),
                    ),
                    onTap: () => editStory(context, ref, s),
                  ),
              ],
            ),
    );
  }
}

/// Coverage of one framework (or a role's person specification): each item
/// with no story, some evidence, or two or more confirmed stories. A gap
/// opens a new story already tagged with it.
class EvidenceCoverage extends ConsumerStatefulWidget {
  const EvidenceCoverage(this.stories, {super.key});
  final List<Story> stories;

  @override
  ConsumerState<EvidenceCoverage> createState() => _EvidenceCoverageState();
}

class _EvidenceCoverageState extends ConsumerState<EvidenceCoverage> {
  String _framework = nhsValuesFramework.id;

  @override
  Widget build(BuildContext context) {
    final roles = roleFrameworks(ref.watch(roleProfilesProvider).value ?? const []);
    final all = [...evidenceFrameworks, competencyFramework, ...roles];
    final f = all.where((x) => x.id == _framework).firstOrNull ?? all.first;
    final muted = Theme.of(context).textTheme.bodySmall;
    final rows = coverageOf(f, widget.stories);
    final ready = rows.where((r) => r.level == CoverageLevel.ready).length;
    return SectionCard(
      title: 'Evidence coverage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Choice<String>(
            key: ValueKey('coverage-${f.id}'),
            label: 'Framework',
            value: f.id,
            options: {for (final x in all) x.id: x.name},
            onChanged: (v) => setState(() => _framework = v),
          ),
          if (f.about.isNotEmpty) Text(f.about, style: muted),
          if (f.note.isNotEmpty) Text(f.note, style: muted),
          Text('$ready of ${rows.length} ready. Tap a gap to add a story for it.', style: muted),
          const SizedBox(height: 4),
          for (final r in rows)
            ListTile(
              key: ValueKey('coverage-item-${r.item.id}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(switch (r.level) {
                CoverageLevel.none => Icons.radio_button_unchecked,
                CoverageLevel.some => Icons.timelapse_outlined,
                CoverageLevel.ready => Icons.check_circle_outline,
              }, semanticLabel: r.level.label),
              title: Text(r.item.title),
              subtitle: Text([if (r.item.area.isNotEmpty) r.item.area, r.summary].join(' · ')),
              trailing: r.level == CoverageLevel.ready ? null : const Icon(Icons.add),
              onTap: r.level == CoverageLevel.ready
                  ? null
                  : () => editStory(
                      context,
                      ref,
                      null,
                      tags: f.id == competencyFramework.id ? const [] : [StoryTag(f.id, r.item.id)],
                      competencies: f.id == competencyFramework.id ? [r.item.id] : const [],
                    ),
            ),
        ],
      ),
    );
  }
}

/// Folders on this device that Udyoga reads, and what it found in them.
class _Documents extends ConsumerWidget {
  const _Documents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(documentFoldersProvider).value ?? const <String>[];
    final docs = ref.watch(documentsProvider).value ?? const <CareerDocument>[];
    return SectionCard(
      title: 'Your documents',
      hint: 'coach.folders',
      trailing: folders.isEmpty
          ? null
          : FilledButton.tonalIcon(
              icon: const Icon(Icons.manage_search),
              label: const Text('Read now'),
              onPressed: () => _scan(context, ref, folders),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in folders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: Text(f),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Stop reading this folder',
                onPressed: () => ref.mutate((s) => s.book.setDocumentFolders([...folders]..remove(f))),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Add a folder'),
              onPressed: () async {
                final dir = await FilePicker.getDirectoryPath(dialogTitle: 'Folder with your documents');
                if (dir == null || folders.contains(dir)) return;
                await ref.mutate((s) => s.book.setDocumentFolders([...folders, dir]));
                if (context.mounted) await _scan(context, ref, [...folders, dir]);
              },
            ),
          ),
          if (docs.isNotEmpty) const Divider(),
          for (final d in docs)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: d.use,
              onChanged: (v) => ref.mutate((s) => s.book.setDocumentUse(d, v)),
              title: Text(d.name),
              subtitle: Text(
                d.analysed == null
                    ? 'Not read yet'
                    : '${documentKinds[d.kind] ?? d.kind}${d.summary.isEmpty ? '' : ': ${d.summary}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _scan(BuildContext context, WidgetRef ref, List<String> folders) async {
    final r = await runAi(
      context,
      title: 'Reading your documents',
      status: 'Looking through your folders…',
      task: (progress) async {
        final report = await (await companionOf(ref)).scan(folders, today: today(), onProgress: progress);
        ref.changed();
        return report;
      },
    );
    if (r != null && context.mounted) showMessage(context, r.summary);
  }
}

/// The plan as sent, and what Vidya reports, re-read after every write
/// and every sync that brings changes.
final _vidyaBridgeProvider = FutureProvider<(VidyaBridge, ({int learning, int skills}))>((ref) async {
  ref.watch(revisionProvider);
  final book = ref.watch(sessionProvider).book;
  final bridge = await book.vidyaBridge();
  return (bridge, await book.vidyaNew(bridge.done));
});

/// The link with Vidya: what to learn and rehearse goes out as a study
/// plan; what was finished there comes back.
class _VidyaCard extends ConsumerWidget {
  const _VidyaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(_vidyaBridgeProvider).value;
    final bridge = link?.$1;
    final fresh = link?.$2;
    return SectionCard(
      title: 'Learn and rehearse in Vidya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'A study plan for Vidya from what you still need: a story for each competency, the gaps in your job '
            'assessments and your planned learning. Your stories become review cards. When Udyoga and Vidya sync '
            'with the same account, Send to Vidya puts it there and what you finish comes back here. Without '
            'sync, save or copy the plan and use Import a study plan in Vidya.',
          ),
          if (bridge?.sent case final sent?) ...[
            const SizedBox(height: 8),
            Text(
              'Sent to Vidya ${niceDate(sent.substring(0, 10))}. '
              '${bridge!.added ? 'Vidya has added it.' : 'Vidya adds it when you open Vidya and accept it.'}',
            ),
          ],
          if (fresh != null && fresh.learning + fresh.skills > 0) ...[
            const SizedBox(height: 8),
            Text(
              'From Vidya: ${fresh.learning} finished, ${fresh.skills} new skill${fresh.skills == 1 ? '' : 's'} '
              'not on your profile yet.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.download_done),
                label: const Text('Add to my profile'),
                onPressed: () async {
                  final r = await ref.mutate((s) => s.book.importVidya(bridge!.done, today: today()));
                  if (context.mounted) {
                    showMessage(
                      context,
                      '${r.learning} finished on Growth, ${r.skills} skills added to your profile.',
                    );
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.send),
                label: Text(bridge?.sent == null ? 'Send to Vidya' : 'Send again'),
                onPressed: () async {
                  await ref.mutate((s) => s.book.sendToVidya(now: DateTime.now().toUtc().toIso8601String()));
                  if (!context.mounted) return;
                  showMessage(
                    context,
                    ref.read(syncProvider).phase == SyncPhase.signedOut
                        ? 'Kept for Vidya. It goes there once both apps sync with your account; until then, save '
                              'or copy the plan.'
                        : 'Sent. Vidya offers to add it the next time it opens.',
                  );
                },
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Save plan'),
                onPressed: () async {
                  final plan = await ref.read(sessionProvider).book.vidyaPlanNow();
                  if (!context.mounted) return;
                  await saveBytes(
                    context,
                    'udyoga-plan-${today()}.json',
                    Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(plan))),
                    mime: 'application/json',
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy plan'),
                onPressed: () async {
                  final plan = await ref.read(sessionProvider).book.vidyaPlanNow();
                  if (!context.mounted) return;
                  await copyText(context, jsonEncode(plan), what: 'Plan copied. Paste it into Vidya.');
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste what I finished'),
                onPressed: () => _import(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final text = TextEditingController();
    String? done;
    await showFormDialog(
      context,
      title: 'What you finished in Vidya',
      action: 'Import',
      fields: (_) => [
        const Text('In Vidya, open Portfolio and copy it as Markdown, then paste it here.'),
        Field(text, 'Vidya portfolio', lines: 8, autofocus: true),
      ],
      onSave: () async {
        final parsed = parseVidyaPortfolio(text.text);
        if (parsed.learning.isEmpty && parsed.skills.isEmpty) {
          return 'No finished learning or rated skills found. Paste the whole portfolio.';
        }
        final r = await ref.mutate((s) => s.book.importVidya(parsed, today: today()));
        done = '${r.learning} finished on Growth, ${r.skills} skills added to your profile.';
        return null;
      },
    );
    if (done != null && context.mounted) showMessage(context, done!);
  }
}
