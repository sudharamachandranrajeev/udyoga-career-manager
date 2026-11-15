import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/conversations.dart';
import '../domain/countries.dart';
import '../domain/humanizer.dart';
import '../domain/pipeline.dart';
import 'accounts_page.dart';
import 'common.dart';

// Conversations: one list of every thread, the channel always shown, and a
// thread view with a composer. Udyoga never sends on LinkedIn or reads its
// pages: the user copies the text, sends it themselves, then logs it. The
// clipboard is only read when the user presses Paste.
//
// Plain Material widgets, kept small and named so the look can change
// without touching the logic.

/// From this width the list and the thread sit side by side.
const _twoPaneWidth = 840.0;

/// From this width (of the thread pane) the contact panel sits beside it.
const _panelWidth = 900.0;

/// The filter chips: everything, by need, or by channel ('channel:email').
const _filters = {'all': 'All', 'needs_reply': 'Needs reply', 'follow_up': 'Follow-up due'};

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key, this.openThread});

  /// A thread to open straight away.
  final String? openThread;

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  var filter = 'all';
  var screener = false;
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.openThread;
  }

  void _open(String? id) => setState(() => selected = id);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= _twoPaneWidth;
      final list = ThreadList(
        filter: filter,
        screener: screener,
        selected: selected,
        onFilter: (f) => setState(() => filter = f),
        onScreener: (s) => setState(() => screener = s),
        onOpen: _open,
      );
      final thread = selected == null
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'Pick a conversation',
              message: 'Every message with every person, with the channel always shown.',
            )
          : ThreadView(
              key: ValueKey(selected),
              conversationId: selected!,
              onOpen: _open,
              onBack: wide ? null : () => _open(null),
            );
      return PopScope(
        canPop: wide || selected == null,
        onPopInvokedWithResult: (popped, _) {
          if (!popped) _open(null);
        },
        child: PageScaffold(
          title: 'Conversations',
          actions: [
            if ((ref.watch(mailAccountsProvider).value?.isNotEmpty ?? false) ||
                (ref.watch(blueskyAccountProvider).value?.dms ?? false))
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Check messages',
                onPressed: ref.watch(mailSyncProvider).running ? null : () => checkMailNow(context, ref),
              ),
            IconButton(
              icon: const Icon(Icons.alternate_email),
              tooltip: 'Connected accounts',
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountsPage())),
            ),
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New conversation',
              onPressed: () async {
                final id = await startConversationDialog(context, ref);
                if (id != null) _open(id);
              },
            ),
          ],
          // A floating dock covers the bottom of the shell on a phone, its
          // height arriving as bottom padding; the composer sits above it.
          body: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 380, child: list),
                      const VerticalDivider(width: 1),
                      Expanded(child: thread),
                    ],
                  )
                : selected == null
                ? list
                : thread,
          ),
        ),
      );
    },
  );
}

// ---- the list ----

/// The Inbox and Screener tabs, the filter chips and the rows.
class ThreadList extends ConsumerWidget {
  const ThreadList({
    super.key,
    required this.filter,
    required this.screener,
    required this.selected,
    required this.onFilter,
    required this.onScreener,
    required this.onOpen,
  });
  final String filter;
  final bool screener;
  final String? selected;
  final ValueChanged<String> onFilter;
  final ValueChanged<bool> onScreener;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncView(
    ref.watch(threadRowsProvider),
    builder: (rows) {
      final now = today();
      final channels = {for (final r in rows.where((r) => r.thread.contactId != null)) r.thread.channel};
      final waiting = rows.where((r) => r.thread.contactId == null).length;
      final shown = filterThreads(
        rows,
        today: now,
        screener: screener,
        filter: switch (filter) {
          'needs_reply' => ThreadFilter.needsReply,
          'follow_up' => ThreadFilter.followUpDue,
          _ => ThreadFilter.all,
        },
        channel: filter.startsWith('channel:') ? filter.substring(8) : null,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<bool>(
              segments: [
                const ButtonSegment(value: false, label: Text('Inbox'), icon: Icon(Icons.inbox_outlined)),
                ButtonSegment(
                  value: true,
                  label: Text(waiting == 0 ? 'Screener' : 'Screener ($waiting)'),
                  icon: const Icon(Icons.filter_alt_outlined),
                ),
              ],
              selected: {screener},
              onSelectionChanged: (s) => onScreener(s.first),
            ),
          ),
          if (!screener)
            ThreadFilterChips(
              filter: filter,
              channels: [
                for (final c in channelNames.keys)
                  if (channels.contains(c)) c,
              ],
              onFilter: onFilter,
            ),
          Expanded(
            child: shown.isEmpty
                ? ListView(
                    children: [
                      EmptyState(
                        icon: screener ? Icons.filter_alt_outlined : Icons.forum_outlined,
                        title: screener ? 'Nobody waiting' : 'No conversations here',
                        message: screener
                            ? 'Messages from people who are not your contacts wait here until you add them or '
                                  'ignore them.'
                            : 'Start one from a contact, or log a message you sent.',
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) => ConversationTile(
                      shown[i],
                      selected: shown[i].thread.id == selected,
                      onTap: () => onOpen(shown[i].thread.id),
                    ),
                  ),
          ),
        ],
      );
    },
  );
}

