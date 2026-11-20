/// The camera coach's setup check, as a video interview needs it: a face in
/// the picture and near the middle, head and shoulders in frame, light in
/// front, the camera near eye height and a steady picture.
///
/// Plan rule 4 binds everything here. It reads only the face box (where a
/// face is, how big) and how bright the face and the rest of the picture
/// are. Nothing says who the person is, what they feel or where they look,
/// and nothing is scored: each check is fine or comes with a plain tip.
/// The numbers live in memory for a few seconds and are never stored.
library;

import 'dart:math' as math;

import 'blazeface.dart';

/// What one frame showed, as numbers only: the largest face box (null with
/// none), how many faces, and the mean brightness (0 to 255) of the face
/// box and of everything outside it. The frame itself is not kept.
class FrameMeasure {
  const FrameMeasure({this.face, this.faces = 0, this.faceLuma = 0, this.backLuma = 0, this.frameLuma = 0});

  final FaceBox? face;
  final int faces;
  final double faceLuma, backLuma, frameLuma;

  double get cx => face == null ? 0 : face!.left + face!.width / 2;
  double get cy => face == null ? 0 : face!.top + face!.height / 2;
}

/// Brightness (BT.601 luma) of a pixel of [f], read in place.
double _luma(Frame f, int x, int y) {
  if (f.yuv) return f.planes[0][y * f.rowStrides[0] + x].toDouble();
  final i = y * f.rowStrides[0] + x * 4;
  final p = f.planes[0];
  return 0.114 * p[i] + 0.587 * p[i + 1] + 0.299 * p[i + 2];
}

/// Measures [f] given the face boxes found in it. Reads a grid of about
/// 80 by 60 points, so it costs well under a millisecond, and returns only
/// the numbers.
FrameMeasure measureFrame(Frame f, List<FaceBox> faces) {
  FaceBox? face;
  for (final b in faces) {
    if (face == null || b.width * b.height > face.width * face.height) face = b;
  }
  final stepX = math.max(1, f.width ~/ 80), stepY = math.max(1, f.height ~/ 60);
  var inSum = 0.0, outSum = 0.0, all = 0.0;
  var inN = 0, outN = 0, allN = 0;
  for (var y = stepY ~/ 2; y < f.height; y += stepY) {
    for (var x = stepX ~/ 2; x < f.width; x += stepX) {
      final l = _luma(f, x, y);
      all += l;
      allN++;
      final fx = (x + 0.5) / f.width, fy = (y + 0.5) / f.height;
      if (face != null && fx >= face.left && fx < face.right && fy >= face.top && fy < face.bottom) {
        inSum += l;
        inN++;
      } else {
        outSum += l;
        outN++;
      }
    }
  }
  final whole = allN == 0 ? 0.0 : all / allN;
  return FrameMeasure(
    face: face,
    faces: faces.length,
    faceLuma: inN == 0 ? whole : inSum / inN,
    backLuma: outN == 0 ? whole : outSum / outN,
    frameLuma: whole,
  );
}

/// The things the setup check looks at, in the order they are shown.
enum SetupItem {
  face('Face in the picture'),
  framing('Head and shoulders'),
  light('Light'),
  height('Camera height'),
  steady('Steady picture');

  const SetupItem(this.label);
  final String label;
}

/// One check: [ok] true (a green tick), false (with a [tip]) or null while
/// there is not enough to go on (or an earlier check must pass first).
class SetupResult {
  const SetupResult(this.item, this.ok, this.tip);
  final SetupItem item;
  final bool? ok;

  /// What to do, in plain words; what is fine, when [ok].
  final String tip;

  @override
  String toString() => '${item.name}: ${ok ?? '…'} $tip';
}

/// The limits each check uses, in 0..1 of the picture or 0..255 of light.
/// Written out so they can be read and argued with.
abstract final class SetupLimits {
  /// The face's centre may be this far from the middle, across.
  static const offCentre = 0.15;

