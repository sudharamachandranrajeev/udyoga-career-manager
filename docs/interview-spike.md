# Interview simulator: I0 spike

> **Updated for I1 (2026-11-19).** The transcriber is now Moonshine through
> sherpa-onnx, and `whisper_ggml` and its FFmpeg are gone. See
> [I1: speech-to-text without FFmpeg](#i1-speech-to-text-without-ffmpeg) at
> the end. The I0 figures below are kept as measured.

This page records what the I0 spike found. The spike puts every plugin the
interview simulator needs into one build. It then measures how fast and how
big the result is, and checks that nothing goes to the network.

Measured on 2026-11-19 on a Linux laptop: Intel Core i5-1145G7 (4 cores,
8 threads), 16 GB of memory, no GPU used. Phones were not measured; only the
Android build was checked.

## What was added

| Need | Package | Notes |
| --- | --- | --- |
| Microphone | `record` 7.2 | 16 kHz mono PCM, kept in memory. |
| Speech detector | `sherpa_onnx` 2.0.2 + Silero VAD | |
| Interviewer voice | `sherpa_onnx` 2.0.2 + Kokoro-82M (int8) | Replaces Piper: see below. |
| Transcriber | `whisper_ggml` 2.10 | base.en or small.en, chosen in the lab. |
| Camera | `camera` 0.12 + `camera_desktop` 2.0 | CameraX on Android, GStreamer on Linux. |
| Face box | `flutter_litert` 4.2 + BlazeFace short-range | Replaces `face_detection_tflite`: see below. |
| Playing the voice | `audioplayers` 6.8 | Plays a temporary WAV, deleted after. |

No model ships with Udyoga. **Settings → Developer → Interview lab** lists
each model with its size, source and licence. A model downloads only when
you press Download and confirm. It comes from the official URL and is
checked against a pinned SHA-256 and size. It is kept in the app's data
folder (never synced), and Delete removes it.

| Model | Download | On disk | Licence | From |
| --- | --- | --- | --- | --- |
| Kokoro-82M int8, British English lexicon | 132.4 MB | 148.8 MB | Apache-2.0 | k2-fsa/sherpa-onnx releases |
| Silero VAD | 0.6 MB | 0.6 MB | MIT | k2-fsa/sherpa-onnx releases |
| Whisper base.en (ggml) | 148.0 MB | 148.0 MB | MIT | huggingface.co/ggerganov/whisper.cpp |
| Whisper small.en (ggml) | 487.6 MB | 487.6 MB | MIT | huggingface.co/ggerganov/whisper.cpp |
| BlazeFace short-range (float16) | 0.2 MB | 0.2 MB | Apache-2.0 | storage.googleapis.com/mediapipe-models |

The Kokoro archive is 183 MB unpacked. The manager deletes the parts the
voice does not use (Chinese dictionaries, the US lexicon, espeak-ng data),
which leaves 148.8 MB.

## Plugins that were replaced

**`face_detection_tflite` → `flutter_litert` + BlazeFace, decoded in Dart.**
Its `initialize()` always loads `mobilefacenet.tflite`, a face-embedding
(identity) model. Rule 4 of the plan forbids identity recognition, so the
package cannot be used as it is. It also bundles 30.7 MB of model files and
an 18.6 MB OpenCV library into every build. The replacement runs the same
BlazeFace short-range model through `flutter_litert` (the LiteRT runtime,
no Google Play services). It decodes the 896 anchors and runs non-maximum
suppression in about 80 lines of Dart (`lib/vision/blazeface.dart`). The
model is downloaded like the others, so nothing ships in the app.
`flutter_litert`'s desktop LiteRT "CompiledModel" runtime and WebGPU
accelerator (27 MB) are turned off in `linux/CMakeLists.txt` and
`windows/CMakeLists.txt`; the classic interpreter is all the lab needs.

**Piper → Kokoro (same `sherpa_onnx` engine).** sherpa-onnx 2.0 removed
espeak-ng and piper-phonemize (upstream #4055). Piper voices need espeak-ng
to turn text into phonemes, so under 2.0 they make no sound. The test
failed with "Failed to convert … to token IDs". The other ways out are worse:

- Stay on sherpa_onnx 1.13: it links espeak-ng, which is GPL-3.0, into an
  MIT app.
- Bring an outside phonemizer: same licence problem.
- Pocket TTS: its ONNX export is for non-commercial use only.

Kokoro-82M v1.0 int8 ships with a 192,000-word British English lexicon, so
it needs no espeak-ng. Its licence is Apache-2.0, and voice 21 is a British
English voice. One cost: a word missing from the lexicon is skipped. Of 37
common interview words tried, only "asked" was missing, and the transcript
below shows it dropped ("like each nurse").

## Speed

All figures are the median or the run shown, network off (see below).

**Interviewer voice (Kokoro int8, 4 threads), sentence "Thank you for
coming in. Tell us about a time you improved a process." (3.9 s of audio):**

| Run | Load voice | First audio ready | Whole text |
| --- | --- | --- | --- |
| 1 | 1,382 ms | 1,941 ms | 5,198 ms |
| 2 | 2,780 ms | 3,095 ms | 7,340 ms |
| 3 | 1,210 ms | 1,848 ms | 4,887 ms |

"First audio ready" is counted from the start of synthesis, after loading,
and is the first sentence. The voice is loaded again for every sentence in
this spike. Keeping it loaded for a whole round would save the 1.2 to 1.4 s
load. Synthesis is slower than real time on this CPU (about 1.2×), so I1
should speak sentence by sentence as each one is ready. Online run, same
machine: first audio 1,690 to 1,841 ms.

**Speech detector (Silero VAD) on 10 s of audio:** 48 ms. It found one span,
0.04 s to 9.98 s, in a 10 s answer spoken by the voice.

**Transcriber, 10 s answer (spoken by the Kokoro voice, resampled to 16 kHz),
4 threads, with the filler-keeping prompt:**

| Model | Run 1 | Run 2 | Text |
| --- | --- | --- | --- |
| base.en | 1,538 ms | 1,760 ms | Kept "Umm" and "like"; cut at the 10 s mark. |
| small.en | 5,701 ms | 5,628 ms | Kept "Um" and "like"; cleaner punctuation. |

Both are faster than real time. base.en is about 6× real time and small.en
about 1.8×.

**Face box (BlazeFace short-range, 128×128 input, 2 threads):**

- Webcam (848×480 BGRA through GStreamer): 16.7 frames a second, with the
  finder taking 6.1 to 6.9 ms a frame. The camera itself delivers about 17
  frames a second here, so the finder is not the limit. The first seconds
  showed up to 29 frames a second before the camera settled.
- A still portrait (820×1024): one face found, score 0.948, in 6.0 ms. Nobody
  sat in front of the webcam during the run, so it saw no face.

**Microphone:** the real mic recorded 9.8 s at -28 dBFS RMS (room noise). The
speech detector found no speech, which is correct: nobody spoke. The full lab
ran to the end: record, detect, skip the transcriber, speak.

## App size

| Build | Before (no interview plugins) | After | Growth |
| --- | --- | --- | --- |
| Linux release bundle | 42.1 MB | 87.2 MB | +45.1 MB |
| Android debug APK (3 ABIs) | 250.6 MB | 410.3 MB | +159.7 MB |

The largest Linux additions are ONNX Runtime (27.0 MB), the LiteRT C
library (8.7 MB), sherpa-onnx (5.8 MB) and whisper.cpp (2.8 MB).

Per Android ABI (arm64-v8a) the additions are about 54 MB:

- ONNX Runtime: 22.2 MB.
- FFmpeg libraries pulled in by `whisper_ggml`: 14.9 MB.
- LiteRT and its GPU accelerator: 8.9 MB.
- sherpa-onnx: 5.7 MB.
- whisper.cpp: 2.9 MB.

A release build split per ABI should grow by about this much.

With models (downloaded, not shipped), on top of the app:

- **Lightest working set** (Kokoro, Silero, base.en, BlazeFace): 297.6 MB.
- **With small.en instead of base.en:** 637.3 MB.
- **All five:** 785.2 MB.

## Network-off proof

The spike binary (`tool/interview_spike.dart`, built with
`flutter build linux --release -t tool/interview_spike.dart`) ran inside a
new network namespace (`unshare -rnm`). The namespace held only loopback
and a dummy "uplink" carrying both default routes, so every packet meant
for another machine is counted and dropped. The kernel's own IPv6 chatter
was turned off first, so an idle namespace sends 0 packets. The host's
systemd-resolved and nscd sockets were hidden, so a name lookup could not
leave through the host. Inside the app, an `HttpOverrides` counted and
refused every dart:io HTTP client.

The run covered all of these, with the models already downloaded:

- the voice 3 times;
- the speech detector;
- base.en and small.en twice each;
- the full lab on the real mic;
- the webcam with the face finder for 10 s;
- the still-image face check.

Result: **0 packets out on the uplink, 0 on loopback, 0 HTTP clients
created.** The run finished with exit code 0.

## Telemetry check

- **Dart packages.** The only analytics-type packages in `pubspec.lock` are
  `google_mlkit_commons` and `google_mlkit_text_recognition`. They belong to
  the existing page reader (M6), which asks before it uses them. Nothing in
  `lib/voice`, `lib/vision`, the lab page or the spike imports them.
- **Android.** In `releaseRuntimeClasspath`, every match for
  `play-services`, `firebase`, `datatransport` or `mlkit` sits under
  `google_mlkit_commons` or `google_mlkit_text_recognition`. No new plugin
  brings in Firebase, Crashlytics, Sentry, Google Play services or
  datatransport.
  - `camera_android_camerax` adds CameraX and Guava.
  - `whisper_ggml` adds `ffmpeg_kit_flutter_new_min` (LGPL-3.0).
  - `flutter_litert` uses its bundled LiteRT, not Play services.
- **Linux libraries.** The word "telemetry" appears in two local classes:
  ONNX Runtime's Telemetry class, which does nothing on Linux, and LiteRT's
  TelemetryProfiler, which profiles locally. Every URL in the new `.so`
  files is a documentation link.

## Build notes

- `whisper_ggml` pins NDK 29. `android/build.gradle.kts` builds it with the
  app's NDK (28.2) instead, so one NDK is enough. The Android build passed
  with every plugin.
- On Linux, `whisper_ggml` converts audio with the `ffmpeg` command-line
  program, so `ffmpeg` must be installed. On Android it uses its bundled
  FFmpegKit.
- `flutter_litert` downloads its LiteRT Android libraries from
  dl.google.com while building. This happens at build time only, not in the
  app.

## Open questions

1. **Voice speed.** Kokoro takes about 1.8 s to the first sentence on this
   laptop and is slower than real time. I1 should keep the voice loaded and
   speak sentence by sentence. On mid-range phones it may be too slow.
   Smaller voices were not measured: the sherpa ljspeech VITS and Matcha
   voices for 2.0 are US English only.
2. **The plan said Piper.** Piper cannot run on sherpa-onnx 2.0 without a
   GPL phonemizer. Is Kokoro (Apache-2.0, 132 MB download) acceptable as
   the default voice? *Answered in I1: yes, Kokoro is the default.*
3. **ffmpeg.** `whisper_ggml` needs the `ffmpeg` program on Linux and adds
   about 15 MB of FFmpegKit (LGPL-3.0) per Android ABI. It is used only to
   convert audio we already have as 16 kHz PCM. Should I1 call whisper.cpp
   with PCM directly, through a small fork or a different binding?
   *Answered in I1: Moonshine through sherpa-onnx replaced it; see below.*
4. **Windows.** The LiteRT CompiledModel runtime is turned off in
   `windows/CMakeLists.txt` too. The Windows build was not tested.
5. **Phones.** No timing was taken on Android. The first phone run should
   repeat the lab and record the same figures.

## I1: speech-to-text without FFmpeg

Decided after the I0 review: drop FFmpeg. First try sherpa-onnx's own
offline recognizer, fed 16 kHz samples straight from memory. Keep it only
if fillers survive and 10 s of speech is written down in under about 2 s.

**Result: both checks pass, so `whisper_ggml` is removed.** The transcriber
is Moonshine base (English, quantized, 2026-02-27 release) through
sherpa-onnx 2.0.2, which was already a dependency. No temporary WAV, no
converter, no new native library.

Same laptop as above, 4 threads, the model kept loaded (load time shown
apart). Two 10 s clips spoken by the Kokoro voice: clip A is the I0 answer,
clip B is dense with fillers ("Uh, so, um, the main thing was the rota. Um,
we had, uh, three people off sick, and I, like, rang round the bank staff.
Uh, by lunchtime we were, um, fully covered again.": 3 "um", 3 "uh",
1 "like").

| Model | Download | Load | 10 s, clip A | 10 s, clip B | Fillers kept in clip B |
| --- | --- | --- | --- | --- | --- |
| Moonshine base, sherpa-onnx (chosen) | 111.3 MB | 566 ms | 349–457 ms | 331–429 ms | 3 of 3 "um", "like"; "uh" as "er" or lost |
| Moonshine tiny, sherpa-onnx (lighter option) | 29.9 MB | 353 ms | 200–292 ms | 193–286 ms | 3 of 3 "um", "like"; "uh" lost |
| Whisper base.en int8, sherpa-onnx | 208.6 MB archive | 487 ms | 1,170–1,192 ms | 1,252–1,473 ms | 1 of 3 "um", "like" |
| Whisper tiny.en int8, sherpa-onnx | 118.1 MB archive | 264 ms | 641–706 ms | 620–634 ms | 3 of 3 "um", 1 of 3 "uh", "like" |
| whisper.cpp base.en via FFmpeg (I0) | 148.0 MB | – | 1,538–1,760 ms | not run | "Umm", "like" (clip A) |

Ranges are 2 to 3 runs; the Moonshine rows include runs inside the release
app (`tool/interview_spike.dart`). Moonshine base is 20 to 30 times faster
than real time here and keeps "um" and "like" without a prompt (sherpa's
Whisper takes no initial prompt, which is why it tidies fillers away).
Kokoro's "uh" is an odd sound, so its loss may be the voice more than the
transcriber; real speech should be checked. The filler count is labelled
approximate in the app for this reason. The English Moonshine models are
MIT; Moonshine's other languages are under a non-commercial licence and are
not offered.

Clip A, Moonshine base: "In my last role, I led the morning handover on a
busy ward. Um, we were missing key details. So I brought in a short
checklist and, like each nurse to read back the plan, with the". The gap
after "like" is the voice: Kokoro skipped "asked", which is not in its word
list (see below).

### What changed with it

- `whisper_ggml` is removed, with FFmpegKit (about 15 MB of LGPL-3.0
  libraries per Android ABI) and the NDK 29 override in
  `android/build.gradle.kts`. Linux no longer needs the `ffmpeg` program.
- Linux release bundle: 73.6 MB, down from 87.2 MB in I0 (whisper.cpp and
  its helpers are gone).
- Model sizes: the lightest working set for a spoken round (Kokoro, Silero,
  Moonshine base) is 290.7 MB on disk, against 297.6 MB with whisper.cpp
  base.en. With Moonshine tiny it is 193.7 MB.
- The lab offers to delete the old Whisper models if they are still on the
  device.

### Kokoro's missing words

Kokoro's word list has "task" and "ask" but not "tasks" or "asked", and a
missing word is skipped. A spoken round now builds the missing forms of
every question's words from their base word and the English suffix rules
(plural and third-person "-s", "-ed", "-ing"; `lib/voice/lexicon.dart`),
and loads them as a second word list. Checked by writing the voice down
again with Moonshine:

- Without: "Tell us about a time you were to take on extra, and how you,
  thus."
- With: "Tell us about a time you were asked to take on extra tasks, and
  how you prioritize the stakeholders."

### The spoken round on this laptop

`tool/spoken_round_check.dart` runs a two-question round with the real
engines and the real microphone path (`record`, live Silero VAD, Moonshine
on each stretch as it ends, Kokoro kept loaded):

| Step | Time |
| --- | --- |
| Load the voice (with the extra word list) | 1,405–1,646 ms |
| Load the speech detector and transcriber | 528–725 ms |
| Make question 1 (5.5 s of speech, 2 sentences) | 5.9 s |
| Question 2 ready after 3 s of the answer to question 1 | 0 ms wait |
| From the end of the answer to the transcript | 14–15 ms |

The transcript is ready almost at once because each stretch of speech is
written down while the candidate is still talking. The speech detector
ended each answer itself after 4 s of silence.

Two runs:

1. **Room microphone, nobody speaking.** The laptop's own speakers were too
   quiet for the mic to pick up a played answer (peak about -50 dBFS, room
   noise). The round handled it: no speech found, nothing saved, "No speech
   was heard. Try again, or type your answer." Re-run with a person
   speaking before a release.
2. **The answer played into a PipeWire null sink**, read by the app as its
   microphone (`PULSE_SOURCE`): a 22.5 s answer, clips A and B with a 2.5 s
   gap. The transcript kept 4 "um", "like" twice and three "uh" (as "ah").
   Delivery: 190 words a minute (above the usual range: the voice is fast),
   1 pause, longest 2.4 s, 8 fillers (approximate), 1.7 s before starting,
   0:22 long. Both takes were written to the take folder and deleted with
   it.

Making question 1 takes longer than reading it, so the app starts making it
as soon as the round opens; the "Ask me" button follows the "what this
question tests" text, which gives it time. Later questions are always made
during the previous answer.

### Android builds

Release APKs are now split per ABI (`--split-per-abi`), so each carries one
copy of ONNX Runtime and sherpa-onnx instead of three. The 64-bit ARM APK
keeps the `-android.apk` name, so older versions' updaters still find it;
`-android-armeabi-v7a.apk` and `-android-x86_64.apk` are the others, and the
updater fetches the one for the phone. No phone timing yet (open question 5
stands).

## I2: follow-ups, panels and stages

### How a follow-up is picked

At the start of a round the interviewer has a plan for each question: what
it tests, which parts of an answer to listen for, and its own follow-ups.
With an AI the plan is written by the AI the user chose, from the questions
alone (no profile, no answers). Without one, or if the AI fails, built-in
plans by question kind are used: all six parts for "tell us about a time"
questions, fewer for values, situational and technical questions, none for
settlers, strengths and "do you have any questions".

The six parts are the situation, what the speaker did themselves, a
measure, the result, what they learned and who else was involved. After
each answer a matcher on the device reads the transcript (and any earlier
follow-up answers to the same question) and lists what is missing. It is
deterministic: no AI is needed to choose the follow-up. "What you yourself
did" needs at least two "I did" actions, or "my role was", "I took the
lead" and the like; a run of "we" does not count. A measure is any number,
percentage, count, check or feedback.

The follow-up asks about the first missing part, using the plan's own
wording first, then the built-in one. Never more than two per question,
never the same part or the same wording twice. Parts missed in the
previous stage are asked about first.

### Panels and levels

| Panel | Says after an answer | Gap after an answer | Gap before a follow-up |
| --- | --- | --- | --- |
| Friendly | one of three warm lines | 1 s | 1 s |
| Neutral | "Thank you." | 2 s | 1.5 s |
| Probing | "Thank you." (one extra follow-up) | 1.5 s | 1 s |
| Quiet | nothing | 4 s | 3 s |

The quiet panel's silences are deliberate: the screen says "The panel is
writing notes. Silence is normal." (methodology rule 7).

| Level | Follow-ups | Time for an answer | Interrupts |
| --- | --- | --- | --- |
| 1 Rehearsal | 0 | untimed | no |
| 2 Gentle | 1 | 1.5 × usual | no |
| 3 Standard panel | 2 | usual | no |
| 4 Realistic | 2 | usual | 15 s after the time |
| 5 Tough | 2 | 0.75 × usual | at the time |

At levels 4 and 5 an answer over time is stopped with "Thank you. I am
going to stop you there so we keep to time. Could you sum that up in one
sentence?", and the user has 20 s for a one-sentence wrap-up. No follow-ups
come after an interruption.

The end of an answer is now a setting, 3 to 10 s of silence (5 s by
default). A pause shorter than that never ends the answer.

### Stages

A process is a list of stages, each with its own panel, times, a settler
question and the opening "I may interrupt you now and then to keep us to
time". The three templates (NHS-style, Civil Service-style, private sector)
use generic, self-written questions and can be edited. Exercise stages
(in-tray, a spreadsheet task set out in text, reasoning questions labelled
"Practice format, not the real test") and presentation stages (preparation
clock, then the presentation as a timed answer) come before the spoken
part. Each stage is saved as its own practice round. Progress through a
process is kept in memory while the process page is open.

At the end of a stage, "For next time" lists up to three fixes (running
over time first, then the parts missed most, with the latest stage counted
twice) and up to two things to keep. The next stage shows them before it
starts, and its follow-ups go after those parts first.

### One stage on this laptop

`tool/interview_stage_check.dart` runs a three-question screening call
(friendly panel, level 5, answer time 30 s, so 22.5 s at level 5) with the
real engines. The candidate's fictional answers are made with a second
Kokoro voice and played into a PipeWire null sink that the app reads as
its microphone (`PULSE_SOURCE`), as in I1. Two runs gave the same
results, within 0.5 s:

- **Opening and settler.** The opening (greeting, "this is the screening
  call", the interrupt script) and the settler were said as one turn; the
  microphone opened 22 s after the round started. No follow-up on the
  settler; the panel said "Thank you, that is really helpful."
- **A short answer with a 3.5 s pause to think in the middle.** The pause
  did not end the answer: the transcript has both halves. The answer
  ended 5.5 s after the speaker stopped (the 5 s setting plus the speech
  detector's tail).
- **Follow-ups.** The answer had no measure and no learning. The panel
  asked "Thank you. How did you measure this?", then "Thank you. What did
  you learn?", and stopped at two. With the follow-up answers, all six
  parts were covered.
- **The interruption.** A 31 s answer to the third question was stopped at
  22.5 s, mid-sentence; the panel asked for a one-sentence wrap-up, and the
  wrap-up was transcribed in full.
- **Carry-forward.** "For next time": lead with the result so the answer
  fits the time; say how you knew it worked; close with what you learned.
- Transcription slip: "We counted the complaints" came out as "100%
  accounted the complaints". The measure was still found (from "6 to 1").
- The three take files were deleted with the take folder at the end.

## I3: panel scoring and the debrief

### Role profiles and frameworks

A role profile holds the criteria a panel agrees before it meets anyone
(`lib/domain/interview_scoring.dart`). The user's AI reads a pasted advert
and person specification into criteria (text, essential or desirable,
kind, how assessed, a question); only the advert is sent. The reply is
parsed strictly: blank and repeated criteria are dropped, unknown kinds
read as experience, and nothing missing is invented. Without an AI the
criteria are typed in. Every criterion stays editable.

The round asks the essential criteria assessed at interview first, then
the desirable ones (at most eight). Criteria assessed only by the
application or a test are not asked aloud and never count against the
candidate. Each question is tagged with its criterion, and its follow-up
plan gains a probe worded for the criterion.

Five frameworks carry their own scale and anchor text, written for
practice and marked "How panels commonly score", each with a short public
source note: NHS values (N/O, then 1 to 4), NI HSC values-based and HSE
Ireland competencies (0 to 3 against agreed key elements), Civil Service
Success Profiles (1 to 7, commonly 4 or more on every behaviour) and a
private-sector rubric (1 to 4). Their example values, behaviours and
competencies are generic; the employer's own list wins.

### Scoring only what was said

The AI scores each answer per criterion with a quote from the transcript;
only transcripts and criteria are sent, never the profile. A deterministic
check backs it up: the quote must appear in that answer's transcript
(ignoring case, punctuation and fillers, three words or more, parts
separated by an ellipsis in order). A score with a missing quote, a level
off the scale or a criterion the question does not test is dropped, and
the criterion reads as not observed. The raw scoring is saved with the
round and checked again each time the debrief opens.

### The debrief

Coverage comes first: each criterion is evidenced, thin or missing, and a
missing essential assessed at interview is flagged as likely to make the
candidate unappointable. Then each scored criterion with its level, the
anchor text and the quoted line; one strength and one task-level fix per
answer (no percentages, no confidence score); and recovery lines for weak
moments. Without an AI, coverage comes from the I2 element matcher: an
example with the speaker's own actions and how it ended is evidence; some
of the parts is thin; nothing, or a bare claim, is missing. A round with no
profile uses each question's aim as a desirable criterion.

A good answer can be saved to the story bank as a draft, source
"practice", with the criteria it evidenced (a new `criteria` column).

### I2 follow-ups

- **Process progress** is saved in `career_processes` (schema 9): the
  edited process, each stage's round, what it covered and the carry-forward
  as it stood. Text only; it syncs like the rounds. A stage started and left
  unfinished goes on in the same round.
- **Spoken follow-ups** keep their transcript and delivery; the review now
  shows delivery for each one. Audio handling is unchanged.
- **Speaking sooner.** The opening is already made and played a sentence
  at a time. `tool/voice_timing_check.dart` timed the screening call's
  opening and settler (14.8 s of speech) on this laptop: the first audio is
  ready after 2.7 s and the microphone would open at 20.6 s, because Kokoro
  makes speech about 1.4 times slower than it plays. Splitting sentences
  into clauses did not bring the first audio forward (the first sentence is
  already short) and added about 0.6 s overall. Six threads (22.9 s) and
  eight (25.7 s) were slower than four, and two engines making alternate
  sentences gave 4.7 s to first audio and 21.9 s overall. No change was
  made. The opening is made from the moment the round opens, so time spent
  on the "Ask me" screen comes off the wait.

### Live check

With Claude Code (Sonnet), a fictional advert gave six criteria with the
right essential and desirable split and how each is assessed, and the NHS
values framework, in about 4 s. A fictional two-answer round was scored in
about 4 s: the diary answer scored 2 (Good) with an exact quote; the bare
"good team player" claim scored N/O. No quote was dropped. The first run
showed that criteria assessed only by the application were asked and a
test-only essential was flagged; both were fixed.

## I4: the confidence loop with Vidya

### I3 follow-ups

- **Faster start.** The interrupt script is said only at levels 4 and 5,
  the levels that interrupt. The stage's name is on the screen, not said.
  The interviewer's fixed lines are kept in `voice-cache/` in the app
  support folder once made:
  - the greetings and acknowledgements;
  - the interrupt and wrap-up lines;
  - the built-in follow-ups;
  - the template settlers.

  Each clip is keyed by a SHA-256 of the voice, speed, model and text, so
  only hashes are on disk. A sentence is cached only when it is one of
  these fixed lines. Questions, answers and anything the user typed or
  edited are never cached.

  `tool/voice_timing_check.dart` timed the screening call's opening and
  settler on this laptop, best of two runs:

  | Opening | Speech | First audio | Mic opens |
  |---|---|---|---|
  | I3, every level (greeting, stage name, script) | 14.4 s | 2.9 s | 20.4 s |
  | I4, level 3, cold | 5.2 s | 2.7 s | 9.1 s |
  | I4, level 3, cached | 5.2 s | 0.01 s | 5.3 s |
  | I4, level 5, cold | 12.8 s | 2.8 s | 18.4 s |
  | I4, level 5, cached | 12.8 s | 0.01 s | 12.8 s |

  From the second round on, the microphone opens as soon as the opening has
  been said.
- **Feedback wording.** The scoring and review prompts forbid talk of
  scores, levels or the scale in a strength or fix. `taskLevelText` backs
  them up with a deterministic check:
  - A sentence like "Add a measure, to move toward a 3" is cut back to the
    action before it.
  - A sentence with nothing task-level left is dropped.
  - An empty fix falls back to the debrief's own wording.

  Counts such as "2 minutes" or "three points" are left alone.
- **Whole-process summary.** One page per process combines every stage's
  debrief. It lists each criterion with the stages that evidenced it or
  touched on it, or says no stage did. It then gives the top three fixes:
  missing essentials first, then the fixes that came up most, with later
  stages counting more.

### Nerves

- Before and after each round (spoken, typed or a stage), the user can rate
  their nerves from 1 (calm) to 5 (overwhelmed) with one tap. Rating is
  optional, and tapping the same chip again clears it.
- The ratings are stored with the round (`nerves_before` and
  `nerves_after`, schema 10).
- The Interview page shows the trend: a small chart of before (filled)
  and after (hollow) ratings, and one line in words. The ratings are never
  scored.

### Drills (Udyoga makes them, Vidya runs them)

The drills go out on their own plan row, `udyoga.interview-drills`, in
`bridge_study_plans`. It is a vidya-curriculum v1 plan:

- **Cards** in the "Interview drills" deck, each with a stable id:
  - the settler (`udyoga.drill.settler`);
  - each story in three bullets: the situation, what I did, the result
    (`udyoga.drill.story.<id>`);
  - seven recovery lines with when to use them
    (`udyoga.drill.recovery.<key>`);
  - the user's own questions for the panel (`udyoga.drill.questions`).
    The set starts from a generic bank by stage and is edited on the
    Interview page.
- **Checklists:**
  - the pre-interview routine (the day before, 30 minutes before,
    5 minutes before, in the room), from methodology 4.2;
  - the video-interview setup.
- **The optional "I'm excited" note.** It is off by default and always
  labelled "Small effect in studies; try it, keep it if it helps."

Study-plan story cards now carry an id too (`udyoga.story.<id>`).

### Vidya changes

- **Updates in place.** A plan card's id is kept as the card's `ref`
  (Vidya schema 5). When a plan comes again:
  - the card with that ref is updated in place and keeps its schedule and
    reviews;
  - a card deleted in Vidya stays deleted;
  - a card from before ids, matched by deck and front, takes the id.
- **Results back.** The progress Vidya sends for each plan now has a
  `drills` list:
  - each of the plan's cards rehearsed at least once, with the day of the
    last review, the user's rating of it and how many times;
  - each of the plan's checklist items ticked off.

  The user's own cards are never included. Readers that do not know the
  field ignore it, so brahma_core is unchanged. Udyoga shows the results
  on the Interview page.

### Confidence first

The Interview page now opens with "What you're ready for":

- the criteria the user's answers evidenced in the last ten rounds;
- the stories they have rehearsed in Vidya;
- the nerves trend.

The ways to practise, the drills and the gaps come after it.

## I5: the camera coach

### I4 follow-ups

- **Vidya: cards a plan no longer sends.** When a plan comes again
  without a card it sent before (the story was deleted in Udyoga), Vidya
  sets the card aside instead of deleting it:
  - its schedule and reviews are kept;
  - it is never due, and Review counts it apart ("set aside");
  - if the plan sends it again, it comes back as it was.

  Cards now record the plan they came from (Vidya schema 6, filled in for
  plans already received through sync). One part of a long plan never
  sets anything aside.
- **Vidya: progress back more often, not more noisily.** A review grade
  no longer writes a report. The report goes when a review session ends,
  when Vidya opens and when it comes back to the front, at most once
  every ten minutes. A request inside the ten minutes runs when they are
  over, so nothing is lost. A report still writes only when something
  changed.
- **Udyoga: the voice cache goes with the voice.** Deleting the
  interviewer voice in the lab also deletes its ready-made clips. The
  lab shows the cache's size with a **Clear voice cache** button.

### What it does

Plan rule 4 binds all of it. The camera is off at the start of every
round. Turning it on is one button, and a red **Camera on** pill shows
while it runs; tapping the pill turns it off. Whether it was on is not
saved. (Since I6 the self-view and hint switches are remembered on the
device; see the I6 section.)

Each frame is read in memory, turned into a few numbers and dropped:

- the largest face box from BlazeFace;
- how many faces;
- the mean brightness of the face box and of the rest of the picture.

No frame and no number is written to disk or the database, sent or
synced. Nothing reads identity, expression or the eyes. Nothing is
scored.

**The setup check** (before a round or stage, and on its own from the
Interview page, "Check my video setup") reads the last second of frames.
Medians smooth out a bad frame. Each check shows a green tick or one
plain tip:

| Check | Fine when | Tip otherwise |
| --- | --- | --- |
| Face in the picture | a face in at least half the frames, its centre within 0.15 of the middle across | "No face in the picture yet…" (or "very dark" when the picture is); "Move so your face is in the middle of the picture…" |
| Head and shoulders | face box 0.18 to 0.5 of the picture's height | "Move closer…" / "Move back a little…" |
| Light | face at least 70 of 255, no more than 225, and the rest of the picture no more than 45 brighter | "The light is behind you… Move the light in front of you…"; "in shadow"; "very bright" |
| Camera height | face centre 0.28 to 0.6 down the picture, head not at the top edge | "Raise the camera to eye height…" / "Tilt the camera down a little…" |
| Steady picture | the face centre moves less than 0.025 (spread over the last second) | "Rest the camera or phone on something steady." |

The tips never say left or right, because previews are mirrored.

**During a round**, if switched on (both are off by default):

- **Out of the picture.** After more than 3 s with no face, a quiet note
  says "You have moved out of the picture." It clears when a face is
  back.
- **"Looking at the lens".** This comes only from where the face box
  sits, with no gaze or iris model. When the face sits well to one side
  or low for most of two seconds, the note suggests putting the panel's
  window under the camera. It says the habit is optional and never
  scored.

**Self-view** is a switch, on by default once the camera is on, because
some people find seeing themselves distracting. The checks work either
way.

**At the end of the round** the camera turns itself off. The finished
screen may list **Setup notes**: the tips that were still open when the
round started, marked "Information only: not part of any score, and not
saved". The debrief, the answers and the scores are the same with or
without the camera. A test runs the same round both ways and compares
everything saved.

Everything works with the camera off, and no other feature needs it.

### Platforms

- **Linux:** `camera_desktop` (GStreamer), BGRA frames. Tested here.
- **Android:** `camera` (CameraX), YUV frames. The camera permission was
  already in the manifest and is asked for when the camera first opens.
  Not run on a phone.
- **Windows:** `camera_desktop` streams BGRA there too, and the code path
  is the same as Linux. It was written but not built or run (no Windows
  machine here).

### On this laptop

`tool/camera_coach_check.dart` runs the coach with the real webcam and
the real face finder. `tool/camera_setup_live.dart` shows the real setup
card with the webcam on.

**The webcam, for real.** It ran at 848x480 and about 16.7 frames a
second, and the face finder took 6.2 to 7.6 ms a frame. Nobody was in
front of the camera, and the room was dark (brightness 11 to 12 of 255).
The check said so: "The picture is very dark, so no face shows. Turn on
a light in front of you…". The setup card rendered with the live preview
and no Flutter errors.

**A still picture, fed as camera frames.** The picture was a
public-domain 1864 portrait photograph from Wikimedia Commons. It was
kept outside the repository and drawn into a 640x480 frame five ways.
The real face finder ran on each, 5.5 to 6.3 ms a frame:

| Setup | Face box (left, top, w x h) | Face / rest brightness | Result |
| --- | --- | --- | --- |
| As it is | 0.35, 0.26, 0.26x0.34 | 107 / 107 | all five ticks |
| Small in a big frame | 0.42, 0.42, 0.13x0.17 | 117 / 92 | "Move closer…" |
| Cropped close | 0.22, 0.22, 0.53x0.70 | 102 / 144 | "Move back a little…" |
| Darkened, bright surround | 0.36, 0.26, 0.25x0.34 | 36 / 132 | "The light is behind you…" |
| Empty frame | none | 90 / 90 | "No face in the picture yet…" |

For the away note, the picture was shown for 1 s, then an empty frame
for 4 s, then the picture again, with 15 fps time stamps. The note
showed at seconds 4 and 5 and was gone at 6.

**Nothing written.** Both runs listed the app support folder and the
system temp folder before and after: no file was added.

## I6: local model, live captions, offline practice

### I5 follow-up: the camera coach's switches

Self-view, the round hints and the lens hint are now remembered on this
device, in a local setting (`udyoga.interview.coach`). Local settings are
never synced. Only the three switches are stored, never a frame or
anything the camera saw. The camera itself still starts off in every
session and every round. Tests check all three points.

### The interview AI on Ollama

The **On this device** card on the Interview page has a switch: "Use a
local model (Ollama) for the interview AI". With it on, every interview
AI task goes to Ollama on this computer. That covers the question plan,
reading an advert into criteria, scoring, the round review and the
follow-up wording. The cloud AI is not used.

- **Where Ollama is.** If Settings → Ask AI already points at a local
  server (brahma_core's `HelpAi.local`), that host and model are used.
  Otherwise Udyoga has its own host and model fields. The default host is
  `http://localhost:11434`.
- **Structured answers.** Each call goes to `/api/chat` with the task's
  JSON schema in Ollama's `format` field, `stream: false` and
  temperature 0. A reply that breaks the schema is asked again once. The
  scores then go through the same `verifyScores` check as cloud scores: a
  score stands only when its quote is in the transcript.
- **Suggested models.** `qwen2.5:7b` (about 4.7 GB, needs about 8 GB of
  free memory) and `llama3.2:3b` (about 2 GB). The card says plainly that
  a small model plans and scores less reliably than a large cloud model.
- **Problems are said plainly.** "Ollama is not running at …" and "the
  model … is not on this computer. To get it, run: ollama pull …".
  While the local model is chosen but not ready, the built-in follow-ups
  and checks are used. There is no silent fall-back to the cloud.
  Udyoga never installs Ollama, starts it or pulls a model.

### Live captions

The transcript now grows while you speak. While the speech detector hears
speech, the open stretch is transcribed again every 1.2 s, up to its last
20 s. The text appears under the closed stretches already transcribed.
When the stretch closes, its final text replaces the partial one. The
panel's spoken lines are captioned as they are said.

Captions are on by default. They have their own switch in the round's app
bar and on the Interview page. The text size goes from 100% to 200%
(default 125%), with a preview. The newest four lines stay in view, and
screen readers hear the caption as a live region.

### Offline interview practice

One switch on the Interview page: **Offline interview practice**. With it
on:

- Only what is on the device is used: Kokoro, Silero, Moonshine and
  BlazeFace, plus Ollama when it runs on this computer. Without Ollama,
  the built-in plans and the matcher are used. A local model on another
  machine is refused. The cloud AI is never chosen.
- Every interview screen shows an **Offline** badge in its app bar. While
  the badge shows, the screen holds the app's network guard. This is the
  I0 hook, moved into the app (`lib/domain/offline_guard.dart`):
  - every dart:io HTTP client made while it holds can reach this machine
    only, with no proxy;
  - plain sockets to another machine are refused;
  - each refusal is counted.
  Leaving the last interview screen, or turning the switch off, releases
  it.
- Model downloads are turned off with a message, on the round page, in
  the lab and for the face finder. The model manager also refuses on its
  own.

**A limit.** An HTTPS client made *before* the guard held, and kept
across screens, is not covered by the hook. Dart's TLS sockets do not go
through `IOOverrides`. The interview path does not use such a client
while offline is on, because the cloud adviser and downloads are not
chosen. The hook is the check behind that, not the only barrier.

### Network-off proof, again

`tool/interview_stage_check.dart --offline` runs the I2 stage as offline
practice:

- the guard holds for the whole run;
- a download is tried and must be refused;
- a request to another machine is tried and must be refused;
- after the stage, the debrief is built with no AI;
- Ollama is checked at its default address.

The release build ran inside `unshare -rnm`, set up as in I0 (loopback,
a dummy uplink with both default routes, IPv6 chatter off, the host's
resolver sockets hidden). The answers came from a second Kokoro voice
through a null sink. The packet counts come from the namespace's
`/proc/net/dev`. An idle namespace sent 0 packets, and a test `curl` to
another address was counted on the uplink.

Ollama 0.40.7 (installed here) ran inside the namespace on
`127.0.0.1:11434`, with no model pulled.

**Result:** exit code 0, and **0 packets on the uplink**.
- The stage ran in full: a settler, then question 1 with 2 follow-ups,
  then question 2, which the panel cut off with a wrap-up. Every answer
  ended by the speech detector, except the one cut off.
- The no-AI debrief showed both criteria as Evidenced, with a strength
  and a fix for each answer.
- The download was refused with the message.
- The request to example.com was refused before any packet: 1 refusal.
- 2 HTTP clients were made, both limited to this machine.
- Ollama answered on loopback: "Ollama is running, but the model
  qwen2.5:7b is not on this computer. To get it, run: ollama pull
  qwen2.5:7b". Loopback carried 12 packets during the run, which was the
  `/api/tags` check.
- The recordings were deleted.

**Ollama itself.** At start-up, Ollama's server tried to reach
ollama.com 3 times (a cloud model cache). The namespace stopped it at the
name lookup. That is Ollama's own process, not Udyoga, and the guard
cannot reach it. Someone who wants Ollama fully offline should check
Ollama's own settings.

**Not tried.** No model was pulled (several GB), so local planning and
scoring were not run against a real model. Fake-server tests cover the
request and reply format.
