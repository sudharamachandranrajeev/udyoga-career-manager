import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:udyoga/domain/ollama.dart';
import 'package:udyoga/domain/schema.dart';

import 'ollama_test.dart' show FakeOllama;

// The offline guard is tested in the interview engine package. This checks
// that Udyoga's Ollama client still works through it on this machine.

void main() {
  final guard = OfflineGuard.instance;
  tearDown(() {
    while (guard.active) {
      guard.release();
    }
  });

  test('held: Ollama on loopback still answers', () async {
    final server = await FakeOllama.start();
    server.replies = [
      jsonEncode({'ok': 'yes'}),
    ];
    final made = guard.clients;
    await guard.run(() async {
      final ai = Ollama(host: server.host);
      expect((await ai.check()).ready, isTrue);
      final r = await ai.ask(
        system: 's',
        content: const [
          {'type': 'text', 'text': 'q'},
        ],
        schema: object({'ok': string()}),
      );
      expect(r.data['ok'], 'yes');
    });
    expect(guard.clients - made, 2, reason: 'each made inside the guard, limited to this machine');
    await server.close();
  });
}
