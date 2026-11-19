import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udyoga/vision/blazeface.dart';
import 'package:udyoga/voice/lab.dart';
import 'package:udyoga/voice/models.dart';
import 'package:udyoga/voice/voice_cache.dart';

class FakeRecorder implements MicRecorder {
  int calls = 0;
  @override
  Future<Pcm> record(Duration length, {void Function(double dbfs)? level}) async {
    calls++;
    level?.call(-30);
    return Pcm(Float32List(length.inMilliseconds * 16));
  }
}

class FakeDetector implements SpeechDetector {
  FakeDetector(this.found);
  final List<SpeechSpan> found;
  @override
  Future<List<SpeechSpan>> spans(Pcm audio) async => found;
}

class FakeTranscriber implements Transcriber {
  FakeTranscriber({this.fail = false});
  final bool fail;
  int calls = 0;
  @override
  String get model => 'fake';
  @override
  Future<Transcript> transcribe(Pcm audio) async {
    calls++;
    if (fail) throw StateError('model missing');
    return const Transcript('I led the ward handover, um, every morning.', Duration(milliseconds: 900));
  }
}

class FakeSpeaker implements Speaker {
  final said = <String>[];
  @override
  Future<SpeechTiming> speak(String text) async {
    said.add(text);
    return const SpeechTiming(
      firstAudio: Duration(milliseconds: 120),
      synthesis: Duration(milliseconds: 300),
      audio: Duration(seconds: 4),
    );
  }
}

/// A fictional model for the manager tests.
SpeechModel fakeModel(
  List<int> body, {
  String? hash,
  bool archive = false,
  String entry = 'model.bin',
  String id = 'example-model',
  ModelRole role = ModelRole.vad,
}) => SpeechModel(
  id: id,
  label: 'Example model',
  role: role,
  url: 'https://models.example.org/model.bin',
  sha256: hash ?? sha256.convert(body).toString(),
  bytes: body.length,
  entry: entry,
  source: 'Example',
  licence: 'MIT',
  archive: archive,
);

