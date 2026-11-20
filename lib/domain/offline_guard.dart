/// Offline interview practice (plan I6): while it is on and an interview
/// screen is open, nothing may leave the device. This is the I0 spike's
/// network-off hook (tool/interview_spike.dart), moved into the app and
/// scoped to the interview screens: every dart:io HTTP client made while
/// it holds can reach this machine only (for Ollama on localhost), and
/// every plain socket to another machine is refused. Each refusal is
/// counted.
///
/// The interview path also stops network use at its source in this mode:
/// the cloud AI is never chosen, and model downloads are refused
/// ([offlineDownloadMessage]). The hook is the check behind that.
library;

import 'dart:async';
import 'dart:io';

/// Said wherever a download is refused in offline practice.
const offlineDownloadMessage =
    'Offline interview practice is on, so models cannot be downloaded. Turn it off on the Interview page to '
    'download, then turn it on again.';

/// True when [host] names this machine, so a request to it never leaves
/// the device.
bool isLoopbackHost(String host) {
  final h = host.toLowerCase().replaceAll('[', '').replaceAll(']', '');
  if (h == 'localhost' || h.endsWith('.localhost')) return true;
  final ip = InternetAddress.tryParse(h);
  return ip != null && ip.isLoopback;
}

String _hostOf(Object? host) => host is InternetAddress ? host.address : '$host';

/// The app-wide guard. Screens [hold] it while offline practice is on and
/// [release] it when they close; it is active while any screen holds it.
class OfflineGuard {
  OfflineGuard._();
  static final instance = OfflineGuard._();

  var _holds = 0;
  HttpOverrides? _previousHttp;
  IOOverrides? _previousIo;

  /// Connections refused since the app started, and to where.
  var refused = 0;
  final refusedHosts = <String>[];

  /// HTTP clients made while active (each limited to this machine).
  var clients = 0;

  bool get active => _holds > 0;

  void hold() {
    if (_holds++ > 0) return;
    _previousHttp = HttpOverrides.current;
    _previousIo = IOOverrides.current;
    HttpOverrides.global = _OfflineHttp(this);
    IOOverrides.global = _OfflineIo(this);
  }

  void release() {
    if (_holds == 0) return;
    if (--_holds > 0) return;
    HttpOverrides.global = _previousHttp;
    IOOverrides.global = _previousIo;
    _previousHttp = null;
    _previousIo = null;
  }

  /// Runs [body] with the guard held.
  Future<T> run<T>(Future<T> Function() body) async {
    hold();
    try {
      return await body();
    } finally {
      release();
    }
  }

  SocketException _refuse(String host) {
    refused++;
    refusedHosts.add(host);
    return SocketException('Offline interview practice is on: $host was not contacted.');
  }
}

class _OfflineHttp extends HttpOverrides {
  _OfflineHttp(this.guard);
  final OfflineGuard guard;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    guard.clients++;
    final client = super.createHttpClient(context)
      // A proxy would be another machine.
      ..findProxy = ((_) => 'DIRECT');
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (!isLoopbackHost(uri.host)) return Future.error(guard._refuse(uri.host));
      return uri.scheme == 'https'
          ? SecureSocket.startConnect(uri.host, uri.port, context: context)
          : Socket.startConnect(uri.host, uri.port);
    };
    return client;
  }
}

/// Plain sockets: any made by code that does not go through HttpClient,
/// and HTTP clients made before the guard held.
final class _OfflineIo extends IOOverrides {
  _OfflineIo(this.guard);
  final OfflineGuard guard;

  @override
  Future<Socket> socketConnect(
    dynamic host,
    int port, {
    dynamic sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) {
    final h = _hostOf(host);
    if (!isLoopbackHost(h)) return Future.error(guard._refuse(h));
    return super.socketConnect(
      host,
      port,
      sourceAddress: sourceAddress,
      sourcePort: sourcePort,
      timeout: timeout,
    );
  }

  @override
  Future<ConnectionTask<Socket>> socketStartConnect(
    dynamic host,
    int port, {
    dynamic sourceAddress,
    int sourcePort = 0,
  }) {
    final h = _hostOf(host);
    if (!isLoopbackHost(h)) return Future.error(guard._refuse(h));
    return super.socketStartConnect(host, port, sourceAddress: sourceAddress, sourcePort: sourcePort);
  }
}
