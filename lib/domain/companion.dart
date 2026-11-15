import 'json.dart';
import 'schema.dart';

/// The candidate companion: documents read into the profile, questions that
/// confirm it, the daily check-in and the story bank built from all three.
///
/// Every request to the AI carries the profile; the companion keeps that
/// profile true (questions), growing (check-ins) and provable (stories).

/// What employers score at interview, across sectors. Stories are tagged with
/// these ids; readiness is counted per competency.
const competencyNames = <String, String>{
  'prioritising': 'Prioritising a heavy workload',
  'accuracy': 'Accuracy and data quality',
  'communication': 'Communication',
  'teamwork': 'Working with others',
  'problem_solving': 'Solving problems',
  'improvement': 'Initiative and improving things',
  'service': 'Patients, customers and service users',
  'confidentiality': 'Confidentiality and following policy',
  'systems': 'Learning and using systems',
  'supporting': 'Training and supporting colleagues',
  'pressure': 'Working under pressure',
  'values': 'Values and attitude',
};

/// What kind of document a file is.
const documentKinds = <String, String>{
  'cv': 'CV',
  'reference': 'Reference',
  'interview': 'Interview preparation',
  'advert': 'Job advert or description',
  'application': 'Application or answers',
  'certificate': 'Certificate or qualification',
  'notes': 'Notes',
  'other': 'Other',
};

/// One thing a document states about the candidate.
class DocumentFact {
  const DocumentFact({this.topic = '', this.statement = '', this.quote = ''});

  /// What it is about, short: "Start date at Acme", "Excel level".
  final String topic;

  /// The fact in the AI's words.
  final String statement;

  /// The document's own words.
  final String quote;

  factory DocumentFact.fromJson(Json j) =>
      DocumentFact(topic: str(j['topic']), statement: str(j['statement']), quote: str(j['quote']));

  Json toJson() => {'topic': topic, 'statement': statement, 'quote': quote};

  static final schema = object({
    'topic': string('What the fact is about, in a few words, e.g. "Start date at <employer>"'),
    'statement': string('The fact as the document states it'),
    'quote': string('The document\'s own words, short'),
  });
}

/// A STAR story as the AI drafts it.
class StoryDraft {
  const StoryDraft({
    this.title = '',
    this.situation = '',
    this.task = '',
    this.action = '',
    this.result = '',
    this.competencies = const [],
  });

  final String title, situation, task, action, result;
  final List<String> competencies;

  factory StoryDraft.fromJson(Json j) => StoryDraft(
    title: str(j['title']),
    situation: str(j['situation']),
    task: str(j['task']),
    action: str(j['action']),
    result: str(j['result']),
    competencies: strs(j['competencies']).where(competencyNames.containsKey).toList(),
  );

  static final schema = object({
    'title': string('A short name for the story, e.g. "Short-notice slot tracker"'),
    'situation': string('Where and when, in one or two sentences'),
    'task': string('What the candidate had to do'),
    'action': string('What the candidate did, in the first person, specific'),
    'result': string('What changed, with figures only when the source gives them; "" when unknown'),
    'competencies': array(oneOf(competencyNames.keys.toList()), description: 'The competencies it proves'),
  });
}

/// What the AI read from one document.
class DocumentReading {
  const DocumentReading({
    this.name = '',
    this.kind = 'other',
    this.summary = '',
    this.facts = const [],
    this.stories = const [],
  });

  final String name, kind, summary;
  final List<DocumentFact> facts;
  final List<StoryDraft> stories;

  factory DocumentReading.fromJson(Json j) => DocumentReading(
    name: str(j['name']),
    kind: documentKinds.containsKey(str(j['kind'])) ? str(j['kind']) : 'other',
    summary: str(j['summary']),
    facts: objs(j['facts']).map(DocumentFact.fromJson).toList(),
    stories: objs(j['stories']).map(StoryDraft.fromJson).toList(),
  );

  static final schema = object({
    'documents': array(
      object({
        'name': string('The document\'s name exactly as given'),
        'kind': oneOf(documentKinds.keys.toList()),
        'summary': string('One or two sentences: what it is and what it is for'),
        'facts': array(
          DocumentFact.schema,
          description:
              'What it states about the candidate: dates, roles, duties, figures, systems, qualifications, '
              'achievements. Not facts about other people.',
        ),
        'stories': array(
          StoryDraft.schema,
          description:
              'Examples of the candidate\'s own work it describes that could answer an interview question',
        ),
      }),
    ),
  });
}

