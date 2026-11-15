// The post plan (schema 5): weekly slots, posts planned into them, due and
// posted, and the reminders the phone gets. A fake scheduler stands in for
// the notifications.
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/post_reminders.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/post_plan.dart';

import 'support.dart';

class FakePostReminders implements PostReminderScheduler {
  List<({DateTime at, String body})>? scheduled;
  @override
  bool get supported => true;
  @override
  Future<void> replaceAll(List<({DateTime at, String body})> items) async => scheduled = items;
}

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
  tearDown(() => book.db.close());

  // Wednesday 11 November 2026, 12:00.
  final now = DateTime(2026, 11, 11, 12);

  test('slots are kept in order, once each, and bad times refused', () async {
    await book.addPostSlot((day: 4, time: '08:30', channel: 'linkedin'));
    await book.addPostSlot((day: 2, time: '12:15', channel: 'linkedin'));
    await book.addPostSlot((day: 2, time: '08:00', channel: 'bluesky'));
    await book.addPostSlot((day: 2, time: '12:15', channel: 'linkedin'));
    expect(await book.postSlots(), [
      (day: 2, time: '08:00', channel: 'bluesky'),
      (day: 2, time: '12:15', channel: 'linkedin'),
      (day: 4, time: '08:30', channel: 'linkedin'),
    ]);
    expect(() => book.addPostSlot((day: 1, time: '8.30am', channel: 'linkedin')), throwsArgumentError);
    await book.removePostSlot((day: 2, time: '08:00', channel: 'bluesky'));
    expect(await book.postSlots(), hasLength(2));
  });

  test('a week is planned from the slots still to come, once', () async {
    await book.addPostSlot((day: 2, time: '08:30', channel: 'linkedin')); // Tuesday: passed
    await book.addPostSlot((day: 4, time: '08:30', channel: 'linkedin')); // Thursday
    await book.addPostSlot((day: 5, time: '17:00', channel: 'bluesky')); // Friday
    expect(weekStart(now), DateTime(2026, 11, 9));
    expect(await book.planWeek(now, now: now), 2);
    expect(await book.planWeek(now, now: now), 0);
    final posts = await book.postsBetween('2026-11-09', '2026-11-16');
    expect(
      [for (final p in posts) (p.at, p.channel, p.status)],
      [('2026-11-12T08:30', 'linkedin', 'planned'), ('2026-11-13T17:00', 'bluesky', 'planned')],
    );
    // Next week takes every slot.
    expect(await book.planWeek(DateTime(2026, 11, 16), now: now), 3);
  });

  test('due, posted with its link, skipped and planned again', () async {
    final id = await book.addPost(at: '2026-11-11T09:00', topic: 'EPR go-live lessons', body: 'Draft one');
    var p = await book.plannedPost(id);
    expect(postStatus(p, now), 'due');
    expect(postStatus(p, DateTime(2026, 11, 11, 8)), 'planned');

    await book.editPost(id, humanized: 'Draft one, humanized');
    expect(postText(await book.plannedPost(id)), 'Draft one, humanized');
    // A new draft drops the old humanized version.
    await book.editPost(id, body: 'Draft two');
    p = await book.plannedPost(id);
    expect((p.humanized, postText(p)), ('', 'Draft two'));

    await book.markPosted(id, url: 'https://www.linkedin.com/posts/example-123', at: now);
    p = await book.plannedPost(id);
    expect(
      (postStatus(p, now), p.postUrl, p.postedAt),
      ('posted', 'https://www.linkedin.com/posts/example-123', '2026-11-11T12:00'),
    );
    await book.reopenPost(id);
    expect((await book.plannedPost(id)).status, 'planned');
    await book.skipPost(id);
    expect(postStatus(await book.plannedPost(id), now), 'skipped');
    await book.deletePost(id);
    expect(await book.postsBetween('2026-11-09', '2026-11-16'), isEmpty);
  });

  test('reminders: one for each planned post still to come', () async {
    await book.addPost(at: '2026-11-11T09:00', body: 'Past');
    await book.addPost(at: '2026-11-13T08:30', topic: 'NHS digital week', body: 'Soon');
    final posted = await book.addPost(at: '2026-11-14T08:30', body: 'Already out');
    await book.markPosted(posted, at: now);
    await book.addPost(channel: 'bluesky', at: '2026-11-12T08:30', body: 'Bluesky one');
    final scheduler = FakePostReminders();
    await syncPostReminders(scheduler, book, now: now);
    expect(
      [for (final r in scheduler.scheduled!) (r.at, r.body)],
      [
        (DateTime(2026, 11, 12, 8, 30), 'Time to post on Bluesky.'),
        (DateTime(2026, 11, 13, 8, 30), 'Time to post on LinkedIn: NHS digital week'),
      ],
    );
  });

  test('a schema 4 database gains the post plan', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('DROP TABLE career_posts');
    await db.customStatement(
      "INSERT INTO career_contacts (id, hlc, deleted, name) VALUES ('c1', '', 0, 'Jordan Example')",
    );
    await db.customStatement('PRAGMA user_version = 4');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final b = CareerBook(await Store.open(db));
    expect((await db.select(db.careerContacts).getSingle()).name, 'Jordan Example');
    final id = await b.addPost(at: '2026-11-12T08:30', body: 'After the upgrade');
    expect((await b.plannedPost(id)).body, 'After the upgrade');
    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'career_posts_at'")
        .get();
    expect(indexes, hasLength(1));
    await db.close();
  });
}
