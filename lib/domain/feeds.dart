import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' show SecretStore;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'countries.dart';
import 'json.dart';
import 'work_rights.dart';
import 'world.dart';

/// An opening as a job feed gives it, before it is saved.
class Posting {
  const Posting({
    required this.source,
    required this.sourceId,
    required this.title,
    this.company = '',
    this.location = '',
    this.country = '',
    this.remote = false,
    this.salaryMin,
    this.salaryMax,
    this.currency = '',
    this.salaryText = '',
    this.url = '',
    this.description = '',
    this.posted,
    this.closing,
  });
  final String source, sourceId, title, company, location, country;
  final bool remote;
  final int? salaryMin, salaryMax;
  final String currency, salaryText, url, description;
  final String? posted, closing;
}

/// What to look for: search terms, where, and whether remote work counts.
class FeedQuery {
  const FeedQuery({
    required this.terms,
    required this.country,
    this.place = '',
    this.radiusMiles,
    this.remote = false,
    this.keep,
  });
  final List<String> terms;

  /// ISO alpha-2; '' for a search not tied to a country (remote work, UN
  /// jobs).
  final String country;
  final String place;

  /// How far around [place]; null: the site's default.
  final int? radiusMiles;
  final bool remote;

  /// The titles a feed that checks titles itself (NHS Jobs) accepts: a
  /// result is kept when its title holds every word of one of them, so a
  /// role search keeps any title in the role's family. Null: each search
  /// term's own words, the strict check.
  final List<String>? keep;

  /// This query with other [terms] (and [keep]); the place stays.
  FeedQuery withTerms(List<String> terms, {List<String>? keep}) => FeedQuery(
    terms: terms,
    country: country,
    place: place,
    radiusMiles: radiusMiles,
    remote: remote,
    keep: keep,
  );
}

/// Free job-search APIs. Each says which countries it covers; keys (where
/// needed) are the user's own, free from the provider.
abstract class JobFeed {
  String get id;
  String get name;

  /// Searches around a town. A feed that does not is asked once per
  /// country, however many home areas the candidate has.
  bool get usesPlace => false;

  /// The most search terms one run should send to the site: each term is
  /// one request (or a few pages), so callers cap the terms they pass. Null:
  /// the feed downloads one list and filters it here, so more terms cost
  /// nothing more.
  int? get maxTerms => 6;
  bool covers(FeedQuery q);
  Future<List<Posting>> search(FeedQuery q);
}

class FeedException implements Exception {
  FeedException(this.message);
  final String message;
  @override
  String toString() => message;
}

String? _date(Object? v) {
  final s = str(v);
  if (s.isEmpty) return null;
  final uk = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(s);
  if (uk != null) return '${uk[3]}-${uk[2]}-${uk[1]}';
  return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s) ? s.substring(0, 10) : null;
}

Future<Object?> _getJson(http.Client client, Uri uri, {Map<String, String> headers = const {}}) async {
  final r = await client
      .get(uri, headers: {'accept': 'application/json', ...headers})
      .timeout(const Duration(seconds: 30));
  if (r.statusCode == 401 || r.statusCode == 403) throw FeedException('the key was rejected');
  if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
  try {
    return jsonDecode(utf8.decode(r.bodyBytes));
  } on FormatException {
    // A sign-in page on public Wi-Fi, or the site changed its reply.
    throw FeedException('sent a reply that is not job data (a Wi-Fi sign-in page, or the site changed)');
  }
}

/// What went wrong with a feed, in a few words: its own message, a reply
/// that could not be read, a time-out, or no connection.
String feedProblem(Object e) => switch (e) {
  FeedException() => e.message,
  FormatException() => 'sent a reply that could not be read',
  TimeoutException() => 'did not answer in time',
  SocketException() || HandshakeException() || http.ClientException() => 'not reachable',
  _ => 'failed ($e)',
};

/// True when [text] holds every word of at least one of [terms].
bool mentionsAny(String text, List<String> terms) => _mentions(text, terms);

/// True when [text] holds every word of at least one of [phrases] as a
/// whole word (a plural "s", "es" or "ies" allowed), in any order and case.
/// So a short family title such as "PA" keeps "Medical PA" but not
/// "Paediatrics" or "Part time", which a plain substring check would.
bool holdsWords(String text, List<String> phrases) => phrases.any((t) {
  final words = t.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.isNotEmpty &&
      words.every((w) {
        final y = w.length > 1 && w.toLowerCase().endsWith('y');
        final word = y
            ? '${RegExp.escape(w.substring(0, w.length - 1))}(?:y|ies)'
            : '${RegExp.escape(w)}(?:e?s)?';
        return RegExp(
          '(?<![A-Za-z0-9\u00C0-\u024F])$word(?![A-Za-z0-9\u00C0-\u024F])',
          caseSensitive: false,
        ).hasMatch(text);
      });
});

