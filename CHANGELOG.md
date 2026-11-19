# Changelog

## Unreleased

- Fit scores rebuilt: whole-word matching, skills counted as a share, pay compared only in the same currency, and location, seniority and eligibility now count. Scores update when your profile changes; the job page shows why.
- Who can apply: Udyoga reads adverts for no sponsorship, nationals only, right to work or residence, security clearance, required languages and essential local experience, quotes the line, and weighs it against your rights to work. Exclusions you set hide jobs entirely.
- Right to work and languages on the Profile page, with a countdown for any visa that ends and Today reminders 18, 12, 6 and 3 months before.
- UK licensed sponsors: a badge on jobs and employers on the GOV.UK register of licensed sponsors, refreshed at most once a day.
- To-do list: add, edit and tick off to-dos with due dates on the Growth page; due ones show on Today.
- A settings/udyoga.json file in your document folders sets targets, rights to work, passports, languages and to-dos.
- Refresh: a failed check no longer counts as checked; only changed jobs are rewritten, and your status and dismissals are never overwritten; the AI search runs on one device at a time.
- Adzuna jobs show "Jobs by Adzuna"; Settings explains that the free tier is for evaluation under Adzuna's terms.
- Saved reports are pruned past a cap; a bad reply from a job site is told apart from "not reachable".

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
