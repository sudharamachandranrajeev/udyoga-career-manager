import 'insights.dart';

/// General questions most panels ask, for a spoken round that needs no AI.
/// Each says what it tests (shown before the answer) and what a good answer
/// covers.
const commonQuestions = [
  PracticeQuestion({
    'question': 'Tell us a little about yourself and why you applied for this role.',
    'category': 'Motivation',
    'why': 'Whether you can link your experience to this role, briefly and with a clear reason for applying.',
    'lookFor': [
      'Two or three points from your experience that match the role',
      'Why this role and this employer',
      'About a minute and a half',
    ],
    'difficulty': 'standard',
  }),
  PracticeQuestion({
    'question': 'Tell us about a time you had to deal with a difficult situation at work. What did you do?',
    'category': 'Behavioural',
    'why': 'How you solve problems under pressure, shown through one real example.',
    'lookFor': [
      'One specific situation, briefly set out',
      'What you yourself did, step by step',
      'The result, with a figure if you have one',
    ],
    'difficulty': 'standard',
  }),
  PracticeQuestion({
    'question': 'Describe a time you worked with others to reach a shared goal. What was your part?',
    'category': 'Behavioural',
    'why': 'Teamwork: how you work with colleagues and what you add to a team.',
    'lookFor': [
      'Your own part, not only the team\'s',
      'How you handled a disagreement or setback',
      'The outcome',
    ],
    'difficulty': 'standard',
  }),
  PracticeQuestion({
    'question': 'Tell us about a mistake you made. What did you learn from it?',
    'category': 'Values',
    'why': 'Honesty and learning: whether you own a mistake and change what you do.',
    'lookFor': [
      'A real mistake, not a disguised strength',
      'What you did to put it right',
      'What you now do differently',
    ],
    'difficulty': 'hard',
  }),
  PracticeQuestion({
    'question': 'How do you decide what to do first when several things are due at once?',
    'category': 'Situational',
    'why': 'Organisation: how you weigh urgency and importance, and when you ask for help.',
    'lookFor': [
      'A clear way of deciding',
      'An example of it working',
      'Telling others when a deadline moves',
    ],
    'difficulty': 'standard',
  }),
  PracticeQuestion({
    'question': 'Do you have any questions for us?',
    'category': 'Motivation',
    'why': 'Interest and preparation: questions that show you have thought about the job.',
    'lookFor': [
      'One or two questions about the work or the team',
      'Nothing you could have read on the advert',
    ],
    'difficulty': 'standard',
  }),
];
