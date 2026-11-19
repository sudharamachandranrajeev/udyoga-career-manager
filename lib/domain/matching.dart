import 'dart:math' as math;

import 'countries.dart';
import 'eligibility.dart';
import 'pay.dart';
import 'profile.dart';

/// A job as the quick match reads it.
class JobFacts {
  const JobFacts({
    required this.title,
    this.description = '',
    this.company = '',
    this.location = '',
    this.country = '',
    this.remote = false,
    this.salaryMin,
    this.salaryMax,
    this.currency = '',
    this.salaryText = '',
  });
  final String title, description, company, location, country;
  final bool remote;
  final int? salaryMin, salaryMax;
  final String currency, salaryText;
}

/// One part of the quick match: a score from 0 to 1, or null when there is
/// nothing to go on (it then counts neither way), and why.
class FitFactor {
  const FitFactor(this.name, this.weight, this.score, this.why);
  final String name;
  final int weight;
  final double? score;
  final String why;

  bool get known => score != null;
}

/// The quick match of a job to the candidate: the score, each factor
/// behind it, and the advert's eligibility lines for this person.
class FitResult {
  const FitResult(this.fit, this.factors, this.eligibility);
  final int fit;
  final List<FitFactor> factors;
  final EligibilityCheck eligibility;

  bool get excluded => eligibility.excluded;
  bool get blocked => eligibility.blocked;
}

/// The most a job scores when the advert rules the candidate out.
const blockedCap = 15;

/// A quick, offline match of a job to the candidate, 0 to 100, with its
/// reasons. Title words and skills are matched as whole words (plurals
/// allowed), so "Excel" never matches "excellent". Pay is compared only in
/// the same currency. A factor with nothing to go on is left out rather
/// than guessed. Exclusions score 0; an eligibility blocker caps the score
/// at [blockedCap]. The AI's assessment replaces it when asked.
FitResult scoreFit(CandidateProfile p, JobFacts j, {required String today}) {
  final eligibility = checkEligibility(
    p,
    title: j.title,
    company: j.company,
    description: j.description,
    country: j.country,
    today: today,
  );
  final factors = [
    _title(p, j),
    _skills(p, j),
    _location(p, j),
    _seniority(p, j),
    _pay(p, j),
    _eligibility(p, j, eligibility, today),
  ];
  if (eligibility.excluded) return FitResult(0, factors, eligibility);
  var sum = 0.0, weights = 0;
  for (final f in factors.where((f) => f.known)) {
    sum += f.weight * f.score!;
    weights += f.weight;
  }
  var fit = weights == 0 ? 0 : (100 * sum / weights).round();
  if (eligibility.blocked) fit = math.min(fit, blockedCap);
  return FitResult(fit.clamp(0, 100), factors, eligibility);
}

/// Just the score of [scoreFit].
int localFit(CandidateProfile p, JobFacts j, {required String today}) => scoreFit(p, j, today: today).fit;

const _stop = {'and', 'or', 'of', 'the', 'a', 'an', 'in', 'for', 'to', 'with', 'at', 'on', '&', '-', '/'};

/// The words of a role or skill, lower case, without filler words.
List<String> wordsOf(String s) =>
    s.toLowerCase().split(RegExp(r'[^a-z0-9+#]+')).where((w) => w.length > 1 && !_stop.contains(w)).toList();

final _cache = <String, RegExp>{};

/// True when [phrase] appears in [text] as whole words, any case, allowing
/// a plural ("analyst" finds "Analysts", never "analytics").
bool mentions(String text, String phrase) {
  final words = phrase.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return false;
  final re = _cache.putIfAbsent(
    words.join(' '),
    () => RegExp(
      '(?<![a-z0-9À-ɏ])${words.map(RegExp.escape).join(r'[\s\-/]+')}(?:s|es)?(?![a-z0-9À-ɏ])',
      caseSensitive: false,
    ),
  );
  return re.hasMatch(text);
}