/// A question that would make the profile more accurate.
class QuestionDraft {
  const QuestionDraft({this.topic = '', this.question = '', this.why = '', this.choices = const []});
  final String topic, question, why;
  final List<String> choices;

  factory QuestionDraft.fromJson(Json j) => QuestionDraft(
    topic: str(j['topic']),
    question: str(j['question']),
    why: str(j['why']),
    choices: strs(j['choices']),
  );

  static final schema = object({
    'questions': array(
      object({
        'topic': string('What it is about, in a few words'),
        'question': string('The question, short and plain, to the candidate as "you"'),
        'why': string('Why it is asked: the conflicting statements and which documents they are in'),
        'choices': strings('Likely answers to pick from, e.g. each conflicting value; [] when open'),
      }),
    ),
  });
}

/// What Udyoga took from a check-in.
class CheckInDigest {
  const CheckInDigest({
    this.summary = '',
    this.stories = const [],
    this.skills = const [],
    this.achievements = const [],
    this.learning = const [],
    this.nextQuestion = '',
  });

  final String summary;
  final List<StoryDraft> stories;
  final List<String> skills, achievements, learning;

  /// A follow-up for tomorrow, when today's answer left a gap.
  final String nextQuestion;

  factory CheckInDigest.fromJson(Json j) => CheckInDigest(
    summary: str(j['summary']),
    stories: objs(j['stories']).map(StoryDraft.fromJson).toList(),
    skills: strs(j['skills']),
    achievements: strs(j['achievements']),
    learning: strs(j['learning']),
    nextQuestion: str(j['nextQuestion']),
  );

  Json toJson() => {
    'summary': summary,
    'stories': [
      for (final s in stories)
        {
          'title': s.title,
          'situation': s.situation,
          'task': s.task,
          'action': s.action,
          'result': s.result,
          'competencies': s.competencies,
        },
    ],
    'skills': skills,
    'achievements': achievements,
    'learning': learning,
    'nextQuestion': nextQuestion,
  };

  bool get isEmpty => stories.isEmpty && skills.isEmpty && achievements.isEmpty && learning.isEmpty;

  static final schema = object({
    'summary': string('One line: what the day was about'),
    'stories': array(
      StoryDraft.schema,
      description:
          'Only real examples from the answer that could answer an interview question; usually none or one',
    ),
    'skills': strings('Skills or systems the answer shows that the profile does not list yet'),
    'achievements': strings('Concrete wins worth adding to the CV, in CV wording; usually none'),
    'learning': strings('Things to learn or courses the answer points to'),
    'nextQuestion': string(
      'A short follow-up for tomorrow when a story lacks its result or a figure; "" if none',
    ),
  });
}

/// Questions for days without the AI, or before it has anything to go on.
/// Each one aims at a competency, so a week of answers covers the set.
const checkInQuestions = <String, String>{
  'prioritising': 'What was the most urgent thing today, and how did you decide what came first?',
  'accuracy': 'Did you find or fix a mistake in any record or list today? What was it?',
  'communication': 'Who was the hardest person to talk to today, and how did you handle it?',
  'teamwork': 'Who did you help today, or who helped you?',
  'problem_solving': 'What problem did you solve today, and what did you try first?',
  'improvement': 'What would you change about how your team works, and why?',
  'service': 'Tell me about one patient, customer or service user you helped today.',
  'confidentiality': 'Did anything today need care with confidential information? What did you do?',
  'systems': 'What did you do in a system today that a new starter would find hard?',
  'supporting': 'Did you show anyone how to do something today?',
  'pressure': 'When was today busiest, and what did you do to stay on top of it?',
  'values': 'What went well today that you are proud of?',
};

/// The competency with the fewest stories, ties broken by the day so the
/// question changes daily.
String weakestCompetency(Map<String, int> storiesPer, {required String day}) {
  final order = competencyNames.keys.toList();
  final seed = day.codeUnits.fold(0, (a, b) => a + b) % order.length;
  final rotated = [...order.skip(seed), ...order.take(seed)];
  rotated.sort((a, b) => (storiesPer[a] ?? 0).compareTo(storiesPer[b] ?? 0));
  return rotated.first;
}

/// Readiness for interview, per competency, 0 to 100: two confirmed
/// stories make a competency ready; a draft counts half until confirmed.
Map<String, int> readiness(Map<String, ({int confirmed, int drafts})> stories) => {
  for (final c in competencyNames.keys)
    c: (((stories[c]?.confirmed ?? 0) * 50 + (stories[c]?.drafts ?? 0) * 25)).clamp(0, 100),
};
