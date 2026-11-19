/// The country screen: puts every country into Ready, Possible, Later or
/// Blocked for this person, from their rights, passports, languages, job
/// codes and pay against the route tables. Pure: no I/O, the same answer
/// for the same inputs, every tier with its reasons and blockers.
library;

import 'occupations.dart';
import 'profile.dart';
import 'routes.dart';
import 'work_rights.dart';
import 'world.dart';

enum Tier {
  ready('Ready', 'You may work there now.'),
  possible('Possible', 'A sourced route fits your jobs and pay.'),
  later('Later', 'A gap to close, or rules Udyoga has not verified.'),
  blocked('Blocked', 'Nothing open to you on the current rules.');

  const Tier(this.label, this.meaning);
  final String label, meaning;
}

/// How one route fits.
enum RouteFit { fits, gap, unknown, ineligible }

/// One route checked against the person.
class RouteCheck {
  const RouteCheck(this.route, this.fit, this.reasons, {this.floor, this.deadline});
  final VisaRoute route;
  final RouteFit fit;
  final List<String> reasons;

  /// The pay floor that applies to the person's best job code, if known.
  final Money? floor;

  /// The day this route closes to them, yyyy-MM-dd (the UK Temporary
  /// Shortage List cut-off).
  final String? deadline;
}

/// One country, screened.
class CountryScreen {
  const CountryScreen({
    required this.country,
    required this.tier,
    this.basis,
    this.reasons = const [],
    this.blockers = const [],
    this.routes = const [],
    this.deadline,
    this.target = false,
  });

  final WorldCountry country;
  final Tier tier;

  /// Why they may work there now, when they may.
  final String? basis;
  final List<String> reasons, blockers;
  final List<RouteCheck> routes;

  /// The day something ends: their right to work, or the route's cut-off.
  final String? deadline;

  /// One of the countries on their profile's targets.
  final bool target;

  String get code => country.code;
  bool get hasRoutes => routes.isNotEmpty;
}

/// The pay the person is after, a year: the target minimum in its currency,
/// else the pay baseline (Udyoga keeps that in GBP); null when neither.
Money? expectedPay(CandidateProfile p, {int baselineGbp = 0}) {
  final min = p.targets.salaryMin;
  if (min != null && min > 0) {
    final cur = p.targets.salaryCurrency.trim().toUpperCase();
    return Money(min, cur.isEmpty ? 'GBP' : cur);
  }
  return baselineGbp > 0 ? Money(baselineGbp, 'GBP') : null;
}

/// How well the person speaks one of [country]'s languages: true (B2 or
/// better in one), false (none at B2), null (they list no languages, or
/// CLDR lists none for the country).
({bool? ok, String detail}) languageFit(CandidateProfile p, WorldCountry country) {
  if (country.languages.isEmpty) return (ok: null, detail: '');
  if (p.rights.languages.isEmpty && p.languages.isEmpty) {
    return (ok: null, detail: 'Add your languages to your profile to check ${country.languages.first}.');
  }
  LanguageLevel? best;
  var bestName = '';
  for (final l in country.languages) {
    final level = p.rights.levelIn(l, cv: p.languages);
    if (level != null && (best == null || level.index > best.index)) {
      best = level;
      bestName = l;
    }
  }
  if (best != null && best.index >= LanguageLevel.professional.index) {
    return (ok: true, detail: 'You speak $bestName (${best.label}, ${best.cefr}).');
  }
  final names = country.languages.take(2).join(' or ');
  final have = best == null ? 'you have not listed it' : 'you list $bestName at ${best.label} (${best.cefr})';
  return (
    ok: false,
    detail:
        'Most jobs in ${country.name} ask for $names at B2 or above; $have. Some international employers hire in '
        'other languages.',
  );
}

String _gbp(int n) => Money(n, 'GBP').label;

