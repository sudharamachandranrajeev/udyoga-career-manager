/// Live refresh of the route tables that publish machine-readable data:
/// the UK's Appendix Skilled Occupations (GOV.UK Content API JSON) and
/// Canada's Express Entry rounds (IRCC JSON). Kept on this device with the
/// day they were read; the shipped tables stay the fallback.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'feeds.dart';
import 'json.dart';
import 'routes.dart';

const skilledOccupationsApi =
    'https://www.gov.uk/api/content/guidance/immigration-rules/immigration-rules-appendix-skilled-occupations';
const skilledOccupationsPage =
    'https://www.gov.uk/guidance/immigration-rules/immigration-rules-appendix-skilled-occupations';

String _text(String html) => html
    .replaceAll(RegExp(r'<[^>]+>'), ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int? _pounds(String cell) {
  final m = RegExp(r'^£\s*([\d,]+)').firstMatch(cell);
  return m == null ? null : int.tryParse(m[1]!.replaceAll(',', ''));
}

/// The UK rules with the rates in [body] (the Content API JSON of
/// Appendix Skilled Occupations) for the codes in [base]. Floors, the TSL
/// cut-off and Health and Care flags stay as in [base]. Null when the page
/// gives none of the codes, so a changed layout falls back to [base].
UkRules? parseSkilledOccupations(String body, {required UkRules base, required String today}) {
  final Json j;
  try {
    j = obj(jsonDecode(body));
  } on FormatException {
    return null;
  }
  final html = str(obj(j['details'])['body']);
  if (html.isEmpty) return null;
  final found = <String, UkOccupation>{};
  // A code can sit in Table 2aa and 2b; the first care rate is the one.
  final careSeen = <String>{};
  var table = '';
  final parts = html.split(RegExp(r'(?=<h[234][^>]*>)'));
  for (final part in parts) {
    final heading = RegExp(r'^<h[234][^>]*>(.*?)</h[234]>', dotAll: true).firstMatch(part);
    if (heading != null) {
      final t = RegExp(r'^Table (\w+):').firstMatch(_text(heading[1]!));
      if (t != null) table = t[1]!.toLowerCase();
    }
    if (!const {'1', '1a', '2', '2aa', '6'}.contains(table)) continue;
    for (final row in RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true).allMatches(part)) {
      final cells = [
        for (final c in RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>', dotAll: true).allMatches(row[1]!)) _text(c[1]!),
      ];
      if (cells.isEmpty) continue;
      final soc = RegExp(r'^(\d{4})\b').firstMatch(cells.first)?[1];
      if (soc == null || !base.occupations.containsKey(soc)) continue;
      final shipped = found[soc] ?? base.occupations[soc]!;
      final money = cells.map(_pounds).whereType<int>().toList();
      final title = cells.first.substring(4).trim();
      found[soc] = switch (table) {
        '1' || '1a' when money.isNotEmpty => shipped.copyWith(
          title: title.isEmpty ? null : title,
          table: table,
          goingRate: money.first,
          newEntrantRate: money.last,
        ),
        '2' || '2aa' when money.isNotEmpty && careSeen.add(soc) => shipped.copyWith(
          careRate: money.first,
          careNewEntrantRate: money.last,
        ),
        '6' => shipped.copyWith(table: '6'),
        _ => shipped,
      };
    }
  }
  if (found.isEmpty) return null;
  final updated = str(j['public_updated_at']);
  final day = updated.length >= 10 ? updated.substring(0, 10) : '';
  return UkRules(
    generalFloor: base.generalFloor,
    newEntrantFloor: base.newEntrantFloor,
    careFloor: base.careFloor,
    careNewEntrantFloor: base.careNewEntrantFloor,
    tslCutoff: base.tslCutoff,
    occupations: {...base.occupations, ...found},
    source: RouteSource(
      'Immigration Rules Appendix Skilled Occupations (GOV.UK${day.isEmpty ? '' : ', updated $day'}, read live)',
      skilledOccupationsPage,
      asOf: today,
    ),
    live: true,
  );
}

/// One Express Entry round of invitations.
class ExpressEntryRound {
  const ExpressEntryRound({
    required this.number,
    required this.date,
    required this.name,
    required this.size,
    required this.crs,
  });
  final int number;

  /// yyyy-MM-dd
  final String date;

  /// "Healthcare and social services occupations (Version 2)", "Canadian
  /// Experience Class", "No Program Specified".
  final String name;
  final int size, crs;

  Json toJson() => {'drawNumber': number, 'drawDate': date, 'drawName': name, 'drawSize': size, 'drawCRS': crs};
}

/// The rounds in IRCC's JSON, newest first.
List<ExpressEntryRound> parseExpressEntryRounds(String body) {
  final Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  final out = <ExpressEntryRound>[];
  for (final r in objs(obj(j)['rounds'])) {
    final n = intOf(r['drawNumber']);
    final date = str(r['drawDate']);
    if (n == null || !isDayText(date)) continue;
    out.add(
      ExpressEntryRound(
        number: n,
        date: date,
        name: str(r['drawName']),
        size: intOf(r['drawSize']) ?? 0,
        crs: intOf(r['drawCRS']) ?? 0,
      ),
    );
  }
  out.sort((a, b) => b.date != a.date ? b.date.compareTo(a.date) : b.number.compareTo(a.number));
  return out;
}

/// The latest rounds and when they were read.
class ExpressEntryRounds {
  const ExpressEntryRounds(this.rounds, this.checked);
  final List<ExpressEntryRound> rounds;

  /// yyyy-MM-dd
  final String checked;
}

/// Reads and caches the live tables on this device.
class RouteRefresh {
  RouteRefresh(this.client, this.db);
  final http.Client client;
  final AppDatabase db;

  static const ukKey = 'udyoga.routes.uk';
  static const roundsKey = 'udyoga.routes.ee';

  /// How long a read stays fresh.
  static const every = Duration(days: 7);

  /// The UK rules last read on this device, else the shipped ones.
  Future<UkRules> ukRules() async {
    final j = decodeObject(await db.localSetting(ukKey) ?? '');
    if (j['rules'] is! Map) return shippedUkRules;
    return UkRules.fromJson(obj(j['rules']));
  }

  Future<String> _get(String url) async {
    final http.Response r;
    try {
      r = await client.get(Uri.parse(url), headers: {'Accept': 'application/json'});
    } on Exception catch (e) {
      throw FeedException('could not reach ${Uri.parse(url).host} ($e)');
    }
    if (r.statusCode != 200) throw FeedException('${Uri.parse(url).host} answered ${r.statusCode}');
    return utf8.decode(r.bodyBytes);
  }

  bool _fresh(Json cached, DateTime now) {
    final at = DateTime.tryParse(str(cached['checked']));
    return at != null && now.difference(at) < every;
  }

  /// Reads Appendix Skilled Occupations from GOV.UK unless read this week
  /// ([force] reads anyway). Throws FeedException when GOV.UK cannot be
  /// reached or its page no longer reads, leaving the last good copy.
  Future<UkRules> refreshUk({DateTime? now, bool force = false}) async {
    final at = now ?? DateTime.now();
    final cached = decodeObject(await db.localSetting(ukKey) ?? '');
    if (!force && cached['rules'] is Map && _fresh(cached, at)) return UkRules.fromJson(obj(cached['rules']));
    final body = await _get(skilledOccupationsApi);
    final rules = parseSkilledOccupations(body, base: shippedUkRules, today: _day(at));
    if (rules == null) throw FeedException('the GOV.UK appendix has changed layout; using the shipped table');
    await db.setLocalSetting(ukKey, jsonEncode({'checked': at.toIso8601String(), 'rules': rules.toJson()}));
    return rules;
  }

  /// The Express Entry rounds last read on this device, or null.
  Future<ExpressEntryRounds?> rounds() async {
    final j = decodeObject(await db.localSetting(roundsKey) ?? '');
    final list = parseExpressEntryRounds(jsonEncode({'rounds': j['rounds'] ?? const []}));
    if (list.isEmpty) return null;
    return ExpressEntryRounds(list, str(j['checked']).split('T').first);
  }

  /// Reads the rounds from IRCC unless read this week; keeps the latest 20.
  Future<ExpressEntryRounds> refreshRounds({DateTime? now, bool force = false}) async {
    final at = now ?? DateTime.now();
    final cached = await rounds();
    final raw = decodeObject(await db.localSetting(roundsKey) ?? '');
    if (!force && cached != null && _fresh(raw, at)) return cached;
    final list = parseExpressEntryRounds(await _get(expressEntryRoundsUrl));
    if (list.isEmpty) throw FeedException('IRCC sent no rounds Udyoga could read');
    final keep = list.take(20).toList();
    await db.setLocalSetting(
      roundsKey,
      jsonEncode({
        'checked': at.toIso8601String(),
        'rounds': [for (final r in keep) r.toJson()],
      }),
    );
    return ExpressEntryRounds(keep, _day(at));
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
