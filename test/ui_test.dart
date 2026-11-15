import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brahma_core/brahma_core.dart' show AppShell;
import 'package:udyoga/app/modules.dart';
import 'package:udyoga/app/navigation.dart';
import 'package:udyoga/app/settings_page.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/pipeline.dart';
import 'package:udyoga/ui/applications_page.dart';
import 'package:udyoga/ui/coach_page.dart';
import 'package:udyoga/ui/growth_page.dart';
import 'package:udyoga/ui/interview_page.dart';
import 'package:udyoga/ui/kit/kit.dart';
import 'package:udyoga/ui/linkedin_page.dart';
import 'package:udyoga/ui/today_hero.dart';
import 'package:udyoga/ui/today_page.dart';

import 'app_harness.dart';
import 'seed.dart';

/// Smoke tests: every page builds, with and without data, on phone and
/// desktop widths, without throwing or overflowing; and the main flows.
void main() {
  // Every page, including those inside a grouped navigation entry.
  final pages = [for (final d in allPages) d.label];

  testWidgets('every page builds on a desktop window, empty and with data', (tester) async {
    for (final seeded in [false, true]) {
      final app = AppHarness(tester)..desktop();
      await app.open(seed: seeded ? seedBook : null);
      await app.run();
      for (final label in pages) {
        await app.go(label);
        expect(tester.takeException(), isNull, reason: '$label (seeded: $seeded)');
      }
      await app.close();
    }
  });

  testWidgets('the application board moves a card by drag and by its menu', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('Applications');
    expect(find.byType(ApplicationBoard), findsOneWidget);

    Future<String> stageOf(String title) => tester
        .runAsync(() async => (await app.book.db.select(app.book.db.jobApplications).get()))
        .then((all) => all!.singleWhere((a) => a.title == title).stage);

    final card = find.text('Digital Nurse Specialist');
    final screening = find.ancestor(
      of: find.text('Screening'),
      matching: find.byType(DragTarget<JobApplication>),
    );
    final drag = await tester.startGesture(tester.getCenter(card));
    await tester.pump(kLongPressTimeout);
    await drag.moveTo(tester.getCenter(screening));
    await tester.pump();
    await drag.up();
    await app.settle();
    expect(await stageOf('Digital Nurse Specialist'), Stage.screening.id);

    await app.tap(
      find.descendant(
        of: find.ancestor(of: find.text('EPR Trainer'), matching: find.byType(Card)),
        matching: find.byTooltip('Move to'),
      ),
    );
    await app.tapText('Move to Rejected');
    expect(await stageOf('EPR Trainer'), Stage.rejected.id);
    expect(find.text('EPR Trainer'), findsNothing);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('every page builds on a phone, with the detail pages', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: seedBook);
    await app.run();
    for (final label in pages) {
      await app.go(label);
      expect(tester.takeException(), isNull, reason: label);
    }
    await app.go('Jobs');
    await app.tap(find.widgetWithText(ChoiceChip, 'Applied'));
    await app.tapText('EPR Trainer');
    expect(find.text('The advert'), findsOneWidget);
    expect(find.text('Pay change'), findsOneWidget);
    expect(find.textContaining('+£6,951 a year'), findsOneWidget);
    expect(find.text('Working at Northwind Health'), findsOneWidget);
    expect(find.textContaining('A merger is planned'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await app.settle();

    await app.go('Applications');
    await app.tapText('Digital Nurse Specialist');
    expect(find.text('Timeline'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await app.settle();

    await app.go('Interview');
    await app.tapText('Clinical Informatics Nurse');
    expect(find.text('Tell us about a change you led.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('Today shows due follow-ups, the interview and closing jobs', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    expect(find.text('Follow up today'), findsOneWidget);
    expect(find.text('Upcoming interviews'), findsOneWidget);
    expect(find.text('Closing this week'), findsOneWidget);
    // The hero strip: six counts, rolled to their values, laid out with no
    // lone tile, and the next deadline (a saved job closing this week) with
    // the beam round it.
    for (final label in [
      'Applied',
      'Interviews',
      'Follow-ups due',
      'In progress',
      'New matches',
      'Response rate',
      'Next deadline',
    ]) {
      expect(find.descendant(of: find.byType(TodayHero), matching: find.text(label)), findsOneWidget);
    }
    final counts = tester.widgetList<RollingNumber>(find.byType(RollingNumber)).toList();
    expect(counts, hasLength(6));
    for (final n in counts) {
      final shown = RollingNumber.format(n.value, suffix: n.suffix);
      expect(find.descendant(of: find.byWidget(n), matching: find.text(shown)), findsOneWidget);
    }
    expect(counts[2].value, greaterThan(0), reason: 'the seed has follow-ups due');
    expect(counts.last.suffix, '%', reason: 'the response rate');
    expect(find.ancestor(of: find.text('Next deadline'), matching: find.byType(BorderBeam)), findsOneWidget);
    // The seed's due items sit under "Needs you", each group arriving in turn.
    expect(find.text('Needs you'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Follow up today'), matching: find.byType(BlurFadeIn)),
      findsOneWidget,
    );
    expect(find.text('Nothing needs you today.'), findsNothing);
    await app.close();
  });

  testWidgets('Today with no data has zero counts and no deadline beam', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open();
    await app.run();
    expect(find.descendant(of: find.byType(TodayHero), matching: find.text('Applied')), findsOneWidget);
    // Five zero counts, and a dash for the response rate: nothing was sent.
    expect(find.descendant(of: find.byType(TodayHero), matching: find.text('0')), findsNWidgets(5));
    expect(find.descendant(of: find.byType(TodayHero), matching: find.text('–')), findsOneWidget);
    expect(find.text('Next deadline'), findsNothing);
    // Nothing is due, and it says so with one next step.
    expect(find.text('Nothing needs you today.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Open Jobs'), findsOneWidget);
    expect(find.byType(BorderBeam), findsNothing);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('a job moves to an application from its page', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('Jobs');
    await app.tap(find.widgetWithText(ChoiceChip, 'Saved'));
    await app.tapText('Clinical Informatics Nurse');
    await app.tapText('Apply for this job');
    expect(tester.takeException(), isNull);
    // The dialog asks whether it was sent; either answer opens an application.
    final sent = find.textContaining('sent', findRichText: true);
    expect(sent, findsWidgets);
    await app.close();
  });

  testWidgets('the LinkedIn human check cleans a draft on the device', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('LinkedIn');
    expect(find.text('Your voice'), findsOneWidget);
    expect(find.textContaining('You post and send everything yourself'), findsWidgets);
    await app.tapText('Human check');
    await app.enter('Draft', 'We leverage it \u2014 daily.');
    await app.tapText('Check');
    await app.settle();
    expect(find.text('Cleaned text'), findsOneWidget);
    expect(find.textContaining('\u2014'), findsNothing);
    expect(tester.takeException(), isNull);
    await app.close();
  });

  testWidgets('the Coach shows the questions, stories and documents; Settings the check-in time', (
    tester,
  ) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('Coach');
    for (final text in ['When did you start?', 'E-observations pilot', 'cv.txt']) {
      expect(find.textContaining(text), findsWidgets, reason: text);
    }
    await app.go('Settings');
    expect(find.text('Daily check-in'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
    await app.close();
  });

  testWidgets('the side rail scrolls by touchpad on a short window', (tester) async {
    final app = AppHarness(tester);
    tester.view.physicalSize = const Size(1000, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await app.open();
    await app.run();
    // Five entries do not fit 360 pixels: the rail must scroll, not overflow.
    expect(tester.takeException(), isNull);
    final rail = find.byType(NavigationRail);
    final last = find.descendant(of: rail, matching: find.text(allDestinations.last.label));
    expect(tester.getRect(last).top, greaterThan(360));
    final pad = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    await pad.panZoomStart(tester.getCenter(rail));
    await pad.panZoomUpdate(tester.getCenter(rail), pan: const Offset(0, -800));
    await pad.panZoomEnd();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getRect(last).bottom, lessThanOrEqualTo(360));
    await app.close();
  });

  test('eleven pages sit under five entries, each keeping its old id', () {
    expect(allDestinations.map((d) => d.id), ['today', 'jobs', 'network', 'prepare', 'you']);
    expect(allPages.map((p) => p.id), [
      'today',
      'jobs',
      'applications',
      'contacts',
      'linkedin',
      'interview',
      'coach',
      'growth',
      'profile',
      'career',
      'settings',
    ]);
    expect(groupOf('applications')?.id, 'jobs');
    expect(groupOf('settings')?.id, 'you');
    expect(groupOf('today'), isNull);
  });

  for (final phone in [false, true]) {
    testWidgets('a page opened by its id lands on its tab (${phone ? 'phone' : 'desktop'})', (tester) async {
      final app = AppHarness(tester);
      phone ? app.phone() : app.desktop();
      await app.open(seed: seedBook);
      await app.run();
      final ref = tester.element(find.byType(AppShell)) as WidgetRef;
      for (final (id, page) in [
        ('applications', ApplicationsPage),
        ('growth', GrowthPage),
        ('settings', SettingsPage),
        ('linkedin', LinkedInPage),
        ('coach', CoachPage),
        ('today', TodayPage),
      ]) {
        expect(goToPage(ref, id), isTrue, reason: id);
        await app.settle();
        // Only the page on show is onstage; the others wait offstage.
        expect(find.byType(page), findsOneWidget, reason: id);
        expect(tester.takeException(), isNull, reason: id);
      }
      expect(goToPage(ref, 'nowhere'), isFalse);
      await app.close();
    });
  }

  testWidgets('Ctrl+K opens the palette, which jumps to a page inside a group', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.byType(CommandPalette), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(CommandPalette), matching: find.byType(EditableText)),
      'grow',
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await app.settle();
    expect(find.byType(CommandPalette), findsNothing);
    expect(find.byType(GrowthPage), findsOneWidget);
    expect(find.byType(TodayPage), findsNothing);
    await app.close();
  });

  testWidgets('on a phone the search button opens the palette, whose help answers open grouped pages', (
    tester,
  ) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: seedBook);
    await app.run();
    await app.tap(find.byTooltip('Search pages, actions and help (Ctrl+K)'));
    expect(find.byType(CommandPalette), findsOneWidget);
    // A question no page name answers: the help knows it is about Interview,
    // which lives inside Prepare.
    await tester.enterText(
      find.descendant(of: find.byType(CommandPalette), matching: find.byType(EditableText)),
      'speaking time fillers',
    );
    await tester.pump();
    final answer = find.text('Help · Interview');
    expect(answer, findsWidgets);
    await app.tap(answer.first);
    expect(find.byType(CommandPalette), findsNothing);
    expect(find.byType(InterviewPage), findsOneWidget);
    expect(find.byType(TodayPage), findsNothing);
    // Every grouped page has the button too, beside its switch.
    expect(find.descendant(of: find.byType(GroupPage), matching: find.byType(PaletteButton)), findsOneWidget);
    await app.close();
  });
}
