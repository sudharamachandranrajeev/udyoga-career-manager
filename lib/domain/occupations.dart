/// Job titles to occupation codes: UK SOC 2020 from the full ONS coding
/// index (shipped as a compressed asset, loaded once on first use), and
/// ISCO-08 from the ESCO API (no key; answers cached on the device). The
/// codes pick a route's rules and its pay threshold, and group job titles
/// into role families (lib/domain/role_family.dart).
library;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'feeds.dart';
import 'json.dart';
import 'routes.dart';
import 'title_synonyms.dart';

/// The ONS page the SOC coding index came from.
const socIndexSource = RouteSource(
  'ONS SOC 2020 Volume 2: the coding index, version 14 (file of 27 Aug 2026, v4; Open Government Licence)',
  'https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2020/soc2020volume2codingrulesandconventions',
  asOf: '2026-11-21',
);

/// The credit the Data sources screen shows for the SOC coding index.
const onsSocCredit =
    'Contains public sector information licensed under the Open Government Licence v3.0. '
    'Source: Office for National Statistics, SOC 2020 Volume 2: the coding index (version 14).';

/// The credit ESCO asks every reuser to show. Udyoga filters and combines
/// ESCO labels with other data, so what it shows is a modified version.
const escoCredit = 'This service uses the ESCO classification of the European Commission.';

/// The ESCO page the credit links to.
const escoSource = RouteSource(
  'ESCO: European Skills, Competences, Qualifications and Occupations (European Commission)',
  'https://esco.ec.europa.eu/en/about-esco/data-science-and-esco/esco-api',
  asOf: '2026-11-21',
);

const escoSearchApi = 'https://ec.europa.eu/esco/api/search';
const escoOccupationApi = 'https://ec.europa.eu/esco/api/resource/occupation';

/// The shipped coding index, made by tool/gen_soc_index.dart.
const socIndexAsset = 'assets/soc/soc2020_index.tsv.gz';

/// One title in the SOC coding index.
class SocEntry {
  const SocEntry(this.title, this.soc, this.isco, {this.qualified = false});

  /// The job title in lower case, as ONS writes it ("clinical systems trainer").
  final String title;

  /// SOC 2020 unit group (4 digits) and the ISCO-08 code ONS gives it.
  final String soc, isco;

  /// ONS lists this title only with a qualifier or an industry
  /// ("manager (hospital)"), so it is not a full match on its own.
  final bool qualified;

  /// The last word, which names the job ("trainer").
  String get head => title.split(' ').last;
}

/// The ONS SOC 2020 coding index: every job title ONS codes, with its unit
/// group, plus the unit group titles.
class SocIndex {
  SocIndex(this.entries, this.unitTitles) {
    for (final e in entries) {
      (_byTitle[e.title] ??= []).add(e);
      (_bySoc[e.soc] ??= []).add(e);
      (_byHead[_norm(e.title).split(' ').last] ??= []).add(e);
    }
  }

