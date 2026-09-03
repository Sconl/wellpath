// lib/features/notifications/providers/notification_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. NotificationPreferences Riverpod notifier.
//            Async load from SharedPreferences on first watch.
//            notificationPrefsProvider.notifier.toggle*(bool) → saves + rebuilds.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_preferences.dart';
import '../notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationPreferencesNotifier
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() => NotificationPreferences.load();

  Future<void> toggleSessionReminder24h(bool value) async {
    final current = state.value ?? const NotificationPreferences();
    final next    = current.copyWith(sessionReminder24h: value);
    state         = AsyncData(next);
    await next.save();
  }

  Future<void> toggleSessionReminder1h(bool value) async {
    final current = state.value ?? const NotificationPreferences();
    final next    = current.copyWith(sessionReminder1h: value);
    state         = AsyncData(next);
    await next.save();
  }

  Future<void> toggleBookingConfirmations(bool value) async {
    final current = state.value ?? const NotificationPreferences();
    final next    = current.copyWith(bookingConfirmations: value);
    state         = AsyncData(next);
    await next.save();
  }

  Future<void> toggleCancellationAlerts(bool value) async {
    final current = state.value ?? const NotificationPreferences();
    final next    = current.copyWith(cancellationAlerts: value);
    state         = AsyncData(next);
    await next.save();
  }

  Future<void> toggleWellnessReminder(bool value) async {
    final current = state.value ?? const NotificationPreferences();
    final next    = current.copyWith(wellnessReminder: value);
    state         = AsyncData(next);
    await next.save();
  }

  Future<void> toggleWeeklyGoalsSummary(bool value) async {
    final current = state.value ?? const NotificationPreferences();
    final next    = current.copyWith(weeklyGoalsSummary: value);
    state         = AsyncData(next);
    await next.save();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final notificationPrefsProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier,
        NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// notificationServiceProvider — singleton accessor
// ─────────────────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);