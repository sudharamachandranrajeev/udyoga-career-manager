import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/matching.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/work_rights.dart';

import 'support.dart';

const today = '2026-11-19';

FitResult fit(JobFacts j, {CandidateProfile p = sampleProfile}) => scoreFit(p, j, today: today);

FitFactor factor(FitResult r, String name) => r.factors.firstWhere((f) => f.name == name);

void main() {
  group('whole words', () {
    test('a phrase matches as whole words, any case, with plurals', () {
      expect(mentions('Senior Data Analysts wanted', 'data analyst'), isTrue);
      expect(mentions('Use EXCEL daily', 'Excel'), isTrue);
      expect(mentions('Excellent pay', 'Excel'), isFalse);
      expect(mentions('analytics team', 'analyst'), isFalse);
      expect(mentions('Patient-safety lead', 'patient safety'), isTrue);
      expect(mentions('C++ and C# developers', 'C#'), isTrue);
      expect(mentions('Java', 'JavaScript'), isFalse);
      expect(mentions('JavaScript', 'Java'), isFalse);
    });

    test('a skill inside another word does not count', () {
      final p = sampleProfile.copyWith(skills: ['Excel', 'R']);
      final r = fit(
        const JobFacts(title: 'Nurse', description: 'Excellent rewards. Rota-based shifts.'),
        p: p,
      );
      expect(factor(r, 'Skills').score, 0);
    });
  });

  group('skills', () {
    test('every skill named counts: no cap at five', () {
      final skills = [for (var i = 0; i < 10; i++) 'skill$i'];
      final p = sampleProfile.copyWith(skills: skills);
      final five = fit(
        JobFacts(title: 'Nurse', description: skills.take(5).join(' ')),
        p: p,
      );
      final ten = fit(
        JobFacts(title: 'Nurse', description: skills.join(' ')),
        p: p,
      );
      expect(factor(ten, 'Skills').score, 1);
      expect(factor(five, 'Skills').score, greaterThan(0.5));
      expect(factor(five, 'Skills').score, lessThan(1));
      expect(ten.fit, greaterThan(five.fit));
    });

    test('no skills on the profile leaves the factor out', () {
      final r = fit(
        const JobFacts(title: 'Nurse'),
        p: sampleProfile.copyWith(skills: []),
      );
      expect(factor(r, 'Skills').known, isFalse);
    });
  });

  group('title', () {
    test('a target role in the title scores in full; a share of its words partly', () {
      expect(factor(fit(const JobFacts(title: 'Senior Clinical Informatics Nurse')), 'Title').score, 1);
      final part = factor(fit(const JobFacts(title: 'Informatics Officer')), 'Title').score!;
      expect(part, inExclusiveRange(0, 1));
      expect(factor(fit(const JobFacts(title: 'Forklift Driver')), 'Title').score, 0);
    });
  });

  group('pay', () {
    final p = sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(salaryMin: 40000));

    test('compares only in the same currency', () {
      final gbp = fit(
        const JobFacts(title: 'Nurse', salaryMax: 45000, currency: 'GBP'),
        p: p,
      );
      expect(factor(gbp, 'Pay').score, 1);
      final aed = fit(
        const JobFacts(title: 'Nurse', salaryMax: 45000, currency: 'AED'),
        p: p,
      );
      expect(factor(aed, 'Pay').known, isFalse);
      expect(factor(aed, 'Pay').why, contains('AED'));
      final none = fit(const JobFacts(title: 'Nurse', salaryMax: 45000), p: p);
      expect(factor(none, 'Pay').known, isFalse);
    });

    test('below the minimum scores less, and nothing at 70 % or under', () {
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', salaryMax: 34000, currency: 'GBP'),
            p: p,
          ),
          'Pay',
        ).score,
        closeTo(0.5, 0.01),
      );
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', salaryMax: 20000, currency: 'GBP'),
            p: p,
          ),
          'Pay',
        ).score,
        0,
      );
    });

    test("the minimum's own currency wins over the home country's", () {
      final usd = p.copyWith(targets: p.targets.copyWith(salaryCurrency: 'USD'));
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', salaryMax: 50000, currency: 'USD'),
            p: usd,
          ),
          'Pay',
        ).score,
        1,
      );
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', salaryMax: 50000, currency: 'GBP'),
            p: usd,
          ),
          'Pay',
        ).known,
        isFalse,
      );
    });
  });

  group('location', () {
    test('a target country scores; another country does not; no country is unknown', () {
      expect(factor(fit(const JobFacts(title: 'N', country: 'IE')), 'Location').score, 1);
      expect(factor(fit(const JobFacts(title: 'N', country: 'AE')), 'Location').score, 0);
      expect(factor(fit(const JobFacts(title: 'N')), 'Location').known, isFalse);
    });

    test('remote work scores when wanted', () {
      final remote = sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(workModes: ['remote']));
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', country: 'US', remote: true),
            p: remote,
          ),
          'Location',
        ).score,
        1,
      );
    });

    test('home towns narrow the home country', () {
      final towns = sampleProfile.copyWith(
        targets: sampleProfile.targets.copyWith(locations: ['Exampletown']),
      );
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', country: 'GB', location: 'Exampletown, Shire'),
            p: towns,
          ),
          'Location',
        ).score,
        1,
      );
      expect(
        factor(
          fit(
            const JobFacts(title: 'N', country: 'GB', location: 'Farcity'),
            p: towns,
          ),
          'Location',
        ).score,
        0.6,
      );
    });
  });

  group('seniority', () {
    test('reads levels from titles and NHS bands', () {
      expect(seniorityOf('Head of Nursing'), 5);
      expect(seniorityOf('Senior Analyst'), 4);
      expect(seniorityOf('Analyst'), 3);
      expect(seniorityOf('Junior Developer'), 2);
      expect(seniorityOf('Graduate Trainee'), 1);
      expect(seniorityOf('Nurse', salaryText: 'Band 7'), 4);
      expect(seniorityOf('Something'), isNull);
    });

    test('the same level scores best; far above or below scores little', () {
      final p = sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(roles: ['Senior Analyst']));
      expect(factor(fit(const JobFacts(title: 'Lead Analyst'), p: p), 'Seniority').score, 1);
      expect(factor(fit(const JobFacts(title: 'Director of Analytics'), p: p), 'Seniority').score, 0.7);
      expect(
        factor(fit(const JobFacts(title: 'Analyst Apprentice'), p: p), 'Seniority').score,
        lessThan(0.5),
      );
    });
  });

  group('eligibility', () {
    test('a blocker caps the score', () {
      final p = sampleProfile.copyWith(rights: const WorkRights(passports: ['GB']));
      const job = JobFacts(
        title: 'Clinical Informatics Nurse',
        description:
            'EPR systems, patient safety and training. We are unable to sponsor visas. US citizens only.',
        country: 'US',
      );
      final r = fit(job, p: p);
      expect(r.blocked, isTrue);
      expect(r.fit, lessThanOrEqualTo(blockedCap));
    });

    test('no sponsorship where the person may work does not lower the score', () {
      final p = sampleProfile.copyWith(rights: const WorkRights(passports: ['GB']));
      const open = JobFacts(title: 'Clinical Informatics Nurse', description: 'EPR systems.', country: 'GB');
      const closed = JobFacts(
        title: 'Clinical Informatics Nurse',
        description: 'EPR systems. Sponsorship is not available.',
        country: 'GB',
      );
      expect(fit(closed, p: p).fit, fit(open, p: p).fit);
      expect(factor(fit(closed, p: p), 'Eligibility').score, 1);
    });

    test('an exclusion scores nothing', () {
      final p = sampleProfile.copyWith(targets: sampleProfile.targets.copyWith(exclusions: ['bank']));
      final r = fit(
        const JobFacts(title: 'Clinical Informatics Nurse (Bank)', country: 'GB'),
        p: p,
      );
      expect(r.excluded, isTrue);
      expect(r.fit, 0);
    });

    test('unknown rights leave the factor out instead of guessing', () {
      expect(factor(fit(const JobFacts(title: 'N', country: 'GB')), 'Eligibility').known, isFalse);
    });
  });

  test('a close match beats a far one, and both stay within 0 to 100', () {
    final near = fit(
      const JobFacts(
        title: 'Clinical Informatics Nurse',
        description: 'EPR systems, patient safety and training.',
        country: 'GB',
        location: 'Exampletown',
      ),
    );
    final far = fit(const JobFacts(title: 'Forklift Driver', description: 'Warehouse shifts', country: 'AE'));
    expect(near.fit, greaterThan(80));
    expect(far.fit, lessThan(20));
    for (final r in [near, far]) {
      expect(r.fit, inInclusiveRange(0, 100));
    }
  });

  test('with nothing to go on the score is 0', () {
    const empty = CandidateProfile();
    expect(fit(const JobFacts(title: 'Anything'), p: empty).fit, 0);
  });
}
