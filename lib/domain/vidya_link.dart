/// The link with Vidya, the learning app: what the candidate still needs
/// goes out as a Vidya study plan; what they finish in Vidya comes back.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';
import 'package:interview_engine/interview_engine.dart' show RoleProfile;

import '../db/database.dart';
import 'book.dart';
import 'companion.dart';
import 'companion_book.dart';
import 'evidence.dart';
import 'insights.dart';
import 'interview_book.dart';
import 'job_identity.dart';
import 'json.dart';
import 'pipeline.dart';
import 'profile.dart';
import 'role_insight.dart';
import 'todos.dart';

/// A Vidya study plan ("vidya-curriculum", version 1) from the candidate's
/// gaps: competencies without enough interview stories, the gaps in their
/// job assessments, and the learning they planned. Their stories become
/// review cards, so they are rehearsed on a spaced schedule.
Json vidyaPlan({
  required CandidateProfile profile,
  required List<Job> jobs,
  required List<Story> stories,
  required Map<String, ({int confirmed, int drafts})> storyCounts,
  required List<GrowthItem> learning,
  List<EvidenceFramework> roles = const [],
}) {
  final ready = readiness(storyCounts);
  final role = profile.targets.roles.firstOrNull ?? '';
  final courses = <Json>[];

  final weak = [
    for (final e in ready.entries)
      if (e.value < 100) e.key,
  ];
  if (weak.isNotEmpty) {
    courses.add({
      'title': 'Interview stories',
      'kind': 'practice',
      'startWeek': 0,
      'dueWeek': 2,
      'summary':
          'A true example from your own work for each thing a panel scores. Write each one in Udyoga\'s '
          'story bank (situation, task, action, result) and say it aloud until it takes about two minutes.',
      'topics': [
        for (final c in weak)
          {
            'title': competencyNames[c],
            'minutes': 30,
            'details': [
              'Readiness ${ready[c]}%. To find one, ask yourself: ${checkInQuestions[c]}',
              'Answer in the first person with what you did and what changed.',
            ].join(' '),
          },
      ],
    });
  }

  // The gaps in each assessed job still being pursued, newest first.
  final assessed = jobs.where((j) => j.assessment.isNotEmpty && j.status != 'dismissed').toList()
    ..sort((a, b) => b.found.compareTo(a.found));
  for (final j in assessed.take(5)) {
    final gaps = FitAssessment(decodeObject(j.assessment)).gaps;
    if (gaps.isEmpty) continue;
    courses.add({
      'title': 'Gaps for ${j.title}${j.company.isEmpty ? '' : ' at ${j.company}'}',
      'kind': 'course',
      'startWeek': 0,
      'dueWeek': 1,
      'summary': 'What the advert asks for that your CV does not show yet, and how to close or explain it.',
      'topics': [
        for (final g in gaps)
          if (str(g['requirement']).isNotEmpty)
            {
              'title': _clip(str(g['requirement']), 200),
              'minutes': str(g['severity']) == 'minor' ? 20 : 45,
              'details': [
                if (str(g['severity']).isNotEmpty) 'Severity: ${str(g['severity'])}.',
                str(g['mitigation']),
              ].where((t) => t.isNotEmpty).join(' '),
            },
      ],
    });
  }

  for (final g in learning) {
    if (!const {'suggested', 'planned', 'doing'}.contains(g.status)) continue;
    if (!const {'course', 'certification', 'degree'}.contains(g.kind)) continue;
    courses.add({
      'title': g.title,
      'kind': g.kind,
      if (g.provider.isNotEmpty) 'provider': g.provider,
      if (g.url.startsWith('http')) 'url': g.url,
      if (g.why.isNotEmpty) 'summary': g.why,
      'topics': const [],
    });
  }

  final cards = [
    for (final s in stories)
      if (s.action.isNotEmpty)
        {
          'id': storyCardId(s.id),
          'deck': 'Interview stories',
          'front': [
            'Tell your story: ${s.title}',
            if (CompanionBook.competenciesOf(s) case final cs when cs.isNotEmpty)
              '(${cs.map((c) => competencyNames[c]).join('; ')})',
          ].join(' '),
          'back': [
            if (s.situation.isNotEmpty) 'Situation: ${s.situation}',
            if (s.task.isNotEmpty) 'Task: ${s.task}',
            'Action: ${s.action}',
            if (s.result.isNotEmpty) 'Result: ${s.result}',
          ].join('\n'),
          // Added for evidence links (A4/A6), only when there are any, so
          // untagged stories send the same card as before; readers that do
          // not know these keys ignore them.
          if (tagsOf(s) case final tags when tags.isNotEmpty)
            'tags': [
              for (final t in tags) {...t.toJson(), 'title': tagTitle(t, roles: roles)},
            ],
          if ((s.happened ?? '').isNotEmpty) 'happened': s.happened,
        },
  ];

  return {
    'format': 'vidya-curriculum',
    'version': 1,
    'part': '1 of 1',
    'program': {
      'title': role.isEmpty ? 'Interview ready' : 'Interview ready: $role',
      'goal':
          'Be ready to apply and interview with confidence: a story for each competency, the job gaps '
          'closed or explained, and the planned learning done.',
    },
    'courses': courses,
    'skills': [
      for (final c in competencyNames.keys)
        {'name': competencyNames[c], 'category': 'Interview', 'target': 4},
    ],
    'cards': cards,
    'notes': [
      {
        'title': 'From Udyoga',
        'body': [
          'Made by Udyoga from your story bank, job assessments and learning list.',
          '',
          for (final c in competencyNames.keys) '- ${competencyNames[c]}: ${ready[c]}% ready',
          '',
          'What you finish here reaches Udyoga\'s Coach page by itself when both apps sync with the same '
              'account. Without sync, copy your portfolio from Vidya and paste it on Udyoga\'s Coach page.',
        ].join('\n'),
        'tags': ['udyoga', 'interview'],
      },
    ],
  };
}

