/// Interview lab (Settings > Developer): checks the interview simulator's
/// on-device stack on this device. Models are downloaded here on request;
/// the mic, voice, transcriber and camera all run locally. Nothing from
/// this page is synced, and no camera frame is stored.
library;

import 'dart:io';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interview_engine/interview_engine.dart';
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';
import 'interview_device_ui.dart' show OfflineBadge, offlinePractice;

/// Device-only: "on" shows the Developer tools (the interview lab).
const devToolsKey = 'udyoga.dev.tools';

final devToolsProvider = FutureProvider<bool>((ref) async {
  ref.watch(revisionProvider);
  return await ref.watch(sessionProvider).db.localSetting(devToolsKey) == 'on';
});

/// Where downloaded models live, never synced: on a desktop the per-user
/// folder Udyoga and Vidya share (see the interview engine's
/// [sharedModelFolder]), on a phone the app's own data folder. Models an
/// earlier Udyoga downloaded into its own folder move to the shared one
/// the first time, after their checksum check, so nothing is fetched again.
final modelManagerProvider = FutureProvider<ModelManager>((ref) async {
  final base = await getApplicationSupportDirectory();
  final own = Directory('${base.path}/models');
  final shared = sharedModelFolder();
  if (shared != null) {
    try {
      await adoptModels(from: own, to: shared);
    } on FileSystemException {
      // Left where they are; the lab offers the download again.
    }
  }
  return ModelManager(
    shared ?? own,
    client: ref.watch(httpClientProvider),
    voiceCache: Directory('${base.path}/voice-cache'),
  );
});

class InterviewLabPage extends ConsumerStatefulWidget {
  const InterviewLabPage({super.key});

  @override
  ConsumerState<InterviewLabPage> createState() => _InterviewLabPageState();
}

