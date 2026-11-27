/// Career signals from a helper app (docs/handoff.md, "Career signals"):
/// the jobs a social network suggested, where applications made there
/// stand, new connections and profile views from people at employers the
/// user watches. Each lands in the part of Udyoga that already holds that
/// kind of thing: a job alert becomes a job through the same import as the
/// job boards, a status becomes a timeline entry on its application, and
/// people become contacts through the same merge as other leads. Nothing
/// here goes online.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'conversations.dart';
import 'feeds.dart';
import 'insights.dart';
import 'job_identity.dart';
import 'json.dart';
import 'pipeline.dart';

/// The signal kinds Udyoga reads.
const signalKinds = {'job_alert', 'application_status', 'invite_accepted', 'profile_view'};

/// Where an application stands on the helper's network.
const signalStatuses = {
  'applied': 'Applied',
  'viewed': 'Application viewed',
  'resume_downloaded': 'CV downloaded',
  'in_review': 'In review',
  'not_selected': 'Not selected',
  'closed': 'No longer taking applications',
  'unknown': 'Status changed',
};

/// The job source of a helper's job alerts.
const helperJobSource = 'linkedin_helper';

/// How sure a match by employer and title must be to update an
/// application by itself; below it the update waits as a suggestion.
const autoMatch = 0.75;

/// The job a signal is about.
class HandoffJob {
  const HandoffJob({this.id = '', this.url = '', this.title = '', this.company = '', this.location = ''});
  final String id, url, title, company, location;

  static HandoffJob? fromJson(Object? v) {
    if (v is! Map) return null;
    final m = v.cast<String, Object?>();
    return HandoffJob(
      id: str(m['id']).trim(),
      url: str(m['url']).trim(),
      title: str(m['title']).trim(),
      company: str(m['company']).trim(),
      location: str(m['location']).trim(),
    );
  }

  Json toJson() => {'id': id, 'url': url, 'title': title, 'company': company, 'location': location};

  String get label => company.isEmpty ? title : '$title at $company';
}

/// One career signal line.
class HandoffSignal {
  const HandoffSignal({
    required this.kind,
    required this.source,
    required this.id,
    required this.sentAt,
    this.job,
    this.status = '',
    this.statusText = '',
    this.name = '',
    this.headline = '',
    this.profileUrl = '',
    this.company = '',
    this.text = '',
    this.reasons = const [],
  });

  final String kind, source, id, status, statusText, name, headline, profileUrl, company, text;
  final DateTime sentAt;
  final HandoffJob? job;
  final List<String> reasons;

  /// Reads a signal of [handoffVersion]; throws [FormatException] with the
  /// reason when what its kind needs is missing. Unknown fields are ignored.
  factory HandoffSignal.fromJson(Json j) {
    String need(String k) {
      final v = j[k];
      if (v is! String || v.trim().isEmpty) throw FormatException('"$k" is missing');
      return v.trim();
    }

    final kind = need('kind');
    final at = DateTime.tryParse(need('sentAt'));
    if (at == null) throw const FormatException('"sentAt" is not an ISO 8601 time');
    final job = HandoffJob.fromJson(j['job']);
    final peer = j['peer'] is Map ? (j['peer'] as Map).cast<String, Object?>() : const <String, Object?>{};
    var status = str(j['status']).trim();
    switch (kind) {
      case 'job_alert':
        if (job == null || job.title.isEmpty) throw const FormatException('no "job" with a title');
        if (job.id.isEmpty && job.url.isEmpty) throw const FormatException('the job has no "id" or "url"');
      case 'application_status':
        if (job == null || (job.title.isEmpty && job.id.isEmpty && job.url.isEmpty)) {
          throw const FormatException('no "job" to match');
        }
        if (status.isEmpty) throw const FormatException('"status" is missing');
        if (!signalStatuses.containsKey(status)) status = 'unknown';
      case 'invite_accepted' || 'profile_view':
        if (str(peer['name']).trim().isEmpty) throw const FormatException('no "peer" with a name');
    }
    return HandoffSignal(
      kind: kind,
      source: need('source'),
      id: need('id'),
      sentAt: at,
      job: job,
      status: status,
      statusText: str(j['statusText']).trim(),
      name: str(peer['name']).trim(),
      headline: str(peer['headline']).trim(),
      profileUrl: str(peer['profileUrl']).trim(),
      company: str(peer['company']).trim(),
      text: str(j['text']).trim(),
      reasons: strs(j['reasons']),
    );
  }

