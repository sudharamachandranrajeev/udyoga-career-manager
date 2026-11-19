import 'dart:convert';

import 'package:brahma_core/brahma_core.dart'
    hide Release, UpdateException, checksumsName, updaterProvider, addMonths;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'eligibility.dart' show addMonths;
import 'explore.dart';
import 'json.dart';
import 'todos.dart';

/// One dated step on a route track.
class Milestone {
  const Milestone({required this.id, required this.title, this.due, this.done, this.todo});
  final String id, title;

  /// yyyy-MM-dd, or null when undated.
  final String? due;

  /// The day it was done, or null.
  final String? done;

  /// The to-do made from it, by row id.
  final String? todo;

  bool get isDone => done != null;

  Json toJson() => {'id': id, 'title': title, 'due': due, 'done': done, 'todo': todo};

  factory Milestone.fromJson(Json j) {
    String? day(Object? v) => isDay(str(v)) ? str(v) : null;
    return Milestone(
      id: str(j['id']),
      title: str(j['title']),
      due: day(j['due']),
      done: day(j['done']),
      todo: str(j['todo']).isEmpty ? null : str(j['todo']),
    );
  }

  Milestone copyWith({String? title, Value<String?>? due, Value<String?>? done, Value<String?>? todo}) =>
      Milestone(
        id: id,
        title: title ?? this.title,
        due: due == null ? this.due : due.value,
        done: done == null ? this.done : done.value,
        todo: todo == null ? this.todo : todo.value,
      );
}

/// The milestones stored on a track, by due date (undated last).
List<Milestone> milestonesOf(RouteTrack t) {
  final list = decodeList(t.milestones)
      .map((e) => Milestone.fromJson(obj(e)))
      .where((m) => m.id.isNotEmpty)
      .toList();
  list.sort((a, b) {
    if ((a.due == null) != (b.due == null)) return a.due == null ? 1 : -1;
    return (a.due ?? '').compareTo(b.due ?? '');
  });
  return list;
}

String _encode(List<Milestone> ms) => jsonEncode([for (final m in ms) m.toJson()]);

