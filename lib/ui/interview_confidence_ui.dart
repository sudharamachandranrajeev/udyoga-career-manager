/// The confidence loop on screen (interview plan I4): the one-tap nerves
/// rating, its trend, what the candidate is ready for, and the drills that
/// go to Vidya.
library;

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/interview_confidence.dart';
import '../domain/vidya_practice.dart' show VidyaPractice;
import 'common.dart';

/// "How nervous do you feel?", one tap, optional. Tapping the chosen one
/// again clears it. [onChanged] gets 1 to 5, or 0 when cleared.
class NervesRating extends StatelessWidget {
  const NervesRating({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final MapEntry(key: n, value: words) in nervesLabels.entries)
            ChoiceChip(
              label: Text('$n $words'),
              selected: value == n,
              onSelected: (_) => onChanged(value == n ? 0 : n),
            ),
        ],
      ),
      Text(
        'Optional: skip it if you like. Only you see it, as a trend on the Interview page.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// The ratings over time: before each round (filled) and after (hollow),
/// calm at the bottom.
class NervesChart extends StatelessWidget {
  const NervesChart(this.points, {super.key});
  final List<NervesPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = nervesSummary(points);
    return Semantics(
      label: 'Nerves over your last ${points.length} rated rounds. $summary',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: CustomPaint(
                painter: _NervesPainter(
                  points,
                  before: scheme.primary,
                  after: scheme.tertiary,
                  grid: scheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                _Key(color: scheme.primary, filled: true, text: 'Before'),
                _Key(color: scheme.tertiary, filled: false, text: 'After'),
                Text('Higher is more nervous', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.filled, required this.text});
  final Color color;
  final bool filled;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : null,
          border: Border.all(color: color, width: 2),
        ),
      ),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _NervesPainter extends CustomPainter {
  _NervesPainter(this.points, {required this.before, required this.after, required this.grid});
  final List<NervesPoint> points;
  final Color before, after, grid;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final w = size.width - 2 * pad, h = size.height - 2 * pad;
    double y(int n) => pad + h * (5 - n) / 4;
    double x(int i) => points.length == 1 ? size.width / 2 : pad + w * i / (points.length - 1);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var n = 1; n <= 5; n++) {
      canvas.drawLine(Offset(pad, y(n)), Offset(size.width - pad, y(n)), gridPaint);
    }
    void series(int? Function(NervesPoint p) of, Color color, {required bool filled}) {
      final line = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      Offset? last;
      for (final (i, p) in points.indexed) {
        final v = of(p);
        if (v == null) continue;
        final at = Offset(x(i), y(v));
        if (last != null) canvas.drawLine(last, at, line);
        last = at;
      }
      for (final (i, p) in points.indexed) {
        final v = of(p);
        if (v == null) continue;
        final at = Offset(x(i), y(v));
        if (filled) {
          canvas.drawCircle(at, 4, Paint()..color = color);
        } else {
          canvas.drawCircle(at, 4, line);
        }
      }
    }

    series((p) => p.after, after, filled: false);
    series((p) => p.before, before, filled: true);
  }

  @override
  bool shouldRepaint(_NervesPainter old) =>
      old.points != points || old.before != before || old.after != after;
}

final readyForProvider = FutureProvider<ReadyFor>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.readyFor();
});

final _drillsProvider =
    FutureProvider<
      ({
        List<String> questions,
        bool reappraisal,
        ({String? sent, bool added}) link,
        List<DrillResult> results,
        int readinessDrills,
      })
    >((ref) async {
      ref.watch(revisionProvider);
      final book = ref.watch(sessionProvider).book;
      return (
        questions: await book.questionsForThem(),
        reappraisal: await book.reappraisal(),
        link: await book.drillsSent(),
        results: await book.drillResults(),
        readinessDrills: (await book.vidyaReadiness()).fold(0, (n, r) => n + r.essentialGaps.length),
      );
    });

