import 'package:brahma_core/brahma_core.dart' show daysBetween;

import '../db/database.dart';

/// What to know about a listing before applying: whether it comes from an
/// official NHS or HSC site, and anything that says it is closed, stale or
/// not what it claims.
class ListingCheck {
  const ListingCheck({this.official = false, this.problems = const [], this.cautions = const []});

  /// From NHS Jobs, HSC Jobs, a trust's own site or its recruitment system.
  final bool official;

  /// Reasons not to apply (closed).
  final List<String> problems;

  /// Reasons to check before applying.
  final List<String> cautions;

  bool get clear => problems.isEmpty && cautions.isEmpty;
}

/// Sites NHS and HSC employers advertise and take applications on.
const _officialHosts = [
  'jobs.nhs.uk',
  'nhs.uk',
  'jobs.hscni.net',
  'hscni.net',
  'healthjobsuk.com',
  'trac.jobs',
  'jobtrain.co.uk',
];

bool officialSite(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host.isNotEmpty && _officialHosts.any((h) => host == h || host.endsWith('.$h'));
}

/// Signs from job-scam warnings: paying to apply, talking on a messaging app,
/// handing over bank details, a personal email address.
final _signs = <(RegExp, String)>[
  (
    RegExp(
      r'\b(upfront|registration|training|admin(istration)?|processing|application) (fee|payment|charge)\b'
      r'|\bpay (a |an |the |your )?(fee|deposit)\b',
      caseSensitive: false,
    ),
    'It mentions a fee. Genuine employers do not ask you to pay to apply, or for training up front.',
  ),
  (
    RegExp(r'\b(whats ?app|telegram)\b', caseSensitive: false),
    'It asks you to talk on a messaging app. NHS and HSC employers use their own sites and work email.',
  ),
  (
    RegExp(r'\bbank (details|account)\b|\bsort code\b|\bnational insurance number\b', caseSensitive: false),
    'It asks for bank or National Insurance details. Give them only after a written offer from an employer you have checked.',
  ),
  (
    RegExp(r'@(gmail|googlemail|hotmail|yahoo|outlook|live|aol)\.', caseSensitive: false),
    'The contact is a personal email address, not the employer\'s.',
  ),
];

ListingCheck checkListing(Job j, {required String today}) {
  final official = j.source == 'nhs' || officialSite(j.url);
  final problems = <String>[];
  final cautions = <String>[];
  final closing = j.closing;
  if (closing != null && closing.compareTo(today) < 0) {
    problems.add('Closed on $closing.');
  }
  final since = j.posted ?? j.found;
  if (closing == null && since.length >= 10 && daysBetween(since.substring(0, 10), today) > 30) {
    cautions.add(
      'Listed over a month ago with no closing date, so it may be filled. NHS adverts can close early once '
      'enough people apply.',
    );
  }
  if (!official) {
    final text = '${j.title}\n${j.company}\n${j.description}';
    for (final (re, warning) in _signs) {
      if (re.hasMatch(text)) cautions.add(warning);
    }
    if (RegExp(r'\b(NHS|HSC)\b').hasMatch(text)) {
      cautions.add(
        'It names the NHS or HSC but is not on their sites. Find the same job on NHS Jobs, HSC Jobs or the '
        'trust\'s own site and apply there.',
      );
    }
  }
  return ListingCheck(official: official, problems: problems, cautions: cautions);
}
