import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/vidya_link.dart';

import 'support.dart';

/// Vidya's portfolio Markdown, as its Portfolio page copies it.
const _portfolio = '''
# Portfolio

## Skills

- **Interview:** Communication (Proficient)
- **Digital:** SystmOne (Competent), Excel (Learning)

## Learning completed

- Care Certificate (Certification, Skills for Health, 3 Nov 2026)
- RTT rules (Course, 1 Nov 2026)
- A practice round (Practice, 2 Nov 2026)

---

12 hours of study · 4 topics · 2 courses completed
''';

void main() {
  late CareerBook book;
  setUp(() async {
    book = CareerBook(await Store.open(memoryDatabase()));
    await book.saveProfile(sampleProfile);
  });

  test('the Vidya plan carries the weak competencies, job gaps, learning and stories', () async {
    final id = (await book.importPostings([samplePosting()], sampleProfile, today: '2026-11-15')).single;
    await book.saveAssessment(
      id,
      const FitAssessment({
        'fit': 60,
        'gaps': [
          {'requirement': 'SystmOne experience', 'severity': 'major', 'mitigation': 'Do the e-learning.'},
        ],
      }),
    );
    await book.suggestLearning([
      const LearningSuggestion(
        title: 'Care Certificate',
        kind: 'certification',
        provider: 'Skills for Health',
      ),
    ], today: '2026-11-15');
    await book.addStories(
      [
        const StoryDraft(
          title: 'E-obs training',
          action: 'I trained 40 staff.',
          result: 'Live on time.',
          competencies: ['supporting'],
        ),
      ],
      source: 'manual',
      today: '2026-11-15',
    );

    final plan = await book.vidyaPlanNow();
    expect((plan['format'], plan['version']), ('vidya-curriculum', 1));
    expect((plan['program'] as Map)['title'], 'Interview ready: Clinical Informatics Nurse');
    final courses = [for (final c in plan['courses'] as List) c as Map];
    expect(courses.map((c) => c['title']), [
      'Interview stories',
      'Gaps for Clinical Informatics Nurse at Example Health Trust',
      'Care Certificate',
    ]);
    // Every competency is short of a confirmed pair of stories.
    expect((courses.first['topics'] as List).length, competencyNames.length);
    expect(((courses[1]['topics'] as List).single as Map)['details'], 'Severity: major. Do the e-learning.');
    final card = (plan['cards'] as List).single as Map;
    expect(card['deck'], 'Interview stories');
    expect(card['front'], 'Tell your story: E-obs training (${competencyNames['supporting']})');
    expect(card['back'], 'Action: I trained 40 staff.\nResult: Live on time.');
    expect((plan['skills'] as List).length, competencyNames.length);
    // Plain JSON a file can carry.
    expect(jsonDecode(jsonEncode(plan)), plan);
  });

  test('the Vidya portfolio is read: completed learning and skills rated Competent or better', () {
    final done = parseVidyaPortfolio(_portfolio);
    expect(done.learning, [
      (
        title: 'Care Certificate',
        kind: 'certification',
        provider: 'Skills for Health',
        finished: '3 Nov 2026',
      ),
      (title: 'RTT rules', kind: 'course', provider: '', finished: '1 Nov 2026'),
    ]);
    expect(done.skills, ['SystmOne']);
  });

  test('what Vidya finished marks learning done and adds skills, once', () async {
    await book.suggestLearning([const LearningSuggestion(title: 'Care certificate')], today: '2026-11-10');
    final done = parseVidyaPortfolio(_portfolio);
    expect(await book.importVidya(done, today: '2026-11-15'), (learning: 2, skills: 1));
    final growth = await book.db.select(book.db.careerGrowth).get();
    expect(growth.map((g) => (g.title, g.status)).toSet(), {
      ('Care certificate', 'done'),
      ('RTT rules', 'done'),
    });
    expect((await book.profile()).skills, contains('SystmOne'));
    expect(await book.importVidya(done, today: '2026-11-16'), (learning: 0, skills: 0));
  });

  test('the plan fixture shared with Vidya is current', () async {
    // Vidya's tests parse this file, so a change in the plan shows there.
    await book.addStories(
      [
        const StoryDraft(title: 'Fixture story', action: 'I did the thing.', competencies: ['teamwork']),
      ],
      source: 'manual',
      today: '2026-11-15',
    );
    final plan = const JsonEncoder.withIndent('  ').convert(await book.vidyaPlanNow());
    final fixture = File('test/fixtures/udyoga-plan.json');
    if (!fixture.existsSync() || Platform.environment['UPDATE_FIXTURES'] == '1') {
      await fixture.parent.create(recursive: true);
      await fixture.writeAsString('$plan\n');
    }
    expect(await fixture.readAsString(), '$plan\n');
  });
}
