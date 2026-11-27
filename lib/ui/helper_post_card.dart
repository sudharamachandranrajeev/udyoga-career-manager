import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/helper_posts.dart';
import '../domain/json.dart';
import 'carousel.dart';
import 'common.dart';
import 'kit/kit.dart';

/// A pill for a studio draft's hand-off state, or null when it has none
/// (or it is posted: the Posted pill says that).
StatusPill? helperPostPill(Json content) {
  final h = helperPostOf(content);
  return switch (str(h?['state'])) {
    'pending' => const StatusPill('With the helper app', status: Status.info, icon: Icons.outbox_outlined),
    'waiting' => const StatusPill('Helper: waiting', status: Status.warning),
    'posting' => const StatusPill('Posting', status: Status.info),
    'scheduled' => StatusPill(
      'Scheduled ${niceDateTime(_local(str(h?['scheduledAt'])))}',
      status: Status.good,
      icon: Icons.event,
    ),
    'failed' => const StatusPill('Helper: not posted', status: Status.serious),
    'cancelled' => const StatusPill('Cancelled in the helper app', quiet: true),
    _ => null,
  };
}

String _local(String utc) => DateTime.tryParse(utc)?.toLocal().toIso8601String().substring(0, 16) ?? utc;

/// On a finished post or carousel: posting through the helper app on this
/// computer, shown only while the hand-off is on and the helper is alive
/// and takes posts. The user checks it in the helper app and taps Post
/// there; nothing is posted from here. Otherwise copying it by hand stays
/// the way.
class HelperPostCard extends ConsumerStatefulWidget {
  const HelperPostCard(this.report, {super.key, this.slides = const []});
  final Report report;
  final List<Slide> slides;

  @override
  ConsumerState<HelperPostCard> createState() => _HelperPostCardState();
}

class _HelperPostCardState extends ConsumerState<HelperPostCard> {
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final content = decodeObject(widget.report.content);
    final h = helperPostOf(content);
    final state = str(h?['state']);
    final reason = str(h?['reason']);
    final url = str(content['postedUrl']).ifEmpty(str(h?['url']));
    final folder = ref.watch(handoffFolderProvider);
    final channel = folder == null
        ? null
        : ref.watch(helperStatusProvider).value?.usable('linkedin', DateTime.now());
    final canSend =
        channel != null && channel.posts && (state.isEmpty || state == 'failed' || state == 'cancelled');
    if (!canSend && state.isEmpty) return const SizedBox.shrink();
    final left = channel?.postBudget;
    return SectionCard(
      title: 'Helper app',
      trailing: canSend
          ? FilledButton.icon(
              key: const Key('send-post-to-helper'),
              onPressed: sending ? null : () => _send(folder!),
              icon: const Icon(Icons.outbox_outlined),
              label: const Text('Send to helper'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (state) {
            '' =>
              'The helper app on this computer can post this to LinkedIn. You check it there and tap Post; '
                  'nothing is posted from here.',
            'pending' => 'In the helper app, waiting for you to check it and tap Post.',
            'waiting' => 'The helper app is holding it.',
            'posting' => 'Being posted and checked on your profile.',
            'scheduled' =>
              'In LinkedIn\'s own scheduler for ${niceDateTime(_local(str(h?['scheduledAt'])))}.',
            'posted' => 'Posted, and seen on your profile.',
            'failed' => 'Not posted.',
            _ => 'Cancelled in the helper app.',
          }),
          if (reason.isNotEmpty) ...[const SizedBox(height: 6), StatusLabel(Status.info, reason)],
          if (left != null && left.dayLimit > 0 && canSend) ...[
            const SizedBox(height: 6),
            Text(
              'Posts left today: ${left.dayLeft} of ${left.dayLimit}; this week: ${left.weekLeft} of ${left.weekLimit}.',
            ),
          ],
          if (url.isNotEmpty)
            TextButton.icon(
              onPressed: () => openLink(context, url),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open the post'),
            ),
        ],
      ),
    );
  }

  Future<void> _send(String folder) async {
    final choice = await showDialog<({String visibility, DateTime? at})>(
      context: context,
      builder: (_) => const _SendDialog(),
    );
    if (choice == null || !mounted) return;
    setState(() => sending = true);
    try {
      final pdf = widget.slides.isEmpty
          ? null
          : await carouselPdf(widget.slides, name: (await ref.read(profileProvider.future)).name);
      await ref.mutate(
        (s) => s.book.sendPostViaHelper(
          folder,
          widget.report.id,
          now: DateTime.now(),
          visibility: choice.visibility,
          scheduleAt: choice.at,
          pdf: pdf,
          pdfTitle: widget.slides.isEmpty ? '' : widget.slides.first.title,
        ),
      );
      if (mounted) showMessage(context, 'Sent to the helper app. Check it there and tap Post.');
    } catch (e) {
      if (mounted) showMessage(context, describeError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}

class _SendDialog extends StatefulWidget {
  const _SendDialog();

  @override
  State<_SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends State<_SendDialog> {
  String visibility = 'anyone';
  DateTime? at;

  Future<void> _pick() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 30));
    if (time == null) return;
    setState(() => at = DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Send to the helper app'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who sees it'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'anyone', label: Text('Anyone')),
            ButtonSegment(value: 'connections', label: Text('Connections')),
          ],
          selected: {visibility},
          onSelectionChanged: (v) => setState(() => visibility = v.first),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Suggest a time'),
          subtitle: Text(
            at == null
                ? 'The helper app offers it; you confirm there.'
                : niceDateTime(at!.toIso8601String().substring(0, 16)),
          ),
          value: at != null,
          onChanged: (v) => v ? _pick() : setState(() => at = null),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () => Navigator.pop(context, (visibility: visibility, at: at)),
        child: const Text('Send'),
      ),
    ],
  );
}
