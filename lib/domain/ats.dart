import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'book.dart';
import 'employers.dart';
import 'feeds.dart';
import 'json.dart';
import 'polite.dart';
import 'profile.dart';
import 'work_rights.dart';

/// The job-board systems with a public, published job API (Workday's is
/// the one its own careers sites call).
enum AtsKind {
  greenhouse('Greenhouse'),
  lever('Lever'),
  ashby('Ashby'),
  smartrecruiters('SmartRecruiters'),
  workday('Workday');

  const AtsKind(this.label);
  final String label;
}

/// One employer's board on a job-board system.
class AtsBoard {
  const AtsBoard(this.kind, this.token, {this.host = '', this.site = ''});
  final AtsKind kind;

  /// The board's name on the system (Workday: the tenant).
  final String token;

  /// Workday: the careers host and site; Lever: the EU host when it is one.
  final String host, site;

  factory AtsBoard.fromJson(Json j) => AtsBoard(
    AtsKind.values.firstWhere((k) => k.name == str(j['kind']), orElse: () => AtsKind.greenhouse),
    str(j['token']),
    host: str(j['host']),
    site: str(j['site']),
  );

  Json toJson() => {'kind': kind.name, 'token': token, 'host': host, 'site': site};

  @override
  bool operator ==(Object other) =>
      other is AtsBoard &&
      other.kind == kind &&
      other.token == token &&
      other.host == host &&
      other.site == site;

  @override
  int get hashCode => Object.hash(kind, token, host, site);

  @override
  String toString() => '${kind.label} board "$token"';
}

final _boardPatterns = <(RegExp, AtsBoard Function(Match))>[
  (
    RegExp(
      r'(?:boards|job-boards)(?:\.eu)?\.greenhouse\.io/(?:embed/job_board(?:/js)?\?for=)?([A-Za-z0-9_-]+)',
    ),
    (m) => AtsBoard(AtsKind.greenhouse, m[1]!),
  ),
  (
    RegExp(r'boards-api\.greenhouse\.io/v1/boards/([A-Za-z0-9_-]+)'),
    (m) => AtsBoard(AtsKind.greenhouse, m[1]!),
  ),
  (
    RegExp(r'(?:jobs|api)\.(eu\.)?lever\.co/(?:v0/postings/)?([A-Za-z0-9_.-]+)'),
    (m) => AtsBoard(AtsKind.lever, m[2]!, host: m[1] == null ? '' : 'api.eu.lever.co'),
  ),
  (
    RegExp(r'jobs\.ashbyhq\.com/([A-Za-z0-9_.%-]+)'),
    (m) => AtsBoard(AtsKind.ashby, Uri.decodeComponent(m[1]!)),
  ),
  (
    RegExp(r'api\.ashbyhq\.com/posting-api/job-board/([A-Za-z0-9_.%-]+)'),
    (m) => AtsBoard(AtsKind.ashby, Uri.decodeComponent(m[1]!)),
  ),
  (
    RegExp(r'(?:careers|jobs)\.smartrecruiters\.com/([A-Za-z0-9_-]+)'),
    (m) => AtsBoard(AtsKind.smartrecruiters, m[1]!),
  ),
  (
    RegExp(r'api\.smartrecruiters\.com/v1/companies/([A-Za-z0-9_-]+)'),
    (m) => AtsBoard(AtsKind.smartrecruiters, m[1]!),
  ),
  (
    RegExp(r'(([A-Za-z0-9-]+)\.wd\d+\.myworkdayjobs\.com)/(?:[a-z]{2}-[A-Z]{2}/)?([A-Za-z0-9_-]+)'),
    (m) => AtsBoard(AtsKind.workday, m[2]!, host: m[1]!, site: m[3]!),
  ),
];

/// Board paths that are not a board name.
const _notBoards = {'embed', 'jobs', 'v1', 'v0', 'api', 'job', 'wday', 'en-US', 'search', 'apply'};

/// The board a careers or job-board link points at, or null.
AtsBoard? atsFromUrl(String url) {
  for (final (re, make) in _boardPatterns) {
    final m = re.firstMatch(url);
    if (m == null) continue;
    final b = make(m);
    if (b.token.isNotEmpty && !_notBoards.contains(b.token) && !_notBoards.contains(b.site)) return b;
  }
  return null;
}

