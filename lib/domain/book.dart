import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';
import 'package:interview_engine/interview_engine.dart' show CoachPrefs, InterviewDevice, RoundSettings;

import '../db/database.dart';
import 'ai.dart';
import 'companion_book.dart';
import 'conversations.dart';
import 'eligibility.dart';
import 'feeds.dart';
import 'insights.dart';
import 'job_identity.dart';
import 'json.dart';
import 'linkedin_export.dart';
import 'linkedin_messages.dart';
import 'matching.dart';
import 'n8n.dart';
import 'pay.dart';
import 'pipeline.dart';
import 'profile.dart';
import 'resume.dart';
import 'saved_searches.dart';
import 'subscription.dart';
import 'vidya_link.dart';
import 'work_rights.dart';

/// Pref keys. The prefs table is shared by every Brahma app, so Udyoga's
/// keys carry its prefix.
abstract final class PrefKeys {
  static const profile = 'udyoga.profile';

  /// The Claude API key (named before Gemini joined).
  static const aiKey = 'udyoga.ai.key';
  static const geminiKey = 'udyoga.ai.gemini';
  static const aiModel = 'udyoga.ai.model';

  /// How often the AI looks for jobs and refreshes the career map on its own:
  /// off | weekly | daily.
  static const aiRoutine = 'udyoga.ai.routine';
  static const feedKeys = 'udyoga.feeds';

  /// The user's n8n lead workflow: {"url": ..., "secret": ...}.
  static const n8n = 'udyoga.n8n';

  /// How the user writes on LinkedIn: their notes and a few past posts.
  static const linkedInVoice = 'udyoga.linkedin.voice';

  /// The candidate's current pay and rent, for the pay change on each job.
  static const pay = 'udyoga.pay';

  /// Passports, rights to work and languages (WorkRights), apart from the
  /// profile so reading a CV never wipes them.
  static const rights = 'udyoga.rights';

  /// Which device runs the AI routine, and until when: {"device": id,
  /// "until": ISO time, "ran": ISO time of the last successful run}. Synced,
  /// so only one device spends on it.
  static const aiLease = 'udyoga.ai.lease';

  /// True once the profile's search terms have become saved searches
  /// (lib/domain/saved_searches.dart). Synced, so it runs on one device.
  static const searchesMoved = 'udyoga.searches.moved';
}

/// Device-only settings (local_settings).
abstract final class LocalKeys {
  static const feedsChecked = 'udyoga.feeds.checked';
  static const aiChecked = 'udyoga.ai.checked';

  /// Spend this month: {"month": "2026-10", "dollars": 1.23}.
  static const spend = 'udyoga.ai.spend';

  /// Permission to use this device's Claude Code or Codex
  /// (SubscriptionGrant), or '', by subscription.
  static const grants = {AiProvider.claudeCode: 'udyoga.ai.claude_code', AiProvider.codex: 'udyoga.ai.codex'};

  /// 'off' when Udyoga should not look for a new version at start.
  static const updateOnStart = 'udyoga.update.on_start';

  /// Folders on this device to read documents from, JSON list of paths.
  static const documentFolders = 'udyoga.documents.folders';

  /// The daily check-in time on this device, HH:mm, and whether to remind.
  static const checkInTime = 'udyoga.checkin.time';
  static const checkInReminder = 'udyoga.checkin.reminder';

  /// Set once the phone has been asked to allow the reminder.
  static const checkInAsked = 'udyoga.checkin.asked';

  /// The fingerprint of the career file's settings last applied here, so
  /// the profile takes the file's values only when the file changes.
  static const careerFile = 'udyoga.careerfile.applied';

  /// The spoken round's settings on this device (RoundSettings as JSON).
  static const roundSettings = 'udyoga.interview.round';

  /// The camera coach's switches on this device (CoachPrefs as JSON): self-
  /// view and the two round hints. Settings only; the camera is still off
  /// at the start of every session, and nothing it sees is stored.
  static const coachPrefs = 'udyoga.interview.coach';

  /// Offline practice, the local AI and live captions on this device
  /// (InterviewDevice as JSON).
  static const interviewDevice = 'udyoga.interview.device';
}

/// Udyoga's write path and the reads screens share.
class CareerBook {
  CareerBook(this.store);
  final Store store;

  AppDatabase get db => store.db as AppDatabase;

  Future<T> pref<T>(String key, T fallback) async {
    final row = await (db.select(db.prefs)..where((p) => p.id.equals(key))).getSingleOrNull();
    if (row == null || row.deleted) return fallback;
    final v = jsonDecode(row.value);
    return v is T ? v : fallback;
  }

  Future<void> setPref(String key, Object value) => store.save(
    db.prefs,
    PrefsCompanion.insert(id: key, value: jsonEncode(value), deleted: const Value(false)),
    key,
  );

  /// The profile, with the candidate's ideas and wins from the Growth page
  /// as [CandidateProfile.notes], their story bank and the facts they have
  /// confirmed, so every AI request knows them.
  Future<CandidateProfile> profile() async =>
      CandidateProfile.fromJson(await pref<Map<String, Object?>>(PrefKeys.profile, const {})).copyWith(
        notes: [
          for (final n in await notes())
            '${noteKinds[n.kind]}: ${n.title}${n.why.isEmpty ? '' : ' (${n.why})'}'
                '${n.url.isEmpty ? '' : ' ${n.url}'}',
        ],
        stories: [for (final s in await stories()) CompanionBook.storyLine(s)],
        confirmed: [for (final q in await questions(status: 'answered')) '${q.topic}: ${q.answer}'],
        rights: await workRights(),
      );

  /// Passports, rights to work and languages.
  Future<WorkRights> workRights() async =>
      WorkRights.fromJson(await pref<Map<String, Object?>>(PrefKeys.rights, const {}));

  /// Saves them and rescores the jobs, since eligibility changed.
  Future<void> saveWorkRights(WorkRights r) async {
    await setPref(PrefKeys.rights, r.toJson());
    await rescoreJobs();
  }

