# Changelog

## Unreleased

- Role families (groundwork for role search): one role becomes the titles the same work is advertised under, each with its reason and how close it is: titles in the same SOC 2020 unit group, head-noun synonyms ("Digital Training Facilitator" also as "Digital Trainer"), and, when online, ESCO's other titles and narrower occupations, cached on the device and used only when they agree with the SOC match. An optional AI suggestion is always labelled. ESCO skill lists per role are kept for later "search tasks and tools" chips.
- Udyoga now ships the full ONS SOC 2020 coding index (version 14, about 29,000 titles, 188 KB compressed) instead of a health-admin and IT subset, so any job title can be coded. A facilitator now matches trainers, an officer matches administrators and coordinators, and "training" no longer matches rail jobs.
- Career file on every device: the device with your career folder shares `settings/udyoga.json`, your Vidya plans (`settings/vidya-*.json`) and recipes (`recipes/*.json`, each up to 512 KB) with your other devices through end-to-end-encrypted sync when you tap Read now (and on each routine refresh). A device without the folder applies the settings, uses the recipes when no Recipes folder is chosen, and passes the plans to Vidya. Documents, CVs and notes never travel. Settings, Career file, says whether it came from this folder or from sync, when and from which device, and can remove it from sync.
- Answer aloud (Interview page, and on every practice round): the interviewer reads each question aloud in a British English voice and you answer by voice, or type any answer instead. Before each answer you see what the question tests. After it: your transcript, and how you said it (pace, pauses, approximate fillers, time before you started, length) against usual ranges, never as a score. Re-take any answer and play take 1 against the latest. With an AI, one strength and one fix on what you said; only the transcript is sent. A set of common questions works with no AI at all. Before the round: a microphone check, and each speech model offered for download with its size. Everything runs on the device; recordings stay on it, are deleted when you leave the round (or with Delete all recordings) and never sync; only the transcript is saved with the round.
- The interviewer follows up: after each answer it checks, on the device, which parts a panel listens for are missing (the situation, what you yourself did, a measure, the result, what you learned, who else was involved) and asks about the first one, at most twice per question: "What did you yourself do?", "How did you measure this?", "What did you learn?", "Who else was involved?", "What would you do differently?". With an AI, it writes a plan for each question first (what it tests, what to listen for, its own follow-ups), sent the questions only; without one, built-in plans work the same way.
- Panels and levels: a friendly, neutral, probing or quiet panel (the quiet one says nothing between answers and leaves longer silences, which is normal in real panels), and five levels from Rehearsal (untimed, no follow-ups) to Tough (two follow-ups, three-quarters of the usual time). At levels 4 and 5 the interviewer may stop an answer that runs over time, politely, and ask you to sum it up in one sentence.
- End-of-answer silence is a round setting, 3 to 10 seconds (5 by default), so a pause to think does not end your answer.
- Rehearse a whole process (Interview page): NHS-style (screening call, panel with a values question, optional presentation), Civil Service-style (optional reasoning test practice, a blended behaviours and strengths interview, presentation) and private sector (recruiter screen, a technical or case stage with a timed exercise, final interview). Each stage has its own clock, a settler question and the "I may interrupt you to keep to time" opening, and starts with what the stage before it left to fix; its follow-ups go after what you missed earlier. Exercises: a made-up in-tray to put in order, a spreadsheet task set out in text, and reasoning questions labelled "Practice format, not the real test". Presentations get a preparation clock and a notes box (kept in memory only). Every template is editable: stage names, panels, times, the brief and the questions.
- Role profiles (Interview page): paste an advert and person specification and your AI lists its essential and desirable criteria (only the advert is sent), or type them in; every criterion can be edited. Pick how the panel scores: NHS values (N/O, then 1 to 4), NI HSC values-based, Civil Service Success Profiles (1 to 7), HSE Ireland competencies or private-sector competencies, each with its scale and anchor text, marked as how panels commonly score. The criteria become the round's questions and follow-ups; criteria assessed only by the application or a test are not asked aloud.
- The debrief (after a spoken round, on every practice round and each process stage): coverage first, every essential criterion evidenced, thin or missing, and a missing one flagged as likely to make you unappointable. With an AI, each criterion is scored on the framework's scale with the line of your transcript it rests on; a score whose quote is not in the transcript is dropped and the criterion reads as not observed, never guessed. Only transcripts and criteria are sent. Then one strength and one fix per answer, no percentages, and lines to recover with ("Can I come back to that with a better example?"). Without an AI, coverage comes from the device's matcher.
- Save a good practice answer to the story bank, marked "From practice" with the criteria it evidenced, as a draft to check.
- A process is saved as you go, with what each stage covered and carries forward (text only, synced like rounds), so you can stop and carry on later from the Interview page. A process can use a role profile for its panel stage.
- A follow-up answered aloud shows how you said it, as the main answer does.
- Speech is written down by Moonshine through sherpa-onnx, straight from memory: about 0.4 s for 10 s of speech on a laptop, keeping "um" and "like". Whisper and its FFmpeg libraries are gone, which makes the Linux build 14 MB smaller and drops about 15 MB per Android ABI. The interview lab offers to delete the old Whisper models.
- The interviewer voice now says inflected words its word list lacks ("tasks", "asked", "prioritised") instead of skipping them.
- Android releases are split per ABI, so each APK is smaller: `-android.apk` for 64-bit phones, `-android-armeabi-v7a.apk` for older 32-bit ones. The updater fetches the right one.
- Camera setup check (optional, before a spoken round or stage, and from the Interview page): off every time until you turn it on, with a red "Camera on" pill that turns it off in one tap. It checks your face is in the picture and near the middle, head and shoulders fit, the light is in front of you (it spots backlight), the camera is near eye height and the picture is steady, each with a green tick or one plain tip. Show or hide your own picture. During the round, if you ask, a quiet note when you leave the picture for more than 3 seconds, and an optional "looking at the lens" hint taken only from where your face sits in the picture. Frames are looked at on the device and dropped: never saved, sent or synced. It reads no identity, expression or eyes, and scores nothing; setup notes at the end of the round are information only and the debrief is the same with the camera off.
- Interview lab: deleting the interviewer voice also deletes its ready-made clips, and Clear voice cache empties them on its own.

