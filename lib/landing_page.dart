// landing_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────
// Project schedule constants — edit these and everything
// updates automatically across the whole UI.
// ─────────────────────────────────────────────────────────

final DateTime _projectStart = DateTime(2026, 2, 23); // Week 1 Monday
final DateTime _projectLaunch = DateTime(2026, 5, 1);  // Week 10 Friday

// ─────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────

enum _PhaseStatus { completed, active, pending }

class _Milestone {
  final String title;
  final String description;
  final DateTime date;

  _Milestone({
    required this.title,
    required this.description,
    required this.date,
  });

  /// A milestone is considered done once its target date has passed.
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

  /// Status is derived purely from the current time — no manual flag needed.
  _PhaseStatus statusAt(DateTime now) {
    if (now.isAfter(endDate)) return _PhaseStatus.completed;
    if (now.isAfter(startDate) || now.isAtSameMomentAs(startDate)) {
      return _PhaseStatus.active;
    }
    return _PhaseStatus.pending;
  }

  String statusEmojiAt(DateTime now) {
    switch (statusAt(now)) {
      case _PhaseStatus.completed: return "✅";
      case _PhaseStatus.active:    return "🚧";
      case _PhaseStatus.pending:   return "⏳";
    }
  }

  String statusLabelAt(DateTime now) {
    switch (statusAt(now)) {
      case _PhaseStatus.completed: return "Completed";
      case _PhaseStatus.active:    return "Active Development";
      case _PhaseStatus.pending:   return "Pending";
    }
  }

