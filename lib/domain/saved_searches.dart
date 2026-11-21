/// Saved role searches (role search plan U3). Each target role becomes a
/// saved search: the role, the family titles the person switched on, NOT
/// words, employers to leave out and places. The routine refresh runs the
/// saved searches instead of the profile's flat list of search terms, and
/// the Jobs page shows how many listed jobs are new since the person last
/// looked at each one.
///
/// Old profiles move over once: each search term (the profile's keywords,
/// else its target roles, else the current role, as
/// [CandidateProfile.searchTerms] picks them) becomes one saved search for
/// that exact title only, so the jobs found do not change until the person
/// turns the other titles on. A term added to the profile later becomes a
/// saved search the same way; one removed from it takes its saved search
/// with it, unless the person has changed that search since.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'job_identity.dart';
import 'json.dart';
import 'profile.dart';
import 'role_family.dart';
import 'role_search.dart';

/// One family title in a saved search, and whether it is switched on.
class SearchTitle {
  const SearchTitle(this.title, {this.on = true});
  final FamilyTitle title;
  final bool on;

  Json toJson() => {...title.toJson(), 'on': on};

  factory SearchTitle.fromJson(Json j) => SearchTitle(FamilyTitle.fromJson(j), on: j['on'] != false);
}

/// Where a saved search came from.
abstract final class SearchOrigin {
  /// Made from a profile search term and not changed since.
  static const profile = 'profile';

  /// Saved or edited by the person.
  static const user = 'user';
}

/// The most job ids a saved search remembers as seen.
const maxSeen = 2000;

/// A saved role search.
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.role,
    this.titles = const [],
    this.exactOnly = false,
    this.skills = const [],
    this.notWords = const [],
    this.notEmployers = const [],
    this.places = const [],
    this.origin = SearchOrigin.user,
    required this.created,
    String? updated,
    this.lastLooked,
    this.seen = const [],
  }) : updated = updated ?? created;

  final String id;

  /// What the person calls it; the role until renamed.
  final String name;

  /// The role as typed.
  final String role;

  /// The family titles shown when it was saved, each on or off.
  final List<SearchTitle> titles;

  /// Search the typed title only: the family is not searched.
  final bool exactOnly;

  /// Tasks and tools searched as well.
  final List<String> skills;

  /// Words that rule a job out when its title or employer says one.
  final List<String> notWords;

  /// Employers and agencies whose jobs are left out.
  final List<String> notEmployers;

  /// Where to search; empty: the profile's home areas, as they are then.
  final List<HomeArea> places;

  /// A [SearchOrigin].
  final String origin;

  /// When it was saved and last changed (UTC, ISO 8601).
  final String created, updated;

  /// When the person last opened it; null: never.
  final String? lastLooked;

  /// Ids of the listed jobs it matched when last looked at.
  final List<String> seen;

  /// The family titles switched on.
  List<FamilyTitle> get onTitles => [
    for (final t in titles)
      if (t.on) t.title,
  ];

  /// What it asks the job sites.
  RoleQuery get query => RoleQuery(
    role: role,
    titles: onTitles,
    exactOnly: exactOnly,
    skills: skills,
    notWords: notWords,
    notEmployers: notEmployers,
    places: places,
  );

  /// True when a listed job with [title] at [company] belongs to this
  /// search: its title holds the role (or, with the family on, a title
  /// switched on), and neither the person's exclusions nor this search's
  /// NOT words and employers rule it out.
  bool matches(String title, String company, CandidateProfile p) {
    final q = query;
    return RoleSearch.matchOf(title, q).$1 != TitleMatch.other && !RoleSearch.excluded(title, company, p, q);
  }

  /// The listed jobs in [jobs] it matches (deleted ones never).
  List<Job> matching(Iterable<Job> jobs, CandidateProfile p) => [
    for (final j in jobs)
      if (!j.deleted && matches(j.title, j.company, p)) j,
  ];

  /// How many of [jobs] it matches that are still new (not saved, applied
  /// for or dismissed) and were not there when the person last looked.
  int newSinceLook(Iterable<Job> jobs, CandidateProfile p) {
    final had = seen.toSet();
    return matching(jobs, p).where((j) => j.status == 'new' && !had.contains(j.id)).length;
  }

  /// This search marked as looked at [now], with [jobs]' matches as seen.
  SavedSearch looked(Iterable<Job> jobs, CandidateProfile p, {required String now}) =>
      copyWith(lastLooked: now, seen: [for (final j in matching(jobs, p)) j.id]);

  SavedSearch copyWith({
    String? name,
    String? role,
    List<SearchTitle>? titles,
    bool? exactOnly,
    List<String>? skills,
    List<String>? notWords,
    List<String>? notEmployers,
    List<HomeArea>? places,
    String? origin,
    String? updated,
    String? lastLooked,
    List<String>? seen,
  }) => SavedSearch(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    titles: titles ?? this.titles,
    exactOnly: exactOnly ?? this.exactOnly,
    skills: skills ?? this.skills,
    notWords: notWords ?? this.notWords,
    notEmployers: notEmployers ?? this.notEmployers,
    places: places ?? this.places,
    origin: origin ?? this.origin,
    created: created,
    updated: updated ?? this.updated,
    lastLooked: lastLooked ?? this.lastLooked,
    seen: seen ?? this.seen,
  );

  factory SavedSearch.fromRow(SavedSearchRow r) => SavedSearch(
    id: r.id,
    name: r.name,
    role: r.role,
    titles: [for (final t in objs(decodeList(r.titles))) SearchTitle.fromJson(t)],
    exactOnly: r.exactOnly,
    skills: strs(decodeList(r.skills)),
    notWords: strs(decodeList(r.notWords)),
    notEmployers: strs(decodeList(r.notEmployers)),
    places: [
      for (final a in objs(decodeList(r.places)).map(HomeArea.fromJson))
        if (a.place.isNotEmpty) a,
    ],
    origin: r.origin,
    created: r.created,
    updated: r.updated,
    lastLooked: r.lastLooked,
    seen: strs(decodeList(r.seen)),
  );

  CareerSavedSearchesCompanion toRow() => CareerSavedSearchesCompanion.insert(
    id: id,
    name: name,
    role: role,
    titles: Value(jsonEncode([for (final t in titles) t.toJson()])),
    exactOnly: Value(exactOnly),
    skills: Value(jsonEncode(skills)),
    notWords: Value(jsonEncode(notWords)),
    notEmployers: Value(jsonEncode(notEmployers)),
    places: Value(jsonEncode([for (final a in places) a.toJson()])),
    origin: Value(origin),
    created: created,
    updated: updated,
    lastLooked: Value(lastLooked),
    seen: Value(jsonEncode(seen.length > maxSeen ? seen.sublist(seen.length - maxSeen) : seen)),
    deleted: const Value(false),
  );
}

