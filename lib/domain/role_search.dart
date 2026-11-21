/// Role search: one role, and the job titles the same work goes by, looked
/// for on every job site that covers the person's countries and home areas,
/// live. The titles come from the role's family (lib/domain/role_family.dart)
/// and are the ones the person left switched on, so nothing is added out of
/// sight. Results are ranked by how the title matched (the exact title, a
/// family title, or neither), then by fit, never by anything else; the same
/// job on several boards is one result with every board's link.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart' show SecretStore;
import 'package:http/http.dart' as http;

import 'book.dart';
import 'eligibility.dart';
import 'feeds.dart';
import 'job_identity.dart';
import 'matching.dart';
import 'profile.dart';
import 'refresh.dart';
import 'role_family.dart';

/// What one role search asks for.
class RoleQuery {
  const RoleQuery({
    required this.role,
    this.titles = const [],
    this.exactOnly = false,
    this.skills = const [],
    this.notWords = const [],
    this.notEmployers = const [],
  });

  /// The role as the person typed it.
  final String role;

  /// The family titles the person left switched on. The typed role is
  /// always searched, whether or not it is among them.
  final List<FamilyTitle> titles;

  /// Search for the typed title only, and keep only results whose title
  /// holds it.
  final bool exactOnly;

  /// Tasks and tools to search for as well ("Also search tasks/tools").
  final List<String> skills;

  /// Words that rule a result out when its title or employer says one.
  final List<String> notWords;

  /// Employers and agencies whose jobs are left out.
  final List<String> notEmployers;

  /// The typed role as a family title.
  FamilyTitle get typed => FamilyTitle(
    title: role.trim(),
    reason: 'The title you searched for',
    closeness: Closeness.close,
    source: FamilySource.typed,
  );

  /// The titles searched: the typed role first, then the chosen titles,
  /// close before related before distant, each once (any case). Only the
  /// typed role with [exactOnly].
  List<FamilyTitle> get searched {
    if (exactOnly) return [typed];
    final seen = <String>{normalJobTitle(role)};
    final rest = [
      for (final c in Closeness.values)
        for (final t in titles)
          if (t.closeness == c && t.source != FamilySource.typed && seen.add(normalJobTitle(t.title))) t,
    ];
    return [typed, ...rest];
  }

  /// The search terms for one feed that takes at most [cap] (null: any
  /// number): the closest titles first, then up to two tasks or tools so
  /// a chosen skill is never crowded out.
  List<String> termsFor(int? cap) {
    final titles = [for (final t in searched) t.title];
    final extra = exactOnly ? const <String>[] : skills.where((s) => s.trim().isNotEmpty).toList();
    if (cap == null) return [...titles, ...extra];
    final skillSlots = math.min(extra.length, extra.isEmpty ? 0 : (cap >= 4 ? 2 : 1));
    final titleSlots = math.max(1, cap - skillSlots);
    final picked = titles.take(titleSlots).toList();
    return [...picked, ...extra.take(cap - picked.length)];
  }

  /// The titles NHS Jobs accepts (see [FeedQuery.keep]): every searched
  /// title, or null (the strict check) with [exactOnly].
  List<String>? get keep => exactOnly ? null : [for (final t in searched) t.title];
}

/// How a result's title matched the search.
enum TitleMatch {
  /// It holds the title the person typed.
  exact,

  /// It holds one of the chosen family titles.
  family,

  /// Neither: the site found it by a task or tool, or matched loosely.
  other,
}

/// One job in the results: the same job from every board that has it.
class RoleHit {
  const RoleHit({
    required this.postings,
    required this.match,
    required this.matched,
    required this.fit,
    this.why = '',
  });

  /// The adverts for this job, the fullest first.
  final List<Posting> postings;
  final TitleMatch match;

  /// The title that matched; null for [TitleMatch.other].
  final FamilyTitle? matched;

  /// The quick match to the person's profile, 0 to 100.
  final int fit;

  /// Why it is in the results, in plain words.
  final String why;

  /// The fullest advert.
  Posting get main => postings.first;

  /// Each board's link, once per board and link.
  List<({String source, String url})> get links {
    final seen = <String>{};
    return [
      for (final p in postings)
        if (p.url.isNotEmpty && seen.add(p.url)) (source: p.source, url: p.url),
    ];
  }

