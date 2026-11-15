import 'dart:convert';

import 'package:brahma_core/brahma_core.dart' show addDays, isoDate, newId;
import 'package:drift/drift.dart' show Value;
import 'package:udyoga/db/database.dart';
import 'package:udyoga/domain/ai.dart';
import 'package:udyoga/domain/book.dart';
import 'package:udyoga/domain/companion.dart';
import 'package:udyoga/domain/companion_book.dart';
import 'package:udyoga/domain/conversations.dart';
import 'package:udyoga/domain/feeds.dart';
import 'package:udyoga/domain/insights.dart';
import 'package:udyoga/domain/mail.dart';
import 'package:udyoga/domain/mail_sync.dart';
import 'package:udyoga/domain/pay.dart';
import 'package:udyoga/domain/pipeline.dart';
import 'package:udyoga/domain/post_plan.dart';

import 'support.dart';

/// A book with something on every page: profile, jobs, applications at
/// several stages, a lead, a career map, an assessment, growth items and a
/// practice round with a reviewed answer.
Future<void> seedBook(CareerBook book, {String today = '2026-10-24'}) async {
  // Today's lists look ahead from the real date, so these stay in the future.
  final soon = addDays(isoDate(DateTime.now()), 3);
  await book.saveProfile(sampleProfile);
  final ids = await book.importPostings(
    [
      samplePosting(closing: soon),
      samplePosting(id: '2', title: 'Digital Nurse Specialist', company: 'Sample Care Group'),
      samplePosting(id: '3', title: 'EPR Trainer', company: 'Northwind Health'),
      samplePosting(
        id: '4',
        title: 'Nursing Informatics Lead',
        company: 'Contoso Medical',
        description: 'Lead EPR optimisation and patient safety training for nursing staff.',
      ),
      samplePosting(id: '5', title: 'Patient Safety Educator', company: 'Fabrikam Clinics'),
      samplePosting(id: '6', title: 'Digital Health Analyst', company: 'Example Labs', description: 'Data.'),
    ],
    sampleProfile,
    today: today,
  );
  await book.setJobStatus(ids[0], 'saved');
  final a1 = await book.applyFor(await book.job(ids[1]), today: '2026-10-10', sent: true);
  final a2 = await book.applyFor(await book.job(ids[2]), today: '2026-10-01', sent: true);
  await book.moveTo(a2, Stage.interview, date: '2026-10-15');
  await book.logEvent(a2, 'interview', at: '${soon}T10:00', summary: 'Panel interview');
  await book.setFollowUp(a1, '2026-10-20');
  await book.importLeads([
    const LeadSuggestion({
      'name': 'Sam Recruiter',
      'title': 'Talent Partner',
      'company': 'Sample Care Group',
      'kind': 'recruiter',
      'linkedin': '',
      'email': '',
      'source': '',
      'why': 'Hires for digital nursing roles',
      'approach': 'Mention the e-observations pilot',
    }),
  ], today: today);
  const outlook = {
    'exposure': 'medium',
    'summary': 'Documentation is being automated; judgement and change leadership grow.',
    'tasksAtRisk': ['Manual charting'],
    'tasksGrowing': ['Clinical safety of AI tools'],
    'skillsToBuild': ['Clinical safety officer training'],
  };
  await book.saveReport(
    'career_map',
    {
      'current': {'role': 'Staff Nurse', 'level': 'Band 5', 'summary': 'Ward nurse with digital experience.'},
      'paths': [
        {
          'name': 'Into informatics',
          'direction': 'specialist',
          'realism': 'likely',
          'summary': 'Build on the EPR roll-out.',
          'aiOutlook': outlook,
          'steps': [
            {
              'role': 'Clinical Informatics Nurse',
              'timeframe': '0-1 years',
              'salaryRange': '£38k-£45k',
              'likelihood': 70,
              'requirements': ['EPR project work'],
              'certifications': [],
              'employers': ['Health trusts'],
            },
          ],
          'risks': ['Few posts locally'],
          'firstMoves': ['Join the digital nurse network'],
        },
        {
          'name': 'Ward management',
          'direction': 'management',
          'realism': 'possible',
          'summary': 'Lead a ward.',
          'aiOutlook': outlook,
          'steps': [],
          'risks': [],
          'firstMoves': [],
        },
      ],
      'recommended': 'Into informatics',
      'rationale': 'Strongest evidence on the CV.',
      'marketTrends': ['Digital nursing posts up in 2026'],
    },
    const [],
    at: '${today}T09:00',
  );
  await book.saveReport(
    'assessment',
    {
      'verdict': 'Competitive for band 6 informatics roles; strengthen project evidence.',
      'marketPosition': {'level': 'Mid-level', 'competitiveness': 'average', 'summary': 'Solid ward record.'},
      'strengths': [
        {'point': 'Led a digital pilot', 'evidence': 'e-observations roll-out'},
      ],
      'weaknesses': [
        {'point': 'No formal informatics training', 'fix': 'Take an introductory course'},
      ],
      'toughestChallenges': [
        {'challenge': 'Competing with IT staff', 'why': 'Panels want both', 'prepare': 'Quantify the pilot'},
      ],
      'aiImpact': outlook,
      'targetRoles': [
        {
          'title': 'Clinical Informatics Nurse',
          'why': 'Direct fit',
          'fit': 72,
          'salaryRange': '£38k-£45k',
          'searchTerms': ['clinical informatics nurse'],
        },
      ],
      'countries': [
        {
          'country': 'GB',
          'demand': 'high',
          'salaryRange': '£38k-£45k',
          'rightToWork': 'Yes',
          'verdict': 'Best market',
        },
      ],
      'learning': [
        {
          'title': 'Introduction to Health Informatics',
          'kind': 'course',
          'provider': 'Example Academy',
          'url': '',
          'cost': 'free',
          'duration': '6 weeks',
          'why': 'Fills the training gap',
          'priority': 'essential',
        },
      ],
      'quickWins': ['Update the LinkedIn headline'],
    },
    const [],
    at: '${today}T09:05',
  );
  await book.suggestLearning([
    const LearningSuggestion(title: 'Clinical Safety Officer training', kind: 'certification'),
  ], today: today);
  final round = await book.startPractice(
    role: 'Clinical Informatics Nurse',
    mode: 'competency',
    questions: const [
      PracticeQuestion({
        'question': 'Tell us about a change you led.',
        'category': 'Behavioural',
        'why': 'Leadership of change',
        'lookFor': ['Situation', 'Measured result'],
        'difficulty': 'standard',
      }),
    ],
    at: '${today}T08:00',
  );
  await book.saveAnswer(
    round,
    0,
    'I led the e-observations pilot on a 28-bed ward and trained 40 staff; late observations fell 30%.',
    const AnswerReview({
      'score': 7.4,
      'rating': 'strong',
      'dimensions': [
        {'name': 'Relevance', 'score': 8, 'comment': 'On point'},
      ],
      'strengths': ['Numbers'],
      'improvements': ['Say what you would do differently'],
      'redFlags': [],
      'betterAnswer': '',
      'followUp': 'What went wrong?',
    }),
    at: '${today}T08:10',
  );

  // The coach: a document read, a question, a story and a check-in.
  final doc = (await book.recordFound([
    (hash: 'c' * 64, name: 'cv.txt', content: 'CV'),
  ], today: today)).single;
  await book.saveReading(
    (await book.documents()).firstWhere((d) => d.id == doc),
    const DocumentReading(
      name: 'cv.txt',
      kind: 'cv',
      summary: 'The master CV.',
      facts: [DocumentFact(topic: 'Start date', statement: 'Started in 2020', quote: '2020 – present')],
      stories: [
        StoryDraft(
          title: 'E-observations pilot',
          situation: 'A 28-bed ward moved to electronic observations.',
          action: 'I trained 40 staff on the new system.',
          result: 'The ward went live on time.',
          competencies: ['systems', 'supporting'],
        ),
      ],
    ),
    today: today,
  );
  await book.addQuestions([
    const QuestionDraft(topic: 'Start date', question: 'When did you start?', choices: ['2020', '2021']),
  ], today: today);
  final c = await book.askToday(today, 'What went well today?', at: '${today}T18:30');
  await book.answerCheckIn(c, 'Helped a new starter with the e-obs system.', at: '${today}T18:40');

  // Pay and employer research for the job pages.
  await book.setPayBaseline(
    const PayBaseline(pay: 31049, label: 'NI 2025/26 Band 5 entry', rentNow: 600, rentNext: 900),
  );
  await book.saveEmployerBrief(
    'Northwind Health',
    const AiResult(
      {
        'employer': 'Northwind Health',
        'summary': 'A made-up community health provider.',
        'systems': [
          {'name': 'Example EPR', 'detail': 'Patient record, replaced in 2027'},
        ],
        'culture': [
          {
            'point': '62% would recommend it as a place to work (2025)',
            'source': 'https://example.org/survey',
          },
        ],
        'watch': ['A merger is planned'],
        'askAtInterview': ['How is the team preparing for the new EPR?'],
      },
      sources: [(title: 'Staff survey', url: 'https://example.org/survey')],
    ),
    at: '${today}T09:00',
  );
}