FitFactor _title(CandidateProfile p, JobFacts j) {
  final roles = {...p.targets.roles, ...p.searchTerms, if (p.currentRole.isNotEmpty) p.currentRole};
  if (roles.isEmpty) return const FitFactor('Title', 35, null, 'No target roles to compare with');
  var best = 0.0;
  var bestRole = '';
  for (final role in roles) {
    if (mentions(j.title, role)) return FitFactor('Title', 35, 1, 'The title is "$role"');
    final words = wordsOf(role);
    if (words.isEmpty) continue;
    final share = words.where((w) => mentions(j.title, w)).length / words.length;
    if (share > best) (best, bestRole) = (share, role);
  }
  return FitFactor(
    'Title',
    35,
    best,
    best == 0 ? 'The title names none of your target roles' : 'The title shares words with "$bestRole"',
  );
}

FitFactor _skills(CandidateProfile p, JobFacts j) {
  final skills = {
    for (final s in p.skills)
      if (s.trim().length > 1) s.trim(),
  }.toList();
  if (skills.isEmpty) return const FitFactor('Skills', 20, null, 'No skills on your profile');
  final text = '${j.title}\n${j.description}';
  final hits = skills.where((s) => mentions(text, s)).toList();
  // The square root of the share: a long skills list is not punished for
  // an advert naming only some of them, and every extra hit still counts.
  final score = math.sqrt(hits.length / skills.length);
  return FitFactor(
    'Skills',
    20,
    score,
    hits.isEmpty
        ? 'The advert names none of your skills'
        : 'The advert names ${hits.length} of your ${skills.length} skills: ${hits.take(5).join(', ')}',
  );
}

FitFactor _location(CandidateProfile p, JobFacts j) {
  final wanted = p.searchCountries;
  final remoteOk = p.targets.remote;
  if (j.remote && remoteOk) return const FitFactor('Location', 15, 1, 'Remote, and you want remote work');
  if (j.country.isEmpty) {
    return FitFactor('Location', 15, j.remote ? 0.7 : null, j.remote ? 'Remote' : 'The country is not given');
  }
  if (wanted.isNotEmpty && !wanted.contains(j.country)) {
    return FitFactor('Location', 15, j.remote ? 0.5 : 0, '${Country.nameOf(j.country)} is not on your list');
  }
  // In a wanted country: the home areas (and their commute towns) narrow
  // it further.
  final places = [
    for (final a in p.targets.homeAreas)
      if ((a.country.isEmpty ? p.country : a.country) == j.country) ...a.towns,
  ];
  if (places.isEmpty || j.location.isEmpty) {
    return FitFactor('Location', 15, 1, 'In ${Country.nameOf(j.country)}');
  }
  final near = places.firstWhere((l) => mentions(j.location, l), orElse: () => '');
  return near.isNotEmpty
      ? FitFactor('Location', 15, 1, 'In $near')
      : FitFactor('Location', 15, 0.6, 'In ${Country.nameOf(j.country)}, away from ${places.first}');
}

/// How senior a job title is, 1 (trainee) to 5 (director); null when the
/// title says nothing. An NHS band in the title or pay text counts too.
int? seniorityOf(String title, {String salaryText = ''}) {
  final band = bandIn('$title $salaryText');
  if (band.isNotEmpty) {
    return switch (band) {
      '1' || '2' => 1,
      '3' || '4' => 2,
      '5' || '6' => 3,
      '7' => 4,
      _ => 5,
    };
  }
  final t = title.toLowerCase();
  bool has(String words) => RegExp('\\b($words)\\b').hasMatch(t);
  if (has(r'chief|director|head|vice president|vp|cxo|cto|cio|ceo|cfo|coo|partner')) return 5;
  if (has(r'principal|lead|senior|sr|staff engineer|manager|consultant')) return 4;
  if (has(r'intern|internship|apprentice|apprenticeship|trainee|graduate|student|entry level|entry-level')) {
    return 1;
  }
  if (has(r'junior|jr|assistant|associate|support worker|administrator|clerk|receptionist')) return 2;
  if (has(r'officer|specialist|analyst|engineer|developer|nurse|coordinator|co-ordinator|practitioner')) {
    return 3;
  }
  return null;
}

