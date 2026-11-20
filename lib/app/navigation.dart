import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/applications_page.dart' show exportReminders;
import '../ui/kit/kit.dart';
import 'modules.dart';
import 'providers.dart';

/// One navigation entry that groups several pages (Jobs: Jobs and
/// Applications). It shows a switch over its pages, each kept whole.
class PageGroup {
  const PageGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.pages,
  });
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<Destination> pages;

  /// The group as the shell's navigation entry.
  Destination get destination => Destination(
    id: id,
    label: label,
    icon: icon,
    selectedIcon: selectedIcon,
    primary: true,
    page: (_) => GroupPage(this),
  );
}

/// Which page each group shows, by group id; a group not listed shows its
/// first page.
final groupTabProvider = NotifierProvider<GroupTabs, Map<String, String>>(GroupTabs.new);

class GroupTabs extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void show(String group, String page) {
    if (state[group] != page) state = {...state, group: page};
  }
}

/// A grouped entry: the pill switch at the top, then the chosen page. Pages
/// are built on first visit and then kept, like the shell's own.
class GroupPage extends ConsumerStatefulWidget {
  const GroupPage(this.group, {super.key});
  final PageGroup group;

  @override
  ConsumerState<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends ConsumerState<GroupPage> {
  final _visited = <String>{};

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final chosen = ref.watch(groupTabProvider.select((m) => m[g.id]));
    final index = g.pages.indexWhere((p) => p.id == chosen).clamp(0, g.pages.length - 1);
    _visited.add(g.pages[index].id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 2),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: PillNav<String>(
                      key: ValueKey('pills.${g.id}'),
                      items: [for (final p in g.pages) PillNavItem(p.id, p.label, icon: p.icon)],
                      selected: g.pages[index].id,
                      onChanged: (id) => ref.read(groupTabProvider.notifier).show(g.id, id),
                    ),
                  ),
                ),
                // The palette, for touch: every page, the actions and the help.
                const PaletteButton(),
              ],
            ),
          ),
        ),
        Expanded(
          // The switch above has taken the status bar's room.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: IndexedStack(
              index: index,
              children: [
                for (final p in g.pages)
                  _visited.contains(p.id)
                      ? KeyedSubtree(key: ValueKey(p.id), child: p.page(context))
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows page [id] wherever it lives: the shell switches to its entry and a
/// grouped entry to its tab. Returns whether the page could be shown.
bool goToPage(WidgetRef ref, String id) {
  final group = groupOf(id);
  if (group == null && !allDestinations.any((d) => d.id == id)) return false;
  if (group != null) ref.read(groupTabProvider.notifier).show(group.id, id);
  return showDestination(group?.id ?? id);
}

/// Shows the Conversations page with thread [id] asked for: the page opens
/// it from [openThreadProvider].
bool openThread(WidgetRef ref, String id) {
  ref.read(openThreadProvider.notifier).open(id);
  return goToPage(ref, 'conversations');
}

/// Switches the shell to navigation entry [id].
///
/// brahma_core's AppShell keeps its selection to itself, but it marks each
/// navigation item with a public TourTarget. On a wide window the rail
/// takes the choice by index (the selected item has no marker, so any other
/// one leads to the rail); on a phone the dock item is tapped. A change to
/// brahma_core giving AppShell a controller would make this direct.
bool showDestination(String id) {
  final i = allDestinations.indexWhere((d) => d.id == id);
  if (i < 0) return false;
  for (final d in [allDestinations[i], ...allDestinations]) {
    final target = TourTarget.find(d.hint);
    if (target == null) continue;
    final rail = target.findAncestorWidgetOfExactType<NavigationRail>();
    if (rail != null) {
      rail.onDestinationSelected?.call(i);
      return true;
    }
    if (d.id != id) continue;
    InkWell? item;
    void visit(Element e) {
      if (item != null) return;
      if (e.widget case final InkWell w) {
        item = w;
        return;
      }
      e.visitChildren(visit);
    }

    target.visitChildElements(visit);
    item?.onTap?.call();
    return item != null;
  }
  return false;
}

/// Ctrl+K over the whole app: every page, and a few actions.
class UdyogaPalette extends ConsumerWidget {
  const UdyogaPalette({super.key, required this.child});
  final Widget child;

  static const _keywords = <String, List<String>>{
    'today': ['home', 'follow-ups', 'dashboard'],
    'jobs': ['openings', 'matches', 'search'],
    'applications': ['pipeline', 'board', 'stages'],
    'explore': ['countries', 'visa', 'abroad', 'relocate', 'routes', 'tracks'],
    'contacts': ['people', 'recruiters', 'leads'],
    'linkedin': ['posts', 'comments'],
    'interview': ['practice', 'questions'],
    'coach': ['check-in', 'journal', 'stories'],
    'growth': ['courses', 'certifications', 'learning', 'notes'],
    'profile': ['CV', 'resume', 'experience'],
    'career': ['map', 'paths', 'assessment'],
    'settings': ['AI', 'keys', 'sync', 'updates', 'security'],
  };

  /// Help answers for [query] that belong to a page, each opening its page:
  /// the help's "go to" for pages inside a group, which brahma_core's own
  /// Help dialog cannot reach (it knows only the navigation entries).
  static List<PaletteEntry> helpFor(WidgetRef ref, String query) => [
    for (final h in searchHelp(query, ref.read(hintTextsProvider), allPages, limit: 6))
      if (h.screen case final page?)
        PaletteEntry(
          id: 'help.${h.id}',
          label: h.text,
          icon: Icons.help_outline,
          section: 'Help · ${page.label}',
          onSelect: () => goToPage(ref, page.id),
        ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => CommandPaletteScope(
    more: (q) => helpFor(ref, q),
    entries: (context) => [
      for (final p in allPages)
        PaletteEntry(
          id: p.id,
          label: p.label,
          icon: p.icon,
          section: groupOf(p.id)?.label ?? 'Pages',
          keywords: _keywords[p.id] ?? const [],
          onSelect: () => goToPage(ref, p.id),
        ),
      PaletteEntry(
        id: 'refresh',
        label: 'Check the job sites now',
        icon: Icons.refresh,
        section: 'Actions',
        keywords: const ['refresh', 'update jobs'],
        onSelect: () {
          goToPage(ref, 'jobs');
          ref.read(refreshProvider.notifier).run(force: true).catchError((_) => null).ignore();
          showToast(context, 'Checking the job sites', description: 'Jobs shows how far it has got.');
        },
      ),
      PaletteEntry(
        id: 'calendar',
        label: 'Reminders to calendar',
        icon: Icons.event_available_outlined,
        section: 'Actions',
        keywords: const ['export', 'follow-ups', 'ics'],
        onSelect: () => exportReminders(context, ref),
      ),
    ],
    child: child,
  );
}