  /// The candidate's ideas and wins, newest first.
  Future<List<GrowthItem>> notes() =>
      (db.select(db.careerGrowth)
            ..where((g) => g.deleted.not() & g.kind.isIn(noteKinds.keys))
            ..orderBy([(g) => OrderingTerm.desc(g.added)]))
          .get();

  /// Saves an idea or win: new without [id].
  Future<void> saveNote({
    String? id,
    required String kind,
    required String title,
    String detail = '',
    String url = '',
    required String added,
  }) {
    final rowId = id ?? newId();
    return save(
      db.careerGrowth,
      CareerGrowthCompanion.insert(
        id: rowId,
        title: title,
        kind: kind,
        why: Value(detail),
        url: Value(url),
        status: const Value('planned'),
        added: added,
      ),
      rowId,
    );
  }

  /// Brings a LinkedIn export into every part of the app it helps: the
  /// profile (filled in, never overwritten), held certifications and
  /// recommendations on the Growth page, contacts at the employers the user
  /// is pursuing (and recruiters), recent applications and saved jobs, and
  /// the messages and connection requests as imported conversations.
  Future<LinkedInImport> importLinkedIn(LinkedInExport x, {required String today}) async {
    final before = await profile();
    final after = x.mergeInto(before);
    await saveProfile(after);
    final held = await recordHeld(after.certifications, today: today);

    var wins = 0;
    final known = {for (final n in await notes()) n.title.toLowerCase()};
    for (final r in x.recommendations) {
      final text = col(r, 'text');
      if (text.isEmpty || col(r, 'status').toLowerCase() == 'hidden') continue;
      final from = [col(r, 'first name'), col(r, 'last name')].where((s) => s.isNotEmpty).join(' ');
      final role = [col(r, 'job title'), col(r, 'company')].where((s) => s.isNotEmpty).join(', ');
      final title =
          'Recommendation from ${from.isEmpty ? 'a colleague' : from}${role.isEmpty ? '' : ' ($role)'}';
      if (!known.add(title.toLowerCase())) continue;
      final on = linkedInDate(col(r, 'creation date'));
      await saveNote(kind: 'win', title: title, detail: text, added: on.length == 10 ? on : today);
      wins++;
    }

    final applications = await (db.select(db.jobApplications)..where((a) => a.deleted.not())).get();
    final applied = {for (final a in applications) _key(a.title, a.company)};
    var sent = 0;
    for (final r in x.recentApplications(today: today)) {
      final title = col(r, 'job title');
      final company = col(r, 'company name');
      if (!applied.add(_key(title, company))) continue;
      final date = linkedInDate(col(r, 'application date'));
      final on = date.length == 10 ? date : today;
      final id = newId();
      await save(
        db.jobApplications,
        JobApplicationsCompanion.insert(
          id: id,
          title: title,
          company: Value(company),
          url: Value(col(r, 'job url')),
          stage: Value(Stage.applied.id),
          applied: Value(on),
          followUp: Value(followUpFor(Stage.applied, on)),
          notes: const Value('Applied through LinkedIn.'),
          updated: on,
        ),
        id,
      );
      sent++;
    }

    final saved = await importPostings(x.savedPostings(today: today), after, today: today);
    for (final id in saved) {
      await setJobStatus(id, 'saved');
    }

    final jobs = await (db.select(
      db.jobListings,
    )..where((j) => j.deleted.not() & j.status.isNotIn(['dismissed']))).get();
    final companies = {
      for (final a in await (db.select(db.jobApplications)..where((a) => a.deleted.not())).get()) a.company,
      for (final j in jobs) j.company,
    };
    final contacts = await importLeads(
      [
        for (final c in x.usefulConnections(companies))
          LeadSuggestion({
            'name': [col(c, 'first name'), col(c, 'last name')].where((s) => s.isNotEmpty).join(' '),
            'title': col(c, 'position'),
            'company': col(c, 'company'),
            'kind': isRecruiter(col(c, 'position')) ? 'recruiter' : 'peer',
            'linkedin': col(c, 'url'),
            'email': col(c, 'email address'),
            'source': 'LinkedIn connection',
            'why':
                'Already a LinkedIn connection'
                '${col(c, 'connected on').isEmpty ? '' : ' since ${col(c, 'connected on')}'}.',
            'approach': '',
          }),
      ],
      today: today,
      chase: false,
      sourceKind: 'archive',
    );
    final said = await importLinkedInMessages(x, today: today);

    return (
      jobs: after.experience.length - before.experience.length,
      skills: after.skills.length - before.skills.length,
      certifications: held,
      wins: wins,
      applications: sent,
      savedJobs: saved.length,
      contacts: contacts,
      messages: said.messages,
      invitations: said.invitations,
    );
  }

  /// Certifications the candidate holds, recorded as done on the Growth page
  /// unless already there. Returns how many were added.
  Future<int> recordHeld(List<String> certifications, {required String today}) => db.transaction(() async {
    final existing = await (db.select(db.careerGrowth)..where((g) => g.deleted.not())).get();
    final known = {for (final g in existing) g.title.toLowerCase().trim()};
    var added = 0;
    for (final c in certifications) {
      if (c.trim().isEmpty || !known.add(c.toLowerCase().trim())) continue;
      final id = newId();
      await save(
        db.careerGrowth,
        CareerGrowthCompanion.insert(
          id: id,
          title: c.trim(),
          kind: 'certification',
          status: const Value('done'),
          progress: const Value(100),
          done: Value(today),
          why: const Value('Held, from your CV or LinkedIn'),
          added: today,
        ),
        id,
      );
      added++;
    }
    return added;
  });

  /// Saves the profile (not its rights, notes or stories, which live apart)
  /// and rescores the jobs against it. A search term added to it becomes a
  /// saved search for that exact title (see [SavedSearchBook.followProfileTerms]).
  Future<void> saveProfile(CandidateProfile p) async {
    final before = CandidateProfile.fromJson(await pref<Map<String, Object?>>(PrefKeys.profile, const {}));
    await setPref(PrefKeys.profile, p.toJson());
    await followProfileTerms(before, p);
    await rescoreJobs();
  }

