/// The interview's device-only settings on screen (plan I6): offline
/// practice, live captions and the local model (Ollama).
library;

import 'dart:async';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/interview_providers.dart';
import '../domain/interview_plan.dart';
import '../domain/offline_guard.dart';
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
            title: const Text('Offline interview practice'),
            subtitle: const Text(
              'Uses only what is on this device: the voice, the speech detector, the transcriber, the face '
              'finder and, when it is running here, Ollama. Without Ollama the built-in follow-ups and checks '
              'are used. Nothing from the interview screens goes to the network, and models cannot be '
              'downloaded while it is on. Ollama itself can still contact ollama.com: to stop its cloud '
              'features, start Ollama with OLLAMA_NO_CLOUD=1 (or put "disable_ollama_cloud": true in '
              '~/.ollama/server.json) and restart it.',
            ),
            value: dev.offline,
            onChanged: (v) => unawaited(_save(dev.copyWith(offline: v))),
          ),
          if (dev.offline && !dev.localAi)
            switch (ref.watch(ollamaStatusProvider)) {
              AsyncData(:final value?) => StatusLabelWrap(
                value.ready ? Status.good : Status.info,
                value.ready
                    ? '${value.message} It plans, scores and gives feedback offline.'
                    : '${value.message} Until then the built-in follow-ups and checks are used.',
              ),
              _ => const SizedBox.shrink(),
            },
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Live captions'),
            subtitle: const Text(
              'Your words appear as you speak, and the panel\'s words as they are said. Made on this device.',
            ),
            value: dev.captions,
            onChanged: (v) => unawaited(_save(dev.copyWith(captions: v))),
          ),
          if (dev.captions) ...[
            Text('Caption text size: ${(dev.captionScale * 100).round()}%'),
            Slider(
              value: dev.captionScale,
              min: InterviewDevice.minScale,
              max: InterviewDevice.maxScale,
              divisions: 8,
              label: '${(dev.captionScale * 100).round()}%',
              semanticFormatterCallback: (v) => 'Caption text size ${(v * 100).round()} percent',
              onChanged: (v) => unawaited(_save(dev.copyWith(captionScale: v))),
            ),
            LiveCaption(speaker: 'Example', text: 'This is how captions look.', scale: dev.captionScale),
            const SizedBox(height: 8),
          ],
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
    final why = status != null && !status.ready ? '${status.message} ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StatusLabelWrap(
        Status.info,
        dev.offline
            ? 'Offline interview practice. ${why}The built-in follow-ups and checks on this device are used.'
            : '${why}Until then the built-in follow-ups and checks on this device are used.',
      ),
    );
  }
}

/// A live caption: who is speaking and the words so far, in the user's
/// caption size, newest words kept in view. Screen readers hear it as a
/// live region.
class LiveCaption extends StatelessWidget {
  const LiveCaption({super.key, required this.speaker, required this.text, this.scale = 1.25});
  final String speaker;
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final size = (base.fontSize ?? 16) * scale;
    return Semantics(
      liveRegion: true,
      label: '$speaker: $text',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('caption-$speaker'),
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(speaker, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size * 1.4 * 4),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  text,
                  style: base.copyWith(fontSize: size, height: 1.4, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Offline" badge for an interview screen's app bar. While it shows,
/// the screen holds the [OfflineGuard]: nothing can leave the device.
class OfflineBadge extends ConsumerStatefulWidget {
  const OfflineBadge({super.key});

  @override
  ConsumerState<OfflineBadge> createState() => _OfflineBadgeState();
}

class _OfflineBadgeState extends ConsumerState<OfflineBadge> {
  bool _held = false;

  void _hold(bool on) {
    if (on && !_held) OfflineGuard.instance.hold();
    if (!on && _held) OfflineGuard.instance.release();
    _held = on;
  }

  @override
  void dispose() {
    _hold(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(interviewDeviceProvider).value?.offline ?? false;
    _hold(offline);
    if (!offline) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Offline interview practice: nothing on this screen uses the network',
      child: Semantics(
        label: 'Offline interview practice is on',
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 16, color: scheme.onSecondaryContainer),
              const SizedBox(width: 6),
              Text(
                'Offline',
                style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// True while offline practice is on: downloads are refused.
bool offlinePractice(WidgetRef ref) => ref.watch(interviewDeviceProvider).value?.offline ?? false;