class ThreadFilterChips extends StatelessWidget {
  const ThreadFilterChips({super.key, required this.filter, required this.channels, required this.onFilter});
  final String filter;
  final List<String> channels;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in {..._filters, for (final c in channels) 'channel:$c': channelNames[c] ?? c}.entries)
          ChoiceChip(label: Text(e.value), selected: filter == e.key, onSelected: (_) => onFilter(e.key)),
      ],
    ),
  );
}

/// One row: who, where, the last message, its status and where the record
/// came from.
class ConversationTile extends StatelessWidget {
  const ConversationTile(this.row, {super.key, this.selected = false, required this.onTap});
  final ThreadRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = row.thread;
    final l = row.contact;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final role = l == null ? '' : [l.title, l.company].where((s) => s.isNotEmpty).join(' · ');
    return Material(
      color: selected ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(l?.name ?? ''),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l?.name ?? senderName(t).ifEmpty('Unknown sender'),
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(whenText(t.lastAt), style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                    if (role.isNotEmpty)
                      Text(
                        role,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ChannelLabel(t.channel, account: t.account),
                    if (row.last != null) LastMessageLine(row.last!),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: [StatusPill(row), SourceBadge(t.mode)]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "14:05" today, else "yesterday", "3 days ago".
String whenText(String at) {
  final now = today();
  final day = at.length >= 10 ? at.substring(0, 10) : now;
  return day == now && at.length >= 16 ? at.substring(11, 16) : relativeDay(day, now);
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.radius = 20});
  final String name;
  final double radius;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    child: Text(initials(name), style: TextStyle(fontSize: radius * 0.7)),
  );
}

const _channelIcons = {
  'linkedin': Icons.work_outline,
  'email': Icons.email_outlined,
  'phone': Icons.call_outlined,
  'in_person': Icons.people_outline,
  'bluesky': Icons.cloud_outlined,
  'other': Icons.chat_bubble_outline,
};

/// The channel, with the account: "Email · you@example.org".
class ChannelLabel extends StatelessWidget {
  const ChannelLabel(this.channel, {super.key, this.account = ''});
  final String channel, account;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(_channelIcons[channel] ?? Icons.chat_bubble_outline, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            channelLabel(channel, account: account),
            style: TextStyle(fontSize: 12, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The newest message: which way it went and how it starts.
class LastMessageLine extends StatelessWidget {
  const LastMessageLine(this.message, {super.key});
  final ThreadMessage message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (icon, who) = switch (message.direction) {
      'out' => (Icons.north_east, 'You: '),
      'in' => (Icons.south_west, ''),
      _ => (Icons.sticky_note_2_outlined, 'Note: '),
    };
    return Row(
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$who${message.body.replaceAll('\n', ' ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted),
          ),
        ),
      ],
    );
  }
}

/// Where the thread stands, with "needs reply" and due follow-ups picked
/// out.
class StatusPill extends StatelessWidget {
  const StatusPill(this.row, {super.key});
  final ThreadRow row;

  @override
  Widget build(BuildContext context) {
    final t = row.thread;
    final now = today();
    final (label, status) = row.needsReply
        ? ('Needs reply', Status.warning)
        : row.followUpDue(now)
        ? ('Follow up ${t.followUp == null ? 'now' : relativeDay(t.followUp!, now)}', Status.serious)
        : t.status == 'closed'
        ? ('Closed', Status.info)
        : (threadStatuses[t.status] ?? t.status, t.status == 'replied' ? Status.good : Status.info);
    return SmallPill(label, color: status.color);
  }
}

/// "Synced", "Imported" or "Logged by you": is this the real record or the
/// user's note of it?
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.mode, {super.key});
  final String mode;

  @override
  Widget build(BuildContext context) => SmallPill(
    threadSources[mode] ?? mode,
    icon: switch (mode) {
      'api' => Icons.sync,
      'import' => Icons.download_outlined,
      _ => Icons.edit_note,
    },
  );
}

