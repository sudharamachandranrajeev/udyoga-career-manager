import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/json.dart';
import '../domain/todos.dart';
import 'common.dart';

/// The to-dos among the Growth rows, in [compareTodos] order.
List<GrowthItem> todosIn(List<GrowthItem> growth) =>
    growth.where((g) => g.kind == todoKind).toList()..sort(compareTodos);

/// Open, and due on or before [day].
bool isDue(GrowthItem t, String day) =>
    t.status != 'done' && t.target != null && t.target!.compareTo(day) <= 0;

/// One to-do: a tick box, its title, and when it is due.
class TodoTile extends ConsumerWidget {
  const TodoTile(this.t, {super.key});
  final GrowthItem t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = today();
    final done = t.status == 'done';
    final overdue = !done && t.target != null && t.target!.compareTo(now) < 0;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final due = t.target;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: done,
        semanticLabel: done ? 'Mark "${t.title}" not done' : 'Mark "${t.title}" done',
        onChanged: (v) => ref.mutate((s) => s.book.setTodoDone(t, v ?? false, today: now)),
      ),
      title: Text(
        t.title,
        style: done ? TextStyle(decoration: TextDecoration.lineThrough, color: muted) : null,
      ),
      subtitle: due == null && t.why.isEmpty
          ? null
          : Text(
              [
                if (due != null)
                  done
                      ? 'Was due ${niceDate(due)}'
                      : overdue
                      ? 'Overdue: was due ${niceDate(due)} (${relativeDay(due, now)})'
                      : 'Due ${niceDate(due)} (${relativeDay(due, now)})',
                if (t.why.isNotEmpty) t.why,
              ].join('\n'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: overdue ? TextStyle(color: Status.serious.color) : null,
            ),
      onTap: () => editTodo(context, ref, t),
    );
  }
}

/// Adds a to-do (no [t]) or edits one.
Future<void> editTodo(BuildContext context, WidgetRef ref, [GrowthItem? t]) {
  final title = TextEditingController(text: t?.title ?? '');
  final notes = TextEditingController(text: t?.why ?? '');
  final due = TextEditingController(text: t?.target ?? '');
  return showFormDialog(
    context,
    title: t == null ? 'Add a to-do' : 'To-do',
    fields: (_) => [
      Field(title, 'What to do', autofocus: t == null),
      Field(due, 'Due', hint: '2026-12-01', helper: 'yyyy-mm-dd; empty for no date'),
      Field(notes, 'Notes', lines: 3),
      if (t != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await ref.mutate((s) => s.book.remove(s.db.careerGrowth, t.id));
              if (context.mounted) Navigator.of(context, rootNavigator: true).pop(false);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ),
    ],
    onSave: () async {
      if (title.text.trim().isEmpty) return 'Say what to do.';
      final d = due.text.trim();
      if (d.isNotEmpty && !isDay(d)) {
        return 'Write the due date as yyyy-mm-dd.';
      }
      await ref.mutate(
        (s) => s.book.saveTodo(
          id: t?.id,
          title: title.text,
          notes: notes.text,
          due: d.isEmpty ? null : d,
          today: today(),
        ),
      );
      return null;
    },
  );
}

/// The to-do list as a card: open ones first (due and overdue at the top),
/// [limit] at most, and an Add button. With [showDone], the done ones follow.
class TodoCard extends ConsumerWidget {
  const TodoCard(this.todos, {super.key, this.limit, this.showDone = false, this.onMore});
  final List<GrowthItem> todos;
  final int? limit;
  final bool showDone;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = todos.where((t) => showDone || t.status != 'done').toList();
    final cut = limit == null ? shown : shown.take(limit!).toList();
    return SectionCard(
      title: 'To-do',
      hint: 'todos',
      trailing: TextButton(onPressed: () => editTodo(context, ref), child: const Text('Add to-do')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shown.isEmpty) const Text('Nothing to do. Add anything you need to remember, with a date.'),
          for (final t in cut) TodoTile(t, key: ValueKey(t.id)),
          if (cut.length < shown.length && onMore != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onMore,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text('See all ${shown.length}'),
              ),
            ),
        ],
      ),
    );
  }
}