String _clip(String s, int max) => s.length > max ? s.substring(0, max) : s;

/// The Vidya plan row id for a role ("Study for this role"): one per role,
/// beside Udyoga's main plan, so sending again replaces it.
String rolePlanId(String role) => 'udyoga.role.${normalJobTitle(role).replaceAll(' ', '-')}';

/// Where a criterion came from, in Vidya's words.
String _sourceName(InsightFrom f) => switch (f) {
  InsightFrom.esco => 'ESCO',
  InsightFrom.ai => 'AI',
  InsightFrom.ncs => 'National Careers Service',
  InsightFrom.skillsEngland => 'Skills England',
  InsightFrom.profile => 'You',
  _ => 'Udyoga',
};

/// A role insight as a Vidya study plan ("vidya-curriculum", version 1):
/// the gaps and the first moves as topics, each linked to the criteria it
/// works on, and the role's criteria for Vidya's readiness view.
///
/// Fields added to version 1 (Vidya's reader skips fields it does not know,
/// so the current Vidya imports this as an ordinary plan):
/// - "role": the role's title.
/// - "criteria": [{id, text, essential, kind, source, shown}], every
///   criterion of the role; "shown" is true or false when Udyoga checked it
///   against the profile, null when it did not.
/// - per topic "criteria": the ids it works on, and "items": study items
///   [{type, title, required, source}] (practice tasks for now).
/// - "journey": the job journey of Vidya's plan format 3 (see
///   [jobJourney]); Vidya fills in the stages from its own templates.
Json roleVidyaPlan(RoleInsight i) {
  Json task(String title, InsightFrom from) => {
    'type': 'practice task',
    'title': _clip(title, 200),
    'required': true,
    'source': _sourceName(from),
  };
  const minutes = {'blocker': 60, 'major': 45, 'minor': 20};
  final gaps = [
    for (final g in i.gaps)
      {
        'title': _clip(g.text, 200),
        'minutes': minutes[g.severity] ?? 30,
        'details': [
          'Severity: ${g.severity}.',
          if (g.howToClose.isNotEmpty) '${g.from.isAi ? 'AI suggestion: ' : ''}${g.howToClose}',
        ].join(' '),
        'criteria': [if (g.criterion.isNotEmpty) g.criterion],
        'items': [if (g.howToClose.isNotEmpty) task(g.howToClose, g.from)],
      },
  ];
  final moves = [
    for (final m in i.moves)
      {
        'title': _clip(m.text, 200),
        'minutes': 30,
        'details': 'A first move for the next 30 days${m.from.isAi ? ' (AI suggestion)' : ''}.',
        'criteria': [if (m.criterion.isNotEmpty) m.criterion],
        'items': [task(m.text, m.from)],
      },
  ];
  return {
    'format': 'vidya-curriculum',
    'version': 1,
    'part': '1 of 1',
    'program': {
      'title': _clip('Approach: ${i.role}', 200),
      'goal': 'Close the gaps for ${i.role} and make the first moves, with evidence for each criterion.',
    },
    'role': i.role,
    'journey': jobJourney(role: i.role, sector: i.nhs ? 'nhs' : 'other'),
    'criteria': [
      for (final c in i.criteria.take(80))
        {
          'id': c.id,
          'text': _clip(c.text, 200),
          'essential': c.essential,
          'kind': c.kind,
          'source': _sourceName(c.from),
          'shown': c.shown,
        },
    ],
    'courses': [
      if (gaps.isNotEmpty)
        {
          'title': _clip('Gaps for ${i.role}', 200),
          'kind': 'course',
          'startWeek': 0,
          'dueWeek': 6,
          'summary': 'What ${i.role} asks for that your CV does not show yet, most serious first.',
          'topics': gaps.take(60).toList(),
        },
      if (moves.isNotEmpty)
        {
          'title': _clip('First moves: ${i.role}', 200),
          'kind': 'practice',
          'startWeek': 0,
          'dueWeek': 4,
          'summary': 'Things to do in the next 30 days.',
          'topics': moves,
        },
    ],
    'skills': const [],
    'cards': const [],
    'notes': [
      {
        'title': _clip('From Udyoga: ${i.role}', 200),
        'body': [
          'Made by Udyoga from its role insight for ${i.role} (${i.updated}).',
          if (i.fit != null)
            'Fit today: ${i.fit}%${i.fitAi != null ? ' (AI)' : ' (skills shown in your profile)'}.',
          if (i.timeToReach.isNotEmpty) 'Time to reach: ${i.timeToReach} (AI).',
          '',
          'Criteria:',
          for (final c in i.criteria.take(80))
            '- ${c.text} (${c.essential ? 'essential' : 'optional'}${c.shown == true ? ', shown in your CV' : ''})',
        ].join('\n'),
        'tags': ['udyoga', 'role'],
      },
    ],
  };
}

