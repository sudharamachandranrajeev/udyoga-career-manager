import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'book.dart';
import 'conversations.dart';
import 'json.dart';
import 'linkedin_messages.dart' show closeInTime, similarText;
import 'mail_sync.dart' show MailAlert;

// Bluesky over the AT Protocol, signed in with an app password: search for
// people and posts by topic, post when the user presses Post, and the
// user's own direct messages in Conversations. Every call is one the user
// asked for or a modest check (at start and hourly); nothing loops. The
// session tokens stay in this device's keychain; the account in its local
// settings. Neither is synced.

/// The main Bluesky host. A self-hosted PDS can be entered instead.
const bskyService = 'https://bsky.social';

/// Direct messages go to Bluesky's chat service through the user's PDS.
const bskyChatProxy = 'did:web:api.bsky.chat#bsky_chat';

/// Where the account is kept (local settings, never synced).
const blueskyAccountKey = 'udyoga.bluesky.account';

/// Topics offered as one-tap searches.
const blueskyTopics = [
  'NHS digital',
  'health informatics',
  'clinical informatics',
  'digital health UK',
  'NHS jobs',
];

/// Bluesky app passwords look like `abcd-efgh-ijkl-mnop`.
final _appPassword = RegExp(r'^[a-z0-9]{4}(-[a-z0-9]{4}){3}$');

/// The longest post Bluesky takes, in characters.
const bskyPostLimit = 300;

const appPasswordHelp =
    'Make an app password in Bluesky: Settings > Privacy and security > App passwords. Tick '
    '"Allow access to your direct messages" if Udyoga should show your DMs in Conversations.';
const appPasswordUrl = 'https://bsky.app/settings/app-passwords';

class BlueskyException implements Exception, UserFacingError {
  const BlueskyException(this.message, {this.code = ''});
  @override
  final String message;

  /// The server's error name (ExpiredToken, RateLimitExceeded...).
  final String code;

  @override
  String toString() => message;
}

/// The signed-in account.
class BlueskyAccount {
  const BlueskyAccount({
    required this.handle,
    required this.did,
    this.service = bskyService,
    this.pds = '',
    this.dms = false,
    this.notify = true,
    this.lastSync,
    this.convos = const {},
  });

  final String handle, did;

  /// Where the user signed in, and the PDS their DID document names (used
  /// for every call after sign-in).
  final String service, pds;

  /// Whether the app password allows direct messages.
  final bool dms;

  /// Alert on this device when a saved contact writes.
  final bool notify;
  final String? lastSync;

  /// Each conversation's rev at the last sync, so unchanged ones are skipped.
  final Map<String, String> convos;

  String get host => pds.isNotEmpty ? pds : service;

  factory BlueskyAccount.fromJson(Json j) => BlueskyAccount(
    handle: str(j['handle']),
    did: str(j['did']),
    service: str(j['service']).isEmpty ? bskyService : str(j['service']),
    pds: str(j['pds']),
    dms: j['dms'] == true,
    notify: j['notify'] != false,
    lastSync: j['lastSync'] as String?,
    convos: {for (final e in obj(j['convos']).entries) e.key: str(e.value)},
  );

  Json toJson() => {
    'handle': handle,
    'did': did,
    'service': service,
    'pds': pds,
    'dms': dms,
    'notify': notify,
    'lastSync': ?lastSync,
    'convos': convos,
  };

  BlueskyAccount copyWith({bool? dms, bool? notify, String? lastSync, Map<String, String>? convos}) =>
      BlueskyAccount(
        handle: handle,
        did: did,
        service: service,
        pds: pds,
        dms: dms ?? this.dms,
        notify: notify ?? this.notify,
        lastSync: lastSync ?? this.lastSync,
        convos: convos ?? this.convos,
      );
}

/// A person found on Bluesky.
class BskyPerson {
  const BskyPerson({required this.did, required this.handle, this.displayName = '', this.description = ''});
  final String did, handle, displayName, description;

  String get name => displayName.trim().isNotEmpty ? displayName.trim() : handle;
  String get profileUrl => 'https://bsky.app/profile/$handle';

  factory BskyPerson.fromJson(Object? v) {
    final j = obj(v);
    return BskyPerson(
      did: str(j['did']),
      handle: str(j['handle']),
      displayName: str(j['displayName']),
      description: str(j['description']),
    );
  }
}

/// A post found on Bluesky.
class BskyPost {
  const BskyPost({required this.uri, required this.author, required this.text, this.createdAt = ''});
  final String uri, text, createdAt;
  final BskyPerson author;

