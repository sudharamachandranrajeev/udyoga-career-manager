/// Assisted fill: puts a draft the user approved into one text box on the
/// page they have open (a connection note, a message). The user reads it
/// there and presses Send themselves.
///
/// This file is the whole of the fill path, and it has no way to press
/// anything: the script it builds only sets a text box's value and tells
/// the page the text changed. A test reads this file to keep it so.
library;

import 'dart:convert';

import '../db/database.dart';
import 'polite.dart';
import 'recipes.dart';

/// What a fill would do, shown to the user before anything happens.
class FillPlan {
  const FillPlan({
    required this.recipe,
    required this.text,
    required this.used,
    this.problems = const [],
    this.cut = false,
  });

  final Recipe recipe;

  /// The exact text that would go into the box.
  final String text;

  /// Fills already made today with this recipe.
  final int used;

  /// Reasons it cannot go ahead (wrong page, cap reached, nothing to fill).
  final List<String> problems;

  /// The text was shortened to the box's limit.
  final bool cut;

  int get cap => recipe.effectiveCap;
  int get left => cap - used < 0 ? 0 : cap - used;
  bool get ready => problems.isEmpty;
  String get target => recipe.fill!.targetSelector;
}

/// Plans fills and carries them out once the user has seen the plan.
class AssistFill {
  AssistFill(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;

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
    final used = await DailyCounter(db, clock: _clock).used(recipe.use);
    if (used >= recipe.effectiveCap) {
      problems.add(
        'Today\'s limit of ${recipe.effectiveCap} for ${recipe.title} is used up. It resets tomorrow.',
      );
    }
    final last = DateTime.tryParse(await db.localSetting(_lastKey(recipe)) ?? '');
    if (last != null && _clock().difference(last) < recipe.gap) {
      final wait = recipe.gap - _clock().difference(last);
      problems.add('Wait ${wait.inSeconds + 1} seconds between fills on ${recipe.title}.');
    }
    return FillPlan(recipe: recipe, text: text, used: used, problems: problems, cut: cut);
  }

  /// Fills the box through [fillTextBox] (the browser's one fill call,
  /// which runs [fillScript]) and counts it. Returns null on success, or
  /// why it did not fill.
  Future<String?> apply(
    FillPlan plan,
    Future<Object?> Function(String selector, String text) fillTextBox,
  ) async {
    if (!plan.ready) return plan.problems.first;
    // The cap is checked again: a plan can be stale.
    final counter = DailyCounter(db, clock: _clock);
    if (await counter.used(plan.recipe.use) >= plan.cap) return 'Today\'s limit is used up.';
    final reply = _decode(await fillTextBox(plan.target, plan.text));
    if (reply['ok'] != true) return '${reply['reason'] ?? 'The page did not take the text.'}';
    await counter.add(plan.recipe.use);
    await db.setLocalSetting(_lastKey(plan.recipe), _clock().toIso8601String());
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
