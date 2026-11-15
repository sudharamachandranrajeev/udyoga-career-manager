/// What a move does to pay: the candidate's current basic pay against a
/// job's, gross and as an estimated take-home, with the rent difference.
library;

/// An Agenda for Change pay point (annual, full-time, basic pay).
class PayPoint {
  const PayPoint(this.scale, this.band, this.step, this.pay);

  /// Which table: e.g. "England 2026/27".
  final String scale;
  final String band, step;
  final int pay;

  String get label => '$scale Band $band $step';
}

/// Built-in Agenda for Change points, checked against the official tables
/// (NHS Employers pay scales 2026/27; DoH NI circular HSC (AfC) 06/2025).
/// Only the bands checked are listed; other pay is typed in.
const afcPoints = [
  PayPoint('England 2026/27', '3', 'entry', 25760),
  PayPoint('England 2026/27', '3', 'top', 27476),
  PayPoint('England 2026/27', '4', 'entry', 28392),
  PayPoint('England 2026/27', '4', 'top', 31157),
  PayPoint('England 2026/27', '5', 'entry', 32073),
  PayPoint('England 2026/27', '5', 'intermediate', 34592),
  PayPoint('England 2026/27', '5', 'top', 39043),
  PayPoint('NI 2025/26', '3', 'entry', 24937),
  PayPoint('NI 2025/26', '3', 'top', 26598),
  PayPoint('NI 2025/26', '4', 'entry', 27485),
  PayPoint('NI 2025/26', '4', 'top', 30162),
  PayPoint('NI 2025/26', '5', 'entry', 31049),
  PayPoint('NI 2025/26', '5', 'intermediate', 33487),
  PayPoint('NI 2025/26', '5', 'top', 37796),
];

const afcSources = [
  'https://www.nhsemployers.org/articles/pay-scales-202627',
  'https://nipsa.org.uk/images/attachments/2025-Attachments/afc-6-2025.pdf',
];

/// The Agenda for Change band an advert names ("Band 4", "band 8a"), or ''.
String bandIn(String text) =>
    RegExp(r'\bband\s*(8[a-d]|[1-9])\b', caseSensitive: false).firstMatch(text)?.group(1)?.toLowerCase() ??
    '';

/// The pay on promotion into an England [band]: its entry point, when the
/// band is in the built-in table.
int? englandEntry(String band) => afcPoints
    .where((p) => p.scale.startsWith('England') && p.band == band && p.step == 'entry')
    .firstOrNull
    ?.pay;

/// Estimated monthly take-home from an NHS basic salary, 2026/27: income tax
/// for England, Wales and Northern Ireland (not Scotland), Class 1 National
/// Insurance, and the NHS Pension at its member tiers, taken before tax.
/// No student loan, salary sacrifice or extra hours. Null above £52,778,
/// where the higher pension tiers for the year are not built in.
int? monthlyTakeHome(int annual) {
  if (annual > 52778) return null;
  final pension =
      annual *
      switch (annual) {
        <= 13259 => 0.052,
        <= 28854 => 0.065,
        <= 35155 => 0.083,
        _ => 0.098,
      };
  final taxable = annual - pension;
  final tax = _band(taxable, 12570, 50270) * 0.20 + _band(taxable, 50270, 125140) * 0.40;
  final ni =
      _band(annual.toDouble(), 12570, 50270) * 0.08 + _band(annual.toDouble(), 50270, double.infinity) * 0.02;
  return ((annual - pension - tax - ni) / 12).round();
}

double _band(double x, double from, double to) => (x.clamp(from, to) - from).toDouble();

/// The change from [now] to [next] (annual basic pay), and the monthly
/// rents when known.
class PayChange {
  PayChange({required this.now, required this.next, this.rentNow, this.rentNext});
  final int now, next;
  final int? rentNow, rentNext;

  int get grossYear => next - now;
  double get grossPercent => now == 0 ? 0 : grossYear * 100 / now;

  /// Take-home change a month, when both are estimated.
  int? get takeHomeMonth => switch ((monthlyTakeHome(next), monthlyTakeHome(now))) {
    (final a?, final b?) => a - b,
    _ => null,
  };

  int? get rentMonth => rentNow != null && rentNext != null ? rentNext! - rentNow! : null;

  /// What is left a month after the rent change.
  int? get afterRentMonth => switch ((takeHomeMonth, rentMonth)) {
    (final t?, final r?) => t - r,
    _ => null,
  };
}

/// The candidate's current pay and rent, and the rent expected after moving.
class PayBaseline {
  const PayBaseline({this.pay = 0, this.label = '', this.rentNow, this.rentNext});
  final int pay;
  final String label;
  final int? rentNow, rentNext;

  bool get isSet => pay > 0;

  factory PayBaseline.fromJson(Map<String, Object?> j) => PayBaseline(
    pay: (j['pay'] as num?)?.toInt() ?? 0,
    label: j['label'] as String? ?? '',
    rentNow: (j['rentNow'] as num?)?.toInt(),
    rentNext: (j['rentNext'] as num?)?.toInt(),
  );

  Map<String, Object?> toJson() => {
    'pay': pay,
    'label': label,
    if (rentNow != null) 'rentNow': rentNow,
    if (rentNext != null) 'rentNext': rentNext,
  };
}