  /// Adds [code] to the target countries (keeping the home country first
  /// when none were chosen yet), so the job feeds search it on the next
  /// refresh. False when it is already there.
  Future<bool> addTargetCountry(String code) async {
    final cc = code.toUpperCase();
    final p = await profile();
    final now = p.searchCountries;
    if (now.contains(cc)) return false;
    final stored = CandidateProfile.fromJson(await pref<Map<String, Object?>>(PrefKeys.profile, const {}));
    await saveProfile(stored.copyWith(targets: stored.targets.copyWith(countries: [...now, cc])));
    return true;
  }

  Future<FeedKeys> feedKeys() async =>
      FeedKeys.fromJson(await pref<Map<String, Object?>>(PrefKeys.feedKeys, const {}));

  /// The user's key for each AI service, '' where there is none. A
  /// subscription has no key: it counts as set while a grant exists, even a
  /// lapsed one, so a lapsed grant is reported rather than quietly replaced
  /// by a paid key.
  Future<Map<AiProvider, String>> aiKeys() async => {
    for (final p in LocalKeys.grants.keys) p: await grant(p) == null ? '' : 'subscription',
    AiProvider.claude: await pref<String>(PrefKeys.aiKey, ''),
    AiProvider.gemini: await pref<String>(PrefKeys.geminiKey, ''),
  };

  /// The grant for subscription [p], or null.
  Future<SubscriptionGrant?> grant(AiProvider p) async {
    final j = decodeObject(await db.localSetting(LocalKeys.grants[p]!) ?? '');
    return j.isEmpty ? null : SubscriptionGrant.fromJson(j);
  }

  /// Saves or (with null) removes the grant for subscription [p], on this
  /// device only.
  Future<void> setGrant(AiProvider p, SubscriptionGrant? g) =>
      db.setLocalSetting(LocalKeys.grants[p]!, g == null ? '' : jsonEncode(g.toJson()));

  /// The spoken round's persona, level and end-of-answer silence here.
  Future<RoundSettings> roundSettings() async =>
      RoundSettings.fromJson(decodeObject(await db.localSetting(LocalKeys.roundSettings) ?? ''));

  Future<void> setRoundSettings(RoundSettings r) =>
      db.setLocalSetting(LocalKeys.roundSettings, jsonEncode(r.toJson()));

  Future<CoachPrefs> coachPrefs() async =>
      CoachPrefs.fromJson(decodeObject(await db.localSetting(LocalKeys.coachPrefs) ?? ''));

  Future<void> setCoachPrefs(CoachPrefs p) =>
      db.setLocalSetting(LocalKeys.coachPrefs, jsonEncode(p.toJson()));

  Future<InterviewDevice> interviewDevice() async =>
      InterviewDevice.fromJson(decodeObject(await db.localSetting(LocalKeys.interviewDevice) ?? ''));

  Future<void> setInterviewDevice(InterviewDevice d) =>
      db.setLocalSetting(LocalKeys.interviewDevice, jsonEncode(d.toJson()));

  Future<bool> updateOnStart() async => await db.localSetting(LocalKeys.updateOnStart) != 'off';

  Future<void> setUpdateOnStart(bool on) => db.setLocalSetting(LocalKeys.updateOnStart, on ? 'on' : 'off');

  /// The folders this device reads documents from.
  Future<List<String>> documentFolders() async =>
      decodeList(await db.localSetting(LocalKeys.documentFolders) ?? '').whereType<String>().toList();

  Future<void> setDocumentFolders(List<String> folders) =>
      db.setLocalSetting(LocalKeys.documentFolders, jsonEncode(folders));

  /// The check-in time on this device (default 18:30) and whether it reminds.
  Future<({String time, bool remind})> checkInSettings() async => (
    time: await db.localSetting(LocalKeys.checkInTime) ?? '18:30',
    remind: await db.localSetting(LocalKeys.checkInReminder) != 'off',
  );

  Future<void> setCheckInSettings({String? time, bool? remind}) async {
    if (time != null) await db.setLocalSetting(LocalKeys.checkInTime, time);
    if (remind != null) await db.setLocalSetting(LocalKeys.checkInReminder, remind ? 'on' : 'off');
  }

  Future<N8nLink> n8nLink() async =>
      N8nLink.fromJson(await pref<Map<String, Object?>>(PrefKeys.n8n, const {}));

  /// Saves a row of any Udyoga table.
  Future<void> save<T extends Table, D>(TableInfo<T, D> table, Insertable<D> row, String id) =>
      store.save(table, row, id);

  Future<void> remove(TableInfo table, String id) => store.remove(table, id);

  // ---- jobs ----

  static String _key(String title, String company) =>
      '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${company.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