/// Conversations for the Conversations page: a LinkedIn thread with a
/// reply, an e-mail to a personal address awaiting a reply, and an unknown
/// sender in the Screener. Every person is made up.
Future<void> seedConversations(CareerBook book) async {
  Future<String> person(String name, String title, String email, String linkedin) async {
    final id = newId();
    await book.save(
      book.db.careerContacts,
      CareerContactsCompanion.insert(
        id: id,
        name: name,
        title: Value(title),
        company: const Value('Example Health Trust'),
        email: Value(email),
        linkedin: Value(linkedin),
        source: const Value('NHS Jobs advert'),
        sourceKind: const Value('advert'),
        foundOn: const Value('2026-11-10'),
      ),
      id,
    );
    return id;
  }

  final jordan = await person(
    'Jordan Example',
    'Practice Manager',
    '',
    'https://www.linkedin.com/in/jordan-example-0000',
  );
  final sam = await person('Sam Sample', 'Recruitment Lead', 'sam.sample@gmail.com', '');
  final li = await book.startConversation(contactId: jordan, channel: 'linkedin', at: '2026-11-11T09:00');
  await book.logSent(
    li,
    'Hello Jordan, I saw the practice manager advert.',
    at: '2026-11-11T09:05',
    invite: true,
  );
  await book.logReply(li, 'Thanks, happy to talk next week.', at: '2026-11-12T16:20');
  final mail = await book.startConversation(
    contactId: sam,
    channel: 'email',
    account: 'you@example.org',
    subject: 'Recruitment Lead role',
    at: '2026-11-13T10:00',
  );
  await book.logSent(mail, 'Dear Sam, a question about the role.', at: '2026-11-13T10:00');
  final unknown = await book.startConversation(
    channel: 'email',
    peer: 'someone@example.org',
    mode: 'api',
    at: '2026-11-14T08:00',
  );
  await book.addMessage(
    unknown,
    direction: 'in',
    body: 'Are you open to new roles?',
    at: '2026-11-14T08:00',
    source: 'api',
  );
}

