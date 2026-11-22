import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

export 'package:interview_engine/interview_engine.dart' show isLoopbackHost;

import 'ai.dart';
import 'json.dart';

import 'schema.dart';

/// Where Ollama listens unless the user says otherwise.
const ollamaDefaultHost = 'http://localhost:11434';

/// Small instruct models that fit a laptop, best first. Udyoga never pulls
/// one: the user runs `ollama pull <name>` if they want it.
const ollamaSuggestions = {
  'qwen2.5:7b': 'Qwen 2.5 7B Instruct: about 4.7 GB, needs about 8 GB of free memory',
  'llama3.2:3b':
      'Llama 3.2 3B Instruct: about 2 GB, for smaller machines. It reads adverts well, but scores bare claims too '
      'kindly, and each step took about a minute on a laptop processor',
};

/// The model suggested when the user names none.
const ollamaDefaultModel = 'qwen2.5:7b';

/// Said wherever the local model is offered.
const ollamaQualityNote =
    'A small model on this computer plans and scores less reliably than a large cloud model. Its scores '
    'still have to quote your own words, and any that do not are dropped.';

/// What a check of the local server found.
enum OllamaState { ready, notRunning, modelMissing, failed }

class OllamaStatus {
  const OllamaStatus(this.state, this.message, {this.models = const []});
  final OllamaState state;

  /// Plain words for the user.
  final String message;

  /// The models the server has, when it answered.
  final List<String> models;

  bool get ready => state == OllamaState.ready;
}

/// The server's address in the form the native API needs: a scheme, no
/// trailing slash, and none of the `/v1` (OpenAI-compatible) or `/api`
/// paths that settings for other tools carry. Empty means the default.
String ollamaHost(String typed) {
  var h = typed.trim();
  if (h.isEmpty) return ollamaDefaultHost;
  if (!h.contains('://')) h = 'http://$h';
  while (h.endsWith('/')) {
    h = h.substring(0, h.length - 1);
  }
  for (final tail in ['/v1', '/api']) {
    if (h.endsWith(tail)) h = h.substring(0, h.length - tail.length);
  }
  return h;
}

/// The interview AI on the user's own computer, through Ollama's native
/// API (`/api/chat`). Every answer is JSON in the given schema, enforced
/// while decoding through Ollama's `format` field and checked again here.
/// Text only: no web search, no documents, no images. Udyoga never installs,
/// starts or pulls anything: [check] says plainly what is missing.
class Ollama implements Ai {
  Ollama({String host = ollamaDefaultHost, String model = '', http.Client? client})
    : host = ollamaHost(host),
      model = model.trim().isEmpty ? ollamaDefaultModel : model.trim(),
      _http = client;

  final String host;
  @override
  final String model;
  final http.Client? _http;

  Uri _api(String path) => Uri.parse('$host/api/$path');

  /// The message when nothing answers at [host].
  String get notRunning =>
      'Ollama is not running at $host. Start it (open the Ollama app, or run "ollama serve"), then check '
      'again. Udyoga does not install or start it for you.';

  /// The message when the server has no [model].
  String get modelMissing =>
      'Ollama is running, but the model $model is not on this computer. To get it, run: ollama pull $model';

