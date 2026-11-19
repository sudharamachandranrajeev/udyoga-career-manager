/// Site recipes: small JSON files, kept in a folder the user picks (the
/// career file's recipes/ folder), that teach Udyoga one site. Udyoga ships
/// the engine only; it holds no recipe of its own. docs/recipes.md is the
/// schema.
///
/// A recipe runs in one of three modes:
/// - fetch: reads the site in the background through the politeness layer
///   (robots.txt, a gap between requests, a daily cap). Never for the sites
///   on [fetchDenied].
/// - browser-read: reads a page the user has open in Udyoga's browser.
/// - assist-fill: puts a draft the user approved into a text box on the
///   open page. It never presses anything (see assist_fill.dart).
library;

import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'ats.dart';
import 'feeds.dart';
import 'json.dart';
import 'page_reader.dart';
import 'polite.dart';
import 'profile.dart';

/// A recipe that does not follow the schema.
class RecipeException implements Exception {
  RecipeException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum RecipeMode {
  fetch('fetch', 'Background fetch'),
  browserRead('browser-read', 'Reads pages you open'),
  assistFill('assist-fill', 'Fills a text box for you');

  const RecipeMode(this.id, this.label);
  final String id, label;

  static RecipeMode? of(String s) => values.where((m) => m.id == s).firstOrNull;
}

/// Sites never read in the background, whatever a recipe says: they forbid
/// it. Only what the user opens in Udyoga's browser is read there.
const fetchDenied = ['linkedin.com', 'indeed.*', 'glassdoor.*'];

/// LinkedIn fills are capped at this many a day, whatever a recipe says.
const linkedInDailyCeiling = 15;

/// True when [host] is [rule] or under it; "indeed.*" matches any ending
/// (indeed.com, uk.indeed.com, indeed.co.uk).
bool hostMatches(String host, String rule) {
  final h = host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  if (rule.endsWith('.*')) {
    final name = rule.substring(0, rule.length - 2);
    return RegExp('(^|\\.)${RegExp.escape(name)}\\.[a-z.]+\$').hasMatch(h);
  }
  return h == rule || h.endsWith('.$rule');
}

bool isFetchDenied(String host) => fetchDenied.any((r) => hostMatches(host, r));
bool isLinkedIn(String host) => hostMatches(host, 'linkedin.com');

/// Where a field's value comes from: a CSS selector (its text, or an
/// attribute with "@href"), or a JSON-LD path ("ld:hiringOrganization.name").
class FieldSource {
  FieldSource(String spec) : spec = spec.trim() {
    if (this.spec.isEmpty) throw RecipeException('a field has no selector');
  }
  final String spec;

  bool get isLd => spec.startsWith('ld:');

  /// The value on [doc] (or in [ld], the JSON-LD object the recipe names).
  String read(dom.Document doc, Json? ld) {
    if (isLd) return ld == null ? '' : _ldPath(ld, spec.substring(3));
    final at = spec.lastIndexOf('@');
    final selector = at > 0 ? spec.substring(0, at).trim() : spec;
    final attr = at > 0 ? spec.substring(at + 1).trim() : '';
    final e = doc.querySelector(selector);
    if (e == null) return '';
    return (attr.isEmpty ? e.text : (e.attributes[attr] ?? '')).replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  static String _ldPath(Json j, String path) {
    Object? v = j;
    for (final part in path.split('.')) {
      if (v is List) v = v.isEmpty ? null : v.first;
      v = v is Map ? v[part] : null;
    }
    if (v is List) v = v.isEmpty ? null : v.first;
    if (v is Map) v = v['name'] ?? v['value'] ?? v['@id'];
    return htmlToText(str(v));
  }
}

/// How a fetch recipe finds pages: a search page ([url], with {terms} for
/// the profile's search terms) and the links on it ([item], an "a"
/// selector, read from [attr]), at most [max] a run.
class RecipeList {
  const RecipeList({required this.url, required this.item, this.attr = 'href', this.max = 10});
  final String url, item, attr;
  final int max;
}

/// How a page becomes a record: the JSON-LD type to read ("JobPosting"),
/// and each field's source.
class RecipeDetail {
  const RecipeDetail({this.jsonLd = '', this.fields = const {}});
  final String jsonLd;
  final Map<String, FieldSource> fields;
}

/// What an assist-fill recipe types, and where.
class RecipeFill {
  const RecipeFill({
    required this.targetSelector,
    required this.templateSource,
    this.template = '',
    this.maxLength = 0,
  });

