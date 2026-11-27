import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    JobListings,
    JobApplications,
    JobEvents,
    JobChecks,
    JobArchive,
    CareerContacts,
    CareerResumes,
    CareerReports,
    CareerGrowth,
    CareerPractice,
    CareerAnswers,
    CareerDocuments,
    CareerQuestions,
    CareerJournal,
    CareerStories,
    CareerStoryUses,
    ContactHandles,
    Conversations,
    Messages,
    CareerPosts,
    CareerTracks,
    CareerRoleProfiles,
    CareerProcesses,
    BridgeStudyPlans,
    BridgeStudyProgress,
    CareerFileDocs,
    CareerSavedSearches,
    CareerRoleInsights,
    Prefs,
    Outbox,
    SyncCursors,
    LocalSettings,
  ],
)
class AppDatabase extends _$AppDatabase with SyncedDatabase {
  AppDatabase(super.e);

  /// Opens Udyoga's encrypted database (see [openEncryptedDatabase]).
  AppDatabase.open(String key) : this(openEncryptedDatabase('udyoga', key));

  @override
  final syncedTables = const [
    'job_listings',
    'job_applications',
    'job_events',
    'job_checks',
    'job_archive',
    'career_contacts',
    'career_resumes',
    'career_reports',
    'career_growth',
    'career_practice',
    'career_answers',
    'career_documents',
    'career_questions',
    'career_journal',
    'career_stories',
    'career_story_uses',
    'career_handles',
    'career_conversations',
    'career_messages',
    'career_posts',
    'career_tracks',
    'career_role_profiles',
    'career_processes',
    'bridge_study_plans',
    'bridge_study_progress',
    'career_file_docs',
    'career_saved_searches',
    'career_role_insights',
    'prefs',
  ];

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final sql in _indexes) {
        await customStatement(sql);
      }
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(jobChecks);
        await m.createTable(jobArchive);
        for (final sql in _v2Indexes) {
          await customStatement(sql);
        }
      }
      if (from < 3) {
        await m.createTable(careerDocuments);
        await m.createTable(careerQuestions);
        await m.createTable(careerJournal);
        await m.createTable(careerStories);
        for (final sql in _v3Indexes) {
          await customStatement(sql);
        }
      }
      if (from < 4) {
        // Only the columns not there yet, so a half-finished upgrade can run
        // again.
        final have = await customSelect('PRAGMA table_info(career_contacts)')
            .map((r) => r.read<String>('name'))
            .get();
        for (final c in [
          careerContacts.sourceUrl,
          careerContacts.sourceKind,
          careerContacts.foundOn,
          careerContacts.basis,
          careerContacts.basisNote,
          careerContacts.doNotContact,
          careerContacts.keepInTouchWeeks,
        ]) {
          if (!have.contains(c.name)) await m.addColumn(careerContacts, c);
        }
        await m.createTable(contactHandles);
        await m.createTable(conversations);
        await m.createTable(messages);
        for (final sql in _v4Indexes) {
          await customStatement(sql);
        }
      }
      if (from < 5) {
        await m.createTable(careerPosts);
        for (final sql in _v5Indexes) {
          await customStatement(sql);
        }
      }
      if (from < 6) {
        // createTable is CREATE TABLE IF NOT EXISTS, so this can run again.
        await m.createTable(bridgeStudyPlans);
        await m.createTable(bridgeStudyProgress);
      }
      if (from < 7) {
        // Who set each job's fit, so a profile change redoes only the
        // offline scores. Only if not there yet, so it can run again.
        final have = await customSelect('PRAGMA table_info(job_listings)')
            .map((r) => r.read<String>('name'))
            .get();
        if (!have.contains(jobListings.fitBy.name)) await m.addColumn(jobListings, jobListings.fitBy);
        await customStatement("UPDATE job_listings SET fit_by = 'ai' WHERE assessment != ''");
      }
      if (from < 8) {
        // Route tracks (Explore). CREATE TABLE IF NOT EXISTS, so it can run again.
        await m.createTable(careerTracks);
        for (final sql in _v8Indexes) {
          await customStatement(sql);
        }
      }
      if (from < 9) {
        // Interview I3: role profiles, saved processes, the debrief and the
        // criteria a practice story evidenced. Only what is not there yet,
        // so it can run again.
        await m.createTable(careerRoleProfiles);
        await m.createTable(careerProcesses);
        Future<void> add(TableInfo t, String table, List<GeneratedColumn> cols) async {
          final have = await customSelect('PRAGMA table_info($table)')
              .map((r) => r.read<String>('name'))
              .get();
          for (final c in cols) {
            if (!have.contains(c.name)) await m.addColumn(t, c);
          }
        }

        await add(careerPractice, 'career_practice', [careerPractice.profileId, careerPractice.debrief]);
        await add(careerStories, 'career_stories', [careerStories.criteria]);
      }
      if (from < 10) {
        // Interview I4: nerves before and after a round. Only if missing.
        final have = await customSelect('PRAGMA table_info(career_practice)')
            .map((r) => r.read<String>('name'))
            .get();
        for (final c in [careerPractice.nervesBefore, careerPractice.nervesAfter]) {
          if (!have.contains(c.name)) await m.addColumn(careerPractice, c);
        }
      }
      if (from < 11) {
        // The synced career file. CREATE TABLE IF NOT EXISTS, so it can run again.
        await m.createTable(careerFileDocs);
      }
      if (from < 12) {
        // Saved role searches. CREATE TABLE IF NOT EXISTS, so it can run again.
        await m.createTable(careerSavedSearches);
      }
      if (from < 13) {
        // Role insights. CREATE TABLE IF NOT EXISTS, so it can run again.
        await m.createTable(careerRoleInsights);
      }
      if (from < 14) {
        // Evidence tags (A4): framework tags and the date a story happened,
        // and where each story was used. Only what is missing, so it can
        // run again.
        final have = await customSelect('PRAGMA table_info(career_stories)')
            .map((r) => r.read<String>('name'))
            .get();
        for (final c in [careerStories.tags, careerStories.happened]) {
          if (!have.contains(c.name)) await m.addColumn(careerStories, c);
        }
        await m.createTable(careerStoryUses);
        await customStatement(_v14Index);
      }
    },
    // The background refresh opens the same file from another process (or
    // isolate) while the app may be open: wait for the other's write to end
    // instead of failing with "database is locked".
    beforeOpen: (_) => customStatement('PRAGMA busy_timeout = 10000'),
  );

  static const _indexes = [
    'CREATE INDEX IF NOT EXISTS job_listings_source ON job_listings (source, source_id)',
    'CREATE INDEX IF NOT EXISTS job_events_application ON job_events (application_id)',
    'CREATE INDEX IF NOT EXISTS career_answers_session ON career_answers (session_id)',
    'CREATE INDEX IF NOT EXISTS career_reports_kind ON career_reports (kind, created)',
    ..._v2Indexes,
    ..._v3Indexes,
    ..._v4Indexes,
    ..._v5Indexes,
    ..._v8Indexes,
    _v14Index,
  ];

  /// Added in schema 14 (story uses).
  static const _v14Index =
      'CREATE INDEX IF NOT EXISTS career_story_uses_story ON career_story_uses (story_id)';

  /// Added in schema 8 (route tracks).
  static const _v8Indexes = ['CREATE INDEX IF NOT EXISTS career_tracks_country ON career_tracks (country)'];

  /// Added in schema 2 (pre-employment checks and the archive).
  static const _v2Indexes = [
    'CREATE INDEX IF NOT EXISTS job_checks_application ON job_checks (application_id)',
    'CREATE INDEX IF NOT EXISTS job_archive_application ON job_archive (application_id)',
  ];

  /// Added in schema 3 (documents, profile questions, check-ins, stories).
  static const _v3Indexes = [
    'CREATE INDEX IF NOT EXISTS career_documents_hash ON career_documents (hash)',
    'CREATE INDEX IF NOT EXISTS career_journal_day ON career_journal (day)',
    'CREATE INDEX IF NOT EXISTS career_questions_status ON career_questions (status)',
  ];

  /// Added in schema 4 (conversations, handles and messages).
  static const _v4Indexes = [
    'CREATE INDEX IF NOT EXISTS career_handles_contact ON career_handles (contact_id)',
    'CREATE INDEX IF NOT EXISTS career_conversations_contact ON career_conversations (contact_id)',
    'CREATE INDEX IF NOT EXISTS career_conversations_last ON career_conversations (last_at)',
    'CREATE INDEX IF NOT EXISTS career_messages_conversation ON career_messages (conversation_id, sent_at)',
  ];

  /// Added in schema 5 (the post plan).
  static const _v5Indexes = ['CREATE INDEX IF NOT EXISTS career_posts_at ON career_posts (at)'];
}
