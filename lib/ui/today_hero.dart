import 'package:brahma_core/brahma_core.dart' show Status;
import 'package:flutter/material.dart';

import 'kit/kit.dart';

/// The soonest date something must be done by: a saved job closing, or an
/// offer check falling due.
typedef Deadline = ({String title, String detail, String date, String when, VoidCallback open});

/// Today's hero strip: the counts that matter most, rolling to their value
/// as the data arrives, and the next deadline across the full width, ringed
/// by a moving beam.
class TodayHero extends StatelessWidget {
  const TodayHero({super.key, required this.counts, this.deadline});

  /// StatTiles. Six read best: they fill two, three or six columns.
  final List<Widget> counts;
  final Deadline? deadline;

  @override
  Widget build(BuildContext context) {
    final d = deadline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatGrid(children: counts),
          if (d != null) BorderBeam(child: _DeadlineCard(d)),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard(this.d);
  final Deadline d;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StatCard(
      label: 'Next deadline',
      icon: Icons.hourglass_bottom,
      onTap: d.open,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(d.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // "in 3 days" stays short on a phone; the date is on hover.
          Tooltip(
            message: d.date,
            child: StatusPill(d.when, status: Status.warning, icon: Icons.schedule),
          ),
        ],
      ),
    );
  }
}
