import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:drift/drift.dart';

// Table names are unique across the Brahma suite: every app on an account
// reads the same change log and applies only its own tables. Udyoga's all
// start with `job_` or `career_`.
//
// Dates are yyyy-MM-dd, times local yyyy-MM-ddTHH:mm. JSON columns hold what
// the AI returned (see domain/advisor.dart) and are read through the domain
// models, never shown raw.

/// An opening, from a job feed, the AI search or typed in.
@DataClassName('Job')
class JobListings extends Table with SyncedRow {
  TextColumn get title => text()();
  TextColumn get company => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();

  /// ISO 3166 alpha-2, upper case ('GB', 'IE', 'IN'); '' when unknown.
  TextColumn get country => text().withDefault(const Constant(''))();
  BoolColumn get remote => boolean().withDefault(const Constant(false))();

  /// Yearly figures in [currency] when the advert gives them.
  IntColumn get salaryMin => integer().nullable()();
  IntColumn get salaryMax => integer().nullable()();
  TextColumn get currency => text().withDefault(const Constant(''))();

  /// The advert's own wording ("£24,000 - £26,500 a year", "Band 4").
  TextColumn get salaryText => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get posted => text().nullable()();
  TextColumn get closing => text().nullable()();

  /// adzuna | reed | arbeitnow | remotive | jobicy | ai | manual; with the
  /// source's own id, so a refresh updates instead of duplicating.
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get sourceId => text().withDefault(const Constant(''))();
  TextColumn get found => text()();

  /// new | saved | dismissed | applied
  TextColumn get status => text().withDefault(const Constant('new'))();

  /// 0 to 100: the AI's when it has assessed the job, else the local match.
  IntColumn get fit => integer().nullable()();

  /// Who set [fit]: local (the offline match, redone whenever the profile
  /// changes) | triage (the AI's quick score) | ai (a full assessment).
  TextColumn get fitBy => text().withDefault(const Constant('local'))();

  /// The AI's assessment (FitAssessment), '' until asked.
  TextColumn get assessment => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// An application and where it stands.
@DataClassName('JobApplication')
class JobApplications extends Table with SyncedRow {
  TextColumn get jobId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get company => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();

  /// See domain/pipeline.dart.
  TextColumn get stage => text().withDefault(const Constant('preparing'))();
  TextColumn get applied => text().nullable()();

  /// When to chase it up, and what to ask.
  TextColumn get followUp => text().nullable()();
  TextColumn get followUpNote => text().withDefault(const Constant(''))();

  /// The CV sent (career_resumes id).
  TextColumn get resumeId => text().nullable()();
  TextColumn get reference => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Last change of stage, for "no reply in N days".
  TextColumn get updated => text()();
}

/// What happened on an application: sent, chased, heard back, interviews.
@DataClassName('JobEvent')
class JobEvents extends Table with SyncedRow {
  TextColumn get applicationId => text()();
  TextColumn get at => text()();

  /// applied | followup | reply | interview | offer | rejected | withdrawn | note
  TextColumn get kind => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
}

/// One pre-employment check or step between an offer and the first day.
@DataClassName('JobCheck')
class JobChecks extends Table with SyncedRow {
  TextColumn get applicationId => text()();

  /// identity | references | criminal_record | health | qualifications |
  /// forms | contract | notice | start | other
  TextColumn get kind => text()();
  TextColumn get title => text()();

  /// todo | sent | done | not_needed
  TextColumn get status => text().withDefault(const Constant('todo'))();
  TextColumn get due => text().nullable()();
  TextColumn get done => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// A copy kept by the candidate: the advert as it read, or the application
/// as sent. Job sites delete both after a while.
@DataClassName('Archived')
class JobArchive extends Table with SyncedRow {
  TextColumn get applicationId => text().nullable()();
  TextColumn get jobId => text().nullable()();

  /// advert | application
  TextColumn get kind => text()();
  TextColumn get at => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get content => text()();
}

/// Recruiters, hiring managers, referrers and other leads.
@DataClassName('Lead')
class CareerContacts extends Table with SyncedRow {
  TextColumn get name => text()();

