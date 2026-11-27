/// The evidence bank's frameworks (plan A4): the standards a story can be
/// tagged with, how well each one is covered, which stories suit a
/// criterion, and where a story has already been used.
///
/// Everything here runs on the device: no AI is needed to tag, count or
/// suggest.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' show isValidIsoDate;
import 'package:interview_engine/interview_engine.dart' show RoleProfile;

import '../db/database.dart';
import 'companion.dart';
import 'interview_book.dart';
import 'json.dart';

/// One standard, dimension or value a story can evidence.
class EvidenceItem {
  const EvidenceItem(this.id, this.title, {this.area = ''});

  /// Stable within its framework; saved in the story's tags.
  final String id;
  final String title;

  /// The group it sits in ("Self effectiveness"); '' when the framework has none.
  final String area;
}

/// A set of standards to gather evidence against.
class EvidenceFramework {
  const EvidenceFramework({
    required this.id,
    required this.name,
    required this.items,
    this.about = '',
    this.note = '',
  });

  /// Saved in the story's tags. Person specifications use `role.<id>`.
  final String id;
  final String name;
  final List<EvidenceItem> items;
  final String about;

  /// A caveat shown beside the name, e.g. that the wording is a draft.
  final String note;

  bool get isRole => id.startsWith(rolePrefix);

  EvidenceItem? item(String id) => items.where((i) => i.id == id).firstOrNull;
}

/// The id prefix of a role profile's person specification.
const rolePrefix = 'role.';

/// The NHS Leadership and Management Framework, as structured in the
/// September 2025 draft: three areas, nine standards.
const nhsLeadershipFramework = EvidenceFramework(
  id: 'nhs_lmf',
  name: 'NHS Leadership and Management Framework',
  about: 'Standards for managers and leaders at every level, in three areas.',
  note: 'Draft structure (September 2025): check the final wording.',
  items: [
    EvidenceItem('self_safety', 'Balancing safety, productivity and wellbeing', area: 'Self effectiveness'),
    EvidenceItem('self_communicating', 'Communicating and listening effectively', area: 'Self effectiveness'),
    EvidenceItem(
      'self_accountability',
      'Delivering with accountability and integrity',
      area: 'Self effectiveness',
    ),
    EvidenceItem(
      'people_environment',
      'Creating a high-performing work environment',
      area: 'Managing people and resources',
    ),
    EvidenceItem(
      'people_performance',
      'Improving performance and operational delivery',
      area: 'Managing people and resources',
    ),
    EvidenceItem(
      'people_resources',
      'Maximising resources and financial value',
      area: 'Managing people and resources',
    ),
    EvidenceItem(
      'care_outcomes',
      'Improving patient outcomes and experiences',
      area: 'Delivering across health and care',
    ),
    EvidenceItem(
      'care_improvement',
      'Leading with a mindset of improvement and innovation',
      area: 'Delivering across health and care',
    ),
    EvidenceItem(
      'care_collaboration',
      'Working collaboratively to achieve successful outcomes',
      area: 'Delivering across health and care',
    ),
  ],
);

/// The NHS Healthcare Leadership Model: nine dimensions.
const healthcareLeadershipModel = EvidenceFramework(
  id: 'nhs_hlm',
  name: 'Healthcare Leadership Model',
  about: 'The nine dimensions of leadership behaviour used across the NHS.',
  items: [
    EvidenceItem('shared_purpose', 'Inspiring shared purpose'),
    EvidenceItem('leading_with_care', 'Leading with care'),
    EvidenceItem('evaluating_information', 'Evaluating information'),
    EvidenceItem('connecting_service', 'Connecting our service'),
    EvidenceItem('sharing_vision', 'Sharing the vision'),
    EvidenceItem('engaging_team', 'Engaging the team'),
    EvidenceItem('holding_to_account', 'Holding to account'),
    EvidenceItem('developing_capability', 'Developing capability'),
    EvidenceItem('influencing_results', 'Influencing for results'),
  ],
);

/// The six values of the NHS Constitution.
const nhsValuesFramework = EvidenceFramework(
  id: 'nhs_values',
  name: 'NHS Constitution values',
  about: 'Values-based recruitment asks for a story behind each value.',
  items: [
    EvidenceItem('working_together', 'Working together for patients'),
    EvidenceItem('respect_dignity', 'Respect and dignity'),
    EvidenceItem('quality_of_care', 'Commitment to quality of care'),
    EvidenceItem('compassion', 'Compassion'),
    EvidenceItem('improving_lives', 'Improving lives'),
    EvidenceItem('everyone_counts', 'Everyone counts'),
  ],
);

