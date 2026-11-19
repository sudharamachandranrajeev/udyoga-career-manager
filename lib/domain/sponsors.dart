import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'feeds.dart';

/// The GOV.UK page of the register of licensed sponsors. Its attachment is
/// renamed with each day's date, so the CSV link is read from here rather
/// than written into the app.
const sponsorRegisterApi =
    'https://www.gov.uk/api/content/government/publications/register-of-licensed-sponsors-workers';

/// The public page, for people to look for themselves.
const sponsorRegisterPage =
    'https://www.gov.uk/government/publications/register-of-licensed-sponsors-workers';

/// An organisation on the register and the routes it may sponsor.
class Sponsor {
  const Sponsor({required this.name, this.town = '', this.routes = const {}});
  final String name, town;
  final Set<String> routes;

  /// Licensed for Skilled Worker, which includes the Health and Care visa.
  bool get skilledWorker => routes.any((r) => r.toLowerCase().contains('skilled worker'));

  /// The badge text.
  String get badge => skilledWorker
      ? 'Licensed sponsor (Skilled Worker / Health and Care)'
      : 'Licensed sponsor (${routes.isEmpty ? 'workers' : (routes.toList()..sort()).join(' / ')})';
}

const _suffixes = [
  'nhs foundation trust',
  'nhs trust',
  'foundation trust',
  'health and social care trust',
  'limited',
  'ltd',
  'plc',
  'llp',
  'llc',
  'inc',
  'incorporated',
  'uk',
  'co',
];

/// An employer's name reduced for matching: lower case, "&" as "and",
/// punctuation and a leading "The" dropped, and legal endings ("Ltd",
/// "PLC", "NHS Foundation Trust") taken off. "The Example Hospitals NHS
/// Foundation Trust" and "Example Hospitals" give the same key.
String sponsorKey(String name) {
  var s = name.toLowerCase().replaceAll('&', ' and ').replaceAll(RegExp(r"['’`]"), '');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  s = s.replaceFirst(RegExp(r'^the\s+'), '');
  var changed = true;
  while (changed) {
    changed = false;
    for (final suffix in _suffixes) {
      if (s.endsWith(' $suffix')) {
        s = s.substring(0, s.length - suffix.length - 1).trim();
        changed = true;
      }
    }
  }
  return s;
}

/// The names an employer is known by: its own and, for "A Ltd t/a B", B.
List<String> _namesOf(String name) => name
    .split(RegExp(r'\s+(?:t/a|T/A|trading as|Trading As|TA)\s+'))
    .map((n) => n.trim())
    .where((n) => n.isNotEmpty)
    .toList();

/// The register, keyed by [sponsorKey].
class SponsorRegister {
  SponsorRegister(this.byKey);
  final Map<String, Sponsor> byKey;

  int get length => byKey.length;

  /// The sponsor [employer] names, or null. Exact on the reduced name, so
  /// "Example Care" never matches "Example Care Homes".
  Sponsor? lookup(String employer) {
    for (final n in _namesOf(employer)) {
      final s = byKey[sponsorKey(n)];
      if (s != null) return s;
    }
    return null;
  }

  /// From the register's CSV: a header row naming "Organisation Name",
  /// "Town/City" and "Route" (in any order), then one row per organisation
  /// and route.
  factory SponsorRegister.fromCsv(String csv) {
    final rows = parseCsv(csv);
    if (rows.isEmpty) throw const FormatException('The sponsor register is empty');
    final head = [for (final h in rows.first) h.toLowerCase().trim()];
    final nameAt = head.indexWhere((h) => h.contains('organisation'));
    final townAt = head.indexWhere((h) => h.contains('town'));
    final routeAt = head.indexWhere((h) => h == 'route' || h.contains('route'));
    if (nameAt < 0) throw const FormatException('The sponsor register has no Organisation Name column');
    final out = <String, Sponsor>{};
    for (final r in rows.skip(1)) {
      if (r.length <= nameAt) continue;
      final name = r[nameAt].trim();
      if (name.isEmpty) continue;
      final town = townAt >= 0 && townAt < r.length ? r[townAt].trim() : '';
      final route = routeAt >= 0 && routeAt < r.length ? r[routeAt].trim() : '';
      for (final n in _namesOf(name)) {
        final k = sponsorKey(n);
        if (k.isEmpty) continue;
        final was = out[k];
        out[k] = Sponsor(
          name: was?.name ?? name,
          town: was?.town ?? town,
          routes: {...?was?.routes, if (route.isNotEmpty) route},
        );
      }
    }
    return SponsorRegister(out);
  }

