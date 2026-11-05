import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/ui/apply_helper_page.dart';

void main() {
  test('only http(s) links with a host can be opened', () {
    expect(applyUrl(' https://jobs.example.com/apply/1 '), isNotNull);
    expect(applyUrl('http://example.com'), isNotNull);
    expect(applyUrl('javascript:alert(1)'), isNull);
    expect(applyUrl('file:///etc/passwd'), isNull);
    expect(applyUrl('example.com'), isNull);
    expect(applyUrl(''), isNull);
  });

  testWidgets('the field is pre-filled with the letter and switches to the CV', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApplyHelperPage(url: 'https://jobs.example.com/1', coverLetter: 'Dear team', cv: 'My CV text'),
      ),
    );
    expect(find.text('https://jobs.example.com/1'), findsOneWidget);
    expect(find.text('Dear team'), findsOneWidget);
    await tester.tap(find.text('CV'));
    await tester.pump();
    expect(find.text('My CV text'), findsOneWidget);
    expect(find.text('Dear team'), findsNothing);
  });

  testWidgets('without a cover letter it starts on the CV', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApplyHelperPage(url: '', coverLetter: '', cv: 'My CV text'),
      ),
    );
    expect(find.text('My CV text'), findsOneWidget);
    expect(find.text('Cover letter'), findsNothing);
  });
}