  /// The text box (a textarea, a text input or a contenteditable element).
  final String targetSelector;

  /// "draft": the draft the user approved in Udyoga (a connection note, a
  /// message). "recipe": [template], with {firstName}, {name}, {company}
  /// and {jobTitle} filled in.
  final String templateSource;
  final String template;

  /// 0: no limit (LinkedIn connection notes allow 200 or 300 characters).
  final int maxLength;
}

/// One validated recipe.
class Recipe {
  const Recipe({
    required this.id,
    required this.site,
    required this.urlPatterns,
    required this.mode,
    required this.rate,
    required this.dailyCap,
    this.name = '',
    this.record = RecordKind.job,
    this.robots = false,
    this.list,
    this.detail = const RecipeDetail(),
    this.fill,
    this.file = '',
  });

  final String id, site, name;
  final List<String> urlPatterns;
  final RecipeMode mode;
  final RecordKind record;

  /// The fewest seconds between two requests (or fills).
  final int rate;
  final int dailyCap;
  final bool robots;
  final RecipeList? list;
  final RecipeDetail detail;
  final RecipeFill? fill;

  /// The file it was read from.
  final String file;

  String get title => name.isNotEmpty ? name : site;

  /// The cap that applies: the recipe's, but never more than
  /// [linkedInDailyCeiling] for a LinkedIn fill.
  int get effectiveCap => mode == RecipeMode.assistFill && isLinkedIn(site) && dailyCap > linkedInDailyCeiling
      ? linkedInDailyCeiling
      : dailyCap;

  /// The key its daily use is counted under.
  String get use => 'recipe.$id';

  Duration get gap => Duration(seconds: rate);

  /// True when [url] is one of this recipe's pages.
  bool matches(String url) => urlPatterns.any((p) => _glob(p).hasMatch(url));

  static RegExp _glob(String pattern) =>
      RegExp('^${pattern.split('*').map(RegExp.escape).join('.*')}\$', caseSensitive: false);

  static const _keys = {
    'id',
    'name',
    'site',
    'urlPatterns',
    'mode',
    'record',
    'rate',
    'dailyCap',
    'robots',
    'list',
    'detail',
    'fill',
    'notes',
  };

  /// A recipe from its JSON, checked strictly: unknown keys or modes, a
  /// missing rate or cap, robots not true for fetch, fetch on a denied
  /// site, pages off the recipe's site, and a fill that is not a text box
  /// are all refused.
  factory Recipe.fromJson(Json j, {String file = ''}) {
    Never bad(String why) => throw RecipeException(why);
    final unknown = j.keys.where((k) => !_keys.contains(k)).toList();
    if (unknown.isNotEmpty) bad('unknown field ${unknown.join(', ')}');

    final id = str(j['id']).trim();
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$').hasMatch(id)) {
      bad('id must be lower-case letters, digits and dashes');
    }
    final site = str(j['site']).trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$').hasMatch(site)) {
      bad('site must be a host name like jobs.example.org');
    }

    final mode = RecipeMode.of(str(j['mode']));
    if (mode == null) bad('mode must be fetch, browser-read or assist-fill (not "${str(j['mode'])}")');

    final rate = j['rate'];
    if (rate is! num || rate < 1) bad('rate (the fewest seconds between requests) is missing or under 1');
    final cap = j['dailyCap'];
    if (cap is! int || cap < 1) bad('dailyCap is missing or under 1');

    if (j.containsKey('robots') && j['robots'] is! bool) bad('robots must be true or false');
    final robots = j['robots'] == true;

