import 'dart:convert';
import 'dart:typed_data';

import '../db/database.dart';
import 'answer_metrics.dart';
import 'avenues.dart';
import 'companion.dart';
import 'ai.dart';
import 'countries.dart';
import 'explore.dart';
import 'insights.dart';
import 'interview_plan.dart';
import 'interview_scoring.dart';
import 'json.dart';
import 'occupations.dart';
import 'page_reader.dart';
import 'profile.dart';
import 'resume.dart';
import 'schema.dart';

typedef Progress = void Function(String status);

/// A CV to read: a PDF (the model reads the layout itself) or text, with the
/// document's [name].
sealed class CvSource {
  const CvSource(this.name);
  final String name;
}

class PdfCv extends CvSource {
  const PdfCv(this.bytes, {String name = 'CV.pdf'}) : super(name);
  final Uint8List bytes;
}

class TextCv extends CvSource {
  const TextCv(this.text, {String name = 'Pasted CV'}) : super(name);
  final String text;
}

/// Udyoga's career adviser: every AI task, its instructions and its schema.
/// The candidate's profile goes with each request; nothing else about the
/// user does.
class Advisor {
  Advisor(this.ai, {required this.today});
  final Ai ai;

  /// yyyy-MM-dd, so research is dated and deadlines are judged right.
  final String today;

  String _system(CandidateProfile p) {
    final home = p.country.isEmpty ? 'the candidate\'s country' : Country.nameOf(p.country);
    return '''
You are Udyoga's career adviser: a senior recruiter, hiring manager and careers coach who knows the job market in $home and abroad. Today is $today.

Principles:
- Be realistic and candid. Say plainly when something is a long shot and why; do not flatter. The candidate wants to be ready for the toughest version of every challenge.
- Never invent experience, qualifications, employers, dates, figures or achievements. Work only from the candidate's profile and CV. Where something would help but is not there, say what is missing instead of making it up.
- Facts that change (salaries, demand, pay bands, visa and right-to-work rules, certifications, how AI is changing the work) must be current: research them and prefer sources from the last 12 months. Give currencies and the year of any figure.
- Account for the growth of AI in the candidate's field in every judgement: what is being automated, what is growing in value, and what employers now expect.
- Use the spelling and terms of the candidate's country (for example "CV" and UK English in the UK and Ireland).
- Be specific and practical: name real employers, job sites, qualifications and awarding bodies, with official links where you have them.''';
  }

  Json _candidate(CandidateProfile p) => {
    'type': 'text',
    'text': '<candidate>\n${jsonEncode(p.forPrompt())}\n</candidate>',
  };

  Json _text(String t) => {'type': 'text', 'text': t};

  String _job(Job j) => jsonEncode({
    'title': j.title,
    'company': j.company,
    'location': j.location,
    'country': j.country,
    'salary': j.salaryText.isNotEmpty ? j.salaryText : _salary(j),
    'url': j.url,
    'posted': j.posted,
    'closing': j.closing,
    'advert': j.description,
  });

  String _salary(Job j) => [
    if (j.salaryMin != null) '${j.salaryMin}',
    if (j.salaryMax != null && j.salaryMax != j.salaryMin) '${j.salaryMax}',
  ].join('–').let((s) => s.isEmpty ? '' : '${j.currency} $s'.trim());

  /// Reads one or more CVs into one profile. Several are usually versions of
  /// the same CV tailored for different roles: they are merged into a master
  /// profile that keeps everything any of them says.
  Future<CandidateProfile> readCv(List<CvSource> cvs) async {
    final many = cvs.length > 1;
    final content = <Json>[
      for (final cv in cvs)
        ...switch (cv) {
          PdfCv(:final bytes) => [
            _text('<cv name="${cv.name}">'),
            {
              'type': 'document',
              'source': {'type': 'base64', 'media_type': 'application/pdf', 'data': base64Encode(bytes)},
            },
            _text('</cv>'),
          ],
          TextCv(:final text) => [_text('<cv name="${cv.name}">\n$text\n</cv>')],
        },
      _text(
        many
            ? 'These ${cvs.length} CVs belong to the same candidate, most likely versions tailored for different '
                  'roles. Fill in one master profile from all of them.'
            : 'This is the candidate\'s CV. Fill in the profile from it.',
      ),
    ];
    final r = await ai.ask(
      system:
          'You read CVs and fill in a structured profile exactly as the CVs state it. Today is $today. '
          'Copy facts faithfully; do not improve, guess or add anything. Leave unknown fields empty.'
          '${many ? ' With several CVs: list each job once (the same employer and dates is the same job, '
                    'however the title or wording differs; prefer the fuller title) and keep every distinct '
                    'highlight from any version, without repeating the same point. Combine skills, '
                    'certifications, achievements and languages without duplicates. Take contact details and '
                    'the summary from the most recent or most complete version. Put every role the versions '
                    'aim at in the target roles. Where versions contradict each other on a fact, use the most '
                    'recent document\'s.' : ''}',
      content: content,
      schema: CandidateProfile.schema,
      effort: many ? 'high' : 'medium',
    );
    return CandidateProfile.fromJson(r.data);
  }

