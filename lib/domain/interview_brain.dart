/// Udyoga's adapter for the interview engine's AI steps.
///
/// The engine (package interview_engine) holds the instructions and the
/// schemas; this sends them to whichever AI Udyoga is set to use (Claude,
/// Gemini, Claude Code, Codex, Ollama and the rest, all behind [Ai]).
library;

import 'package:interview_engine/interview_engine.dart';

import 'ai.dart';
import 'json.dart';

/// The interview engine's [InterviewBrain] over one of Udyoga's [Ai]
/// providers. Follow-ups stay on the device ([PromptedInterviewBrain]
/// returns null), as before.
class AiInterviewBrain extends PromptedInterviewBrain {
  const AiInterviewBrain(this.ai);
  final Ai ai;

  @override
  Future<Json> ask(BrainRequest request) async {
    final r = await ai.ask(
      system: request.system,
      content: [
        for (final t in request.texts) {'type': 'text', 'text': t},
      ],
      schema: request.schema,
      effort: request.effort,
      maxTokens: request.maxTokens,
    );
    return r.data;
  }
}