/// The first job board linked or embedded in a careers page, or null.
AtsBoard? atsInHtml(String html) {
  for (final m in RegExp(r'''(?:href|src|action|data-[a-z-]+)\s*=\s*["']([^"']+)["']''').allMatches(html)) {
    final b = atsFromUrl(m[1]!.replaceAll('&amp;', '&'));
    if (b != null) return b;
  }
  return atsFromUrl(html);
}

/// The JobPosting entries in a page's JSON-LD (schema.org) markup, as
/// postings for [employer].
List<Posting> jobPostingsIn(String html, {required String pageUrl, String employer = ''}) {
  final out = <Posting>[];
  void visit(Object? v) {
    if (v is List) {
      v.forEach(visit);
      return;
    }
    if (v is! Map) return;
    final j = v.cast<String, Object?>();
    final type = j['@type'];
    final types = type is List ? type.map(str) : [str(type)];
    if (types.contains('JobPosting')) {
      final p = _jobPosting(j, pageUrl: pageUrl, employer: employer);
      if (p != null) out.add(p);
      return;
    }
    visit(j['@graph']);
    visit(j['itemListElement']);
    if (types.contains('ListItem')) visit(j['item']);
  }

  for (final m in RegExp(
    r'''<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>''',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html)) {
    try {
      visit(jsonDecode(m[1]!.trim()));
    } on FormatException {
      continue;
    }
  }
  return out;
}

/// A schema.org JobPosting object as a posting, or null without a title.
Posting? jobPostingFromLd(Json j, {required String pageUrl, String employer = ''}) =>
    _jobPosting(j, pageUrl: pageUrl, employer: employer);

/// The JSON-LD script bodies in [html].
List<String> ldScriptsIn(String html) => [
  for (final m in RegExp(
    r'''<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>''',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html))
    m[1]!.trim(),
];

/// Every typed object in JSON-LD [scripts]: top-level ones, those in an
/// @graph, and the items of an ItemList. Scripts that do not parse are
/// skipped.
List<Json> ldObjects(Iterable<String> scripts) {
  final out = <Json>[];
  void visit(Object? v) {
    if (v is List) {
      v.forEach(visit);
      return;
    }
    if (v is! Map) return;
    final j = v.cast<String, Object?>();
    if (j['@type'] != null) out.add(j);
    visit(j['@graph']);
    visit(j['itemListElement']);
    if (ldTypes(j).contains('ListItem')) visit(j['item']);
  }

  for (final s in scripts) {
    try {
      visit(jsonDecode(s));
    } on FormatException {
      continue;
    }
  }
  return out;
}

/// The @type of a JSON-LD object, as a list.
List<String> ldTypes(Json j) {
  final t = j['@type'];
  return t is List ? [for (final x in t) str(x)] : [str(t)];
}

Posting? _jobPosting(Json j, {required String pageUrl, required String employer}) {
  final title = htmlToText(str(j['title']));
  if (title.isEmpty) return null;
  final org = j['hiringOrganization'];
  final company = org is Map ? str(org['name']) : str(org);
  final places = j['jobLocation'] is List ? objs(j['jobLocation']) : [obj(j['jobLocation'])];
  final address = obj(places.firstOrNull?['address']);
  final country = address['addressCountry'] is Map
      ? str(obj(address['addressCountry'])['name'])
      : str(address['addressCountry']);
  final salary = obj(j['baseSalary']);
  final value = obj(salary['value']);
  final unit = str(value['unitText']).toUpperCase();
  final yearly = unit.isEmpty || unit == 'YEAR';
  final min = intOf(value['minValue'] ?? value['value']), max = intOf(value['maxValue']);
  final id = j['identifier'] is Map ? str(obj(j['identifier'])['value']) : str(j['identifier']);
  final url = str(j['url']).isNotEmpty ? Uri.parse(pageUrl).resolve(str(j['url'])).toString() : pageUrl;
  String? day(Object? v) {
    final s = str(v);
    return s.length >= 10 && isDay(s.substring(0, 10)) ? s.substring(0, 10) : null;
  }

  return Posting(
    source: 'careers',
    sourceId: id.isNotEmpty ? id : url,
    title: title,
    company: employer.isNotEmpty ? employer : company,
    location: [
      str(address['addressLocality']),
      str(address['addressRegion']),
    ].where((x) => x.isNotEmpty).join(', '),
    country: countryCode(country),
    remote: str(j['jobLocationType']).toUpperCase() == 'TELECOMMUTE',
    salaryMin: yearly ? min : null,
    salaryMax: yearly ? (max ?? min) : null,
    currency: yearly && min != null ? str(salary['currency']) : '',
    url: url,
    description: htmlToText(str(j['description'])),
    posted: day(j['datePosted']),
    closing: day(j['validThrough']),
  );
}

