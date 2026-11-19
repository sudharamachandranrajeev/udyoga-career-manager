/// A whole interview process to rehearse, stage by stage (interview plan
/// I2): a screening call, a test or exercise, a panel, a presentation and a
/// final interview. Each stage has its own timers, a settler question and
/// the "I may interrupt you" script. What the last stage missed carries
/// forward: the next stage opens with the fixes, and its follow-ups aim at
/// those gaps first.
///
/// The templates are generic and every part is editable. Employers vary:
/// these show the usual shape of each kind of process, not any employer's
/// own. All exercise content is made up for practice.
library;

import 'insights.dart';
import 'interview_plan.dart';
import 'json.dart';

enum StageKind {
  screening('Screening call'),
  exercise('Test or exercise'),
  panel('Panel interview'),
  presentation('Presentation'),
  finalStage('Final interview');

  const StageKind(this.label);
  final String label;

  static StageKind byName(String n) => values.where((k) => k.name == n).firstOrNull ?? panel;
}

enum ExerciseKind {
  inTray('In-tray: put the tasks in order'),
  spreadsheet('Spreadsheet task'),
  reasoning('Reasoning questions');

  const ExerciseKind(this.label);
  final String label;

  static ExerciseKind? byName(String n) => values.where((k) => k.name == n).firstOrNull;
}

/// Shown on every reasoning exercise: the real tests are not published.
const practiceFormatLabel = 'Practice format, not the real test';

PracticeQuestion _q(String text, String category, String tests, [List<String> lookFor = const []]) =>
    PracticeQuestion({'question': text, 'category': category, 'why': tests, 'lookFor': lookFor});

/// One stage of a process.
class InterviewStage {
  const InterviewStage({
    required this.kind,
    required this.title,
    required this.about,
    required this.settler,
    this.questions = const [],
    this.persona = PersonaKind.neutral,
    this.answerTime = const Duration(seconds: 150),
    this.optional = false,
    this.included = true,
    this.exercises = const [],
    this.exerciseTime = const Duration(minutes: 10),
    this.brief = '',
    this.prepTime = const Duration(minutes: 10),
    this.deliveryTime = const Duration(minutes: 5),
  });

  final StageKind kind;
  final String title;

  /// What happens at this stage, in a line or two.
  final String about;

  /// The easy opening question.
  final PracticeQuestion settler;
  final List<PracticeQuestion> questions;
  final PersonaKind persona;

  /// The time for each main answer, before the ladder.
  final Duration answerTime;

  /// Optional stages can be left out.
  final bool optional;
  final bool included;

  /// Done before the spoken part (a test or exercise stage).
  final List<ExerciseKind> exercises;
  final Duration exerciseTime;

  /// The presentation topic; empty for other stages.
  final String brief;
  final Duration prepTime;
  final Duration deliveryTime;

  bool get presents => brief.isNotEmpty;

  InterviewStage copyWith({
    String? title,
    PracticeQuestion? settler,
    List<PracticeQuestion>? questions,
    PersonaKind? persona,
    Duration? answerTime,
    bool? included,
    List<ExerciseKind>? exercises,
    Duration? exerciseTime,
    String? brief,
    Duration? prepTime,
    Duration? deliveryTime,
  }) => InterviewStage(
    kind: kind,
    title: title ?? this.title,
    about: about,
    settler: settler ?? this.settler,
    questions: questions ?? this.questions,
    persona: persona ?? this.persona,
    answerTime: answerTime ?? this.answerTime,
    optional: optional,
    included: included ?? this.included,
    exercises: exercises ?? this.exercises,
    exerciseTime: exerciseTime ?? this.exerciseTime,
    brief: brief ?? this.brief,
    prepTime: prepTime ?? this.prepTime,
    deliveryTime: deliveryTime ?? this.deliveryTime,
  );

  /// What the interviewer says before the first question: the persona's
  /// greeting, what this stage is, and that they may interrupt.
  String opening(Persona p) => '${p.greeting} This is the ${title.toLowerCase()}. $mayInterruptScript';

