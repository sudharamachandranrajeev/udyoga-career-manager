// Connected accounts, reached from Conversations: connecting Gmail with an
// app password (a wrong one says what Gmail needs), the password kept in the
// keychain, and Send in the composer once an account is connected. A fake
// mail server stands in; every address is made up.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/app/providers.dart';
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/mail.dart';
import 'package:udyoga/domain/mail_sync.dart';
import 'package:udyoga/ui/accounts_page.dart';

import 'app_harness.dart';
import 'fake_mail.dart';

Future<void> _seed(CareerBook book) async {
  const id = 'jordan';
  await book.save(
    book.db.careerContacts,
    CareerContactsCompanion.insert(
      id: id,
      name: 'Jordan Example',
      email: const Value('jordan@example.org'),
      company: const Value('Example Trust'),
    ),
    id,
  );
  await book.startConversation(
    contactId: id,
    channel: 'email',
    subject: 'Digital lead role',
    at: '2026-11-12T09:00',
  );
}

void main() {
  testWidgets('connect Gmail with an app password, then send from the composer', (tester) async {
    final server = FakeMailServer();
    final app = AppHarness(tester)..desktop();
    await app.open(seed: _seed);
    await app.run(overrides: [mailTransportProvider.overrideWithValue(server)]);
    await app.go('Conversations');

    // No account: the composer copies and opens the mail app.
    await app.tapText('Jordan Example');
    expect(find.text('Copy & open mail'), findsOneWidget);

    await app.tap(find.byTooltip('Connected accounts'));
    expect(find.byType(AccountsPage), findsOneWidget);
    expect(find.textContaining('No account yet'), findsOneWidget);

    await app.tapText('Connect');
    expect(find.textContaining('2-Step Verification'), findsOneWidget);
    expect(find.text('Make an app password'), findsOneWidget);
    await app.enter('E-mail address', me);
    await app.enter('Your name on sent mail', 'Alex Example');
    await app.enter('App password', 'not-the-app-password');
    await app.tapText('Test and connect');
    // The sign-in failed: the dialog stays and says what Gmail needs.
    expect(find.textContaining('would not sign in $me'), findsOneWidget);

    await app.enter('App password', 'abcd abcd abcd abcd');
    await app.tapText('Test and connect');
    expect(find.text(me), findsOneWidget);
    expect(find.textContaining('Alert me when a saved contact writes'), findsOneWidget);

    final keychain = app.session.keys.store;
    await tester.runAsync(() async {
      final a = ChannelAccount.preset('gmail', me);
      expect(await keychain.read(a.secretKey), 'abcdabcdabcdabcd');
      expect(await app.session.db.localSetting(mailAccountsKey), isNot(contains('abcd')));
    });

    // Back in the thread, Send goes through the account.
    await app.tap(find.byTooltip('Back'));
    expect(find.text('Copy & open mail'), findsNothing);
    await app.enter('Message', 'Hello Jordan, is Thursday good?');
    await app.tapText('Send from $me');
    expect(server.sent, hasLength(1));
    expect(server.sent.single.raw, contains('Subject: Digital lead role'));
    await tester.runAsync(() async {
      final t = (await app.book.conversationsOf('jordan')).single;
      final m = (await app.book.messagesIn(t.id)).single;
      expect((m.status, m.source), ('sent', 'api'));
    });
    expect(find.textContaining('Sent from Udyoga'), findsOneWidget);
    await app.close();
  });
}
