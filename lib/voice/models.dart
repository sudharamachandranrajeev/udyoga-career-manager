/// Speech and vision models for the interview simulator.
///
/// None of them ship with Udyoga. Each one is downloaded only when the user
/// asks, from the project that publishes it, checked against the SHA-256
/// pinned here, and kept in the app's own data folder (never synced). The
/// user sees the size before downloading and can delete any of them.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// What a model is for.
enum ModelRole { voice, vad, transcribe, face }

/// One downloadable model, pinned by URL, size and SHA-256.
class SpeechModel {
  const SpeechModel({
    required this.id,
    required this.label,
    required this.role,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.entry,
    required this.source,
    required this.licence,
    this.archive = false,
    this.drop = const [],
  });

  /// Folder name under the models folder; never changes once released.
  final String id;
  final String label;
  final ModelRole role;

  /// The official release URL.
  final String url;

  /// SHA-256 of the downloaded file (the archive, for an archive).
  final String sha256;

  /// Size of the download in bytes, shown before it starts.
  final int bytes;

  /// The main file, relative to the model's folder, once installed.
  final String entry;

  /// Who publishes it, shown with the licence.
  final String source;
  final String licence;

  /// A .tar.bz2 that is unpacked after the check.
  final bool archive;

  /// Paths in the archive that are not needed and are deleted after
  /// unpacking.
  final List<String> drop;
}

/// The models the interview simulator can use. URLs are the publishers' own
/// release links; hashes are the publishers' (GitHub release digests) or,
/// for MediaPipe, measured on 2026-11-19.
const speechModels = <SpeechModel>[
  SpeechModel(
    id: 'kokoro-en-gb-int8',
    label: 'Interviewer voice (Kokoro, British English)',
    role: ModelRole.voice,
    url:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/'
        'kokoro-int8-multi-lang-v1_0.tar.bz2',
    sha256: '72c347230107ef8a31098ec4d468a605244beef5f1ed00db97efa13518800653',
    bytes: 132353410,
    entry: 'kokoro-int8-multi-lang-v1_0/model.int8.onnx',
    source: 'hexgrad/Kokoro-82M via k2-fsa/sherpa-onnx',
    licence: 'Apache-2.0',
    archive: true,
    // Only the English parts are kept: the Chinese dictionaries and rules,
    // the US lexicon and espeak-ng's data (unused since sherpa-onnx 2.0).
    drop: [
      'kokoro-int8-multi-lang-v1_0/espeak-ng-data',
      'kokoro-int8-multi-lang-v1_0/dict',
      'kokoro-int8-multi-lang-v1_0/lexicon-zh.txt',
      'kokoro-int8-multi-lang-v1_0/lexicon-us-en.txt',
      'kokoro-int8-multi-lang-v1_0/date-zh.fst',
      'kokoro-int8-multi-lang-v1_0/number-zh.fst',
      'kokoro-int8-multi-lang-v1_0/phone-zh.fst',
    ],
  ),
  SpeechModel(
    id: 'silero-vad',
    label: 'Speech detector (Silero VAD)',
    role: ModelRole.vad,
    url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx',
    sha256: '9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6',
    bytes: 643854,
    entry: 'silero_vad.onnx',
    source: 'snakers4/silero-vad via k2-fsa/sherpa-onnx',
    licence: 'MIT',
  ),
  SpeechModel(
    id: 'moonshine-base-en',
    label: 'Transcriber (Moonshine base, English)',
    role: ModelRole.transcribe,
    url:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
        'sherpa-onnx-moonshine-base-en-quantized-2026-02-27.tar.bz2',
    sha256: '43232c1d13013d37317163baec3135bd771a186a4356f28c889bab453bb0e891',
    bytes: 111266225,
    entry: 'sherpa-onnx-moonshine-base-en-quantized-2026-02-27/encoder_model.ort',
    source: 'moonshine-ai/moonshine via k2-fsa/sherpa-onnx',
    // The English Moonshine models are MIT; other languages are not, so
    // only English is offered.
    licence: 'MIT',
    archive: true,
    drop: ['sherpa-onnx-moonshine-base-en-quantized-2026-02-27/test_wavs'],
  ),
  SpeechModel(
    id: 'moonshine-tiny-en',
    label: 'Transcriber, lighter (Moonshine tiny, English)',
    role: ModelRole.transcribe,
    url:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
        'sherpa-onnx-moonshine-tiny-en-quantized-2026-02-27.tar.bz2',
    sha256: '9ec31b342d8fa3240c3b81b8f82e1cf7e3ac467c93ca5a999b741d5887164f8d',
    bytes: 29858559,
    entry: 'sherpa-onnx-moonshine-tiny-en-quantized-2026-02-27/encoder_model.ort',
    source: 'moonshine-ai/moonshine via k2-fsa/sherpa-onnx',
    licence: 'MIT',
    archive: true,
    drop: ['sherpa-onnx-moonshine-tiny-en-quantized-2026-02-27/test_wavs'],
  ),
  SpeechModel(
    id: 'blazeface-short-range',
    label: 'Face finder (MediaPipe BlazeFace, short range)',
    role: ModelRole.face,
    url:
        'https://storage.googleapis.com/mediapipe-models/face_detector/'
        'blaze_face_short_range/float16/1/blaze_face_short_range.tflite',
    sha256: 'b4578f35940bf5a1a655214a1cce5cab13eba73c1297cd78e1a04c2380b0152f',
    bytes: 229746,
    entry: 'blaze_face_short_range.tflite',
    source: 'Google MediaPipe model card (model file only; no MediaPipe runtime)',
    licence: 'Apache-2.0',
  ),
];