/// [seedBook] and [seedConversations] together, with a LinkedIn
/// connection at an employer a job is saved at, someone to keep in touch
/// with, and a LinkedIn draft: the people pages with something in every
/// section. Every person is made up.
Future<void> seedPeople(CareerBook book) async {
  await seedBook(book);
  await seedConversations(book);
  final today = isoDate(DateTime.now());
  await book.importLeads(
    const [
      LeadSuggestion({
        'name': 'Kim Peer',
        'title': 'Records Officer',
        'company': 'Example Health Trust',
        'kind': 'peer',
        'linkedin': 'https://www.linkedin.com/in/kim-peer',
        'source': 'LinkedIn connection',
        'why': '',
        'approach': '',
      }),
    ],
    today: today,
    chase: false,
    sourceKind: 'archive',
  );
  final old = addDays(today, -30);
  await book.importLeads(
    const [
      LeadSuggestion({
        'name': 'Riley Mentor',
        'title': 'Chief Nursing Information Officer',
        'company': 'Northwind Health',
        'kind': 'mentor',
        'linkedin': '',
        'email': '',
        'source': 'Digital Health Networks meet-up',
        'why': 'Mentored me through the e-observations pilot',
        'approach': '',
      }),
    ],
    today: old,
    chase: false,
    sourceKind: 'met',
  );
  final riley = (await book.db.select(book.db.careerContacts).get()).firstWhere(
    (c) => c.name == 'Riley Mentor',
  );
  await book.setKeepInTouch(riley.id, 4, today: old);
  await book.saveReport(
    'linkedin.post',
    {
      'headline': 'What an e-observations pilot taught me about change on a ward',
      'score': 82,
      'sections': const [],
    },
    const [],
    at: '${today}T09:00',
  );
}

