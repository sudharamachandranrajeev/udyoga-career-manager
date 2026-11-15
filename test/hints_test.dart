import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/hints.dart';

void main() {
  test('every card hint names a hint that exists', () {
    // A card's hint is an id; text put there by mistake shows nothing.
    final known = {...coreHints.keys, ...udyogaHints.keys};
    final used = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in RegExp(r"SectionCard\([^;]*?hint: '([^']*)'", dotAll: true).allMatches(src)) {
        used.add(m[1]!);
      }
    }
    expect(used, isNotEmpty);
    expect(used.difference(known), isEmpty);
  });
}
