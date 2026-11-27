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

| Folder      | Who writes it    | What is in it                                                       |
| ----------- | ---------------- | ------------------------------------------------------------------- |
| `inbox/`    | the helper app   | Files waiting to be read.                                           |
| `tmp/`      | the helper app   | Files still being written. Udyoga never reads this folder.          |
| `done/`     | Udyoga           | Files Udyoga has read. Kept for 30 days.                            |
| `rejected/` | Udyoga           | Lines Udyoga could not read, with the reason. Kept for 30 days.     |

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

| Kind                 | Status                                                              |
| -------------------- | ------------------------------------------------------------------- |
| `message`            | Imported.                                                           |
| `job_alert`          | Reserved. Skipped for now.                                          |
| `application_status` | Reserved. Skipped for now.                                          |
| `invite_accepted`    | Reserved. Skipped for now.                                          |
| `profile_view`       | Reserved. Skipped for now.                                          |

Udyoga skips any other kind. It also skips any line where `v` is not `1`.
It does not guess what those lines mean. They stay in the file under
`done/`.

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

## Idempotency

A helper app can write the same item again, for example after a restart.
This is safe:

- Udyoga skips a message whose `id` is already in the thread.
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

## Privacy

- Only items the helper app chose to pass on reach Udyoga. A helper app
  should write career items only. It should never write a friend's chat.
- The folder is in your own user's app data, on your own computer. Udyoga
  sends nothing from it anywhere.
- Once a thread is imported, it is part of your Udyoga data. It syncs with
  Udyoga's own sync, like any thread you log by hand.
- Udyoga deletes read files and rejected lines after 30 days.
