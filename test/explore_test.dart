import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/explore.dart';
import 'package:udyoga/domain/occupations.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/routes.dart';
import 'package:udyoga/domain/work_rights.dart';
import 'package:udyoga/domain/world.dart';

import 'support.dart';

const today = '2026-11-19';

CandidateProfile withRights(WorkRights r, {Targets? targets}) => CandidateProfile(
  name: sampleProfile.name,
  currentRole: sampleProfile.currentRole,
  targets: targets ?? sampleProfile.targets,
  rights: r,
);

const english = SpokenLanguage('English', LanguageLevel.native);

OccupationMatch code(String title) => socMatches(title).first;

CountryScreen screen(String c, CandidateProfile p, {List<OccupationMatch> occ = const [], Money? pay, UkRules? uk}) =>
    screenCountry(worldCountry(c)!, profile: p, today: today, occupations: occ, pay: pay, uk: uk);

void main() {
  test('a passport and the language make a country Ready', () {
    final p = withRights(const WorkRights(passports: ['IE'], languages: [english]));
    final ie = screen('IE', p);
    expect(ie.tier, Tier.ready);
    expect(ie.basis, contains('Ireland passport'));
    // Free movement reaches the rest of the EU, and the Common Travel Area the UK.
    expect(screen('GB', p).tier, Tier.ready);
    expect(screen('DE', p).basis, contains('free movement'));
  });

  test('pushback: a right to work without the language is Later, not Ready', () {
    final p = withRights(const WorkRights(passports: ['IE'], languages: [english]));
    final de = screen('DE', p);
    expect(de.tier, Tier.later);
    expect(de.blockers.single, contains('German'));
    final basic = withRights(
      const WorkRights(passports: ['IE'], languages: [english, SpokenLanguage('German', LanguageLevel.basic)]),
    );
    expect(screen('DE', basic).blockers.single, contains('German at Basic'));
    final b2 = withRights(
      const WorkRights(passports: ['IE'], languages: [english, SpokenLanguage('German', LanguageLevel.professional)]),
    );
    expect(screen('DE', b2).tier, Tier.ready);
  });

  test('a right to work that ends gives the deadline; one that has ended does not count', () {
    final p = withRights(
      const WorkRights(
        languages: [english],
        rightToWork: [RightToWork(country: 'GB', status: 'Dependant visa', until: '2027-06-30')],
      ),
    );
    final gb = screen('GB', p);
    expect(gb.tier, Tier.ready);
    expect(gb.deadline, '2027-06-30');
    final ended = withRights(
      const WorkRights(
        languages: [english],
        rightToWork: [RightToWork(country: 'GB', status: 'Dependant visa', until: '2026-01-01')],
      ),
    );
    expect(screen('GB', ended).tier, isNot(Tier.ready));
  });

  test('UK Skilled Worker: an IT code at the going rate is Possible', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final gb = screen('GB', p, occ: [code('Business analyst')], pay: const Money(55000, 'GBP'));
    expect(gb.tier, Tier.possible);
    final sw = gb.routes.firstWhere((r) => r.route.id == 'gb.skilled-worker');
    expect(sw.fit, RouteFit.fits);
    expect(sw.floor!.amount, 50200);
    // 2431 is not on the Health and Care list as Udyoga ships it: unknown, not a fit.
    expect(gb.routes.firstWhere((r) => r.route.id == 'gb.health-care').fit, isNot(RouteFit.fits));
  });

  test('pushback: pay below the UK floor is Later, and new-entrant pay says so', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final low = screen('GB', p, occ: [code('Business analyst')], pay: const Money(30000, 'GBP'));
    expect(low.tier, Tier.later);
    expect(low.blockers, contains(contains('pay below the floor')));
    final ne = screen('GB', p, occ: [code('Business analyst')], pay: const Money(36000, 'GBP'));
    final sw = ne.routes.firstWhere((r) => r.route.id == 'gb.skilled-worker');
    expect(sw.fit, RouteFit.gap);
    expect(sw.reasons.join(), contains('only for new entrants'));
  });

  test('UK Temporary Shortage List: open until the cut-off, closed after it', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final coder = code('Clinical coder');
    expect(coder.soc, '3549');
    final open = screen('GB', p, occ: [coder], pay: const Money(42000, 'GBP'));
    expect(open.tier, Tier.possible);
    expect(open.deadline, '2026-12-31');
    final sw = open.routes.firstWhere((r) => r.route.id == 'gb.skilled-worker');
    expect(sw.reasons.join(), contains('Clinical coders'));
    final after = screenCountry(
      worldCountry('GB')!,
      profile: p,
      today: '2027-01-05',
      occupations: [coder],
      pay: const Money(42000, 'GBP'),
    );
    expect(after.tier, Tier.blocked);
    expect(after.blockers.join(), contains('closed on 2026-12-31'));
  });

  test('pushback: a Table 6 job blocks the UK route', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final clerk = socMatches('Medical secretary').first;
    expect(clerk.soc, '4211');
    final gb = screen('GB', p, occ: [clerk], pay: const Money(50000, 'GBP'));
    expect(gb.tier, Tier.blocked);
    expect(gb.blockers.join(), contains('Table 6'));
  });

  test('Health and Care: 1171 fits at the Table 2 rate', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    const manager = OccupationMatch(title: 'Service manager', soc: '1171', isco: '1342');
    final gb = screen('GB', p, occ: [manager], pay: const Money(42000, 'GBP'));
    final hc = gb.routes.firstWhere((r) => r.route.id == 'gb.health-care');
    expect(hc.fit, RouteFit.fits);
    expect(hc.floor!.amount, 41600);
  });

  test('Ireland: the GEP floor; currencies are never mixed', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    expect(screen('IE', p, pay: const Money(40000, 'EUR')).tier, Tier.possible);
    final low = screen('IE', p, pay: const Money(35000, 'EUR'));
    expect(low.tier, Tier.later);
    final gep = low.routes.firstWhere((r) => r.route.id == 'ie.general-permit');
    expect(gep.fit, RouteFit.gap);
    final gbp = screen('IE', p, pay: const Money(30000, 'GBP'));
    expect(gbp.routes.first.reasons.join(), contains('did not compare'));
  });

  test('Netherlands compares monthly floors with yearly pay', () {
    final p = withRights(
      const WorkRights(passports: ['IN'], languages: [english, SpokenLanguage('Dutch', LanguageLevel.professional)]),
    );
    expect(screen('NL', p, pay: const Money(72000, 'EUR')).tier, Tier.possible);
    expect(screen('NL', p, pay: const Money(60000, 'EUR')).tier, Tier.later);
  });

  test('pushback: a route that fits still waits on the language', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final de = screen('DE', p, pay: const Money(60000, 'EUR'));
    expect(de.routes.single.fit, RouteFit.fits);
    expect(de.tier, Tier.later);
    expect(de.blockers.join(), contains('German'));
  });

  test('pushback: nationals-only jobs block Saudi Arabia for admin work', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    const admin = OccupationMatch(title: 'Administrator', soc: '4159', isco: '4110');
    final sa = screen('SA', p, occ: [admin]);
    expect(sa.tier, Tier.blocked);
    expect(sa.blockers.first, contains('Saudization'));
    expect(sa.blockers.first, contains('unverified'));
    const it = OccupationMatch(title: 'Developer', soc: '2134', isco: '2512');
    final mixed = screen('SA', p, occ: [admin, it]);
    expect(mixed.tier, Tier.later);
    expect(mixed.blockers, contains(contains('Saudization')));
  });

  test('unverified routes and countries without data are Later', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final au = screen('AU', p);
    expect(au.tier, Tier.later);
    expect(au.routes.single.route.verified, isFalse);
    final fj = screen('FJ', p);
    expect(fj.tier, Tier.later);
    expect(fj.reasons.join(), contains('no route data'));
  });

  test('Canada Express Entry is points-based: never Possible on pay alone', () {
    final p = withRights(const WorkRights(passports: ['IN'], languages: [english]));
    final ca = screen('CA', p, pay: const Money(90000, 'CAD'));
    expect(ca.routes.single.fit, RouteFit.unknown);
    expect(ca.tier, Tier.later);
  });

  test('no languages listed asks for them rather than guessing', () {
    final p = withRights(const WorkRights(passports: ['IE']));
    final ie = screen('IE', p);
    expect(ie.tier, Tier.ready);
    expect(ie.reasons.join(), contains('Add your languages'));
  });

  test('screening every country: 249, targets first, then by tier', () {
    final p = withRights(const WorkRights(passports: ['GB'], languages: [english]));
    final all = screenCountries(profile: p, today: today);
    expect(all, hasLength(249));
    expect(all.take(2).map((s) => s.code), unorderedEquals(['GB', 'IE']));
    expect(all.first.tier, Tier.ready);
    final rest = all.skip(2).toList();
    for (var i = 1; i < rest.length; i++) {
      expect(rest[i].tier.index, greaterThanOrEqualTo(rest[i - 1].tier.index));
    }
  });

  test('expected pay: the target minimum, else the baseline in GBP', () {
    expect(expectedPay(sampleProfile), isNull);
    expect(expectedPay(sampleProfile, baselineGbp: 38000)!.label, '£38,000 a year');
    final p = withRights(const WorkRights(), targets: const Targets(salaryMin: 50000, salaryCurrency: 'eur'));
    expect(expectedPay(p, baselineGbp: 38000)!.currency, 'EUR');
  });
}
