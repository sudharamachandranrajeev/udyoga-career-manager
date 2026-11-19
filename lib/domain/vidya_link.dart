/// The link with Vidya, the learning app: what the candidate still needs
/// goes out as a Vidya study plan; what they finish in Vidya comes back.
library;

import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'companion.dart';
import 'companion_book.dart';
import 'insights.dart';
import 'json.dart';
import 'profile.dart';
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
