import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadInput;

import '../look.dart';

/// One thing the command palette can do: open a page or run an action.
class PaletteEntry {
  const PaletteEntry({
    required this.id,
    required this.label,
    required this.icon,
    required this.onSelect,
    this.section = 'Pages',
    this.keywords = const [],
  });
  final String id;
  final String label;
  final IconData icon;

  /// Runs after the palette has closed.
  final VoidCallback onSelect;

  /// Shown beside the entry: "Pages", "Actions".
  final String section;

  /// Other words that should find it ("CV" for Profile).
  final List<String> keywords;
}

/// How well [query] matches [text], higher is better, or null when the
/// query's letters do not all appear in order. Letters next to each other,
/// letters starting a word and a matching start all count extra, so "app"
/// ranks Applications above "Map paths".
int? fuzzyScore(String query, String text) {
  final q = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (q.isEmpty) return 0;
  final t = text.toLowerCase();
  var score = 0, from = 0, last = -2;
  for (final ch in q.split('')) {
    final at = t.indexOf(ch, from);
    if (at < 0) return null;
    score += 1;
    if (at == last + 1) score += 5;
    if (at == 0 || !RegExp('[a-z0-9]').hasMatch(t[at - 1])) score += 8;
    score -= (at - from).clamp(0, 3);
    last = at;
    from = at + 1;
  }
  if (t.startsWith(q)) score += 20;
  return score;
}

/// The entries matching [query], best first; every entry, in order, for an
/// empty query. A keyword match counts a little less than one on the label.
List<PaletteEntry> filterEntries(String query, List<PaletteEntry> entries) {
  if (query.trim().isEmpty) return entries;
  final scored = <(int, int, PaletteEntry)>[];
  for (final (i, e) in entries.indexed) {
    int? best = fuzzyScore(query, e.label);
    for (final k in e.keywords) {
      final s = fuzzyScore(query, k);
      if (s != null && (best == null || s - 2 > best)) best = s - 2;
    }
    if (best != null) scored.add((best, i, e));
  }
  scored.sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2));
  return [for (final s in scored) s.$3];
}

/// Opens the palette over the current page. It appears and goes at once, with
/// no animation: it is opened from the keyboard, many times a day.
///
/// [more] adds entries for a typed query after the ones that match it, such
/// as answers from the help.
Future<void> showCommandPalette(
  BuildContext context,
  List<PaletteEntry> entries, {
  List<PaletteEntry> Function(String query)? more,
}) async {
  final chosen = await showGeneralDialog<PaletteEntry>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => CommandPalette(entries: entries, more: more),
  );
  chosen?.onSelect();
}

