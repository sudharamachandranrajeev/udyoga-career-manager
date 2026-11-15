import 'book.dart';
import 'countries.dart';
import 'insights.dart';

// The lead finder: search links the user opens and reads by hand, and
// people named in job adverts. Udyoga never reads a search result or a
// profile itself; the user pastes in who they found, and where.

/// A search the user opens in their browser. People saved from it get
/// [sourceKind] and [source] (as "I came across your name on [source]")
/// as where they were found.
typedef LeadSearch = ({String label, String why, Uri uri, String sourceKind, String source});

/// Searches for people in [role] at [employer] in [place].
List<LeadSearch> leadSearches({required String role, String employer = '', String place = ''}) {
  String q(String s) => s.trim().isEmpty ? '' : '"${s.trim()}"';
  String join(List<String> parts) => parts.where((s) => s.trim().isNotEmpty).join(' ');
  Uri google(String query) => Uri.https('www.google.com', '/search', {'q': query});
  return [
    (
      label: 'LinkedIn people search',
      why: 'People in this role on LinkedIn. Open a profile, then save the person here.',
      uri: linkedInPeople(join([role, place]), company: employer),
      sourceKind: 'other',
      source: 'LinkedIn',
    ),
    (
      label: 'Google X-ray of LinkedIn',
      why: 'Public LinkedIn profiles that Google has, without signing in.',
      uri: google(join(['site:linkedin.com/in', q(role), q(employer), q(place)])),
      sourceKind: 'other',
      source: 'LinkedIn',
    ),
    if (employer.trim().isNotEmpty || place.trim().isNotEmpty)
      (
        label: 'Team and staff pages',
        why: 'The employer\'s own pages that name its teams.',
        uri: google(
          join([
            q(employer.trim().isEmpty ? place : employer),
            '("meet the team" OR "our team" OR "who\'s who" OR "our staff")',
            q(role),
            '-site:linkedin.com',
          ]),
        ),
        sourceKind: 'team_page',
        source: '',
      ),
    (
      label: 'NHS Jobs adverts',
      why: 'Adverts name a contact for informal enquiries. Save the job, and its contact shows below.',
      uri: Uri.https('www.jobs.nhs.uk', '/candidate/search/results', {
        'keyword': join([role, employer]),
        if (place.trim().isNotEmpty) 'location': place.trim(),
      }),
      sourceKind: 'advert',
      source: 'an NHS Jobs advert',
    ),
  ];
}

/// A person a job advert names for enquiries.
typedef AdvertContact = ({String name, String title, String email, String phone});

final _trigger = RegExp(
  r'informal (?:enquir|inquir|discussion|chat|visit)|further (?:information|details)|more information|'
  r'any (?:questions|queries)|please contact|contact details|for an informal',
  caseSensitive: false,
);
final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
final _phone = RegExp(r'(?:\+44\s?\(?0?\)?\s?|\b0)\d{2,4}[\s-]?\d{3,4}[\s-]?\d{3,4}\b');
final _name = RegExp(
  r"\b(?:(?:Dr|Mr|Mrs|Ms|Miss|Mx|Prof)\.?\s+)?[A-Z][a-zA-Z'\-]*[a-z](?:\s+[A-Z][a-zA-Z'\-]*[a-z]){1,2}\b",
);
const _notNames = {
  'informal', 'enquiries', 'enquiry', 'further', 'information', 'please', 'contact', 'job', 'description', //
  'person', 'specification', 'trust', 'foundation', 'team', 'department', 'service', 'services', 'hospital',
  'hospitals', 'the', 'for', 'email', 'tel', 'telephone', 'phone', 'manager', 'lead', 'head', 'director',
  'officer', 'senior', 'band', 'details', 'name', 'title', 'address', 'number', 'questions', 'visit', 'via',
  'on', 'or', 'and', 'health', 'care', 'clinical', 'digital', 'nurse', 'practice', 'assistant', 'support',
  'apply', 'application', 'employer', 'interview', 'interviews', 'date', 'closing', 'recruitment',
};

