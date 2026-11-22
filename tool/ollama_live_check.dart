// Runs the interview AI path (I3/I6) against a real local model through
// Ollama: reading a fictional advert into criteria, a question plan, and
// scoring a fictional three-answer round, with every score checked by
// verifyScores. Prints, per call, the time it took, how many /api/chat
// requests it needed (more than one means a reply broke the schema and
// was asked again) and what came back. Not part of the app. Everything
// sent is made up.
//
//   ollama serve            # in another terminal, if it is not running
//   ollama pull llama3.2:3b
//   OLLAMA_MODEL=llama3.2:3b flutter test tool/ollama_live_check.dart
//
// It runs under `flutter test` (the domain code imports Flutter) as a plain
// test, so real HTTP to Ollama is allowed. OLLAMA_HOST picks another host.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/ollama.dart';

const advert = '''
Medical Records Officer, Band 3
Example Valley NHS Trust, Sampleford

About the role
Keep the outpatient diary and patient records accurate and up to date for three busy clinics.
You will book and move appointments, prepare clinic lists and answer patient calls.

Person specification
Essential
- Experience of booking appointments or managing a diary (assessed at application and interview)
- Good IT skills, including email and spreadsheets (application and test)
- Able to work accurately and keep records confidential (interview)
- Works well as part of a team (interview)
- Shows our values: compassion, respect and working together (interview)
Desirable
- Experience of a patient records system (application)
''';

/// Fixed criteria for the scoring call, so the result can be compared
/// with the earlier cloud check on the same answers.
const criteria = [
  Criterion(id: 'c1', text: 'Experience of booking appointments or managing a diary'),
  Criterion(id: 'c2', text: 'Able to work accurately and keep records confidential'),
  Criterion(id: 'c3', text: 'Works well as part of a team'),
];

const answers = [
  (
    index: 0,
    question: 'Tell us about a time you managed a busy diary.',
    criteria: ['c1'],
    answer:
        'In my last role the clinic diary was double-booked most Mondays. I rang each patient on the list, '
        'I moved the overflow to a Tuesday session and I told the consultant. As a result the double bookings '
        'fell from nine a week to one.',
  ),
  (
    index: 1,
    question: 'Tell us about a time you worked as part of a team.',
    criteria: ['c3'],
    answer: 'I am a very good team player and I value working together.',
  ),
  (
    index: 2,
    question: 'How do you make sure records are accurate and kept confidential?',
    criteria: ['c2'],
    answer:
        'I check the patient\'s date of birth and address before I open a record. I never leave a screen '
        'unlocked, and once I found two records for the same patient and reported it to the records manager '
        'so they could be merged.',
  ),
];

class _Counting extends http.BaseClient {
  final _inner = http.Client();
  int chats = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest r) {
    if (r.url.path == '/api/chat') chats++;
    return _inner.send(r);
  }
}

void main() {
  test('the interview AI on a real local model', _run, timeout: const Timeout(Duration(minutes: 30)));
}

Future<void> _run() async {
  final model = Platform.environment['OLLAMA_MODEL'] ?? 'llama3.2:3b';
  final host = Platform.environment['OLLAMA_HOST'] ?? ollamaDefaultHost;
  final client = _Counting();
  final ollama = Ollama(host: host, model: model, client: client);
  final status = await ollama.check();
  stdout.writeln(status.message);
  if (!status.ready) fail(status.message);
  final advisor = Advisor(ollama, today: '2026-11-20');
  final out = <String, Object?>{'model': model};

  Future<T?> timed<T>(String name, Future<T> Function() f, Object? Function(T) show) async {
    final before = client.chats;
    final sw = Stopwatch()..start();
    try {
      final v = await f();
      out[name] = {
        'seconds': sw.elapsedMilliseconds / 1000,
        'requests': client.chats - before,
        'result': show(v),
      };
      return v;
    } on Object catch (e) {
      out[name] = {
        'seconds': sw.elapsedMilliseconds / 1000,
        'requests': client.chats - before,
        'error': '$e',
      };
      return null;
    }
  }

  await timed('criteria', () => advisor.readCriteria(advert: advert, title: 'Medical Records Officer'), (
    data,
  ) {
    final c = parseCriteria(data);
    return {
      'count': c.length,
      'framework': suggestedFramework(data),
      'criteria': [
        for (final x in c) '${x.essential ? 'E' : 'D'} ${x.kind.name} ${x.assessBy.join('')}: ${x.text}',
      ],
    };
  });

  await timed(
    'plan',
    () => advisor.questionPlan(
      role: 'Medical Records Officer',
      questions: [
        for (final a in answers) PracticeQuestion({'question': a.question, 'category': 'competency'}),
      ],
    ),
    (plans) => [for (final p in plans) p.toJson()],
  );

  final framework = Framework.of('nhs_values');
  final raw = await timed(
    'scoring',
    () => advisor.scoreRound(
      role: 'Medical Records Officer',
      framework: framework,
      criteria: criteria,
      answers: answers,
    ),
    (scores) => [for (final s in scores) s.toJson()],
  );
  if (raw != null) {
    final v = verifyScores(
      raw,
      framework.scale,
      heard: {for (final a in answers) a.index: a.answer},
      asked: {for (final a in answers) a.index: a.criteria},
    );
    out['verified'] = {
      'dropped': v.dropped,
      'scores': [
        for (final s in v.scores)
          {
            'q': s.question + 1,
            'criterion': s.criterionId,
            'level': s.level.code,
            'quote': s.quote,
            if (s.reason.isNotEmpty) 'reason': s.reason,
          },
      ],
      'answers': {
        for (final e in v.answers.entries) '${e.key + 1}': {'strength': e.value.strength, 'fix': e.value.fix},
      },
    };
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(out));
  client.close();
}