  /// The day it happened, on this device's calendar.
  String get date => sentAt.toLocal().toIso8601String().substring(0, 10);
  String get minute => sentAt.toLocal().toIso8601String().substring(0, 16);

  /// What the helper's network showed, for a timeline entry.
  String get said => statusText.isNotEmpty ? statusText : signalStatuses[status] ?? status;
}

/// A status that matched no application surely enough, waiting for the
/// user: apply it to [applicationId] (the best guess, if any), add it as a
/// new application, or dismiss it.
class SignalSuggestion {
  const SignalSuggestion({
    required this.id,
    required this.job,
    required this.status,
    required this.said,
    required this.at,
    this.applicationId,
    this.applicationLabel = '',
    this.score = 0,
    this.state = 'pending',
  });

  /// The signal's id.
  final String id;
  final HandoffJob job;
  final String status, said, at, applicationLabel, state;
  final String? applicationId;
  final double score;

  factory SignalSuggestion.fromJson(Json j) => SignalSuggestion(
    id: str(j['id']),
    job: HandoffJob.fromJson(j['job']) ?? const HandoffJob(),
    status: str(j['status']),
    said: str(j['said']),
    at: str(j['at']),
    applicationId: str(j['applicationId']).isEmpty ? null : str(j['applicationId']),
    applicationLabel: str(j['applicationLabel']),
    score: j['score'] is num ? (j['score'] as num).toDouble() : 0,
    state: str(j['state']).isEmpty ? 'pending' : str(j['state']),
  );

  Json toJson() => {
    'id': id,
    'job': job.toJson(),
    'status': status,
    'said': said,
    'at': at,
    'applicationId': applicationId ?? '',
    'applicationLabel': applicationLabel,
    'score': score,
    'state': state,
  };

  SignalSuggestion dismissed() => SignalSuggestion.fromJson({...toJson(), 'state': 'dismissed'});
}

/// A stable row id for a signal, so the same signal read twice (or on two
/// devices) writes the same row.
String signalRowId(String signalId) {
  final h = sha256.convert(utf8.encode('udyoga-handoff:$signalId')).toString();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
}

/// The job posting id in a network link (".../jobs/view/4100000001/").
String jobIdInUrl(String url) => RegExp(r'/jobs/view/(\d+)').firstMatch(url)?.group(1) ?? '';

/// How alike two job titles are: the share of their words in common.
double titleLikeness(String a, String b) {
  final x = normalJobTitle(a).split(' ').where((w) => w.isNotEmpty).toSet();
  final y = normalJobTitle(b).split(' ').where((w) => w.isNotEmpty).toSet();
  if (x.isEmpty || y.isEmpty) return 0;
  return x.intersection(y).length / x.union(y).length;
}

