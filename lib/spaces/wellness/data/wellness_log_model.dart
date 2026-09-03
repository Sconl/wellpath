// lib/features/wellness/data/wellness_log_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Mirrors users/{uid}/wellnessLogs/{logId} exactly.
//            Covers the three MVP log types: workout, water, sleep.
//            fromFirestore / toMap / typeString. Designed so WellnessType
//            can be imported anywhere without pulling in Firebase.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const kWellnessLogsCollection = 'wellnessLogs';

// ── Daily targets — used as progress ring denominators on the home screen.
//    These are display defaults; they'll be overridden by the user's goal
//    documents once Feature 2's goal system is wired (Week 5).
const kDefaultWorkoutTargetMins    = 60.0;
const kDefaultWaterTargetGlasses   = 8.0;
const kDefaultSleepTargetHours     = 8.0;

// ─────────────────────────────────────────────────────────────────────────────
// WellnessType
// ─────────────────────────────────────────────────────────────────────────────

enum WellnessType { workout, water, sleep }

extension WellnessTypeX on WellnessType {
  static WellnessType fromString(String raw) {
    switch (raw) {
      case 'workout': return WellnessType.workout;
      case 'water':   return WellnessType.water;
      case 'sleep':   return WellnessType.sleep;
      // Unknown strings default to workout — better than crashing on a bad
      // Firestore value, but worth logging in production (Week 8 Crashlytics).
      default:        return WellnessType.workout;
    }
  }

  String get displayLabel {
    switch (this) {
      case WellnessType.workout: return 'Workout';
      case WellnessType.water:   return 'Water';
      case WellnessType.sleep:   return 'Sleep';
    }
  }

  String get unit {
    switch (this) {
      case WellnessType.workout: return 'min';
      case WellnessType.water:   return 'gl';
      case WellnessType.sleep:   return 'hr';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WellnessLog — pure data object, no UI dependencies
// ─────────────────────────────────────────────────────────────────────────────

class WellnessLog {
  final String              id;
  final WellnessType        type;
  final double              value;
  final Map<String, dynamic> metadata;  // e.g. { workoutType: 'cardio' }
  final DateTime            timestamp;

  const WellnessLog({
    required this.id,
    required this.type,
    required this.value,
    required this.metadata,
    required this.timestamp,
  });

  factory WellnessLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return WellnessLog(
      id:        doc.id,
      type:      WellnessTypeX.fromString(data['type'] as String? ?? ''),
      value:     (data['value'] as num?)?.toDouble() ?? 0.0,
      metadata:  Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      // Fall back to now rather than throw — a missing timestamp would be a
      // Firestore write bug, not a user action we can predict or handle cleanly.
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type':      type.name,
    'value':     value,
    'metadata':  metadata,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}