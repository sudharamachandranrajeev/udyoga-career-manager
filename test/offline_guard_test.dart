import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/domain/offline_guard.dart';
import 'package:udyoga/domain/ollama.dart';
import 'package:udyoga/domain/schema.dart';
import 'package:udyoga/voice/models.dart';

import 'ollama_test.dart' show FakeOllama;

void main() {
  final guard = OfflineGuard.instance;
  tearDown(() {
    while (guard.active) {
      guard.release();
    }
  });

  test('held: HTTP to another machine is refused before any connection, and counted', () async {
    final before = guard.refused;
    await guard.run(() async {
      for (final url in ['http://192.0.2.10/', 'https://example.invalid/models.bin']) {
        final client = HttpClient();
        await expectLater(
          client.getUrl(Uri.parse(url)),
          throwsA(
            isA<SocketException>().having(
              (e) => e.message,
              'message',
              contains('Offline interview practice'),
            ),
          ),
        );
        client.close(force: true);
      }
      // The http package goes through the same HttpClient.
      final c = http.Client();
      await expectLater(c.get(Uri.parse('https://example.invalid/')), throwsA(isA<http.ClientException>()));
      c.close();
    });
    expect(guard.refused - before, 3);
    expect(guard.refusedHosts.reversed.take(3), ['example.invalid', 'example.invalid', '192.0.2.10']);
  });

  test('held: plain sockets to another machine are refused; this machine is allowed', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((s) => s.destroy());
    await guard.run(() async {
      await expectLater(Socket.connect('192.0.2.10', 80), throwsA(isA<SocketException>()));
      final s = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
      s.destroy();
    });
    await server.close();
  });

  test('a client made before the guard held cannot reach another machine over plain HTTP', () async {
    final early = HttpClient();
    await guard.run(() async {
      await expectLater(early.getUrl(Uri.parse('http://192.0.2.10/')), throwsA(isA<SocketException>()));
    });
    early.close(force: true);
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

  test('released: the previous overrides come back; holds nest', () async {
    final previous = HttpOverrides.current;
    guard.hold();
    guard.hold();
    expect(HttpOverrides.current, isNot(same(previous)));
    guard.release();
    expect(guard.active, isTrue, reason: 'another screen still holds it');
    guard.release();
    expect(guard.active, isFalse);
    expect(HttpOverrides.current, same(previous));
    guard.release();
    expect(guard.active, isFalse, reason: 'an extra release does nothing');
  });

  test('model downloads are refused while held, without a request', () async {
    var requests = 0;
    final dir = await Directory.systemTemp.createTemp('udyoga-offline-');
    final mm = ModelManager(
      dir,
      client: MockClient((_) async {
        requests++;
        return http.Response('', 200);
      }),
    );
    await guard.run(() async {
      await expectLater(
        mm.download(speechModel(vadModelId)),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', offlineDownloadMessage)),
      );
    });
    expect(requests, 0);
    await dir.delete(recursive: true);
  });
}
