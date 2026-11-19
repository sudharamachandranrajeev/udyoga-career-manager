/// The page reader: turns the page the user has open in Udyoga's browser
/// into records they can keep (a job, a person, an employer). It reads the
/// page's text and its schema.org markup first; when that gives little (a
/// canvas or PDF-like page), the text comes from a screenshot instead (OCR
/// on the device, or the user's AI). Nothing is saved here: the user sees
/// each record and confirms it first.
library;

import 'dart:convert';

import 'ats.dart';
import 'feeds.dart';
import 'json.dart';
import 'lead_finder.dart';

/// Reads the open page: its address, title, visible text, JSON-LD scripts,
/// HTML (capped at 1.5 MB) and whether it shows canvases or a PDF. Runs in
/// the page; returns a JSON string.
const readPageScript = r'''(function () {
  var ld = [];
  document.querySelectorAll('script[type="application/ld+json"]').forEach(function (s) { ld.push(s.textContent || ''); });
  var html = document.documentElement ? document.documentElement.outerHTML : '';
  if (html.length > 1500000) html = html.slice(0, 1500000);
  var pdf = document.contentType === 'application/pdf' ||
    document.querySelectorAll('embed[type="application/pdf"],object[type="application/pdf"],iframe[src$=".pdf"]').length > 0;
  return JSON.stringify({
    url: location.href,
    title: document.title,
    text: document.body ? document.body.innerText : '',
    ld: ld,
    html: html,
    canvases: document.querySelectorAll('canvas').length,
    pdf: pdf
  });
})()''';

/// The largest canvas on the page as a PNG data URL, or '' when there is
/// none or the page does not allow it to be read. Runs in the page.
const canvasImageScript = r'''(function () {
  var best = null, area = 0;
  document.querySelectorAll('canvas').forEach(function (c) {
    var a = c.width * c.height;
    if (a > area) { area = a; best = c; }
  });
  if (!best || area < 10000) return '';
  try { return best.toDataURL('image/png'); } catch (e) { return ''; }
})()''';

/// What [readPageScript] read from a page.
class PageSnapshot {
  const PageSnapshot({
    required this.url,
    this.title = '',
    this.text = '',
    this.ld = const [],
    this.html = '',
    this.canvases = 0,
    this.pdf = false,
  });

  final String url, title, text, html;

  /// The JSON-LD script bodies.
  final List<String> ld;
  final int canvases;
  final bool pdf;

  /// The reply of [readPageScript]; platforms return the JSON either as is
  /// or quoted once more. Null when it is not one.
  static PageSnapshot? decode(Object? raw) {
    var v = raw;
    for (var i = 0; i < 2 && v is String; i++) {
      try {
        v = jsonDecode(v);
      } on FormatException {
        return null;
      }
    }
    if (v is! Map) return null;
    final j = v.cast<String, Object?>();
    return PageSnapshot(
      url: str(j['url']),
      title: str(j['title']).trim(),
      text: str(j['text']).trim(),
      ld: [for (final s in j['ld'] is List ? j['ld'] as List : const []) str(s)],
      html: str(j['html']),
      canvases: intOf(j['canvases']) ?? 0,
      pdf: j['pdf'] == true,
    );
  }

  /// Too little text to read from: a canvas or PDF-like page, or one that
  /// is mostly pictures. The reader then offers a screenshot.
  bool get thin {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (pdf) return words < 400;
    if (ldObjects(ld).isNotEmpty) return false;
    if (canvases > 0) return words < 150;
    return words < 40;
  }
}

/// The kinds of record the reader makes, with the fields each one has.
enum RecordKind {
  job('Job', ['title', 'company', 'location', 'salary', 'closing', 'posted', 'reference', 'description']),
  person('Person', ['name', 'title', 'company', 'email', 'phone', 'profileUrl']),
  company('Employer', ['name', 'website', 'location', 'about']);

  const RecordKind(this.label, this.fields);
  final String label;
  final List<String> fields;

  static RecordKind? of(String s) => values.where((k) => k.name == s).firstOrNull;
}

/// One thing found on a page, for the user to check and keep.
class PageRecord {
  PageRecord(this.kind, Map<String, String> fields, {required this.from, this.url = ''})
    : fields = {
        for (final f in kind.fields)
          if ((fields[f] ?? '').trim().isNotEmpty) f: fields[f]!.trim(),
      };

  final RecordKind kind;
  final Map<String, String> fields;

  /// How it was read: "page markup", "page text", "OCR", "AI" or a recipe.
  final String from;

  /// The page it came from.
  final String url;

  String operator [](String f) => fields[f] ?? '';

  /// The field that names it: the job title, the person or the employer.
  String get headline => this[kind == RecordKind.job ? 'title' : 'name'];

  bool get usable => headline.isNotEmpty || (kind == RecordKind.person && this['email'].isNotEmpty);

  PageRecord withFields(Map<String, String> next) => PageRecord(kind, next, from: from, url: url);

