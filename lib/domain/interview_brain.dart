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
/// returns null), as before. The round plan carries the panel's persona:
/// for the challenging panel the engine's [personaGuidance] (its tone
/// limits) goes into the planning prompt.
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

/// What the panel chooser says about [p]: Udyoga's own line for the
/// challenging panel, the engine's for the rest.
String personaBlurb(Persona p) => switch (p.kind) {
  PersonaKind.challenging => challengingBlurb,
  _ => p.about,
};

const challengingBlurb = 'Firm panel: challenges claims, asks for evidence, interrupts politely. Never rude.';
