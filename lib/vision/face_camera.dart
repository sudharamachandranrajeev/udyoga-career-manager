/// The lab's camera: `camera` (CameraX on Android) or `camera_desktop`
/// (GStreamer on Linux, Windows), with BlazeFace drawing a box round the
/// face. Each frame is read in memory, measured and dropped; no frame is
/// ever written anywhere.
library;

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'blazeface.dart';

/// [img] as a [Frame], without copying the pixels.
Frame frameOf(CameraImage img) {
  if (img.format.group == ImageFormatGroup.yuv420 && img.planes.length == 3) {
    return Frame.yuv420(
      img.width,
      img.height,
      [for (final p in img.planes) p.bytes],
      [for (final p in img.planes) p.bytesPerRow],
      [for (final p in img.planes) p.bytesPerPixel ?? 1],
    );
  }
  final p = img.planes.first;
  return Frame.bgra(img.width, img.height, p.bytes, p.bytesPerRow);
}

/// A camera with a face box. [boxes] and [fps] update as frames arrive.
class FaceCamera {
  FaceCamera._(this.controller, this._detector);

  final CameraController controller;
  final BlazeFaceDetector _detector;

  /// The faces in the latest frame looked at.
  final boxes = ValueNotifier<List<FaceBox>>(const []);

  /// Frames run through the face finder per second, over the last second.
  final fps = ValueNotifier<double>(0);

  /// Average time the face finder took per frame, in milliseconds.
  final detectMs = ValueNotifier<double>(0);

  bool _busy = false;
  int _frames = 0;
  double _msTotal = 0;
  final _window = Stopwatch();

  /// Opens the first front camera (or any camera) and starts looking for
  /// a face with the BlazeFace model at [modelPath].
  static Future<FaceCamera> open(String modelPath) async {
    final cams = await availableCameras();
    if (cams.isEmpty) throw StateError('No camera was found.');
    final cam = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    final controller = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
    await controller.initialize();
    final fc = FaceCamera._(controller, BlazeFaceDetector.open(modelPath));
    fc._window.start();
    await controller.startImageStream(fc._onFrame);
    return fc;
  }

  void _onFrame(CameraImage img) {
    // One frame at a time; frames that arrive meanwhile are dropped.
    if (_busy) return;
    _busy = true;
    try {
      final t = Stopwatch()..start();
      boxes.value = _detector.detect(frameOf(img));
      _msTotal += t.elapsedMicroseconds / 1000;
      _frames++;
      if (_window.elapsedMilliseconds >= 1000) {
        fps.value = _frames * 1000 / _window.elapsedMilliseconds;
        detectMs.value = _msTotal / _frames;
        _frames = 0;
        _msTotal = 0;
        _window.reset();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> close() async {
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    await controller.dispose();
    _detector.close();
    boxes.dispose();
    fps.dispose();
    detectMs.dispose();
  }
}