  /// Reads the asset text (see tool/gen_soc_index.dart for the format).
  factory SocIndex.parse(String tsv) {
    final entries = <SocEntry>[];
    final units = <String, String>{};
    for (final line in const LineSplitter().convert(tsv)) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final f = line.split('\t');
      if (f.first == 'U' && f.length >= 3) {
        units[f[1]] = f[2];
      } else if (f.first == 'T' && f.length >= 4) {
        entries.add(SocEntry(f[1], f[2], f[3], qualified: f.length > 4 && f[4] == 'q'));
      }
    }
    return SocIndex(entries, units);
  }

  /// Reads the gzip-compressed asset bytes.
  factory SocIndex.fromGzip(List<int> bytes) => SocIndex.parse(utf8.decode(GZipDecoder().decodeBytes(bytes)));

  final List<SocEntry> entries;
  final Map<String, String> unitTitles;
  final _byTitle = <String, List<SocEntry>>{};
  final _bySoc = <String, List<SocEntry>>{};
  final _byHead = <String, List<SocEntry>>{};

  /// The title of a SOC 2020 unit group, or ''.
  String unitTitle(String soc) => unitTitles[soc] ?? '';

  /// Every title in unit group [soc], plain titles first.
  List<SocEntry> group(String soc) => [
    ...?_bySoc[soc]?.where((e) => !e.qualified),
    ...?_bySoc[soc]?.where((e) => e.qualified),
  ];

  /// The index entries for [title] word for word (any case).
  List<SocEntry> exact(String title) => _byTitle[_norm(title)] ?? const [];

  /// The SOC 2020 codes the index gives [title], best first: an exact
  /// title (plain titles before ones ONS lists only with a qualifier), else
  /// the index titles sharing most of its words (at least half of each
  /// side's words, and more than the head noun alone). The head noun (last
  /// word) must match, or be a synonym from lib/domain/title_synonyms.dart,
  /// so "digital training facilitator" finds IT trainers. Empty when
  /// nothing is close.
  List<OccupationMatch> matches(String title, {int limit = 3}) {
    final t = _norm(title);
    if (t.isEmpty) return const [];
    final exact = _byTitle[t] ?? const [];
    if (exact.isNotEmpty) {
      final best = exact.any((e) => !e.qualified) ? exact.where((e) => !e.qualified) : exact;
      return [
        for (final e in {for (final e in best) e.soc: e}.values)
          OccupationMatch(title: title, soc: e.soc, socTitle: unitTitle(e.soc), isco: e.isco, exact: true),
      ];
    }
    final head = t.split(' ').last;
    final keys = titleKeys(t);
    if (keys.isEmpty) return const [];
    final scored = <(double, SocEntry)>[];
    for (final h in headSynonyms(head)) {
      for (final e in _byHead[h] ?? const <SocEntry>[]) {
        final k = titleKeys(e.title);
        final common = k.intersection(keys).length;
        // Sharing only the head noun is not enough ("dog trainer" is no
        // match for "IT trainer"), unless the index title is the bare head.
        if (common == 0 || (common < 2 && k.length > 1)) continue;
        final a = common / keys.length, b = common / k.length;
        if (a < 0.5 || b < 0.5) continue;
        // The same head noun beats a synonym a little.
        scored.add((a + b + (h == head ? 0.1 : 0), e));
      }
    }
    // A title ONS lists only with a qualifier counts only when no plain
    // title matches.
    if (scored.any((s) => !s.$2.qualified)) scored.removeWhere((s) => s.$2.qualified);
    scored.sort((x, y) {
      final c = y.$1.compareTo(x.$1);
      return c != 0 ? c : x.$2.title.compareTo(y.$2.title);
    });
    final out = <String, OccupationMatch>{};
    for (final (_, e) in scored) {
      out.putIfAbsent(
        e.soc,
        () => OccupationMatch(title: title, soc: e.soc, socTitle: unitTitle(e.soc), isco: e.isco),
      );
      if (out.length >= limit) break;
    }
    return out.values.toList();
  }
}

SocIndex? _socIndex;
Future<SocIndex>? _socLoading;

/// The coding index once loaded, or null before [loadSocIndex] finishes.
SocIndex? get loadedSocIndex => _socIndex;

/// Loads the shipped coding index once (later calls get the same one).
/// Call it before the synchronous lookups ([socMatches], [socTitle]),
/// which find nothing until it is loaded. [bundle] is for tests.
Future<SocIndex> loadSocIndex({AssetBundle? bundle}) {
  final have = _socIndex;
  if (have != null) return Future.value(have);
  return _socLoading ??= () async {
    try {
      final data = await (bundle ?? rootBundle).load(socIndexAsset);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final index = await compute(SocIndex.fromGzip, bytes);
      _socIndex = index;
      return index;
    } catch (_) {
      _socLoading = null;
      rethrow;
    }
  }();
}

/// Uses [index] as the loaded coding index (tests and tools), or forgets
/// it with null.
void useSocIndex(SocIndex? index) {
  _socIndex = index;
  _socLoading = null;
}

/// The title of a SOC 2020 unit group, or '' (also before the index loads).
String socTitle(String soc) => _socIndex?.unitTitle(soc) ?? '';

/// One way a job title is coded.
class OccupationMatch {
  const OccupationMatch({
    required this.title,
    this.soc = '',
    this.socTitle = '',
    this.isco = '',
    this.iscoTitle = '',
    this.exact = false,
    this.from = 'ons',
  });

