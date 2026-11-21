/// Telling one job apart from another across job boards. The same opening is
/// often on NHS Jobs, Reed and Adzuna at once, written a little differently
/// each time ("Co-ordinator" and "Coordinator", "Example Trust Ltd" and
/// "Example Trust", "Leeds, West Yorkshire" and "Leeds"). These keys ignore
/// those differences, so the copies can be merged into one.
library;

/// Short forms written out, so "Sr" and "Senior" read the same.
const _spelled = {
  'sr': 'senior',
  'snr': 'senior',
  'jr': 'junior',
  'jnr': 'junior',
  'mgr': 'manager',
  'asst': 'assistant',
  'admin': 'administrator',
  'dev': 'developer',
  'eng': 'engineer',
};

/// Words that say nothing about the job ("(m/f/d)" and filler).
const _noise = {'m', 'f', 'd', 'w', 'x', 'job', 'vacancy', 'the'};

/// Words that end an employer's name without changing who it is.
const _legal = {'ltd', 'limited', 'plc', 'llp', 'llc', 'inc', 'gmbh', 'co', 'company', 'uk', 'the', 'group'};

List<String> _words(String s) => s
    .toLowerCase()
    .replaceAll('&', ' and ')
    // "Co-ordinator" is "coordinator", "E-learning" is "elearning".
    .replaceAll(RegExp(r"(?<=[a-z])[-'’.](?=[a-z])"), '')
    .split(RegExp('[^a-z0-9]+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// A job title as a key: any case, punctuation and short forms ignored.
String normalJobTitle(String title) => [
  for (final w in _words(title))
    if (!_noise.contains(w)) _spelled[w] ?? w,
].join(' ');

/// An employer as a key: any case, without "Ltd", "PLC" and the like.
String normalEmployer(String company) => [
  for (final w in _words(company))
    if (!_legal.contains(w)) w,
].join(' ');

/// The town of a job's place as a key: the first part before a comma,
/// semicolon, bracket or dash, without a postcode ("Leeds, West Yorkshire"
/// and "Leeds LS1 4AP" are both "leeds").
String normalTown(String location) {
  final first = location.split(RegExp(r'[,;(/|]| - ')).first;
  return [
    for (final w in _words(first))
      // A UK postcode part (LS1, 4AP) or any word with a digit.
      if (!RegExp(r'\d').hasMatch(w)) w,
  ].join(' ');
}

/// The key two adverts for the same job share: title, employer and town.
/// Empty when there is no title or no employer, as two jobs with no
/// employer named cannot be told to be one.
String jobKey({required String title, required String company, String location = ''}) {
  final t = normalJobTitle(title), c = normalEmployer(company);
  if (t.isEmpty || c.isEmpty) return '';
  return '$t|$c|${normalTown(location)}';
}

/// True when two adverts are the same job: the same [jobKey], and the same
/// closing date when both give one.
bool sameJob(
  ({String title, String company, String location, String? closing}) a,
  ({String title, String company, String location, String? closing}) b,
) {
  final k = jobKey(title: a.title, company: a.company, location: a.location);
  if (k.isEmpty || k != jobKey(title: b.title, company: b.company, location: b.location)) return false;
  return a.closing == null || b.closing == null || a.closing == b.closing;
}