  /// Adds new openings and refreshes known ones (same source and id, same
  /// link, or same title at the same employer). A known job is written only
  /// when something the feed says changed, so a refresh never re-sends
  /// untouched rows; the user's status, notes, dismissal and the AI's
  /// scores are never written over, and a job the user dismissed or
  /// deleted is left alone. Jobs the user's exclusions rule out are not
  /// added, nor is the same job from another board, matched on [jobKey]
  /// and the closing date (the saved copy keeps its own link). Returns the
  /// ids of the new ones.
  Future<List<String>> importPostings(List<Posting> postings, CandidateProfile p, {required String today}) =>
      db.transaction(() async {
        final existing = await db.select(db.jobListings).get();
        final bySource = {for (final j in existing) '${j.source}:${j.sourceId}': j};
        final byUrl = {
          for (final j in existing)
            if (j.url.isNotEmpty) j.url: j,
        };
        final byName = {
          for (final j in existing)
            if (j.company.isNotEmpty) _key(j.title, j.company): j,
        };
        // The same job from another board, written a little differently.
        final byJob = <String, List<Job>>{};
        void addJob(Job j) {
          final k = jobKey(title: j.title, company: j.company, location: j.location);
          if (k.isNotEmpty) byJob.putIfAbsent(k, () => []).add(j);
        }

        existing.forEach(addJob);
        final added = <String>[];
        for (final post in postings) {
          if (post.title.isEmpty) continue;
          var match =
              bySource['${post.source}:${post.sourceId}'] ??
              (post.url.isEmpty ? null : byUrl[post.url]) ??
              (post.company.isEmpty ? null : byName[_key(post.title, post.company)]);
          // A deleted job stays deleted, unless the user adds it again by hand.
          if (match != null && match.deleted && post.source == 'manual') match = null;
          if (match != null && (match.deleted || match.status == 'dismissed')) continue;
          // Already saved from another board: skipped, so it is not on the
          // list twice. (A deleted one added again by hand is let through.)
          if (match == null) {
            final k = jobKey(title: post.title, company: post.company, location: post.location);
            final twin = byJob[k]?.where(
              (j) =>
                  (j.closing == null || post.closing == null || j.closing == post.closing) &&
                  !(j.deleted && post.source == 'manual'),
            );
            if (twin != null && twin.isNotEmpty) continue;
          }
          if (match == null &&
              excludedBy(p.targets.exclusions, title: post.title, company: post.company) != null) {
            continue;
          }
          final id = match?.id ?? newId();
          final facts = JobFacts(
            title: post.title,
            description: post.description.length >= (match?.description.length ?? 0)
                ? post.description
                : match!.description,
            company: post.company.isNotEmpty ? post.company : match?.company ?? '',
            location: post.location.isNotEmpty ? post.location : match?.location ?? '',
            country: post.country.isNotEmpty ? post.country : match?.country ?? '',
            remote: post.remote || (match?.remote ?? false),
            salaryMin: post.salaryMin ?? match?.salaryMin,
            salaryMax: post.salaryMax ?? match?.salaryMax,
            currency: post.currency.isNotEmpty ? post.currency : match?.currency ?? '',
            salaryText: post.salaryText.isNotEmpty ? post.salaryText : match?.salaryText ?? '',
          );
          final url = post.url.isNotEmpty ? post.url : match?.url ?? '';
          final posted = post.posted ?? match?.posted;
          final closing = post.closing ?? match?.closing;
          final fit = match == null || match.fitBy == 'local' ? localFit(p, facts, today: today) : match.fit;
          if (match != null &&
              match.title == facts.title &&
              match.company == facts.company &&
              match.location == facts.location &&
              match.country == facts.country &&
              match.remote == facts.remote &&
              match.salaryMin == facts.salaryMin &&
              match.salaryMax == facts.salaryMax &&
              match.currency == facts.currency &&
              match.salaryText == facts.salaryText &&
              match.url == url &&
              match.description == facts.description &&
              match.posted == posted &&
              match.closing == closing &&
              match.fit == fit) {
            continue;
          }
          final row = JobListingsCompanion(
            id: Value(id),
            title: Value(facts.title),
            company: Value(facts.company),
            location: Value(facts.location),
            country: Value(facts.country),
            remote: Value(facts.remote),
            salaryMin: Value(facts.salaryMin),
            salaryMax: Value(facts.salaryMax),
            currency: Value(facts.currency),
            salaryText: Value(facts.salaryText),
            url: Value(url),
            description: Value(facts.description),
            posted: Value(posted),
            closing: Value(closing),
            source: Value(match?.source ?? post.source),
            sourceId: Value(match?.sourceId ?? post.sourceId),
            found: Value(match?.found ?? today),
            fit: Value(fit),
            fitBy: Value(match?.fitBy ?? 'local'),
          );
          await save(db.jobListings, row, id);
          if (match == null) {
            added.add(id);
            final saved = await job(id);
            bySource['${post.source}:${post.sourceId}'] = saved;
            if (post.url.isNotEmpty) byUrl[post.url] = saved;
            if (post.company.isNotEmpty) byName[_key(post.title, post.company)] = saved;
            addJob(saved);
          }
        }
        return added;
      });

  /// What the quick match reads from a saved job.
  static JobFacts factsOf(Job j) => JobFacts(
    title: j.title,
    description: j.description,
    company: j.company,
    location: j.location,
    country: j.country,
    remote: j.remote,
    salaryMin: j.salaryMin,
    salaryMax: j.salaryMax,
    currency: j.currency,
    salaryText: j.salaryText,
  );

  /// Redoes the quick match of every job the AI has not scored, against
  /// the profile as it is now; writes only the ones whose score changed.
  /// Returns how many changed.
  Future<int> rescoreJobs({String? today}) async {
    final p = await profile();
    final on = today ?? DateTime.now().toIso8601String().substring(0, 10);
    final jobs = await (db.select(
      db.jobListings,
    )..where((j) => j.deleted.not() & j.fitBy.equals('local'))).get();
    var changed = 0;
    await db.transaction(() async {
      for (final j in jobs) {
        final fit = localFit(p, factsOf(j), today: on);
        if (fit == j.fit) continue;
        await save(db.jobListings, j.copyWith(fit: Value(fit)), j.id);
        changed++;
      }
    });
    return changed;
  }

  Future<Job> job(String id) => (db.select(db.jobListings)..where((j) => j.id.equals(id))).getSingle();

  Future<void> setJobStatus(String id, String status) async {
    final j = await job(id);
    await save(db.jobListings, j.copyWith(status: status), id);
  }

  Future<void> saveAssessment(String id, FitAssessment a) async {
    final j = await job(id);
    await save(
      db.jobListings,
      j.copyWith(
        fit: Value(a.fit.clamp(0, 100)),
        fitBy: 'ai',
        assessment: jsonEncode(a.j),
        closing: Value(j.closing ?? (a.closing.length == 10 ? a.closing : null)),
      ),
      id,
    );
  }

  /// Quick AI scores for new jobs, unless the AI has assessed one in depth.
  Future<void> saveTriage(Map<String, ({int fit, String why})> scores) => db.transaction(() async {
    for (final e in scores.entries) {
      final j = await (db.select(db.jobListings)..where((t) => t.id.equals(e.key))).getSingleOrNull();
      if (j == null || j.assessment.isNotEmpty) continue;
      await save(
        db.jobListings,
        j.copyWith(fit: Value(e.value.fit), fitBy: 'triage', notes: j.notes.isEmpty ? e.value.why : j.notes),
        j.id,
      );
    }
  });

  // ---- applications ----

  Future<JobApplication> application(String id) =>
      (db.select(db.jobApplications)..where((a) => a.id.equals(id))).getSingle();

