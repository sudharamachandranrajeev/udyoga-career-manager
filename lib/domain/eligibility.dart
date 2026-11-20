import 'countries.dart';
import 'profile.dart';
import 'work_rights.dart';

/// What an advert says about who may apply.
enum EligibilityKind {
  noSponsorship('No visa sponsorship'),
  sponsorshipOffered('Visa sponsorship offered'),
  nationalsOnly('Nationals or citizens only'),
  rightToWork('Must already have the right to work'),
  residence('Must already live there'),
  clearance('Security clearance'),
  language('Language'),
  localExperience('Local experience essential'),
  excluded('Ruled out by your exclusions');

  const EligibilityKind(this.label);
  final String label;
}

/// How much a finding matters, worst first. [clear] is a rule the person
/// meets (a "no sponsorship" line where they already have the right to
/// work); [info] is worth knowing but changes nothing.
enum Severity { blocker, caution, info, clear }

/// One line of an advert that limits who may apply, with the sentence it
/// came from, word for word.
class EligibilityFinding {
  const EligibilityFinding({
    required this.kind,
    required this.severity,
    required this.quote,
    this.subject = '',
    this.essential = true,
    this.level,
    this.note = '',
  });
  final EligibilityKind kind;
  final Severity severity;

  /// The advert's sentence, exactly as written.
  final String quote;

  /// What the rule is about: a country code ('GB', 'EU', 'GCC'), a
  /// language ('German'), a clearance level ('SC'), or the excluded word;
  /// '' when the advert does not say.
  final String subject;

  /// False for a "desirable" line.
  final bool essential;

  /// For a language: the level asked for.
  final LanguageLevel? level;

  /// Why it has this severity for this person, in a line.
  final String note;

  EligibilityFinding copyWith({Severity? severity, String? subject, String? note}) => EligibilityFinding(
    kind: kind,
    severity: severity ?? this.severity,
    quote: quote,
    subject: subject ?? this.subject,
    essential: essential,
    level: level,
    note: note ?? this.note,
  );

  /// A short title: the kind and its subject.
  String get title => switch (kind) {
    EligibilityKind.language =>
      '${essential ? '' : 'Desirable: '}$subject${level == null ? '' : ' (${level!.label.toLowerCase()})'}',
    EligibilityKind.clearance => subject.isEmpty ? kind.label : '${kind.label}: $subject',
    EligibilityKind.excluded => '${kind.label}: "$subject"',
    _ when subject.isNotEmpty => '${kind.label} (${_placeName(subject)})',
    _ => kind.label,
  };

  @override
  String toString() => '${kind.name}/${severity.name} [$subject] "$quote"';
}

String _placeName(String code) => code.contains(',')
    ? _orList(code.split(',').map(_placeName).toList())
    : switch (code) {
        'EU' => 'EU/EEA',
        'GCC' => 'Gulf states',
        _ => Country.nameOf(code),
      };

String _orList(List<String> xs) =>
    xs.length < 2 ? xs.join() : '${xs.take(xs.length - 1).join(', ')} or ${xs.last}';

const _gcc = {'AE', 'SA', 'QA', 'OM', 'KW', 'BH'};

/// What an advert's eligibility lines mean for one person.
class EligibilityCheck {
  const EligibilityCheck(this.findings);
  final List<EligibilityFinding> findings;

  static const none = EligibilityCheck([]);

  bool get excluded => findings.any((f) => f.kind == EligibilityKind.excluded);
  bool get blocked => findings.any((f) => f.severity == Severity.blocker);
  bool get cautious => findings.any((f) => f.severity == Severity.caution);

  /// Findings worth showing, worst first.
  List<EligibilityFinding> get sorted =>
      [...findings]..sort((a, b) => a.severity.index.compareTo(b.severity.index));

  /// The worst severity, or null with no findings.
  Severity? get worst => findings.isEmpty ? null : sorted.first.severity;
}

// ---- reading an advert ----

/// The advert's sentences: split at line breaks, bullets and full stops,
/// each as written (trimmed).
List<String> sentencesOf(String text) {
  final out = <String>[];
  final lines = [
    for (final raw in text.split(RegExp(r'[\n\r]+')))
      for (final part in raw.split(RegExp(r'\s[•·▪●◦]\s')))
        part.replaceFirst(RegExp(r'^\s*(?:[•·▪●◦*\-–]|\d{1,2}[.)])\s+'), ''),
  ];
  for (final line in lines) {
    var start = 0;
    final ends = RegExp(r'[.!?;](?=\s+["“(]?[A-Z0-9])');
    for (final m in ends.allMatches(line)) {
      // "e.g." and "U.K." are not ends of sentences.
      final before = line.substring(start, m.start + 1);
      if (RegExp(r'(\b[A-Za-z]\.[A-Za-z]\.?|\be\.g|\bi\.e|\betc|\bNo|\bSt|\bDr|\bMr|\bMrs|\bMs)\.$')
          .hasMatch(before)) {
        continue;
      }
      out.add(before.trim());
      start = m.end;
    }
    out.add(line.substring(start).trim());
  }
  return out.where((s) => s.length > 3).toList();
}

