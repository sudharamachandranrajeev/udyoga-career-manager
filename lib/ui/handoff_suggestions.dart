import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/handoff_signals.dart';

/// Application updates from a helper app waiting for the user.
final signalSuggestionsProvider = FutureProvider<List<SignalSuggestion>>((ref) async {
  ref.watch(revisionProvider);
  final all = await ref.watch(sessionProvider).book.signalSuggestions();
  return [
    for (final s in all)
      if (s.state == 'pending') s,
  ];
});

/// Updates from a helper app (for example "Application viewed" on
/// LinkedIn) that matched no application surely enough. The user says which
/// application each is about, adds it as a new one, or dismisses it.
class SignalSuggestionsCard extends ConsumerWidget {
  const SignalSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(signalSuggestionsProvider).value ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Updates from a helper app',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('These could not be matched to an application for sure. Say which one each is about.'),
          for (final s in list) _Suggestion(s),
        ],
      ),
    );
  }
}

class _Suggestion extends ConsumerWidget {
  const _Suggestion(this.s);
  final SignalSuggestion s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = s.at.length >= 10 ? niceDate(s.at.substring(0, 10)) : s.at;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.job.label.isEmpty ? 'A job on LinkedIn' : s.job.label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text('LinkedIn: ${s.said}, $when'),
          if (s.applicationId != null) Text('Maybe your application for ${s.applicationLabel}'),
          Wrap(
            spacing: 8,
            children: [
              if (s.applicationId != null)
                FilledButton.tonal(
                  onPressed: () => ref.mutate((x) => x.book.acceptSuggestion(s.id, s.applicationId!)),
                  child: const Text('Yes, that one'),
                ),
              TextButton(
                onPressed: () => ref.mutate((x) => x.book.addSuggestionAsApplication(s.id, today: today())),
                child: const Text('Add as a new application'),
              ),
              TextButton(
                onPressed: () => ref.mutate((x) => x.book.dismissSuggestion(s.id)),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
