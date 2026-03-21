// lib/features/bookings/data/booking_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Mirrors bookings/{bookingId} exactly as spec'd in the
//            Feature 1 data model. `trainerName` and `slotStartTime`/
//            `slotEndTime` are denormalized on write (Cloud Function Week 4)
//            so the home screen can render cards without a join.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const kBookingsCollection = 'bookings';

// ─────────────────────────────────────────────────────────────────────────────
// BookingStatus
// ─────────────────────────────────────────────────────────────────────────────

enum BookingStatus { pending, confirmed, cancelled }

extension BookingStatusX on BookingStatus {
  static BookingStatus fromString(String raw) {
    switch (raw) {
      case 'pending':   return BookingStatus.pending;
      case 'confirmed': return BookingStatus.confirmed;
      case 'cancelled': return BookingStatus.cancelled;
      default:          return BookingStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:   return 'Pending';
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.cancelled: return 'Cancelled';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingModel
// ─────────────────────────────────────────────────────────────────────────────

class BookingModel {
  final String        id;
  final String        userId;
  final String        trainerId;

  // Denormalized so cards can render trainer name without a secondary read.
  // The createBooking Cloud Function (Week 4) must write this field.
  final String        trainerName;

  final String        slotId;
  final BookingStatus status;

  // Also denormalized from the availability slot — same reason as trainerName.
  final DateTime?     slotStartTime;
  final DateTime?     slotEndTime;

  final DateTime?     createdAt;
  final DateTime?     updatedAt;
  final String?       cancelledBy;   // "user" | "trainer" — only set on cancel

  const BookingModel({
    required this.id,
    required this.userId,
    required this.trainerId,
    required this.trainerName,
    required this.slotId,
    required this.status,
    this.slotStartTime,
    this.slotEndTime,
    this.createdAt,
    this.updatedAt,
    this.cancelledBy,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return BookingModel(
      id:            doc.id,
      userId:        data['userId']       as String? ?? '',
      trainerId:     data['trainerId']    as String? ?? '',
      trainerName:   data['trainerName']  as String? ?? 'Trainer',
      slotId:        data['slotId']       as String? ?? '',
      status:        BookingStatusX.fromString(data['status'] as String? ?? ''),
      slotStartTime: (data['slotStartTime'] as Timestamp?)?.toDate(),
      slotEndTime:   (data['slotEndTime']   as Timestamp?)?.toDate(),
      createdAt:     (data['createdAt']     as Timestamp?)?.toDate(),
      updatedAt:     (data['updatedAt']     as Timestamp?)?.toDate(),
      cancelledBy:   data['cancelledBy']    as String?,
    );
  }
}