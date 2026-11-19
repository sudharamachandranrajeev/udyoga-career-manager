/// Job titles to occupation codes: UK SOC 2020 from the shipped ONS coding
/// index subset, and ISCO-08 from the ESCO API (no key; answers cached on
/// the device). The codes pick a route's rules and its pay threshold.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'feeds.dart';
import 'json.dart';
import 'routes.dart';

part 'soc_index_data.dart';

/// The ONS page the SOC subset came from.
const socIndexSource = RouteSource(
  'ONS SOC 2020 Volume 2: the coding index (27 Aug 2026, Open Government Licence)',
  'https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2020/soc2020volume2codingrulesandconventions',
  asOf: routesAsOf,
);

const escoSearchApi = 'https://ec.europa.eu/esco/api/search';

/// The title of a SOC 2020 unit group Udyoga ships, or ''.
String socTitle(String soc) => _socTitles[soc] ?? '';

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

const _stop = {'and', 'of', 'the', 'in', 'for', 'a', 'senior', 'junior', 'lead', 'principal', 'trainee', 'assistant'};

Set<String> _words(String s) => _norm(s).split(' ').where((w) => w.isNotEmpty && !_stop.contains(w)).toSet();

/// The SOC 2020 codes the shipped coding index gives [title], best first:
/// an exact title, else the index titles sharing most of its words (at
/// least half of each side's words). Empty when nothing is close; the
/// index covers health administration, EPR and IT work only.
List<OccupationMatch> socMatches(String title, {int limit = 3}) {
  final t = _norm(title);
  if (t.isEmpty) return const [];
  final exact = _socIndex.where((e) => e.$1 == t).toList();
  if (exact.isNotEmpty) {
    return [
      for (final e in {for (final e in exact) e.$2: e}.values)
        OccupationMatch(title: title, soc: e.$2, socTitle: socTitle(e.$2), isco: e.$3, exact: true),
    ];
  }
  final words = _words(t);
  if (words.isEmpty) return const [];
  // The last word names the job ("nurse" in "staff nurse"); it must match.
  final head = _norm(t).split(' ').last;
  final scored = <(double, (String, String, String))>[];
  for (final e in _socIndex) {
    final w = _words(e.$1);
    if (w.isEmpty) continue;
    final common = w.intersection(words).length;
    if (common == 0 || !w.contains(head)) continue;
    final a = common / words.length, b = common / w.length;
    if (a < 0.5 || b < 0.5) continue;
    scored.add((a + b, e));
  }
  scored.sort((x, y) => y.$1.compareTo(x.$1));
  final out = <String, OccupationMatch>{};
  for (final (_, e) in scored) {
    out.putIfAbsent(e.$2, () => OccupationMatch(title: title, soc: e.$2, socTitle: socTitle(e.$2), isco: e.$3));
    if (out.length >= limit) break;
  }
  return out.values.toList();
}

/// The job titles worth coding for a person: the target roles, then the
/// current role and recent job titles, without repeats.
List<String> titlesToCode({required List<String> targets, String current = '', List<String> past = const []}) {
  final seen = <String>{};
  return [
    for (final t in [...targets, current, ...past.take(3)])
      if (t.trim().isNotEmpty && seen.add(_norm(t))) t.trim(),
  ];
}

/// ESCO occupation search results: (ESCO title, ISCO-08 4-digit code).
List<(String, String)> parseEscoSearch(String body) {
  final Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  final out = <(String, String)>[];
  for (final r in objs(obj(obj(j)['_embedded'])['results'])) {
    final code = str(r['code']);
    var isco = RegExp(r'^\d{4}').firstMatch(code)?[0] ?? '';
    if (isco.isEmpty) {
      final broader = objs(obj(r['_links'])['broaderIscoGroup']).map((b) => str(b['href'])).firstOrNull ?? '';
      isco = RegExp(r'C(\d{4})$').firstMatch(broader)?[1] ?? '';
    }
    final title = str(r['title']).isNotEmpty ? str(r['title']) : str(r['preferredLabel']);
    if (isco.isNotEmpty && title.isNotEmpty) out.add((title, isco));
  }
  return out;
}

/// Looks titles up in ESCO, keeping each answer on this device so a title
/// is asked once.
class EscoLookup {
  EscoLookup(this.client, this.db);
  final http.Client client;
  final AppDatabase db;

  static const cacheKey = 'udyoga.esco.cache';

  Future<Map<String, Object?>> _cache() async => decodeObject(await db.localSetting(cacheKey) ?? '');

  /// The ISCO-08 codes ESCO gives [title], best first; cached, so it works
  /// offline once asked. Throws FeedException when ESCO cannot be reached
  /// and nothing is cached.
  Future<List<(String, String)>> isco(String title) async {
    final key = _norm(title);
    if (key.isEmpty) return const [];
    final cache = await _cache();
    if (cache[key] is List) {
      return [for (final e in objs(cache[key])) (str(e['title']), str(e['isco']))];
    }
    final uri = Uri.parse(escoSearchApi)
        .replace(queryParameters: {'text': title, 'type': 'occupation', 'language': 'en', 'limit': '5'});
    final http.Response r;
    try {
      r = await client.get(uri, headers: {'Accept': 'application/json'});
    } on Exception catch (e) {
      throw FeedException('ESCO could not be reached ($e)');
    }
    if (r.statusCode != 200) throw FeedException('ESCO answered ${r.statusCode}');
    final found = parseEscoSearch(utf8.decode(r.bodyBytes));
    final next = {
      ...cache,
      key: [
        for (final (t, c) in found) {'title': t, 'isco': c},
      ],
    };
    await db.setLocalSetting(cacheKey, jsonEncode(next));
    return found;
  }

  /// [matches] with an ISCO code filled from ESCO where the index gave
  /// none; a title the index does not know gets an ESCO-only match.
  /// Lookups that fail are skipped.
  Future<List<OccupationMatch>> complete(List<String> titles, List<OccupationMatch> matches) async {
    final out = <OccupationMatch>[];
    for (final t in titles) {
      final mine = matches.where((m) => m.title == t).toList();
      if (mine.isNotEmpty && mine.every((m) => m.isco.isNotEmpty)) {
        out.addAll(mine);
        continue;
      }
      List<(String, String)> esco;
      try {
        esco = await isco(t);
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
