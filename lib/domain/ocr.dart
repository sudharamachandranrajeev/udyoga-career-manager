/// Reading text from a screenshot on the device. Udyoga bundles no OCR: on
/// Linux and Windows it uses Tesseract when the user has installed it; on
/// Android it uses Google ML Kit, only after the user agrees (see
/// app/ocr.dart).
library;

import 'dart:io';
import 'dart:typed_data';

/// Reads the text in an image.
abstract interface class OcrEngine {
  /// A short name for the screen ("Tesseract", "ML Kit").
  String get name;

  /// The text in [png] (or JPEG), top to bottom.
  Future<String> read(Uint8List image);
}

/// Tesseract, run as a program. Found on the PATH, or in its usual Windows
/// folder.
class TesseractOcr implements OcrEngine {
  TesseractOcr(this.exe, {this.language = 'eng'});
  final String exe;
  final String language;

  @override
  String get name => 'Tesseract';

  /// Tesseract on this device, or null when it is not installed.
  static Future<TesseractOcr?> find({
    Future<ProcessResult> Function(String, List<String>)? run,
    bool? windows,
    Map<String, String>? env,
  }) async {
    final exec = run ?? Process.run;
    final win = windows ?? Platform.isWindows;
    try {
      final r = await exec(win ? 'where' : 'which', ['tesseract']);
      final path = '${r.stdout}'
          .split(RegExp(r'[\r\n]+'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .firstOrNull;
      if (r.exitCode == 0 && path != null) return TesseractOcr(path);
    } on ProcessException {
      // No which or where: try the usual folder below.
    }
    if (win) {
      final e = env ?? Platform.environment;
      for (final base in [
        e['ProgramFiles'],
        e['LOCALAPPDATA'] == null ? null : '${e['LOCALAPPDATA']}\\Programs',
      ]) {
        if (base == null) continue;
        final p = '$base\\Tesseract-OCR\\tesseract.exe';
        if (await File(p).exists()) return TesseractOcr(p);
      }
    }
    return null;
  }

  @override
  Future<String> read(Uint8List image) async {
    final dir = await Directory.systemTemp.createTemp('udyoga-ocr-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}page.png');
      await file.writeAsBytes(image);
      // "stdout" sends the text back instead of to a file; psm 3 finds the
      // page layout itself.
      final r = await Process.run(exe, [file.path, 'stdout', '-l', language, '--psm', '3']);
      if (r.exitCode != 0) throw OcrException('Tesseract could not read it: ${'${r.stderr}'.trim()}');
      return '${r.stdout}';
    } finally {
      await dir.delete(recursive: true).catchError((_) => dir);
    }
  }
}

class OcrException implements Exception {
  OcrException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What Android's ML Kit sends Google, said before the user agrees to use
/// it. ML Kit reads the text on the phone, but Google's data disclosure
/// says the SDK sends device and usage information (device model, OS
/// version, app, which ML Kit feature ran and how it performed) and has no
/// switch to turn that off.
const mlKitNotice =
    'Android reads the screenshot with Google ML Kit. The text stays on your phone, but ML Kit sends Google '
    'information about its use (your phone model and Android version, Udyoga\'s name, and how the text reading '
    'performed). It has no setting to stop that. Use it?';

/// Turns a data URL ("data:image/png;base64,...") into its bytes, or null.
Uint8List? dataUrlBytes(String url) {
  final m = RegExp(r'^data:image/(png|jpe?g|webp);base64,(.+)$', dotAll: true).firstMatch(url.trim());
  if (m == null) return null;
  try {
    return Uint8List.fromList(UriData.parse(url.trim()).contentAsBytes());
  } on FormatException {
    return null;
  }
}