/// A job journey for Vidya (plan format 3's `journey`): only the job's own
/// data. The generic, dated stage templates live in Vidya, so nothing here
/// teaches. Empty fields are left out. [advertText] is the advert as saved,
/// for Vidya's dossier; [facts] are claims about the employer with the web
/// address each came from ([employerFacts]): Vidya keeps them as
/// unverified inference until it finds the supporting sentence in a source.
/// [checks] are the application's offer-to-start checks ([vidyaChecks]):
/// Vidya's checks stage shows them, with due dates and overdue warnings,
/// in place of its own list.
Json jobJourney({
  required String role,
  String employer = '',
  required String sector,
  String advertUrl = '',
  String? closes,
  String applicationStage = '',
  String advertText = '',
  List<Json> facts = const [],
  List<Json> checks = const [],
}) => {
  'role': _clip(role, 200),
  if (employer.isNotEmpty) 'employer': _clip(employer, 200),
  'sector': sector,
  if (advertUrl.startsWith('http')) 'advertUrl': _clip(advertUrl, 500),
  if (closes != null && isValidIsoDate(closes)) 'closes': closes,
  if (applicationStage.isNotEmpty) 'applicationStage': applicationStage,
  if (advertText.trim().isNotEmpty) 'advertText': _clip(advertText.trim(), 20000),
  if (facts.isNotEmpty) 'facts': facts.take(30).toList(),
  if (checks.isNotEmpty) 'checks': checks.take(40).toList(),
};