/// A small rounded label.
class SmallPill extends StatelessWidget {
  const SmallPill(this.label, {super.key, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 3)],
          Text(label, style: TextStyle(fontSize: 11, color: c)),
        ],
      ),
    );
  }
}

// ---- the thread ----

/// The header, the messages, the composer and (on wide screens) the contact
/// panel.
class ThreadView extends ConsumerWidget {
  const ThreadView({super.key, required this.conversationId, required this.onOpen, this.onBack});
  final String conversationId;
  final ValueChanged<String?> onOpen;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(threadRowsProvider).value ?? const <ThreadRow>[];
    final row = rows.where((r) => r.thread.id == conversationId).firstOrNull;
    if (row == null) {
      return const EmptyState(icon: Icons.forum_outlined, title: 'This conversation is gone');
    }
    return LayoutBuilder(
      builder: (context, box) {
        final panel = box.maxWidth >= _panelWidth;
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ThreadHeader(
              row,
              onBack: onBack,
              onDetails: panel
                  ? null
                  : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (sheet) => SafeArea(
                        child: ContactPanel(
                          row,
                          onOpen: (id) {
                            Navigator.pop(sheet);
                            onOpen(id);
                          },
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1),
            Expanded(child: MessageList(conversationId)),
            const Divider(height: 1),
            // On a short screen the composer scrolls rather than squeezing
            // the messages out.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight * 0.55),
              child: SingleChildScrollView(
                child: Composer(row, key: ValueKey('composer-$conversationId'), onOpen: onOpen),
              ),
            ),
          ],
        );
        if (!panel) return column;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: column),
            const VerticalDivider(width: 1),
            SizedBox(width: 320, child: ContactPanel(row, onOpen: onOpen)),
          ],
        );
      },
    );
  }
}

/// "To Jordan Example · Practice Manager, Example Health Trust · via
/// LinkedIn message · found on ...", always, and the thread's status menu.
class ThreadHeader extends ConsumerWidget {
  const ThreadHeader(this.row, {super.key, this.onBack, this.onDetails});
  final ThreadRow row;
  final VoidCallback? onBack, onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = row.thread;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'All conversations', onPressed: onBack),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(threadHeader(t, row.contact), style: Theme.of(context).textTheme.titleSmall),
                if (t.subject.isNotEmpty)
                  Text(t.subject, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (row.contact != null)
            PopupMenuButton<String>(
              tooltip: 'Status',
              icon: const Icon(Icons.flag_outlined),
              onSelected: (v) => _setStatus(context, ref, v),
              itemBuilder: (_) => [
                for (final e in threadStatuses.entries)
                  if (e.key != 'follow_up') PopupMenuItem(value: e.key, child: Text(e.value)),
                const PopupMenuItem(value: 'follow_up', child: Text('Follow up on…')),
              ],
            ),
          if (onDetails != null)
            IconButton(icon: const Icon(Icons.info_outline), tooltip: 'Details', onPressed: onDetails),
        ],
      ),
    );
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, String status) async {
    if (status != 'follow_up') {
      await ref.mutate((s) => s.book.setThread(row.thread.id, status: status, today: today()));
      return;
    }
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    await ref.mutate(
      (s) => s.book.setThread(row.thread.id, followUp: Value(isoDate(picked)), today: today()),
    );
  }
}

class MessageList extends ConsumerWidget {
  const MessageList(this.conversationId, {super.key});
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncView(
    ref.watch(threadMessagesProvider(conversationId)),
    builder: (messages) => messages.isEmpty
        ? const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Nothing yet',
            message: 'Write below, send it yourself, then log it here.',
          )
        : ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (_, i) => MessageBubble(messages[messages.length - 1 - i]),
          ),
  );
}

