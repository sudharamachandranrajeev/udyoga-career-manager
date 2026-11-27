/// Stories for a supporting statement (plan A4): for each criterion of a
/// role profile, the stories that fit best, on this device and without an
/// AI. Using one copies it, tags it with the criterion and logs where it
/// went, with a warning when the same employer has already seen it.
library;

import 'package:brahma_core/brahma_core.dart' show SectionCard;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interview_engine/interview_engine.dart' show RoleProfile;

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/companion_book.dart';
import '../domain/evidence.dart';
import 'common.dart';
import 'story_editor.dart';

class StatementEvidenceCard extends ConsumerWidget {
  const StatementEvidenceCard(this.profile, {super.key});

  /// A saved role profile ([RoleProfile.id] not empty).
  final RoleProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider).value ?? const <Story>[];
    final uses = ref.watch(storyUsesProvider).value ?? const <StoryUse>[];
    final f = personSpecFramework(profile);
    final muted = Theme.of(context).textTheme.bodySmall;
    return SectionCard(
      title: 'Stories for your supporting statement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'For each criterion, the stories that fit best: tagged ones first, then by shared words. Use one to '
            'copy it and note where it went, so you do not give the same employer the same story twice.',
            style: muted,
          ),
          for (final c in profile.criteria) ...[
            const SizedBox(height: 10),
            Text(c.text, style: Theme.of(context).textTheme.titleSmall),
            ...() {
              final item = f.item(c.id)!;
              final found = suggestStories(item, stories, framework: f);
              if (found.isEmpty) {
                return [
                  Text('No story fits this yet.', style: muted),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey('add-story-${c.id}'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add a story for this'),
                      onPressed: () => editStory(context, ref, null, tags: [StoryTag(f.id, c.id)]),
                    ),
                  ),
                ];
              }
              return [
                for (final x in found)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(x.story.title),
                    subtitle: Text(
                      [
                        if (x.tagged) 'Tagged for this' else 'Shares ${x.overlap} key words',
                        if (!x.story.confirmed) 'draft',
                        if (earlierUsesWith(
                          uses,
                          storyId: x.story.id,
                          employer: profile.employer,
                          refId: profile.id,
                          criterion: c.text,
                        ).isNotEmpty)
                          'already used with ${profile.employer}',
                      ].join(' · '),
                    ),
                    trailing: PopupMenuButton<String>(
                      key: ValueKey('use-${c.id}-${x.story.id}'),
                      tooltip: 'Use this story',
                      icon: const Icon(Icons.playlist_add_check),
                      onSelected: (kind) => _use(context, ref, x.story, c.id, c.text, f.id, kind),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'statement', child: Text('Use in the supporting statement')),
                        PopupMenuItem(value: 'interview', child: Text('Use at interview')),
                      ],
                    ),
                  ),
              ];
            }(),
          ],
        ],
      ),
    );
  }

  Future<void> _use(
    BuildContext context,
    WidgetRef ref,
    Story s,
    String criterionId,
    String criterion,
    String frameworkId,
    String kind,
  ) async {
    final warning = await ref.mutate((x) async {
      final w = await x.book.useStory(
        s,
        kind: kind,
        refId: profile.id,
        employer: profile.employer,
        role: profile.title,
        criterion: criterion,
        at: nowLocal(),
      );
      await x.book.tagStory(s, StoryTag(frameworkId, criterionId));
      return w;
    });
    if (!context.mounted) return;
    await copyText(context, storyText(s), what: 'Copied "${s.title}" for this criterion.');
    if (warning != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Used with this employer before'),
          content: Text(warning),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }
}