/// An application's offer-to-start checks for Vidya's journey: kind,
/// title, status and dates only (never the notes, which may hold personal
/// details).
List<Json> vidyaChecks(List<JobCheck> checks) => [
  for (final c in checks)
    {
      'kind': c.kind,
      'title': _clip(c.title, 200),
      'status': c.status,
      if (c.due != null && isValidIsoDate(c.due!)) 'due': c.due,
      if (c.done != null && isValidIsoDate(c.done!)) 'done': c.done,
    },
];

/// The culture points of employer research that name the web address they
/// come from, as journey facts (`claim`, `url`, `title`). The title is the
/// brief's own name for that source, when it lists one. Points without a
/// web address are left out: Vidya could never check them.
List<Json> employerFacts(EmployerBrief? brief) {
  if (brief == null) return const [];
  final titles = {
    for (final s in brief.sources)
      if (str(s['url']).startsWith('http')) str(s['url']): str(s['title']),
  };
  final seen = <String>{};
  return [
    for (final c in brief.culture)
      if ((claim: str(c['point']).trim(), url: str(c['source']).trim()) case (:final claim, :final url)
          when claim.isNotEmpty && RegExp(r'^https?://').hasMatch(url) && seen.add('$claim|$url'))
        {
          'claim': _clip(claim, 2000),
          'url': _clip(url, 500),
          if (titles[url] case final t? when t.isNotEmpty) 'title': _clip(t, 200),
        },
  ];
}

/// The kind of employer a job is with, for Vidya's templates: `nhs`,
/// `university`, `civil-service`, `private` or `other`. The interview
/// framework (when a role profile names one) wins; otherwise the
/// employer's name is read. A guess: the learner can see it in Vidya.
String journeySector({String employer = '', String framework = ''}) {
  switch (framework) {
    case 'nhs_values' || 'hsc_ni':
      return 'nhs';
    case 'civil_service':
      return 'civil-service';
  }
  final e = ' ${employer.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ')} ';
  bool has(String words) => RegExp(' ($words) ').hasMatch(e);
  if (has('nhs|hsc|health and social care|health board|ambulance service') || has('health') && has('trust')) {
    return 'nhs';
  }
  if (has('university|college')) return 'university';
  if (has('hm|ministry of|department for|civil service')) return 'civil-service';
  if (has('ltd|limited|plc|llp|inc|group')) return 'private';
  return 'other';
}

/// The Vidya plan row id for a saved job ("Prepare this job").
String jobPlanId(String jobId) => 'udyoga.job.$jobId';

