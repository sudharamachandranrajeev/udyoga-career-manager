import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/interview_process.dart';
import 'package:udyoga/ui/interview_process_page.dart';
import 'package:udyoga/ui/spoken_round_page.dart' show spokenEnginesProvider;

import 'app_harness.dart';
import 'spoken_round_ui_test.dart' show FakeEngines;

void main() {
  testWidgets('a process runs stage by stage and carries the fixes forward', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    final engines = FakeEngines();
    await app.run(
      home: ProcessPage(nhsStyle),
      overrides: [spokenEnginesProvider.overrideWith((ref) async => engines)],
    );
    expect(find.text('1. Screening call'), findsOneWidget);
    expect(find.text('Optional: left out.'), findsOneWidget);

    // Templates are editable: cut the screening call down to one question.
    await app.tap(find.text('Edit').first);
    await app.enter(
      'Questions, one per line',
      'Tell us about a time you sorted out a problem for a patient.',
    );
    await app.tapText('Save');
    expect(find.textContaining('2 questions with the settler'), findsOneWidget);

    await app.tapText('Start Screening call');
    expect(find.text(nhsStyle.stages[0].about), findsOneWidget);
    await app.tapText('Check the microphone');
    await app.tapText('Start the round');
    // The settler, after the greeting. Level 3 does not interrupt, so no
    // interrupt script, and the stage's name is on the screen, not said.
    await app.tapText('Ask me');
    expect(
      engines.voice.said.single,
      allOf(
        startsWith(personas[nhsStyle.stages[0].persona]!.greeting),
        endsWith(nhsStyle.stages[0].settler.question),
        isNot(contains(mayInterruptScript)),
        isNot(contains('This is the')),
      ),
    );
    await app.tapText('Done');
    expect(find.text('Follow-up'), findsNothing);
    await app.tapText('Next question');
    // An answer with no measure, result or learning in it.
    await app.tapText('Type instead');
    await app.enter(
      'Your answer',
      'At the time a patient had lost a letter, so I rang the hospital and I booked a new date.',
    );
    await app.tapText('Save answer');
    expect(find.text('Follow-up'), findsOneWidget);
    await app.tapText('Move on');
    await app.tapText('Finish');
    expect(find.text('For next time'), findsOneWidget);
    await app.tapText('Back to the process');

    expect(find.text('Done'), findsOneWidget);
    // The next stage opens with what this one left out.
    expect(find.text('From the last stage'), findsOneWidget);
    expect(find.text(elementFixes[AnswerElement.result]!), findsOneWidget);

    // One page for the whole process: every criterion, then the top fixes.
    await app.tap(find.byTooltip('Whole-process summary'));
    expect(find.text('Summary: ${nhsStyle.name}'), findsOneWidget);
    expect(find.textContaining('Across Screening call.'), findsOneWidget);
    expect(find.text('Top fixes overall'), findsOneWidget);
    expect(find.text('Every criterion across the process'), findsOneWidget);
    expect(find.text('End the example with what happened in the end.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The optional presentation can be switched on.
    await app.tap(find.byType(Switch));
    expect(find.text('Optional: included.'), findsOneWidget);
    expect(find.text('Start Presentation'), findsOneWidget);
    await app.close();
  });

  testWidgets('a timed exercise checks its answers, with the practice label', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    final stage = privateSectorStyle.stages[1].copyWith(
      exercises: [ExerciseKind.spreadsheet, ExerciseKind.inTray, ExerciseKind.reasoning],
    );
    await app.run(home: ExercisePage(stage));
    await app.tapText('Start the clock');
    expect(find.textContaining('Time left'), findsOneWidget);
    expect(find.text(practiceFormatLabel), findsOneWidget);
    await app.enter('Answer 1', '310');
    await app.enter('Answer 2', 'North');
    await app.tap(find.byTooltip('Move up').at(1));
    await app.tap(find.text(reasoningItems.first.options[reasoningItems.first.answer]));
    await app.tapText('Check my answers');
    expect(find.text('Right: 310'), findsOneWidget);
    expect(find.textContaining('The answer is East'), findsOneWidget);
    expect(find.text('One reasonable order'), findsOneWidget);
    expect(find.textContaining('Right. '), findsOneWidget);
    expect(find.text('On to the interview'), findsOneWidget);
    await app.close();
  });

  testWidgets('presentation prep runs a clock and keeps the notes in memory', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    final stage = civilServiceStyle.stages[2].copyWith(prepTime: const Duration(seconds: 2));
    await app.run(home: PresentationPrepPage(stage));
    expect(find.text(stage.brief), findsOneWidget);
    await app.tapText('Start preparing');
    expect(find.textContaining('Preparation left'), findsOneWidget);
    await app.enter('Your notes (shown while you present; never saved)', 'Answer first. Three points.');
    await app.settle();
    expect(find.text('Time to present.'), findsOneWidget);
    expect(find.text('Ready to present'), findsOneWidget);
    await app.close();
  });
}
