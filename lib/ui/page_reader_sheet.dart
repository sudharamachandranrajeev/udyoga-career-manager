import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/page_tools.dart';
import '../app/providers.dart';
import '../domain/ai.dart';
import '../domain/assist_fill.dart';
import '../domain/employers.dart';
import '../domain/fill_drafts.dart';
import '../domain/lead_finder.dart';
import '../domain/ocr.dart';
import '../domain/page_reader.dart';
import '../domain/recipes.dart';
import 'jobs_page.dart';
import 'site_browser.dart';

/// "Read this page": reads the page open in [browser] into records, falls
/// back to a screenshot when the page has little text, and shows what it
/// found for the user to check. Nothing is kept until they save it.
Future<void> readOpenPage(BuildContext context, WidgetRef ref, SiteBrowser browser) async {
  final PageSnapshot? page;
  try {
    page = await browser.snapshot();
  } on Object catch (e) {
    if (context.mounted) showMessage(context, 'Could not read the page: $e');
    return;
  }
  if (!context.mounted) return;
  if (page == null) return showMessage(context, 'Open the page in Udyoga first.');
  final recipes = await ref.read(recipesProvider.future).catchError((_) => const RecipeSet());
  final fromRecipes = [
    for (final r in recipes.forPage(page.url, RecipeMode.browserRead))
      ?r.recordFrom(page.html, url: page.url, ld: page.ld),
  ];
  var records = readPage(page, first: fromRecipes);
  if (!context.mounted) return;
  if (page.thin || records.isEmpty) {
    final more = await _readScreenshot(context, ref, browser, page);
    if (more == null || !context.mounted) return;
    records = [...records, ...more.where((r) => !records.any(r.sameAs))];
  }
  if (!context.mounted) return;
  if (records.isEmpty) {
    return showMessage(context, 'Nothing to keep on this page: no job, person or employer.');
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PageRecordsPage(records: records)));
}

/// Offers the screenshot ways this device has, and reads the one chosen.
/// Null when the user stops.
Future<List<PageRecord>?> _readScreenshot(
  BuildContext context,
  WidgetRef ref,
  SiteBrowser browser,
  PageSnapshot page,
) async {
  final ocr = await ref.read(ocrProvider.future).catchError((_) => null);
  final advisor = await ref.read(advisorProvider.future).catchError((_) => null);
  final vision = advisor != null && AiProvider.of(advisor.ai.model).images ? advisor : null;
  if (!context.mounted) return null;
  final how = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('This page has little text to read'),
      content: Text(
        [
          'It may be a picture, a canvas or a PDF. Udyoga can read a screenshot of it instead: the page\'s own '
              'picture when it allows that, or a screenshot you take and choose.',
          if (ocr == null)
            'No text reader is installed on this device. On Linux or Windows, install Tesseract to read '
                'screenshots here.',
          if (vision != null)
            'Your AI (${AiProvider.of(vision.ai.model).label}) can read it too: the screenshot is sent to it.',
        ].join('\n\n'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (vision != null)
          TextButton(onPressed: () => Navigator.pop(context, 'ai'), child: const Text('Ask the AI')),
        if (ocr != null)
          FilledButton(
            onPressed: () => Navigator.pop(context, 'ocr'),
            child: Text('Read it here (${ocr.name})'),
          ),
      ],
    ),
  );
  if (how == null || !context.mounted) return null;
  if (how == 'ocr' && ocr is MlKitOcr && !await _mlKitConsent(context, ref)) return null;
  if (!context.mounted) return null;
  final image = await _screenshot(context, browser);
  if (image == null || !context.mounted) return null;
  try {
    if (how == 'ai') {
      final answer = await vision!.readScreenshot(image, url: page.url);
      return recordsFromVision(answer, url: page.url);
    }
    final text = await ocr!.read(image);
    return recordsFromText(text, url: page.url, title: page.title, from: 'OCR');
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  }
}

/// Asks once whether ML Kit may be used, saying what it sends Google.
Future<bool> _mlKitConsent(BuildContext context, WidgetRef ref) async {
  final db = ref.read(sessionProvider).db;
  if (await db.localSetting(mlKitConsentKey) == 'yes') return true;
  if (!context.mounted) return false;
  final ok = await confirm(
    context,
    title: 'Read screenshots with ML Kit?',
    message: mlKitNotice,
    action: 'Use ML Kit',
  );
  await db.setLocalSetting(mlKitConsentKey, ok ? 'yes' : 'no');
  return ok;
}

/// The page's own canvas when it gives one, otherwise a screenshot the
/// user chooses.
Future<Uint8List?> _screenshot(BuildContext context, SiteBrowser browser) async {
  final canvas = await browser.canvasImage().catchError((_) => null);
  if (canvas != null) return canvas;
  if (!context.mounted) return null;
  final go = await confirm(
    context,
    title: 'Choose a screenshot',
    message:
        'The page does not hand over its picture. Take a screenshot of it (your system\'s screenshot key, or '
        'power and volume down on a phone), then choose it here.',
    action: 'Choose it',
  );
  if (!go) return null;
  final files = await FilePicker.pickFiles(dialogTitle: 'Screenshot of the page', type: FileType.image);
  if (files.isEmpty) return null;
  return files.first.readAsBytes();
}

