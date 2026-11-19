/// Udyoga's hints, by id, on top of the shared ones (coreHints). Tooltips
/// use the short ones; page banners (ids starting `page.`) explain a whole
/// screen once.
const udyogaHints = <String, String>{
  // Navigation
  'nav.today': 'Follow-ups due, interviews, new matches and your next steps.',
  'nav.jobs': 'Openings matched to your profile, and every application by stage.',
  'nav.network':
      'Conversations with people on every channel, your contacts, people to meet, and LinkedIn posts and notes to '
      'send by hand.',
  'nav.prepare': 'Interview practice, your coach and what to learn next.',
  'nav.you': 'Your profile and CV, your career map, and Settings.',
  'nav.applications': 'Every application by stage, with follow-up dates.',
  'nav.explore':
      'Every country screened for you: where you can work now, later or not, and your route tracks.',
  'nav.interview': 'Practice interviews: answer questions and get scored.',
  'nav.career': 'Your career map: every path from your current role.',
  'nav.contacts': 'Recruiters, hiring managers and referrers to follow up.',
  'nav.growth': 'Certifications, courses and skills to build.',
  'nav.profile': 'Your CV, experience and what you are looking for.',
  'nav.linkedin': 'Posts, comments, connection notes and a profile score, for you to post by hand.',
  'nav.settings': 'AI keys or your Claude or ChatGPT subscription, updates, job sites, the AI routine, sync and security.',
  // Jobs
  'jobs.refresh': 'Check the job sites now.',
  'jobs.ai': 'Ask the AI to search LinkedIn, Indeed, national and public-sector boards for you.',
  'jobs.add': 'Paste a job link or the advert text.',
  'jobs.employers': 'Their new openings, from NHS Jobs, their job board or careers page, show on Today.',
  'today.watched': 'New openings at the employers you watch.',
  'jobs.portals': 'Open searches for your roles on the main job sites, in your browser.',
  'jobs.fit': 'How well the job fits you, 0 to 100. A star means the AI assessed it.',
  'job.n8n': 'Sends this job (not your name or contact details) to your n8n workflow and adds the contacts it finds.',
  'job.assess': 'The AI reads the advert, researches the employer and scores your fit honestly.',
  'job.tailor': 'A CV and cover letter for this job, from your real experience only.',
  'job.leads': 'Find the recruiter, hiring manager and agencies for this job.',
  'job.eligibility':
      'Lines in the advert that limit who can apply (visa, nationality, residence, vetting, language, local '
      'experience), checked against the rights and languages on your profile.',
  'profile.rights': 'Passports, rights to work and languages. Udyoga checks every advert against them.',
  'todos': 'Your own to-do list. Due and overdue ones show on Today.',
  // Explore
  'explore.tier':
      'Ready: you may work there now. Possible: a sourced route fits. Later: a gap to close or unverified rules. '
      'Blocked: nothing open on the current rules.',
  'explore.route':
      'The route\'s rules with their sources and the day they were read. Unverified ones say so.',
  'explore.codes':
      'Your job titles coded as SOC 2020 (UK) and ISCO-08. A route\'s rules and pay floor follow the code.',
  'explore.rounds': 'The latest rounds of invitations, read from IRCC\'s own data.',
  'explore.jobs': 'Openings in this country from your job sites.',
  'explore.assess':
      'The AI checks the screen against official sources: live adverts, pay against living costs, the route, '
      'blockers and pushback, with how sure it is.',
  'explore.plan': 'Ordered steps timed to your deadline, with a qualification planner. Steps can become to-dos or go to Vidya.',
  'explore.track': 'A route you are working on, with the trigger that starts it and dated milestones.',
  // Applications
  'apps.followup': 'When to chase this up. Add it to your calendar so it reminds you.',
  'apps.calendar': 'Download every follow-up as a calendar file with 9 am alerts.',
  'apps.chase': 'The AI drafts a short, polite message asking for an update or feedback.',
  // Interview
  'interview.mode': 'The kind of interview to practise.',
  'interview.metrics': 'Measured on this device: length, speaking time, fillers, "I" against "we" and STAR.',
  // Career
  'career.map': 'Every realistic path from your current role, with timeframes, pay and AI exposure.',
  'career.target': 'Adds this path\'s steps as goals and its certifications to Growth.',
  'career.assess': 'A candid assessment of where you stand in today\'s market.',
  // Settings
  'growth.notes': 'Ideas, tips and wins for your career. The AI reads them in everything it does for you.',
  'growth.linkedin': 'Your own LinkedIn data, read on this device. Udyoga never signs in to LinkedIn.',
  'settings.n8n': 'A webhook in your own n8n that takes a job and answers with contacts. See docs/n8n in the Udyoga repository.',
  'settings.ai':
      'Your own Gemini or Claude key, or on a computer your Claude subscription through Claude Code or your '
      'ChatGPT subscription through Codex. Requests go straight from this device to Google, Anthropic or OpenAI.',
  'linkedin.voice':
      'A few words on how you write and a few lines you wrote. Every draft is written to match.',
  'settings.routine':
      'Let the AI search for jobs and refresh your career map on its own. Each run costs a little.',
  'settings.feeds': 'Free keys for Adzuna (many countries) and Reed (UK) add their jobs to each refresh.',
  // Page banners
  'page.today':
      'Your day: follow-ups due, interviews coming up, the best new matches and what to do next. '
      'Hover or long-press anything for a tip.',
  'page.jobs':
      'Openings for your target roles in your countries, refreshed every few hours from job sites, and by '
      'the AI search when you turn it on. Open one to assess your fit, tailor your CV and apply.',
  'page.explore':
      'Every country, screened against your passports, rights to work, languages, job codes and pay. Rules carry '
      'their source and date; open a country for its routes, live jobs, an AI assessment and a prep plan.',
  'page.applications':
      'Each application by stage. Udyoga sets a follow-up date when it moves on, and marks it No reply '
      'after six weeks of silence.',
  'page.spoken':
      'The interviewer reads each question aloud; answer by voice or type. Before each answer you see what the '
      'question tests. The interviewer follows up on what your answer leaves out. After it: your transcript, '
      'how you said it against usual ranges, and with an AI one strength and one fix.',
  'page.interview':
      'Questions a real panel would ask for the role, then a strict review of each answer on seven '
      'dimensions, with a better answer and the follow-up to expect.',
  'page.career':
      'Where you can go from here: up, sideways, specialist, management or a change of field, judged for '
      'realism and AI exposure. Pick a path to turn it into goals.',
  'page.contacts':
      'People to reach: recruiters, hiring managers, referrers. The AI finds public professional contacts; '
      'LinkedIn searches open in your browser.',
  'page.growth':
      'What to learn next and how far you have got. Suggestions come from your assessment and career map.',
  'page.linkedin':
      'Drafts for LinkedIn in your voice: your profile scored and rewritten, posts, comments, connection notes, '
      'replies and a week plan. Every draft is cleaned of machine marks. You post and send everything yourself.',
  'page.coach':
      'A question at the end of each day turns your real work into interview stories. Udyoga reads your '
      'documents, asks you to confirm anything that disagrees, and shows how ready you are for each competency.',
  'page.profile':
      'Import your CV and the AI fills this in. Everything Udyoga does starts from it, so keep it accurate.',
  'network.bluesky':
      'Search Bluesky by topic with your own account. Save someone to keep them, with where you found '
      'them; nothing else is stored.',
  'accounts.mail':
      'Udyoga keeps only mail to or from people you saved, and replies in their threads. '
      'Everything else in your mailbox is skipped and never stored.',
  'accounts.bluesky':
      'Search people and posts by topic, post when you press Post, and see your direct messages with '
      'saved contacts in Conversations.',
  'coach.readiness':
      'Two confirmed stories make a competency ready. Your check-ins and documents add drafts.',
  'coach.folders':
      'CVs, references, interview notes and applications in these folders are read into your profile. '
      'Files stay on this device; what is read from them syncs with your account.',
  'linkedin.postPlan':
      'Pick weekly times to post, write each post ahead, and get a reminder when it is time. You post on '
      'LinkedIn yourself; Udyoga never posts there.',
  'network.known': 'Your LinkedIn connections at employers you have applied to or saved jobs at.',
  'network.search':
      'Each search opens in your browser. Save the people you find here, with where you found them.',
  'network.adverts': 'People adverts name for informal enquiries. They expect questions about the job.',
  'network.communities':
      'Where people in health administration and digital health meet. Turning up is the warmest way in.',
};
