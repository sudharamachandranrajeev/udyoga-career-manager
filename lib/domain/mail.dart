import 'dart:convert';
import 'dart:math';

import 'package:brahma_core/brahma_core.dart' show UserFacingError;
// enough_mail is MPL-2.0: used as published, none of its files changed.
import 'package:enough_mail/enough_mail.dart' show MimeMessage;

// E-mail accounts the user connects with an app password, and the pieces
// that turn mail into conversations: reading a message (headers, a plain
// text body without the quoted reply below it) and writing one with the
// headers that keep it in its thread. Nothing here touches the network;
// mail_transport.dart does.

/// A mail provider's servers and where its app passwords are made.
class MailPreset {
  const MailPreset(
    this.id,
    this.name, {
    this.imapHost = '',
    this.imapPort = 993,
    this.smtpHost = '',
    this.smtpPort = 465,
    this.passwordHelp = '',
    this.passwordUrl = '',
  });
  final String id, name, imapHost, smtpHost, passwordHelp, passwordUrl;
  final int imapPort, smtpPort;
}

/// Outlook.com needs OAuth (Microsoft dropped app passwords in 2024); it
/// shows as "coming soon" until that is built.
const outlookReady = false;

const mailPresets = {
  'gmail': MailPreset(
    'gmail',
    'Gmail',
    imapHost: 'imap.gmail.com',
    smtpHost: 'smtp.gmail.com',
    passwordHelp:
        'Gmail needs 2-Step Verification turned on, then an app password (16 letters) made for Udyoga. '
        'Your normal Google password will not work.',
    passwordUrl: 'https://myaccount.google.com/apppasswords',
  ),
  'icloud': MailPreset(
    'icloud',
    'iCloud Mail',
    imapHost: 'imap.mail.me.com',
    smtpHost: 'smtp.mail.me.com',
    smtpPort: 587,
    passwordHelp: 'iCloud needs an app-specific password, made in your Apple Account settings.',
    passwordUrl: 'https://support.apple.com/en-us/102654',
  ),
  'yahoo': MailPreset(
    'yahoo',
    'Yahoo Mail',
    imapHost: 'imap.mail.yahoo.com',
    smtpHost: 'smtp.mail.yahoo.com',
    passwordHelp: 'Yahoo needs an app password, made in Account security.',
    passwordUrl: 'https://help.yahoo.com/kb/SLN15241.html',
  ),
  'fastmail': MailPreset(
    'fastmail',
    'Fastmail',
    imapHost: 'imap.fastmail.com',
    smtpHost: 'smtp.fastmail.com',
    passwordHelp: 'Fastmail needs an app password with IMAP and SMTP access.',
    passwordUrl: 'https://www.fastmail.help/hc/en-us/articles/360058752854-App-passwords',
  ),
  'outlook': MailPreset('outlook', 'Outlook.com (coming soon)'),
  'other': MailPreset(
    'other',
    'Other (IMAP and SMTP)',
    passwordHelp: 'Use an app password if your provider offers one.',
  ),
};

/// A connected e-mail account. Kept on this device only (local settings);
/// its password is in the system keychain under [secretKey].
class ChannelAccount {
  const ChannelAccount({
    required this.provider,
    required this.address,
    this.name = '',
    required this.imapHost,
    this.imapPort = 993,
    this.imapTls = true,
    required this.smtpHost,
    this.smtpPort = 465,
    this.notify = true,
    this.lastSync,
    this.folders = const {},
  });

  /// One of [mailPresets].
  final String provider;
  final String address;

  /// The name mail goes out under.
  final String name;
  final String imapHost, smtpHost;
  final int imapPort, smtpPort;

  /// TLS from the start on IMAP (993); false for STARTTLS (143).
  final bool imapTls;

  /// Alert on this device when a saved contact writes.
  final bool notify;

  /// When the last sync finished (UTC ISO 8601).
  final String? lastSync;

  /// Where each folder's sync got to: its UIDVALIDITY and the highest UID
  /// read.
  final Map<String, ({int validity, int uid})> folders;

  String get channel => 'email';
  String get secretKey => 'udyoga.mail.${address.toLowerCase()}.password';

  /// SMTP on 465 is TLS from the start; 587 and 25 upgrade with STARTTLS.
  bool get smtpTls => smtpPort == 465;

  factory ChannelAccount.preset(String provider, String address, {String name = ''}) {
    final p = mailPresets[provider] ?? mailPresets['other']!;
    return ChannelAccount(
      provider: p.id,
      address: address.trim(),
      name: name.trim(),
      imapHost: p.imapHost,
      imapPort: p.imapPort,
      smtpHost: p.smtpHost,
      smtpPort: p.smtpPort,
    );
  }

