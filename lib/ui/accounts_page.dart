import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/bluesky.dart';
import '../domain/mail.dart';
import 'common.dart';

// Connected accounts: the user's own e-mail accounts, signed in with an
// app password. Udyoga reads only mail to or from people saved in it (and
// replies in their threads) and sends only what the user writes and sends.
// The settings stay on this device; the password stays in its keychain.
// Bluesky signs in with an app password too, for search, posting and the
// user's own DMs; its session tokens stay in the keychain.

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(mailSyncProvider);
    return PageScaffold(
      title: 'Connected accounts',
      actions: [
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'Check messages now',
          onPressed: sync.running ? null : () => checkMailNow(context, ref),
        ),
      ],
      children: [
        SectionCard(
          title: 'E-mail',
          hint:
              'Udyoga keeps only mail to or from people you saved, and replies in their threads. '
              'Everything else in your mailbox is skipped and never stored.',
          trailing: FilledButton.tonalIcon(
            icon: const Icon(Icons.add),
            label: const Text('Connect'),
            onPressed: () => connectMailAccount(context, ref),
          ),
          child: AsyncView(
            ref.watch(mailAccountsProvider),
            builder: (accounts) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (accounts.isEmpty)
                  const Text(
                    'No account yet. Connect Gmail, iCloud, Yahoo, Fastmail or any IMAP account to see '
                    'replies from your contacts in Conversations and send from Udyoga.',
                  ),
                for (final a in accounts) _AccountTile(a),
                if (sync.status.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(sync.status)),
              ],
            ),
          ),
        ),
        const BlueskyAccountCard(),
      ],
    );
  }
}

