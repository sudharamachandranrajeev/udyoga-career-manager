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
