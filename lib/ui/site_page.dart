import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/answer_pack.dart';
import '../domain/insights.dart';
import '../domain/json.dart';
import '../domain/pipeline.dart';
import 'common.dart';
import 'jobs_page.dart';
import 'site_browser.dart';

/// Opens [url] inside Udyoga. With [applicationId] it is the application's
/// page: the candidate's answers sit beside the site, ready to copy, and
/// they mark it sent when they have pressed submit there. Without, it is a
/// job site to browse, and the job on screen can be saved to Udyoga.
Future<void> openSite(
  BuildContext context, {
  required String url,
  required String title,
  String? applicationId,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => SitePage(url: url, title: title, applicationId: applicationId),
  ),
);

class SitePage extends ConsumerStatefulWidget {
  const SitePage({super.key, required this.url, required this.title, this.applicationId});
  final String url, title;
  final String? applicationId;

  @override
  ConsumerState<SitePage> createState() => _SitePageState();
}

class _SitePageState extends ConsumerState<SitePage> {
  SiteBrowser? _browser;
  Widget? _embedded;
  var _opened = false;
  var _showSite = true;

  bool get _applying => widget.applicationId != null;

  @override
  void initState() {
    super.initState();
    _browser = ref.read(siteBrowserProvider)();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _browser?.close();
    super.dispose();
  }

  Future<void> _open() async {
    if (widget.url.isEmpty) return;
    final b = _browser;
    if (b == null) {
      await openLink(context, widget.url);
      return;
    }
    try {
      final w = await b.open(widget.url, title: widget.title);
      if (mounted) {
        setState(() {
          _embedded = w;
          _opened = true;
        });
      }
    } on Object catch (e) {
      // No web view on this device (Linux needs WebKitGTK 4.1): the system
      // browser still works, without page copies.
      _browser = null;
      if (!mounted) return;
      showMessage(context, 'Opening it in your browser instead ($e).');
      await openLink(context, widget.url);
    }
  }

  Future<({String url, String title, String text})?> _page() async {
    final p = await _browser?.page();
    if (p == null || p.text.isEmpty) {
      if (mounted) showMessage(context, 'Open the page in Udyoga first.');
      return null;
    }
    return p;
  }

  Future<void> _keepCopy() async {
    final p = await _page();
    if (p == null || !mounted) return;
    final a = await ref.read(sessionProvider).book.application(widget.applicationId!);
    await ref.mutate(
      (s) => s.book.archive(
        applicationId: a.id,
        jobId: a.jobId,
        kind: 'advert',
        at: nowLocal(),
        title: p.title,
        url: p.url,
        content: p.text,
      ),
    );
    if (mounted) showMessage(context, 'A copy of this page is kept with the application.');
  }

  Future<void> _saveJob() async {
    final p = await _page();
    if (p == null || !mounted) return;
    try {
      // Without an AI the page title stands in for the job title
      // ("Ward Clerk | HSC Jobs" gives "Ward Clerk").
      final posting = await readPosting(
        ref,
        url: p.url,
        text: p.text,
        title: p.title.split(RegExp(r'\s[|–-]\s')).first.trim(),
      );
      if (!mounted) return;
      if (posting == null || posting.title.isEmpty) {
        showMessage(context, 'No job advert on this page. Open the job first.');
        return;
      }
      final id = await saveAdvert(ref, posting);
      if (!mounted) return;
      showMessage(
        context,
        id == null ? 'This job is already saved.' : 'Saved to your jobs: ${posting.title}',
      );
    } on Object catch (e) {
      if (mounted) showMessage(context, 'Could not save it: $e');
    }
  }