  /// The deep assessment: market position, strengths and weaknesses, the
  /// toughest challenges, AI impact, target roles, countries and learning.
  Future<AiResult> assess(CandidateProfile p, {Progress? onProgress}) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text(
        '''
Assess this candidate thoroughly and research the current market for them.

Cover: where they stand today and how competitive they are; strengths with evidence from the CV; weaknesses and how to fix each; the toughest challenges to their next move and how to prepare; how AI is changing their field; the roles they should target now with current salary ranges and job-board search terms; their prospects in their current country and in realistic other countries ${p.searchCountries.isEmpty ? '' : '(they are considering ${p.searchCountries.map(Country.nameOf).join(', ')})'} including right to work; and the certifications, courses, degrees and experience that would most improve their prospects, with providers, costs and official links. End with quick wins for this week.''',
      ),
    ],
    schema: Assessment.schema,
    web: true,
    searches: 12,
    onProgress: onProgress,
  );

  /// Every realistic career path from the current role.
  Future<AiResult> careerMap(CandidateProfile p, {Assessment? assessment, Progress? onProgress}) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      if (assessment != null) _text('<assessment>\n${jsonEncode(assessment.j)}\n</assessment>'),
      _text(
        '''
Map every realistic career progression from the candidate's current role: up the same ladder, sideways into related roles, specialist routes, management, a change of field, and independent work where it fits. For each path give two to four steps with timeframes, current salary ranges, likelihood, what each step requires (experience, skills, certifications) and typical employers in their countries. Judge each path's exposure to AI and say which parts will grow or shrink. Be honest about which paths are ambitious. Recommend one path and say why. Research current pay scales, grade structures and hiring trends.''',
      ),
    ],
    schema: CareerMap.schema,
    web: true,
    searches: 10,
    onProgress: onProgress,
  );

  /// How well the candidate fits [job], with research on the employer.
  Future<AiResult> assessJob(CandidateProfile p, Job job, {Progress? onProgress}) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text('<job>\n${_job(job)}\n</job>'),
      _text(
        '''
Evaluate this job for the candidate as a demanding hiring manager would. If the advert text is short, read the advert at its URL. Research the employer (what it is like to work there, recent news, pay against the market). Score the fit honestly against the essential and desirable criteria, list each requirement they meet with evidence from the CV and each gap with its severity and how to close or address it, and give realistic odds of an interview and an offer. Pick out the keywords the application must contain and what the interview will probe.''',
      ),
    ],
    schema: FitAssessment.schema,
    web: true,
    searches: 6,
    onProgress: onProgress,
  );

  /// An avenue: whether [screen]'s country is realistic for the candidate,
  /// with live adverts, pay against living costs, the route by name and
  /// honest pushback. [economy] gives sourced figures to work from.
  Future<AiResult> assessAvenue(
    CandidateProfile p,
    CountryScreen screen, {
    List<OccupationMatch> occupations = const [],
    CountryEconomy? economy,
    Progress? onProgress,
  }) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text('<screen>\n${jsonEncode(screenForPrompt(screen))}\n</screen>'),
      if (occupations.isNotEmpty)
        _text(
          '<occupation_codes>\n${jsonEncode([for (final o in occupations) o.toJson()])}\n</occupation_codes>',
        ),
      if (economy != null && economy.figures.isNotEmpty)
        _text('<economy>\n${jsonEncode(economy.toJson())}\n</economy>'),
      _text(
        '''
Assess ${screen.country.name} as an avenue for this candidate. Udyoga's rule-based screen above put it in "${screen.tier.label}"; check it against the official sources and say where it is wrong.

Cover: the role families they could do there (local job titles, codes, demand and current pay); three to six live adverts you actually find now, with links (never invent one); typical pay against rent and living costs, using the economy figures where they help; the visa or permit route by its official name and page, its current threshold, and whether it fits; every blocker (language, pay floor, jobs reserved for nationals, recognition of qualifications, registration, the employer's willingness to sponsor) with how to fix it; and plain pushback where the candidate's hopes or the screen are unrealistic. Give your confidence and what it rests on. Answer for country code ${screen.code}.''',
      ),
    ],
    schema: AvenueAssessment.schema,
    web: true,
    searches: 10,
    onProgress: onProgress,
  );

  /// A prep plan for an avenue: ordered steps (qualifications, tests,
  /// certifications with cost and time, CV gaps, applications) that finish
  /// before [deadline], and the qualification planner.
  Future<AiResult> prepPlan(
    CandidateProfile p,
    CountryScreen screen, {
    AvenueAssessment? assessment,
    String? deadline,
    List<QualificationOption> options = const [],
    Progress? onProgress,
  }) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text('<screen>\n${jsonEncode(screenForPrompt(screen))}\n</screen>'),
      if (assessment != null) _text('<avenue_assessment>\n${jsonEncode(assessment.j)}\n</avenue_assessment>'),
      if (options.isNotEmpty)
        _text('<known_options>\n${jsonEncode([for (final o in options) o.toJson()])}\n</known_options>'),
      _text(
        '''
Make a prep plan for moving to ${screen.country.name}${deadline == null ? '' : ", with everything finished before $deadline (when the candidate's current right to work or the route closes)"}. Today is $today.

Order the steps so that what unlocks later steps comes first: getting qualifications recognised or verified, language tests, certifications that employers there ask for (with cost and time from official or clearly named sources), CV gaps to close, applications, and any tests or registrations. Date each step so the whole plan fits before the deadline, and say when it cannot fit.

Qualification planner: decide whether the route or the target jobs need the candidate's qualifications recognised or verified. Compare the options (start from the known options above, which carry their sources), including whether each needs the awarding university to respond, and recommend which to take and when. Prefer options that do not depend on a slow university when time is short. Mark a step verified only when you read its cost and time on an official page. Answer for country code ${screen.code}.''',
      ),
    ],
    schema: PrepPlan.schema,
    web: true,
    searches: 8,
    effort: 'medium',
    onProgress: onProgress,
  );

  /// Research on what it is like to work for [employer]: systems, culture
  /// evidence with sources, and risks.
  Future<AiResult> researchEmployer(
    CandidateProfile p,
    String employer, {
    String place = '',
    Progress? onProgress,
  }) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text('<employer>$employer${place.isEmpty ? '' : ' ($place)'}</employer>'),
      _text(
        '''
Research what it is like to work for this employer in the candidate's kind of role. Find the systems staff use day to day (for health employers: the electronic patient record, patient administration and rostering systems, and any planned replacement with its date), evidence on culture from official sources (the latest staff survey results such as "would recommend as a place to work", inspection ratings, awards, recent news), and any risks such as restructures, mergers or financial pressure. Cite a source URL for every culture point. Say plainly when you could not find something; do not guess. End with good questions the candidate could ask at interview.''',
      ),
    ],
    schema: EmployerBrief.schema,
    web: true,
    searches: 8,
    effort: 'medium',
    onProgress: onProgress,
  );

  /// A CV (and cover letter) for [job], from the profile.
  Future<AiResult> tailor(CandidateProfile p, Job job, {FitAssessment? fit, Progress? onProgress}) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text('<base_cv>\n${jsonEncode(ResumeDoc.fromProfile(p).toJson())}\n</base_cv>'),
      _text('<job>\n${_job(job)}\n</job>'),
      if (fit != null) _text('<fit_assessment>\n${jsonEncode(fit.j)}\n</fit_assessment>'),
      _text(
        '''
Tailor the CV to this job. Follow the job description, key responsibilities, essential and desirable criteria and the employer's values:
- Rewrite the profile for this role. Order skills and bullets so the most relevant come first; lead bullets with actions and results, using real figures from the CV only.
- Use the advert's wording where it truthfully describes the candidate's experience, so applicant tracking systems match it. Do not add a skill, duty, qualification or result the candidate does not have; list such keywords as missing instead.
- Keep it to about two pages: cut or shorten what does not serve this job.
- Keep the candidate's real job titles, employers and dates.
Then write the cover letter (or supporting statement, if the advert asks for one against criteria), and the notes.''',
      ),
    ],
    schema: tailorSchema,
    effort: 'high',
    onProgress: onProgress,
  );

  /// Quick fit scores for many jobs at once, from their adverts.
  Future<Map<String, ({int fit, String why})>> triage(CandidateProfile p, List<Job> jobs) async {
    if (jobs.isEmpty) return const {};
    final list = [
      for (final j in jobs)
        {
          'id': j.id,
          'title': j.title,
          'company': j.company,
          'location': j.location,
          'salary': j.salaryText.isNotEmpty ? j.salaryText : _salary(j),
          'advert': j.description.length > 700 ? '${j.description.substring(0, 700)}…' : j.description,
        },
    ];
    final r = await ai.ask(
      system: _system(p),
      content: [
        _candidate(p),
        _text('<jobs>\n${jsonEncode(list)}\n</jobs>'),
        _text(
          'Score each job 0 to 100 for this candidate (70+ only if they meet nearly all essentials), '
          'with one line on why. Be strict about level, location, right to work and pay.',
        ),
      ],
      schema: object({
        'scores': array(object({'id': string(), 'fit': integer(), 'why': string()})),
      }),
      effort: 'low',
      maxTokens: 16000,
    );
    return {
      for (final s in objs(r.data['scores']))
        str(s['id']): (fit: (intOf(s['fit']) ?? 0).clamp(0, 100), why: str(s['why'])),
    };
  }

  /// Searches the web for current openings across the candidate's countries
  /// and job sites (LinkedIn, Indeed, national and public-sector boards).
  Future<AiResult> findJobs(
    CandidateProfile p, {
    required List<String> countries,
    List<String> known = const [],
    Progress? onProgress,
  }) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      _text('''
Find current job openings this candidate could realistically apply for now, in ${countries.map(Country.nameOf).join(', ')}${p.targets.remote ? ', and remote roles open to them' : ''}. Search the main job sites for each country (LinkedIn, Indeed and the national, public-sector and specialist boards), employers' own career pages and recruiters. Include roles one step up where they are competitive, not only like-for-like.
Only include adverts that are open today ($today) and link to the advert itself. Skip any already known:
${known.isEmpty ? '(none)' : known.take(200).join('\n')}
Return up to 20, best fit first.'''),
    ],
    schema: FoundJob.schema,
    web: true,
    searches: 15,
    effort: 'medium',
    onProgress: onProgress,
  );

  /// Reads an advert from its page or pasted text into job fields.
  Future<Json> readAdvert({String url = '', String text = '', Progress? onProgress}) async {
    final r = await ai.ask(
      system: 'You extract job adverts into fields exactly as written. Today is $today.',
      content: [
        _text(
          url.isNotEmpty && text.isEmpty
              ? 'Read the job advert at $url and fill in its fields. Put the full role description, key '
                    'responsibilities and person specification in the description.'
              : '<advert url="$url">\n$text\n</advert>\n\nFill in this advert\'s fields. Put the full role '
                    'description, key responsibilities and person specification in the description.',
        ),
      ],
      schema: object({
        'title': string(),
        'company': string(),
        'location': string(),
        'country': string('ISO alpha-2'),
        'remote': boolean(),
        'salaryText': string(),
        'posted': string("yyyy-MM-dd or ''"),
        'closing': string("yyyy-MM-dd or ''"),
        'description': string(),
      }),
      web: url.isNotEmpty && text.isEmpty,
      searches: 3,
      effort: 'low',
      onProgress: onProgress,
    );
    return r.data;
  }

  /// Reads a screenshot of a page (a PNG) into job, person and employer
  /// records, as they are written there. Only offered when the model reads
  /// images ([AiProvider.images]).
  Future<Json> readScreenshot(Uint8List png, {String url = '', Progress? onProgress}) async {
    final r = await ai.ask(
      system:
          'You read screenshots of web pages into records exactly as written: a job advert (job), people named '
          'with their role and contact details as shown (person), and the employer (company). Copy the words on '
          'the page; never guess or add anything that is not visible. Leave a field empty when the page does not '
          'show it. Dates as yyyy-MM-dd. Today is $today.',
      content: [
        {
          'type': 'image',
          'source': {'type': 'base64', 'media_type': 'image/png', 'data': base64Encode(png)},
        },
        _text('This is a screenshot of ${url.isEmpty ? 'a web page' : url}. List the records on it.'),
      ],
      schema: visionRecordsSchema,
      effort: 'low',
      maxTokens: 8000,
      onProgress: onProgress,
    );
    return r.data;
  }

  /// People worth contacting about [job] or at [company]: recruiters,
  /// hiring managers, teams, from public professional pages.
  Future<AiResult> findLeads(CandidateProfile p, {Job? job, String company = '', Progress? onProgress}) =>
      ai.ask(
        system: _system(p),
        content: [
          _candidate(p),
          if (job != null) _text('<job>\n${_job(job)}\n</job>'),
          _text(
            '''
Find people and teams the candidate could contact about ${job != null ? 'this job' : 'openings${company.isEmpty ? ' in their field' : ' at $company'}'}: the recruiter or hiring manager named on the advert, the employer's recruitment team, specialist recruitment agencies and consultants for this field and area, and professional groups or events where they would meet hiring managers. Use only professional information that people or organisations publish for this purpose (adverts, team pages, agency sites, public LinkedIn profiles and company pages). Do not guess e-mail addresses or include private contact details. For each, say how to approach them and what to say first.''',
          ),
        ],
        schema: LeadSuggestion.schema,
        web: true,
        searches: 8,
        effort: 'medium',
        onProgress: onProgress,
      );

  /// A short message: outreach to a lead, chasing feedback, thanks after an
  /// interview.
  Future<Draft> draft(CandidateProfile p, {required String purpose, String context = ''}) async {
    final r = await ai.ask(
      system: _system(p),
      content: [
        _candidate(p),
        if (context.isNotEmpty) _text('<context>\n$context\n</context>'),
        _text(
          'Write this message for the candidate to send: $purpose. Keep it short, warm and professional, '
          'specific to the context, with one clear ask. Sign with the candidate\'s name.',
        ),
      ],
      schema: Draft.schema,
      effort: 'low',
      maxTokens: 8000,
    );
    return Draft(r.data);
  }

  /// A practice interview's questions.
  Future<AiResult> practiceQuestions(
    CandidateProfile p, {
    required String role,
    required String mode,
    Job? job,
    int count = 8,
    Progress? onProgress,
  }) => ai.ask(
    system: _system(p),
    content: [
      _candidate(p),
      if (job != null) _text('<job>\n${_job(job)}\n</job>'),
      _text(
        '''
Prepare $count interview questions for the candidate for the role of $role.
Kind of interview: ${practiceModes[mode] ?? mode}.
Research how this employer or sector interviews now (competency frameworks, values, panel formats, assessment centres, current hot topics including AI adoption) and ask what a real panel would ask in $today's market. Make at least a third of them hard, and include questions that probe the gaps in the candidate's CV. For each, say what the panel is testing and what a top answer includes.''',
      ),
    ],
    schema: PracticeQuestion.schema,
    web: true,
    searches: 5,
    effort: 'medium',
    onProgress: onProgress,
  );

  /// Writes the round's question plan (interview plan I2): for each
  /// question, the criterion it tests, the elements a full answer has and
  /// probes for each. Only the questions go: no profile, no answers. The
  /// probe is later picked on the device from what the answer lacks.
  Future<List<QuestionPlan>> questionPlan({
    required String role,
    required List<PracticeQuestion> questions,
  }) async {
    final r = await ai.ask(
      system:
          'You plan structured interview questions the way a trained UK panel does: each question tests one '
          'pre-agreed criterion, and follow-up probes are chosen by what an answer leaves out. Use plain UK '
          'English. Probes are short, neutral and open; never leading, never two questions in one.',
      content: [
        _text(
          '<round role="${_attr(role)}">\n'
          '${[for (final (i, q) in questions.indexed) '<question n="${i + 1}" kind="${_attr(q.category)}">${q.question}</question>'].join('\n')}\n'
          '</round>',
        ),
        _text('''
For each question, in order, give:
- criterion: what it tests, in a few words.
- expected: the elements a full answer has, from: situation (one specific example), ownAction (what the candidate did themselves), measure (how they measured it or knew it worked), result (the outcome), learning (what they learned or would do differently), others (who else was involved). Settler, motivation, strengths and "any questions for us" questions expect none.
- probes: one or two short follow-ups for each expected element, worded for this question.'''),
      ],
      schema: object({
        'questions': array(
          object({
            'criterion': string(),
            'expected': array(oneOf([for (final e in AnswerElement.values) e.name])),
            'probes': array(
              object({
                'element': oneOf([for (final e in AnswerElement.values) e.name]),
                'text': string(),
              }),
            ),
          }),
        ),
      }),
      effort: 'low',
      maxTokens: 6000,
    );
    return [for (final q in objs(r.data['questions'])) QuestionPlan.fromJson(q)];
  }

  /// Reads an advert and person specification into the criteria a panel
  /// agrees in advance (interview plan I3). Only the advert goes: no
  /// profile. The reply is checked and parsed by [parseCriteria]; the user
  /// edits it before it is used.
  Future<Json> readCriteria({required String advert, String title = ''}) async {
    final r = await ai.ask(
      system:
          'You read job adverts and person specifications the way a UK or Irish recruiting panel does before '
          'shortlisting. List only criteria the text states; never add your own. Keep each criterion in the '
          "document's own words, shortened. Use plain UK English.",
      content: [
        _text('<advert title="${_attr(title)}">\n$advert\n</advert>'),
        _text(
          '''
List every essential and desirable criterion in the person specification (and any the advert states as required), one per item:
- text: the criterion, short, in the document's words.
- essential: true when the document calls it essential or required; false when desirable.
- kind: experience, skill, knowledge, value, behaviour or qualification.
- assessBy: how it is assessed when the document says (A application, I interview, T test, P presentation); [] when it does not say.
- question: one open, neutral interview question that tests it. Values: "What does … mean to you, and when have you shown it?". Experience and behaviours: "Tell us about a time…".
Also give the job title, the employer, and the framework this employer most likely scores with (nhs_values for NHS England, Scotland and Wales; hsc_ni for Health and Social Care Northern Ireland; civil_service for the UK Civil Service; hse_ie for the HSE in Ireland; private otherwise).''',
        ),
      ],
      schema: criteriaSchema,
      effort: 'low',
      maxTokens: 8000,
    );
    return r.data;
  }

  /// Scores a whole round against the agreed criteria (interview plan I3):
  /// only the transcripts and the criteria go, no profile. Every score must
  /// quote the transcript; the caller checks each quote with
  /// [verifyScores] and drops any that is not there.
  Future<List<AnswerScore>> scoreRound({
    required String role,
    required Framework framework,
    required List<Criterion> criteria,
    required List<({int index, String question, List<String> criteria, String answer})> answers,
  }) async {
    final scale = framework.scale;
    final r = await ai.ask(
      system:
          'You are a trained interview panel member scoring a practice interview. You score only what the '
          'candidate said, against criteria agreed in advance, on the panel\'s own scale. Never guess: if the '
          'transcript has no evidence for a criterion, give the "no evidence" level. Every other level must quote '
          'the candidate\'s exact words that it rests on. Feedback is about the task, never the person: no '
          'judgements of confidence or personality, no percentages.',
      content: [
        _text(
          '<scale name="${_attr(scale.name)}">\n'
          '${[for (final l in scale.levels) '<level code="${l.code}" label="${_attr(l.label)}">${l.anchor}</level>'].join('\n')}\n'
          '</scale>\n'
          '<criteria role="${_attr(role)}">\n'
          '${[for (final c in criteria) '<criterion id="${c.id}" essential="${c.essential}">${c.text}</criterion>'].join('\n')}\n'
          '</criteria>',
        ),
        _text(
          '<round>\n'
          '${[for (final a in answers) '<answer question="${a.index + 1}" tests="${a.criteria.join(',')}">\n<asked>${a.question}</asked>\n<said>\n${a.answer}\n</said>\n</answer>'].join('\n')}\n'
          '</round>',
        ),
        _text('''
For each answer, score each criterion it tests (its "tests" ids) on the scale:
- level: a code from the scale. "${scale.noEvidence.code}" when the answer has no evidence for it, or only a bare claim.
- quote: the candidate's exact words (one sentence or part of one, copied character for character) that the level rests on; "" for "${scale.noEvidence.code}".
Then one strength of the answer and one fix: a concrete thing to do differently in the answer next time.
The strength and the fix never mention scores, levels, the scale or its numbers (not "move toward a 3", not "to score higher"). Say what to do, for example "Say how you knew it worked: a number, a check or feedback."'''),
      ],
      schema: scoringSchema(scale, [for (final c in criteria) c.id]),
      effort: 'medium',
      maxTokens: 12000,
    );
    return parseScoring(r.data);
  }

  /// Scores an answer on every dimension, with a better version.
  Future<AnswerReview> review(
    CandidateProfile p, {
    required String role,
    required String mode,
    required PracticeQuestion question,
    required String answer,
  }) async {
    final m = AnswerMetrics.of(answer);
    final r = await ai.ask(
      system: _system(p),
      content: [
        _candidate(p),
        _text(
          '<interview role="${_attr(role)}" kind="${_attr(practiceModes[mode] ?? mode)}">\n'
          '<question category="${_attr(question.category)}">${question.question}</question>\n'
          '<testing>${question.why}</testing>\n'
          '<top_answer_includes>${question.lookFor.join('; ')}</top_answer_includes>\n'
          '<answer>\n$answer\n</answer>\n'
          '<measured words="${m.words}" speaking_seconds="${m.speakingTime.inSeconds}" fillers="${m.fillers}" '
          'i_count="${m.iCount}" we_count="${m.weCount}" figures="${m.figures}" star="${m.star.join(',')}"/>\n'
          '</interview>',
        ),
        _text(
          '''
Evaluate the answer as a strict, experienced panel would in today's market. Score each dimension 0 to 10:
- Relevance: answers the question asked, for this role.
- Structure: clear STAR (situation, task, action, result) or equivalent; easy to follow.
- Evidence: a specific, real example with the candidate's own actions, not generalities.
- Impact: measurable results and what changed because of them.
- Communication: concise, confident, right length (about two minutes), few fillers.
- Role knowledge: understanding of the role, sector, standards and current practice.
- AI and change readiness: awareness of how AI and new tools are changing the work, and adaptability.
Then the overall score, what was strong, what to improve (most important first; each an action to take in the answer, never put in terms of the score), any red flags, a better answer using only the candidate's real experience, and the follow-up a tough interviewer would ask.''',
        ),
      ],
      schema: AnswerReview.schema,
      effort: 'medium',
      maxTokens: 12000,
    );
    return AnswerReview(r.data);
  }

  String _attr(String s) => s.replaceAll('"', "'");

  List<Json> _sources(List<CvSource> docs, String tag) => [
    for (final d in docs)
      ...switch (d) {
        PdfCv(:final bytes) => [
          _text('<$tag name="${_attr(d.name)}">'),
          {
            'type': 'document',
            'source': {'type': 'base64', 'media_type': 'application/pdf', 'data': base64Encode(bytes)},
          },
          _text('</$tag>'),
        ],
        TextCv(:final text) => [_text('<$tag name="${_attr(d.name)}">\n$text\n</$tag>')],
      },
  ];

  /// Reads the candidate's own documents: what each is, what it states
  /// about them and the stories in it. A few at a time.
  Future<List<DocumentReading>> readDocuments(
    CandidateProfile p,
    List<CvSource> docs, {
    Progress? onProgress,
  }) async {
    final r = await ai.ask(
      system:
          'You read a job candidate\'s own documents (CVs, references, interview notes, application answers, '
          'adverts they kept) and record what they state about the candidate. Today is $today. Copy facts '
          'faithfully; never improve, guess or add. Facts about other people (referees, managers, patients) are '
          'not recorded, and no patient or service-user details are ever copied.',
      content: [
        _candidate(p),
        ..._sources(docs, 'document'),
        _text(
          'For each document: its kind, a one-line summary, the facts it states about the candidate (dates, roles, '
          'duties, figures, systems, qualifications, achievements) and any real examples of their work that could '
          'answer an interview question, as STAR stories in the candidate\'s first person. Return one entry per '
          'document, using each document\'s name exactly.',
        ),
      ],
      schema: DocumentReading.schema,
      effort: 'medium',
      onProgress: onProgress,
    );
    return objs(r.data['documents']).map(DocumentReading.fromJson).toList();
  }

  /// Questions that would make the profile accurate: documents that disagree,
  /// claims without support, points only one old document makes.
  Future<List<QuestionDraft>> profileQuestions(
    CandidateProfile p, {
    required List<({String name, String kind, List<DocumentFact> facts})> documents,
    required List<String> settled,
    int max = 8,
  }) async {
    final r = await ai.ask(
      system: _system(p),
      content: [
        _candidate(p),
        _text(
          '<documents>\n${jsonEncode([
            for (final d in documents) {'name': d.name, 'kind': d.kind, 'facts': d.facts.map((f) => f.toJson()).toList()},
          ])}\n</documents>',
        ),
        if (settled.isNotEmpty) _text('<already_settled>\n${settled.join('\n')}\n</already_settled>'),
        _text(
          'Compare the profile with what the documents state. List up to $max questions for the candidate, most '
          'important first, about: facts that disagree between documents or with the profile (dates, titles, '
          'figures), claims an employer would ask them to prove (estimated figures, "available on request"), and '
          'gaps in employment over three months without an explanation. Never ask about anything already settled. '
          'Do not ask for opinions, only facts. Give likely answers as choices when the documents disagree.',
        ),
      ],
      schema: QuestionDraft.schema,
      effort: 'medium',
      maxTokens: 12000,
    );
    return objs(r.data['questions']).map(QuestionDraft.fromJson).toList();
  }

  /// The profile with the candidate's confirmed answers written in.
  Future<CandidateProfile> reviseProfile(CandidateProfile p, List<String> confirmed) async {
    final r = await ai.ask(
      system:
          'You keep a job candidate\'s structured profile accurate. Today is $today. Change only what the '
          'candidate\'s confirmed answers require; keep everything else exactly as it is, word for word.',
      content: [
        _candidate(p),
        _text('<confirmed_by_candidate>\n${confirmed.join('\n')}\n</confirmed_by_candidate>'),
        _text('Return the whole profile with these answers applied.'),
      ],
      schema: CandidateProfile.schema,
      effort: 'medium',
    );
    final revised = CandidateProfile.fromJson(r.data);
    // The AI never sees these as editable; keep the originals.
    return revised.copyWith(
      targets: p.targets,
      cvText: p.cvText,
      versions: p.versions,
      notes: p.notes,
      stories: p.stories,
      confirmed: p.confirmed,
    );
  }

  /// Today's check-in question: aimed at what the candidate's target roles
  /// ask for and their evidence still lacks.
  Future<String> checkInQuestion(
    CandidateProfile p, {
    required String weakest,
    required List<String> recent,
    String followUp = '',
  }) async {
    final r = await ai.ask(
      system: _system(p),
      content: [
        _candidate(p),
        _text(
          '<recent_check_ins>\n${recent.join('\n')}\n</recent_check_ins>\n'
          '<least_evidence>${competencyNames[weakest] ?? weakest}</least_evidence>'
          '${followUp.isEmpty ? '' : '\n<follow_up_from_yesterday>$followUp</follow_up_from_yesterday>'}',
        ),
        _text(
          'Write the one question to ask the candidate at the end of their working day. It should be quick to '
          'answer in a few sentences, about their real day at work, and draw out an example the candidate could '
          'use at interview for their target roles: prefer yesterday\'s follow-up if there is one, otherwise the '
          'competency with least evidence. Plain words, second person, one question only, no preamble.',
        ),
      ],
      schema: object({'question': string()}),
      effort: 'low',
      maxTokens: 2000,
    );
    return str(r.data['question']);
  }

  /// What a check-in answer adds: stories, skills, wins, learning.
  Future<CheckInDigest> digestCheckIn(
    CandidateProfile p, {
    required String question,
    required String answer,
  }) async {
    final r = await ai.ask(
      system:
          '${_system(p)}\n\nYou are reading the candidate\'s end-of-day check-in. Take only what they actually '
          'said; never add results, figures or actions they did not state. No patient or service-user details.',
      content: [
        _candidate(p),
        _text('<check_in>\n<question>$question</question>\n<answer>\n$answer\n</answer>\n</check_in>'),
        _text(
          'Record what this adds to the candidate\'s evidence: STAR stories (first person, only when the answer '
          'describes a real example), skills or systems the profile lacks, CV-worthy achievements, things to learn, '
          'and a follow-up question for tomorrow when a story is missing its result.',
        ),
      ],
      schema: CheckInDigest.schema,
      effort: 'low',
      maxTokens: 8000,
    );
    return CheckInDigest.fromJson(r.data);
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
