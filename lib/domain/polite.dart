/// The politeness layer every background page read goes through: robots.txt
/// (kept for a week), a minimum gap between requests to one site, a daily
/// cap per use, and a record of pages already read so they are not read
/// again. The employer watch and the site recipes both use it.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'ats.dart';
import 'feeds.dart';
import 'json.dart';

/// Thrown when robots.txt asks programs not to read a page.
class RobotsRefused extends FeedException {
  RobotsRefused(String path) : super('its robots.txt asks programs not to read $path');
}

/// Thrown when a use has made its requests for the day.
class DailyCapReached extends FeedException {
  DailyCapReached(int cap) : super('the daily cap of $cap is reached; it carries on tomorrow');
}

/// Device-only keys for the politeness layer.
abstract final class PoliteKeys {
  /// When a site was last asked (ISO time).
  static String last(String host) => 'udyoga.polite.last.$host';

  /// {"day": "yyyy-MM-dd", "n": int} for one use (a recipe, say).
  static String count(String use) => 'udyoga.polite.count.$use';

  /// {url: ISO time} of pages a use has read, pruned after [PoliteFetcher.seenFor].
  static String seen(String use) => 'udyoga.polite.seen.$use';
}

/// How many times [use] ran on [day], and records one more. Kept on this
/// device; the day is local.
class DailyCounter {
  DailyCounter(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;

  String get _today => _clock().toIso8601String().substring(0, 10);

  Future<int> used(String use) async {
    final j = decodeObject(await db.localSetting(PoliteKeys.count(use)) ?? '');
    return str(j['day']) == _today ? (intOf(j['n']) ?? 0) : 0;
  }

  Future<void> add(String use) async {
    final n = await used(use);
    await db.setLocalSetting(PoliteKeys.count(use), jsonEncode({'day': _today, 'n': n + 1}));
  }

  /// Raises today's count for [use] to [n] (a count from another device);
  /// a lower [n] changes nothing.
  Future<void> raiseTo(String use, int n) async {
    if (n <= await used(use)) return;
    await db.setLocalSetting(PoliteKeys.count(use), jsonEncode({'day': _today, 'n': n}));
  }
}

/// Reads web pages politely. Every request names Udyoga ([politeAgent]),
/// checks robots.txt first, waits [gap] after the last request to the same
/// site, and counts against [dailyCap] for its use.
class PoliteFetcher {
  PoliteFetcher(this.db, this.client, {DateTime Function()? clock, Future<void> Function(Duration)? sleep})
    : _clock = clock ?? DateTime.now,
      _sleep = sleep ?? Future<void>.delayed;
  final AppDatabase db;
  final http.Client client;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;

  static const robotsEvery = Duration(days: 7);

  /// A page read for a use is not read again for this long.
  static const seenFor = Duration(days: 7);

  /// The page at [uri] as text. Throws [RobotsRefused], [DailyCapReached]
  /// or a [FeedException] for a refusal or an error. [onAnswer] runs once
  /// the site has answered, whatever it said.
  Future<String> get(
    Uri uri, {
    Duration gap = Duration.zero,
    String? use,
    int? dailyCap,
    String accept = 'text/html',
    FutureOr<void> Function()? onAnswer,
  }) async {
    await checkRobots(uri);
    final counter = DailyCounter(db, clock: _clock);
    if (use != null && dailyCap != null && await counter.used(use) >= dailyCap) {
      throw DailyCapReached(dailyCap);
    }
    await _wait(uri.host, gap);
    final r = await client
        .get(uri, headers: {'user-agent': politeAgent, 'accept': accept})
        .timeout(const Duration(seconds: 30));
    await db.setLocalSetting(PoliteKeys.last(uri.host), _clock().toIso8601String());
    if (use != null) await counter.add(use);
    await onAnswer?.call();
    if (r.statusCode == 403 || r.statusCode == 429) throw FeedException('the site turned Udyoga away');
    if (r.statusCode != 200) throw FeedException('error ${r.statusCode}');
    return utf8.decode(r.bodyBytes, allowMalformed: true);
  }

  /// Throws [RobotsRefused] when robots.txt asks programs not to read [uri].
  Future<void> checkRobots(Uri uri) async {
    final path = uri.path.isEmpty ? '/' : uri.path;
    if (!robotsAllows(await robots(uri), path)) throw RobotsRefused(path);
  }

  /// Waits until [gap] has passed since the last request to [host].
  Future<void> _wait(String host, Duration gap) async {
    if (gap <= Duration.zero) return;
    final last = DateTime.tryParse(await db.localSetting(PoliteKeys.last(host)) ?? '');
    if (last == null) return;
    final left = gap - _clock().difference(last);
    if (left > Duration.zero) await _sleep(left);
  }

  /// The site's robots.txt, from the week's copy when there is one. No
  /// robots.txt (404) allows everything; any other failure means "not now".
  Future<String> robots(Uri page) async {
    final key = WatchKeys.robots(page.host);
    final cached = decodeObject(await db.localSetting(key) ?? '');
    final at = DateTime.tryParse(str(cached['at']));
    if (at != null && _clock().difference(at) < robotsEvery) return str(cached['text']);
    final r = await client
        .get(
          Uri(scheme: page.scheme, host: page.host, port: page.port, path: '/robots.txt'),
          headers: {'user-agent': politeAgent},
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200 && r.statusCode != 404) {
      throw FeedException('robots.txt answered ${r.statusCode}');
    }
    final text = r.statusCode == 200 ? utf8.decode(r.bodyBytes, allowMalformed: true) : '';
    await db.setLocalSetting(key, jsonEncode({'at': _clock().toIso8601String(), 'text': text}));
    return text;
  }

  /// True when [use] read [url] within [seenFor].
  Future<bool> seen(String use, String url) async {
    final at = DateTime.tryParse(str(decodeObject(await db.localSetting(PoliteKeys.seen(use)) ?? '')[url]));
    return at != null && _clock().difference(at) < seenFor;
  }

  /// Records that [use] read [url], dropping entries past [seenFor].
  Future<void> markSeen(String use, String url) async {
    final now = _clock();
    final all = decodeObject(await db.localSetting(PoliteKeys.seen(use)) ?? '');
    final kept = <String, Object?>{
      for (final e in all.entries)
        if (DateTime.tryParse(str(e.value)) case final at? when now.difference(at) < seenFor) e.key: e.value,
      url: now.toIso8601String(),
    };
    await db.setLocalSetting(PoliteKeys.seen(use), jsonEncode(kept));
  }
}
