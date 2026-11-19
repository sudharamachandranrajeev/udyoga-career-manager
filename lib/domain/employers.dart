import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'json.dart';

/// An employer the candidate keeps an eye on. Its openings come from the
/// NHS Jobs feed (for NHS employers, matched by name and aliases), from its
/// job board's public API, or from the job markup on its careers page.
class WatchedEmployer {
  const WatchedEmployer({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.why = '',
    this.sources = const [],
    this.keywords = const [],
    this.seed = '',
  });

  /// Short and stable ("example-health-trust"); the career file uses it to
  /// update the same employer.
  final String id;
  final String name;

  /// Other names its adverts use.
  final List<String> aliases;
  final String why;

  /// Where its jobs are: "nhs" (the NHS Jobs feed) and careers or job-board
  /// links.
  final List<String> sources;

  /// Only openings whose title says one of these count; empty: the
  /// profile's search terms.
  final List<String> keywords;

  /// The career file's version of it, so the file only overwrites it when
  /// the file changes (see [WatchBook.importWatchedEmployers]).
  final String seed;

  /// Advertises through NHS Jobs.
  bool get nhs => sources.any((s) {
    final l = s.toLowerCase().trim();
    return l == 'nhs' || l == 'nhs jobs' || l == 'nhs-jobs' || l.contains('jobs.nhs.uk');
  });

  /// The web links among [sources].
  List<String> get urls => [
    for (final s in sources)
      if (Uri.tryParse(s.trim()) case final u? when u.hasScheme && u.host.isNotEmpty) s.trim(),
  ];

  /// True when [company] is this employer: its name or an alias, as whole
  /// words, ignoring case and punctuation.
  bool matches(String company) {
    final c = normaliseEmployer(company);
    if (c.isEmpty) return false;
    for (final n in [name, ...aliases]) {
      final x = normaliseEmployer(n);
      if (x.isEmpty) continue;
      if (c == x || ' $c '.contains(' $x ')) return true;
    }
    return false;
  }

  factory WatchedEmployer.fromJson(Json j) {
    List<String> list(Object? v) => v is String ? [if (v.trim().isNotEmpty) v.trim()] : strs(v);
    return WatchedEmployer(
      id: employerId(str(j['id']).isNotEmpty ? str(j['id']) : str(j['name'])),
      name: str(j['name']),
      aliases: list(j['aliases']),
      why: str(j['why']),
      sources: list(j['sources']),
      keywords: list(j['keywords']),
      seed: str(j['seed']),
    );
  }

  Json toJson() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'why': why,
    'sources': sources,
    'keywords': keywords,
    if (seed.isNotEmpty) 'seed': seed,
  };

  /// What the career file said, as a short fingerprint.
  String get fingerprint => 'seed:${_fnv(jsonEncode({...toJson()}..remove('seed')))}';

  WatchedEmployer copyWith({String? seed}) => WatchedEmployer(
    id: id,
    name: name,
    aliases: aliases,
    why: why,
    sources: sources,
    keywords: keywords,
    seed: seed ?? this.seed,
  );
}

String _fnv(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// "Example Health Trust" as "example-health-trust".
String employerId(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

/// Lower case, letters and digits only, single spaces; "&" reads "and".
String normaliseEmployer(String s) => s
    .toLowerCase()
    .replaceAll('&', ' and ')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

/// The new jobs (not yet looked at) from employers the user watches,
/// with the employer each came from.
List<({Job job, WatchedEmployer employer})> watchedNewJobs(List<Job> jobs, List<WatchedEmployer> watched) => [
  for (final j in jobs)
    if (!j.deleted && j.status == 'new')
      if (watched.where((e) => e.matches(j.company)).firstOrNull case final e?) (job: j, employer: e),
];

/// The watched employers, kept as one synced pref each so two devices
/// editing different employers never clash.
extension WatchBook on CareerBook {
  static const prefix = 'udyoga.watch.';

  /// Every watched employer, by name.
  Future<List<WatchedEmployer>> watchedEmployers() async {
    final rows = await (db.select(db.prefs)..where((p) => p.id.like('$prefix%') & p.deleted.not())).get();
    return [
      for (final r in rows)
        if (WatchedEmployer.fromJson(decodeObject(r.value)) case final e
            when e.id.isNotEmpty && e.name.isNotEmpty)
          e,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Adds or replaces one.
  Future<void> saveWatchedEmployer(WatchedEmployer e) => setPref('$prefix${e.id}', e.toJson());

  Future<void> removeWatchedEmployer(String id) => remove(db.prefs, '$prefix$id');

  /// Brings in employers from the career file, matched by id: new ones are
  /// added; a known one takes the file's version only when the file's
  /// version changed, so the user's own edits otherwise stand. One the user
  /// removed is not brought back. Returns how many it wrote.
  Future<int> importWatchedEmployers(List<WatchedEmployer> seeds) => db.transaction(() async {
    var wrote = 0;
    for (final s in seeds) {
      if (s.id.isEmpty || s.name.isEmpty) continue;
      final key = '$prefix${s.id}';
      final known = await (db.select(db.prefs)..where((p) => p.id.equals(key))).getSingleOrNull();
      final mark = s.fingerprint;
      if (known != null &&
          (known.deleted || WatchedEmployer.fromJson(decodeObject(known.value)).seed == mark)) {
        continue;
      }
      await save(
        db.prefs,
        PrefsCompanion.insert(
          id: key,
          value: jsonEncode(s.copyWith(seed: mark).toJson()),
          deleted: const Value(false),
        ),
        key,
      );
      wrote++;
    }
    return wrote;
  });
}
