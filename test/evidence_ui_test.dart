// The evidence bank on screen (plan A4): a gap in the coverage map opens a
// story already tagged for it, and a story used for a criterion is copied,
// logged and flagged when the same employer has seen it. Made-up data only.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/evidence.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/resume.dart';
import 'package:udyoga/ui/coach_page.dart';
import 'package:brahma_core/brahma_core.dart' show today;
import 'package:udyoga/ui/interview_debrief_page.dart';
import 'package:udyoga/ui/resume_page.dart';

import 'app_harness.dart';

void main() {
  testWidgets('a gap in the coverage map opens a new story tagged for it', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (book) async {
        // One story for "Compassion", a draft: some evidence, not ready.
        await book.save(
          book.db.careerStories,
          CareerStoriesCompanion.insert(
            id: 's1',
            title: 'Frightened visitor',
            action: const Value('I sat with them and explained the visiting rules.'),
            tags: Value(encodeTags([const StoryTag('nhs_values', 'compassion')])),
            added: '2026-11-01',
          ),
          's1',
        );
      },
    );
    await app.run(home: const CoachPage());
    expect(find.text('Evidence coverage'), findsOneWidget);
    expect(find.text('0 of 6 ready. Tap a gap to add a story for it.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('coverage-item-compassion')),
        matching: find.text('1 story (draft)'),
      ),
      findsOneWidget,
    );

    await app.tap(find.byKey(const ValueKey('coverage-item-respect_dignity')));
    expect(find.text('Capture a story'), findsOneWidget);
    // Prefilled: the values framework is open with "Respect and dignity" chosen.
    final chip = tester.widget<FilterChip>(
      find.ancestor(of: find.text('Respect and dignity').last, matching: find.byType(FilterChip)),
    );
    expect(chip.selected, isTrue);
    expect(find.text('1 chosen'), findsOneWidget);
    await app.enter('Title', 'Private conversation on the ward');
    await app.enter('When it happened', '2026-10-14');
    await app.enter(
      'What you did',
      'I moved the conversation to the side room so the patient could speak freely.',
    );
    await app.tapText('Save as checked');

    final saved = (await tester.runAsync(app.book.stories))!.firstWhere((s) => s.id != 's1');
    expect(tagsOf(saved), [const StoryTag('nhs_values', 'respect_dignity')]);
    expect(saved.happened, '2026-10-14');
    expect(saved.confirmed, isTrue);
    await app.close();
  });

  testWidgets('a suggested story is used for a criterion, and reuse with the same employer is flagged', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    String clip = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clip = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    late String profileId;
    await app.open(
      seed: (book) async {
        profileId = await book.saveRoleProfile(
          const RoleProfile(
            id: '',
            title: 'Ward clerk',
            employer: 'Example Trust',
            criteria: [
              Criterion(id: 'c1', text: 'Experience of keeping accurate patient records'),
              Criterion(id: 'c2', text: 'Able to use a rostering system'),
            ],
          ),
          at: '2026-11-20T10:00',
        );
        await book.save(
          book.db.careerStories,
          CareerStoriesCompanion.insert(
            id: 's1',
            title: 'Records clean-up',
            action: const Value('I checked every patient record against the list and fixed the errors.'),
            confirmed: const Value(true),
            added: '2026-11-01',
          ),
          's1',
        );
        // Used before with the same employer, for another role.
        await book.useStory(
          (await book.stories()).single,
          kind: 'application',
          refId: 'older',
          employer: 'Example Trust',
          role: 'Receptionist',
          at: '2026-10-01T09:00',
        );
      },
    );
    await app.run(home: RoleProfilePage(id: profileId));
    expect(find.text('Stories for your supporting statement'), findsOneWidget);
    expect(find.textContaining('Shares 2 key words'), findsOneWidget);
    expect(find.textContaining('already used with Example Trust'), findsOneWidget);
    // Nothing fits the rostering criterion: a prefilled capture is offered.
    expect(find.byKey(const ValueKey('add-story-c2')), findsOneWidget);

    await app.tap(find.byKey(const ValueKey('use-c1-s1')));
    await app.tapText('Use in the supporting statement');
    expect(find.text('Used with this employer before'), findsOneWidget);
    expect(find.textContaining('Application'), findsWidgets);
    await app.tapText('OK');
    expect(clip, contains('I checked every patient record'));

    final uses = (await tester.runAsync(app.book.storyUses))!;
    expect(
      uses.map((u) => (u.kind, u.refId, u.criterion)),
      contains(('statement', profileId, 'Experience of keeping accurate patient records')),
    );
    final story = (await tester.runAsync(app.book.stories))!.single;
    expect(tagsOf(story), [StoryTag('role.$profileId', 'c1')]);
    await app.close();
  });

  testWidgets('a tailored CV notes the stories it used, preselected from its text, and flags reuse', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    late String cvId;
    await app.open(
      seed: (book) async {
        await book.save(
          book.db.jobListings,
          JobListingsCompanion.insert(
            id: 'j1',
            title: 'Ward clerk',
            company: const Value('Example Trust'),
            found: '2026-11-20',
          ),
          'j1',
        );
        await book.save(
          book.db.careerStories,
          CareerStoriesCompanion.insert(
            id: 's1',
            title: 'Records clean-up',
            action: const Value(
              'I checked every patient record against the clinic list and fixed the errors.',
            ),
            confirmed: const Value(true),
            added: '2026-11-01',
          ),
          's1',
        );
        await book.save(
          book.db.careerStories,
          CareerStoriesCompanion.insert(
            id: 's2',
            title: 'Rota swap',
            action: const Value('I set up a shared swap board for the porters.'),
            confirmed: const Value(true),
            added: '2026-11-02',
          ),
          's2',
        );
        await book.useStory(
          (await book.stories()).firstWhere((s) => s.id == 's1'),
          kind: 'interview',
          refId: 'older',
          employer: 'Example Trust',
          role: 'Receptionist',
          at: '2026-10-01T09:00',
        );
        cvId = await book.saveResume(
          name: 'CV for Ward clerk, Example Trust',
          doc: const ResumeDoc(
            name: 'Alex Example',
            summary:
                'Ward clerk who checked every patient record against the clinic list and fixed the errors.',
          ),
          jobId: 'j1',
          tailoring: {'coverLetter': 'Dear panel, I would like to apply.'},
          today: '2026-11-27',
        );
      },
    );
    await app.run(home: ResumePage(cvId));
    expect(find.text('Stories used'), findsOneWidget);

    await app.tap(find.byKey(const ValueKey('stories-used-pick')));
    bool ticked(String id) =>
        tester.widget<CheckboxListTile>(find.byKey(ValueKey('story-used-$id'))).value ?? false;
    expect(ticked('s1'), isTrue);
    expect(ticked('s2'), isFalse);
    await app.tap(find.byKey(const ValueKey('story-used-s2')));
    await app.tapText('Save');

    expect(find.text('Used with this employer before'), findsOneWidget);
    expect(
      find.textContaining('Records clean-up: You already used this story with Example Trust'),
      findsOneWidget,
    );
    await app.tapText('OK');
    expect(find.byKey(const ValueKey('used-s1')), findsOneWidget);
    expect(find.text('Rota swap · Tailored CV'), findsOneWidget);

    final uses = (await tester.runAsync(() => app.book.draftUses(cvId)))!;
    expect(uses.map((u) => (u.storyId, u.kind, u.employer, u.role)).toSet(), {
      ('s1', 'cv', 'Example Trust', 'Ward clerk'),
      ('s2', 'cv', 'Example Trust', 'Ward clerk'),
    });
    await app.close();
  });

  testWidgets('the check-in offers to capture a story from this month when none came in 30 days', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (book) async {
        await book.save(
          book.db.careerStories,
          CareerStoriesCompanion.insert(id: 's1', title: 'Old story', added: '2020-01-01'),
          's1',
        );
      },
    );
    await app.run(home: const CoachPage());
    expect(find.byKey(const ValueKey('capture-story-nudge')), findsOneWidget);

    await app.tap(find.byKey(const ValueKey('capture-story-nudge')));
    expect(find.text('Capture a story'), findsOneWidget);
    final month = today().substring(0, 7);
    expect(find.widgetWithText(TextField, month), findsOneWidget);
    await app.enter('Title', 'Tidy discharge lounge');
    await app.enter('What you did', 'I sorted the lounge bookings so families knew when to come.');
    await app.tapText('Save as checked');

    final saved = (await tester.runAsync(app.book.stories))!.firstWhere((s) => s.id != 's1');
    expect(saved.happened, month);
    // A story captured today: no nudge until the next quiet month.
    expect(find.byKey(const ValueKey('capture-story-nudge')), findsNothing);
    await app.close();
  });

  testWidgets('no nudge when a story was captured this month', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (book) async {
        await book.save(
          book.db.careerStories,
          CareerStoriesCompanion.insert(id: 's1', title: 'Fresh story', added: today()),
          's1',
        );
      },
    );
    await app.run(home: const CoachPage());
    expect(find.text("Today's check-in"), findsOneWidget);
    expect(find.byKey(const ValueKey('capture-story-nudge')), findsNothing);
    await app.close();
  });
}