/// Whether robots.txt lets [agent] fetch [path]: the group naming the agent,
/// else the "*" group; the longest matching rule wins, Allow on a tie.
bool robotsAllows(String robots, String path, {String agent = 'udyoga'}) {
  final groups = <List<String>, List<(bool, String)>>{};
  var agents = <String>[];
  var rules = <(bool, String)>[];
  var inRules = false;
  for (final raw in robots.split('\n')) {
    final line = raw.replaceFirst(RegExp(r'#.*$'), '').trim();
    final m = RegExp(r'^([A-Za-z-]+)\s*:\s*(.*)$').firstMatch(line);
    if (m == null) continue;
    final key = m[1]!.toLowerCase(), value = m[2]!.trim();
    if (key == 'user-agent') {
      if (inRules) {
        agents = [];
        rules = [];
        inRules = false;
      }
      agents.add(value.toLowerCase());
      groups[agents] = rules;
    } else if (key == 'allow' || key == 'disallow') {
      inRules = true;
      if (agents.isEmpty) continue;
      if (value.isNotEmpty) rules.add((key == 'allow', value));
    }
  }
  final me = agent.toLowerCase();
  final mine =
      groups.entries.where((g) => g.key.any((a) => a != '*' && me.contains(a))).firstOrNull ??
      groups.entries.where((g) => g.key.contains('*')).firstOrNull;
  if (mine == null) return true;
  (bool, String)? best;
  for (final r in mine.value) {
    final pattern = RegExp('^${RegExp.escape(r.$2).replaceAll(r'\*', '.*').replaceAll(r'\$', r'$')}');
    if (!pattern.hasMatch(path)) continue;
    if (best == null || r.$2.length > best.$2.length || (r.$2.length == best.$2.length && r.$1)) best = r;
  }
  return best?.$1 ?? true;
}

/// How Udyoga names itself to careers sites.
const politeAgent =
    'Udyoga/1.0 (personal job search; +https://github.com/sudharamachandranrajeev/udyoga-career-manager)';

/// Reads job boards' public APIs.
class AtsClient {
  AtsClient(this.client);
  final http.Client client;