  /// recruiter | hiring_manager | referral | peer | mentor | referee | other
  TextColumn get kind => text().withDefault(const Constant('recruiter'))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get company => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get linkedin => text().withDefault(const Constant(''))();

  /// Where the lead was found (a team page, a job advert...).
  TextColumn get source => text().withDefault(const Constant(''))();

  /// new | contacted | replied | cold. Since schema 4 these three follow the
  /// person's newest conversation (domain/conversations.dart); they are kept
  /// so the Contacts and Today pages read them as before.
  TextColumn get status => text().withDefault(const Constant('new'))();
  TextColumn get lastContact => text().nullable()();
  TextColumn get followUp => text().nullable()();
  TextColumn get jobId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  // Where the person was found and why the user may contact them (UK GDPR:
  // the source and the lawful basis are recorded for every contact).

  /// The page the person was found on (an advert, a team page...).
  TextColumn get sourceUrl => text().withDefault(const Constant(''))();

  /// advert | team_page | speaker | register | met | archive | inbound |
  /// referral | other
  TextColumn get sourceKind => text().withDefault(const Constant('other'))();

  /// When they were found, yyyy-MM-dd.
  TextColumn get foundOn => text().nullable()();

  /// legitimate_interest | they_contacted | consent
  TextColumn get basis => text().withDefault(const Constant('legitimate_interest'))();
  TextColumn get basisNote => text().withDefault(const Constant(''))();

  /// True when the person asked not to be contacted: the composer is
  /// blocked and lead imports skip their address and profile.
  BoolColumn get doNotContact => boolean().withDefault(const Constant(false))();

  /// "Keep in touch every N weeks", or null for no reminder.
  IntColumn get keepInTouchWeeks => integer().nullable()();
}

/// One of a person's identities on a channel: an e-mail address, a LinkedIn
/// profile, a phone number. One person can have many.
@DataClassName('ContactHandle')
class ContactHandles extends Table with SyncedRow {
  @override
  String get tableName => 'career_handles';

  TextColumn get contactId => text()();

  /// email | linkedin | bluesky | phone | in_person | other
  TextColumn get channel => text()();

  /// The address, profile URL, Bluesky handle or number.
  TextColumn get handle => text()();

  /// Which of the user's own accounts talks to it ('' for any).
  TextColumn get account => text().withDefault(const Constant(''))();

  /// The one to use first on this channel. ("primary" is an SQL keyword.)
  BoolColumn get primary => boolean().named('is_primary').withDefault(const Constant(false))();
}

/// One thread with one person on one channel.
@DataClassName('Conversation')
class Conversations extends Table with SyncedRow {
  @override
  String get tableName => 'career_conversations';

  /// The person (career_contacts id); null while the sender is unknown and
  /// the thread waits in the Screener.
  TextColumn get contactId => text().nullable()();

  /// email | linkedin | bluesky | phone | in_person | other
  TextColumn get channel => text()();

  /// The user's own account on that channel ('' when there is one only).
  TextColumn get account => text().withDefault(const Constant(''))();

  /// api (sent and received by Udyoga) | manual (logged by the user) |
  /// import (from an export file)
  TextColumn get mode => text().withDefault(const Constant('manual'))();

  /// The channel's own thread id (a Gmail thread, a Bluesky convo), so a
  /// later fetch or import adds to this thread.
  TextColumn get externalId => text().nullable()();

  /// Who the other side is as the channel gave it (an address or profile
  /// URL); names the sender of a Screener thread.
  TextColumn get peer => text().withDefault(const Constant(''))();
  TextColumn get subject => text().withDefault(const Constant(''))();

  /// draft | to_send | awaiting_reply | replied | follow_up | closed
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get followUp => text().nullable()();
  TextColumn get jobId => text().nullable()();

  /// Time of the newest message, for sorting.
  TextColumn get lastAt => text()();
  IntColumn get unread => integer().withDefault(const Constant(0))();
}

/// One message in a conversation, or the user's note on it.
@DataClassName('ThreadMessage')
class Messages extends Table with SyncedRow {
  @override
  String get tableName => 'career_messages';

