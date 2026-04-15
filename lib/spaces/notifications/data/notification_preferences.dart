// lib/features/notifications/data/notification_preferences.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. NotificationPreferences data class + SharedPreferences
//            persistence. Separate from Firestore — preferences are local and
//            don't need to sync across devices in MVP. Week 8 enhancement:
//            write to users/{uid}/settings/notifications if cross-device sync
//            becomes a requirement.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG — SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────

const String _kPrefix               = 'wellpath_notif_';
const String _kKeySessionReminder24 = '${_kPrefix}session_24h';
const String _kKeySessionReminder1h = '${_kPrefix}session_1h';
const String _kKeyConfirmation      = '${_kPrefix}confirmation';
const String _kKeyCancellation      = '${_kPrefix}cancellation';
const String _kKeyWellnessReminder  = '${_kPrefix}wellness';
const String _kKeyWeeklyGoals       = '${_kPrefix}weekly_goals';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationPreferences
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPreferences {
  /// 24-hour reminder before a booked session.
  final bool sessionReminder24h;

  /// 1-hour reminder before a booked session.
  final bool sessionReminder1h;

  /// Instant confirmation when a booking is created.
  final bool bookingConfirmations;

  /// Alert when the other party cancels a session.
  final bool cancellationAlerts;

  /// Daily wellness logging reminder.
  final bool wellnessReminder;

  /// Weekly progress & goals summary.
  final bool weeklyGoalsSummary;

  const NotificationPreferences({
    this.sessionReminder24h   = true,
    this.sessionReminder1h    = true,
    this.bookingConfirmations = true,
    this.cancellationAlerts   = true,
    this.wellnessReminder     = false,
    this.weeklyGoalsSummary   = false,
  });

  NotificationPreferences copyWith({
    bool? sessionReminder24h,
    bool? sessionReminder1h,
    bool? bookingConfirmations,
    bool? cancellationAlerts,
    bool? wellnessReminder,
    bool? weeklyGoalsSummary,
  }) =>
      NotificationPreferences(
        sessionReminder24h:   sessionReminder24h   ?? this.sessionReminder24h,
        sessionReminder1h:    sessionReminder1h    ?? this.sessionReminder1h,
        bookingConfirmations: bookingConfirmations ?? this.bookingConfirmations,
        cancellationAlerts:   cancellationAlerts   ?? this.cancellationAlerts,
        wellnessReminder:     wellnessReminder     ?? this.wellnessReminder,
        weeklyGoalsSummary:   weeklyGoalsSummary   ?? this.weeklyGoalsSummary,
      );

  // ── Persistence ───────────────────────────────────────────────────────────

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      sessionReminder24h:   prefs.getBool(_kKeySessionReminder24) ?? true,
      sessionReminder1h:    prefs.getBool(_kKeySessionReminder1h) ?? true,
      bookingConfirmations: prefs.getBool(_kKeyConfirmation)      ?? true,
      cancellationAlerts:   prefs.getBool(_kKeyCancellation)      ?? true,
      wellnessReminder:     prefs.getBool(_kKeyWellnessReminder)  ?? false,
      weeklyGoalsSummary:   prefs.getBool(_kKeyWeeklyGoals)       ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKeySessionReminder24, sessionReminder24h);
    await prefs.setBool(_kKeySessionReminder1h, sessionReminder1h);
    await prefs.setBool(_kKeyConfirmation,      bookingConfirmations);
    await prefs.setBool(_kKeyCancellation,      cancellationAlerts);
    await prefs.setBool(_kKeyWellnessReminder,  wellnessReminder);
    await prefs.setBool(_kKeyWeeklyGoals,       weeklyGoalsSummary);
  }
}