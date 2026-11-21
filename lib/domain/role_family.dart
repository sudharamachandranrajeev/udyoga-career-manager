/// Role families: one role turned into the other job titles the same work
/// is advertised under, each with the reason it was added. Job search shows
/// them as chips the person can switch off, so nothing is hidden.
///
/// Sources, in order:
/// 1. The ONS SOC 2020 coding index (shipped): titles in the same unit group
///    as the role's best SOC matches.
/// 2. The head-noun synonym map (lib/domain/title_synonyms.dart):
///    "Digital Training Facilitator" also as "Digital Trainer".
/// 3. ESCO alternative labels and narrower occupations, fetched when online
///    and cached on the device. Only for a role that already had a SOC or
///    synonym match, and only ESCO occupations whose ISCO-08 code agrees
///    with that SOC match: ESCO answers invented titles with junk
///    ("digital training facilitator" gives "assistant outdoor animator").
/// 4. AI suggestions, labelled as such, only when the person asks.
library;

import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'ai.dart';
import 'feeds.dart';
import 'json.dart';
import 'occupations.dart';
import 'schema.dart';
import 'title_synonyms.dart';

/// How close a family title is to the role. Job search switches close
/// titles on by default and distant ones off.
enum Closeness { close, related, distant }

/// Where a family title came from.
enum FamilySource {
  /// The role exactly as the person typed it.
  typed,

  /// The ONS SOC 2020 coding index.
  soc,

  /// The head-noun synonym map.
  synonym,

  /// ESCO (European Commission).
  esco,

  /// An AI model; always shown as "AI suggestion".
  ai,
}

/// One title in a role family.
class FamilyTitle {
  const FamilyTitle({
    required this.title,
    required this.reason,
    required this.closeness,
    required this.source,
  });

  final String title;

  /// Why it is in the family, in plain words ("Same SOC 2020 group 3573").
  final String reason;
  final Closeness closeness;
  final FamilySource source;

  Json toJson() => {'title': title, 'reason': reason, 'closeness': closeness.name, 'source': source.name};

  factory FamilyTitle.fromJson(Json j) => FamilyTitle(
    title: str(j['title']),
    reason: str(j['reason']),
    closeness: Closeness.values.asNameMap()[str(j['closeness'])] ?? Closeness.related,
    source: FamilySource.values.asNameMap()[str(j['source'])] ?? FamilySource.soc,
  );
}

/// One role and the titles it goes by: the role first, then the rest,
/// without repeats (any case).
class RoleFamily {
  const RoleFamily({
    required this.role,
    required this.titles,
    this.matches = const [],
    this.synonymMatch = false,
  });

  /// The role as given.
  final String role;

  /// The role itself first, then the family, closest first by source.
  final List<FamilyTitle> titles;

  /// The role's SOC 2020 matches, best first; empty when the index has
  /// nothing close.
  final List<OccupationMatch> matches;

  /// The role's head noun is in the synonym map.
  final bool synonymMatch;

  /// The index or the synonym map knew the role, so ESCO may be asked.
  bool get known => matches.isNotEmpty || synonymMatch;

  /// The titles with [closeness].
  List<FamilyTitle> where(Closeness closeness) => [
    for (final t in titles)
      if (t.closeness == closeness) t,
  ];

  /// This family with [more] added after the titles it has, skipping
  /// repeats (any case).
  RoleFamily plus(Iterable<FamilyTitle> more) => RoleFamily(
    role: role,
    titles: _dedupe([...titles, ...more]),
    matches: matches,
    synonymMatch: synonymMatch,
  );

  Json toJson() => {
    'role': role,
    'titles': [for (final t in titles) t.toJson()],
    'matches': [for (final m in matches) m.toJson()],
    'synonymMatch': synonymMatch,
  };

  factory RoleFamily.fromJson(Json j) => RoleFamily(
    role: str(j['role']),
    titles: [for (final t in objs(j['titles'])) FamilyTitle.fromJson(t)],
    matches: [for (final m in objs(j['matches'])) OccupationMatch.fromJson(m)],
    synonymMatch: j['synonymMatch'] == true,
  );
}

