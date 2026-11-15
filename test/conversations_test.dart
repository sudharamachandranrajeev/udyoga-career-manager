// Conversations (schema 4): threads on every channel, contact provenance
// and the compliance tools. Every person here is made up.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';

void main() {
  test('a schema 3 database gains conversations and keeps its contacts', () async {
    final dir = await Directory.systemTemp.createTemp('udyoga_migrate');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    // Back to schema 3: no conversation tables, no provenance columns.
    for (final t in ['career_handles', 'career_conversations', 'career_messages']) {
      await db.customStatement('DROP TABLE $t');
    }
    for (final c in [
      'source_url',
      'source_kind',
      'found_on',
      'basis',
      'basis_note',
      'do_not_contact',
      'keep_in_touch_weeks',
    ]) {
      await db.customStatement('ALTER TABLE career_contacts DROP COLUMN $c');
    }
    await db.customStatement(
      "INSERT INTO career_contacts (id, hlc, deleted, name, kind, title, company, email, phone, linkedin, "
      "source, status, last_contact, follow_up, notes) VALUES ('c1', '', 0, 'Jordan Example', 'recruiter', "
      "'Talent Partner', 'Example Health Trust', 'jordan@example.org', '', '', 'Team page', 'contacted', "
      "'2026-10-01', '2026-10-08', 'Met at a careers fair')",
    );
    await db.customStatement('PRAGMA user_version = 3');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'career_%'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, containsAll(['career_handles', 'career_conversations', 'career_messages']));
    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'career_%'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(
      indexes,
      containsAll([
        'career_handles_contact',
        'career_conversations_contact',
        'career_conversations_last',
        'career_messages_conversation',
      ]),
    );
    final c = await db.select(db.careerContacts).getSingle();
    expect(
      (c.name, c.company, c.email, c.status),
      ('Jordan Example', 'Example Health Trust', 'jordan@example.org', 'contacted'),
    );
    expect((c.lastContact, c.followUp, c.notes), ('2026-10-01', '2026-10-08', 'Met at a careers fair'));
    expect(
      (c.sourceKind, c.basis, c.doNotContact, c.keepInTouchWeeks, c.sourceUrl),
      ('other', 'legitimate_interest', false, null, ''),
    );
    expect(await db.select(db.conversations).get(), isEmpty);
    await db.close();
  });
}
