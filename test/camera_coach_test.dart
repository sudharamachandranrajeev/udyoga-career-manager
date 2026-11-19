import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/vision/blazeface.dart';
import 'package:udyoga/vision/camera_coach.dart';
import 'package:udyoga/vision/setup_check.dart';
import 'package:udyoga/voice/models.dart';

/// A frame's numbers: a face box centred at ([cx], [cy]) of height [h]
/// (square-ish, as BlazeFace gives), and brightness of the face and the
/// rest. Fictional fixtures: no real picture.
FrameMeasure m({
  double cx = 0.5,
  double cy = 0.42,
  double h = 0.32,
  double face = 140,
  double back = 120,
  bool seen = true,
  int faces = 1,
}) => FrameMeasure(
  face: seen ? FaceBox(cx - h * 0.4, cy - h / 2, h * 0.8, h, 0.95) : null,
  faces: seen ? faces : 0,
  faceLuma: face,
  backLuma: back,
  frameLuma: seen ? (face + back) / 2 : back,
);

Map<SetupItem, SetupResult> check(Iterable<FrameMeasure> frames) {
  final c = SetupChecker();
  frames.forEach(c.add);
  return {for (final r in c.results) r.item: r};
}

List<FrameMeasure> times(FrameMeasure f, [int n = 15]) => List.filled(n, f);

class FakeFeed implements CoachFeed {
  final value = ValueNotifier<FrameMeasure?>(null);
  var closed = false;
  @override
  ValueListenable<FrameMeasure?> get measures => value;
  @override
  Widget? preview() => null;
  @override
  Future<void> close() async => closed = true;
}

class FakeCamera implements CoachCamera {
  FakeCamera({this.ready = true});
  bool ready;
  final feeds = <FakeFeed>[];
  var downloads = 0;
  @override
  SpeechModel get model => speechModel(faceModelId);
  @override
  Future<bool> modelReady() async => ready;
  @override
  Future<void> downloadModel({void Function(double share)? progress}) async {
    downloads++;
    ready = true;
  }

  @override
  Future<CoachFeed> open() async {
    final f = FakeFeed();
    feeds.add(f);
    return f;
  }
}

/// Records every file, directory and link the code under test touches, and
/// refuses it.
class _Spy {
  final made = <String>[];
  Never _refuse(String path) {
    made.add(path);
    throw UnsupportedError('No file may be touched: $path');
  }

  File createFile(String path) => _refuse(path);
  Directory createDirectory(String path) => _refuse(path);
  Link createLink(String path) => _refuse(path);
}

