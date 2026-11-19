import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/countries.dart';
import 'package:udyoga/domain/work_rights.dart';
import 'package:udyoga/domain/world.dart';

void main() {
  test('every ISO 3166-1 country, each with a region', () {
    expect(worldCountries, hasLength(249));
    expect(worldCountries.map((c) => c.code).toSet(), hasLength(249));
    for (final c in worldCountries) {
      expect(worldRegions, contains(c.region), reason: c.code);
    }
    final gb = worldCountry('gb')!;
    expect(gb.name, 'United Kingdom');
    expect(gb.currency, 'GBP');
    expect(gb.languages, contains('English'));
    expect(worldCountry('DE')!.languages.first, 'German');
    expect(worldCountry('XX'), isNull);
  });

  test('names and codes come from the world list too', () {
    expect(Country.nameOf('FJ'), 'Fiji');
    expect(countryCode('Fiji'), 'FJ');
    expect(countryCode('Trinidad & Tobago'), 'TT');
    expect(countryCode('fj'), 'FJ');
  });
}