  TextColumn get conversationId => text()();

  /// out | in | note
  TextColumn get direction => text()();

  /// Plain text.
  TextColumn get body => text().withDefault(const Constant(''))();

  /// When it was sent; for a logged message, when the user says it was.
  TextColumn get sentAt => text()();

  /// api | manual | import | ai_draft
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// logged | invite (a LinkedIn connection note, logged) | draft | queued |
  /// sent | failed | received
  TextColumn get status => text().withDefault(const Constant('logged'))();

  /// The provider's message id (Message-ID...), so nothing is stored twice.
  TextColumn get externalId => text().nullable()();
  TextColumn get inReplyTo => text().nullable()();

  /// The AI draft this message came from.
  TextColumn get draftOf => text().nullable()();
}

/// A post in the weekly plan: when to post it, the draft, and whether it
/// went out. The user posts by hand (or presses Post for Bluesky); nothing
/// is posted on its own.
@DataClassName('PlannedPost')
class CareerPosts extends Table with SyncedRow {
  @override
  String get tableName => 'career_posts';

  /// linkedin | bluesky
  TextColumn get channel => text().withDefault(const Constant('linkedin'))();

  /// The slot, local time (YYYY-MM-DDTHH:mm).
  TextColumn get at => text()();

  /// What it is about, before there is a draft.
  TextColumn get topic => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();

  /// The draft after the humanizer, when the user ran it.
  TextColumn get humanized => text().withDefault(const Constant(''))();

  /// planned | posted | skipped ("due" is a planned post whose time has
  /// come).
  TextColumn get status => text().withDefault(const Constant('planned'))();

  /// The post's address, pasted by the user or given by Bluesky.
  TextColumn get postUrl => text().withDefault(const Constant(''))();
  TextColumn get postedAt => text().nullable()();
}

/// CVs: the base one made from the profile and those tailored to a job.
@DataClassName('Resume')
class CareerResumes extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get jobId => text().nullable()();
  TextColumn get created => text()();

  /// ResumeDoc as JSON.
  TextColumn get content => text()();

  /// What was changed for the job, keyword cover and cautions (TailorNotes).
  TextColumn get tailoring => text().withDefault(const Constant(''))();
}

/// AI reports: profile assessment, career map, market scans. Kept so they can
/// be compared over time; the newest of each kind is the current one.
@DataClassName('Report')
class CareerReports extends Table with SyncedRow {
  /// assessment | career_map
  TextColumn get kind => text()();
  TextColumn get created => text()();
  TextColumn get content => text()();

  /// Web pages the AI read for it, as JSON [{title, url}].
  TextColumn get sources => text().withDefault(const Constant('[]'))();
}

/// Self-improvement: certifications, courses, degrees, skills and goals.
@DataClassName('GrowthItem')
class CareerGrowth extends Table with SyncedRow {
  TextColumn get title => text()();

  /// certification | course | degree | skill | experience | goal
  TextColumn get kind => text()();
  TextColumn get provider => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get why => text().withDefault(const Constant(''))();
  TextColumn get cost => text().withDefault(const Constant(''))();
  TextColumn get duration => text().withDefault(const Constant(''))();

  /// suggested | planned | doing | done | dropped
  TextColumn get status => text().withDefault(const Constant('suggested'))();

  /// 0 to 100.
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get target => text().nullable()();
  TextColumn get done => text().nullable()();

  /// The career path it serves, by name, when it came from the map.
  TextColumn get path => text().withDefault(const Constant(''))();
  TextColumn get added => text()();
}

/// A route track: one way into a country being worked on, with dated
/// milestones and the trigger that starts or switches it. Several run side
/// by side (say Ireland now, the UK if a sponsor appears).
@DataClassName('RouteTrack')
class CareerTracks extends Table with SyncedRow {
  /// ISO alpha-2.
  TextColumn get country => text()();

