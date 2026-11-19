import 'dart:async';

import 'package:brahma_core/brahma_core.dart' show Store;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/interview_process.dart';
import 'package:udyoga/voice/round.dart';
import 'package:udyoga/voice/round_engines.dart' show answerEnded;

import 'spoken_round_test.dart' show FakeListener, FakeVoice, ListSink, MemoryTakes, s, spoken;
import 'support.dart';

/// Fictional answers, written for these tests.
const fullAnswer =
    'In my last role at Example Clinic, two people were off sick one weekend. I rang the bank staff, moved the '
    'training day and told the manager. As a result every shift was covered, and complaints about cover fell '
    'from 6 to 1 that month. I learned to keep a list of bank staff ready, and next time I would ask earlier.';

/// The I1 fixture answer: no measure and no learning.
const rotaAnswer =
    'Um, at the time I ran the weekend rota for a small team at Example Clinic, and two people were off. '
    'So I, like, rang the bank staff, uh, moved the training day and told the manager the same morning. '
    'Every shift was covered and we used the plan again the next winter.';

const weAnswer = 'We had a backlog last winter. We sat down as a team, we split the work and we cleared it.';

const assertion = 'I possess excellent communication skills and I always work hard.';

const behaviouralQ = PracticeQuestion({
  'question': 'Tell us about a time you covered a gap at short notice.',
  'category': 'Behavioural',
  'why': 'Problem solving under pressure.',
});

final behavioural = templatePlan(behaviouralQ);