  factory ChannelAccount.fromJson(Map<String, Object?> j) => ChannelAccount(
    provider: '${j['provider'] ?? 'other'}',
    address: '${j['address'] ?? ''}',
    name: '${j['name'] ?? ''}',
    imapHost: '${j['imapHost'] ?? ''}',
    imapPort: (j['imapPort'] as num?)?.toInt() ?? 993,
    imapTls: j['imapTls'] != false,
    smtpHost: '${j['smtpHost'] ?? ''}',
    smtpPort: (j['smtpPort'] as num?)?.toInt() ?? 465,
    notify: j['notify'] != false,
    lastSync: j['lastSync'] as String?,
    folders: {
      for (final e in ((j['folders'] as Map?) ?? const {}).entries)
        if (e.value case {'validity': final num v, 'uid': final num u})
          '${e.key}': (validity: v.toInt(), uid: u.toInt()),
    },
  );

  Map<String, Object?> toJson() => {
    'provider': provider,
    'address': address,
    'name': name,
    'imapHost': imapHost,
    'imapPort': imapPort,
    'imapTls': imapTls,
    'smtpHost': smtpHost,
    'smtpPort': smtpPort,
    'notify': notify,
    'lastSync': lastSync,
    'folders': {
      for (final e in folders.entries) e.key: {'validity': e.value.validity, 'uid': e.value.uid},
    },
  };

  ChannelAccount copyWith({
    String? name,
    bool? notify,
    String? lastSync,
    Map<String, ({int validity, int uid})>? folders,
  }) => ChannelAccount(
    provider: provider,
    address: address,
    name: name ?? this.name,
    imapHost: imapHost,
    imapPort: imapPort,
    imapTls: imapTls,
    smtpHost: smtpHost,
    smtpPort: smtpPort,
    notify: notify ?? this.notify,
    lastSync: lastSync ?? this.lastSync,
    folders: folders ?? this.folders,
  );

  /// What is wrong with the settings, or null.
  String? get problem {
    if (provider == 'outlook' && !outlookReady) {
      return 'Outlook.com is coming soon: it needs a Microsoft sign-in.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) return 'Enter the full e-mail address.';
    if (imapHost.isEmpty || smtpHost.isEmpty) return 'Enter the IMAP and SMTP servers.';
    return null;
  }
}

/// Something went wrong talking to a mail server, said plainly.
class MailException implements Exception, UserFacingError {
  const MailException(this.message, {this.helpUrl = ''});
  @override
  final String message;

  /// A page that helps fix it (making an app password).
  final String helpUrl;

  @override
  String toString() => message;
}

/// A failed sign-in, with what this provider needs.
MailException signInFailed(ChannelAccount a, String server) {
  final p = mailPresets[a.provider] ?? mailPresets['other']!;
  return MailException(
    '$server would not sign in ${a.address}. ${p.passwordHelp}'.trim(),
    helpUrl: p.passwordUrl,
  );
}

// ---- reading ----

/// One message as Udyoga keeps it.
class MailItem {
  const MailItem({
    required this.messageId,
    this.inReplyTo = '',
    this.references = const [],
    required this.from,
    this.fromName = '',
    this.to = const [],
    this.subject = '',
    this.date,
    this.body = '',
  });

  /// Message-ID, In-Reply-To and References, each as `<id@host>`.
  final String messageId, inReplyTo;
  final List<String> references;

  /// Lower-case addresses.
  final String from;
  final String fromName;

  /// To and Cc.
  final List<String> to;
  final String subject;
  final DateTime? date;

  /// Plain text, without the quoted reply below it.
  final String body;

  /// Every message this one answers, nearest first.
  List<String> get ancestors => [if (inReplyTo.isNotEmpty) inReplyTo, ...references.reversed];