  /// The person's job title, as given.
  final String title;

  /// SOC 2020 unit group and its title; '' when not coded.
  final String soc, socTitle;

  /// ISCO-08 unit group (4 digits) and its title; '' when not coded.
  final String isco, iscoTitle;

  /// The title is in the coding index word for word.
  final bool exact;

  /// 'ons' (shipped index) or 'esco' (looked up).
  final String from;

  Json toJson() => {
    'title': title,
    'soc': soc,
    'socTitle': socTitle,
    'isco': isco,
    'iscoTitle': iscoTitle,
    'exact': exact,
    'from': from,
  };

  factory OccupationMatch.fromJson(Json j) => OccupationMatch(
    title: str(j['title']),
    soc: str(j['soc']),
    socTitle: str(j['socTitle']),
    isco: str(j['isco']),
    iscoTitle: str(j['iscoTitle']),
    exact: j['exact'] == true,
    from: str(j['from']).isEmpty ? 'ons' : str(j['from']),
  );

  OccupationMatch withIsco(String code, String name) => OccupationMatch(
    title: title,
    soc: soc,
    socTitle: socTitle,
    isco: isco.isNotEmpty ? isco : code,
    iscoTitle: iscoTitle.isNotEmpty ? iscoTitle : name,
    exact: exact,
    from: from,
  );
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll('&', ' and ')
    .replaceAll(RegExp(r'\([^)]*\)'), ' ')
    .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// [s] in lower case with punctuation and brackets dropped, for comparing
/// job titles.
String normTitle(String s) => _norm(s);

/// Words that say nothing about the job itself.
const _stop = {
  'and',
  'of',
  'the',
  'in',
  'for',
  'a',
  'senior',
  'junior',
  'lead',
  'principal',
  'trainee',
  'assistant',
};

/// The comparison keys of a job title's words (see [wordKey]): stems, with
/// head-noun synonyms sharing one key. Grade words like "senior" are left
/// out, but the head noun always counts.
Set<String> titleKeys(String title) {
  final words = _norm(title).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const {};
  final head = words.last;
  return {
    for (final w in words)
      if (!_stop.contains(w) || w == head) wordKey(w, head),
  };
}

/// The SOC 2020 codes the shipped coding index gives [title], best first
/// (see [SocIndex.matches]). Empty before [loadSocIndex] finishes.
List<OccupationMatch> socMatches(String title, {int limit = 3}) =>
    _socIndex?.matches(title, limit: limit) ?? const [];

/// The job titles worth coding for a person: the target roles, then the
/// current role and recent job titles, without repeats.
List<String> titlesToCode({
  required List<String> targets,
  String current = '',
  List<String> past = const [],
}) {
  final seen = <String>{};
  return [
    for (final t in [...targets, current, ...past.take(3)])
      if (t.trim().isNotEmpty && seen.add(_norm(t))) t.trim(),
  ];
}

/// One ESCO occupation search result.
class EscoHit {
  const EscoHit(this.title, this.isco, {this.uri = ''});

  /// The ESCO preferred title, its ISCO-08 4-digit code, and its concept
  /// URI ('' in answers cached before Udyoga kept it).
  final String title, isco, uri;

  Json toJson() => {'title': title, 'isco': isco, if (uri.isNotEmpty) 'uri': uri};

  factory EscoHit.fromJson(Json j) => EscoHit(str(j['title']), str(j['isco']), uri: str(j['uri']));
}

/// ESCO occupation search results, best first.
List<EscoHit> parseEscoHits(String body) {
  final Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  final out = <EscoHit>[];
  for (final r in objs(obj(obj(j)['_embedded'])['results'])) {
    final code = str(r['code']);
    var isco = RegExp(r'^\d{4}').firstMatch(code)?[0] ?? '';
    if (isco.isEmpty) {
      final broader = objs(obj(r['_links'])['broaderIscoGroup']).map((b) => str(b['href'])).firstOrNull ?? '';
      isco = RegExp(r'C(\d{4})$').firstMatch(broader)?[1] ?? '';
    }
    final title = str(r['title']).isNotEmpty ? str(r['title']) : str(r['preferredLabel']);
    if (isco.isNotEmpty && title.isNotEmpty) out.add(EscoHit(title, isco, uri: str(r['uri'])));
  }
  return out;
}

/// ESCO occupation search results: (ESCO title, ISCO-08 4-digit code).
List<(String, String)> parseEscoSearch(String body) => [
  for (final h in parseEscoHits(body)) (h.title, h.isco),
];

/// What ESCO says about one occupation: other titles it goes by, narrower
/// occupations, and the skills it needs. Only labels are kept, never the
/// descriptions.
class EscoOccupation {
  const EscoOccupation({
    required this.uri,
    required this.title,
    this.isco = '',
    this.altLabels = const [],
    this.narrower = const [],
    this.essentialSkills = const [],
    this.optionalSkills = const [],
  });