  /// The route's id from the route tables ("gb.skilled-worker"), or ''.
  TextColumn get routeId => text().withDefault(const Constant(''))();
  TextColumn get title => text()();

  /// active | paused | done | dropped
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// What starts or switches this track ("a sponsored offer at £41,700").
  TextColumn get trigger => text().withDefault(const Constant(''))();

  /// JSON list of {id, title, due (yyyy-MM-dd or null), done (yyyy-MM-dd or null), todo (row id or null)}.
  TextColumn get milestones => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get added => text()();
}

/// An interview practice round.
@DataClassName('PracticeSession')
class CareerPractice extends Table with SyncedRow {
  TextColumn get jobId => text().nullable()();
  TextColumn get role => text()();

  /// standard | competency | technical | toughest | ai
  TextColumn get mode => text()();
  TextColumn get started => text()();

  /// The question set (PracticeQuestion list as JSON).
  TextColumn get questions => text()();

  /// Mean of the scored answers, 0 to 10.
  RealColumn get score => real().nullable()();

  /// The role profile (career_role_profiles) the round's questions came
  /// from, if any.
  TextColumn get profileId => text().nullable()();

  /// The panel scoring of the round (interview plan I3) as JSON: the
  /// framework and each answer's scores with the quotes they rest on, ''
  /// until scored. Text only, like the transcripts.
  TextColumn get debrief => text().withDefault(const Constant(''))();

  /// How nervous the candidate felt before and after the round, 1 (calm)
  /// to 5 (very nervous), when they said (interview plan I4).
  IntColumn get nervesBefore => integer().nullable()();
  IntColumn get nervesAfter => integer().nullable()();
}

/// A role to practise for (interview plan I3): the criteria from its advert
/// and person specification, and the framework its panel scores with.
@DataClassName('RoleProfileRow')
class CareerRoleProfiles extends Table with SyncedRow {
  TextColumn get title => text()();
  TextColumn get employer => text().withDefault(const Constant(''))();
  TextColumn get jobId => text().nullable()();

  /// A framework id (domain/interview_scoring.dart).
  TextColumn get framework => text().withDefault(const Constant('private'))();

  /// Criterion list as JSON.
  TextColumn get criteria => text().withDefault(const Constant('[]'))();

  /// ai | manual
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get added => text()();
  TextColumn get updated => text()();
}

/// A whole interview process being rehearsed (interview plan I2): its
/// stages as edited, and how far it has got, so it can be picked up later.
@DataClassName('ProcessRow')
class CareerProcesses extends Table with SyncedRow {
  TextColumn get name => text()();

  /// The template it started from.
  TextColumn get template => text().withDefault(const Constant(''))();
  TextColumn get profileId => text().nullable()();

  /// InterviewProcess as JSON.
  TextColumn get process => text()();

  /// ProcessProgress as JSON: each stage's round, what it covered and what
  /// it carries forward. Text only.
  TextColumn get progress => text().withDefault(const Constant('{}'))();
  TextColumn get started => text()();
  TextColumn get updated => text()();
}

/// One answer in a practice round and its evaluation.
@DataClassName('PracticeAnswer')
class CareerAnswers extends Table with SyncedRow {
  TextColumn get sessionId => text()();
  IntColumn get question => integer()();
  TextColumn get answer => text()();
  TextColumn get at => text()();

  /// AnswerReview as JSON, '' until evaluated.
  TextColumn get review => text().withDefault(const Constant(''))();
  RealColumn get score => real().nullable()();
}

/// A document of the candidate's that Udyoga has read: a CV, a reference,
/// interview notes, an advert. The file stays where it is on the device;
/// what was read from it syncs, so every device builds the same profile.
/// The id comes from the content hash, so the same file found on two
/// devices is one row.
@DataClassName('CareerDocument')
class CareerDocuments extends Table with SyncedRow {
  /// SHA-256 of the file's bytes, hex.
  TextColumn get hash => text()();
  TextColumn get name => text()();

  /// cv | reference | interview | advert | application | certificate |
  /// notes | other (see domain/companion.dart).
  TextColumn get kind => text().withDefault(const Constant('other'))();
  TextColumn get summary => text().withDefault(const Constant(''))();