void main() {
  group('lab state machine', () {
    const spans = [SpeechSpan(Duration(seconds: 1), Duration(seconds: 4))];

    test('runs record, detect, transcribe and speak in order, timing each', () async {
      final speaker = FakeSpeaker();
      final lab = InterviewLab(
        recorder: FakeRecorder(),
        detector: FakeDetector(spans),
        transcriber: FakeTranscriber(),
        speaker: speaker,
      );
      final seen = <LabStep>[];
      lab.changes.listen(seen.add);
      final r = await lab.run();
      await Future<void>.delayed(Duration.zero);
      expect(seen, [
        LabStep.recording,
        LabStep.detecting,
        LabStep.transcribing,
        LabStep.speaking,
        LabStep.done,
      ]);
      expect(r.audio!.length, const Duration(seconds: 10));
      expect(r.speechTotal, const Duration(seconds: 3));
      expect(r.transcript!.text, contains('um'));
      expect(r.speech!.firstAudio, const Duration(milliseconds: 120));
      expect(speaker.said.single, contains('Tell us about'));
      expect(lab.level, -30);
      expect(lab.busy, isFalse);
      await lab.dispose();
    });

    test('no speech skips the transcriber but still speaks', () async {
      final t = FakeTranscriber();
      final lab = InterviewLab(
        recorder: FakeRecorder(),
        detector: FakeDetector(const []),
        transcriber: t,
        speaker: FakeSpeaker(),
      );
      final r = await lab.run();
      expect((lab.step, t.calls, r.transcript!.text), (LabStep.done, 0, ''));
    });

    test('a failing step stops the run there and keeps earlier results', () async {
      final speaker = FakeSpeaker();
      final lab = InterviewLab(
        recorder: FakeRecorder(),
        detector: FakeDetector(spans),
        transcriber: FakeTranscriber(fail: true),
        speaker: speaker,
      );
      final r = await lab.run();
      expect(lab.step, LabStep.failed);
      expect(r.failedAt, LabStep.transcribing);
      expect(r.error, contains('model missing'));
      expect(r.spans, hasLength(1));
      expect(speaker.said, isEmpty);
      // It can run again.
      expect((await lab.run()).failedAt, LabStep.transcribing);
    });

    test('refuses a second run while one is going', () async {
      final lab = InterviewLab(
        recorder: FakeRecorder(),
        detector: FakeDetector(spans),
        transcriber: FakeTranscriber(),
        speaker: FakeSpeaker(),
      );
      final first = lab.run();
      expect(lab.busy, isTrue);
      expect(lab.run, throwsStateError);
      await first;
    });
  });

  group('model manager', () {
    late Directory root;
    setUp(() async => root = await Directory.systemTemp.createTemp('udyoga-models-'));
    tearDown(() async => root.delete(recursive: true));

    MockClient serving(List<int> body, {List<Uri>? asked}) => MockClient((req) async {
      asked?.add(req.url);
      return http.Response.bytes(body, 200);
    });

    test('downloads, checks the hash, installs, reports size and deletes', () async {
      final body = List<int>.generate(5000, (i) => i % 251);
      final m = fakeModel(body);
      final asked = <Uri>[];
      final mm = ModelManager(root, client: serving(body, asked: asked));
      expect(await mm.installed(m), isFalse);
      expect(await mm.sizeOnDisk(m), 0);
      final progress = <int>[];
      await mm.download(
        m,
        onProgress: (got, total) {
          expect(total, 5000);
          progress.add(got);
        },
      );
      expect(asked.single.toString(), m.url);
      expect(progress.last, 5000);
      expect(await mm.installed(m), isTrue);
      expect(await File(mm.path(m)).readAsBytes(), body);
      expect(mm.folder(m), '${root.path}/example-model');
      expect(
        mm.folder(speechModel('kokoro-en-gb-int8')),
        endsWith('kokoro-en-gb-int8/kokoro-int8-multi-lang-v1_0'),
      );
      // The model plus its 64-character marker.
      expect(await mm.sizeOnDisk(m), 5000 + 64);
      expect(root.listSync().map((e) => e.path.split('/').last), ['example-model']);

      await mm.delete(m);
      expect(await mm.installed(m), isFalse);
      expect(await mm.sizeOnDisk(m), 0);
      expect(root.listSync(), isEmpty);
    });

    test('deleting the voice deletes its cached clips; the cache can be cleared alone', () async {
      final body = List<int>.generate(3000, (i) => i % 13);
      final cache = Directory('${root.path}/voice-cache');
      final voice = fakeModel(body, id: 'example-voice', role: ModelRole.voice);
      final vad = fakeModel(body);
      final mm = ModelManager(Directory('${root.path}/models'), client: serving(body), voiceCache: cache);
      Future<void> fill() async {
        await VoiceCache(cache, voice: 21).write(
          VoiceCache(cache, voice: 21).keyFor(fixedVoiceSentences.first)!,
          Float32List.fromList([0.1, 0.2, 0.3]),
          24000,
        );
      }

      await mm.download(voice);
      await mm.download(vad);
      expect(await mm.voiceCacheBytes(), 0);
      await fill();
      expect(await mm.voiceCacheBytes(), 4 + 3 * 4);

      // Another kind of model leaves the clips alone.
      await mm.delete(vad);
      expect(await mm.voiceCacheBytes(), 16);

      await mm.delete(voice);
      expect(await mm.installed(voice), isFalse);
      expect(cache.existsSync(), isFalse, reason: 'clips made by a deleted voice go with it');

      await fill();
      await mm.clearVoiceCache();
      expect(await mm.voiceCacheBytes(), 0);
      expect(cache.existsSync(), isFalse);
      await mm.clearVoiceCache(); // nothing there: fine
    });

    test('a SHA-256 mismatch is refused and leaves nothing behind', () async {
      final body = List<int>.filled(1000, 7);
      final m = fakeModel(body, hash: sha256.convert([1, 2, 3]).toString());
      final mm = ModelManager(root, client: serving(body));
      await expectLater(
        mm.download(m),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', contains('checksum'))),
      );
      expect(await mm.installed(m), isFalse);
      expect(root.listSync(), isEmpty);
    });

    test('a model pinned to a new hash must be downloaded again', () async {
      final body = List<int>.filled(100, 1);
      final m = fakeModel(body);
      final mm = ModelManager(root, client: serving(body));
      await mm.download(m);
      // A different model pinned under the same id (an update) needs a new download.
      final updated = fakeModel(body, hash: sha256.convert([9]).toString());
      expect(await mm.installed(updated), isFalse);
      expect(await mm.installed(m), isTrue);
    });

    test('wrong size, HTTP errors and oversize downloads are refused', () async {
      final body = List<int>.filled(100, 1);
      final short = SpeechModel(
        id: 'example-model',
        label: 'Example model',
        role: ModelRole.vad,
        url: 'https://models.example.org/model.bin',
        sha256: sha256.convert(body).toString(),
        bytes: 200,
        entry: 'model.bin',
        source: 'Example',
        licence: 'MIT',
      );
      final mm = ModelManager(root, client: serving(body));
      await expectLater(mm.download(short), throwsA(isA<ModelException>()));
      final big = fakeModel(body.sublist(0, 50), hash: sha256.convert(body).toString());
      await expectLater(
        ModelManager(root, client: serving(body)).download(big),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', contains('bigger'))),
      );
      final missing = ModelManager(root, client: MockClient((_) async => http.Response('gone', 404)));
      await expectLater(
        missing.download(fakeModel(body)),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', contains('404'))),
      );
      expect(root.listSync(), isEmpty);
    });

    test('the catalogue pins https URLs, hashes and sizes, and never a face-embedding model', () {
      final ids = <String>{};
      for (final m in speechModels) {
        expect(ids.add(m.id), isTrue);
        expect(Uri.parse(m.url).scheme, 'https');
        expect(m.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(m.bytes, greaterThan(0));
        expect(
          m.url.toLowerCase(),
          isNot(anyOf(contains('facenet'), contains('embed'), contains('landmark'))),
        );
      }
      expect(speechModels.map((m) => m.role).toSet(), ModelRole.values.toSet());
      expect(formatBytes(speechModel('kokoro-en-gb-int8').bytes), '132.4 MB');
      expect(formatBytes(speechModel('moonshine-base-en').bytes), '111.3 MB');
      expect(speechModels.map((m) => m.id), isNot(contains(anyOf(retiredModelIds))));
    });
  });

  group('BlazeFace decoding', () {
    test('896 anchors, in two layers', () {
      expect(blazeAnchors, hasLength(896));
      expect(blazeAnchors.first, (0.5 / 16, 0.5 / 16));
      expect(blazeAnchors[512], (0.5 / 8, 0.5 / 8));
    });

    test('a confident anchor becomes a box; overlaps are dropped', () {
      final boxes = Float32List(896 * 16), scores = Float32List(896)..fillRange(0, 896, -10);
      // Anchor 600 sits in the 8x8 layer; the box is 32 px square, nudged right.
      final (ax, ay) = blazeAnchors[600];
      boxes.setAll(600 * 16, [6.4, 0, 32, 32]);
      scores[600] = 4;
      // A near copy, slightly less sure, is dropped.
      boxes.setAll(601 * 16, [6.4, 0, 30, 30]);
      scores[601] = 3;
      final found = decodeBlazeFace(boxes, scores);
      expect(found, hasLength(1));
      final f = found.single;
      expect(f.width, closeTo(0.25, 1e-6));
      expect(f.left + f.width / 2, closeTo(ax + 0.05, 1e-6));
      expect(f.top + f.height / 2, closeTo(ay, 1e-6));
      expect(f.score, greaterThan(0.98));
    });

    test('the input is the centre square, in -1..1, from BGRA or YUV', () {
      // 4x2 BGRA frame: the centre square is columns 1..2.
      final px = Uint8List(4 * 2 * 4);
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 4; x++) {
          final i = (y * 4 + x) * 4;
          px.setAll(i, [0, 0, x == 1 || x == 2 ? 255 : 0, 255]);
        }
      }
      final (input, left, top, side) = blazeInputFrom(Frame.bgra(4, 2, px, 16));
      expect((left, top, side), (0.25, 0.0, 0.5));
      expect(input.length, 128 * 128 * 3);
      expect(input.every((v) => v >= -1 && v <= 1), isTrue);
      // Every sampled pixel is red: R = 1, G = B = -1.
      expect((input[0], input[1], input[2]), (1.0, -1.0, -1.0));

      final y = Uint8List(4)..fillRange(0, 4, 128), uv = Uint8List(1)..[0] = 128;
      final (grey, _, _, _) = blazeInputFrom(Frame.yuv420(2, 2, [y, uv, uv], [2, 1, 1], [1, 1, 1]));
      expect(grey[0], closeTo(128 / 127.5 - 1, 1e-6));
    });
  });
}
