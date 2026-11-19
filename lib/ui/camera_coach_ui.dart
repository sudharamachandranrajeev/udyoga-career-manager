/// The camera coach on screen (plan rule 4): an opt-in setup check, the
/// "Camera on" pill with one-tap off, an optional self-view and, during a
/// round, at most one gentle hint. Everything works with the camera off;
/// nothing here is needed for any other feature.
library;

import 'dart:async';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/interview_providers.dart';
import '../app/providers.dart';
import '../domain/offline_guard.dart' show offlineDownloadMessage;
import '../vision/camera_coach.dart';
import '../vision/setup_check.dart';
import '../voice/models.dart';
import 'common.dart';
import 'interview_device_ui.dart' show OfflineBadge;
import 'interview_lab_page.dart' show modelManagerProvider;

/// The device's camera for the coach; tests override it with a fake.
final coachCameraProvider = FutureProvider<CoachCamera>(
  (ref) async => NativeCoachCamera(await ref.watch(modelManagerProvider.future)),
);

const cameraPrivacy =
    'Off unless you turn it on, every time. The picture is looked at on this device and dropped: never saved, '
    'sent or synced. It checks your setup only. Nothing about your face, expression or eyes is read, and '
    'nothing is scored.';

/// The red "Camera on" pill. Tapping it turns the camera off.
class CameraOnPill extends StatelessWidget {
  const CameraOnPill(this.coach, {super.key});
  final CameraCoach coach;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Camera on. Turn the camera off',
    excludeSemantics: true,
    child: Material(
      color: Status.serious.color,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: coach.turnOff,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Camera on',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 6),
              Icon(Icons.close, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One check: a green tick when fine, otherwise the tip.
class SetupRow extends StatelessWidget {
  const SetupRow(this.r, {super.key});
  final SetupResult r;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (r.ok) {
      true => (Icons.check_circle, Status.good.color),
      false => (Icons.lightbulb_outline, Status.warning.color),
      null => (Icons.more_horiz, Status.info.color),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color, semanticLabel: r.ok == true ? 'Fine' : null),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.item.label, style: Theme.of(context).textTheme.labelLarge),
                Text(r.tip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The live picture when self-view is on, at the camera's own shape.
class CoachSelfView extends StatelessWidget {
  const CoachSelfView(this.coach, {super.key, this.height = 220});
  final CameraCoach coach;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = coach.feed?.preview();
    if (!coach.selfView || p == null) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: Center(
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: p),
      ),
    );
  }
}

/// The setup check before a round or on its own: off until turned on.
class CameraSetupCard extends ConsumerStatefulWidget {
  const CameraSetupCard(this.coach, {super.key, this.inRound = true});
  final CameraCoach coach;

  /// Offer the during-round hints (not on the stand-alone check).
  final bool inRound;

  @override
  ConsumerState<CameraSetupCard> createState() => _CameraSetupCardState();
}

class _CameraSetupCardState extends ConsumerState<CameraSetupCard> {
  double? _progress;

