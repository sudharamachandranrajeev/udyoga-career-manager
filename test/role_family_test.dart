import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/occupations.dart';
import 'package:udyoga/domain/role_family.dart';
import 'package:udyoga/domain/title_synonyms.dart';

import 'support.dart';

// Made-up ESCO answers in the shape the ESCO API gives. The animator is the
// junk ESCO really returns for "digital training facilitator".
const _trainerUri = 'http://data.europa.eu/esco/occupation/trainer-example';
const _animatorUri = 'http://data.europa.eu/esco/occupation/animator-example';

String _search(List<(String, String, String)> hits) => jsonEncode({
  '_embedded': {
    'results': [
      for (final (title, code, uri) in hits) {'title': title, 'code': code, 'uri': uri},
    ],
  },
});

final _trainer = jsonEncode({
  'uri': _trainerUri,
  'title': 'ICT trainer',
  'code': '2356.1',
  'preferredLabel': {'en': 'ICT trainer'},
  'alternativeLabel': {
    'en': ['ICT instructor', 'distance-learning trainer', 'ICT trainers', 'IT trainer'],
  },
  '_links': {
    'narrowerOccupation': [
      {'title': 'digital literacy teacher', 'uri': 'http://data.europa.eu/esco/occupation/narrower-example'},
    ],
    'hasEssentialSkill': [
      {'title': 'create training materials'},
      {'title': 'plan learning curriculum'},
    ],
    'hasOptionalSkill': [
      {'title': 'online moderation techniques'},
    ],
  },
});

/// An ESCO stand-in that records every request.
class _Esco {
  final requests = <Uri>[];

  late final http.Client client = MockClient((r) async {
    requests.add(r.url);
    if (r.url.path.endsWith('/search')) {
      return http.Response(
        _search([
          ('assistant outdoor animator', '3423.1.2.1', _animatorUri),
          ('ICT trainer', '2356.1', _trainerUri),
        ]),
        200,
      );
    }
    if (r.url.queryParameters['uri'] == _trainerUri) return http.Response(_trainer, 200);
    return http.Response('{}', 404);
  });
}

class _FakeAi implements Ai {
  _FakeAi(this.answer);
  final Json answer;
  String? asked;

  @override
  String get model => 'fake';

  @override
  Future<AiResult> ask({
    required String system,
    required List<Json> content,
    required Json schema,
    bool web = false,
    int searches = 8,
    String effort = 'high',
    int maxTokens = 32000,
    void Function(String status)? onProgress,
  }) async {
    asked = str(content.first['text']);
    return AiResult(answer);
  }
}

Set<String> _titles(RoleFamily f) => {for (final t in f.titles) t.title.toLowerCase()};