  Color statusColorAt(DateTime now) {
    switch (statusAt(now)) {
      case _PhaseStatus.completed: return Colors.greenAccent;
      case _PhaseStatus.active:    return Colors.orangeAccent;
      case _PhaseStatus.pending:   return Colors.white54;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Phase definitions — dates drive everything automatically
// ─────────────────────────────────────────────────────────

final List<_Phase> _phases = [
  // ── WEEK 1 ── Core Firebase & Flutter Setup
  _Phase(
    title: "Week 1: Firebase & Flutter Init",
    description: "Firebase projects created, Flutter initialized, email/password auth working, user documents auto-created in Firestore.",
    startDate: DateTime(2026, 2, 23),
    endDate:   DateTime(2026, 2, 27),
    milestones: [
      _Milestone(title: "Day 1 — Firebase Setup", date: DateTime(2026, 2, 23), description: "Create wellpath-dev and wellpath-prod Firebase projects, enable Email/Password Auth, create Firestore DB in test mode, install and login Firebase CLI."),
      _Milestone(title: "Day 2 — Flutter Project Setup", date: DateTime(2026, 2, 24), description: "Create Flutter project, add pubspec.yaml dependencies (firebase_core, firebase_auth, cloud_firestore, flutter_riverpod, go_router), run FlutterFire CLI to generate firebase_options.dart."),
      _Milestone(title: "Day 3 — Authentication UI", date: DateTime(2026, 2, 25), description: "Build AuthRepository (signUp, signIn, signOut, authStateChanges stream), create authRepositoryProvider and authStateProvider in Riverpod, build signup screen with email/password/displayName fields."),
      _Milestone(title: "Day 4 — Firestore User Creation", date: DateTime(2026, 2, 26), description: "Auto-create users/{uid} document on signup (uid, email, displayName, role: 'user', preferences: {dailyReminderEnabled, reminderTime}), build login screen, configure GoRouter with auth redirect guard. ← Current progress"),
      _Milestone(title: "Day 5 — Auth Testing & Commit", date: DateTime(2026, 2, 27), description: "Full auth flow test: signup → Firestore document verify → logout → login. Handle all error cases (email in use, weak password, invalid format, network error). Add loading states. Retrospective + git commit."),
    ],
  ),
  // ── WEEK 2 ── Auth Hardening, Roles & Routing
  _Phase(
    title: "Week 2: Auth Hardening & Roles",
    description: "Role-based access control (user/trainer), custom JWT claims, user profile screen, protected routing, robust error handling and loading states finalized.",
    startDate: DateTime(2026, 3, 2),
    endDate:   DateTime(2026, 3, 6),
    milestones: [
      _Milestone(title: "Day 6 — Role-Based Access Control", date: DateTime(2026, 3, 2), description: "Implement custom JWT claims for user/trainer roles via Cloud Function (setUserRole). Write initial Firestore security rules gating trainer writes behind role claim. Deploy to emulator and verify."),
      _Milestone(title: "Day 7 — User Profile Screen", date: DateTime(2026, 3, 3), description: "Build ProfileScreen (displayName, avatar placeholder, role badge) wired to Firestore users/{uid} stream. Add edit profile form with updateDisplayName and Firestore sync."),
      _Milestone(title: "Day 8 — Error Handling & Loading States", date: DateTime(2026, 3, 4), description: "Create global LoadingIndicator widget, ErrorWidget with retry action, shimmer placeholders for async content. Apply consistently across auth and profile screens."),
      _Milestone(title: "Day 9 — GoRouter Guards & Deep Linking", date: DateTime(2026, 3, 5), description: "Add protected route redirect (unauthenticated → /login). Configure /signup, /login, /home, /profile routes. Test browser refresh and deep link preservation of auth state."),
      _Milestone(title: "Day 10 — Week 2 Integration Testing", date: DateTime(2026, 3, 6), description: "End-to-end test: role claim assignment, Firestore rules in emulator (trainer vs user access), GoRouter redirects verified. Retrospective + commit."),
    ],
  ),
  // ── WEEK 3 ── Data Architecture & Trainer Discovery
  _Phase(
    title: "Week 3: Data Architecture & Discovery",
    description: "Trainer and slot Dart models, Firestore indexes and rules hardened, sample data seeded, trainer list and profile screens built with specialty filter and responsive layout.",
    startDate: DateTime(2026, 3, 9),
    endDate:   DateTime(2026, 3, 13),
    milestones: [
      _Milestone(title: "Day 11 — Trainer & Slot Models + Seed Data", date: DateTime(2026, 3, 9), description: "Create Trainer model (trainerId, displayName, bio, specialties, photoUrl, GeoPoint) and AvailabilitySlot model (slotId, trainerId, startTime, endTime, status). Seed 5 Mombasa trainers and 10+ availability slots in Firestore."),
      _Milestone(title: "Day 12 — Firestore Indexes, Rules & Repositories", date: DateTime(2026, 3, 10), description: "Add compound indexes for specialty filter queries, write security rules (trainers public read, trainer-only slot writes, user own-data). Build TrainerRepository (getTrainers, getTrainerById, getTrainersBySpecialty) with Riverpod StreamProviders."),
      _Milestone(title: "Day 13 — Trainer List Screen", date: DateTime(2026, 3, 11), description: "Build TrainerListScreen with ListView.builder, TrainerCard widget (CircleAvatar, displayName, specialty chips, location). Wire to trainersListProvider. Add horizontal chip specialty filter row and search TextField."),
      _Milestone(title: "Day 14 — Trainer Profile Screen & Routing", date: DateTime(2026, 3, 12), description: "Build TrainerProfileScreen (full avatar, bio, specialty chips, availability section stub, 'View Availability' CTA). Add GoRoute /trainer/:id. Wire trainerByIdProvider. Test tap-to-profile navigation."),
      _Milestone(title: "Day 15 — Responsive Layout & Review", date: DateTime(2026, 3, 13), description: "Implement LayoutBuilder breakpoints (mobile list vs desktop 2-column grid). Test responsive rendering in Chrome DevTools. Full discovery navigation test (list → filter → profile → back). Retrospective + commit."),
    ],
  ),
  // ── WEEK 4 ── Booking Backend & Client
  _Phase(
    title: "Week 4: Booking Flow",
    description: "AvailabilityRepository, Cloud Function createBooking with atomic Firestore transaction, client-side booking UI, My Bookings screen, trainer bookings view, and double-booking prevention tested.",
    startDate: DateTime(2026, 3, 16),
    endDate:   DateTime(2026, 3, 20),
    milestones: [
      _Milestone(title: "Day 16 — Availability Repository & UI", date: DateTime(2026, 3, 16), description: "Build AvailabilityRepository (getAvailableSlots stream: trainerId + status='available', ordered by startTime). Wire availableSlotsProvider.family. Add slot cards to TrainerProfileScreen showing date, time, and status badge."),
      _Milestone(title: "Day 17 — Cloud Function: createBooking", date: DateTime(2026, 3, 17), description: "Init Cloud Functions (Node.js 18). Implement createBooking HTTPS Callable with full Firestore transaction: read slot → verify status='available' → update to 'booked' → create bookings document (userId, trainerId, slotId, status:'pending', createdAt). Deploy to dev."),
      _Milestone(title: "Day 18 — Booking Client & Confirmation UI", date: DateTime(2026, 3, 18), description: "Build BookingRepository: createBooking calls httpsCallable, maps FirebaseFunctionsException to BookingException. Wire 'Book' button: loading dialog → createBooking → SnackBar success/error → navigate to /bookings."),
      _Milestone(title: "Day 19 — My Bookings & Trainer Bookings Screens", date: DateTime(2026, 3, 19), description: "Build MyBookingsScreen (user bookings list: trainer, time, status, cancel action). Build TrainerBookingsScreen (role-gated via JWT claim): incoming bookings, confirm/cancel actions, status updates."),
      _Milestone(title: "Day 20 — Race Condition Testing & Review", date: DateTime(2026, 3, 20), description: "Run Firebase Emulator concurrent test: two simultaneous createBooking calls on same slot — verify only one succeeds. Full booking end-to-end test (browse → book → My Bookings → cancel). Retrospective + commit."),
    ],
  ),
  // ── WEEK 5 ── Wellness Logging & Dashboard
  _Phase(
    title: "Week 5: Wellness Logging",
    description: "Three log forms (workout, water, sleep) each under 10 seconds, WellnessRepository, weekly summary dashboard with progress bars, goal setting, calendar heat-map, and offline queue.",
    startDate: DateTime(2026, 3, 23),
    endDate:   DateTime(2026, 3, 27),
    milestones: [
      _Milestone(title: "Day 21 — Wellness Models & Log Forms", date: DateTime(2026, 3, 23), description: "Create WellnessLog model (type, value, metadata, timestamp) and Goal model. Build WorkoutLogForm (duration + SegmentedButton type), WaterLogForm (glasses Slider), SleepLogForm (hours Slider, 0.5 increments). Each < 10s UX target."),
      _Milestone(title: "Day 22 — Wellness Repository & Providers", date: DateTime(2026, 3, 24), description: "Build WellnessRepository: createLog writes to users/{uid}/wellnessLogs, getLogsStream returns today/week variants. Wire wellnessLogsProvider, createLogProvider in Riverpod. Test Firestore writes for all three log types."),
      _Milestone(title: "Day 23 — Weekly Dashboard", date: DateTime(2026, 3, 25), description: "Build WellnessDashboardScreen: total workout minutes, total water glasses, avg sleep hours for current week with prev/next week navigation. Wire to Firestore date-range query. Real-time stream updates."),
      _Milestone(title: "Day 24 — Goals, Progress Bars & Calendar Heat-Map", date: DateTime(2026, 3, 26), description: "Build GoalSettingSheet (type, targetValue, deadline). Add animated LinearProgressIndicator per goal. Build 7-day calendar row with activity color coding (empty/partial/full). Enable Firestore offline persistence and verify queue-and-sync."),
      _Milestone(title: "Day 25 — Wellness Review & Commit", date: DateTime(2026, 3, 27), description: "Test all three log forms, dashboard accuracy across week boundary, goal progress calculation, offline queue sync on reconnect. Input validation (positive numbers, max caps). Retrospective + commit."),
    ],
  ),
  // ── WEEK 6 ── Push Notifications & Reminders
  _Phase(
    title: "Week 6: Notifications & Reminders",
    description: "FCM web setup with VAPID key, token storage, booking confirmation push for user and trainer, daily wellness reminder Cloud Scheduler, settings screen, and cancellation notifications.",
    startDate: DateTime(2026, 3, 30),
    endDate:   DateTime(2026, 4, 3),
    milestones: [
      _Milestone(title: "Day 26 — FCM Setup & Token Storage", date: DateTime(2026, 3, 30), description: "Add VAPID key, configure firebase-messaging-sw.js service worker, initialize FirebaseMessaging in Flutter. Request push permission on first authenticated visit. Store FCM token in users/{uid}/fcmTokens/{tokenId}. Handle token refresh and permission-denied gracefully."),
      _Milestone(title: "Day 27 — Booking Push Trigger", date: DateTime(2026, 3, 31), description: "Deploy onBookingCreated Firestore trigger: on new bookings/{id}, fetch user and trainer FCM tokens, send 'Booking confirmed with [Trainer]' to user and '[User] booked your slot' to trainer via sendMulticast."),
      _Milestone(title: "Day 28 — FCM Message Handling", date: DateTime(2026, 4, 1), description: "Handle FCM in foreground (in-app banner), background (system notification tray), and terminated state (onMessageOpenedApp). Navigate to relevant screen on notification tap. Test all three app states."),
      _Milestone(title: "Day 29 — Daily Reminder Scheduler & Settings", date: DateTime(2026, 4, 2), description: "Deploy sendDailyReminder Cloud Scheduler (cron '0 20 * * *'): query dailyReminderEnabled=true users, send 'Log your wellness data today!' push. Build NotificationSettingsScreen: toggle + TimePickerDialog (default 20:00), sync to Firestore preferences map. Deploy onBookingCancelled trigger."),
      _Milestone(title: "Day 30 — Notifications Full Test & Commit", date: DateTime(2026, 4, 3), description: "End-to-end booking push test (both parties). Manually trigger Cloud Scheduler from Firebase Console. Test settings persistence across restart. Cancellation notification test (both cancel directions). Retrospective + commit."),
    ],
  ),
  // ── WEEK 7 ── UI Polish & Performance
  _Phase(
    title: "Week 7: UI Polish & Performance",
    description: "Full UI consistency pass, micro-animations, empty state illustrations, mobile responsiveness on physical devices, Lighthouse performance optimization, and Firestore query tuning.",
    startDate: DateTime(2026, 4, 6),
    endDate:   DateTime(2026, 4, 10),
    milestones: [
      _Milestone(title: "Day 31 — UI Consistency Pass", date: DateTime(2026, 4, 6), description: "Audit all screens for typography, spacing, and color consistency. Align to AppColors and AppTextStyles design tokens. Fix any layout overflow or clipping issues on edge-case screen sizes."),
      _Milestone(title: "Day 32 — Micro-Animations & Empty States", date: DateTime(2026, 4, 7), description: "Add success micro-animation (checkmark fade) on log save and booking confirmation. Build empty state widgets for: no trainers, no bookings, no wellness logs. Add shimmer loading placeholders on all async screens."),
      _Milestone(title: "Day 33 — Mobile Device Testing", date: DateTime(2026, 4, 8), description: "Test on physical Android and iOS devices (or BrowserStack). Fix tap target sizes < 44px. Fix keyboard-covering form fields (use Padding + MediaQuery.viewInsetsOf). Test orientation changes."),
      _Milestone(title: "Day 34 — Lighthouse & Firestore Optimization", date: DateTime(2026, 4, 9), description: "Run Chrome Lighthouse audit. Enable Flutter web deferred loading. Add missing Firestore composite indexes. Limit query result sizes with .limit(). Verify createBooking Cloud Function cold start < 2s and page loads < 2s."),
      _Milestone(title: "Day 35 — Polish Review & Commit", date: DateTime(2026, 4, 10), description: "Full visual walkthrough of every screen. Fix all remaining cosmetic issues. Accessibility check (contrast ratios, semantic labels). Performance targets confirmed (< 2s loads). Retrospective + commit."),
    ],
  ),
  // ── WEEK 8 ── Analytics, Monitoring & Security Hardening
  _Phase(
    title: "Week 8: Analytics & Security",
    description: "Firebase Analytics event instrumentation, Crashlytics setup, performance monitoring, complete Firestore rules test suite in emulator, and full security audit sign-off.",
    startDate: DateTime(2026, 4, 13),
    endDate:   DateTime(2026, 4, 17),
    milestones: [
      _Milestone(title: "Day 36 — Firebase Analytics Instrumentation", date: DateTime(2026, 4, 13), description: "Instrument key events: booking_created (trainerId, slotId), wellness_log_created (type), user_signup, trainer_profile_viewed. Verify events appear in Firebase Analytics DebugView. Add week number to wellness events."),
      _Milestone(title: "Day 37 — Crashlytics & Performance Monitoring", date: DateTime(2026, 4, 14), description: "Configure Crashlytics: FlutterError.onError = recordFlutterFatalError, PlatformDispatcher.instance.onError records non-fatal errors. Enable FirebasePerformance. Set up custom trace for createBooking end-to-end duration."),
      _Milestone(title: "Day 38 — Firestore Security Rules Test Suite", date: DateTime(2026, 4, 15), description: "Write @firebase/rules-unit-testing tests: prevent cross-user wellness log reads, prevent client-side booking creation, allow trainer slot writes only for own trainerId, block unauthenticated access to all collections. Run suite in emulator — all tests must pass."),
      _Milestone(title: "Day 39 — Security Audit", date: DateTime(2026, 4, 16), description: "Audit all Cloud Functions for auth checks (context.auth guard on every Callable). Review CORS config. Verify Firebase Hosting security headers. Attempt known attack vectors: direct booking write, cross-user log read, role escalation. Document findings."),
      _Milestone(title: "Day 40 — Security Sign-Off & Commit", date: DateTime(2026, 4, 17), description: "Fix all security audit findings. Re-run rules test suite. Verify Analytics data flowing in console. Confirm zero critical security issues remain. Update canvas risk register. Retrospective + commit."),
    ],
  ),
  // ── WEEK 9 ── UAT & Bug Fixing
  _Phase(
    title: "Week 9: UAT & Bug Fixing",
    description: "User Acceptance Testing with 5 participants across 3 defined scenarios, structured feedback collection, bug triage, and all critical/high severity fixes applied and regression-tested.",
    startDate: DateTime(2026, 4, 20),
    endDate:   DateTime(2026, 4, 24),
    milestones: [
      _Milestone(title: "Day 41 — UAT Preparation", date: DateTime(2026, 4, 20), description: "Prepare UAT environment: seed realistic trainer and availability data, create 5 participant test accounts (3 users + 2 trainers). Write test scenarios and task scripts. Set up Google Forms feedback survey. Deploy latest build to wellpath-dev."),
      _Milestone(title: "Day 42 — UAT Session: Users", date: DateTime(2026, 4, 21), description: "Facilitate UAT with 3 regular user participants: Scenario 1 (Discovery & Booking) and Scenario 2 (Wellness Logging). Observe without intervening. Note all friction points, confusion moments, and bugs. Record session (with consent)."),
      _Milestone(title: "Day 43 — UAT Session: Trainers", date: DateTime(2026, 4, 22), description: "Facilitate UAT with 2 trainer participants: Scenario 3 (Availability Management, bookings view, confirm/cancel). Collect post-task survey responses. Conduct 15-minute 1-on-1 debrief interview per participant."),
      _Milestone(title: "Day 44 — Bug Triage & Critical Fixes", date: DateTime(2026, 4, 23), description: "Categorize all UAT findings by severity (critical / high / medium / low). Fix all critical and high-severity bugs. Regression-test all fixed flows. Update canvas UAT outcomes section."),
      _Milestone(title: "Day 45 — Final Regression & Week 9 Review", date: DateTime(2026, 4, 24), description: "Full regression test of all 3 UAT scenarios after fixes. Verify no new issues introduced. Address any medium bugs if time permits. Retrospective + commit. Prepare production deployment checklist."),
    ],
  ),
  // ── WEEK 10 ── Production Deployment & Launch
  _Phase(
    title: "Week 10: Production Launch",
    description: "Production Firebase project configuration, Firestore rules and Cloud Functions deployed to prod, Flutter web release build, Firebase Hosting live, demo recording, and v1.0.0 tagged.",
    startDate: DateTime(2026, 4, 27),
    endDate:   DateTime(2026, 5, 1),
    milestones: [
      _Milestone(title: "Day 46 — Production Firebase Config", date: DateTime(2026, 4, 27), description: "Switch firebase use wellpath-prod. Deploy finalized Firestore security rules. Deploy all Cloud Functions (createBooking, onBookingCreated, sendDailyReminder, onBookingCancelled, setUserRole) to production. Verify all functions healthy in Firebase Console."),
      _Milestone(title: "Day 47 — Flutter Web Release Build", date: DateTime(2026, 4, 28), description: "Run flutter build web --release. Run firebase deploy --only hosting targeting wellpath-prod. Smoke-test live URL: signup, discover trainers, book a slot, log wellness, receive push notification. Confirm Analytics events firing in production."),
      _Milestone(title: "Day 48 — Production Smoke Test & Billing Setup", date: DateTime(2026, 4, 29), description: "Full production smoke test across all 3 UAT scenarios on live URL. Set Firebase billing alerts at \$10, \$25, and \$50 thresholds. Enable automated daily Firestore backup. Confirm Crashlytics receiving events."),
      _Milestone(title: "Day 49 — Demo Recording & Documentation", date: DateTime(2026, 4, 30), description: "Record 5-minute walkthrough demo video covering: signup, trainer discovery, booking flow, wellness logging, push notification received. Update canvas changelog to v1.0.0. Write README with setup and deployment instructions."),
      _Milestone(title: "Day 50 — v1.0.0 Launch & Monitor", date: DateTime(2026, 5, 1), description: "Tag v1.0.0 on GitHub main branch. Announce to pilot users (5+ trainers pre-onboarded). Monitor Firebase Console for first 24 hours: auth sign-up counts, Firestore read/write rates, Cloud Function invocations, error rates, and performance traces."),
    ],
  ),
];

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

String _formatWeekdayDate(DateTime d) {
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return "${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}, ${d.year}";
}

String _formatShortDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return "${months[d.month - 1]} ${d.day}";
}

// ─────────────────────────────────────────────────────────
// Landing Page
// ─────────────────────────────────────────────────────────

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  late Timer _timer;
  DateTime _now = DateTime.now();

  final ScrollController _scrollController = ScrollController();
  int _activeCardIndex = 0;

  static const double _cardWidth = 200.0;
  static const double _cardSpacing = 16.0;
  static const double _cardHeight = 185.0;

  @override
  void initState() {
    super.initState();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final index = (offset / (_cardWidth + _cardSpacing)).round().clamp(0, _phases.length - 1);
    if (index != _activeCardIndex) {
      setState(() => _activeCardIndex = index);
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _timer.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Duration _remaining(DateTime target) => target.difference(_now);

  void _scrollToCard(int index) {
    _scrollController.animateTo(
      index * (_cardWidth + _cardSpacing),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Overall sprint progress: days elapsed / total sprint days (0.0 → 1.0)
  double get _overallProgress {
    final total = _projectLaunch.difference(_projectStart).inSeconds;
    final elapsed = _now.difference(_projectStart).inSeconds.clamp(0, total);
    return elapsed / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          final start = Color.lerp(
            const Color(0xFF031F1C),
            const Color(0xFF00B85C),
            _gradientController.value,
          )!;
          const end = Color(0xFF00110A);

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [start, end],
                  ),
                ),
              ),
              const Positioned.fill(child: _ParticleField()),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 32),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Well",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 46,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Path",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 46,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "A WEB-BASED INTEGRATED FITNESS AND WELLNESS PLATFORM:\nA CASE STUDY OF WELLPATH",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white30, width: 1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "GRACE MIRIRI  |  BSIT/445J/2020",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Countdown to Launch:",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            _LaunchCountdown(duration: _remaining(_projectLaunch)),
                            const SizedBox(height: 32),

                            // ── Roadmap header ────────────────────────────
                            const Text(
                              "Roadmap",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── Overall progress bar ──────────────────────
                            _OverallProgressBar(progress: _overallProgress),
                            const SizedBox(height: 16),

                            // ── Card list — top padding gives hover lift room ──
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                height: _cardHeight,
                                child: ListView.separated(
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: _phases.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: _cardSpacing),
                                  itemBuilder: (context, index) {
                                    final phase = _phases[index];
                                    return _PhaseCard(
                                      phase: phase,
                                      remaining: _remaining(phase.endDate),
                                      now: _now,
                                      cardWidth: _cardWidth,
                                      cardHeight: _cardHeight,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Scroll dot indicator ──────────────────────
                            _ScrollDotIndicator(
                              count: _phases.length,
                              activeIndex: _activeCardIndex,
                              onTap: _scrollToCard,
                              now: _now,
                            ),
                            const SizedBox(height: 28),

                            // ── CTA Button ────────────────────────────────
                            _BeginJourneyButton(
                              projectStart: _projectStart,
                              now: _now,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Overall Progress Bar
// ─────────────────────────────────────────────────────────

class _OverallProgressBar extends StatelessWidget {
  final double progress;
  const _OverallProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Overall Sprint Progress",
              style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5),
            ),
            Text(
              "${pct.toStringAsFixed(1)}%",
              style: const TextStyle(
                color: Color(0xFF00CC66),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 4,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  height: 4,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00CC66), Color(0xFF00FF99)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x5500CC66),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Scroll Dot Indicator
// ─────────────────────────────────────────────────────────

class _ScrollDotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final void Function(int) onTap;
  final DateTime now;

  const _ScrollDotIndicator({
    required this.count,
    required this.activeIndex,
    required this.onTap,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final phase = _phases[i];
        final color = phase.statusColorAt(now);
        final isActive = i == activeIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? color : color.withAlpha(70),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Begin Journey Button
// ─────────────────────────────────────────────────────────

class _BeginJourneyButton extends StatefulWidget {
  final DateTime projectStart;
  final DateTime now;

  const _BeginJourneyButton({
    required this.projectStart,
    required this.now,
  });

  @override
  State<_BeginJourneyButton> createState() => _BeginJourneyButtonState();
}

class _BeginJourneyButtonState extends State<_BeginJourneyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasStarted = widget.now.isAfter(widget.projectStart);
    final label = hasStarted ? "Continue Journey →" : "Begin Journey →";

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hovered
                ? [const Color(0xFF00FF99), const Color(0xFF00CC66)]
                : [const Color(0xFF00CC66), const Color(0xFF009944)],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00CC66).withAlpha(_hovered ? 100 : 50),
              blurRadius: _hovered ? 24 : 12,
              spreadRadius: _hovered ? 2 : 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _hovered ? const Color(0xFF001A0A) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Phase Card
// ─────────────────────────────────────────────────────────

class _PhaseCard extends StatefulWidget {
  final _Phase phase;
  final Duration remaining;
  final DateTime now;
  final double cardWidth;
  final double cardHeight;

  const _PhaseCard({
    required this.phase,
    required this.remaining,
    required this.now,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _hovered = false;

  void _openModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _PhaseModal(phase: widget.phase, now: widget.now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final status = phase.statusAt(widget.now);
    final statusColor = phase.statusColorAt(widget.now);
    final isCompleted = status == _PhaseStatus.completed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openModal(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.cardWidth,
          height: widget.cardHeight,
          padding: const EdgeInsets.all(14),
          transform: Matrix4.translationValues(0.0, _hovered ? -5.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color.fromARGB(220, 2, 28, 14)
                : const Color.fromARGB(190, 1, 20, 10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? statusColor : Colors.white24,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: statusColor.withAlpha(55), blurRadius: 16, spreadRadius: 1)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title — clamp to 2 lines max, no overflow
              Text(
                phase.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatWeekdayDate(phase.endDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(phase.statusEmojiAt(widget.now), style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      phase.statusLabelAt(widget.now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: statusColor, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!isCompleted)
                Text(
                  "${widget.remaining.inDays}d "
                  "${widget.remaining.inHours % 24}h "
                  "${widget.remaining.inMinutes % 60}m "
                  "${widget.remaining.inSeconds % 60}s",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              if (_hovered) ...[
                const SizedBox(height: 4),
                Text(
                  "Tap for details →",
                  style: TextStyle(
                    color: statusColor.withAlpha(190),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Phase Modal
// ─────────────────────────────────────────────────────────

class _PhaseModal extends StatelessWidget {
  final _Phase phase;
  final DateTime now;

  const _PhaseModal({required this.phase, required this.now});

  @override
  Widget build(BuildContext context) {
    final statusColor = phase.statusColorAt(now);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF020E08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(100), width: 1),
            boxShadow: [
              BoxShadow(
                color: statusColor.withAlpha(40),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phase.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(phase.statusEmojiAt(now), style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor.withAlpha(80)),
                                    ),
                                    child: Text(
                                      phase.statusLabelAt(now),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "Due: ${_formatWeekdayDate(phase.endDate)}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            phase.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),

              // ── Milestone list ───────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SPRINT BREAKDOWN",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(phase.milestones.length, (i) {
                        final m = phase.milestones[i];
                        final isLast = i == phase.milestones.length - 1;
                        return _MilestoneRow(
                          milestone: m,
                          isLast: isLast,
                          phaseStatus: phase.statusAt(now),
                          now: now,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Milestone Row
// ─────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final _Milestone milestone;
  final bool isLast;
  final _PhaseStatus phaseStatus;
  final DateTime now;

  const _MilestoneRow({
    required this.milestone,
    required this.isLast,
    required this.phaseStatus,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final done = milestone.isCompletedAt(now);

    final dotColor = done
        ? Colors.greenAccent
        : phaseStatus == _PhaseStatus.active
            ? Colors.orangeAccent
            : Colors.white24;

    final String milestoneEmoji = done
        ? "✅"
        : phaseStatus == _PhaseStatus.active
            ? "🔄"
            : "⏳";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline track
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor.withAlpha(done ? 255 : 80),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(top: 4),
                      color: Colors.white12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(milestoneEmoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            color: done ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatShortDate(milestone.date),
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    milestone.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Launch Countdown
// ─────────────────────────────────────────────────────────

class _LaunchCountdown extends StatelessWidget {
  final Duration duration;
  const _LaunchCountdown({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Text(
      "${duration.inDays}d "
      "${duration.inHours % 24}h "
      "${duration.inMinutes % 60}m "
      "${duration.inSeconds % 60}s",
      style: const TextStyle(
        color: Color(0xFF00CC66),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Particle Field
// ─────────────────────────────────────────────────────────

class _ParticleField extends StatefulWidget {
  const _ParticleField();

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => CustomPaint(painter: _ParticlePainter(controller.value)),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00CC66).withAlpha(50);
    for (int i = 0; i < 40; i++) {
      final dx = (size.width / 40) * i + sin(progress * pi * 2 + i) * 40;
      final dy = (size.height * progress + i * 50) % size.height;
      final radius = 5 + sin(progress * pi + i) * 3;
      canvas.drawCircle(Offset(dx, dy), radius.abs(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}