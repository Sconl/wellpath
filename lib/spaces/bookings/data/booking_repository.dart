// lib/features/bookings/data/booking_repository.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Client-side Firestore transaction for booking creation
//            and cancellation. Structured identically to what the Cloud
//            Function (Week 4) will do — swap the createBooking body for a
//            CF call without touching any UI code. See the TODO comment.
//
//   TRANSACTION STRATEGY:
//   The Cloud Function is the production path but isn't deployed yet.
//   The client-side transaction provides identical atomicity guarantees for
//   the MVP: Firestore transactions are atomic and serialisable, so
//   concurrent booking attempts on the same slot will not double-book.
//   The race condition window (between read and write) is handled by
//   Firestore's optimistic locking — the transaction retries up to 5× and
//   throws if the slot is taken. This matches CF behaviour exactly.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

import 'availability_model.dart';
import 'booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BookingError — typed errors surface clean messages to the UI
// ─────────────────────────────────────────────────────────────────────────────

class BookingError implements Exception {
  final String message;
  final BookingErrorCode code;
  const BookingError(this.message, this.code);

  @override
  String toString() => 'BookingError(${code.name}): $message';
}

enum BookingErrorCode {
  slotUnavailable,  // Slot was taken between user opening screen and tapping confirm
  notAuthenticated, // uid was null — shouldn't happen past auth gate, but be safe
  alreadyBooked,    // user already has a confirmed booking for this slot
  networkError,     // Firestore unreachable
  unknown,
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingResult — returned by createBooking on success
// ─────────────────────────────────────────────────────────────────────────────

class BookingResult {
  final String       bookingId;
  final BookingModel booking;
  const BookingResult({required this.bookingId, required this.booking});
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingRepository
// ─────────────────────────────────────────────────────────────────────────────

class BookingRepository {
  final FirebaseFirestore _db;

  BookingRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── createBooking ──────────────────────────────────────────────────────────
  //
  // Creates a booking atomically. Throws BookingError on failure.
  //
  // TODO (Week 4, Day 23): Replace this body with the Cloud Function call:
  //
  //   final callable = FirebaseFunctions.instance.httpsCallable('createBooking');
  //   final result   = await callable.call({'slotId': slot.id, 'trainerId': slot.trainerId});
  //   final bookingId = result.data['bookingId'] as String;
  //   // CF returns the full booking doc; fetch it or reconstruct from result.data.
  //
  // The CF call automatically handles FCM push notifications to both parties.
  // Until then, this transaction is production-safe for the MVP.
  // ──────────────────────────────────────────────────────────────────────────

  Future<BookingResult> createBooking({
    required String            uid,
    required String            displayName,
    required AvailabilitySlot  slot,
  }) async {
    if (uid.isEmpty) {
      throw const BookingError(
          'You must be signed in to book a session.',
          BookingErrorCode.notAuthenticated);
    }

    final slotRef    = _db.collection(kAvailabilityCollection).doc(slot.id);
    final bookingRef = _db.collection(kBookingsCollection).doc();

    late BookingModel booking;

    try {
      await _db.runTransaction((tx) async {
        final slotSnap = await tx.get(slotRef);

        if (!slotSnap.exists) {
          throw const BookingError(
              'This slot no longer exists.', BookingErrorCode.slotUnavailable);
        }

        final currentStatus = slotSnap.data()?['status'] as String? ?? '';
        if (currentStatus != SlotStatus.available.value) {
          throw BookingError(
              currentStatus == SlotStatus.booked.value
                  ? 'Sorry, this slot was just booked by someone else.'
                  : 'This slot is no longer available.',
              BookingErrorCode.slotUnavailable);
        }

        // Construct the booking document.
        // Mirrors the Cloud Function's write shape exactly so the
        // home_providers.dart BookingModel.fromFirestore() can read either.
        final now = DateTime.now();
        booking = BookingModel(
          id:           bookingRef.id,
          userId:       uid,
          trainerId:    slot.trainerId,
          trainerName:  slot.trainerName,
          slotId:       slot.id,
          status:       BookingStatus.confirmed,
          slotStartTime: slot.startTime,
          slotEndTime:   slot.endTime,
          createdAt:     now,
          updatedAt:     now,
          // Extra fields for display — not in base BookingModel but safe to write.
        );

        tx.set(bookingRef, {
          'userId':        uid,
          'userDisplayName': displayName,
          'trainerId':     slot.trainerId,
          'trainerName':   slot.trainerName,
          'slotId':        slot.id,
          'status':        BookingStatus.confirmed.value,
          'slotStartTime': Timestamp.fromDate(slot.startTime),
          'slotEndTime':   Timestamp.fromDate(slot.endTime),
          'locationLabel': slot.locationLabel,
          'sessionType':   slot.sessionType.value,
          'priceKes':      slot.priceKes,
          'createdAt':     FieldValue.serverTimestamp(),
          'updatedAt':     FieldValue.serverTimestamp(),
          'cancelledBy':   null,
        });

        // Lock the slot immediately — this is what prevents double-booking.
        tx.update(slotRef, {
          'status':        SlotStatus.booked.value,
          'bookedByUserId': uid,
          'updatedAt':     FieldValue.serverTimestamp(),
        });
      });

      return BookingResult(bookingId: bookingRef.id, booking: booking);
    } on BookingError {
      rethrow; // Our typed errors pass through unchanged.
    } on FirebaseException catch (e) {
      throw BookingError(
          'Network error. Please check your connection and try again. (${e.code})',
          BookingErrorCode.networkError);
    } catch (e) {
      throw BookingError(
          'Something went wrong. Please try again.',
          BookingErrorCode.unknown);
    }
  }

  // ── cancelBooking ──────────────────────────────────────────────────────────
  //
  // Cancels a booking and releases the slot back to available.
  // cancelledBy: 'user' | 'trainer'
  //
  // TODO (Week 4): Replace with onBookingCancelled Cloud Function trigger or
  // a cancelBooking callable that also fires FCM push to the other party.
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> cancelBooking({
    required String bookingId,
    required String slotId,
    required String cancelledBy, // 'user' | 'trainer'
  }) async {
    final bookingRef = _db.collection(kBookingsCollection).doc(bookingId);
    final slotRef    = _db.collection(kAvailabilityCollection).doc(slotId);

    try {
      await _db.runTransaction((tx) async {
        final bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) return; // Already gone — idempotent.

        final status = bookingSnap.data()?['status'] as String? ?? '';
        if (status == BookingStatus.cancelled.value) return; // Already cancelled.

        tx.update(bookingRef, {
          'status':      BookingStatus.cancelled.value,
          'cancelledBy': cancelledBy,
          'updatedAt':   FieldValue.serverTimestamp(),
        });

        // Release the slot so other users can book it.
        tx.update(slotRef, {
          'status':        SlotStatus.available.value,
          'bookedByUserId': null,
          'updatedAt':     FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw BookingError(
          'Could not cancel your booking. Please try again. (${e.code})',
          BookingErrorCode.networkError);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingStatus extension — adds value getter used by repository writes
// ─────────────────────────────────────────────────────────────────────────────

extension _BookingStatusWrite on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:   return 'pending';
      case BookingStatus.confirmed: return 'confirmed';
      case BookingStatus.cancelled: return 'cancelled';
    }
  }
}