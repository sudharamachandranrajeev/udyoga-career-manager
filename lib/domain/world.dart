/// Every country in ISO 3166-1, with what Unicode CLDR says about it: its
/// English name, UN M49 region, currency and official languages. Generated
/// into world_data.dart by tool/gen_world.dart; the job sites per country
/// stay in countries.dart.
library;

part 'world_data.dart';

/// One ISO 3166-1 country.
class WorldCountry {
  const WorldCountry(
    this.code,
    this.name,
    this.region,
    this.subregion,
    this.currency,
    this.languages, {
    this.officialLanguages = true,
  });

  /// ISO 3166-1 alpha-2, upper case.
  final String code;
  final String name;

  /// UN M49 continent ("Europe", "Asia") and subregion ("Northern Europe").
  final String region, subregion;

  /// ISO 4217 code of the current legal tender; '' when CLDR has none.
  final String currency;

  /// Official languages, most spoken first; when CLDR lists none
  /// ([officialLanguages] false), the most spoken language.
  final List<String> languages;
  final bool officialLanguages;
}

/// All 249 countries, by code.
final Map<String, WorldCountry> worldByCode = {for (final c in _world) c.code: c};

/// All countries, in code order.
List<WorldCountry> get worldCountries => _world;

/// The country for [code], or null.
WorldCountry? worldCountry(String code) => worldByCode[code.toUpperCase()];

/// The regions, in the order people expect.
const worldRegions = ['Europe', 'Asia', 'Americas', 'Africa', 'Oceania'];