  final String uri, title, isco;

  /// Other titles for the same occupation ("IT trainer" for "ICT trainer").
  final List<String> altLabels;

  /// Titles of more specialised occupations under this one.
  final List<String> narrower;

  /// Skill and knowledge labels ESCO marks essential or optional.
  final List<String> essentialSkills, optionalSkills;

  Json toJson() => {
    'uri': uri,
    'title': title,
    'isco': isco,
    'alt': altLabels,
    'narrower': narrower,
    'essential': essentialSkills,
    'optional': optionalSkills,
  };

  factory EscoOccupation.fromJson(Json j) => EscoOccupation(
    uri: str(j['uri']),
    title: str(j['title']),
    isco: str(j['isco']),
    altLabels: strs(j['alt']),
    narrower: strs(j['narrower']),
    essentialSkills: strs(j['essential']),
    optionalSkills: strs(j['optional']),
  );
}

/// An ESCO occupation resource (English labels), or null when [body] is
/// not one.
EscoOccupation? parseEscoOccupation(String body) {
  final Object? raw;
  try {
    raw = jsonDecode(body);
  } on FormatException {
    return null;
  }
  final j = obj(raw);
  final links = obj(j['_links']);
  final title = str(obj(j['preferredLabel'])['en']).isNotEmpty
      ? str(obj(j['preferredLabel'])['en'])
      : str(j['title']);
  if (title.isEmpty) return null;
  List<String> titles(String key) => [
    for (final l in objs(links[key]))
      if (str(l['title']).isNotEmpty) str(l['title']),
  ];
  final isco =
      RegExp(r'^\d{4}').firstMatch(str(j['code']))?[0] ??
      objs(links['broaderIscoGroup']).map((b) => str(b['code'])).firstOrNull ??
      '';
  return EscoOccupation(
    uri: str(j['uri']),
    title: title,
    isco: isco,
    altLabels: strs(obj(j['alternativeLabel'])['en']),
    narrower: titles('narrowerOccupation'),
    essentialSkills: titles('hasEssentialSkill'),
    optionalSkills: titles('hasOptionalSkill'),
  );
}

/// Looks titles up in ESCO, keeping each answer on this device so a title
/// is asked once.
class EscoLookup {
  EscoLookup(this.client, this.db);
  final http.Client client;
  final AppDatabase db;

  static const cacheKey = 'udyoga.esco.cache';

  /// Occupation details by concept URI.
  static const occupationCacheKey = 'udyoga.esco.occupations';

  Future<Map<String, Object?>> _cache([String key = cacheKey]) async =>
      decodeObject(await db.localSetting(key) ?? '');

  Future<String> _get(Uri uri) async {
    final http.Response r;
    try {
      r = await client.get(uri, headers: {'Accept': 'application/json'});
    } on Exception catch (e) {
      throw FeedException('ESCO could not be reached ($e)');
    }
    if (r.statusCode != 200) throw FeedException('ESCO answered ${r.statusCode}');
    return utf8.decode(r.bodyBytes);
  }

