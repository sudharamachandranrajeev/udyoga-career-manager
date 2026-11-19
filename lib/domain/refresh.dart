import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:http/http.dart' as http;

import 'advisor.dart';
import 'ats.dart';
import 'book.dart';
import 'career_file.dart';
import 'employers.dart';
import 'feeds.dart';
import 'insights.dart';
import 'json.dart';
import 'profile.dart';
import 'recipes.dart';
import 'route_refresh.dart';
import 'sponsors.dart';

/// What a refresh did.
class RefreshReport {
  int found = 0;
  int added = 0;
  int ghosted = 0;
  bool aiSearched = false;
  bool mapRefreshed = false;

  /// The live route tables (GOV.UK, IRCC) were read this run.
  bool routesRead = false;

  /// The feeds were due and at least one answered (or none applied).
  bool feedsChecked = false;

  /// Another device holds the AI routine, so this one left it.
  bool aiElsewhere = false;
  final problems = <String>[];

  String get summary => [
    if (added > 0) '$added new ${added == 1 ? 'job' : 'jobs'}' else 'No new jobs',
    if (aiSearched) 'AI search done',
    if (mapRefreshed) 'career map updated',
    if (routesRead) 'route tables updated',
    if (ghosted > 0) '$ghosted marked no reply',
    if (problems.isNotEmpty) 'problems: ${problems.join('; ')}',
  ].join(' · ');
}

/// Which device runs the AI routine. Kept in a synced pref: the holder
/// renews it on each run, and when it lapses (the device was not opened)
/// another device takes over, so the AI spend is not doubled.
class AiLease {
  const AiLease({this.device = '', this.until, this.ran});
  final String device;
  final DateTime? until;

  /// The last successful AI run on any device.
  final DateTime? ran;

  /// Held by a device other than [me], and not lapsed at [now].
  bool heldElsewhere(String me, DateTime now) =>
      device.isNotEmpty && device != me && until != null && until!.isAfter(now);

  factory AiLease.fromJson(Json j) => AiLease(
    device: str(j['device']),
    until: DateTime.tryParse(str(j['until'])),
    ran: DateTime.tryParse(str(j['ran'])),
  );

  Json toJson() => {'device': device, 'until': until?.toIso8601String(), 'ran': ran?.toIso8601String()};
}

/// How long past its interval a device's claim on the AI routine lasts.
const leaseGrace = Duration(hours: 12);

/// Feeds are checked at most this often (Remotive asks for a few calls a day).
const feedInterval = Duration(hours: 6);

/// The career map is redone this often while the AI routine is on.
const mapAgeDays = 30;

/// The routine refresh: job feeds for every target country, then (when the
/// user turned the AI routine on and it is due) an AI web search, quick AI
/// scores for the new jobs and a fresh career map.
class Refresher {
  Refresher(
    this.book,
    this.client, {
    this.advisor,
    this.sponsors,
    this.secrets,
    this.watch,
    this.recipes,
    this.routes,
    this.leaseOnly = false,
  });
  final CareerBook book;
  final http.Client client;
  final Advisor? advisor;

  /// This device's keychain, for the USAJOBS and Jooble keys; null: none.
  final SecretStore? secrets;

  /// The employer watch, run with the feeds; null leaves it out.
  final EmployerWatch? watch;

  /// The user's fetch recipes, run with the feeds; null leaves them out.
  final Future<RecipeFetch?> Function()? recipes;

  /// The UK sponsor register, refreshed when the UK is a target; null
  /// leaves it alone.
  final SponsorStore? sponsors;

  /// The live route tables, re-read when a week old; null leaves them.
  final RouteRefresh? routes;

  /// A background run: the AI routine runs only when this device already
  /// holds the lease. It never takes the lease over, so a phone in a
  /// drawer does not start spending while the laptop is the one in use.
  final bool leaseOnly;