/// Words written in capitals in job titles.
const _acronyms = {
  'it': 'IT',
  'ict': 'ICT',
  'hr': 'HR',
  'nhs': 'NHS',
  'gp': 'GP',
  'ai': 'AI',
  'epr': 'EPR',
  'ehr': 'EHR',
  'pa': 'PA',
  'ux': 'UX',
  'ui': 'UI',
  'sql': 'SQL',
  'seo': 'SEO',
  'cad': 'CAD',
  'qa': 'QA',
  'gis': 'GIS',
  'crm': 'CRM',
  'erp': 'ERP',
  'pmo': 'PMO',
  'bi': 'BI',
};

/// Lower-case [title] in title case ("it trainer" is "IT Trainer"). Words
/// that already hold a capital are kept as they are.
String titleCase(String title) => title
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) {
      if (w.contains(RegExp('[A-Z]'))) return w;
      final a = _acronyms[w];
      if (a != null) return a;
      if (const {'and', 'of', 'the', 'in', 'for', 'to', 'with'}.contains(w)) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    })
    .join(' ')
    .replaceFirstMapped(RegExp('^[a-z]'), (m) => m[0]!.toUpperCase());

/// The key titles are deduplicated on: any case, and "E-learning" is
/// "Elearning".
String _key(String title) =>
    title.toLowerCase().replaceAll(RegExp(r"[-'.]"), '').replaceAll(RegExp(r'\s+'), ' ').trim();

List<FamilyTitle> _dedupe(Iterable<FamilyTitle> titles) {
  final seen = <String>{};
  return [
    for (final t in titles)
      if (_key(t.title).isNotEmpty && seen.add(_key(t.title))) t,
  ];
}

/// The key of a title's head noun (its synonym group, or the word).
String _headKey(String title) {
  final words = normTitle(title).split(' ');
  return wordKey(words.last, words.last);
}

/// True when [title], whose head noun is the role's or a synonym of it, is
/// a close title for [role]: it ends in the role's own head word, or in a
/// word the role already uses ("trainer" for a "training facilitator"), or
/// its other words share at least one with the role's ("ICT Instructor" for
/// "Digital Training Facilitator": ICT and digital name the same field). A
/// synonym head with nothing else in common is only related: "AI Coach"
/// shares nothing with "Digital Training".
bool closeByHead(String title, String role) {
  final words = normTitle(title).split(' ').where((w) => w.isNotEmpty).toList();
  final roleWords = normTitle(role).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty || roleWords.isEmpty) return false;
  final head = words.last;
  if (roleWords.any((w) => w == head || stem(w) == stem(head))) return true;
  final others = titleKeys(title).difference({_headKey(title)});
  final roleOthers = titleKeys(role).difference({_headKey(role)});
  return others.intersection(roleOthers).isNotEmpty;
}

/// The role's title with its head noun swapped for each synonym:
/// "digital training facilitator" gives "digital trainer" (the word before
/// the head folds in when it is the same word, like "training"), "digital
/// training instructor", and so on.
List<String> synonymTitles(String role) {
  final words = normTitle(role).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final head = words.last;
  final out = <String>[];
  for (final syn in headSynonyms(head)) {
    if (syn == head) continue;
    final rest = words.sublist(0, words.length - 1);
    // "training" + "trainer" is "trainer", not "training trainer".
    if (rest.isNotEmpty && stem(rest.last) == stem(syn)) rest.removeLast();
    // A one-word role swaps to a bare head noun, which says little alone.
    if (rest.isEmpty) continue;
    out.add([...rest, syn].join(' '));
  }
  return out;
}