/// The worst a real book could look: very long job titles and employer
/// names, a one-letter employer, Welsh and non-Latin names, no pay, very
/// high pay in rupees, jobs closing today and tomorrow, fit scores at both
/// ends and none, and enough applications that every count runs into the
/// dozens. For checking that nothing spills, clips or reads badly.
Future<void> seedWorstCase(CareerBook book) async {
  final today = isoDate(DateTime.now());
  await book.saveProfile(
    sampleProfile.copyWith(
      name: 'Oluwaseun Siobhán Ní Mhaoláin-Kowalczyk-Fitzgerald',
      targets: sampleProfile.targets.copyWith(
        roles: [
          'Advanced Clinical Practitioner in Emergency and Urgent Care Medicine',
          'Chief Nursing Information Officer',
          'Digital Nurse Specialist',
        ],
      ),
    ),
  );
  Posting job(
    String id,
    String title,
    String company, {
    int? min,
    int? max,
    String currency = 'GBP',
    String? closing,
    String location = 'Exampletown',
    String description = 'Support EPR systems and patient safety training across wards.',
  }) => Posting(
    source: 'reed',
    sourceId: id,
    title: title,
    company: company,
    location: location,
    country: 'GB',
    salaryMin: min,
    salaryMax: max,
    currency: currency,
    description: description,
    posted: today,
    closing: closing,
  );
  final ids = await book.importPostings(
    [
      job(
        'w1',
        'Band 8a Advanced Clinical Practitioner – Emergency Department and Same Day Emergency Care '
            '(Fixed Term / Secondment Opportunity, 12 Months, Flexible Working Considered)',
        'Betsi Cadwaladr University Health Board – Ysbyty Ysgol Glan Clwyd, Bodelwyddan',
        min: 55690,
        max: 62682,
        closing: today,
        location: 'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch, Ynys Môn',
        description:
            'Lead advanced practice in the emergency department.\n\nFor informal enquiries please contact '
            'Dr Maximilian Featherstonehaugh-Wolstenholme, Associate Director of Nursing Informatics and Digital '
            'Transformation, on maximilian.featherstonehaugh-wolstenholme@betsicadwaladr-university.wales.nhs.uk '
            'or 01745 000000.',
      ),
      job('w2', 'Nurse', 'X', closing: addDays(today, 1)),
      job(
        'w3',
        'मुख्य नर्सिंग सूचना अधिकारी (Chief Nursing Information Officer)',
        'अखिल भारतीय आयुर्विज्ञान संस्थान',
        min: 2500000,
        max: 4800000,
        currency: 'INR',
        location: 'नई दिल्ली',
      ),
      job('w4', '看護情報スペシャリスト', '東京大学医学部附属病院', min: 1250000, max: 1250000),
      job(
        'w5',
        'Chief Executive',
        'Example Health Trust',
        min: 1250000,
        max: 2400000,
        closing: addDays(today, 6),
      ),
      for (var i = 0; i < 40; i++)
        job('n$i', 'Clinical Informatics Nurse ${i + 1}', 'Example Health Trust', min: 38000, max: 45000),
    ],
    sampleProfile,
    today: today,
  );
  await book.saveTriage({
    ids[0]: (fit: 100, why: 'Every requirement met.'),
    ids[1]: (fit: 0, why: 'Nothing in common.'),
    ids[3]: (fit: 7, why: 'Language barrier.'),
  });
  for (final id in ids.take(2)) {
    await book.setJobStatus(id, 'saved');
  }
  await book.setJobStatus(ids[4], 'saved');
  // Thirty-two applications, all due a chase today.
  for (final id in ids.skip(5).take(32)) {
    final a = await book.applyFor(await book.job(id), today: addDays(today, -20), sent: true);
    await book.setFollowUp(a, today);
  }

  // People: long names and titles, a one-letter name, one marked do not
  // contact, connections at the long-named board, and a crowd to chase.
  const board = 'Betsi Cadwaladr University Health Board – Ysbyty Ysgol Glan Clwyd, Bodelwyddan';
  LeadSuggestion person(
    String name, {
    String company = board,
    String kind = 'recruiter',
    String linkedin = '',
  }) => LeadSuggestion({
    'name': name,
    'title': 'Associate Director of Nursing Informatics, Clinical Safety and Digital Transformation',
    'company': company,
    'kind': kind,
    'linkedin': linkedin,
    'email': '',
    'source': 'NHS Jobs advert for an Advanced Clinical Practitioner in the Emergency Department',
    'why': 'Hires for digital nursing roles',
    'approach': '',
  });
  await book.importLeads(
    [
      for (var i = 0; i < 3; i++)
        person(
          'Gwenllian Angharad Llewelyn-Featherstonehaugh ${i + 1}',
          kind: 'peer',
          linkedin: 'https://www.linkedin.com/in/gwenllian-example-$i',
        ),
    ],
    today: today,
    chase: false,
    sourceKind: 'archive',
  );
  await book.importLeads(
    [
      person('Dr Maximiliana Alexandra Featherstonehaugh-Wolstenholme-Cholmondeley'),
      person('Q', company: 'X'),
      person('Siân Ní Mhaoláin', company: 'Example Health Trust'),
      for (var i = 0; i < 20; i++) person('Recruiter ${i + 1}', company: 'Example Health Trust'),
    ],
    today: today,
    sourceKind: 'advert',
  );
  final people = {for (final c in await book.db.select(book.db.careerContacts).get()) c.name: c};
  await book.setDoNotContact(people['Q']!.id, true, today: today);

  // Seven threads waiting on a reply, on three channels, each newest message
  // long and over several lines.
  final now = DateTime.now();
  String at(int minutesAgo) => now.subtract(Duration(minutes: minutesAgo)).toIso8601String().substring(0, 16);
  for (var i = 0; i < 7; i++) {
    final who = people['Recruiter ${i + 1}']!;
    final t = await book.startConversation(
      contactId: who.id,
      channel: ['email', 'linkedin', 'bluesky'][i % 3],
      account: 'oluwaseun.featherstonehaugh@example.com',
      at: at(600),
    );
    await book.logSent(
      t,
      'Hello, I saw the advanced practitioner role and wondered about the rota.',
      at: at(500),
    );
    await book.logReply(
      t,
      'Thanks for getting in touch!\nThe rota is a four-on four-off pattern with one long day and one night '
      'in each block, and we can talk through flexible working at interview. Could you send your CV by Friday?',
      at: at(400 - i),
    );
  }
  // Keep in touch every 2 weeks, last heard from a month ago: due now.
  final old = addDays(today, -30);
  await book.importLeads(
    [person('Professor Bartholomew Montgomery-Fitzwilliam', kind: 'mentor')],
    today: old,
    chase: false,
  );
  final mentor = (await book.db.select(book.db.careerContacts).get()).firstWhere(
    (c) => c.name.startsWith('Professor'),
  );
  await book.setKeepInTouch(mentor.id, 2, today: old);

  // Eleven LinkedIn invitations today: a busy pace.
  final li = await book.startConversation(
    contactId: people['Siân Ní Mhaoláin']!.id,
    channel: 'linkedin',
    at: at(300),
  );
  for (var i = 0; i < 11; i++) {
    await book.logSent(li, 'Hello, I would like to connect.', at: at(200 - i), invite: true);
  }

  // LinkedIn drafts with long headlines, one posted.
  for (var i = 0; i < 3; i++) {
    await book.saveReport(
      'linkedin.post',
      {
        'headline':
            'What three years of leading an electronic observations roll-out across twenty-eight wards taught me '
            'about clinical safety, change fatigue and the unglamorous work of training night staff (${i + 1})',
        'score': [0, 100, 55][i],
        'scoreAfter': 100,
        if (i == 1) 'posted': today,
        'sections': const [],
      },
      const [],
      at: at(100 + i),
    );
  }
}