const _languages = [
  'English', 'German', 'French', 'Spanish', 'Italian', 'Portuguese', 'Dutch', 'Flemish', 'Arabic', //
  'Welsh', 'Irish', 'Gaelic', 'Hindi', 'Urdu', 'Mandarin', 'Chinese', 'Cantonese', 'Japanese', 'Korean',
  'Polish', 'Swedish', 'Norwegian', 'Danish', 'Finnish', 'Icelandic', 'Russian', 'Ukrainian', 'Turkish',
  'Greek', 'Hebrew', 'Malay', 'Bahasa', 'Indonesian', 'Tagalog', 'Filipino', 'Thai', 'Vietnamese',
  'Romanian', 'Hungarian', 'Czech', 'Slovak', 'Bulgarian', 'Croatian', 'Serbian', 'Bengali', 'Punjabi',
  'Tamil', 'Malayalam', 'Telugu', 'Gujarati', 'Marathi', 'Kannada', 'Farsi', 'Persian', 'Swahili',
  'Afrikaans', 'Luxembourgish', 'Estonian', 'Latvian', 'Lithuanian', 'Maltese', 'Slovenian',
];

final _lang = _languages.join('|');

/// Nationality words and the country they mean.
const _nationalities = {
  'emirati': 'AE', 'uae': 'AE', 'saudi': 'SA', 'qatari': 'QA', 'omani': 'OM', 'kuwaiti': 'KW', //
  'bahraini': 'BH', 'gcc': 'GCC', 'us': 'US', 'u.s.': 'US', 'american': 'US', 'united states': 'US',
  'british': 'GB', 'uk': 'GB', 'irish': 'IE', 'canadian': 'CA', 'australian': 'AU', 'new zealand': 'NZ',
  'indian': 'IN', 'german': 'DE', 'french': 'FR', 'dutch': 'NL', 'singapore': 'SG', 'singaporean': 'SG',
  'eu': 'EU', 'eea': 'EU', 'european': 'EU', 'swiss': 'CH', 'spanish': 'ES', 'italian': 'IT',
};