void main() {
  group('element detection on fixture transcripts', () {
    test('a full answer covers all six elements', () {
      expect(detectElements(fullAnswer), AnswerElement.values.toSet());
    });

    test('the rota answer lacks a measure and a learning', () {
      expect(detectElements(rotaAnswer), {
        AnswerElement.situation,
        AnswerElement.ownAction,
        AnswerElement.result,
        AnswerElement.others,
      });
      // "I ran", "rang", "moved" and "told": fillers and commas do not hide them.
      expect(ownActions(rotaAnswer), 4);
    });

    test('"we" all the way through is not the speaker\'s own action', () {
      final e = detectElements(weAnswer);
      expect(e, isNot(contains(AnswerElement.ownAction)));
      expect(e, containsAll([AnswerElement.situation, AnswerElement.others]));
      expect(ownActions(weAnswer), 0);
    });

    test('an assertion with no example has no situation, action or result', () {
      final e = detectElements(assertion);
      for (final x in [AnswerElement.situation, AnswerElement.ownAction, AnswerElement.result]) {
        expect(e, isNot(contains(x)));
      }
    });

    test('a plan for a situational question counts as own action', () {
      expect(
        detectElements(
          'I would check the rota first, then I\'d call the manager and agree the order with the team, so that '
          'the clinic stays safe.',
        ),
        containsAll([AnswerElement.ownAction, AnswerElement.others, AnswerElement.result]),
      );
    });

    test('figures and checks are measures; feelings are not actions', () {
      expect(detectElements('It cut waiting from 40 minutes to 25.'), contains(AnswerElement.measure));
      expect(detectElements('We ran a survey afterwards.'), contains(AnswerElement.measure));
      expect(ownActions('I needed help and I worried about it.'), 0);
      expect(detectElements(''), isEmpty);
    });
  });

  group('probe choice', () {
    test('picks the first missing element, with the built-in wording', () {
      final p = ProbePicker.next(plan: behavioural, heard: rotaAnswer, asked: const []);
      expect(p, const Probe(AnswerElement.measure, 'How did you measure this?'));
    });

    test('never more than two, never the same element or wording twice', () {
      const m = Probe(AnswerElement.measure, 'How did you measure this?');
      final second = ProbePicker.next(plan: behavioural, heard: rotaAnswer, asked: const [m]);
      expect(second, const Probe(AnswerElement.learning, 'What did you learn?'));
      expect(ProbePicker.next(plan: behavioural, heard: rotaAnswer, asked: [m, second!]), isNull);
      // Even a plan asking for more stops at two.
      expect(ProbePicker.next(plan: behavioural, heard: assertion, asked: [m, second], limit: 5), isNull);
    });

    test('an element filled by a follow-up answer is not probed again', () {
      final heard = '$rotaAnswer We counted the complaints: they fell from 6 to 1.';
      expect(
        ProbePicker.next(plan: behavioural, heard: heard, asked: const [])!.element,
        AnswerElement.learning,
      );
    });

    test('the level limit, the earlier stage\'s focus and the plan\'s own wording', () {
      const m = Probe(AnswerElement.measure, 'How did you measure this?');
      expect(ProbePicker.next(plan: behavioural, heard: rotaAnswer, asked: const [m], limit: 1), isNull);
      expect(ProbePicker.next(plan: behavioural, heard: rotaAnswer, asked: const [], limit: 0), isNull);
      expect(
        ProbePicker.next(
          plan: behavioural,
          heard: rotaAnswer,
          asked: const [],
          focus: const [AnswerElement.learning],
        ),
        const Probe(AnswerElement.learning, 'What did you learn?'),
      );
      const own = QuestionPlan(
        criterion: 'Cover',
        expected: [AnswerElement.measure],
        probes: [Probe(AnswerElement.measure, 'How did you know the new rota worked?')],
      );
      expect(
        ProbePicker.next(plan: own, heard: rotaAnswer, asked: const [])!.text,
        startsWith('How did you know'),
      );
      // The plan's wording used, the built-in comes next for the same element only if not yet probed.
      expect(
        ProbePicker.next(
          plan: own,
          heard: rotaAnswer,
          asked: const [Probe(AnswerElement.measure, 'How did you know the new rota worked?')],
        ),
        isNull,
      );
    });

    test('nothing missing, or nothing expected, means no probe', () {
      expect(ProbePicker.next(plan: behavioural, heard: fullAnswer, asked: const []), isNull);
      final motivation = templatePlan(commonQuestions.first);
      expect(motivation.expected, isEmpty);
      expect(ProbePicker.next(plan: motivation, heard: assertion, asked: const []), isNull);
    });
  });

  group('plans with no AI', () {
    test('templates by kind of question', () {
      List<AnswerElement> of(String cat, [String q = 'Q?']) => expectedFor(cat, q);
      expect(of('Settler'), isEmpty);
      expect(of('Strengths'), isEmpty);
      expect(of('Closing'), isEmpty);
      expect(of('Values'), [AnswerElement.situation, AnswerElement.ownAction, AnswerElement.learning]);
      expect(of('Behavioural'), hasLength(6));
      expect(of('', 'Tell us about a time you led a change.'), hasLength(6));
      expect(of('Situational'), contains(AnswerElement.others));
      // Every common question has a plan; the example questions are probed.
      final plans = [for (final q in commonQuestions) templatePlan(q)];
      expect(plans[1].expected, contains(AnswerElement.ownAction));
      expect(plans.last.expected, isEmpty);
    });

    test('the AI plan is used where sound and the template fills the gaps', () {
      final qs = [behaviouralQ, commonQuestions.first, behaviouralQ];
      final fromAi = [
        QuestionPlan.fromJson({
          'criterion': 'Cover at short notice',
          'expected': ['ownAction', 'measure', 'nonsense'],
          'probes': [
            {'element': 'measure', 'text': 'How did you know every shift was safe?'},
            {'element': 'bogus', 'text': 'x'},
            {'element': 'learning', 'text': '  '},
          ],
        }),
        const QuestionPlan(criterion: 'Motivation', expected: []),
        // An empty plan for an example question is not trusted.
        const QuestionPlan(criterion: 'Teamwork', expected: []),
      ];
      final merged = mergePlans(qs, fromAi);
      expect(merged[0].expected, [AnswerElement.ownAction, AnswerElement.measure]);
      expect(merged[0].probes.single.text, contains('every shift'));
      expect(merged[1].expected, isEmpty);
      expect(merged[2].expected, hasLength(6));
      expect(mergePlans(qs, const []).map((p) => p.expected.length), [6, 0, 6]);
      expect(QuestionPlan.fromJson(merged[0].toJson()).toJson(), merged[0].toJson());
    });
  });

  group('personas and the ladder', () {
    test('quiet says nothing after an answer and waits longest', () {
      final quiet = Persona.of(PersonaKind.quiet);
      expect(quiet.acknowledgement(0), isEmpty);
      expect(quiet.silenceNote, contains('Silence'.toLowerCase()));
      for (final p in personas.values.where((p) => p.kind != PersonaKind.quiet)) {
        expect(quiet.gapAfterAnswer, greaterThan(p.gapAfterAnswer));
        expect(quiet.gapBeforeProbe, greaterThan(p.gapBeforeProbe));
        expect(p.acknowledgement(0), isNotEmpty);
      }
      final friendly = Persona.of(PersonaKind.friendly);
      expect({for (var i = 0; i < 3; i++) friendly.acknowledgement(i)}, hasLength(3));
    });

    test('the ladder adds probes, interruptions and a tighter clock', () {
      expect([for (final l in ladder) l.probes], [0, 1, 2, 2, 2]);
      expect([for (final l in ladder) l.interrupts], [false, false, false, true, true]);
      expect(Ladder.of(0).level, 1);
      expect(Ladder.of(9).level, 5);
      expect(answerBudget(behaviouralQ, Ladder.of(1)), isNull);
      expect(answerBudget(behaviouralQ, Ladder.of(3)), const Duration(seconds: 150));
      expect(answerBudget(behaviouralQ, Ladder.of(5)), const Duration(milliseconds: 112500));
      const slot = PracticeQuestion({
        'question': 'Present.',
        'category': 'Presentation',
        'seconds': 300,
        'fixedTime': true,
      });
      expect(answerBudget(slot, Ladder.of(5)), const Duration(minutes: 5));
      expect(
        answerBudget(const PracticeQuestion({'category': 'Strengths'}), Ladder.of(3)),
        const Duration(seconds: 45),
      );
    });

    test('the probing persona asks one more, still at most two', () {
      Interviewer iv(PersonaKind k, int level) =>
          Interviewer(persona: Persona.of(k), level: Ladder.of(level), plans: const []);
      expect(iv(PersonaKind.neutral, 2).probeLimit, 1);
      expect(iv(PersonaKind.probing, 2).probeLimit, 2);
      expect(iv(PersonaKind.probing, 3).probeLimit, 2);
      expect(iv(PersonaKind.probing, 1).probeLimit, 0);
    });

    test('round settings keep the silence between 3 and 10 seconds, 5 by default', () async {
      expect(const RoundSettings().endSilence, const Duration(seconds: 5));
      expect(RoundSettings.fromJson(const {'endSilenceSeconds': 30}).endSilence, const Duration(seconds: 10));
      expect(RoundSettings.fromJson(const {'endSilenceSeconds': 1}).endSilence, const Duration(seconds: 3));
      expect(RoundSettings.fromJson(const {}).level, 3);
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
  });

  group('end of an answer', () {
    test('pauses to think under the threshold never end the answer', () {
      bool ended(int heard, int last, int seconds) => answerEnded(
        heardMs: heard,
        firstSpeechMs: 500,
        lastSpeechMs: last,
        endSilence: Duration(seconds: seconds),
      );
      // A 4.5 s pause to think with a 5 s threshold, however late in the answer.
      expect(ended(24500, 20000, 5), isFalse);
      expect(ended(64500, 60000, 5), isFalse);
      expect(ended(25000, 20000, 5), isTrue);
      // A 9 s pause with the threshold at 10 s.
      expect(ended(29000, 20000, 10), isFalse);
      expect(ended(30000, 20000, 10), isTrue);
      // Nothing said, or a cough, never ends it.
      expect(answerEnded(heardMs: 60000, firstSpeechMs: -1, lastSpeechMs: -1, endSilence: s(3)), isFalse);
      expect(answerEnded(heardMs: 60000, firstSpeechMs: 1000, lastSpeechMs: 1800, endSilence: s(3)), isFalse);
    });
  });

  group('the interviewer in a round', () {
    late FakeVoice voice;
    late FakeListener listener;
    late ListSink sink;
    late List<Duration> pauses;
    late SpokenRound round;

    const qs = [
      RoundQuestion('Tell us about a time you covered a gap at short notice.', tests: 'Problem solving.'),
      RoundQuestion('Why this role?', tests: 'Motivation.'),
    ];

    SpokenRound make(
      List<CapturedAnswer> answers, {
      PersonaKind persona = PersonaKind.neutral,
      int level = 3,
      List<AnswerElement> focus = const [],
      String opening = '',
      Duration endSilence = const Duration(seconds: 5),
    }) {
      voice = FakeVoice();
      listener = FakeListener(answers);
      sink = ListSink();
      pauses = [];
      final l = Ladder.of(level);
      return round = SpokenRound(
        questions: qs,
        voice: voice,
        listener: listener,
        takes: MemoryTakes(),
        sink: sink,
        endSilence: endSilence,
        pause: (d) async => pauses.add(d),
        interviewer: Interviewer(
          persona: Persona.of(persona),
          level: l,
          plans: [behavioural, templatePlan(commonQuestions.first)],
          budgets: [answerBudget(behaviouralQ, l), null],
          focus: focus,
          opening: opening,
        ),
      )..start();
    }

    test('follows up on what is missing, twice at most, then says thank you', () async {
      make([
        spoken(rotaAnswer, seconds: 30),
        spoken('We counted complaints about cover: they fell from 6 to 1.'),
        spoken('Honestly, it went fine.'),
      ]);
      await round.ask();
      await round.done();
      // The gap, then the probe for the first missing element.
      expect(voice.said.last, 'How did you measure this?');
      expect(round.phase, RoundPhase.answering);
      expect(round.followingUp, isTrue);
      expect(round.followUpQuestion, 'How did you measure this?');
      await round.done();
      expect(voice.said.last, 'What did you learn?');
      await round.done();
      // Learning is still missing, but two is the most.
      expect(round.phase, RoundPhase.review);
      expect(voice.said.last, 'Thank you.');
      final neutral = Persona.of(PersonaKind.neutral);
      expect(pauses, [neutral.gapBeforeProbe, neutral.gapBeforeProbe, neutral.gapAfterAnswer]);
      final st = round.state;
      expect(st.followUps.map((f) => f.probe!.element), [AnswerElement.measure, AnswerElement.learning]);
      expect(sink.saved.last.$2, contains('Follow-up: "How did you measure this?"\nWe counted'));
      final c = round.coverage(0)!;
      expect(c.heard, contains(AnswerElement.measure));
      expect(round.outcomes().single.missed, [AnswerElement.learning]);
      // A question with nothing expected goes straight to the thank you.
      round.next();
      await round.ask();
      await round.done();
      expect(round.phase, RoundPhase.review);
      expect(voice.said.last, 'Thank you. Moving on.');
      expect(round.state.followUps, isEmpty);
    });

    test('the quiet panel says nothing and leaves longer gaps', () async {
      make([spoken(fullAnswer)], persona: PersonaKind.quiet);
      await round.ask();
      await round.done();
      expect(round.phase, RoundPhase.review);
      expect(voice.said, [qs[0].text]);
      expect(pauses, [Persona.of(PersonaKind.quiet).gapAfterAnswer]);
    });

    test('level 1 never probes; an earlier stage\'s gap is probed first', () async {
      make([spoken(rotaAnswer)], level: 1);
      await round.ask();
      await round.done();
      expect(round.state.followUps, isEmpty);
      expect(round.phase, RoundPhase.review);

      make([spoken(rotaAnswer), spoken('x')], focus: const [AnswerElement.learning]);
      await round.ask();
      await round.done();
      expect(voice.said.last, 'What did you learn?');
    });

    test('at level 5 an answer over time is stopped and a one-sentence wrap-up asked for', () async {
      make([spoken(rotaAnswer, seconds: 120), spoken('So every shift was covered.')], level: 5);
      await round.ask();
      final capture = listener.captures.single;
      capture.statuses.add(ListenStatus(elapsed: s(100), heardSpeech: true));
      await pumpEventQueue();
      expect(round.phase, RoundPhase.answering);
      capture.statuses.add(ListenStatus(elapsed: s(113), heardSpeech: true));
      await pumpEventQueue();
      expect(voice.said.last, interruptLine);
      expect(round.wrappingUp, isTrue);
      expect(round.budget, wrapUpTime);
      await round.done();
      expect(round.phase, RoundPhase.review);
      final st = round.state;
      expect(st.interrupted, isTrue);
      expect(st.followUps.single.kind, FollowUpKind.wrapUp);
      expect(st.fullTranscript, contains('Wrap-up:'));
      // No probes after an interruption: time is up.
      expect(st.probes, isEmpty);
      expect(round.outcomes().single.interrupted, isTrue);
    });

    test('level 4 lets an answer run 15 s past the time before stopping it', () async {
      make([spoken(rotaAnswer), spoken('x')], level: 4);
      await round.ask();
      final capture = listener.captures.single;
      capture.statuses.add(ListenStatus(elapsed: s(160), heardSpeech: true));
      await pumpEventQueue();
      expect(round.phase, RoundPhase.answering);
      expect(round.followingUp, isFalse);
      capture.statuses.add(ListenStatus(elapsed: s(166), heardSpeech: true));
      await pumpEventQueue();
      expect(round.wrappingUp, isTrue);
    });

    test('a typed answer gets typed follow-ups; Move on ends the question', () async {
      make([spoken('unused')]);
      await round.typeInstead();
      await round.submitTyped(rotaAnswer);
      expect(voice.said.last, 'How did you measure this?');
      expect(round.phase, RoundPhase.typing);
      expect(round.followingUp, isTrue);
      await round.submitTyped('We counted complaints: 6 down to 1.');
      expect(round.state.followUps.single.take.typed, isTrue);
      expect(round.followUpQuestion, 'What did you learn?');
      await round.moveOn();
      expect(round.phase, RoundPhase.review);
      expect(round.state.followUps, hasLength(1));
      expect(listener.captures, isEmpty);
    });

    test('a re-take starts the follow-ups again; the opening is said once', () async {
      make([spoken(fullAnswer)], opening: 'Thank you for coming.', endSilence: const Duration(seconds: 8));
      await round.ask();
      expect(voice.said.first, 'Thank you for coming. ${qs[0].text}');
      await round.done();
      await round.retake();
      expect(voice.said.where((t) => t == qs[0].text), hasLength(1));
      expect(listener.endSilences, [const Duration(seconds: 8), const Duration(seconds: 8)]);
    });
  });

  group('stages and processes', () {
    test('three generic templates; optional stages can be left out', () {
      expect(processTemplates.map((p) => p.name), ['NHS-style', 'Civil Service-style', 'Private sector']);
      expect(nhsStyle.stages.map((s) => s.kind), [
        StageKind.screening,
        StageKind.panel,
        StageKind.presentation,
      ]);
      expect(nhsStyle.running.map((s) => s.kind), [StageKind.screening, StageKind.panel]);
      final withTalk = nhsStyle.withStage(2, nhsStyle.stages[2].copyWith(included: true));
      expect(withTalk.running, hasLength(3));
      expect(civilServiceStyle.stages[1].questions.where((q) => q.category == 'Strengths'), hasLength(2));
      expect(privateSectorStyle.stages.last.kind, StageKind.finalStage);
    });

    test('each stage: settler first, its own times, and the interrupt script', () {
      final panel = nhsStyle.stages[1];
      final qs = panel.roundQuestions();
      expect(qs.first.category, 'Settler');
      expect(templatePlan(qs.first).expected, isEmpty);
      expect(qs.first.j['seconds'], 60);
      expect(qs[1].j['seconds'], panel.answerTime.inSeconds);
      expect(
        panel.opening(Persona.of(PersonaKind.neutral)),
        allOf(contains('panel interview'), contains(mayInterruptScript)),
      );

      final talk = civilServiceStyle.stages[2];
      final tq = talk.roundQuestions();
      expect(tq[1].category, 'Presentation');
      expect(answerBudget(tq[1], Ladder.of(5)), talk.deliveryTime);
      // Strengths questions keep their short clock.
      final blended = civilServiceStyle.stages[1].roundQuestions();
      final strength = blended.firstWhere((q) => q.category == 'Strengths');
      expect(answerBudget(strength, Ladder.of(3)), const Duration(seconds: 45));
    });

    test('a process survives JSON, edits included', () {
      final edited = privateSectorStyle.withStage(
        0,
        privateSectorStyle.stages[0].copyWith(
          persona: PersonaKind.quiet,
          answerTime: const Duration(seconds: 45),
        ),
      );
      final back = InterviewProcess.fromJson(edited.toJson());
      expect(back.toJson(), edited.toJson());
      expect(back.stages[0].persona, PersonaKind.quiet);
      expect(back.stages[1].exercises, [ExerciseKind.spreadsheet, ExerciseKind.inTray]);
    });

    test('exercises have checkable answers and a labelled practice format', () {
      expect(practiceFormatLabel, 'Practice format, not the real test');
      expect(inTrayCloseCount(inTrayOrder), inTrayOrder.length);
      expect(inTrayCloseCount(inTrayOrder.reversed.toList()), lessThan(3));
      expect(spreadsheetTasks[0].check('310'), isTrue);
      expect(spreadsheetTasks[1].check(' East '), isTrue);
      expect(spreadsheetTasks[2].check('9.2%'), isTrue);
      expect(spreadsheetTasks[2].check('9.5'), isFalse);
      expect(spreadsheetTasks[3].check('sum(b2:d2)'), isTrue);
      // The table agrees with the answers.
      expect(spreadsheetRows[1].skip(1).cast<int>().reduce((a, b) => a + b), 310);
      for (final r in reasoningItems) {
        expect(r.answer, inInclusiveRange(0, r.options.length - 1));
      }
    });
  });

  group('feedback carries forward', () {
    QuestionOutcome q(List<AnswerElement> heard, {bool interrupted = false}) =>
        QuestionOutcome(expected: behavioural.expected, heard: heard.toSet(), interrupted: interrupted);

    test('the most-missed elements become the fixes and the next probes', () {
      final stage1 = [
        q([AnswerElement.situation, AnswerElement.ownAction, AnswerElement.result, AnswerElement.others]),
        q([AnswerElement.situation, AnswerElement.ownAction, AnswerElement.result, AnswerElement.learning]),
      ];
      final c = CarryForward.from([stage1]);
      expect(c.focus.first, AnswerElement.measure);
      expect(c.fixes.first, elementFixes[AnswerElement.measure]);
      expect(c.fixes, hasLength(3));
      expect(c.keep, contains('You said what you yourself did.'));
      // The next stage's first probe goes for the measure.
      final p = ProbePicker.next(
        plan: behavioural,
        heard: 'I sorted it and I rang them.',
        asked: const [],
        focus: c.focus,
      );
      expect(p!.element, AnswerElement.measure);
    });

    test('running over time comes first; the latest stage counts most', () {
      final c = CarryForward.from([
        [q(AnswerElement.values.where((e) => e != AnswerElement.others).toList())],
        [q(AnswerElement.values.where((e) => e != AnswerElement.learning).toList(), interrupted: true)],
      ]);
      expect(c.fixes.first, overTimeFix);
      expect(c.focus, [AnswerElement.learning, AnswerElement.others]);
    });

    test('nothing to carry from a stage of settlers', () {
      expect(CarryForward.from(const []).isEmpty, isTrue);
      expect(
        CarryForward.from([
          [const QuestionOutcome(expected: [], heard: {})],
        ]).isEmpty,
        isTrue,
      );
    });

    test('a round reports what each answer covered for the next stage', () async {
      final r = SpokenRound(
        questions: const [RoundQuestion('Tell us about a time you covered a gap.')],
        voice: FakeVoice(),
        listener: FakeListener([spoken(weAnswer)]),
        takes: MemoryTakes(),
        sink: ListSink(),
        pause: (_) async {},
        interviewer: Interviewer(
          persona: Persona.of(PersonaKind.neutral),
          level: Ladder.of(1),
          plans: [behavioural],
        ),
      )..start();
      await r.ask();
      await r.done();
      final c = CarryForward.from([r.outcomes()]);
      expect(c.focus.first, AnswerElement.ownAction);
      expect(c.fixes.first, contains('yourself'));
      unawaited(r.close());
    });
  });
}
