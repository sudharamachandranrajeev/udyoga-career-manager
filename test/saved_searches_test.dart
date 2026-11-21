// Saved role searches (role search plan U3): old profiles move over to
// exact-title searches once, the routine refresh runs saved searches, and
// each counts the listed jobs new since the last look. Made-up data only.
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/refresh.dart';
import 'package:udyoga/domain/role_family.dart';
import 'package:udyoga/domain/saved_searches.dart';

import 'app_harness.dart';
import 'support.dart';

const today = '2026-11-21';
const now = '2026-11-21T09:00:00Z';

/// A job feed that records what it is asked and answers with [answer].
class _FakeFeed extends JobFeed {
  _FakeFeed(this.id, {this.answer = const [], this.most = 6});
  @override
  final String id;
  final List<Posting> answer;
  final int? most;
  final asked = <FeedQuery>[];

  @override
  String get name => 'Fake $id';
  @override
  bool get usesPlace => true;
  @override
  int? get maxTerms => most;
  @override
  bool covers(FeedQuery q) => q.country == 'GB';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    asked.add(q);
    return answer;
  }
}

Posting _post(String title, {String company = 'Example Council', String? id}) => Posting(
  source: 'reed',
  sourceId: id ?? '$title-$company',
  title: title,
  company: company,
  location: 'Exampletown',
  country: 'GB',
  description: 'A made-up advert.',
);

FamilyTitle _title(String t, [Closeness c = Closeness.close]) =>
    FamilyTitle(title: t, reason: 'Made up for the test', closeness: c, source: FamilySource.soc);

/// The profile an older Udyoga saved: written straight to the pref, so
/// nothing has moved it over yet.
Future<void> _oldProfile(CareerBook b, CandidateProfile p) => b.setPref(PrefKeys.profile, p.toJson());

