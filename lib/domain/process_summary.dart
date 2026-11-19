/// One page for a whole process (interview plan I3 follow-up): every
/// criterion across all the stages, where each was evidenced or that it is
/// still missing, and the three fixes that matter most overall.
library;

import 'interview_scoring.dart';

/// How one criterion fared across every stage of a process.
class ProcessCriterion {
  const ProcessCriterion({
    required this.criterion,
    required this.status,
    this.evidencedIn = const [],
    this.thinIn = const [],
    this.asked = true,
  });

  final Criterion criterion;

  /// The best it reached in any stage.
  final Coverage status;

  /// The stages where it was evidenced, and where it was only touched on.
  final List<String> evidencedIn, thinIn;

  /// False when no stage asked about it.
  final bool asked;

  /// An essential criterion assessed at interview with no evidence in any
  /// stage: a panel could not appoint (plan rule 3).
  bool get unappointable => criterion.essential && criterion.atInterview && status == Coverage.missing;

  /// Where it stands, in a line.
  String get note => switch (status) {
    Coverage.evidenced => 'Evidenced in ${evidencedIn.join(', ')}.',
    Coverage.thin => 'Touched on in ${thinIn.join(', ')}, but not yet a full example.',
    Coverage.missing =>
      !criterion.atInterview
          ? 'Assessed by the ${criterion.assessBy.map((a) => assessByLabels[a]!.toLowerCase()).join(' and ')}, '
                'not at interview.'
          : asked
          ? 'Asked, but no evidence heard in any stage.'
          : 'Not asked in any stage yet.',
  };
}

/// The whole process in one view.
class ProcessSummary {
  const ProcessSummary({required this.stages, required this.criteria, required this.topFixes});

  /// The stages it covers, in order.
  final List<String> stages;

  /// Essentials first, gaps first within them.
  final List<ProcessCriterion> criteria;

  /// At most three, the most important first.
  final List<String> topFixes;

  List<ProcessCriterion> get missingEssentials => [
    for (final c in criteria)
      if (c.unappointable) c,
  ];

  List<ProcessCriterion> get evidenced => [
    for (final c in criteria)
      if (c.status == Coverage.evidenced) c,
  ];

  /// The fix for an essential criterion no stage evidenced.
  static String prepareFix(Criterion c) =>
      'Prepare one example that shows ${_lowerFirst(c.text)}, and say it aloud before the interview.';

  /// From each stage's debrief, in the order the stages ran. [profile]'s
  /// criteria that no stage asked about are listed too, as not asked.
  /// Criteria are matched across stages by their wording.
  static ProcessSummary build(List<({String stage, Debrief debrief})> stages, {RoleProfile? profile}) {
    final byKey = <String, ({Criterion criterion, Coverage best, bool asked, List<String> ev, List<String> thin})>{};
    String key(Criterion c) => c.text.toLowerCase().trim();
    for (final (:stage, :debrief) in stages) {
      for (final c in debrief.coverage) {
        final k = key(c.criterion);
        final was = byKey[k];
        final asked = c.asked;
        final status = asked ? c.status : Coverage.missing;
        final best = was == null || status.index < was.best.index ? status : was.best;
        byKey[k] = (
          // A profile's criterion (which can be essential) wins over a
          // question's aim standing in for one.
          criterion: was == null || (!was.criterion.essential && c.criterion.essential)
              ? c.criterion
              : was.criterion,
          best: best,
          asked: (was?.asked ?? false) || asked,
          ev: [...?was?.ev, if (asked && c.status == Coverage.evidenced && !(was?.ev.contains(stage) ?? false)) stage],
          thin: [...?was?.thin, if (asked && c.status == Coverage.thin && !(was?.thin.contains(stage) ?? false)) stage],
        );
      }
    }
    for (final c in profile?.criteria ?? const <Criterion>[]) {
      byKey.putIfAbsent(key(c), () => (criterion: c, best: Coverage.missing, asked: false, ev: [], thin: []));
    }
    final criteria = [
      for (final v in byKey.values)
        ProcessCriterion(
          criterion: v.criterion,
          status: v.best,
          evidencedIn: v.ev,
          thinIn: v.thin,
          asked: v.asked,
        ),
    ];
    int group(ProcessCriterion c) => !c.criterion.atInterview ? 2 : (c.criterion.essential ? 0 : 1);
    criteria.sort((a, b) {
      final g = group(a).compareTo(group(b));
      return g != 0 ? g : b.status.index.compareTo(a.status.index);
    });

    // The fixes: missing essentials first, then the per-answer fixes that
    // came up most, later stages counting more (fresher evidence).
    final counts = <String, int>{};
    final order = <String>[];
    for (final (i, s) in stages.indexed) {
      for (final n in s.debrief.notes) {
        final f = n.fix.trim();
        if (f.isEmpty || mentionsScale(f)) continue;
        if (!counts.containsKey(f)) order.add(f);
        counts[f] = (counts[f] ?? 0) + 1 + i;
      }
    }
    final first = {for (final (i, f) in order.indexed) f: i};
    order.sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : first[a]!.compareTo(first[b]!);
    });
    final topFixes = <String>[
      for (final c in criteria)
        if (c.unappointable) prepareFix(c.criterion),
      ...order,
    ].take(3).toList();
    return ProcessSummary(stages: [for (final s in stages) s.stage], criteria: criteria, topFixes: topFixes);
  }
}

String _lowerFirst(String s) => s.length > 1 && s[1] == s[1].toLowerCase() && !s.startsWith(RegExp('[A-Z]{2}'))
    ? s[0].toLowerCase() + s.substring(1)
    : s;
