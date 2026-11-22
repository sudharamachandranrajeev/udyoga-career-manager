import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/ollama.dart';
import 'package:udyoga/domain/schema.dart';

/// A stand-in for Ollama on loopback: answers /api/tags with [models] and
/// /api/chat with [replies] in turn (the last repeats), and keeps every
/// request body.
class FakeOllama {
  FakeOllama._(this._server);
  final HttpServer _server;
  List<String> models = ['qwen2.5:7b'];
  List<Object> replies = [];
  int chatStatus = 200;
  final requests = <Map<String, Object?>>[];

  static Future<FakeOllama> start() async {
    final f = FakeOllama._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    f._server.listen(f._handle);
    return f;
  }

  String get host => 'http://127.0.0.1:${_server.port}';

  Future<void> _handle(HttpRequest r) async {
    r.response.headers.contentType = ContentType.json;
    if (r.uri.path == '/api/tags') {
      r.response.write(
        jsonEncode({
          'models': [
            for (final m in models) {'name': m, 'model': m},
          ],
        }),
      );
    } else if (r.uri.path == '/api/chat') {
      requests.add((jsonDecode(await utf8.decodeStream(r)) as Map).cast<String, Object?>());
      r.response.statusCode = chatStatus;
      final reply = replies[(requests.length - 1).clamp(0, replies.length - 1)];
      r.response.write(jsonEncode(reply is String ? chat(reply) : reply));
    } else {
      r.response.statusCode = 404;
    }
    await r.response.close();
  }

  /// A finished, non-streamed chat reply carrying [content].
  static Map<String, Object?> chat(String content) => {
    'model': 'qwen2.5:7b',
    'message': {'role': 'assistant', 'content': content},
    'done': true,
    'done_reason': 'stop',
    'prompt_eval_count': 120,
    'eval_count': 40,
  };

  Future<void> close() => _server.close(force: true);
}

