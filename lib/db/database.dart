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
    'prefs',
  ];

  @override
  int get schemaVersion => 2;

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
    },
  );

  static const _indexes = [
    'CREATE INDEX job_listings_source ON job_listings (source, source_id)',
    'CREATE INDEX job_events_application ON job_events (application_id)',
    'CREATE INDEX career_answers_session ON career_answers (session_id)',
    'CREATE INDEX career_reports_kind ON career_reports (kind, created)',
    ..._v2Indexes,
  ];

  /// Added in schema 2 (pre-employment checks and the archive).
  static const _v2Indexes = [
    'CREATE INDEX job_checks_application ON job_checks (application_id)',
    'CREATE INDEX job_archive_application ON job_archive (application_id)',
  ];
}