  Future<void> _turnOn() async {
    final cam = await ref.read(coachCameraProvider.future);
    if (!await cam.modelReady()) {
      final m = cam.model;
      if (!mounted) return;
      if (ref.read(interviewDeviceProvider).value?.offline ?? false) {
        return showMessage(context, offlineDownloadMessage);
      }
      final ok = await confirm(
        context,
        title: 'Download ${m.label}?',
        message:
            'The setup check finds where your face is in the picture with this model: ${formatBytes(m.bytes)} '
            'from ${Uri.parse(m.url).host} (${m.source}). Licence: ${m.licence}. It is checked against its '
            'published SHA-256 and kept on this device only.',
        action: 'Download ${formatBytes(m.bytes)}',
      );
      if (!ok || !mounted) return;
      setState(() => _progress = 0);
      try {
        await cam.downloadModel(progress: (s) => mounted ? setState(() => _progress = s) : null);
      } on Object catch (e) {
        if (mounted) showError(context, e);
        return;
      } finally {
        if (mounted) setState(() => _progress = null);
      }
    }
    await widget.coach.turnOn(cam);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.coach,
    builder: (context, _) {
      final c = widget.coach;
      final muted = Theme.of(context).textTheme.bodySmall;
      return SectionCard(
        title: 'Camera setup check (optional)',
        trailing: c.on ? CameraOnPill(c) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'For a video interview: checks your face is in the picture, head and shoulders fit, the light is '
              'in front of you, the camera is near eye height and the picture is steady.',
            ),
            const SizedBox(height: 4),
            Text(cameraPrivacy, style: muted),
            const SizedBox(height: 8),
            if (!c.on) ...[
              if (_progress != null)
                LinearProgressIndicator(value: _progress)
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: c.opening ? null : _turnOn,
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(c.opening ? 'Opening the camera…' : 'Turn the camera on'),
                  ),
                ),
              if (c.error case final e?) ...[
                const SizedBox(height: 8),
                Text(e, style: TextStyle(color: Status.warning.color)),
              ],
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: c.turnOff,
                    icon: const Icon(Icons.videocam_off_outlined),
                    label: const Text('Turn the camera off'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show my picture'),
                subtitle: const Text(
                  'Some people find seeing themselves distracting. The checks work either way.',
                ),
                value: c.selfView,
                onChanged: (v) => c.set(selfView: v),
              ),
              CoachSelfView(c),
              const SizedBox(height: 8),
              for (final r in c.results) SetupRow(r),
              if (c.checker.allGood)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('All set for a video interview.', style: TextStyle(color: Status.good.color)),
                ),
              if (widget.inRound) ...[
                const Subhead('During the round'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tell me if I leave the picture'),
                  subtitle: const Text('A quiet note after 3 seconds out of view.'),
                  value: c.roundHints,
                  onChanged: (v) => c.set(roundHints: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('"Looking at the lens" hint'),
                  subtitle: const Text(
                    'From where your face sits in the picture only, not your eyes. Looking at the lens is '
                    'optional: customs differ, and it is never scored.',
                  ),
                  value: c.lensHint,
                  onChanged: (v) => c.set(lensHint: v),
                ),
              ],
            ],
          ],
        ),
      );
    },
  );
}

/// During a round: the pill, the optional small self-view and the one
/// hint, if any. Nothing when the camera is off.
class CameraRoundBar extends StatelessWidget {
  const CameraRoundBar(this.coach, {super.key});
  final CameraCoach coach;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: coach,
    builder: (context, _) {
      if (!coach.on) return const SizedBox.shrink();
      final hint = coach.hint;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CameraOnPill(coach),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setup hints only. Not part of any score.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (coach.selfView) ...[const SizedBox(height: 8), CoachSelfView(coach, height: 120)],
            if (hint != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Status.info.color),
                    const SizedBox(width: 6),
                    Expanded(child: Text(hint)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// The setup check on its own, from the Interview page.
class CameraSetupPage extends ConsumerStatefulWidget {
  const CameraSetupPage({super.key});

  @override
  ConsumerState<CameraSetupPage> createState() => _CameraSetupPageState();
}

class _CameraSetupPageState extends ConsumerState<CameraSetupPage> {
  late final _coach = CameraCoach(onPrefs: (p) => unawaited(ref.read(sessionProvider).book.setCoachPrefs(p)));

  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider).book.coachPrefs().then((p) {
      if (mounted) _coach.usePrefs(p);
    }).ignore();
  }

  @override
  void dispose() {
    _coach.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Camera setup',
    actions: const [OfflineBadge()],
    children: [
      CameraSetupCard(_coach, inRound: false),
      const SectionCard(
        title: 'Without a camera check',
        child: Text(
          'Light in front of you, not behind. Head and shoulders in frame. Camera at eye height, on something '
          'steady. Looking at the lens when you make a point is optional.',
        ),
      ),
    ],
  );
}