SpeechModel speechModel(String id) => speechModels.firstWhere((m) => m.id == id);

/// Folders earlier versions downloaded and no longer use (the I0 spike's
/// whisper.cpp models). The lab offers to delete them.
const retiredModelIds = ['whisper-base-en', 'whisper-small-en'];

/// The default transcriber, voice and speech detector of a spoken round.
const defaultTranscriber = 'moonshine-base-en';
const voiceModelId = 'kokoro-en-gb-int8';
const vadModelId = 'silero-vad';

/// A download that failed; [message] is for the user.
class ModelException implements Exception {
  ModelException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// "21.1 MB" from a byte count.
String formatBytes(int bytes) {
  if (bytes < 1000) return '$bytes B';
  if (bytes < 1000 * 1000) return '${(bytes / 1000).toStringAsFixed(0)} kB';
  if (bytes < 1000 * 1000 * 1000) return '${(bytes / 1e6).toStringAsFixed(1)} MB';
  return '${(bytes / 1e9).toStringAsFixed(2)} GB';
}

/// Downloads, checks, lists and deletes [speechModels] under [root].
///
/// Layout: `<root>/<id>/...` holds an installed model, with a `.verified`
/// file holding the SHA-256 it was checked against. A download in progress
/// is `<root>/<id>.part`; it is deleted if it fails or does not match.
class ModelManager {
  ModelManager(this.root, {this.client});

  final Directory root;

  /// The HTTP client to use; null means a fresh one per download.
  final http.Client? client;

  static const _marker = '.verified';

  Directory _dir(SpeechModel m) => Directory('${root.path}/${m.id}');

  /// The installed model's main file.
  String path(SpeechModel m) => '${_dir(m).path}/${m.entry}';

  /// The folder holding the main file (a sherpa voice needs its tokens and
  /// espeak-ng-data, which sit beside the model).
  String folder(SpeechModel m) => File(path(m)).parent.path;

  /// True once [m] was downloaded and matched its SHA-256.
  Future<bool> installed(SpeechModel m) async {
    final marker = File('${_dir(m).path}/$_marker');
    if (!await marker.exists() || !await File(path(m)).exists()) return false;
    return (await marker.readAsString()).trim() == m.sha256;
  }

