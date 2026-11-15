import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/bluesky.dart';
import 'accounts_page.dart' show connectBluesky;
import 'common.dart';

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
                          hintText: 'health informatics Leeds',
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

  Widget _personTile(BskyPerson p) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.person_outline),
    title: Text(p.name),
    subtitle: Text(
      ['@${p.handle}', if (p.description.trim().isNotEmpty) p.description.trim()].join('\n'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: p.description.trim().isNotEmpty,
    onTap: () => openLink(context, p.profileUrl),
    trailing: _saveButton(p),
  );

  Widget _postTile(BskyPost p) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.article_outlined),
    title: Text('${p.author.name} · @${p.author.handle}'),
    subtitle: Text(p.text, maxLines: 3, overflow: TextOverflow.ellipsis),
    isThreeLine: true,
    onTap: () => openLink(context, p.url),
    trailing: _saveButton(p.author, sourceUrl: p.url),
  );
}