void main() {
  group('setup check from fixture face boxes and light', () {
    test('a centred, well-lit, steady head and shoulders: every check is a green tick', () {
      final r = check(times(m()));
      expect(r.values.map((x) => x.ok), everyElement(isTrue), reason: '${r.values}');
      final c = SetupChecker();
      times(m()).forEach(c.add);
      expect(c.allGood, isTrue);
      expect(c.notes, isEmpty);
    });

    test('too few frames: checking, not failing', () {
      final r = check(times(m(), 3));
      expect(r.values.map((x) => (x.ok, x.tip)), everyElement((null, 'Checking…')));
    });

    test('off-centre: move to the middle (no left or right, as previews are mirrored)', () {
      final r = check(times(m(cx: 0.78)));
      expect(r[SetupItem.face]!.ok, isFalse);
      expect(r[SetupItem.face]!.tip, contains('middle of the picture'));
      expect(r[SetupItem.face]!.tip, isNot(contains('left')));
    });

    test('too small: move closer', () {
      final r = check(times(m(h: 0.12)));
      expect(r[SetupItem.framing]!.ok, isFalse);
      expect(r[SetupItem.framing]!.tip, startsWith('Move closer'));
    });

    test('too close: move back', () {
      final r = check(times(m(h: 0.62, cy: 0.45)));
      expect(r[SetupItem.framing]!.ok, isFalse);
      expect(r[SetupItem.framing]!.tip, startsWith('Move back'));
    });

    test('backlit: move the light in front of you', () {
      final r = check(times(m(face: 60, back: 200)));
      expect(r[SetupItem.light]!.ok, isFalse);
      expect(r[SetupItem.light]!.tip, contains('Move the light in front of you'));
    });

    test('dark face with a dark room is shadow, not backlight; very bright is washed out', () {
      expect(check(times(m(face: 50, back: 45)))[SetupItem.light]!.tip, contains('in shadow'));
      expect(check(times(m(face: 240, back: 230)))[SetupItem.light]!.tip, contains('very bright'));
    });

    test('camera height from where the face sits: low face, camera too low; top edge, too high', () {
      expect(check(times(m(cy: 0.68)))[SetupItem.height]!.tip, contains('Raise the camera to eye height'));
      expect(check(times(m(cy: 0.2)))[SetupItem.height]!.tip, contains('near the top edge'));
      expect(check(times(m(cy: 0.42)))[SetupItem.height]!.ok, isTrue);
    });

    test('a moving picture is not steady; one stray frame does not fail the rest', () {
      final shaky = [for (var i = 0; i < 15; i++) m(cx: i.isEven ? 0.44 : 0.56)];
      expect(check(shaky)[SetupItem.steady]!.ok, isFalse);
      expect(check(shaky)[SetupItem.face]!.ok, isTrue, reason: 'the median is still central');
      final oneOff = [...times(m(), 14), m(cx: 0.9, face: 30)];
      final r = check(oneOff);
      expect((r[SetupItem.face]!.ok, r[SetupItem.light]!.ok), (true, true));
    });

    test('no face: say so, and wait on the rest', () {
      final r = check(times(m(seen: false)));
      expect(r[SetupItem.face]!.ok, isFalse);
      expect(r[SetupItem.face]!.tip, contains('No face in the picture'));
      expect(r[SetupItem.light]!.ok, isNull);
      expect(check(times(m(seen: false, back: 10)))[SetupItem.face]!.tip, contains('very dark'));
    });

    test('two faces: the largest is checked, and it says so', () {
      expect(check(times(m(faces: 2)))[SetupItem.face]!.tip, contains('More than one face'));
    });
  });

  group('frame measuring', () {
    test('face and background brightness from a BGRA frame, read in place', () {
      // A bright window behind a dark face: 64x48, face box in the middle.
      const w = 64, h = 48;
      final px = Uint8List(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final inFace = x >= 24 && x < 40 && y >= 12 && y < 32;
          final v = inFace ? 50 : 210;
          px.setAll((y * w + x) * 4, [v, v, v, 255]);
        }
      }
      final box = FaceBox(24 / w, 12 / h, 16 / w, 20 / h, 0.9);
      final r = measureFrame(Frame.bgra(w, h, px, w * 4), [box]);
      expect(r.faceLuma, closeTo(50, 1));
      expect(r.backLuma, closeTo(210, 1));
      expect(check(times(r))[SetupItem.light]!.tip, contains('light is behind you'));
    });

    test('the largest face is the one measured; a YUV frame reads its Y plane', () {
      final y = Uint8List(32 * 32)..fillRange(0, 32 * 32, 100);
      final u = Uint8List(16 * 16)..fillRange(0, 256, 128);
      final f = Frame.yuv420(32, 32, [y, u, u], [32, 16, 16], [1, 1, 1]);
      const small = FaceBox(0.1, 0.1, 0.1, 0.1, 0.9), big = FaceBox(0.4, 0.3, 0.3, 0.4, 0.8);
      final r = measureFrame(f, [small, big]);
      expect(r.face, big);
      expect(r.faces, 2);
      expect((r.faceLuma, r.backLuma), (100, 100));
      expect(measureFrame(f, const []).face, isNull);
    });
  });

  group('during a round', () {
    test('out of the picture for more than 3 s gives one gentle hint, cleared on return', () {
      final w = AwayWatch();
      final t0 = DateTime(2026, 11, 19, 10);
      w.add(m(), t0);
      w.add(m(seen: false), t0.add(const Duration(seconds: 1)));
      expect(
        w.hintAt(t0.add(const Duration(seconds: 3))),
        isNull,
        reason: 'exactly 3 s is not more than 3 s',
      );
      expect(w.hintAt(t0.add(const Duration(milliseconds: 3100))), AwayWatch.hint);
      w.add(m(), t0.add(const Duration(seconds: 4)));
      expect(w.hintAt(t0.add(const Duration(seconds: 5))), isNull);
      // Never seen at all since the round began counts from the start.
      final fresh = AwayWatch()..add(m(seen: false), t0);
      expect(fresh.hintAt(t0.add(const Duration(seconds: 4))), AwayWatch.hint);
    });

    test('the lens hint comes only from the face box place, and only when it holds', () {
      final l = LensHint();
      for (var i = 0; i < 30; i++) {
        l.add(m());
      }
      expect(l.current, isNull);
      for (var i = 0; i < 30; i++) {
        l.add(m(cx: 0.8));
      }
      expect(l.current, LensHint.hint);
      expect(LensHint.hint, contains('Optional'));
    });
  });

  group('the coach', () {
    test('everything is off until asked: camera, round hints, lens hint', () {
      final c = CameraCoach();
      expect((c.on, c.roundHints, c.lensHint, c.hint), (false, false, false, null));
      expect(c.selfView, isTrue, reason: 'self-view only matters once the camera is on');
      c.dispose();
    });

    test('hints show only when switched on; setup notes are the open tips at the start', () async {
      var now = DateTime(2026, 11, 19, 10);
      final cam = FakeCamera();
      final c = CameraCoach(clock: () => now);
      await c.turnOn(cam);
      expect(c.on, isTrue);
      final feed = cam.feeds.last;
      for (final f in times(m(face: 60, back: 200))) {
        feed.value.value = f;
        feed.value.value = null; // as frames come and go
      }
      c.roundStarted();
      expect(c.setupNotes.single, contains('light is behind you'));

      now = now.add(const Duration(seconds: 1));
      feed.value.value = m(seen: false);
      now = now.add(const Duration(seconds: 5));
      expect(c.hint, isNull, reason: 'the away hint is off by default');
      c.set(roundHints: true);
      expect(c.hint, AwayWatch.hint);

      await c.turnOff();
      expect((c.on, c.hint, c.checker.seen), (false, null, 0), reason: 'nothing it saw is kept');
      expect(feed.closed, isTrue);
      expect(c.setupNotes, hasLength(1), reason: 'the notes stay for the end of the round (in memory)');
      c.dispose();
    });

    test('the coach keeps only the last second of numbers and writes nothing anywhere', () async {
      final spy = _Spy();
      await IOOverrides.runZoned(
        () async {
          final cam = FakeCamera();
          final c = CameraCoach();
          await c.turnOn(cam);
          for (var i = 0; i < 500; i++) {
            cam.feeds.last.value.value = m(cx: 0.5 + (i % 7) / 100);
          }
          expect(c.checker.seen, lessThanOrEqualTo(c.checker.window));
          c.roundStarted();
          await c.turnOff();
          c.dispose();
        },
        createFile: spy.createFile,
        createDirectory: spy.createDirectory,
        createLink: spy.createLink,
      );
      expect(spy.made, isEmpty);
    });

    test('a camera that will not open says so and stays off', () async {
      final c = CameraCoach();
      await c.turnOn(_Broken());
      expect(c.on, isFalse);
      expect(c.error, contains('did not open'));
      c.dispose();
    });
  });
}

class _Broken extends FakeCamera {
  @override
  Future<CoachFeed> open() async => throw StateError('No camera was found.');
}