  /// The job as a posting to save.
  Posting toPosting({String country = '', String source = 'page'}) {
    final salary = this['salary'];
    final (low, high) = salaryIn(salary);
    String? day(String v) => RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v)
        ? v.substring(0, 10)
        : v.isEmpty
        ? null
        : closingIn('Closing date: $v');
    return Posting(
      source: source,
      sourceId: url.isNotEmpty ? url : 'page:${this['reference']}:${this['title']}',
      title: this['title'],
      company: this['company'],
      location: this['location'],
      country: country,
      salaryText: salary,
      salaryMin: low,
      salaryMax: high,
      currency: low == null ? '' : 'GBP',
      url: url,
      description: this['description'],
      posted: day(this['posted']),
      closing: day(this['closing']),
    );
  }

  /// Same kind and same headline (ignoring case).
  bool sameAs(PageRecord o) =>
      o.kind == kind &&
      (headline.isNotEmpty
          ? o.headline.toLowerCase() == headline.toLowerCase()
          : o['email'].isNotEmpty && o['email'].toLowerCase() == this['email'].toLowerCase());
}

/// The records on a page: [first] (a site recipe's, say) win, then the
/// page's schema.org markup (JobPosting, Person, Organization), then what
/// its text says (a job advert's title and contacts).
List<PageRecord> readPage(PageSnapshot page, {List<PageRecord> first = const []}) {
  final out = <PageRecord>[];
  void add(PageRecord r) {
    if (r.usable && !out.any(r.sameAs)) out.add(r);
  }

  first.forEach(add);
  for (final r in recordsFromLd(page.ld, pageUrl: page.url)) {
    add(r);
  }
  for (final r in recordsFromText(page.text, url: page.url, title: page.title, from: 'page text')) {
    // Text guesses only fill gaps the markup left.
    if (r.kind == RecordKind.job && out.any((o) => o.kind == RecordKind.job)) continue;
    add(r);
  }
  return out;
}

const _orgTypes = {
  'Organization',
  'Corporation',
  'NGO',
  'GovernmentOrganization',
  'EducationalOrganization',
  'MedicalOrganization',
  'Hospital',
  'LocalBusiness',
  'EmployerAggregateRating',
};

/// Records from schema.org JSON-LD: JobPosting, Person and Organization
/// (and its kinds), including the employer a JobPosting names.
List<PageRecord> recordsFromLd(List<String> scripts, {required String pageUrl}) {
  final out = <PageRecord>[];
  const from = 'page markup';
  String text(Object? v) => htmlToText(str(v is Map ? v['name'] : v));
  String address(Object? a) {
    final o = a is List ? (a.isEmpty ? null : a.first) : a;
    if (o is! Map) return str(o);
    final m = o.cast<String, Object?>();
    final addr = m['address'] is Map ? obj(m['address']) : m;
    return [
      str(addr['addressLocality']),
      str(addr['addressRegion']),
      str(addr['addressCountry'] is Map ? obj(addr['addressCountry'])['name'] : addr['addressCountry']),
    ].where((x) => x.isNotEmpty).join(', ');
  }

  String sameAs(Json j, String host) {
    final s = j['sameAs'];
    final all = s is List ? s.map(str) : [str(s)];
    return all.where((u) => u.contains(host)).firstOrNull ?? '';
  }

  PageRecord org(Json j) => PageRecord(
    RecordKind.company,
    {
      'name': text(j['name']),
      'website': str(j['url']).isNotEmpty ? str(j['url']) : str(j['sameAs'] is List ? '' : j['sameAs']),
      'location': address(j['address']),
      'about': htmlToText(str(j['description'])),
    },
    from: from,
    url: pageUrl,
  );

  for (final j in ldObjects(scripts)) {
    final types = ldTypes(j);
    if (types.contains('JobPosting')) {
      final p = jobPostingFromLd(j, pageUrl: pageUrl);
      if (p == null) continue;
      out.add(
        PageRecord(
          RecordKind.job,
          {
            'title': p.title,
            'company': p.company,
            'location': p.location,
            'salary': p.salaryText.isNotEmpty
                ? p.salaryText
                : p.salaryMin == null
                ? ''
                : '${p.currency} ${p.salaryMin}${p.salaryMax != null && p.salaryMax != p.salaryMin ? ' to ${p.salaryMax}' : ''}'
                      .trim(),
            'closing': p.closing ?? '',
            'posted': p.posted ?? '',
            'reference': str(j['identifier'] is Map ? obj(j['identifier'])['value'] : j['identifier']),
            'description': p.description,
          },
          from: from,
          url: p.url.isNotEmpty ? p.url : pageUrl,
        ),
      );
      if (j['hiringOrganization'] is Map) out.add(org(obj(j['hiringOrganization'])));
    } else if (types.contains('Person')) {
      out.add(
        PageRecord(
          RecordKind.person,
          {
            'name': text(j['name']),
            'title': str(j['jobTitle'] is List ? (j['jobTitle'] as List).map(str).join(', ') : j['jobTitle']),
            'company': text(j['worksFor'] is List ? (j['worksFor'] as List).firstOrNull : j['worksFor']),
            'email': str(j['email']).replaceFirst(RegExp('^mailto:'), ''),
            'phone': str(j['telephone']),
            'profileUrl': sameAs(j, 'linkedin.com').isNotEmpty ? sameAs(j, 'linkedin.com') : str(j['url']),
          },
          from: from,
          url: pageUrl,
        ),
      );
    } else if (types.any(_orgTypes.contains)) {
      out.add(org(j));
    }
  }
  return out;
}

