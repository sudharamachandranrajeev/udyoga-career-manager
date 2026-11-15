import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'resume.dart';

/// The kinds of file Udyoga reads from the candidate's folders.
const documentExtensions = {'pdf', 'docx', 'txt', 'md'};

/// Larger files are skipped: CVs, letters and notes are far smaller, and the
/// AI takes PDFs only up to about this size.
const maxDocumentBytes = 15 * 1024 * 1024;

/// Folders never worth reading: version control, build output, caches.
const _skipDirs = {'.git', 'node_modules', 'build', '.dart_tool', '__pycache__', '.cache', '.Trash'};

/// A file found in one of the candidate's folders, read and hashed.
class FoundDocument {
  const FoundDocument({required this.path, required this.name, required this.bytes, required this.hash});
  final String path, name;
  final Uint8List bytes;

  /// SHA-256 of [bytes], hex: the same file anywhere is the same document.
  final String hash;

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  bool get isPdf => extension == 'pdf';

  /// The text, for Word, text and Markdown files; '' for PDFs (the AI reads
  /// those whole) and for files that will not open.
  String get text {
    try {
      return switch (extension) {
        'docx' => docxText(bytes),
        'txt' || 'md' => utf8.decode(bytes, allowMalformed: true),
        _ => '',
      };
    } on FormatException {
      return '';
    }
  }
}

String hashOf(List<int> bytes) => sha256.convert(bytes).toString();

/// Every readable document under [folders], each file once even when folders
/// overlap. Hidden files and folders and [_skipDirs] are left out; folders
/// that are missing or cannot be read are skipped silently (a USB drive that
/// is not plugged in is normal).
Future<List<FoundDocument>> scanFolders(List<String> folders) async {
  final seen = <String>{};
  final found = <FoundDocument>[];
  for (final folder in folders) {
    final dir = Directory(folder);
    if (!await dir.exists()) continue;
    await for (final f in _walk(dir)) {
      final name = f.uri.pathSegments.last;
      if (!documentExtensions.contains(name.split('.').last.toLowerCase())) continue;
      if (name.startsWith('~\$')) continue; // Word's lock files
      try {
        if (await f.length() > maxDocumentBytes) continue;
        final path = f.absolute.path;
        if (!seen.add(path)) continue;
        final bytes = await f.readAsBytes();
        found.add(FoundDocument(path: path, name: name, bytes: bytes, hash: hashOf(bytes)));
      } on FileSystemException {
        continue;
      }
    }
  }
  return found;
}

Stream<File> _walk(Directory dir) async* {
  List<FileSystemEntity> entries;
  try {
    entries = await dir.list(followLinks: false).toList();
  } on FileSystemException {
    return;
  }
  for (final e in entries) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name.startsWith('.')) continue;
    if (e is File) {
      yield e;
    } else if (e is Directory && !_skipDirs.contains(name)) {
      yield* _walk(e);
    }
  }
}
