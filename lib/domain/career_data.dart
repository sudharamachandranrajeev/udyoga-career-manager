/// Optional keyed career data for role insights (role search plan U4):
/// the National Careers Service job profiles API and Skills England's
/// occupational maps API. Both are off until the person pastes their own
/// key in Settings. Keys stay in this device's keychain (SecretStore):
/// never synced, never in the repository, never in test fixtures.
///
/// Skills England (checked against its OpenAPI file, 2026-11-21):
/// https://occupational-maps-api.skillsengland.education.gov.uk/swagger/v1.0/swagger.json
/// The key goes in the X-API-KEY header. Used here: OccupationsBySOC,
/// SearchOccupations and OccupationalProgression/{stdCode}.
///
/// National Careers Service job profiles API, release 1 (11 May 2026), from
/// its OpenAPI file in the DfE API catalogue: GET /search/{searchTerm} and
/// GET /{canonicalName}, with the key in the Ocp-Apim-Subscription-Key
/// header. The catalogue lists only a development server and gives no
/// reply shape, so the production address below and the field names read
/// (those of the earlier public job profiles API) are not verified. The
/// reader is lenient: a field it cannot find is left out.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' show SecretStore;
import 'package:http/http.dart' as http;

import 'feeds.dart';
import 'job_identity.dart';
import 'json.dart';
import 'occupations.dart';
import 'role_family.dart';
import 'role_insight.dart';

/// Where the keys are kept: this device's keychain only.
abstract final class CareerDataSecrets {
  static const ncs = 'udyoga.ncs.key';
  static const skillsEngland = 'udyoga.skillsengland.key';
}

/// The person's own keys for the keyed career data. Empty: that source is off.
class CareerDataKeys {
  const CareerDataKeys({this.ncs = '', this.skillsEngland = ''});
  final String ncs, skillsEngland;

  bool get any => ncs.isNotEmpty || skillsEngland.isNotEmpty;

  /// The keys in [store]; none without one.
  static Future<CareerDataKeys> read(SecretStore? store) async {
    if (store == null) return const CareerDataKeys();
    return CareerDataKeys(
      ncs: (await store.read(CareerDataSecrets.ncs) ?? '').trim(),
      skillsEngland: (await store.read(CareerDataSecrets.skillsEngland) ?? '').trim(),
    );
  }

  /// Saves the keys to [store]; an empty one is removed (that source off).
  static Future<void> save(SecretStore store, {required String ncs, required String skillsEngland}) async {
    Future<void> put(String k, String v) => v.trim().isEmpty ? store.delete(k) : store.write(k, v.trim());
    await put(CareerDataSecrets.ncs, ncs);
    await put(CareerDataSecrets.skillsEngland, skillsEngland);
  }
}

/// The credit a data source asks for, with its link.
class DataCredit {
  const DataCredit({required this.name, required this.text, required this.url, this.licenceUrl = '', this.note = ''});
  final String name, text, url, licenceUrl, note;
}

const oglUrl = 'https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/';

const ncsCredit = DataCredit(
  name: 'National Careers Service',
  text:
      'Contains public sector information licensed under the Open Government Licence v3.0. Source: National '
      'Careers Service job profiles (Department for Education).',
  url: 'https://nationalcareers.service.gov.uk/explore-careers',
  licenceUrl: oglUrl,
  note: 'Only used with your own key. OGL v3.0 "except where otherwise stated".',
);

/// Skills England's attribution statement, as its API page words it.
const skillsEnglandCredit = DataCredit(
  name: 'Skills England',
  text: '© Skills England 2025. This information is licensed under the Open Government Licence.',
  url: 'https://occupational-maps.skillsengland.education.gov.uk/',
  licenceUrl: oglUrl,
  note:
      'Only used with your own key. Skills England also asks for its logo on products built on its data; '
      'Udyoga does not ship the logo, and shows this statement with a link instead.',
);

/// The ONS SOC coding index credit, as a [DataCredit].
final onsCredit = DataCredit(
  name: 'Office for National Statistics',
  text: onsSocCredit,
  url: socIndexSource.url,
  licenceUrl: oglUrl,
);

