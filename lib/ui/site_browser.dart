import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../domain/assist_fill.dart';
import '../domain/ocr.dart';
import '../domain/page_reader.dart';

/// An employer's or job board's site opened inside Udyoga, so the candidate
/// applies there (signing in and pressing submit themselves) while Udyoga
/// keeps the answers beside it and can keep a copy of the page.
abstract class SiteBrowser {
  /// Opens [url]. Returns the page to show inside Udyoga (Android), or null
  /// when it opens in its own window (desktop).
  Future<Widget?> open(String url, {required String title});

  /// The address and the readable text of the page now showing, or null
  /// when nothing is open.
  Future<({String url, String title, String text})?> page();

  /// The page read in full for the page reader (text, JSON-LD, HTML), or
  /// null when nothing is open.
  Future<PageSnapshot?> snapshot();

  /// The page's largest canvas as a PNG, or null when there is none or the
  /// page does not allow it to be read.
  Future<Uint8List?> canvasImage();

  /// Puts [text] into the text box at [selector] and nothing more: the only
  /// way Udyoga changes a page. It runs [fillScript], which presses nothing.
  Future<Object?> fillTextBox(String selector, String text);

  Future<void> close();
}

/// [canvasImageScript]'s reply as bytes.
Uint8List? _decodeImage(Object? raw) {
  var v = raw;
  if (v is String && v.startsWith('"')) {
    try {
      v = jsonDecode(v);
    } on FormatException {
      return null;
    }
  }
  return v is String ? dataUrlBytes(v) : null;
}

/// A new browser for each site page, or null on devices without one (the
/// site then opens in the system browser).
final siteBrowserProvider = Provider<SiteBrowser? Function()>((ref) => platformSiteBrowser);

SiteBrowser? platformSiteBrowser() {
  if (Platform.isAndroid) return _AndroidSiteBrowser();
  if (Platform.isLinux || Platform.isWindows) return _DesktopSiteBrowser();
  return null;
}

/// Reads the page as text (what a person would select and copy).
const _readPage =
    "JSON.stringify({url: location.href, title: document.title, text: document.body ? document.body.innerText : ''})";

({String url, String title, String text})? _decodePage(Object? raw) {
  var v = raw;
  // Platforms return the JSON string either as is or quoted once more.
  for (var i = 0; i < 2 && v is String; i++) {
    try {
      v = jsonDecode(v);
    } on FormatException {
      return null;
    }
  }
  if (v is! Map) return null;
  String s(Object? x) => x is String ? x : '';
  return (url: s(v['url']), title: s(v['title']).trim(), text: s(v['text']).trim());
}

/// Linux (WebKitGTK) and Windows (WebView2): a separate window with back,
/// forward and reload in its title bar. Sign-ins stay in Udyoga's own
/// browser profile, apart from the system browser.
class _DesktopSiteBrowser implements SiteBrowser {
  Webview? _view;

  @override
  Future<Widget?> open(String url, {required String title}) async {
    if (_view != null) {
      _view!.launch(url);
      return null;
    }
    final support = await getApplicationSupportDirectory();
    final view = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: title,
        windowWidth: 1100,
        windowHeight: 860,
        userDataFolderWindows: '${support.path}${Platform.pathSeparator}webview',
      ),
    );
    _view = view;
    view.onClose.whenComplete(() => _view = null);
    view.launch(url);
    return null;
  }

  @override
  Future<({String url, String title, String text})?> page() async {
    final view = _view;
    if (view == null) return null;
    return _decodePage(await view.evaluateJavaScript(_readPage));
  }

  @override
  Future<PageSnapshot?> snapshot() async {
    final view = _view;
    if (view == null) return null;
    return PageSnapshot.decode(await view.evaluateJavaScript(readPageScript));
  }

  @override
  Future<Uint8List?> canvasImage() async {
    final view = _view;
    if (view == null) return null;
    return _decodeImage(await view.evaluateJavaScript(canvasImageScript));
  }

  @override
  Future<Object?> fillTextBox(String selector, String text) async =>
      _view?.evaluateJavaScript(fillScript(selector, text));

  @override
  Future<void> close() async {
    _view?.close();
    _view = null;
  }
}

/// Android: the site inside the page, with the answers a tab away.
class _AndroidSiteBrowser implements SiteBrowser {
  WebViewController? _controller;

  @override
  Future<Widget?> open(String url, {required String title}) async {
    final c = _controller ??= WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
    await c.loadRequest(Uri.parse(url));
    return WebViewWidget(controller: c);
  }

  @override
  Future<({String url, String title, String text})?> page() async {
    final c = _controller;
    if (c == null) return null;
    return _decodePage(await c.runJavaScriptReturningResult(_readPage));
  }

  @override
  Future<PageSnapshot?> snapshot() async {
    final c = _controller;
    if (c == null) return null;
    return PageSnapshot.decode(await c.runJavaScriptReturningResult(readPageScript));
  }

  @override
  Future<Uint8List?> canvasImage() async {
    final c = _controller;
    if (c == null) return null;
    return _decodeImage(await c.runJavaScriptReturningResult(canvasImageScript));
  }

  @override
  Future<Object?> fillTextBox(String selector, String text) async =>
      _controller?.runJavaScriptReturningResult(fillScript(selector, text));

  @override
  Future<void> close() async => _controller = null;
}
