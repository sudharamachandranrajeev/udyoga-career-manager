import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/matching.dart';
import 'package:udyoga/domain/profile.dart';
import 'package:udyoga/domain/refresh.dart';

Posting _post({
  String title = 'Nurse',
  bool remote = false,
  int? max,
  String currency = 'GBP',
  String description = '',
}) => Posting(
  source: 'reed',
  sourceId: title,
  title: title,
  remote: remote,
  salaryMax: max,
  currency: currency,
  description: description,
);

void main() {
  test('no filters keeps everything', () {
    expect(passesFilters(const Targets(), _post(title: 'Chief Nurse', description: 'PhD required')), isTrue);
  });

  test('remote only', () {
    const t = Targets(remoteOnly: true);
    expect(passesFilters(t, _post()), isFalse);
    expect(passesFilters(t, _post(remote: true)), isTrue);
  });

  test('minimum pay hides only jobs that state less, in the same currency', () {
    const t = Targets(strictSalary: true, salaryMin: 40000, salaryCurrency: 'GBP');
    expect(passesFilters(t, _post(max: 30000)), isFalse);
    expect(passesFilters(t, _post(max: 50000)), isTrue);
    expect(passesFilters(t, _post()), isTrue);
    expect(passesFilters(t, _post(max: 30000, currency: 'INR')), isTrue);
    expect(passesFilters(const Targets(salaryMin: 40000), _post(max: 30000)), isTrue);
  });

  test('highest level, from the title', () {
    const t = Targets(maxSeniority: 'mid');
    expect(passesFilters(t, _post(title: 'Junior Nurse')), isTrue);
    expect(passesFilters(t, _post(title: 'Clinical Nurse')), isTrue);
    expect(passesFilters(t, _post(title: 'Senior Nurse')), isFalse);
    expect(passesFilters(t, _post(title: 'Head of Nursing')), isFalse);
    expect(passesFilters(const Targets(maxSeniority: 'senior'), _post(title: 'Lead Nurse')), isTrue);
  });

  test('highest degree required, ignoring preferred ones', () {
    const t = Targets(maxDegree: 'bachelor');
    expect(passesFilters(t, _post(description: "A bachelor's degree is required.")), isTrue);
    expect(passesFilters(t, _post(description: "You hold a master's degree.")), isFalse);
    expect(passesFilters(t, _post(description: 'A PhD is preferred.')), isTrue);
    expect(passesFilters(t, _post(description: 'PhD in chemistry.')), isFalse);
    expect(passesFilters(const Targets(maxDegree: 'none'), _post(description: 'Degree required')), isFalse);
  });

  test('filters are kept with the profile and drive the queries', () {
    const t = Targets(
      remoteOnly: true,
      strictSalary: true,
      salaryMin: 1,
      maxSeniority: 'senior',
      maxDegree: 'master',
    );
    final back = Targets.fromJson(t.toJson());
    expect(
      [back.remoteOnly, back.strictSalary, back.maxSeniority, back.maxDegree],
      [true, true, 'senior', 'master'],
    );
    final p = CandidateProfile(
      country: 'GB',
      targets: back.copyWith(roles: ['Nurse'], countries: ['GB', 'IE']),
    );
    final q = Refresher.queries(p);
    expect(q, hasLength(1));
    expect(q.single.remote, isTrue);
  });
}
