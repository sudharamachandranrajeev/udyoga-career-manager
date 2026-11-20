import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/eligibility.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/work_rights.dart';

import 'support.dart';

const today = '2026-11-19';

/// The findings of [kind] in [text].
List<EligibilityFinding> kinds(String text, EligibilityKind kind, {String country = ''}) =>
    scanPosting(text, country: country).where((f) => f.kind == kind).toList();

EligibilityFinding one(String text, EligibilityKind kind, {String country = ''}) {
  final found = kinds(text, kind, country: country);
  expect(
    found,
    hasLength(1),
    reason: 'expected one ${kind.name} in "$text", got ${scanPosting(text, country: country)}',
  );
  return found.single;
}

void none(String text, EligibilityKind kind, {String country = ''}) =>
    expect(kinds(text, kind, country: country), isEmpty, reason: 'expected no ${kind.name} in "$text"');

// Made-up adverts, written the way real ones in each place are.

const nhsAdvert = '''
Job overview
Example Health NHS Foundation Trust is looking for a Band 6 Clinical Informatics Nurse to join our digital team.

Main duties of the job
You will support the roll-out of the electronic patient record across wards.

Person specification
Essential: NMC registration. Experience of EPR systems.
Desirable: Experience of working in the NHS digital team.

UK Registration
Applicants must have current UK professional registration. For further information please see NHS Careers website.

Certificate of Sponsorship
Applications from job seekers who require current Skilled worker sponsorship to work in the UK are welcome and will be considered alongside all other applications. For further information visit the UK Visas and Immigration website.
''';

const nhsNoSponsorAdvert = '''
Band 5 Staff Nurse, Example Ward.
Please note: this post does not meet the eligibility criteria for Skilled Worker sponsorship.
Applicants must have the right to work in the UK.
''';

const gulfAdvert = '''
Senior Nurse – ICU (Dubai)
• Bachelor's degree in Nursing
• Minimum 3 years of UK, US or Australian experience is essential.
• DHA licence or eligibility.
• Fluent English; Arabic is an advantage.
• Emiratisation: UAE nationals are encouraged to apply.
Attractive tax-free package, visa provided, annual flights.
''';

const saudiAdvert = '''
Clinical Nurse Specialist, Riyadh.
This position is open to Saudi nationals only.
Candidates must be currently residing in KSA with a transferable iqama.
''';

const usAdvert = '''
Nurse Informaticist – Remote (US)
Candidates must be legally authorized to work in the United States. We are unable to sponsor or take over sponsorship of an employment visa at this time.
Active Secret clearance required.
''';

const usNoClearanceAdvert = '''
Data Analyst, Example City.
Must be authorized to work in the US without the need for employer sponsorship now or in the future.
''';

const euAdvert = '''
Klinische Informatiker (m/w/d) – Berlin.
Fluent German (C1) is essential; good English is desirable.
EU citizenship or a valid German work permit is required.
Candidates must already live in Germany.
''';

const ukDefenceAdvert = '''
Systems Engineer, Example Defence Ltd.
Due to the nature of the work, applicants must be eligible for SC clearance.
This role requires BPSS clearance as a minimum.
''';

const civilServiceAdvert = '''
Policy Adviser.
Nationality requirements: this job is broadly open to the following groups: UK nationals, nationals of the Republic of Ireland.
''';