    final patterns = j['urlPatterns'];
    if (patterns is! List || patterns.isEmpty || patterns.any((p) => p is! String)) {
      bad('urlPatterns must list at least one address pattern');
    }
    final urls = patterns.cast<String>();
    for (final p in urls) {
      final host = Uri.tryParse(p.replaceAll('*', 'x'))?.host ?? '';
      if (!p.startsWith('https://') && !p.startsWith('http://')) bad('pattern $p must start with https://');
      if (!hostMatches(host, site)) bad('pattern $p is not on $site');
    }

    final record = j.containsKey('record') ? RecordKind.of(str(j['record'])) : RecordKind.job;
    if (record == null) bad('record must be job, person or company');

    final detail = _detail(j['detail'], record, bad);
    RecipeList? list;
    RecipeFill? fill;
    switch (mode) {
      case RecipeMode.fetch:
        if (!robots) bad('a fetch recipe must set "robots": true');
        if (isFetchDenied(site)) bad('$site does not allow programs to read it; use browser-read instead');
        if (rate < 5) bad('a fetch recipe waits at least 5 seconds between requests');
        if (record != RecordKind.job) bad('a fetch recipe reads jobs');
        list = _list(j['list'], site, bad);
        if (detail.fields.isEmpty && detail.jsonLd.isEmpty) {
          bad('a fetch recipe needs detail.jsonLd or detail.fields');
        }
        if (j.containsKey('fill')) bad('only an assist-fill recipe has fill');
      case RecipeMode.browserRead:
        if (detail.fields.isEmpty && detail.jsonLd.isEmpty) {
          bad('a browser-read recipe needs detail.jsonLd or detail.fields');
        }
        if (j.containsKey('fill') || j.containsKey('list')) {
          bad('a browser-read recipe has neither list nor fill');
        }
      case RecipeMode.assistFill:
        fill = _fill(j['fill'], bad);
        if (j.containsKey('list') || j.containsKey('detail')) {
          bad('an assist-fill recipe has neither list nor detail');
        }
    }

    return Recipe(
      id: id,
      name: str(j['name']).trim(),
      site: site,
      urlPatterns: urls,
      mode: mode,
      record: record,
      rate: rate.ceil(),
      dailyCap: cap,
      robots: robots,
      list: list,
      detail: detail,
      fill: fill,
      file: file,
    );
  }

  static RecipeDetail _detail(Object? v, RecordKind record, Never Function(String) bad) {
    if (v == null) return const RecipeDetail();
    if (v is! Map) bad('detail must be an object');
    final d = v.cast<String, Object?>();
    final unknown = d.keys.where((k) => k != 'jsonLd' && k != 'fields');
    if (unknown.isNotEmpty) bad('unknown detail field ${unknown.join(', ')}');
    final f = d['fields'] ?? const {};
    if (f is! Map) bad('detail.fields must be an object');
    final fields = <String, FieldSource>{};
    for (final e in f.entries) {
      final key = str(e.key);
      if (!record.fields.contains(key)) {
        bad('${record.name} has no field "$key" (${record.fields.join(', ')})');
      }
      if (e.value is! String) bad('detail.fields.$key must be a selector or an ld: path');
      fields[key] = FieldSource(e.value as String);
    }
    return RecipeDetail(jsonLd: str(d['jsonLd']).trim(), fields: fields);
  }

  static RecipeList _list(Object? v, String site, Never Function(String) bad) {
    if (v is! Map) bad('a fetch recipe needs list (url and item)');
    final l = v.cast<String, Object?>();
    final unknown = l.keys.where((k) => !const {'url', 'item', 'attr', 'max'}.contains(k));
    if (unknown.isNotEmpty) bad('unknown list field ${unknown.join(', ')}');
    final url = str(l['url']).trim();
    final host = Uri.tryParse(url.replaceAll('{terms}', 'x'))?.host ?? '';
    if (!url.startsWith('https://') || !hostMatches(host, site)) {
      bad('list.url must be an https address on $site');
    }
    if (str(l['item']).trim().isEmpty) bad('list.item (the selector of each job link) is missing');
    final max = l['max'] ?? 10;
    if (max is! int || max < 1 || max > 100) bad('list.max must be 1 to 100');
    return RecipeList(url: url, item: str(l['item']).trim(), attr: str(l['attr'] ?? 'href'), max: max);
  }

