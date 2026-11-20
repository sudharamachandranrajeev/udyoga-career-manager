# Research behind Udyoga

Reusable findings behind the Explore, eligibility, interview and network
features. Read in November 2026 and dated here. Terms, prices and rules
change, so check the linked source before relying on any of it.

Labels:

- **V**: read on the official page or by calling the endpoint, Nov 2026.
- **U**: secondary source, or the page could not be read. Check first.

## Contents

1. [Job data sources and their terms](#1-job-data-sources-and-their-terms)
2. [Visa routes, sponsors and occupation codes](#2-visa-routes-sponsors-and-occupation-codes)
3. [Country context data](#3-country-context-data)
4. [Interview methodology](#4-interview-methodology)
5. [What users of other apps hate and want](#5-what-users-of-other-apps-hate-and-want)

---

## 1. Job data sources and their terms

### Sources Udyoga uses

| Source | Access | Key | Limits | Terms that matter |
|---|---|---|---|---|
| NHS Jobs | Public XML feed | None | - | England and Wales NHS posts |
| Adzuna | REST API | Free app ID and key, one per user | Free tier is "intended for evaluating the API" | Personal job search is a permitted use. Each displayed ad needs an "Adzuna" link label of at least 116x23 px (V, [terms](https://developer.adzuna.com/docs/terms_of_service)). Udyoga shows "Jobs by Adzuna" |
| Reed | REST API | Free key, one per user | - | UK jobs ([reed.co.uk/developers/jobseeker](https://www.reed.co.uk/developers/jobseeker)) |
| USAJOBS | `data.usajobs.gov/api/search` | Free key per user; the `User-Agent` header must be the e-mail it was registered with | 500 rows a page, 10,000 a query | Open licence for "lawful commercial or noncommercial purposes". Do not imply OPM endorsement. Keep the key confidential (V, [terms](https://developer.usajobs.gov/guides/terms-of-service), [limits](https://developer.usajobs.gov/guides/rate-limiting)) |
| Jooble | `POST jooble.org/api/{key}` | Free key per country site | 100 searches a day per key | Terms page sits behind a bot check; not read (U) |
| JobTech JobSearch (Sweden) | `jobsearch.api.jobtechdev.se/search` | None | Not published | Licence reported as CC0 (U) |
| NAV pam-stilling-feed (Norway) | `pam-stilling-feed.nav.no/api/v1/feed` | Signed JWT; a public token rotates at irregular intervals | Not published | "Anyone can use this API free of charge"; accept the terms of use (V, [docs](https://navikt.github.io/pam-stilling-feed/)) |
| unvacancies.org (UN system) | `unvacancies.org/feed.xml` | None | Refreshed daily | "Needs no account or agreement"; candidates apply on the official portal. Not affiliated with the UN (V, [partners](https://unvacancies.org/partners)) |
| Greenhouse | `boards-api.greenhouse.io/v1/boards/{token}/jobs` | None for reading | "May be rate limited" | Public board data (V, [docs](https://developers.greenhouse.io/job-board.html)) |
| Lever | `api.lever.co/v0/postings/{site}?mode=json` | None | - | Published postings are public. `jobs.lever.co` robots.txt says `ai-train=no` (V, [docs](https://github.com/lever/postings-api)) |
| Ashby | `api.ashbyhq.com/posting-api/job-board/{name}` | None | - | Published for custom careers pages (V, [docs](https://developers.ashbyhq.com/docs/public-job-posting-api)) |
| SmartRecruiters | `api.smartrecruiters.com/v1/companies/{id}/postings` | None | - | Published Posting API (V, [docs](https://developers.smartrecruiters.com/docs/posting-api)) |
| Remotive, Jobicy, Arbeitnow | Public JSON | None | - | Remote and European jobs; terms not re-read in this round |

Keys a user enters are their own. Udyoga never ships a shared key.

### Sources considered and not used

| Source | Why not |
|---|---|
| ReliefWeb Jobs API | Every call needs a pre-approved `appname`; an unapproved one gets HTTP 403. 10,000 calls a day once approved (V, [docs](https://apidoc.reliefweb.int/)). unvacancies.org covers UN jobs without it |
| France Travail "Offres d'emploi" | Withdrawn for third parties while reuse terms are reviewed (V, [data.gouv](https://www.data.gouv.fr/dataservices/api-offres-demploi)) |
| Bundesagentur für Arbeit Jobsuche | Only community-documented, and returned 403 (U, [bundesAPI](https://github.com/bundesAPI/jobsuche-api)) |
| EURES | No public API; robots.txt disallows `/search/` |
| Job Market Finland | For registered organisations only (V, [terms](https://tyomarkkinatori.fi/en/instructions-and-support/interfaces/interfaces-for-job-postings/terms-of-use-for-job-market-finlands-job-posting-apis)) |
| UN Careers RSS | Returns 403 to non-browser clients |
| Careerjet | Built for publisher websites; needs each end user's IP and user agent ([docs](https://www.careerjet.com/partners/api)) |
| Canada Job Bank | Monthly open-data CSVs (Open Government Licence – Canada), not a live API. Good for bulk use ([open.canada.ca](https://open.canada.ca/data/en/dataset/ea639e28-c0fc-48bf-b5dd-b8899bd43072)) |
| LinkedIn, Glassdoor | Their terms forbid automation. Udyoga only opens links and drafts text you send yourself |
| Indeed, SEEK, Jora, JobStreet, Bayt, GulfTalent | Block bots or disallow search in robots.txt |
| Stepstone group boards (Totaljobs and others) | Terms forbid "any bot, script, crawler, scraper". Read only in the user's own in-app browser |

### Employer career pages

Many employers have no feed. A workable pattern:

1. Seed employers from open lists: NHS ODS (all trusts), Wikidata hospitals
   with an official website (CC0), and EPR customer lists (section 3).
2. Find the careers page (Wikidata P856, then `/careers` or `/jobs`).
3. Recognise the applicant tracking system from the page (`greenhouse`,
   `lever.co`, `ashbyhq`, `smartrecruiters`, `myworkdayjobs`, `oraclecloud`,
   `taleo`, `icims`, `successfactors`, `jobtrain`, `trac.jobs`).
4. Use the official API where one exists. Otherwise read schema.org
   `JobPosting` markup, slowly and cached.

Workday, Oracle Recruiting Cloud, Taleo, iCIMS, SuccessFactors, Jobtrain and
Trac publish no third-party job API. Udyoga ships no site recipes for them;
users can write their own (see [recipes.md](recipes.md)).

---

## 2. Visa routes, sponsors and occupation codes

Udyoga shows likely routes and codes. It never decides them: the employer
chooses the occupation code on a sponsorship certificate.

### United Kingdom

| Data | Source | Format and licence |
|---|---|---|
| Skilled Worker and Health and Care rules, going rates, thresholds | GOV.UK Content API: `www.gov.uk/api/content/guidance/immigration-rules/immigration-rules-appendix-skilled-occupations` (also `…-appendix-skilled-worker`, `…-appendix-immigration-salary-list`) | JSON with HTML tables. "Anyone can use this API for any purpose." OGL v3 (V, [Content API](https://content-api.publishing.service.gov.uk/)) |
| Licensed sponsors | Content API attachments of `/government/publications/register-of-licensed-sponsors-workers` | Daily CSV, about 11 MB: organisation, town, rating, routes. The file URL changes daily, so resolve it through the API each time (V, [register](https://www.gov.uk/government/publications/register-of-licensed-sponsors-workers)) |
| Job title to SOC 2020 to ISCO-08 | ONS SOC 2020 coding index | xlsx, about 30,000 titles (V, [ONS](https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/soc2020/soc2020volume2codingrulesandconventions)) |
| Code lookup for people | CASCOT, linked from GOV.UK | Web tool ([GOV.UK](https://www.gov.uk/health-care-worker-visa/your-job)) |

Rules as read in Nov 2026 (Appendix Skilled Worker updated 8 Oct 2026; V):

- General threshold: the higher of £41,700 and the occupation's going rate.
- New-entrant rate: the higher of £33,400 and 70% of the going rate. It
  needs one of: under 26; a named postdoc role; working towards a UK
  professional qualification, registration or chartered status; or a last
  permission as a Student (UK degree) or Graduate. It is capped at 4 years.
- Health and Care visa: only listed codes qualify. Many IT codes (2133,
  2134, 2139, 3573, 3544, 3549) do not; 1171 (health services managers)
  does, with a lower rate at NHS employers.
- Temporary Shortage List codes: the certificate must be issued before
  31 Dec 2026, and a worker sponsored in one cannot bring new dependants.
- Switching to Skilled Worker inside the UK is allowed from most routes,
  but not from Visitor and a few others (SW 1.5ZA). Time as a dependant
  does not count towards one's own Skilled Worker settlement.
- A sponsor licence is not a promise to sponsor any post. NHS adverts often
  say outright that a post "does not meet the minimum criteria for visa
  sponsorship".

### Other countries (published amounts, Nov 2026)

| Country | Source | Machine-readable? | Notes |
|---|---|---|---|
| Ireland | DETE employment-permit pages | HTML and PDF | From 1 Mar 2026: Critical Skills €40,904; General Employment Permit €36,605 (V, [DETE](https://enterprise.gov.ie/en/news-and-events/department-news/2025/december/20251202.html)). Ineligible-occupation lists apply |
| Canada | IRCC Express Entry rounds | JSON (`ee_rounds_123_en.json`) | Category-based rounds keyed to NOC codes (V, [IRCC](https://www.canada.ca/en/immigration-refugees-citizenship/services/immigrate-canada/express-entry/rounds-invitations/category-based-selection.html)) |
| Germany | Bundesagentur für Arbeit | HTML | EU Blue Card 2026: €50,700; €45,934.20 for shortage jobs and new entrants (V, [BA](https://www.arbeitsagentur.de/vor-ort/zav/working-and-living-in-germany/iss-en/issue-03-2026/blue-card)) |
| Netherlands | IND required amounts | HTML table | Highly skilled migrant 30+: €5,942 a month (V, [IND](https://ind.nl/en/required-amounts-income-requirements)) |
| Singapore | MOM Employment Pass | HTML | Minimum S$5,600 (S$6,000 for new applications from 1 Jan 2027), rising with age; COMPASS points (V, [MOM](https://www.mom.gov.sg/passes-and-permits/employment-pass/eligibility)) |
| New Zealand | INZ Green List and median wage | HTML | Keyed to ANZSCO (U) |
| Australia | Home Affairs CSOL | Not confirmed | Keyed to ANZSCO (U) |
| UAE, Saudi Arabia, Qatar, Oman, Kuwait | Ministry pages | No open API | Many admin roles are reserved for nationals (U) |

No open, authoritative visa-free (passport) matrix was found. Community
datasets derive from passportindex.org, whose terms are unverified.

### Occupation mapping

1. A CV job title goes to the ONS coding index (UK) or the ESCO search API
   (anywhere).
2. Either gives an ISCO-08 code.
3. From ISCO-08, map to the country's own system: UK SOC 2020, US SOC (BLS
   crosswalk), Canada NOC, Australia and New Zealand ANZSCO.
4. Look up that country's visa list.

| Source | Terms |
|---|---|
| ESCO API (`ec.europa.eu/esco/api`) | No key. Data free to reuse (in practice CC BY 4.0); software EUPL 1.2 (V, [ESCO](https://esco.ec.europa.eu/en/use-esco/use-esco-services-api)) |
| O\*NET Web Services | Free key. Show a link to O\*NET Web Services prominently. Throttled above 5 requests a second or 50,000 a day (V, [terms](https://services.onetcenter.org/terms)) |

---

## 3. Country context data

| Source | Access | Terms | Use |
|---|---|---|---|
| World Bank API v2 | `api.worldbank.org/v2/country/{iso}/indicator/{id}?format=json`, no key | CC BY 4.0 (U) | Unemployment, GDP per head, PPP |
| ILOSTAT | `rplumber.ilo.org/data/indicator/` | CC BY 4.0 (U) | Earnings and employment by occupation |
| OECD Data Explorer | `sdmx.oecd.org/public/rest/` | CC BY 4.0 (U); conflicting rate limits; no VPN traffic | Wages, migration |
| Unicode CLDR `territoryInfo.json` | Bundled file | Unicode licence | Official languages and literacy |
| Numbeo | Paid API only (from US$260 a month) | Proprietary | Not used. Use World Bank PPP instead ([pricing](https://www.numbeo.com/common/api.jsp)) |
| REST Countries | Now redirects to a legacy file | MPL-2.0 (U) | Not used; CLDR instead |
| Epic customer list | `open.epic.com/Endpoints/Brands` (FHIR bundle) | May be distributed "only by linking": fetch at run time, never bundle (V, [terms](https://open.epic.com/Home/TermsOfUse)) | Employers that run Epic |
| Oracle Health customer list | `github.com/oracle-samples/ignite-endpoints` | No licence file: reference at run time | Employers on Millennium |
| NHS organisations | NHS ODS ORD API (`directory.spineservices.nhs.uk`), no key | OGL (U) | Every NHS trust |
| Hospitals worldwide | Wikidata SPARQL | CC0; send a descriptive User-Agent | Seed list for career pages |

---

## 4. Interview methodology

This is why the interview simulator scores and coaches the way it does.

### Panels score content against set criteria

Scales differ by employer. Udyoga never claims a single national scale.

| Example | Scale | What it rewards |
|---|---|---|
| NHS Lothian Band 5 pack (Jan 2025) | N/O, then 1–4 per question. N/O = "only dealt with in passing", e.g. "I possess excellent communication skills" with no example | Elements of the competency, with evidence and depth (V, [pack](https://careers.nhslothian.scot/wp-content/uploads/2025/01/Interview-Pack-Registered-Nurses-and-Midwives-Band-5.pdf)) |
| Salisbury NHS FT guidance | 0–3, by consensus, against at least 3 key elements agreed in advance | More time on behaviours and impact than on circumstances (V, [guide](https://www.salisbury.nhs.uk/media/n1qjsvrh/preparing-for-interview-guidance-version-1-september-2023.docx)) |
| UK Civil Service Success Profiles | 1–7 for behaviours, experience and technical; 4-point for strengths | Independent scores, then reconciled (V, [COPFS](https://www.copfs.gov.uk/about-copfs/careers/how-your-application-is-assessed-success-profiles), [GOV.UK](https://www.gov.uk/government/publications/success-profiles/success-profiles-candidate-overview)) |
| Irish publicjobs | Competency Model or Capability Framework | Examples are probed: "How did you measure this?" (V, [advice](https://publicjobs.ie/en/information-hub/our-recruitment-process/interview-advice)) |

Common rules seen in published packs and policies:

- Judge what is said, not how it is said. Panels note facts only.
- A candidate who shows no evidence for an essential criterion cannot be
  appointed. Coverage of every essential criterion matters more than polish.
- Panels are trained not to show opinion, surprise or disagreement, and may
  interrupt to move on. A quiet panel is normal.
- Typical probes target the missing part of an answer: "What did you
  yourself do?", "What was the outcome?", "How did you measure that?", "What
  did you learn?", "Who else was involved?", "Can you give a real example?"
  At most one or two per question.

### Delivery: what is measured, and what is never scored

- **Content is scored; delivery shapes impressions.** Impression management
  relates more to interview ratings than to job performance (Barrick,
  Shaffer & DeGrassi 2009, [doi](https://doi.org/10.1037/a0016532)). Udyoga
  helps you avoid being marked down for delivery, without treating delivery
  as the job.
- **Fillers.** Filled pauses ("um") were rated better than silent pauses and
  often went unnoticed (Christenfeld 1995). Interviewers mostly missed
  nervous tics; slower speech was the cue read as nerves (Feiler & Powell
  2016, [summary](https://www.bps.org.uk/research-digest/why-interviewers-rate-anxious-candidates-harshly-and-what-you-can-do-about-it)).
  So a few fillers are never flagged.
- **Pace and length** are shown against usual ranges, never scored. No
  study gives an optimum length; 90–150 seconds for a behavioural answer
  fits the time panels allow.
- **No facial emotion scoring.** Facial movements are not reliable signals
  of emotion (Barrett et al. 2019, [PMC6640856](https://pmc.ncbi.nlm.nih.gov/articles/PMC6640856)).
  HireVue dropped visual analysis in 2021
  ([SHRM](https://www.shrm.org/resourcesandtools/hr-topics/talent-acquisition/pages/hirevue-discontinues-facial-analysis-screening.aspx)).
  The EU AI Act, Art. 5(1)(f), bans inferring emotions at work and in
  education from biometric data, from 2 Feb 2025
  ([FPF](https://fpf.org/blog/red-lines-under-eu-ai-act-unpacking-the-prohibition-of-emotion-recognition-in-the-workplace-and-education-institutions/)).
  Voice-tone emotion and "confidence detection" are excluded for the same
  reasons.
- **No eye-contact scoring.** There is no good isolated evidence for it, and
  it harms autistic candidates and people from cultures where steady eye
  contact is not the norm. The camera check only offers setup tips.
- **Video interviews start at a disadvantage**: technology-mediated
  interviews got lower ratings (d ≈ −0.41; Blacksmith, Willford & Behrend
  2016, [PAD](https://scholarworks.bgsu.edu/pad/vol2/iss1/2)). Light, sound
  and framing checks are worth more than gesture coaching.

### Confidence: what holds up

| Technique | Evidence | How Udyoga uses it |
|---|---|---|
| Telling candidates what is assessed | Improved performance and validity (Klehe et al. 2008) | Every question shows what it tests |
| Coaching and structured practice | Content coaching raised ratings without hurting validity (Maurer et al.) | Practise against the role's criteria |
| Job-search programmes | Skills plus motivation work best (Liu, Huang & Wang 2014, 47 studies) | Each drill ends with a small, real win |
| Feedback | Over a third of feedback interventions made performance worse, mostly self-focused feedback (Kluger & DeNisi 1996, [doi](https://doi.org/10.1037/0033-2909.119.2.254)) | One strength and one task-level fix per answer; no judgements about the person |
| Graded exposure | First-line for social anxiety; small VR interview trials helped | Five levels, from untimed rehearsal to a challenging panel |
| "I am excited" reappraisal | A 2025 direct replication found no observer-rated benefit ([Poynter & Pasqualini](https://reference-global.com/download/article/10.58734/plc-2025-0011.pdf)) | Optional, labelled as weak evidence |
| Power posing | Effects did not replicate ([Carney's statement](https://faculty.haas.berkeley.edu/dana_carney/pdf_my%20position%20on%20power%20poses.pdf)) | Not included |

Answer frameworks (STAR, STARR, CAR, PREP) have no validity evidence of their
own. They help because they map onto what panels mark: action, outcome and
reflection.

---

## 5. What users of other apps hate and want

From public reviews read in Nov 2026: App Store and Google Play reviews,
Trustpilot, Reddit, Hacker News and GitHub issues. Samples were filtered by
topic, so counts are approximate and lean negative.

### Job search and relocation apps (about 450 reviews, 33 sources)

Hate:

1. Paying to apply: paywalls, credits and subscriptions aimed at people with
   no job, plus billing traps.
2. Fake, ghost, expired and reposted listings.
3. Matches in the wrong place or field; filters ignored.
4. Visa and sponsorship ignored: no working filter.
5. Auto-apply tools sending wrong, unwanted or invented applications.
6. Notification and e-mail spam.
7. Accounts restricted on LinkedIn after automation, with no one to ask.

Asked for by name: a visa and relocation filter that works; a realistic
route and plan; pay compared after tax and rent; approve before anything is
sent; exclude keywords and companies; plain filters (date, salary, distance).

Nobody solves: needing a job to move but needing to live there to get one;
routes changing mid-cycle with nothing watching them; judging the whole move,
not only the offer.

### Interview practice apps (Final Round AI, Exponent, Big Interview, Yoodli, Orai and others)

Hate:

1. Billing traps, no cancel button, refused refunds; high prices.
2. Bugs, crashes and lost recordings.
3. Generic, canned or robotic questions; no real follow-ups.
4. Delivery metrics that punish normal speech.
5. Camera self-view and one-way video raising anxiety.
6. Recordings kept on servers; local storage only for enterprise plans.

Asked for: practise out loud with an interviewer that talks back; record,
play back and re-take; score against what the panel marks (values,
criteria); know what each round assesses; interruptions and challenge;
later rounds (panels, presentations), not only screens.

Unsolved: practice that carries over to real nerves; formats that penalise
introverted and neurodivergent people; tools pushing a zero-filler polish
panels do not want; "copilots" that sell anxiety relief through cheating.

### Networking and unified-inbox apps

Hate: inbox clutter and spam; billing traps; accounts restricted or banned
after automation; fragile unified inboxes (disconnects, missing messages);
losing track of who said what, where; handing over passwords.

Asked for: follow-up reminders with control over who; important-only alerts;
e-mail and LinkedIn in one place; one person across many accounts.

Unsolved: networking tools are built for sales, not job seekers; nothing
helps people grow a network by hand, safely.

### What Udyoga does with this

- Free, no credits, no pay-to-apply, no notification spam.
- Eligibility and sponsor checks on every job; ghost and stale listing
  checks.
- Nothing is sent or submitted for you: Udyoga drafts, you send.
- Interview practice scores content against the role's criteria, runs on the
  device, and never reads your face.
