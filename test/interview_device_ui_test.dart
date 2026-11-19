import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/app/interview_providers.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/domain/advisor.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/common_questions.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/json.dart';
import 'package:udyoga/domain/ollama.dart';
import 'package:udyoga/ui/spoken_round_page.dart';

import 'app_harness.dart';
import 'spoken_round_ui_test.dart' show FakeEngines;

/// A cloud AI that must never be asked once the local model is chosen.
class Cloud implements Ai {
  var asked = 0;
  @override
  String get model => 'cloud';
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
    asked++;
    throw AiException('The cloud was asked.');
  }
}

/// Ollama's HTTP API in memory: /api/tags lists [models], /api/chat
/// answers a question plan for each question asked.
MockClient fakeOllamaHttp(List<http.Request> seen, {List<String> models = const ['qwen2.5:7b']}) =>
    MockClient((r) async {
      seen.add(r);
      if (r.url.path == '/api/tags') {
        return http.Response(
          jsonEncode({
            'models': [
              for (final m in models) {'name': m},
            ],
          }),
          200,
        );
      }
      final body = jsonDecode(r.body) as Map;
      final n = RegExp('<question n=')
          .allMatches(((body['messages'] as List).last as Map)['content'] as String);
      return http.Response(
        jsonEncode({
          'message': {
            'role': 'assistant',
            'content': jsonEncode({
              'questions': [
                for (final _ in n)
                  {
                    'criterion': 'Planning',
                    'expected': ['situation', 'ownAction'],
                    'probes': [
                      {'element': 'ownAction', 'text': 'Which part did you do?'},
                    ],
                  },
              ],
            }),
          },
          'done': true,
          'done_reason': 'stop',
        }),
        200,
      );
    });

void main() {
  testWidgets('a missing local model is said plainly, with the command, and the AI is off until fixed', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    await app.open(
      seed: (b) => b.setInterviewDevice(const InterviewDevice(localAi: true, ollamaModel: 'llama3.2:3b')),
    );
    final cloud = Cloud();
    await app.run(
      overrides: [
        advisorProvider.overrideWith((ref) async => Advisor(cloud, today: '2026-11-19')),
        ollamaFactoryProvider.overrideWithValue(
          (s) => Ollama(
            host: s.host,
            model: s.model,
            client: fakeOllamaHttp([], models: ['gemma3:4b']),
          ),
        ),
      ],
    );
    await app.go('Interview');
    expect(find.textContaining('ollama pull llama3.2:3b'), findsWidgets);
    expect(find.text(ollamaQualityNote), findsOneWidget);
    expect(find.textContaining('never installs Ollama'), findsOneWidget);
    expect(find.text('Practise'), findsNothing, reason: 'no silent fall-back to the cloud AI');
    await app.close();
  });

  testWidgets('with the local model ready, the round is planned by it and the cloud is never asked', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    late String id;
    await app.open(
      seed: (b) async {
        await b.setInterviewDevice(const InterviewDevice(localAi: true));
        id = await b.startPractice(
          role: 'Common questions',
          mode: 'standard',
          questions: commonQuestions.take(2).toList(),
          at: '2026-11-19T10:00',
        );
      },
    );
    final cloud = Cloud();
    final seen = <http.Request>[];
    await app.run(
      home: SpokenRoundPage(id),
      overrides: [
        advisorProvider.overrideWith((ref) async => Advisor(cloud, today: '2026-11-19')),
        ollamaFactoryProvider.overrideWithValue(
          (s) => Ollama(host: s.host, model: s.model, client: fakeOllamaHttp(seen)),
        ),
        spokenEnginesProvider.overrideWith((ref) async => FakeEngines()),
      ],
    );
    await app.tapText('Start the round');
    expect(find.textContaining('Follow-ups planned by the local model'), findsOneWidget);
    expect(cloud.asked, 0);
    final chat = seen.where((r) => r.url.path == '/api/chat').single;
    expect(chat.url.toString(), 'http://localhost:11434/api/chat', reason: 'the default address');
    final body = jsonDecode(chat.body) as Map;
    expect(body['format'], isA<Map>());
    expect(body['stream'], false);
    await app.close();
  });
}