bool _mentions(String text, List<String> terms) {
  final t = text.toLowerCase();
  return terms.any((term) => term.toLowerCase().split(RegExp(r'\s+')).every(t.contains));
}

/// Where Adzuna's postings must credit it (its terms ask for a "Jobs by
/// Adzuna" link on every ad shown).
const adzunaHome = 'https://www.adzuna.com';

/// Adzuna: many countries, needs a free app id and key. Its terms: the free
/// tier is for evaluating the API, and each ad shown links back to Adzuna.
class AdzunaFeed extends JobFeed {
  AdzunaFeed(this.client, {required this.appId, required this.appKey});
  final http.Client client;
  final String appId, appKey;

  @override
  String get id => 'adzuna';
  @override
  String get name => 'Adzuna';
  @override
  bool get usesPlace => true;
  @override
  bool covers(FeedQuery q) => appId.isNotEmpty && Country.of(q.country)?.adzuna != null;

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final cc = Country.of(q.country)!.adzuna!;
    final out = <Posting>[];
    for (final term in q.terms) {
      final uri = Uri.https('api.adzuna.com', '/v1/api/jobs/$cc/search/1', {
        'app_id': appId,
        'app_key': appKey,
        'what': term,
        if (q.place.isNotEmpty) 'where': q.place,
        if (q.place.isNotEmpty && q.radiusMiles != null) 'distance': '${(q.radiusMiles! * 1.609).round()}',
        'results_per_page': '30',
        'max_days_old': '21',
        'sort_by': 'date',
      });
      for (final r in objs(obj(await _getJson(client, uri))['results'])) {
        final min = intOf(r['salary_min']), max = intOf(r['salary_max']);
        final predicted = str(r['salary_is_predicted']) == '1';
        out.add(
          Posting(
            source: id,
            sourceId: str(r['id']),
            title: htmlToText(str(r['title'])),
            company: str(obj(r['company'])['display_name']),
            location: str(obj(r['location'])['display_name']),
            country: q.country,
            salaryMin: predicted ? null : min,
            salaryMax: predicted ? null : max,
            currency: predicted ? '' : Country.of(q.country)!.currency,
            salaryText: predicted && min != null
                ? 'Estimated ${Country.of(q.country)!.currency} $min–$max'
                : '',
            url: str(r['redirect_url']),
            description: htmlToText(str(r['description'])),
            posted: _date(r['created']),
          ),
        );
      }
    }
    return out;
  }
}

/// Reed: the UK, needs a free API key.
class ReedFeed extends JobFeed {
  ReedFeed(this.client, {required this.key});
  final http.Client client;
  final String key;

  @override
  String get id => 'reed';
  @override
  String get name => 'Reed';
  @override
  bool get usesPlace => true;
  @override
  bool covers(FeedQuery q) => key.isNotEmpty && q.country == 'GB';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final auth = 'Basic ${base64Encode(utf8.encode('$key:'))}';
    final out = <Posting>[];
    for (final term in q.terms) {
      final uri = Uri.https('www.reed.co.uk', '/api/1.0/search', {
        'keywords': term,
        if (q.place.isNotEmpty) 'locationName': q.place,
        if (q.place.isNotEmpty) 'distanceFromLocation': '${q.radiusMiles ?? 25}',
        'resultsToTake': '40',
      });
      for (final r in objs(obj(await _getJson(client, uri, headers: {'authorization': auth}))['results'])) {
        out.add(
          Posting(
            source: id,
            sourceId: str(r['jobId']),
            title: str(r['jobTitle']),
            company: str(r['employerName']),
            location: str(r['locationName']),
            country: 'GB',
            salaryMin: intOf(r['minimumSalary']),
            salaryMax: intOf(r['maximumSalary']),
            currency: str(r['currency']).isEmpty ? 'GBP' : str(r['currency']),
            url: str(r['jobUrl']),
            description: htmlToText(str(r['jobDescription'])),
            posted: _date(r['date']),
            closing: _date(r['expirationDate']),
          ),
        );
      }
    }
    return out;
  }
}

