import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'feeds.dart';
import 'profile.dart';

/// A row of a LinkedIn export CSV, by header in lower case.
typedef CsvRow = Map<String, String>;

/// What a LinkedIn import added, part by part.
typedef LinkedInImport = ({
  int jobs,
  int skills,
  int certifications,
  int wins,
  int applications,
  int savedJobs,
  int contacts,
  int messages,
  int invitations,
});

/// The parts of the archive LinkedIn gives a member (Settings > Data privacy
/// > Get a copy of your data) that help a job search. It is read on the
/// device: nothing is fetched from LinkedIn, so the account is never at risk.
/// LinkedIn renames columns now and then, so every column is looked up
/// leniently and a missing file reads as empty.
class LinkedInExport {
  const LinkedInExport({
    this.profile = const {},
    this.positions = const [],
    this.education = const [],
    this.skills = const [],
    this.certifications = const [],
    this.languages = const [],
    this.honors = const [],
    this.recommendations = const [],
    this.connections = const [],
    this.applications = const [],
    this.savedJobs = const [],
    this.messages = const [],
    this.invitations = const [],
  });

  final CsvRow profile;
  final List<CsvRow> positions, education, certifications, honors, recommendations, connections;
  final List<CsvRow> applications, savedJobs;

  /// messages.csv (one row per message, grouped by conversation id) and
  /// Invitations.csv (connection requests sent and received).
  final List<CsvRow> messages, invitations;
  final List<String> skills, languages;

  bool get isEmpty =>
      profile.isEmpty &&
      positions.isEmpty &&
      skills.isEmpty &&
      connections.isEmpty &&
      applications.isEmpty &&
      recommendations.isEmpty &&
      messages.isEmpty &&
      invitations.isEmpty;

