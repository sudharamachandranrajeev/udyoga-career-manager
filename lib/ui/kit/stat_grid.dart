import 'package:brahma_core/brahma_core.dart' show Status;
import 'package:flutter/material.dart';

import 'rolling_number.dart';
import 'spotlight_card.dart';
import 'status_pill.dart';

/// Tiles in rows of equal columns, each at least [minWidth] wide. It picks a
/// column count the tiles divide into when one is near (six tiles: two,
/// three or six across), so no row is left with a lone tile; when none is,
/// the last row's tiles share its full width. Tiles in a row are as tall as
/// the tallest, and no taller.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.minWidth = 150, this.gap = 12});
  final List<Widget> children;
  final double minWidth, gap;

  /// The column count for [count] tiles at [width].
  static int columnsFor(int count, double width, {double minWidth = 150, double gap = 12}) {
    if (count == 0) return 1;
    final fit = ((width + gap) / (minWidth + gap)).floor().clamp(1, count);
    for (var c = fit; c * 2 > fit && c > 1; c--) {
      if (count % c == 0) return c;
    }
    return fit;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LayoutBuilder(
      builder: (context, box) {
        final cols = columnsFor(children.length, box.maxWidth, minWidth: minWidth, gap: gap);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < children.length; start += cols)
              Padding(
                padding: EdgeInsets.only(top: start == 0 ? 0 : gap),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = start; i < start + cols && i < children.length; i++) ...[
                        if (i > start) SizedBox(width: gap),
                        Expanded(child: children[i]),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// A tile's frame: a small labelled heading over [child], on a spotlight
/// card; tappable when [onTap] is given.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.icon, required this.child, this.onTap});
  final String label;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SpotlightCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
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
            ),
          ),
        ),
      ),
    );
  }
}

/// One headline number that rolls to its value, with a line saying what it
/// means. A null [value] (nothing to count yet) shows as a dash. A [status]
/// shows the caption as a tinted pill.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.caption,
    this.suffix = '',
    this.fractionDigits = 0,
    this.status,
  });
  final String label;
  final IconData icon;
  final num? value;
  final String? caption;
  final String suffix;
  final int fractionDigits;
  final Status? status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1);
    final v = value;
    final shown = v == null
        ? 'none yet'
        : RollingNumber.format(v, suffix: suffix, fractionDigits: fractionDigits);
    final c = caption;
    return Semantics(
      label: [label, shown, ?c].join('. '),
      excludeSemantics: true,
      child: StatCard(
        label: label,
        icon: icon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A huge count shrinks to fit rather than spilling out.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: v == null
                  ? Text('–', style: style)
                  : RollingNumber(v, suffix: suffix, fractionDigits: fractionDigits, style: style),
            ),
            if (c != null) ...[
              const SizedBox(height: 4),
              status == null
                  ? Text(c, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)
                  : StatusPill(c, status: status),
            ],
          ],
        ),
      ),
    );
  }
}