  String get url => postUrl(author.handle, uri);

  factory BskyPost.fromJson(Object? v) {
    final j = obj(v);
    final record = obj(j['record']);
    return BskyPost(
      uri: str(j['uri']),
      author: BskyPerson.fromJson(j['author']),
      text: str(record['text']),
      createdAt: str(record['createdAt']),
    );
  }
}

/// The bsky.app page for a post's at:// URI.
String postUrl(String handle, String uri) => 'https://bsky.app/profile/$handle/post/${uri.split('/').last}';

/// A handle as stored and compared: lower case, without the @.
String bskyHandle(String h) => h.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

/// Link facets for the URLs in [text], so they show as links. Bluesky
/// counts positions in UTF-8 bytes.
List<Json> linkFacets(String text) => [
  for (final m in RegExp(r'https?://[^\s<>()]+[^\s<>().,;:!?"]').allMatches(text))
    {
      'index': {
        'byteStart': utf8.encode(text.substring(0, m.start)).length,
        'byteEnd': utf8.encode(text.substring(0, m.end)).length,
      },
      'features': [
        {'\$type': 'app.bsky.richtext.facet#link', 'uri': m[0]},
      ],
    },
];

/// The Bluesky client: sign-in, search, posting and direct messages.
class Bluesky {
  Bluesky(this.book, this.client, this.secrets, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;
  final CareerBook book;
  final http.Client client;
  final SecretStore secrets;
  final DateTime Function() clock;

  static const _accessKey = 'udyoga.bluesky.access';
  static const _refreshKey = 'udyoga.bluesky.refresh';
  static const _timeout = Duration(seconds: 20);

  AppDatabase get db => book.db;

  Future<BlueskyAccount?> account() async {
    final raw = await db.localSetting(blueskyAccountKey);
    if (raw == null || raw.isEmpty) return null;
    return BlueskyAccount.fromJson(decodeObject(raw));
  }

  Future<void> saveAccount(BlueskyAccount a) => db.setLocalSetting(blueskyAccountKey, jsonEncode(a.toJson()));

  /// Signs in with an app password (never the main password, which is not
  /// kept either way), then checks whether it allows direct messages.
  Future<BlueskyAccount> signIn({
    String service = bskyService,
    required String identifier,
    required String appPassword,
  }) async {
    final pw = appPassword.trim().toLowerCase();
    if (!_appPassword.hasMatch(pw)) {
      throw const BlueskyException(
        'Use an app password (four groups of four, like abcd-efgh-ijkl-mnop), '
        'not your main Bluesky password. $appPasswordHelp',
      );
    }
    final Uri base;
    try {
      base = validateServerUrl(service.trim().isEmpty ? bskyService : service.trim());
    } on SyncException {
      throw const BlueskyException('Enter the server as https://… (or http:// on your own network).');
    }
    final Json s;
    try {
      s = await _send(
        'POST',
        '$base',
        'com.atproto.server.createSession',
        body: {'identifier': bskyHandle(identifier), 'password': pw},
      );
    } on BlueskyException catch (e) {
      if (e.code == 'AuthenticationRequired' || e.code == 'AuthFactorTokenRequired') {
        throw BlueskyException('Bluesky would not sign in ${bskyHandle(identifier)}. $appPasswordHelp');
      }
      rethrow;
    }
    await secrets.write(_accessKey, str(s['accessJwt']));
    await secrets.write(_refreshKey, str(s['refreshJwt']));
    final pds = [
      for (final svc in objs(obj(s['didDoc'])['service']))
        if (str(svc['id']).endsWith('#atproto_pds')) str(svc['serviceEndpoint']),
    ].firstOrNull;
    var a = BlueskyAccount(handle: str(s['handle']), did: str(s['did']), service: '$base', pds: pds ?? '');
    await saveAccount(a);
    // A quick look at the inbox says whether the password allows DMs.
    try {
      await _call('GET', 'chat.bsky.convo.listConvos', query: {'limit': '1'}, chat: true);
      a = a.copyWith(dms: true);
    } on BlueskyException catch (_) {
      a = a.copyWith(dms: false);
    }
    await saveAccount(a);
    return a;
  }

  /// Forgets the account and its tokens on this device. Messages already in
  /// Conversations stay.
  Future<void> signOut() async {
    await secrets.delete(_accessKey);
    await secrets.delete(_refreshKey);
    await db.setLocalSetting(blueskyAccountKey, '');
  }

  // ---- calls ----

  Future<Json> _send(
    String method,
    String base,
    String nsid, {
    Map<String, String>? query,
    Json? body,
    String? token,
    bool chat = false,
  }) async {
    final uri = Uri.parse('${base.replaceFirst(RegExp(r'/+$'), '')}/xrpc/$nsid')
        .replace(queryParameters: query);
    final headers = {
      if (token != null) 'authorization': 'Bearer $token',
      if (body != null) 'content-type': 'application/json',
      if (chat) 'atproto-proxy': bskyChatProxy,
    };
    final http.Response r;
    try {
      r =
          await (method == 'POST'
                  ? client.post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
                  : client.get(uri, headers: headers))
              .timeout(_timeout);
    } on SocketException {
      throw BlueskyException('Could not reach ${uri.host}. Check the connection.');
    } on TimeoutException {
      throw BlueskyException('${uri.host} did not answer in time. Try again later.');
    } on http.ClientException {
      throw BlueskyException('Could not reach ${uri.host}. Check the connection.');
    }
    Json j;
    try {
      j = r.body.isEmpty ? const {} : obj(jsonDecode(r.body));
    } on FormatException {
      j = const {};
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return j;
    final code = str(j['error']);
    final said = str(j['message']);
    throw BlueskyException(switch ((r.statusCode, code)) {
      (429, _) || (_, 'RateLimitExceeded') => 'Bluesky asked Udyoga to slow down. Try again in a while.',
      _ when chat && said.toLowerCase().contains('scope') =>
        'This app password does not allow direct messages. Make a new one with "Allow access to your '
            'direct messages" ticked, then connect again.',
      _ =>
        'Bluesky: ${said.isNotEmpty
            ? said
            : code.isNotEmpty
            ? code
            : 'error ${r.statusCode}'}',
    }, code: code.isNotEmpty ? code : '${r.statusCode}');
  }

  /// A signed-in call. An expired access token is refreshed once and the
  /// call made again; nothing more.
  Future<Json> _call(
    String method,
    String nsid, {
    Map<String, String>? query,
    Json? body,
    bool chat = false,
  }) async {
    final a = await account();
    final token = await secrets.read(_accessKey);
    if (a == null || token == null || token.isEmpty) {
      throw const BlueskyException('Connect your Bluesky account first (Connected accounts).');
    }
    try {
      return await _send(method, a.host, nsid, query: query, body: body, token: token, chat: chat);
    } on BlueskyException catch (e) {
      if (e.code != 'ExpiredToken' && e.code != '401') rethrow;
      // A 401 that is not about the token's age is not retried.
      if (e.code == '401' && !e.message.toLowerCase().contains('expired')) rethrow;
      final fresh = await _refresh(a);
      return _send(method, a.host, nsid, query: query, body: body, token: fresh, chat: chat);
    }
  }

  Future<String> _refresh(BlueskyAccount a) async {
    final refresh = await secrets.read(_refreshKey);
    if (refresh == null || refresh.isEmpty) {
      throw const BlueskyException('Your Bluesky sign-in has ended. Connect the account again.');
    }
    final Json s;
    try {
      s = await _send('POST', a.host, 'com.atproto.server.refreshSession', token: refresh);
    } on BlueskyException {
      throw const BlueskyException('Your Bluesky sign-in has ended. Connect the account again.');
    }
    await secrets.write(_accessKey, str(s['accessJwt']));
    await secrets.write(_refreshKey, str(s['refreshJwt']));
    return str(s['accessJwt']);
  }

  // ---- search ----

  /// People whose profile matches [q].
  Future<List<BskyPerson>> searchPeople(String q, {int limit = 25}) async => [
    for (final p in objs(
      (await _call(
        'GET',
        'app.bsky.actor.searchActors',
        query: {'q': q.trim(), 'limit': '$limit'},
      ))['actors'],
    ))
      BskyPerson.fromJson(p),
  ];

  /// Recent posts about [q].
  Future<List<BskyPost>> searchPosts(String q, {int limit = 25}) async => [
    for (final p in objs(
      (await _call(
        'GET',
        'app.bsky.feed.searchPosts',
        query: {'q': q.trim(), 'limit': '$limit', 'sort': 'latest'},
      ))['posts'],
    ))
      BskyPost.fromJson(p),
  ];

  // ---- posting ----

  /// Posts [text] as the user. Only called when the user presses Post.
  /// Returns the post's bsky.app address.
  Future<String> post(String text) async {
    final t = text.trim();
    if (t.isEmpty) throw const BlueskyException('Write the post first.');
    if (t.runes.length > bskyPostLimit) {
      throw BlueskyException(
        'Bluesky posts take up to $bskyPostLimit characters; this has ${t.runes.length}.',
      );
    }
    final a = (await account())!;
    final facets = linkFacets(t);
    final r = await _call(
      'POST',
      'com.atproto.repo.createRecord',
      body: {
        'repo': a.did,
        'collection': 'app.bsky.feed.post',
        'record': {
          '\$type': 'app.bsky.feed.post',
          'text': t,
          'createdAt': clock().toUtc().toIso8601String(),
          'langs': ['en'],
          if (facets.isNotEmpty) 'facets': facets,
        },
      },
    );
    return postUrl(a.handle, str(r['uri']));
  }

  // ---- direct messages ----

  /// Reads the newest conversations and brings the ones with saved contacts
  /// (and new ones from strangers, into the Screener) into Conversations.
  Future<({int added, List<MailAlert> alerts})> syncMessages() async {
    var a = await account();
    if (a == null || !a.dms) return (added: 0, alerts: const <MailAlert>[]);
    final known = await _knownPeople();
    final revs = {...a.convos};
    var added = 0;
    final alerts = <MailAlert>[];
    // One page of the newest 30: a modest check, never a crawl.
    final convos = objs(
      (await _call('GET', 'chat.bsky.convo.listConvos', query: {'limit': '30'}, chat: true))['convos'],
    );
    for (final c in convos) {
      final id = str(c['id']);
      final members = [for (final m in objs(c['members'])) BskyPerson.fromJson(m)];
      final other = members.where((m) => m.did != a!.did).toList();
      if (other.length != 1) continue; // group chats are left alone
      final them = other.single;
      if (revs[id] == str(c['rev'])) continue;
      final person = known[them.did] ?? known[bskyHandle(them.handle)];
      var t = await book.threadByExternalId('bluesky', id);
      if (t == null && person != null) {
        t = (await book.conversationsOf(person.id))
            .where((x) => x.channel == 'bluesky' && x.externalId == null)
            .firstOrNull;
        if (t != null) {
          t = t.copyWith(externalId: Value(id), account: a.handle, mode: 'api');
          await book.save(db.conversations, t, t.id);
        }
      }
      if (t == null) {
        // A stranger who wrote first waits in the Screener; a convo with a
        // stranger the user started elsewhere is left alone.
        final last = obj(c['lastMessage']);
        if (person == null && str(obj(last['sender'])['did']) != them.did) {
          revs[id] = str(c['rev']);
          continue;
        }
        final tid = await book.startConversation(
          contactId: person?.id,
          channel: 'bluesky',
          account: a.handle,
          mode: 'api',
          peer: '@${them.handle}',
          externalId: id,
          at: _local(str(last['sentAt'])),
        );
        t = await book.conversation(tid);
      }
      final messages = objs(
        (await _call(
          'GET',
          'chat.bsky.convo.getMessages',
          query: {'convoId': id, 'limit': '50'},
          chat: true,
        ))['messages'],
      ).reversed;
      final logged = [
        for (final m in await book.messagesIn(t.id))
          if (m.source == 'manual') m,
      ];
      for (final m in messages) {
        final text = str(m['text']);
        if (text.isEmpty) continue; // deleted
        final out = str(obj(m['sender'])['did']) == a.did;
        final at = _local(str(m['sentAt']));
        final direction = out ? 'out' : 'in';
        if (logged.any(
          (x) => x.direction == direction && closeInTime(x.sentAt, at) && similarText(x.body, text),
        )) {
          continue;
        }
        final mid = await book.addMessage(
          t.id,
          direction: direction,
          body: text,
          at: at,
          source: 'api',
          status: out ? 'sent' : null,
          externalId: str(m['id']),
        );
        if (mid == null) continue;
        added++;
        if (!out && person != null && a.notify) {
          alerts.add((
            conversationId: t.id,
            name: person.name,
            preview: text.replaceAll(RegExp(r'\s+'), ' '),
          ));
        }
      }
      revs[id] = str(c['rev']);
    }
    a = (await account())!;
    await saveAccount(a.copyWith(convos: revs, lastSync: clock().toUtc().toIso8601String()));
    return (added: added, alerts: alerts);
  }

  /// Checks messages when the last check is older than [every].
  Future<({int added, List<MailAlert> alerts})> syncDue({
    Duration every = const Duration(minutes: 15),
    bool force = false,
  }) async {
    final a = await account();
    if (a == null || !a.dms) return (added: 0, alerts: const <MailAlert>[]);
    final last = DateTime.tryParse(a.lastSync ?? '');
    if (!force && last != null && clock().toUtc().difference(last) < every) {
      return (added: 0, alerts: const <MailAlert>[]);
    }
    return syncMessages();
  }

  /// Sends a DM in [thread]: in its conversation, or a new one with the
  /// contact's DID. Returns the message id.
  Future<String> sendMessage(Conversation thread, Lead contact, String text) async {
    var convoId = thread.externalId;
    if (convoId == null || convoId.isEmpty) {
      final did = await _didOf(thread, contact);
      convoId = str(
        obj(
          (await _call(
            'GET',
            'chat.bsky.convo.getConvoForMembers',
            query: {'members': did},
            chat: true,
          ))['convo'],
        )['id'],
      );
      final t = await book.conversation(thread.id);
      await book.save(db.conversations, t.copyWith(externalId: Value(convoId), mode: 'api'), t.id);
    }
    final r = await _call(
      'POST',
      'chat.bsky.convo.sendMessage',
      body: {
        'convoId': convoId,
        'message': {
          'text': text.trim(),
          if (linkFacets(text.trim()) case final f when f.isNotEmpty) 'facets': f,
        },
      },
      chat: true,
    );
    return str(r['id']);
  }

  Future<String> _didOf(Conversation thread, Lead contact) async {
    final handles = [
      for (final h in await book.handlesOf(contact.id))
        if (h.channel == 'bluesky') bskyHandle(h.handle),
    ];
    if (handles.where((h) => h.startsWith('did:')).firstOrNull case final did?) return did;
    final handle = handles.firstOrNull ?? bskyHandle(thread.peer);
    if (handle.isEmpty) throw BlueskyException('${contact.name} has no Bluesky handle.');
    final r = await _call('GET', 'com.atproto.identity.resolveHandle', query: {'handle': handle});
    return str(r['did']);
  }

  /// Saved contacts by Bluesky DID and handle.
  Future<Map<String, Lead>> _knownPeople() async {
    final people = {
      for (final c in await (db.select(db.careerContacts)..where((c) => c.deleted.not())).get()) c.id: c,
    };
    return {
      for (final h in await (db.select(
        db.contactHandles,
      )..where((h) => h.deleted.not() & h.channel.equals('bluesky'))).get())
        bskyHandle(h.handle): ?people[h.contactId],
    };
  }

  String _local(String iso) =>
      (DateTime.tryParse(iso) ?? clock()).toLocal().toIso8601String().substring(0, 16);
}

/// Saves a person found on Bluesky as a contact, with their handle and DID,
/// where they were found and why they may be contacted. Returns the
/// contact's id (the existing one when they are saved already).
Future<String> saveBlueskyPerson(
  CareerBook book,
  BskyPerson p, {
  String sourceUrl = '',
  String topic = '',
  required String today,
}) async {
  final keys = {bskyHandle(p.handle), p.did.toLowerCase()};
  for (final h in await (book.db.select(
    book.db.contactHandles,
  )..where((h) => h.deleted.not() & h.channel.equals('bluesky'))).get()) {
    if (keys.contains(bskyHandle(h.handle)) && await book.contact(h.contactId) != null) return h.contactId;
  }
  final id = newId();
  await book.save(
    book.db.careerContacts,
    CareerContactsCompanion.insert(
      id: id,
      name: p.name,
      kind: const Value('peer'),
      source: Value(topic.isEmpty ? 'Bluesky' : 'Bluesky search: $topic'),
      sourceUrl: Value(sourceUrl.isNotEmpty ? sourceUrl : p.profileUrl),
      sourceKind: const Value('other'),
      foundOn: Value(today),
      basis: const Value('legitimate_interest'),
      notes: Value(p.description.trim()),
    ),
    id,
  );
  await book.addHandle(id, 'bluesky', '@${p.handle}', primary: true);
  if (p.did.isNotEmpty) await book.addHandle(id, 'bluesky', p.did);
  return id;
}

/// Bluesky DMs from the composer.
class BlueskySender implements ChannelSender {
  BlueskySender(this.bluesky, this.a);
  final Bluesky bluesky;
  final BlueskyAccount a;

  @override
  String get channel => 'bluesky';

  @override
  String get account => a.handle;

  @override
  Future<String> send(Conversation thread, Lead contact, String body, {String subject = ''}) =>
      bluesky.sendMessage(thread, contact, body);
}