final _nat = (_nationalities.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
    .map(RegExp.escape)
    .join('|');

const _localisation = {
  'emirati': 'AE', 'saudi': 'SA', 'nitaqat': 'SA', 'qatari': 'QA', 'omani': 'OM', 'kuwaiti': 'KW', //
  'bahraini': 'BH',
};

RegExp _re(String pattern) => RegExp(pattern, caseSensitive: false);

/// The country a run of words names, trying the longest start first
/// ("United Kingdom without…" is GB); '' when none.
String placeIn(String words) {
  final w = words
      .replaceAll(RegExp(r'[,;:()]'), ' ')
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((s) => s.endsWith('.') && s.length > 4 ? s.substring(0, s.length - 1) : s)
      .toList();
  for (var n = w.length.clamp(0, 5); n > 0; n--) {
    final phrase = w.take(n).join(' ');
    final up = phrase.toUpperCase();
    if (up == 'EU' || up == 'EEA' || up == 'EUROPEAN UNION' || up == 'EUROPE') return 'EU';
    if (up == 'GCC' || up == 'GULF' || up == 'MIDDLE EAST') return 'GCC';
    // Two-letter words count only as codes written in capitals ("UK", not "in").
    if (phrase.length <= 3 && phrase != up) continue;
    final c = countryCode(phrase);
    if (c.isNotEmpty && Country.of(c) != null) return c;
  }
  return '';
}

const _place = r'((?:[\w.\-]+\s*){1,5})';

final _noSponsorship = [
  _re(
    r'\b(?:no|not\s+(?:be\s+)?(?:able|in\s+a\s+position)\s+to\s+(?:offer|provide|support|consider)|unable\s+to\s+(?:offer|provide|support|consider)'
    r"|cannot\s+(?:offer|provide|support)|can(?:'|’)t\s+(?:offer|provide|support)"
    r'|(?:do|does|will|are|is|would)\s+not\s+(?:be\s+)?(?:offer(?:ing)?|provid(?:e|ing)|support(?:ing)?|consider(?:ing)?)'
    r"|(?:don|doesn|won)(?:'|’)t\s+(?:offer|provide|support))\s+(?:any\s+)?(?:visa\s+|work\s+permit\s+|immigration\s+|skilled\s+worker\s+|employment\s+|h-?1b\s+)?sponsorship",
  ),
  _re(r'\bsponsorship\s+(?:is|will)\s+not\s+(?:be\s+)?(?:available|offered|provided|possible|considered)'),
  _re(r'\bsponsorship\s+(?:is\s+)?unavailable'),
  _re(
    r"\b(?:not|unable\s+to|cannot|can(?:'|’)t|will\s+not|won(?:'|’)t|do\s+not|does\s+not)\s+(?:be\s+able\s+to\s+)?sponsor\b",
  ),
  _re(r'\bnot\s+eligible\s+for\s+(?:visa\s+|skilled\s+worker\s+|tier\s*2\s+)?sponsorship'),
  _re(
    r'\bwithout\s+(?:the\s+need\s+for\s+|requiring\s+|needing\s+|the\s+need\s+of\s+)?(?:current\s+or\s+future\s+|now\s+or\s+in\s+the\s+future\s+|future\s+)?(?:visa\s+|employer\s+|employment\s+)?sponsorship',
  ),
  _re(
    r'\b(?:does|do)\s+not\s+(?:hold|have)\s+an?\s+(?:visa\s+|skilled\s+worker\s+)?sponsor(?:ship)?\s+licen[cs]e',
  ),
  _re(
    r'\b(?:unable|not\s+able)\s+to\s+(?:accept|consider)\s+(?:applications\s+from\s+)?(?:candidates|applicants|anyone|those|people|job\s?seekers|individuals)\s+(?:who|that)\s+(?:require|need|will\s+require)\s+(?:visa\s+|skilled\s+worker\s+)?sponsorship',
  ),
  _re(
    r'\b(?:does|do)\s+not\s+meet\s+the\s+(?:eligibility\s+)?(?:criteria|requirements)\s+for\s+(?:visa\s+|skilled\s+worker\s+)?sponsorship',
  ),
  _re(r'\b(?:visa\s+)?sponsorship\s*(?:available)?\s*[:\-–]\s*no\b'),
  _re(
    r'\bnot\s+(?:open|available)\s+to\s+(?:candidates|applicants)\s+(?:who|that)\s+(?:require|need)\s+(?:visa\s+)?sponsorship',
  ),
  _re(
    r'\b(?:requir|need)\w*\s+(?:visa\s+|skilled\s+worker\s+)?sponsorship\s+(?:will|would|can|cannot)\s*(?:not\s+)?be\s+(?:considered|accepted)',
  ),
  _re(r'\bnot\s+an?\s+(?:licensed|registered|approved)\s+(?:visa\s+)?sponsor'),
];

final _welcome = _re(
  r'\b(?:require|need|requiring|needing)\s+(?:current\s+)?(?:skilled\s+worker\s+|visa\s+)?sponsorship\b.{0,120}?\b(?:are\s+welcome|welcome\s+to\s+apply|will\s+be\s+considered|are\s+encouraged|can\s+apply)',
);

final _maybeNoSponsorship = _re(
  r'\bsponsorship\s+(?:may|might)\s+not\s+be\s+(?:available|offered|possible|provided)',
);

final _sponsorshipOffered = [
  _re(
    r'\b(?:visa\s+)?sponsorship\s+(?:is\s+|may\s+be\s+|can\s+be\s+|will\s+be\s+)?(?:available|offered|provided|considered|possible)\b',
  ),
  _re(
    r'\b(?:we|the\s+trust|the\s+employer|the\s+company|the\s+board|this\s+(?:post|role|position))\s+(?:can|will|are\s+able\s+to|is\s+able\s+to|may|would)\s+(?:offer|provide|consider|support)\s+(?:visa\s+|skilled\s+worker\s+)?sponsorship',
  ),
  _re(
    r'\b(?:require|need|requiring|needing)\s+(?:current\s+)?(?:skilled\s+worker\s+|visa\s+)?sponsorship\b.{0,120}?\b(?:welcome|will\s+be\s+considered|are\s+encouraged|can\s+apply)',
  ),
  _re(r'\b(?:licensed|registered|approved)\s+(?:visa\s+|skilled\s+worker\s+)?sponsor\b'),
  _re(r'\b(?:visa|sponsorship)\s*[:\-–]\s*(?:yes|provided|available)\b'),
  _re(r'\bvisa\s+(?:will\s+be\s+)?(?:provided|arranged)\b'),
  _re(r'\b(?:offer|offers|offering|provide|provides)\s+(?:visa\s+|skilled\s+worker\s+)?sponsorship\b'),
];

final _nationalsOnly = [
  _re('\\b($_nat)\\s+(?:nationals?|citizens?)(?:\\s+and\\s+(?:permanent\\s+residents|PRs?))?\\s+only\\b'),
  _re(
    '\\b(?:only|exclusively|restricted\\s+to|limited\\s+to|reserved\\s+for|open\\s+only\\s+to)\\s+(?:to\\s+)?($_nat)\\s+(?:nationals?|citizens?)',
  ),
  _re('\\bmust\\s+be\\s+an?\\s+($_nat)\\s+(?:citizen|national)'),
  _re('\\b($_nat)\\s+(?:citizenship|nationality)\\s+(?:is\\s+)?(?:required|essential|mandatory|needed)'),
  _re(r'\b(?:citizenship|nationality)\s+(?:is\s+)?(?:required|essential|mandatory)'),
  _re(r'\b(?:nationals?|citizens?)\s+only\b'),
  _re(r'\b(singaporeans?)\s+(?:and\s+PRs?\s+)?only\b'),
];

final _localisationRe = _re(
  r'\b(emirati|saudi|qatari|omani|kuwaiti|bahraini)(?:[sz]ation|i[sz]ation)\b|\b(nitaqat)\b',
);

final _civilServiceNationality = _re(
  r'\bnationality\s+(?:requirements|rules)\b|\bopen\s+to\s+the\s+following\s+groups',
);

final _rightToWork = [
  _re(
    r'\b(?:must|should|will\s+need\s+to|need\s+to|are\s+required\s+to|is\s+required\s+to)\s+(?:already\s+|currently\s+)?'
    r'(?:have|hold|possess|be\s+able\s+to\s+(?:demonstrate|provide\s+evidence\s+of|prove)|provide\s+(?:evidence|proof)\s+of)\s+'
    r'(?:the\s+|a\s+|an\s+|your\s+)?(?:(?:full|valid|existing|current|unrestricted|permanent|legal)\s+)*'
    r'(?:right\s+to\s+work|work(?:ing)?\s+(?:permit|visa|rights)|work\s+authori[sz]ation|eligibility\s+to\s+work|residence\s+(?:permit|visa))'
    '(?:\\s+(?:in|for)\\s+(?:the\\s+)?$_place)?',
  ),
  _re(
    r'\b(?:must|should|need\s+to)\s+(?:already\s+)?be\s+(?:legally\s+)?(?:eligible|authori[sz]ed|entitled|permitted|able)\s+to\s+(?:live\s+and\s+)?work\s+in\s+(?:the\s+)?'
    '$_place',
  ),
  _re(
    r'\b(?:(?:full|existing|current|valid|unrestricted)\s+)?right\s+to\s+work\s+in\s+(?:the\s+)?'
    '$_place'
    r'\s*(?:is\s+)?(?:required|essential|mandatory|needed)',
  ),
  _re(
    r'\b(?:legally\s+)?authori[sz]ed\s+to\s+work\s+(?:for\s+any\s+employer\s+)?in\s+the\s+(US|U\.S\.|United\s+States)',
  ),
  _re('\\bmust\\s+hold\\s+(?:a\\s+)?valid\\s+$_place\\s+(?:work\\s+)?visa'),
  _re(r'\btransferable\s+(?:visa|iqama|residence)\b'),
  _re(
    r"\b(?:on\s+)?(?:their|your|own)\s+(?:own\s+)?(?:visa|sponsorship)\b(?=.{0,40}\b(?:required|only|must|essential)\b)|\bown\s+visa\s+(?:holders?|only|required)",
  ),
];

/// "EU citizenship or a valid work permit": a right-to-work rule, not
/// nationals only.
final _orPermit = _re(
  r'\b(?:citizenship|nationality|passport)\s+or\s+(?:an?\s+)?(?:valid\s+)?(?:[\w-]+\s+)?(?:work\s+(?:permit|visa)|residence\s+permit|right\s+to\s+work)',
);

final _permitRequired = _re(
  '\\b(?:valid\\s+)?($_nat|[A-Z][a-z]+)\\s+(?:work\\s+(?:permit|visa|authori[sz]ation)|residence\\s+permit)\\s+(?:is\\s+)?(?:required|essential|mandatory|needed)',
);

final _residence = [
  _re(
    r'\b(?:must|should|need\s+to|are\s+required\s+to)\s+(?:already\s+|currently\s+)?(?:be\s+)?'
    r'(?:live|living|reside|residing|based|located|resident)\s+in\s+(?:the\s+)?'
    '$_place',
  ),
  _re(
    r'\b(?:candidates|applicants|applications|those)\s+(?:must\s+be\s+|who\s+are\s+|from\s+those\s+|currently\s+)?(?:currently\s+)?(?:based|residing|living|located|resident)\s+in\s+(?:the\s+)?'
    '$_place'
    r'\s*only',
  ),
  _re(r"\b([\w.]+)[- ]based\s+(?:candidates|applicants|residents)\s+only"),
  _re(r'\blocal\s+(?:candidates|applicants|hires?|residents)\s+only\b'),
  _re(
    r'\b(?:currently|already)\s+(?:residing|living|based|located)\s+in\s+(?:the\s+)?'
    '$_place',
  ),
  _re(r'\bin[- ]country\s+(?:candidates|applicants|hires?)\b'),
  _re(
    r'\bmust\s+be\s+a\s+(?:permanent\s+)?resident\s+of\s+(?:the\s+)?'
    '$_place',
  ),
];

final _clearance = [
  _re(
    r'\b(BPSS|CTC|SC|eDV|DV|NPPV\s?[1-3]?)\s+(?:level\s+)?(?:security\s+)?(?:clearance|cleared|vetting|vetted|check)\b',
  ),
  _re(r'\b(Developed\s+Vetting|Baseline\s+Personnel\s+Security\s+Standard|Counter[- ]Terrorist\s+Check)\b'),
  _re(r'\b(Top\s+Secret|TS/SCI|Secret|Public\s+Trust)\s+(?:security\s+)?clearance\b'),
  _re(r'\b(?:security\s+clearance|security\s+vetting|national\s+security\s+vetting)\b'),
  _re(r'\b(?:eligible\s+for|able\s+to\s+(?:obtain|gain|achieve))\s+(SC|DV)\b'),
];

const _clearanceNames = {
  'developed vetting': 'DV',
  'baseline personnel security standard': 'BPSS',
  'counter-terrorist check': 'CTC',
  'counter terrorist check': 'CTC',
  'ts/sci': 'TS/SCI',
  'top secret': 'Top Secret',
  'secret': 'Secret',
  'public trust': 'Public Trust',
};

final _levelWord =
    r'(fluent|fluency|native|mother[- ]tongue|bilingual|business[- ](?:level|fluent)|professional|proficient|proficiency'
    r'|excellent|strong|good|working|advanced|full|C1|C2|B1|B2)';

final _languageRes = [
  _re(
    '\\b$_levelWord\\b(?:\\s+(?:level|written|spoken|verbal|oral|and|&|command|knowledge|skills|ability|in|of|the|both|/|\\(\\w+\\)))*\\s+($_lang)\\b'
    '(?:\\s+(?:and|&)\\s+($_lang)\\b)?',
  ),
  _re(
    '\\b($_lang)(?:\\s+language)?(?:\\s+(?:skills|proficiency|fluency|speaker))?(?:\\s+(?:at|to)\\s+(?:level\\s+)?(C1|C2|B1|B2)(?:\\s+level)?)?\\s*'
    r'(?:\((?:written\s+and\s+spoken|spoken\s+and\s+written)\)\s*)?(?:is\s+|are\s+|would\s+be\s+)?(?:highly\s+)?'
    r'(essential|required|mandatory|a\s+must|necessary|desirable|preferred|an\s+advantage|a\s+plus|beneficial|advantageous|an\s+asset)',
  ),
  _re('\\b(?:native|fluent)\\s+($_lang)\\s+speakers?\\b'),
  _re(
    '\\b($_lang)[- ]speaking\\s+(?:candidates?|applicants?|professionals?|nurses?|staff|role|position|doctor|clinician)s?\\b',
  ),
  _re(
    '\\b(?:must|required\\s+to|able\\s+to|ability\\s+to)\\s+(?:speak|read\\s+and\\s+write|communicate\\s+(?:fluently\\s+)?in)\\s+(?:fluent\\s+)?($_lang)\\b',
  ),
];

final _weakLevel = _re(r'^(excellent|strong|good|working|advanced|full|professional)$');

final _aboutLanguage = _re(
  r'(?<![-\w])(language|languages|speak|speaks|speaking|spoken|written|verbal|oral|fluent|fluency|command|proficien\w*|reading|writing|communication)\b',
);

final _desirable = _re(
  r'\b(desirable|preferred|preferable|an?\s+advantage|a\s+plus|beneficial|advantageous|an\s+asset|ideally|nice\s+to\s+have|not\s+essential|would\s+be\s+useful)\b',
);

const _placeWord =
    r'(UK|NHS|HSC|British|US|U\.S\.|American|Irish|Canadian|Australian|NZ|New\s+Zealand|GCC|Gulf|Middle[- ]East(?:ern)?|Saudi|UAE|Emirati|Qatari|EU|European|German|Dutch|Singapore|local(?!\s+(?:government|authorit|council|area|communit|services?|health|population|teams?|partners?|people|knowledge|systems?|polic|procedure|NHS|trust|hospital|organisation|organization|business|context|needs|level))|in[- ]country|domestic)';

final _localExperience = [
  _re(
    '\\b($_placeWord(?:\\s*(?:,|/|\\bor\\b|\\band\\b)\\s*$_placeWord)*)\\s+(?:(?:work(?:ing)?|clinical|healthcare|health\\s+care|industry|professional|post[- ]registration|relevant|hospital|nursing|market|sector|employment|recruitment)\\s+)*experience\\b',
  ),
  _re(
    '\\bexperience\\s+(?:(?:of|in|within)\\s+(?:(?:working|employment)\\s+(?:in|within|for|with)\\s+)?|(?:working|employment)\\s+(?:in|within|for|with)\\s+)(?:the\\s+|an?\\s+)?$_placeWord\\b',
  ),
  _re(
    '\\bexperience\\s+(?:of|in|within)\\s+(?:(?:working|employment)\\s+(?:in|within|for|with)\\s+)?(?:the\\s+|an?\\s+)?$_placeWord\\b',
  ),
];

final _mustWord = _re(
  r'\b(essential|required|requirement|must|mandatory|minimum|at\s+least|is\s+a\s+must|needed|necessary|only)\b',
);

String _subjectFor(String word, {String country = ''}) {
  final w = word.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return switch (w) {
    'uk' || 'nhs' || 'hsc' || 'british' => 'GB',
    'us' || 'u.s.' || 'american' => 'US',
    'irish' => 'IE',
    'canadian' => 'CA',
    'australian' => 'AU',
    'nz' || 'new zealand' => 'NZ',
    'gcc' || 'gulf' || 'middle east' || 'middle-east' || 'middle eastern' || 'middle-eastern' => 'GCC',
    'saudi' => 'SA',
    'uae' || 'emirati' => 'AE',
    'qatari' => 'QA',
    'eu' || 'european' => 'EU',
    'german' => 'DE',
    'dutch' => 'NL',
    'singapore' => 'SG',
    _ => country,
  };
}

LanguageLevel _levelFrom(String sentence, String? word) {
  final cefr = RegExp(r'\b(C2|C1|B2|B1|A2|A1)\b').firstMatch(sentence)?.group(1);
  if (cefr != null) return LanguageLevel.parse(cefr)!;
  return LanguageLevel.parse(word ?? '') ?? LanguageLevel.parse(sentence) ?? LanguageLevel.professional;
}

/// The part of [s] around [start]..[end] between commas, semicolons or a
/// "but": "Fluent German is essential; good English is desirable" has two.
String _clauseAt(String s, int start, int end) {
  final stops = RegExp(r'[;,]|\s(?:but|whilst|while|although)\s|\s[–—]\s', caseSensitive: false);
  var from = 0, to = s.length;
  for (final m in stops.allMatches(s)) {
    if (m.end <= start) from = m.end;
    if (m.start >= end) {
      to = m.start;
      break;
    }
  }
  return s.substring(from, to);
}

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

/// Everything [text] says about who may apply, before knowing who is
/// asking: each finding's severity is what it would be for someone with no
/// right to work there. [country] is the job's country (ISO alpha-2), for
/// lines that name no place ("local candidates only").
///
/// A pure function: the same text always gives the same findings.
List<EligibilityFinding> scanPosting(String text, {String country = ''}) {
  final found = <EligibilityFinding>[];
  final seen = <String>{};
  void add(EligibilityFinding f) {
    if (seen.add('${f.kind.name}|${f.subject}')) found.add(f);
  }

  for (final s in sentencesOf(text)) {
    // Sponsorship. "Those who need sponsorship are welcome" (the NHS's
    // standard line) is an offer; otherwise any "no" wins over an offer in
    // the same sentence ("unable to offer sponsorship").
    final offer = EligibilityFinding(
      kind: EligibilityKind.sponsorshipOffered,
      severity: Severity.info,
      quote: s,
      subject: country,
    );
    if (_welcome.hasMatch(s)) {
      add(offer);
    } else if (_noSponsorship.any((r) => r.hasMatch(s))) {
      add(
        EligibilityFinding(
          kind: EligibilityKind.noSponsorship,
          severity: Severity.blocker,
          quote: s,
          subject: country,
        ),
      );
    } else if (_maybeNoSponsorship.hasMatch(s)) {
      add(
        EligibilityFinding(
          kind: EligibilityKind.noSponsorship,
          severity: Severity.caution,
          quote: s,
          subject: country,
        ),
      );
    } else if (_sponsorshipOffered.any((r) => r.hasMatch(s))) {
      add(offer);
    }

    for (final r in _nationalsOnly) {
      if (_orPermit.hasMatch(s)) break;
      final m = r.firstMatch(s);
      if (m == null) continue;
      final word = m.groupCount >= 1 ? (m.group(1) ?? '') : '';
      final code = word.isEmpty
          ? country
          : _nationalities[word.toLowerCase()] ??
                (word.toLowerCase().startsWith('singapore') ? 'SG' : country);
      add(
        EligibilityFinding(
          kind: EligibilityKind.nationalsOnly,
          severity: Severity.blocker,
          quote: s,
          subject: code,
        ),
      );
      break;
    }
    final loc = _localisationRe.firstMatch(s);
    if (loc != null) {
      final word = (loc.group(1) ?? loc.group(2) ?? '').toLowerCase();
      add(
        EligibilityFinding(
          kind: EligibilityKind.nationalsOnly,
          severity: Severity.caution,
          quote: s,
          subject: _localisation[word] ?? country,
          note: 'A national workforce quota: the role may be kept for citizens.',
        ),
      );
    } else if (_civilServiceNationality.hasMatch(s) &&
        !found.any((f) => f.kind == EligibilityKind.nationalsOnly)) {
      add(
        EligibilityFinding(
          kind: EligibilityKind.nationalsOnly,
          severity: Severity.caution,
          quote: s,
          subject: country,
          note: 'The advert has nationality rules: check which groups may apply.',
        ),
      );
    }

    var rtw = false;
    for (final r in _rightToWork) {
      final m = r.firstMatch(s);
      if (m == null) continue;
      final words = m.groupCount >= 1 ? (m.group(1) ?? '') : '';
      final place = words.isEmpty ? country : placeIn(words).ifEmpty(country);
      add(
        EligibilityFinding(
          kind: EligibilityKind.rightToWork,
          severity: Severity.blocker,
          quote: s,
          subject: place,
        ),
      );
      rtw = true;
      break;
    }
    if (!rtw) {
      final m = _permitRequired.firstMatch(s);
      if (m != null) {
        final word = m.group(1)!.toLowerCase();
        final place = _nationalities[word] ?? placeIn(m.group(1)!).ifEmpty(country);
        add(
          EligibilityFinding(
            kind: EligibilityKind.rightToWork,
            severity: Severity.blocker,
            quote: s,
            subject: place == 'EU' && freeMovement.contains(country) ? country : place,
          ),
        );
      }
    }

    for (final r in _residence) {
      final m = r.firstMatch(s);
      if (m == null) continue;
      final words = m.groupCount >= 1 ? (m.group(1) ?? '') : '';
      final place = words.isEmpty ? country : placeIn(words);
      // A town ("must live within reach of Exampletown") is a commute, not a
      // residence rule.
      if (place.isEmpty) continue;
      final strict = RegExp(
        r'\b(already|currently|only|local|in[- ]country)\b',
        caseSensitive: false,
      ).hasMatch(s);
      add(
        EligibilityFinding(
          kind: EligibilityKind.residence,
          severity: strict ? Severity.blocker : Severity.caution,
          quote: s,
          subject: place,
        ),
      );
      break;
    }

    for (final r in _clearance) {
      final m = r.firstMatch(s);
      if (m == null) continue;
      // UK visas use "entry clearance"; that is not security vetting.
      if (RegExp(r'\bentry\s+clearance\b', caseSensitive: false).hasMatch(s) &&
          !RegExp(r'\bsecurity\b|\b(SC|DV|BPSS|NPPV)\b').hasMatch(s)) {
        continue;
      }
      final raw = m.groupCount >= 1 ? (m.group(1) ?? '') : '';
      final level =
          _clearanceNames[raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ')] ??
          (raw.isEmpty ? '' : raw.toUpperCase().replaceAll(RegExp(r'\s+'), ''));
      final hold = RegExp(
        r'\b(active|current|existing|already|hold|holding|held)\b',
        caseSensitive: false,
      ).hasMatch(s);
      final us = const {'Top Secret', 'TS/SCI', 'Secret', 'Public Trust'}.contains(level);
      add(
        EligibilityFinding(
          kind: EligibilityKind.clearance,
          severity: level == 'BPSS' ? Severity.info : (us ? Severity.blocker : Severity.caution),
          quote: s,
          subject: level,
          note: switch (level) {
            'BPSS' => 'A basic check most people pass: identity, right to work and history.',
            'SC' || 'CTC' || 'NPPV1' || 'NPPV2' || 'NPPV3' || 'NPPV' =>
              'Usually needs 3 to 5 years living in the UK.${hold ? ' The advert wants it already held.' : ''}',
            'DV' || 'EDV' =>
              'Usually needs about 10 years living in the UK.${hold ? ' The advert wants it already held.' : ''}',
            _ when us => 'US government clearances are for US citizens.',
            _ =>
              'Vetting often needs years of residence in the country.${hold ? ' The advert wants it already held.' : ''}',
          },
        ),
      );
      break;
    }

    for (final r in _languageRes) {
      for (final m in r.allMatches(s)) {
        final groups = [for (var i = 1; i <= m.groupCount; i++) m.group(i)];
        final langs = groups
            .whereType<String>()
            .where((g) => _languages.any((l) => l.toLowerCase() == g.toLowerCase()))
            .map(_cap)
            .toList();
        final levelWord = groups.whereType<String>().where((g) => LanguageLevel.parse(g) != null).firstOrNull;
        // "Strong German engineering firm" is not about speaking German.
        if (levelWord != null &&
            _weakLevel.hasMatch(levelWord) &&
            !_aboutLanguage.hasMatch(_clauseAt(s, m.start, m.end))) {
          continue;
        }
        final desirable = _desirable.hasMatch(_clauseAt(s, m.start, m.end));
        for (final l in langs) {
          add(
            EligibilityFinding(
              kind: EligibilityKind.language,
              severity: desirable ? Severity.info : Severity.caution,
              quote: s,
              subject: l,
              essential: !desirable,
              level: _levelFrom(s, levelWord),
            ),
          );
        }
      }
    }

    if (RegExp(r'\bexperience\b', caseSensitive: false).hasMatch(s)) {
      for (final r in _localExperience) {
        final m = r.firstMatch(s);
        if (m == null) continue;
        // "us" is a word, not the country, unless written US.
        final places = {
          for (final w in RegExp(_placeWord, caseSensitive: false).allMatches(m.group(1)!))
            if (w.group(0) != 'us' && w.group(0) != 'Us') _subjectFor(w.group(0)!, country: country),
        }..remove('');
        if (places.isEmpty) continue;
        final clause = _clauseAt(s, m.start, m.end);
        final desirable = _desirable.hasMatch(clause);
        if (!desirable && !_mustWord.hasMatch(clause) && !clause.toLowerCase().startsWith('essential')) {
          continue;
        }
        add(
          EligibilityFinding(
            kind: EligibilityKind.localExperience,
            severity: desirable ? Severity.info : Severity.caution,
            quote: s,
            subject: places.join(','),
            essential: !desirable,
          ),
        );
        break;
      }
    }
  }
  return found;
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

bool _covers(String subject, String code) =>
    subject == code ||
    (subject == 'EU' && freeMovement.contains(code)) ||
    (subject == 'GCC' && _gcc.contains(code));

/// True when [phrase] appears in [text] as whole words, any case.
bool hasWords(String text, String phrase) {
  final words = phrase.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map(RegExp.escape).toList();
  if (words.isEmpty) return false;
  return RegExp(
    '(?<![A-Za-z0-9À-ɏ])${words.join(r'\s+')}(?![A-Za-z0-9À-ɏ])',
    caseSensitive: false,
  ).hasMatch(text);
}

/// The exclusion in [exclusions] that rules the job out, or null.
String? excludedBy(List<String> exclusions, {required String title, String company = ''}) {
  for (final e in exclusions) {
    if (e.trim().isEmpty) continue;
    if (hasWords(title, e) || hasWords(company, e)) return e.trim();
  }
  return null;
}

/// What the advert's eligibility lines mean for [p] on [today]: each
/// finding re-graded against their passports, rights to work, languages
/// and experience, plus their exclusions as hard rules.
EligibilityCheck checkEligibility(
  CandidateProfile p, {
  required String title,
  String company = '',
  String description = '',
  String country = '',
  required String today,
}) {
  final rights = p.rights;
  final out = <EligibilityFinding>[];
  final excluded = excludedBy(p.targets.exclusions, title: title, company: company);
  if (excluded != null) {
    out.add(
      EligibilityFinding(
        kind: EligibilityKind.excluded,
        severity: Severity.blocker,
        quote: hasWords(title, excluded) ? title : company,
        subject: excluded,
        note: 'You asked never to see jobs that say this.',
      ),
    );
  }
  final known = !rights.isEmpty;
  for (final f in scanPosting('$title\n$description', country: country)) {
    out.add(_grade(f, p, today: today, known: known, jobCountry: country));
  }
  return EligibilityCheck(out);
}

EligibilityFinding _grade(
  EligibilityFinding f,
  CandidateProfile p, {
  required String today,
  required bool known,
  required String jobCountry,
}) {
  final rights = p.rights;
  final place = f.subject;
  String? basis() {
    if (place.isEmpty) return null;
    if (place == 'EU') {
      final eu = p.rights.passports.where(freeMovement.contains).firstOrNull;
      return eu == null ? null : 'Your ${Country.nameOf(eu)} passport gives free movement';
    }
    if (place == 'GCC') {
      return _gcc.map((c) => rights.basisIn(c, today)).whereType<String>().firstOrNull;
    }
    return rights.basisIn(place, today);
  }

  switch (f.kind) {
    case EligibilityKind.noSponsorship:
    case EligibilityKind.rightToWork:
      if (place.isEmpty) {
        return f.copyWith(severity: Severity.caution, note: 'The advert does not say which country.');
      }
      final b = basis();
      if (b != null) {
        final ending = place.length == 2 ? rights.endingIn(place, today) : null;
        if (ending != null && ending.until!.compareTo(_addMonths(today, 6)) < 0) {
          return f.copyWith(
            severity: Severity.caution,
            note: '$b, but it ends ${ending.until}: check the employer accepts that.',
          );
        }
        return f.copyWith(severity: Severity.clear, note: '$b, so this does not stop you.');
      }
      if (!known) {
        return f.copyWith(
          severity: f.kind == EligibilityKind.noSponsorship ? f.severity : Severity.caution,
          note: 'Add your right to work on the Profile page to check this.',
        );
      }
      return f.copyWith(
        note: f.kind == EligibilityKind.noSponsorship
            ? 'You have no right to work in ${_placeName(place)} on record, and they will not sponsor a visa.'
            : 'You have no right to work in ${_placeName(place)} on record.',
      );
    case EligibilityKind.sponsorshipOffered:
      final b = basis();
      return f.copyWith(
        severity: b != null ? Severity.clear : Severity.info,
        note: b != null ? '$b; sponsorship is not needed.' : 'A good sign if you need a visa.',
      );
    case EligibilityKind.nationalsOnly:
      if (place.isEmpty) {
        return f.copyWith(severity: Severity.caution, note: 'Check which nationalities may apply.');
      }
      final citizen = place == 'EU'
          ? rights.passports.any(freeMovement.contains)
          : place == 'GCC'
          ? rights.passports.any(_gcc.contains)
          : rights.passports.contains(place);
      if (citizen) return f.copyWith(severity: Severity.clear, note: 'Your passport meets it.');
      if (rights.passports.isEmpty) {
        return f.copyWith(
          severity: f.severity == Severity.blocker ? Severity.caution : f.severity,
          note: f.note.isEmpty ? 'Add your passport on the Profile page to check this.' : f.note,
        );
      }
      return f.copyWith(note: f.note.isEmpty ? 'Your passport is not ${_placeName(place)}.' : f.note);
    case EligibilityKind.residence:
      final lives = place == p.country || _covers(place, p.country);
      if (lives) return f.copyWith(severity: Severity.clear, note: 'You live there.');
      if (p.country.isEmpty) {
        return f.copyWith(severity: Severity.caution, note: 'Add where you live to check this.');
      }
      final b = basis();
      if (b != null) {
        return f.copyWith(
          severity: Severity.caution,
          note:
              '$b, but you would need to be living there${f.severity == Severity.blocker ? ' already' : ''}.',
        );
      }
      return f.copyWith(note: 'You do not live in ${_placeName(place)}.');
    case EligibilityKind.clearance:
      if (const {'Top Secret', 'TS/SCI', 'Secret', 'Public Trust'}.contains(place)) {
        return rights.passports.contains('US')
            ? f.copyWith(severity: Severity.caution, note: 'US citizens can be put forward for it.')
            : f;
      }
      return f;
    case EligibilityKind.language:
      final level = rights.levelIn(place, cv: p.languages);
      final wanted = f.level ?? LanguageLevel.professional;
      final listsAny = rights.languages.isNotEmpty || p.languages.isNotEmpty;
      if (level == null) {
        if (!listsAny) {
          return f.copyWith(
            severity: place == 'English' || !f.essential ? Severity.info : Severity.caution,
            note: 'Add your languages on the Profile page to check this.',
          );
        }
        return f.copyWith(
          severity: f.essential ? Severity.blocker : Severity.info,
          note: '$place is not among your languages.',
        );
      }
      final gap = wanted.index - level.index;
      if (gap <= 0) {
        return f.copyWith(severity: Severity.clear, note: 'Your $place is ${level.label.toLowerCase()}.');
      }
      return f.copyWith(
        severity: !f.essential ? Severity.info : (gap == 1 ? Severity.caution : Severity.blocker),
        note: 'They ask for ${wanted.label.toLowerCase()} ($place); yours is ${level.label.toLowerCase()}.',
      );
    case EligibilityKind.localExperience:
      if (_hasExperienceIn(p, place)) {
        return f.copyWith(severity: Severity.clear, note: 'Your experience covers it.');
      }
      return f.copyWith(
        note: f.essential
            ? 'Your profile shows no ${place.isEmpty ? 'local' : _placeName(place)} experience.'
            : 'Desirable only.',
      );
    case EligibilityKind.excluded:
      return f;
  }
}

bool _hasExperienceIn(CandidateProfile p, String places) =>
    places.split(',').any((place) => _hasExperienceInOne(p, place));

bool _hasExperienceInOne(CandidateProfile p, String place) {
  if (place.isEmpty) return false;
  for (final e in p.experience) {
    final where = countryCode(e.location.split(',').last.trim());
    if (_covers(place, where)) return true;
    if (place == 'GB' &&
        RegExp(r'\b(NHS|HSC)\b|\bHealth Board\b|\bNHS Trust\b').hasMatch('${e.organisation} ${e.location}')) {
      return true;
    }
  }
  // The current job, when it is in the home country.
  return p.currentEmployer.isNotEmpty && _covers(place, p.country);
}

String _addMonths(String day, int months) {
  final d = DateTime.parse(day);
  final m = d.month - 1 + months;
  final y = d.year + (m ~/ 12) - (m < 0 && m % 12 != 0 ? 1 : 0);
  final month = ((m % 12) + 12) % 12 + 1;
  final last = DateTime(y, month + 1, 0).day;
  final out = DateTime(y, month, d.day > last ? last : d.day);
  return out.toIso8601String().substring(0, 10);
}

/// [day] (yyyy-MM-dd) moved by whole calendar months, keeping the day of
/// the month where it exists (31 Mar less one month is 28 or 29 Feb).
String addMonths(String day, int months) => _addMonths(day, months);