/// What the candidate can already show, before any gap (plan I4): criteria
/// evidenced, stories rehearsed, and how their nerves have gone.
class ReadyForCard extends ConsumerWidget {
  const ReadyForCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(readyForProvider).value;
    final rounds = ref.watch(practiceProvider).value ?? const [];
    final points = nervesTrend(rounds);
    final muted = Theme.of(context).textTheme.bodySmall;
    return SectionCard(
      title: 'What you\'re ready for',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ready == null)
            const LinearProgressIndicator()
          else if (ready.isEmpty && points.isEmpty)
            const Text(
              'Answer a round aloud and what you showed collects here: each criterion your answers evidenced, '
              'the stories you have rehearsed and how your nerves change.',
            )
          else ...[
            if (ready.evidenced.isNotEmpty) ...[
              const Subhead('Evidenced in your answers'),
              Bullets(ready.evidenced.take(8).toList(), icon: Icons.check, color: Status.good.color),
            ],
            if (ready.stories.isNotEmpty) ...[
              const Subhead('Stories you have rehearsed'),
              Bullets(ready.stories.take(8).toList(), icon: Icons.record_voice_over_outlined),
            ],
            if (points.isNotEmpty) ...[
              const Subhead('Nerves'),
              if (ready.nerves.isNotEmpty) Text(ready.nerves),
              const SizedBox(height: 4),
              NervesChart(points),
            ] else
              Text('Rate your nerves before and after a round to see the trend here.', style: muted),
          ],
        ],
      ),
    );
  }
}

/// The drills Vidya runs: the candidate's questions for the panel, the
/// optional reappraisal note, sending, and what Vidya says was rehearsed.
class DrillsCard extends ConsumerWidget {
  const DrillsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(_drillsProvider).value;
    final muted = Theme.of(context).textTheme.bodySmall;
    if (d == null) return const SectionCard(title: 'Drills in Vidya', child: LinearProgressIndicator());
    final rehearsed = d.results.where((r) => r.rehearsed).toList();
    return SectionCard(
      title: 'Drills in Vidya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Short cards to say aloud in Vidya: your settler answer, each story in three bullets, recovery lines '
            'for when an answer goes wrong, and your questions for them. Also the pre-interview routine and a '
            'video-setup checklist.',
          ),
          const Subhead('Your questions for them'),
          Bullets(d.questions),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit my questions'),
              onPressed: () => _editQuestions(context, ref, d.questions),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add the "I\'m excited" note'),
            subtitle: const Text(reappraisalLabel),
            value: d.reappraisal,
            onChanged: (v) => ref.mutate((s) => s.book.setReappraisal(v)),
          ),
          if (d.readinessDrills > 0)
            Text(
              d.readinessDrills == 1
                  ? 'Also 1 drill for an essential criterion Vidya counts weak or missing.'
                  : 'Also ${d.readinessDrills} drills for essential criteria Vidya counts weak or missing.',
              style: muted,
            ),
          if (d.link.sent != null)
            Text(
              'Sent ${d.link.sent!.substring(0, 10)}. '
              '${d.link.added ? 'Vidya has added them.' : 'Vidya adds them when you open it and accept.'}',
              style: muted,
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.send),
              label: Text(d.link.sent == null ? 'Send drills to Vidya' : 'Send drills again'),
              onPressed: () async {
                await ref.mutate((s) => s.book.sendDrills(now: DateTime.now().toUtc().toIso8601String()));
                if (context.mounted) {
                  showMessage(context, 'Sent. Changed cards update in Vidya and keep their reviews.');
                }
              },
            ),
          ),
          if (rehearsed.isNotEmpty) ...[
            const Subhead('Rehearsed in Vidya'),
            for (final r in rehearsed.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(r.title),
                subtitle: Text(
                  [
                    'Last ${r.done}',
                    if (r.rating.isNotEmpty) 'you rated it ${r.rating}',
                    if (r.times > 1) '${r.times} times',
                  ].join(' · '),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _editQuestions(BuildContext context, WidgetRef ref, List<String> current) async {
    final field = TextEditingController(text: current.join('\n'));
    final bank = [for (final e in questionsForThemBank.entries) '${e.key}: ${e.value.join(' / ')}']
        .join('\n');
    await showFormDialog(
      context,
      title: 'Your questions for them',
      action: 'Save',
      fields: (_) => [
        Field(field, 'One per line', lines: 6, autofocus: true, helper: 'Ideas by stage:\n$bank'),
      ],
      onSave: () async {
        await ref.mutate((s) => s.book.setQuestionsForThem(field.text.split('\n')));
        return null;
      },
    );
  }
}