  /// Reads the export ZIP. Throws a [FormatException] when it is not one.
  factory LinkedInExport.read(Uint8List zip) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zip);
    } catch (_) {
      throw const FormatException('That is not a ZIP file. Choose the archive LinkedIn sent you.');
    }
    final files = {
      for (final f in archive.files)
        if (f.isFile && f.name.toLowerCase().endsWith('.csv'))
          f.name.split('/').last.toLowerCase(): utf8.decode(f.content, allowMalformed: true),
    };
    List<CsvRow> rows(String name, {String header = ''}) => readCsv(files[name] ?? '', header: header);
    final export = LinkedInExport(
      profile: rows('profile.csv').firstOrNull ?? const {},
      positions: rows('positions.csv'),
      education: rows('education.csv'),
      skills: [for (final r in rows('skills.csv')) ?_nonEmpty(r['name'])],
      certifications: rows('certifications.csv'),
      languages: [for (final r in rows('languages.csv')) ?_nonEmpty(r['name'])],
      honors: rows('honors.csv'),
      recommendations: rows('recommendations_received.csv'),
      // Connections.csv opens with a few lines of notes before its header.
      connections: rows('connections.csv', header: 'first name'),
      applications: rows('job applications.csv'),
      savedJobs: rows('saved jobs.csv'),
      messages: rows('messages.csv'),
      invitations: rows('invitations.csv'),
    );
    if (export.isEmpty) {
      throw const FormatException(
        'No LinkedIn data found in that ZIP. Choose the archive from LinkedIn > Settings > Data privacy > '
        'Get a copy of your data.',
      );
    }
    return export;
  }

  /// The profile with what LinkedIn adds: empty fields filled in, jobs and
  /// education the profile lacks, and every skill, certification and
  /// language. Nothing the user already has is changed.
  CandidateProfile mergeInto(CandidateProfile p) {
    final name = [
      _col(profile, 'first name'),
      _col(profile, 'last name'),
    ].where((s) => s.isNotEmpty).join(' ');
    final jobs = [...p.experience];
    for (final r in positions) {
      final org = _col(r, 'company name');
      final title = _col(r, 'title');
      if (org.isEmpty && title.isEmpty) continue;
      final start = linkedInDate(_col(r, 'started on'));
      final i = jobs.indexWhere(
        (e) =>
            _same(e.organisation, org) &&
            (_same(e.title, title) || (start.isNotEmpty && e.start.startsWith(start))),
      );
      final highlights = [
        for (final l in _col(r, 'description').split(RegExp(r'\n+')))
          if (l.replaceFirst(RegExp(r'^[\s•*\-–]+'), '').trim() case final t when t.isNotEmpty) t,
      ];
      if (i < 0) {
        jobs.add(
          Experience(
            title: title,
            organisation: org,
            location: _col(r, 'location'),
            start: start,
            end: linkedInDate(_col(r, 'finished on')),
            highlights: highlights,
          ),
        );
      } else if (jobs[i].highlights.isEmpty && highlights.isNotEmpty) {
        final e = jobs[i];
        jobs[i] = Experience(
          title: e.title,
          organisation: e.organisation,
          location: e.location.isEmpty ? _col(r, 'location') : e.location,
          start: e.start.isEmpty ? start : e.start,
          end: e.end,
          highlights: highlights,
        );
      }
    }
    jobs.sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
    final schools = [...p.education];
    for (final r in education) {
      final school = _col(r, 'school name');
      if (school.isEmpty || schools.any((e) => _same(e.institution, school))) continue;
      schools.add(
        Education(
          qualification: _col(r, 'degree name'),
          institution: school,
          year: linkedInDate(_col(r, 'end date')).split('-').first,
        ),
      );
    }
    final current = jobs.where((e) => e.current).firstOrNull;
    return p.copyWith(
      name: p.name.isEmpty ? name : null,
      headline: p.headline.isEmpty ? _col(profile, 'headline') : null,
      location: p.location.isEmpty ? _col(profile, 'geo location') : null,
      summary: p.summary.isEmpty ? _col(profile, 'summary') : null,
      currentRole: p.currentRole.isEmpty ? current?.title : null,
      currentEmployer: p.currentEmployer.isEmpty ? current?.organisation : null,
      experience: jobs,
      education: schools,
      skills: _union(p.skills, skills),
      certifications: _union(p.certifications, [for (final c in certifications) ?_nonEmpty(_col(c, 'name'))]),
      languages: _union(p.languages, languages),
      achievements: _union(p.achievements, [
        for (final h in honors)
          if (_col(h, 'title') case final t when t.isNotEmpty) t,
      ]),
    );
  }

  /// Connections worth having as contacts: people at an employer the user
  /// is applying to or watching, and recruiters. A whole network would bury
  /// the few who matter.
  List<CsvRow> usefulConnections(Iterable<String> companies) => [
    for (final c in connections)
      if (atEmployer(_col(c, 'company'), companies) || isRecruiter(_col(c, 'position'))) c,
  ];

  /// The member's own name, to tell their messages from other people's: the
  /// profile's, or else the one person in the most conversations.
  String get ownName {
    final named = [
      _col(profile, 'first name'),
      _col(profile, 'last name'),
    ].where((s) => s.isNotEmpty).join(' ');
    if (named.isNotEmpty) return named;
    final seen = <String, Set<String>>{};
    for (final m in messages) {
      for (final n in [_col(m, 'from'), ..._list(_col(m, 'to'))]) {
        if (n.isNotEmpty) (seen[_person(n)] ??= {}).add(_col(m, 'conversation id'));
      }
    }
    final names = {
      for (final m in messages)
        for (final n in [_col(m, 'from'), ..._list(_col(m, 'to'))]) _person(n): n,
    };
    final top = seen.entries.fold<MapEntry<String, Set<String>>?>(
      null,
      (best, e) => best == null || e.value.length > best.value.length ? e : best,
    );
    return top == null ? '' : names[top.key] ?? '';
  }

  /// The conversations in messages.csv, each with its messages oldest first.
  /// Drafts and the spam folder are left out.
  List<LinkedInThread> threads() {
    final me = _person(ownName);
    final byId = <String, List<CsvRow>>{};
    for (final m in messages) {
      final id = _col(m, 'conversation id');
      if (id.isEmpty || _col(m, 'folder').toLowerCase().contains('spam')) continue;
      if (RegExp(r'^(yes|true)$', caseSensitive: false).hasMatch(_col(m, 'is message draft'))) continue;
      (byId[id] ??= []).add(m);
    }
    final out = <LinkedInThread>[];
    for (final MapEntry(key: id, value: rows) in byId.entries) {
      final people = <String, LinkedInPerson>{};
      void add(String name, String url) {
        final key = _person(name);
        if (key.isEmpty || key == me) return;
        final had = people[key];
        if (had == null || had.url.isEmpty) people[key] = (name: name.trim(), url: url.trim());
      }

      final said = <LinkedInMessage>[];
      for (final r in rows) {
        final from = _col(r, 'from');
        add(from, _col(r, 'sender profile url'));
        final to = _list(_col(r, 'to'));
        final urls = _list(_col(r, 'recipient profile urls'));
        for (final (i, n) in to.indexed) {
          add(n, to.length == urls.length ? urls[i] : '');
        }
        final at = linkedInTime(_col(r, 'date'));
        final body = _col(r, 'content');
        if (at == null || body.isEmpty) continue;
        said.add((
          out: _person(from) == me,
          at: at,
          body: body,
          key: 'li:${_hash('$id|${_col(r, 'date')}|$from|$body')}',
        ));
      }
      if (said.isEmpty || people.isEmpty) continue;
      said.sort((a, b) => a.at.compareTo(b.at));
      final title = _col(rows.first, 'conversation title').ifBlank(_col(rows.first, 'subject'));
      out.add((id: id, title: title, people: people.values.toList(), messages: said));
    }
    return out..sort((a, b) => a.messages.last.at.compareTo(b.messages.last.at));
  }

  /// Connection requests from Invitations.csv, oldest first.
  List<LinkedInInvite> invites() => [
    for (final r in invitations)
      if ((_col(r, 'direction').toLowerCase().startsWith('out'), linkedInTime(_col(r, 'sent at'))) case (
        final out,
        final at?,
      ))
        if ((out ? _col(r, 'to') : _col(r, 'from')) case final name when name.isNotEmpty)
          (
            out: out,
            at: at,
            name: name,
            url: out ? _col(r, 'invitee profile url') : _col(r, 'inviter profile url'),
            body: _col(r, 'message'),
            key: 'invite:${_hash('${_col(r, 'direction')}|$name|${_col(r, 'sent at')}')}',
          ),
  ]..sort((a, b) => a.at.compareTo(b.at));

  /// Saved jobs from the last [days] days, as postings.
  List<Posting> savedPostings({required String today, int days = 90}) => [
    for (final r in savedJobs)
      if (_col(r, 'job title') case final title when title.isNotEmpty)
        if (linkedInDate(_col(r, 'saved date')) case final saved
            when saved.isEmpty || _within(saved, today, days))
          Posting(
            source: 'linkedin',
            sourceId: _col(r, 'job url'),
            title: title,
            company: _col(r, 'company name'),
            url: _col(r, 'job url'),
          ),
  ];

  /// Applications sent through LinkedIn in the last [days] days.
  List<CsvRow> recentApplications({required String today, int days = 180}) => [
    for (final r in applications)
      if (_col(r, 'job title').isNotEmpty)
        if (linkedInDate(_col(r, 'application date')) case final d when d.isEmpty || _within(d, today, days))
          r,
  ];
}

