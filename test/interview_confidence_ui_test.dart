import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' show SectionCard;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/interview_confidence.dart';
import 'package:udyoga/ui/interview_confidence_ui.dart';
import 'package:udyoga/ui/interview_page.dart';

import 'app_harness.dart';

void main() {
  testWidgets('the Interview page leads with what you are ready for, then sends the drills', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (b) async {
        for (final (day, before, after) in [('2026-11-17', 5, 3), ('2026-11-19', 3, 2)]) {
          final id = await b.startPractice(
            role: 'Common questions',
            mode: 'standard',
            questions: commonQuestions.take(1).toList(),
            at: '${day}T10:00',
          );
          await b.saveNerves(id, before: before, after: after);
        }
      },
    );
    await app.run(home: const InterviewPage());

    // Confidence first: the ready card is the first card on the page.
    final cards = find.byType(SectionCard);
    expect(tester.widget<SectionCard>(cards.first).title, 'What you\'re ready for');
    expect(find.byType(NervesChart), findsOneWidget);
    expect(find.textContaining('Before a round you went from overwhelmed to nervous.'), findsOneWidget);

    // The drills: the questions set is the candidate's, then off to Vidya.
    expect(find.text('Drills in Vidya'), findsOneWidget);
    expect(find.text(defaultQuestionsForThem.first), findsOneWidget);
    await app.tapText('Edit my questions');
    await app.enter('One per line', 'How is a new starter supported?');
    await app.tapText('Save');
    expect(find.text('How is a new starter supported?'), findsOneWidget);
    await app.tapText('Send drills to Vidya');
    final row = await tester.runAsync(
      () => (app.book.db.select(
        app.book.db.bridgeStudyPlans,
      )..where((p) => p.id.equals(drillsPlanId))).getSingle(),
    );
    final cardsSent = (jsonDecode(row!.plan) as Map)['cards'] as List;
    expect(
      cardsSent.cast<Map>().firstWhere((c) => c['id'] == 'udyoga.drill.questions')['back'],
      '- How is a new starter supported?',
    );
    expect(find.text('Send drills again'), findsOneWidget);
    await app.close();
  });
}