/// A saved job as a Vidya plan with a journey ("Prepare this job"): the
/// job's criteria (from its role profile, checked by the candidate, else
/// the AI fit assessment's requirements), its employer, a sector guess,
/// the advert's link, text and closing date, where the application stands,
/// the employer research's sourced culture points ([brief]) and the
/// application's offer-to-start [checks].
/// A version 1 plan with a note, so an older Vidya still imports it.
Json jobVidyaPlan(
  Job j, {
  RoleProfile? profile,
  JobApplication? application,
  EmployerBrief? brief,
  List<JobCheck> checks = const [],
}) {
  final fit = j.assessment.isEmpty ? null : FitAssessment(decodeObject(j.assessment));
  final where = j.company.isEmpty ? j.title : '${j.title} at ${j.company}';
  final criteria = <Json>[
    if (profile != null && profile.criteria.isNotEmpty)
      for (final c in profile.criteria.take(80))
        {
          'id': c.id,
          'text': _clip(c.text, 200),
          'essential': c.essential,
          'kind': c.kind.name,
          'source': profile.source == 'ai' ? 'Advert (read by AI, checked by you)' : 'Advert',
        }
    else if (fit != null)
      for (final (k, r) in [
        ...fit.matched.map((m) => str(m['requirement'])),
        ...fit.gaps.map((g) => str(g['requirement'])),
      ].where((r) => r.isNotEmpty).take(80).indexed)
        {'id': 'a${k + 1}', 'text': _clip(r, 200), 'essential': true, 'source': 'AI'},
  ];
  final closes = j.closing ?? (fit != null && isValidIsoDate(fit.closing) ? fit.closing : null);
  return {
    'format': 'vidya-curriculum',
    'version': 1,
    'part': '1 of 1',
    'program': {
      'title': _clip('Prepare: $where', 200),
      'goal': 'Every stage of $where, from deciding to apply to the first months in the post.',
      if (closes != null && isValidIsoDate(closes)) 'targetDate': closes,
    },
    'role': _clip(j.title, 200),
    'journey': jobJourney(
      role: j.title,
      employer: j.company,
      sector: journeySector(employer: j.company, framework: profile?.frameworkId ?? ''),
      advertUrl: j.url,
      closes: closes,
      applicationStage: application?.stage ?? '',
      advertText: j.description,
      facts: employerFacts(brief),
      checks: vidyaChecks(checks),
    ),
    'criteria': criteria,
    'courses': const [],
    'skills': const [],
    'cards': const [],
    'notes': [
      {
        'title': _clip('From Udyoga: $where', 200),
        'body': [
          'Sent by Udyoga from your saved job.',
          if (j.url.startsWith('http')) 'Advert: ${j.url}',
          if (closes != null) 'Closes: ${niceDate(closes)}',
          if (application != null) 'Application: ${Stage.of(application.stage).label}',
          if (criteria.isEmpty) '',
          if (criteria.isEmpty)
            'No criteria yet: read them from the advert on Udyoga\'s interview page, or add them in Vidya.',
        ].join('\n'),
        'tags': ['udyoga', 'job'],
      },
    ],
  };
}

/// What Vidya says was finished, from its portfolio Markdown: completed
/// learning and rated skills.
typedef VidyaDone = ({
  List<({String title, String kind, String provider, String finished})> learning,
  List<String> skills,
});

/// Vidya's kinds of finished learning that the Growth page keeps, as its kinds.
const _kinds = {'course': 'course', 'book': 'course', 'certification': 'certification', 'degree': 'degree'};

/// Skills at Vidya's level 3 (Competent) or above go on the profile.
const _competent = 3;

VidyaDone parseVidyaPortfolio(String markdown) {
  final learning = <({String title, String kind, String provider, String finished})>[];
  final skills = <String>[];
  var section = '';
  const kinds = _kinds;
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('## ')) {
      section = line.substring(3).trim().toLowerCase();
      continue;
    }
    if (!line.startsWith('- ')) continue;
    final item = line.substring(2);
    if (section == 'learning completed') {
      // "- Title (Kind, Provider, 3 Nov 2026)"
      final m = RegExp(r'^(.*) \(([^()]*)\)$').firstMatch(item);
      final title = (m?[1] ?? item).trim();
      final parts = (m?[2] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final kind = kinds[parts.firstOrNull?.toLowerCase()];
      if (kind == null || title.isEmpty) continue;
      final dated = parts.length > 1 && RegExp(r'\d{4}$').hasMatch(parts.last);
      learning.add((
        title: title,
        kind: kind,
        provider: parts.length > (dated ? 2 : 1) ? parts[1] : '',
        finished: dated ? parts.last : '',
      ));
    } else if (section == 'skills') {
      // "- **Category:** Name (Level), Name (Level)"
      final m = RegExp(r'^\*\*(.+?):\*\*\s*(.*)$').firstMatch(item);
      if (m == null || m[1]!.toLowerCase() == 'interview') continue;
      for (final s in RegExp(r'([^,()]+?)\s*\((Competent|Proficient|Expert)\)').allMatches(m[2]!)) {
        skills.add(s[1]!.trim());
      }
    }
  }
  return (learning: learning, skills: skills);
}

/// The same as [parseVidyaPortfolio], from what Vidya reports through sync.
VidyaDone vidyaDoneFrom(StudyProgress p) => (
  learning: [
    for (final l in p.learning)
      if (_kinds[l.kind.toLowerCase()] case final kind?)
        (title: l.title, kind: kind, provider: l.provider, finished: l.finished),
  ],
  skills: [
    for (final k in p.skills)
      if (k.level >= _competent && k.category.toLowerCase() != 'interview') k.name,
  ],
);

