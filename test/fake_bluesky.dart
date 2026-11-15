// A Bluesky server in memory for tests: sessions, search, posts and DMs
// answered from fixed data, every request recorded. No network. Every
// handle and DID is made up.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const myDid = 'did:plc:alexexample';
const myHandle = 'alex.example.com';
const appPassword = 'abcd-efgh-ijkl-mnop';

class FakeBluesky {
  final requests = <http.Request>[];
  var access = 'access-1';
  var refresh = 'refresh-1';
  var refreshes = 0;

  /// The next signed-in call answers ExpiredToken once.
  var expireNext = false;

  /// Whether the app password allows DMs.
  var dms = true;
  var refreshWorks = true;

  final actors = <Map<String, Object?>>[];
  final posts = <Map<String, Object?>>[];
  final created = <Map<String, Object?>>[];

  /// Convo id to the convo view and its messages (oldest first).
  final convos = <String, ({Map<String, Object?> view, List<Map<String, Object?>> messages})>{};
  final sent = <({String convoId, String text})>[];

  late final client = MockClient((r) async {
    requests.add(r);
    final nsid = r.url.pathSegments.last;
    final auth = r.headers['authorization'] ?? '';
    Map<String, Object?> body() => r.body.isEmpty ? const {} : jsonDecode(r.body) as Map<String, Object?>;
    http.Response ok(Object j) =>
        http.Response(jsonEncode(j), 200, headers: {'content-type': 'application/json'});
    http.Response err(int code, String error, String message) =>
        http.Response(jsonEncode({'error': error, 'message': message}), code);

    switch (nsid) {
      case 'com.atproto.server.createSession':
        if (body()['password'] != appPassword) {
          return err(401, 'AuthenticationRequired', 'Invalid identifier or password');
        }
        return ok({
          'accessJwt': access,
          'refreshJwt': refresh,
          'handle': myHandle,
          'did': myDid,
          'didDoc': {
            'service': [
              {
                'id': '#atproto_pds',
                'type': 'AtprotoPersonalDataServer',
                'serviceEndpoint': 'https://pds.example.com',
              },
            ],
          },
        });
      case 'com.atproto.server.refreshSession':
        if (!refreshWorks || auth != 'Bearer $refresh') return err(400, 'ExpiredToken', 'Token has expired');
        refreshes++;
        access = 'access-${refreshes + 1}';
        refresh = 'refresh-${refreshes + 1}';
        return ok({'accessJwt': access, 'refreshJwt': refresh, 'handle': myHandle, 'did': myDid});
    }
    if (auth != 'Bearer $access') return err(400, 'ExpiredToken', 'Token has expired');
    if (expireNext) {
      expireNext = false;
      return err(400, 'ExpiredToken', 'Token has expired');
    }
    final chat = nsid.startsWith('chat.bsky.');
    if (chat && r.headers['atproto-proxy'] != 'did:web:api.bsky.chat#bsky_chat') {
      return err(400, 'InvalidRequest', 'missing proxy');
    }
    if (chat && !dms) return err(401, 'InvalidToken', 'Bad token scope');
    final q = r.url.queryParameters;
    switch (nsid) {
      case 'app.bsky.actor.searchActors':
        return ok({'actors': actors});
      case 'app.bsky.feed.searchPosts':
        return ok({'posts': posts});
      case 'com.atproto.repo.createRecord':
        created.add(body());
        return ok({'uri': 'at://$myDid/app.bsky.feed.post/3kpost', 'cid': 'bafy'});
      case 'com.atproto.identity.resolveHandle':
        return ok({'did': 'did:plc:${q['handle']!.split('.').first}'});
      case 'chat.bsky.convo.listConvos':
        return ok({
          'convos': [for (final c in convos.values) c.view],
        });
      case 'chat.bsky.convo.getMessages':
        return ok({'messages': convos[q['convoId']]!.messages.reversed.toList()});
      case 'chat.bsky.convo.getConvoForMembers':
        final did = q['members']!;
        final id = 'convo-$did';
        convos.putIfAbsent(id, () => (view: convoView(id, did, did.split(':').last, rev: '1'), messages: []));
        return ok({'convo': convos[id]!.view});
      case 'chat.bsky.convo.sendMessage':
        final b = body();
        final text = (b['message'] as Map)['text'] as String;
        sent.add((convoId: b['convoId'] as String, text: text));
        return ok({
          'id': 'm-sent-${sent.length}',
          'rev': 'r',
          'text': text,
          'sender': {'did': myDid},
          'sentAt': '2026-11-12T10:00:00Z',
        });
    }
    return err(404, 'MethodNotImplemented', nsid);
  });

  /// A one-to-one convo view.
  static Map<String, Object?> convoView(
    String id,
    String did,
    String handle, {
    required String rev,
    String? lastFrom,
  }) => {
    'id': id,
    'rev': rev,
    'members': [
      {'did': myDid, 'handle': myHandle},
      {'did': did, 'handle': handle, 'displayName': ''},
    ],
    if (lastFrom != null)
      'lastMessage': {
        'id': 'x',
        'rev': rev,
        'text': '…',
        'sender': {'did': lastFrom},
        'sentAt': '2026-11-11T09:00:00Z',
      },
    'muted': false,
    'unreadCount': 1,
  };

  static Map<String, Object?> message(String id, String fromDid, String text, String sentAt) => {
    'id': id,
    'rev': id,
    'text': text,
    'sender': {'did': fromDid},
    'sentAt': sentAt,
  };
}