  /// The advert to save: the fullest one, with the other boards' links
  /// added to its text so they are not lost.
  Posting toSave() {
    final others = links.where((l) => l.url != main.url).toList();
    if (others.isEmpty) return main;
    final p = main;
    return Posting(
      source: p.source,
      sourceId: p.sourceId,
      title: p.title,
      company: p.company,
      location: p.location,
      country: p.country,
      remote: p.remote,
      salaryMin: p.salaryMin,
      salaryMax: p.salaryMax,
      currency: p.currency,
      salaryText: p.salaryText,
      url: p.url,
      description: [
        p.description,
        'Also advertised at: ${others.map((l) => l.url).join(' ; ')}',
      ].where((s) => s.isNotEmpty).join('\n\n'),
      posted: p.posted,
      closing: p.closing,
    );
  }
}

/// Where one feed is in a search.
enum FeedState { waiting, running, done, failed }

/// One feed's progress in a search.
class FeedRun {
  FeedRun(this.id, this.name);
  final String id, name;
  var state = FeedState.waiting;

  /// Adverts it gave, before exclusions and merging.
  var found = 0;

  /// What went wrong, in a few words; empty when nothing did.
  var problem = '';
}

/// What a role search found.
class RoleSearchResult {
  const RoleSearchResult({required this.hits, required this.feeds, required this.leftOut});

  /// Ranked: exact title, then family title, then the rest; best fit first
  /// within each.
  final List<RoleHit> hits;
  final List<FeedRun> feeds;

  /// Adverts left out by the person's exclusions and this search's NOT
  /// words and employers.
  final int leftOut;
}