/// The one study plan Udyoga sends; sending again replaces it.
const studyPlanId = 'udyoga.study-plan';

/// A story's card id in Vidya: stable, so an edited story updates its card
/// in place instead of adding a second one.
String storyCardId(String storyId) => 'udyoga.story.$storyId';

/// The live link through sync: the plan as last sent, whether Vidya has
/// added it, and what Vidya reports finished.
typedef VidyaBridge = ({String? sent, bool added, VidyaDone done});

/// The candidate's records as a Vidya plan, and what Vidya finished back
/// into the profile.
extension VidyaLink on CareerBook {
  /// Sends the plan to Vidya through sync (the [bridge_study_plans] table).
  Future<void> sendToVidya({required String now}) async {
    final plan = await vidyaPlanNow();
    await save(
      db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(
        id: studyPlanId,
        source: 'udyoga',
        plan: jsonEncode(plan),
        updated: now,
      ),
      studyPlanId,
    );
  }

  /// Sends [i] to Vidya as its own study plan ("Study for this role"),
  /// beside the main one, which it does not touch. Returns the row id.
  Future<String> sendRoleToVidya(RoleInsight i, {required String now}) async {
    final id = rolePlanId(i.role);
    await save(
      db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(
        id: id,
        source: 'udyoga',
        plan: jsonEncode(roleVidyaPlan(i)),
        updated: now,
      ),
      id,
    );
    return id;
  }

  /// The Vidya plan for saved job [j], with the criteria of its latest
  /// role profile and its application's stage.
  Future<Json> _jobPlan(Job j) async {
    final profile = (await roleProfileRows()).where((r) => r.jobId == j.id).firstOrNull;
    final application =
        await (db.select(db.jobApplications)
              ..where((a) => a.jobId.equals(j.id) & a.deleted.not())
              ..limit(1))
            .getSingleOrNull();
    return jobVidyaPlan(
      j,
      profile: profile == null ? null : InterviewBook.roleProfileOf(profile),
      application: application,
      brief: await employerBrief(j.company),
      checks: application == null ? const [] : await checks(application.id),
    );
  }

  /// Sends [j] to Vidya as a plan with a journey ("Prepare this job").
  /// Returns the row id.
  Future<String> sendJobToVidya(Job j, {required String now}) async {
    final id = jobPlanId(j.id);
    await save(
      db.bridgeStudyPlans,
      BridgeStudyPlansCompanion.insert(
        id: id,
        source: 'udyoga',
        plan: jsonEncode(await _jobPlan(j)),
        updated: now,
      ),
      id,
    );
    return id;
  }

  /// Sends the job's journey again when it was sent before and has
  /// changed (the application moved on, say), so Vidya can suggest the
  /// next stage. Nothing happens otherwise.
  Future<void> refreshJobJourney(String? jobId, {required String now}) async {
    if (jobId == null) return;
    final sent = await (db.select(
      db.bridgeStudyPlans,
    )..where((p) => p.id.equals(jobPlanId(jobId)) & p.deleted.not())).getSingleOrNull();
    if (sent == null) return;
    final j = await (db.select(db.jobListings)..where((x) => x.id.equals(jobId))).getSingleOrNull();
    if (j == null) return;
    final plan = jsonEncode(await _jobPlan(j));
    if (plan != sent.plan) await save(db.bridgeStudyPlans, sent.copyWith(plan: plan, updated: now), sent.id);
  }

  /// Sends again every job plan already sent for [employer] (any case),
  /// so new employer research reaches Vidya as proposed facts.
  Future<void> refreshEmployerJourneys(String employer, {required String now}) async {
    final key = employer.toLowerCase().trim();
    if (key.isEmpty) return;
    final sent = await (db.select(
      db.bridgeStudyPlans,
    )..where((p) => p.id.like('${jobPlanId('')}%') & p.deleted.not())).get();
    for (final p in sent) {
      final jobId = p.id.substring(jobPlanId('').length);
      final j = await (db.select(db.jobListings)..where((x) => x.id.equals(jobId))).getSingleOrNull();
      if (j != null && j.company.toLowerCase().trim() == key) await refreshJobJourney(jobId, now: now);
    }
  }

