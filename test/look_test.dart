import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:udyoga/ui/look.dart';

/// The look's tokens, and the shadcn_ui widgets living inside the Material
/// app: both themes follow light and dark together.
void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('shadcn widgets work inside the Material app ($mode)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: udyogaTheme(Brightness.light),
          darkTheme: udyogaTheme(Brightness.dark),
          themeMode: mode,
          builder: (context, child) => ShadBridge(child: child!),
          home: Scaffold(
            body: Column(
              children: [
                ShadButton(onPressed: () => taps++, child: const Text('Go')),
                const ShadBadge(child: Text('New')),
                const SizedBox(width: 300, child: ShadInput(placeholder: Text('Name'))),
                const ShadCard(title: Text('Card'), child: Text('Body')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(taps, 1);
      await tester.enterText(find.byType(EditableText), 'Asha');
      await tester.pump();
      expect(find.text('Asha'), findsOneWidget);
      final context = tester.element(find.text('Card'));
      final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      expect(ShadTheme.of(context).brightness, brightness);
      expect(ShadTheme.of(context).colorScheme.primary, palette(brightness).primary);
      expect(Theme.of(context).colorScheme.primary, palette(brightness).primary);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('motion lengths drop to zero when the system asks for reduced motion', (tester) async {
    late Duration normal, reduced;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          normal = paced(context, Pace.base);
          return MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = paced(context, Pace.base);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(normal, Pace.base);
    expect(reduced, Duration.zero);
    for (final d in [Pace.fast, Pace.base, Pace.slow]) {
      expect(d.inMilliseconds, inInclusiveRange(150, 250));
    }
  });
}
