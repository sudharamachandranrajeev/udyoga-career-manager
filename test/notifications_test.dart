import 'package:brahma_core/brahma_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/book.dart';

import 'support.dart';

void main() {
  test('every notification category is off until opted in, and toggles independently', () async {
    final book = CareerBook(await Store.open(memoryDatabase()));
    for (final k in notificationKinds.keys) {
      expect(await book.notifies(k), isFalse, reason: k);
    }
    await book.setNotifies('digest', true);
    expect(await book.notifies('digest'), isTrue);
    expect(await book.notifies('matches'), isFalse);
    expect(await book.notifies('followups'), isFalse);
    await book.setNotifies('digest', false);
    expect(await book.notifies('digest'), isFalse);
  });
}
