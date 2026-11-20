import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/interview_plan.dart';
import 'package:udyoga/domain/interview_process.dart';
import 'package:udyoga/voice/round_engines.dart' show sentencesOf;
import 'package:udyoga/voice/voice_cache.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('udyoga-voice-cache-test-'));
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('only the app\'s own fixed sentences may be cached, never user text', () {
    final cache = VoiceCache(dir, voice: 21);
    final neutral = Persona.of(PersonaKind.neutral);
    // Fixed lines: greetings, the interrupt script, wrap-up, built-in
    // follow-ups, acknowledgements and template settlers.
    for (final line in [
      neutral.greeting,
      mayInterruptScript,
      interruptLine,
      builtInProbes[AnswerElement.measure]!.first,
      Persona.of(PersonaKind.friendly).acknowledgements.first,
      nhsStyle.stages[0].settler.question,
    ]) {
      for (final s in sentencesOf(line)) {
        expect(cache.keyFor(s), isNotNull, reason: s);
      }
    }
    // Anything the user wrote or edited, or the round's own questions.
    for (final text in [
      'Tell us about a time you sorted out a problem for a patient.',
      'Could you start by telling me a little about your current role at Example Clinic?',
      'I rang the hospital and booked a new date.',
      '${neutral.greeting} extra',
    ]) {
      expect(cache.keyFor(text), isNull, reason: text);
    }
  });

  test('the key is a hash of the voice, speed, model and text; the text is not in it', () {
    final s = sentencesOf(mayInterruptScript).first;
    final a = VoiceCache(dir, voice: 21).keyFor(s)!;
    expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(VoiceCache(dir, voice: 21).keyFor(s), a, reason: 'stable');
    expect(VoiceCache(dir, voice: 3).keyFor(s), isNot(a));
    expect(VoiceCache(dir, voice: 21, speed: 1.2).keyFor(s), isNot(a));
    expect(VoiceCache(dir, voice: 21, model: 'another-voice').keyFor(s), isNot(a));
    expect(
      VoiceCache(dir, voice: 21).keyFor(sentencesOf(Persona.of(PersonaKind.quiet).greeting).first),
      isNot(a),
    );
  });

  test('a clip goes in and comes back; a damaged one reads as missing', () async {
    final cache = VoiceCache(dir, voice: 21);
    final key = cache.keyFor(Persona.of(PersonaKind.neutral).greeting)!;
    expect(await cache.read(key), isNull);
    await cache.write(key, Float32List.fromList([0.5, -0.25, 0.125]), 24000);
    final (samples, rate) = (await cache.read(key))!;
    expect(rate, 24000);
    expect(samples, [0.5, -0.25, 0.125]);
    // Only hashes on disk: no text of any kind in the folder.
    expect(dir.listSync().map((f) => f.uri.pathSegments.last), ['$key.pcm']);

    await File('${dir.path}/$key.pcm').writeAsBytes([1, 2, 3]);
    expect(await cache.read(key), isNull);
    await cache.clear();
    expect(await dir.exists(), isFalse);
  });
}