void main() {
  group('reading adverts', () {
    test('splits sentences at full stops and bullets, not "e.g." or "U.K."', () {
      final s = sentencesOf(
        'Experience e.g. in wards. You must live in the U.K. Today. • First point\n• Second point\n- Third point',
      );
      expect(s, [
        'Experience e.g. in wards.',
        'You must live in the U.K. Today.',
        'First point',
        'Second point',
        'Third point',
      ]);
    });

    test('the NHS "sponsorship welcome" line is an offer, not a refusal', () {
      final f = one(nhsAdvert, EligibilityKind.sponsorshipOffered, country: 'GB');
      expect(
        f.quote,
        startsWith('Applications from job seekers who require current Skilled worker sponsorship'),
      );
      none(nhsAdvert, EligibilityKind.noSponsorship, country: 'GB');
    });

    test('the NHS "does not meet the criteria for sponsorship" line is a refusal', () {
      final f = one(nhsNoSponsorAdvert, EligibilityKind.noSponsorship, country: 'GB');
      expect(f.severity, Severity.blocker);
      expect(
        f.quote,
        'Please note: this post does not meet the eligibility criteria for Skilled Worker sponsorship.',
      );
      expect(one(nhsNoSponsorAdvert, EligibilityKind.rightToWork, country: 'GB').subject, 'GB');
    });

    test('"UK professional registration" is not a right-to-work rule', () {
      none(nhsAdvert, EligibilityKind.rightToWork, country: 'GB');
    });

    test('NHS experience marked desirable is information only', () {
      final f = one(nhsAdvert, EligibilityKind.localExperience, country: 'GB');
      expect(f.severity, Severity.info);
      expect(f.subject, 'GB');
      expect(f.essential, isFalse);
    });

    test('Gulf: home-country experience, languages, Emiratisation and a visa offered', () {
      final exp = one(gulfAdvert, EligibilityKind.localExperience, country: 'AE');
      expect(exp.severity, Severity.caution);
      expect(exp.subject, 'GB,US,AU');
      expect(exp.title, contains('United Kingdom, United States or Australia'));
      expect(exp.quote, 'Minimum 3 years of UK, US or Australian experience is essential.');
      final langs = kinds(gulfAdvert, EligibilityKind.language, country: 'AE');
      expect({for (final l in langs) l.subject: l.essential}, {'English': true, 'Arabic': false});
      expect(langs.firstWhere((l) => l.subject == 'English').level, LanguageLevel.fluent);
      final quota = one(gulfAdvert, EligibilityKind.nationalsOnly, country: 'AE');
      expect(quota.severity, Severity.caution);
      expect(quota.subject, 'AE');
      expect(
        one(gulfAdvert, EligibilityKind.sponsorshipOffered, country: 'AE').quote,
        contains('visa provided'),
      );
    });

    test('Saudi: nationals only, and residence with a transferable iqama', () {
      final n = one(saudiAdvert, EligibilityKind.nationalsOnly, country: 'SA');
      expect(n.subject, 'SA');
      expect(n.severity, Severity.blocker);
      final r = one(saudiAdvert, EligibilityKind.residence, country: 'SA');
      expect(r.subject, 'SA');
      expect(r.severity, Severity.blocker);
      expect(
        one(saudiAdvert, EligibilityKind.rightToWork, country: 'SA').quote,
        contains('transferable iqama'),
      );
    });

    test('US: authorised to work, no sponsorship and a Secret clearance', () {
      expect(one(usAdvert, EligibilityKind.rightToWork, country: 'US').subject, 'US');
      expect(
        one(usAdvert, EligibilityKind.noSponsorship, country: 'US').quote,
        startsWith('We are unable to sponsor'),
      );
      final c = one(usAdvert, EligibilityKind.clearance, country: 'US');
      expect(c.subject, 'Secret');
      expect(c.severity, Severity.blocker);
    });

    test('US: "without the need for sponsorship now or in the future"', () {
      one(usNoClearanceAdvert, EligibilityKind.noSponsorship, country: 'US');
      expect(one(usNoClearanceAdvert, EligibilityKind.rightToWork, country: 'US').subject, 'US');
      none(usNoClearanceAdvert, EligibilityKind.clearance, country: 'US');
    });

    test('EU: German at C1, EU citizenship, and living in Germany already', () {
      final german = kinds(
        euAdvert,
        EligibilityKind.language,
        country: 'DE',
      ).firstWhere((l) => l.subject == 'German');
      expect(german.level, LanguageLevel.fluent);
      expect(german.essential, isTrue);
      final english = kinds(
        euAdvert,
        EligibilityKind.language,
        country: 'DE',
      ).firstWhere((l) => l.subject == 'English');
      expect(english.essential, isFalse);
      // "EU citizenship or a work permit" asks for the right to work, not a nationality.
      none(euAdvert, EligibilityKind.nationalsOnly, country: 'DE');
      expect(one(euAdvert, EligibilityKind.rightToWork, country: 'DE').subject, 'DE');
      final r = one(euAdvert, EligibilityKind.residence, country: 'DE');
      expect(r.subject, 'DE');
      expect(r.severity, Severity.blocker);
    });

    test('UK vetting: SC is a caution, BPSS information only', () {
      final found = kinds(ukDefenceAdvert, EligibilityKind.clearance, country: 'GB');
      expect({for (final f in found) f.subject: f.severity}, {'SC': Severity.caution, 'BPSS': Severity.info});
    });

    test('common UK lines', () {
      const cases = {
        'This role is not eligible for sponsorship.': EligibilityKind.noSponsorship,
        'Sponsorship: No': EligibilityKind.noSponsorship,
        'Unfortunately we cannot offer visa sponsorship.': EligibilityKind.noSponsorship,
        'We are a licensed sponsor and can offer Skilled Worker sponsorship.':
            EligibilityKind.sponsorshipOffered,
        'You must be eligible to work in the UK.': EligibilityKind.rightToWork,
        'UK based candidates only.': EligibilityKind.residence,
        'Ability to speak Welsh is essential for this post.': EligibilityKind.language,
        'This role is open to UK nationals only.': EligibilityKind.nationalsOnly,
        'Experience working within the NHS is essential.': EligibilityKind.localExperience,
        'Must hold DV clearance.': EligibilityKind.clearance,
      };
      for (final e in cases.entries) {
        final f = one(e.key, e.value, country: 'GB');
        expect(f.quote, e.key);
      }
      expect(one('UK based candidates only.', EligibilityKind.residence).subject, 'GB');
      expect(one('Welsh language skills are desirable.', EligibilityKind.language).severity, Severity.info);
    });

    test('"entry clearance" is a visa, not security vetting', () {
      none('You will need entry clearance before you travel to the UK.', EligibilityKind.clearance);
    });

    test('Civil Service nationality rules are a caution', () {
      final f = one(civilServiceAdvert, EligibilityKind.nationalsOnly, country: 'GB');
      expect(f.severity, Severity.caution);
    });

    test('ordinary words do not trigger findings', () {
      const plain = '''
Join a strong German engineering firm with an excellent English-language website.
Experience of local government is helpful. Tell us about yourself.
We offer secret-santa parties and good pensions.
You will work with US clients across time zones.
Please let us know if you need reasonable adjustments.
Join us to help our local communities.
You must live within commuting distance of Exampletown.
''';
      expect(scanPosting(plain, country: 'GB'), isEmpty);
    });

    test('quotes are the sentence exactly as written', () {
      const text = 'Great team.  Visa sponsorship is not available for this role.   Apply now.';
      expect(
        one(text, EligibilityKind.noSponsorship).quote,
        'Visa sponsorship is not available for this role.',
      );
    });

    test('the same text always gives the same findings', () {
      expect(
        scanPosting(gulfAdvert, country: 'AE').toString(),
        scanPosting(gulfAdvert, country: 'AE').toString(),
      );
    });
  });

  group('for one person', () {
    const ukWorker = WorkRights(
      passports: ['IN'],
      rightToWork: [RightToWork(country: 'GB', status: 'Skilled Worker visa', until: '2029-05-31')],
      languages: [
        SpokenLanguage('English', LanguageLevel.fluent),
        SpokenLanguage('Hindi', LanguageLevel.native),
      ],
    );
    final p = sampleProfile.copyWith(rights: ukWorker);

    EligibilityCheck check(
      String text, {
      String country = '',
      CandidateProfile? who,
      String title = 'Nurse',
    }) => checkEligibility(who ?? p, title: title, description: text, country: country, today: today);

    test('no sponsorship is no blocker with the right to work there', () {
      final c = check(nhsNoSponsorAdvert, country: 'GB');
      final f = c.findings.firstWhere((f) => f.kind == EligibilityKind.noSponsorship);
      expect(f.severity, Severity.clear);
      expect(f.note, contains('Skilled Worker visa'));
      expect(c.blocked, isFalse);
    });

    test('a right to work ending within six months is a caution', () {
      final soon = sampleProfile.copyWith(
        rights: const WorkRights(
          rightToWork: [RightToWork(country: 'GB', status: 'Graduate visa', until: '2027-02-01')],
        ),
      );
      final f = check(nhsNoSponsorAdvert, country: 'GB', who: soon).findings.first;
      expect(f.severity, Severity.caution);
      expect(f.note, contains('2027-02-01'));
    });

    test('an expired right to work does not count', () {
      final lapsed = sampleProfile.copyWith(
        rights: const WorkRights(
          rightToWork: [RightToWork(country: 'GB', until: '2026-01-01')],
        ),
      );
      expect(check(nhsNoSponsorAdvert, country: 'GB', who: lapsed).blocked, isTrue);
    });

    test('no sponsorship abroad blocks someone with no rights there', () {
      final c = check(usAdvert, country: 'US');
      expect(c.blocked, isTrue);
      expect(
        c.findings.firstWhere((f) => f.kind == EligibilityKind.noSponsorship).severity,
        Severity.blocker,
      );
    });

    test('an EU passport clears EU citizenship and the right to work in Germany', () {
      final eu = sampleProfile.copyWith(
        country: 'DE',
        rights: const WorkRights(
          passports: ['FR'],
          languages: [
            SpokenLanguage('German', LanguageLevel.native),
            SpokenLanguage('English', LanguageLevel.fluent),
          ],
        ),
      );
      final c = check(euAdvert, country: 'DE', who: eu);
      expect(c.blocked, isFalse, reason: '${c.findings}');
      expect(c.findings.firstWhere((f) => f.kind == EligibilityKind.rightToWork).severity, Severity.clear);
      expect(c.findings.firstWhere((f) => f.kind == EligibilityKind.residence).severity, Severity.clear);
    });

    test('a language below the level asked for blocks; one level below cautions', () {
      final some = sampleProfile.copyWith(
        rights: const WorkRights(languages: [SpokenLanguage('German', LanguageLevel.professional)]),
      );
      final none = sampleProfile.copyWith(
        rights: const WorkRights(languages: [SpokenLanguage('German', LanguageLevel.basic)]),
      );
      Severity german(CandidateProfile who) => check(
        euAdvert,
        country: 'DE',
        who: who,
      ).findings.firstWhere((f) => f.kind == EligibilityKind.language && f.subject == 'German').severity;
      expect(german(some), Severity.caution);
      expect(german(none), Severity.blocker);
    });

    test('languages fall back to the CV list', () {
      final cv = sampleProfile.copyWith(
        languages: ['German (native)'],
        rights: const WorkRights(passports: ['GB']),
      );
      final f = check(euAdvert, country: 'DE', who: cv).findings.firstWhere((f) => f.subject == 'German');
      expect(f.severity, Severity.clear);
    });

    test('with no rights on record, nothing is called a hard block on the right to work', () {
      final unknown = sampleProfile;
      final f = check(
        nhsNoSponsorAdvert,
        country: 'GB',
        who: unknown,
      ).findings.firstWhere((f) => f.kind == EligibilityKind.rightToWork);
      expect(f.severity, Severity.caution);
      expect(f.note, contains('Profile'));
    });

    test('UK experience is met by NHS work in the profile', () {
      final f = check(
        gulfAdvert,
        country: 'AE',
      ).findings.firstWhere((f) => f.kind == EligibilityKind.localExperience);
      expect(f.severity, Severity.clear);
    });

    test('US Secret clearance blocks without a US passport', () {
      final f = check(
        usAdvert,
        country: 'US',
      ).findings.firstWhere((f) => f.kind == EligibilityKind.clearance);
      expect(f.severity, Severity.blocker);
    });

    test('exclusions are a hard rule on whole words of the title or employer', () {
      final picky = p.copyWith(targets: p.targets.copyWith(exclusions: ['agency', 'night shift']));
      expect(checkEligibility(picky, title: 'Staff Nurse (Night Shift)', today: today).excluded, isTrue);
      expect(
        checkEligibility(picky, title: 'Nurse', company: 'Example Agency Ltd', today: today).excluded,
        isTrue,
      );
      expect(checkEligibility(picky, title: 'Agency-free Nurse', today: today).excluded, isTrue);
      expect(checkEligibility(picky, title: 'Nurse', company: 'Agencyworks', today: today).excluded, isFalse);
      expect(excludedBy(['  '], title: 'Anything'), isNull);
    });
  });
}