  Future<Object?> _json(Uri uri, {String? post}) async {
    final headers = {'accept': 'application/json', 'user-agent': politeAgent};
    final r =
        await (post == null
                ? client.get(uri, headers: headers)
                : client.post(uri, headers: {...headers, 'content-type': 'application/json'}, body: post))
            .timeout(const Duration(seconds: 30));
    if (r.statusCode == 404) throw FeedException('no such board');
    if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      throw FeedException('sent a reply that is not job data');
    }
  }

  /// The board's open jobs, one request, as postings for [employer].
  Future<List<Posting>> jobs(AtsBoard b, {required String employer}) async => switch (b.kind) {
    AtsKind.greenhouse => parseGreenhouse(
      obj(await _json(Uri.https('boards-api.greenhouse.io', '/v1/boards/${b.token}/jobs'))),
      employer: employer,
    ),
    AtsKind.lever => parseLever(
      await _json(
        Uri.https(b.host.isEmpty ? 'api.lever.co' : b.host, '/v0/postings/${b.token}', {'mode': 'json'}),
      ),
      employer: employer,
    ),
    AtsKind.ashby => parseAshby(
      obj(
        await _json(
          Uri.https('api.ashbyhq.com', '/posting-api/job-board/${b.token}', {'includeCompensation': 'true'}),
        ),
      ),
      employer: employer,
    ),
    AtsKind.smartrecruiters => parseSmartRecruiters(
      obj(
        await _json(
          Uri.https('api.smartrecruiters.com', '/v1/companies/${b.token}/postings', {'limit': '100'}),
        ),
      ),
      employer: employer,
    ),
    AtsKind.workday => parseWorkday(
      obj(
        await _json(
          Uri.https(b.host, '/wday/cxs/${b.token}/${b.site}/jobs'),
          post: jsonEncode({
            'appliedFacets': <String, Object?>{},
            'limit': 20,
            'offset': 0,
            'searchText': '',
          }),
        ),
      ),
      board: b,
      employer: employer,
    ),
  };

  static String? _day(Object? v) {
    final s = str(v);
    return s.length >= 10 && isDay(s.substring(0, 10)) ? s.substring(0, 10) : null;
  }

  static List<Posting> parseGreenhouse(Json body, {required String employer}) => [
    for (final j in objs(body['jobs']))
      if (str(j['title']).isNotEmpty)
        Posting(
          source: 'greenhouse',
          sourceId: str(j['id']),
          title: str(j['title']),
          company: employer.isNotEmpty ? employer : str(j['company_name']),
          location: str(obj(j['location'])['name']),
          remote: str(obj(j['location'])['name']).toLowerCase().contains('remote'),
          url: str(j['absolute_url']),
          description: htmlToText(htmlToText(str(j['content']))),
          posted: _day(j['first_published']) ?? _day(j['updated_at']),
        ),
  ];

  static List<Posting> parseLever(Object? body, {required String employer}) => [
    for (final j in objs(body))
      if (str(j['text']).isNotEmpty)
        Posting(
          source: 'lever',
          sourceId: str(j['id']),
          title: str(j['text']),
          company: employer,
          location: str(obj(j['categories'])['location']),
          country: str(j['country']).toUpperCase(),
          remote: str(j['workplaceType']) == 'remote',
          salaryMin: str(obj(j['salaryRange'])['interval']).contains('year')
              ? intOf(obj(j['salaryRange'])['min'])
              : null,
          salaryMax: str(obj(j['salaryRange'])['interval']).contains('year')
              ? intOf(obj(j['salaryRange'])['max'])
              : null,
          currency: str(obj(j['salaryRange'])['interval']).contains('year')
              ? str(obj(j['salaryRange'])['currency'])
              : '',
          url: str(j['hostedUrl']),
          description: str(j['descriptionPlain']),
          posted: switch (intOf(j['createdAt'])) {
            final t? => DateTime.fromMillisecondsSinceEpoch(
              t,
              isUtc: true,
            ).toIso8601String().substring(0, 10),
            null => null,
          },
        ),
  ];

  static List<Posting> parseAshby(Json body, {required String employer}) => [
    for (final j in objs(body['jobs']))
      if (str(j['title']).isNotEmpty && j['isListed'] != false)
        Posting(
          source: 'ashby',
          sourceId: str(j['id']),
          title: str(j['title']),
          company: employer,
          location: str(j['location']),
          country: countryCode(str(obj(obj(j['address'])['postalAddress'])['addressCountry'])),
          remote: j['isRemote'] == true,
          salaryText: str(obj(j['compensation'])['compensationTierSummary']),
          url: str(j['jobUrl']),
          description: str(j['descriptionPlain']),
          posted: _day(j['publishedAt']),
        ),
  ];

  static List<Posting> parseSmartRecruiters(Json body, {required String employer}) => [
    for (final j in objs(body['content']))
      if (str(j['name']).isNotEmpty)
        Posting(
          source: 'smartrecruiters',
          sourceId: str(j['id']),
          title: str(j['name']),
          company: employer.isNotEmpty ? employer : str(obj(j['company'])['name']),
          location: str(obj(j['location'])['fullLocation']),
          country: str(obj(j['location'])['country']).toUpperCase(),
          remote: obj(j['location'])['remote'] == true,
          url: 'https://jobs.smartrecruiters.com/${str(obj(j['company'])['identifier'])}/${str(j['id'])}',
          posted: _day(j['releasedDate']),
        ),
  ];

  static List<Posting> parseWorkday(Json body, {required AtsBoard board, required String employer}) => [
    for (final j in objs(body['jobPostings']))
      if (str(j['title']).isNotEmpty)
        Posting(
          source: 'workday',
          sourceId: strs(j['bulletFields']).firstOrNull ?? str(j['externalPath']),
          title: str(j['title']),
          company: employer,
          location: str(j['locationsText']),
          remote: str(j['remoteType']).toLowerCase() == 'remote',
          url: 'https://${board.host}/${board.site}${str(j['externalPath'])}',
        ),
  ];
}