  static RecipeFill _fill(Object? v, Never Function(String) bad) {
    if (v is! Map) bad('an assist-fill recipe needs fill');
    final f = v.cast<String, Object?>();
    final unknown = f.keys.where(
      (k) => !const {'targetSelector', 'templateSource', 'template', 'maxLength', 'neverClick'}.contains(k),
    );
    if (unknown.isNotEmpty) bad('unknown fill field ${unknown.join(', ')}');
    if (f['neverClick'] != true) bad('fill.neverClick must be true: Udyoga never presses Send or Submit');
    final target = str(f['targetSelector']).trim();
    if (target.isEmpty) bad('fill.targetSelector is missing');
    if (RegExp(
      r'\bbutton\b|type\s*=\s*["]?(submit|button|image)|\[role\s*=\s*["]?button',
      caseSensitive: false,
    ).hasMatch(target)) {
      bad('fill.targetSelector must be a text box, not a button');
    }
    final source = str(f['templateSource']);
    if (source != 'draft' && source != 'recipe') bad('fill.templateSource must be draft or recipe');
    if (source == 'recipe' && str(f['template']).trim().isEmpty) bad('fill.template is missing');
    final max = f['maxLength'] ?? 0;
    if (max is! int || max < 0) bad('fill.maxLength must be a whole number');
    return RecipeFill(
      targetSelector: target,
      templateSource: source,
      template: str(f['template']),
      maxLength: max,
    );
  }

  /// The record on a page of this recipe's ([pageHtml] at [url]), or null
  /// when the page gives no headline.
  PageRecord? recordFrom(String pageHtml, {required String url, List<String>? ld}) {
    final doc = html.parse(pageHtml);
    Json? ldObject;
    if (detail.jsonLd.isNotEmpty) {
      ldObject = ldObjects(ld ?? ldScriptsIn(pageHtml))
          .where((o) => ldTypes(o).contains(detail.jsonLd))
          .firstOrNull;
    }
    final fields = <String, String>{
      for (final e in detail.fields.entries) e.key: e.value.read(doc, ldObject),
    };
    if (ldObject != null && record == RecordKind.job && detail.jsonLd == 'JobPosting') {
      // The JobPosting markup fills what the selectors left.
      final fromLd = recordsFromLd([jsonEncode(ldObject)], pageUrl: url).firstOrNull;
      if (fromLd != null) {
        for (final f in fromLd.fields.entries) {
          if ((fields[f.key] ?? '').isEmpty) fields[f.key] = f.value;
        }
      }
    }
    final r = PageRecord(record, fields, from: 'recipe ${title.toLowerCase()}', url: url);
    return r.usable ? r : null;
  }

  /// The links on a list page, absolute, on this recipe's pages, at most
  /// [RecipeList.max].
  List<String> linksIn(String pageHtml, {required Uri base}) {
    final l = list;
    if (l == null) return const [];
    final out = <String>{};
    for (final e in html.parse(pageHtml).querySelectorAll(l.item)) {
      final href = (l.attr == 'text' ? e.text : e.attributes[l.attr] ?? '').trim();
      if (href.isEmpty) continue;
      final u = base.resolve(href).removeFragment().toString();
      if (matches(u)) out.add(u);
      if (out.length >= l.max) break;
    }
    return out.toList();
  }
}

/// The recipes in a folder, and the files that were refused.
class RecipeSet {
  const RecipeSet({this.recipes = const [], this.problems = const []});
  final List<Recipe> recipes;

  /// "file.json: why".
  final List<String> problems;

  Iterable<Recipe> ofMode(RecipeMode m) => recipes.where((r) => r.mode == m);

  /// The recipes for [url] in [mode].
  List<Recipe> forPage(String url, RecipeMode mode) => [
    for (final r in recipes)
      if (r.mode == mode && r.matches(url)) r,
  ];

