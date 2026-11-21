/// What Vidya asked to practise, on the Interview page, and Vidya's
/// readiness for a role, where the role is prepared for.
library;

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/vidya_practice.dart';
import 'common.dart';
import 'interview_device_ui.dart' show StatusLabelWrap;
import 'spoken_round_page.dart';

/// The requests from Vidya not practised here yet, newest first.
final pendingPractiseProvider = FutureProvider<List<PractiseRequest>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.pendingPractiseRequests();
});

/// Vidya's readiness for a role's plan, null until Vidya reports on it.
final roleReadinessProvider = FutureProvider.family<VidyaReadiness?, String>((ref, role) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.roleReadiness(role);
});

/// Runs [r] as a one-question spoken round, then sends the score to Vidya.
Future<void> practiseForVidya(BuildContext context, WidgetRef ref, PractiseRequest r) async {
  final id = await ref.mutate((s) => s.book.startVidyaPractice(r, at: nowLocal()));
  if (!context.mounted) return;
  await openSpokenRound(context, id);
  final result = await ref.mutate(
    (s) => s.book.recordVidyaPractice(id, now: DateTime.now().toUtc().toIso8601String()),
  );
  if (!context.mounted) return;
  showMessage(
    context,
    result == null
        ? 'Nothing was answered, so no score went to Vidya. Try it again when you are ready.'
        : 'Scored ${_num(result.score)} of ${_num(result.max)}. Vidya shows it on the drill after the next sync.',
  );
}

String _num(num n) => n % 1 == 0 ? '${n.toInt()}' : n.toStringAsFixed(1);

/// The drills Vidya asked to practise here. Hidden when there are none.
class PractiseRequestsCard extends ConsumerWidget {
  const PractiseRequestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingPractiseProvider).value ?? const <PractiseRequest>[];
    if (pending.isEmpty) return const SizedBox.shrink();
    final muted = Theme.of(context).textTheme.bodySmall;
    return SectionCard(
      title: 'From Vidya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Each runs as a one-question round aloud. The score goes back to Vidya through your own sync.',
            style: muted,
          ),
          for (final r in pending.take(5))
            ListTile(
              key: ValueKey('vidya.request.${r.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined),
              title: Text('Vidya asked you to practise: ${r.question}'),
              subtitle: Text(
                [
                  if (r.criterion.isNotEmpty) 'Tests: ${r.criterion}',
                  if (r.role.isNotEmpty) r.role,
                  if (r.askedDay.isNotEmpty) 'asked ${niceDate(r.askedDay)}',
                ].join(' · '),
              ),
              trailing: const Icon(Icons.mic_none),
              onTap: () => practiseForVidya(context, ref, r),
            ),
          if (pending.length > 5) Text('And ${pending.length - 5} more.', style: muted),
        ],
      ),
    );
  }
}

/// "Vidya readiness: 2 weak, 1 missing" for [role], with how many become
/// drill cards. Nothing until Vidya has reported on the role's plan.
class RoleReadinessLine extends ConsumerWidget {
  const RoleReadinessLine(this.role, {super.key});
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (role.trim().isEmpty) return const SizedBox.shrink();
    final r = ref.watch(roleReadinessProvider(role)).value;
    if (r == null) return const SizedBox.shrink();
    final drills = r.essentialGaps.length;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: StatusLabelWrap(
        r.rows.isEmpty ? Status.good : (r.missing > 0 ? Status.warning : Status.info),
        [
          r.text,
          if (drills > 0)
            '${drills == 1 ? '1 essential criterion becomes an interview drill' : '$drills essential criteria become interview drills'} '
                'in your next drills send to Vidya',
        ].join(' · '),
      ),
    );
  }
}
