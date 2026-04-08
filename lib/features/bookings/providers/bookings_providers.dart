// lib/features/bookings/providers/bookings_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/availability_model.dart';
import '../data/booking_model.dart';
import '../data/booking_repository.dart';

const int kSlotWindowDays = 21;
const int kMaxSlotsPerTrainer = 100;
const int kMaxBookingHistory = 50;

final trainerSlotsProvider =
    StreamProvider.family<List<AvailabilitySlot>, String>((ref, trainerId) {
  if (trainerId.isEmpty) return Stream.value([]);

  final now = DateTime.now();
  final windowEnd = now.add(Duration(days: kSlotWindowDays));

  final query = FirebaseFirestore.instance
      .collection(kAvailabilityCollection)
      .where('trainerId', isEqualTo: trainerId)
      .where('status', isEqualTo: SlotStatus.available.value)
      .where('startTime', isGreaterThan: Timestamp.fromDate(now))
      .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(windowEnd))
      .orderBy('startTime')
      .limit(kMaxSlotsPerTrainer);

  // includeMetadataChanges: true ensures the local cache write (from the
  // booking transaction) is reflected immediately before server confirmation.
  return query.snapshots(includeMetadataChanges: true).map((snap) {
    // ignore: avoid_print
    print('[trainerSlotsProvider] docs: ${snap.docs.length}');
    return snap.docs.map(AvailabilitySlot.fromFirestore).toList();
  }).handleError((error, stack) {
    // ignore: avoid_print
    print('[trainerSlotsProvider] ERROR: $error');
  });
});

// ─────────────────────────────────────────────

final myBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(kBookingsCollection)
      .where('userId', isEqualTo: uid)
      .orderBy('slotStartTime', descending: true)
      .limit(kMaxBookingHistory)
      // includeMetadataChanges: true is the key fix for realtime updates:
      // Firestore writes are first committed to the local cache — without this
      // flag, snapshots() only emits on server confirmation, causing a visible
      // delay after booking. With it, the new booking card appears immediately.
      .snapshots(includeMetadataChanges: true)
      .map((snap) =>
          snap.docs.map(BookingModel.fromFirestore).toList())
      .handleError((error, stack) {
        // ignore: avoid_print
        print('[myBookingsProvider] ERROR: $error');
      });
});

// ─────────────────────────────────────────────

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

  return bookings
      .where((b) => b.status == BookingStatus.cancelled)
      .toList();
});

// ─────────────────────────────────────────────

final bookingRepositoryProvider = Provider<BookingRepository>(
  (_) => BookingRepository(),
);

// ─────────────────────────────────────────────

Map<DateTime, List<AvailabilitySlot>> groupSlotsByDate(
    List<AvailabilitySlot> slots) {
  final map = <DateTime, List<AvailabilitySlot>>{};
  for (final slot in slots) {
    final day = DateTime(
      slot.startTime.year,
      slot.startTime.month,
      slot.startTime.day,
    );
    map.putIfAbsent(day, () => []).add(slot);
  }
  return map;
}