  /// The questions as the spoken round asks them: the settler, the
  /// presentation itself when there is one, then the stage's questions,
  /// each with its time.
  List<PracticeQuestion> roundQuestions() => [
    PracticeQuestion({...settler.j, 'category': 'Settler', 'seconds': 60}),
    if (presents)
      PracticeQuestion({
        'question': 'Whenever you are ready, please give your presentation.',
        'category': 'Presentation',
        'why': 'The brief: $brief',
        'lookFor': const [
          'Your answer to the brief in the first 30 seconds',
          'Three points, each with evidence',
          'Risks and next steps',
          'Finishing within the time',
        ],
        'seconds': deliveryTime.inSeconds,
        'fixedTime': true,
      }),
    for (final q in questions)
      PracticeQuestion({
        ...q.j,
        if (intOf(q.j['seconds']) == null && !q.category.toLowerCase().contains('strength'))
          'seconds': answerTime.inSeconds,
      }),
  ];

  Json toJson() => {
    'kind': kind.name,
    'title': title,
    'about': about,
    'settler': settler.j,
    'questions': [for (final q in questions) q.j],
    'persona': persona.name,
    'answerSeconds': answerTime.inSeconds,
    'optional': optional,
    'included': included,
    'exercises': [for (final e in exercises) e.name],
    'exerciseSeconds': exerciseTime.inSeconds,
    'brief': brief,
    'prepSeconds': prepTime.inSeconds,
    'deliverySeconds': deliveryTime.inSeconds,
  };

  factory InterviewStage.fromJson(Json j) {
    Duration secs(String k, int fallback) => Duration(seconds: intOf(j[k]) ?? fallback);
    return InterviewStage(
      kind: StageKind.byName(str(j['kind'])),
      title: str(j['title']),
      about: str(j['about']),
      settler: PracticeQuestion(obj(j['settler'])),
      questions: [for (final q in objs(j['questions'])) PracticeQuestion(q)],
      persona:
          PersonaKind.values.where((p) => p.name == str(j['persona'])).firstOrNull ?? PersonaKind.neutral,
      answerTime: secs('answerSeconds', 150),
      optional: j['optional'] == true,
      included: j['included'] != false,
      exercises: [for (final n in strs(j['exercises'])) ?ExerciseKind.byName(n)],
      exerciseTime: secs('exerciseSeconds', 600),
      brief: str(j['brief']),
      prepTime: secs('prepSeconds', 600),
      deliveryTime: secs('deliverySeconds', 300),
    );
  }
}

/// A whole process: its stages in order.
class InterviewProcess {
  const InterviewProcess({required this.id, required this.name, required this.about, required this.stages});
  final String id;
  final String name;
  final String about;
  final List<InterviewStage> stages;

  /// The stages that will run (optional ones can be switched off).
  List<InterviewStage> get running => [
    for (final s in stages)
      if (s.included) s,
  ];

  InterviewProcess withStage(int i, InterviewStage s) =>
      InterviewProcess(id: id, name: name, about: about, stages: [...stages]..[i] = s);

  Json toJson() => {
    'id': id,
    'name': name,
    'about': about,
    'stages': [for (final s in stages) s.toJson()],
  };

  factory InterviewProcess.fromJson(Json j) => InterviewProcess(
    id: str(j['id']),
    name: str(j['name']),
    about: str(j['about']),
    stages: [for (final s in objs(j['stages'])) InterviewStage.fromJson(s)],
  );
}

// ---- the templates ----

final _currentRole = _q(
  'Could you start by telling me a little about your current role?',
  'Settler',
  'Nothing is scored here: it is to help you settle in.',
);

final _anyQuestions = _q('Do you have any questions for us?', 'Closing', 'Interest and preparation.', [
  'One or two questions about the work or the team',
  'Nothing the advert already answers',
]);

final _exerciseSettler = _q(
  'Thank you for doing the exercise. How did you find it?',
  'Settler',
  'Nothing is scored here: a moment to breathe after the exercise.',
);

final _talkThroughExercise = _q(
  'Talk us through the order you chose and why.',
  'Situational',
  'Judgement and prioritisation: how you weigh urgency, risk and people.',
  ['What you put first and why', 'What you would hand on or ask about', 'Who you would tell'],
);