/// NHS Jobs (England and Wales): the official public search feed
/// (NHSBSA "Self-Serve Job Adverts API"), no key. Its terms allow extracts
/// for personal, non-commercial use; each job opens on NHS Jobs.
class NhsJobsFeed extends JobFeed {
  NhsJobsFeed(this.client);
  final http.Client client;

  /// Pages of ten read per search term.
  static const pages = 3;

  @override
  String get id => 'nhs';
  @override
  String get name => 'NHS Jobs';

  @override
  bool get usesPlace => true;
  @override
  bool covers(FeedQuery q) => q.country == 'GB';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final out = <Posting>[];
    for (final term in q.terms) {
      for (var page = 1; page <= pages; page++) {
        final uri = Uri.https('www.jobs.nhs.uk', '/api/v1/search_xml', {
          'keyword': term,
          if (q.place.isNotEmpty) ...{
            'location': q.place,
            'distance': '${q.radiusMiles ?? 15}',
            'countryCode': 'GB-ENG',
          },
          'page': '$page',
        });
        final r = await client
            .get(uri, headers: {'accept': 'application/xml'})
            .timeout(const Duration(seconds: 30));
        if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
        final found = parse(utf8.decode(r.bodyBytes));
        out.addAll(found.where((p) => holdsWords(p.title, q.keep ?? [term])));
        if (found.length < 10) break;
      }
    }
    return out;
  }

  /// The postings in one search_xml response.
  static List<Posting> parse(String body) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(body);
    } on XmlException {
      throw FeedException('NHS Jobs sent something unreadable');
    }
    String text(XmlElement e, String name) => e.getElement(name)?.innerText.trim() ?? '';
    return [
      for (final v in doc.findAllElements('vacancyDetails'))
        if (text(v, 'title').isNotEmpty)
          () {
            final (min, max) = _pounds(text(v, 'salary'));
            final places = v
                .findAllElements('location')
                .map((l) => l.innerText.trim())
                .where((l) => l.isNotEmpty);
            return Posting(
              source: 'nhs',
              sourceId: text(v, 'id'),
              title: text(v, 'title'),
              company: text(v, 'employer'),
              location: places.join('; '),
              country: 'GB',
              salaryMin: min,
              salaryMax: max,
              currency: 'GBP',
              salaryText: text(v, 'salary'),
              url: text(v, 'url'),
              description: [
                text(v, 'description'),
                if (text(v, 'type').isNotEmpty) 'Contract: ${text(v, 'type')}.',
                if (text(v, 'reference').isNotEmpty) 'Reference: ${text(v, 'reference')}.',
              ].join('\n'),
              posted: _date(text(v, 'postDate')),
              closing: _date(text(v, 'closeDate')),
            );
          }(),
    ];
  }

  /// "£25760.00 to £27476.00" or "£25272.00"; anything else (Negotiable,
  /// an hourly rate) gives no figures.
  static (int?, int?) _pounds(String s) {
    final m = RegExp(r'£([\d,]+)(?:\.\d+)?(?:\s+to\s+£([\d,]+)(?:\.\d+)?)?$').firstMatch(s.trim());
    if (m == null) return (null, null);
    int? n(String? x) => x == null ? null : int.tryParse(x.replaceAll(',', ''));
    final low = n(m[1]);
    // Hourly rates (£12.21 to £12.60) stay as text only.
    if (low == null || low < 1000) return (null, null);
    return (low, n(m[2]) ?? low);
  }
}

/// Remotive: remote jobs worldwide, no key. Its terms ask for a link back
/// (each job opens on Remotive) and at most a few calls a day.
class RemotiveFeed extends JobFeed {
  RemotiveFeed(this.client);
  final http.Client client;

  @override
  String get id => 'remotive';
  @override
  String get name => 'Remotive';

  /// A few searches a run: the site asks for few calls.
  @override
  int? get maxTerms => 3;

  /// Worldwide, so it answers only the country-less remote query.
  @override
  bool covers(FeedQuery q) => q.remote && q.country.isEmpty;

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final out = <Posting>[];
    for (final term in q.terms) {
      final uri = Uri.https('remotive.com', '/api/remote-jobs', {'search': term, 'limit': '30'});
      for (final r in objs(obj(await _getJson(client, uri))['jobs'])) {
        out.add(
          Posting(
            source: id,
            sourceId: str(r['id']),
            title: str(r['title']),
            company: str(r['company_name']),
            location: str(r['candidate_required_location']),
            remote: true,
            salaryText: str(r['salary']),
            url: str(r['url']),
            description: htmlToText(str(r['description'])),
            posted: _date(r['publication_date']),
          ),
        );
      }
    }
    return out;
  }
}