void main() {
  test('a digital training facilitator is in the IT trainer family', () {
    final f = offlineFamily('Digital Training Facilitator');
    expect(f.titles.first.title, 'Digital Training Facilitator');
    expect(f.titles.first.source, FamilySource.typed);
    expect(f.matches.first.soc, '3573');
    final titles = _titles(f);
    expect(titles, contains('clinical systems trainer'));
    expect(titles, contains('it trainer'));
    expect(titles, contains('digital trainer'));
    expect(titles.where((t) => t.contains('animator')), isEmpty);
    final cst = f.titles.firstWhere((t) => t.title == 'Clinical Systems Trainer');
    expect(cst.source, FamilySource.soc);
    expect(cst.closeness, Closeness.close);
    expect(cst.reason, contains('3573'));
  });

  test('a synonym head with nothing else in common is related, not close', () {
    final f = offlineFamily('Digital Training Facilitator');
    final coach = f.titles.firstWhere((t) => t.title == 'AI Coach');
    expect(coach.source, FamilySource.soc);
    expect(coach.closeness, Closeness.related);
    // The role's own head word, or one it already uses, stays close.
    expect(closeByHead('clinical systems trainer', 'Digital Training Facilitator'), isTrue);
    expect(closeByHead('learning facilitator', 'Digital Training Facilitator'), isTrue);
    // A synonym head with a shared field word ("ICT" is "digital") is close.
    expect(closeByHead('ict instructor', 'Digital Training Facilitator'), isTrue);
    expect(closeByHead('ai coach', 'Digital Training Facilitator'), isFalse);
    expect(closeByHead('dog coach', 'IT Trainer'), isFalse);
    expect(closeByHead('it tutor', 'IT Trainer'), isTrue);
  });

  test('the exact title comes first and titles never repeat, in any case', () {
    final f = offlineFamily('it trainer');
    expect(f.titles.first.title, 'it trainer');
    expect(f.titles.first.reason, contains('SOC 2020 3573'));
    final keys = [for (final t in f.titles) t.title.toLowerCase()];
    expect(keys.toSet().length, keys.length);
    expect(keys.where((k) => k == 'it trainer').length, 1);
    // "E-learning Coordinator" and "Elearning Coordinator" are one title.
    expect(keys.where((k) => k.contains('learning coordinator')).length, 1);
  });

  test('in a mixed (n.e.c.) SOC group, unlike titles are only distant', () {
    final f = offlineFamily('Clinical Coder');
    expect(f.where(Closeness.close).map((t) => t.title), contains('Medical Coder'));
    for (final t in f.titles) {
      if (!t.title.toLowerCase().contains(RegExp('clinical|coder|coding'))) {
        expect(t.closeness, Closeness.distant, reason: t.title);
      }
    }
  });

  test('synonyms swap the head noun and fold "training" into "trainer"', () {
    expect(synonymTitles('Digital Training Facilitator'), contains('digital trainer'));
    expect(synonymTitles('Digital Training Facilitator'), contains('digital training instructor'));
    expect(synonymTitles('Staff Nurse'), isEmpty);
    expect(synonymTitles('Facilitator'), isEmpty);
    expect(sameHead('facilitator', 'coach'), isTrue);
    expect(sameHead('officer', 'assistant'), isFalse);
    final s = offlineFamily('Digital Training Facilitator').titles
        .firstWhere((t) => t.title == 'Digital Trainer');
    expect(s.source, FamilySource.synonym);
    expect(s.reason, 'Synonym: trainer for facilitator');
  });

  test('an invented title the shipped data does not know never asks ESCO', () async {
    final esco = _Esco();
    final families = RoleFamilies(esco.client, memoryDatabase());
    final f = await families.family('Chief Vibes Wrangler');
    expect(f.known, isFalse);
    expect(f.titles.map((t) => t.title), ['Chief Vibes Wrangler']);
    expect(await families.skills('Chief Vibes Wrangler'), isNull);
    expect(esco.requests, isEmpty);
  });

  test('ESCO adds labels only from occupations that agree with the SOC match', () async {
    final esco = _Esco();
    final f = await RoleFamilies(esco.client, memoryDatabase()).family('Digital Training Facilitator');
    final titles = _titles(f);
    expect(titles, contains('distance-learning trainer'));
    expect(titles, contains('ict instructor'));
    expect(titles, contains('digital literacy teacher'));
    expect(titles, isNot(contains('ict trainers')));
    expect(titles.where((t) => t.contains('animator')), isEmpty);
    // The animator was never even fetched.
    expect(esco.requests.where((u) => u.queryParameters['uri'] == _animatorUri), isEmpty);
    final alt = f.titles.firstWhere((t) => t.title == 'Distance-learning Trainer');
    expect(alt.source, FamilySource.esco);
    expect(alt.reason, contains('ICT trainer'));
    // The exact title still comes first.
    expect(f.titles.first.title, 'Digital Training Facilitator');
  });

  test('ESCO answers are cached: a second ask needs no network', () async {
    final db = memoryDatabase();
    final esco = _Esco();
    final first = await RoleFamilies(esco.client, db).family('Digital Training Facilitator');
    final asked = esco.requests.length;
    expect(asked, 2);
    final down = MockClient((_) async => throw Exception('no network'));
    final again = await RoleFamilies(down, db).family('Digital Training Facilitator');
    expect(_titles(again), _titles(first));
    final offline = await RoleFamilies(esco.client, db).family('Digital Training Facilitator', offline: true);
    expect(_titles(offline), _titles(first));
    expect(esco.requests.length, asked);
  });

  test('skills come from ESCO, and are null offline before any lookup', () async {
    final db = memoryDatabase();
    final esco = _Esco();
    expect(await RoleFamilies(esco.client, db).skills('IT Trainer', offline: true), isNull);
    expect(esco.requests, isEmpty);
    final s = await RoleFamilies(esco.client, db).skills('IT Trainer');
    expect(s!.occupation.title, 'ICT trainer');
    expect(s.essential, ['create training materials', 'plan learning curriculum']);
    expect(s.optional, ['online moderation techniques']);
    final down = MockClient((_) async => throw Exception('no network'));
    expect((await RoleFamilies(down, db).skills('IT Trainer'))!.essential, hasLength(2));
    expect(await RoleFamilies(down, memoryDatabase()).skills('IT Trainer'), isNull);
  });

  test('AI suggestions are labelled, distant and never repeat the family', () async {
    final f = offlineFamily('Digital Training Facilitator');
    final ai = _FakeAi({
      'titles': [
        {'title': 'Digital Skills Trainer', 'reason': 'Same work in council adverts'},
        {'title': 'clinical systems trainer', 'reason': 'Already there'},
        {'title': ' ', 'reason': 'Empty'},
      ],
    });
    final more = await aiFamilyTitles(ai, f);
    expect(more.map((t) => t.title), ['Digital Skills Trainer']);
    expect(more.single.source, FamilySource.ai);
    expect(more.single.closeness, Closeness.distant);
    expect(more.single.reason, startsWith('AI suggestion'));
    expect(ai.asked, contains('Digital Training Facilitator'));
    final all = f.plus(more);
    expect(all.titles.first.title, 'Digital Training Facilitator');
    expect(all.titles.last.title, 'Digital Skills Trainer');
  });

  test('a family survives a JSON round trip', () {
    final f = offlineFamily('Digital Training Facilitator');
    final back = RoleFamily.fromJson(jsonDecode(jsonEncode(f.toJson())) as Json);
    expect(back.titles.map((t) => t.toJson()), f.titles.map((t) => t.toJson()));
    expect(back.matches.first.soc, f.matches.first.soc);
    expect(back.known, isTrue);
  });

  test('ESCO occupation resources parse to labels only', () {
    final o = parseEscoOccupation(_trainer)!;
    expect(o.isco, '2356');
    expect(o.altLabels, contains('IT trainer'));
    expect(o.narrower, ['digital literacy teacher']);
    expect(parseEscoOccupation('nope'), isNull);
    expect(parseEscoHits(_search([('ICT trainer', '2356.1', _trainerUri)])).single.uri, _trainerUri);
  });

  test('credits for the Data sources screen', () {
    expect(escoCredit, 'This service uses the ESCO classification of the European Commission.');
    expect(onsSocCredit, contains('Open Government Licence v3.0'));
  });
}
