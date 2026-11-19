import 'countries.dart';
import 'json.dart';

/// EU and EEA members plus Switzerland: a passport from one gives the right
/// to work in all of them.
const freeMovement = {
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', //
  'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'IS', 'LI', 'NO', 'CH',
};

/// The Common Travel Area: British and Irish citizens may work in both.
const commonTravelArea = {'GB', 'IE'};

/// An ISO alpha-2 code from a code or a name as people write it ("UK",
/// "United Kingdom", "England", "UAE", "KSA"), upper case; '' when unknown.
String countryCode(String s) {
  final t = s.trim().replaceAll(RegExp(r'^the\s+', caseSensitive: false), '').trim();
  if (t.isEmpty) return '';
  final up = t.toUpperCase();
  if (_aliases[up] case final c?) return c;
  if (up.length == 2 && Country.of(up) != null) return up;
  for (final c in countries) {
    if (c.name.toUpperCase() == up) return c.code;
  }
  return up.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(up) ? up : '';
}

const _aliases = {
  'UK': 'GB',
  'U.K.': 'GB',
  'BRITAIN': 'GB',
  'GREAT BRITAIN': 'GB',
  'UNITED KINGDOM': 'GB',
  'ENGLAND': 'GB',
  'SCOTLAND': 'GB',
  'WALES': 'GB',
  'NORTHERN IRELAND': 'GB',
  'REPUBLIC OF IRELAND': 'IE',
  'IRELAND': 'IE',
  'US': 'US',
  'U.S.': 'US',
  'USA': 'US',
  'U.S.A.': 'US',
  'UNITED STATES': 'US',
  'UNITED STATES OF AMERICA': 'US',
  'AMERICA': 'US',
  'UAE': 'AE',
  'U.A.E.': 'AE',
  'UNITED ARAB EMIRATES': 'AE',
  'DUBAI': 'AE',
  'ABU DHABI': 'AE',
  'KSA': 'SA',
  'SAUDI': 'SA',
  'SAUDI ARABIA': 'SA',
  'KINGDOM OF SAUDI ARABIA': 'SA',
  'QATAR': 'QA',
  'OMAN': 'OM',
  'KUWAIT': 'KW',
  'BAHRAIN': 'BH',
  'SINGAPORE': 'SG',
  'INDIA': 'IN',
  'CANADA': 'CA',
  'AUSTRALIA': 'AU',
  'NEW ZEALAND': 'NZ',
  'GERMANY': 'DE',
  'NETHERLANDS': 'NL',
  'THE NETHERLANDS': 'NL',
  'HOLLAND': 'NL',
};

/// Permission to work in one country: a citizen's, a visa, settled status.
class RightToWork {
  const RightToWork({required this.country, this.status = '', this.until, this.notes = ''});

  /// ISO alpha-2, upper case.
  final String country;

  /// In the person's own words ("Dependant partner visa", "Settled").
  final String status;

  /// The last day it lasts, yyyy-MM-dd; null when it does not end.
  final String? until;
  final String notes;

  /// In force on [today] (yyyy-MM-dd).
  bool activeOn(String today) => until == null || until!.compareTo(today) >= 0;

  factory RightToWork.fromJson(Json j) {
    final until = str(j['until']);
    return RightToWork(
      country: countryCode(str(j['country'])),
      status: str(j['status']),
      until: isDay(until) ? until : null,
      notes: str(j['notes']),
    );
  }

  Json toJson() => {'country': country, 'status': status, 'until': until, 'notes': notes};
}

/// How well someone speaks a language, lowest first.
enum LanguageLevel {
  basic('Basic', 'A1–A2'),
  conversational('Conversational', 'B1'),
  professional('Professional', 'B2'),
  fluent('Fluent', 'C1'),
  native('Native', 'C2');

  const LanguageLevel(this.label, this.cefr);
  final String label, cefr;

  /// From a word or a CEFR level ("fluent", "C1", "business", "mother
  /// tongue"); null when it names no level.
  static LanguageLevel? parse(String s) {
    final t = s.toLowerCase();
    if (RegExp(r'\b(native|mother[- ]tongue|first language|bilingual|c2)\b').hasMatch(t)) return native;
    if (RegExp(r'\b(fluent|fluency|full professional|advanced|excellent|c1)\b').hasMatch(t)) return fluent;
    if (RegExp(
      r'\b(professional|business|working|good|strong|proficient|proficiency|upper[- ]intermediate|b2)\b',
    ).hasMatch(t)) {
      return professional;
    }
    if (RegExp(r'\b(conversational|intermediate|b1)\b').hasMatch(t)) return conversational;
    if (RegExp(r'\b(basic|beginner|elementary|limited|a1|a2)\b').hasMatch(t)) return basic;
    return null;
  }