/// NHS-style: a screening call, a panel with values questions, and an
/// optional presentation. Values come from the employer's own pack; the
/// wording here is a placeholder to edit.
final nhsStyle = InterviewProcess(
  id: 'nhs-style',
  name: 'NHS-style',
  about:
      'Screening call, then a panel with values and competency questions, and sometimes a short '
      'presentation. Trusts differ: swap in the values from the employer\'s own pack.',
  stages: [
    InterviewStage(
      kind: StageKind.screening,
      title: 'Screening call',
      about: 'A short call with the recruiting manager: why this post, and how you fit the person specification.',
      persona: PersonaKind.friendly,
      answerTime: const Duration(seconds: 90),
      settler: _currentRole,
      questions: [
        _q('What interests you about this post?', 'Motivation', 'Why this role and this employer.', [
          'What drew you to the role',
          'Something specific about the employer',
        ]),
        _q(
          'Tell me about a time you organised work for other people at short notice.',
          'Behavioural',
          'Organisation: planning work and keeping people informed.',
          ['One specific example', 'What you yourself did', 'The result'],
        ),
      ],
    ),
    InterviewStage(
      kind: StageKind.panel,
      title: 'Panel interview',
      about:
          'Two or three panel members ask set questions, each tied to a value or a criterion, and take '
          'notes. They may say little: that is how panels are trained.',
      persona: PersonaKind.neutral,
      settler: _q(
        'Tell us about your current responsibilities.',
        'Settler',
        'Nothing is scored here: it is to help you settle in.',
      ),
      questions: [
        _q(
          'One of our values is working together. What does it mean to you, and when have you shown it at work?',
          'Values',
          'Working together: what the value means to you, shown by a real example.',
          ['What the value means to you, briefly', 'One real example', 'What you would keep doing'],
        ),
        _q(
          'Tell us about a time you noticed something that could be done better and made a change.',
          'Behavioural',
          'Improving quality: spotting a problem and acting on it.',
          ['The problem and why it mattered', 'What you yourself did', 'How you knew it worked'],
        ),
        _q(
          'Tell us about a time you dealt with someone who was upset or unhappy with a service.',
          'Behavioural',
          'Respect and compassion: listening and finding a way forward.',
          ['How you listened', 'What you did', 'How it ended, and what you learned'],
        ),
        _anyQuestions,
      ],
    ),
    InterviewStage(
      kind: StageKind.presentation,
      title: 'Presentation',
      about: 'A short presentation on a topic sent in advance, then questions on it.',
      optional: true,
      included: false,
      persona: PersonaKind.neutral,
      settler: _q('Thank you. Are you ready to begin?', 'Settler', 'A moment to get set.'),
      brief:
          'In five minutes, tell us how you would improve one process in your first three months in this '
          'role, and how you would know it had worked.',
      prepTime: const Duration(minutes: 10),
      deliveryTime: const Duration(minutes: 5),
      questions: [
        _q(
          'How would you measure whether your change had worked?',
          'Presentation',
          'Evidence: how you would know.',
        ),
        _q('Who would you need to bring with you on this?', 'Presentation', 'Working with others.'),
      ],
    ),
  ],
);

/// Civil Service-style: Success Profiles. Behaviour questions are scored
/// on evidence; strengths questions are quick and unrehearsed, so they get
/// no follow-ups and a short clock.
final civilServiceStyle = InterviewProcess(
  id: 'civil-service-style',
  name: 'Civil Service-style',
  about:
      'Success Profiles: behaviour questions ("tell us about a time"), quick strengths questions you are not '
      'meant to rehearse, and often a five-minute presentation. An online test may come first.',
  stages: [
    InterviewStage(
      kind: StageKind.exercise,
      title: 'Online test practice',
      about: 'Reasoning questions in a practice format. The real tests are different; this is to get used to a clock.',
      optional: true,
      included: false,
      exercises: const [ExerciseKind.reasoning],
      exerciseTime: const Duration(minutes: 8),
      settler: _exerciseSettler,
      questions: [
        _q(
          'Which question did you find hardest, and how did you go about it?',
          'Situational',
          'How you approach a problem you cannot solve at once.',
        ),
      ],
    ),
    InterviewStage(
      kind: StageKind.panel,
      title: 'Blended interview',
      about:
          'Behaviour questions first, then strengths. The panel scores each behaviour on what you said, so '
          'say what you did and how it turned out.',
      persona: PersonaKind.neutral,
      settler: _currentRole,
      questions: [
        _q(
          'Tell us about a time you had to deliver work to a tight deadline.',
          'Behavioural',
          'Delivering at pace.',
          ['The deadline and what was at stake', 'How you planned and what you did', 'The result'],
        ),
        _q(
          'Tell us about a time you worked with people outside your own team to get something done.',
          'Behavioural',
          'Working together.',
          ['Who was involved', 'Your own part', 'What changed because of it'],
        ),
        _q(
          'Tell us about a time you explained something complicated to someone without your background.',
          'Behavioural',
          'Communicating and influencing.',
          ['Who you were explaining to', 'How you made it clear', 'How you knew they understood'],
        ),
        _q('What kind of work gives you the most energy?', 'Strengths', 'Strengths: what energises you.'),
        _q('How do you feel when plans change at the last minute?', 'Strengths', 'Strengths: adaptability.'),
        _anyQuestions,
      ],
    ),
    InterviewStage(
      kind: StageKind.presentation,
      title: 'Presentation',
      about: 'Five minutes on a topic given in advance; going over time is a common slip.',
      persona: PersonaKind.quiet,
      settler: _q('Thank you. Are you ready to begin?', 'Settler', 'A moment to get set.'),
      brief: 'In five minutes, set out how you would plan your first month in this role, and what you would do first.',
      prepTime: const Duration(minutes: 10),
      deliveryTime: const Duration(minutes: 5),
      questions: [
        _q('What would you do if your plan met resistance?', 'Presentation', 'Influencing and judgement.'),
      ],
    ),
  ],
);

