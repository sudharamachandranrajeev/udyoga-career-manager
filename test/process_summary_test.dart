import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/interview_scoring.dart';
import 'package:udyoga/domain/process_summary.dart';

// Fictional, self-written criteria: no real advert.
const diary = Criterion(id: 'c1', text: 'Experience of managing a busy appointments diary');
const together = Criterion(id: 'c2', text: 'Working together', kind: CriterionKind.value);
const records = Criterion(id: 'c3', text: 'Experience of a patient records system', essential: false);
const typing = Criterion(id: 'c4', text: 'Typing at 40 words a minute', kind: CriterionKind.skill, assessBy: ['T']);
const calm = Criterion(id: 'c5', text: 'Staying calm with upset callers');

CriterionCoverage cov(Criterion c, Coverage s, {bool asked = true}) =>
    CriterionCoverage(criterion: c, status: s, note: '', asked: asked);

AnswerNote note(int q, String fix) => AnswerNote(question: q, strength: 'Clear.', fix: fix);

Debrief debrief(List<CriterionCoverage> coverage, List<AnswerNote> notes) =>
    Debrief(framework: Framework.of('nhs_values'), coverage: coverage, notes: notes);

void main() {
  test('every criterion across the stages: where it was evidenced, or that it is missing', () {
    final s = ProcessSummary.build(
      [
        (
          stage: 'Screening call',
          debrief: debrief(
            [cov(diary, Coverage.thin), cov(together, Coverage.missing), cov(records, Coverage.missing, asked: false)],
            [note(0, 'Say what you yourself did.'), note(1, 'Name the result.')],
          ),
        ),
        (
          stage: 'Panel interview',
          debrief: debrief(
            [cov(diary, Coverage.evidenced), cov(together, Coverage.missing), cov(records, Coverage.thin)],
            [note(0, 'Name the result.'), note(1, 'Keep the answer to 2 minutes.'), note(2, 'Move toward a 3.')],
          ),
        ),
      ],
      profile: const RoleProfile(
        id: 'p1',
        title: 'Patient services administrator',
        frameworkId: 'nhs_values',
        criteria: [diary, together, records, typing, calm],
      ),
    );
    expect(s.stages, ['Screening call', 'Panel interview']);
    final by = {for (final c in s.criteria) c.criterion.id: c};
    expect(by['c1']!.status, Coverage.evidenced);
    expect(by['c1']!.evidencedIn, ['Panel interview']);
    expect(by['c1']!.thinIn, ['Screening call']);
    expect(by['c2']!.status, Coverage.missing);
    expect(by['c2']!.note, 'Asked, but no evidence heard in any stage.');
    expect(by['c3']!.status, Coverage.thin);
    // From the profile, never asked.
    expect(by['c5']!.asked, isFalse);
    expect(by['c5']!.note, 'Not asked in any stage yet.');
    expect(by['c4']!.unappointable, isFalse, reason: 'assessed by a test, not at interview');
    // Essentials first, gaps first among them; the test-only one last.
    expect([for (final c in s.criteria) c.criterion.id], ['c2', 'c5', 'c1', 'c3', 'c4']);
    expect([for (final c in s.missingEssentials) c.criterion.id], ['c2', 'c5']);

    // Top three: the missing essentials, then the fix that came up most.
    expect(s.topFixes, [
      ProcessSummary.prepareFix(together),
      ProcessSummary.prepareFix(calm),
      'Name the result.',
    ]);
    expect(s.topFixes.any(mentionsScale), isFalse);
  });

  test('with every essential evidenced, the top fixes are the most repeated, fresher counting more', () {
    final s = ProcessSummary.build([
      (
        stage: 'One',
        debrief: debrief(
          [cov(diary, Coverage.evidenced)],
          [note(0, 'Lead with the result.'), note(1, 'Say what you yourself did.')],
        ),
      ),
      (
        stage: 'Two',
        debrief: debrief(
          [cov(diary, Coverage.evidenced)],
          [note(0, 'Say what you yourself did.'), note(1, 'Slow down.'), note(2, 'Add a measure.'), note(3, '')],
        ),
      ),
    ]);
    expect(s.missingEssentials, isEmpty);
    expect(s.criteria.single.evidencedIn, ['One', 'Two']);
    expect(s.topFixes, ['Say what you yourself did.', 'Slow down.', 'Add a measure.']);
  });

  test('no stages run: nothing to show but the profile, all not asked', () {
    final s = ProcessSummary.build(const [], profile: const RoleProfile(id: 'p', title: 'T', criteria: [diary]));
    expect(s.stages, isEmpty);
    expect(s.criteria.single.asked, isFalse);
    expect(s.topFixes, [ProcessSummary.prepareFix(diary)]);
  });
}