  /// DocumentReading.facts as JSON.
  TextColumn get facts => text().withDefault(const Constant('[]'))();

  /// The text read from the file (Word, text, Markdown); '' for PDFs,
  /// which the AI reads whole.
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get found => text()();

  /// When the AI read it; null until then.
  TextColumn get analysed => text().nullable()();

  /// False when the candidate asked Udyoga to ignore it.
  BoolColumn get use => boolean().withDefault(const Constant(true))();
}

/// A question to the candidate about their own profile: two documents
/// disagree, a claim needs a figure, a point is unconfirmed.
@DataClassName('ProfileQuestion')
class CareerQuestions extends Table with SyncedRow {
  /// What it is about, e.g. "Start date at Acme".
  TextColumn get topic => text()();
  TextColumn get question => text()();

  /// Why it is asked: the conflicting statements and where they are.
  TextColumn get why => text().withDefault(const Constant(''))();

  /// Likely answers to pick from, JSON list of strings.
  TextColumn get choices => text().withDefault(const Constant('[]'))();

  /// open | answered | dismissed
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get answer => text().withDefault(const Constant(''))();
  TextColumn get asked => text()();
  TextColumn get answered => text().nullable()();

  /// True once the answer has been written into the profile.
  BoolColumn get applied => boolean().withDefault(const Constant(false))();
}

/// One day's check-in: the question asked, the candidate's answer and what
/// Udyoga took from it.
@DataClassName('CheckIn')
class CareerJournal extends Table with SyncedRow {
  /// yyyy-MM-dd.
  TextColumn get day => text()();
  TextColumn get prompt => text()();
  TextColumn get entry => text().withDefault(const Constant(''))();

  /// CheckInDigest as JSON, '' until read.
  TextColumn get digest => text().withDefault(const Constant(''))();
  TextColumn get at => text()();
}

/// A story from the candidate's own work, in STAR form, that proves one or
/// more competencies; the raw material for applications and interviews.
@DataClassName('Story')
class CareerStories extends Table with SyncedRow {
  TextColumn get title => text()();
  TextColumn get situation => text().withDefault(const Constant(''))();
  TextColumn get task => text().withDefault(const Constant(''))();
  TextColumn get action => text().withDefault(const Constant(''))();
  TextColumn get result => text().withDefault(const Constant(''))();

  /// Competency ids (domain/companion.dart), JSON list.
  TextColumn get competencies => text().withDefault(const Constant('[]'))();

  /// checkin | document | practice | manual
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get sourceId => text().nullable()();

  /// The role criteria a practice answer evidenced, JSON list of text.
  TextColumn get criteria => text().withDefault(const Constant('[]'))();

  /// False until the candidate has checked it is true as written.
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  TextColumn get added => text()();

  /// Framework standards and person-specification criteria the story
  /// evidences, JSON list of {"framework": id, "item": id}
  /// (domain/evidence.dart). One story can carry many. Added in schema 14.
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// When it happened, yyyy-MM-dd (or yyyy-MM); null when not given, and
  /// then [added] stands in. Added in schema 14.
  TextColumn get happened => text().nullable()();
}

/// Where a story was used: a supporting statement, an application or an
/// interview answer, so the same story is not given twice to one employer.
@DataClassName('StoryUse')
class CareerStoryUses extends Table with SyncedRow {
  TextColumn get storyId => text()();

  /// statement | application | interview
  TextColumn get kind => text()();

  /// The role profile, application or round it went into; '' if none.
  TextColumn get refId => text().withDefault(const Constant(''))();
  TextColumn get employer => text().withDefault(const Constant(''))();
  TextColumn get role => text().withDefault(const Constant(''))();

