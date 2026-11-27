# Career hand-off from helper apps

Another app on the same computer can pass career items to Udyoga. For
example, an app that reads your social network messages can pass on the
messages a recruiter sent you. Vani is one such helper app, but any app can
do this. The other app writes small files into a shared folder. Udyoga reads
them and adds the items to **Conversations**.

Nothing goes over the network. The folder is on your own computer. Udyoga
only reads it when you switch the import on.

## Switching it on

1. In Udyoga, open **Settings**.
2. Find **Helper apps**.
3. Switch on **Import career items from a helper app**. It is off by
   default, and the setting applies to this device only.
4. The card shows the folder Udyoga reads. Turn on the hand-off in the
   helper app too.

Udyoga reads the folder at these times:

- when it starts
- once an hour while it is open
- soon after a helper app drops a new file, on systems that can watch
  folders (Linux, Windows and macOS)

## The folder

The folder is the same for every Brahma app:

| System  | Folder                                                    |
| ------- | --------------------------------------------------------- |
| Linux   | `${XDG_DATA_HOME:-~/.local/share}/brahma/handoff/career/` |
| Windows | `%APPDATA%\brahma\handoff\career\`                        |
| macOS   | `~/Library/Application Support/brahma/handoff/career/`    |

Phones have no hand-off folder.

It contains these folders:

| Folder             | Who writes it         | What is in it                                                                 |
| ------------------ | --------------------- | ----------------------------------------------------------------------------- |
| `inbox/`           | the helper app        | Files waiting to be read.                                                     |
| `tmp/`             | both apps             | Files still being written. Neither app reads this folder.                     |
| `done/`            | Udyoga                | Files Udyoga has read. Kept for 30 days.                                      |
| `rejected/`        | Udyoga                | Lines Udyoga could not read, with the reason. Kept for 30 days.               |
| `outbox/`          | Udyoga                | Messages waiting for the helper app to send (see below).                      |
| `outbox/read/`     | the helper app        | Messages the helper app has taken in. Kept for 30 days.                       |
| `outbox/rejected/` | the helper app        | Messages the helper app could not read. Kept for 30 days.                     |
| `status/`          | the helper app        | The helper app's answer for each message: sent, failed, and so on.            |
| `status.json`      | the helper app        | The helper app is running, and the LinkedIn budget it has left.               |

## How a helper app writes a file

1. Write the whole file into `tmp/`.
2. Flush it to disk, for example with `fsync`, and close it.
3. Rename it into `inbox/`. A rename within the same folder tree is
   atomic, so Udyoga never sees a half-written file.

Name each file `<UTC time>-<random>.jsonl`, for example
`20261127T093000.000Z-5f1c2a9e.jsonl`. Udyoga reads the files in name
order, so the oldest file is read first.

Never change a file after it is in `inbox/`. To add more items, write a
new file.

## File format, version 1

A file is [JSON Lines](https://jsonlines.org/): one JSON object on each
line, in UTF-8. Udyoga ignores empty lines.

```json
{"v":1,"kind":"message","source":"linkedin","id":"linkedin:urn:li:msg_message:(…)","threadId":"linkedin:urn:li:msg_conversation:(…)","threadTitle":"Sol Example","peer":{"name":"Sol Example","headline":"Recruiter at Example Agency","profileUrl":"https://www.linkedin.com/in/sol-example","company":"Example Agency"},"subject":"","text":"We have a records officer role you may like.","sentAt":"2026-11-20T09:00:00Z","direction":"in","reasons":["InMail","sender's headline says hiring (Recruiter at Example Agency)"],"scam":{"level":"none","signs":[]}}
```

| Field         | Required | Meaning                                                                                                    |
| ------------- | -------- | ---------------------------------------------------------------------------------------------------------- |
| `v`           | yes      | Format version. Always `1` for this version.                                                               |
| `kind`        | yes      | The record kind (see below).                                                                               |
| `source`      | yes      | Where the item came from, such as `linkedin`. Udyoga uses it as the thread's channel. Unknown names become `other`. |
| `id`          | yes      | A stable, unique id for this item. The same item always gets the same id.                                  |
| `threadId`    | yes      | A stable id for the conversation the item belongs to.                                                      |
| `threadTitle` | no       | The conversation's name in the helper app.                                                                 |
| `peer`        | no       | The other person: `name`, `headline`, `profileUrl` and `company`. Each one is optional.                    |
| `subject`     | no       | A subject line, as an InMail has.                                                                          |
| `text`        | yes, unless there is a `subject` | The message text.                                                                  |
| `sentAt`      | yes      | When it was sent, as ISO 8601 with a time zone (`2026-11-20T09:00:00Z`).                                   |
| `direction`   | yes      | `in` (they wrote to you) or `out` (you wrote to them).                                                     |
| `reasons`     | no       | Short sentences that explain why the helper app thought this item was about your career.                   |
| `scam`        | no       | The helper app's scam check: `level` is `none`, `caution` or `high`, and `signs` lists what it saw.        |

## Record kinds

| Kind                 | Status                                                    |
| -------------------- | --------------------------------------------------------- |
| `message`            | Imported into **Conversations** (below).                  |
| `job_alert`          | Imported as a job (see [Career signals](#career-signals)). |
| `application_status` | Imported onto an application (see [Career signals](#career-signals)). |
| `invite_accepted`    | Imported as a contact (see [Career signals](#career-signals)). |
| `profile_view`       | Imported as a contact (see [Career signals](#career-signals)). |

Udyoga skips any other kind. It also skips any line where `v` is not `1`.
It does not guess what those lines mean. They stay in the file under
`done/`.

The fields in the table above are for `message`. The other kinds have
their own fields.

## What Udyoga does with a message

- **One thread per conversation.** The thread's mode is "From a helper
  app", and its external id is the `threadId`.
- **Each message is added once.** It is stored with the record `id` as its
  external id.
- **Matching the person.** Udyoga looks for the person by profile link
  first, then by name when only one contact has that name.
- **Unknown people.** If Udyoga finds no match, the thread waits in the
  **Screener**, so you can add the person as a lead or ignore them.
- **Threads you logged by hand.** If you already logged a thread with that
  person by hand, the thread takes the helper app's id. A message you
  already logged is not added again.
- **Do not contact.** Udyoga skips people you marked "do not contact".
- **Scam warning.** The thread keeps the most severe scam check it was
  given. For `caution` or `high`, Udyoga shows a banner above the thread.
  The banner lists the signs and says how to check the company yourself.
- **Reasons.** The thread keeps every reason it was given.

## Career signals

A helper app can also pass on what a social network shows about your job
search. Vani, for example, reads your LinkedIn applied jobs, notifications
and profile views two or three times a day. These signals use the same
files and the same version, `v: 1`. Udyoga ignores fields it does not
know.

```json
{"v":1,"kind":"job_alert","source":"linkedin","id":"linkedin:job:4100000101","sentAt":"2026-11-26T08:00:00Z","job":{"id":"4100000101","url":"https://www.linkedin.com/jobs/view/4100000101/","title":"Ward Coordinator","company":"Example Health","location":"Leeds"},"text":"New job for you: Ward Coordinator at Example Health","reasons":["job alert in LinkedIn's notifications"]}
{"v":1,"kind":"application_status","source":"linkedin","id":"linkedin:application:4100000001:viewed","sentAt":"2026-11-27T12:00:00Z","job":{"id":"4100000001","url":"https://www.linkedin.com/jobs/view/4100000001/","title":"Ward Coordinator","company":"Example Health","location":"Leeds"},"status":"viewed","statusText":"Application viewed","reasons":["LinkedIn shows: Application viewed"]}
{"v":1,"kind":"invite_accepted","source":"linkedin","id":"linkedin:invite-accepted:sol-example","sentAt":"2026-11-25T12:00:00Z","peer":{"name":"Sol Example","headline":"Ward Manager at Example Health","profileUrl":"https://www.linkedin.com/in/sol-example","company":"Example Health"},"reasons":["accepted your LinkedIn invitation"]}
{"v":1,"kind":"profile_view","source":"linkedin","id":"linkedin:profile-view:sol-example:2026-11-26","sentAt":"2026-11-26T10:30:00Z","peer":{"name":"Sol Example","headline":"Talent Partner at Example Health","profileUrl":"https://www.linkedin.com/in/sol-example","company":"Example Health"},"reasons":["works at a target employer: Example Health"]}
```

| Field        | Kinds                                  | Meaning                                                                                       |
| ------------ | -------------------------------------- | --------------------------------------------------------------------------------------------- |
| `v`, `kind`, `source`, `id`, `sentAt`, `reasons` | all              | As for a message. `sentAt` is when it happened, or when the helper app first saw it.          |
| `job`        | `job_alert`, `application_status`      | The job: `id` (the network's job id), `url`, `title`, `company` and `location`.                |
| `status`     | `application_status`                   | `applied`, `viewed`, `resume_downloaded`, `in_review`, `not_selected`, `closed` or `unknown`.  |
| `statusText` | `application_status`                   | What the network showed, in its own words. Needed for `unknown`.                              |
| `peer`       | `invite_accepted`, `profile_view`      | The person: `name` (required), `headline`, `profileUrl` and `company`.                         |
| `text`       | `job_alert`                            | The notification's line. Optional.                                                            |

What each kind needs, or the line is refused under `rejected/`:

- `job_alert`: a `job` with a `title`, and an `id` or a `url`.
- `application_status`: a `job` with something to match (`id`, `url` or
  `title`) and a `status`. An unknown `status` is read as `unknown`.
- `invite_accepted` and `profile_view`: a `peer` with a `name`.

The helper app decides what to pass on. Vani passes every job alert, every
status and every accepted invitation, but a profile view only when the
viewer works at an employer in your career file.

### What Udyoga does with a signal

- **Job alert.** It becomes a job on the **Jobs** page, through the same
  import as the job boards: the same fit score, and the same check for a
  job you already have. Its source shows as "LinkedIn alert via helper".
  A job you dismissed or deleted stays that way.
- **Application status.** Udyoga looks for the application it is about:
  - first by the job's `id` or `url`, in the application's link or its
    job's link;
  - then by employer and title. The employer must match, and the titles
    must share at least 75% of their words.

  When it finds one, it adds a timeline entry such as "LinkedIn:
  Application viewed (via helper app)". `applied` also moves an
  application you were still preparing to **Applied**. `not_selected`
  also moves an open application to **Rejected**. Udyoga never moves an
  application back.

  When no application matches surely enough, nothing changes by itself.
  The status waits on the **Applications** page under **Updates from a
  helper app**. You choose the application it is about, add it as a new
  application, or dismiss it. These choices stay on this device.
- **Accepted invitation and profile view.** The person becomes a contact,
  through the same merge as other leads. Udyoga finds a known contact by
  profile link first, then by a name only one contact has. A known
  contact gets the profile link if it was missing, and a note. A new
  contact's source is "LinkedIn (helper app)". A profile view adds the
  note "Viewed your profile on <date>" and marks the contact as someone
  who got in touch. Udyoga skips people you marked "do not contact".

Each signal is imported once. Udyoga keeps each status's timeline entry
under an id made from the signal's `id`, so the same status read twice,
or on two devices, is one entry.

## Idempotency

A helper app can write the same item again, for example after a restart.
This is safe:

- Udyoga skips a message whose `id` is already in the thread, and a
  signal it has imported before.
- Every `id` and `threadId` must stay the same each time the helper app
  writes the same item.
- Two Udyoga copies can read the same folder. Only the first copy moves a
  file into `done/`. Neither copy stores a line twice.

## Lines Udyoga cannot read

Udyoga writes each bad line into a file of the same name under
`rejected/`. Each entry has the line number, the reason and the original
text:

```json
{"line":3,"reason":"\"id\" is missing","text":"{…}"}
```

The good lines in the same file are still imported.

## Sending LinkedIn messages through a helper app

These are additions to format version 1. A helper app that can send
LinkedIn messages (Vani is one) can send them for Udyoga. Udyoga never
sends anything itself: it leaves the message in the folder, and the helper
app shows it to you. **Nothing is sent until you check it in the helper app
and press Send there.** You can change the text first, or cancel it.

### Switching it on

1. Switch on the import in **Settings**, **Helper apps** (see above).
2. Switch on the hand-off in the helper app.
3. In a LinkedIn thread, the composer now shows **Send via LinkedIn
   helper**. It shows only while the helper app's `status.json` is less
   than 5 minutes old, so only while the helper app is running. Otherwise
   **Copy & open** shows, as before.

A connection note (an invitation) always goes by hand with **Copy & open**.

### What the helper app sends to

The helper app sends only to someone you already talk to:

- a person you already have a conversation with in the helper app, or
- a 1st-degree connection. The helper app checks this on LinkedIn first.

Anyone else gets the answer `failed` with the reason "not a connection".
The helper app never sends a first message to a stranger.

### Each message: `outbox/<id>.json`

Udyoga writes one file per message, the whole file under `tmp/` first and
then renamed into `outbox/`. The file name is the `id` with `.json`.

```json
{"v":1,"kind":"message","id":"udyoga-0b5e7c1a-…","source":"linkedin","createdAt":"2026-11-27T10:00:00Z","to":{"name":"Mira Example","profileUrl":"https://www.linkedin.com/in/mira-example"},"threadId":"linkedin:urn:li:msg_conversation:(…)","text":"Hello Mira, …","application":{"id":"…","title":"Records Officer","company":"Example Health"}}
```

| Field         | Required | Meaning                                                                                       |
| ------------- | -------- | --------------------------------------------------------------------------------------------- |
| `v`           | yes      | Always `1`.                                                                                   |
| `kind`        | yes      | Always `message`. Invitations are not sent this way.                                          |
| `id`          | yes      | `udyoga-` and the message's id. Stable: writing it again gives the same file. Letters, digits, `.`, `_` and `-` only. |
| `source`      | yes      | The network. Always `linkedin` for now.                                                       |
| `createdAt`   | yes      | When Udyoga wrote it, in UTC (RFC 3339).                                                      |
| `to`          | yes      | `profileUrl` (required): the person's LinkedIn profile link. `name` is optional.              |
| `threadId`    | no       | The thread's hand-off id, when the thread came from the helper app.                           |
| `text`        | yes      | The message, 1 to 4,000 characters.                                                           |
| `application` | no       | The job application it is about: `id`, `title` and `company`, each optional. Shown on the card. |

The helper app moves each file it has read to `outbox/read/`, or to
`outbox/rejected/` when it cannot read it, and answers `failed` with the
reason. Reading the same `id` twice changes nothing.

### Each answer: `status/<id>.json`

The helper app rewrites the whole file (under `tmp/`, then renamed) each
time the message's state changes:

```json
{"v":1,"id":"udyoga-0b5e7c1a-…","state":"sent","updatedAt":"2026-11-27T12:00:00Z","sentAt":"2026-11-27T11:58:00Z","text":"Hello Mira, …","messageId":"linkedin:urn:li:msg_message:(…)","threadId":"linkedin:urn:li:msg_conversation:(…)"}
```

| `state`     | Meaning                                                                                         |
| ----------- | ----------------------------------------------------------------------------------------------- |
| `pending`   | Waiting for you in the helper app.                                                              |
| `waiting`   | Held, with the `reason`: over the budget (confirm it again later), signed out, or the account is halted. |
| `sending`   | You confirmed it; it is in the helper app's send queue.                                         |
| `sent`      | LinkedIn has it. `text` is what went (you may have changed it). `messageId` and `threadId` are the same ids the helper app gives career items. |
| `failed`    | Not sent, with the `reason`. It is not tried again.                                             |
| `cancelled` | You cancelled it in the helper app.                                                             |

What Udyoga does with an answer:

- The message in the thread moves to the new state. Its label says so, for
  example "Sent through the helper app".
- A sent message takes the text that went and LinkedIn's message id. If
  the same message also came in as a career item, it is kept once.
- A thread without a hand-off id takes the conversation's `threadId`.
- For `failed` and `waiting`, Udyoga adds a note with the reason, once for
  each reason.

Udyoga only reads `status/`. The helper app deletes final answers after 30
days.

### The budget: `status.json`

The helper app rewrites `status.json` at least once a minute while it runs:

```json
{"v":1,"updatedAt":"2026-11-27T12:00:00Z","channels":{"linkedin":{"drafts":true,"posts":true,"state":"ok","budget":{"invite":{"dayLeft":15,"dayLimit":15,"weekLeft":80,"weekLimit":80},"message":{"dayLeft":37,"dayLimit":40,"weekLeft":147,"weekLimit":150},"post":{"dayLeft":2,"dayLimit":2,"weekLeft":7,"weekLimit":7}}}}}
```

- `drafts`: the helper app takes drafts for this network.
- `posts`: the helper app takes posts for this network (see below). A
  helper app without posts leaves it out, which reads as `false`.
- `state`: `ok`, `needs-login`, `halted` or `none`.
- `budget`: what is left of each kind of action today and this week. A
  limit of `0` (and `-1` left) means no cap.

While the file is less than 5 minutes old, Udyoga shows the helper app's
budget in place of its own count of messages sent by hand. The helper app
refuses a message over its budget (`waiting`), so the numbers agree.

## Posting to LinkedIn through a helper app

These are also additions to format version 1. A helper app that can post
on LinkedIn (Vani is one) can post a finished draft from the LinkedIn
studio: a post, or a carousel (its caption and its PDF). Udyoga never posts
anything itself. **Nothing is posted until you check it in the helper app
and tap Post there.** You can change the text or who sees it first, or
cancel it.

### Switching it on

1. Switch on the import in **Settings**, **Helper apps** (see above).
2. Switch on the hand-off in the helper app.
3. Open a finished post or carousel in the LinkedIn studio. A **Helper
   app** card shows **Send to helper**. It shows only while the helper
   app's `status.json` is less than 5 minutes old and says `"posts":true`.
   Otherwise copy the post by hand, as before.
4. Choose who sees it (anyone, or your connections only), and if you like
   a time. The time is a wish: the helper app offers it on its card.

### When it goes out

- **Post now** in the helper app posts it straight away.
- **A later time**: the helper app either hands it to LinkedIn's own
  scheduler at that same tap, or, where it cannot, holds it and reminds
  you at the time to tap Post. Nothing is ever posted on its own.
- The helper app keeps to its own post budget (in `status.json`). Over the
  budget, the post waits, with the reason.

### Each post: `files/<id>/` and `outbox/<id>.json`

Udyoga first writes the post's files, each one whole (under `tmp/`, then
renamed) into `files/<id>/`. Then it writes the post itself into `outbox/`
the same way. So the helper app never sees a post whose files are not
there yet.

```json
{"v":1,"kind":"post","id":"udyoga-post-…-20261127100100","source":"linkedin","createdAt":"2026-11-27T10:01:00Z","text":"Five records habits …","visibility":"connections","attachments":[{"path":"files/udyoga-post-…-20261127100100/carousel.pdf","type":"document","title":"Five records habits"}],"scheduleAt":"2026-11-28T08:30:00Z","report":{"id":"…","tool":"carousel","title":"Five records habits"}}
```

| Field         | Required | Meaning                                                                                  |
| ------------- | -------- | ---------------------------------------------------------------------------------------- |
| `v`           | yes      | Always `1`.                                                                              |
| `kind`        | yes      | Always `post`.                                                                           |
| `id`          | yes      | `udyoga-post-`, the studio draft's id and the time it was sent. Letters, digits, `.`, `_` and `-` only. |
| `source`      | yes      | The network. Always `linkedin` for now.                                                  |
| `createdAt`   | yes      | When Udyoga wrote it, in UTC (RFC 3339).                                                 |
| `text`        | yes      | The post, up to 3,000 characters (may be empty when a file is attached).                 |
| `visibility`  | no       | `anyone` (the default) or `connections`.                                                 |
| `attachments` | no       | Up to 9 pictures (`image`: PNG or JPEG, 8 MB each) or one `document` (a PDF, 20 MB). `path` is `files/<id>/<name>`, inside the folder. A document may have a `title`. |
| `scheduleAt`  | no       | When you would like it out, in UTC. A wish only.                                         |
| `report`      | no       | Which studio draft it came from: `id`, `tool` (`post` or `carousel`) and `title`.        |

The helper app checks each file: inside the folder (no `..`, no link that
leads out), within the size limit, and really a PNG, JPEG or PDF. It keeps
its own copy and removes `files/<id>/`. It moves the post to
`outbox/read/`, or to `outbox/rejected/` when it cannot take it, and then
answers `failed` with the reason.

### Each answer: `status/<id>.json`

```json
{"v":1,"id":"udyoga-post-…-20261127100000","kind":"post","state":"posted","updatedAt":"2026-11-27T12:00:00Z","url":"https://www.linkedin.com/feed/update/urn:li:activity:…/","postedAt":"2026-11-27T11:00:00Z","text":"Three things …"}
```

| `state`     | Meaning                                                                                  |
| ----------- | ---------------------------------------------------------------------------------------- |
| `pending`   | Waiting for you in the helper app.                                                       |
| `waiting`   | Held, with the `reason`: over the budget, signed out, the account is halted, or waiting for you to tap Post at the time (`remindAt`). |
| `posting`   | You tapped Post; it is going out, or being checked on your profile.                      |
| `scheduled` | In LinkedIn's own scheduler for `scheduledAt`.                                           |
| `posted`    | Live, and seen on your own profile. `url` is the post; `text` is what went.              |
| `failed`    | Not posted, or not showing on your profile, with the `reason`. Check LinkedIn before you send it again. |
| `cancelled` | You cancelled it in the helper app.                                                      |

What Udyoga does with an answer: the studio draft shows the state. A
`posted` draft is marked posted on that day, with a link to the post. To
send a `failed` or `cancelled` draft again, press **Send to helper**
again; it goes as a new post with a new `id`.

## Privacy

- Only items the helper app chose to pass on reach Udyoga. A helper app
  should write career items only. It should never write a friend's chat.
- The folder is in your own user's app data, on your own computer. Udyoga
  sends nothing from it anywhere.
- Once a thread is imported, it is part of your Udyoga data. It syncs with
  Udyoga's own sync, like any thread you log by hand.
- Udyoga deletes read files and rejected lines after 30 days.
- Messages in `outbox/` hold only what you wrote and who it is for. The
  helper app sends nothing until you press Send in it.
- Posts in `outbox/` and their files hold only what you wrote. The helper
  app posts nothing until you tap Post in it.
