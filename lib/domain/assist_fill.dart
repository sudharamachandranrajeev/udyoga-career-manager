/// Assisted fill: puts a draft the user approved into one text box on the
/// page they have open (a connection note, a message). The user reads it
/// there and presses Send themselves.
///
/// This file is the whole of the fill path, and it has no way to press
/// anything: the script it builds only sets a text box's value and tells
/// the page the text changed. A test reads this file to keep it so.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'book.dart';
import 'polite.dart';
import 'recipes.dart';

/// Synced pref: how many fills [recipeId] made on [day] (yyyy-MM-dd) on
/// any device of the account, so a daily cap (LinkedIn's 15 above all)
/// holds across devices, not on each one.
String syncedFillsKey(String recipeId, String day) => 'udyoga.recipe.fills.$recipeId.$day';

/// The id the combined LinkedIn count is kept under. A recipe id cannot
/// start with "_", so it never clashes with one.
const linkedInFillsId = '_linkedin';

/// Synced pref: fills made on [day] by every recipe whose site is
/// linkedin.com, together, on any device of the account.
String syncedLinkedInFillsKey(String day) => syncedFillsKey(linkedInFillsId, day);

/// Synced fill counts are kept this many days, then pruned.
const fillCountDays = 7;

/// True when [r]'s fills count towards the combined LinkedIn ceiling.
bool countsTowardsLinkedIn(Recipe r) => r.mode == RecipeMode.assistFill && isLinkedIn(r.site);

/// What a fill would do, shown to the user before anything happens.
class FillPlan {
  const FillPlan({
    required this.recipe,
    required this.text,
    required this.used,
    this.linkedInUsed,
    this.problems = const [],
    this.cut = false,
  });

  final Recipe recipe;

  /// The exact text that would go into the box.
  final String text;

  /// Fills already made today with this recipe.
  final int used;

  /// Fills already made today by all LinkedIn recipes together; null when
  /// the recipe is not a LinkedIn one.
  final int? linkedInUsed;

  /// Reasons it cannot go ahead (wrong page, cap reached, nothing to fill).
  final List<String> problems;

  /// The text was shortened to the box's limit.
  final bool cut;

  int get cap => recipe.effectiveCap;

  /// Fills left today: the recipe's own cap and, for LinkedIn, the
  /// combined ceiling, whichever is lower.
  int get left {
    var n = cap - used;
    final li = linkedInUsed;
    if (li != null && linkedInDailyCeiling - li < n) n = linkedInDailyCeiling - li;
    return n < 0 ? 0 : n;
  }

  bool get ready => problems.isEmpty;
  String get target => recipe.fill!.targetSelector;
}

/// Plans fills and carries them out once the user has seen the plan.
class AssistFill {
  AssistFill(this.db, {DateTime Function()? clock, this.book}) : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;

  /// Where the synced counts live; without it the counts stay on this
  /// device.
  final CareerBook? book;

  String get _today => _clock().toIso8601String().substring(0, 10);

  /// Fills made today with [recipe]: the larger of this device's count and
  /// the account's synced count.
  Future<int> used(Recipe recipe) => _used(recipe.use, syncedFillsKey(recipe.id, _today));

  /// Fills made today by every LinkedIn recipe together, counted the same
  /// way as [used].
  Future<int> linkedInUsed() => _used(_linkedInUse, syncedLinkedInFillsKey(_today));

  static const _linkedInUse = 'fill.linkedin';

  Future<int> _used(String use, String syncedKey) async {
    final local = await DailyCounter(db, clock: _clock).used(use);
    final b = book;
    if (b == null) return local;
    final synced = await b.pref<int>(syncedKey, 0);
    return synced > local ? synced : local;
  }

  /// Counts one fill on this device and in the synced pref, and in the
  /// combined LinkedIn count when it is a LinkedIn recipe.
  Future<void> _count(Recipe recipe) async {
    await _raise(recipe.use, syncedFillsKey(recipe.id, _today));
    if (countsTowardsLinkedIn(recipe)) await _raise(_linkedInUse, syncedLinkedInFillsKey(_today));
  }

  Future<void> _raise(String use, String syncedKey) async {
    final n = await _used(use, syncedKey) + 1;
    await DailyCounter(db, clock: _clock).raiseTo(use, n);
    await book?.setPref(syncedKey, n);
  }

  /// Why [recipe] cannot fill again today, or null if it can.
  Future<String?> _capProblem(Recipe recipe) async {
    if (await used(recipe) >= recipe.effectiveCap) {
      return 'Today\'s limit of ${recipe.effectiveCap} for ${recipe.title} is used up. It resets tomorrow.';
    }
    if (countsTowardsLinkedIn(recipe) && await linkedInUsed() >= linkedInDailyCeiling) {
      return 'Today\'s limit of $linkedInDailyCeiling LinkedIn fills, all recipes together, is used up. '
          'It resets tomorrow.';
    }
    return null;
  }