  /// The first message of its thread, as far as the headers tell.
  String get root => references.firstOrNull ?? (inReplyTo.isNotEmpty ? inReplyTo : messageId);
}

/// The message ids in a header (`<a@x> <b@y>`), each once.
List<String> messageIds(String? header) =>
    {for (final m in RegExp(r'<[^<>\s]+>').allMatches(header ?? '')) m.group(0)!.toLowerCase()}.toList();

/// Reads a message: from the headers alone when that is all there is.
MailItem parseMail(String raw) {
  final m = MimeMessage.parseFromText(raw);
  final from = m.from?.firstOrNull;
  final html = m.decodeTextHtmlPart();
  final text = m.decodeTextPlainPart() ?? (html == null ? '' : htmlToText(html));
  return MailItem(
    messageId: messageIds(m.getHeaderValue('message-id')).firstOrNull ?? '',
    inReplyTo: messageIds(m.getHeaderValue('in-reply-to')).firstOrNull ?? '',
    references: messageIds(m.getHeaderValue('references')),
    from: from?.email.toLowerCase() ?? '',
    fromName: from?.personalName ?? '',
    to: [
      for (final a in [...?m.to, ...?m.cc]) a.email.toLowerCase(),
    ],
    subject: (m.decodeSubject() ?? '').trim(),
    date: m.decodeDate(),
    body: trimQuoted(text),
  );
}

/// HTML as readable plain text: paragraphs and line breaks kept, scripts,
/// styles and tags dropped, common entities decoded.
String htmlToText(String html) {
  var s = html
      .replaceAll(RegExp(r'<(script|style|head)[^>]*>.*?</\1\s*>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|tr|h[1-6]|blockquote)\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {'&nbsp;': ' ', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&#39;': "'", '&apos;': "'"};
  for (final e in entities.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  s = s.replaceAll('&amp;', '&');
  return s
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// The new part of a reply: the quoted message below it ("On ... wrote:",
/// "> " lines, Outlook's "From: ... Sent: ...", "-----Original Message-----")
/// and a "-- " signature are cut.
String trimQuoted(String text) {
  final lines = const LineSplitter().convert(text.replaceAll('\r', ''));
  var end = lines.length;
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i].trim();
    final next = i + 1 < lines.length ? lines[i + 1].trim() : '';
    final wrote =
        RegExp(r'^On .{6,200}wrote:$', caseSensitive: false).hasMatch(l) ||
        // "On Tue, 3 Nov 2026 at 10:00, Jordan Example <jordan@example.org>" then "wrote:".
        (RegExp(r'^On .{6,200}', caseSensitive: false).hasMatch(l) && next.toLowerCase() == 'wrote:');
    if (wrote ||
        RegExp(r'^-{2,}\s*Original Message\s*-{2,}$', caseSensitive: false).hasMatch(l) ||
        (RegExp(r'^From:\s', caseSensitive: false).hasMatch(l) &&
            lines
                .skip(i + 1)
                .take(4)
                .any((n) => RegExp(r'^(Sent|Date):\s', caseSensitive: false).hasMatch(n.trim()))) ||
        lines[i] == '-- ' ||
        l.startsWith('>') && lines.skip(i).every((n) => n.trim().isEmpty || n.trim().startsWith('>'))) {
      end = i;
      break;
    }
  }
  return lines.take(end).join('\n').trim();
}

// ---- writing ----

/// A new Message-ID on the sender's own domain.
String newMessageId(String from) {
  final r = Random.secure();
  final id = List.generate(16, (_) => r.nextInt(36).toRadixString(36)).join();
  final domain = from.contains('@') ? from.split('@').last.toLowerCase() : 'udyoga.invalid';
  return '<udyoga.$id@$domain>';
}

/// "Re: " in front of a subject that lacks it.
String replySubject(String subject) {
  final s = subject.trim();
  if (s.isEmpty) return '';
  return RegExp(r'^re:', caseSensitive: false).hasMatch(s) ? s : 'Re: $s';
}

String _word(String s) =>
    RegExp(r'^[\x20-\x7e]*$').hasMatch(s) ? s : '=?UTF-8?B?${base64.encode(utf8.encode(s))}?=';

String _address(String name, String email) {
  if (name.trim().isEmpty) return email;
  final n = name.trim();
  final safe = RegExp(r'^[\x20-\x7e]*$').hasMatch(n) ? '"${n.replaceAll(RegExp(r'["\\]'), '')}"' : _word(n);
  return '$safe <$email>';
}

/// The whole message as sent over SMTP: plain text in UTF-8, with the
/// headers that keep a reply in its thread.
String buildMail({
  required String fromName,
  required String from,
  required String to,
  required String subject,
  required String body,
  required String messageId,
  String inReplyTo = '',
  List<String> references = const [],
  required DateTime date,
}) {
  String two(int n) => n.toString().padLeft(2, '0');
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final u = date.toUtc();
  final stamp =
      '${days[u.weekday - 1]}, ${u.day} ${months[u.month - 1]} ${u.year} ${two(u.hour)}:${two(u.minute)}:${two(u.second)} +0000';
  final encoded = base64.encode(utf8.encode(body.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n')));
  final lines = [
    for (var i = 0; i < encoded.length; i += 76) encoded.substring(i, min(i + 76, encoded.length)),
  ];
  return [
    'From: ${_address(fromName, from)}',
    'To: $to',
    'Subject: ${_word(subject)}',
    'Date: $stamp',
    'Message-ID: $messageId',
    if (inReplyTo.isNotEmpty) 'In-Reply-To: $inReplyTo',
    if (references.isNotEmpty) 'References: ${references.join(' ')}',
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=utf-8',
    'Content-Transfer-Encoding: base64',
    '',
    ...lines,
    '',
  ].join('\r\n');
}
