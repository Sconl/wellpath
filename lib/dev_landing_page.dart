// lib/dev_landing_page.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// MOVED from lib/landing_page.dart — this is the original developer-focused
// roadmap / project progress page. Accessible via /dev route from the
// production landing page footer.
//
// Class rename only: LandingPage → DevLandingPage.
// Zero logic changes. All CONFIG, data models, phase definitions, and widgets
// are identical to the previous landing_page.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/style/app_branding.dart';
import 'core/style/app_theme.dart';
import 'core/style/app_canvas.dart';
import 'core/style/app_decorations.dart';
import 'core/widgets/app_fab.dart';
import 'core/widgets/app_nav_bar.dart';
import 'core/widgets/developer_feedback_chat.dart';
import 'core/constants/marketing_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

final DateTime kProjectStart  = DateTime(2026, 2, 23);
final DateTime kProjectLaunch = DateTime(2026, 4, 17);

const String kSubtitleText =
    'a web-based integrated fitness and wellness platform:\n'
    'a case study of wellpath';

const String kAuthorName = 'Grace Miriri';
const String kAuthorId   = 'BSIT/445J/2020';

const String kCountdownLabel = 'Countdown to Launch:';
const String kRoadmapLabel   = 'Roadmap';
const String kProgressLabel  = 'Overall Sprint Progress';

const String kHeaderGifPath =
    'assets/gifs/20260312_asset_animated_text_wellpath_landing_page_header_v1.0.0.gif';

const double kPageMaxWidth  = 1100.0;
const double kPagePaddingH  = 60.0;
const double kPagePaddingV  = 32.0;

const double kCardWidth   = 200.0;
const double kCardSpacing = 16.0;
const double kCardHeight  = 185.0;

const double kHeaderGifWidth  = 1200.0;
const double kHeaderGifHeight = 120.0;

const double kSubtitleFontSize     = 16.0;
const double kCountdownFontSize    = 20.0;
const double kRoadmapTitleSize     = 22.0;
const double kAuthorFontSize       = 13.0;
const double kAuthorLetterSpacing  = 1.0;

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

enum _PhaseStatus { completed, active, pending }

class _Milestone {
  final String title;
  final String description;
  final DateTime date;
  _Milestone({required this.title, required this.description, required this.date});
  bool isCompletedAt(DateTime now) => now.isAfter(date);
}

class _Phase {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<_Milestone> milestones;

  _Phase({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.milestones,
  });

  _PhaseStatus statusAt(DateTime now) {
    if (now.isAfter(endDate)) return _PhaseStatus.completed;
    if (now.isAfter(startDate) || now.isAtSameMomentAs(startDate)) return _PhaseStatus.active;
    return _PhaseStatus.pending;
  }

  String statusEmojiAt(DateTime now) {
    switch (statusAt(now)) {
      case _PhaseStatus.completed: return '✅';
      case _PhaseStatus.active:    return '🚧';
      case _PhaseStatus.pending:   return '⏳';
    }
  }

  String statusLabelAt(DateTime now) {
    switch (statusAt(now)) {
      case _PhaseStatus.completed: return 'Completed';
      case _PhaseStatus.active:    return 'Active Development';
      case _PhaseStatus.pending:   return 'Pending';
    }
  }