/// What the reader found, each record editable, kept only when ticked and
/// saved.
class PageRecordsPage extends ConsumerStatefulWidget {
  const PageRecordsPage({super.key, required this.records});
  final List<PageRecord> records;

  @override
  ConsumerState<PageRecordsPage> createState() => _PageRecordsPageState();
}

class _PageRecordsPageState extends ConsumerState<PageRecordsPage> {
  late final List<Map<String, TextEditingController>> _fields = [
    for (final r in widget.records) {for (final f in r.kind.fields) f: TextEditingController(text: r[f])},
  ];

  /// Nothing is ticked at first: the user picks what to keep.
  late final List<bool> _keep = [for (final _ in widget.records) false];
  var _saving = false;

  @override
  void dispose() {
    for (final m in _fields) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  PageRecord _edited(int i) =>
      widget.records[i].withFields({for (final e in _fields[i].entries) e.key: e.value.text});

  Future<void> _save() async {
    setState(() => _saving = true);
    final p = await ref.read(profileProvider.future);
    final saved = <String>[];
    final book = ref.read(sessionProvider).book;
    final hasJob = [
      for (var i = 0; i < _keep.length; i++)
        if (_keep[i]) _edited(i),
    ].any((r) => r.kind == RecordKind.job);
    try {
      for (var i = 0; i < widget.records.length; i++) {
        if (!_keep[i]) continue;
        final r = _edited(i);
        if (!r.usable) continue;
        final host = Uri.tryParse(r.url)?.host ?? '';
        switch (r.kind) {
          case RecordKind.job:
            if (!mounted) return;
            final id = await saveAdvert(ref, r.toPosting(country: p.country));
            saved.add(id == null ? '${r.headline} (already saved)' : r.headline);
          case RecordKind.person:
            final added = await ref.mutate(
              (s) => s.book.saveFoundLead(
                name: r['name'],
                title: r['title'],
                company: r['company'],
                email: r['email'],
                phone: r['phone'],
                linkedin: r['profileUrl'].contains('linkedin.com/in/') ? r['profileUrl'] : '',
                sourceKind: hasJob ? 'advert' : 'other',
                source: host,
                sourceUrl: r.url,
                today: today(),
              ),
            );
            saved.add(added ? r.headline : '${r.headline} (already a contact)');
          case RecordKind.company:
            final id = employerId(r['name']);
            final exists = (await book.watchedEmployers()).any((e) => e.id == id || e.matches(r['name']));
            if (!exists) {
              await ref.mutate(
                (s) => s.book.saveWatchedEmployer(
                  WatchedEmployer(
                    id: id,
                    name: r['name'],
                    why: r['about'].length > 200 ? '${r['about'].substring(0, 200)}…' : r['about'],
                    sources: [if (r['website'].startsWith('http')) r['website']],
                  ),
                ),
              );
            }
            saved.add(exists ? '${r.headline} (already watched)' : r.headline);
        }
      }
      if (!mounted) return;
      showMessage(context, saved.isEmpty ? 'Nothing was kept.' : 'Kept: ${saved.join(', ')}');
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final any = _keep.contains(true);
    return PageScaffold(
      title: 'Found on this page',
      banner:
          'Check each one and tick what to keep. Nothing is saved until you press Keep. Jobs go to your jobs, '
          'people to your contacts and employers to the ones you watch.',
      actions: [
        TextButton.icon(
          onPressed: any && !_saving ? _save : null,
          icon: const Icon(Icons.check),
          label: const Text('Keep'),
        ),
      ],
      children: [
        for (var i = 0; i < widget.records.length; i++)
          SectionCard(
            title:
                '${widget.records[i].kind.label}: ${widget.records[i].headline.isEmpty ? '(no name)' : widget.records[i].headline}',
            trailing: Checkbox(
              value: _keep[i],
              semanticLabel: 'Keep ${widget.records[i].headline}',
              onChanged: (v) => setState(() => _keep[i] = v ?? false),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Read from the ${widget.records[i].from}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                for (final f in widget.records[i].kind.fields)
                  if (_fields[i][f]!.text.isNotEmpty || _primary(widget.records[i].kind, f))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _fields[i][f],
                        minLines: 1,
                        maxLines: f == 'description' || f == 'about' ? 6 : 1,
                        decoration: InputDecoration(labelText: _label(f), isDense: true),
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  static bool _primary(RecordKind k, String f) => switch (k) {
    RecordKind.job => const {'title', 'company', 'location', 'closing'}.contains(f),
    RecordKind.person => const {'name', 'title', 'company'}.contains(f),
    RecordKind.company => const {'name', 'website'}.contains(f),
  };

  static String _label(String f) => switch (f) {
    'title' => 'Title',
    'company' => 'Employer',
    'location' => 'Location',
    'salary' => 'Pay',
    'closing' => 'Closing date',
    'posted' => 'Posted',
    'reference' => 'Reference',
    'description' => 'Description',
    'name' => 'Name',
    'email' => 'E-mail',
    'phone' => 'Phone',
    'profileUrl' => 'Profile link',
    'website' => 'Website',
    'about' => 'About',
    _ => f,
  };
}

/// "Fill a text box": the assist-fill recipes for the open page. The user
/// writes or pastes their approved draft, sees exactly what goes where and
/// how many fills are left today, and only then is it filled. Udyoga never
/// presses Send; the user does, on the page.
Future<void> fillOnPage(BuildContext context, WidgetRef ref, SiteBrowser browser) async {
  final page = await browser.snapshot().catchError((_) => null);
  if (!context.mounted) return;
  if (page == null) return showMessage(context, 'Open the page in Udyoga first.');
  final set = await ref.read(recipesProvider.future).catchError((_) => const RecipeSet());
  final matching = set.forPage(page.url, RecipeMode.assistFill);
  if (!context.mounted) return;
  if (matching.isEmpty) return showMessage(context, 'None of your recipes fills a text box on this page.');
  final recipe = matching.length == 1
      ? matching.single
      : await showDialog<Recipe>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Which text box?'),
            children: [
              for (final r in matching)
                SimpleDialogOption(onPressed: () => Navigator.pop(context, r), child: Text(r.title)),
            ],
          ),
        );
  if (recipe == null || !context.mounted) return;
  final fill = recipe.fill!;
  final person = readPage(page).where((r) => r.kind == RecordKind.person).firstOrNull;
  final job = readPage(page).where((r) => r.kind == RecordKind.job).firstOrNull;
  final values = {
    'name': person?['name'] ?? '',
    'company': person?['company'].isNotEmpty == true ? person!['company'] : (job?['company'] ?? ''),
    'jobTitle': job?['title'] ?? '',
  };
  final session = ref.read(sessionProvider);
  final saved = await session.book.fillDrafts().catchError((_) => const <FillDraft>[]);
  if (!context.mounted) return;
  final draft = TextEditingController(
    text: fill.templateSource == 'recipe' ? fillTemplate(fill.template, values) : '',
  );
  final engine = AssistFill(session.db, book: session.book);
  try {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your draft for ${recipe.title}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (saved.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await _pickSavedDraft(context, saved, maxLength: fill.maxLength);
                      if (picked != null) draft.text = picked;
                    },
                    icon: const Icon(Icons.drafts_outlined, size: 18),
                    label: Text('Use a saved draft (${saved.length})'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: draft,
                autofocus: true,
                minLines: 4,
                maxLines: 10,
                maxLength: fill.maxLength > 0 ? fill.maxLength : null,
                decoration: const InputDecoration(
                  helperText: 'Write, paste or pick the text you approve. It goes into the box as it is.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Preview')),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    final plan = await engine.plan(recipe, pageUrl: page.url, draft: draft.text);
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dry run: nothing is filled yet'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Text box: ${plan.target}'),
              Text(
                'Fills today: ${plan.used} of ${plan.cap}${isLinkedIn(recipe.site) ? ' (LinkedIn: at most $linkedInDailyCeiling a day)' : ''}',
              ),
              if (plan.cut) Text('Shortened to the box\'s ${fill.maxLength} characters.'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SelectableText(plan.text.isEmpty ? '(empty)' : plan.text),
              ),
              const SizedBox(height: 12),
              const Text(
                'Udyoga only types this into the box. Read it on the page, then press Send yourself.',
              ),
              for (final p in plan.problems)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(p, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: plan.ready ? () => Navigator.pop(context, true) : null,
            child: const Text('Fill it in'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    // Through mutate, so the synced count is queued for the other devices.
    final problem = await ref.mutate((_) => engine.apply(plan, browser.fillTextBox));
    ref.invalidate(recipeUsageProvider);
    if (!context.mounted) return;
    showMessage(context, problem ?? 'Filled in. Check it on the page and press Send yourself.');
  } finally {
    draft.dispose();
  }
}

/// The saved drafts to choose from, newest first; the chosen text, or null.
/// A draft longer than the box says so (it would be cut in the dry run).
Future<String?> _pickSavedDraft(
  BuildContext context,
  List<FillDraft> drafts, {
  int maxLength = 0,
}) => showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text('Use a saved draft'),
    children: [
      for (final d in drafts)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, d.text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                '${d.from}${d.at.length >= 10 ? ' · ${d.at.substring(0, 10)}' : ''} · ${d.text.length} characters'
                '${maxLength > 0 && d.text.length > maxLength ? ' (longer than the box\'s $maxLength)' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(d.text, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
    ],
  ),
);
