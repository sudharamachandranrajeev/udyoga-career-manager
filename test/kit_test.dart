import 'package:brahma_core/brahma_core.dart' show Status;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/kit/kit.dart';
import 'package:udyoga/ui/look.dart';

/// The kit's widgets: numbers roll to the right value, reduced motion turns
/// every animation off, the palette filters and opens, chips say the right
/// thing. No goldens: behaviour only.
Widget _app(Widget child, {bool reduced = false, Brightness brightness = Brightness.light}) => MaterialApp(
  theme: udyogaTheme(brightness),
  builder: (context, child) => ShadBridge(
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: child!,
    ),
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('RollingNumber', () {
    test('formats with grouping, prefix, suffix and sign', () {
      expect(RollingNumber.format(1234), '1,234');
      expect(RollingNumber.format(1250, prefix: '£', showSign: true), '+£1,250');
      expect(RollingNumber.format(-1250, prefix: '£'), '−£1,250');
      expect(RollingNumber.format(0, showSign: true), '0');
      expect(RollingNumber.format(12.5, fractionDigits: 1, suffix: '%'), '12.5%');
    });

    testWidgets('rolls and lands on the final value', (tester) async {
      await tester.pumpWidget(_app(const RollingNumber(5)));
      expect(find.text('5'), findsOneWidget);
      await tester.pumpWidget(_app(const RollingNumber(1234)));
      await tester.pump(const Duration(milliseconds: 60));
      // Mid-roll the digits are wheels, read out as the final value.
      expect(find.text('1,234'), findsNothing);
      expect(find.bySemanticsLabel('1,234'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1,234'), findsOneWidget);
      // And back down past a wrap (1,234 to 999).
      await tester.pumpWidget(_app(const RollingNumber(999)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('shows the new value at once under reduced motion', (tester) async {
      await tester.pumpWidget(_app(const RollingNumber(3), reduced: true));
      await tester.pumpWidget(_app(const RollingNumber(42, prefix: '£'), reduced: true));
      // No time has passed, and it already reads the new value.
      expect(find.text('£42'), findsOneWidget);
    });
  });

  testWidgets('reduced motion stops every kit animation', (tester) async {
    Widget kit() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BorderBeam(child: SizedBox(width: 200, height: 60)),
        const BlurFadeIn(index: 3, child: Text('Arrives')),
        const SizedBox(width: 200, child: ShimmerSkeleton()),
        PillNav<int>(
          items: const [PillNavItem(0, 'One'), PillNavItem(1, 'Two')],
          selected: 0,
          onChanged: (_) {},
        ),
      ],
    );
    await tester.pumpWidget(_app(kit(), reduced: true));
    // On the very first frame the item is fully in place, not fading in.
    expect(find.text('Arrives'), findsOneWidget);
    expect(find.ancestor(of: find.text('Arrives'), matching: find.byType(Opacity)), findsNothing);
    expect(find.ancestor(of: find.text('Arrives'), matching: find.byType(ImageFiltered)), findsNothing);
    // Once the first frame's own settling is over nothing moves: the beam
    // and the shimmer, which loop forever, stand still.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    // The same widgets with motion on do animate.
    await tester.pumpWidget(_app(kit()));
    expect(find.ancestor(of: find.text('Arrives'), matching: find.byType(Opacity)), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('the pill nav slides only for a pointer, and reports the choice', (tester) async {
    var selected = 'jobs';
    late StateSetter set;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return PillNav<String>(
              items: const [PillNavItem('jobs', 'Jobs'), PillNavItem('applications', 'Applications')],
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            );
          },
        ),
      ),
    );
    AnimatedAlign align() => tester.widget(find.byType(AnimatedAlign));
    await tester.tap(find.text('Applications'));
    await tester.pump();
    expect(selected, 'applications');
    expect(align().duration, Pace.base);
    // A jump from elsewhere (the palette, a link) moves it at once.
    set(() => selected = 'jobs');
    await tester.pump();
    expect(align().duration, Duration.zero);
    expect(tester.getSemantics(find.text('Jobs')), isSemantics(isSelected: true));
  });

  group('command palette', () {
    final opened = <String>[];
    final entries = [
      for (final (id, label) in [
        ('today', 'Today'),
        ('jobs', 'Jobs'),
        ('applications', 'Applications'),
        ('career', 'Career'),
        ('settings', 'Settings'),
      ])
        PaletteEntry(id: id, label: label, icon: Icons.circle, onSelect: () => opened.add(id)),
      PaletteEntry(
        id: 'profile',
        label: 'Profile',
        icon: Icons.badge,
        keywords: const ['CV'],
        onSelect: () => opened.add('profile'),
      ),
    ];

    test('fuzzy matching ranks word starts and runs of letters first', () {
      expect(fuzzyScore('xyz', 'Applications'), isNull);
      expect(fuzzyScore('apl', 'Applications'), isNotNull);
      expect(filterEntries('app', entries).first.id, 'applications');
      expect(filterEntries('set', entries).first.id, 'settings');
      expect(filterEntries('cv', entries).single.id, 'profile');
      expect(filterEntries('', entries).map((e) => e.id), entries.map((e) => e.id));
    });

    testWidgets('Ctrl+K opens it at once; typing filters; arrows and Enter choose', (tester) async {
      opened.clear();
      await tester.pumpWidget(_app(CommandPaletteScope(entries: (_) => entries, child: const Text('Home'))));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      // No opening animation: it is all there on the next frame.
      expect(find.byType(CommandPalette), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Career'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump();
      final shown = tester.widgetList<Text>(
        find.descendant(of: find.byType(ListView), matching: find.byType(Text)),
      );
      expect(shown.map((t) => t.data), isNot(contains('Profile')));

      await tester.enterText(find.byType(EditableText), 'ca');
      await tester.pump();
      // Career first, then the arrow moves to the next match.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byType(CommandPalette), findsNothing);
      expect(opened, ['career']);
    });

    testWidgets('a click chooses and Escape closes without choosing', (tester) async {
      opened.clear();
      await tester.pumpWidget(_app(Builder(builder: (context) => const Text('Home'))));
      final context = tester.element(find.text('Home'));
      showCommandPalette(context, entries);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(CommandPalette), findsNothing);
      expect(opened, isEmpty);

      showCommandPalette(context, entries);
      await tester.pump();
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(opened, ['settings']);
    });
  });

  testWidgets('channel chips name the channel and the account', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelChip('email', account: 'asha@example.com'),
            ChannelChip('linkedin'),
            ChannelChip('bluesky', account: '@asha.bsky.social'),
            ChannelChip('phone'),
            ChannelChip('in_person'),
            ChannelChip('carrier pigeon'),
          ],
        ),
        brightness: Brightness.dark,
      ),
    );
    for (final label in [
      'Email · asha@example.com',
      'LinkedIn',
      'Bluesky · @asha.bsky.social',
      'Phone',
      'In person',
      'Other',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(ChannelLook.of('in_person').icon, Icons.handshake_outlined);
  });

  testWidgets('status pills, spotlight cards and dot grids build in both themes', (tester) async {
    for (final b in Brightness.values) {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 320,
            height: 240,
            child: DotGrid(
              child: SpotlightCard(
                child: Column(
                  children: [
                    StatusPill('Shortlisted', status: Status.good),
                    StatusPill('Closes in 3 days', status: Status.warning, icon: Icons.schedule),
                    StatusPill('Draft'),
                  ],
                ),
              ),
            ),
          ),
          brightness: b,
        ),
      );
      expect(find.text('Shortlisted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('toasts and sheets show their content', (tester) async {
    await tester.pumpWidget(_app(Builder(builder: (context) => const Text('Home'))));
    final context = tester.element(find.text('Home'));
    showToast(context, 'Saved the job', status: Status.good);
    // The toast list takes a few frames to insert and build the toast.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Saved the job'), findsOneWidget);
    // It closes by itself.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Saved the job'), findsNothing);

    showSheet<void>(context, builder: (_) => const Text('In a sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('In a sheet'), findsOneWidget);
    Navigator.of(tester.element(find.text('In a sheet'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('In a sheet'), findsNothing);
  });

  group('StatGrid', () {
    test('picks a column count with no lone last tile', () {
      // Six tiles: two across on a phone, three or six on wider screens.
      expect(StatGrid.columnsFor(6, 288, minWidth: 128), 2);
      expect(StatGrid.columnsFor(6, 600), 3);
      expect(StatGrid.columnsFor(6, 1100), 6);
      // Five tiles fit four across but divide only by five or one, so it
      // keeps four and the last tile has the full row.
      expect(StatGrid.columnsFor(5, 700), 4);
      expect(StatGrid.columnsFor(0, 700), 1);
    });

    testWidgets('huge counts and long labels fit a 320-wide phone', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          const Padding(
            padding: EdgeInsets.all(16),
            child: StatGrid(
              minWidth: 128,
              children: [
                StatTile(label: 'Applications sent this year', icon: Icons.send, value: 12345678),
                StatTile(
                  label: 'Follow-ups due',
                  icon: Icons.notifications,
                  value: 99999,
                  caption: 'Chase today',
                  status: Status.warning,
                ),
                StatTile(
                  label: 'Response rate',
                  icon: Icons.mail,
                  value: null,
                  caption: 'No applications sent yet',
                ),
                StatTile(
                  label: 'Pay',
                  icon: Icons.payments,
                  value: 1234567.89,
                  fractionDigits: 2,
                  suffix: '%',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StatTile), findsNWidgets(4));
      expect(find.bySemanticsLabel(RegExp('^Response rate. none yet')), findsOneWidget);
    });
  });
}