/// What one employer-watch run found.
class WatchResult {
  final postings = <Posting>[];
  final problems = <String>[];

  /// Sources asked, and how many failed.
  var asked = 0, failed = 0;
}

/// Device-only keys for the watch: the board found on a careers page, when
/// a page was last read, and each site's robots.txt.
abstract final class WatchKeys {
  static String board(String id) => 'udyoga.watch.board.$id';
  static String page(String url) => 'udyoga.watch.page.${Uri.tryParse(url)?.host ?? url}';
  static String robots(String host) => 'udyoga.robots.$host';
}

/// Checks the watched employers: NHS ones through NHS Jobs (by their
/// keywords, nationwide, kept when the employer matches); the rest through
/// their job board's public API, found from the careers link. A careers
/// page with no known board is read for its JobPosting markup, politely:
/// at most once a day, one request per site, only where robots.txt allows,
/// with its robots.txt kept for a week.
class EmployerWatch {
  EmployerWatch(this.book, this.client, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final CareerBook book;
  final http.Client client;
  final DateTime Function() _clock;

  static const pageEvery = Duration(days: 1);

  Future<WatchResult> run(CandidateProfile p, List<WatchedEmployer> watched) async {
    final out = WatchResult();
    if (watched.isEmpty) return out;
    final ats = AtsClient(client);
    bool wanted(WatchedEmployer e, Posting j) {
      final terms = e.keywords.isNotEmpty ? e.keywords : p.searchTerms;
      return terms.isEmpty || mentionsAny('${j.title} ${j.description}', terms);
    }

    // NHS employers: their keywords searched once, nationwide.
    final nhs = watched.where((e) => e.nhs && e.keywords.isNotEmpty).toList();
    if (nhs.isNotEmpty) {
      out.asked++;
      try {
        final terms = {for (final e in nhs) ...e.keywords}.take(4).toList();
        for (final j in await NhsJobsFeed(client).search(FeedQuery(terms: terms, country: 'GB'))) {
          if (nhs.any((e) => e.matches(j.company) && wanted(e, j))) out.postings.add(j);
        }
      } on Object catch (e) {
        out.failed++;
        out.problems.add('NHS Jobs (watched employers): ${feedProblem(e)}');
      }
    }

    final read = <String>{};
    for (final e in watched) {
      for (final url in e.urls) {
        var board = atsFromUrl(url);
        if (board == null) {
          final cached = decodeObject(await book.db.localSetting(WatchKeys.board(e.id)) ?? '');
          if (cached.isNotEmpty) board = AtsBoard.fromJson(cached);
        }
        try {
          if (board == null) {
            final host = Uri.parse(url).host;
            if (!read.add(host) || !await _due(url)) continue;
            out.asked++;
            final page = await _page(url);
            board = atsInHtml(page);
            if (board != null) {
              await book.db.setLocalSetting(WatchKeys.board(e.id), jsonEncode(board.toJson()));
            } else {
              out.postings.addAll(
                jobPostingsIn(page, pageUrl: url, employer: e.name).where((j) => wanted(e, j)),
              );
              continue;
            }
          }
          out.asked++;
          out.postings.addAll((await ats.jobs(board, employer: e.name)).where((j) => wanted(e, j)));
        } on Object catch (x) {
          out.failed++;
          out.problems.add('${e.name}: ${feedProblem(x)}');
        }
      }
    }
    return out;
  }

  /// True when the careers page at [url] was not read in the last day.
  Future<bool> _due(String url) async {
    final last = DateTime.tryParse(await book.db.localSetting(WatchKeys.page(url)) ?? '');
    return last == null || _clock().difference(last) >= pageEvery;
  }

  /// The careers page at [url]; throws when robots.txt asks not to read it.
  /// The day's read is recorded once the site answers.
  Future<String> _page(String url) => PoliteFetcher(book.db, client, clock: _clock).get(
    Uri.parse(url),
    onAnswer: () => book.db.setLocalSetting(WatchKeys.page(url), _clock().toIso8601String()),
  );
}
