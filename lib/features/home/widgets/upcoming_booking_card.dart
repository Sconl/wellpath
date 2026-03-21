// lib/features/home/widgets/upcoming_booking_card.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Date-block + trainer name + time + status badge.
//            Manual date formatting — no intl dependency required.
//            Matches all three BookingStatus values with correct colors.
//   v1.1.0 — Fixed invalid_constant: removed const from Icon inside
//            _DateBlock — AppColors.primary is a computed getter, not a
//            compile-time constant. Same class of bug as Bug 7 (home_screen).
//          — Replaced all withOpacity() calls with withValues(alpha:) to
//            resolve deprecated_member_use warnings (Flutter 3.27+ Color API).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../bookings/data/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kDateBlockSize = 52.0;
const double _kCardPadding   = 16.0;
const double _kIconSpacing   = 14.0;

// ── Date/time formatting ──
const List<String> _kMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _kDaysShort = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

// ─────────────────────────────────────────────────────────────────────────────
// UpcomingBookingCard
// ─────────────────────────────────────────────────────────────────────────────

class UpcomingBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;

  const UpcomingBookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = booking.slotStartTime;
    final end   = booking.slotEndTime;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:    const EdgeInsets.all(_kCardPadding),
        decoration: AppDecorations.card.copyWith(
          // A green-tinted border distinguishes upcoming sessions from
          // the general card style — draws the eye without being loud.
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            // ── Date block ─────────────────────────────────────────────
            _DateBlock(date: start),

            const SizedBox(width: _kIconSpacing),

            // ── Trainer name + time range ───────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.trainerName,
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeRange(start, end),
                    style: AppTypography.helper.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Status badge ────────────────────────────────────────────
            _StatusBadge(status: booking.status),
          ],
        ),
      ),
    );
  }

  String _timeRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Time TBC';
    final dayName  = _kDaysShort[start.weekday - 1];
    final monthStr = _kMonthsShort[start.month - 1];
    final dateStr  = '$dayName, $monthStr ${start.day}';
    final startStr = _formatTime(start);
    final endStr   = end != null ? ' – ${_formatTime(end)}' : '';
    return '$dateStr  $startStr$endStr';
  }

  static String _formatTime(DateTime dt) {
    final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DateBlock
// ─────────────────────────────────────────────────────────────────────────────

class _DateBlock extends StatelessWidget {
  final DateTime? date;
  const _DateBlock({this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  _kDateBlockSize,
      height: _kDateBlockSize,
      decoration: BoxDecoration(
        color:        AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.inputBR,
      ),
      child: date == null
          // ⚠ Do NOT add const here — AppColors.primary is a computed getter,
          // not a compile-time constant. Same class of bug as Bug 7.
          ? Icon(Icons.calendar_today_outlined,
              color: AppColors.primary, size: 18)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date!.day.toString(),
                  style: AppTypography.h4.copyWith(color: AppColors.primary),
                ),
                Text(
                  _kMonthsShort[date!.month - 1],
                  style: AppTypography.helper.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    // Switch expression + records — Dart 3.0+ (project uses 3.2+).
    final (label, color) = switch (status) {
      BookingStatus.confirmed  => (BookingStatus.confirmed.label,  AppColors.success),
      BookingStatus.pending    => (BookingStatus.pending.label,    AppColors.warning),
      BookingStatus.cancelled  => (BookingStatus.cancelled.label,  AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBR,
      ),
      child: Text(
        label,
        style: AppTypography.helper.copyWith(
          color:      color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}