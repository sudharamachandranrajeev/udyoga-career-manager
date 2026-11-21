/// Head nouns that name the same kind of job. The head noun is the last word
/// of a job title ("trainer" in "clinical systems trainer"); employers swap
/// it freely, so a search for a "facilitator" should also find "trainer"
/// jobs. Used by SOC matching (lib/domain/occupations.dart) and by role
/// families (lib/domain/role_family.dart).
///
/// The map is kept small and conservative on purpose. Over-fuzzy matching is
/// as hated as literal matching, so only words that really are swapped for
/// the same work are grouped. Left out on purpose:
/// - "assistant" (a lower grade than officer or administrator),
/// - "engineer" (civil and software engineers share nothing),
/// - "teacher" and "lecturer" (regulated, need a teaching qualification),
/// - "champion" (a side role, not a job),
/// - "consultant" (in the NHS a consultant is a senior doctor).
library;

/// Groups of head nouns used for the same work.
const headSynonymGroups = <List<String>>[
  // People who teach adults at work.
  ['trainer', 'facilitator', 'educator', 'instructor', 'tutor', 'coach'],
  // Office roles that run a process or a team's paperwork.
  ['officer', 'administrator', 'coordinator'],
  // People who study data, systems or a subject in depth.
  ['analyst', 'specialist'],
  // People who write software.
  ['developer', 'programmer'],
  // People who lead a team or a piece of work.
  ['lead', 'leader', 'manager'],
  // The same word, two spellings.
  ['adviser', 'advisor'],
];

/// Groups of other words in a title that mean the same field. Only one so
/// far: in UK job titles "digital" work is IT work (NHS digital teams are
/// the IT department), so a "digital trainer" is an IT trainer.
const wordSynonymGroups = <List<String>>[
  ['it', 'ict', 'digital', 'computer', 'computing'],
];

/// The head-noun group holding [w], or null.
List<String>? _groupOf(String w) => headSynonymGroups.where((g) => g.contains(w)).firstOrNull;

/// The head nouns used for the same work as [head], including [head]
/// itself; just [head] when it is in no group. [head] is lower case.
Set<String> headSynonyms(String head) => {head, ...?_groupOf(head)};

/// True when [a] and [b] are the same head noun or synonyms.
bool sameHead(String a, String b) => a == b || headSynonyms(a).contains(b);

/// A crude stem, so "training" and "trainer" count as the same word when
/// checking a head-noun group. Only for comparing words, never for display.
String stem(String w) {
  if (w.length <= 4) return w;
  for (final end in const ['ings', 'ing', 'ers', 'er', 'ors', 'or', 'es', 's']) {
    if (w.endsWith(end) && w.length - end.length >= 4) return w.substring(0, w.length - end.length);
  }
  return w;
}

/// The comparison key of word [w] in a title whose head noun is [head]:
/// a shared key ('#trainer', '#it') for a word in a synonym group, else
/// the word without a plural "s" ("systems" is "system"). A word whose
/// stem is the stem of a member of [head]'s group, like "training" in a
/// trainer's title, takes the group key too. Other words are not stemmed,
/// so "training" never matches "train" (a train manager is rail work).
String wordKey(String w, String head) {
  final group = _groupOf(w) ?? wordSynonymGroups.where((g) => g.contains(w)).firstOrNull;
  if (group != null) return '#${group.first}';
  final heads = _groupOf(head);
  if (heads != null && heads.any((h) => stem(h) == stem(w))) return '#${heads.first}';
  return w.length > 4 && w.endsWith('s') && !w.endsWith('ss') ? w.substring(0, w.length - 1) : w;
}