/// Jobicy: remote jobs by region, no key.
class JobicyFeed extends JobFeed {
  JobicyFeed(this.client);
  final http.Client client;

  @override
  String get id => 'jobicy';
  @override
  String get name => 'Jobicy';

  @override
  int? get maxTerms => 3;

  static const _geo = {
    'GB': 'uk',
    'IE': 'ireland',
    'US': 'usa',
    'CA': 'canada',
    'DE': 'germany',
    'FR': 'france',
    'ES': 'spain',
    'NL': 'netherlands',
    'AU': 'australia',
    'IN': 'apac',
  };

  @override
  bool covers(FeedQuery q) => q.remote && _geo.containsKey(q.country);

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final out = <Posting>[];
    for (final term in q.terms) {
      final uri = Uri.https('jobicy.com', '/api/v2/remote-jobs', {
        'count': '30',
        'geo': _geo[q.country]!,
        'tag': term,
      });
      for (final r in objs(obj(await _getJson(client, uri))['jobs'])) {
        out.add(
          Posting(
            source: id,
            sourceId: str(r['id']),
            title: htmlToText(str(r['jobTitle'])),
            company: str(r['companyName']),
            location: str(r['jobGeo']),
            remote: true,
            salaryMin: intOf(r['annualSalaryMin']),
            salaryMax: intOf(r['annualSalaryMax']),
            currency: str(r['salaryCurrency']),
            url: str(r['url']),
            description: htmlToText(str(r['jobDescription'])),
            posted: _date(r['pubDate']),
          ),
        );
      }
    }
    return out;
  }
}

/// Arbeitnow: jobs in Germany and nearby, no key and no search, so the
/// newest page is filtered here.
class ArbeitnowFeed extends JobFeed {
  ArbeitnowFeed(this.client);
  final http.Client client;

  @override
  String get id => 'arbeitnow';
  @override
  String get name => 'Arbeitnow';

  /// One download filtered here, so any number of terms.
  @override
  int? get maxTerms => null;

  @override
  bool covers(FeedQuery q) => const {'DE', 'AT', 'CH'}.contains(q.country);

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final data = obj(await _getJson(client, Uri.https('www.arbeitnow.com', '/api/job-board-api')));
    return [
      for (final r in objs(data['data']))
        if (_mentions('${r['title']} ${strs(r['tags']).join(' ')}', q.terms))
          Posting(
            source: id,
            sourceId: str(r['slug']),
            title: str(r['title']),
            company: str(r['company_name']),
            location: str(r['location']),
            country: q.country,
            remote: r['remote'] == true,
            url: str(r['url']),
            description: htmlToText(str(r['description'])),
            posted: switch (intOf(r['created_at'])) {
              final t? => DateTime.fromMillisecondsSinceEpoch(
                t * 1000,
                isUtc: true,
              ).toIso8601String().substring(0, 10),
              null => null,
            },
          ),
    ];
  }
}

/// Where the USAJOBS and Jooble keys are kept: this device's keychain
/// (SecretStore), never synced.
abstract final class FeedSecrets {
  static const usajobsKey = 'udyoga.usajobs.key';
  static const usajobsEmail = 'udyoga.usajobs.email';

  /// JSON {"GB": key, ...}: Jooble gives one key per country site.
  static const jooble = 'udyoga.jooble.keys';
}

/// The user's job-feed keys. Adzuna and Reed sync (end-to-end encrypted);
/// USAJOBS and Jooble stay in this device's keychain.
class FeedKeys {
  const FeedKeys({
    this.adzunaId = '',
    this.adzunaKey = '',
    this.reed = '',
    this.usajobsKey = '',
    this.usajobsEmail = '',
    this.jooble = const {},
  });
  final String adzunaId, adzunaKey, reed;

  /// USAJOBS: the key and the e-mail it was registered with (sent as the
  /// User-Agent, as its rules ask).
  final String usajobsKey, usajobsEmail;

  /// Jooble keys by ISO country code.
  final Map<String, String> jooble;

  factory FeedKeys.fromJson(Json j) =>
      FeedKeys(adzunaId: str(j['adzunaId']), adzunaKey: str(j['adzunaKey']), reed: str(j['reed']));

  /// The synced part only.
  Json toJson() => {'adzunaId': adzunaId, 'adzunaKey': adzunaKey, 'reed': reed};