/// The family of [role] from the shipped data alone (SOC index and synonym
/// map), so it works offline. Up to [perGroup] titles from each of the
/// role's best [groups] SOC unit groups.
RoleFamily offlineFamily(String role, {SocIndex? index, int groups = 2, int perGroup = 15}) {
  final r = role.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (r.isEmpty) return RoleFamily(role: role, titles: const []);
  final soc = index ?? loadedSocIndex;
  final matches = soc?.matches(r) ?? const <OccupationMatch>[];
  final head = normTitle(r).split(' ').last;
  final synonymMatch = headSynonyms(head).length > 1;
  final roleHead = _headKey(r);
  final roleKeys = titleKeys(r);

  final titles = <FamilyTitle>[
    FamilyTitle(
      title: r,
      reason: matches.firstOrNull?.exact == true
          ? 'The title you searched for (SOC 2020 ${matches.first.soc})'
          : 'The title you searched for',
      closeness: Closeness.close,
      source: FamilySource.typed,
    ),
  ];

  if (soc != null) {
    for (final (i, m) in matches.take(groups).indexed) {
      final ranked = [
        for (final e in soc.group(m.soc))
          // A title ONS lists only with a qualifier joins only when it
          // names the same kind of job.
          if (!e.qualified || _headKey(e.title) == roleHead) e,
      ];
      int score(SocEntry e) =>
          (_headKey(e.title) == roleHead ? 10 : 0) +
          titleKeys(e.title).intersection(roleKeys).length * 2 -
          (e.qualified ? 1 : 0);
      ranked.sort((a, b) {
        final c = score(b).compareTo(score(a));
        return c != 0 ? c : a.title.compareTo(b.title);
      });
      // A "not elsewhere classified" group gathers unlike jobs, so there a
      // title that shares no word with the role is only distant.
      final mixed = m.socTitle.contains('n.e.c.');
      for (final e in ranked.take(perGroup)) {
        final sameHead = _headKey(e.title) == roleHead;
        final shares = titleKeys(e.title).intersection(roleKeys).isNotEmpty;
        titles.add(
          FamilyTitle(
            title: titleCase(e.title),
            reason: 'Same SOC 2020 group ${m.soc} (${m.socTitle})',
            closeness: switch ((i == 0, sameHead)) {
              (true, true) => closeByHead(e.title, r) ? Closeness.close : Closeness.related,
              (true, false) => mixed && !shares ? Closeness.distant : Closeness.related,
              (false, true) => Closeness.related,
              (false, false) => Closeness.distant,
            },
            source: FamilySource.soc,
          ),
        );
      }
    }
  }

  for (final t in synonymTitles(r)) {
    titles.add(
      FamilyTitle(
        title: titleCase(t),
        reason: 'Synonym: ${t.split(' ').last} for $head',
        closeness: Closeness.related,
        source: FamilySource.synonym,
      ),
    );
  }

  return RoleFamily(role: r, titles: _dedupe(titles), matches: matches, synonymMatch: synonymMatch);
}

/// The skills ESCO lists for a role's occupation, for "search tasks and
/// tools" chips and gap analysis.
class RoleSkills {
  const RoleSkills({
    required this.role,
    required this.occupation,
    required this.essential,
    required this.optional,
  });

  /// The role as given, and the ESCO occupation the skills come from.
  final String role;
  final EscoOccupation occupation;

  /// Skill and knowledge labels ESCO marks essential or optional.
  final List<String> essential, optional;
}

/// Builds role families: the shipped data first, then ESCO (cached on the
/// device) for roles the shipped data knows.
class RoleFamilies {
  RoleFamilies(http.Client client, AppDatabase db, {this.index}) : esco = EscoLookup(client, db);

  final EscoLookup esco;

  /// The coding index to use; the loaded one when null.
  final SocIndex? index;

  /// ESCO occupations at most this many per role.
  static const escoOccupations = 2;

  Future<SocIndex> _index() async => index ?? await loadSocIndex();

  /// The ESCO occupations for [family] that agree with its SOC match: the
  /// ISCO-08 code of an ESCO search hit must be one the SOC index gives the
  /// role, or (for a synonym-only match) the hit's head noun must be a
  /// synonym of the role's. Empty for a role the shipped data does not
  /// know: ESCO is never asked about it. Lookups that fail are skipped.
  Future<List<EscoOccupation>> _escoFor(RoleFamily family, {bool offline = false}) async {
    if (!family.known) return const [];
    final List<EscoHit> hits;
    try {
      hits = await esco.hits(family.role, offline: offline, needUri: true);
    } on FeedException {
      return const [];
    }
    final iscos = {
      for (final m in family.matches)
        if (m.isco.isNotEmpty) m.isco,
    };
    final roleHead = _headKey(family.role);
    final kept = [
      for (final h in hits)
        if (h.uri.isNotEmpty && (iscos.isNotEmpty ? iscos.contains(h.isco) : _headKey(h.title) == roleHead))
          h,
    ];
    final out = <EscoOccupation>[];
    for (final h in kept.take(escoOccupations)) {
      try {
        final o = await esco.occupation(h.uri, offline: offline);
        if (o != null) out.add(o);
      } on FeedException {
        continue;
      }
    }
    return out;
  }