  /// The ESCO occupations a search for [title] gives, best first; cached,
  /// so it works offline once asked. With [offline], only the cache is
  /// read. With [needUri], an answer cached without concept URIs (by an
  /// older Udyoga) is asked again. Throws FeedException when ESCO cannot be
  /// reached and nothing is cached.
  Future<List<EscoHit>> hits(String title, {bool offline = false, bool needUri = false}) async {
    final key = _norm(title);
    if (key.isEmpty) return const [];
    final cache = await _cache();
    if (cache[key] is List) {
      final had = [for (final e in objs(cache[key])) EscoHit.fromJson(e)];
      if (offline || !needUri || had.isEmpty || had.every((h) => h.uri.isNotEmpty)) return had;
    }
    if (offline) return const [];
    final uri = Uri.parse(escoSearchApi)
        .replace(queryParameters: {'text': title, 'type': 'occupation', 'language': 'en', 'limit': '5'});
    final found = parseEscoHits(await _get(uri));
    final next = {
      ...await _cache(),
      key: [for (final h in found) h.toJson()],
    };
    await db.setLocalSetting(cacheKey, jsonEncode(next));
    return found;
  }

  /// The ISCO-08 codes ESCO gives [title], best first; cached, so it works
  /// offline once asked. With [offline], only the cache is read. Throws
  /// FeedException when ESCO cannot be reached and nothing is cached.
  Future<List<(String, String)>> isco(String title, {bool offline = false}) async => [
    for (final h in await hits(title, offline: offline)) (h.title, h.isco),
  ];

  /// The ESCO occupation at concept [uri]: other titles, narrower
  /// occupations and skills; cached on the device. Null when [offline] and
  /// not cached. Throws FeedException when ESCO cannot be reached.
  Future<EscoOccupation?> occupation(String uri, {bool offline = false}) async {
    if (uri.isEmpty) return null;
    final cache = await _cache(occupationCacheKey);
    if (cache[uri] is Map) return EscoOccupation.fromJson(obj(cache[uri]));
    if (offline) return null;
    final found = parseEscoOccupation(
      await _get(Uri.parse(escoOccupationApi).replace(queryParameters: {'uri': uri, 'language': 'en'})),
    );
    if (found == null) return null;
    final next = {...await _cache(occupationCacheKey), uri: found.toJson()};
    await db.setLocalSetting(occupationCacheKey, jsonEncode(next));
    return found;
  }

  /// [matches] with an ISCO code filled from ESCO where the index gave
  /// none; a title the index does not know gets an ESCO-only match.
  /// Lookups that fail are skipped.
  Future<List<OccupationMatch>> complete(
    List<String> titles,
    List<OccupationMatch> matches, {
    bool offline = false,
  }) async {
    final out = <OccupationMatch>[];
    for (final t in titles) {
      final mine = matches.where((m) => m.title == t).toList();
      if (mine.isNotEmpty && mine.every((m) => m.isco.isNotEmpty)) {
        out.addAll(mine);
        continue;
      }
      List<(String, String)> esco;
      try {
        esco = await isco(t, offline: offline);
      } on FeedException {
        esco = const [];
      }
      if (mine.isEmpty) {
        if (esco.isNotEmpty) {
          out.add(OccupationMatch(title: t, isco: esco.first.$2, iscoTitle: esco.first.$1, from: 'esco'));
        }
      } else {
        out.addAll([for (final m in mine) esco.isEmpty ? m : m.withIsco(esco.first.$2, esco.first.$1)]);
      }
    }
    return out;
  }
}

/// The shipped SOC matches for each of [titles].
List<OccupationMatch> codeTitles(List<String> titles) => [for (final t in titles) ...socMatches(t)];

/// What one UK code means for pay: the going rate for the general route
/// and for new entrants, or why it does not qualify.
class UkThreshold {
  const UkThreshold({required this.occupation, required this.floor, required this.newEntrantFloor});
  final UkOccupation occupation;

  /// The higher of the general threshold and the going rate; null when the
  /// code is not eligible for new applicants.
  final int? floor, newEntrantFloor;
}

/// The Skilled Worker pay floor for [soc] under [uk], or null when Udyoga
/// has no rates for that code.
UkThreshold? ukThreshold(String soc, UkRules uk) {
  final o = uk.occupations[soc];
  if (o == null) return null;
  if (o.table == '6') return UkThreshold(occupation: o, floor: null, newEntrantFloor: null);
  final g = o.goingRate ?? 0, ne = o.newEntrantRate ?? 0;
  return UkThreshold(
    occupation: o,
    floor: g > uk.generalFloor ? g : uk.generalFloor,
    newEntrantFloor: ne > uk.newEntrantFloor ? ne : uk.newEntrantFloor,
  );
}