const escoDataCredit = DataCredit(
  name: 'ESCO',
  text: '$escoCredit Udyoga filters and combines ESCO labels with other data, so what it shows is a modified version.',
  url: 'https://esco.ec.europa.eu/',
);

const nhsCareersCredit = DataCredit(
  name: 'NHS Health Careers',
  text: 'NHS Health Careers content is © Crown copyright, all rights reserved. Udyoga links to it only and copies none of it.',
  url: 'https://www.healthcareers.nhs.uk/explore-roles',
);

const afcCredit = DataCredit(
  name: 'NHS Agenda for Change pay',
  text:
      'Pay points checked against NHS Employers pay scales 2026/27 and DoH NI circular HSC (AfC) 06/2025, '
      'built into Udyoga for bands 3 to 5. Check the official tables before relying on them.',
  url: afcPayPage,
);

/// What a keyed source says about a role.
class CareerData {
  const CareerData({
    required this.from,
    required this.credit,
    this.title = '',
    this.url = '',
    this.summary = '',
    this.waysIn = const [],
    this.pay = const [],
    this.progression = const [],
    this.stones = const [],
  });
  final InsightFrom from;
  final DataCredit credit;

  /// The source's own name for the role, and its page.
  final String title, url;
  final String summary;
  final List<WayIn> waysIn;
  final List<PayFigure> pay;
  final List<String> progression;
  final List<SteppingStone> stones;
}

/// A keyed career data source. Only built when its key is set, so with no
/// key it is never asked.
abstract interface class CareerDataSource {
  String get name;
  InsightFrom get from;

  /// What the source says about [role] ([soc]: its SOC 2020 matches), or
  /// null when it has nothing. Throws [FeedException] when it fails.
  Future<CareerData?> lookup(String role, {List<OccupationMatch> soc = const []});
}

/// The keyed sources [keys] switch on (none without keys).
List<CareerDataSource> careerDataSources(http.Client client, CareerDataKeys keys, {required String today}) => [
  if (keys.ncs.isNotEmpty) NcsJobProfiles(client, key: keys.ncs, today: today),
  if (keys.skillsEngland.isNotEmpty) SkillsEnglandMaps(client, key: keys.skillsEngland, today: today),
];

Future<Object?> _get(http.Client client, Uri uri, Map<String, String> headers, String who) async {
  final http.Response r;
  try {
    r = await client.get(uri, headers: {'accept': 'application/json', ...headers}).timeout(const Duration(seconds: 30));
  } on Exception catch (e) {
    throw FeedException('$who could not be reached ($e)');
  }
  if (r.statusCode == 401 || r.statusCode == 403) throw FeedException('$who rejected the key');
  if (r.statusCode == 404) return null;
  if (r.statusCode == 429) throw FeedException('$who asked Udyoga to slow down; try again later');
  if (r.statusCode != 200) throw FeedException('$who answered ${r.statusCode}');
  try {
    return jsonDecode(utf8.decode(r.bodyBytes));
  } on FormatException {
    throw FeedException('$who sent a reply that is not data');
  }
}

/// [j]'s value for [name], any letter case ("Title" or "title").
Object? _field(Object? j, String name) {
  if (j is! Map) return null;
  final k = name.toLowerCase();
  for (final e in j.entries) {
    if ('${e.key}'.toLowerCase() == k) return e.value;
  }
  return null;
}

/// Every string in [v] (a string, a list, or a map of them), HTML removed.
List<String> _texts(Object? v) => switch (v) {
  String s when s.trim().isNotEmpty => [htmlToText(s).trim()],
  List l => [for (final e in l) ..._texts(e)],
  Map m => [for (final e in m.values) ..._texts(e)],
  _ => const [],
};

String _money(Object? v) {
  final n = intOf(v);
  if (n != null && n > 0) {
    final s = n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '£$s a year';
  }
  return str(v);
}

/// The National Careers Service job profiles API (own key).
class NcsJobProfiles implements CareerDataSource {
  NcsJobProfiles(this.client, {required this.key, required this.today, this.base = defaultBase});
  final http.Client client;
  final String key, today;

  /// Not verified: the catalogue lists only a development server.
  static const defaultBase = 'https://api.nationalcareers.service.gov.uk/job-profiles';
  final String base;

