// lib/features/notifications/notification_service.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Platform-aware notification service.
//
//   ARCHITECTURE:
//   WellPath is web-first (Flutter web). On web, flutter_local_notifications
//   does not support scheduling. This service uses:
//     - Mobile: flutter_local_notifications with timezone scheduling.
//     - Web:    In-memory reminder queue + browser Notification API.
//
//   The singleton NotificationService.instance ensures one initialisation.
//   Booking flow calls scheduleSessionReminder() after successful booking.
//   BookingsScreen calls cancelSessionReminder() on cancellation.
//
//   ⚠️  Week 6 (FCM): When Firebase Cloud Messaging is added, the server-side
//       push notifications from Cloud Functions will fire automatically.
//       This local service remains complementary — it handles reminders even
//       when the browser tab is closed (mobile) and provides immediate
//       in-app confirmation toasts (all platforms).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// How many hours before the session to send the first reminder.
const int kReminderHoursDay = 24;
const int kReminderHoursHour = 1;

// Notification channel IDs (Android).
const String kChannelBookings = 'wellpath_bookings';
const String kChannelReminders = 'wellpath_reminders';

// ─────────────────────────────────────────────────────────────────────────────
// InAppNotification — for web overlay display
// ─────────────────────────────────────────────────────────────────────────────

class InAppNotification {
  final String bookingId;
  final String title;
  final String body;
  final DateTime scheduledFor;
  final NotifType type;
  Timer? _timer;

  InAppNotification({
    required this.bookingId,
    required this.title,
    required this.body,
    required this.scheduledFor,
    required this.type,
  });
}

