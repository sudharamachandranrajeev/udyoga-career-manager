// J6: Udyoga scores on the same engine path as Vidya: twice with the
// criteria shuffled, disputes that re-check only the quote and criterion,
// strengths that quote their line, and "improve my answer" refused when it
// invents. Old rounds scored once still read. Fictional role and answers.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/interview_book.dart';
import 'package:udyoga/domain/interview_brain.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/ui/interview_debrief_page.dart';

import 'app_harness.dart';

const _at = '2026-11-22T10:00';

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

const _quote = 'I rang each patient on the list';

/// Scores by the request's shape; the second scoring run gives c1 one
/// level lower, so the runs disagree.
class _FakeAi implements Ai {
  final asked = <Json>[];
  var runs = 0;
  String rewrite = 'I rang each patient on the list and moved the overflow to a Tuesday.';

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
    asked.add(schema);
    final keys = (schema['properties'] as Map).keys.toSet();
    if (keys.contains('answer')) return AiResult({'answer': rewrite});
    runs++;
    return AiResult({
      'answers': [
        {
          'question': 2,
          'scores': [
            {'criterion': 'c1', 'level': runs == 1 ? '3' : '2', 'quote': _quote},
          ],
          'strength': 'Wonderful, a superb answer.',
          'strengthQuote': '',
          'fix': 'Say what you learned. Then add more. Then smile.',
        },
      ],
    });
  }
}

DebriefRound _round() => DebriefRound.of(
  questions: questionsFromProfile(_profile.copyWith(criteria: _profile.criteria)),
  answers: {1: _good},
  profile: _profile,
);

void main() {
  test('Udyoga scores twice through its own AI adapter, with the criteria in two orders', () async {
    final ai = _FakeAi();
    final round = _round();
    final runs = await scoreTwice(
      brain: AiInterviewBrain(ai),
      role: 'Practice administrator',
      framework: _profile.framework,
      round: round,
    );
    expect(runs, hasLength(2));
    expect(ai.runs, 2);
    final v = verifyRuns(runs, _profile.framework.scale, round);
    final c1 = v.scores.firstWhere((s) => s.criterionId == 'c1');
    expect((c1.level.code, c1.uncertain), ('2', true));
    expect(v.answers[1]!.strength, '', reason: 'praise with no quoted line is not shown');
    expect(v.answers[1]!.fix, 'Say what you learned.');
    final r = recheckScore(
      c1,
      round: round,
      scale: _profile.framework.scale,
      pushback: 'I think that deserves a 4.',
    );
    expect(r.score.level.code, '2');
  });

  test('a rewrite that invents is refused; one in the candidate\'s words stands', () async {
    final ai = _FakeAi()..rewrite = 'I rang 140 patients and won a team award.';
    final bad = await improveAnswer(brain: AiInterviewBrain(ai), question: 'Q', answer: _good);
    expect(bad.refused, isTrue);
    expect(bad.invented, containsAll(['140', 'won', 'award']));
    final ok = await improveAnswer(brain: AiInterviewBrain(_FakeAi()), question: 'Q', answer: _good);
    expect(ok.ok, isTrue);
    final none = await improveAnswer(brain: AiInterviewBrain(ai), question: 'Q', answer: '');
    expect(none.message, noAttemptNote);
  });

  testWidgets('the debrief reads both runs: uncertain, the next anchor, a quoted strength and a dispute', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    late String round;
    await app.open(
      seed: (book) async {
        final id = await book.saveRoleProfile(_profile, at: _at);
        round = await book.startProfileRound((await book.roleProfile(id))!, at: _at);
        await book.saveTranscript(round, 1, _good, at: _at);
        AnswerScore run(String level) => AnswerScore(
          question: 1,
          scores: [CriterionScore(criterionId: 'c1', code: level, quote: _quote)],
          strength: 'You said what you did.',
          strengthQuote: _quote,
          fix: 'Say what you learned.',
        );
        await book.saveScoring(round, {
          'framework': 'nhs_values',
          'engine': engineVersion,
          'runs': [
            [run('3').toJson()],
            [run('2').toJson()],
          ],
        });
      },
    );
    await app.run(home: DebriefPage(round));
    expect(find.textContaining('Experience of managing a busy diary: 2'), findsOneWidget);
    expect(find.text(uncertainNote), findsOneWidget);
    expect(find.textContaining('Next level (3):'), findsOneWidget);
    expect(find.byKey(const Key('strength-quote-1')), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await app.tap(find.text('What they expected'));
    expect(find.textContaining(noSourcesNote), findsNWidgets(2));

    await app.tap(find.byKey(const Key('dispute-c1')));
    await app.enter('What do you think it missed? (optional)', 'I think that deserves a 4.');
    await app.tapText('Check again');
    expect(find.text('The score stands'), findsOneWidget);
    await app.tapText('OK');
    await app.close();
  });

  test('a round scored once before J6 still reads', () {
    final round = _round();
    final saved = jsonEncode({
      'framework': 'nhs_values',
      'answers': [
        AnswerScore(
          question: 1,
          scores: const [CriterionScore(criterionId: 'c1', code: '3', quote: _quote)],
        ).toJson(),
      ],
    });
    final v = InterviewBook.verifiedOf(saved, round, _profile.framework)!;
    expect(v.scores.single.level.code, '3');
    expect(v.scores.single.uncertain, isFalse);
    expect(InterviewBook.verifiedOf('', round, _profile.framework), isNull);
  });
}