  static LanguageLevel of(String name) => values.where((l) => l.name == name).firstOrNull ?? professional;
}

/// A language the person speaks, and how well.
class SpokenLanguage {
  const SpokenLanguage(this.language, this.level);
  final String language;
  final LanguageLevel level;

  factory SpokenLanguage.fromJson(Json j) => SpokenLanguage(
    str(j['language']),
    LanguageLevel.values.where((l) => l.name == str(j['level'])).firstOrNull ??
        LanguageLevel.parse(str(j['level'])) ??
        LanguageLevel.professional,
  );

  Json toJson() => {'language': language, 'level': level.name};
}

/// Where the person may work and what they speak: passports, rights to work
/// and languages with levels. Kept apart from the CV fields (its own synced
/// pref), so reading a CV never wipes it.
class WorkRights {
  const WorkRights({this.passports = const [], this.rightToWork = const [], this.languages = const []});

  /// Passport countries, ISO alpha-2.
  final List<String> passports;
  final List<RightToWork> rightToWork;
  final List<SpokenLanguage> languages;

  bool get isEmpty => passports.isEmpty && rightToWork.isEmpty && languages.isEmpty;

  factory WorkRights.fromJson(Json j) => WorkRights(
    passports: strs(j['passports']).map(countryCode).where((c) => c.isNotEmpty).toList(),
    rightToWork: objs(j['rightToWork']).map(RightToWork.fromJson).where((r) => r.country.isNotEmpty).toList(),
    languages: objs(j['languages']).map(SpokenLanguage.fromJson).where((l) => l.language.isNotEmpty).toList(),
  );

  Json toJson() => {
    'passports': passports,
    'rightToWork': [for (final r in rightToWork) r.toJson()],
    'languages': [for (final l in languages) l.toJson()],
  };

  WorkRights copyWith({
    List<String>? passports,
    List<RightToWork>? rightToWork,
    List<SpokenLanguage>? languages,
  }) => WorkRights(
    passports: passports ?? this.passports,
    rightToWork: rightToWork ?? this.rightToWork,
    languages: languages ?? this.languages,
  );

  /// Why the person may work in [country] on [today], or null when nothing
  /// says they may: a passport (with EU free movement and the Common Travel
  /// Area) or a right to work in force.
  String? basisIn(String country, String today) {
    final c = countryCode(country);
    if (c.isEmpty) return null;
    if (passports.contains(c)) return 'You hold a ${Country.nameOf(c)} passport';
    if (freeMovement.contains(c)) {
      final eu = passports.where(freeMovement.contains).firstOrNull;
      if (eu != null) return 'Your ${Country.nameOf(eu)} passport gives free movement';
    }
    if (commonTravelArea.contains(c)) {
      final cta = passports.where(commonTravelArea.contains).firstOrNull;
      if (cta != null) return 'British and Irish citizens may work in both countries';
    }
    final r = rightToWork.where((r) => r.country == c && r.activeOn(today)).firstOrNull;
    if (r != null) return r.status.isEmpty ? 'You have the right to work there' : 'Your ${r.status}';
    return null;
  }

  /// The right to work in [country] that is in force on [today] and ends,
  /// or null (none, or one that does not end).
  RightToWork? endingIn(String country, String today) => rightToWork
      .where((r) => r.country == countryCode(country) && r.until != null && r.activeOn(today))
      .firstOrNull;

  /// How well the person speaks [language]: their own entry, else what the
  /// CV's language list says ("French (fluent)"); null when not listed.
  LanguageLevel? levelIn(String language, {List<String> cv = const []}) {
    final l = language.toLowerCase();
    for (final s in languages) {
      if (s.language.toLowerCase() == l) return s.level;
    }
    for (final s in cv) {
      if (RegExp('\\b${RegExp.escape(l)}\\b').hasMatch(s.toLowerCase())) {
        return LanguageLevel.parse(s.toLowerCase().replaceAll(l, '')) ?? LanguageLevel.professional;
      }
    }
    return null;
  }
}