/// The twelve interview competencies (domain/companion.dart) as a
/// framework, read from each story's competency list rather than its tags.
final competencyFramework = EvidenceFramework(
  id: 'competencies',
  name: 'Interview competencies',
  about: 'What employers score at interview, across sectors.',
  items: [for (final e in competencyNames.entries) EvidenceItem(e.key, e.value)],
);

/// The built-in frameworks a story can be tagged with.
const evidenceFrameworks = [nhsLeadershipFramework, healthcareLeadershipModel, nhsValuesFramework];

/// A role profile's person specification as a framework: one item per
/// criterion.
EvidenceFramework personSpecFramework(RoleProfile p) => EvidenceFramework(
  id: '$rolePrefix${p.id}',
  name: 'Person specification: ${[p.title, if (p.employer.isNotEmpty) p.employer].join(', ')}',
  items: [
    for (final c in p.criteria) EvidenceItem(c.id, c.text, area: c.essential ? 'Essential' : 'Desirable'),
  ],
);

/// The person specifications of the saved role profiles that have criteria.
List<EvidenceFramework> roleFrameworks(List<RoleProfileRow> rows) => [
  for (final p in [
    for (final r in rows)
      if (!r.deleted) InterviewBook.roleProfileOf(r),
  ])
    if (p.criteria.isNotEmpty) personSpecFramework(p),
];

/// A built-in framework by id, or null.
EvidenceFramework? builtInFramework(String id) => id == competencyFramework.id
    ? competencyFramework
    : evidenceFrameworks.where((f) => f.id == id).firstOrNull;

// ---- tags ----

/// One framework item a story evidences.
class StoryTag {
  const StoryTag(this.framework, this.item);
  final String framework;
  final String item;

  Json toJson() => {'framework': framework, 'item': item};

  @override
  bool operator ==(Object other) => other is StoryTag && other.framework == framework && other.item == item;

  @override
  int get hashCode => Object.hash(framework, item);

  @override
  String toString() => '$framework/$item';
}

/// The tags saved on a story; anything unreadable is skipped.
List<StoryTag> tagsOf(Story s) => decodeTags(s.tags);

List<StoryTag> decodeTags(String json) => {
  for (final t in decodeList(json))
    if (t case {'framework': final String f, 'item': final String i} when f.isNotEmpty && i.isNotEmpty)
      StoryTag(f, i),
}.toList();

String encodeTags(Iterable<StoryTag> tags) => jsonEncode([for (final t in tags.toSet()) t.toJson()]);

/// The title of [t], from the built-in frameworks or [roles]; '' if unknown.
String tagTitle(StoryTag t, {List<EvidenceFramework> roles = const []}) {
  final f = builtInFramework(t.framework) ?? roles.where((r) => r.id == t.framework).firstOrNull;
  return f?.item(t.item)?.title ?? '';
}

/// True when [s] evidences [item] of [f]: a tag, or for the competencies
/// the competency list, or for a person specification the criterion text
/// a practice answer was saved with.
bool storyCovers(Story s, EvidenceFramework f, EvidenceItem item) {
  if (f.id == competencyFramework.id) return strs(decodeList(s.competencies)).contains(item.id);
  if (tagsOf(s).contains(StoryTag(f.id, item.id))) return true;
  if (f.isRole) {
    final want = item.title.toLowerCase().trim();
    return strs(decodeList(s.criteria)).any((c) => c.toLowerCase().trim() == want);
  }
  return false;
}

// ---- coverage ----

/// How well one item is evidenced: none, some (one story, or drafts), or
/// ready (two or more confirmed stories).
enum CoverageLevel {
  none('No story yet'),
  some('Some evidence'),
  ready('Ready: 2+ confirmed');

  const CoverageLevel(this.label);
  final String label;
}

class ItemCoverage {
  const ItemCoverage(this.item, this.stories);
  final EvidenceItem item;
  final List<Story> stories;

  int get confirmed => stories.where((s) => s.confirmed).length;

  CoverageLevel get level => confirmed >= 2
      ? CoverageLevel.ready
      : stories.isEmpty
      ? CoverageLevel.none
      : CoverageLevel.some;

  /// "No story yet", "1 story (draft)", "2 stories, 1 confirmed", "3 confirmed".
  String get summary {
    if (stories.isEmpty) return CoverageLevel.none.label;
    final n = stories.length;
    if (confirmed == n) return n == 1 ? '1 story' : '$n confirmed';
    if (n == 1) return '1 story (draft)';
    return '$n stories, $confirmed confirmed';
  }
}