/// The palette: a search field over a list of pages and actions. Arrows move
/// the highlight, Enter opens it, Escape closes; typing filters as you go.
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.entries, this.more});
  final List<PaletteEntry> entries;

  /// Entries for a typed query, listed after the matching [entries].
  final List<PaletteEntry> Function(String query)? more;

  static const rowHeight = 44.0;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  late var _shown = widget.entries;
  var _at = 0;
  var _done = false;

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _filter(String q) => setState(() {
    _shown = [...filterEntries(q, widget.entries), if (q.trim().isNotEmpty) ...?widget.more?.call(q)];
    _at = 0;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  });

  void _move(int by) {
    if (_shown.isEmpty) return;
    setState(() => _at = (_at + by) % _shown.length);
    // Keep the highlight in view, at once: no scrolling animation.
    if (!_scroll.hasClients) return;
    final top = _at * CommandPalette.rowHeight;
    final view = _scroll.position.viewportDimension;
    if (top < _scroll.offset) {
      _scroll.jumpTo(top);
    } else if (top + CommandPalette.rowHeight > _scroll.offset + view) {
      _scroll.jumpTo(top + CommandPalette.rowHeight - view);
    }
  }

  void _choose([int? i]) {
    if (_done || _shown.isEmpty) return;
    _done = true;
    Navigator.of(context).pop(_shown[i ?? _at]);
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        if (e is KeyDownEvent) _choose();
      case LogicalKeyboardKey.escape:
        if (e is KeyDownEvent) Navigator.of(context).pop();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = palette(theme.brightness);
    final size = MediaQuery.sizeOf(context);
    return Align(
      alignment: const Alignment(0, -0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: size.height * 0.7),
          child: Material(
            color: p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: BorderSide(color: p.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Focus(
                    onKeyEvent: _key,
                    child: ShadInput(
                      controller: _query,
                      autofocus: true,
                      placeholder: Text(
                        widget.more == null
                            ? 'Go to a page or run an action'
                            : 'Go to a page, run an action or ask',
                      ),
                      leading: Icon(Icons.search, size: 18, color: p.muted),
                      onChanged: _filter,
                      onSubmitted: (_) => _choose(),
                    ),
                  ),
                ),
                Divider(height: 1, color: p.hairline),
                Flexible(
                  child: _shown.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Nothing matches.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.muted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(6),
                          itemExtent: CommandPalette.rowHeight,
                          itemCount: _shown.length,
                          itemBuilder: (context, i) => _Row(
                            entry: _shown[i],
                            highlighted: i == _at,
                            onHover: () {
                              if (_at != i) setState(() => _at = i);
                            },
                            onTap: () => _choose(i),
                          ),
                        ),
                ),
                Divider(height: 1, color: p.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    '↑ ↓ to move  ·  Enter to open  ·  Esc to close',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.highlighted, required this.onHover, required this.onTap});
  final PaletteEntry entry;
  final bool highlighted;
  final VoidCallback onHover, onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = palette(theme.brightness);
    return MouseRegion(
      onHover: (_) => onHover(),
      child: Semantics(
        button: true,
        selected: highlighted,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // The highlight changes at once: it follows the keyboard.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlighted ? p.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.sm - 4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(entry.icon, size: 18, color: highlighted ? p.primary : p.muted),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(entry.section, style: theme.textTheme.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the command palette on Ctrl+K (Cmd+K on a Mac) anywhere inside
/// [child], or from a [PaletteButton]. [entries] is asked for the list each
/// time it opens, so it is always current.
class CommandPaletteScope extends StatefulWidget {
  const CommandPaletteScope({super.key, required this.entries, required this.child, this.more});
  final List<PaletteEntry> Function(BuildContext context) entries;
  final List<PaletteEntry> Function(String query)? more;
  final Widget child;

  /// Opens the palette of the scope around [context]; false when there is
  /// none.
  static bool open(BuildContext context) =>
      context.findAncestorStateOfType<_CommandPaletteScopeState>()?._show() ?? false;

  @override
  State<CommandPaletteScope> createState() => _CommandPaletteScopeState();
}

class _CommandPaletteScopeState extends State<CommandPaletteScope> {
  var _open = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_key);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_key);
    super.dispose();
  }

  bool _key(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.keyK) return false;
    final keys = HardwareKeyboard.instance;
    if (!(keys.isControlPressed || keys.isMetaPressed) || keys.isShiftPressed || keys.isAltPressed) {
      return false;
    }
    // Only from the screen on top, and never twice.
    if (_open || !mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return _open;
    return _show();
  }

  bool _show() {
    if (_open || !mounted) return false;
    _open = true;
    showCommandPalette(context, widget.entries(context), more: widget.more).whenComplete(() => _open = false);
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The palette for touch screens and anyone who does not know Ctrl+K: a
/// search button that opens it. Nothing shows outside a palette scope.
class PaletteButton extends StatelessWidget {
  const PaletteButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorStateOfType<_CommandPaletteScopeState>() == null) return const SizedBox.shrink();
    final mac = Theme.of(context).platform == TargetPlatform.macOS;
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: 'Search pages, actions and help (${mac ? '⌘' : 'Ctrl+'}K)',
      onPressed: () => CommandPaletteScope.open(context),
    );
  }
}
