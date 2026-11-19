/// Fills gaps in the interviewer voice's word list.
///
/// Kokoro under sherpa-onnx 2.0 has no espeak-ng, so it can only say words
/// in its British English lexicon and silently skips the rest. The lexicon
/// often has a word but not its inflections ("task" but not "tasks", "ask"
/// but not "asked"). This builds pronunciations for those from the base
/// word and the English suffix rules, so a question is read in full.
library;

/// Phonemes after which a plural or third-person "-s" is said "-iz".
const _sibilants = {'s', 'z', 'ʃ', 'ʒ', 'ʧ', 'ʤ'};

/// Voiceless endings: "-s" stays "s", "-ed" is "t".
const _voiceless = {'p', 't', 'k', 'f', 'θ', 's', 'ʃ', 'ʧ'};

/// Marks that are not phonemes: stress and length.
const _marks = {'ˈ', 'ˌ', 'ː'};

/// The last real phoneme of a pronunciation (tokens separated by spaces).
String _last(List<String> phones) {
  for (final p in phones.reversed) {
    if (!_marks.contains(p)) return p;
  }
  return '';
}

/// Words of [text] as the voice sees them: lower case, letters and
/// apostrophes.
Iterable<String> lexiconWords(String text) =>
    RegExp(r"[a-z]+(?:'[a-z]+)?").allMatches(text.toLowerCase()).map((m) => m[0]!);

/// A pronunciation for [word] built from [lexicon], or null when no base
/// word is found. [lexicon] maps a word to its phoneme tokens.
List<String>? inflect(String word, Map<String, List<String>> lexicon) {
  List<String>? base(String w) => lexicon[w];

  // Plurals and third person: -ies, -es, -s.
  if (word.endsWith('ies') && word.length > 4) {
    if (base('${word.substring(0, word.length - 3)}y') case final b?) return [...b, 'z'];
  }
  if (word.endsWith('es') && word.length > 3) {
    final stem = word.substring(0, word.length - 2);
    if (base(stem) case final b? when _sibilants.contains(_last(b))) return [...b, 'ɪ', 'z'];
  }
  if (word.endsWith('s') && !word.endsWith('ss') && word.length > 2) {
    final stem = word.substring(0, word.length - 1);
    if (base(stem) case final b?) {
      final l = _last(b);
      if (_sibilants.contains(l)) return [...b, 'ɪ', 'z'];
      return [...b, _voiceless.contains(l) ? 's' : 'z'];
    }
  }
  // Past tense: -ied, -ed, -d.
  if (word.endsWith('ied') && word.length > 4) {
    if (base('${word.substring(0, word.length - 3)}y') case final b?) return [...b, 'd'];
  }
  if (word.endsWith('ed') && word.length > 3) {
    final stems = [
      word.substring(0, word.length - 1), // "prioritised" -> "prioritise"
      word.substring(0, word.length - 2), // "asked" -> "ask"
      if (word.length > 5 && word[word.length - 3] == word[word.length - 4])
        word.substring(0, word.length - 3), // "planned" -> "plan"
    ];
    for (final s in stems) {
      if (base(s) case final b?) {
        final l = _last(b);
        if (l == 't' || l == 'd') return [...b, 'ɪ', 'd'];
        return [...b, _voiceless.contains(l) ? 't' : 'd'];
      }
    }
  }
  // -ing.
  if (word.endsWith('ing') && word.length > 4) {
    final stem = word.substring(0, word.length - 3);
    final stems = [
      stem,
      '${stem}e',
      if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2])
        stem.substring(0, stem.length - 1),
    ];
    for (final s in stems) {
      if (base(s) case final b?) return [...b, 'ɪ', 'ŋ'];
    }
  }
  return null;
}

/// Lexicon lines ("word p h o n e s") for every word of [texts] that is
/// missing from [lexiconText] but can be built from a base word in it.
/// Words that cannot be built are left out (the voice skips them).
String extraLexicon(String lexiconText, Iterable<String> texts) {
  final wanted = {for (final t in texts) ...lexiconWords(t)};
  if (wanted.isEmpty) return '';
  // Only the base words that could matter are split, to keep this quick
  // on the 190,000-word lexicon.
  final known = <String>{};
  for (final line in lexiconText.split('\n')) {
    final space = line.indexOf(' ');
    if (space > 0) known.add(line.substring(0, space));
  }
  final missing = wanted.where((w) => !known.contains(w)).toList();
  if (missing.isEmpty) return '';
  final stems = {for (final w in missing) ..._stemsOf(w)}.intersection(known);
  final lexicon = <String, List<String>>{};
  for (final line in lexiconText.split('\n')) {
    final space = line.indexOf(' ');
    if (space <= 0) continue;
    final w = line.substring(0, space);
    if (stems.contains(w)) lexicon[w] = line.substring(space + 1).trim().split(' ');
  }
  final out = StringBuffer();
  for (final w in missing) {
    if (inflect(w, lexicon) case final p? when p.length > 1) out.writeln('$w ${p.join(' ')}');
  }
  return out.toString();
}

/// Every base word [inflect] may look up for [word].
Iterable<String> _stemsOf(String w) sync* {
  for (final cut in [1, 2, 3, 4]) {
    if (w.length > cut + 1) {
      final s = w.substring(0, w.length - cut);
      yield s;
      yield '${s}e';
      yield '${s}y';
    }
  }
}
