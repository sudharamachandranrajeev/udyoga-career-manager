import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';

import '../ui/applications_page.dart';
import '../ui/career_page.dart';
import '../ui/coach_page.dart';
import '../ui/contacts_page.dart';
import '../ui/conversations_page.dart';
import '../ui/growth_page.dart';
import '../ui/interview_page.dart';
import '../ui/jobs_page.dart';
import '../ui/linkedin_page.dart';
import '../ui/network_page.dart';
import '../ui/profile_page.dart';
import '../ui/today_page.dart';
import 'navigation.dart';
import 'settings_page.dart';

// Every page, by id. The ids are the old navigation ids, so anything that
// opens a page by id still finds it; most now live inside a group.

final todayPage = Destination(
  id: 'today',
  label: 'Today',
  icon: Icons.today_outlined,
  selectedIcon: Icons.today,
  primary: true,
  page: (_) => const TodayPage(),
);

final jobsPage = Destination(
  id: 'jobs',
  label: 'Jobs',
  icon: Icons.work_outline,
  selectedIcon: Icons.work,
  page: (_) => const JobsPage(),
);

final applicationsPage = Destination(
  id: 'applications',
  label: 'Applications',
  icon: Icons.send_outlined,
  selectedIcon: Icons.send,
  page: (_) => const ApplicationsPage(),
);

/// Every conversation with every person, on any channel, as chat threads.
/// It opens the Network entry, so the phone dock keeps five entries that fit.
final conversationsPage = Destination(
  id: 'conversations',
  label: 'Conversations',
  icon: Icons.forum_outlined,
  selectedIcon: Icons.forum,
  page: (_) => const ConversationsPage(),
);

/// Finding people in the field: who you know, search links, advert
/// contacts and communities.
final findPeoplePage = Destination(
  id: 'find-people',
  label: 'Find people',
  icon: Icons.person_search_outlined,
  selectedIcon: Icons.person_search,
  page: (_) => const LeadFinderPage(),
);

final contactsPage = Destination(
  id: 'contacts',
  label: 'Contacts',
  icon: Icons.contacts_outlined,
  selectedIcon: Icons.contacts,
  page: (_) => const ContactsPage(),
);

final linkedinPage = Destination(
  id: 'linkedin',
  label: 'LinkedIn',
  icon: Icons.campaign_outlined,
  selectedIcon: Icons.campaign,
  page: (_) => const LinkedInPage(),
);

final interviewPage = Destination(
  id: 'interview',
  label: 'Interview',
  icon: Icons.record_voice_over_outlined,
  selectedIcon: Icons.record_voice_over,
  page: (_) => const InterviewPage(),
);

final coachPage = Destination(
  id: 'coach',
  label: 'Coach',
  icon: Icons.psychology_alt_outlined,
  selectedIcon: Icons.psychology_alt,
  page: (_) => const CoachPage(),
);

final growthPage = Destination(
  id: 'growth',
  label: 'Growth',
  icon: Icons.school_outlined,
  selectedIcon: Icons.school,
  page: (_) => const GrowthPage(),
);

final profilePage = Destination(
  id: 'profile',
  label: 'Profile',
  icon: Icons.badge_outlined,
  selectedIcon: Icons.badge,
  page: (_) => const ProfilePage(),
);

final careerPage = Destination(
  id: 'career',
  label: 'Career',
  icon: Icons.account_tree_outlined,
  selectedIcon: Icons.account_tree,
  page: (_) => const CareerPage(),
);

/// Settings is app-wide; it sits last, under You.
final settingsPage = Destination(
  id: 'settings',
  label: 'Settings',
  icon: Icons.settings_outlined,
  selectedIcon: Icons.settings,
  page: (_) => const SettingsPage(),
);

/// The navigation's grouped entries, each a switch over its pages.
final pageGroups = <PageGroup>[
  PageGroup(
    id: 'jobs',
    label: 'Jobs',
    icon: Icons.work_outline,
    selectedIcon: Icons.work,
    pages: [jobsPage, applicationsPage],
  ),
  PageGroup(
    id: 'network',
    label: 'Network',
    icon: Icons.hub_outlined,
    selectedIcon: Icons.hub,
    pages: [conversationsPage, contactsPage, findPeoplePage, linkedinPage],
  ),
  PageGroup(
    id: 'prepare',
    label: 'Prepare',
    icon: Icons.record_voice_over_outlined,
    selectedIcon: Icons.record_voice_over,
    pages: [interviewPage, coachPage, growthPage],
  ),
  PageGroup(
    id: 'you',
    label: 'You',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    pages: [profilePage, careerPage, settingsPage],
  ),
];

final careerModule = AppModule(
  id: 'career',
  name: 'Career',
  destinations: [todayPage, for (final g in pageGroups) g.destination],
);

final modules = <AppModule>[careerModule];

/// The navigation's entries, in order: what the shell shows.
List<Destination> get allDestinations => [for (final m in modules) ...m.destinations];

/// Every page, in navigation order, grouped or not.
List<Destination> get allPages => [todayPage, for (final g in pageGroups) ...g.pages];

/// The group page [id] lives in, or null for a page of its own (Today).
PageGroup? groupOf(String id) => pageGroups.where((g) => g.pages.any((p) => p.id == id)).firstOrNull;