  /// Starts an application for [j] (or returns the open one) and marks the
  /// job applied.
  Future<String> applyFor(Job j, {required String today, bool sent = false}) => db.transaction(() async {
    final open =
        await (db.select(db.jobApplications)
              ..where((a) => a.jobId.equals(j.id) & a.deleted.not())
              ..limit(1))
            .getSingleOrNull();
    if (open != null) return open.id;
    final id = newId();
    await save(
      db.jobApplications,
      JobApplicationsCompanion.insert(
        id: id,
        jobId: Value(j.id),
        title: j.title,
        company: Value(j.company),
        location: Value(j.location),
        url: Value(j.url),
        updated: today,
      ),
      id,
    );
    await save(db.jobListings, j.copyWith(status: 'applied'), j.id);
    await archive(
      applicationId: id,
      jobId: j.id,
      kind: 'advert',
      at: '${today}T${_clock()}',
      title: j.company.isEmpty ? j.title : '${j.title} at ${j.company}',
      url: j.url,
      content: advertText(j),
    );
    if (sent) {
      await moveTo(id, Stage.applied, date: today);
    } else if (j.closing != null) {
      await setFollowUp(id, _sendBy(j.closing!, today), note: _sendNote(j.closing!));
    }
    return id;
  });

  /// Moves an application to [stage] on [date], records it (at [at] when the
  /// time is known, as for a booked interview) and sets the next follow-up.
  Future<void> moveTo(String id, Stage stage, {required String date, String summary = '', String? at}) =>
      db.transaction(() async {
        final a = await application(id);
        final from = Stage.of(a.stage);
        final job = a.jobId == null
            ? null
            : await (db.select(db.jobListings)..where((j) => j.id.equals(a.jobId!))).getSingleOrNull();
        final (followUp, note) = switch (stage) {
          Stage.preparing when job?.closing != null => (
            _sendBy(job!.closing!, date),
            _sendNote(job.closing!),
          ),
          // HSC waiting-list offers lapse at 12 noon two working days on.
          Stage.offer when from == Stage.waitingList => (
            addWorkingDays(date, 2),
            'Offer from the waiting list: reply by 12 noon on ${niceDate(addWorkingDays(date, 2))}, '
                'or it counts as a refusal.',
          ),
          Stage.rejected when from == Stage.interview || from == Stage.waitingList => (
            addDays(date, 3),
            'Ask the panel for feedback on your interview, and say you would welcome future posts.',
          ),
          _ => (followUpFor(stage, date), stage.chaseAfter == null ? '' : _chaseNote(stage)),
        };
        await save(
          db.jobApplications,
          a.copyWith(
            stage: stage.id,
            updated: date,
            applied: Value(a.applied ?? (stage.index >= Stage.applied.index && stage.open ? date : null)),
            followUp: Value(followUp),
            followUpNote: note,
          ),
          id,
        );
        final kind = eventKinds.entries.where((e) => e.value.$2 == stage).firstOrNull?.key ?? 'note';
        await _event(id, kind, summary.isNotEmpty ? summary : stage.label, at ?? '${date}T${_clock()}');
        if (stage == Stage.checks && from != Stage.checks) await startChecks(id, date);
        if (stage == Stage.accepted) await _flagOthers(a, date);
        // A journey sent to Vidya hears where the application now stands.
        if (stage != from) await refreshJobJourney(a.jobId, now: DateTime.now().toUtc().toIso8601String());
      });

  /// When to remind about an unsent application: two days before [closing]
  /// (NHS adverts can close early), never before [today].
  static String _sendBy(String closing, String today) {
    final d = addDays(closing, -2);
    return d.compareTo(today) < 0 ? today : d;
  }

  static String _sendNote(String closing) =>
      'Send this before the advert closes on ${niceDate(closing)}; busy adverts can close early.';

  /// After accepting [won], every other open application gets a reminder to
  /// withdraw it (nothing is withdrawn for the candidate).
  Future<void> _flagOthers(JobApplication won, String date) async {
    final others =
        await (db.select(db.jobApplications)..where(
              (a) =>
                  a.deleted.not() &
                  a.id.equals(won.id).not() &
                  a.stage.isIn(Stage.openStages.map((s) => s.id)),
            ))
            .get();
    final where = won.company.isEmpty ? won.title : '${won.title} at ${won.company}';
    for (final o in others) {
      await save(
        db.jobApplications,
        o.copyWith(
          followUp: Value(date),
          followUpNote:
              'You accepted $where. Withdraw this application, or tell them you are no longer available.',
        ),
        o.id,
      );
    }
  }

  /// The steps between a conditional offer and the first day, as NHS
  /// England and HSC (Northern Ireland) run them. Forms are due within five
  /// working days (HSC's deadline; NHS trusts ask for them promptly).
  static const offerSteps = [
    ('identity', 'Identity and right to work: book the appointment and bring the original documents'),
    ('references', 'References: confirm your referees and the period they must cover'),
    (
      'criminal_record',
      'Criminal record check if the post needs one (DBS in England, AccessNI in Northern Ireland)',
    ),
    ('health', 'Occupational health questionnaire and evidence of immunisations'),
    ('qualifications', 'Evidence of the qualifications the advert asks for'),
    ('forms', 'Personal declaration and payroll forms (HSC: FRMPEC4, FRMPEC6 and FRMPEC7)'),
    ('contract', 'Unconditional offer and contract received'),
    ('notice', 'Notice given to your current employer'),
    ('start', 'Start date agreed with your new line manager'),
  ];

  static const _formsDue = {'identity', 'references', 'criminal_record', 'health', 'qualifications', 'forms'};

  /// Adds the offer-to-start checklist ([offerSteps]) unless the
  /// application has one; forms are due 5 working days after [date].
  Future<void> startChecks(String applicationId, String date) async {
    final existing = await checks(applicationId);
    if (existing.isNotEmpty) return;
    for (final (kind, title) in offerSteps) {
      await addCheck(
        applicationId,
        kind: kind,
        title: title,
        due: _formsDue.contains(kind) ? addWorkingDays(date, 5) : null,
      );
    }
  }