/// Conversations at their worst: 200 threads, 50 unknown senders waiting in
/// the Screener, very long names, addresses and subjects, a 5,000-character
/// message, and emoji and right-to-left text in names and bodies. The
/// longest thread is the newest, so it heads the list. Every person and
/// address is made up.
Future<void> seedWorstConversations(CareerBook book) async {
  final now = DateTime.now();
  String at(int minutesAgo) => now.subtract(Duration(minutes: minutesAgo)).toIso8601String().substring(0, 16);
  const board = 'Betsi Cadwaladr University Health Board – Ysbyty Ysgol Glan Clwyd, Bodelwyddan';
  Future<String> person(String name, {String email = '', String company = board}) async {
    final id = newId();
    await book.save(
      book.db.careerContacts,
      CareerContactsCompanion.insert(
        id: id,
        name: name,
        title: const Value(
          'Associate Director of Nursing Informatics, Clinical Safety and Digital Transformation',
        ),
        company: Value(company),
        email: Value(email),
        source: const Value(
          'NHS Jobs advert for an Advanced Clinical Practitioner in the Emergency Department',
        ),
        sourceKind: const Value('advert'),
        foundOn: Value(isoDate(now)),
      ),
      id,
    );
    return id;
  }

  // 196 ordinary threads among twenty people, on every channel, older than
  // the rest.
  final people = [
    for (var i = 0; i < 20; i++)
      await person('Correspondent ${i + 1}', email: 'correspondent${i + 1}@nhs.net'),
  ];
  const channels = ['email', 'linkedin', 'bluesky', 'phone'];
  for (var i = 0; i < 196; i++) {
    final t = await book.startConversation(
      contactId: people[i % people.length],
      channel: channels[i % channels.length],
      account: i % 4 == 0 ? 'you@example.org' : '',
      subject: i % 4 == 0 ? 'About the role, part ${i + 1}' : '',
      at: at(9000 - i * 10),
    );
    await book.logSent(t, 'A question about the role (${i + 1}).', at: at(9000 - i * 10));
    if (i % 3 == 0) await book.logReply(t, 'Thanks, I will come back to you.', at: at(8995 - i * 10));
  }

  // Right to left and emoji, in names and in bodies.
  final arabic = await person('مريم عبد الرحمن الهاشمي', company: 'مستشفى الملك فيصل التخصصي');
  final rtl = await book.startConversation(contactId: arabic, channel: 'linkedin', at: at(300));
  await book.logSent(rtl, 'Hello Maryam, I saw the informatics role.', at: at(300));
  await book.logReply(rtl, 'شكراً لتواصلك. يسعدنا التحدث معك يوم الخميس عن الدور.', at: at(290));
  final star = await person('🌟 Priya 🌟 Recruiter 🚀', company: 'Example Health Trust');
  final emoji = await book.startConversation(contactId: star, channel: 'bluesky', at: at(200));
  await book.logReply(emoji, '🎉🎉 Great news!! 👍🏽 Can you do Thursday? 🙌 ☕️', at: at(200));
  final short = await person('Q', company: 'X');
  await book.startConversation(contactId: short, channel: 'phone', at: at(150));

  // The longest of everything, newest of all.
  final max = await person(
    'Dr Maximiliana Alexandra Featherstonehaugh-Wolstenholme-Cholmondeley',
    email: 'maximiliana.alexandra.featherstonehaugh-wolstenholme-cholmondeley@betsicadwaladr-university.wales.nhs.uk',
  );
  final long = await book.startConversation(
    contactId: max,
    channel: 'email',
    account: 'oluwaseun.siobhan.featherstonehaugh-kowalczyk@example-long-domain.co.uk',
    subject:
        'Re: Re: Fwd: Band 8a Advanced Clinical Practitioner – Emergency Department and Same Day Emergency Care '
        '(Fixed Term / Secondment Opportunity, 12 Months, Flexible Working Considered) – informal enquiry',
    at: at(120),
  );
  const sentence =
      'I have led the electronic observations roll-out across twenty-eight wards, including night staff '
      'training and the clinical safety case. ';
  final essay = (sentence * 40).substring(0, 5000);
  await book.logSent(long, essay, at: at(110));
  await book.addNote(long, 'Called the ward: she is on leave until Monday. 📞', at: at(100));
  await book.logReply(
    long,
    'Thank you for such a thorough note! 🙏 Could you send the safety case too?\n\n'
    'ممتاز، شكراً جزيلاً.\n\nKind regards,\nMaximiliana',
    at: at(90),
  );

  // Fifty unknown senders waiting in the Screener, with long addresses.
  for (var i = 0; i < 50; i++) {
    final t = await book.startConversation(
      channel: 'email',
      peer: 'unknown.sender.${i + 1}.with.a.very.long.address@recruitment-agency-example.co.uk',
      mode: 'api',
      at: at(60 + i),
    );
    await book.addMessage(
      t,
      direction: 'in',
      body: 'Are you open to new roles? 🚀 We have ${i + 1} exciting opportunities across the North West.',
      at: at(60 + i),
      source: 'api',
    );
  }
}