/// Checks one route against the person's job codes and pay.
RouteCheck checkRoute(
  VisaRoute r, {
  required List<OccupationMatch> occupations,
  required Money? pay,
  required UkRules uk,
  required String today,
}) {
  final reasons = <String>[];
  switch (r.rule) {
    case OccupationRule.ukSkilled:
      final coded = occupations.where((o) => o.soc.isNotEmpty).toList();
      if (coded.isEmpty) {
        return RouteCheck(r, RouteFit.unknown, [
          'Udyoga could not give your job titles a SOC 2020 code. The sponsor chooses the code; check it on the '
              'ONS coding index.',
        ]);
      }
      RouteFit best = RouteFit.ineligible;
      Money? floor;
      String? deadline;
      for (final o in coded) {
        final t = ukThreshold(o.soc, uk);
        if (t == null) {
          reasons.add('${o.title}: SOC ${o.soc} (${o.socTitle}) is not in the tables Udyoga ships.');
          if (best == RouteFit.ineligible) best = RouteFit.unknown;
          continue;
        }
        final occ = t.occupation;
        if (t.floor == null) {
          reasons.add(
            '${o.title}: SOC ${o.soc} (${occ.title}) is not eligible for the Skilled Worker visa (Table 6).',
          );
          continue;
        }
        if (occ.table == '1a') {
          final open = occ.tsl && today.compareTo(uk.tslCutoff) <= 0;
          if (!open) {
            reasons.add(
              '${o.title}: SOC ${o.soc} is only open to new applicants through the Temporary Shortage List'
              '${occ.tsl ? ', which closed on ${uk.tslCutoff}' : ', and it is not on it'}.',
            );
            continue;
          }
          deadline = uk.tslCutoff;
          reasons.add(
            '${o.title}: SOC ${o.soc} is on the Temporary Shortage List: the certificate of sponsorship must be '
            'issued before ${uk.tslCutoff}, and no new dependants'
            '${occ.tslJobs.isEmpty ? '' : '. Only these job types: ${occ.tslJobs.join(', ')}'}.',
          );
        }
        final f = t.floor!, ne = t.newEntrantFloor!;
        final fit = _payFit(pay, Money(f, 'GBP'), Money(ne, 'GBP'));
        reasons.add(
          '${o.title}: SOC ${o.soc}, pay at least ${_gbp(f)} (${_gbp(ne)} as a new entrant). ${fit.$2}',
        );
        if (fit.$1.index < best.index || best == RouteFit.ineligible) {
          best = fit.$1;
          floor = Money(f, 'GBP');
        }
      }
      return RouteCheck(
        r,
        best,
        reasons,
        floor: floor,
        deadline: best == RouteFit.ineligible ? null : deadline,
      );
    case OccupationRule.ukHealthCare:
      final coded = occupations.where((o) => o.soc.isNotEmpty).toList();
      final listed = coded.where((o) => uk.occupations[o.soc]?.healthCare == true).toList();
      if (listed.isNotEmpty) {
        final o = listed.first, occ = uk.occupations[o.soc]!;
        final rate = occ.careRate ?? 0;
        final f = rate > uk.careFloor ? rate : uk.careFloor;
        final fit = _payFit(pay, Money(f, 'GBP'), null);
        return RouteCheck(r, fit.$1, [
          '${o.title}: SOC ${o.soc} is on the Health and Care list; pay at least ${_gbp(f)} at an NHS, NHS '
              'supplier or adult social care employer. ${fit.$2}',
        ], floor: Money(f, 'GBP'));
      }
      final known = coded.where((o) {
        final occ = uk.occupations[o.soc];
        return occ?.healthCare == false || occ?.table == '6';
      }).toList();
      if (coded.isNotEmpty && known.length == coded.length) {
        return RouteCheck(r, RouteFit.ineligible, [
          'None of your codes (${coded.map((o) => o.soc).toSet().join(', ')}) is on the Health and Care list.',
        ]);
      }
      return RouteCheck(r, RouteFit.unknown, [
        'Udyoga has not checked your codes against the Health and Care list; see the GOV.UK page.',
      ]);
    case OccupationRule.payFloor:
      if (r.floor == null) return RouteCheck(r, RouteFit.unknown, const ['No pay floor on record.']);
      final fit = _payFit(pay, r.floor!, r.reducedFloor, reducedWhen: r.reducedWhen);
      return RouteCheck(r, r.verified ? fit.$1 : RouteFit.unknown, [
        'Pay at least ${r.floor!.label}${r.reducedFloor == null ? '' : ' (${r.reducedFloor!.label} for ${r.reducedWhen})'}. '
            '${fit.$2}',
        if (!r.verified) 'Unverified: Udyoga could not confirm this on the official page.',
      ], floor: r.floor);
    case OccupationRule.points:
      return RouteCheck(r, RouteFit.unknown, [
        'Points-based: your score decides, not a job offer. Compare it with the latest round.',
      ]);
    case OccupationRule.unchecked:
      return RouteCheck(r, RouteFit.unknown, ['Unverified: ask the AI assessment to research it.']);
  }
}

/// (fit, plain sentence) for [pay] against [floor] (and a lower [reduced]).
(RouteFit, String) _payFit(Money? pay, Money floor, Money? reduced, {String reducedWhen = 'new entrants'}) {
  if (pay == null) return (RouteFit.fits, 'Add the pay you are after to compare.');
  if (pay.currency != floor.currency) {
    return (RouteFit.fits, 'Your pay target is in ${pay.currency}, so Udyoga did not compare it.');
  }
  if (pay.yearly >= floor.yearly) return (RouteFit.fits, 'Your target (${pay.label}) reaches it.');
  if (reduced != null && pay.yearly >= reduced.yearly) {
    return (RouteFit.gap, 'Your target (${pay.label}) reaches it only for $reducedWhen.');
  }
  return (RouteFit.gap, 'Your target (${pay.label}) is below it.');
}