/// Outgoing on the right, incoming on the left, notes in the middle. A
/// message that failed to send offers Retry.
class MessageBubble extends ConsumerWidget {
  const MessageBubble(this.message, {super.key});
  final ThreadMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final m = message;
    final (align, color, label) = switch (m.direction) {
      'out' => (
        Alignment.centerRight,
        scheme.primaryContainer,
        m.status == 'invite' ? 'Connection note' : 'You',
      ),
      'in' => (Alignment.centerLeft, scheme.surfaceContainerHighest, 'Them'),
      _ => (Alignment.center, scheme.tertiaryContainer.withValues(alpha: 0.5), 'Note'),
    };
    final source = switch (m.source) {
      'api' when m.status == 'failed' => 'Not sent',
      'api' when m.status == 'sending' => 'Sending…',
      'api' when m.status == 'sent' => 'Sent from Udyoga',
      'api' => 'Synced',
      'import' => 'Imported',
      'ai_draft' => 'AI draft',
      _ => 'Logged by you',
    };
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: m.direction == 'note' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              SelectableText(
                m.body,
                style: m.direction == 'note' ? const TextStyle(fontStyle: FontStyle.italic) : null,
              ),
              const SizedBox(height: 4),
              Text(
                '$label · ${niceDateTime(m.sentAt)} · $source',
                style: TextStyle(
                  fontSize: 11,
                  color: m.status == 'failed' ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
              if (m.source == 'api' && m.status == 'failed')
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () => _retry(context, ref),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on MessageBubble {
  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final book = ref.read(sessionProvider).book;
    final sender = senderFor(
      await book.conversation(message.conversationId),
      ref.read(channelSendersProvider),
    );
    if (!context.mounted) return;
    if (sender == null) return showMessage(context, 'Connect the account this was sent from first.');
    try {
      await ref.mutate((s) => s.book.retrySend(sender, message.id));
      if (context.mounted) showMessage(context, 'Sent.');
    } catch (e) {
      ref.changed();
      if (context.mounted) showError(context, e);
    }
  }
}

// ---- the composer ----

/// The text box and what can be done with it, by channel. Hand channels
/// (LinkedIn, phone, Bluesky until it is connected) copy the text and open
/// the page; the user sends it there and comes back to log it. E-mail with
/// no connected account opens the mail app the same way.
class Composer extends ConsumerStatefulWidget {
  const Composer(this.row, {super.key, required this.onOpen});
  final ThreadRow row;
  final ValueChanged<String?> onOpen;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final text = TextEditingController();

  /// The text copied and opened, waiting for "Did you send it?".
  String? pending;

  /// The LinkedIn message is a connection note (the pace guard counts those
  /// apart).
  var invite = false;

  /// A message is going out through a connected account.
  var sending = false;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Conversation get thread => widget.row.thread;
  Lead? get contact => widget.row.contact;

  @override
  Widget build(BuildContext context) {
    final l = contact;
    if (l == null) return ScreenerActions(widget.row, onOpen: widget.onOpen);
    if (l.doNotContact) return DoNotContactNotice(l, onLogReply: _logReply);
    final hasAi = ref.watch(advisorProvider).value != null;
    final messages = ref.watch(threadMessagesProvider(thread.id)).value ?? const <ThreadMessage>[];
    final first = !messages.any((m) => m.direction == 'out');
    final opener = howIFoundYou(l);
    final sender = senderFor(thread, ref.watch(channelSendersProvider));
    final target = sender != null ? null : openTarget(thread, l, subject: thread.subject, body: '');
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending != null)
            SentCheckBar(
              onYes: () => _log(pending!),
              onEdited: _pasteFinal,
              onNotYet: () => setState(() => pending = null),
            ),
          if (thread.channel == 'linkedin') const PaceNotice(),
          if (thread.channel == 'email' && emailKind(l.email) == 'personal') const PecrHint(),
          if (first && opener.isNotEmpty)
            OpenerHint(
              opener,
              onInsert: () =>
                  setState(() => text.text = text.text.isEmpty ? opener : '$opener\n\n${text.text}'),
            ),
          TextField(
            controller: text,
            minLines: 1,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasAi)
                OutlinedButton.icon(
                  onPressed: () => _draft(first),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Draft with AI'),
                ),
              if (thread.channel == 'linkedin')
                FilterChip(
                  label: const Text('Connection note'),
                  selected: invite,
                  onSelected: (v) => setState(() => invite = v),
                ),
              if (sender != null)
                FilledButton.icon(
                  onPressed: sending ? null : () => _send(sender, first),
                  icon: const Icon(Icons.send),
                  label: Text('Send from ${sender.account}'),
                ),
              if (target != null)
                FilledButton.icon(
                  onPressed: _copyAndOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(thread.channel == 'email' ? 'Copy & open mail' : 'Copy & open'),
                ),
              if (sender == null)
                OutlinedButton.icon(
                  onPressed: () => _log(text.text),
                  icon: const Icon(Icons.done),
                  label: const Text('Log as sent'),
                ),
              OutlinedButton.icon(
                onPressed: _logReply,
                icon: const Icon(Icons.reply),
                label: const Text('Log a reply'),
              ),
              TextButton.icon(
                onPressed: _note,
                icon: const Icon(Icons.sticky_note_2_outlined),
                label: const Text('Add note'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sends through the connected account: a subject first if an e-mail
  /// thread has none, and the PECR reminder before the first mail to a personal
  /// address. A failed send stays in the thread with Retry.
  Future<void> _send(ChannelSender sender, bool first) async {
    final body = text.text.trim();
    if (body.isEmpty) return showMessage(context, 'Write the message first.');
    final l = contact!;
    var subject = thread.subject;
    if (subject.isEmpty && thread.channel == 'email') {
      subject =
          (await pasteDialog(context, title: 'Subject', label: 'What the e-mail is about'))?.trim() ?? '';
      if (subject.isEmpty || !mounted) return;
    }
    if (first && thread.channel == 'email' && emailKind(l.email.ifEmpty(thread.peer)) == 'personal') {
      final ok = await confirm(
        context,
        title: 'Personal address',
        message:
            'This goes to ${l.name}\'s personal address. PECR consent rules apply to marketing-style or '
            'templated e-mail; keep it a one-to-one message about work.',
        action: 'Send',
      );
      if (!ok || !mounted) return;
    }
    setState(() => sending = true);
    try {
      await ref.read(sessionProvider).book.sendVia(sender, thread.id, body, at: nowLocal(), subject: subject);
      if (!mounted) return;
      text.clear();
      showMessage(context, 'Sent.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      ref.changed();
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _copyAndOpen() async {
    final body = text.text.trim();
    if (body.isEmpty) return showMessage(context, 'Write the message first.');
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    final uri = openTarget(thread, contact!, subject: thread.subject, body: body)!;
    setState(() => pending = body);
    await openUri(context, uri);
  }

  Future<void> _log(String body) async {
    if (body.trim().isEmpty) return showMessage(context, 'Write or paste what you sent first.');
    try {
      await ref.mutate((s) => s.book.logSent(thread.id, body, at: nowLocal(), invite: invite));
      if (!mounted) return;
      setState(() {
        pending = null;
        invite = false;
        text.clear();
      });
      showMessage(context, 'Logged as sent.');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pasteFinal() async {
    final body = await pasteDialog(
      context,
      title: 'What you sent',
      label: 'The final text',
      initial: pending ?? '',
    );
    if (body != null) await _log(body);
  }

  Future<void> _logReply() async {
    final body = await pasteDialog(context, title: 'Log a reply', label: 'Their reply');
    if (body == null) return;
    await ref.mutate((s) => s.book.logReply(thread.id, body, at: nowLocal()));
    if (mounted) showMessage(context, 'Reply logged.');
  }

  Future<void> _note() async {
    if (text.text.trim().isEmpty) return showMessage(context, 'Write the note in the box first.');
    await ref.mutate((s) => s.book.addNote(thread.id, text.text, at: nowLocal()));
    if (mounted) setState(text.clear);
  }

  /// The existing drafting, then the humanizer, into the box for the user
  /// to edit.
  Future<void> _draft(bool first) async {
    final l = contact!;
    final p = await ref.read(profileProvider.future);
    final job = thread.jobId ?? l.jobId;
    final j = job == null
        ? null
        : (await ref.read(jobsProvider.future)).where((x) => x.id == job).firstOrNull;
    final messages = await ref.read(threadMessagesProvider(thread.id).future);
    if (!mounted) return;
    final d = await runAi(
      context,
      title: 'Drafting',
      task: (_) async => (await requireAdvisor(ref)).draft(
        p,
        purpose: first
            ? thread.channel == 'linkedin'
                  ? 'a first message (short enough for a LinkedIn connection note, under 300 characters) '
                        'introducing the candidate and asking a specific, easy question'
                  : 'a first message introducing the candidate and asking a specific, easy question'
            : 'the next message in this conversation, answering what they last said, or a brief follow-up '
                  'adding something useful',
        context: [
          'To: ${l.name}, ${l.title} at ${l.company} (${leadKinds[l.kind] ?? l.kind})',
          'Channel: ${channelLabel(thread.channel)}',
          if (l.notes.isNotEmpty) 'Notes: ${l.notes}',
          if (j != null) 'About the job: ${j.title} at ${j.company}, ${j.url}',
          for (final m in messages.reversed.take(6).toList().reversed)
            '${m.direction == 'out'
                ? 'Candidate'
                : m.direction == 'in'
                ? l.name
                : 'Note'}: ${m.body}',
        ].join('\n'),
      ),
    );
    if (d == null || !mounted) return;
    setState(() => text.text = humanize(d.message).text);
  }
}

/// Where "Copy & open" goes: the person's LinkedIn profile (or a people
/// search), a mailto: link, a tel: link; null for channels with nowhere to
/// open (in person).
Uri? openTarget(Conversation t, Lead l, {String subject = '', String body = ''}) {
  switch (t.channel) {
    case 'linkedin':
      final url = l.linkedin.isNotEmpty ? l.linkedin : t.peer;
      if (url.startsWith('http')) return Uri.tryParse(url);
      return linkedInPeople('${l.name} ${l.company}'.trim());
    case 'email':
      final to = l.email.ifEmpty(t.peer);
      if (to.isEmpty) return null;
      final query = [
        if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
        if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
      ].join('&');
      return Uri(scheme: 'mailto', path: to, query: query.isEmpty ? null : query);
    case 'phone':
      return l.phone.isEmpty ? null : Uri(scheme: 'tel', path: l.phone);
    case 'bluesky':
      final h = t.peer.replaceFirst('@', '');
      return h.isEmpty ? null : Uri.parse('https://bsky.app/profile/$h');
  }
  return null;
}

/// A dialog with one text box and a Paste button; the clipboard is read only
/// when the user presses it.
Future<String?> pasteDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
}) async {
  final c = TextEditingController(text: initial);
  final ok = await showFormDialog(
    context,
    title: title,
    action: 'Log it',
    fields: (_) => [
      Field(c, label, lines: 5, autofocus: true),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () async {
            final clip = await Clipboard.getData(Clipboard.kTextPlain);
            if (clip?.text != null) c.text = clip!.text!;
          },
          icon: const Icon(Icons.content_paste),
          label: const Text('Paste'),
        ),
      ),
    ],
    onSave: () async => c.text.trim().isEmpty ? 'Paste or type the text.' : null,
  );
  final text = c.text.trim();
  c.dispose();
  return ok ? text : null;
}

/// "Did you send it?" after Copy & open.
class SentCheckBar extends StatelessWidget {
  const SentCheckBar({super.key, required this.onYes, required this.onEdited, required this.onNotYet});
  final VoidCallback onYes, onEdited, onNotYet;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Did you send it?', style: TextStyle(fontWeight: FontWeight.w600)),
          FilledButton(onPressed: onYes, child: const Text('Yes, log it')),
          OutlinedButton(onPressed: onEdited, child: const Text('Edited, paste final')),
          TextButton(onPressed: onNotYet, child: const Text('Not yet')),
        ],
      ),
    ),
  );
}