/// The id of the saved search made from profile search term [term]. The
/// same on every device, so two devices moving the same profile over make
/// one search, not two.
String profileSearchId(String term) => 'term:${normalJobTitle(term)}';

String _now() => DateTime.now().toUtc().toIso8601String();

/// Saved searches on the book.
extension SavedSearchBook on CareerBook {
  /// The saved searches, oldest first.
  Future<List<SavedSearch>> savedSearches() async => [
    for (final r
        in await (db.select(db.careerSavedSearches)
              ..where((s) => s.deleted.not())
              ..orderBy([(s) => OrderingTerm.asc(s.created), (s) => OrderingTerm.asc(s.name)]))
            .get())
      SavedSearch.fromRow(r),
  ];

  Future<List<Job>> _listedJobs() => (db.select(db.jobListings)..where((j) => j.deleted.not())).get();

  CandidateProfile _stored(Map<String, Object?> j) => CandidateProfile.fromJson(j);

  /// Saves [s]. A new search starts with the jobs already listed counted
  /// as seen, so "new since last look" begins at nothing. An existing one
  /// keeps its stored last look and seen jobs: only [markLooked] changes
  /// them, so saving a copy read before a look cannot undo the look.
  Future<SavedSearch> saveSearch(SavedSearch s) async {
    final had = await (db.select(db.careerSavedSearches)..where((r) => r.id.equals(s.id))).getSingleOrNull();
    var out = s;
    if (had != null && !had.deleted) {
      final stored = SavedSearch.fromRow(had);
      out = SavedSearch(
        id: s.id,
        name: s.name,
        role: s.role,
        titles: s.titles,
        exactOnly: s.exactOnly,
        skills: s.skills,
        notWords: s.notWords,
        notEmployers: s.notEmployers,
        places: s.places,
        origin: s.origin,
        created: stored.created,
        updated: s.updated,
        lastLooked: stored.lastLooked,
        seen: stored.seen,
      );
    } else {
      final p = _stored(await pref<Map<String, Object?>>(PrefKeys.profile, const {}));
      out = s.copyWith(seen: [for (final j in s.matching(await _listedJobs(), p)) j.id]);
    }
    await save(db.careerSavedSearches, out.toRow(), out.id);
    return out;
  }

