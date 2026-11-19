/// A long-lived isolate that owns native engines (the voice, the speech
/// detector, the transcriber), so a model is loaded once per round instead
/// of once per sentence, and the UI isolate never blocks on it.
library;

import 'dart:async';
import 'dart:isolate';

/// Handles one request inside the worker and returns the reply. It runs on
/// the worker's isolate, so it may hold native objects between calls.
typedef EngineHandler = Object? Function(Object? request);

/// The last request a handler gets: free the engines. Its reply is ignored.
const engineCloseRequest = '__close__';

class EngineWorker {
  EngineWorker._(this._isolate, this._requests, this._replies, this._exit);

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _replies;
  final ReceivePort _exit;
  final _waiting = <int, Completer<Object?>>{};
  var _next = 0;
  var _closed = false;
  void Function()? _onExit;

  /// Starts a worker. [open] runs on the new isolate: it loads the engines
  /// and returns the handler for requests, which gets [engineCloseRequest]
  /// last. Throws what [open] threw.
  static Future<EngineWorker> start(EngineHandler Function() open) async {
    final replies = ReceivePort(), exit = ReceivePort();
    final ready = Completer<SendPort>();
    EngineWorker? worker;
    replies.listen((msg) {
      if (!ready.isCompleted) {
        if (msg case (SendPort p, null)) {
          ready.complete(p);
        } else if (msg case (null, String error)) {
          ready.completeError(StateError(error));
        }
        return;
      }
      final (id, ok, value) = msg as (int, bool, Object?);
      final c = worker?._waiting.remove(id);
      if (c == null) return;
      ok ? c.complete(value) : c.completeError(StateError('$value'));
    });
    final isolate = await Isolate.spawn(
      _main,
      (replies.sendPort, open),
      onExit: exit.sendPort,
      debugName: 'udyoga-engine',
    );
    exit.listen((_) async {
      // The isolate ended: fail anything still waiting. A loading error is
      // sent on another port just before the exit, so give it a moment to
      // arrive first.
      if (!ready.isCompleted) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!ready.isCompleted) ready.completeError(StateError('The speech engine stopped while loading.'));
      }
      worker?._failAll('The speech engine stopped.');
      worker?._onExit?.call();
    });
    try {
      final port = await ready.future;
      return worker = EngineWorker._(isolate, port, replies, exit);
    } on Object {
      replies.close();
      exit.close();
      isolate.kill();
      rethrow;
    }
  }

  void _failAll(String why) {
    for (final c in _waiting.values) {
      if (!c.isCompleted) c.completeError(StateError(why));
    }
    _waiting.clear();
  }

  /// Sends [request] and waits for the reply. Requests are handled one at a
  /// time, in the order sent.
  Future<T> call<T>(Object? request) {
    if (_closed) return Future.error(StateError('The speech engine is closed.'));
    final id = _next++;
    final c = _waiting[id] = Completer<Object?>();
    _requests.send((id, request));
    return c.future.then((v) => v as T);
  }

  /// Frees the engines and ends the isolate.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // The request queue is in order, so earlier requests finish first.
    final gone = Completer<void>();
    _onExit = gone.complete;
    _requests.send(engineCloseRequest);
    await gone.future.timeout(const Duration(seconds: 10), onTimeout: () => _isolate.kill());
    _failAll('The speech engine was closed.');
    _replies.close();
    _exit.close();
  }

  static void _main((SendPort, EngineHandler Function()) setup) {
    final (out, open) = setup;
    final EngineHandler handle;
    try {
      handle = open();
    } on Object catch (e) {
      out.send((null, '$e'));
      return;
    }
    final inbox = ReceivePort();
    out.send((inbox.sendPort, null));
    inbox.listen((msg) {
      if (msg == engineCloseRequest) {
        try {
          handle(engineCloseRequest);
        } on Object {
          // Freeing failed; the isolate ends anyway.
        }
        inbox.close();
        Isolate.exit();
      }
      final (id, request) = msg as (int, Object?);
      try {
        out.send((id, true, handle(request)));
      } on Object catch (e) {
        out.send((id, false, '$e'));
      }
    });
  }
}