  /// These keys with the device's own from [store].
  Future<FeedKeys> withSecrets(SecretStore? store) async {
    if (store == null) return this;
    final jooble = decodeObject(await store.read(FeedSecrets.jooble) ?? '');
    return FeedKeys(
      adzunaId: adzunaId,
      adzunaKey: adzunaKey,
      reed: reed,
      usajobsKey: (await store.read(FeedSecrets.usajobsKey) ?? '').trim(),
      usajobsEmail: (await store.read(FeedSecrets.usajobsEmail) ?? '').trim(),
      jooble: {
        for (final e in jooble.entries)
          if (str(e.value).isNotEmpty) e.key.toUpperCase(): str(e.value),
      },
    );
  }

  /// Saves the device-only keys to [store]; an empty value removes one.
  static Future<void> saveSecrets(
    SecretStore store, {
    required String usajobsKey,
    required String usajobsEmail,
    required Map<String, String> jooble,
  }) async {
    Future<void> put(String k, String v) => v.isEmpty ? store.delete(k) : store.write(k, v);
    await put(FeedSecrets.usajobsKey, usajobsKey.trim());
    await put(FeedSecrets.usajobsEmail, usajobsEmail.trim());
    await put(FeedSecrets.jooble, jooble.isEmpty ? '' : jsonEncode(jooble));
  }
}

/// "GB: abc123" lines as {"GB": "abc123"}; country names work too.
Map<String, String> joobleKeysIn(String text) => {
  for (final line in text.split('\n'))
    if (RegExp(r'^\s*([^:=]+?)\s*[:=]\s*(\S+)\s*$').firstMatch(line) case final m?)
      if (countryCode(m[1]!) case final cc when cc.isNotEmpty) cc: m[2]!,
};

List<JobFeed> allFeeds(http.Client client, FeedKeys keys) => [
  AdzunaFeed(client, appId: keys.adzunaId, appKey: keys.adzunaKey),
  ReedFeed(client, key: keys.reed),
  NhsJobsFeed(client),
  RemotiveFeed(client),
  JobicyFeed(client),
  ArbeitnowFeed(client),
  JobTechFeed(client),
  NavFeed(client),
  UsaJobsFeed(client, key: keys.usajobsKey, email: keys.usajobsEmail),
  JoobleFeed(client, keys: keys.jooble),
  UnVacanciesFeed(client),
];

/// The credit a source's terms ask for on each of its ads, with its link.
const feedCredits = <String, ({String label, String url})>{
  'adzuna': (label: 'Jobs by Adzuna', url: adzunaHome),
  'jooble': (label: 'Jobs by Jooble', url: 'https://jooble.org'),
  'usajobs': (label: 'From USAJOBS (not endorsed by OPM)', url: 'https://www.usajobs.gov'),
  'jobtech': (
    label: 'From Platsbanken, Arbetsförmedlingen',
    url: 'https://arbetsformedlingen.se/platsbanken',
  ),
  'nav': (label: 'From arbeidsplassen.no, NAV', url: 'https://arbeidsplassen.nav.no'),
  'unvacancies': (label: 'Via unvacancies.org (not part of the UN)', url: 'https://unvacancies.org'),
};

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// The closing date an advert's text states ("Closing date: 17 November
/// 2026", "Closes 17/11/2026"), as yyyy-MM-dd, or null.
String? closingIn(String text) {
  final m = RegExp(
    r'clos(?:ing date|es|ing)\s*:?\s*(?:on\s+)?(?:[A-Za-z]+day\s+)?'
    r'(?:(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})|(\d{1,2})/(\d{1,2})/(\d{4}))',
    caseSensitive: false,
  ).firstMatch(text);
  if (m == null) return null;
  final (day, month, year) = m[1] != null
      ? (int.parse(m[1]!), _months[m[2]!.substring(0, 3).toLowerCase()], int.parse(m[3]!))
      : (int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!));
  if (month == null || month > 12 || day < 1 || day > 31) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '$year-${two(month)}-${two(day)}';
}

/// The yearly salary range an advert's text states ("£28,392 to £31,157 a
/// year", "£28,392 - £31,157"), or nulls.
(int?, int?) salaryIn(String text) {
  final m = RegExp(r'£\s?([\d,]{5,})(?:\.\d+)?(?:\s*(?:to|-|–)\s*£\s?([\d,]{5,}))?').firstMatch(text);
  if (m == null) return (null, null);
  int? n(String? x) => x == null ? null : int.tryParse(x.replaceAll(',', ''));
  final low = n(m[1]);
  if (low == null || low < 1000) return (null, null);
  return (low, n(m[2]) ?? low);
}