  Future<void> _sent(List<PackSection> pack) async {
    final ok = await confirm(
      context,
      title: 'Mark as sent?',
      message:
          'Only once you have pressed submit on the site. Udyoga starts the follow-up clock '
          'and keeps a copy of these answers.',
      action: 'It is sent',
    );
    if (!ok || !mounted) return;
    await ref.mutate((s) => s.book.markSent(widget.applicationId!, today: today(), sent: packText(pack)));
    if (!mounted) return;
    showMessage(context, 'Marked as sent. Udyoga will remind you to follow up.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final embedded = _embedded;
    final answers = _applying ? _Answers(applicationId: widget.applicationId!, onSent: _sent) : null;
    final actions = [
      if (_applying)
        IconButton(
          icon: const Icon(Icons.inventory_2_outlined),
          tooltip: 'Keep a copy of this page',
          onPressed: _opened ? _keepCopy : null,
        )
      else
        IconButton(
          icon: const Icon(Icons.bookmark_add_outlined),
          tooltip: 'Save this job',
          onPressed: _opened ? _saveJob : null,
        ),
      IconButton(icon: const Icon(Icons.refresh), tooltip: 'Open the site again', onPressed: _open),
    ];

    // Android: the site in the page, the answers a tab away.
    if (embedded != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title, overflow: TextOverflow.ellipsis),
          actions: actions,
          bottom: answers == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Site'), icon: Icon(Icons.public)),
                        ButtonSegment(
                          value: false,
                          label: Text('Your answers'),
                          icon: Icon(Icons.assignment),
                        ),
                      ],
                      selected: {_showSite},
                      onSelectionChanged: (v) => setState(() => _showSite = v.first),
                    ),
                  ),
                ),
        ),
        body: IndexedStack(index: _showSite || answers == null ? 0 : 1, children: [embedded, ?answers]),
      );
    }

    // Desktop: the site in its own window, the answers here.
    return PageScaffold(
      title: widget.title,
      actions: actions,
      children: [
        SectionCard(
          title: _browser == null ? 'Opened in your browser' : 'Opened in its own window',
          child: Text(
            _applying
                ? 'Sign in and fill in the form there. Copy each answer from below, check it, '
                      'and press submit on the site yourself. Then mark it sent here.'
                : 'Search there. When a job you like is on screen, save it to Udyoga with the bookmark button.',
          ),
        ),
        ?answers,
      ],
    );
  }
}

/// The answer pack for an application, section by section.
class _Answers extends ConsumerWidget {
  const _Answers({required this.applicationId, required this.onSent});
  final String applicationId;
  final Future<void> Function(List<PackSection>) onSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).value;
    final a = (ref.watch(applicationsProvider).value ?? const <JobApplication>[])
        .where((a) => a.id == applicationId)
        .firstOrNull;
    if (p == null || a == null) return const Center(child: CircularProgressIndicator());
    final cvs = ref.watch(resumesProvider).value ?? const <Resume>[];
    final cv =
        cvs.where((r) => r.id == a.resumeId).firstOrNull ??
        cvs.where((r) => a.jobId != null && r.jobId == a.jobId).firstOrNull;
    final statement = cv == null ? '' : TailorNotes(decodeObject(cv.tailoring)).coverLetter;
    final referees = (ref.watch(leadsProvider).value ?? const <Lead>[])
        .where((l) => l.kind == 'referee')
        .toList();
    final pack = answerPack(p, statement: statement, referees: referees);
    final sent = Stage.of(a.stage).index >= Stage.applied.index;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        for (final s in pack)
          SectionCard(
            title: s.title,
            trailing: s.ready
                ? IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy ${s.title.toLowerCase()}',
                    onPressed: () => copyText(context, s.text, what: '${s.title} copied.'),
                  )
                : null,
            child: s.ready
                ? SelectableText(s.text)
                : Text(s.missing, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: sent ? null : () => onSent(pack),
            icon: const Icon(Icons.send),
            label: Text(
              sent ? 'Sent ${a.applied == null ? '' : niceDate(a.applied!)}' : 'I have submitted it',
            ),
          ),
        ),
      ],
    );
  }
}