enum NotifType { reminder24h, reminder1h, confirmation }

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  // In-memory queue for web reminders — keyed by bookingId so we can cancel.
  final Map<String, List<InAppNotification>> _webReminders = {};

  // Overlay notifier — widgets listen to this stream to show banners.
  final StreamController<InAppNotification> _notifStream =
      StreamController.broadcast();

  Stream<InAppNotification> get notificationStream => _notifStream.stream;

  // ── initialize ─────────────────────────────────────────────────────────────
  //
  // Call once from main.dart after Firebase.initializeApp().
  // On mobile: sets up flutter_local_notifications channels.
  // On web: no-op — reminders use in-memory timers.
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      // Web: request browser notification permission.
      // This is best-effort — if denied, in-app banners still work.
      try {
        // Browser Notification API is accessed via dart:html on web.
        // We use a conditional import pattern here to avoid dart:html
        // crashing on mobile compilation.
        // The actual permission request is handled by _requestWebPermission().
        await _requestWebPermission();
      } catch (_) {
        // Permission denied or API unavailable — silent fallback to in-app.
      }
    } else {
      // Mobile: initialise flutter_local_notifications.
      // The actual plugin code is here as a comment block — uncomment when
      // flutter_local_notifications is added to pubspec.yaml (Week 6).
      //
      // final plugin = FlutterLocalNotificationsPlugin();
      // const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      // const iosSettings = DarwinInitializationSettings(
      //   requestAlertPermission: true,
      //   requestBadgePermission: true,
      //   requestSoundPermission: true,
      // );
      // await plugin.initialize(
      //   const InitializationSettings(android: androidSettings, iOS: iosSettings),
      //   onDidReceiveNotificationResponse: _onNotificationTap,
      // );
      // await _createAndroidChannels(plugin);
    }
  }

  Future<void> _requestWebPermission() async {
    // Conditional implementation — only runs on web where dart:html is available.
    // On web, this calls Notification.requestPermission() via JS interop.
    // Non-web builds skip this entirely via kIsWeb guard at call site.
    if (!kIsWeb) return;
    // In production, use package:web or dart:js_interop for the permission call.
    // For MVP: the in-memory reminder queue works regardless of permission.
  }

  // ── scheduleSessionReminder ─────────────────────────────────────────────────

  Future<void> scheduleSessionReminder({
    required String bookingId,
    required DateTime sessionTime,
    required String trainerName,
  }) async {
    final now = DateTime.now();

    // 24-hour reminder
    final remind24 = sessionTime.subtract(Duration(hours: kReminderHoursDay));
    if (remind24.isAfter(now)) {
      await _schedule(
        bookingId: bookingId,
        title: 'Session tomorrow with $trainerName',
        body: 'Your session is at ${_time(sessionTime)} tomorrow. '
            'Get ready to crush it! 💪',
        at: remind24,
        type: NotifType.reminder24h,
      );
    }

    // 1-hour reminder
    final remind1h = sessionTime.subtract(Duration(hours: kReminderHoursHour));
    if (remind1h.isAfter(now)) {
      await _schedule(
        bookingId: bookingId,
        title: 'Your session starts in 1 hour',
        body: '${_time(sessionTime)} session with $trainerName. '
            'Time to warm up! 🔥',
        at: remind1h,
        type: NotifType.reminder1h,
      );
    }
  }

  // ── cancelSessionReminder ──────────────────────────────────────────────────

  Future<void> cancelSessionReminder(String bookingId) async {
    final reminders = _webReminders.remove(bookingId);
    if (reminders != null) {
      for (final r in reminders) {
        r._timer?.cancel();
      }
    }

    if (!kIsWeb) {
      // Mobile: cancel scheduled notifications by bookingId hash.
      // Uncomment when flutter_local_notifications is live:
      // final plugin = FlutterLocalNotificationsPlugin();
      // await plugin.cancel(_idFromBookingId(bookingId, 0));
      // await plugin.cancel(_idFromBookingId(bookingId, 1));
    }
  }

  // ── showBookingConfirmedNotification ──────────────────────────────────────

  /// Call immediately after a successful booking to give instant feedback.
  Future<void> showBookingConfirmedNotification({
    required String bookingId,
    required String trainerName,
    required DateTime sessionTime,
  }) async {
    final notif = InAppNotification(
      bookingId: bookingId,
      title: 'Booking confirmed!',
      body: 'Session with $trainerName on ${_shortDate(sessionTime)}.',
      scheduledFor: DateTime.now(),
      type: NotifType.confirmation,
    );
    _notifStream.add(notif);
  }

  // ── _schedule ─────────────────────────────────────────────────────────────

  Future<void> _schedule({
    required String bookingId,
    required String title,
    required String body,
    required DateTime at,
    required NotifType type,
  }) async {
    final notif = InAppNotification(
      bookingId: bookingId,
      title: title,
      body: body,
      scheduledFor: at,
      type: type,
    );

    if (kIsWeb) {
      // Web: use a Dart Timer to fire the in-app banner at the right time.
      final delay = at.difference(DateTime.now());
      if (delay.isNegative) return;
      notif._timer = Timer(delay, () {
        _notifStream.add(notif);
        // Also attempt browser notification if permission was granted.
        _fireBrowserNotification(title, body);
      });
      _webReminders.putIfAbsent(bookingId, () => []).add(notif);
    } else {
      // Mobile: schedule with flutter_local_notifications.
      // Uncomment when plugin is live (Week 6):
      //
      // final plugin   = FlutterLocalNotificationsPlugin();
      // final tz       = tz.local;
      // final tzAt     = tz.TZDateTime.from(at, tz);
      // await plugin.zonedSchedule(
      //   _idFromBookingId(bookingId, type.index),
      //   title,
      //   body,
      //   tzAt,
      //   const NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       kChannelReminders, 'Session Reminders',
      //       importance: Importance.high, priority: Priority.high,
      //     ),
      //     iOS: DarwinNotificationDetails(),
      //   ),
      //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //   uiLocalNotificationDateInterpretation:
      //       UILocalNotificationDateInterpretation.absoluteTime,
      // );
    }
  }

  void _fireBrowserNotification(String title, String body) {
    // Browser notification via JS interop — only on web.
    // In production: use package:web Notification API.
    // For MVP this is a no-op stub; in-app banner fires regardless.
    if (!kIsWeb) return;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  static String _shortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  // Deterministic integer ID from bookingId + index (for mobile notifications).
  // ignore: unused_element
  static int _idFromBookingId(String bookingId, int index) {
    return (bookingId.hashCode.abs() % 100000) * 10 + index;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationBanner — overlay widget
//
// Wrap app root with this to show in-app notification banners automatically.
// Usage in app_router.dart or main.dart:
//   builder: (ctx, state, child) => NotificationBannerHost(child: child),
// ─────────────────────────────────────────────────────────────────────────────

class NotificationBannerHost extends StatefulWidget {
  final Widget child;
  const NotificationBannerHost({super.key, required this.child});

  @override
  State<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends State<NotificationBannerHost> {
  StreamSubscription<InAppNotification>? _sub;
  final List<_BannerEntry> _banners = [];

  @override
  void initState() {
    super.initState();
    _sub = NotificationService.instance.notificationStream.listen(_onNotif);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onNotif(InAppNotification notif) {
    if (!mounted) return;
    final entry = _BannerEntry(id: notif.bookingId + notif.type.name);
    setState(() => _banners.add(entry));
    // Show using SnackBar for simplicity — no overlay juggling needed.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(notif.body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF1A3A2A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: const Color(0xFF00CC66),
          onPressed: () {
            setState(() => _banners.remove(entry));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _BannerEntry {
  final String id;
  const _BannerEntry({required this.id});
}