  @override
  String get name => 'National Careers Service';
  @override
  InsightFrom get from => InsightFrom.ncs;

  Map<String, String> get _headers => {'Ocp-Apim-Subscription-Key': key};

  Uri _uri(String path) => Uri.parse('$base/${Uri.encodeComponent(path)}');

  /// The profile name in a search hit or profile: its canonical name, or
  /// the last part of its page address.
  static String canonical(Object? hit) {
    final c = str(_field(hit, 'canonicalName'));
    if (c.isNotEmpty) return c;
    final url = str(_field(hit, 'url'));
    final parts = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const [];
    return parts.isEmpty ? '' : parts.last;
  }

  @override
  Future<CareerData?> lookup(String role, {List<OccupationMatch> soc = const []}) async {
    final found = await _get(client, Uri.parse('$base/search/${Uri.encodeComponent(role)}'), _headers, name);
    final hits = found is List ? found : (_field(found, 'results') as List? ?? const []);
    if (hits.isEmpty) return null;
    final k = normalJobTitle(role);
    final best = hits.firstWhere((h) => normalJobTitle(str(_field(h, 'title'))) == k, orElse: () => hits.first);
    final profile = canonical(best);
    if (profile.isEmpty) return null;
    final p = await _get(client, _uri(profile), _headers, name);
    if (p == null) return null;
    return parseNcsProfile(p, today: today);
  }
}

/// A National Careers Service job profile as [CareerData]. Field names are
/// those of the earlier public job profiles API (not verified against
/// release 1); missing ones are skipped.
CareerData parseNcsProfile(Object? p, {required String today}) {
  const from = InsightFrom.ncs;
  final title = str(_field(p, 'title'));
  final url = str(_field(p, 'url'));
  final how = _field(p, 'howToBecome');
  final routes = _field(how, 'entryRoutes');
  const kinds = {
    'university': ('qualification', 'University'),
    'college': ('qualification', 'College'),
    'apprenticeship': ('apprenticeship', 'Apprenticeship'),
    'work': ('internal', 'Work your way up'),
    'volunteering': ('volunteering', 'Volunteering'),
    'directApplication': ('direct', 'Apply directly'),
    'otherRoutes': ('other', 'Other routes'),
  };
  final waysIn = <WayIn>[
    for (final e in kinds.entries)
      if (_texts(_field(routes, e.key)) case final t when t.isNotEmpty)
        WayIn(kind: e.value.$1, title: e.value.$2, detail: t.take(4).join(' '), url: url, from: from),
  ];
  final pay = [
    if (_money(_field(p, 'salaryStarter')) case final s when s.isNotEmpty)
      PayFigure(label: 'Starter', amount: s, source: 'National Careers Service', asOf: today, from: from),
    if (_money(_field(p, 'salaryExperienced')) case final s when s.isNotEmpty)
      PayFigure(label: 'Experienced', amount: s, source: 'National Careers Service', asOf: today, from: from),
  ];
  return CareerData(
    from: from,
    credit: ncsCredit,
    title: title,
    url: url,
    summary: _texts(_field(p, 'overview')).join(' '),
    waysIn: waysIn,
    pay: pay,
    progression: _texts(_field(p, 'careerPathAndProgression')).take(4).toList(),
  );
}

/// Skills England's occupational maps API (own key).
class SkillsEnglandMaps implements CareerDataSource {
  SkillsEnglandMaps(this.client, {required this.key, required this.today, this.base = defaultBase});
  final http.Client client;
  final String key, today;

  static const defaultBase = 'https://occupational-maps-api.skillsengland.education.gov.uk/api/v1';
  final String base;

  static const expand = 'occupation.summary,occupation.typicaljobtitles,occupation.products,occupation.salary';

  @override
  String get name => 'Skills England';
  @override
  InsightFrom get from => InsightFrom.skillsEngland;

  Map<String, String> get _headers => {'X-API-KEY': key};

  Future<Object?> _ask(String path, Map<String, String> query) =>
      _get(client, Uri.parse('$base/$path').replace(queryParameters: query), _headers, name);

