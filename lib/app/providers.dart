import 'dart:async';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../domain/advisor.dart';
import '../domain/bluesky.dart';
import '../domain/book.dart';
import '../domain/ai.dart';
import '../domain/ats.dart';
import '../domain/background.dart';
import '../domain/claude.dart';
import '../domain/claude_code.dart';
import '../domain/codex.dart';
import '../domain/companion_service.dart';
import '../domain/conversations.dart';
import '../domain/employers.dart';
import '../domain/feeds.dart';
import '../domain/gemini.dart';
import '../domain/insights.dart';
import '../domain/linkedin_messages.dart';
import '../domain/mail.dart';
import '../domain/mail_sync.dart';
import '../domain/mail_transport.dart';
import '../domain/pay.dart';
import '../domain/profile.dart';
import '../domain/recipes.dart';
import '../domain/refresh.dart';
import '../domain/route_refresh.dart';
import '../domain/sponsors.dart';
import '../domain/n8n.dart';
import '../domain/subscription.dart';
import '../domain/update.dart';
import '../ui/hints.dart';
import 'mail_alerts.dart';
import 'security_checks.dart';
import 'session.dart';

/// The open session; main() overrides this before the first frame.
final sessionProvider = Provider<AppSession>((ref) => throw StateError('No session'));

/// HTTP for the AI and the job feeds; tests override it.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// The self-updater: main() sets it in a release build of the standalone app.
/// Null in the Brahma suite (which updates itself) and in tests.
final updaterProvider = Provider<Updater?>((ref) => null);

/// Set when the user asks for an update check, so one runs even with the
/// start-up check turned off.
class UpdateAsked extends Notifier<bool> {
  @override
  bool build() => false;
  void ask() => state = true;
}

final updateAskedProvider = NotifierProvider<UpdateAsked, bool>(UpdateAsked.new);

/// A newer release for this device, looked for once a run (at start unless
/// the user turned that off in Settings); null when this is the newest,
/// there is no updater, or nobody asked.
final updateProvider = FutureProvider<Release?>((ref) async {
  final updater = ref.watch(updaterProvider);
  if (updater == null) return null;
  if (!ref.watch(updateAskedProvider) && !await ref.read(sessionProvider).book.updateOnStart()) return null;
  return updater.check();
});

/// The CLIs that run the user's subscriptions, by service.
const subscriptionClis = <AiProvider, SubscriptionCli>{
  AiProvider.claudeCode: ClaudeCodeCli(),
  AiProvider.codex: CodexCli(),
};

/// Permission to use this device's CLI for a subscription, or null when
/// never given.
final grantProvider = FutureProvider.family<SubscriptionGrant?, AiProvider>((ref, p) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.grant(p);
});

/// What main() and the tests override: the session, under both its Udyoga
/// and its shared type, and the app's identity and hints.
List<Override> udyogaOverrides(AppSession session, {http.Client? client, Updater? updater}) => [
  sessionProvider.overrideWithValue(session),
  coreSessionProvider.overrideWithValue(session),
  appIdentityProvider.overrideWithValue(udyogaIdentity),
  hintTextsProvider.overrideWithValue({...coreHints, ...udyogaHints}),
  sentinelChecksProvider.overrideWithValue([...coreChecks, lockCheck, ...udyogaChecks]),
  if (client != null) httpClientProvider.overrideWithValue(client),
  if (updater != null) updaterProvider.overrideWithValue(updater),
];

extension Mutate on WidgetRef {
  /// Runs a write, refreshes the screens and queues a sync.
  Future<T> mutate<T>(Future<T> Function(AppSession s) write) async {
    final result = await write(read(sessionProvider));
    changed();
    return result;
  }
}

/// The rows of [table] that are not deleted, re-read after every write.
FutureProvider<List<D>> _rows<T extends SyncedRow, D>(
  TableInfo<T, D> Function(AppDatabase db) table, {
  List<OrderingTerm Function(T t)> orderBy = const [],
}) => FutureProvider<List<D>>((ref) {
  ref.watch(revisionProvider);
  final db = ref.watch(sessionProvider).db;
  final q = db.select(table(db))
    ..where((t) => t.deleted.not())
    ..orderBy(orderBy);
  return q.get();
});

final jobsProvider = _rows<$JobListingsTable, Job>(
  (db) => db.jobListings,
  orderBy: [(j) => OrderingTerm.desc(j.found), (j) => OrderingTerm.desc(j.fit)],
);

final applicationsProvider = _rows<$JobApplicationsTable, JobApplication>(
  (db) => db.jobApplications,
  orderBy: [(a) => OrderingTerm.desc(a.updated)],
);

final eventsProvider = _rows<$JobEventsTable, JobEvent>(
  (db) => db.jobEvents,
  orderBy: [(e) => OrderingTerm.desc(e.at)],
);