/// The yyyy-MM-dd of an RFC 822 date ("Thu, 19 Nov 2026 00:00:00 GMT"), or
/// null.
String? rfc822Day(String s) {
  final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})').firstMatch(s);
  if (m == null) return _date(s);
  final month = _months[m[2]!.toLowerCase()];
  if (month == null) return null;
  return '${m[3]}-${month.toString().padLeft(2, '0')}-${m[1]!.padLeft(2, '0')}';
}

/// JobTech JobSearch: Sweden's public employment service (Platsbanken),
/// no key.
class JobTechFeed extends JobFeed {
  JobTechFeed(this.client);
  final http.Client client;

  @override
  String get id => 'jobtech';
  @override
  String get name => 'Platsbanken (JobTech)';
  @override
  int? get maxTerms => 3;
  @override
  bool covers(FeedQuery q) => q.country == 'SE';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final out = <Posting>[];
    for (final term in q.terms) {
      final uri = Uri.https('jobsearch.api.jobtechdev.se', '/search', {'q': term, 'limit': '50'});
      out.addAll(parse(obj(await _getJson(client, uri))));
    }
    return out;
  }

  /// The postings in one /search reply.
  static List<Posting> parse(Json body) => [
    for (final h in objs(body['hits']))
      if (h['removed'] != true && str(h['headline']).isNotEmpty)
        Posting(
          source: 'jobtech',
          sourceId: str(h['id']),
          title: str(h['headline']),
          company: str(obj(h['employer'])['name']).isNotEmpty
              ? str(obj(h['employer'])['name'])
              : str(obj(h['employer'])['workplace']),
          location: [
            str(obj(h['workplace_address'])['municipality']),
            str(obj(h['workplace_address'])['region']),
          ].where((x) => x.isNotEmpty).toSet().join(', '),
          country: 'SE',
          salaryText: str(h['salary_description']),
          url: str(h['webpage_url']).isNotEmpty
              ? str(h['webpage_url'])
              : str(obj(h['application_details'])['url']),
          description: str(obj(h['description'])['text']),
          posted: _date(h['publication_date']),
          closing: _date(h['application_deadline']),
        ),
  ];
}

/// NAV's job vacancy feed (Norway, arbeidsplassen.no). It is a stream of
/// changes, not a search: Udyoga reads the last two days' pages with NAV's
/// public token (which rotates, so it is fetched each run), keeps the open
/// ads whose title matches, and reads those in full. Contact details are
/// never kept.
class NavFeed extends JobFeed {
  NavFeed(this.client, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final http.Client client;
  final DateTime Function() _clock;

  static const host = 'pam-stilling-feed.nav.no';

  /// Pages of up to 1,000 changes read per run, and ads read in full.
  static const pages = 3, details = 15;

  @override
  String get id => 'nav';
  @override
  String get name => 'NAV (arbeidsplassen.no)';

  /// One download filtered here, so any number of terms.
  @override
  int? get maxTerms => null;
  @override
  bool covers(FeedQuery q) => q.country == 'NO';

  /// The token in NAV's public-token page.
  static String tokenIn(String text) =>
      RegExp(r'[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}').firstMatch(text)?[0] ?? '';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final t = await client.get(Uri.https(host, '/api/publicToken')).timeout(const Duration(seconds: 30));
    if (t.statusCode != 200) throw FeedException('the public token page answered ${t.statusCode}');
    final token = tokenIn(utf8.decode(t.bodyBytes));
    if (token.isEmpty) throw FeedException('the public token page holds no token');
    final auth = {'authorization': 'Bearer $token'};
    final since = HttpDate.format(_clock().toUtc().subtract(const Duration(days: 2)));
    final entries = <Json>[];
    var path = '/api/v1/feed';
    for (var i = 0; i < pages; i++) {
      final page = obj(
        await _getJson(
          client,
          Uri.https(host, path),
          headers: {...auth, if (i == 0) 'if-modified-since': since},
        ),
      );
      entries.addAll(matching(page, q.terms));
      final next = str(page['next_url']);
      if (next.isEmpty || next == path) break;
      path = next;
    }
    final out = <Posting>[];
    final seen = <String>{};
    for (final e in entries) {
      final f = obj(e['_feed_entry']);
      if (!seen.add(str(f['uuid']))) continue;
      if (out.length >= details) break;
      try {
        out.add(parseEntry(obj(await _getJson(client, Uri.https(host, str(e['url'])), headers: auth))));
      } on FeedException {
        out.add(_brief(f));
      }
    }
    return out;
  }

