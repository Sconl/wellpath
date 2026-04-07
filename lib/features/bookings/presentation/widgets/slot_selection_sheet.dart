// lib/features/bookings/presentation/widgets/slot_selection_sheet.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Bottom sheet: slot details → confirm → success/error.
//            Three internal states: idle → loading → success | error.
//            On success: schedules local notification, navigates to /bookings.
//            BookingRepository.createBooking() handles the Firestore transaction.
//            On slot conflict (race): surfaces friendly error without dismissing.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/trainer_profile.dart';
import '../../../../core/style/app_decorations.dart';
import '../../../../core/style/app_theme.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/notification_service.dart';
import '../../../home/providers/home_providers.dart';
import '../../data/availability_model.dart';
import '../../data/booking_repository.dart';
import '../../providers/bookings_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const List<String> _kDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// ─────────────────────────────────────────────────────────────────────────────
// SlotSelectionSheet
// ─────────────────────────────────────────────────────────────────────────────

enum _SheetState { idle, loading, success, error }

class SlotSelectionSheet extends ConsumerStatefulWidget {
  final AvailabilitySlot slot;
  final TrainerProfile profile;
  const SlotSelectionSheet({
    super.key,
    required this.slot,
    required this.profile,
  });

  @override
  ConsumerState<SlotSelectionSheet> createState() => _SlotSelectionSheetState();
}

class _SlotSelectionSheetState extends ConsumerState<SlotSelectionSheet> {
  _SheetState _state = _SheetState.idle;
  String _errorMsg = '';
  String _bookingId = '';

