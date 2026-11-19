import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ats.dart';
import 'employers.dart';
import 'feeds.dart';
import 'json.dart';
import 'profile.dart';
import 'work_rights.dart';

/// An employer worth watching, from a public list.
class EmployerSuggestion {
  const EmployerSuggestion({
    required this.name,
    required this.source,
    this.place = '',
    this.website = '',
    this.nhs = false,
  });
  final String name, source, place, website;

  /// An NHS trust, whose jobs are on NHS Jobs.
  final bool nhs;

  /// As a watched employer.
  WatchedEmployer toWatched() => WatchedEmployer(
    id: employerId(name),
    name: name,
    why: 'Suggested from $source',
    sources: [if (nhs) 'nhs', if (website.isNotEmpty) website],
  );
}

/// Where the customer lists come from. Each is fetched when the user asks
/// and never shipped with Udyoga: Epic's terms let its materials be shared
/// only by linking, and Oracle's list carries no licence.
abstract final class CustomerLists {
  static const epic = 'https://open.epic.com/Endpoints/R4';
  static const epicTerms = 'https://open.epic.com/Home/TermsOfUse';
  static const oracle =
      'https://raw.githubusercontent.com/oracle-samples/ignite-endpoints/main/oracle_health_fhir_endpoints/'
      'millennium_patient_r4_endpoints.json';
  static const oracleHome = 'https://github.com/oracle-samples/ignite-endpoints';
}

/// Finds employers near the candidate's home areas: NHS trusts (NHS ODS),
/// hospitals (Wikidata), and the organisations on the Epic and Oracle
/// Health record systems.
class EmployerDiscovery {
  EmployerDiscovery(this.client);
  final http.Client client;