/// Checks every connected account now, and says how it went.
Future<void> checkMailNow(BuildContext context, WidgetRef ref) async {
  try {
    final r = await ref.read(mailSyncProvider.notifier).run(force: true);
    if (r != null && context.mounted) showMessage(context, ref.read(mailSyncProvider).status);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile(this.a);
  final ChannelAccount a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(mailServiceProvider);
    final last = DateTime.tryParse(a.lastSync ?? '')?.toLocal().toIso8601String();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline),
            title: Text(a.address),
            subtitle: Text(
              '${mailPresets[a.provider]?.name ?? 'IMAP'} · '
              '${last == null ? 'not checked yet' : 'checked ${niceDateTime(last.substring(0, 16))}'}',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Alert me when a saved contact writes'),
            subtitle: const Text('On Android. Nothing else in your mailbox makes an alert.'),
            value: a.notify,
            onChanged: (v) async {
              await service.saveAccount(a.copyWith(notify: v));
              ref.read(revisionProvider.notifier).bump();
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Test connection'),
                onPressed: () async {
                  try {
                    await service.test(a);
                    if (context.mounted) showMessage(context, '${a.address} signs in to read and send.');
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                onPressed: () async {
                  if (!await confirm(
                    context,
                    title: 'Disconnect ${a.address}?',
                    message:
                        'Udyoga stops reading and sending from this account and removes its password '
                        'from this device. Mail already in your conversations stays.',
                    action: 'Disconnect',
                    destructive: true,
                  )) {
                    return;
                  }
                  await service.removeAccount(a);
                  ref.read(revisionProvider.notifier).bump();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for an account and its app password, signs in to check them, and
/// saves the account.
Future<void> connectMailAccount(BuildContext context, WidgetRef ref) async {
  var provider = 'gmail';
  final address = TextEditingController();
  final name = TextEditingController();
  final password = TextEditingController();
  final imapHost = TextEditingController();
  final imapPort = TextEditingController(text: '993');
  final smtpHost = TextEditingController();
  final smtpPort = TextEditingController(text: '465');
  final service = ref.read(mailServiceProvider);

  ChannelAccount account() {
    final a = ChannelAccount.preset(provider, address.text, name: name.text);
    if (provider != 'other') return a;
    return ChannelAccount(
      provider: 'other',
      address: a.address,
      name: a.name,
      imapHost: imapHost.text.trim(),
      imapPort: intIn(imapPort) ?? 993,
      imapTls: (intIn(imapPort) ?? 993) != 143,
      smtpHost: smtpHost.text.trim(),
      smtpPort: intIn(smtpPort) ?? 465,
    );
  }

  final saved = await showFormDialog(
    context,
    title: 'Connect an e-mail account',
    action: 'Test and connect',
    fields: (setState) {
      final preset = mailPresets[provider]!;
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: provider,
            decoration: const InputDecoration(labelText: 'Provider'),
            isExpanded: true,
            items: [
              for (final p in mailPresets.values)
                DropdownMenuItem(
                  value: p.id,
                  enabled: p.id != 'outlook' || outlookReady,
                  child: Text(p.name),
                ),
            ],
            onChanged: (v) => setState(() => provider = v ?? provider),
          ),
        ),
        Field(address, 'E-mail address', hint: 'you@example.org'),
        Field(name, 'Your name on sent mail'),
        Field(password, 'App password', obscure: true),
        if (preset.passwordHelp.isNotEmpty) Text(preset.passwordHelp),
        if (preset.passwordUrl.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Make an app password'),
              onPressed: () => openLink(context, preset.passwordUrl),
            ),
          ),
        if (provider == 'other') ...[
          Field(imapHost, 'IMAP server', hint: 'imap.example.org'),
          Field(imapPort, 'IMAP port', number: true, helper: '993 for TLS, 143 for STARTTLS'),
          Field(smtpHost, 'SMTP server', hint: 'smtp.example.org'),
          Field(smtpPort, 'SMTP port', number: true, helper: '465 for TLS, 587 for STARTTLS'),
        ],
        const SizedBox(height: 8),
        const Text(
          'The password stays in this device\'s keychain and is sent only to your mail provider. '
          'Udyoga reads only mail to or from people you saved.',
        ),
      ];
    },
    onSave: () async {
      final a = account();
      if (a.problem case final p?) return p;
      if (password.text.trim().isEmpty) return 'Enter the app password.';
      await service.test(a, password: password.text);
      await service.saveAccount(a, password: password.text);
      return null;
    },
  );
  if (!saved || !context.mounted) return;
  ref.read(revisionProvider.notifier).bump();
  showMessage(context, 'Connected. Checking for mail from your contacts…');
  await checkMailNow(context, ref);
}

// ---- Bluesky ----

/// The Bluesky account: connect, what it allows, alerts and disconnect.
class BlueskyAccountCard extends ConsumerWidget {
  const BlueskyAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: 'Bluesky',
    hint:
        'Search people and posts by topic, post when you press Post, and see your direct messages with '
        'saved contacts in Conversations.',
    child: AsyncView(
      ref.watch(blueskyAccountProvider),
      builder: (a) => a == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Not connected.'),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Connect Bluesky'),
                  onPressed: () => connectBluesky(context, ref),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text('@${a.handle}'),
                  subtitle: Text(
                    a.dms
                        ? 'Search, posting and direct messages.'
                        : 'Search and posting. This app password does not allow direct messages: make one '
                              'with "Allow access to your direct messages" ticked and connect again to see them.',
                  ),
                ),
                if (a.dms)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Alert me when a saved contact sends a DM'),
                    value: a.notify,
                    onChanged: (v) async {
                      await ref.read(blueskyProvider).saveAccount(a.copyWith(notify: v));
                      ref.read(revisionProvider.notifier).bump();
                    },
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect Bluesky'),
                    onPressed: () async {
                      if (!await confirm(
                        context,
                        title: 'Disconnect @${a.handle}?',
                        message:
                            'Udyoga signs out of Bluesky on this device. Messages already in your '
                            'conversations stay.',
                        action: 'Disconnect',
                        destructive: true,
                      )) {
                        return;
                      }
                      await ref.read(blueskyProvider).signOut();
                      ref.read(revisionProvider.notifier).bump();
                    },
                  ),
                ),
              ],
            ),
    ),
  );
}

/// Signs in to Bluesky with an app password. Returns whether it worked.
Future<bool> connectBluesky(BuildContext context, WidgetRef ref) async {
  final server = TextEditingController(text: bskyService);
  final handle = TextEditingController();
  final password = TextEditingController();
  final ok = await showFormDialog(
    context,
    title: 'Connect Bluesky',
    action: 'Sign in',
    fields: (_) => [
      Field(handle, 'Handle', hint: 'you.bsky.social'),
      Field(password, 'App password', obscure: true, hint: 'abcd-efgh-ijkl-mnop'),
      const Text(appPasswordHelp),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('Make an app password'),
          onPressed: () => openLink(context, appPasswordUrl),
        ),
      ),
      Field(server, 'Server', helper: 'Change only if your account is on your own PDS.'),
      const Text(
        'Udyoga keeps the sign-in tokens in this device\'s keychain, not the password. Nothing is posted or '
        'sent unless you press Post or Send.',
      ),
    ],
    onSave: () async {
      if (handle.text.trim().isEmpty) return 'Enter your handle.';
      await ref
          .read(blueskyProvider)
          .signIn(service: server.text, identifier: handle.text, appPassword: password.text);
      return null;
    },
  );
  if (ok) ref.read(revisionProvider.notifier).bump();
  return ok;
}