/// A gentle note when the user has sent a lot on LinkedIn lately. Never a
/// block.
class PaceNotice extends ConsumerWidget {
  const PaceNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(paceProvider).value;
    if (p == null || p.level == PaceLevel.calm) return const SizedBox.shrink();
    return Hint(
      icon: Icons.speed,
      color: (p.level == PaceLevel.slowDown ? Status.serious : Status.warning).color,
      text: '${p.advice} ${p.summary}',
    );
  }
}

/// E-mail to a personal address: PECR's consent rules apply to marketing.
class PecrHint extends StatelessWidget {
  const PecrHint({super.key});

  @override
  Widget build(BuildContext context) => Hint(
    icon: Icons.privacy_tip_outlined,
    color: Status.warning.color,
    text:
        'Personal address: PECR consent rules apply to marketing-style or templated e-mail. Keep this a '
        'one-to-one message about work.',
  );
}

/// The Article 14 line, offered for the first message.
class OpenerHint extends StatelessWidget {
  const OpenerHint(this.line, {super.key, required this.onInsert});
  final String line;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Say how you found them: "$line"',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        TextButton(onPressed: onInsert, child: const Text('Insert')),
      ],
    ),
  );
}

class Hint extends StatelessWidget {
  const Hint({super.key, required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

/// In place of the composer for someone who asked not to be contacted.
class DoNotContactNotice extends StatelessWidget {
  const DoNotContactNotice(this.contact, {super.key, required this.onLogReply});
  final Lead contact;
  final VoidCallback onLogReply;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(Icons.block, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${contact.name} is marked "do not contact", so Udyoga will not help you write to them. '
            'You can still log a reply they send. Clear it from their details if they ask you to get in touch.',
          ),
        ),
        TextButton(onPressed: onLogReply, child: const Text('Log a reply')),
      ],
    ),
  );
}

