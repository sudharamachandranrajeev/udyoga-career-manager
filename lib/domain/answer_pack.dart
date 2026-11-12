import '../db/database.dart';
import 'profile.dart';

/// One section of an application form, ready to copy into the employer's
/// site (NHS Jobs, HSC Jobs and the trusts' own systems ask in this order).
class PackSection {
  const PackSection(this.title, this.text, {this.missing = ''});
  final String title;
  final String text;

  /// What to add first when the section cannot be filled yet.
  final String missing;

  bool get ready => text.isNotEmpty;
}

/// Everything the candidate types into an application, from the profile,
/// the CV tailored for this job ([statement] is its supporting statement)
/// and the contacts marked as referees.
List<PackSection> answerPack(CandidateProfile p, {String statement = '', List<Lead> referees = const []}) => [
  PackSection(
    'Personal details',
    [
      p.name,
      if (p.email.isNotEmpty) p.email,
      if (p.phone.isNotEmpty) p.phone,
      if (p.location.isNotEmpty) p.location,
    ].where((s) => s.isNotEmpty).join('\n'),
    missing: 'Add your name and contact details to your profile.',
  ),
  PackSection(
    'Employment history (most recent first)',
    [for (final e in _recentFirst(p.experience)) _job(e)].join('\n\n'),
    missing: 'Add your jobs to your profile, or import your CV.',
  ),
  if (employmentGaps(p.experience).isNotEmpty)
    PackSection(
      'Gaps in employment to explain',
      [for (final g in employmentGaps(p.experience)) '$g: '].join('\n'),
    ),
  PackSection(
    'Education and qualifications',
    [
      for (final e in p.education)
        [e.qualification, e.institution, e.year, e.grade].where((s) => s.isNotEmpty).join(', '),
      for (final c in p.certifications) c,
    ].join('\n'),
    missing: 'Add your qualifications to your profile.',
  ),
  PackSection('Skills', p.skills.join(', ')),
  PackSection(
    'Supporting information',
    statement,
    missing: 'Tailor a CV for this job: it drafts a supporting statement against the person specification.',
  ),
  PackSection(
    'References',
    [
      for (final r in referees)
        [
          r.name,
          [r.title, r.company].where((s) => s.isNotEmpty).join(', '),
          r.email,
          r.phone,
        ].where((s) => s.isNotEmpty).join('\n'),
    ].join('\n\n'),
    missing:
        'Add your referees on the Contacts page (kind: Referee). NHS employers usually want two, '
        'covering the last three years.',
  ),
];

/// The whole pack as one text, as kept in the archive when it is sent.
String packText(List<PackSection> pack) =>
    [for (final s in pack.where((s) => s.ready)) '${s.title}\n${s.text}'].join('\n\n');

List<Experience> _recentFirst(List<Experience> jobs) =>
    [...jobs]..sort((a, b) => (b.current ? '9999' : b.end).compareTo(a.current ? '9999' : a.end));

String _job(Experience e) => [
  [e.title, e.organisation].where((s) => s.isNotEmpty).join(', '),
  [e.start, e.current ? 'present' : e.end].where((s) => s.isNotEmpty).join(' to '),
  if (e.location.isNotEmpty) e.location,
  for (final h in e.highlights) '- $h',
].where((s) => s.isNotEmpty).join('\n');

/// Gaps of more than three months between jobs (yyyy-MM dates only), which
/// NHS application forms ask the candidate to explain.
List<String> employmentGaps(List<Experience> jobs) {
  int? month(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})').firstMatch(s);
    return m == null ? null : int.parse(m[1]!) * 12 + int.parse(m[2]!) - 1;
  }

  String label(int m) => '${m ~/ 12}-${(m % 12 + 1).toString().padLeft(2, '0')}';
  final spans = [
    for (final e in jobs)
      if (month(e.start) case final s?)
        if (e.current ? 1 << 30 : month(e.end) case final end?) (s, end),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final gaps = <String>[];
  var reach = spans.isEmpty ? 0 : spans.first.$2;
  for (final (s, e) in spans.skip(1)) {
    if (s - reach > 3) gaps.add('${label(reach + 1)} to ${label(s - 1)}');
    if (e > reach) reach = e;
  }
  return gaps;
}