/// Private sector: a recruiter screen, a technical or case stage, and a
/// final interview with a senior leader.
final privateSectorStyle = InterviewProcess(
  id: 'private-sector',
  name: 'Private sector',
  about:
      'A recruiter screen, a technical or case stage (here a spreadsheet task and an in-tray), and a final '
      'interview with a senior leader about fit and why you over others.',
  stages: [
    InterviewStage(
      kind: StageKind.screening,
      title: 'Recruiter screen',
      about: 'A short call: your background, why this company, and the practical questions.',
      persona: PersonaKind.friendly,
      answerTime: const Duration(seconds: 60),
      settler: _currentRole,
      questions: [
        _q('Why are you interested in this company?', 'Motivation', 'Motivation and research.'),
        _q(
          'Walk me through one achievement on your CV that you are proud of.',
          'Behavioural',
          'Evidence of impact.',
          ['What you did', 'The result, with a figure if you have one'],
        ),
      ],
    ),
    InterviewStage(
      kind: StageKind.exercise,
      title: 'Technical or case stage',
      about: 'A short task against the clock, then a case discussion with the hiring manager.',
      persona: PersonaKind.probing,
      exercises: const [ExerciseKind.spreadsheet, ExerciseKind.inTray],
      exerciseTime: const Duration(minutes: 15),
      settler: _exerciseSettler,
      questions: [
        _talkThroughExercise,
        _q(
          'A key client says the last delivery was late and wants a discount. What would you do?',
          'Case',
          'Judgement under pressure, and working with others.',
          ['What you would find out first', 'Who you would involve', 'What you would offer and why'],
        ),
      ],
    ),
    InterviewStage(
      kind: StageKind.finalStage,
      title: 'Final interview',
      about: 'A senior leader looks at fit and any doubts left from earlier stages.',
      persona: PersonaKind.probing,
      settler: _q(
        'Thanks for coming back. How have you found the process so far?',
        'Settler',
        'Nothing is scored here: it is to help you settle in.',
      ),
      questions: [
        _q(
          'Tell me about a time you had to change your approach because something was not working.',
          'Behavioural',
          'Adaptability and learning.',
          ['What was not working', 'What you changed', 'What happened and what you learned'],
        ),
        _q(
          'Why should we choose you over the other candidates?',
          'Motivation',
          'Your case, in your own words.',
        ),
        _anyQuestions,
      ],
    ),
  ],
);

final processTemplates = [nhsStyle, civilServiceStyle, privateSectorStyle];

// ---- exercises (all made up for practice) ----

class InTrayItem {
  const InTrayItem(this.id, this.from, this.text, this.why);
  final String id;
  final String from;
  final String text;

  /// Why it sits where it does in [inTrayOrder].
  final String why;
}

