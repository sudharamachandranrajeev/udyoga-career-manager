/// The page reader's and the recipes' device parts: the recipes folder and
/// what it holds, and the OCR this device has (Tesseract on Linux and
/// Windows when installed, ML Kit on Android once the user agrees).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/ocr.dart';
import '../domain/polite.dart';
import '../domain/recipes.dart';
import 'providers.dart';

/// The recipes in this device's recipes folder, re-read after each change.
final recipesProvider = FutureProvider<RecipeSet>((ref) async {
  ref.watch(revisionProvider);
  return savedRecipes(ref.watch(sessionProvider).db);
});

/// The recipes folder chosen on this device, or ''.
final recipesFolderProvider = FutureProvider<String>((ref) async {
  ref.watch(revisionProvider);
  return (await ref.watch(sessionProvider).db.localSetting(recipesFolderKey) ?? '').trim();
});

/// Each recipe's use today, by id.
final recipeUsageProvider = FutureProvider<Map<String, int>>((ref) async {
  final set = await ref.watch(recipesProvider.future);
  final counter = DailyCounter(ref.watch(sessionProvider).db);
  return {for (final r in set.recipes) r.id: await counter.used(r.use)};
});

/// Device-only key: "yes" once the user agreed to ML Kit, "no" if they
/// declined.
const mlKitConsentKey = 'udyoga.ocr.mlkit';

/// The OCR on this device: Tesseract (when installed) on a desktop, ML Kit
/// on Android; null when there is none. ML Kit still needs the user's
/// consent before each first use ([mlKitConsentKey]).
final ocrProvider = FutureProvider<OcrEngine?>((ref) async {
  if (Platform.isAndroid) return MlKitOcr();
  if (Platform.isLinux || Platform.isWindows) return TesseractOcr.find();
  return null;
});

/// Google ML Kit's on-device Latin text recognition (the model ships in
/// the app; nothing is downloaded). See [mlKitNotice] for what it sends.
class MlKitOcr implements OcrEngine {
  @override
  String get name => 'ML Kit';

  @override
  Future<String> read(Uint8List image) async {
    final dir = await Directory.systemTemp.createTemp('udyoga-ocr-');
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final file = File('${dir.path}${Platform.pathSeparator}page.png');
      await file.writeAsBytes(image);
      return (await recognizer.processImage(InputImage.fromFilePath(file.path))).text;
    } finally {
      await recognizer.close();
      await dir.delete(recursive: true).catchError((_) => dir);
    }
  }
}

extension RecipeFolder on WidgetRef {
  Future<void> setRecipesFolder(String path) async {
    await read(sessionProvider).db.setLocalSetting(recipesFolderKey, path.trim());
    changed();
  }
}