String _minus(String day, int days) {
  final d = DateTime.parse(day).subtract(Duration(days: days));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _earliest(String a, String? b) => b != null && b.compareTo(a) < 0 ? b : a;

/// A first track for a screened country: its trigger and the milestones
/// that follow from the screen, dated back from the earliest deadline (the
/// route's cut-off, or the person's right to work ending). The person
/// edits them after.
({String title, String routeId, String trigger, List<Milestone> milestones}) suggestTrack(
  CountryScreen s, {
  required String today,
  String? rightEnds,
}) {
  final name = s.country.name;
  final route = s.routes.where((r) => r.fit == RouteFit.fits).firstOrNull ?? s.routes.firstOrNull;
  final horizon = _earliest(addMonths(today, 6), _earliest(s.deadline ?? '9999-12-31', rightEnds));
  final ms = <Milestone>[];
  var n = 0;
  void add(String title, String? due) => ms.add(Milestone(id: 'm${++n}', title: title, due: due));
  switch (s.tier) {
    case Tier.ready:
      add('Shortlist ten openings in $name', _earliest(addMonths(today, 1), horizon));
      add('Apply to five of them', _earliest(addMonths(today, 2), horizon));
    case Tier.possible || Tier.later:
      for (final b in s.blockers.where((b) => b.contains('B2'))) {
        add('Reach B2 in the language: ${b.split(';').first}', horizon);
      }
      if (route != null && route.route.sponsored) {
        add(
          'List employers in $name that sponsor ${route.route.name}',
          _earliest(addMonths(today, 1), horizon),
        );
        add('Apply to five sponsored roles', _earliest(addMonths(today, 2), horizon));
        if (s.deadline != null) add('Offer and certificate or permit issued', _minus(s.deadline!, 1));
      } else if (route != null) {
        add(
          'Check the ${route.route.name} requirements on the official page',
          _earliest(addMonths(today, 1), horizon),
        );
      } else {
        add('Run the AI assessment for $name', addMonths(today, 1));
      }
    case Tier.blocked:
      add('Look again when the rules change', addMonths(today, 6));
  }
  if (rightEnds != null && s.basis == null) add('Your current right to work ends', rightEnds);
  final trigger = switch (s.tier) {
    Tier.ready => 'You may work in $name now.',
    Tier.possible =>
      route?.floor != null
          ? 'An offer at or above ${route!.floor!.label} under ${route.route.name}.'
          : 'An offer under ${route?.route.name ?? 'a work route'}.',
    Tier.later =>
      s.blockers.isNotEmpty ? 'Once this is solved: ${s.blockers.first}' : 'Once the route is verified.',
    Tier.blocked => 'A change in the rules.',
  };
  return (
    title: '$name: ${route?.route.name ?? 'work route'}',
    routeId: route?.route.id ?? '',
    trigger: trigger,
    milestones: ms,
  );
}

/// The person's route tracks.
extension TrackBook on CareerBook {
  /// Every track not deleted, active first, then by when added.
  Future<List<RouteTrack>> tracks() async {
    final all = await (db.select(db.careerTracks)..where((t) => t.deleted.not())).get();
    const order = ['active', 'paused', 'done', 'dropped'];
    return all..sort((a, b) {
      final s = order.indexOf(a.status).compareTo(order.indexOf(b.status));
      return s != 0 ? s : a.added.compareTo(b.added);
    });
  }

  /// Adds a track (no [id]) or edits one.
  Future<String> saveTrack({
    String? id,
    required String country,
    required String title,
    String routeId = '',
    String trigger = '',
    String status = 'active',
    String notes = '',
    List<Milestone>? milestones,
    required String today,
  }) async {
    final rowId = id ?? newId();
    final known = id == null
        ? null
        : await (db.select(db.careerTracks)..where((t) => t.id.equals(id))).getSingleOrNull();
    await save(
      db.careerTracks,
      known == null
          ? CareerTracksCompanion.insert(
              id: rowId,
              country: country,
              title: title.trim(),
              routeId: Value(routeId),
              trigger: Value(trigger.trim()),
              status: Value(status),
              notes: Value(notes.trim()),
              milestones: Value(_encode(milestones ?? const [])),
              added: today,
            )
          : known.copyWith(
              title: title.trim(),
              trigger: trigger.trim(),
              status: status,
              notes: notes.trim(),
              milestones: milestones == null ? null : _encode(milestones),
            ),
      rowId,
    );
    return rowId;
  }

  Future<void> deleteTrack(String id) => remove(db.careerTracks, id);

  Future<void> _setMilestones(RouteTrack t, List<Milestone> ms) =>
      save(db.careerTracks, t.copyWith(milestones: _encode(ms)), t.id);

  /// Adds or edits a milestone on [t].
  Future<void> saveMilestone(RouteTrack t, Milestone m) {
    final ms = milestonesOf(t);
    final i = ms.indexWhere((x) => x.id == m.id);
    i < 0 ? ms.add(m) : ms[i] = m;
    return _setMilestones(t, ms);
  }

  Future<void> deleteMilestone(RouteTrack t, String milestoneId) =>
      _setMilestones(t, milestonesOf(t)..removeWhere((m) => m.id == milestoneId));

  /// Ticks a milestone done or open again, and its to-do with it.
  Future<void> setMilestoneDone(RouteTrack t, Milestone m, bool done, {required String today}) async {
    await saveMilestone(t, m.copyWith(done: Value(done ? today : null)));
    if (m.todo == null) return;
    final todo = await (db.select(db.careerGrowth)..where((g) => g.id.equals(m.todo!))).getSingleOrNull();
    if (todo != null && !todo.deleted) await setTodoDone(todo, done, today: today);
  }

  /// Makes a to-do from a milestone (once); returns its row id.
  Future<String> milestoneTodo(RouteTrack t, Milestone m, {required String today}) async {
    if (m.todo != null) {
      final known = await (db.select(db.careerGrowth)..where((g) => g.id.equals(m.todo!))).getSingleOrNull();
      if (known != null && !known.deleted) return m.todo!;
    }
    final id = await saveTodo(
      id: 'todo.track.${t.id}.${m.id}',
      title: m.title,
      notes: '${t.title}${t.trigger.isEmpty ? '' : '. Trigger: ${t.trigger}'}',
      due: m.due,
      today: today,
    );
    await saveMilestone(t, m.copyWith(todo: Value(id)));
    return id;
  }
}

/// Open milestones with a date on active tracks, soonest first, for Today.
List<({RouteTrack track, Milestone milestone})> trackDeadlines(List<RouteTrack> tracks) {
  final out = [
    for (final t in tracks)
      if (t.status == 'active' && !t.deleted)
        for (final m in milestonesOf(t))
          if (!m.isDone && m.due != null) (track: t, milestone: m),
  ];
  out.sort((a, b) => a.milestone.due!.compareTo(b.milestone.due!));
  return out;
}