  Future<VidyaBridge> vidyaBridge() async {
    final plan = await (db.select(
      db.bridgeStudyPlans,
    )..where((p) => p.id.equals(studyPlanId) & p.deleted.not())).getSingleOrNull();
    final progress = await (db.select(
      db.bridgeStudyProgress,
    )..where((p) => p.id.equals(studyPlanId) & p.deleted.not())).getSingleOrNull();
    return (
      sent: plan?.updated,
      added: plan != null && progress != null && progress.planUpdated == plan.updated,
      done: progress == null
          ? (learning: const <FinishedLearning>[], skills: const <String>[])
          : vidyaDoneFrom(StudyProgress.parse(progress.progress)),
    );
  }

  /// How much of [done] is not on the profile or Growth page yet: what
  /// [importVidya] would change.
  Future<({int learning, int skills})> vidyaNew(VidyaDone done) async {
    final growth = {
      for (final g in await (db.select(
        db.careerGrowth,
      )..where((g) => g.deleted.not() & g.kind.equals(todoKind).not())).get())
        if (g.status == 'done') g.title.toLowerCase().trim(),
    };
    final have = {for (final s in (await profile()).skills) s.toLowerCase().trim()};
    return (
      learning: done.learning.where((l) => !growth.contains(l.title.toLowerCase().trim())).length,
      skills: done.skills.map((s) => s.toLowerCase().trim()).toSet().difference(have).length,
    );
  }

  Future<Json> vidyaPlanNow() async => vidyaPlan(
    profile: await profile(),
    jobs: await (db.select(db.jobListings)..where((j) => j.deleted.not())).get(),
    stories: await stories(),
    storyCounts: await storyCounts(),
    roles: roleFrameworks(await roleProfileRows()),
    learning: await (db.select(
      db.careerGrowth,
    )..where((g) => g.deleted.not() & g.kind.equals(todoKind).not())).get(),
  );

  /// Marks finished learning done on the Growth page (adding what is not
  /// there) and adds new skills to the profile. Returns how many changed.
  Future<({int learning, int skills})> importVidya(VidyaDone done, {required String today}) =>
      db.transaction(() async {
        final existing = await (db.select(
          db.careerGrowth,
        )..where((g) => g.deleted.not() & g.kind.equals(todoKind).not())).get();
        final byTitle = {for (final g in existing) g.title.toLowerCase().trim(): g};
        var learning = 0;
        for (final l in done.learning) {
          final known = byTitle[l.title.toLowerCase().trim()];
          if (known != null) {
            if (known.status == 'done') continue;
            await save(
              db.careerGrowth,
              known.copyWith(status: 'done', progress: 100, done: Value(today)),
              known.id,
            );
          } else {
            final id = newId();
            await save(
              db.careerGrowth,
              CareerGrowthCompanion.insert(
                id: id,
                title: l.title,
                kind: l.kind,
                provider: Value(l.provider),
                status: const Value('done'),
                progress: const Value(100),
                done: Value(today),
                why: Value('Finished in Vidya${l.finished.isEmpty ? '' : ' (${l.finished})'}'),
                added: today,
              ),
              id,
            );
            byTitle[l.title.toLowerCase().trim()] = (await (db.select(
              db.careerGrowth,
            )..where((g) => g.id.equals(id))).getSingle());
          }
          learning++;
        }
        final p = await profile();
        final have = {for (final s in p.skills) s.toLowerCase().trim()};
        final added = [
          for (final s in done.skills)
            if (have.add(s.toLowerCase().trim())) s,
        ];
        if (added.isNotEmpty) await saveProfile(p.copyWith(skills: [...p.skills, ...added]));
        return (learning: learning, skills: added.length);
      });
}
