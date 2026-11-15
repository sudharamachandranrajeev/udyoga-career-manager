import 'package:brahma_core/brahma_core.dart' show Status;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadBadge;

/// A small rounded label with a coloured dot: "Shortlisted", "Closes in 3
/// days". The dot and an optional icon mean the state never rests on colour
/// alone.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.status, this.icon, this.dot = true});
  final String label;

  /// The tone; none (or info) reads as neutral.
  final Status? status;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tone = status == null || status == Status.info ? null : status!.color;
    final fg = tone ?? theme.colorScheme.onSurfaceVariant;
    final bg = tone?.withValues(alpha: dark ? 0.18 : 0.1) ?? theme.colorScheme.surfaceContainerHighest;
    return ShadBadge(
      backgroundColor: bg,
      hoverBackgroundColor: bg,
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      shape: StadiumBorder(
        side: BorderSide(color: tone?.withValues(alpha: 0.3) ?? theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 13, color: fg),
            )
          else if (dot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: tone ?? fg, shape: BoxShape.circle),
            ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