- Read this page: in Udyoga's browser (desktop and Android), one button reads the open page's text and schema.org markup into a job, a person and an employer, each shown for you to check, edit and tick before anything is kept. Pages with little text (canvas or PDF-like) can be read from a screenshot: Tesseract on Linux and Windows when you have installed it, Google ML Kit on Android only after you agree (it sends Google usage information), or your AI when its model reads images (Claude API, Gemini, Claude subscription).
- Site recipes: JSON files in a folder you choose (Settings, Recipes) teach Udyoga one site each. Fetch recipes read jobs in the background through the politeness layer (robots.txt, a gap between requests, a daily cap, pages read once a week) and are refused for LinkedIn, Indeed and Glassdoor. Browser-read recipes read pages you open. Assist-fill recipes type a draft you approve into one text box after a dry run, never press Send or Submit, and stop at the daily cap (15 a day on LinkedIn whatever the recipe says). Udyoga ships no recipes; docs/recipes.md is the schema, with a made-up example.
- Fill a text box can start from a draft Udyoga already wrote: the LinkedIn studio's connection notes and messages, and the drafts and intro messages written for a conversation or a contact. You still approve the text and see the dry run first.
- Assist-fill daily caps now count across all your devices, so LinkedIn's 15 a day holds on the account, not on each device. The 15 is shared by every LinkedIn recipe together, and fill counts older than a week are pruned.
- Background refresh on Android is now off until you turn it on; Udyoga offers it once after your profile is set up.
- Background refresh on Linux: the README and the Settings card now say plainly that the timer runs only while you are logged in to a desktop session. It does not run over SSH or on a machine without a screen.
- Interview lab (Settings, Developer, off by default): a test bench for the coming interview simulator. It downloads the speech and face models only when you ask (size, source and licence shown first; each checked against its SHA-256; delete any time), records 10 seconds from the microphone, finds the speech, writes it down with Moonshine, reads a sentence aloud with a British English voice, and draws a box round your face from the camera. Everything runs on the device; recordings stay in memory and camera frames are never stored. Measurements are in docs/interview-spike.md.

