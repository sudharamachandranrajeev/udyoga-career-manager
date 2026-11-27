// The evidence bank (plan A4): framework data, tags, coverage, story
// suggestions, the usage log with its reuse warning, the "refresh the
// details" hint, the Vidya payload and the panel persona in the planning
// prompt. Every story, employer and role here is made up.
import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/evidence.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/interview_brain.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/vidya_link.dart';

import 'support.dart';

Story _story(
  String id, {
  String title = 'A story',
  String action = 'I did a thing.',
  bool confirmed = true,
  List<StoryTag> tags = const [],
  List<String> competencies = const [],
  List<String> criteria = const [],
  String added = '2026-11-01',
  String? happened,
}) => Story(
  id: id,
  hlc: '',
  deleted: false,
  title: title,
  situation: '',
  task: '',
  action: action,
  result: '',
  competencies: jsonEncode(competencies),
  source: 'manual',
  criteria: jsonEncode(criteria),
  confirmed: confirmed,
  added: added,
  tags: encodeTags(tags),
  happened: happened,
);

/// Records the system prompt of each request; plans nothing.
class _PlanAi implements Ai {
  final systems = <String>[];

  @override
  String get model => 'test';

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
    systems.add(system);
    return AiResult({'questions': <Json>[]});
  }
}