/// The level the candidate is aiming at: their target roles, else their
/// current role, else their years of experience; null with nothing to go on.
int? candidateLevel(CandidateProfile p) {
  final targets = [for (final r in p.targets.roles) ?seniorityOf(r)];
  if (targets.isNotEmpty) return targets.reduce(math.max);
  final current = seniorityOf(p.currentRole);
  final years = p.yearsExperience;
  final byYears = years == null || years <= 0
      ? null
      : years < 1
      ? 1
      : years < 3
      ? 2
      : years < 8
      ? 3
      : years < 15
      ? 4
      : 5;
  if (current != null && byYears != null) return ((current + byYears) / 2).round();
  return current ?? byYears;
}

const _levels = {1: 'trainee', 2: 'junior', 3: 'mid-level', 4: 'senior', 5: 'director'};

FitFactor _seniority(CandidateProfile p, JobFacts j) {
  final job = seniorityOf(j.title, salaryText: j.salaryText);
  final me = candidateLevel(p);
  if (job == null || me == null) return const FitFactor('Seniority', 10, null, 'Level not clear');
  final d = job - me;
  final score = switch (d) {
    0 => 1.0,
    1 || -1 => 0.7,
    -2 => 0.4,
    2 => 0.3,
    _ => 0.1,
  };
  return FitFactor(
    'Seniority',
    10,
    score,
    d == 0
        ? 'A ${_levels[job]} role, your level'
        : d > 0
        ? 'A ${_levels[job]} role, above your ${_levels[me]} level'
        : 'A ${_levels[job]} role, below your ${_levels[me]} level',
  );
}

FitFactor _pay(CandidateProfile p, JobFacts j) {
  final min = p.targets.salaryMin;
  if (min == null) return const FitFactor('Pay', 10, null, 'No minimum pay set');
  final top = j.salaryMax ?? j.salaryMin;
  if (top == null || top <= 0) return const FitFactor('Pay', 10, null, 'The advert gives no pay');
  final mine =
      (p.targets.salaryCurrency.isNotEmpty ? p.targets.salaryCurrency : Country.of(p.country)?.currency ?? '')
          .toUpperCase();
  final theirs = j.currency.toUpperCase();
  if (mine.isEmpty || theirs.isEmpty || mine != theirs) {
    return FitFactor(
      'Pay',
      10,
      null,
      theirs.isEmpty
          ? 'The pay\'s currency is not given'
          : 'Pay is in $theirs, your minimum in ${mine.ifEmpty('?')}',
    );
  }
  if (top >= min) return FitFactor('Pay', 10, 1, 'Pays up to $theirs $top, at or above your $min');
  // 70 % of the minimum or less scores nothing.
  final score = ((top / min - 0.7) / 0.3).clamp(0, 1).toDouble();
  return FitFactor('Pay', 10, score, 'Pays up to $theirs $top, below your $min');
}

FitFactor _eligibility(CandidateProfile p, JobFacts j, EligibilityCheck e, String today) {
  if (e.excluded) return const FitFactor('Eligibility', 10, 0, 'Ruled out by your exclusions');
  if (e.blocked) {
    final f = e.sorted.first;
    return FitFactor('Eligibility', 10, 0, '${f.title}: ${f.note}');
  }
  if (e.cautious) {
    final f = e.sorted.first;
    return FitFactor('Eligibility', 10, 0.5, '${f.title}: ${f.note}');
  }
  final basis = j.country.isEmpty ? null : p.rights.basisIn(j.country, today);
  if (basis != null) return FitFactor('Eligibility', 10, 1, basis);
  if (e.findings.any((f) => f.kind == EligibilityKind.sponsorshipOffered)) {
    return const FitFactor('Eligibility', 10, 0.8, 'Visa sponsorship offered');
  }
  // Without the person's rights on record there is nothing to judge.
  if (p.rights.isEmpty || j.country.isEmpty) return const FitFactor('Eligibility', 10, null, 'Not known');
  return FitFactor('Eligibility', 10, 0.4, 'No right to work in ${Country.nameOf(j.country)} on record');
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