/// In place of the composer for an unknown sender.
class ScreenerActions extends ConsumerWidget {
  const ScreenerActions(this.row, {super.key, required this.onOpen});
  final ThreadRow row;
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Not one of your contacts.'),
        FilledButton.icon(
          onPressed: () => addFromScreenerDialog(context, ref, row.thread),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add as lead'),
        ),
        OutlinedButton(
          onPressed: () async {
            await ref.mutate((s) => s.book.ignoreScreener(row.thread.id));
            onOpen(null);
          },
          child: const Text('Ignore'),
        ),
      ],
    ),
  );
}

Future<void> addFromScreenerDialog(BuildContext context, WidgetRef ref, Conversation t) async {
  final name = TextEditingController(text: senderName(t) == t.peer ? '' : senderName(t));
  final title = TextEditingController();
  final company = TextEditingController();
  var kind = 'recruiter';
  await showFormDialog(
    context,
    title: 'Add as lead',
    fields: (setState) => [
      if (t.peer.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t.peer)),
      Field(name, 'Name', autofocus: true),
      Choice<String>(
        label: 'Who',
        value: kind,
        options: leadKinds,
        onChanged: (v) => setState(() => kind = v),
      ),
      Field(title, 'Job title'),
      Field(company, 'Organisation'),
      const Text('They got in touch with you, so that is recorded as the reason you may reply.'),
    ],
    onSave: () async {
      if (name.text.trim().isEmpty) return 'Enter a name.';
      await ref.mutate(
        (s) => s.book.addFromScreener(
          t.id,
          name: name.text,
          title: title.text,
          company: company.text,
          kind: kind,
          today: today(),
        ),
      );
      return null;
    },
  );
}