void main() {
  late FakeOllama server;
  setUp(() async => server = await FakeOllama.start());
  tearDown(() => server.close());

  final schema = object({
    'criterion': string(),
    'expected': array(oneOf(['situation', 'result'])),
  });

  group('the request', () {
    test('goes to /api/chat with the schema in format, no streaming, system and user turns', () async {
      server.replies = [
        jsonEncode({
          'criterion': 'Planning',
          'expected': ['situation'],
        }),
      ];
      final ai = Ollama(host: server.host, model: 'qwen2.5:7b');
      final r = await ai.ask(
        system: 'You plan questions.',
        content: [
          {'type': 'text', 'text': 'First part.'},
          {'type': 'text', 'text': 'Second part.'},
        ],
        schema: schema,
        maxTokens: 6000,
      );
      expect(r.data, {
        'criterion': 'Planning',
        'expected': ['situation'],
      });
      expect((r.usage.input, r.usage.output, r.usage.dollars), (120, 40, 0));
      final body = server.requests.single;
      expect(body['model'], 'qwen2.5:7b');
      expect(body['format'], schema, reason: 'JSON-schema output through the format field');
      expect(body['stream'], false);
      expect(body['messages'], [
        {'role': 'system', 'content': 'You plan questions.'},
        {'role': 'user', 'content': 'First part.\n\nSecond part.'},
      ]);
      expect((body['options'] as Map)['num_predict'], 6000);
      expect((body['options'] as Map)['temperature'], 0);
    });

    test('a reply wrapped in prose is read; one off the schema is asked again, then refused', () async {
      server.replies = [
        'Here you are: {"criterion": "Planning", "expected": ["nonsense"]}',
        'Sure. {"criterion": "Planning", "expected": ["result"]} Hope that helps.',
      ];
      final ai = Ollama(host: server.host);
      final r = await ai.ask(
        system: 's',
        content: const [
          {'type': 'text', 'text': 'q'},
        ],
        schema: schema,
      );
      expect(r.data['expected'], ['result']);
      expect(server.requests, hasLength(2));

      server.requests.clear();
      server.replies = ['not json at all'];
      await expectLater(
        ai.ask(
          system: 's',
          content: const [
            {'type': 'text', 'text': 'q'},
          ],
          schema: schema,
        ),
        throwsA(isA<AiException>().having((e) => e.message, 'message', contains('unexpected form'))),
      );
      expect(server.requests, hasLength(2), reason: 'one more try, no more');
    });

    test('a document or an image is refused: text only', () async {
      final ai = Ollama(host: server.host);
      await expectLater(
        ai.ask(
          system: 's',
          content: const [
            {
              'type': 'document',
              'source': {'data': 'x'},
            },
          ],
          schema: schema,
        ),
        throwsA(isA<AiException>().having((e) => e.message, 'message', contains('text only'))),
      );
      expect(server.requests, isEmpty);
    });

    test('an answer cut off at the length limit says so', () async {
      server.replies = [
        {...FakeOllama.chat('{"criterion": "Plan'), 'done_reason': 'length'},
      ];
      await expectLater(
        Ollama(host: server.host).ask(
          system: 's',
          content: const [
            {'type': 'text', 'text': 'q'},
          ],
          schema: schema,
        ),
        throwsA(isA<AiException>().having((e) => e.message, 'message', contains('longer than allowed'))),
      );
    });
  });

  group('when Ollama is missing', () {
    test('nothing listening: "not running", and Udyoga installs nothing', () async {
      final port = server.host.split(':').last;
      await server.close();
      final ai = Ollama(host: 'http://127.0.0.1:$port', model: 'llama3.2:3b');
      final s = await ai.check();
      expect(s.state, OllamaState.notRunning);
      expect(s.message, contains('Ollama is not running at http://127.0.0.1:$port'));
      expect(s.message, contains('does not install or start it'));
      await expectLater(
        ai.ask(
          system: 's',
          content: const [
            {'type': 'text', 'text': 'q'},
          ],
          schema: schema,
        ),
        throwsA(isA<AiException>().having((e) => e.message, 'message', contains('not running'))),
      );
      // Leave a server for tearDown to close.
      server = await FakeOllama.start();
    });

    test('running without the model: the pull command to run, not run for you', () async {
      server.models = ['llama3.2:3b'];
      final s = await Ollama(host: server.host, model: 'qwen2.5:7b').check();
      expect(s.state, OllamaState.modelMissing);
      expect(s.message, contains('ollama pull qwen2.5:7b'));
      expect(s.models, ['llama3.2:3b']);
      expect((await Ollama(host: server.host, model: 'llama3.2:3b').check()).ready, isTrue);
    });

    test('the model missing at chat time says the same', () async {
      server.chatStatus = 404;
      server.replies = [
        {'error': 'model "qwen2.5:7b" not found, try pulling it first'},
      ];
      await expectLater(
        Ollama(host: server.host).ask(
          system: 's',
          content: const [
            {'type': 'text', 'text': 'q'},
          ],
          schema: schema,
        ),
        throwsA(isA<AiException>().having((e) => e.message, 'message', contains('ollama pull qwen2.5:7b'))),
      );
    });

    test('a name without a tag is the latest, as Ollama reads it', () {
      expect(Ollama.hasModel(['gemma3:latest'], 'gemma3'), isTrue);
      expect(Ollama.hasModel(['gemma3'], 'gemma3:latest'), isTrue);
      expect(Ollama.hasModel(['gemma3:4b'], 'gemma3'), isFalse);
    });
  });

  test('host addresses: the default, the /v1 of other tools, and loopback', () {
    expect(ollamaHost(''), 'http://localhost:11434');
    expect(ollamaHost('http://localhost:11434/v1/'), 'http://localhost:11434');
    expect(ollamaHost('192.168.1.20:11434'), 'http://192.168.1.20:11434');
    expect(Ollama(model: '').model, ollamaDefaultModel);
    for (final h in ['localhost', '127.0.0.1', '::1', '[::1]', '127.0.0.53']) {
      expect(isLoopbackHost(h), isTrue, reason: h);
    }
    for (final h in ['192.168.1.20', 'example.com', 'localhost.example.com']) {
      expect(isLoopbackHost(h), isFalse, reason: h);
    }
  });

  group('the interview tasks through Ollama', () {
    test('the question plan parses into plans', () async {
      server.replies = [
        jsonEncode({
          'questions': [
            {
              'criterion': 'Covering gaps',
              'expected': ['situation', 'ownAction', 'result'],
              'probes': [
                {'element': 'ownAction', 'text': 'What did you do yourself?'},
              ],
            },
          ],
        }),
      ];
      final advisor = Advisor(Ollama(host: server.host), today: '2026-11-19');
      final plans = await advisor.questionPlan(
        role: 'Clinic receptionist',
        questions: const [
          PracticeQuestion({
            'question': 'Tell us about a time you covered a gap.',
            'category': 'Behavioural',
          }),
        ],
      );
      expect(plans.single.expected, [AnswerElement.situation, AnswerElement.ownAction, AnswerElement.result]);
      expect(server.requests.single['format'], isA<Map>());
    });

    test('scores are held to the same quote check: an invented quote is dropped', () async {
      const said = 'I rang each patient on the list and the double bookings fell from nine a week to one.';
      server.replies = [
        jsonEncode({
          'answers': [
            {
              'question': 1,
              'scores': [
                {'criterion': 'c1', 'level': '3', 'quote': 'I rang each patient on the list'},
                {'criterion': 'c2', 'level': '4', 'quote': 'I ran a daily team huddle'},
              ],
              'strength': 'A measured result.',
              'strengthQuote': 'I rang each patient on the list',
              'fix': 'Say what you learned.',
            },
          ],
        }),
      ];
      final framework = Framework.of('nhs_values');
      final advisor = Advisor(Ollama(host: server.host), today: '2026-11-19');
      final raw = await advisor.scoreRound(
        role: 'Patient services administrator',
        framework: framework,
        criteria: const [
          Criterion(id: 'c1', text: 'Managing a busy diary'),
          Criterion(id: 'c2', text: 'Working together', kind: CriterionKind.value),
        ],
        answers: [
          (index: 0, question: 'Tell us about a busy diary.', criteria: ['c1', 'c2'], answer: said),
        ],
      );
      final v = verifyScores(
        raw,
        framework.scale,
        heard: {0: said},
        asked: {
          0: ['c1', 'c2'],
        },
      );
      expect(v.dropped, 1, reason: 'the huddle was never said');
      final c1 = v.scores.firstWhere((s) => s.criterionId == 'c1');
      expect((c1.level.code, c1.quote), ('3', 'I rang each patient on the list'));
      expect(v.scores.firstWhere((s) => s.criterionId == 'c2').level, framework.scale.noEvidence);
    });
  });
}