  /// The open ads on a feed page whose title matches [terms].
  static List<Json> matching(Json page, List<String> terms) => [
    for (final e in objs(page['items']))
      if (str(obj(e['_feed_entry'])['status']) == 'ACTIVE' && _mentions(str(e['title']), terms)) e,
  ];

  static Posting _brief(Json f) => Posting(
    source: 'nav',
    sourceId: str(f['uuid']),
    title: str(f['title']),
    company: str(f['businessName']),
    location: _town(str(f['municipal'])),
    country: 'NO',
    url: 'https://arbeidsplassen.nav.no/stillinger/stilling/${str(f['uuid'])}',
  );

  /// "TRONDHEIM" as "Trondheim".
  static String _town(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// One ad in full (a /feedentry reply); its contacts are left out.
  static Posting parseEntry(Json entry) {
    final ad = obj(entry['ad_content']);
    final place = objs(ad['workLocations']).firstOrNull ?? const <String, Object?>{};
    return Posting(
      source: 'nav',
      sourceId: str(ad['uuid']).isNotEmpty ? str(ad['uuid']) : str(entry['uuid']),
      title: str(ad['title']),
      company: str(obj(ad['employer'])['name']),
      location: _town(str(place['city']).isNotEmpty ? str(place['city']) : str(place['municipal'])),
      country: 'NO',
      url: str(ad['link']).isNotEmpty
          ? str(ad['link'])
          : 'https://arbeidsplassen.nav.no/stillinger/stilling/${str(ad['uuid'])}',
      description: htmlToText(str(ad['description'])),
      posted: _date(ad['published']),
      closing: _date(ad['applicationDue']) ?? _date(ad['expires']),
    );
  }
}

/// USAJOBS: US federal jobs, with the user's own free key. Its rules: the
/// registered e-mail goes as the User-Agent, the key stays private, and
/// nothing may suggest OPM endorses Udyoga.
class UsaJobsFeed extends JobFeed {
  UsaJobsFeed(this.client, {required this.key, required this.email});
  final http.Client client;
  final String key, email;

  @override
  String get id => 'usajobs';
  @override
  String get name => 'USAJOBS';
  @override
  int? get maxTerms => 3;
  @override
  bool get usesPlace => true;
  @override
  bool covers(FeedQuery q) => key.isNotEmpty && email.isNotEmpty && q.country == 'US';

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final out = <Posting>[];
    for (final term in q.terms) {
      final uri = Uri.https('data.usajobs.gov', '/api/search', {
        'Keyword': term,
        'ResultsPerPage': '50',
        if (q.place.isNotEmpty) 'LocationName': q.place,
        if (q.place.isNotEmpty && q.radiusMiles != null) 'Radius': '${q.radiusMiles}',
      });
      out.addAll(
        parse(
          obj(
            await _getJson(
              client,
              uri,
              headers: {'host': 'data.usajobs.gov', 'user-agent': email, 'authorization-key': key},
            ),
          ),
        ),
      );
    }
    return out;
  }

  static List<Posting> parse(Json body) => [
    for (final item in objs(obj(body['SearchResult'])['SearchResultItems']))
      if (obj(item['MatchedObjectDescriptor']) case final d when str(d['PositionTitle']).isNotEmpty)
        () {
          final pay = objs(d['PositionRemuneration']).firstOrNull ?? const <String, Object?>{};
          final yearly = str(pay['RateIntervalCode']) == 'PA';
          final min = intOf(pay['MinimumRange']), max = intOf(pay['MaximumRange']);
          return Posting(
            source: 'usajobs',
            sourceId: str(item['MatchedObjectId']).isNotEmpty
                ? str(item['MatchedObjectId'])
                : str(d['PositionID']),
            title: str(d['PositionTitle']),
            company: [
              str(d['OrganizationName']),
              str(d['DepartmentName']),
            ].where((x) => x.isNotEmpty).toSet().join(', '),
            location: str(d['PositionLocationDisplay']),
            country: 'US',
            salaryMin: yearly ? min : null,
            salaryMax: yearly ? max : null,
            currency: yearly && min != null ? 'USD' : '',
            salaryText: !yearly && min != null
                ? 'USD $min–${max ?? min} ${str(pay['Description'])}'.trim()
                : '',
            url: str(d['PositionURI']),
            description: htmlToText(str(obj(obj(d['UserArea'])['Details'])['JobSummary'])),
            posted: _date(d['PublicationStartDate']),
            closing: _date(d['ApplicationCloseDate']),
          );
        }(),
  ];
}