  /// Bytes [m] takes on disk (0 when not installed).
  Future<int> sizeOnDisk(SpeechModel m) async {
    final d = _dir(m);
    if (!await d.exists()) return 0;
    var n = 0;
    await for (final e in d.list(recursive: true, followLinks: false)) {
      if (e is File) n += await e.length();
    }
    return n;
  }

  /// Downloads [m], checks its size and SHA-256, and installs it. A
  /// mismatch deletes the download and throws [ModelException]; nothing is
  /// installed. [onProgress] gets bytes received and the expected total.
  Future<void> download(SpeechModel m, {void Function(int received, int total)? onProgress}) async {
    await root.create(recursive: true);
    final part = File('${root.path}/${m.id}.part');
    final c = client ?? http.Client();
    try {
      final res = await c.send(http.Request('GET', Uri.parse(m.url)));
      if (res.statusCode != 200) {
        throw ModelException('${m.label}: the download failed (HTTP ${res.statusCode}).');
      }
      final sink = part.openWrite();
      final digest = _DigestSink();
      final hasher = sha256.startChunkedConversion(digest);
      var received = 0;
      try {
        await for (final chunk in res.stream) {
          received += chunk.length;
          if (received > m.bytes) {
            throw ModelException('${m.label}: the download is bigger than expected, so it was stopped.');
          }
          hasher.add(chunk);
          sink.add(chunk);
          onProgress?.call(received, m.bytes);
        }
      } finally {
        await sink.close();
      }
      hasher.close();
      if (received != m.bytes) {
        throw ModelException('${m.label}: the download is incomplete ($received of ${m.bytes} bytes).');
      }
      if (digest.value.toString() != m.sha256) {
        throw ModelException(
          '${m.label}: the file does not match its published checksum, so it was deleted.',
        );
      }
      await _install(m, part);
    } finally {
      if (client == null) c.close();
      if (await part.exists()) await part.delete();
    }
  }

  Future<void> _install(SpeechModel m, File verified) async {
    final dir = _dir(m);
    final staging = Directory('${root.path}/${m.id}.new');
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);
    if (m.archive) {
      final from = verified.path, to = staging.path;
      await Isolate.run(() {
        final tar = BZip2Decoder().decodeBytes(File(from).readAsBytesSync());
        extractArchiveToDiskSync(TarDecoder().decodeBytes(tar), to);
      });
    } else {
      await verified.rename('${staging.path}/${m.entry}');
    }
    for (final d in m.drop) {
      final e = FileSystemEntity.typeSync('${staging.path}/$d');
      if (e == FileSystemEntityType.directory) await Directory('${staging.path}/$d').delete(recursive: true);
      if (e == FileSystemEntityType.file) await File('${staging.path}/$d').delete();
    }
    if (!await File('${staging.path}/${m.entry}').exists()) {
      await staging.delete(recursive: true);
      throw ModelException('${m.label}: the download does not hold ${m.entry}.');
    }
    await File('${staging.path}/$_marker').writeAsString(m.sha256);
    if (await dir.exists()) await dir.delete(recursive: true);
    await staging.rename(dir.path);
  }

  /// Bytes held by [retiredModelIds] folders still on this device.
  Future<int> retiredBytes() async {
    var n = 0;
    for (final id in retiredModelIds) {
      final d = Directory('${root.path}/$id');
      if (!await d.exists()) continue;
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) n += await e.length();
      }
    }
    return n;
  }

  /// Deletes every [retiredModelIds] folder.
  Future<void> deleteRetired() async {
    for (final id in retiredModelIds) {
      final d = Directory('${root.path}/$id');
      if (await d.exists()) await d.delete(recursive: true);
    }
  }

  /// Deletes [m] and any half-finished download of it.
  Future<void> delete(SpeechModel m) async {
    for (final e in [_dir(m), Directory('${root.path}/${m.id}.new')]) {
      if (await e.exists()) await e.delete(recursive: true);
    }
    final part = File('${root.path}/${m.id}.part');
    if (await part.exists()) await part.delete();
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
