// lib/features/bookings/data/availability_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Maps availability/{slotId} Firestore collection.
//            SlotStatus enum mirrors what the createBooking Cloud Function
//            reads and writes — never change values without updating CF too.
//            priceKes + sessionType + locationLabel are optional — trainers
//            that don't set these get sensible display defaults.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const String kAvailabilityCollection = 'availability';

// Default session duration shown when endTime is absent (shouldn't happen in
// production — the trainer app always writes both, but defensive handling here).
const int kDefaultSessionDurationMinutes = 60;

// ─────────────────────────────────────────────────────────────────────────────
// SlotStatus
//
// The Cloud Function reads these exact string values from Firestore.
// Changing the enum names here without updating the CF will break bookings.
// ─────────────────────────────────────────────────────────────────────────────

enum SlotStatus { available, booked, cancelled }

extension SlotStatusX on SlotStatus {
  static SlotStatus fromString(String raw) {
    switch (raw) {
      case 'available': return SlotStatus.available;
      case 'booked':    return SlotStatus.booked;
      case 'cancelled': return SlotStatus.cancelled;
      default:          return SlotStatus.available;
    }
  }

  String get value {
    switch (this) {
      case SlotStatus.available: return 'available';
      case SlotStatus.booked:    return 'booked';
      case SlotStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case SlotStatus.available: return 'Available';
      case SlotStatus.booked:    return 'Booked';
      case SlotStatus.cancelled: return 'Cancelled';
    }
  }

  bool get isBookable => this == SlotStatus.available;
}

// ─────────────────────────────────────────────────────────────────────────────
// SessionType — maps to what trainers advertise
// ─────────────────────────────────────────────────────────────────────────────

enum SessionType { personal, group, online, assessment }

extension SessionTypeX on SessionType {
  static SessionType fromString(String raw) {
    switch (raw) {
      case 'group':      return SessionType.group;
      case 'online':     return SessionType.online;
      case 'assessment': return SessionType.assessment;
      default:           return SessionType.personal;
    }
  }

  String get value {
    switch (this) {
      case SessionType.personal:   return 'personal';
      case SessionType.group:      return 'group';
      case SessionType.online:     return 'online';
      case SessionType.assessment: return 'assessment';
    }
  }

  String get label {
    switch (this) {
      case SessionType.personal:   return 'Personal Training';
      case SessionType.group:      return 'Group Session';
      case SessionType.online:     return 'Online Session';
      case SessionType.assessment: return 'Fitness Assessment';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AvailabilitySlot
//
// Firestore document shape:
// availability/{slotId} {
//   trainerId:      string    ← required. Indexed for availableSlotsProvider query.
//   trainerName:   string    ← denormalized. Avoids secondary read when listing slots.
//   startTime:     Timestamp ← required.
//   endTime:       Timestamp ← required. Cloud Function validates endTime > startTime.
//   status:        string    ← "available" | "booked" | "cancelled"
//   bookedByUserId: string?  ← set by createBooking Cloud Function on booking.
//   locationLabel: string?   ← "Mombasa Sports Club", "Online", etc.
//   sessionType:   string?   ← "personal" | "group" | "online" | "assessment"
//   priceKes:      number?   ← price in Kenyan Shillings. null = "Contact trainer"
//   notes:         string?   ← optional trainer notes shown to booked user
//   createdAt:     Timestamp
// }
// ─────────────────────────────────────────────────────────────────────────────

class AvailabilitySlot {
  final String      id;
  final String      trainerId;
  final String      trainerName;
  final DateTime    startTime;
  final DateTime    endTime;
  final SlotStatus  status;
  final String?     bookedByUserId;
  final String?     locationLabel;
  final SessionType sessionType;
  final double?     priceKes;
  final String?     notes;
  final DateTime?   createdAt;

  const AvailabilitySlot({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookedByUserId,
    this.locationLabel,
    this.sessionType = SessionType.personal,
    this.priceKes,
    this.notes,
    this.createdAt,
  });

  // Duration is calculated, not stored — avoids stale data if trainer edits times.
  Duration get duration => endTime.difference(startTime);

  int get durationMinutes => duration.inMinutes;

  // Formatting helpers used by slot cards and confirmation screens.
  String get priceDisplay =>
      priceKes != null ? 'KES ${priceKes!.toStringAsFixed(0)}' : 'Contact trainer';

  String get locationDisplay => locationLabel ?? 'Location TBC';

  factory AvailabilitySlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AvailabilitySlot(
      id:             doc.id,
      trainerId:      data['trainerId']    as String? ?? '',
      trainerName:    data['trainerName']  as String? ?? 'Trainer',
      startTime:      (data['startTime']   as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime:        (data['endTime']     as Timestamp?)?.toDate() ??
                          DateTime.now().add(const Duration(hours: 1)),
      status:         SlotStatusX.fromString(data['status'] as String? ?? 'available'),
      bookedByUserId: data['bookedByUserId'] as String?,
      locationLabel:  data['locationLabel']  as String?,
      sessionType:    SessionTypeX.fromString(data['sessionType'] as String? ?? ''),
      priceKes:       (data['priceKes'] as num?)?.toDouble(),
      notes:          data['notes'] as String?,
      createdAt:      (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'trainerId':      trainerId,
    'trainerName':    trainerName,
    'startTime':      Timestamp.fromDate(startTime),
    'endTime':        Timestamp.fromDate(endTime),
    'status':         status.value,
    'bookedByUserId': bookedByUserId,
    'locationLabel':  locationLabel,
    'sessionType':    sessionType.value,
    'priceKes':       priceKes,
    'notes':          notes,
    'createdAt':      FieldValue.serverTimestamp(),
  };
}