  /// The compact cache: key, name, town, routes (joined by "|"), a line each.
  String toTsv() => [
    for (final e in byKey.entries)
      [
        e.key,
        e.value.name,
        e.value.town,
        e.value.routes.join('|'),
      ].map((v) => v.replaceAll(RegExp(r'[\t\n\r]'), ' ')).join('\t'),
  ].join('\n');

  factory SponsorRegister.fromTsv(String tsv) => SponsorRegister({
    for (final line in const LineSplitter().convert(tsv))
      if (line.split('\t') case [final k, final name, final town, final routes, ...])
        k: Sponsor(name: name, town: town, routes: routes.isEmpty ? const {} : routes.split('|').toSet()),
  });
}

/// Rows of a CSV file (RFC 4180: quoted fields, doubled quotes, line
/// breaks inside quotes).
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = 0;
  if (text.startsWith('﻿')) i = 1;
  for (; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// The register kept on this device: fetched at most once a day while the
/// UK is a target, cached as a small file, read back for the badges.
class SponsorStore {
  SponsorStore(this.dir, this.client, this.db);
  final Directory dir;
  final http.Client client;
  final AppDatabase db;

  static const checkedKey = 'udyoga.sponsors.checked';
  static const urlKey = 'udyoga.sponsors.url';
  static const every = Duration(days: 1);

  File get _file => File('${dir.path}${Platform.pathSeparator}sponsors.tsv');

  SponsorRegister? _loaded;
  DateTime? _loadedAt;

  /// The cached register, or null before the first download.
  Future<SponsorRegister?> load() async {
    final f = _file;
    if (!await f.exists()) return null;
    final modified = await f.lastModified();
    if (_loaded != null && _loadedAt == modified) return _loaded;
    _loaded = SponsorRegister.fromTsv(await f.readAsString());
    _loadedAt = modified;
    return _loaded;
  }

  /// The CSV link on the GOV.UK page.
  Future<Uri> csvUrl() async {
    final r = await client.get(Uri.parse(sponsorRegisterApi), headers: {'Accept': 'application/json'});
    if (r.statusCode != 200) throw FeedException('GOV.UK answered ${r.statusCode}');
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      throw FeedException('GOV.UK sent a reply Udyoga could not read');
    }
    final details = body is Map ? body['details'] : null;
    final attachments = details is Map ? details['attachments'] : null;
    for (final a in attachments is List ? attachments : const []) {
      if (a is! Map) continue;
      final url = '${a['url'] ?? ''}';
      final type = '${a['content_type'] ?? ''}';
      if (url.isNotEmpty && (type.contains('csv') || url.toLowerCase().endsWith('.csv'))) {
        return Uri.parse(url).isAbsolute ? Uri.parse(url) : Uri.parse('https://www.gov.uk').resolve(url);
      }
    }
    throw FeedException('the GOV.UK page lists no CSV file');
  }

  /// Downloads the register when a day has passed since the last check and
  /// the file has changed. Returns true when it downloaded.
  Future<bool> refreshIfDue({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final checked = DateTime.tryParse(await db.localSetting(checkedKey) ?? '');
    if (checked != null && at.difference(checked) < every && await _file.exists()) return false;
    final url = await csvUrl();
    if (await db.localSetting(urlKey) == '$url' && await _file.exists()) {
      await db.setLocalSetting(checkedKey, at.toIso8601String());
      return false;
    }
    final r = await client.get(url);
    if (r.statusCode != 200) throw FeedException('the register download answered ${r.statusCode}');
    final register = SponsorRegister.fromCsv(utf8.decode(r.bodyBytes, allowMalformed: true));
    await dir.create(recursive: true);
    final tmp = File('${_file.path}.part');
    await tmp.writeAsString(register.toTsv());
    await tmp.rename(_file.path);
    await db.setLocalSetting(urlKey, '$url');
    await db.setLocalSetting(checkedKey, at.toIso8601String());
    _loaded = register;
    _loadedAt = await _file.lastModified();
    return true;
  }
}
