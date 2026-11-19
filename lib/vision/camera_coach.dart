/// The camera coach (plan rule 4): an opt-in setup check before a round, and
/// during it, if asked, two gentle hints. It is off at the start of every
/// session and nothing about it is saved: not the choice, not a frame, not
/// a number. Frames are measured in memory and dropped (face_camera.dart),
/// nothing is sent or synced, and nothing it sees reaches a score.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../voice/models.dart';
import 'face_camera.dart';
import 'setup_check.dart';

/// A running camera, as the coach sees it: the latest frame's numbers, and
/// a preview to show when self-view is on.
abstract class CoachFeed {
  ValueListenable<FrameMeasure?> get measures;

  /// The live picture, or null where there is none (tests).
  Widget? preview();

  Future<void> close();
}

/// Opens the camera for the coach, once its face-box model is on the device.
abstract class CoachCamera {
  /// The model the face box needs (BlazeFace, 230 kB).
  SpeechModel get model;

  Future<bool> modelReady();
  Future<void> downloadModel({void Function(double share)? progress});
  Future<CoachFeed> open();
}

/// The device's camera with BlazeFace (camera on Android, camera_desktop on
/// Linux and Windows).
class NativeCoachCamera implements CoachCamera {
  NativeCoachCamera(this._models);
  final ModelManager _models;

  @override
  SpeechModel get model => speechModel(faceModelId);

  @override
  Future<bool> modelReady() => _models.installed(model);

  @override
  Future<void> downloadModel({void Function(double share)? progress}) =>
      _models.download(model, onProgress: (got, total) => progress?.call(got / total));

  @override
  Future<CoachFeed> open() async => _NativeFeed(await FaceCamera.open(_models.path(model)));
}

class _NativeFeed implements CoachFeed {
  _NativeFeed(this._cam);
  final FaceCamera _cam;

  @override
  ValueListenable<FrameMeasure?> get measures => _cam.measure;

  @override
  Widget? preview() =>
      AspectRatio(aspectRatio: _cam.controller.value.aspectRatio, child: _cam.controller.buildPreview());

  @override
  Future<void> close() => _cam.close();
}

/// The coach's state for one screen. Everything is in memory and goes with
/// it.
class CameraCoach extends ChangeNotifier {
  CameraCoach({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  CoachFeed? _feed;
  bool _opening = false, _disposed = false;
  String? _error;

  final checker = SetupChecker();
  final away = AwayWatch();
  final lens = LensHint();

  /// Show the live picture. Some people find it distracting.
  bool selfView = true;

  /// During the round: say so when the face has left the picture.
  bool roundHints = false;

  /// During the round: the "looking at the lens" hint, from the face box's
  /// place only.
  bool lensHint = false;

  /// The setup tips still open when the round started: information for the
  /// end of the round, never part of a score, never saved.
  List<String> setupNotes = const [];

  bool get on => _feed != null;
  bool get opening => _opening;
  String? get error => _error;
  CoachFeed? get feed => _feed;

  List<SetupResult> get results => checker.results;

  /// The one hint to show during a round, or null. Leaving the picture
  /// comes first; the lens hint only when switched on.
  String? get hint {
    if (!on) return null;
    if (roundHints) {
      final a = away.hintAt(_clock());
      if (a != null) return a;
    }
    return lensHint ? lens.current : null;
  }

  /// Turns the camera on with [camera]. Off again with [turnOff].
  Future<void> turnOn(CoachCamera camera) async {
    if (on || _opening) return;
    _opening = true;
    _error = null;
    _notify();
    try {
      final feed = await camera.open();
      if (_disposed) {
        await feed.close();
        return;
      }
      attach(feed);
    } on Object catch (e) {
      _error = 'The camera did not open: $e';
    } finally {
      _opening = false;
      _notify();
    }
  }

  /// Starts reading [feed] (turnOn's second half; tests call it directly).
  void attach(CoachFeed feed) {
    _feed = feed;
    feed.measures.addListener(_onMeasure);
    _notify();
  }

  void _onMeasure() {
    final m = _feed?.measures.value;
    if (m == null) return;
    add(m);
  }

  /// One frame's numbers.
  void add(FrameMeasure m) {
    checker.add(m);
    away.add(m, _clock());
    lens.add(m);
    _notify();
  }

  /// Notes the open tips as the round starts, and starts the round's
  /// watches afresh.
  void roundStarted() {
    setupNotes = on ? checker.notes : const [];
    away.reset();
    lens.reset();
    _notify();
  }

  /// Turns the camera off. Nothing it saw is kept.
  Future<void> turnOff() async {
    final f = _feed;
    _feed = null;
    f?.measures.removeListener(_onMeasure);
    checker.clear();
    away.reset();
    lens.reset();
    _notify();
    await f?.close();
  }

  void set({bool? selfView, bool? roundHints, bool? lensHint}) {
    this.selfView = selfView ?? this.selfView;
    this.roundHints = roundHints ?? this.roundHints;
    this.lensHint = lensHint ?? this.lensHint;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(turnOff());
    super.dispose();
  }
}
