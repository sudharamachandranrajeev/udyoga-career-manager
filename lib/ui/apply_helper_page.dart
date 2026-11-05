import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'common.dart';

/// The apply helper only exists on the desktop apps, where the application
/// form is open in a browser beside Udyoga.
bool get applyHelperSupported => !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

/// A web address the helper may open: http(s) with a host, else null.
Uri? applyUrl(String text) {
  final u = Uri.tryParse(text.trim());
  return u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty ? u : null;
}

/// Desktop companion for filling in an external application form by hand:
/// opens the advert's link in the browser and keeps the tailored cover letter
/// and CV text ready to copy. Udyoga never fills in or submits the form; every
/// paste and every submission is the user's.
class ApplyHelperPage extends StatefulWidget {
  const ApplyHelperPage({super.key, required this.url, required this.coverLetter, required this.cv});
  final String url, coverLetter, cv;

  @override
  State<ApplyHelperPage> createState() => _ApplyHelperPageState();
}

class _ApplyHelperPageState extends State<ApplyHelperPage> {
  late final url = TextEditingController(text: widget.url);
  late final text = TextEditingController(
    text: widget.coverLetter.isNotEmpty ? widget.coverLetter : widget.cv,
  );
  late var showing = widget.coverLetter.isNotEmpty ? 'letter' : 'cv';

  @override
  void dispose() {
    url.dispose();
    text.dispose();
    super.dispose();
  }

  void _show(String which) => setState(() {
    showing = which;
    text.text = which == 'letter' ? widget.coverLetter : widget.cv;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Apply helper')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Open the application in your browser, then copy the text below into the form yourself. '
          'Udyoga does not fill in or send anything.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: url,
          decoration: const InputDecoration(labelText: 'Application link', hintText: 'https://…'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () {
              final u = applyUrl(url.text);
              if (u == null) return showMessage(context, 'Enter a web address starting with https://');
              openUri(context, u);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in browser'),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: [
            if (widget.coverLetter.isNotEmpty)
              const ButtonSegment(value: 'letter', label: Text('Cover letter')),
            const ButtonSegment(value: 'cv', label: Text('CV')),
          ],
          selected: {showing},
          onSelectionChanged: (s) => _show(s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: text,
          minLines: 8,
          maxLines: 20,
          decoration: const InputDecoration(helperText: 'Edit if you like; changes are not saved.'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => copyText(context, text.text, what: 'Copied. Paste it into the form.'),
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ),
      ],
    ),
  );
}