// ---- the contact panel ----

/// The person: every handle, their other threads, the linked job, where they
/// were found and on what basis, and Forget / Do not contact.
class ContactPanel extends ConsumerWidget {
  const ContactPanel(this.row, {super.key, required this.onOpen});
  final ThreadRow row;
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = row.contact;
    final t = row.thread;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (l == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          Text(
            senderName(t) == t.peer ? 'Unknown sender' : senderName(t),
            style: theme.textTheme.titleMedium,
          ),
          if (t.peer.isNotEmpty) SelectableText(t.peer),
          const SizedBox(height: 8),
          Text(
            channelLabel(t.channel, account: t.account),
            style: TextStyle(color: muted),
          ),
        ],
      );
    }
    final handles = (ref.watch(handlesProvider).value ?? const <ContactHandle>[])
        .where((h) => h.contactId == l.id)
        .toList();
    final others = (ref.watch(threadRowsProvider).value ?? const <ThreadRow>[])
        .where((r) => r.thread.contactId == l.id && r.thread.id != t.id)
        .toList();
    final jobId = t.jobId ?? l.jobId;
    final job = jobId == null
        ? null
        : (ref.watch(jobsProvider).value ?? const <Job>[]).where((j) => j.id == jobId).firstOrNull;
    final found = foundOnText(l);
    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: [
        Row(
          children: [
            InitialsAvatar(l.name, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name, style: theme.textTheme.titleMedium),
                  if (l.title.isNotEmpty || l.company.isNotEmpty)
                    Text([l.title, l.company].where((s) => s.isNotEmpty).join(', ')),
                  Text(leadKinds[l.kind] ?? l.kind, style: TextStyle(color: muted)),
                ],
              ),
            ),
          ],
        ),
        const PanelHeading('Handles'),
        if (handles.isEmpty) Text('None recorded', style: TextStyle(color: muted)),
        for (final h in handles)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(_channelIcons[h.channel] ?? Icons.alternate_email, size: 16, color: muted),
                const SizedBox(width: 8),
                Expanded(child: SelectableText(h.handle)),
                if (h.channel == 'email' && emailKind(h.handle).isNotEmpty)
                  SmallPill(emailKind(h.handle) == 'work' ? 'Work' : 'Personal'),
              ],
            ),
          ),
        const PanelHeading('Other conversations'),
        if (others.isEmpty) Text('None', style: TextStyle(color: muted)),
        for (final r in others)
          InkWell(
            onTap: () => onOpen(r.thread.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: ChannelLabel(r.thread.channel, account: r.thread.account)),
                  StatusPill(r),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () async {
            final id = await startConversationDialog(context, ref, contact: l);
            if (id != null) onOpen(id);
          },
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('New conversation'),
        ),
        const PanelHeading('Job'),
        Row(
          children: [
            Expanded(
              child: Text(
                job == null ? 'Not linked' : [job.title, job.company].where((s) => s.isNotEmpty).join(' · '),
                style: job == null ? TextStyle(color: muted) : null,
              ),
            ),
            TextButton(onPressed: () => _linkJob(context, ref), child: Text(job == null ? 'Link' : 'Change')),
          ],
        ),
        const PanelHeading('Found'),
        Text(found.isEmpty ? 'Not recorded' : found, style: found.isEmpty ? TextStyle(color: muted) : null),
        if (l.sourceUrl.isNotEmpty)
          InkWell(
            onTap: () => openLink(context, l.sourceUrl),
            child: Text(
              l.sourceUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        const PanelHeading('Basis for contact'),
        Text([lawfulBases[l.basis] ?? l.basis, l.basisNote].where((s) => s.isNotEmpty).join(': ')),
        const PanelHeading('Keep in touch'),
        Choice<int>(
          label: 'Remind me',
          value: l.keepInTouchWeeks ?? 0,
          options: {for (final e in keepInTouchChoices.entries) e.key ?? 0: e.value},
          onChanged: (v) => ref.mutate((s) => s.book.setKeepInTouch(l.id, v == 0 ? null : v, today: today())),
        ),
        const Divider(height: 24),
        ComplianceActions(l, onForgotten: () => onOpen(null)),
      ],
    );
  }

  Future<void> _linkJob(BuildContext context, WidgetRef ref) async {
    final jobs = await ref.read(jobsProvider.future);
    if (!context.mounted) return;
    var pick = row.thread.jobId ?? '';
    await showFormDialog(
      context,
      title: 'Link a job',
      fields: (setState) => [
        Choice<String>(
          label: 'Job',
          value: pick,
          options: {
            '': 'None',
            for (final j in jobs.where((j) => j.status != 'dismissed'))
              j.id: [j.title, j.company].where((s) => s.isNotEmpty).join(' · '),
          },
          onChanged: (v) => setState(() => pick = v),
        ),
      ],
      onSave: () async {
        await ref.mutate((s) => s.book.linkJob(row.thread.id, pick.isEmpty ? null : pick));
        return null;
      },
    );
  }
}

