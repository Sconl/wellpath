// lib/features/home/providers/home_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Five providers + WellnessLogRepository.
//   v2.0.0 — Added wellnessHistoryProvider (last 30 days) for WellnessScreen.
//            Removed featuredTrainersProvider — superseded by allTrainersProvider
//            in discover_providers.dart which the home map now uses directly.
//            upcomingBookingsProvider and trainerBookingsProvider retained —
//            home_screen's _BookingCalendarCard and _NextSessionCard use them.
//
//   ⚠️  COMPOSITE INDEXES REQUIRED:
//      1. bookings: (userId ASC, status ASC, slotStartTime ASC)
//      2. bookings: (trainerId ASC, status ASC, slotStartTime ASC)
//      3. users/{uid}/wellnessLogs: (timestamp ASC) — single-field, auto-created
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../features/wellness/data/wellness_log_model.dart';
import '../../../features/bookings/data/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// How many upcoming bookings to surface on the home dashboard.
const int _kMaxUpcomingBookings = 5;

// History window for WellnessScreen chart + log list.
const int kWellnessHistoryDays = 30;

// ─────────────────────────────────────────────────────────────────────────────
// todayWellnessLogsProvider — logs for today only (home rings + quick-log)
//
// Date range is rebuilt on every provider watch — midnight transitions
// work correctly without needing to invalidate the provider at midnight.
// ─────────────────────────────────────────────────────────────────────────────

final todayWellnessLogsProvider = StreamProvider<List<WellnessLog>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  final now      = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd   = dayStart.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection(kWellnessLogsCollection)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
      .where('timestamp', isLessThan:             Timestamp.fromDate(dayEnd))
      .snapshots()
      .map((snap) =>
          snap.docs.map(WellnessLog.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// wellnessHistoryProvider — last 30 days of logs for WellnessScreen
//
// Used by:
//   - wellness_screen.dart  (7-day chart, weekly goals, recent log list)
// ─────────────────────────────────────────────────────────────────────────────

final wellnessHistoryProvider = StreamProvider<List<WellnessLog>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  final cutoff = DateTime.now()
      .subtract(Duration(days: kWellnessHistoryDays));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection(kWellnessLogsCollection)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(WellnessLog.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// upcomingBookingsProvider — user's confirmed future bookings
//
// Drives _BookingCalendarCard and _NextSessionCard on the home dashboard.
// ⚠️  Requires composite index: bookings(userId, status, slotStartTime)
// ─────────────────────────────────────────────────────────────────────────────

final upcomingBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(kBookingsCollection)
      .where('userId',        isEqualTo:              uid)
      .where('status',        isEqualTo:              'confirmed')
      .where('slotStartTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
      .orderBy('slotStartTime')
      .limit(_kMaxUpcomingBookings)
      .snapshots()
      .map((snap) =>
          snap.docs.map(BookingModel.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// trainerBookingsProvider — trainer's confirmed future bookings
//
// Drives _BookingCalendarCard and _TrainerStatsCard on the trainer dashboard.
// ⚠️  Requires composite index: bookings(trainerId, status, slotStartTime)
// ─────────────────────────────────────────────────────────────────────────────

final trainerBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(kBookingsCollection)
      .where('trainerId',     isEqualTo:              uid)
      .where('status',        isEqualTo:              'confirmed')
      .where('slotStartTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
      .orderBy('slotStartTime')
      .limit(_kMaxUpcomingBookings)
      .snapshots()
      .map((snap) =>
          snap.docs.map(BookingModel.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// WellnessLogRepository — write-only
//
// All Firestore wellness writes go through here — no cloud_firestore imports
// in any screen widget.
// ─────────────────────────────────────────────────────────────────────────────

class WellnessLogRepository {
  final FirebaseFirestore _db;

  WellnessLogRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> addLog({
    required String       uid,
    required WellnessType type,
    required double       value,
    Map<String, dynamic>  metadata = const {},
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection(kWellnessLogsCollection)
        .add({
          'type':      type.name,
          'value':     value,
          'metadata':  metadata,
          // serverTimestamp prevents client clock drift from corrupting
          // day-range queries (client clocks in Mombasa can drift significantly).
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}

final wellnessLogRepositoryProvider = Provider<WellnessLogRepository>(
  (_) => WellnessLogRepository(),
);