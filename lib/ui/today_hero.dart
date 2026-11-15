import 'package:brahma_core/brahma_core.dart' show Status, TileGrid;
import 'package:flutter/material.dart';

import 'kit/kit.dart';

/// The soonest date something must be done by: a saved job closing, or an
/// offer check falling due.
typedef Deadline = ({String title, String detail, String date, String when, VoidCallback open});

/// Today's hero strip: the counts that matter most, rolling to their value
/// as the data arrives, and the next deadline ringed by a moving beam.
class TodayHero extends StatelessWidget {
  const TodayHero({
    super.key,
    required this.applied,
    required this.interviews,
    required this.followUps,
    this.deadline,
  });

  /// Applications sent, ever.
  final int applied;

  /// Interviews from today on.
  final int interviews;

  /// Follow-ups due today or overdue.
  final int followUps;
  final Deadline? deadline;

  @override
  Widget build(BuildContext context) {
    final d = deadline;
    return TileGrid(
      minWidth: 160,
      children: [
        _Count(
          label: 'Applied',
          value: applied,
          icon: Icons.send_outlined,
          caption: applied == 0 ? 'Nothing sent yet' : 'Applications sent',
        ),
        _Count(
          label: 'Interviews',
          value: interviews,
          icon: Icons.record_voice_over_outlined,
          caption: interviews == 0 ? 'None booked' : 'Coming up',
        ),
        _Count(
          label: 'Follow-ups due',
          value: followUps,
          icon: Icons.notifications_active_outlined,
          caption: followUps == 0 ? 'All caught up' : 'Chase them today',
          status: followUps == 0 ? null : Status.warning,
        ),
        if (d != null) BorderBeam(child: _DeadlineCard(d)),
      ],
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
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
    return SpotlightCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: body),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.value,
    required this.icon,
    required this.caption,
    this.status,
  });
  final String label, caption;
  final int value;
  final IconData icon;
  final Status? status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value. $caption',
      excludeSemantics: true,
      child: _Tile(
        label: label,
        icon: icon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RollingNumber(value, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 6),
            status == null ? Text(caption, style: t.bodySmall) : StatusPill(caption, status: status),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
          const SizedBox(height: 2),
          Text(d.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
          const SizedBox(height: 6),
          // "in 3 days" fits a phone's half-width card; the date is on hover.
          Tooltip(
            message: d.date,
            child: StatusPill(d.when, status: Status.warning, icon: Icons.schedule),
          ),
        ],
      ),
    );
  }
}