- Fit scores rebuilt: whole-word matching, skills counted as a share, pay compared only in the same currency, and location, seniority and eligibility now count. Scores update when your profile changes; the job page shows why.
- Who can apply: Udyoga reads adverts for no sponsorship, nationals only, right to work or residence, security clearance, required languages and essential local experience, quotes the line, and weighs it against your rights to work. Exclusions you set hide jobs entirely.
- Right to work and languages on the Profile page, with a countdown for any visa that ends and Today reminders 18, 12, 6 and 3 months before.
- UK licensed sponsors: a badge on jobs and employers on the GOV.UK register of licensed sponsors, refreshed at most once a day.
- To-do list: add, edit and tick off to-dos with due dates on the Growth page; due ones show on Today.
- A settings/udyoga.json file in your document folders sets targets, rights to work, passports, languages and to-dos.
- Refresh: a failed check no longer counts as checked; only changed jobs are rewritten, and your status and dismissals are never overwritten; the AI search runs on one device at a time.
- Adzuna jobs show "Jobs by Adzuna"; Settings explains that the free tier is for evaluation under Adzuna's terms.
- Saved reports are pruned past a cap; a bad reply from a job site is told apart from "not reachable".

- Explore (new tab under Jobs): every country screened against your passports, rights to work, languages, job codes and pay, as Ready, Possible, Later or Blocked, each with its reasons and blockers. Country pages show each route's pay thresholds and requirements with the source and the day it was read (unverified ones say so): UK Skilled Worker and Health and Care with the SOC 2020 going rates and the Temporary Shortage List cut-off, Ireland's employment permits, the EU Blue Card in Germany and the Netherlands, Singapore's Employment Pass, Canada's latest Express Entry rounds, and basics for Australia, New Zealand and the Gulf states. The UK table and the Canadian rounds refresh from GOV.UK and IRCC.
- Your job titles are coded as UK SOC 2020 (from the ONS coding index) and ISCO-08 (from ESCO), with the UK pay floor for each code.
- AI avenue assessment per country (live adverts, pay against living costs, the route, blockers, pushback and a confidence) and a prep plan timed to your right-to-work end date, with a qualification planner. Plan steps become to-dos or go to Vidya as their own study plan.
- Route tracks: work several routes side by side, each with a trigger and dated milestones; milestones can become to-dos and show on Today when due.
- More job sources, with no key: Sweden's Platsbanken (JobTech), Norway's arbeidsplassen.no (NAV) and UN jobs from unvacancies.org. With your own key (kept on this device only): USAJOBS and Jooble (one key per country). Each source is credited where its terms ask.
- Employers you watch (Jobs page): list the employers you want to work for. NHS employers are matched on NHS Jobs by name and other names; others are read from their job board's public API (Greenhouse, Lever, Ashby, SmartRecruiters, Workday), or from the job markup on their careers page at most once a day, only where robots.txt allows. Their new openings show on Today. *Find employers near you* suggests NHS trusts, hospitals near your home areas (Wikidata), and Epic and Oracle Health customers, fetched from their public lists when you ask. The career file's watchEmployers list adds them too.
- Local radar: several home areas, each with its own radius and the towns you could commute to; job sites that take a place search each area. The career file's places can carry a radius and commute towns.
- Explore: *Add to targets* on a country page adds it to the countries the job sites search.

- Background refresh (Settings): the job sites, the employers you watch, the route tables and the sponsor register are checked while Udyoga is closed, every 15 minutes to once a day (6 hours by default). A notification tells you about new jobs and, once a day, to-dos that are due. On Android it is on by default and waits for a network and a battery that is not low. On Linux it is a systemd user timer and on Windows a Task Scheduler entry; both are added only when you turn the option on, and removed when you turn it off. The AI routine runs there only on the device that already runs it. Settings shows the last run, what it found and the next run. A background run and the open app never refresh at the same time.
- Find people: the communities list is UK-wide, with regional health innovation events for London, Greater Manchester, the West Midlands, Yorkshire and the Humber, the North East, Scotland and Wales.