  @override
  Future<CareerData?> lookup(String role, {List<OccupationMatch> soc = const []}) async {
    final codes = [
      for (final m in soc)
        if (RegExp(r'^\d{4}$').hasMatch(m.soc)) m.soc,
    ];
    final occupations = <Json>[];
    for (final c in codes.take(2)) {
      final r = await _ask('OccupationsBySOC', {'SOCCode': c, 'SOCVersion': '2020', 'expand': expand});
      occupations.addAll(objs(r));
    }
    if (occupations.isEmpty) {
      final r = await _ask('SearchOccupations', {'searchTerm': role, 'pageSize': '5', 'expand': expand});
      occupations.addAll(objs(obj(r)['results']));
    }
    if (occupations.isEmpty) return null;
    final best = bestOccupation(role, occupations);
    final code = str(best['stdCode']);
    Object? progression;
    if (code.isNotEmpty) {
      progression = await _ask('OccupationalProgression/$code', {'expand': 'occupation.typicaljobtitles'});
    }
    return parseSkillsEngland(best, progression, today: today);
  }

  /// The occupation in [all] whose name or a typical job title is [role],
  /// else the first.
  static Json bestOccupation(String role, List<Json> all) {
    final k = normalJobTitle(role);
    bool named(Json o) =>
        normalJobTitle(str(o['name'])) == k ||
        objs(o['typicalJobTitles']).any((t) => normalJobTitle(str(t['name'])) == k);
    return all.where(named).firstOrNull ?? all.first;
  }
}

/// A Skills England occupation (and its progression map, when given) as
/// [CareerData]: its apprenticeships and qualifications as ways in, the
/// median salary, the occupations that lead into it as stepping stones and
/// those it leads to as progression.
CareerData parseSkillsEngland(Json occupation, Object? progression, {required String today}) {
  const from = InsightFrom.skillsEngland;
  final code = str(occupation['stdCode']);
  final name = str(occupation['name']);
  final waysIn = [
    for (final p in objs(occupation['products']))
      if (str(p['name']).isNotEmpty)
        WayIn(
          kind: str(p['typeName']).toLowerCase().contains('apprentic') ? 'apprenticeship' : 'qualification',
          title: [str(p['name']), if ((intOf(p['level']) ?? 0) > 0) '(level ${intOf(p['level'])})'].join(' '),
          detail: str(p['typeName']),
          from: from,
        ),
  ];
  final median = intOf(occupation['medianAnnualSalaryinGBP']);
  final map = obj(progression);
  final byCode = {for (final o in objs(map['occupations'])) str(o['stdCode']): o};
  final links = [
    for (final p in objs(map['progressions'])) (from: str(p['stdCodeFrom']), to: str(p['stdCodeTo'])),
  ];
  List<FamilyTitle> titles(Json o) => [
    for (final t in objs(o['typicalJobTitles']).take(4))
      if (str(t['name']).isNotEmpty)
        FamilyTitle(
          title: titleCase(str(t['name'])),
          reason: 'Skills England typical job title',
          closeness: Closeness.close,
          source: FamilySource.soc,
        ),
  ];
  final stones = [
    for (final l in links)
      if (l.to == code && l.from != code && byCode[l.from] != null)
        SteppingStone(
          role: str(byCode[l.from]!['name']),
          why: 'Skills England maps a progression from it to $name.',
          titles: titles(byCode[l.from]!),
          from: from,
        ),
  ];
  final next = [
    for (final l in links)
      if (l.from == code && l.to != code && byCode[l.to] != null) str(byCode[l.to]!['name']),
  ];
  return CareerData(
    from: from,
    credit: skillsEnglandCredit,
    title: name,
    url: code.isEmpty ? '' : 'https://occupational-maps.skillsengland.education.gov.uk/',
    summary: str(occupation['summary']),
    waysIn: waysIn,
    pay: [
      if (median != null && median > 0)
        PayFigure(label: 'Median', amount: _money(median), source: 'Skills England occupational maps', asOf: today, from: from),
    ],
    progression: [if (next.isNotEmpty) 'Skills England maps progression on to: ${next.take(4).join(', ')}.'],
    stones: stones.take(3).toList(),
  );
}