final checksProvider = _rows<$JobChecksTable, JobCheck>((db) => db.jobChecks);

final archiveProvider = _rows<$JobArchiveTable, Archived>(
  (db) => db.jobArchive,
  orderBy: [(a) => OrderingTerm.desc(a.at)],
);

final leadsProvider = _rows<$CareerContactsTable, Lead>(
  (db) => db.careerContacts,
  orderBy: [(c) => OrderingTerm(expression: c.name)],
);

final resumesProvider = _rows<$CareerResumesTable, Resume>(
  (db) => db.careerResumes,
  orderBy: [(r) => OrderingTerm.desc(r.created)],
);

final reportsProvider = _rows<$CareerReportsTable, Report>(
  (db) => db.careerReports,
  orderBy: [(r) => OrderingTerm.desc(r.created)],
);

final growthProvider = _rows<$CareerGrowthTable, GrowthItem>(
  (db) => db.careerGrowth,
  orderBy: [
    (g) => OrderingTerm(expression: g.status),
    (g) => OrderingTerm(expression: g.title),
  ],
);

final practiceProvider = _rows<$CareerPracticeTable, PracticeSession>(
  (db) => db.careerPractice,
  orderBy: [(p) => OrderingTerm.desc(p.started)],
);

final roleProfilesProvider = _rows<$CareerRoleProfilesTable, RoleProfileRow>(
  (db) => db.careerRoleProfiles,
  orderBy: [(p) => OrderingTerm.desc(p.updated)],
);

final processesProvider = _rows<$CareerProcessesTable, ProcessRow>(
  (db) => db.careerProcesses,
  orderBy: [(p) => OrderingTerm.desc(p.updated)],
);

final answersProvider = _rows<$CareerAnswersTable, PracticeAnswer>(
  (db) => db.careerAnswers,
  orderBy: [(a) => OrderingTerm(expression: a.question)],
);

final documentsProvider = _rows<$CareerDocumentsTable, CareerDocument>(
  (db) => db.careerDocuments,
  orderBy: [
    (d) => OrderingTerm.desc(d.found),
    (d) => OrderingTerm(expression: d.name),
  ],
);

final questionsProvider = _rows<$CareerQuestionsTable, ProfileQuestion>(
  (db) => db.careerQuestions,
  orderBy: [(q) => OrderingTerm(expression: q.asked)],
);

final journalProvider = _rows<$CareerJournalTable, CheckIn>(
  (db) => db.careerJournal,
  orderBy: [(c) => OrderingTerm.desc(c.day)],
);

final storiesProvider = _rows<$CareerStoriesTable, Story>(
  (db) => db.careerStories,
  orderBy: [
    (s) => OrderingTerm(expression: s.confirmed),
    (s) => OrderingTerm.desc(s.added),
  ],
);

final handlesProvider = _rows<$ContactHandlesTable, ContactHandle>((db) => db.contactHandles);

/// Every conversation with its person and newest message, newest first.
final threadRowsProvider = FutureProvider<List<ThreadRow>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.threadRows();
});

/// A thread's messages and notes, oldest first.
final threadMessagesProvider = FutureProvider.family<List<ThreadMessage>, String>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.messagesIn(id);
});

/// People to get back to today or earlier: thread follow-ups and "keep in
/// touch" dates (see [ConversationBook.dueFollowUps]).
final dueFollowUpsProvider = FutureProvider<List<FollowUpDue>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.dueFollowUps(today());
});

/// A thread another page asked the Conversations page to open, such as a
/// reply waiting on Today. The Conversations page opens it and clears it.
class OpenThread extends Notifier<String?> {
  @override
  String? build() => null;
  void open(String id) => state = id;
  void clear() => state = null;
}

final openThreadProvider = NotifierProvider<OpenThread, String?>(OpenThread.new);

/// What the user has sent by hand on LinkedIn lately (see [Pace]).
final paceProvider = FutureProvider<Pace>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.pace(DateTime.now());
});

/// Contact records that look like the same person.
final mergeSuggestionsProvider = FutureProvider<List<MergeSuggestion>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.mergeSuggestions();
});

/// First-degree connections at the employers the user is aiming for.
final knownAtTargetsProvider = FutureProvider<List<KnownAt>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.knownAtTargets();
});

/// The employers the user watches, by name.
final watchedEmployersProvider = FutureProvider<List<WatchedEmployer>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.watchedEmployers();
});

/// The job-feed keys, the device-only ones (USAJOBS, Jooble) included.
final feedKeysProvider = FutureProvider<FeedKeys>((ref) async {
  ref.watch(revisionProvider);
  final s = ref.watch(sessionProvider);
  return (await s.book.feedKeys()).withSecrets(s.keys.store);
});

final targetEmployersProvider = FutureProvider<List<String>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.targetEmployers();
});