/// A fictional in-tray for an administrator at "Example Clinic".
const inTrayItems = [
  InTrayItem(
    'reception',
    'Phone message',
    'Tonight\'s reception cover has called in sick. The evening clinic opens at 17:00.',
    'Today, and the clinic cannot open safely without it.',
  ),
  InTrayItem(
    'fire',
    'Clinic manager',
    'The fire safety audit is tomorrow at 9:00 and the evacuation sign-in sheets are missing from the folder.',
    'Tomorrow morning, and it is about safety.',
  ),
  InTrayItem(
    'letter',
    'A patient\'s daughter',
    'Upset that her mother\'s appointment letter went to an old address. The appointment is on Friday.',
    'A person is upset and the appointment is soon; a quick call settles it.',
  ),
  InTrayItem(
    'password',
    'IT service desk',
    'Your password expires in three days.',
    'Two minutes now saves a lock-out later.',
  ),
  InTrayItem(
    'overtime',
    'Finance',
    'Please send last month\'s overtime figures by the end of next week.',
    'Due next week: plan time for it.',
  ),
  InTrayItem('lunch', 'A colleague', 'Can we swap our lunch cover on Thursday?', 'A quick reply; no rush.'),
  InTrayItem(
    'awayday',
    'Team lead',
    'Could you draft some ideas for the team away day in two months\' time?',
    'Important but not urgent.',
  ),
];

/// One reasonable order (ids). Others can be right if the reason is good.
const inTrayOrder = ['reception', 'fire', 'letter', 'password', 'overtime', 'lunch', 'awayday'];

/// How many items of [order] sit within one place of [inTrayOrder]. A
/// comparison to talk about, not a score.
int inTrayCloseCount(List<String> order) {
  var n = 0;
  for (final (i, id) in order.indexed) {
    final j = inTrayOrder.indexOf(id);
    if (j >= 0 && (i - j).abs() <= 1) n++;
  }
  return n;
}

/// A small made-up table, described in text, with questions that have one
/// right answer.
const spreadsheetColumns = ['Clinic', 'January', 'February', 'March'];
const spreadsheetRows = [
  ['North', 120, 135, 128],
  ['South', 98, 102, 110],
  ['East', 143, 150, 139],
  ['West', 87, 91, 95],
];

class SpreadsheetTask {
  const SpreadsheetTask(this.question, this.answer, this.check, this.working);
  final String question;

  /// The right answer, as shown afterwards.
  final String answer;
  final bool Function(String given) check;

  /// How to get there.
  final String working;
}

double? _number(String s) => double.tryParse(s.replaceAll(RegExp(r'[^0-9.\-]'), ''));

final spreadsheetTasks = [
  SpreadsheetTask(
    'How many appointments did South have across the three months?',
    '310',
    (g) => _number(g) == 310,
    '98 + 102 + 110 = 310, or =SUM(B3:D3).',
  ),
  SpreadsheetTask(
    'Which clinic had the most appointments in March?',
    'East',
    (g) => g.trim().toLowerCase() == 'east',
    'Sort or filter the March column: East has 139.',
  ),
  SpreadsheetTask(
    'By what percentage did West grow from January to March? One decimal place.',
    '9.2%',
    (g) => ((_number(g) ?? -1) - 9.2).abs() < 0.051,
    '(95 − 87) ÷ 87 = 0.092, so 9.2%. In a sheet: =(D5-B5)/B5, formatted as a percentage.',
  ),
  SpreadsheetTask(
    'If North\'s January figure is in cell B2 and its March figure in D2, what formula totals its three months?',
    '=SUM(B2:D2)',
    (g) => g.replaceAll(' ', '').toUpperCase().replaceFirst(RegExp('^=?'), '=') == '=SUM(B2:D2)',
    '=SUM(B2:D2) adds B2, C2 and D2.',
  ),
];

class ReasoningItem {
  const ReasoningItem(this.question, this.options, this.answer, this.working);
  final String question;
  final List<String> options;

  /// Index into [options].
  final int answer;
  final String working;
}

