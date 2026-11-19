/// Finds a face box in a camera frame with MediaPipe's BlazeFace
/// short-range model, run by LiteRT (flutter_litert). Nothing else is
/// loaded: no landmarks, no face embedding, no identity, no emotion. The
/// frame is read in memory and never stored.
///
/// The decoding (anchors, boxes, overlap removal) is plain Dart so it can be
/// tested without the native runtime.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_litert/flutter_litert.dart';

/// A face box in 0..1 frame coordinates, with the model's score.
class FaceBox {
  const FaceBox(this.left, this.top, this.width, this.height, this.score);
  final double left, top, width, height, score;

  double get right => left + width;
  double get bottom => top + height;

  double iou(FaceBox o) {
    final w = math.min(right, o.right) - math.max(left, o.left);
    final h = math.min(bottom, o.bottom) - math.max(top, o.top);
    if (w <= 0 || h <= 0) return 0;
    final inter = w * h;
    return inter / (width * height + o.width * o.height - inter);
  }

  @override
  String toString() =>
      'FaceBox(${left.toStringAsFixed(2)}, ${top.toStringAsFixed(2)}, '
      '${width.toStringAsFixed(2)}x${height.toStringAsFixed(2)}, ${score.toStringAsFixed(2)})';
}

/// BlazeFace short range: 128x128 input, 896 anchors from two layers
/// (16x16 cells x 2 anchors, then 8x8 cells x 6 anchors).
const blazeInput = 128;

/// Anchor centres (x, y) in 0..1, in the model's output order.
final List<(double, double)> blazeAnchors = () {
  final out = <(double, double)>[];
  for (final (cells, perCell) in [(16, 2), (8, 6)]) {
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        for (var k = 0; k < perCell; k++) {
          out.add(((x + 0.5) / cells, (y + 0.5) / cells));
        }
      }
    }
  }
  return out;
}();

/// Boxes from the model's raw outputs: [boxes] holds 16 numbers per anchor
/// (centre offset, size, then 6 keypoints, which are ignored), [scores] one
/// logit per anchor. Keeps those over [minScore], then drops overlaps.
List<FaceBox> decodeBlazeFace(
  Float32List boxes,
  Float32List scores, {
  double minScore = 0.6,
  double maxOverlap = 0.3,
}) {
  final found = <FaceBox>[];
  for (var i = 0; i < blazeAnchors.length; i++) {
    final logit = scores[i].clamp(-100.0, 100.0);
    final score = 1 / (1 + math.exp(-logit));
    if (score < minScore) continue;
    final (ax, ay) = blazeAnchors[i];
    final b = i * 16;
    final cx = boxes[b] / blazeInput + ax, cy = boxes[b + 1] / blazeInput + ay;
    final w = boxes[b + 2] / blazeInput, h = boxes[b + 3] / blazeInput;
    found.add(FaceBox(cx - w / 2, cy - h / 2, w, h, score));
  }
  found.sort((a, b) => b.score.compareTo(a.score));
  final kept = <FaceBox>[];
  for (final f in found) {
    if (kept.every((k) => k.iou(f) <= maxOverlap)) kept.add(f);
  }
  return kept;
}

/// A frame in memory: BGRA (desktop) or the Y, U and V planes of YUV420
/// (Android). Only read, never kept.
class Frame {
  Frame.bgra(this.width, this.height, Uint8List bytes, int bytesPerRow)
    : planes = [bytes],
      rowStrides = [bytesPerRow],
      pixelStrides = const [4],
      yuv = false;

  Frame.yuv420(this.width, this.height, this.planes, this.rowStrides, this.pixelStrides) : yuv = true;

  final int width, height;
  final List<Uint8List> planes;
  final List<int> rowStrides, pixelStrides;
  final bool yuv;
}

/// The model input: the centre square of [f], scaled to 128x128 by nearest
/// neighbour, as RGB floats in -1..1. Returns the square's place in the
/// frame (left, top, side, all 0..1 of width or height) to map boxes back.
(Float32List, double, double, double) blazeInputFrom(Frame f) {
  final side = math.min(f.width, f.height);
  final x0 = (f.width - side) ~/ 2, y0 = (f.height - side) ~/ 2;
  final out = Float32List(blazeInput * blazeInput * 3);
  var o = 0;
  for (var y = 0; y < blazeInput; y++) {
    final sy = y0 + (y * side) ~/ blazeInput;
    for (var x = 0; x < blazeInput; x++) {
      final sx = x0 + (x * side) ~/ blazeInput;
      int r, g, b;
      if (f.yuv) {
        final yv = f.planes[0][sy * f.rowStrides[0] + sx];
        final ui = (sy >> 1) * f.rowStrides[1] + (sx >> 1) * f.pixelStrides[1];
        final u = f.planes[1][ui] - 128, v = f.planes[2][ui] - 128;
        r = (yv + 1.402 * v).round().clamp(0, 255);
        g = (yv - 0.344 * u - 0.714 * v).round().clamp(0, 255);
        b = (yv + 1.772 * u).round().clamp(0, 255);
      } else {
        final i = sy * f.rowStrides[0] + sx * 4;
        b = f.planes[0][i];
        g = f.planes[0][i + 1];
        r = f.planes[0][i + 2];
      }
      out[o++] = r / 127.5 - 1;
      out[o++] = g / 127.5 - 1;
      out[o++] = b / 127.5 - 1;
    }
  }
  return (out, x0 / f.width, y0 / f.height, side / f.width);
}

/// Runs BlazeFace on frames with LiteRT on the CPU.
class BlazeFaceDetector {
  BlazeFaceDetector._(this._interpreter, this._boxesAt, this._scoresAt);

  /// Loads the downloaded model at [modelPath].
  static BlazeFaceDetector open(String modelPath) {
    final it = Interpreter.fromFile(File(modelPath), options: InterpreterOptions()..threads = 2);
    it.allocateTensors();
    // The two outputs are told apart by shape: [1, 896, 16] and [1, 896, 1].
    final a = it.getOutputTensor(0).shape.last == 16 ? 0 : 1;
    return BlazeFaceDetector._(it, a, 1 - a);
  }

  final Interpreter _interpreter;
  final int _boxesAt, _scoresAt;

  /// Face boxes in [f], in 0..1 of the whole frame.
  List<FaceBox> detect(Frame f) {
    final (input, left, top, side) = blazeInputFrom(f);
    _interpreter.getInputTensor(0).asFloat32View().setAll(0, input);
    _interpreter.invoke();
    final boxes = _interpreter.getOutputTensor(_boxesAt).asFloat32View();
    final scores = _interpreter.getOutputTensor(_scoresAt).asFloat32View();
    final sideY = side * f.width / f.height;
    return [
      for (final b in decodeBlazeFace(boxes, scores))
        FaceBox(left + b.left * side, top + b.top * sideY, b.width * side, b.height * sideY, b.score),
    ];
  }

  void close() => _interpreter.close();
}