/// IMAP and SMTP over the network; tests put a fake in its place.
final mailTransportProvider = Provider<MailTransport>((ref) => const EnoughMailTransport());

/// Connected mail accounts: settings on this device, passwords in its
/// keychain.
final mailServiceProvider = Provider<MailService>((ref) {
  final s = ref.watch(sessionProvider);
  return MailService(s.book, s.keys.store, ref.watch(mailTransportProvider));
});

final mailAccountsProvider = FutureProvider<List<ChannelAccount>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(mailServiceProvider).accounts();
});

/// Bluesky: search, posting and DMs with the user's app password.
final blueskyProvider = Provider<Bluesky>((ref) {
  final s = ref.watch(sessionProvider);
  return Bluesky(s.book, ref.watch(httpClientProvider), s.keys.store);
});

final blueskyAccountProvider = FutureProvider<BlueskyAccount?>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(blueskyProvider).account();
});

/// The channels Udyoga can send on by itself, once the user connects an
/// account (e-mail, Bluesky DMs). Empty until then: every message is sent
/// by the user and logged. LinkedIn never has one.
final channelSendersProvider = Provider<List<ChannelSender>>((ref) {
  final service = ref.watch(mailServiceProvider);
  final bluesky = ref.watch(blueskyAccountProvider).value;
  return [
    for (final a in ref.watch(mailAccountsProvider).value ?? const <ChannelAccount>[])
      EmailSender(service, a),
    if (bluesky != null && bluesky.dms) BlueskySender(ref.watch(blueskyProvider), bluesky),
  ];
});

class MailSyncState {
  const MailSyncState({this.running = false, this.status = ''});
  final bool running;
  final String status;
}

/// Checks the connected mail accounts and Bluesky DMs: at start and with
/// the hourly refresh when the last check is over 15 minutes old, or now
/// when the user asks.
class MailSyncController extends Notifier<MailSyncState> {
  @override
  MailSyncState build() => const MailSyncState();

  Future<MailSyncReport?> run({bool force = false}) async {
    if (state.running) return null;
    state = const MailSyncState(running: true, status: 'Checking messages…');
    try {
      final mail = await ref.read(mailServiceProvider).syncDue(force: force);
      // Bluesky DMs ride along; a Bluesky problem does not hide the mail.
      var dms = (added: 0, alerts: const <MailAlert>[]);
      String? bskyProblem;
      try {
        dms = await ref.read(blueskyProvider).syncDue(force: force);
      } catch (e) {
        bskyProblem = 'Bluesky: ${describeError(e)}';
      }
      final report = (
        added: mail.added + dms.added,
        alerts: [...mail.alerts, ...dms.alerts],
        failed: [...mail.failed, ?bskyProblem],
      );
      state = MailSyncState(
        status: [
          if (report.added == 0)
            'No new messages from your contacts.'
          else
            '${report.added} new message${report.added == 1 ? '' : 's'}.',
          ...report.failed,
        ].join('\n'),
      );
      ref.read(revisionProvider.notifier).bump();
      await ref.read(mailNotifierProvider).show(report.alerts).catchError((_) {});
      return report;
    } catch (e) {
      state = MailSyncState(status: describeError(e));
      ref.read(revisionProvider.notifier).bump();
      rethrow;
    }
  }
}

final mailSyncProvider = NotifierProvider<MailSyncController, MailSyncState>(MailSyncController.new);

/// The folders this device reads documents from.
final documentFoldersProvider = FutureProvider<List<String>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.documentFolders();
});

/// The check-in time on this device and whether it reminds.
final checkInSettingsProvider = FutureProvider<({String time, bool remind})>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.checkInSettings();
});

/// The companion with the user's adviser (or none: it still finds documents
/// and asks the built-in check-in questions).
Future<Companion> companionOf(WidgetRef ref) async =>
    Companion(ref.read(sessionProvider).book, advisor: await ref.read(advisorProvider.future));

final profileProvider = FutureProvider<CandidateProfile>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.profile();
});

/// The newest report of [kind] ('assessment', 'career_map'), or null.
final latestReportProvider = FutureProvider.family<Report?, String>((ref, kind) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.latestReport(kind);
});

/// The latest research on an employer, by name.
final employerBriefProvider = FutureProvider.family<EmployerBrief?, String>((ref, employer) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.employerBrief(employer);
});

/// The candidate's current pay and rent.
final payBaselineProvider = FutureProvider<PayBaseline>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.payBaseline();
});

/// The user's n8n lead workflow (not set until they connect one).
final n8nLinkProvider = FutureProvider<N8nLink>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.n8nLink();
});

/// The adviser with the user's model and its key, or null until a key is set.
final advisorProvider = FutureProvider<Advisor?>((ref) async {
  ref.watch(revisionProvider);
  return advisorFor(ref.watch(sessionProvider).book, ref.watch(httpClientProvider));
});

