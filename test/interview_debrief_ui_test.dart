import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/ui/interview_debrief_page.dart';
import 'package:udyoga/ui/interview_process_page.dart';
import 'package:udyoga/ui/spoken_round_page.dart' show spokenEnginesProvider;

import 'app_harness.dart';
import 'spoken_round_ui_test.dart' show FakeEngines;

const _at = '2026-11-19T10:00';

/// Fictional and self-written.
const _profile = RoleProfile(
  id: '',
  title: 'Practice administrator',
  frameworkId: 'nhs_values',
  criteria: [
    Criterion(id: 'c1', text: 'Experience of managing a busy diary'),
    Criterion(id: 'c2', text: 'Working together', kind: CriterionKind.value),
  ],
);

const _good =
    'In my last role the clinic diary was double-booked most Mondays. I rang each patient on the list, I moved '
    'the overflow to a Tuesday session and I told the consultant. As a result the double bookings fell from nine '
    'a week to one.';

void main() {
  testWidgets('without an AI the debrief shows coverage, flags a missing essential and saves a story', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    late String round;
    await app.open(
      seed: (book) async {
        final id = await book.saveRoleProfile(_profile, at: _at);
        round = await book.startProfileRound((await book.roleProfile(id))!, at: _at);
        await book.saveTranscript(round, 1, _good, at: _at);
        await book.saveTranscript(round, 2, 'I am a very good team player.', at: _at);
      },
    );
    await app.run(home: DebriefPage(round));
    expect(find.text('Coverage'), findsOneWidget);
    expect(find.textContaining('Coverage from the words on this device'), findsOneWidget);
    expect(find.text('Evidenced'), findsOneWidget);
    expect(find.textContaining(unappointableNote), findsOneWidget);
    expect(find.textContaining('1 essential criterion with no evidence'), findsOneWidget);
    expect(find.text('Lines to recover with'), findsOneWidget);
    // No AI: no scores on the scale, and no percentages anywhere.
    expect(find.textContaining('Scores:'), findsNothing);
    expect(find.textContaining('%'), findsNothing);

    await app.tapText('Save to story bank');
    expect(find.text('Saved to the story bank'), findsWidgets);
    final story = (await app.session.book.stories()).single;
    expect(story.source, 'practice');
    expect(story.criteria, contains('managing a busy diary'));
    // Let the toast go.
    await tester.pump(const Duration(seconds: 5));
    await app.close();
  });

  testWidgets('criteria typed by hand become a round', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run(
      home: const RoleProfilePage(),
      overrides: [spokenEnginesProvider.overrideWith((ref) async => FakeEngines())],
    );
    await app.enter('Job title', 'Ward clerk');
    await app.tapText('Add a criterion by hand');
    await app.enter('Criterion', 'Experience of keeping accurate records');
    await app.tapText('Save');
    expect(find.text('Experience of keeping accurate records'), findsOneWidget);
    await app.tapText('Add these competencies as criteria');
    expect(find.text('Ownership'), findsOneWidget);
    await app.tapText('Practise these aloud');
    final profile = (await app.session.book.roleProfileRows()).single;
    expect(profile.title, 'Ward clerk');
    final rounds = await app.session.db.select(app.session.db.careerPractice).get();
    expect(rounds.single.profileId, profile.id);
    await app.close();
  });

  testWidgets('a saved process picks up where it was left', (tester) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (book) async {
        final round = await book.startPractice(
          role: 'NHS-style: Screening call',
          mode: 'standard',
          questions: nhsStyle.stages[0].roundQuestions(),
          at: _at,
        );
        const outcomes = [
          QuestionOutcome(expected: [AnswerElement.result], heard: {}),
        ];
        id = await book.saveProcess(
          '',
          nhsStyle,
          const ProcessProgress().withStage(
            0,
            StageProgress(roundId: round, finished: true, outcomes: outcomes),
          ),
          at: _at,
        );
      },
    );
    await app.run(
      home: ProcessPage(nhsStyle, savedId: id),
      overrides: [spokenEnginesProvider.overrideWith((ref) async => FakeEngines())],
    );
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('From the last stage'), findsOneWidget);
    expect(find.text(elementFixes[AnswerElement.result]!), findsOneWidget);
    expect(find.text('Debrief'), findsOneWidget);
    expect(find.text('Start Panel interview'), findsOneWidget);
    await app.close();
  });
}