  /// Reads every *.json file in [dir]: one recipe, or a list of them. A
  /// file that breaks the schema is refused whole; a repeated id keeps the
  /// first.
  static Future<RecipeSet> load(Directory dir) async {
    if (!await dir.exists()) return RecipeSet(problems: ['${dir.path}: no such folder']);
    final recipes = <Recipe>[];
    final problems = <String>[];
    final files =
        await dir
              .list()
              .where((e) => e is File && e.path.toLowerCase().endsWith('.json'))
              .cast<File>()
              .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      try {
        final v = jsonDecode(await f.readAsString());
        final items = v is List ? v : [v];
        final read = [
          for (final i in items)
            if (i is Map)
              Recipe.fromJson(i.cast<String, Object?>(), file: name)
            else
              throw RecipeException('not a recipe object'),
        ];
        for (final r in read) {
          if (recipes.any((x) => x.id == r.id)) {
            problems.add('$name: id ${r.id} is used twice; the first is kept');
          } else {
            recipes.add(r);
          }
        }
      } on FormatException catch (e) {
        problems.add('$name: not valid JSON (${e.message})');
      } on RecipeException catch (e) {
        problems.add('$name: ${e.message}');
      }
    }
    return RecipeSet(recipes: recipes, problems: problems);
  }
}

/// Device-only key: the recipes folder.
const recipesFolderKey = 'udyoga.recipes.folder';

/// The recipes in the folder chosen on this device; none when no folder is
/// chosen.
Future<RecipeSet> savedRecipes(AppDatabase db) async {
  final folder = (await db.localSetting(recipesFolderKey) ?? '').trim();
  if (folder.isEmpty) return const RecipeSet();
  return RecipeSet.load(Directory(folder));
}

/// The fetch run for this device's recipes folder, or null without one.
Future<RecipeFetch?> recipeFetchFor(AppDatabase db, http.Client client) async {
  final set = await savedRecipes(db);
  final fetch = set.recipes.where((r) => r.mode == RecipeMode.fetch).toList();
  return fetch.isEmpty ? null : RecipeFetch(db, PoliteFetcher(db, client), fetch);
}

/// Runs the fetch recipes: each one's search page for the profile's terms,
/// then the job pages it links to that were not read this week, through
/// [PoliteFetcher] (robots.txt, the recipe's rate and daily cap).
class RecipeFetch {
  RecipeFetch(this.db, this.fetcher, this.recipes);
  final AppDatabase db;
  final PoliteFetcher fetcher;
  final List<Recipe> recipes;

  Future<({List<Posting> postings, List<String> problems, int asked, int failed})> run(
    CandidateProfile p, {
    void Function(String status)? onProgress,
  }) async {
    final postings = <Posting>[];
    final problems = <String>[];
    var asked = 0, failed = 0;
    for (final r in recipes.where((r) => r.mode == RecipeMode.fetch)) {
      // Checked again here: a recipe built by hand must not slip past.
      if (!r.robots || isFetchDenied(r.site) || r.list == null) continue;
      asked++;
      onProgress?.call('Reading ${r.title} (one page every ${r.rate} s)…');
      try {
        final terms = p.searchTerms.take(3).join(' ');
        final listUrl = Uri.parse(r.list!.url.replaceAll('{terms}', Uri.encodeQueryComponent(terms)));
        final page = await fetcher.get(listUrl, gap: r.gap, use: r.use, dailyCap: r.effectiveCap);
        for (final link in r.linksIn(page, base: listUrl)) {
          if (await fetcher.seen(r.use, link)) continue;
          final detail = await fetcher.get(Uri.parse(link), gap: r.gap, use: r.use, dailyCap: r.effectiveCap);
          await fetcher.markSeen(r.use, link);
          final rec = r.recordFrom(detail, url: link);
          if (rec != null && rec.kind == RecordKind.job) {
            postings.add(rec.toPosting(country: p.country, source: 'recipe'));
          }
        }
      } on DailyCapReached {
        // Enough for today; what was read is kept.
      } on Object catch (e) {
        failed++;
        problems.add('${r.title}: ${feedProblem(e)}');
      }
    }
    return (postings: postings, problems: problems, asked: asked, failed: failed);
  }
}