  String _formatDate(DateTime dt) =>
      '${_kDays[dt.weekday - 1]}, ${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  String _timeRange() {
    final s = widget.slot.startTime;
    final e = widget.slot.endTime;
    return '${_formatTime(s)} – ${_formatTime(e)}';
  }

  Future<void> _confirm() async {
    final user = ref.read(firestoreUserProvider).value;
    if (user == null) return;

    setState(() => _state = _SheetState.loading);

    try {
      final result = await ref.read(bookingRepositoryProvider).createBooking(
            uid: user.uid,
            displayName: user.displayName,
            slot: widget.slot,
          );

      // Schedule a local reminder notification.
      await NotificationService.instance.scheduleSessionReminder(
        bookingId: result.bookingId,
        sessionTime: widget.slot.startTime,
        trainerName: widget.slot.trainerName,
      );

      setState(() {
        _state = _SheetState.success;
        _bookingId = result.bookingId;
      });

      // Invalidate booking providers to ensure UI updates immediately
      ref.invalidate(upcomingBookingsProvider);
      ref.invalidate(myBookingsProvider);
    } on BookingError catch (e) {
      setState(() {
        _state = _SheetState.error;
        _errorMsg = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        child: switch (_state) {
          _SheetState.idle => _IdleBody(
              key: const ValueKey('idle'),
              slot: widget.slot,
              profile: widget.profile,
              date: _formatDate(widget.slot.startTime),
              timeRange: _timeRange(),
              duration: '${widget.slot.durationMinutes} minutes',
              onConfirm: _confirm,
            ),
          _SheetState.loading => const _LoadingBody(key: ValueKey('loading')),
          _SheetState.success => _SuccessBody(
              key: const ValueKey('success'),
              trainerName: widget.slot.trainerName,
              date: _formatDate(widget.slot.startTime),
              timeRange: _timeRange(),
              bookingId: _bookingId,
              onViewBookings: () {
                Navigator.pop(context);
                context.go('/bookings');
              },
              onDone: () => Navigator.pop(context),
            ),
          _SheetState.error => _ErrorBody(
              key: const ValueKey('error'),
              message: _errorMsg,
              onRetry: () => setState(() => _state = _SheetState.idle),
              onDismiss: () => Navigator.pop(context),
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _IdleBody — slot detail + confirm button
// ─────────────────────────────────────────────────────────────────────────────

class _IdleBody extends StatelessWidget {
  final AvailabilitySlot slot;
  final TrainerProfile profile;
  final String date, timeRange, duration;
  final VoidCallback onConfirm;

  const _IdleBody({
    super.key,
    required this.slot,
    required this.profile,
    required this.date,
    required this.timeRange,
    required this.duration,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle
        Center(child: _Handle()),
        const SizedBox(height: 20),

        Text('Confirm Booking', style: AppTypography.h3),
        const SizedBox(height: 4),
        Text('Review your session details before confirming.',
            style:
                AppTypography.helper.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        // Trainer row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card,
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.avatar,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  slot.trainerName.isNotEmpty
                      ? slot.trainerName[0].toUpperCase()
                      : '?',
                  style: AppTypography.h3.copyWith(color: AppColors.onPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.trainerName, style: AppTypography.h5),
                  Text('Personal Trainer',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(slot.priceDisplay,
                style: AppTypography.h5.copyWith(color: AppColors.primary)),
          ]),
        ),

        const SizedBox(height: 14),

        // Session details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row(icon: Icons.calendar_today_outlined, label: date),
              const SizedBox(height: 10),
              _Row(icon: Icons.schedule_rounded, label: timeRange),
              const SizedBox(height: 10),
              _Row(icon: Icons.timer_outlined, label: duration),
              const SizedBox(height: 10),
              _Row(
                  icon: Icons.fitness_center_rounded,
                  label: slot.sessionType.label),
              const SizedBox(height: 10),
              _Row(icon: Icons.place_rounded, label: slot.locationDisplay),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Confirm button
        GestureDetector(
          onTap: onConfirm,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: AppDecorations.primaryButton,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: AppColors.onPrimary),
                  const SizedBox(width: 8),
                  Text('Confirm Booking', style: AppTypography.button),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'By confirming, you agree that the session is non-refundable '
          'within 2 hours of start time.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LoadingBody
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text('Securing your slot…',
                  style: AppTypography.h5
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('This takes just a moment.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuccessBody
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessBody extends StatelessWidget {
  final String trainerName, date, timeRange, bookingId;
  final VoidCallback onViewBookings, onDone;

  const _SuccessBody({
    super.key,
    required this.trainerName,
    required this.date,
    required this.timeRange,
    required this.bookingId,
    required this.onViewBookings,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        // Success icon with glow
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 36),
        ),

        const SizedBox(height: 20),

        Text("You're booked!", style: AppTypography.h2),
        const SizedBox(height: 6),
        // Emotional moment — approved AppTypography.signature use case.
        Text('Session confirmed. You\'ve got this. 💪',
            textAlign: TextAlign.center, style: AppTypography.signature),

        const SizedBox(height: 24),

        // Booking summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card.copyWith(
            border:
                Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            _ConfirmRow(label: 'Trainer', value: trainerName),
            const Divider(height: 20),
            _ConfirmRow(label: 'Date', value: date),
            const Divider(height: 20),
            _ConfirmRow(label: 'Time', value: timeRange),
            const Divider(height: 20),
            _ConfirmRow(
                label: 'Booking ID',
                value: bookingId.substring(0, 8).toUpperCase()),
          ]),
        ),

        const SizedBox(height: 10),
        Text('A reminder will be sent 24h and 1h before your session.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),

        const SizedBox(height: 20),

        GestureDetector(
          onTap: onViewBookings,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: AppDecorations.primaryButton,
            child: Center(
                child: Text('View My Bookings', style: AppTypography.button)),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onDone,
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: AppDecorations.outlinedButton,
            child: Center(
              child: Text('Back to Profile',
                  style:
                      AppTypography.button.copyWith(color: AppColors.primary)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBody
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry, onDismiss;

  const _ErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Booking failed', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: AppDecorations.primaryButton,
              child:
                  Center(child: Text('Try Again', style: AppTypography.button)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onDismiss,
            child: Center(
              child: Text('Dismiss',
                  style: AppTypography.button
                      .copyWith(color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Support widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Row({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary)),
        ),
      ]);
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted)),
          Text(value,
              style: AppTypography.h5.copyWith(color: AppColors.textPrimary)),
        ],
      );
}