/// Runs role searches. Keep one for the screen: answers are kept for
/// [cacheFor], so searching again with the same titles asks no site twice.
class RoleSearch {
  RoleSearch(this.book, this.client, {this.secrets, this.feeds, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final CareerBook book;
  final http.Client client;

  /// This device's keychain, for the USAJOBS and Jooble keys; null: none.
  final SecretStore? secrets;

  /// The feeds to ask; null: every feed, with the person's keys.
  final List<JobFeed>? feeds;
  final DateTime Function() _clock;

  /// The most titles one feed is asked about in one search, closest first:
  /// each title is a request (or a few), and the sites are shared.
  static const maxTitlesPerFeed = 6;

  /// How long a feed's answer is reused.
  static const cacheFor = Duration(minutes: 15);

  final _cache = <String, (DateTime, List<Posting>)>{};

  /// Searches every feed that covers the person's countries and home areas
  /// for [q]; [onProgress] hears each feed start and finish.
  Future<RoleSearchResult> run(
    RoleQuery q, {
    required String today,
    void Function(List<FeedRun> feeds)? onProgress,
  }) async {
    final p = await book.profile();
    final all = feeds ?? allFeeds(client, await (await book.feedKeys()).withSecrets(secrets));
    // Each feed's queries; a feed that does not search by town is asked
    // once per country.
    final plan = <JobFeed, List<FeedQuery>>{};
    final once = <String>{};
    for (final fq in Refresher.queries(p, terms: q.termsFor(null), keep: q.keep)) {
      for (final f in all.where((f) => f.covers(fq))) {
        if (!f.usesPlace && !once.add('${f.id}:${fq.country}')) continue;
        final cap = f.maxTerms == null ? null : math.min(f.maxTerms!, maxTitlesPerFeed);
        plan.putIfAbsent(f, () => []).add(fq.withTerms(q.termsFor(cap), keep: q.keep));
      }
    }
    final runs = {for (final f in plan.keys) f: FeedRun(f.id, f.name)};
    final progress = runs.values.toList();
    onProgress?.call(progress);

    final postings = <Posting>[];
    // Each feed is a different site, so they are asked side by side; one
    // feed's own requests go one after another.
    await Future.wait([
      for (final MapEntry(key: f, value: queries) in plan.entries)
        () async {
          final run = runs[f]!..state = FeedState.running;
          onProgress?.call(progress);
          var failed = 0;
          for (final fq in queries) {
            try {
              final got = await _search(f, fq);
              run.found += got.length;
              postings.addAll(got);
            } on Object catch (e) {
              failed++;
              run.problem = feedProblem(e);
            }
          }
          run.state = failed == queries.length ? FeedState.failed : FeedState.done;
          onProgress?.call(progress);
        }(),
    ]);

    final kept = [
      for (final x in postings)
        if (!_leftOut(x, p, q)) x,
    ];
    final hits = rank(merge(kept), q, p, today: today);
    return RoleSearchResult(hits: hits, feeds: progress, leftOut: postings.length - kept.length);
  }

  /// A feed's answer, from the cache when it is recent.
  Future<List<Posting>> _search(JobFeed f, FeedQuery fq) async {
    final key = [
      f.id,
      fq.country,
      fq.place,
      fq.radiusMiles,
      fq.remote,
      fq.terms.join('\u0001'),
      fq.keep?.join('\u0001'),
    ].join('|');
    final now = _clock();
    final hit = _cache[key];
    if (hit != null && now.difference(hit.$1) < cacheFor) return hit.$2;
    final got = await f.search(fq);
    _cache[key] = (now, got);
    return got;
  }

  /// True when the person's exclusions, or this search's NOT words or
  /// employers, rule [x] out.
  static bool _leftOut(Posting x, CandidateProfile p, RoleQuery q) =>
      excludedBy(p.targets.exclusions, title: x.title, company: x.company) != null ||
      excludedBy(q.notWords, title: x.title, company: x.company) != null ||
      q.notEmployers.any((e) => e.trim().isNotEmpty && hasWords(x.company, e.trim()));

  /// [postings] with the same job from several boards (or several searches)
  /// merged: the same board and id, the same link, or the same [jobKey] and
  /// closing date (when both give one). Each group's fullest advert first.
  static List<List<Posting>> merge(List<Posting> postings) {
    final groups = <List<Posting>>[];
    final bySource = <String, List<Posting>>{};
    final byUrl = <String, List<Posting>>{};
    final byKey = <String, List<List<Posting>>>{};
    for (final x in postings) {
      final same = bySource['${x.source}:${x.sourceId}'] ?? (x.url.isEmpty ? null : byUrl[x.url]);
      // Asked again for another title or area: the same advert.
      if (same != null) continue;
      final key = jobKey(title: x.title, company: x.company, location: x.location);
      final group = key.isEmpty
          ? null
          : byKey[key]?.where((g) {
              final closing = g.map((y) => y.closing).nonNulls.firstOrNull;
              return closing == null || x.closing == null || closing == x.closing;
            }).firstOrNull;
      final g = group ?? <Posting>[];
      if (group == null) {
        groups.add(g);
        if (key.isNotEmpty) byKey.putIfAbsent(key, () => []).add(g);
      }
      g.add(x);
      bySource['${x.source}:${x.sourceId}'] = g;
      if (x.url.isNotEmpty) byUrl[x.url] = g;
    }
    int richness(Posting x) =>
        x.description.length + (x.salaryMin != null || x.salaryMax != null ? 100000 : 0);
    return [for (final g in groups) g..sort((a, b) => richness(b).compareTo(richness(a)))];
  }

  /// True when [title] holds [phrase] as whole words (a plural allowed),
  /// whatever its punctuation ("E-learning" and "Elearning" alike).
  static bool _holds(String title, String phrase) =>
      mentions(title, phrase) || ' ${normalJobTitle(title)} '.contains(' ${normalJobTitle(phrase)} ');

  /// How [title] matched [q], and the title it matched.
  static (TitleMatch, FamilyTitle?) matchOf(String title, RoleQuery q) {
    final searched = q.searched;
    if (_holds(title, q.role)) return (TitleMatch.exact, searched.first);
    for (final t in searched.skip(1)) {
      if (_holds(title, t.title)) return (TitleMatch.family, t);
    }
    return (TitleMatch.other, null);
  }

  /// [groups] as results, ranked by title match and then fit. With
  /// [RoleQuery.exactOnly], only exact title matches are kept.
  static List<RoleHit> rank(
    List<List<Posting>> groups,
    RoleQuery q,
    CandidateProfile p, {
    required String today,
  }) {
    final hits = <RoleHit>[];
    for (final g in groups) {
      final main = g.first;
      final (match, matched) = matchOf(main.title, q);
      if (q.exactOnly && match != TitleMatch.exact) continue;
      final fit = localFit(
        p,
        JobFacts(
          title: main.title,
          description: main.description,
          company: main.company,
          location: main.location,
          country: main.country,
          remote: main.remote,
          salaryMin: main.salaryMin,
          salaryMax: main.salaryMax,
          currency: main.currency,
          salaryText: main.salaryText,
        ),
        today: today,
      );
      hits.add(
        RoleHit(
          postings: g,
          match: match,
          matched: matched,
          fit: fit,
          why: switch (match) {
            TitleMatch.exact => 'The title you searched for',
            TitleMatch.family => matched!.reason,
            TitleMatch.other =>
              q.skills.isNotEmpty
                  ? 'Found by a task or tool search; the title is none of the chosen titles'
                  : 'The site matched it, but the title is none of the chosen titles',
          },
        ),
      );
    }
    hits.sort((a, b) {
      final c = a.match.index.compareTo(b.match.index);
      if (c != 0) return c;
      final f = b.fit.compareTo(a.fit);
      return f != 0 ? f : a.main.title.compareTo(b.main.title);
    });
    return hits;
  }
}
