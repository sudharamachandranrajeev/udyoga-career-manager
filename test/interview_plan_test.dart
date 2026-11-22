import 'package:brahma_core/brahma_core.dart' show Store;
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/common_questions.dart';

import 'support.dart';

// Question plans, probes, personas and processes are tested in the interview
// engine package. These tests check Udyoga's side: its built-in questions
// and the round settings it keeps on the device.

void main() {
  test('every built-in common question has a plan; the example questions are probed', () {
    final plans = [for (final q in commonQuestions) templatePlan(q)];
    expect(plans.first.expected, isEmpty, reason: 'motivation');
    expect(plans[1].expected, contains(AnswerElement.ownAction));
    expect(plans.last.expected, isEmpty);
    expect(mergePlans(commonQuestions, const []), hasLength(commonQuestions.length));
  });

  test('round settings are kept on the device', () async {
    final db = memoryDatabase();
    final book = CareerBook(await Store.open(db));
    expect((await book.roundSettings()).persona, PersonaKind.neutral);
    await book.setRoundSettings(
      const RoundSettings(
        persona: PersonaKind.quiet,
        level: 4,
        endSilence: Duration(seconds: 8),
        aiPlan: false,
      ),
    );
    final back = await book.roundSettings();
    expect(
      [back.persona, back.level, back.endSilence, back.aiPlan],
      [PersonaKind.quiet, 4, const Duration(seconds: 8), false],
    );
    await db.close();
  });
}