/// Screens one country.
CountryScreen screenCountry(
  WorldCountry country, {
  required CandidateProfile profile,
  required String today,
  List<OccupationMatch> occupations = const [],
  Money? pay,
  UkRules? uk,
}) {
  final rules = uk ?? shippedUkRules;
  final target = profile.targets.countries.contains(country.code);
  final lang = languageFit(profile, country);
  final basis = profile.rights.basisIn(country.code, today);
  final reasons = <String>[], blockers = <String>[];
  if (lang.detail.isNotEmpty) (lang.ok == false ? blockers : reasons).add(lang.detail);

  if (basis != null) {
    reasons.insert(0, '$basis.');
    final ends = profile.rights.endingIn(country.code, today);
    if (lang.ok == false) {
      return CountryScreen(
        country: country,
        tier: Tier.later,
        basis: basis,
        reasons: reasons,
        blockers: blockers,
        deadline: ends?.until,
        target: target,
      );
    }
    if (ends != null) reasons.add('Your right to work there ends on ${ends.until}.');
    return CountryScreen(
      country: country,
      tier: Tier.ready,
      basis: basis,
      reasons: reasons,
      blockers: blockers,
      deadline: ends?.until,
      target: target,
    );
  }

  // Jobs kept for nationals.
  final coded = occupations.where((o) => o.isco.isNotEmpty).toList();
  for (final rule in nationalsOnlyIn(country.code)) {
    final hit = coded.where((o) => rule.covers(o.isco)).toList();
    if (hit.isEmpty) continue;
    final line =
        '${rule.name}: ${rule.detail} It covers ${hit.map((o) => o.title).toSet().join(', ')}'
        '${rule.source.verified ? '' : ' (unverified)'}.';
    if (hit.length == coded.length) {
      return CountryScreen(
        country: country,
        tier: Tier.blocked,
        blockers: [line, ...blockers],
        target: target,
      );
    }
    blockers.add(line);
  }

  final routes = routesFor(country.code, uk: rules);
  if (routes.isEmpty) {
    return CountryScreen(
      country: country,
      tier: Tier.later,
      reasons: [
        ...reasons,
        'Udyoga has no route data for ${country.name} yet. The AI assessment can research it.',
      ],
      blockers: blockers,
      target: target,
    );
  }
  final checks = [
    for (final r in routes) checkRoute(r, occupations: occupations, pay: pay, uk: rules, today: today),
  ];
  final fits = checks.where((c) => c.fit == RouteFit.fits).toList();
  if (checks.every((c) => c.fit == RouteFit.ineligible)) {
    return CountryScreen(
      country: country,
      tier: Tier.blocked,
      reasons: reasons,
      blockers: [...blockers, for (final c in checks) ...c.reasons.map((s) => '${c.route.name}: $s')],
      routes: checks,
      target: target,
    );
  }
  final deadline = ([for (final c in checks) ?c.deadline]..sort()).firstOrNull;
  if (fits.isNotEmpty && lang.ok != false) {
    return CountryScreen(
      country: country,
      tier: Tier.possible,
      reasons: [...reasons, for (final c in fits) '${c.route.name} fits.'],
      blockers: blockers,
      routes: checks,
      deadline: deadline,
      target: target,
    );
  }
  for (final c in checks) {
    if (c.fit == RouteFit.gap) blockers.add('${c.route.name}: pay below the floor.');
  }
  if (fits.isEmpty && checks.every((c) => c.fit != RouteFit.gap)) {
    reasons.add('The routes here are not verified, or depend on things Udyoga cannot check.');
  }
  return CountryScreen(
    country: country,
    tier: Tier.later,
    reasons: reasons,
    blockers: blockers,
    routes: checks,
    deadline: deadline,
    target: target,
  );
}

/// Screens every country, targets first, then by tier and name.
List<CountryScreen> screenCountries({
  required CandidateProfile profile,
  required String today,
  List<OccupationMatch> occupations = const [],
  Money? pay,
  UkRules? uk,
  Iterable<WorldCountry>? countries,
}) {
  final out = [
    for (final c in countries ?? worldCountries)
      screenCountry(c, profile: profile, today: today, occupations: occupations, pay: pay, uk: uk),
  ];
  out.sort((a, b) {
    if (a.target != b.target) return a.target ? -1 : 1;
    final t = a.tier.index.compareTo(b.tier.index);
    if (t != 0) return t;
    if (a.hasRoutes != b.hasRoutes) return a.hasRoutes ? -1 : 1;
    return a.country.name.compareTo(b.country.name);
  });
  return out;
}
