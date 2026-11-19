/// The interview's device-only settings on screen (plan I6): the local
/// model (Ollama).
library;

import 'dart:async';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/interview_providers.dart';
import '../domain/interview_plan.dart';
import '../domain/ollama.dart';
import 'common.dart';

/// "On this device": the local model for the interview's AI tasks.
class InterviewDeviceCard extends ConsumerStatefulWidget {
  const InterviewDeviceCard({super.key});

  @override
  ConsumerState<InterviewDeviceCard> createState() => _InterviewDeviceCardState();
}

class _InterviewDeviceCardState extends ConsumerState<InterviewDeviceCard> {
  final _host = TextEditingController();
  final _model = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _host.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save(InterviewDevice d) => ref.read(interviewDeviceProvider.notifier).save(d);

  Future<void> _saveFields(InterviewDevice d) async {
    await _save(d.copyWith(ollamaHost: _host.text.trim(), ollamaModel: _model.text.trim()));
    ref.invalidate(ollamaStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dev = ref.watch(interviewDeviceProvider).value;
    if (dev == null) return const SizedBox.shrink();
    if (!_filled) {
      _host.text = dev.ollamaHost;
      _model.text = dev.ollamaModel;
      _filled = true;
    }
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SectionCard(
      title: 'On this device',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use a local model (Ollama) for the interview AI'),
            subtitle: const Text(
              'Plans the follow-ups, reads adverts into criteria, scores the round and gives feedback on this '
              'computer, with nothing sent to a cloud AI.',
            ),
            value: dev.localAi,
            onChanged: (v) => unawaited(_save(dev.copyWith(localAi: v))),
          ),
          if (dev.localAi) ..._local(dev, muted),
        ],
      ),
    );
  }

  List<Widget> _local(InterviewDevice dev, TextStyle? muted) {
    final setup = ref.watch(ollamaSetupProvider).value;
    final status = ref.watch(ollamaStatusProvider);
    return [
      Text(ollamaQualityNote, style: muted),
      const Subhead('Suggested models'),
      Bullets([for (final e in ollamaSuggestions.entries) '${e.key}: ${e.value}']),
      Text(
        'Udyoga never installs Ollama or downloads a model. Get Ollama from ollama.com, then run, for '
        'example: ollama pull $ollamaDefaultModel',
        style: muted,
      ),
      const SizedBox(height: 8),
      if (setup != null && setup.fromAskAi)
        Text(
          'Using the local server from Settings → Ask AI: ${setup.host}'
          '${setup.model.isEmpty ? '' : ', model ${setup.model}'}.',
        )
      else ...[
        TextField(
          controller: _host,
          decoration: const InputDecoration(labelText: 'Ollama address', hintText: ollamaDefaultHost),
          onSubmitted: (_) => _saveFields(dev),
        ),
        const SizedBox(height: 8),
      ],
      if (setup == null || !setup.fromAskAi || setup.model.isEmpty)
        TextField(
          controller: _model,
          decoration: const InputDecoration(labelText: 'Model', hintText: ollamaDefaultModel),
          onSubmitted: (_) => _saveFields(dev),
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: status.isLoading ? null : () => _saveFields(dev),
            icon: const Icon(Icons.refresh),
            label: const Text('Check the local model'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      switch (status) {
        AsyncData(:final value?) => Semantics(
          liveRegion: true,
          child: StatusLabelWrap(value.ready ? Status.good : Status.warning, value.message),
        ),
        AsyncLoading() => const LinearProgressIndicator(),
        _ => const SizedBox.shrink(),
      },
    ];
  }
}

/// A status icon with text that wraps (StatusLabel keeps to one line).
class StatusLabelWrap extends StatelessWidget {
  const StatusLabelWrap(this.status, this.text, {super.key});
  final Status status;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        status == Status.good ? Icons.check_circle_outline : Icons.info_outline,
        color: status.color,
        size: 20,
      ),
      const SizedBox(width: 8),
      Expanded(child: SelectableText(text)),
    ],
  );
}

/// Why the interview has no AI: the key to add, or the local model's
/// state, or offline practice.
class InterviewNoAi extends ConsumerWidget {
  const InterviewNoAi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dev = ref.watch(interviewDeviceProvider).value ?? const InterviewDevice();
    if (!dev.localAi && !dev.offline) return const NeedsKey(what: 'Interview practice');
    final status = ref.watch(ollamaStatusProvider).value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StatusLabelWrap(
        Status.info,
        dev.localAi && status != null && !status.ready
            ? '${status.message} Until then the built-in follow-ups and checks on this device are used.'
            : 'Offline interview practice: the built-in follow-ups and checks on this device are used.',
      ),
    );
  }
}
