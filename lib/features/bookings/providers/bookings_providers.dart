// lib/features/bookings/providers/booking_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Six providers + BookingRepository provider:
//
//   availableSlotsProvider(trainerId)  — real-time stream of bookable slots
//   trainerProfileProvider(trainerId)  — trainer document from Firestore
//   allTrainersProvider                — list of all trainers (for profile screen)
//   myBookingsProvider                 — all of this user's bookings (stream)
//   myUpcomingBookingsProvider         — upcoming confirmed bookings only
//   myPastBookingsProvider             — past completed bookings
//   myCancelledBookingsProvider        — cancelled bookings
//   bookingRepositoryProvider          — injectable BookingRepository
//
//   ⚠️  COMPOSITE INDEXES REQUIRED (create in Firebase Console):
//      1. availability: (trainerId ASC, status ASC, startTime ASC)
//      2. bookings:     (userId ASC, status ASC, slotStartTime ASC)
//      3. bookings:     (userId ASC, slotStartTime ASC) — for past bookings
//      Firebase logs the exact creation URL on first query failure.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/trainer_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bookings/data/availability_model.dart';
import '../../bookings/data/booking_model.dart';
import '../../bookings/data/booking_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// Days ahead to show available slots — keeps the slot list focused and fast.
const int kSlotWindowDays = 21;

// Max slots to stream per trainer — prevents runaway reads on power users.
const int kMaxSlotsPerTrainer = 100;

// Max bookings per user for history screens — adjust if users are heavy bookers.
const int kMaxBookingHistory = 50;

// ─────────────────────────────────────────────────────────────────────────────
// availableSlotsProvider — real-time bookable slots for a trainer
//
// Streams only slots that:
//   - belong to the given trainer
//   - have status == 'available'
//   - start in the future (within kSlotWindowDays)
//
// The UI groups these by date for the day-picker UX.
// ─────────────────────────────────────────────────────────────────────────────

final availableSlotsProvider =
    StreamProvider.family<List<AvailabilitySlot>, String>((ref, trainerId) {
  final now = DateTime.now();
  final windowEnd = now.add(Duration(days: kSlotWindowDays));

  return FirebaseFirestore.instance
      .collection(kAvailabilityCollection)
      .where('trainerId', isEqualTo: trainerId)
      .where('status', isEqualTo: SlotStatus.available.value)
      .where('startTime', isGreaterThan: Timestamp.fromDate(now))
      .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(windowEnd))
      .orderBy('startTime')
      .limit(kMaxSlotsPerTrainer)
      .snapshots()
      .map((snap) => snap.docs.map(AvailabilitySlot.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// trainerProfileProvider — trainer document for the profile screen
// ─────────────────────────────────────────────────────────────────────────────

final trainerProfileProvider =
    StreamProvider.family<TrainerProfile?, String>((ref, trainerId) {
  return FirebaseFirestore.instance
      .collection('trainers')
      .doc(trainerId)
      .snapshots()
      .map((doc) => doc.exists ? TrainerProfile.fromFirestore(doc) : null);
});

// ─────────────────────────────────────────────────────────────────────────────
// allTrainersProvider — full list for the discover trainers tab
// ─────────────────────────────────────────────────────────────────────────────

final allTrainersProvider = StreamProvider<List<TrainerProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection('trainers')
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(TrainerProfile.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// myBookingsProvider — full booking history stream for the current user
//
// Intentionally un-filtered — the bookings screen tabs do client-side
// filtering. One stream → three tabs avoids duplicate Firestore listeners.
// ─────────────────────────────────────────────────────────────────────────────

final myBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(kBookingsCollection)
      .where('userId', isEqualTo: uid)
      .orderBy('slotStartTime', descending: true)
      .limit(kMaxBookingHistory)
      .snapshots()
      .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
});

// ── Derived views — avoid re-querying Firestore; filter in-memory ──────────

final myUpcomingBookingsProvider = Provider<List<BookingModel>>((ref) {
  final bookings = ref.watch(myBookingsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return bookings
      .where((b) =>
          b.status == BookingStatus.confirmed &&
          b.slotStartTime != null &&
          b.slotStartTime!.isAfter(now))
      .toList()
    ..sort((a, b) => a.slotStartTime!.compareTo(b.slotStartTime!));
});

final myPastBookingsProvider = Provider<List<BookingModel>>((ref) {
  final bookings = ref.watch(myBookingsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return bookings
      .where((b) =>
          b.status == BookingStatus.confirmed &&
          b.slotStartTime != null &&
          b.slotStartTime!.isBefore(now))
      .toList();
});

final myCancelledBookingsProvider = Provider<List<BookingModel>>((ref) {
  final bookings = ref.watch(myBookingsProvider).valueOrNull ?? [];
  return bookings.where((b) => b.status == BookingStatus.cancelled).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// bookingRepositoryProvider — injectable; tests can override with a mock
// ─────────────────────────────────────────────────────────────────────────────

final bookingRepositoryProvider = Provider<BookingRepository>(
  (_) => BookingRepository(),
);

// ─────────────────────────────────────────────────────────────────────────────
// SlotsByDate — helper for grouping slots in the slot selection sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Groups a flat slot list by calendar date. Keys are midnight DateTime values.
Map<DateTime, List<AvailabilitySlot>> groupSlotsByDate(
    List<AvailabilitySlot> slots) {
  final map = <DateTime, List<AvailabilitySlot>>{};
  for (final slot in slots) {
    final day =
        DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day);
    map.putIfAbsent(day, () => []).add(slot);
  }
  return map;
}