void main() {
  group('frameworks', () {
    test('the NHS LMF draft has three areas of three standards, marked as a draft', () {
      final f = nhsLeadershipFramework;
      expect(f.items, hasLength(9));
      expect(f.note, contains('Draft'));
      expect(f.note, contains('check the final wording'));
      final areas = <String, List<String>>{};
      for (final i in f.items) {
        (areas[i.area] ??= []).add(i.title);
      }
      expect(areas, {
        'Self effectiveness': [
          'Balancing safety, productivity and wellbeing',
          'Communicating and listening effectively',
          'Delivering with accountability and integrity',
        ],
        'Managing people and resources': [
          'Creating a high-performing work environment',
          'Improving performance and operational delivery',
          'Maximising resources and financial value',
        ],
        'Delivering across health and care': [
          'Improving patient outcomes and experiences',
          'Leading with a mindset of improvement and innovation',
          'Working collaboratively to achieve successful outcomes',
        ],
      });
    });

    test('the Healthcare Leadership Model has its nine dimensions and the values their six', () {
      expect(healthcareLeadershipModel.items.map((i) => i.title), [
        'Inspiring shared purpose',
        'Leading with care',
        'Evaluating information',
        'Connecting our service',
        'Sharing the vision',
        'Engaging the team',
        'Holding to account',
        'Developing capability',
        'Influencing for results',
      ]);
      expect(nhsValuesFramework.items.map((i) => i.title), [
        'Working together for patients',
        'Respect and dignity',
        'Commitment to quality of care',
        'Compassion',
        'Improving lives',
        'Everyone counts',
      ]);
    });

    test('ids are unique, and the twelve competencies stay as their own framework', () {
      for (final f in [...evidenceFrameworks, competencyFramework]) {
        expect(f.items.map((i) => i.id).toSet(), hasLength(f.items.length), reason: f.id);
        expect(builtInFramework(f.id), same(f));
      }
      expect(evidenceFrameworks.map((f) => f.id).toSet(), hasLength(3));
      expect(competencyFramework.items, hasLength(12));
    });

    test('a role profile\'s person specification is a framework of its criteria', () {
      final f = personSpecFramework(
        const RoleProfile(
          id: 'p1',
          title: 'Ward clerk',
          employer: 'Example Trust',
          criteria: [
            Criterion(id: 'c1', text: 'Experience of keeping accurate records'),
            Criterion(id: 'c2', text: 'Calm under pressure', essential: false),
          ],
        ),
      );
      expect(f.id, 'role.p1');
      expect(f.isRole, isTrue);
      expect(f.name, 'Person specification: Ward clerk, Example Trust');
      expect(f.items.map((i) => (i.id, i.area)), [('c1', 'Essential'), ('c2', 'Desirable')]);
    });
  });

  group('tags', () {
    test('many tags round-trip; duplicates and unreadable entries are dropped', () {
      const a = StoryTag('nhs_values', 'compassion'), b = StoryTag('nhs_lmf', 'self_safety');
      expect(decodeTags(encodeTags([a, b, a])), [a, b]);
      expect(decodeTags('[{"framework":"x"},3,"y",{"framework":"nhs_hlm","item":"leading_with_care"}]'), [
        const StoryTag('nhs_hlm', 'leading_with_care'),
      ]);
      expect(decodeTags('not json'), isEmpty);
      expect(tagTitle(a), 'Compassion');
      expect(tagTitle(const StoryTag('role.p9', 'c1')), '');
    });
  });

  group('coverage', () {
    test('each item is none, some or ready (two or more confirmed)', () {
      const t = StoryTag('nhs_values', 'compassion');
      final rows = coverageOf(nhsValuesFramework, [
        _story('1', tags: [t]),
        _story('2', tags: [t, const StoryTag('nhs_values', 'everyone_counts')]),
        _story('3', tags: [const StoryTag('nhs_values', 'everyone_counts')], confirmed: false),
        _story('4', tags: [const StoryTag('nhs_lmf', 'care_outcomes')]),
      ]);
      final by = {for (final r in rows) r.item.id: r};
      expect(by['compassion']!.level, CoverageLevel.ready);
      expect(by['compassion']!.summary, '2 confirmed');
      expect(by['everyone_counts']!.level, CoverageLevel.some);
      expect(by['everyone_counts']!.summary, '2 stories, 1 confirmed');
      expect(by['respect_dignity']!.level, CoverageLevel.none);
      expect(by['respect_dignity']!.summary, 'No story yet');
      expect(rows.map((r) => r.item.id), nhsValuesFramework.items.map((i) => i.id));
    });

    test('competencies count from the competency list; a person spec also from saved criteria', () {
      final comp = coverageOf(competencyFramework, [
        _story('1', competencies: ['teamwork']),
      ]);
      expect(comp.firstWhere((r) => r.item.id == 'teamwork').summary, '1 story');
      final spec = personSpecFramework(
        const RoleProfile(
          id: 'p1',
          title: 'Ward clerk',
          criteria: [
            Criterion(id: 'c1', text: 'Experience of keeping accurate records'),
            Criterion(id: 'c2', text: 'Calm under pressure'),
          ],
        ),
      );
      final rows = coverageOf(spec, [
        _story('1', criteria: ['experience of keeping accurate records ']),
        _story('2', tags: [const StoryTag('role.p1', 'c1')]),
        _story('3', tags: [const StoryTag('role.other', 'c2')]),
      ]);
      expect(rows.first.level, CoverageLevel.ready);
      expect(rows.last.level, CoverageLevel.none);
    });
  });

  group('suggestions', () {
    test('tagged stories first, then shared words, confirmed before drafts; no match is left out', () {
      const item = EvidenceItem('c1', 'Experience of keeping accurate patient records');
      final spec = EvidenceFramework(id: 'role.p1', name: 'Spec', items: const [item]);
      final found = suggestStories(
        item,
        [
          _story('none', title: 'Fire drill', action: 'I led the evacuation.'),
          _story('one-draft', title: 'Records audit', action: 'I checked the list.', confirmed: false),
          _story('one', title: 'Records audit', action: 'I checked the list.'),
          _story('two', title: 'Patient records', action: 'I made the records accurate.'),
          _story('tagged', title: 'Night shift', tags: [const StoryTag('role.p1', 'c1')]),
        ],
        framework: spec,
        limit: 5,
      );
      expect(found.map((x) => x.story.id), ['tagged', 'two', 'one', 'one-draft']);
      expect(found.first.tagged, isTrue);
      expect(found[1].overlap, 3);
      expect(suggestStories(item, [_story('x')], framework: spec), isEmpty);
    });

    test('keywords drop short and common words and trim endings', () {
      expect(keywords('Experience of working with patients and keeping records'), {
        'patient',
        'keep',
        'record',
      });
    });
  });

  group('dates', () {
    test('stories over twelve months old get the refresh hint; the date it happened wins', () {
      expect(needsRefresh(_story('a', happened: '2025-10-20'), today: '2026-11-27'), isTrue);
      expect(needsRefresh(_story('a', happened: '2025-12-01'), today: '2026-11-27'), isFalse);
      expect(needsRefresh(_story('a', happened: '2025-10'), today: '2026-11-27'), isTrue);
      expect(needsRefresh(_story('a', added: '2025-01-01'), today: '2026-11-27'), isTrue);
      expect(
        needsRefresh(
          _story('a', added: '2025-01-01', happened: '2026-06-01'),
          today: '2026-11-27',
        ),
        isFalse,
      );
      expect(storyDate(_story('a', added: '2026-11-01')), '2026-11-01');
    });

    test('a date is yyyy-mm-dd or yyyy-mm and real', () {
      expect(validStoryDate('2026-02-28'), isTrue);
      expect(validStoryDate('2026-02'), isTrue);
      expect(validStoryDate('2026-02-31'), isFalse);
      expect(validStoryDate('2026-13'), isFalse);
      expect(validStoryDate('last spring'), isFalse);
    });
  });

  group('usage log', () {
    late CareerBook book;
    setUp(() async => book = CareerBook(await Store.open(memoryDatabase())));

    Future<Story> add(String title) async {
      final id = newId();
      await book.save(
        book.db.careerStories,
        CareerStoriesCompanion.insert(
          id: id,
          title: title,
          action: const Value('I did it.'),
          added: '2026-11-01',
        ),
        id,
      );
      return (await book.stories()).firstWhere((s) => s.id == id);
    }

    test('records each use, warns on the same employer only, and logs a repeat once', () async {
      final s = await add('Diary clash');
      expect(
        await book.useStory(
          s,
          kind: 'statement',
          refId: 'p1',
          employer: 'Example Trust',
          role: 'Ward clerk',
          criterion: 'Managing a diary',
          at: '2026-11-20T10:00',
        ),
        isNull,
      );
      // The same criterion of the same profile again: no warning, no second row.
      expect(
        await book.useStory(
          s,
          kind: 'statement',
          refId: 'p1',
          employer: 'Example Trust',
          criterion: 'Managing a diary',
          at: '2026-11-20T10:05',
        ),
        isNull,
      );
      expect(await book.storyUses(), hasLength(1));
      // Another employer: fine.
      expect(
        await book.useStory(
          s,
          kind: 'interview',
          refId: 'p2',
          employer: 'Other Health Board',
          at: '2026-11-21T09:00',
        ),
        isNull,
      );
      // The same employer, another role: warned, with where it was used.
      final w = await book.useStory(
        s,
        kind: 'interview',
        refId: 'p3',
        employer: 'example trust',
        at: '2026-11-22T09:00',
      );
      expect(w, contains('already used this story with Example Trust'));
      expect(w, contains('Supporting statement, "Managing a diary", 2026-11-20'));
      final uses = await book.storyUses();
      expect(uses, hasLength(3));
      expect(usedInLines(uses, s.id), [
        'Interview · example trust · 2026-11-22',
        'Interview · Other Health Board · 2026-11-21',
        'Supporting statement · Ward clerk, Example Trust · Managing a diary · 2026-11-20',
      ]);
      // No employer given: nothing to compare.
      expect(reuseWarning(uses, storyId: s.id, employer: ''), isNull);
    });

    test('tagging a story adds the tag once and keeps the others', () async {
      final s = await add('Rota gap');
      await book.tagStory(s, const StoryTag('nhs_values', 'compassion'));
      var now = (await book.stories()).single;
      await book.tagStory(now, const StoryTag('nhs_values', 'compassion'));
      await book.tagStory(now, const StoryTag('role.p1', 'c1'));
      now = (await book.stories()).single;
      expect(tagsOf(now), [const StoryTag('nhs_values', 'compassion'), const StoryTag('role.p1', 'c1')]);
    });

    test('Vidya cards carry the tags and the date, beside the old fields', () async {
      final s = await add('Clinic diary clash');
      await book.saveStory(
        s.copyWith(
          tags: encodeTags([
            const StoryTag('nhs_values', 'everyone_counts'),
            const StoryTag('role.p1', 'c1'),
          ]),
          happened: const Value('2026-10-02'),
          competencies: '["prioritising"]',
        ),
      );
      await book.saveRoleProfile(
        const RoleProfile(
          id: 'p1',
          title: 'Ward clerk',
          criteria: [Criterion(id: 'c1', text: 'Experience of keeping accurate records')],
        ),
        at: '2026-11-20T10:00',
      );
      final card = ((await book.vidyaPlanNow())['cards'] as List).single as Map;
      expect(card.keys, containsAll(['id', 'deck', 'front', 'back', 'tags', 'happened']));
      expect(card['front'], 'Tell your story: Clinic diary clash (Prioritising a heavy workload)');
      expect(card['happened'], '2026-10-02');
      expect(card['tags'], [
        {'framework': 'nhs_values', 'item': 'everyone_counts', 'title': 'Everyone counts'},
        {'framework': 'role.p1', 'item': 'c1', 'title': 'Experience of keeping accurate records'},
      ]);
    });
  });

  group('panel persona', () {
    const questions = [
      EngineQuestion({'question': 'Tell us about a time you kept records accurate.'}),
    ];

    test('the challenging panel\'s tone limits go into the planning prompt', () async {
      final ai = _PlanAi();
      await Advisor(
        ai,
        today: '2026-11-27',
      ).questionPlan(role: 'Ward clerk', questions: questions, persona: PersonaKind.challenging);
      expect(ai.systems.single, contains(personaGuidance(PersonaKind.challenging)));
      expect(ai.systems.single, contains('never rude'));
    });

    test('other panels plan neutral probes, as before', () async {
      final ai = _PlanAi();
      await Advisor(ai, today: '2026-11-27').questionPlan(role: 'Ward clerk', questions: questions);
      expect(ai.systems.single, contains('never leading'));
      expect(ai.systems.single, isNot(contains('challenge claims')));
    });

    test('the chooser describes the challenging panel in Udyoga\'s words', () {
      expect(
        personaBlurb(Persona.of(PersonaKind.challenging)),
        'Firm panel: challenges claims, asks for evidence, interrupts politely. Never rude.',
      );
      expect(personaBlurb(Persona.of(PersonaKind.friendly)), Persona.of(PersonaKind.friendly).about);
      expect(personas.keys, contains(PersonaKind.challenging));
    });
  });
}
