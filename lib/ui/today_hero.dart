import 'package:brahma_core/brahma_core.dart' show Status;
import 'package:flutter/material.dart';

import 'kit/kit.dart';

/// The soonest date something must be done by: a saved job closing, or an
/// offer check falling due.
typedef Deadline = ({String title, String detail, String date, String when, VoidCallback open});

/// One headline count: what it counts, the number (null when there is
/// nothing to count yet, shown as a dash) and a line saying what it means.
typedef HeroCount = ({
  String label,
  int? value,
  String suffix,
  IconData icon,
  String caption,
  Status? status,
});

/// Today's hero strip: the counts that matter most, rolling to their value
/// as the data arrives, and the next deadline across the full width, ringed
/// by a moving beam.
class TodayHero extends StatelessWidget {
  const TodayHero({super.key, required this.counts, this.deadline});

  /// Six read best: they fill two, three or six columns with no gaps.
  final List<HeroCount> counts;
  final Deadline? deadline;

  /// How many tiles sit side by side at [width]: always a number the six
  /// counts divide by, so no row is left with a lone tile.
  static int columnsFor(double width) => width >= 960
      ? 6
      : width >= 480
      ? 3
      : 2;

  @override
  Widget build(BuildContext context) {
    final d = deadline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final cols = columnsFor(box.maxWidth);
              return Column(
                children: [
                  for (var row = 0; row * cols < counts.length; row++)
                    Padding(
                      padding: EdgeInsets.only(top: row == 0 ? 0 : 12),
                      // Tiles in a row share the tallest one's height, and no
                      // more: no blank space under short tiles.
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = row * cols; i < (row + 1) * cols; i++) ...[
                              if (i > row * cols) const SizedBox(width: 12),
                              Expanded(child: i < counts.length ? _Count(counts[i]) : const SizedBox()),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (d != null) ...[const SizedBox(height: 12), BorderBeam(child: _DeadlineCard(d))],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.icon, required this.child, this.onTap});
  final String label;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
    return SpotlightCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: body),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.c);
  final HeroCount c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1);
    final v = c.value;
    final shown = v == null ? 'none yet' : RollingNumber.format(v, suffix: c.suffix);
    return Semantics(
      label: '${c.label}: $shown. ${c.caption}',
      excludeSemantics: true,
      child: _Tile(
        label: c.label,
        icon: c.icon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A huge count shrinks to fit rather than spilling out.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: v == null ? Text('–', style: style) : RollingNumber(v, suffix: c.suffix, style: style),
            ),
            const SizedBox(height: 4),
            c.status == null
                ? Text(c.caption, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)
                : StatusPill(c.caption, status: c.status),
          ],
        ),
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
    return _Tile(
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