/// Jooble: many countries, one free key per country site (jooble.org is
/// the US; uk.jooble.org the UK, and so on), 100 calls a day each.
class JoobleFeed extends JobFeed {
  JoobleFeed(this.client, {required this.keys});
  final http.Client client;
  final Map<String, String> keys;

  @override
  String get id => 'jooble';
  @override
  String get name => 'Jooble';

  /// Two searches a run: each key has 100 calls a day.
  @override
  int? get maxTerms => 2;
  @override
  bool get usesPlace => true;
  @override
  bool covers(FeedQuery q) => keys[q.country]?.isNotEmpty ?? false;

  /// The country's Jooble site.
  static String hostFor(String cc) => switch (cc) {
    'US' => 'jooble.org',
    'GB' => 'uk.jooble.org',
    _ => '${cc.toLowerCase()}.jooble.org',
  };

  /// Jooble takes only these radii (km).
  static String radiusKm(int miles) {
    final km = miles * 1.609;
    return const [0, 4, 8, 16, 26, 40, 80].firstWhere((r) => r >= km, orElse: () => 80).toString();
  }

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final out = <Posting>[];
    for (final term in q.terms) {
      final r = await client
          .post(
            Uri.https(hostFor(q.country), '/api/${keys[q.country]}'),
            headers: {'content-type': 'application/json', 'accept': 'application/json'},
            body: jsonEncode({
              'keywords': term,
              'location': q.place.isNotEmpty ? q.place : worldCountry(q.country)?.name ?? q.country,
              if (q.place.isNotEmpty && q.radiusMiles != null) 'radius': radiusKm(q.radiusMiles!),
              'page': '1',
              'ResultOnPage': '30',
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 403) throw FeedException('the key was rejected');
      if (r.statusCode == 429) throw FeedException("used up today's calls");
      if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
      final Object? body;
      try {
        body = jsonDecode(utf8.decode(r.bodyBytes));
      } on FormatException {
        throw FeedException('sent a reply that is not job data (a Wi-Fi sign-in page, or the site changed)');
      }
      out.addAll(parse(obj(body), country: q.country));
    }
    return out;
  }

  static List<Posting> parse(Json body, {required String country}) => [
    for (final j in objs(body['jobs']))
      if (str(j['title']).isNotEmpty)
        Posting(
          source: 'jooble',
          sourceId: str(j['id']),
          title: htmlToText(str(j['title'])),
          company: str(j['company']),
          location: str(j['location']),
          country: country,
          salaryText: str(j['salary']),
          url: str(j['link']),
          description: htmlToText(str(j['snippet'])),
          posted: _date(j['updated']),
        ),
  ];
}

/// unvacancies.org: an independent index of 45 UN-system career sites, no
/// key or agreement needed; every job is applied for on the official
/// portal. Its feed holds the newest 50, filtered here.
class UnVacanciesFeed extends JobFeed {
  UnVacanciesFeed(this.client);
  final http.Client client;

  @override
  String get id => 'unvacancies';
  @override
  String get name => 'UN jobs (unvacancies.org)';

  /// One download filtered here, so any number of terms.
  @override
  int? get maxTerms => null;

  /// Not tied to a country, so it answers the country-less query.
  @override
  bool covers(FeedQuery q) => q.country.isEmpty;

  @override
  Future<List<Posting>> search(FeedQuery q) async {
    final r = await client
        .get(Uri.https('unvacancies.org', '/feed.xml'), headers: {'accept': 'application/rss+xml'})
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
    return [
      for (final p in parse(utf8.decode(r.bodyBytes)))
        if (holdsWords('${p.title}\n${p.description}', q.terms)) p,
    ];
  }

  static List<Posting> parse(String body) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(body);
    } on XmlException {
      throw FeedException('sent a reply that is not job data (a Wi-Fi sign-in page, or the site changed)');
    }
    String text(XmlElement e, String name) => e.getElement(name)?.innerText.trim() ?? '';
    return [
      for (final item in doc.findAllElements('item'))
        if (text(item, 'title').isNotEmpty)
          () {
            final link = text(item, 'link').replaceFirst(RegExp(r'\?utm_.*$'), '');
            final guid = text(item, 'guid').isNotEmpty ? text(item, 'guid') : link;
            return Posting(
              source: 'unvacancies',
              sourceId: guid.split('/').last.replaceFirst(RegExp(r'\?.*$'), ''),
              title: htmlToText(text(item, 'title')),
              company: text(item, 'category'),
              url: link,
              description: htmlToText(text(item, 'description')),
              posted: rfc822Day(text(item, 'pubDate')),
            );
          }(),
    ];
  }
}