  /// Runs what is due; [force] runs the feeds (and, with [ai], the AI
  /// search) now regardless. A check that failed everywhere is not counted
  /// as done, so the next tick tries again.
  Future<RefreshReport> run({
    required String today,
    bool force = false,
    bool ai = false,
    Progress? onProgress,
  }) async {
    final report = RefreshReport();
    try {
      await CareerFile(book).applyFrom(await book.documentFolders(), today: today);
    } on Object catch (e) {
      report.problems.add('Career file: ${describeError(e)}');
    }
    final p = await book.profile();
    report.ghosted = await book.markGhosted(today);
    if (p.searchTerms.isEmpty) {
      report.problems.add('add a current role or target roles to your profile first');
      return report;
    }
    final now = DateTime.now();
    final db = book.db;

    final checked = DateTime.tryParse(await db.localSetting(LocalKeys.feedsChecked) ?? '');
    if (force || checked == null || now.difference(checked) >= feedInterval) {
      onProgress?.call('Checking job sites…');
      var (:added, :answered) = await _feeds(p, report, today);
      if (watch != null) {
        final watched = await book.watchedEmployers();
        if (watched.isNotEmpty) {
          onProgress?.call('Checking the employers you watch…');
          final w = await watch!.run(p, watched);
          report
            ..found += w.postings.length
            ..problems.addAll(w.problems);
          added = [...added, ...await book.importPostings(w.postings, p, today: today)];
          // The feeds count as checked when either part answered.
          if (!answered && w.asked > w.failed) answered = true;
        }
      }
      final fetch = await recipes?.call();
      if (fetch != null && fetch.recipes.any((r) => r.mode == RecipeMode.fetch)) {
        final r = await fetch.run(p, onProgress: onProgress);
        report
          ..found += r.postings.length
          ..problems.addAll(r.problems);
        added = [...added, ...await book.importPostings(r.postings, p, today: today)];
        if (!answered && r.asked > r.failed) answered = true;
      }
      report.added += added.length;
      if (answered) {
        report.feedsChecked = true;
        await db.setLocalSetting(LocalKeys.feedsChecked, now.toIso8601String());
      }
      if (added.isNotEmpty && advisor != null && await _routine() != 'off') {
        await _triage(p, added, report);
      }
    }

    if (sponsors != null && p.searchCountries.contains('GB')) {
      try {
        await sponsors!.refreshIfDue(now: now);
      } on Object catch (e) {
        report.problems.add('Sponsor register: ${describeError(e)}');
      }
    }

    if (routes != null) await _routes(report, now);

    final routine = await _routine();
    if (advisor != null && (ai || routine != 'off')) {
      final me = book.store.deviceId;
      final lease = AiLease.fromJson(await book.pref<Map<String, Object?>>(PrefKeys.aiLease, const {}));
      if (!ai && (lease.heldElsewhere(me, now) || (leaseOnly && lease.device != me))) {
        report.aiElsewhere = true;
        return report;
      }
      final local = DateTime.tryParse(await db.localSetting(LocalKeys.aiChecked) ?? '');
      final last = [
        local,
        lease.ran,
      ].whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      final every = routine == 'daily' ? const Duration(hours: 20) : const Duration(days: 6);
      if (ai || last == null || now.difference(last) >= every) {
        // Claim the routine first, so another device opened meanwhile waits.
        await book.setPref(
          PrefKeys.aiLease,
          AiLease(device: me, until: now.add(every + leaseGrace), ran: lease.ran).toJson(),
        );
        if (await _aiSearch(p, report, today, onProgress)) {
          await db.setLocalSetting(LocalKeys.aiChecked, now.toIso8601String());
          await book.setPref(
            PrefKeys.aiLease,
            AiLease(device: me, until: now.add(every + leaseGrace), ran: now).toJson(),
          );
          if (!ai) await _map(p, report, today, onProgress);
        }
      }
    }
    return report;
  }

  /// The UK appendix and Canada's rounds; each is read at most weekly, and
  /// a failure keeps the last good copy.
  Future<void> _routes(RefreshReport report, DateTime now) async {
    Future<List<String?>> cached() async => [
      await book.db.localSetting(RouteRefresh.ukKey),
      await book.db.localSetting(RouteRefresh.roundsKey),
    ];
    final before = await cached();
    for (final (name, read) in [
      ('GOV.UK route table', () => routes!.refreshUk(now: now)),
      ('Express Entry rounds', () => routes!.refreshRounds(now: now)),
    ]) {
      try {
        await read();
      } on Object catch (e) {
        report.problems.add('$name: ${feedProblem(e)}');
      }
    }
    final after = await cached();
    report.routesRead = before[0] != after[0] || before[1] != after[1];
  }

  Future<String> _routine() => book.pref<String>(PrefKeys.aiRoutine, 'off');

