import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';

/// The Growth row kind for a to-do. A to-do is a plain career_growth row:
/// title, why (the notes), target (the due date, yyyy-MM-dd) and status
/// planned | doing | done.
const todoKind = 'task';

/// A to-do from the career file, before it is saved.
class SeedTodo {
  const SeedTodo({required this.id, required this.title, this.notes = '', this.due});
  final String id, title, notes;
  final String? due;

  /// The row id: fixed by the seed's id, so the same to-do on two devices
  /// is one row.
  String get rowId => 'todo.$id';

  /// What the file said, so a to-do is only rewritten when the file's
  /// version of it changes (and the user's own edits otherwise stand).
  String get fingerprint => 'seed:${_fnv('$title\u0000$notes\u0000${due ?? ''}')}';
}

String _fnv(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// Open to-dos first, those due soonest at the top (undated after dated),
/// then the done ones, latest first.
int compareTodos(GrowthItem a, GrowthItem b) {
  final ad = a.status == 'done', bd = b.status == 'done';
  if (ad != bd) return ad ? 1 : -1;
  if (ad) return (b.done ?? '').compareTo(a.done ?? '');
  final at = a.target ?? '', bt = b.target ?? '';
  if (at.isEmpty != bt.isEmpty) return at.isEmpty ? 1 : -1;
  final c = at.compareTo(bt);
  return c != 0 ? c : a.added.compareTo(b.added);
}

/// The candidate's to-do list.
extension TodoBook on CareerBook {
  /// Every to-do not deleted, in [compareTodos] order.
  Future<List<GrowthItem>> todos() async =>
      (await (db.select(db.careerGrowth)..where((g) => g.deleted.not() & g.kind.equals(todoKind))).get())
        ..sort(compareTodos);

  /// Adds a to-do (no [id]) or edits one. [due] is yyyy-MM-dd or null.
  Future<String> saveTodo({
    String? id,
    required String title,
    String notes = '',
    String? due,
    required String today,
  }) async {
    final rowId = id ?? newId();
    final known = id == null
        ? null
        : await (db.select(db.careerGrowth)..where((g) => g.id.equals(id))).getSingleOrNull();
    await save(
      db.careerGrowth,
      known == null
          ? CareerGrowthCompanion.insert(
              id: rowId,
              title: title.trim(),
              kind: todoKind,
              why: Value(notes.trim()),
              target: Value(due),
              status: const Value('planned'),
              added: today,
            )
          : known.copyWith(title: title.trim(), why: notes.trim(), target: Value(due)),
      rowId,
    );
    return rowId;
  }

  /// Ticks a to-do done, or opens it again.
  Future<void> setTodoDone(GrowthItem t, bool done, {required String today}) => save(
    db.careerGrowth,
    t.copyWith(status: done ? 'done' : 'planned', progress: done ? 100 : 0, done: Value(done ? today : null)),
    t.id,
  );

  /// Brings in to-dos from the career file, matched by their id: new ones
  /// are added; a known one takes the file's title, notes and due date only
  /// when the file's version changed. Never touches whether it is done, and
  /// never brings back one the user deleted. Returns how many it wrote.
  Future<int> importTodos(List<SeedTodo> seeds, {required String today}) => db.transaction(() async {
    var wrote = 0;
    for (final s in seeds) {
      if (s.id.trim().isEmpty || s.title.trim().isEmpty) continue;
      final known = await (db.select(db.careerGrowth)..where((g) => g.id.equals(s.rowId))).getSingleOrNull();
      if (known != null && (known.deleted || known.provider == s.fingerprint)) continue;
      await save(
        db.careerGrowth,
        known == null
            ? CareerGrowthCompanion.insert(
                id: s.rowId,
                title: s.title.trim(),
                kind: todoKind,
                why: Value(s.notes.trim()),
                target: Value(s.due),
                provider: Value(s.fingerprint),
                status: const Value('planned'),
                added: today,
              )
            : known.copyWith(
                title: s.title.trim(),
                why: s.notes.trim(),
                target: Value(s.due),
                provider: s.fingerprint,
              ),
        s.rowId,
      );
      wrote++;
    }
    return wrote;
  });
}