  /// Removes the saved search [id] from every device.
  Future<void> removeSavedSearch(String id) => remove(db.careerSavedSearches, id);

  /// Marks the saved search [id] as looked at now: the jobs it matches
  /// stop counting as new.
  Future<void> markLooked(String id, {String? now}) async {
    final r = await (db.select(db.careerSavedSearches)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (r == null || r.deleted) return;
    final p = _stored(await pref<Map<String, Object?>>(PrefKeys.profile, const {}));
    final s = SavedSearch.fromRow(r).looked(await _listedJobs(), p, now: now ?? _now());
    await save(db.careerSavedSearches, s.toRow(), s.id);
  }

  /// Adds one exact-title saved search for each of [terms] that has none
  /// yet. A removed one comes back only with [revive] (the term was just
  /// added to the profile again). Returns how many it added.
  Future<int> _addProfileSearches(
    Iterable<String> terms,
    CandidateProfile p,
    String now, {
    bool revive = false,
  }) async {
    final jobs = await _listedJobs();
    var added = 0;
    final done = <String>{};
    final at = DateTime.tryParse(now)?.toUtc();
    for (final t in terms) {
      final term = t.trim();
      if (term.isEmpty) continue;
      final id = profileSearchId(term);
      if (!done.add(id)) continue;
      final had = await (db.select(db.careerSavedSearches)..where((r) => r.id.equals(id))).getSingleOrNull();
      if (had != null && !(revive && had.deleted)) continue;
      final s = SavedSearch(
        id: id,
        name: term,
        role: term,
        exactOnly: true,
        origin: SearchOrigin.profile,
        // A millisecond apart, so they list in the profile's order.
        created: at?.add(Duration(milliseconds: added)).toIso8601String() ?? now,
      );
      await save(
        db.careerSavedSearches,
        s.copyWith(seen: [for (final j in s.matching(jobs, p)) j.id]).toRow(),
        id,
      );
      added++;
    }
    return added;
  }

  /// Moves an old profile over to saved searches, once: each search term
  /// becomes a saved search for that exact title only. Does nothing until
  /// the profile has a search term, and nothing after it has run (on any
  /// device: the mark syncs). Returns how many searches it added.
  Future<int> migrateSavedSearches({String? now}) async {
    if (await pref<bool>(PrefKeys.searchesMoved, false)) return 0;
    final p = _stored(await pref<Map<String, Object?>>(PrefKeys.profile, const {}));
    if (p.searchTerms.isEmpty) return 0;
    final added = await _addProfileSearches(p.searchTerms, p, now ?? _now());
    await setPref(PrefKeys.searchesMoved, true);
    return added;
  }

  /// Keeps the saved searches in step with a profile change from [before]
  /// to [after]: a new search term becomes an exact-title saved search,
  /// and a term taken out removes the search made from it, unless the
  /// person has changed that search. Before the move has run, it runs the
  /// move instead.
  Future<void> followProfileTerms(CandidateProfile before, CandidateProfile after, {String? now}) async {
    if (!await pref<bool>(PrefKeys.searchesMoved, false)) {
      await migrateSavedSearches(now: now);
      return;
    }
    final was = {for (final t in before.searchTerms) normalJobTitle(t)};
    final kept = {for (final t in after.searchTerms) normalJobTitle(t)};
    await _addProfileSearches(
      after.searchTerms.where((t) => !was.contains(normalJobTitle(t))),
      after,
      now ?? _now(),
      revive: true,
    );
    for (final t in before.searchTerms) {
      if (kept.contains(normalJobTitle(t))) continue;
      final id = profileSearchId(t);
      final r = await (db.select(db.careerSavedSearches)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (r != null && !r.deleted && r.origin == SearchOrigin.profile) await removeSavedSearch(id);
    }
  }
}
