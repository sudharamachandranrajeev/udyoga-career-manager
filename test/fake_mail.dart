// A mail server in memory for tests: IMAP folders with messages by UID,
// and SMTP that records what was sent. No network.
import 'package:udyoga/domain/mail.dart';
import 'package:udyoga/domain/mail_transport.dart';

/// The user's own (made-up) address.
const me = 'alex@example.com';

/// One mailbox: its messages by UID, each with an optional Gmail thread id.
class FakeFolder {
  FakeFolder(this.path, {this.inbox = false, this.sent = false});
  final String path;
  final bool inbox, sent;
  var validity = 7;
  final messages = <int, ({String raw, String? thread})>{};
  void add(int uid, String raw, {String? thread}) => messages[uid] = (raw: raw, thread: thread);
}

class FakeImap implements ImapSession {
  FakeImap(this.server);
  final FakeMailServer server;
  FakeFolder? _open;

  @override
  Future<List<MailFolder>> folders() async => [
    for (final f in server.folders) (path: f.path, inbox: f.inbox, sent: f.sent),
  ];

  @override
  Future<int> open(String path) async {
    _open = server.folders.firstWhere((f) => f.path == path);
    return _open!.validity;
  }

  @override
  Future<List<int>> uidsSince(DateTime day) async {
    server.searches.add('since');
    return _open!.messages.keys.toList()..sort();
  }

  @override
  Future<List<int>> uidsAbove(int uid) async {
    server.searches.add('above $uid');
    return _open!.messages.keys.where((u) => u > uid).toList()..sort();
  }

  @override
  Future<List<FetchedMail>> fetch(List<int> uids, {bool headers = false}) async => [
    for (final u in uids)
      if (_open!.messages[u] case final m?)
        () {
          if (!headers) server.fullyRead.add(u);
          return FetchedMail(u, headers ? m.raw.split('\r\n\r\n').first : m.raw, gmailThreadId: m.thread);
        }(),
  ];

  @override
  Future<void> close() async {}
}

/// IMAP and SMTP in memory: what was read in full, what was sent.
class FakeMailServer implements MailTransport {
  final inbox = FakeFolder('INBOX', inbox: true);
  final sentFolder = FakeFolder('[Gmail]/Sent Mail', sent: true);
  late final folders = [inbox, sentFolder, FakeFolder('[Gmail]/Spam')];
  final fullyRead = <int>[];
  final searches = <String>[];
  final sent = <({String raw, List<String> to})>[];
  var password = 'abcdabcdabcdabcd';
  var refuseSend = false;

  void _check(ChannelAccount a, String pw) {
    if (pw != password) throw signInFailed(a, 'The mail server (IMAP)');
  }

  @override
  Future<ImapSession> imap(ChannelAccount a, String pw) async {
    _check(a, pw);
    return FakeImap(this);
  }

  @override
  Future<void> checkSmtp(ChannelAccount a, String pw) async => _check(a, pw);

  @override
  Future<void> send(
    ChannelAccount a,
    String pw, {
    required String raw,
    required String from,
    required List<String> to,
  }) async {
    _check(a, pw);
    if (refuseSend) throw const MailException('The message was not sent: the server refused it.');
    sent.add((raw: raw, to: to));
  }
}
