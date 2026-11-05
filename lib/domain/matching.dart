import 'feeds.dart';
import 'profile.dart';

/// A quick, offline match of a job to the candidate, 0 to 100: target roles
/// and search terms in the title, skills in the description, and the
/// salary against the minimum. The AI's assessment replaces it when asked.
int localFit(CandidateProfile p, {required String title, required String description, int? salaryMax}) {
  final t = title.toLowerCase();
  final d = description.toLowerCase();
  final roles = {...p.targets.roles, ...p.searchTerms, if (p.currentRole.isNotEmpty) p.currentRole};

  // Title: the best share of a target role's words that appear in it.
  var titleScore = 0.0;
  for (final role in roles) {
    final words = _words(role);
    if (words.isEmpty) continue;
    final share = words.where(t.contains).length / words.length;
    if (share > titleScore) titleScore = share;
  }

  // Skills: how many of the candidate's skills the advert mentions, out of
  // a handful (adverts name few of anyone's skills).
  final skills = p.skills.where((s) => s.length > 2).toList();
  final hits = skills.where((s) => d.contains(s.toLowerCase()) || t.contains(s.toLowerCase())).length;
  final skillScore = skills.isEmpty ? 0.5 : (hits / 5).clamp(0, 1).toDouble();

  var score = 60 * titleScore + 35 * skillScore + 5;
  final min = p.targets.salaryMin;
  if (min != null && salaryMax != null && salaryMax > 0 && salaryMax < min) score -= 20;
  return score.round().clamp(0, 100);
}

const _stop = {'and', 'or', 'of', 'the', 'a', 'an', 'in', 'for', 'to', 'with', '&', '-', '/'};

List<String> _words(String s) =>
    s.toLowerCase().split(RegExp(r'[^a-z0-9+#]+')).where((w) => w.length > 1 && !_stop.contains(w)).toList();

/// Levels a search can stop at, lowest first.
const seniorityLevels = {
  'junior': 'Junior',
  'mid': 'Mid-level',
  'senior': 'Senior',
  'director': 'Director or head',
};

const degreeLevels = {'none': 'No degree', 'bachelor': "Bachelor's", 'master': "Master's"};

final _director = RegExp(r'\b(head of|director|vp|vice president|chief)\b');
final _senior = RegExp(r'\b(senior|sr|lead|principal|staff)\b');
final _junior = RegExp(r'\b(junior|jr|graduate|trainee|apprentice|intern|entry[- ]level)\b');

/// Index into [seniorityLevels], from the title alone; no marker is mid-level.
int seniorityOf(String title) {
  final t = title.toLowerCase();
  if (_director.hasMatch(t)) return 3;
  if (_senior.hasMatch(t)) return 2;
  if (_junior.hasMatch(t)) return 0;
  return 1;
}

final _doctorate = RegExp(r'\b(ph\.?d|doctorate|doctoral)\b');
final _master = RegExp(r"\b(master'?s|msc|m\.sc|mba|postgraduate)\b");
final _bachelor = RegExp(r"\b(bachelor'?s?|bsc|b\.sc|undergraduate|degree)\b");
final _optional = RegExp(r'\b(preferred|desirable|desired|equivalent|or experience|advantageous|bonus)\b');

/// The degree an advert asks for, as an index into [degreeLevels] (0 none,
/// 1 bachelor's, 2 master's; a doctorate counts as 3, above every choice).
/// Sentences that call it preferred or replaceable by experience are ignored.
int degreeRequired(String description) {
  var level = 0;
  for (final sentence in description.toLowerCase().split(RegExp(r'[.\n;]'))) {
    if (_optional.hasMatch(sentence)) continue;
    final l = _doctorate.hasMatch(sentence)
        ? 3
        : _master.hasMatch(sentence)
        ? 2
        : _bachelor.hasMatch(sentence)
        ? 1
        : 0;
    if (l > level) level = l;
  }
  return level;
}

/// Whether [post] passes the search filters in [t]. Unknowns pass: a job
/// that does not state its pay is not hidden by the pay filter.
bool passesFilters(Targets t, Posting post) {
  if (t.remoteOnly && !post.remote) return false;
  final pay = post.salaryMax ?? post.salaryMin;
  final sameCurrency = post.currency.isEmpty || t.salaryCurrency.isEmpty || post.currency == t.salaryCurrency;
  if (t.strictSalary && t.salaryMin != null && pay != null && pay > 0 && sameCurrency && pay < t.salaryMin!) {
    return false;
  }
  final seniority = seniorityLevels.keys.toList().indexOf(t.maxSeniority);
  if (seniority >= 0 && seniorityOf(post.title) > seniority) return false;
  final degree = degreeLevels.keys.toList().indexOf(t.maxDegree);
  if (degree >= 0 && degreeRequired(post.description) > degree) return false;
  return true;
}