  Color statusColorAt(DateTime now) {
    switch (statusAt(now)) {
      case _PhaseStatus.completed: return AppColors.success;
      case _PhaseStatus.active:    return AppColors.warning;
      case _PhaseStatus.pending:   return AppColors.textSecondary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase definitions (identical to original)
// ─────────────────────────────────────────────────────────────────────────────

final List<_Phase> _phases = [
  _Phase(
    title: 'Week 1: Firebase & Flutter Init',
    description: 'Firebase projects created, Flutter initialized, email/password auth working, user documents auto-created in Firestore.',
    startDate: DateTime(2026, 2, 23), endDate: DateTime(2026, 2, 27),
    milestones: [
      _Milestone(title: 'Day 1 — Firebase Setup',        date: DateTime(2026, 2, 23), description: 'Create wellpath-dev and wellpath-prod Firebase projects, enable Email/Password Auth, create Firestore DB in test mode, install and login Firebase CLI.'),
      _Milestone(title: 'Day 2 — Flutter Project Setup', date: DateTime(2026, 2, 24), description: 'Create Flutter project, add pubspec.yaml dependencies, run FlutterFire CLI to generate firebase_options.dart.'),
      _Milestone(title: 'Day 3 — Authentication UI',     date: DateTime(2026, 2, 25), description: 'Build AuthRepository (signUp, signIn, signOut, authStateChanges stream), create Riverpod providers, build signup screen.'),
      _Milestone(title: 'Day 4 — Firestore User Creation', date: DateTime(2026, 2, 26), description: 'Auto-create users/{uid} document on signup, build login screen, configure GoRouter auth redirect guard.'),
      _Milestone(title: 'Day 5 — Auth Testing & Commit', date: DateTime(2026, 2, 27), description: 'Full auth flow test: signup → Firestore verify → logout → login. Error cases, loading states, git commit.'),
    ],
  ),
  _Phase(
    title: 'Week 2: Auth Hardening & Roles',
    description: 'Role-based access control (user/trainer), custom JWT claims, user profile screen, protected routing, robust error handling.',
    startDate: DateTime(2026, 3, 2), endDate: DateTime(2026, 3, 6),
    milestones: [
      _Milestone(title: 'Day 6 — Role-Based Access Control', date: DateTime(2026, 3, 2), description: 'Implement custom JWT claims for user/trainer roles via Cloud Function. Write Firestore security rules.'),
      _Milestone(title: 'Day 7 — User Profile Screen',       date: DateTime(2026, 3, 3), description: 'Build ProfileScreen wired to Firestore users/{uid} stream. Edit profile form with Firestore sync.'),
      _Milestone(title: 'Day 8 — Error Handling & Loading',  date: DateTime(2026, 3, 4), description: 'Global LoadingIndicator, ErrorWidget with retry, shimmer placeholders across auth and profile.'),
      _Milestone(title: 'Day 9 — GoRouter Guards',           date: DateTime(2026, 3, 5), description: 'Protected route redirect (unauthenticated → /login). Configure routes. Test deep link preservation.'),
      _Milestone(title: 'Day 10 — Week 2 Integration Test',  date: DateTime(2026, 3, 6), description: 'End-to-end: role claims, Firestore rules in emulator, GoRouter redirects. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 3: Data Architecture & Discovery',
    description: 'Trainer and slot models, Firestore indexes hardened, sample data seeded, trainer list and profile screens built.',
    startDate: DateTime(2026, 3, 9), endDate: DateTime(2026, 3, 13),
    milestones: [
      _Milestone(title: 'Day 11 — Trainer & Slot Models',  date: DateTime(2026, 3, 9),  description: 'Create Trainer and AvailabilitySlot models. Seed 5 Mombasa trainers and 10+ availability slots.'),
      _Milestone(title: 'Day 12 — Firestore Indexes',      date: DateTime(2026, 3, 10), description: 'Add compound indexes, security rules, build TrainerRepository with Riverpod StreamProviders.'),
      _Milestone(title: 'Day 13 — Trainer List Screen',    date: DateTime(2026, 3, 11), description: 'Build TrainerListScreen with ListView.builder, TrainerCard, specialty filter chips, search TextField.'),
      _Milestone(title: 'Day 14 — Trainer Profile Screen', date: DateTime(2026, 3, 12), description: "TrainerProfileScreen with avatar, bio, availability, 'View Availability' CTA. Wire /trainer/:id route."),
      _Milestone(title: 'Day 15 — Responsive Layout',      date: DateTime(2026, 3, 13), description: 'LayoutBuilder breakpoints. Full discovery navigation test. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 4: Booking Flow',
    description: 'AvailabilityRepository, createBooking Cloud Function with atomic transaction, booking UI, My Bookings, trainer view.',
    startDate: DateTime(2026, 3, 14), endDate: DateTime(2026, 3, 18),
    milestones: [
      _Milestone(title: 'Day 16 — Availability Repository',   date: DateTime(2026, 3, 14), description: 'Build AvailabilityRepository and wire availableSlotsProvider. Add slot cards to TrainerProfileScreen.'),
      _Milestone(title: 'Day 17 — createBooking Function',    date: DateTime(2026, 3, 15), description: 'Implement createBooking with full Firestore transaction. Deploy to dev.'),
      _Milestone(title: 'Day 18 — Booking Client UI',         date: DateTime(2026, 3, 16), description: "Build BookingRepository, wire 'Book' button with loading and SnackBar feedback."),
      _Milestone(title: 'Day 19 — My Bookings & Trainer View', date: DateTime(2026, 3, 17), description: 'Build MyBookingsScreen and TrainerBookingsScreen with confirm/cancel actions.'),
      _Milestone(title: 'Day 20 — Race Condition Testing',    date: DateTime(2026, 3, 18), description: 'Concurrent createBooking test, full end-to-end booking test. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 5: Wellness Logging',
    description: 'Three log forms (workout, water, sleep), WellnessRepository, weekly dashboard, goals, calendar heat-map.',
    startDate: DateTime(2026, 3, 19), endDate: DateTime(2026, 3, 23),
    milestones: [
      _Milestone(title: 'Day 21 — Wellness Models & Log Forms', date: DateTime(2026, 3, 19), description: 'Create WellnessLog and Goal models. Build WorkoutLogForm, WaterLogForm, SleepLogForm.'),
      _Milestone(title: 'Day 22 — Wellness Repository',         date: DateTime(2026, 3, 20), description: 'Build WellnessRepository: createLog → users/{uid}/wellnessLogs. Wire providers.'),
      _Milestone(title: 'Day 23 — Weekly Dashboard',            date: DateTime(2026, 3, 21), description: 'Build WellnessDashboardScreen with prev/next week navigation. Real-time stream updates.'),
      _Milestone(title: 'Day 24 — Goals & Calendar Heat-Map',   date: DateTime(2026, 3, 22), description: 'GoalSettingSheet, animated LinearProgressIndicator, 7-day calendar row. Enable offline persistence.'),
      _Milestone(title: 'Day 25 — Wellness Review',             date: DateTime(2026, 3, 23), description: 'Test all three log forms, dashboard accuracy, offline queue sync. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 6: Notifications & Reminders',
    description: 'FCM web setup, booking confirmation push, daily wellness reminder via Cloud Scheduler, settings screen.',
    startDate: DateTime(2026, 3, 24), endDate: DateTime(2026, 3, 28),
    milestones: [
      _Milestone(title: 'Day 26 — FCM Setup & Token Storage', date: DateTime(2026, 3, 24), description: 'Add VAPID key, configure service worker, initialize FirebaseMessaging. Store FCM token in Firestore.'),
      _Milestone(title: 'Day 27 — Booking Push Trigger',       date: DateTime(2026, 3, 25), description: 'Deploy onBookingCreated Firestore trigger: send push to user and trainer.'),
      _Milestone(title: 'Day 28 — FCM Message Handling',       date: DateTime(2026, 3, 26), description: 'Handle FCM in foreground, background, terminated state. Navigate on notification tap.'),
      _Milestone(title: 'Day 29 — Daily Reminder & Settings',  date: DateTime(2026, 3, 27), description: "Deploy sendDailyReminder Cloud Scheduler. Build NotificationSettingsScreen."),
      _Milestone(title: 'Day 30 — Notifications Full Test',    date: DateTime(2026, 3, 28), description: 'End-to-end booking push test. Manually trigger scheduler. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 7: UI Polish & Performance',
    description: 'UI consistency pass, micro-animations, empty states, mobile testing, Lighthouse optimization.',
    startDate: DateTime(2026, 3, 29), endDate: DateTime(2026, 4, 2),
    milestones: [
      _Milestone(title: 'Day 31 — UI Consistency Pass',      date: DateTime(2026, 3, 29), description: 'Audit all screens for typography, spacing, color. Fix layout overflows.'),
      _Milestone(title: 'Day 32 — Micro-Animations',         date: DateTime(2026, 3, 30), description: 'Success micro-animation on log save and booking. Build empty state widgets.'),
      _Milestone(title: 'Day 33 — Mobile Device Testing',    date: DateTime(2026, 3, 31), description: 'Test on physical Android/iOS. Fix tap targets, keyboard-covering fields.'),
      _Milestone(title: 'Day 34 — Lighthouse & Firestore Opt', date: DateTime(2026, 4, 1), description: 'Run Lighthouse audit. Enable Flutter web deferred loading. Verify < 2s page loads.'),
      _Milestone(title: 'Day 35 — Polish Review',            date: DateTime(2026, 4, 2),  description: 'Full visual walkthrough. Accessibility check. Performance targets confirmed. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 8: Analytics & Security',
    description: 'Firebase Analytics, Crashlytics, performance monitoring, Firestore rules test suite, security audit.',
    startDate: DateTime(2026, 4, 3), endDate: DateTime(2026, 4, 7),
    milestones: [
      _Milestone(title: 'Day 36 — Analytics Instrumentation', date: DateTime(2026, 4, 3), description: 'Instrument: booking_created, wellness_log_created, user_signup, trainer_profile_viewed.'),
      _Milestone(title: 'Day 37 — Crashlytics & Performance', date: DateTime(2026, 4, 4), description: 'Configure Crashlytics and FirebasePerformance. Custom trace for createBooking.'),
      _Milestone(title: 'Day 38 — Firestore Rules Test Suite', date: DateTime(2026, 4, 5), description: 'Write @firebase/rules-unit-testing tests. All tests pass in emulator.'),
      _Milestone(title: 'Day 39 — Security Audit',            date: DateTime(2026, 4, 6), description: 'Audit Cloud Functions, CORS config, Hosting security headers. Attempt known attack vectors.'),
      _Milestone(title: 'Day 40 — Security Sign-Off',         date: DateTime(2026, 4, 7), description: 'Fix all findings. Re-run rules test suite. Zero critical issues. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 9: UAT & Bug Fixing',
    description: 'UAT with 5 participants, feedback collection, bug triage, critical/high severity fixes, regression testing.',
    startDate: DateTime(2026, 4, 8), endDate: DateTime(2026, 4, 12),
    milestones: [
      _Milestone(title: 'Day 41 — UAT Preparation',     date: DateTime(2026, 4, 8),  description: 'Prepare UAT environment, seed data, create 5 participant accounts. Write test scenarios.'),
      _Milestone(title: 'Day 42 — UAT Session: Users',  date: DateTime(2026, 4, 9),  description: 'Facilitate UAT with 3 regular users. Scenarios 1 & 2: Discovery, Booking, Wellness.'),
      _Milestone(title: 'Day 43 — UAT Session: Trainers', date: DateTime(2026, 4, 10), description: 'Facilitate UAT with 2 trainers. Scenario 3: Availability, bookings, confirm/cancel.'),
      _Milestone(title: 'Day 44 — Bug Triage & Fixes',  date: DateTime(2026, 4, 11), description: 'Categorize by severity. Fix all critical and high bugs. Regression test.'),
      _Milestone(title: 'Day 45 — Final Regression',    date: DateTime(2026, 4, 12), description: 'Full regression after fixes. Prepare production deployment checklist. Retrospective + commit.'),
    ],
  ),
  _Phase(
    title: 'Week 10: Production Launch',
    description: 'Production Firebase config, Cloud Functions deployed, Flutter web release build, Firebase Hosting live, v1.0.0 tagged.',
    startDate: DateTime(2026, 4, 13), endDate: DateTime(2026, 4, 17),
    milestones: [
      _Milestone(title: 'Day 46 — Production Firebase Config', date: DateTime(2026, 4, 13), description: 'Switch firebase use wellpath-prod. Deploy Firestore rules and all Cloud Functions. Verify healthy.'),
      _Milestone(title: 'Day 47 — Flutter Web Release Build',  date: DateTime(2026, 4, 14), description: 'flutter build web --release. firebase deploy --only hosting. Smoke-test live URL.'),
      _Milestone(title: 'Day 48 — Smoke Test & Billing',       date: DateTime(2026, 4, 15), description: 'Full production smoke test. Set billing alerts. Enable daily Firestore backup.'),
      _Milestone(title: 'Day 49 — Demo & Documentation',       date: DateTime(2026, 4, 16), description: 'Record 5-minute demo video. Update canvas changelog to v1.0.0. Write README.'),
      _Milestone(title: 'Day 50 — v1.0.0 Launch & Monitor',   date: DateTime(2026, 4, 17), description: 'Tag v1.0.0 on GitHub main. Announce to pilot users. Monitor Firebase Console 24 hours.'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatWeekdayDate(DateTime d) {
  const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  const months   = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}, ${d.year}';
}

String _formatShortDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}';
}

// ─────────────────────────────────────────────────────────────────────────────
// DevLandingPage
// ─────────────────────────────────────────────────────────────────────────────

class DevLandingPage extends StatefulWidget {
  const DevLandingPage({super.key});

  @override
  State<DevLandingPage> createState() => _DevLandingPageState();
}

class _DevLandingPageState extends State<DevLandingPage> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  final ScrollController _scrollController = ScrollController();
  int _activeCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final index = (_scrollController.offset / (kCardWidth + kCardSpacing))
        .round()
        .clamp(0, _phases.length - 1);
    if (index != _activeCardIndex) setState(() => _activeCardIndex = index);
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Duration _remaining(DateTime target) => target.difference(_now);

  void _scrollToCard(int index) {
    _scrollController.animateTo(
      index * (kCardWidth + kCardSpacing),
      duration: AppDurations.normal,
      curve: Curves.easeInOut,
    );
  }

  double get _overallProgress {
    final total   = kProjectLaunch.difference(kProjectStart).inSeconds;
    final elapsed = _now.difference(kProjectStart).inSeconds.clamp(0, total);
    return elapsed / total;
  }

  String get _ctaLabel =>
      _now.isAfter(kProjectStart) ? 'Continue Journey →' : 'Begin Journey →';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppCanvas(
            type: BackgroundType.meshParticle,
            particleStyle: ParticleStyle.drift,
            gradientStyle: GradientStyle.pulse,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kPagePaddingH,
                      vertical:   kPagePaddingV,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AppNavBar(
                            navItems:       kMarketingNavItems,
                            logoSize:       LogoSize.lg,
                            ctaLabel:       _ctaLabel,
                            onCta:          () => context.push('/login'),
                            onProfileTap:   () => context.push('/login'),
                            profileIcon:    Icons.person_outline,
                            profileTooltip: 'Sign in or create an account',
                            fullWidth:      true,
                          ),

                          SizedBox(height: AppSpacing.lg - AppSpacing.sm),

                          // ── Dev badge ──────────────────────────────────
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical:   AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color:        AppColors.tint10(AppColors.warning),
                              borderRadius: AppRadius.pillBR,
                              border:       Border.all(color: AppColors.tint20(AppColors.warning)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.code_rounded, size: 13, color: AppColors.warning),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                'Developer Preview — Project Roadmap',
                                style: AppTypography.caption.copyWith(
                                  color:      AppColors.warning,
                                  fontSize:   11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]),
                          ),

                          SizedBox(height: AppSpacing.sm),

                          Image.asset(
                            kHeaderGifPath,
                            width:  kHeaderGifWidth,
                            height: kHeaderGifHeight,
                            fit:    BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),

                          SizedBox(height: AppSpacing.sm + 2),

                          Text(
                            kSubtitleText,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize:   kSubtitleFontSize,
                              height:     1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: AppSpacing.md),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg - AppSpacing.xs,
                              vertical:   AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              border:       Border.all(color: AppColors.borderStrong),
                              borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                            ),
                            child: Text(
                              '$kAuthorName  |  $kAuthorId',
                              style: AppTypography.body.copyWith(
                                fontSize:      kAuthorFontSize,
                                fontWeight:    FontWeight.w600,
                                letterSpacing: kAuthorLetterSpacing,
                              ),
                            ),
                          ),

                          SizedBox(height: AppSpacing.lg),

                          Text(kCountdownLabel, style: AppTypography.bodySmall),
                          SizedBox(height: AppSpacing.xs + 2),
                          _LaunchCountdown(duration: _remaining(kProjectLaunch)),

                          SizedBox(height: AppSpacing.xl),

                          Text(kRoadmapLabel,
                              style: AppTypography.h2.copyWith(fontSize: kRoadmapTitleSize)),
                          SizedBox(height: AppSpacing.sm + 2),
                          _OverallProgressBar(progress: _overallProgress),
                          SizedBox(height: AppSpacing.md),

                          Padding(
                            padding: EdgeInsets.only(top: AppSpacing.sm),
                            child: SizedBox(
                              height: kCardHeight,
                              child: ListView.separated(
                                controller:       _scrollController,
                                scrollDirection:  Axis.horizontal,
                                clipBehavior:     Clip.none,
                                itemCount:        _phases.length,
                                separatorBuilder: (_, __) => const SizedBox(width: kCardSpacing),
                                itemBuilder: (context, index) {
                                  final phase = _phases[index];
                                  return _PhaseCard(
                                    phase:     phase,
                                    remaining: _remaining(phase.endDate),
                                    now:       _now,
                                  );
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: AppSpacing.sm + 2),

                          _ScrollDotIndicator(
                            count:       _phases.length,
                            activeIndex: _activeCardIndex,
                            onTap:       _scrollToCard,
                            now:         _now,
                          ),

                          SizedBox(height: AppSpacing.lg),

                          // ── Back to main site link ──────────────────────
                          GestureDetector(
                            onTap: () => context.go('/landing'),
                            child: Text(
                              '← Back to WellPath website',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          SizedBox(height: kFabSize + kFabMarginBottom + AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right:  kFabMarginRight,
            bottom: kFabMarginBottom,
            child: AppFab(
              icon:    Icons.chat_bubble_outline,
              label:   'Feedback',
              tooltip: 'Chat with our AI assistant — share bugs, ideas, or feedback',
              onPressed: () => showDialog(
                context:         context,
                barrierColor:     AppColors.scrim,
                barrierDismissible: true,
                builder: (_) => const DeveloperFeedbackChat(page: 'dev-landing'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page-specific widgets (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class _OverallProgressBar extends StatelessWidget {
  final double progress;
  const _OverallProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(kProgressLabel, style: AppTypography.overline),
          Text('${pct.toStringAsFixed(1)}%',
              style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ]),
        SizedBox(height: AppSpacing.xs + 2),
        LayoutBuilder(builder: (context, constraints) => Stack(children: [
          Container(height: 4, width: constraints.maxWidth,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            height: 4,
            width: constraints.maxWidth * progress.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              gradient:     AppGradients.button,
              borderRadius: BorderRadius.circular(2),
              boxShadow:    AppShadows.inputFocus,
            ),
          ),
        ])),
      ],
    );
  }
}

class _ScrollDotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final void Function(int) onTap;
  final DateTime now;
  const _ScrollDotIndicator({required this.count, required this.activeIndex, required this.onTap, required this.now});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final color    = _phases[i].statusColorAt(now);
        final isActive = i == activeIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: AppDurations.fast + const Duration(milliseconds: 100),
            margin:   EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width:  isActive ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:        isActive ? color : color.withAlpha(70),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _PhaseCard extends StatefulWidget {
  final _Phase phase;
  final Duration remaining;
  final DateTime now;
  const _PhaseCard({required this.phase, required this.remaining, required this.now});

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _hovered = false;

  void _openModal(BuildContext context) {
    showDialog(
      context:     context,
      barrierColor: AppColors.scrim,
      builder: (context) => _PhaseModal(phase: widget.phase, now: widget.now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase       = widget.phase;
    final status      = phase.statusAt(widget.now);
    final statusColor = phase.statusColorAt(widget.now);
    final isCompleted = status == _PhaseStatus.completed;

    return MouseRegion(
      cursor:   SystemMouseCursors.click,
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openModal(context),
        child: AnimatedContainer(
          duration:  AppDurations.fast,
          curve:     Curves.easeOut,
          width:     kCardWidth,
          height:    kCardHeight,
          padding:   EdgeInsets.all(AppSpacing.sm + 6),
          transform: Matrix4.translationValues(0, _hovered ? -5.0 : 0, 0),
          decoration: BoxDecoration(
            color:        _hovered ? AppColors.surfaceMid : AppColors.surface,
            borderRadius: AppRadius.cardBR,
            border: Border.all(
              color: _hovered ? statusColor : AppColors.border,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: statusColor.withAlpha(55), blurRadius: 16, spreadRadius: 1)]
                : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(phase.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: AppTypography.h5.copyWith(fontSize: 13)),
            SizedBox(height: AppSpacing.xs),
            Text(_formatWeekdayDate(phase.endDate), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 11)),
            SizedBox(height: AppSpacing.xs + 2),
            Row(children: [
              Text(phase.statusEmojiAt(widget.now), style: AppTypography.caption.copyWith(fontSize: 12)),
              SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(phase.statusLabelAt(widget.now),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: statusColor, fontSize: 11))),
            ]),
            const Spacer(),
            if (!isCompleted)
              Text(
                '${widget.remaining.inDays}d ${widget.remaining.inHours % 24}h '
                '${widget.remaining.inMinutes % 60}m ${widget.remaining.inSeconds % 60}s',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
            if (_hovered) ...[
              SizedBox(height: AppSpacing.xs),
              Text('Tap for details →',
                  style: AppTypography.caption.copyWith(
                    color: statusColor.withAlpha(190), fontSize: 10, fontStyle: FontStyle.italic)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PhaseModal extends StatelessWidget {
  final _Phase phase;
  final DateTime now;
  const _PhaseModal({required this.phase, required this.now});

  @override
  Widget build(BuildContext context) {
    final statusColor = phase.statusColorAt(now);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl - AppSpacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: AppDecorations.modal.copyWith(
            border:    Border.all(color: statusColor.withAlpha(100)),
            boxShadow: [BoxShadow(color: statusColor.withAlpha(40), blurRadius: 40, spreadRadius: 4)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl - AppSpacing.xs, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(phase.title, style: AppTypography.h3),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs + 2, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(phase.statusEmojiAt(now), style: AppTypography.body.copyWith(fontSize: 14)),
                      SizedBox(width: AppSpacing.xs + 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs - 1),
                        decoration: BoxDecoration(
                          color:        AppColors.tint10(statusColor),
                          borderRadius: AppRadius.pillBR,
                          border:       Border.all(color: AppColors.tint20(statusColor)),
                        ),
                        child: Text(phase.statusLabelAt(now), style: AppTypography.chip.copyWith(color: statusColor)),
                      ),
                    ]),
                    Text('Due: ${_formatWeekdayDate(phase.endDate)}', style: AppTypography.caption),
                  ]),
                  SizedBox(height: AppSpacing.sm + 2),
                  Text(phase.description, style: AppTypography.bodySmall),
                ])),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                ),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl - AppSpacing.xs, AppSpacing.md, AppSpacing.xl - AppSpacing.xs, AppSpacing.xl),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SPRINT BREAKDOWN', style: AppTypography.overline),
                  SizedBox(height: AppSpacing.sm + 2),
                  ...List.generate(phase.milestones.length, (i) => _MilestoneRow(
                    milestone:   phase.milestones[i],
                    isLast:      i == phase.milestones.length - 1,
                    phaseStatus: phase.statusAt(now),
                    now:         now,
                  )),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final _Milestone milestone;
  final bool isLast;
  final _PhaseStatus phaseStatus;
  final DateTime now;
  const _MilestoneRow({required this.milestone, required this.isLast, required this.phaseStatus, required this.now});

  @override
  Widget build(BuildContext context) {
    final done     = milestone.isCompletedAt(now);
    final dotColor = done
        ? AppColors.success
        : phaseStatus == _PhaseStatus.active
            ? AppColors.warning
            : AppColors.border;
    final emoji = done
        ? '✅'
        : phaseStatus == _PhaseStatus.active ? '🔄' : '⏳';

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 24, child: Column(children: [
          SizedBox(height: AppSpacing.xs - 1),
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color:  dotColor.withAlpha(done ? 255 : 80),
              shape:  BoxShape.circle,
              border: Border.all(color: dotColor, width: 1.5),
            ),
          ),
          if (!isLast)
            Expanded(child: Container(
              width:  1.5,
              margin: EdgeInsets.only(top: AppSpacing.xs),
              color:  AppColors.border,
            )),
        ])),
        SizedBox(width: AppSpacing.md - AppSpacing.xs),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md + 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(emoji, style: AppTypography.body.copyWith(fontSize: 12)),
              SizedBox(width: AppSpacing.xs + 2),
              Expanded(child: Text(milestone.title,
                  style: AppTypography.h5.copyWith(
                    color:    done ? AppColors.success : AppColors.textPrimary,
                    fontSize: 13,
                  ))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs - 2),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.xs + 6)),
                child: Text(_formatShortDate(milestone.date), style: AppTypography.caption.copyWith(fontSize: 11)),
              ),
            ]),
            SizedBox(height: AppSpacing.xs + 1),
            Text(milestone.description, style: AppTypography.caption.copyWith(fontSize: 12, height: 1.55)),
          ]),
        )),
      ]),
    );
  }
}

class _LaunchCountdown extends StatelessWidget {
  final Duration duration;
  const _LaunchCountdown({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${duration.inDays}d ${duration.inHours % 24}h '
      '${duration.inMinutes % 60}m ${duration.inSeconds % 60}s',
      style: AppTypography.h3.copyWith(fontSize: kCountdownFontSize, color: AppColors.primary),
    );
  }
}