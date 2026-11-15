import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/post_reminders.dart';
import '../app/providers.dart';
import '../db/database.dart';
import '../domain/bluesky.dart';
import '../domain/book.dart';
import '../domain/humanizer.dart';
import '../domain/post_plan.dart';
import 'common.dart';
import 'kit/kit.dart';
import 'look.dart';

// The post plan for the LinkedIn studio: weekly slots, a draft in each, a
// reminder when the time comes. "Copy & open LinkedIn" puts the text on
// the clipboard and opens LinkedIn's share page; the user posts there and
// marks it posted. Bluesky posts go out only when the user presses Post.

final _weekPostsProvider = FutureProvider.family<List<PlannedPost>, String>((ref, monday) {
  ref.watch(revisionProvider);
  final start = DateTime.parse(monday);
  final end = DateTime(start.year, start.month, start.day + 7).toIso8601String().substring(0, 10);
  return ref.watch(sessionProvider).book.postsBetween(monday, end);
});

final _postSlotsProvider = FutureProvider<List<PostSlot>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.postSlots();
});

/// The weekly post plan, with its slots and this week's posts.
class PostPlanner extends ConsumerStatefulWidget {
  const PostPlanner({super.key, this.clock});

  /// The time now (tests set it).
  final DateTime Function()? clock;

  @override
  ConsumerState<PostPlanner> createState() => _PostPlannerState();
}

class _PostPlannerState extends ConsumerState<PostPlanner> {
  /// Weeks from this one (0 this week, 1 next).
  var week = 0;

  DateTime get now => (widget.clock ?? DateTime.now)();
  DateTime get monday {
    final m = weekStart(now);
    return DateTime(m.year, m.month, m.day + 7 * week);
  }

  String get _mondayKey => monday.toIso8601String().substring(0, 10);

