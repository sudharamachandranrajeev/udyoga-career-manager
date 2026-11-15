import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'json.dart';

// The post plan: weekly slots (a day and a time), a draft in each, and a
// reminder when the time comes. LinkedIn posts are copied and posted by
// the user on LinkedIn's own share page (its API terms forbid automated
// posting); Bluesky posts go out only when the user presses Post.

/// The weekly slots, a synced pref: [{"day": 1, "time": "08:30",
/// "channel": "linkedin"}], day 1 being Monday.
const postSlotsKey = 'udyoga.posts.slots';

/// LinkedIn's page for writing a post. The text goes on the clipboard
/// first; LinkedIn has no documented way to fill it in.
const linkedInShareUrl = 'https://www.linkedin.com/feed/?shareActive=true';

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// A weekly time to post.
typedef PostSlot = ({int day, String time, String channel});

/// planned | due | posted | skipped: a planned post is due once its time
/// has come.
String postStatus(PlannedPost p, DateTime now) =>
    p.status == 'planned' && p.at.compareTo(_stamp(now)) <= 0 ? 'due' : p.status;

/// The text to post: the humanized draft when there is one.
String postText(PlannedPost p) => p.humanized.trim().isNotEmpty ? p.humanized.trim() : p.body.trim();

String _stamp(DateTime t) => t.toIso8601String().substring(0, 16);

/// "08:30" as minutes, or null when it is not a time.
int? _minutes(String time) {
  final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(time.trim());
  return m == null ? null : int.parse(m[1]!) * 60 + int.parse(m[2]!);
}

/// The Monday of [day]'s week.
DateTime weekStart(DateTime day) => DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// When [slot] falls in the week starting [monday].
DateTime slotTime(DateTime monday, PostSlot slot) {
  final m = _minutes(slot.time) ?? 0;
  return DateTime(monday.year, monday.month, monday.day + slot.day - 1, m ~/ 60, m % 60);
}

/// A reminder for each planned post still to come, soonest first, at most
/// [limit] (the phone keeps a short list).
List<({DateTime at, String body})> postReminders(List<PlannedPost> posts, DateTime now, {int limit = 20}) {
  final soon = [
    for (final p in posts)
      if (p.status == 'planned' && !p.deleted)
        if (DateTime.tryParse(p.at) case final at? when at.isAfter(now)) (at: at, p: p),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final s in soon.take(limit))
      (
        at: s.at,
        body: s.p.topic.trim().isNotEmpty
            ? 'Time to post on ${_channel(s.p.channel)}: ${s.p.topic.trim()}'
            : 'Time to post on ${_channel(s.p.channel)}.',
      ),
  ];
}

String _channel(String c) => c == 'bluesky' ? 'Bluesky' : 'LinkedIn';

extension PostPlan on CareerBook {
  Future<List<PostSlot>> postSlots() async {
    final raw = await pref<List<dynamic>>(postSlotsKey, const []);
    return [
      for (final j in raw.map(obj))
        if (_minutes(str(j['time'])) != null &&
            j['day'] is int &&
            (j['day'] as int) >= 1 &&
            (j['day'] as int) <= 7)
          (
            day: j['day'] as int,
            time: str(j['time']),
            channel: str(j['channel']) == 'bluesky' ? 'bluesky' : 'linkedin',
          ),
    ]..sort(
      (a, b) => a.day != b.day ? a.day.compareTo(b.day) : _minutes(a.time)!.compareTo(_minutes(b.time)!),
    );
  }

  Future<void> setPostSlots(List<PostSlot> slots) => setPref(postSlotsKey, [
    for (final s in slots) {'day': s.day, 'time': s.time, 'channel': s.channel},
  ]);