  /// One query per target country, or one per home area in it (each with
  /// its radius); then one not tied to a country, for remote work and the
  /// UN jobs.
  static List<FeedQuery> queries(CandidateProfile p) => [
    for (final c in p.searchCountries)
      ...switch ([
        for (final a in p.targets.homeAreas)
          if ((a.country.isEmpty ? p.country : a.country) == c) a,
      ]) {
        final areas when areas.isNotEmpty => [
          for (final a in areas)
            FeedQuery(
              terms: p.searchTerms,
              country: c,
              place: a.place,
              radiusMiles: a.radiusMiles,
              remote: p.targets.remote,
            ),
        ],
        _ => [FeedQuery(terms: p.searchTerms, country: c, remote: p.targets.remote)],
      },
    FeedQuery(terms: p.searchTerms, country: '', remote: p.targets.remote),
  ];

  /// Asks every feed that covers a query; a feed that does not search by
  /// town is asked once per country. [answered] is false only when feeds
  /// were asked and every one failed.
  Future<({List<String> added, bool answered})> _feeds(
    CandidateProfile p,
    RefreshReport report,
    String today,
  ) async {
    final feeds = allFeeds(client, await (await book.feedKeys()).withSecrets(secrets));
    final postings = <Posting>[];
    var asked = 0, failed = 0;
    final once = <String>{};
    for (final q in queries(p)) {
      for (final f in feeds.where((f) => f.covers(q))) {
        if (!f.usesPlace && !once.add('${f.id}:${q.country}')) continue;
        asked++;
        try {
          postings.addAll(await f.search(q));
        } on Object catch (e) {
          failed++;
          report.problems.add('${f.name}: ${feedProblem(e)}');
        }
      }
    }
    report.found += postings.length;
    return (
      added: await book.importPostings(postings, p, today: today),
      answered: asked == 0 || failed < asked,
    );
  }

  Future<void> _triage(CandidateProfile p, List<String> ids, RefreshReport report) async {
    try {
      final jobs = [for (final id in ids.take(40)) await book.job(id)];
      await book.saveTriage(await advisor!.triage(p, jobs));
    } on Object catch (e) {
      report.problems.add('AI scoring: ${describeError(e)}');
    }
  }

  /// The AI web search; false when it failed.
  Future<bool> _aiSearch(CandidateProfile p, RefreshReport report, String today, Progress? onProgress) async {
    try {
      final known = await (book.db.select(
        book.db.jobListings,
      )..where((j) => j.deleted.not())).map((j) => j.url).get();
      final r = await advisor!.findJobs(
        p,
        countries: p.searchCountries,
        known: known.where((u) => u.isNotEmpty).toList(),
        onProgress: onProgress,
      );
      final found = objs(r.data['jobs']);
      final postings = [
        for (final j in found)
          Posting(
            source: 'ai',
            sourceId: str(j['url']),
            title: str(j['title']),
            company: str(j['company']),
            location: str(j['location']),
            country: str(j['country']).toUpperCase(),
            remote: j['remote'] == true,
            salaryText: str(j['salaryText']),
            url: str(j['url']),
            description: [
              str(j['description']),
              if (str(j['site']).isNotEmpty) 'Advertised on ${str(j['site'])}.',
            ].join('\n\n'),
            posted: str(j['posted']).length == 10 ? str(j['posted']) : null,
            closing: str(j['closing']).length == 10 ? str(j['closing']) : null,
          ),
      ];
      final added = await book.importPostings(postings, p, today: today);
      // The search scored its own finds; keep those scores for the new ones.
      final scores = <String, ({int fit, String why})>{};
      for (final id in added) {
        final job = await book.job(id);
        final match = found.where((j) => str(j['url']) == job.url).firstOrNull;
        if (match != null) {
          scores[id] = (fit: (intOf(match['fit']) ?? 0).clamp(0, 100), why: str(match['why']));
        }
      }
      await book.saveTriage(scores);
      report
        ..found += postings.length
        ..added += added.length
        ..aiSearched = true;
      return true;
    } on Object catch (e) {
      report.problems.add('AI search: ${describeError(e)}');
      return false;
    }
  }

  Future<void> _map(CandidateProfile p, RefreshReport report, String today, Progress? onProgress) async {
    final last = await book.latestReport('career_map');
    if (last != null && last.created.compareTo(addDays(today, -mapAgeDays)) > 0) return;
    try {
      final a = await book.latestReport('assessment');
      final r = await advisor!.careerMap(
        p,
        assessment: a == null ? null : Assessment(decodeObject(a.content)),
        onProgress: onProgress,
      );
      await book.saveReport('career_map', r.data, r.sources, at: today);
      report.mapRefreshed = true;
    } on Object catch (e) {
      report.problems.add('Career map: ${describeError(e)}');
    }
  }
}