- Send to Vidya (Coach page): when Udyoga and Vidya sync with the same account, the study plan goes straight into Vidya, and what you finish there shows on the Coach card with *Add to my profile*. Saving or copying the plan still works without sync.
- Sync: *Change server address* follows your sync server to another computer without signing in again; edits that clashed with another device's are kept for you to bring back; the Sync card shows changes waiting to send.

## 0.6.0 (2026-11-15)

- A new look across the app: calmer cards with thin borders, numbers that roll to their value, a glow on the next deadline, quicker page changes, and less motion when your system asks for it. Ctrl+K (or the search button) jumps to any page or action.
- Navigation in five places: Today, Jobs (with Applications), Network (Conversations, Contacts, Find people, LinkedIn), Prepare (Interview, Coach, Growth) and You (Profile, Career, Settings).
- Conversations (new): every exchange with a person as a chat thread, on e-mail, LinkedIn, Bluesky, phone or in person. The top of each thread says who, their role, the channel and where you found them. For LinkedIn, Udyoga copies your message and opens LinkedIn; you send it and log it. Filters for replies waiting and follow-ups due, a Screener for people you have not saved, and a gentle warning when you send a lot on LinkedIn in a day.
- E-mail: connect Gmail, iCloud, Yahoo, Fastmail or any IMAP server with an app password. Only mail to or from people you saved is kept. Send and reply from a thread; an alert on Android when a saved contact replies.
- Contacts: where you found each person and why you may contact them, a suggested first line saying so, *Forget this person*, *Do not contact*, keep-in-touch reminders and merging of duplicates.
- LinkedIn ZIP import now brings in your messages and invitations as threads, and shows who you already know at the employers you are applying to.
- Find people (new): search links by role, employer and place, named contacts from job adverts, Bluesky search by topic, and a list of NHS and digital-health communities and events.
- Post plan: weekly times to post, with a reminder; you post on LinkedIn yourself, or on Bluesky when you press Post.
- Today: replies waiting and people to keep in touch with.

## 0.5.0 (2026-11-15)

- Find and apply inside the app: the official NHS Jobs feed, an in-app browser for the job site (you sign in and submit yourself), an answer pack for the form, and a copy of each advert and application kept with it. Offer-to-start stages with a checklist; warnings for stale or suspicious listings.
- Coach (new page): add the folders that hold your CVs, references and notes on this device. Udyoga reads each document once, fills an empty profile from your CVs and asks you to confirm wherever your documents disagree or leave a gap.
- Daily check-in at a time you choose: one question about your day (a reminder on Android, a Today card everywhere). Your answers become draft interview stories, wins and skills; a story bank shows how ready you are for each competency.
- Job page: the pay change against your current pay, gross and after tax, NI and pension, with the rent difference when you move (Agenda for Change points for England 2026/27 and NI 2025/26 built in). Employer research: the systems staff use, staff survey and inspection evidence with sources, risks and questions to ask the panel.
- Vidya: save a study plan for Vidya from what you still need, with your stories as review cards; paste Vidya's portfolio back to mark finished learning done.
- Jobs added by link keep their closing date and salary.
- Linux needs WebKitGTK 4.1 (webkit2gtk-4.1) and libsoup 3 for the in-app browser.

## 0.4.7 (2026-11-10)

- Windows: the installer always uses its own folder. Other Brahma apps used to share its installer id, so an older install could sit in another app's folder; install this version to put it back in its own. Your data is not touched.

## 0.4.6 (2026-11-06)

- The side panel on wide windows scrolls when the window is too short to show every screen, with
  the touchpad, mouse wheel or a drag. Before, the last screens were cut off.
- Application cards: a long follow-up label no longer spills past the edge of a narrow card.

## 0.4.5 (2026-10-28)

- Application board: active applications as a column per stage. Drag a card to move it (hold it
  first on a phone) or use its menu, which can also close it. Wide windows open on the board; the
  list is a tap away.

## 0.4.4 (2026-10-28)

- Everything in 0.4.3, whose Windows build failed: the Windows app builds again with the newest
  Visual Studio compiler.

## 0.4.3 (2026-10-27)