/// People an advert names for informal enquiries or further information,
/// with their job title, e-mail address and phone number when given. Both
/// the sentence form ("For informal enquiries contact Jordan Example, Digital
/// Lead, on ...") and NHS Jobs' contact block ("Name / Job title / Email
/// address") are read.
List<AdvertContact> advertContacts(String advert) {
  final text = advert
      .replaceAll(RegExp(r'<br\s*/?>|</p>|</div>|</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('\r', '');
  final found = <AdvertContact>[];
  void add(String name, String title, String email, String phone) {
    final n = name.trim(), e = email.trim().toLowerCase();
    if (n.isEmpty && e.isEmpty) return;
    final same = found.indexWhere((f) => (n.isNotEmpty && f.name == n) || (e.isNotEmpty && f.email == e));
    final c = (name: n, title: title.trim(), email: e, phone: phone.trim());
    if (same < 0) {
      found.add(c);
    } else {
      final f = found[same];
      found[same] = (
        name: f.name.isEmpty ? c.name : f.name,
        title: f.title.isEmpty ? c.title : f.title,
        email: f.email.isEmpty ? c.email : f.email,
        phone: f.phone.isEmpty ? c.phone : f.phone,
      );
    }
  }

  // NHS Jobs' block: each label on its own line, its value on the next.
  final block = RegExp(
    r'^\s*Name\s*:?\s*\n?\s*(.+?)\s*\n\s*Job title\s*:?\s*\n?\s*(.+?)\s*\n'
    r'(?:\s*Email address\s*:?\s*\n?\s*(\S+@\S+)\s*\n?)?'
    r'(?:\s*Telephone number\s*:?\s*\n?\s*([+\d][\d\s]+\d))?',
    multiLine: true,
    caseSensitive: false,
  );
  for (final m in block.allMatches(text)) {
    add(m.group(1)!, m.group(2)!, m.group(3) ?? '', m.group(4) ?? '');
  }

  for (final t in _trigger.allMatches(text)) {
    final rest = text.substring(t.end);
    final end = [
      rest.length,
      330,
      if (_trigger.firstMatch(rest) case final next?) next.start,
      if (rest.indexOf('\n\n') case final i when i > 0) i,
    ].reduce((a, b) => a < b ? a : b);
    final window = rest.substring(0, end);
    final email = _email.firstMatch(window)?.group(0) ?? '';
    final phone = _phone.firstMatch(window)?.group(0) ?? '';
    final name = _name
        .allMatches(window)
        .where(
          (m) =>
              !m.group(0)!.split(RegExp(r'\s+')).any((w) => _notNames.contains(w.toLowerCase())) &&
              !(email.isNotEmpty &&
                  window.indexOf(email) <= m.start &&
                  m.start < window.indexOf(email) + email.length),
        )
        .firstOrNull;
    if (name == null && email.isEmpty) continue;
    var title = '';
    if (name != null) {
      final after = window.substring(name.end);
      final m = RegExp(r'^\s*(?:,|\(|-|–|\n)\s*([^,(\n;]+?)\s*(?:[,);\n]|\bon\b|\bat\b|\bvia\b|\bor\b|$)')
          .firstMatch(after);
      final t = m?.group(1)?.trim() ?? '';
      if (t.length >= 3 &&
          t.length <= 80 &&
          !_email.hasMatch(t) &&
          !_phone.hasMatch(t) &&
          RegExp('[A-Za-z]{3}').hasMatch(t)) {
        title = t;
      }
    }
    add(name?.group(0) ?? '', title, email, phone);
  }
  return found;
}

extension LeadFinderBook on CareerBook {
  /// Saves a person the user found by hand: where they were found
  /// ([sourceKind], [source], [sourceUrl]) and today's date are recorded
  /// with them. False when they are already a contact or marked "do not
  /// contact".
  Future<bool> saveFoundLead({
    required String name,
    String title = '',
    String company = '',
    String email = '',
    String phone = '',
    String linkedin = '',
    String kind = 'peer',
    required String sourceKind,
    String source = '',
    String sourceUrl = '',
    String note = '',
    String? jobId,
    required String today,
  }) async =>
      await importLeads(
        [
          LeadSuggestion({
            'name': name.trim(),
            'title': title.trim(),
            'company': company.trim(),
            'kind': kind,
            'email': email.trim(),
            'phone': phone.trim(),
            'linkedin': linkedin.trim().isNotEmpty
                ? linkedin.trim()
                : (sourceUrl.contains('linkedin.com/in/') ? sourceUrl.trim() : ''),
            'source': source.trim(),
            'sourceUrl': sourceUrl.trim(),
            'why': note.trim(),
            'approach': '',
          }),
        ],
        jobId: jobId,
        today: today,
        sourceKind: sourceKind,
      ) ==
      1;
}