/// [seedPeople] with the social side filled in: a connected Gmail account,
/// a longer LinkedIn thread with a note, and a week of planned posts on
/// LinkedIn and Bluesky, one already posted. Every person and address is
/// made up.
Future<void> seedSocial(CareerBook book) async {
  await seedPeople(book);
  final now = DateTime.now();
  await book.db.setLocalSetting(
    mailAccountsKey,
    jsonEncode([
      ChannelAccount.preset(
        'gmail',
        'alex.example@gmail.com',
        name: 'Alex Example',
      ).copyWith(lastSync: now.toUtc().toIso8601String()).toJson(),
    ]),
  );
  final jordan = (await book.db.select(book.db.conversations).get()).firstWhere(
    (c) => c.channel == 'linkedin',
  );
  await book.addNote(jordan.id, 'Prefers mornings. Ask about the EPR go-live date.', at: '2026-11-12T16:30');
  await book.logSent(
    jordan.id,
    'Great, thank you! Would Tuesday at ten suit you? I can bring the e-observations roll-out plan.',
    at: '2026-11-12T17:05',
  );

  await book.addPostSlot((day: 2, time: '08:30', channel: 'linkedin'));
  await book.addPostSlot((day: 4, time: '08:30', channel: 'linkedin'));
  await book.addPostSlot((day: 5, time: '12:00', channel: 'bluesky'));
  final monday = weekStart(now);
  String at(int day, String time) =>
      '${isoDate(DateTime(monday.year, monday.month, monday.day + day))}T$time';
  final posted = await book.addPost(
    at: at(1, '08:30'),
    body: 'Three things our records team learned in the first month of the new EPR.',
  );
  await book.markPosted(posted, url: 'https://www.linkedin.com/posts/example-1', at: now);
  await book.addPost(
    at: at(3, '08:30'),
    topic: 'Night staff training',
    body:
        'What I learned training night staff on e-observations: start with the why, keep sessions short, '
        'and let the ward champions lead.',
  );
  await book.addPost(channel: 'bluesky', at: at(4, '12:00'), topic: 'Digital nursing meet-up in Leeds');
}