class PanelHeading extends StatelessWidget {
  const PanelHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

/// "Do not contact" and "Forget this person", for the panel and the
/// Contacts page.
class ComplianceActions extends ConsumerWidget {
  const ComplianceActions(this.contact, {super.key, this.onForgotten});
  final Lead contact;
  final VoidCallback? onForgotten;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = contact;
    final error = Theme.of(context).colorScheme.error;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => ref.mutate((s) => s.book.setDoNotContact(l.id, !l.doNotContact, today: today())),
          icon: Icon(l.doNotContact ? Icons.check_circle_outline : Icons.block),
          label: Text(l.doNotContact ? 'Allow contact again' : 'Do not contact'),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: error),
          onPressed: () async {
            final ok = await confirm(
              context,
              title: 'Forget ${l.name}?',
              message:
                  'This deletes ${l.name}, every address and profile you hold for them, and every conversation '
                  'and message, on all your devices. It cannot be undone.',
              action: 'Forget',
              destructive: true,
            );
            if (!ok) return;
            onForgotten?.call();
            await ref.mutate((s) => s.book.forgetContact(l.id));
            if (context.mounted) showMessage(context, 'Forgotten.');
          },
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Forget this person'),
        ),
      ],
    );
  }
}

/// Starts a thread with [contact] (or a contact the user picks) on a channel
/// they pick. Returns the new thread's id.
Future<String?> startConversationDialog(BuildContext context, WidgetRef ref, {Lead? contact}) async {
  final people = contact == null
      ? (await ref.read(leadsProvider.future)).where((l) => !l.doNotContact).toList()
      : [contact];
  if (!context.mounted) return null;
  if (people.isEmpty) {
    showMessage(context, 'Add a contact first, on the Contacts page.');
    return null;
  }
  var who = people.first.id;
  var channel = _defaultChannel(people.first);
  final subject = TextEditingController();
  String? id;
  await showFormDialog(
    context,
    title: 'New conversation',
    action: 'Start',
    fields: (setState) => [
      if (contact == null)
        Choice<String>(
          label: 'With',
          value: who,
          options: {for (final p in people) p.id: p.company.isEmpty ? p.name : '${p.name}, ${p.company}'},
          onChanged: (v) => setState(() {
            who = v;
            channel = _defaultChannel(people.firstWhere((p) => p.id == v));
          }),
        )
      else
        Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('With ${contact.name}')),
      Choice<String>(
        label: 'Channel',
        value: channel,
        options: channelNames,
        onChanged: (v) => setState(() => channel = v),
      ),
      if (channel == 'email') Field(subject, 'Subject (optional)'),
      if (channel == 'linkedin')
        const Text('You send LinkedIn messages yourself: Udyoga copies the text and opens the profile.'),
    ],
    onSave: () async {
      final p = people.firstWhere((p) => p.id == who);
      if (p.doNotContact) return '${p.name} asked not to be contacted.';
      id = await ref.mutate(
        (s) => s.book.startConversation(
          contactId: who,
          channel: channel,
          subject: subject.text.trim(),
          jobId: p.jobId,
          at: nowLocal(),
        ),
      );
      return null;
    },
  );
  subject.dispose();
  return id;
}

String _defaultChannel(Lead l) => l.linkedin.isNotEmpty
    ? 'linkedin'
    : l.email.isNotEmpty
    ? 'email'
    : l.phone.isNotEmpty
    ? 'phone'
    : 'linkedin';