  Future<Object?> _json(Uri uri, {Map<String, String> headers = const {}, int seconds = 60}) async {
    final r = await client
        .get(uri, headers: {'accept': 'application/json', 'user-agent': politeAgent, ...headers})
        .timeout(Duration(seconds: seconds));
    if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      throw FeedException('sent a reply that could not be read');
    }
  }

  /// Active NHS trusts whose name says one of [towns] (all of them when
  /// [towns] is empty).
  Future<List<EmployerSuggestion>> nhsTrusts(List<String> towns) async => parseOds(
    obj(
      await _json(
        Uri.https('directory.spineservices.nhs.uk', '/ORD/2-0-0/organisations', {
          'PrimaryRoleId': 'RO197',
          'Status': 'Active',
          'Limit': '1000',
        }),
      ),
    ),
    towns: towns,
  );

  static List<EmployerSuggestion> parseOds(Json body, {List<String> towns = const []}) {
    final all = [
      for (final o in objs(body['Organisations']))
        if (str(o['Name']).isNotEmpty)
          EmployerSuggestion(
            name: titleCase(str(o['Name'])),
            source: 'NHS ODS',
            place: str(o['PostCode']),
            nhs: true,
          ),
    ];
    if (towns.isEmpty) return all;
    return [
      for (final s in all)
        if (towns.any((t) => normaliseEmployer(' ${s.name} ').contains(normaliseEmployer(t)))) s,
    ];
  }

  /// Hospitals with a website within each area's radius (20 miles when
  /// unset), from Wikidata (CC0).
  Future<List<EmployerSuggestion>> hospitalsNear(List<HomeArea> areas, {required String homeCountry}) async {
    final out = <EmployerSuggestion>[];
    for (final a in areas) {
      final cc = a.country.isEmpty ? homeCountry : a.country;
      if (cc.isEmpty) continue;
      final body = await _json(
        Uri.https('query.wikidata.org', '/sparql', {
          'query': hospitalQuery(a.place, cc, a.radiusMiles ?? 20),
        }),
        headers: {'accept': 'application/sparql-results+json'},
      );
      out.addAll(parseWikidata(obj(body), place: a.place));
    }
    final seen = <String>{};
    return [
      for (final s in out)
        if (seen.add(s.name.toLowerCase())) s,
    ];
  }

  /// The SPARQL for hospitals (Q16917 or a subclass) around [place] in
  /// country [cc].
  static String hospitalQuery(String place, String cc, int miles) {
    final name = place.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    final km = (miles * 1.609).round();
    return 'SELECT DISTINCT ?h ?hLabel ?site WHERE { '
        '?c wdt:P297 "${cc.toUpperCase()}" . ?place wdt:P17 ?c ; rdfs:label "$name"@en ; wdt:P625 ?loc . '
        'SERVICE wikibase:around { ?h wdt:P625 ?hl . bd:serviceParam wikibase:center ?loc ; '
        'wikibase:radius "$km" . } '
        '?h wdt:P31/wdt:P279* wd:Q16917 . ?h wdt:P856 ?site . '
        'SERVICE wikibase:label { bd:serviceParam wikibase:language "en" . } } LIMIT 60';
  }

  static List<EmployerSuggestion> parseWikidata(Json body, {String place = ''}) => [
    for (final b in objs(obj(body['results'])['bindings']))
      if (str(obj(b['hLabel'])['value']) case final name
          when name.isNotEmpty && !RegExp(r'^Q\d+$').hasMatch(name))
        EmployerSuggestion(
          name: name,
          source: 'Wikidata',
          place: place,
          website: str(obj(b['site'])['value']),
        ),
  ];

  /// Organisations live on Epic, from Epic's public endpoint list, fetched
  /// now (never stored with Udyoga), filtered to [country] and [towns].
  Future<List<EmployerSuggestion>> epicCustomers({
    String country = '',
    List<String> towns = const [],
  }) async => parseFhirOrganisations(
    obj(await _json(Uri.parse(CustomerLists.epic), seconds: 120)),
    source: 'Epic',
    country: country,
    towns: towns,
  );

  /// Organisations on Oracle Health Millennium, from Oracle's public
  /// endpoint list, fetched now.
  Future<List<EmployerSuggestion>> oracleCustomers({
    String country = '',
    List<String> towns = const [],
  }) async => parseFhirOrganisations(
    obj(await _json(Uri.parse(CustomerLists.oracle), seconds: 120)),
    source: 'Oracle Health',
    country: country,
    towns: towns,
  );

  /// The organisations in a FHIR Bundle (Organization resources, or ones
  /// contained in an Endpoint). An organisation with an address must be in
  /// [country]; with [towns], its city or name must say one.
  static List<EmployerSuggestion> parseFhirOrganisations(
    Json bundle, {
    required String source,
    String country = '',
    List<String> towns = const [],
  }) {
    final out = <EmployerSuggestion>[];
    final seen = <String>{};
    void add(Json o) {
      if (str(o['resourceType']) != 'Organization') return;
      final name = str(o['name']);
      if (name.isEmpty) return;
      final address = objs(o['address']).firstOrNull ?? const <String, Object?>{};
      final cc = countryCode(str(address['country']));
      if (country.isNotEmpty && cc.isNotEmpty && cc != country) return;
      if (country.isNotEmpty && cc.isEmpty && country != 'US' && towns.isEmpty) return;
      final city = str(address['city']);
      if (towns.isNotEmpty &&
          !towns.any((t) {
            final n = normaliseEmployer(t);
            return normaliseEmployer(city) == n || ' ${normaliseEmployer(name)} '.contains(' $n ');
          })) {
        return;
      }
      if (!seen.add(name.toLowerCase())) return;
      out.add(
        EmployerSuggestion(
          name: name,
          source: source,
          place: [city, str(address['state'])].where((x) => x.isNotEmpty).join(', '),
        ),
      );
    }

    for (final e in objs(bundle['entry'])) {
      final r = obj(e['resource']);
      add(r);
      objs(r['contained']).forEach(add);
    }
    return out;
  }
}

/// "EXAMPLE TEACHING HOSPITALS NHS TRUST" as "Example Teaching Hospitals NHS
/// Trust".
String titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) {
      if (const {'nhs', 'uk', 'gp'}.contains(w)) return w.toUpperCase();
      if (const {'and', 'of', 'the', 'for'}.contains(w)) return w;
      return w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}';
    })
    .join(' ')
    .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase());
