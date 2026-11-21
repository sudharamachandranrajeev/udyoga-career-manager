import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/occupations.dart';
import '../domain/profile.dart';
import '../domain/role_family.dart';
import '../domain/saved_searches.dart';
import 'common.dart';
import 'kit/kit.dart';

/// The saved role searches on the Jobs page, as a row of chips: each with
/// how many listed jobs are new since it was last opened. Tap one to run
/// it in "Search job sites"; its menu edits, renames or deletes it. Shows
/// nothing while there are none.
class SavedSearchesRow extends ConsumerWidget {
  const SavedSearchesRow({super.key, required this.onOpen});

  /// Runs [SavedSearch] in search mode.
  final void Function(SavedSearch s) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searches = ref.watch(savedSearchesProvider).value ?? const <SavedSearch>[];
    if (searches.isEmpty) return const SizedBox.shrink();
    final jobs = ref.watch(jobsProvider).value ?? const [];
    final p = ref.watch(profileProvider).value ?? const CandidateProfile();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Subhead('Saved searches'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in searches)
                _SearchChip(
                  s,
                  fresh: s.newSinceLook(jobs, p),
                  onOpen: () => onOpen(s),
                  onMenu: () => _menu(context, ref, s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, SavedSearch s) async {
    final choice = await showSheet<String>(
      context,
      // Transparent material, for the list tiles' ink.
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            for (final (id, icon, label) in [
              ('open', Icons.search, 'Open and search now'),
              ('edit', Icons.edit_outlined, 'Edit or rename'),
              ('delete', Icons.delete_outline, 'Delete'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(context, id),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'open':
        onOpen(s);
      case 'edit':
        await editSavedSearch(context, ref, s);
      case 'delete':
        if (await confirm(
          context,
          title: 'Delete "${s.name}"?',
          message:
              'It is no longer checked on refresh, on any of your devices. Jobs already on your list stay.',
          action: 'Delete',
          destructive: true,
        )) {
          await ref.mutate((x) => x.book.removeSavedSearch(s.id));
        }
    }
  }
}

/// Edits [s]: its name, exact title only, NOT words, employers to leave out
/// and places. Turning "Exact title only" off on a search with no titles
/// yet switches on the role's close titles; open the search to choose
/// others.
Future<void> editSavedSearch(BuildContext context, WidgetRef ref, SavedSearch s) async {
  final name = TextEditingController(text: s.name);
  final notWords = TextEditingController(text: s.notWords.join(', '));
  final notEmployers = TextEditingController(text: s.notEmployers.join(', '));
  final places = TextEditingController(text: s.places.map((a) => a.line).join('\n'));
  var exactOnly = s.exactOnly;
  // Like the app's other forms, the fields go with the dialog.
  await showFormDialog(
    context,
    title: 'Edit saved search',
    fields: (setState) => [
      Field(name, 'Name', autofocus: true),
      Text('Role: ${s.role}', style: Theme.of(context).textTheme.bodySmall),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Exact title only'),
        subtitle: Text(
          exactOnly
              ? 'Only "${s.role}". Turn off to search the titles it goes by too.'
              : 'Also the titles switched on (${s.titles.isEmpty ? 'the close ones' : '${s.onTitles.length}'}). '
                    'Open the search to choose them.',
        ),
        value: exactOnly,
        onChanged: (v) => setState(() => exactOnly = v),
      ),
      Field(notWords, 'Leave out jobs that say', hint: 'senior, bank, locum'),
      Field(notEmployers, 'Leave out employers or agencies'),
      Field(
        places,
        'Places',
        lines: 2,
        helper: 'One per line: place | miles | commute towns. Leave empty to use your profile home areas.',
      ),
    ],
    onSave: () async {
      if (name.text.trim().isEmpty) return 'Give it a name.';
      var titles = s.titles;
      if (!exactOnly && titles.isEmpty) {
        final f = offlineFamily(s.role, index: await loadSocIndex());
        titles = [
          for (final t in f.titles)
            if (t.source != FamilySource.typed) SearchTitle(t, on: t.closeness == Closeness.close),
        ];
      }
      await ref.mutate(
        (x) => x.book.saveSearch(
          s.copyWith(
            name: name.text.trim(),
            titles: titles,
            exactOnly: exactOnly,
            notWords: linesIn(notWords),
            notEmployers: linesIn(notEmployers),
            places: [for (final l in places.text.split('\n')) ?HomeArea.parse(l.trim())],
            origin: SearchOrigin.user,
            updated: DateTime.now().toUtc().toIso8601String(),
          ),
        ),
      );
      return null;
    },
  );
}

/// One saved search: its name and new jobs; tap to run, menu to edit.
class _SearchChip extends StatelessWidget {
  const _SearchChip(this.search, {required this.fresh, required this.onOpen, required this.onMenu});
  final SavedSearch search;
  final int fresh;
  final VoidCallback onOpen, onMenu;

  @override
  Widget build(BuildContext context) {
    final s = search;
    final news = fresh == 0 ? 'Nothing new since you last looked' : '$fresh new since you last looked';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: InputChip(
        key: ValueKey('savedSearch.${s.id}'),
        avatar: Icon(s.exactOnly ? Icons.bookmark_outline : Icons.bookmarks_outlined, size: 18),
        label: Text(
          fresh > 0 ? '${s.name} · $fresh new' : s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        tooltip:
            '$news. ${s.exactOnly ? 'Exact title only.' : '${s.onTitles.length + 1} titles.'} Tap to search.',
        onPressed: onOpen,
        deleteIcon: const Icon(Icons.more_vert, size: 18),
        deleteButtonTooltipMessage: 'Edit or delete',
        onDeleted: onMenu,
      ),
    );
  }
}