final _advertSigns = [
  RegExp(r'clos(?:ing date|es)\b', caseSensitive: false),
  RegExp(r'salary|£\s?\d|€\s?\d|\$\s?\d|per annum|a year\b|an hour\b', caseSensitive: false),
  RegExp(
    r'job (?:description|summary|purpose)|about the role|main duties|responsibilities',
    caseSensitive: false,
  ),
  RegExp(r'person specification|essential criteria|requirements|qualifications', caseSensitive: false),
  RegExp(
    r'full[- ]time|part[- ]time|permanent|fixed[- ]term|contract type|hours per week',
    caseSensitive: false,
  ),
  RegExp(r'\bapply\b', caseSensitive: false),
];

/// True when [text] reads like a job advert (three or more of its signs).
bool looksLikeAdvert(String text) => _advertSigns.where((r) => r.hasMatch(text)).length >= 3;

/// The value after a "Label:" at the start of a line.
String _labelled(String text, List<String> labels) {
  final m = RegExp(
    '^\\s*(?:${labels.join('|')})\\s*[:\\-–]\\s*(.{2,120})\$',
    multiLine: true,
    caseSensitive: false,
  ).firstMatch(text);
  return m?.group(1)?.trim() ?? '';
}

/// Records from plain text: the page's own text, OCR of a screenshot or
/// pasted text. A job when it reads like an advert (its title from a "Job
/// title:" line, else the page title, else its first short line), the
/// employer a "Employer:" line names, and the contacts it lists.
List<PageRecord> recordsFromText(
  String text, {
  String url = '',
  String title = '',
  String from = 'page text',
}) {
  final out = <PageRecord>[];
  final t = text.replaceAll('\r', '');
  if (t.trim().isEmpty) return out;
  final employer = _labelled(t, [
    'Employer',
    'Company',
    'Organisation',
    'Organization',
    'Hiring organisation',
  ]);
  if (looksLikeAdvert(t)) {
    var jobTitle = _labelled(t, ['Job title', 'Position', 'Post', 'Role', 'Vacancy']);
    if (jobTitle.isEmpty) jobTitle = title.split(RegExp(r'\s[|–-]\s')).first.trim();
    if (jobTitle.isEmpty) {
      jobTitle =
          t
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.length >= 4 && l.length <= 80 && RegExp('[A-Za-z]{3}').hasMatch(l))
              .firstOrNull ??
          '';
    }
    final salary = _labelled(t, ['Salary', 'Pay', 'Pay band', 'Pay scale', 'Wage']);
    out.add(
      PageRecord(
        RecordKind.job,
        {
          'title': jobTitle,
          'company': employer,
          'location': _labelled(t, ['Location', 'Base', 'Site', 'Town']),
          'salary': salary.isNotEmpty
              ? salary
              : (RegExp(r'£\s?[\d,]{4,}[^\n]{0,40}').firstMatch(t)?.group(0) ?? ''),
          'closing': closingIn(t) ?? _labelled(t, ['Closing date', 'Closes', 'Deadline']),
          'reference': _labelled(t, ['Reference', 'Reference number', 'Job reference', 'Job ref', 'Ref']),
          'description': t.trim(),
        },
        from: from,
        url: url,
      ),
    );
  }
  if (employer.isNotEmpty) {
    out.add(PageRecord(RecordKind.company, {'name': employer}, from: from, url: url));
  }
  for (final c in advertContacts(t)) {
    out.add(
      PageRecord(
        RecordKind.person,
        {'name': c.name, 'title': c.title, 'company': employer, 'email': c.email, 'phone': c.phone},
        from: from,
        url: url,
      ),
    );
  }
  return out;
}

/// The JSON schema an AI vision model answers in when it reads a
/// screenshot: the same records, nothing invented.
final visionRecordsSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'records': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'kind': {
            'type': 'string',
            'enum': ['job', 'person', 'company'],
          },
          'fields': {
            'type': 'object',
            'properties': {
              for (final f in {for (final k in RecordKind.values) ...k.fields}) f: {'type': 'string'},
            },
          },
        },
        'required': ['kind', 'fields'],
      },
    },
  },
  'required': ['records'],
};

/// The records in an AI's [answer] to [visionRecordsSchema].
List<PageRecord> recordsFromVision(Json answer, {required String url}) => [
  for (final r in objs(answer['records']))
    if (RecordKind.of(str(r['kind'])) case final kind?)
      PageRecord(kind, {for (final e in obj(r['fields']).entries) e.key: str(e.value)}, from: 'AI', url: url),
].where((r) => r.usable).toList();
