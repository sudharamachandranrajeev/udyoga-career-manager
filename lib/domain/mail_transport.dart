import 'dart:async';
import 'dart:io' show SocketException, HandshakeException;

// enough_mail is MPL-2.0: used as published, none of its files changed.
import 'package:enough_mail/enough_mail.dart' hide MailException;

import 'mail.dart';

// The network side of e-mail, behind small interfaces so the sync and send
// logic can be tested without a server. The real one speaks IMAP and SMTP
// through enough_mail.

/// One fetched message: its UID, the raw text (headers only, or the whole
/// message) and Gmail's thread id when the server gives one.
class FetchedMail {
  const FetchedMail(this.uid, this.raw, {this.gmailThreadId});
  final int uid;
  final String raw;
  final String? gmailThreadId;
}

/// A mailbox on the server. [sent] comes from SPECIAL-USE (\Sent).
typedef MailFolder = ({String path, bool inbox, bool sent});

/// An open, signed-in IMAP connection.
abstract interface class ImapSession {
  Future<List<MailFolder>> folders();

  /// Selects [path] read-only; returns its UIDVALIDITY.
  Future<int> open(String path);

  /// UIDs of messages since [day] (first sync), or above [uid] (later ones).
  Future<List<int>> uidsSince(DateTime day);
  Future<List<int>> uidsAbove(int uid);

  /// Messages by UID: [headers] only, or whole.
  Future<List<FetchedMail>> fetch(List<int> uids, {bool headers = false});
  Future<void> close();
}

/// IMAP for reading, SMTP for sending.
abstract interface class MailTransport {
  Future<ImapSession> imap(ChannelAccount a, String password);

  /// Signs in to SMTP and out again.
  Future<void> checkSmtp(ChannelAccount a, String password);

  /// Sends [raw] from [from] to [to].
  Future<void> send(
    ChannelAccount a,
    String password, {
    required String raw,
    required String from,
    required List<String> to,
  });
}

/// [MailTransport] over the network, with enough_mail.
class EnoughMailTransport implements MailTransport {
  const EnoughMailTransport();

  static const _timeout = Duration(seconds: 30);

  @override
  Future<ImapSession> imap(ChannelAccount a, String password) async {
    final client = ImapClient(defaultResponseTimeout: _timeout);
    try {
      await client.connectToServer(a.imapHost, a.imapPort, isSecure: a.imapTls);
      if (!a.imapTls) await client.startTls();
      await client.login(a.address, password);
    } on ImapException catch (_) {
      await client.disconnect().catchError((_) {});
      throw signInFailed(a, 'The mail server (IMAP)');
    } catch (e) {
      await client.disconnect().catchError((_) {});
      throw _network(e, a.imapHost);
    }
    return _EnoughImap(client);
  }

  Future<SmtpClient> _smtp(ChannelAccount a, String password) async {
    final domain = a.address.split('@').last;
    final client = SmtpClient(domain);
    try {
      await client.connectToServer(a.smtpHost, a.smtpPort, isSecure: a.smtpTls);
      await client.ehlo();
      if (!a.smtpTls) {
        await client.startTls();
        await client.ehlo();
      }
      await client.authenticate(a.address, password, AuthMechanism.plain);
      return client;
    } on SmtpException catch (_) {
      await client.disconnect().catchError((_) {});
      throw signInFailed(a, 'The sending server (SMTP)');
    } catch (e) {
      await client.disconnect().catchError((_) {});
      throw _network(e, a.smtpHost);
    }
  }

  @override
  Future<void> checkSmtp(ChannelAccount a, String password) async {
    final client = await _smtp(a, password);
    await client.quit().catchError((_) => SmtpResponse(const []));
  }

  @override
  Future<void> send(
    ChannelAccount a,
    String password, {
    required String raw,
    required String from,
    required List<String> to,
  }) async {
    final client = await _smtp(a, password);
    try {
      await client.sendMessageText(raw, MailAddress(null, from), [for (final t in to) MailAddress(null, t)]);
    } on SmtpException catch (e) {
      throw MailException('The message was not sent: ${e.message ?? 'the server refused it'}.');
    } finally {
      await client.quit().catchError((_) => SmtpResponse(const []));
    }
  }

  MailException _network(Object e, String host) => switch (e) {
    SocketException() ||
    TimeoutException() => MailException('Could not reach $host. Check the connection and the server name.'),
    HandshakeException() => MailException('$host did not offer a secure connection on that port.'),
    _ => MailException('$host: $e'),
  };
}

class _EnoughImap implements ImapSession {
  _EnoughImap(this.client);
  final ImapClient client;

  bool get _gmail => client.serverInfo.supports('X-GM-EXT-1');

  @override
  Future<List<MailFolder>> folders() async => [
    for (final m in await client.listMailboxes(recursive: true))
      if (!m.isNotSelectable)
        (path: m.path, inbox: m.isInbox || m.path.toUpperCase() == 'INBOX', sent: m.isSent),
  ];

  @override
  Future<int> open(String path) async =>
      (await client.examineMailbox(
        (await client.listMailboxes(path: path))
            .firstWhere((m) => m.path == path, orElse: () => throw MailException('No folder $path.')),
      )).uidValidity ??
      0;

  List<int> _ids(SearchImapResult r) => r.matchingSequence?.toList() ?? const [];

  @override
  Future<List<int>> uidsSince(DateTime day) async {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return _ids(
      await client.uidSearchMessages(searchCriteria: 'SINCE ${day.day}-${months[day.month - 1]}-${day.year}'),
    );
  }

  @override
  Future<List<int>> uidsAbove(int uid) async => [
    for (final u in _ids(await client.uidSearchMessages(searchCriteria: 'UID ${uid + 1}:*')))
      if (u > uid) u,
  ];

  @override
  Future<List<FetchedMail>> fetch(List<int> uids, {bool headers = false}) async {
    if (uids.isEmpty) return const [];
    final what = [
      'UID',
      if (_gmail) 'X-GM-THRID',
      headers
          ? 'BODY.PEEK[HEADER.FIELDS (MESSAGE-ID IN-REPLY-TO REFERENCES FROM TO CC SUBJECT DATE)]'
          : 'BODY.PEEK[]',
    ];
    final r = await client.uidFetchMessages(
      MessageSequence.fromIds(uids, isUid: true),
      '(${what.join(' ')})',
    );
    return [
      for (final m in r.messages)
        if (m.uid != null) FetchedMail(m.uid!, m.renderMessage(), gmailThreadId: m.xGmThrid?.toString()),
    ];
  }

  @override
  Future<void> close() async {
    await client.logout().catchError((_) => null);
    await client.disconnect().catchError((_) {});
  }
}