/// Each item of [f] with the stories that evidence it, in the framework's order.
List<ItemCoverage> coverageOf(EvidenceFramework f, List<Story> stories) => [
  for (final i in f.items)
    ItemCoverage(i, [
      for (final s in stories)
        if (storyCovers(s, f, i)) s,
    ]),
];

// ---- suggestions ----

const _stop = {
  'about',
  'with',
  'that',
  'this',
  'from',
  'have',
  'into',
  'your',
  'their',
  'there',
  'which',
  'where',
  'when',
  'what',
  'will',
  'able',
  'ability',
  'experience',
  'evidence',
  'demonstrate',
  'demonstrable',
  'knowledge',
  'understanding',
  'skills',
  'work',
  'working',
  'good',
  'excellent',
  'effective',
  'effectively',
  'other',
  'others',
  'within',
  'across',
  'through',
  'using',
  'including',
  'such',
  'well',
  'must',
  'should',
  'also',
};

/// The words of [text] worth matching: lower case, four letters or more,
/// common words left out, plural and -ing/-ed endings trimmed.
Set<String> keywords(String text) => {
  for (final w in text.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
    if (w.length >= 4 && !_stop.contains(w)) _stem(w),
};

String _stem(String w) {
  for (final end in const ['ing', 'ed', 'es', 's']) {
    if (w.length - end.length >= 4 && w.endsWith(end)) return w.substring(0, w.length - end.length);
  }
  return w;
}

String _storyText(Story s) => [s.title, s.situation, s.task, s.action, s.result].join(' ');

/// A suggested story for a criterion and why.
typedef StorySuggestion = ({Story story, bool tagged, int overlap});

/// The stories that best fit [item]: those tagged with it first, then by
/// how many of its words they share; confirmed before drafts, newer before
/// older. Stories that share no word and carry no tag are left out.
List<StorySuggestion> suggestStories(
  EvidenceItem item,
  List<Story> stories, {
  EvidenceFramework? framework,
  int limit = 3,
}) {
  final want = keywords(item.title);
  final found = <StorySuggestion>[];
  for (final s in stories) {
    final tagged = framework != null && storyCovers(s, framework, item);
    final overlap = keywords(_storyText(s)).intersection(want).length;
    if (tagged || overlap > 0) found.add((story: s, tagged: tagged, overlap: overlap));
  }
  int score(StorySuggestion x) => (x.tagged ? 1000 : 0) + x.overlap * 10 + (x.story.confirmed ? 5 : 0);
  found.sort((a, b) {
    final c = score(b).compareTo(score(a));
    return c != 0 ? c : storyDate(b.story).compareTo(storyDate(a.story));
  });
  return found.take(limit).toList();
}

// ---- dates ----

/// When the story happened, or when it was added if that was not given.
String storyDate(Story s) => (s.happened ?? '').isNotEmpty ? s.happened! : s.added;

/// True for a yyyy-MM-dd or yyyy-MM date.
bool validStoryDate(String d) =>
    d.length == 7 ? RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(d) : isValidIsoDate(d);

const refreshHint = 'This happened over a year ago: refresh the details while you still remember them.';

/// True when [s] happened more than twelve months before [today] (yyyy-MM-dd).
bool needsRefresh(Story s, {required String today}) {
  final d = storyDate(s);
  final when = DateTime.tryParse(d.length == 7 ? '$d-01' : d);
  final now = DateTime.tryParse(today);
  if (when == null || now == null) return false;
  return when.isBefore(DateTime(now.year - 1, now.month, now.day));
}

// ---- uses ----

const storyUseKinds = <String, String>{
  'cv': 'Tailored CV',
  'statement': 'Supporting statement',
  'application': 'Application',
  'interview': 'Interview',
};

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// The earlier uses of [storyId] with [employer], leaving out the same
/// criterion of the same role profile or application ([refId]).
List<StoryUse> earlierUsesWith(
  List<StoryUse> uses, {
  required String storyId,
  required String employer,
  String refId = '',
  String criterion = '',
}) {
  final e = _norm(employer);
  if (e.isEmpty) return const [];
  return [
    for (final u in uses)
      if (!u.deleted &&
          u.storyId == storyId &&
          _norm(u.employer) == e &&
          !(u.refId == refId && u.criterion == criterion))
        u,
  ];
}

/// A warning when [storyId] was already used with [employer]; null if not.
String? reuseWarning(
  List<StoryUse> uses, {
  required String storyId,
  required String employer,
  String refId = '',
  String criterion = '',
}) {
  final before = earlierUsesWith(
    uses,
    storyId: storyId,
    employer: employer,
    refId: refId,
    criterion: criterion,
  );
  if (before.isEmpty) return null;
  final last = before.reduce((a, b) => a.at.compareTo(b.at) >= 0 ? a : b);
  final where = [storyUseKinds[last.kind] ?? last.kind, if (last.criterion.isNotEmpty) '"${last.criterion}"'];
  return 'You already used this story with ${last.employer} (${where.join(', ')}, ${last.at.split('T').first}). '
      'The same panel may read both: use another story if you can.';
}

/// One line per use, newest first: "Supporting statement · Ward clerk, Example Trust · 2026-11-20".
List<String> usedInLines(List<StoryUse> uses, String storyId) {
  final mine = [
    for (final u in uses)
      if (!u.deleted && u.storyId == storyId) u,
  ]..sort((a, b) => b.at.compareTo(a.at));
  return [
    for (final u in mine)
      [
        storyUseKinds[u.kind] ?? u.kind,
        [u.role, u.employer].where((x) => x.isNotEmpty).join(', '),
        if (u.criterion.isNotEmpty) u.criterion,
        u.at.split('T').first,
      ].where((x) => x.isNotEmpty).join(' · '),
  ];
}

// ---- the AI story line (B5) ----

/// The most tags a story brings to the AI line, to keep the prompt small.
const maxTagsInStoryLine = 4;

/// The standards [s] is tagged with, for the AI story line, e.g.
/// "Evidences: NHS Constitution values: Compassion; Healthcare Leadership
/// Model: Engaging the team." At most [max] tags (then "and N more");
/// unknown tags are left out; '' when there is none. A person
/// specification is named by its role, not its long heading.
String storyTagLine(Story s, {List<EvidenceFramework> roles = const [], int max = maxTagsInStoryLine}) {
  final named = <String>[];
  for (final t in tagsOf(s)) {
    final f = builtInFramework(t.framework) ?? roles.where((r) => r.id == t.framework).firstOrNull;
    final title = f?.item(t.item)?.title ?? '';
    if (f == null || title.isEmpty) continue;
    named.add('${f.isRole ? 'Person specification' : f.name}: $title');
  }
  if (named.isEmpty) return '';
  final shown = named.take(max).join('; ');
  final more = named.length - max;
  return 'Evidences: $shown${more > 0 ? '; and $more more' : ''}.';
}

// ---- stories a draft drew on (B5) ----

List<String> _words(String text) => [
  for (final w in text.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
    if (w.isNotEmpty) w,
];

/// The distinctive phrases of [s]: each run of three words from its title,
/// situation, task, action and result that holds at least one keyword
/// (see [keywords]).
Set<String> storyPhrases(Story s) {
  final phrases = <String>{};
  for (final part in [s.title, s.situation, s.task, s.action, s.result]) {
    final w = _words(part);
    for (var i = 0; i + 3 <= w.length; i++) {
      final run = w.sublist(i, i + 3);
      if (run.any((x) => x.length >= 4 && !_stop.contains(x))) phrases.add(run.join(' '));
    }
  }
  return phrases;
}

/// True when [draft] shares at least [min] distinctive phrases with [s], or
/// holds its title whole: a simple sign the draft drew on the story.
bool draftDrawsOn(Story s, String draft, {int min = 2}) {
  final text = ' ${_words(draft).join(' ')} ';
  final title = _words(s.title).join(' ');
  if (_words(s.title).length >= 3 && text.contains(' $title ')) return true;
  var n = 0;
  for (final p in storyPhrases(s)) {
    if (text.contains(' $p ') && ++n >= min) return true;
  }
  return false;
}

/// The use kind for a story in a tailored draft: 'statement' when the
/// cover letter or supporting statement drew on it, else 'cv'.
String draftUseKind(Story s, {required String letter}) =>
    letter.isNotEmpty && draftDrawsOn(s, letter) ? 'statement' : 'cv';

// ---- monthly capture nudge (B5) ----

/// True when no story was captured in the [days] days up to [today]
/// (yyyy-MM-dd): the check-in then offers to capture one from this month.
bool captureNudgeDue(List<Story> stories, {required String today, int days = 30}) {
  final now = DateTime.tryParse(today);
  if (now == null) return false;
  final since = DateTime(now.year, now.month, now.day - days);
  return !stories.any((s) {
    if (s.deleted) return false;
    final added = DateTime.tryParse(s.added.length >= 10 ? s.added.substring(0, 10) : s.added);
    return added != null && !added.isBefore(since);
  });
}