  /// The family of [role]: [offlineFamily], then ESCO's other titles and
  /// narrower occupations when the shipped data knew the role. With
  /// [offline], ESCO answers come from the device cache only.
  Future<RoleFamily> family(String role, {bool offline = false}) async {
    final base = offlineFamily(role, index: await _index());
    final occupations = await _escoFor(base, offline: offline);
    final roleHead = _headKey(base.role);
    final extra = <FamilyTitle>[];
    for (final o in occupations) {
      final labels = {
        for (final l in [o.title, ...o.altLabels]) _key(l): l,
      };
      for (final l in labels.values) {
        // Skip plurals of a label ESCO also gives ("ICT trainers").
        final k = _key(l);
        if (k.endsWith('s') && labels.containsKey(k.substring(0, k.length - 1))) continue;
        extra.add(
          FamilyTitle(
            title: titleCase(l),
            reason: l == o.title ? 'ESCO occupation' : 'ESCO alternative label of "${o.title}"',
            closeness: _headKey(l) == roleHead && closeByHead(l, base.role) ? Closeness.close : Closeness.related,
            source: FamilySource.esco,
          ),
        );
      }
      for (final n in o.narrower) {
        extra.add(
          FamilyTitle(
            title: titleCase(n),
            reason: 'ESCO narrower occupation of "${o.title}"',
            closeness: Closeness.related,
            source: FamilySource.esco,
          ),
        );
      }
    }
    return base.plus(extra);
  }

  /// The skills ESCO lists for [role]'s best agreeing occupation; null for
  /// a role the shipped data does not know, when offline and not cached, or
  /// when ESCO cannot be reached.
  Future<RoleSkills?> skills(String role, {bool offline = false}) async {
    final base = offlineFamily(role, index: await _index());
    final o = (await _escoFor(base, offline: offline)).firstOrNull;
    if (o == null) return null;
    return RoleSkills(
      role: base.role,
      occupation: o,
      essential: o.essentialSkills,
      optional: o.optionalSkills,
    );
  }
}

/// The JSON shape of AI title suggestions.
final aiFamilySchema = object({
  'titles': array(
    object({
      'title': string('A real UK job title used in adverts for the same work'),
      'reason': string('Why it is the same or nearby work, in under 12 words'),
    }),
    description: 'At most 8, most common first',
  ),
});

/// Asks [ai] for other titles [family]'s role is advertised under, and
/// returns them as "AI suggestion" titles (distant, so job search leaves
/// them off until switched on). Only call it when the person asks. Titles
/// already in the family are dropped.
Future<List<FamilyTitle>> aiFamilyTitles(Ai ai, RoleFamily family) async {
  final r = await ai.ask(
    system:
        'You know UK job adverts. Given a job title and the titles already found for it, list other real job '
        'titles employers use in UK adverts for the same or very close work. Only titles you are sure are used. '
        'No made-up titles, no seniority variants of one title, nothing already listed.',
    content: [
      {
        'type': 'text',
        'text':
            '<role>${family.role}</role>\n<known_titles>${family.titles.map((t) => t.title).join('; ')}</known_titles>',
      },
    ],
    schema: aiFamilySchema,
    effort: 'low',
    maxTokens: 2000,
  );
  final known = {for (final t in family.titles) _key(t.title)};
  return _dedupe([
    for (final t in objs(r.data['titles']).take(8))
      if (str(t['title']).trim().isNotEmpty && !known.contains(_key(str(t['title']))))
        FamilyTitle(
          title: str(t['title']).trim(),
          reason: 'AI suggestion${str(t['reason']).trim().isEmpty ? '' : ': ${str(t['reason']).trim()}'}',
          closeness: Closeness.distant,
          source: FamilySource.ai,
        ),
  ]);
}