  /// Face box height for head and shoulders (BlazeFace's box runs from the
  /// brow to the chin).
  static const smallFace = 0.18, bigFace = 0.5;

  /// Face brightness: below [dark] is in shadow, above [bright] washed out.
  static const dark = 70.0, bright = 225.0;

  /// The rest of the picture this much brighter than the face: backlit.
  static const backlight = 45.0;

  /// Where the face's centre sits, down the picture. Lower than [low]: the
  /// camera points up at the face (sits low); higher than [high]: little
  /// room above the head.
  static const high = 0.28, low = 0.6;

  /// Spread of the face's centre over the window: more is a moving picture.
  static const shake = 0.025;
}

/// Reads the last [window] frames (about one second) and gives each check's
/// state. Medians smooth out one bad frame.
class SetupChecker {
  SetupChecker({this.window = 15});

  final int window;
  final _recent = <FrameMeasure>[];

  void add(FrameMeasure m) {
    _recent.add(m);
    if (_recent.length > window) _recent.removeAt(0);
  }

  void clear() => _recent.clear();

  /// Frames looked at so far, up to [window].
  int get seen => _recent.length;

  static double _median(Iterable<double> xs) {
    final s = xs.toList()..sort();
    if (s.isEmpty) return 0;
    return s.length.isOdd ? s[s.length ~/ 2] : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
  }

  static double _spread(Iterable<double> xs) {
    final l = xs.toList();
    if (l.length < 2) return 0;
    final mean = l.reduce((a, b) => a + b) / l.length;
    return math.sqrt(l.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / l.length);
  }

  List<SetupResult> get results {
    const wait = 'Checking…';
    if (_recent.length < math.min(5, window)) {
      return [for (final i in SetupItem.values) SetupResult(i, null, wait)];
    }
    final withFace = [
      for (final m in _recent)
        if (m.face != null) m,
    ];
    // A face in at least half the frames counts as in the picture.
    if (withFace.length * 2 < _recent.length) {
      final lum = _median(_recent.map((m) => m.frameLuma));
      return [
        SetupResult(
          SetupItem.face,
          false,
          lum < SetupLimits.dark / 2
              ? 'The picture is very dark, so no face shows. Turn on a light in front of you, or check '
                    'nothing covers the camera.'
              : 'No face in the picture yet. Sit facing the camera and check nothing covers it.',
        ),
        for (final i in SetupItem.values.skip(1)) SetupResult(i, null, 'Needs a face in the picture first.'),
      ];
    }
    final cx = _median(withFace.map((m) => m.cx)), cy = _median(withFace.map((m) => m.cy));
    final h = _median(withFace.map((m) => m.face!.height));
    final top = _median(withFace.map((m) => m.face!.top));
    final faceL = _median(withFace.map((m) => m.faceLuma)), backL = _median(withFace.map((m) => m.backLuma));
    final many = _median(withFace.map((m) => m.faces.toDouble())) > 1;

    final SetupResult face;
    if ((cx - 0.5).abs() > SetupLimits.offCentre) {
      face = const SetupResult(
        SetupItem.face,
        false,
        'Move so your face is in the middle of the picture, or turn the camera toward you.',
      );
    } else {
      face = SetupResult(
        SetupItem.face,
        true,
        many ? 'In the middle. More than one face shows: the check follows the largest.' : 'In the middle.',
      );
    }

    final SetupResult framing;
    if (h < SetupLimits.smallFace) {
      framing = const SetupResult(
        SetupItem.framing,
        false,
        'Move closer to the camera: your head and shoulders should fill most of the picture.',
      );
    } else if (h > SetupLimits.bigFace) {
      framing = const SetupResult(
        SetupItem.framing,
        false,
        'Move back a little, so your shoulders show as well as your face.',
      );
    } else {
      framing = const SetupResult(SetupItem.framing, true, 'Head and shoulders fit the picture.');
    }

    final SetupResult light;
    if (backL - faceL > SetupLimits.backlight) {
      light = const SetupResult(
        SetupItem.light,
        false,
        'The light is behind you, so your face looks dark. Move the light in front of you, or turn so the '
        'window is in front of you.',
      );
    } else if (faceL < SetupLimits.dark) {
      light = const SetupResult(
        SetupItem.light,
        false,
        'Your face is in shadow. Add light in front of you: a lamp behind the screen, or face a window.',
      );
    } else if (faceL > SetupLimits.bright) {
      light = const SetupResult(
        SetupItem.light,
        false,
        'Your face is very bright. Move the light back a little or soften it.',
      );
    } else {
      light = const SetupResult(SetupItem.light, true, 'Your face is lit from the front.');
    }

    final SetupResult height;
    if (cy > SetupLimits.low) {
      height = const SetupResult(
        SetupItem.height,
        false,
        'Your face sits low in the picture, so the camera looks up at you. Raise the camera to eye height: '
        'a few books under the laptop work.',
      );
    } else if (cy < SetupLimits.high || top < 0.02) {
      height = const SetupResult(
        SetupItem.height,
        false,
        'Your head is near the top edge. Tilt the camera down a little, or lower it to eye height.',
      );
    } else {
      height = const SetupResult(SetupItem.height, true, 'About eye height.');
    }

    final SetupResult steady;
    if (withFace.length < math.min(10, window)) {
      steady = const SetupResult(SetupItem.steady, null, wait);
    } else if (math.max(_spread(withFace.map((m) => m.cx)), _spread(withFace.map((m) => m.cy))) >
        SetupLimits.shake) {
      steady = const SetupResult(
        SetupItem.steady,
        false,
        'The picture is moving. Rest the camera or phone on something steady.',
      );
    } else {
      steady = const SetupResult(SetupItem.steady, true, 'Steady.');
    }
    return [face, framing, light, height, steady];
  }