  /// Adds a weekly slot. Throws when the time is not HH:mm.
  Future<void> addPostSlot(PostSlot slot) async {
    if (_minutes(slot.time) == null) throw ArgumentError('Enter the time as HH:mm, like 08:30.');
    final all = await postSlots();
    if (all.any((s) => s.day == slot.day && s.time == slot.time && s.channel == slot.channel)) return;
    await setPostSlots([...all, slot]);
  }

  Future<void> removePostSlot(PostSlot slot) async => setPostSlots([
    for (final s in await postSlots())
      if (s != slot) s,
  ]);

  /// The posts from [from] to before [to] (YYYY-MM-DD), by time.
  Future<List<PlannedPost>> postsBetween(String from, String to) =>
      (db.select(db.careerPosts)
            ..where((p) => p.deleted.not() & p.at.isBiggerOrEqualValue(from) & p.at.isSmallerThanValue(to))
            ..orderBy([(p) => OrderingTerm(expression: p.at)]))
          .get();

  /// Every post still planned (for the reminders).
  Future<List<PlannedPost>> plannedPosts() =>
      (db.select(db.careerPosts)..where((p) => p.deleted.not() & p.status.equals('planned'))).get();

  Future<PlannedPost> plannedPost(String id) =>
      (db.select(db.careerPosts)..where((p) => p.id.equals(id))).getSingle();

  /// Puts a planned post in each weekly slot of the week starting [monday]
  /// that has none yet (slots already past are left out). Returns how many.
  Future<int> planWeek(DateTime monday, {required DateTime now}) async {
    final start = weekStart(monday);
    final have = await postsBetween(
      _stamp(start).substring(0, 10),
      _stamp(start.add(const Duration(days: 7))).substring(0, 10),
    );
    var added = 0;
    for (final s in await postSlots()) {
      final at = slotTime(start, s);
      if (!at.isAfter(now)) continue;
      if (have.any((p) => p.at == _stamp(at) && p.channel == s.channel)) continue;
      await addPost(channel: s.channel, at: _stamp(at));
      added++;
    }
    return added;
  }

  Future<String> addPost({
    String channel = 'linkedin',
    required String at,
    String topic = '',
    String body = '',
  }) async {
    final id = newId();
    await save(
      db.careerPosts,
      CareerPostsCompanion.insert(
        id: id,
        channel: Value(channel),
        at: at,
        topic: Value(topic.trim()),
        body: Value(body.trim()),
      ),
      id,
    );
    return id;
  }

  /// Changes a post's draft or time. A new [body] clears an old humanized
  /// version unless one comes with it.
  Future<void> editPost(
    String id, {
    String? topic,
    String? body,
    String? humanized,
    String? at,
    String? channel,
  }) async {
    final p = await plannedPost(id);
    await save(
      db.careerPosts,
      p.copyWith(
        topic: topic?.trim() ?? p.topic,
        body: body?.trim() ?? p.body,
        humanized: humanized?.trim() ?? (body != null && body.trim() != p.body ? '' : p.humanized),
        at: at ?? p.at,
        channel: channel ?? p.channel,
      ),
      id,
    );
  }

  /// The user posted it (by hand on LinkedIn, or with Post on Bluesky).
  Future<void> markPosted(String id, {String url = '', required DateTime at}) async {
    final p = await plannedPost(id);
    await save(
      db.careerPosts,
      p.copyWith(
        status: 'posted',
        postUrl: url.trim().isEmpty ? p.postUrl : url.trim(),
        postedAt: Value(_stamp(at)),
      ),
      id,
    );
  }

  Future<void> skipPost(String id) async {
    final p = await plannedPost(id);
    await save(db.careerPosts, p.copyWith(status: 'skipped'), id);
  }

  /// Back to planned (an accidental Posted or Skip).
  Future<void> reopenPost(String id) async {
    final p = await plannedPost(id);
    await save(db.careerPosts, p.copyWith(status: 'planned', postedAt: const Value(null)), id);
  }

  Future<void> deletePost(String id) => remove(db.careerPosts, id);
}
