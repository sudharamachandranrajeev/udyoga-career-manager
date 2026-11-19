import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/bluesky.dart';
import 'accounts_page.dart' show connectBluesky;
import 'common.dart';
import 'look.dart';

// Bluesky search for Find people: people and posts by topic, through the
// user's own signed-in account. One search per press, the first page only.
// A person is saved only when the user presses Save, with where they were
// found and the basis for contacting them.

/// People and posts on Bluesky about a topic, with Save on each person.
class BlueskySearch extends ConsumerStatefulWidget {
  const BlueskySearch({super.key});

  @override
  ConsumerState<BlueskySearch> createState() => _BlueskySearchState();
}

class _BlueskySearchState extends ConsumerState<BlueskySearch> {
  final query = TextEditingController();
  var posts = false;
  var busy = false;
  String? searched;
  List<BskyPerson> people = const [];
  List<BskyPost> found = const [];

  /// Saved this session: handle to contact id.
  final saved = <String, String>{};

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _search([String? topic]) async {
    if (topic != null) query.text = topic;
    final q = query.text.trim();
    if (q.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final b = ref.read(blueskyProvider);
      if (posts) {
        final r = await b.searchPosts(q);
        if (mounted) setState(() => found = r);
      } else {
        final r = await b.searchPeople(q);
        if (mounted) setState(() => people = r);
      }
      if (mounted) setState(() => searched = q);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save(BskyPerson p, {String sourceUrl = ''}) async {
    try {
      final id = await ref.mutate(
        (s) => saveBlueskyPerson(s.book, p, sourceUrl: sourceUrl, topic: searched ?? '', today: today()),
      );
      if (!mounted) return;
      setState(() => saved[p.handle] = id);
      showMessage(context, '${p.name} saved to Contacts.');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'People on Bluesky',
    hint: 'network.bluesky',
    child: AsyncView(
      ref.watch(blueskyAccountProvider),
      builder: (a) => a == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connect Bluesky with an app password to search people and posts by topic.'),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('Connect Bluesky'),
                  onPressed: () => connectBluesky(context, ref),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in blueskyTopics) ActionChip(label: Text(t), onPressed: () => _search(t)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: query,
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          hintText: 'health informatics <your city>',
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: busy ? null : _search, child: const Text('Search')),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('People'), icon: Icon(Icons.person_search)),
                    ButtonSegment(value: true, label: Text('Posts'), icon: Icon(Icons.article_outlined)),
                  ],
                  selected: {posts},
                  onSelectionChanged: (v) => setState(() {
                    posts = v.first;
                    searched = null;
                  }),
                ),
                if (busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                if (searched != null && !busy) ...[
                  if ((posts ? found.length : people.length) == 0)
                    const Padding(padding: EdgeInsets.only(top: 12), child: Text('Nothing found.')),
                  if (posts)
                    for (final p in found) _postTile(p)
                  else
                    for (final p in people) _personTile(p),
                ],
              ],
            ),
    ),
  );

  Widget _saveButton(BskyPerson p, {String sourceUrl = ''}) => saved.containsKey(p.handle)
      ? const Tooltip(message: 'Saved', child: Icon(Icons.check))
      : TextButton(
          onPressed: () => _save(p, sourceUrl: sourceUrl),
          child: const Text('Save'),
        );

  Widget _personTile(BskyPerson p) => _ResultTile(
    name: p.name,
    handle: p.handle,
    text: p.description.trim(),
    onTap: () => openLink(context, p.profileUrl),
    trailing: _saveButton(p),
  );

  Widget _postTile(BskyPost p) => _ResultTile(
    name: p.author.name,
    handle: p.author.handle,
    text: p.text,
    post: true,
    onTap: () => openLink(context, p.url),
    trailing: _saveButton(p.author, sourceUrl: p.url),
  );
}

/// A person or a post found: who on one line each, then a few lines of what
/// they wrote. Tapping opens it on Bluesky.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.name,
    required this.handle,
    required this.text,
    required this.onTap,
    required this.trailing,
    this.post = false,
  });
  final String name, handle, text;
  final bool post;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrgLogo(name.ifEmpty(handle), size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '@$handle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      if (text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textDirection: textDirectionOf(text),
                          style: TextStyle(height: 1.35, color: post ? null : muted),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