  /// Whether the server answers and has [model]. Never throws.
  Future<OllamaStatus> check({Duration timeout = const Duration(seconds: 4)}) async {
    final http.Response r;
    try {
      r = await _run((c) => c.get(_api('tags')).timeout(timeout));
    } on TimeoutException {
      return OllamaStatus(OllamaState.notRunning, notRunning);
    } on SocketException {
      return OllamaStatus(OllamaState.notRunning, notRunning);
    } on http.ClientException {
      return OllamaStatus(OllamaState.notRunning, notRunning);
    } on HandshakeException {
      return OllamaStatus(OllamaState.notRunning, notRunning);
    }
    if (r.statusCode != 200) {
      return OllamaStatus(
        OllamaState.failed,
        'Something answered at $host, but not as Ollama does (error ${r.statusCode}). Check the address.',
      );
    }
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      return OllamaStatus(OllamaState.failed, 'Something answered at $host, but not as Ollama does.');
    }
    final models = [
      for (final m in objs(obj(body)['models']))
        if (str(m['name']).isNotEmpty) str(m['name']) else if (str(m['model']).isNotEmpty) str(m['model']),
    ];
    if (!hasModel(models, model)) {
      return OllamaStatus(OllamaState.modelMissing, modelMissing, models: models);
    }
    return OllamaStatus(OllamaState.ready, 'Ollama is running with $model.', models: models);
  }

  /// Whether [name] is among [models]: a name without a tag means
  /// `:latest`, as Ollama reads it.
  static bool hasModel(List<String> models, String name) {
    String full(String n) => n.contains(':') ? n : '$n:latest';
    return models.any((m) => full(m) == full(name));
  }

  /// [web] is ignored: the local model cannot search, so it answers from
  /// what it knows. [effort] and [searches] are unused.
  @override
  Future<AiResult> ask({
    required String system,
    required List<Json> content,
    required Json schema,
    bool web = false,
    int searches = 8,
    String effort = 'high',
    int maxTokens = 32000,
    void Function(String status)? onProgress,
  }) async {
    final texts = <String>[];
    for (final b in content) {
      if (b['type'] != 'text') {
        throw AiException('The local model reads text only. Paste the text, or use a cloud AI for this.');
      }
      texts.add(str(b['text']));
    }
    final body = requestBody(system: system, user: texts.join('\n\n'), schema: schema, maxTokens: maxTokens);
    // The schema is enforced while decoding, but a small model can still
    // stop early or come back empty, so one more try.
    for (var round = 0; round < 2; round++) {
      onProgress?.call('Thinking on this computer…');
      final reply = await _post(body);
      if (str(reply['done_reason']) == 'length') {
        throw AiException('The answer was longer than allowed. Try again with less to cover.');
      }
      final data = parseReply(reply);
      if (data != null && violation(schema, data) == null) {
        final usage = AiUsage(
          input: intOf(reply['prompt_eval_count']) ?? 0,
          output: intOf(reply['eval_count']) ?? 0,
        );
        return AiResult(data, usage: usage);
      }
    }
    throw AiException(
      'The local model answered in an unexpected form. Try again, or try a larger model.',
      retryable: true,
    );
  }

  /// The `/api/chat` request: the schema in `format`, no streaming, and a
  /// low temperature so the plan and the scores stay steady.
  Json requestBody({
    required String system,
    required String user,
    required Json schema,
    int maxTokens = 8000,
  }) => {
    'model': model,
    'messages': [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ],
    'format': schema,
    'stream': false,
    'options': {'temperature': 0, 'num_ctx': 16384, 'num_predict': maxTokens.clamp(256, 8192)},
  };

  /// The JSON object in a chat reply's message, or null.
  static Json? parseReply(Json reply) {
    final text = str(obj(reply['message'])['content']).trim();
    final start = text.indexOf('{'), end = text.lastIndexOf('}');
    if (start < 0 || end < start) return null;
    try {
      final v = jsonDecode(text.substring(start, end + 1));
      return v is Map ? v.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  Future<Json> _post(Json body) async {
    final http.Response r;
    try {
      // A small model on a laptop CPU can take minutes for a whole round.
      r = await _run(
        (c) => c
            .post(_api('chat'), headers: {'content-type': 'application/json'}, body: jsonEncode(body))
            .timeout(const Duration(minutes: 10)),
      );
    } on TimeoutException {
      throw AiException('The local model did not answer in time. A smaller model may be quicker.');
    } on SocketException {
      throw AiException(notRunning);
    } on http.ClientException {
      throw AiException(notRunning);
    }
    final reply = decodeObject(utf8.decode(r.bodyBytes, allowMalformed: true));
    final error = str(reply['error']);
    if (r.statusCode == 404 || (error.contains('not found') && error.contains('model'))) {
      throw AiException(modelMissing);
    }
    if (r.statusCode != 200) {
      throw AiException('Ollama answered with error ${r.statusCode}${error.isEmpty ? '' : ': $error'}.');
    }
    return reply;
  }

  /// Runs [f] with the given client, or a fresh one closed after.
  Future<T> _run<T>(Future<T> Function(http.Client c) f) async {
    final given = _http;
    if (given != null) return f(given);
    final c = http.Client();
    try {
      return await f(c);
    } finally {
      c.close();
    }
  }
}
