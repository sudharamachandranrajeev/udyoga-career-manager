import 'countries.dart';
import 'eligibility.dart' show addMonths;
import 'work_rights.dart';

/// Months before a right to work ends when Udyoga puts a reminder on Today.
const visaMilestones = [18, 12, 6, 3];

/// One reminder before a right to work ends.
class VisaMilestone {
  const VisaMilestone({required this.right, required this.months, required this.date});
  final RightToWork right;

  /// Months before the end.
  final int months;

  /// The day of the reminder, yyyy-MM-dd.
  final String date;

  String get title => '${Country.nameOf(right.country)} right to work: $months months left';

  String get detail => [
    if (right.status.isNotEmpty) right.status,
    'ends ${right.until}',
    switch (months) {
      18 => 'time to plan the next visa or a route to settlement',
      12 => 'check the next route and what it needs',
      6 => 'apply soon: most extensions can be made in the last months',
      _ => 'act now if nothing is in place',
    },
  ].join(' · ');
}

/// The countdown on a right to work that ends.
class VisaClock {
  const VisaClock(this.right, {required this.today});
  final RightToWork right;
  final String today;

  /// Whole days left, counting the last day as one; negative once ended.
  int get daysLeft => DateTime.parse(right.until!).difference(DateTime.parse(today)).inDays + 1;

  /// Whole calendar months left (0 in the last month).
  int get monthsLeft {
    var m = 0;
    while (addMonths(today, m + 1).compareTo(right.until!) <= 0) {
      m++;
    }
    return m;
  }

  bool get ended => right.until!.compareTo(today) < 0;

  /// "1 year 4 months left", "45 days left", "Ended".
  String get label {
    if (ended) return 'Ended ${right.until}';
    final m = monthsLeft;
    if (m < 2) return '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left';
    final y = m ~/ 12, rest = m % 12;
    final parts = [
      if (y > 0) '$y ${y == 1 ? 'year' : 'years'}',
      if (rest > 0) '$rest ${rest == 1 ? 'month' : 'months'}',
    ].join(' ');
    return '$parts left';
  }

  /// Every reminder for this right, past ones too, soonest first.
  List<VisaMilestone> get milestones => [
    for (final months in visaMilestones)
      VisaMilestone(right: right, months: months, date: addMonths(right.until!, -months)),
  ]..sort((a, b) => a.date.compareTo(b.date));

  /// The reminder in force on [today]: the latest one already reached, or
  /// null before the first (and after the end).
  VisaMilestone? get current {
    if (ended) return null;
    VisaMilestone? last;
    for (final m in milestones) {
      if (m.date.compareTo(today) <= 0) last = m;
    }
    return last;
  }

  /// The next reminder still to come, or null.
  VisaMilestone? get next => milestones.where((m) => m.date.compareTo(today) > 0).firstOrNull;
}

/// The clocks for every right to work that ends and has not ended long ago
/// (a year), soonest end first.
List<VisaClock> visaClocks(WorkRights rights, {required String today}) => [
  for (final r in rights.rightToWork)
    if (r.until != null && addMonths(r.until!, 12).compareTo(today) >= 0) VisaClock(r, today: today),
]..sort((a, b) => a.right.until!.compareTo(b.right.until!));
