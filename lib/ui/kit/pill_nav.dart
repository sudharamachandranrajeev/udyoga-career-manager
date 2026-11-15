import 'package:flutter/material.dart';

import '../look.dart';
import 'glass.dart';

/// One choice in a [PillNav].
class PillNavItem<T> {
  const PillNavItem(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A frosted pill of choices with an indicator that slides to the chosen
/// one: the switch between the pages a navigation entry groups. Every
/// segment is as wide as the widest, so the indicator keeps one size. It
/// slides only when a pointer made the choice; a keyboard or a jump from
/// elsewhere moves it at once, and so does reduced motion.
class PillNav<T> extends StatefulWidget {
  const PillNav({super.key, required this.items, required this.selected, required this.onChanged});
  final List<PillNavItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<PillNav<T>> createState() => _PillNavState<T>();
}

class _PillNavState<T> extends State<PillNav<T>> {
  var _byPointer = false;
  var _slide = Duration.zero;

  @override
  void didUpdateWidget(PillNav<T> old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    _slide = _byPointer ? paced(context, Pace.base) : Duration.zero;
    _byPointer = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final n = widget.items.length;
    final index = widget.items.indexWhere((i) => i.value == widget.selected).clamp(0, n - 1);
    final onIndicator = dark ? ink : Colors.white;
    final quiet = theme.colorScheme.onSurfaceVariant;
    final label = theme.textTheme.labelLarge;
    return LayoutBuilder(
      builder: (context, box) {
        // Icons only when every segment has room for one. When even the
        // longest label does not fit its equal share, every segment shows its
        // icon alone, named by its tooltip; the page below has the title.
        final icons = box.maxWidth >= 120.0 * n + 40;
        final widest = _widestLabel(context, [for (final i in widget.items) i.label], label);
        final bare = widget.items.every((i) => i.icon != null) && box.maxWidth < (widest + 28) * n + 8;
        final segments = Row(
          children: [
            for (final (i, item) in widget.items.indexed)
              Expanded(
                child: _Segment(
                  label: item.label,
                  bare: bare,
                  icon: icons || bare ? item.icon : null,
                  selected: i == index,
                  color: i == index ? onIndicator : quiet,
                  style: label,
                  onPointer: () => _byPointer = true,
                  onTap: () {
                    if (item.value != widget.selected) widget.onChanged(item.value);
                  },
                ),
              ),
          ],
        );
        return Glass(
          padding: const EdgeInsets.all(4),
          child: IntrinsicWidth(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedAlign(
                    alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
                    duration: _slide,
                    curve: Ease.inOut,
                    child: FractionallySizedBox(
                      widthFactor: 1 / n,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: dark ? Colors.white : ink,
                        ),
                      ),
                    ),
                  ),
                ),
                segments,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The width of the longest of [labels] in [style].
double _widestLabel(BuildContext context, List<String> labels, TextStyle? style) {
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  );
  var widest = 0.0;
  for (final l in labels) {
    painter
      ..text = TextSpan(text: l, style: style)
      ..layout();
    if (painter.width > widest) widest = painter.width;
  }
  painter.dispose();
  return widest;
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.onPointer,
    this.bare = false,
    this.icon,
    this.style,
  });
  final String label;

  /// The icon alone, with the label as its tooltip.
  final bool bare;
  final IconData? icon;
  final bool selected;
  final Color color;
  final TextStyle? style;
  final VoidCallback onTap, onPointer;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: bare ? label : null,
    child: Listener(
      onPointerDown: (_) => onPointer(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: bare
              ? Tooltip(
                  message: label,
                  child: Icon(icon, size: 20, color: color),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 17, color: color), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
