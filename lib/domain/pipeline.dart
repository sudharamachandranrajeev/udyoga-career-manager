import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;

/// Where an application stands. Open stages come first, in order.
enum Stage {
  preparing('Preparing', open: true, chaseAfter: null),
  applied('Applied', open: true, chaseAfter: 10),
  screening('Screening', open: true, chaseAfter: 7),
  interview('Interview', open: true, chaseAfter: 5),
  // Passed the interview but not yet placed: HSC (Northern Ireland) keeps
  // ranked waiting lists for up to 12 months and offers posts from them.
  waitingList('Waiting list', open: true, chaseAfter: 30),
  offer('Offer', open: true, chaseAfter: 3),
  // A conditional offer accepted; pre-employment checks under way.
  checks('Checks', open: true, chaseAfter: 7),
  accepted('Accepted', open: false),
  rejected('Rejected', open: false),
  withdrawn('Withdrawn', open: false),
  noReply('No reply', open: false);

  const Stage(this.label, {required this.open, this.chaseAfter});
  final String label;
  final bool open;

  /// Days after reaching this stage to chase it up, when nothing is heard.
  final int? chaseAfter;

  String get id => name;

  static Stage of(String id) => values.firstWhere((s) => s.name == id, orElse: () => preparing);

  static List<Stage> get openStages => values.where((s) => s.open).toList();
}

/// When to chase an application that just reached [stage] on [date], or
/// null for stages that end it.
String? followUpFor(Stage stage, String date) => switch (stage.chaseAfter) {
  final days? => addDays(date, days),
  null => null,
};

/// [date] moved on by [days] working days (Monday to Friday; bank holidays
/// are not known here).
String addWorkingDays(String date, int days) {
  var d = date;
  for (var left = days; left > 0;) {
    d = addDays(d, 1);
    if (DateTime.parse(d).weekday <= DateTime.friday) left--;
  }
  return d;
}

/// An application with no reply this many days after applying is marked as
/// no reply (the user can still move it on).
const ghostedAfterDays = 42;

/// What happens on an application, with the stage it implies.
const eventKinds = {
  'applied': ('Applied', Stage.applied),
  'followup': ('Chased up', null),
  'reply': ('Heard back', Stage.screening),
  'interview': ('Interview', Stage.interview),
  'waitlist': ('Placed on waiting list', Stage.waitingList),
  'offer': ('Offer', Stage.offer),
  'checks': ('Accepted conditional offer', Stage.checks),
  'accepted': ('Accepted', Stage.accepted),
  'rejected': ('Rejected', Stage.rejected),
  'withdrawn': ('Withdrew', Stage.withdrawn),
  'note': ('Note', null),
};

const leadKinds = {
  'recruiter': 'Recruiter',
  'hiring_manager': 'Hiring manager',
  'referral': 'Referral',
  'peer': 'Peer in the field',
  'mentor': 'Mentor',
  'referee': 'Referee',
  'other': 'Other',
};

const leadStatuses = {
  'new': 'Not contacted',
  'contacted': 'Contacted',
  'replied': 'Replied',
  'cold': 'Gone cold',
};

const growthKinds = {
  'certification': 'Certification',
  'course': 'Course',
  'degree': 'Degree or diploma',
  'skill': 'Skill',
  'experience': 'Experience',
  'goal': 'Career goal',
};

/// The candidate's own notes on the Growth page, kept with the plan but
/// shown apart from it. The AI reads them with the profile.
const noteKinds = {'idea': 'Idea', 'win': 'Win'};

const growthStatuses = {
  'suggested': 'Suggested',
  'planned': 'Planned',
  'doing': 'In progress',
  'done': 'Done',
  'dropped': 'Dropped',
};

const jobStatuses = {'new': 'New', 'saved': 'Saved', 'dismissed': 'Dismissed', 'applied': 'Applied'};