  /// The checks on an application, in the order of [offerSteps], then any
  /// the candidate added.
  Future<List<JobCheck>> checks(String applicationId) async => sortChecks(
    await (db.select(
      db.jobChecks,
    )..where((c) => c.applicationId.equals(applicationId) & c.deleted.not())).get(),
  );

  static List<JobCheck> sortChecks(List<JobCheck> list) {
    int rank(JobCheck c) {
      final i = offerSteps.indexWhere((s) => s.$1 == c.kind);
      return i < 0 ? offerSteps.length : i;
    }

    return list..sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : a.title.compareTo(b.title));
  }

  Future<String> addCheck(
    String applicationId, {
    required String kind,
    required String title,
    String? due,
  }) async {
    final id = newId();
    await save(
      db.jobChecks,
      JobChecksCompanion.insert(
        id: id,
        applicationId: applicationId,
        kind: kind,
        title: title,
        due: Value(due),
      ),
      id,
    );
    return id;
  }

  /// Sets a check's status; done ones record [today].
  Future<void> setCheck(JobCheck c, String status, {required String today, String? due, String? notes}) =>
      save(
        db.jobChecks,
        c.copyWith(
          status: status,
          done: Value(status == 'done' ? (c.done ?? today) : null),
          due: due == null ? const Value.absent() : Value(due.isEmpty ? null : due),
          notes: notes ?? c.notes,
        ),
        c.id,
      );

  /// Keeps a copy of [content]: the advert as it read or the application as
  /// sent.
  Future<String> archive({
    String? applicationId,
    String? jobId,
    required String kind,
    required String at,
    required String content,
    String title = '',
    String url = '',
  }) async {
    final id = newId();
    await save(
      db.jobArchive,
      JobArchiveCompanion.insert(
        id: id,
        applicationId: Value(applicationId),
        jobId: Value(jobId),
        kind: kind,
        at: at,
        title: Value(title),
        url: Value(url),
        content: content,
      ),
      id,
    );
    return id;
  }

  Future<List<Archived>> archived(String applicationId) =>
      (db.select(db.jobArchive)
            ..where((a) => a.applicationId.equals(applicationId) & a.deleted.not())
            ..orderBy([(a) => OrderingTerm(expression: a.at)]))
          .get();

  /// Records the application as sent on [today], keeping a copy of what was
  /// sent ([sent], the answer pack as the candidate used it).
  Future<void> markSent(String id, {required String today, required String sent}) => db.transaction(() async {
    final a = await application(id);
    if (Stage.of(a.stage).index < Stage.applied.index) await moveTo(id, Stage.applied, date: today);
    await archive(
      applicationId: id,
      jobId: a.jobId,
      kind: 'application',
      at: '${today}T${_clock()}',
      title: a.company.isEmpty ? a.title : '${a.title} at ${a.company}',
      url: a.url,
      content: sent,
    );
  });

  /// The advert as text, for the archive.
  static String advertText(Job j) => [
    j.title,
    if (j.company.isNotEmpty) j.company,
    if (j.location.isNotEmpty) j.location,
    if (j.salaryText.isNotEmpty) j.salaryText,
    if (j.closing != null) 'Closes ${j.closing}',
    if (j.url.isNotEmpty) j.url,
    '',
    j.description,
  ].join('\n');

  static String _chaseNote(Stage s) => switch (s) {
    Stage.applied => 'Ask whether the application is being considered and when shortlisting ends.',
    Stage.screening => 'Ask about next steps and the interview timetable.',
    Stage.interview =>
      'Thank the panel and ask when they expect to decide; ask for feedback if unsuccessful.',
    Stage.waitingList =>
      'Keep your contact details and preferences current; check email, junk mail and voicemail for offers.',
    Stage.offer => 'Reply to the offer: questions, negotiation or acceptance.',
    Stage.checks => 'Chase any pre-employment check still outstanding and ask for a start date.',
    _ => '',
  };

  static String _clock() => DateTime.now().toIso8601String().substring(11, 16);

  Future<void> _event(String applicationId, String kind, String summary, String at) {
    final id = newId();
    return save(
      db.jobEvents,
      JobEventsCompanion.insert(
        id: id,
        applicationId: applicationId,
        at: at,
        kind: kind,
        summary: Value(summary),
      ),
      id,
    );
  }

  /// Logs what happened; events that imply a stage move the application on
  /// (never back), and chasing it up sets the next follow-up a week later.
  Future<void> logEvent(String id, String kind, {required String at, String summary = ''}) =>
      db.transaction(() async {
        final stage = eventKinds[kind]?.$2;
        final a = await application(id);
        final date = at.substring(0, 10);
        if (stage != null && (stage.index > Stage.of(a.stage).index || !stage.open)) {
          await moveTo(
            id,
            stage,
            date: date,
            at: at,
            summary: summary.isNotEmpty ? summary : eventKinds[kind]!.$1,
          );
          return;
        }
        await _event(id, kind, summary.isNotEmpty ? summary : eventKinds[kind]?.$1 ?? kind, at);
        if (kind == 'followup' && Stage.of(a.stage).open) {
          await save(db.jobApplications, a.copyWith(followUp: Value(addDays(date, 7))), id);
        } else if (stage != null && date.compareTo(a.updated) > 0) {
          // Word from the employer at the same stage: still in touch, so it
          // is not a silent application.
          await save(db.jobApplications, a.copyWith(updated: date), id);
        }
      });

  Future<void> setFollowUp(String id, String? date, {String? note}) async {
    final a = await application(id);
    await save(
      db.jobApplications,
      a.copyWith(followUp: Value(date), followUpNote: note ?? a.followUpNote),
      id,
    );
  }

  /// Applications with no word [ghostedAfterDays] after the last change go
  /// to No reply. Returns how many.
  Future<int> markGhosted(String today) => db.transaction(() async {
    final cutoff = addDays(today, -ghostedAfterDays);
    final stale =
        await (db.select(db.jobApplications)..where(
              (a) =>
                  a.deleted.not() &
                  a.stage.isIn([Stage.applied.id, Stage.screening.id]) &
                  a.updated.isSmallerThanValue(cutoff),
            ))
            .get();
    for (final a in stale) {
      await moveTo(a.id, Stage.noReply, date: today, summary: 'No reply after $ghostedAfterDays days');
    }
    return stale.length;
  });

  // ---- leads ----

  /// Adds leads not already known. With [chase], each gets a follow-up today.
  /// Anyone whose e-mail address or LinkedIn profile belongs to a person
  /// marked "do not contact" is skipped. Each new lead records where it was
  /// found ([sourceKind], the source link) and the day.
  Future<int> importLeads(
    List<LeadSuggestion> leads, {
    String? jobId,
    required String today,
    bool chase = true,
    String sourceKind = 'other',
  }) => db.transaction(() async {
    final existing = await (db.select(db.careerContacts)..where((c) => c.deleted.not())).get();
    final known = {for (final c in existing) _key(c.name, c.company)};
    final blocked = suppressionKeys(
      existing,
      await (db.select(db.contactHandles)..where((h) => h.deleted.not())).get(),
    );
    var added = 0;
    for (final l in leads) {
      if (blocked.contains(handleKey('email', l.email)) ||
          blocked.contains(handleKey('linkedin', l.linkedin))) {
        continue;
      }
      if (l.name.isEmpty || !known.add(_key(l.name, l.company))) continue;
      final id = newId();
      await save(
        db.careerContacts,
        CareerContactsCompanion.insert(
          id: id,
          name: l.name,
          kind: Value(leadKinds.containsKey(l.kind) ? l.kind : 'other'),
          title: Value(l.title),
          company: Value(l.company),
          email: Value(l.email),
          phone: Value(l.phone),
          linkedin: Value(l.linkedin),
          source: Value(l.source),
          sourceUrl: Value(
            l.sourceUrl.isNotEmpty ? l.sourceUrl : (l.source.startsWith('http') ? l.source : ''),
          ),
          sourceKind: Value(sourceKind),
          foundOn: Value(today),
          jobId: Value(jobId),
          followUp: Value(chase ? today : null),
          notes: Value([l.why, if (l.approach.isNotEmpty) 'Approach: ${l.approach}'].join('\n')),
        ),
        id,
      );
      added++;
    }
    return added;
  });

  /// Records contact with a lead: status Contacted, chase again in a week.
  Future<void> contacted(Lead l, {required String today}) => save(
    db.careerContacts,
    l.copyWith(
      status: l.status == 'replied' ? 'replied' : 'contacted',
      lastContact: Value(today),
      followUp: Value(addDays(today, 7)),
    ),
    l.id,
  );

  // ---- CVs, reports, growth ----

  Future<String> saveResume({
    required String name,
    required ResumeDoc doc,
    String? jobId,
    Json? tailoring,
    required String today,
    String? id,
  }) async {
    final rowId = id ?? newId();
    await save(
      db.careerResumes,
      CareerResumesCompanion.insert(
        id: rowId,
        name: name,
        jobId: Value(jobId),
        created: today,
        content: jsonEncode(doc.toJson()),
        tailoring: Value(tailoring == null ? '' : jsonEncode(tailoring)),
      ),
      rowId,
    );
    return rowId;
  }

  Future<String> saveReport(String kind, Json content, List<Source> sources, {required String at}) async {
    final id = newId();
    await save(
      db.careerReports,
      CareerReportsCompanion.insert(
        id: id,
        kind: kind,
        created: at,
        content: jsonEncode(content),
        sources: Value(
          jsonEncode([
            for (final s in sources) {'title': s.title, 'url': s.url},
          ]),
        ),
      ),
      id,
    );
    await pruneReports(kind);
    return id;
  }

  /// How many reports of a kind are kept; older ones are deleted. Employer
  /// research keeps the newest per employer, up to the cap.
  static const reportCaps = {'assessment': 12, 'career_map': 12, 'employer': 100};

  /// The cap for the other kinds (LinkedIn drafts and the like).
  static const otherReportsCap = 60;

  /// Deletes the reports of [kind] past its cap, oldest first. Returns how
  /// many went.
  Future<int> pruneReports(String kind) async {
    final rows =
        await (db.select(db.careerReports)
              ..where((r) => r.kind.equals(kind) & r.deleted.not())
              ..orderBy([(r) => OrderingTerm.desc(r.created), (r) => OrderingTerm.desc(r.id)]))
            .get();
    final cap = reportCaps[kind] ?? otherReportsCap;
    final drop = <Report>[];
    if (kind == 'employer') {
      final seen = <String>{};
      for (final r in rows) {
        final name = str(decodeObject(r.content)['employer']).toLowerCase().trim();
        if (!seen.add(name) || seen.length > cap) drop.add(r);
      }
    } else {
      drop.addAll(rows.skip(cap));
    }
    for (final r in drop) {
      await remove(db.careerReports, r.id);
    }
    return drop.length;
  }

  Future<Report?> latestReport(String kind) =>
      (db.select(db.careerReports)
            ..where((r) => r.kind.equals(kind) & r.deleted.not())
            ..orderBy([(r) => OrderingTerm.desc(r.created)])
            ..limit(1))
          .getSingleOrNull();

  /// The latest research on [employer], if any (matched by name, any case).
  Future<EmployerBrief?> employerBrief(String employer) async {
    final key = employer.toLowerCase().trim();
    if (key.isEmpty) return null;
    final rows =
        await (db.select(db.careerReports)
              ..where((r) => r.kind.equals('employer') & r.deleted.not())
              ..orderBy([(r) => OrderingTerm.desc(r.created)]))
            .get();
    for (final r in rows) {
      final j = decodeObject(r.content);
      if (str(j['employer']).toLowerCase().trim() == key) {
        return EmployerBrief({...j, 'researched': r.created, 'sources': decodeList(r.sources)});
      }
    }
    return null;
  }

  /// Saves research on [employer] under the name the candidate's job uses,
  /// and sends its sourced points to Vidya with any job plan sent for it.
  Future<void> saveEmployerBrief(String employer, AiResult r, {required String at}) async {
    await saveReport('employer', {...r.data, 'employer': employer}, r.sources, at: at);
    await refreshEmployerJourneys(employer, now: DateTime.now().toUtc().toIso8601String());
  }

  Future<PayBaseline> payBaseline() async =>
      PayBaseline.fromJson(await pref<Map<String, Object?>>(PrefKeys.pay, const {}));

  Future<void> setPayBaseline(PayBaseline b) => setPref(PrefKeys.pay, b.toJson());

  /// Adds learning suggestions not already on the list. Returns how many.
  Future<int> suggestLearning(List<LearningSuggestion> items, {String path = '', required String today}) =>
      db.transaction(() async {
        final existing = await (db.select(db.careerGrowth)..where((g) => g.deleted.not())).get();
        final known = {for (final g in existing) g.title.toLowerCase().trim()};
        var added = 0;
        for (final s in items) {
          if (s.title.isEmpty || !known.add(s.title.toLowerCase().trim())) continue;
          final id = newId();
          await save(
            db.careerGrowth,
            CareerGrowthCompanion.insert(
              id: id,
              title: s.title,
              kind: growthKinds.containsKey(s.kind) ? s.kind : 'course',
              provider: Value(s.provider),
              url: Value(s.url),
              cost: Value(s.cost),
              duration: Value(s.duration),
              why: Value(
                [s.why, if (s.priority == 'essential') '(Essential)'].where((t) => t.isNotEmpty).join(' '),
              ),
              path: Value(path),
              added: today,
            ),
            id,
          );
          added++;
        }
        return added;
      });

  /// Makes [path] the target: a goal for each step and its certifications
  /// as learning. Returns how many items were added.
  Future<int> targetPath(CareerPath path, {required String today}) async {
    var added = await suggestLearning(
      [
        for (final step in path.steps)
          for (final c in step.certifications)
            LearningSuggestion(
              title: c,
              kind: 'certification',
              why: 'Needed for ${step.role}',
              priority: 'essential',
            ),
      ],
      path: path.name,
      today: today,
    );
    added += await suggestLearning(
      [
        for (final step in path.steps)
          LearningSuggestion(
            title: 'Become ${step.role}',
            kind: 'goal',
            duration: step.timeframe,
            why: step.requirements.join('; '),
          ),
      ],
      path: path.name,
      today: today,
    );
    final goals = await (db.select(
      db.careerGrowth,
    )..where((g) => g.path.equals(path.name) & g.deleted.not())).get();
    for (final g in goals.where((g) => g.status == 'suggested')) {
      await save(db.careerGrowth, g.copyWith(status: 'planned'), g.id);
    }
    return added;
  }

  Future<void> setGrowth(GrowthItem g, {String? status, int? progress, required String today}) => save(
    db.careerGrowth,
    g.copyWith(
      status:
          status ??
          (progress == 100
              ? 'done'
              : (progress ?? 0) > 0 && g.status != 'done'
              ? 'doing'
              : g.status),
      progress: progress ?? (status == 'done' ? 100 : g.progress),
      done: Value(status == 'done' || progress == 100 ? today : g.done),
    ),
    g.id,
  );

  // ---- interview practice ----

  Future<String> startPractice({
    required String role,
    required String mode,
    String? jobId,
    required List<PracticeQuestion> questions,
    required String at,
  }) async {
    final id = newId();
    await save(
      db.careerPractice,
      CareerPracticeCompanion.insert(
        id: id,
        role: role,
        mode: mode,
        jobId: Value(jobId),
        started: at,
        questions: jsonEncode([for (final q in questions) q.j]),
      ),
      id,
    );
    return id;
  }

  /// Saves an answer and its review, and updates the round's average.
  Future<void> saveAnswer(
    String sessionId,
    int question,
    String answer,
    AnswerReview review, {
    required String at,
  }) => db.transaction(() async {
    final previous =
        await (db.select(db.careerAnswers)
              ..where((a) => a.sessionId.equals(sessionId) & a.question.equals(question) & a.deleted.not()))
            .getSingleOrNull();
    final id = previous?.id ?? newId();
    await save(
      db.careerAnswers,
      CareerAnswersCompanion.insert(
        id: id,
        sessionId: sessionId,
        question: question,
        answer: answer,
        at: at,
        review: Value(jsonEncode(review.j)),
        score: Value(review.score),
      ),
      id,
    );
    await _rescorePractice(sessionId);
  });

  /// Saves the text of a spoken or typed answer before it is reviewed. A
  /// new transcript clears the old review (it was of other words). Only
  /// text is stored here: recordings stay on the device that made them.
  Future<void> saveTranscript(String sessionId, int question, String answer, {required String at}) =>
      db.transaction(() async {
        final previous =
            await (db.select(db.careerAnswers)..where(
                  (a) => a.sessionId.equals(sessionId) & a.question.equals(question) & a.deleted.not(),
                ))
                .getSingleOrNull();
        if (previous != null && previous.answer == answer) return;
        final id = previous?.id ?? newId();
        await save(
          db.careerAnswers,
          CareerAnswersCompanion.insert(
            id: id,
            sessionId: sessionId,
            question: question,
            answer: answer,
            at: at,
            review: const Value(''),
            score: const Value(null),
          ),
          id,
        );
        await _rescorePractice(sessionId);
      });

  Future<void> _rescorePractice(String sessionId) async {
    final scores =
        await (db.select(db.careerAnswers)
              ..where((a) => a.sessionId.equals(sessionId) & a.deleted.not() & a.score.isNotNull()))
            .map((a) => a.score!)
            .get();
    final s = await (db.select(db.careerPractice)..where((p) => p.id.equals(sessionId))).getSingle();
    await save(
      db.careerPractice,
      s.copyWith(score: Value(scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length)),
      s.id,
    );
  }

  // ---- spend ----

  /// Adds a request's cost to this month's running total on this device.
  Future<void> addSpend(AiUsage u, {required String month}) async {
    final j = decodeObject(await db.localSetting(LocalKeys.spend) ?? '');
    final dollars = (str(j['month']) == month ? numOf(j['dollars']) ?? 0 : 0) + u.dollars;
    await db.setLocalSetting(LocalKeys.spend, jsonEncode({'month': month, 'dollars': dollars}));
  }

  Future<double> spend(String month) async {
    final j = decodeObject(await db.localSetting(LocalKeys.spend) ?? '');
    return str(j['month']) == month ? numOf(j['dollars']) ?? 0 : 0;
  }
}