/// Self-written reasoning items in a practice format. They are not taken
/// from any real test.
const reasoningItems = [
  ReasoningItem(
    'What comes next: 3, 7, 15, 31, …?',
    ['47', '55', '62', '63'],
    3,
    'Each number is double the one before, plus one: 31 × 2 + 1 = 63.',
  ),
  ReasoningItem(
    'Every form in tray A has been signed. This form is in tray A. Which must be true?',
    [
      'This form has been signed.',
      'Every signed form is in tray A.',
      'This form has not been checked.',
      'Tray A holds only this form.',
    ],
    0,
    'Only the first follows from the two statements; the others may or may not be true.',
  ),
  ReasoningItem(
    'Using the rules: start with x = 1, then three times do "x becomes x × 2 + 3". What is x at the end?',
    ['11', '17', '29', '35'],
    2,
    '1 → 5 → 13 → 29.',
  ),
  ReasoningItem(
    'Ana works every second day and Ben every third day. Both work this Monday. On which day are they next both '
        'working?',
    ['Thursday', 'Saturday', 'Sunday', 'Next Monday'],
    2,
    'Six days on (the lowest number both 2 and 3 go into) is Sunday.',
  ),
];

// ---- carrying feedback forward ----

/// What happened at one question of a stage, for carrying forward.
class QuestionOutcome {
  const QuestionOutcome({required this.expected, required this.heard, this.interrupted = false});

  /// The elements the question called for.
  final List<AnswerElement> expected;

  /// The elements the answer and its follow-ups covered.
  final Set<AnswerElement> heard;
  final bool interrupted;

  List<AnswerElement> get missed => [
    for (final e in expected)
      if (!heard.contains(e)) e,
  ];
}

/// The fix for a missed element, as a task for next time (one task-level
/// fix, never a judgement of the person).
const elementFixes = {
  AnswerElement.ownAction: 'Say what you yourself did, with "I", before what the team did.',
  AnswerElement.situation: 'Open with one specific example: when, where and how big.',
  AnswerElement.result: 'End each example with what happened in the end.',
  AnswerElement.measure: 'Say how you knew it worked: a number, a check or feedback.',
  AnswerElement.learning: 'Close with what you learned or would do differently.',
  AnswerElement.others: 'Name who else was involved and how you brought them along.',
};

const _keepLines = {
  AnswerElement.ownAction: 'You said what you yourself did.',
  AnswerElement.situation: 'You gave specific examples.',
  AnswerElement.result: 'You said how things turned out.',
  AnswerElement.measure: 'You said how you knew it worked.',
  AnswerElement.learning: 'You said what you learned.',
  AnswerElement.others: 'You named the people involved.',
};

const overTimeFix = 'Lead with the result, then the detail, so the answer fits the time.';

/// What the next stage takes from the ones before.
class CarryForward {
  const CarryForward({this.focus = const [], this.fixes = const [], this.keep = const []});

  /// Elements to probe first, most often missed first.
  final List<AnswerElement> focus;

  /// Up to three fixes for the next stage's opening note.
  final List<String> fixes;

  /// What went well, to keep doing.
  final List<String> keep;

  bool get isEmpty => fixes.isEmpty && keep.isEmpty;

  static const none = CarryForward();

  /// From the outcomes of the earlier stages, oldest first. The latest
  /// stage counts double: it is the freshest evidence.
  factory CarryForward.from(List<List<QuestionOutcome>> stages) {
    final missed = <AnswerElement, int>{};
    final asked = <AnswerElement, int>{};
    final heardAll = <AnswerElement, int>{};
    var interrupted = 0;
    for (final (i, stage) in stages.indexed) {
      final weight = i == stages.length - 1 ? 2 : 1;
      for (final q in stage) {
        if (q.interrupted) interrupted += weight;
        for (final e in q.expected) {
          asked[e] = (asked[e] ?? 0) + 1;
          if (q.heard.contains(e)) {
            heardAll[e] = (heardAll[e] ?? 0) + 1;
          } else {
            missed[e] = (missed[e] ?? 0) + weight;
          }
        }
      }
    }
    final focus = missed.keys.toList()
      ..sort((a, b) {
        final c = missed[b]!.compareTo(missed[a]!);
        return c != 0 ? c : probeOrder.indexOf(a).compareTo(probeOrder.indexOf(b));
      });
    final fixes = [
      if (interrupted > 0) overTimeFix,
      for (final e in focus) elementFixes[e]!,
    ].take(3).toList();
    final keep = [
      for (final e in probeOrder)
        if ((asked[e] ?? 0) >= 2 && heardAll[e] == asked[e]) _keepLines[e]!,
    ].take(2).toList();
    return CarryForward(focus: focus, fixes: fixes, keep: keep);
  }
}
