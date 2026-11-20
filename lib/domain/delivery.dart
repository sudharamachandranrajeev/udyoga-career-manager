/// How a spoken answer was delivered, measured on the device from the
/// transcript and the speech detector's timings: pace, pauses, fillers,
/// how long before the answer started and how long it ran.
///
/// Rule 5 of the interview plan: these are shown against normal ranges,
/// apart from the content feedback, and never as a score. A few fillers and
/// a pause to think are normal.
library;

/// One stretch of speech: when it ran (from the moment the microphone
/// opened, which is when the question finished) and what was said.
class SpokenSegment {
  const SpokenSegment(this.start, this.end, this.text);
  final Duration start, end;
  final String text;
  Duration get length => end - start;
}

/// A measure next to its usual range.
class RangeReading {
  const RangeReading({
    required this.label,
    required this.value,
    required this.usual,
    required this.place,
    this.note = '',
  });

  /// "Pace".
  final String label;

  /// "142 words a minute".
  final String value;

  /// "Usual: 120 to 170 words a minute".
  final String usual;

  /// Where [value] sits against the range.
  final RangePlace place;

  /// Plain words for an outside reading, e.g. "Quicker than most panels
  /// find easy to follow."
  final String note;
}

enum RangePlace { below, within, above }

/// Gaps between stretches of speech this long or longer count as pauses.
const pauseThreshold = Duration(seconds: 1);

/// Approximate filler words. The transcriber drops some and mishears
/// others, so the count is labelled approximate wherever it is shown.
final _hesitation = RegExp(r"\b(u+m+|u+h+|uhm+|e+r+m+|e+r+|h+m+|a+h+)\b");

/// "like" or "you know" used as a filler: next to a comma ("and, like,
/// we…"). "I'd like to" is not counted.
final _discourse = RegExp(r"\b(like|you know)\b");

/// Approximate count of fillers in [text].
int countFillers(String text) {
  final lower = text.toLowerCase();
  var n = _hesitation.allMatches(lower).length;
  for (final m in _discourse.allMatches(lower)) {
    final before = lower.substring(0, m.start).trimRight();
    final after = lower.substring(m.end).trimLeft();
    if (before.endsWith(',') || after.startsWith(',')) n++;
  }
  return n;
}

int countWords(String text) => RegExp(r"[A-Za-z0-9'’]+").allMatches(text).length;

class DeliveryMetrics {
  DeliveryMetrics._({
    required this.words,
    required this.speaking,
    required this.pauses,
    required this.longestPause,
    required this.fillers,
    required this.responseDelay,
  });

  /// From the segments of one answer. [segments] are in time order.
  /// Returns null when nothing was said.
  static DeliveryMetrics? of(List<SpokenSegment> segments) {
    final said = [
      for (final s in segments)
        if (s.length > Duration.zero) s,
    ]..sort((a, b) => a.start.compareTo(b.start));
    if (said.isEmpty) return null;
    var pauses = 0;
    var longest = Duration.zero;
    for (var i = 1; i < said.length; i++) {
      final gap = said[i].start - said[i - 1].end;
      if (gap >= pauseThreshold) pauses++;
      if (gap > longest) longest = gap;
    }
    final text = said.map((s) => s.text).join(' ');
    return DeliveryMetrics._(
      words: countWords(text),
      speaking: said.last.end - said.first.start,
      pauses: pauses,
      longestPause: longest,
      fillers: countFillers(text),
      responseDelay: said.first.start,
    );
  }

  /// Words in the transcript.
  final int words;

  /// From the first word to the last, pauses included.
  final Duration speaking;

  /// Gaps of [pauseThreshold] or longer, and the longest gap of any length.
  final int pauses;
  final Duration longestPause;

  /// Approximate (see [countFillers]).
  final int fillers;

  /// From the end of the question to the first word.
  final Duration responseDelay;

  double get minutes => speaking.inMilliseconds / 60000;

  /// Words a minute over [speaking]; 0 for an answer under two seconds.
  int get wordsPerMinute => speaking < const Duration(seconds: 2) ? 0 : (words / minutes).round();

  double get fillersPerMinute => minutes <= 0 ? 0 : fillers / minutes;

  static RangePlace _place(num v, num low, num high) => v < low
      ? RangePlace.below
      : v > high
      ? RangePlace.above
      : RangePlace.within;

  static String _secs(Duration d) {
    final s = (d.inMilliseconds / 1000);
    return s < 10 ? '${s.toStringAsFixed(1)} s' : '${s.round()} s';
  }

  static String clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  /// The readings, each beside its usual range. The ranges are broad on
  /// purpose: they say what most listeners find easy, not a target.
  List<RangeReading> get readings {
    final wpm = wordsPerMinute;
    final fpm = fillersPerMinute;
    return [
      RangeReading(
        label: 'Pace',
        value: wpm == 0 ? 'Too short to measure' : '$wpm words a minute',
        usual: 'Usual: 120 to 170 words a minute',
        place: wpm == 0 ? RangePlace.within : _place(wpm, 120, 170),
        note: wpm == 0
            ? ''
            : wpm > 170
            ? 'Quicker than most panels find easy to note down.'
            : wpm < 120
            ? 'Slower than most speakers; fine if you were thinking it through.'
            : '',
      ),
      RangeReading(
        label: 'Pauses',
        value: pauses == 0
            ? 'No pauses of a second or more'
            : '$pauses of a second or more; longest ${_secs(longestPause)}',
        usual: 'Usual: a few, each under about 4 s',
        place: longestPause > const Duration(seconds: 4) ? RangePlace.above : RangePlace.within,
        note: longestPause > const Duration(seconds: 4)
            ? 'A long pause is fine; saying "let me think" covers it.'
            : '',
      ),
      RangeReading(
        label: 'Fillers (approximate)',
        value: '$fillers ("um", "uh", "like")${minutes >= 0.5 ? ', ${fpm.toStringAsFixed(1)} a minute' : ''}',
        usual: 'Usual: up to about 6 a minute; a few are normal',
        place: minutes >= 0.5 && fpm > 6 ? RangePlace.above : RangePlace.within,
        note: minutes >= 0.5 && fpm > 6 ? 'A short silent pause can take the place of a filler.' : '',
      ),
      RangeReading(
        label: 'Time before you started',
        value: _secs(responseDelay),
        usual: 'Usual: up to about 5 s',
        place: responseDelay > const Duration(seconds: 5) ? RangePlace.above : RangePlace.within,
        note: responseDelay > const Duration(seconds: 5)
            ? 'Taking time is fine; a holding line ("That\'s a good question…") helps.'
            : '',
      ),
      RangeReading(
        label: 'Answer length',
        value: '${clock(speaking)} · $words words',
        usual: 'Usual for a competency answer: 1 to 3 minutes',
        place: _place(speaking.inSeconds, 60, 180),
        note: speaking.inSeconds < 60
            ? 'Short for a competency question: there may be room for the result.'
            : speaking.inSeconds > 180
            ? 'Long: panels often stop listening after about three minutes.'
            : '',
      ),
    ];
  }
}