void main() {
  late CareerBook book;
  setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));
  tearDown(() => book.db.close());

  group('moving old profiles over', () {
    test('each keyword becomes one exact-title search, once', () async {
      await _oldProfile(
        book,
        sampleProfile.copyWith(
          targets: sampleProfile.targets.copyWith(keywords: ['IT Trainer', 'Clinical Systems Trainer']),
        ),
      );
      expect(await book.migrateSavedSearches(now: now), 2);
      final s = await book.savedSearches();
      expect(s.map((x) => x.role), ['IT Trainer', 'Clinical Systems Trainer']);
      for (final x in s) {
        expect(x.exactOnly, isTrue, reason: 'family expansion starts off');
        expect(x.query.searched.map((t) => t.title), [x.role]);
        expect(x.origin, SearchOrigin.profile);
        expect(x.places, isEmpty, reason: 'the profile home areas');
        expect(x.id, profileSearchId(x.role));
      }
      // Run again (or on another device after sync): nothing more.
      expect(await book.migrateSavedSearches(now: now), 0);
      expect(await book.savedSearches(), hasLength(2));
      expect(await book.pref<bool>(PrefKeys.searchesMoved, false), isTrue);
    });

    test('without keywords the target roles move, else the current role', () async {
      await _oldProfile(book, sampleProfile);
      await book.migrateSavedSearches(now: now);
      expect((await book.savedSearches()).map((s) => s.role), sampleProfile.targets.roles);

      final other = CareerBook(await Store.open(memoryDatabase()));
      addTearDown(other.db.close);
      await _oldProfile(other, sampleProfile.copyWith(targets: const Targets(countries: ['GB'])));
      await other.migrateSavedSearches(now: now);
      expect((await other.savedSearches()).map((s) => s.role), ['Staff Nurse']);
    });

    test('a profile with no search term moves nothing and waits', () async {
      await _oldProfile(book, const CandidateProfile(name: 'Sam Sample'));
      expect(await book.migrateSavedSearches(now: now), 0);
      expect(await book.pref<bool>(PrefKeys.searchesMoved, false), isFalse);
    });

    test('a deleted search is not brought back by running the move again', () async {
      await _oldProfile(book, sampleProfile);
      await book.migrateSavedSearches(now: now);
      await book.removeSavedSearch(profileSearchId('Clinical Informatics Nurse'));
      await book.db.customStatement("DELETE FROM prefs WHERE id = '${PrefKeys.searchesMoved}'");
      await book.migrateSavedSearches(now: now);
      expect((await book.savedSearches()).map((s) => s.role), ['Digital Nurse Specialist']);
    });

    test('a term added to the profile becomes a search; one taken out goes, unless edited', () async {
      await book.saveProfile(sampleProfile);
      expect(await book.savedSearches(), hasLength(2));
      final edited = (await book.savedSearches()).last;
      await book.saveSearch(edited.copyWith(notWords: ['bank'], origin: SearchOrigin.user));
      await book.saveProfile(
        sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(roles: ['Clinical Safety Officer'])),
      );
      expect((await book.savedSearches()).map((s) => s.role), [
        'Digital Nurse Specialist',
        'Clinical Safety Officer',
      ]);
      // Added back: the search returns.
      await book.saveProfile(sampleProfile);
      expect((await book.savedSearches()).map((s) => s.role), contains('Clinical Informatics Nurse'));
    });
  });

  group('the routine refresh', () {
    test('runs each saved search: its titles switched on, its NOT words and employers', () async {
      await book.saveProfile(sampleProfile.copyWith(targets: const Targets(countries: ['GB'])));
      for (final s in await book.savedSearches()) {
        await book.removeSavedSearch(s.id);
      }
      await book.saveSearch(
        SavedSearch(
          id: 'trainer',
          name: 'Trainer jobs',
          role: 'Digital Training Facilitator',
          titles: [
            SearchTitle(_title('Clinical Systems Trainer')),
            SearchTitle(_title('IT Trainer')),
            SearchTitle(_title('AI Coach', Closeness.related), on: false),
          ],
          notWords: const ['senior'],
          notEmployers: const ['Example Recruitment'],
          created: now,
        ),
      );
      final feed = _FakeFeed(
        'reed',
        answer: [
          _post('Clinical Systems Trainer'),
          _post('Senior IT Trainer'),
          _post('IT Trainer', company: 'Example Recruitment Ltd'),
        ],
      );
      final r = await Refresher(book, quietClient(), feeds: [feed]).run(today: today, force: true);
      final q = feed.asked.single;
      expect(q.terms, ['Digital Training Facilitator', 'Clinical Systems Trainer', 'IT Trainer']);
      expect(q.terms, isNot(contains('AI Coach')));
      expect(q.keep, contains('Clinical Systems Trainer'));
      expect(r.added, 1);
      final jobs = await book.db.select(book.db.jobListings).get();
      expect(jobs.map((j) => j.title), ['Clinical Systems Trainer']);
    });

    test('a moved profile sends each feed the same terms as before', () async {
      final p = sampleProfile.copyWith(
        targets: const Targets(countries: ['GB'], keywords: ['IT Trainer', 'Clinical Systems Trainer']),
      );
      await book.saveProfile(p);
      final searches = await book.savedSearches();
      final feed = _FakeFeed('reed');
      final before = Refresher.plan(p, [feed], const []);
      final after = Refresher.plan(p, [feed], searches);
      List<String> terms(Map<JobFeed, List<({FeedQuery query, SavedSearch? search})>> plan) => [
        for (final a in plan[feed]!) ...a.query.terms,
      ];
      expect(terms(after), terms(before));
      expect([for (final a in after[feed]!) a.query.keep], [null, null], reason: 'the strict NHS check');
    });

    test('many searches share the same room per site, each role first', () async {
      const p = CandidateProfile(
        currentRole: 'Staff Nurse',
        targets: Targets(countries: ['GB']),
      );
      final searches = [
        for (final role in ['IT Trainer', 'Clinical Coder', 'Data Analyst'])
          SavedSearch(
            id: role,
            name: role,
            role: role,
            titles: [SearchTitle(_title('$role One')), SearchTitle(_title('$role Two'))],
            created: now,
          ),
      ];
      final capped = _FakeFeed('reed');
      final open = _FakeFeed('arbeitnow', most: null);
      final plan = Refresher.plan(p, [capped, open], searches);
      final sent = [for (final a in plan[capped]!) ...a.query.terms];
      expect(sent, hasLength(Refresher.refreshTerms));
      // Every search's role goes out before any search's second title.
      expect(
        [for (final a in plan[capped]!) a.query.terms.first],
        ['IT Trainer', 'Clinical Coder', 'Data Analyst'],
      );
      expect(plan[capped]!.first.query.terms, ['IT Trainer', 'IT Trainer One']);
      // A feed that filters one download takes every title.
      expect([for (final a in plan[open]!) ...a.query.terms], hasLength(9));
      // The next turn starts with another search.
      final next = Refresher.plan(p, [capped], searches, turn: 1);
      expect(next[capped]!.first.search!.role, 'Clinical Coder');
    });

    test('a saved search with its own places searches there', () {
      const p = CandidateProfile(
        country: 'GB',
        targets: Targets(countries: ['GB'], locations: ['Exampletown']),
      );
      final s = SavedSearch(
        id: 'x',
        name: 'x',
        role: 'IT Trainer',
        places: const [HomeArea(place: 'Sampleby', radiusMiles: 15)],
        created: now,
      );
      final feed = _FakeFeed('reed');
      final asked = Refresher.plan(p, [feed], [s])[feed]!.map((a) => a.query.place);
      expect(asked, ['Sampleby']);
      expect(Refresher.plan(p, [feed], const [])[feed]!.map((a) => a.query.place), ['Exampletown']);
    });
  });

  group('new since last look', () {
    test('counts new listed jobs it matches, and none after a look', () async {
      await book.saveProfile(sampleProfile.copyWith(targets: const Targets(countries: ['GB'])));
      await book.importPostings([_post('IT Trainer', id: 'old')], sampleProfile, today: today);
      final s = await book.saveSearch(
        SavedSearch(id: 'it', name: 'IT Trainer', role: 'IT Trainer', notWords: const ['bank'], created: now),
      );
      Future<int> fresh() async => (await book.savedSearches())
          .firstWhere((x) => x.id == s.id)
          .newSinceLook(await book.db.select(book.db.jobListings).get(), sampleProfile);
      expect(await fresh(), 0, reason: 'jobs listed before it was saved are not new');
      await book.importPostings(
        [
          _post('IT Trainer', company: 'Example College', id: 'a'),
          _post('Bank IT Trainer', id: 'b'),
          _post('Staff Nurse', id: 'c'),
          _post('Senior IT Trainer', company: 'Example Trust', id: 'd'),
        ],
        sampleProfile,
        today: today,
      );
      expect(await fresh(), 2);
      await book.markLooked(s.id, now: '2026-11-21T10:00:00Z');
      expect(await fresh(), 0);
      expect((await book.savedSearches()).firstWhere((x) => x.id == s.id).lastLooked, '2026-11-21T10:00:00Z');
      final added = await book.importPostings(
        [_post('IT Trainer', company: 'Example Library', id: 'e')],
        sampleProfile,
        today: today,
      );
      expect(await fresh(), 1);
      await book.setJobStatus(added.single, 'dismissed');
      expect(await fresh(), 0, reason: 'a dismissed job is not new');
    });

    test('with the family on, a switched-on title counts and a switched-off one does not', () {
      final s = SavedSearch(
        id: 'x',
        name: 'x',
        role: 'Digital Training Facilitator',
        titles: [SearchTitle(_title('IT Trainer')), SearchTitle(_title('AI Coach'), on: false)],
        created: now,
      );
      expect(s.matches('IT Trainer', 'Example Council', sampleProfile), isTrue);
      expect(s.matches('AI Coach', 'Example Council', sampleProfile), isFalse);
      expect(s.copyWith(exactOnly: true).matches('IT Trainer', 'Example Council', sampleProfile), isFalse);
    });
  });

  test('save, rename and delete; a search survives a round trip', () async {
    final s = SavedSearch(
      id: 'x',
      name: 'Trainer jobs',
      role: 'IT Trainer',
      titles: [SearchTitle(_title('ICT Trainer')), SearchTitle(_title('AI Coach'), on: false)],
      skills: const ['plan learning curriculum'],
      notWords: const ['senior'],
      notEmployers: const ['Example Recruitment'],
      places: const [HomeArea(place: 'Sampleby', radiusMiles: 10)],
      created: now,
    );
    await book.saveSearch(s);
    final back = (await book.savedSearches()).single;
    expect(back.name, 'Trainer jobs');
    expect(back.onTitles.map((t) => t.title), ['ICT Trainer']);
    expect(back.titles.last.on, isFalse);
    expect(back.skills, s.skills);
    expect(back.notWords, s.notWords);
    expect(back.notEmployers, s.notEmployers);
    expect(back.places.single.place, 'Sampleby');
    expect(back.places.single.radiusMiles, 10);
    await book.saveSearch(back.copyWith(name: 'Teaching IT'));
    expect((await book.savedSearches()).single.name, 'Teaching IT');
    await book.removeSavedSearch('x');
    expect(await book.savedSearches(), isEmpty);
    final row = await book.db.select(book.db.careerSavedSearches).getSingle();
    expect(row.deleted, isTrue, reason: 'a tombstone, so the delete syncs');
  });

  test(
    'a schema 11 database gains the saved searches table without losing data, and can run again',
    () async {
      final dir = await Directory.systemTemp.createTemp('udyoga_migrate12');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      var b = CareerBook(await Store.open(db));
      await _oldProfile(b, sampleProfile);
      await b.importPostings([_post('Clinical Informatics Nurse', id: 'kept')], sampleProfile, today: today);
      await db.customStatement('DROP TABLE career_saved_searches');
      await db.customStatement('PRAGMA user_version = 11');
      await db.close();
      for (var i = 0; i < 2; i++) {
        db = AppDatabase(NativeDatabase(file));
        b = CareerBook(await Store.open(db));
        expect((await b.db.select(b.db.jobListings).get()).single.title, 'Clinical Informatics Nurse');
        expect((await b.profile()).targets.roles, sampleProfile.targets.roles);
        await b.migrateSavedSearches(now: now);
        expect((await b.savedSearches()).map((s) => s.role), sampleProfile.targets.roles);
        await db.customStatement('PRAGMA user_version = 11');
        await db.close();
      }
    },
  );

  testWidgets('the Jobs page lists saved searches with new jobs, runs, saves and deletes them on a phone', (
    tester,
  ) async {
    final h = AppHarness(tester);
    await h.open(
      seed: (b) async {
        await b.saveProfile(sampleProfile);
        await b.importPostings([samplePosting()], sampleProfile, today: today);
      },
    );
    h.phone();
    await h.run();
    await h.go('Jobs');
    expect(find.text('Saved searches'), findsOneWidget);
    expect(find.text('Clinical Informatics Nurse · 1 new'), findsOneWidget);
    expect(find.text('Digital Nurse Specialist'), findsOneWidget);

    // Tap: search mode, filled in and run; the job no longer counts as new.
    await h.tap(find.text('Clinical Informatics Nurse · 1 new'));
    await h.settle();
    expect(find.text('Clinical Informatics Nurse'), findsWidgets);
    expect(find.text('Clinical Informatics Nurse · 1 new'), findsNothing);
    expect(find.text('Update saved search'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Exact title only')).value,
      isTrue,
    );

    // Delete one through its menu.
    await h.tap(find.byTooltip('Edit or delete').last);
    await h.tapText('Delete');
    await h.tap(find.widgetWithText(FilledButton, 'Delete'));
    expect(find.text('Digital Nurse Specialist'), findsNothing);

    // Rename the other.
    await h.tap(find.byTooltip('Edit or delete').first);
    await h.tapText('Edit or rename');
    await h.enter('Name', 'Informatics jobs');
    await h.tap(find.widgetWithText(FilledButton, 'Save'));
    expect(find.text('Informatics jobs'), findsOneWidget);

    // A new role saved from search mode joins the row.
    await tester.enterText(find.byKey(const ValueKey('roleSearch.role')), 'IT Trainer');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle();
    expect(find.text('Save this search'), findsOneWidget, reason: 'another role is another search');
    await h.tap(find.byKey(const ValueKey('roleSearch.save')));
    expect(find.widgetWithText(InputChip, 'IT Trainer'), findsOneWidget);
    final saved = await tester.runAsync(() => h.book.savedSearches());
    expect(saved!.map((s) => s.name), ['Informatics jobs', 'IT Trainer']);
    expect(saved.last.exactOnly, isFalse);
    expect(saved.last.onTitles, isNotEmpty);
    await h.close();
  });
}