String _name(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

extension HandoffSignalsBook on CareerBook {
  /// Imports a helper's career signals. Returns (imported, skipped); a
  /// signal imported before counts as skipped.
  Future<({int imported, int skipped})> importHandoffSignals(
    List<HandoffSignal> signals, {
    required String today,
  }) async {
    var imported = 0, skipped = 0;
    final alerts = signals.where((s) => s.kind == 'job_alert').toList();
    if (alerts.isNotEmpty) {
      final added = await importPostings(
        [for (final s in alerts) _posting(s)],
        await profile(),
        today: today,
      );
      imported += added.length;
      skipped += alerts.length - added.length;
    }
    for (final s in signals) {
      if (s.kind == 'job_alert') continue;
      final done = switch (s.kind) {
        'application_status' => await _status(s),
        'invite_accepted' || 'profile_view' => await _person(s, today: today),
        _ => false,
      };
      done == true ? imported++ : skipped++;
    }
    return (imported: imported, skipped: skipped);
  }

  Posting _posting(HandoffSignal s) {
    final j = s.job!;
    final id = j.id.isNotEmpty ? j.id : jobIdInUrl(j.url);
    return Posting(
      source: helperJobSource,
      sourceId: id.isNotEmpty ? id : j.url,
      title: j.title,
      company: j.company,
      location: j.location,
      url: j.url,
      description: s.text,
      posted: s.date,
    );
  }

  // ---- application status

  /// The application a status is about: by the job's id or link, else by
  /// employer and title. Returns it with how sure the match is (1 for an
  /// id or link).
  Future<(JobApplication?, double)> _match(HandoffJob job) async {
    final apps = await (db.select(db.jobApplications)..where((a) => a.deleted.not())).get();
    final jobs = {for (final j in await db.select(db.jobListings).get()) j.id: j};
    final id = job.id.isNotEmpty ? job.id : jobIdInUrl(job.url);
    for (final a in apps) {
      final j = a.jobId == null ? null : jobs[a.jobId];
      final ids = {
        jobIdInUrl(a.url),
        if (j != null) jobIdInUrl(j.url),
        if (j != null && j.source == helperJobSource) j.sourceId,
      }..remove('');
      if ((id.isNotEmpty && ids.contains(id)) ||
          (job.url.isNotEmpty && (a.url == job.url || j?.url == job.url))) {
        return (a, 1.0);
      }
    }
    final employer = normalEmployer(job.company);
    JobApplication? best;
    var score = 0.0;
    for (final a in apps) {
      if (employer.isEmpty || normalEmployer(a.company) != employer) continue;
      final like = titleLikeness(a.title, job.title);
      if (like > score) (best, score) = (a, like);
    }
    return (best, score);
  }

  /// Applies a status, or keeps it as a suggestion. Null when it was
  /// applied or kept before.
  Future<bool?> _status(HandoffSignal s) async {
    final eventId = signalRowId(s.id);
    final logged = await (db.select(db.jobEvents)..where((e) => e.id.equals(eventId))).getSingleOrNull();
    if (logged != null) return null;
    final pending = await signalSuggestions();
    if (pending.any((p) => p.id == s.id)) return null;
    final (app, score) = await _match(s.job!);
    if (app == null || score < autoMatch) {
      await _putSuggestions([
        ...pending,
        SignalSuggestion(
          id: s.id,
          job: s.job!,
          status: s.status,
          said: s.said,
          at: s.minute,
          applicationId: app?.id,
          applicationLabel: app == null
              ? ''
              : (app.company.isEmpty ? app.title : '${app.title} at ${app.company}'),
          score: score,
        ),
      ]);
      return true;
    }
    await _applyStatus(app.id, status: s.status, said: s.said, at: s.minute, eventId: eventId);
    return true;
  }

  /// One timeline entry for a status; "applied" and "not selected" also move
  /// the application on (never back, and a closed one stays closed).
  Future<void> _applyStatus(
    String applicationId, {
    required String status,
    required String said,
    required String at,
    required String eventId,
  }) async {
    final a = await application(applicationId);
    final stage = Stage.of(a.stage);
    final summary = 'LinkedIn: $said (via helper app)';
    final date = at.substring(0, 10);
    if (status == 'applied' && stage.open && stage.index < Stage.applied.index) {
      await moveTo(applicationId, Stage.applied, date: date, at: at, summary: summary, eventId: eventId);
    } else if (status == 'not_selected' && stage.open) {
      await moveTo(applicationId, Stage.rejected, date: date, at: at, summary: summary, eventId: eventId);
    } else {
      await logEvent(applicationId, 'note', at: at, summary: summary, eventId: eventId);
    }
  }

  /// Statuses waiting for the user (dismissed ones are kept, so the same
  /// status is not suggested again).
  Future<List<SignalSuggestion>> signalSuggestions() async => [
    for (final x in decodeList(await db.localSetting(LocalKeys.handoffSuggestions) ?? ''))
      if (x is Map) SignalSuggestion.fromJson(x.cast<String, Object?>()),
  ];

  Future<void> _putSuggestions(List<SignalSuggestion> list) =>
      db.setLocalSetting(LocalKeys.handoffSuggestions, jsonEncode([for (final s in list) s.toJson()]));

  Future<SignalSuggestion> _take(String id) async {
    final list = await signalSuggestions();
    final s = list.firstWhere((x) => x.id == id && x.state == 'pending');
    await _putSuggestions([for (final x in list) x.id == id ? x.dismissed() : x]);
    return s;
  }

  /// The user says a suggestion is about [applicationId].
  Future<void> acceptSuggestion(String id, String applicationId) async {
    final s = await _take(id);
    await _applyStatus(applicationId, status: s.status, said: s.said, at: s.at, eventId: signalRowId(s.id));
  }

  /// The user applied for it on the network, not in Udyoga: the job and an
  /// application for it are added, then the status. Returns the
  /// application's id.
  Future<String> addSuggestionAsApplication(String id, {required String today}) async {
    final s = await _take(id);
    final job = s.job;
    final posting = _posting(
      HandoffSignal(kind: 'job_alert', source: 'linkedin', id: s.id, sentAt: DateTime.parse(s.at), job: job),
    );
    await importPostings([posting], await profile(), today: today);
    final j =
        await (db.select(db.jobListings)
              ..where((x) => x.source.equals(helperJobSource) & x.sourceId.equals(posting.sourceId))
              ..limit(1))
            .getSingleOrNull();
    final String appId;
    if (j != null) {
      appId = await applyFor(j, today: today);
    } else {
      // Ruled out by the user's exclusions or dismissed: the application
      // stands alone.
      appId = newId();
      await save(
        db.jobApplications,
        JobApplicationsCompanion.insert(
          id: appId,
          title: job.title.isEmpty ? 'Job ${job.id}' : job.title,
          company: Value(job.company),
          location: Value(job.location),
          url: Value(job.url),
          updated: today,
        ),
        appId,
      );
    }
    if (s.status != 'applied') {
      await moveTo(
        appId,
        Stage.applied,
        date: s.at.substring(0, 10),
        summary: 'Applied on LinkedIn (via helper app)',
      );
    }
    await _applyStatus(appId, status: s.status, said: s.said, at: s.at, eventId: signalRowId(s.id));
    return appId;
  }

  Future<void> dismissSuggestion(String id) => _take(id);

  // ---- people

  /// A new connection or a profile view: the person joins the contacts
  /// (or the known contact gets the profile link and a note). Null when
  /// already done.
  Future<bool?> _person(HandoffSignal s, {required String today}) async {
    final people = await (db.select(db.careerContacts)..where((c) => c.deleted.not())).get();
    final handles = await (db.select(db.contactHandles)..where((h) => h.deleted.not())).get();
    final key = handleKey('linkedin', s.profileUrl);
    if (key.isNotEmpty && suppressionKeys(people, handles).contains(key)) return false;
    final byId = {for (final p in people) p.id: p};
    Lead? known;
    if (key.isNotEmpty) {
      known =
          people.where((p) => handleKey('linkedin', p.linkedin) == key).firstOrNull ??
          byId[handles.where((h) => handleKey(h.channel, h.handle) == key).firstOrNull?.contactId];
    }
    if (known == null) {
      final named = people.where((p) => _name(p.name) == _name(s.name)).toList();
      if (named.length == 1) known = named.single;
    }
    final note = s.kind == 'profile_view'
        ? 'Viewed your profile on ${niceDate(s.date)}'
        : 'Accepted your LinkedIn invitation on ${niceDate(s.date)}';
    if (known != null) {
      if (known.doNotContact) return false;
      final notes = known.notes.contains(note)
          ? known.notes
          : [known.notes, note].where((x) => x.isNotEmpty).join('\n');
      final fresh = known.copyWith(
        linkedin: known.linkedin.isEmpty ? s.profileUrl : known.linkedin,
        title: known.title.isEmpty ? s.headline : known.title,
        company: known.company.isEmpty ? s.company : known.company,
        notes: notes,
      );
      if (fresh == known) return null;
      await save(db.careerContacts, fresh, known.id);
      if (s.profileUrl.isNotEmpty) await syncHandles(fresh);
      return true;
    }
    final added = await importLeads(
      [
        LeadSuggestion({
          'name': s.name,
          'title': s.headline,
          'company': s.company,
          'kind': 'other',
          'linkedin': s.profileUrl,
          'source': 'LinkedIn (helper app)',
          'sourceUrl': s.profileUrl,
          'why': note,
        }),
      ],
      today: today,
      chase: false,
      sourceKind: s.kind == 'profile_view' ? 'inbound' : 'other',
    );
    if (added == 0) return null;
    if (s.profileUrl.isNotEmpty) {
      final c =
          await (db.select(db.careerContacts)
                ..where((c) => c.linkedin.equals(s.profileUrl) & c.deleted.not())
                ..limit(1))
              .getSingleOrNull();
      if (c != null) await syncHandles(c);
    }
    return true;
  }
}
