/// The interview's own choice of AI (plan I6): the cloud AI from Settings,
/// or Ollama on this computer, or none at all in offline practice when no
/// local model is ready. Every interview screen asks [interviewAdvisorProvider]
/// rather than the app-wide adviser.
library;

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/advisor.dart';
import '../domain/ai.dart';
import '../domain/interview_plan.dart';
import '../domain/ollama.dart';
import 'providers.dart';

/// The device-only interview settings.
class InterviewDeviceSettings extends AsyncNotifier<InterviewDevice> {
  @override
  Future<InterviewDevice> build() => ref.watch(sessionProvider).book.interviewDevice();

  Future<void> save(InterviewDevice d) async {
    state = AsyncData(d);
    await ref.read(sessionProvider).book.setInterviewDevice(d);
  }
}

final interviewDeviceProvider = AsyncNotifierProvider<InterviewDeviceSettings, InterviewDevice>(
  InterviewDeviceSettings.new,
);

/// Where the local model is and which one: brahma_core's Ask AI setting
/// when it is a local server, otherwise Udyoga's own.
typedef OllamaSetup = ({String host, String model, bool fromAskAi});

final ollamaSetupProvider = FutureProvider<OllamaSetup>((ref) async {
  final dev = await ref.watch(interviewDeviceProvider.future);
  HelpAiSetup? help;
  try {
    help = await ref.watch(helpAiProvider.future);
  } on Object {
    help = null;
  }
  if (help != null && help.via == HelpAi.local) {
    return (
      host: ollamaHost(help.effectiveBase),
      model: help.model.trim().isNotEmpty ? help.model.trim() : dev.ollamaModel,
      fromAskAi: true,
    );
  }
  return (host: ollamaHost(dev.ollamaHost), model: dev.ollamaModel, fromAskAi: false);
});

/// Builds the local model's client; tests point it at a fake server.
final ollamaFactoryProvider = Provider<Ollama Function(OllamaSetup)>(
  (ref) =>
      (s) => Ollama(host: s.host, model: s.model),
);

/// Whether the local model is ready, or null when it is not chosen.
final ollamaStatusProvider = FutureProvider<OllamaStatus?>((ref) async {
  final dev = await ref.watch(interviewDeviceProvider.future);
  if (!dev.localAi) return null;
  final setup = await ref.watch(ollamaSetupProvider.future);
  return ref.watch(ollamaFactoryProvider)(setup).check();
});

/// The adviser for the interview screens:
/// - the local model, when chosen and ready;
/// - nothing, when it is chosen but not ready, or in offline practice
///   (the built-in plans and the matcher on the device take over);
/// - otherwise the app-wide adviser.
final interviewAdvisorProvider = FutureProvider<Advisor?>((ref) async {
  final dev = await ref.watch(interviewDeviceProvider.future);
  if (dev.localAi) {
    final status = await ref.watch(ollamaStatusProvider.future);
    if (status == null || !status.ready) return null;
    final setup = await ref.watch(ollamaSetupProvider.future);
    return Advisor(ref.watch(ollamaFactoryProvider)(setup), today: today());
  }
  if (dev.offline) return null;
  return ref.watch(advisorProvider.future);
});

/// Shown when an interview screen has no AI, in plain words.
Future<String> interviewNoAiReason(WidgetRef ref) async {
  final dev = await ref.read(interviewDeviceProvider.future);
  if (dev.localAi) {
    final s = await ref.read(ollamaStatusProvider.future);
    if (s != null && !s.ready) return s.message;
  }
  if (dev.offline) {
    return 'Offline interview practice is on and no local model is ready, so the built-in follow-ups and '
        'checks on this device are used.';
  }
  return needsAiKey;
}

/// The interview adviser, or an error saying plainly why there is none.
Future<Advisor> requireInterviewAdvisor(WidgetRef ref) async {
  final advisor = await ref.read(interviewAdvisorProvider.future);
  if (advisor == null) throw AiException(await interviewNoAiReason(ref));
  return advisor;
}