  /// Tombstones the synced fill counts older than [fillCountDays] days, so
  /// the prefs table does not grow a row per recipe per day for ever.
  /// Returns how many it removed. Needs [book]; without it, does nothing.
  Future<int> pruneOldFills() async {
    final b = book;
    if (b == null) return 0;
    final cutoff = _clock().subtract(const Duration(days: fillCountDays)).toIso8601String().substring(0, 10);
    final rows = await (db.select(
      db.prefs,
    )..where((p) => p.id.like('udyoga.recipe.fills.%') & p.deleted.equals(false))).get();
    var removed = 0;
    for (final r in rows) {
      final day = r.id.substring(r.id.lastIndexOf('.') + 1);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) || day.compareTo(cutoff) >= 0) continue;
      await b.remove(db.prefs, r.id);
      removed++;
    }
    return removed;
  }

  /// The dry run: the text [recipe] would put on [pageUrl], from the
  /// user's approved [draft] or the recipe's template filled with [values]
  /// (firstName, name, company, jobTitle), and whether today's cap allows
  /// it. Changes nothing.
  Future<FillPlan> plan(
    Recipe recipe, {
    required String pageUrl,
    String draft = '',
    Map<String, String> values = const {},
  }) async {
    final fill = recipe.fill;
    final problems = <String>[];
    if (recipe.mode != RecipeMode.assistFill || fill == null) {
      return FillPlan(
        recipe: recipe,
        text: '',
        used: 0,
        problems: const ['This recipe does not fill text boxes.'],
      );
    }
    if (!recipe.matches(pageUrl)) problems.add('This page is not one of ${recipe.title}\'s pages.');
    var text = fill.templateSource == 'draft' ? draft : fillTemplate(fill.template, values);
    text = text.trim();
    if (text.isEmpty) problems.add('There is no approved draft to fill in.');
    var cut = false;
    if (fill.maxLength > 0 && text.length > fill.maxLength) {
      text = text.substring(0, fill.maxLength).trimRight();
      cut = true;
    }
    final used = await this.used(recipe);
    final linkedIn = countsTowardsLinkedIn(recipe) ? await linkedInUsed() : null;
    final capped = await _capProblem(recipe);
    if (capped != null) problems.add(capped);
    final last = DateTime.tryParse(await db.localSetting(_lastKey(recipe)) ?? '');
    if (last != null && _clock().difference(last) < recipe.gap) {
      final wait = recipe.gap - _clock().difference(last);
      problems.add('Wait ${wait.inSeconds + 1} seconds between fills on ${recipe.title}.');
    }
    return FillPlan(
      recipe: recipe,
      text: text,
      used: used,
      linkedInUsed: linkedIn,
      problems: problems,
      cut: cut,
    );
  }

  /// Fills the box through [fillTextBox] (the browser's one fill call,
  /// which runs [fillScript]) and counts it. Returns null on success, or
  /// why it did not fill.
  Future<String?> apply(
    FillPlan plan,
    Future<Object?> Function(String selector, String text) fillTextBox,
  ) async {
    if (!plan.ready) return plan.problems.first;
    // The cap is checked again: a plan can be stale, and another device
    // may have filled since.
    final capped = await _capProblem(plan.recipe);
    if (capped != null) return capped;
    final reply = _decode(await fillTextBox(plan.target, plan.text));
    if (reply['ok'] != true) return '${reply['reason'] ?? 'The page did not take the text.'}';
    await _count(plan.recipe);
    await db.setLocalSetting(_lastKey(plan.recipe), _clock().toIso8601String());
    await pruneOldFills();
    return null;
  }

  String _lastKey(Recipe r) => 'udyoga.fill.last.${r.id}';

  static Map<String, Object?> _decode(Object? raw) {
    var v = raw;
    for (var i = 0; i < 2 && v is String; i++) {
      try {
        v = jsonDecode(v);
      } on FormatException {
        return const {};
      }
    }
    return v is Map ? v.cast<String, Object?>() : const {};
  }
}

/// [template] with {firstName}, {name}, {company} and {jobTitle} filled in
/// from [values]; unknown placeholders are left empty.
String fillTemplate(String template, Map<String, String> values) {
  final v = {
    ...values,
    if (!values.containsKey('firstName') && (values['name'] ?? '').isNotEmpty)
      'firstName': values['name']!.trim().split(RegExp(r'\s+')).first,
  };
  return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => v[m[1]] ?? '');
}

/// The script that puts [text] into the text box at [selector]. It refuses
/// anything that is not a textarea, a text input or a contenteditable
/// element, sets the value the way typing would, and fires the "input" and
/// "change" events the page listens for. It sends no key presses and
/// presses nothing, so nothing is sent.
String fillScript(String selector, String text) {
  final sel = jsonEncode(selector), value = jsonEncode(text);
  return '''(function () {
  var el = document.querySelector($sel);
  if (!el) return JSON.stringify({ok: false, reason: 'The text box is not on this page.'});
  var tag = el.tagName.toLowerCase();
  var type = (el.getAttribute('type') || 'text').toLowerCase();
  var isText = tag === 'textarea' || (tag === 'input' && ['text', 'search', 'email', ''].indexOf(type) >= 0);
  if (!isText && !el.isContentEditable) return JSON.stringify({ok: false, reason: 'That is not a text box.'});
  el.focus();
  if (el.isContentEditable && !isText) {
    el.textContent = $value;
  } else {
    var proto = tag === 'textarea' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(proto, 'value').set.call(el, $value);
  }
  el.dispatchEvent(new Event('input', {bubbles: true}));
  el.dispatchEvent(new Event('change', {bubbles: true}));
  return JSON.stringify({ok: true});
})()''';
}