  /// The criterion it answered, in the person specification's words.
  TextColumn get criterion => text().withDefault(const Constant(''))();
  TextColumn get at => text()();
}

/// Shared with Vidya (see brahma_core's bridges.dart): Udyoga writes the
/// study plan, Vidya writes what was finished.
@DataClassName('StudyPlan')
class BridgeStudyPlans extends Table with SyncedRow, StudyPlanColumns {}

@DataClassName('StudyProgressRow')
class BridgeStudyProgress extends Table with SyncedRow, StudyProgressColumns {}

/// The app-relevant files of the candidate's career file folder, as the
/// device that reads the folder last saw them, so devices without the
/// folder apply the same settings, recipes and Vidya plans. Only an
/// allow-list travels (see domain/career_file_sync.dart), inside the
/// end-to-end-encrypted sync like every other row. The id is the path.
@DataClassName('CareerFileDoc')
class CareerFileDocs extends Table with SyncedRow {
  /// Relative to the career folder, with forward slashes:
  /// `settings/udyoga.json`, `settings/vidya-….json`, `recipes/….json`.
  TextColumn get path => text()();

  /// settings | vidya-plan | recipe
  TextColumn get kind => text()();

  /// SHA-256 of [content] as UTF-8, hex.
  TextColumn get sha256 => text()();

  /// The file's text; '' once removed from the folder (the row is then
  /// tombstoned).
  TextColumn get content => text().withDefault(const Constant(''))();

  /// When this version was read (UTC, ISO 8601).
  TextColumn get updated => text()();

  /// The device that read it: its name, for "from device …".
  TextColumn get device => text().withDefault(const Constant(''))();
}

/// A saved role search (role search plan U3): the role, the family titles
/// shown with which are switched on, NOT words, employers to leave out and
/// places. The routine refresh runs every saved search; the Jobs page shows
/// how many jobs on the list are new since the person last looked.
@DataClassName('SavedSearchRow')
class CareerSavedSearches extends Table with SyncedRow {
  /// What the person calls it; the role until renamed.
  TextColumn get name => text()();

  /// The role as typed.
  TextColumn get role => text()();

  /// Family titles as JSON: each FamilyTitle plus "on" (switched on).
  TextColumn get titles => text().withDefault(const Constant('[]'))();

  /// Search the typed title only (family expansion off).
  BoolColumn get exactOnly => boolean().withDefault(const Constant(false))();

  /// Tasks and tools searched as well, JSON list of text.
  TextColumn get skills => text().withDefault(const Constant('[]'))();

  /// Words that rule a job out, JSON list of text.
  TextColumn get notWords => text().withDefault(const Constant('[]'))();

  /// Employers and agencies left out, JSON list of text.
  TextColumn get notEmployers => text().withDefault(const Constant('[]'))();

  /// HomeArea list as JSON; empty: the profile's home areas.
  TextColumn get places => text().withDefault(const Constant('[]'))();

  /// profile (made from a profile keyword or target role, untouched since)
  /// | user (saved or edited by the person).
  TextColumn get origin => text().withDefault(const Constant('user'))();
  TextColumn get created => text()();
  TextColumn get updated => text()();

  /// When the person last opened it; null: never.
  TextColumn get lastLooked => text().nullable()();

  /// Ids of the listed jobs it matched when last looked at, JSON list, so
  /// the rest count as new.
  TextColumn get seen => text().withDefault(const Constant('[]'))();
}

/// A role insight ("Approach this role", role search plan U4): one row per
/// role, its id taken from the role's title, so asking again on any device
/// replaces the same row instead of adding a second.
@DataClassName('RoleInsightRow')
class CareerRoleInsights extends Table with SyncedRow {
  /// The role as typed.
  TextColumn get role => text()();

  /// The whole insight as JSON (lib/domain/role_insight.dart): every
  /// section with its source and date, AI-written parts marked.
  TextColumn get content => text()();
  TextColumn get created => text()();
  TextColumn get updated => text()();
}

@DataClassName('Pref')
class Prefs extends Table with SyncedRow, PrefColumns {}

@DataClassName('OutboxItem')
class Outbox extends Table with OutboxColumns {}

@DataClassName('SyncCursor')
class SyncCursors extends Table with SyncCursorColumns {}

@DataClassName('LocalSetting')
class LocalSettings extends Table with LocalSettingColumns {}