/// A person in a LinkedIn conversation other than the member.
typedef LinkedInPerson = ({String name, String url});

/// One message of a LinkedIn conversation. [key] stays the same however
/// often the archive is imported.
typedef LinkedInMessage = ({bool out, DateTime at, String body, String key});

/// One conversation from messages.csv.
typedef LinkedInThread = ({
  String id,
  String title,
  List<LinkedInPerson> people,
  List<LinkedInMessage> messages,
});

/// One connection request: [out] when the member sent it.
typedef LinkedInInvite = ({bool out, DateTime at, String name, String url, String body, String key});

/// A column of [r] by its lower-case header, tolerating small renames
/// ("Company Name" or "Company").
String col(CsvRow r, String name) => _col(r, name);

String _col(CsvRow r, String name) {
  final v = r[name] ?? r[name.replaceAll(' name', '')] ?? r[name.replaceAll(' ', '')];
  return (v ?? '').trim();
}

extension on String {
  String ifBlank(String other) => trim().isEmpty ? other : this;
}

/// Names or profile links separated by commas.
List<String> _list(String s) => [for (final p in s.split(',')) ?_nonEmpty(p)];

/// A name in one form, to compare.
String _person(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// FNV-1a, so a message's key is the same on every import and device.
String _hash(String s) {
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode(s)) {
    h = (h ^ b) * 0x100000001b3;
  }
  return h.toUnsigned(64).toRadixString(16);
}