/// The adviser for [book]'s chosen model, or null without a key. Shared by
/// the app and the background refresh, which has no providers.
Future<Advisor?> advisorFor(CareerBook book, http.Client client) async {
  final keys = await book.aiKeys();
  final model = effectiveModel(await book.pref<String>(PrefKeys.aiModel, ''), keys);
  if (model == null) return null;
  final provider = AiProvider.of(model);
  final key = keys[provider]!;
  void onUsage(AiUsage u) => book.addSpend(u, month: today().substring(0, 7)).ignore();
  return Advisor(switch (provider) {
    AiProvider.claudeCode => ClaudeCode(grant: (await book.grant(provider))!, model: model),
    AiProvider.codex => Codex(grant: (await book.grant(provider))!, model: model),
    AiProvider.claude => Claude(apiKey: key, model: model, client: client, onUsage: onUsage),
    AiProvider.gemini => Gemini(apiKey: key, model: model, client: client, onUsage: onUsage),
  }, today: today());
}

/// The adviser, or an error telling the user to add a key.
Future<Advisor> requireAdvisor(WidgetRef ref) async {
  final advisor = await ref.read(advisorProvider.future);
  if (advisor == null) throw AiException(needsAiKey);
  return advisor;
}

class RefreshState {
  const RefreshState({this.running = false, this.status = '', this.last});
  final bool running;
  final String status;
  final RefreshReport? last;
}

/// The routine refresh (see Refresher), run at start-up, every few hours
/// while the app is open, and from the Jobs page.
class RefreshController extends Notifier<RefreshState> {
  @override
  RefreshState build() => const RefreshState();

  Future<RefreshReport?> run({bool force = false, bool ai = false}) async {
    if (state.running) return null;
    state = RefreshState(running: true, status: 'Starting…', last: state.last);
    // The background refresh may be running in another process.
    final lock = await ref.read(refreshLockProvider.future);
    if (lock != null && !await lock.acquire('app')) {
      state = RefreshState(
        status: 'A background refresh is running; the jobs it finds appear when it ends.',
        last: state.last,
      );
      return null;
    }
    try {
      final s = ref.read(sessionProvider);
      final client = ref.read(httpClientProvider);
      final report =
          await Refresher(
            s.book,
            client,
            advisor: await ref.read(advisorProvider.future),
            sponsors: await ref.read(sponsorStoreProvider.future),
            secrets: s.keys.store,
            watch: EmployerWatch(s.book, client),
            recipes: () => recipeFetchFor(s.db, client),
            routes: RouteRefresh(client, s.db),
          ).run(
            today: today(),
            force: force,
            ai: ai,
            onProgress: (m) {
              lock?.renew().ignore();
              state = RefreshState(running: true, status: m, last: state.last);
            },
          );
      state = RefreshState(last: report);
      ref.read(revisionProvider.notifier).bump();
      return report;
    } catch (e) {
      state = RefreshState(status: describeError(e), last: state.last);
      rethrow;
    } finally {
      await lock?.release();
    }
  }
}

final refreshProvider = NotifierProvider<RefreshController, RefreshState>(RefreshController.new);

/// The lock shared with the background refresh, or null where there is no
/// app folder (tests).
final refreshLockProvider = FutureProvider<RefreshLock?>((ref) async {
  try {
    return RefreshLock.inFolder((await getApplicationSupportDirectory()).path);
  } on Object {
    return null;
  }
});

/// The UK sponsor register's store on this device, or null where there is
/// no app folder (tests).
final sponsorStoreProvider = FutureProvider<SponsorStore?>((ref) async {
  final s = ref.watch(sessionProvider);
  try {
    final dir = await getApplicationSupportDirectory();
    return SponsorStore(
      Directory('${dir.path}${Platform.pathSeparator}sponsors'),
      ref.watch(httpClientProvider),
      s.db,
    );
  } on Object {
    return null;
  }
});

/// The cached register (null before its first download). Re-read after a
/// refresh; the store keeps it in memory until the file changes.
final sponsorRegisterProvider = FutureProvider<SponsorRegister?>((ref) async {
  ref.watch(revisionProvider);
  final store = await ref.watch(sponsorStoreProvider.future);
  try {
    return await store?.load();
  } on Object {
    return null;
  }
});

/// Runs the routine refresh and the mail check now and then hourly while
/// the app is open; each run does only what is due. Read once at start-up.
final refreshTickerProvider = Provider<void>((ref) {
  void tick() {
    ref.read(refreshProvider.notifier).run().catchError((_) => null).ignore();
    ref.read(mailSyncProvider.notifier).run().catchError((_) => null).ignore();
  }

  tick();
  final timer = Timer.periodic(const Duration(hours: 1), (_) => tick());
  ref.onDispose(timer.cancel);
});
