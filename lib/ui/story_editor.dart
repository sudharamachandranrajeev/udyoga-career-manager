/// Capturing and editing a story (plan A4): the STAR fields, when it
/// happened, the competencies and the framework standards it shows, and
/// where it has been used.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/companion.dart';
import '../domain/companion_book.dart';
import '../domain/evidence.dart';
import 'common.dart';

/// Opens the story [s] to edit, or a new one when null. A new story can
/// start with [tags] and [competencies] already chosen, e.g. from a gap in
/// a coverage map, and with [happened] in place of today (e.g. this month,
/// yyyy-MM, from the monthly nudge). Returns true when it was saved.
Future<bool> editStory(
  BuildContext context,
  WidgetRef ref,
  Story? s, {
  List<StoryTag> tags = const [],
  List<String> competencies = const [],
  String? happened,
}) async {
  final day = today();
  final title = TextEditingController(text: s?.title ?? '');
  final happenedField = TextEditingController(text: s == null ? happened ?? day : (s.happened ?? ''));
  final situation = TextEditingController(text: s?.situation ?? '');
  final task = TextEditingController(text: s?.task ?? '');
  final action = TextEditingController(text: s?.action ?? '');
  final result = TextEditingController(text: s?.result ?? '');
  final chosen = {...?(s == null ? null : CompanionBook.competenciesOf(s)), ...competencies};
  final tagged = {...?(s == null ? null : tagsOf(s)), ...tags};
  final roles = roleFrameworks(ref.read(roleProfilesProvider).value ?? const []);
  final used = s == null
      ? const <String>[]
      : usedInLines(ref.read(storyUsesProvider).value ?? const [], s.id);
  final frameworks = [...evidenceFrameworks, ...roles];
  return showFormDialog(
    context,
    title: s == null ? 'Capture a story' : 'Story',
    action: s == null || !s.confirmed ? 'Save as checked' : 'Save',
    fields: (setState) => [
      Field(title, 'Title', autofocus: s == null),
      Field(
        happenedField,
        'When it happened',
        hint: 'yyyy-mm-dd or yyyy-mm',
        helper: 'Capture it while it is fresh: the details fade within weeks.',
      ),
      if (s != null && needsRefresh(s.copyWith(happened: Value(happenedField.text.trim())), today: day))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.history_outlined, size: 18),
              const SizedBox(width: 6),
              const Expanded(child: Text(refreshHint)),
            ],
          ),
        ),
      Field(situation, 'Situation', lines: 2),
      Field(task, 'Task', lines: 2),
      Field(action, 'What you did', lines: 3),
      Field(result, 'Result', lines: 2, helper: 'Figures only if you are sure of them.'),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in competencyNames.entries)
            FilterChip(
              label: Text(e.value),
              selected: chosen.contains(e.key),
              onSelected: (v) => setState(() => v ? chosen.add(e.key) : chosen.remove(e.key)),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text('Standards it shows', style: Theme.of(context).textTheme.titleSmall),
      for (final f in frameworks)
        ExpansionTile(
          key: ValueKey('tags-${f.id}'),
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: tagged.any((t) => t.framework == f.id),
          title: Text(f.name),
          subtitle: Text(
            [
              if (f.note.isNotEmpty) f.note,
              '${tagged.where((t) => t.framework == f.id).length} chosen',
            ].join(' · '),
          ),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in f.items)
                  FilterChip(
                    label: Text(i.title),
                    selected: tagged.contains(StoryTag(f.id, i.id)),
                    onSelected: (v) => setState(
                      () => v ? tagged.add(StoryTag(f.id, i.id)) : tagged.remove(StoryTag(f.id, i.id)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      if (used.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Used in', style: Theme.of(context).textTheme.titleSmall),
        for (final l in used) Text(l),
      ],
      if (s != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove this story'),
            onPressed: () async {
              await ref.mutate((x) => x.book.remove(x.db.careerStories, s.id));
              if (context.mounted) Navigator.pop(context, false);
            },
          ),
        ),
    ],
    onSave: () async {
      if (title.text.trim().isEmpty || action.text.trim().isEmpty) {
        return 'A title and what you did, please.';
      }
      final when = happenedField.text.trim();
      if (when.isNotEmpty && !validStoryDate(when)) return 'Write the date as yyyy-mm-dd or yyyy-mm.';
      if (when.compareTo(day) > 0) return 'The date it happened is in the future.';
      final fields = (
        title: title.text.trim(),
        situation: situation.text.trim(),
        task: task.text.trim(),
        action: action.text.trim(),
        result: result.text.trim(),
        competencies: jsonEncode(chosen.toList()),
        tags: encodeTags(tagged),
        happened: when.isEmpty ? null : when,
      );
      if (s == null) {
        final id = newId();
        await ref.mutate(
          (x) => x.book.save(
            x.db.careerStories,
            CareerStoriesCompanion.insert(
              id: id,
              title: fields.title,
              situation: Value(fields.situation),
              task: Value(fields.task),
              action: Value(fields.action),
              result: Value(fields.result),
              competencies: Value(fields.competencies),
              tags: Value(fields.tags),
              happened: Value(fields.happened),
              confirmed: const Value(true),
              added: day,
            ),
            id,
          ),
        );
      } else {
        await ref.mutate(
          (x) => x.book.saveStory(
            s.copyWith(
              title: fields.title,
              situation: fields.situation,
              task: fields.task,
              action: fields.action,
              result: fields.result,
              competencies: fields.competencies,
              tags: fields.tags,
              happened: Value(fields.happened),
              confirmed: true,
            ),
          ),
        );
      }
      return null;
    },
  );
}

/// The story as plain text, ready to paste into a form.
String storyText(Story s) => [
  if (s.situation.isNotEmpty) s.situation,
  if (s.task.isNotEmpty) s.task,
  s.action,
  if (s.result.isNotEmpty) s.result,
].join(' ');
