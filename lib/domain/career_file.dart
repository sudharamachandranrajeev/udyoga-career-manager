import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'book.dart';
import 'json.dart';
import 'profile.dart';
import 'todos.dart';
import 'work_rights.dart';

/// The settings a candidate keeps in their own career folder, at
/// `settings/udyoga.json` inside one of the document folders Udyoga reads.
/// Every part is optional:
///
/// ```json
/// {
///   "targets": {"roles": [], "keywords": [], "places": [], "countries": ["GB"],
///               "salaryFloor": 30000, "exclusions": []},
///   "rightToWork": [{"country": "GB", "status": "Skilled Worker visa", "until": "2028-01-31"}],
///   "passport": {"country": "IE", "confirmed": true},
///   "languages": [{"language": "French", "level": "fluent"}],
///   "todos": [{"id": "renew-licence", "title": "Renew licence", "notes": "", "due": "2027-03-01"}]
/// }
/// ```
///
/// Other keys are left alone.
class CareerFileSettings {
  const CareerFileSettings({
    this.roles,
    this.keywords,
    this.places,
    this.countries,
    this.salaryFloor,
    this.exclusions,
    this.rightToWork,
    this.passport,
    this.languages,
    this.todos = const [],
  });

  /// Null when the file does not say.
  final List<String>? roles, keywords, places, countries, exclusions;
  final int? salaryFloor;
  final List<RightToWork>? rightToWork;

  /// A passport country, set only when the file marks it confirmed (or
  /// does not say).
  final String? passport;
  final List<SpokenLanguage>? languages;
  final List<SeedTodo> todos;

  factory CareerFileSettings.fromJson(Json j) {
    final t = obj(j['targets']);
    List<String>? list(Json from, String key) => from.containsKey(key) ? strs(from[key]) : null;
    final passport = obj(j['passport']);
    final confirmed = passport['confirmed'];
    final passportCode = countryCode(str(passport['country']));
    return CareerFileSettings(
      roles: list(t, 'roles'),
      keywords: list(t, 'keywords'),
      places: list(t, 'places') ?? list(t, 'locations'),
      countries: list(t, 'countries')?.map(countryCode).where((c) => c.isNotEmpty).toList(),
      salaryFloor: switch (intOf(t['salaryFloor'] ?? t['salaryMin'])) {
        final v? when v > 0 => v,
        _ => null,
      },
      exclusions: list(t, 'exclusions'),
      rightToWork: j.containsKey('rightToWork')
          ? objs(j['rightToWork']).map(_rightToWork).where((r) => r.country.isNotEmpty).toList()
          : null,
      passport: passportCode.isEmpty || confirmed == false ? null : passportCode,
      languages: j.containsKey('languages')
          ? objs(j['languages']).map(SpokenLanguage.fromJson).where((l) => l.language.isNotEmpty).toList()
          : null,
      todos: [
        for (final o in objs(j['todos']))
          SeedTodo(
            id: str(o['id']),
            title: str(o['title']),
            notes: str(o['notes']),
            due: isDay(str(o['due'])) ? str(o['due']) : null,
          ),
      ],
    );
  }

  /// The profile with the file's targets in place of its own.
  CandidateProfile applyTo(CandidateProfile p) {
    final t = p.targets;
    return p.copyWith(
      targets: t.copyWith(
        roles: roles,
        keywords: keywords,
        locations: places,
        countries: countries,
        salaryMin: salaryFloor,
        exclusions: exclusions,
      ),
    );
  }

  /// The rights with the file's in place of their own; a passport is added,
  /// never taken away.
  WorkRights applyToRights(WorkRights r) => r.copyWith(
    rightToWork: rightToWork,
    passports: passport == null || r.passports.contains(passport) ? null : [...r.passports, passport!],
    languages: languages,
  );

  bool get touchesProfile =>
      roles != null ||
      keywords != null ||
      places != null ||
      countries != null ||
      salaryFloor != null ||
      exclusions != null;

  bool get touchesRights => rightToWork != null || passport != null || languages != null;
}

/// Extra keys on a right-to-work entry (true/false flags) kept as notes.
RightToWork _rightToWork(Json j) {
  final r = RightToWork.fromJson(j);
  if (r.notes.isNotEmpty) return r;
  final flags = [
    for (final e in j.entries)
      if (e.value is bool && !const {'country', 'status', 'until', 'notes'}.contains(e.key))
        '${_words(e.key)}: ${e.value == true ? 'yes' : 'no'}',
  ];
  return flags.isEmpty
      ? r
      : RightToWork(country: r.country, status: r.status, until: r.until, notes: flags.join('; '));
}

/// "partnerRouteToSettlement" as "partner route to settlement".
String _words(String key) =>
    key.replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (m) => ' ${m[1]!.toLowerCase()}').toLowerCase();

/// What applying the career file did.
class CareerFileResult {
  const CareerFileResult({this.path = '', this.profile = false, this.rights = false, this.todos = 0});
  final String path;
  final bool profile, rights;
  final int todos;
}

/// Reads the career file from the candidate's folders and applies it.
class CareerFile {
  CareerFile(this.book);
  final CareerBook book;

  static const relativePath = 'settings/udyoga.json';

  /// The first `settings/udyoga.json` in [folders], or null.
  static File? find(List<String> folders) {
    for (final f in folders) {
      final file = File('$f${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}');
      if (file.existsSync()) return file;
    }
    return null;
  }

  /// Applies the file in [folders], when there is one and it changed since
  /// it was last applied on this device: its targets and rights replace the
  /// profile's, and its to-dos are brought in (see [TodoBook.importTodos]).
  /// A file that cannot be read throws a [FormatException]; null when there
  /// is nothing new.
  Future<CareerFileResult?> applyFrom(List<String> folders, {required String today}) async {
    final file = find(folders);
    if (file == null) return null;
    final text = await file.readAsString();
    final mark = sha256.convert(utf8.encode(text)).toString();
    if (await book.db.localSetting(LocalKeys.careerFile) == mark) return null;
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('settings/udyoga.json is not a JSON object');
    }
    final r = await apply(CareerFileSettings.fromJson(decoded), today: today, path: file.path);
    await book.db.setLocalSetting(LocalKeys.careerFile, mark);
    return r;
  }

  /// Applies already-read settings.
  Future<CareerFileResult> apply(CareerFileSettings s, {required String today, String path = ''}) async {
    var profile = false, rights = false;
    if (s.touchesProfile) {
      final before = await book.profile();
      final after = s.applyTo(before);
      if (jsonEncode(after.toJson()) != jsonEncode(before.toJson())) {
        await book.setPref(PrefKeys.profile, after.toJson());
        profile = true;
      }
    }
    if (s.touchesRights) {
      final before = await book.workRights();
      final after = s.applyToRights(before);
      if (jsonEncode(after.toJson()) != jsonEncode(before.toJson())) {
        await book.setPref(PrefKeys.rights, after.toJson());
        rights = true;
      }
    }
    if (profile || rights) await book.rescoreJobs(today: today);
    final todos = await book.importTodos(s.todos, today: today);
    return CareerFileResult(path: path, profile: profile, rights: rights, todos: todos);
  }
}
