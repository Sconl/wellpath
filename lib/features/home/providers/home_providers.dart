// lib/features/home/providers/home_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Five providers + one write repository:
//            featuredTrainersProvider   — public read from `trainers`
//            todayWellnessLogsProvider  — user's logs for the current day
//            upcomingBookingsProvider   — user's confirmed future bookings
//            trainerBookingsProvider    — trainer's confirmed future bookings
//            WellnessLogRepository      — write new logs to Firestore
//
//   ⚠️ COMPOSITE INDEXES REQUIRED before these queries will work in production:
//      1. bookings: (userId ASC, status ASC, slotStartTime ASC)
//      2. bookings: (trainerId ASC, status ASC, slotStartTime ASC)
//      Firebase will throw an error with a direct link to create them the
//      first time either provider is observed in a running app.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/trainer_model.dart';
import '../../wellness/data/wellness_log_model.dart';
import '../../bookings/data/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// How many upcoming bookings to show on the home screen card strip.
// Enough to show intent without hammering Firestore on every home visit.
const _kMaxUpcomingBookings = 5;

// ─────────────────────────────────────────────────────────────────────────────
// Featured Trainers — public read, no auth dependency
//
// kMaxFeaturedTrainers is defined in trainer_model.dart so it lives with the
// schema — avoids a magic number split across two files.
// ─────────────────────────────────────────────────────────────────────────────

final featuredTrainersProvider = StreamProvider<List<TrainerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(kTrainersCollection)
      .limit(kMaxFeaturedTrainers)
      .snapshots()
      .map((snap) => snap.docs.map(TrainerModel.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// Today's Wellness Logs — scoped to the current user + current calendar day
//
// The query brackets [dayStart, dayEnd) filter server-side. No client-side
// filtering needed. The date range is rebuilt on every provider watch which
// is fine — this is cheap and ensures midnight transitions work correctly
// without needing to invalidate the provider at midnight.
// ─────────────────────────────────────────────────────────────────────────────

final todayWellnessLogsProvider = StreamProvider<List<WellnessLog>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection(kWellnessLogsCollection)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
      .where('timestamp', isLessThan: Timestamp.fromDate(dayEnd))
      .snapshots()
      .map((snap) => snap.docs.map(WellnessLog.fromFirestore).toList());
});

final wellnessHistoryProvider = StreamProvider<List<WellnessLog>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection(kWellnessLogsCollection)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(WellnessLog.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// Upcoming Bookings (User) — confirmed sessions in the future, most recent first
//
// ⚠️ Requires composite index: bookings(userId, status, slotStartTime)
// Firebase will log the index creation URL on first query failure.
// ─────────────────────────────────────────────────────────────────────────────

final upcomingBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(kBookingsCollection)
      .where('userId', isEqualTo: uid)
      .where('status', isEqualTo: 'confirmed')
      .where('slotStartTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
      .orderBy('slotStartTime')
      .limit(_kMaxUpcomingBookings)
      .snapshots()
      .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// Upcoming Bookings (Trainer) — same shape, different query axis
//
// ⚠️ Requires composite index: bookings(trainerId, status, slotStartTime)
// ─────────────────────────────────────────────────────────────────────────────

final trainerBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(kBookingsCollection)
      .where('trainerId', isEqualTo: uid)
      .where('status', isEqualTo: 'confirmed')
      .where('slotStartTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
      .orderBy('slotStartTime')
      .limit(_kMaxUpcomingBookings)
      .snapshots()
      .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// WellnessLogRepository — write-only
//
// Screens never import cloud_firestore directly. Keeping all writes here means
// we can swap the data layer without touching the UI at all.
// ─────────────────────────────────────────────────────────────────────────────

class WellnessLogRepository {
  final FirebaseFirestore _db;

  // Injectable for test overrides — default to the real instance.
  WellnessLogRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> addLog({
    required String uid,
    required WellnessType type,
    required double value,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection(kWellnessLogsCollection)
        .add({
      'type': type.name,
      'value': value,
      'metadata': metadata,
      // serverTimestamp is critical — client clocks in Mombasa can drift.
      // A client-side DateTime.now() would corrupt the day-range query.
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

final wellnessLogRepositoryProvider = Provider<WellnessLogRepository>(
  (_) => WellnessLogRepository(),
);