  /// True when every check has a green tick.
  bool get allGood => results.every((r) => r.ok == true);

  /// The tips still open, for the round's setup notes.
  List<String> get notes => [
    for (final r in results)
      if (r.ok == false) r.tip,
  ];
}

/// During a round: a gentle hint once no face has shown for longer than
/// [after], cleared as soon as one does. Only the time since a face was
/// last seen is kept.
class AwayWatch {
  AwayWatch({this.after = const Duration(seconds: 3)});

  final Duration after;
  DateTime? _lastFace, _started;

  static const hint = 'You have moved out of the picture.';

  /// Notes a frame looked at [at].
  void add(FrameMeasure m, DateTime at) {
    _started ??= at;
    if (m.face != null) _lastFace = at;
  }

  /// The hint to show at [now], or null.
  String? hintAt(DateTime now) {
    final since = _lastFace ?? _started;
    if (since == null) return null;
    return now.difference(since) > after ? hint : null;
  }

  void reset() => _lastFace = _started = null;
}

/// The optional "looking at the lens" hint, from the face box's place only
/// (no eyes, no gaze model): when the face sits well to one side, or low,
/// for most of the last [window] frames, the camera is not in front of the
/// person, so looking at the panel's window does not look at the lens.
class LensHint {
  LensHint({this.window = 30});

  final int window;
  final _recent = <FrameMeasure>[];

  static const hint =
      'The camera sees you from an angle. To seem to look at the panel, put their window just under the '
      'camera, or glance at the lens when you make a key point. Optional.';

  void add(FrameMeasure m) {
    if (m.face == null) return;
    _recent.add(m);
    if (_recent.length > window) _recent.removeAt(0);
  }

  String? get current {
    if (_recent.length < window ~/ 2) return null;
    final off = _recent.where((m) => (m.cx - 0.5).abs() > SetupLimits.offCentre || m.cy > SetupLimits.low);
    return off.length * 3 >= _recent.length * 2 ? hint : null;
  }

  void reset() => _recent.clear();
}