- Several CVs: import up to eight tailored versions at once and the AI merges them into one master
  profile (each job once, every skill, the most recent details), adds the roles they aim at to your
  targets and lists the versions on the Profile page. Certifications you hold go to Growth as done.
- Ideas and wins on the Growth page: jot down an idea, a tip or a win in seconds. The AI reads them
  with your profile in every request; an idea can become a goal.
- LinkedIn data import on the Growth page: import the ZIP LinkedIn sends you. It fills gaps in the
  profile, turns recommendations into wins, adds recent applications, saved jobs and useful
  connections, and never doubles anything. Read on the device; nothing is fetched from LinkedIn.

## 0.4.2 (2026-10-27)

- ChatGPT subscription (Linux and Windows): use the Codex you have installed, signed in to your own
  ChatGPT plan, for every AI feature instead of an API key. Like the Claude subscription, access
  lasts 24 hours and Udyoga asks to renew it at the next start; it never sees your login. Codex
  cannot read PDFs, so paste a CV's text when using it.

## 0.4.1 (2026-10-25)

- LinkedIn: the week plan and repurpose tools now pick from the hook formulas too (only the post
  writer had them).

## 0.4.0 (2026-10-25)

- LinkedIn studio: profile score and rewrite, post writer, comment writer, connection notes and
  follow-ups (also from a contact), inbox triage, replies to comments, week plan, post audit,
  carousel (with a PDF to upload) and repurposing. Everything is a draft for you to post by hand,
  in your own voice (set it on the page). A human check cleans each draft of dashes, invisible
  characters and stock phrases and scores it on five checks; it also runs on a CV and cover letter.
- Claude subscription (Linux and Windows): use the Claude Code you have installed, signed in to
  your own plan, instead of an API key. Udyoga's access lasts 24 hours and it asks you to renew it
  at the next start; it never sees your Claude login.
- Updates: Udyoga checks for a new version at start and asks before installing. Settings > Updates
  has a switch to turn the start-up check off and a Check now button.

## 0.3.1 (2026-10-25)

- Phones get new navigation: a floating dock that scrolls through every screen (the "More"
  sheet is gone) and a side panel listing them all with what each is for. Swipe right on any
  page, or tap the dock's menu button, to open it; Back closes it.

## 0.3.0 (2026-10-24)

- In-app updates: Settings > Updates finds a newer release on GitHub, downloads it, checks it against
  the release's SHA256SUMS.txt and installs it (Android's installer, the Windows setup, or the Linux
  `install.sh`). Today also points to a waiting update. Release builds only.
- Gemini as a second AI service: add a free key from Google AI Studio in Settings (the key is
  checked before it is saved) and every AI feature works with Gemini 3.8 Flash or 3.5 Flash-Lite,
  web research through Google Search and URL context included. With keys for both, choose the
  model in Settings.

## 0.2.0 (2026-10-24)

- n8n lead workflow: connect your own n8n (Settings) and a job's Contacts card can ask it for
  recruiters, hiring managers and agencies. A ready-made workflow and a study of what LinkedIn
  allows are in `docs/n8n`. It uses search-engine results and Claude; you send every connection
  request yourself.

## 0.1.0 (2026-10-24)

First test release.

- Profile from an imported CV (PDF, Word, text), with targets: roles, countries, places, work modes.
- Jobs from Adzuna, Reed, Remotive, Jobicy and Arbeitnow, refreshed every few hours, merged across
  sites, with a quick fit score; optional AI web search.
- Fit assessment, tailored CV and cover letter (Word and text export), applicant-tracking keywords.
- Applications by stage with follow-ups, No reply after six weeks, AI-drafted chasers, thank-you
  notes and feedback requests; reminders to Google Calendar or an `.ics` file.
- Contacts found from public pages or added by hand, with LinkedIn search links and drafted messages.
- Interview practice in five modes with on-device answer measures and a seven-dimension AI review.
- Career assessment, career map of five to eight paths, and growth goals for certifications and
  courses.
- Look: azure canvas, tilting cards, floating pill navigation, depth page transitions, hero logos;
  Inter and Plus Jakarta Sans bundled (SIL OFL).
- Sync and security from Brahma: encrypted database, end-to-end encrypted sync, one account across
  the suite.
