/// "Stories used" on a tailored CV (plan B5): tick the stories the draft
/// drew on, so the usage log knows which employer has seen which story.
/// Stories whose distinctive phrases appear in the draft are ticked to
/// start with. Everything runs on the device; no AI is needed.
library;

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/companion_book.dart';
import '../domain/evidence.dart';
import 'common.dart';

class StoriesUsedCard extends ConsumerWidget {
  const StoriesUsedCard({super.key, required this.resume, required this.cv, required this.letter});

  final Resume resume;

  /// The CV as text, and the cover letter or supporting statement ('' if none).
  final String cv, letter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider).value ?? const <Story>[];
    final uses = [
      for (final u in ref.watch(storyUsesProvider).value ?? const <StoryUse>[])
        if (u.refId == resume.id && (u.kind == 'cv' || u.kind == 'statement')) u,
    ];
    final byId = {for (final s in stories) s.id: s};
    final job = resume.jobId == null
        ? null
        : (ref.watch(jobsProvider).value ?? const <Job>[]).where((j) => j.id == resume.jobId).firstOrNull;
    final muted = Theme.of(context).textTheme.bodySmall;
    return SectionCard(
      title: 'Stories used',
      trailing: stories.isEmpty
          ? null
          : TextButton(
              key: const ValueKey('stories-used-pick'),
              onPressed: () => _pick(context, ref, stories, uses, job),
              child: Text(uses.isEmpty ? 'Choose' : 'Change'),
            ),
      child: stories.isEmpty
          ? Text('Add stories on the Coach page; then note here which ones this draft used.', style: muted)
          : uses.isEmpty
          ? Text(
              'Tick the stories this draft drew on, so you do not give the same employer the same story twice.',
              style: muted,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final u in uses)
                  if (byId[u.storyId] case final s?)
                    Text('${s.title} · ${storyUseKinds[u.kind] ?? u.kind}', key: ValueKey('used-${s.id}')),
              ],
            ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    List<Story> stories,
    List<StoryUse> logged,
    Job? job,
  ) async {
    final draft = '$cv\n$letter';
    final kinds = <String, String>{for (final u in logged) u.storyId: u.kind};
    final ticked = logged.isNotEmpty
        ? {for (final u in logged) u.storyId}
        : {
            for (final s in stories)
              if (draftDrawsOn(s, draft)) s.id,
          };
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Stories this draft used'),
          content: SizedBox(
            width: 480,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  logged.isEmpty
                      ? 'Ticked: the stories whose phrases appear in the draft. Change them if they are wrong.'
                      : 'Tick or untick the stories this draft used.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                for (final s in stories)
                  CheckboxListTile(
                    key: ValueKey('story-used-${s.id}'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: ticked.contains(s.id),
                    title: Text(s.title),
                    subtitle: s.confirmed ? null : const Text('draft'),
                    onChanged: (v) => setState(() => v == true ? ticked.add(s.id) : ticked.remove(s.id)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final warnings = await ref.mutate(
      (x) => x.book.saveDraftUses(
        {
          for (final s in stories)
            if (ticked.contains(s.id)) s: kinds[s.id] ?? draftUseKind(s, letter: letter),
        },
        refId: resume.id,
        employer: job?.company ?? '',
        role: job?.title ?? '',
        at: nowLocal(),
      ),
    );
    if (!context.mounted) return;
    if (warnings.isEmpty) {
      showMessage(
        context,
        ticked.isEmpty ? 'No stories noted for this draft.' : 'Noted the stories this draft used.',
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Used with this employer before'),
        content: Text(warnings.join('\n\n')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}
