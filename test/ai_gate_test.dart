import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/common.dart';

void main() {
  testWidgets('AI text shows its basis and is copied only after the user taps Use this, as edited', (
    tester,
  ) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(
          builder: (context) => TextButton(
            onPressed: () => reviewAiText(
              context,
              title: 'Draft',
              subject: 'Hello',
              text: 'AI wrote this',
              basis: 'Job: Nurse at NHS',
            ),
            child: const Text('open'),
          ),
        )),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Written by the AI from: Job: Nurse at NHS'), findsOneWidget);
    expect(clipboard, isNull, reason: 'nothing is copied just by showing the draft');

    await tester.enterText(find.widgetWithText(TextField, 'Text'), 'My edited text');
    expect(clipboard, isNull, reason: 'editing is not using');

    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();
    expect(clipboard, 'Subject: Hello\n\nMy edited text');
    expect(find.text('Use this'), findsNothing);
  });

  testWidgets('Discard closes without copying', (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(
          builder: (context) => TextButton(
            onPressed: () => reviewAiText(context, title: 'Draft', text: 'x', basis: 'b'),
            child: const Text('open'),
          ),
        )),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(clipboard, isNull);
    expect(find.text('Use this'), findsNothing);
  });
}