class _InterviewLabPageState extends ConsumerState<InterviewLabPage> {
  final _installed = <String, bool>{};
  final _onDisk = <String, int>{};
  final _progress = <String, double>{};
  String _transcriber = defaultTranscriber;
  int _retired = 0, _cached = 0;
  InterviewLab? _lab;
  LabResult? _result;
  FaceCamera? _camera;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _camera?.close();
    _lab?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final mm = await ref.read(modelManagerProvider.future);
    for (final m in speechModels) {
      _installed[m.id] = await mm.installed(m);
      _onDisk[m.id] = await mm.sizeOnDisk(m);
    }
    _retired = await mm.retiredBytes();
    _cached = await mm.voiceCacheBytes();
    if (mounted) setState(() {});
  }

  Future<void> _download(SpeechModel m) async {
    final ok = await confirm(
      context,
      title: 'Download ${m.label}?',
      message:
          '${formatBytes(m.bytes)} from ${Uri.parse(m.url).host} (${m.source}). Licence: ${m.licence}. '
          'It is checked against its published SHA-256 and kept on this device only.',
      action: 'Download ${formatBytes(m.bytes)}',
    );
    if (!ok || !mounted) return;
    final mm = await ref.read(modelManagerProvider.future);
    setState(() => _progress[m.id] = 0);
    try {
      await mm.download(
        m,
        onProgress: (got, total) {
          if (mounted) setState(() => _progress[m.id] = got / total);
        },
      );
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      _progress.remove(m.id);
      await _refresh();
    }
  }

  Future<void> _delete(SpeechModel m) async {
    final mm = await ref.read(modelManagerProvider.future);
    await mm.delete(m);
    await _refresh();
  }

  bool _has(String id) => _installed[id] ?? false;

  Future<void> _runSpeech() async {
    final mm = await ref.read(modelManagerProvider.future);
    final voice = speechModel(voiceModelId), vad = speechModel(vadModelId);
    final ears = speechModel(_transcriber);
    final lab = _lab ??= InterviewLab(
      recorder: RecordMic(),
      detector: SileroVad(mm.path(vad)),
      transcriber: MoonshineTranscriber(mm.folder(ears), ears.id),
      speaker: KokoroSpeaker(mm.folder(voice)),
    );
    final sub = lab.changes.listen((_) {
      if (mounted) setState(() {});
    });
    try {
      final r = await lab.run();
      if (mounted) setState(() => _result = r);
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _toggleCamera() async {
    if (_camera case final cam?) {
      setState(() => _camera = null);
      await cam.close();
      return;
    }
    final mm = await ref.read(modelManagerProvider.future);
    setState(() => _opening = true);
    try {
      final cam = await FaceCamera.open(mm.path(speechModel(faceModelId)));
      if (mounted) {
        setState(() => _camera = cam);
      } else {
        await cam.close();
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  static String _ms(Duration d) => '${d.inMilliseconds} ms';

  @override
  Widget build(BuildContext context) {
    final lab = _lab;
    final speechReady = _has(voiceModelId) && _has(vadModelId) && _has(_transcriber);
    final r = _result;
    return PageScaffold(
      title: 'Interview lab',
      actions: const [OfflineBadge()],
      banner:
          'For testing the interview simulator\'s speech and camera on this device. Recordings stay in memory; '
          'camera frames are looked at and dropped, never stored.',
      children: [
        SectionCard(
          title: 'Models',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nothing is included with Udyoga. Download what you want to test; delete it any time.',
              ),
              if (offlinePractice(ref))
                Text(offlineDownloadMessage, style: TextStyle(color: Status.warning.color)),
              for (final m in speechModels)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.label),
                  subtitle: _progress.containsKey(m.id)
                      ? LinearProgressIndicator(value: _progress[m.id])
                      : Text(
                          _has(m.id)
                              ? 'On this device: ${formatBytes(_onDisk[m.id] ?? 0)} · ${m.licence}'
                              : 'Download ${formatBytes(m.bytes)} · ${m.licence}',
                        ),
                  trailing: _progress.containsKey(m.id)
                      ? null
                      : _has(m.id)
                      ? TextButton(onPressed: () => _delete(m), child: const Text('Delete'))
                      : offlinePractice(ref)
                      ? null
                      : TextButton(onPressed: () => _download(m), child: const Text('Download')),
                ),
              if (_cached > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Voice cache'),
                  subtitle: Text(
                    'The interviewer\'s fixed lines, made once so a round starts sooner: '
                    '${formatBytes(_cached)}. Made again when needed.',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await (await ref.read(modelManagerProvider.future)).clearVoiceCache();
                      await _refresh();
                    },
                    child: const Text('Clear voice cache'),
                  ),
                ),
              if (_retired > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Models this version no longer uses (Whisper)'),
                  subtitle: Text('On this device: ${formatBytes(_retired)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      await (await ref.read(modelManagerProvider.future)).deleteRetired();
                      await _refresh();
                    },
                    child: const Text('Delete'),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Speech',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Records 10 seconds from the microphone, finds the speech, writes it down, then the interviewer '
                'voice reads a sentence aloud.',
              ),
              DropdownButton<String>(
                value: _transcriber,
                items: const [
                  DropdownMenuItem(value: 'moonshine-base-en', child: Text('Moonshine base')),
                  DropdownMenuItem(value: 'moonshine-tiny-en', child: Text('Moonshine tiny (lighter)')),
                ],
                onChanged: lab?.busy ?? false
                    ? null
                    : (v) => setState(() {
                        _transcriber = v!;
                        _lab = null;
                      }),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: !speechReady || (lab?.busy ?? false) ? null : _runSpeech,
                  icon: const Icon(Icons.mic_none),
                  label: Text(switch (lab?.step) {
                    LabStep.recording => 'Recording… speak now',
                    LabStep.detecting => 'Finding speech…',
                    LabStep.transcribing => 'Writing it down…',
                    LabStep.speaking => 'Speaking…',
                    _ => 'Run the speech test',
                  }),
                ),
              ),
              if (!speechReady)
                const Text('Download the voice, the speech detector and the chosen transcriber first.'),
              if (lab?.step == LabStep.recording) Text('Input level: ${lab!.level.toStringAsFixed(0)} dBFS'),
              if (r != null) ...[
                if (r.error != null) Text('Stopped at ${r.failedAt?.name}: ${r.error}'),
                if (r.audio != null)
                  Text(
                    'Speech found: ${r.spans.length} stretch(es), ${_ms(r.speechTotal)} of '
                    '${_ms(r.audio!.length)}.',
                  ),
                if (r.transcript case final t?)
                  Text(
                    t.text.isEmpty ? 'No speech to write down.' : 'Transcript (${_ms(t.took)}): ${t.text}',
                  ),
                if (r.speech case final s?)
                  Text(
                    'Voice: loaded in ${_ms(s.load)}, first audio after ${_ms(s.firstAudio)}, '
                    '${_ms(s.audio)} of speech made in ${_ms(s.synthesis)}.',
                  ),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Camera',
          trailing: _camera == null
              ? null
              : const Chip(
                  avatar: Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                  label: Text('Camera on'),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Opens the camera and draws a box round a face. Only the box is worked out; nothing is kept.',
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: !_has('blazeface-short-range') || _opening ? null : _toggleCamera,
                  icon: Icon(_camera == null ? Icons.videocam_outlined : Icons.videocam_off_outlined),
                  label: Text(_camera == null ? 'Turn the camera on' : 'Turn the camera off'),
                ),
              ),
              if (_camera case final cam?) ...[
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: cam.fps,
                  builder: (context, fps, _) => Text(
                    'Face finder: ${fps.toStringAsFixed(1)} frames a second, '
                    '${cam.detectMs.value.toStringAsFixed(1)} ms a frame',
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AspectRatio(
                    aspectRatio: cam.controller.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        cam.controller.buildPreview(),
                        ValueListenableBuilder(
                          valueListenable: cam.boxes,
                          builder: (context, boxes, _) => CustomPaint(painter: _FacePainter(boxes)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.boxes);
  final List<FaceBox> boxes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;
    for (final b in boxes) {
      canvas.drawRect(
        Rect.fromLTWH(b.left * size.width, b.top * size.height, b.width * size.width, b.height * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.boxes != boxes;
}
