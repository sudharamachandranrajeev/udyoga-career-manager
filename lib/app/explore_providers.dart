import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../domain/explore.dart';
import '../domain/feeds.dart';
import '../domain/occupations.dart';
import '../domain/profile.dart';
import '../domain/route_refresh.dart';
import '../domain/routes.dart';
import '../domain/tracks.dart';
import 'providers.dart';

/// The UK rules: read live from GOV.UK at most weekly, else the last good
/// copy on this device, else the shipped table. Never fails. Read once a
/// session; Explore's refresh button reads again.
final ukRulesProvider = FutureProvider<UkRules>((ref) async {
  final s = ref.watch(sessionProvider);
  final refresh = RouteRefresh(ref.watch(httpClientProvider), s.db);
  try {
    return await refresh.refreshUk();
  } on FeedException {
    return refresh.ukRules();
  }
});

/// Canada's latest Express Entry rounds, read at most weekly; null when
/// IRCC cannot be reached and none were read before.
final expressEntryProvider = FutureProvider<ExpressEntryRounds?>((ref) async {
  final s = ref.watch(sessionProvider);
  final refresh = RouteRefresh(ref.watch(httpClientProvider), s.db);
  try {
    return await refresh.refreshRounds();
  } on FeedException {
    return refresh.rounds();
  }
});

/// The job titles worth coding, from the profile.
List<String> titlesOf(CandidateProfile p) => titlesToCode(
  targets: p.targets.roles,
  current: p.currentRole,
  past: [for (final e in p.experience) e.title],
);

/// The person's job titles coded: SOC 2020 from the shipped index, ISCO-08
/// from ESCO where it was looked up before (the cache only; looking up is
/// a button, as it goes online).
final occupationsProvider = FutureProvider<List<OccupationMatch>>((ref) async {
  ref.watch(revisionProvider);
  final p = await ref.watch(profileProvider.future);
  final titles = titlesOf(p);
  final s = ref.watch(sessionProvider);
  await loadSocIndex();
  return EscoLookup(ref.watch(httpClientProvider), s.db).complete(titles, codeTitles(titles), offline: true);
});

/// Every country screened for the person.
final screensProvider = FutureProvider<List<CountryScreen>>((ref) async {
  final p = await ref.watch(profileProvider.future);
  final occupations = await ref.watch(occupationsProvider.future);
  final pay = await ref.watch(payBaselineProvider.future);
  final uk = await ref.watch(ukRulesProvider.future);
  return screenCountries(
    profile: p,
    today: today(),
    occupations: occupations,
    pay: expectedPay(p, baselineGbp: pay.pay),
    uk: uk,
  );
});

/// The person's route tracks.
final tracksProvider = FutureProvider<List<RouteTrack>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.tracks();
});