String? _nonEmpty(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\b(ltd|limited|inc|plc|llc|gmbh|corp|corporation|co)\b\.?'), '')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _same(String a, String b) => _norm(a).isNotEmpty && _norm(a) == _norm(b);

/// An employer's name without what varies between the ways it is written:
/// "Example Teaching Hospitals NHS Foundation Trust" and "Example Teaching
/// Hospitals" read the same.
String employerKey(String name) {
  final words = name
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  final kept = words.where((w) => !_employerNoise.contains(w)).toList();
  return (kept.isEmpty ? words : kept).join(' ');
}

const _employerNoise = {
  'the', 'nhs', 'foundation', 'trust', 'ft', 'uk', 'ltd', 'limited', 'plc', 'inc', 'llc', 'co', //
  'corp', 'corporation', 'gmbh', 'group',
};

/// Whether [a] and [b] name the same employer: the same [employerKey], or
/// one starting with the other when the shorter has two words or more
/// ("Example Health" and "Example Health and Care").
bool sameEmployer(String a, String b) {
  final x = employerKey(a), y = employerKey(b);
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  final (short, long) = x.length < y.length ? (x, y) : (y, x);
  return short.contains(' ') && long.startsWith('$short ');
}

/// Whether [company] is one of [employers].
bool atEmployer(String company, Iterable<String> employers) => employers.any((e) => sameEmployer(company, e));

String _sortKey(Experience e) => e.current ? '9999' : (e.end.isEmpty ? e.start : e.end);

List<String> _union(List<String> a, List<String> b) {
  final seen = {for (final s in a) s.toLowerCase().trim()};
  return [...a, ...b.where((s) => s.trim().isNotEmpty && seen.add(s.toLowerCase().trim()))];
}

bool _within(String date, String today, int days) {
  final d = DateTime.tryParse(date.length == 7 ? '$date-01' : date);
  final t = DateTime.tryParse(today);
  return d == null || t == null || t.difference(d).inDays <= days;
}

/// Whether a job title is a recruiter's.
bool isRecruiter(String position) => RegExp(
  r'recruit|talent|sourcer|headhunt|hiring|resourcing|\bhr\b|people partner',
  caseSensitive: false,
).hasMatch(position);

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// A LinkedIn date ("Mar 2021", "2021", "14 Mar 2024", "3/14/24, 10:22 AM",
/// "2024-03-14 10:22 UTC") as yyyy-MM-dd, yyyy-MM or yyyy; '' when there is
/// none.
String linkedInDate(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  if (RegExp(r'^(\d{4})-(\d{2})(-(\d{2}))?').firstMatch(t) case final m?) return m.group(0)!;
  if (RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})').firstMatch(t) case final m?) {
    final y = int.parse(m.group(3)!);
    return '${y < 100 ? 2000 + y : y}-${two(int.parse(m.group(1)!))}-${two(int.parse(m.group(2)!))}';
  }
  final words = t.toLowerCase().split(RegExp(r'[\s,]+'));
  final year = words.lastWhere((w) => RegExp(r'^\d{4}$').hasMatch(w), orElse: () => '');
  if (year.isEmpty) return '';
  final month = words.map((w) => _months[w.length >= 3 ? w.substring(0, 3) : w]).nonNulls.firstOrNull;
  if (month == null) return year;
  final day = words.map(int.tryParse).nonNulls.where((n) => n >= 1 && n <= 31).firstOrNull;
  return day == null ? '$year-${two(month)}' : '$year-${two(month)}-${two(day)}';
}

/// A LinkedIn timestamp as local time: "2024-03-14 10:22:33 UTC" (messages)
/// or "3/14/24, 10:22 AM" (invitations, already local). Null when it is not
/// one.
DateTime? linkedInTime(String s) {
  final t = s.trim();
  if (RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(t) case final m?) {
    final p = [for (var i = 1; i <= 6; i++) int.tryParse(m.group(i) ?? '') ?? 0];
    final local = !RegExp(r'(UTC|GMT|Z)\s*$|[+-]00:?00$').hasMatch(t);
    return local
        ? DateTime(p[0], p[1], p[2], p[3], p[4], p[5])
        : DateTime.utc(p[0], p[1], p[2], p[3], p[4], p[5]).toLocal();
  }
  if (RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(t)
      case final m?) {
    final y = int.parse(m.group(3)!);
    var h = int.parse(m.group(4)!);
    final pm = m.group(6)?.toLowerCase();
    if (pm == 'pm' && h < 12) h += 12;
    if (pm == 'am' && h == 12) h = 0;
    return DateTime(
      y < 100 ? 2000 + y : y,
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      h,
      int.parse(m.group(5)!),
    );
  }
  final day = linkedInDate(t);
  return day.length == 10 ? DateTime.tryParse(day) : null;
}

/// Parses CSV text (RFC 4180: quoted fields, doubled quotes, newlines in
/// quotes) into rows keyed by the lower-case header. With [header], rows
/// before the first one holding that column are skipped.
List<CsvRow> readCsv(String text, {String header = ''}) {
  final records = <List<String>>[];
  var field = StringBuffer();
  var record = <String>[];
  var quoted = false;
  final s = text.startsWith('﻿') ? text.substring(1) : text;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      record.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < s.length && s[i + 1] == '\n') i++;
      record.add(field.toString());
      field = StringBuffer();
      if (record.any((f) => f.trim().isNotEmpty)) records.add(record);
      record = <String>[];
    } else {
      field.write(c);
    }
  }
  record.add(field.toString());
  if (record.any((f) => f.trim().isNotEmpty)) records.add(record);
  final start = header.isEmpty
      ? 0
      : records.indexWhere((r) => r.any((f) => f.trim().toLowerCase() == header));
  if (start < 0 || start >= records.length) return const [];
  final keys = [for (final k in records[start]) k.trim().toLowerCase()];
  return [
    for (final r in records.skip(start + 1))
      {
        for (final (i, k) in keys.indexed)
          if (k.isNotEmpty) k: i < r.length ? r[i] : '',
      },
  ];
}