  /// A write, then the screens and the phone's reminders catch up.
  Future<void> _change(Future<void> Function(CareerBook b) write) async {
    try {
      await ref.mutate((s) => write(s.book));
      await ref.syncPostPlanReminders();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(_postSlotsProvider).value ?? const <PostSlot>[];
    return SectionCard(
      title: 'Post plan',
      hint: 'linkedin.postPlan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Subhead('Weekly slots'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final s in slots)
                InputChip(
                  label: Text(
                    '${weekdayNames[s.day - 1].substring(0, 3)} ${s.time}'
                    '${s.channel == 'bluesky' ? ' · Bluesky' : ''}',
                  ),
                  onDeleted: () => _change((b) => b.removePostSlot(s)),
                  deleteButtonTooltipMessage: 'Remove this slot',
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add slot'),
                onPressed: _addSlot,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous week',
                onPressed: week > 0 ? () => setState(() => week--) : null,
              ),
              Expanded(
                child: Text(
                  week == 0 ? 'This week' : 'Week of ${niceDate(_mondayKey)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next week',
                onPressed: week < 3 ? () => setState(() => week++) : null,
              ),
            ],
          ),
          AsyncView(
            ref.watch(_weekPostsProvider(_mondayKey)),
            builder: (posts) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            slots.isEmpty
                                ? 'Add a weekly slot, then plan the week.'
                                : 'Nothing planned for this week yet.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final p in posts) _PostTile(p, now: now, onChange: _change),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (slots.isNotEmpty)
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.event_note),
                        label: const Text('Plan this week'),
                        onPressed: () async {
                          var n = 0;
                          await _change((b) async => n = await b.planWeek(monday, now: now));
                          if (!context.mounted) return;
                          showMessage(
                            context,
                            n == 0 ? 'Every slot is planned.' : '$n post${n == 1 ? '' : 's'} planned.',
                          );
                        },
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add a post'),
                      onPressed: () => editPost(context, ref, null, now: now, onChange: _change),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSlot() async {
    var day = 2;
    var channel = 'linkedin';
    final time = TextEditingController(text: '08:30');
    await showFormDialog(
      context,
      title: 'Add a weekly slot',
      action: 'Add',
      fields: (setState) => [
        Choice<int>(
          label: 'Day',
          value: day,
          options: {for (var i = 1; i <= 7; i++) i: weekdayNames[i - 1]},
          onChanged: (v) => setState(() => day = v),
        ),
        Field(time, 'Time', hint: '08:30', helper: '24-hour clock. Weekday mornings tend to be read most.'),
        Choice<String>(
          label: 'Where',
          value: channel,
          options: const {'linkedin': 'LinkedIn', 'bluesky': 'Bluesky'},
          onChanged: (v) => setState(() => channel = v),
        ),
      ],
      onSave: () async {
        if (!RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(time.text.trim())) {
          return 'Enter the time as HH:mm, like 08:30.';
        }
        await _change((b) => b.addPostSlot((day: day, time: time.text.trim(), channel: channel)));
        return null;
      },
    );
  }
}

class _PostTile extends ConsumerWidget {
  const _PostTile(this.p, {required this.now, required this.onChange});
  final PlannedPost p;
  final DateTime now;
  final Future<void> Function(Future<void> Function(CareerBook b) write) onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = postStatus(p, now);
    final text = postText(p);
    final bluesky = p.channel == 'bluesky';
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: status == 'due' ? Status.warning.color.withValues(alpha: 0.06) : null,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(
          color: status == 'due'
              ? Status.warning.color.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                niceDateTime(p.at),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              ChannelChip(p.channel),
              StatusPill(
                switch (status) {
                  'due' => 'Due',
                  'posted' => 'Posted',
                  'skipped' => 'Skipped',
                  _ => 'Planned',
                },
                status: switch (status) {
                  'due' => Status.warning,
                  'posted' => Status.good,
                  _ => null,
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text.isNotEmpty ? text : (p.topic.isNotEmpty ? 'Topic: ${p.topic}' : 'No draft yet.'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              height: 1.4,
              color: text.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
              fontStyle: text.isEmpty ? FontStyle.italic : null,
            ),
          ),
          const SizedBox(height: 4),
          if (p.postUrl.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open the post'),
              onPressed: () => openLink(context, p.postUrl),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (status == 'planned' || status == 'due') ...[
                if (!bluesky)
                  FilledButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Copy & open LinkedIn'),
                    onPressed: text.isEmpty ? null : () => _copyAndOpen(context, ref, text),
                  )
                else
                  FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Post to Bluesky'),
                    onPressed: text.isEmpty ? null : () => _postBluesky(context, ref, text),
                  ),
                OutlinedButton(
                  onPressed: () => editPost(context, ref, p, now: now, onChange: onChange),
                  child: const Text('Edit'),
                ),
                if (!bluesky)
                  OutlinedButton(onPressed: () => _markPosted(context), child: const Text('Mark posted')),
                TextButton(onPressed: () => onChange((b) => b.skipPost(p.id)), child: const Text('Skip')),
              ] else
                TextButton(
                  onPressed: () => onChange((b) => b.reopenPost(p.id)),
                  child: const Text('Plan again'),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete this post',
                onPressed: () => onChange((b) => b.deletePost(p.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyAndOpen(BuildContext context, WidgetRef ref, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showMessage(context, 'Copied. Paste it into the LinkedIn post box, post it, then mark it posted here.');
    await openUri(context, Uri.parse(linkedInShareUrl));
  }

  Future<void> _markPosted(BuildContext context) async {
    final url = TextEditingController();
    final ok = await showFormDialog(
      context,
      title: 'Posted?',
      action: 'Mark posted',
      fields: (_) => [
        Field(url, 'Link to the post (optional)', hint: 'https://www.linkedin.com/posts/…'),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.content_paste),
            label: const Text('Paste'),
            // The clipboard is read only when the user presses Paste.
            onPressed: () async =>
                url.text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '',
          ),
        ),
      ],
      onSave: () async {
        final u = url.text.trim();
        if (u.isNotEmpty && !u.startsWith('https://')) {
          return 'Paste the post\'s https:// link, or leave it empty.';
        }
        return null;
      },
    );
    if (ok) await onChange((b) => b.markPosted(p.id, url: url.text, at: DateTime.now()));
  }

  Future<void> _postBluesky(BuildContext context, WidgetRef ref, String text) async {
    final final_ = await confirmBlueskyPost(context, text);
    if (final_ == null || !context.mounted) return;
    try {
      final url = await ref.read(blueskyProvider).post(final_);
      await onChange((b) => b.markPosted(p.id, url: url, at: DateTime.now()));
      if (context.mounted) showMessage(context, 'Posted on Bluesky.');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

/// Shows the post before it goes to Bluesky, with the humanizer offered.
/// Returns the text to post, or null.
Future<String?> confirmBlueskyPost(BuildContext context, String text) async {
  final c = TextEditingController(text: text);
  final ok = await showFormDialog(
    context,
    title: 'Post to Bluesky',
    action: 'Post',
    fields: (setState) => [
      Field(c, 'Post', lines: 5),
      Text('${c.text.trim().runes.length} of $bskyPostLimit characters'),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Run the humanizer'),
          onPressed: () => setState(() => c.text = humanize(c.text).text),
        ),
      ),
    ],
    onSave: () async {
      final t = c.text.trim();
      if (t.isEmpty) return 'Write the post first.';
      if (t.runes.length > bskyPostLimit) return 'Bluesky posts take up to $bskyPostLimit characters.';
      return null;
    },
  );
  return ok ? c.text.trim() : null;
}

/// Adds a post ([p] null) or edits one: when, where, the topic and the
/// draft, with the humanizer.
Future<void> editPost(
  BuildContext context,
  WidgetRef ref,
  PlannedPost? p, {
  required DateTime now,
  required Future<void> Function(Future<void> Function(CareerBook b) write) onChange,
}) async {
  final soon = now.add(const Duration(hours: 1));
  final when = TextEditingController(
    text: (p?.at ?? soon.toIso8601String().substring(0, 16)).replaceFirst('T', ' '),
  );
  final topic = TextEditingController(text: p?.topic ?? '');
  final body = TextEditingController(text: p?.body ?? '');
  var humanized = p?.humanized ?? '';
  // The draft the humanized text was made from: editing the draft after
  // drops it.
  var humanizedFrom = p?.body ?? '';
  var channel = p?.channel ?? 'linkedin';
  await showFormDialog(
    context,
    title: p == null ? 'Add a post' : 'Edit the post',
    fields: (setState) => [
      Field(when, 'When', hint: '2026-11-17 08:30'),
      Choice<String>(
        label: 'Where',
        value: channel,
        options: const {'linkedin': 'LinkedIn', 'bluesky': 'Bluesky'},
        onChanged: (v) => setState(() => channel = v),
      ),
      Field(topic, 'Topic', hint: 'What a records team learns in its first EPR month'),
      Field(body, 'Draft', lines: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Run the humanizer'),
          onPressed: () => setState(() {
            humanized = humanize(body.text).text;
            humanizedFrom = body.text;
          }),
        ),
      ),
      if (humanized.isNotEmpty) ...[
        const Subhead('Humanized (this is what gets posted)'),
        SelectableText(humanized),
      ],
    ],
    onSave: () async {
      final at = DateTime.tryParse(when.text.trim().replaceFirst(' ', 'T'));
      if (at == null) return 'Enter the time as YYYY-MM-DD HH:mm.';
      final stamp = at.toIso8601String().substring(0, 16);
      if (body.text.trim() != humanizedFrom.trim()) humanized = '';
      await onChange((b) async {
        if (p == null) {
          final id = await b.addPost(channel: channel, at: stamp, topic: topic.text, body: body.text);
          if (humanized.isNotEmpty) await b.editPost(id, humanized: humanized);
        } else {
          await b.editPost(
            p.id,
            topic: topic.text,
            body: body.text,
            humanized: humanized,
            at: stamp,
            channel: channel,
          );
        }
      });
      return null;
    },
  );
}
