// lib/features/bookings/presentation/bookings_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Full My Bookings screen:
//            - AppNavShell wrapper with AppCanvas background.
//            - Three tabs: Upcoming / Past / Cancelled.
//            - myBookingsProvider drives all three tabs from one stream.
//            - Cancel action → BookingRepository.cancelBooking() transaction.
//            - Reschedule: navigates to trainer profile so user picks new slot.
//            - Empty states per tab use AppTypography.signature for warmth.
//            - _BookingDetailSheet: full booking info in a bottom sheet.
//            - Responsive: stack layout on all widths (booking cards need full width).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_nav.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_theme.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../data/booking_model.dart';
import '../data/booking_repository.dart';
import '../providers/bookings_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kHorizPad = 20.0;
const double _kCardGap = 12.0;
const double _kCardPadding = 18.0;
const double _kTabHeight = 42.0;

const String _kDiscover = '/discover';

// Month/day labels — no intl dependency.
const List<String> _kMonths = [
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
const List<String> _kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─────────────────────────────────────────────────────────────────────────────
// BookingsScreen
// ─────────────────────────────────────────────────────────────────────────────

class BookingsScreen extends ConsumerStatefulWidget {
  final bool isTrainerView;
  const BookingsScreen({super.key, this.isTrainerView = false});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(firestoreUserProvider);
    return userAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (_, __) => const _LoadingScaffold(),
      data: (user) {
        if (user == null) return const _LoadingScaffold();
        return AppNavShell(
          currentRoute: '/bookings',
          isTrainerView: widget.isTrainerView,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          child: _BookingsBody(
            tab: _tab,
            isTrainerView: widget.isTrainerView,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingsBody
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsBody extends ConsumerWidget {
  final TabController _tab;
  final bool isTrainerView;
  const _BookingsBody({required TabController tab, required this.isTrainerView})
      : _tab = tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final upcoming = ref.watch(myUpcomingBookingsProvider);
    final past = ref.watch(myPastBookingsProvider);
    final cancelled = ref.watch(myCancelledBookingsProvider);

    return AppCanvas(
      type: BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(_kHorizPad, 20, _kHorizPad, 0),
            child: Row(
              children: [
                const HamburgerButton(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Bookings', style: AppTypography.h2),
                      Text(
                        '${upcoming.length} upcoming session${upcoming.length == 1 ? "" : "s"}',
                        style: AppTypography.helper
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Quick book CTA
                GestureDetector(
                  onTap: () => context.go(_kDiscover),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: AppDecorations.primaryButton,
                    child: Text('+ Book', style: AppTypography.buttonSm),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kHorizPad),
            child: _TabBar(
              controller: _tab,
              upcomingCount: upcoming.length,
              pastCount: past.length,
              cancelledCount: cancelled.length,
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab views ───────────────────────────────────────────────────
          Expanded(
            child: bookingsAsync.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _BookingList(
                        bookings: upcoming,
                        emptyTitle: 'No upcoming sessions',
                        emptySubtitle: 'Ready to get moving?',
                        emptyAction: () => context.go(_kDiscover),
                        emptyActionLabel: 'Find a Trainer',
                        showCancelButton: true,
                      ),
                      _BookingList(
                        bookings: past,
                        emptyTitle: 'No past sessions yet',
                        emptySubtitle:
                            'Your completed sessions will appear here.',
                        showCancelButton: false,
                      ),
                      _BookingList(
                        bookings: cancelled,
                        emptyTitle: 'No cancelled bookings',
                        emptySubtitle: 'Good to see — nothing cancelled.',
                        showCancelButton: false,
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabBar — custom segment control matching WellPath design language
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController _controller;
  final int upcomingCount, pastCount, cancelledCount;
  const _TabBar({
    required TabController controller,
    required this.upcomingCount,
    required this.pastCount,
    required this.cancelledCount,
  }) : _controller = controller;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Upcoming', upcomingCount),
      ('Past', pastCount),
      ('Cancelled', cancelledCount),
    ];
    return Container(
      height: _kTabHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.inputBR,
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _controller,
        indicator: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: AppRadius.inputBR,
          boxShadow: AppShadows.buttonGlow,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.chip.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.chip,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        tabs: tabs
            .map((t) => Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.$1),
                      if (t.$2 > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            borderRadius: AppRadius.pillBR,
                          ),
                          child: Text('${t.$2}',
                              style: AppTypography.badge
                                  .copyWith(color: AppColors.onPrimary)),
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingList — one tab's content
// ─────────────────────────────────────────────────────────────────────────────

class _BookingList extends ConsumerWidget {
  final List<BookingModel> bookings;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? emptyAction;
  final String? emptyActionLabel;
  final bool showCancelButton;

  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyAction,
    this.emptyActionLabel,
    required this.showCancelButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: emptyActionLabel,
        onAction: emptyAction,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: _kHorizPad, vertical: 4),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
      itemBuilder: (ctx, i) => _BookingCard(
        booking: bookings[i],
        showCancelButton: showCancelButton,
        onTap: () => _showDetail(ctx, ref, bookings[i]),
      ),
    );
  }

  void _showDetail(BuildContext ctx, WidgetRef ref, BookingModel booking) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: booking,
        showCancelButton: showCancelButton,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingCard
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final bool showCancelButton;
  final VoidCallback onTap;
  const _BookingCard({
    required this.booking,
    required this.showCancelButton,
    required this.onTap,
  });

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CancelDialog(trainerName: widget.booking.trainerName),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);

    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(
            bookingId: widget.booking.id,
            slotId: widget.booking.slotId,
            cancelledBy: 'user',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled.', style: AppTypography.helper),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on BookingError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: AppTypography.helper),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final start = b.slotStartTime;
    final isPast = start != null && start.isBefore(DateTime.now());
    final statusColor = switch (b.status) {
      BookingStatus.confirmed => AppColors.success,
      BookingStatus.pending => AppColors.warning,
      BookingStatus.cancelled => AppColors.error,
    };

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(_kCardPadding),
        decoration: AppDecorations.card.copyWith(
          border: Border.all(
            color: statusColor.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Trainer avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.avatar,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    b.trainerName.isNotEmpty
                        ? b.trainerName[0].toUpperCase()
                        : '?',
                    style:
                        AppTypography.h3.copyWith(color: AppColors.onPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.trainerName, style: AppTypography.h5),
                    if (start != null)
                      Text(
                        _formatDate(start),
                        style: AppTypography.helper
                            .copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillBR,
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  b.status.label,
                  style: AppTypography.badge.copyWith(color: statusColor),
                ),
              ),
            ]),

            if (start != null) ...[
              const SizedBox(height: 12),
              // Time pill row
              Wrap(spacing: 8, runSpacing: 6, children: [
                _Pill(icon: Icons.schedule_rounded, label: _formatTime(start)),
                if (b.slotEndTime != null)
                  _Pill(
                      icon: Icons.timer_outlined,
                      label:
                          '${b.slotEndTime!.difference(start).inMinutes} min'),
              ]),
            ],

            // Action row — only for upcoming confirmed bookings
            if (widget.showCancelButton &&
                b.status == BookingStatus.confirmed &&
                !isPast) ...[
              const SizedBox(height: 14),
              Row(children: [
                // Reschedule → trainer profile where they can pick a new slot
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/trainer/${b.trainerId}'),
                    child: Container(
                      height: 36,
                      decoration: AppDecorations.outlinedButton,
                      child: Center(
                        child: Text('Reschedule',
                            style: AppTypography.buttonSm
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _cancelling ? null : _cancel,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: AppRadius.inputBR,
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.30)),
                      ),
                      child: Center(
                        child: _cancelling
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              )
                            : Text('Cancel',
                                style: AppTypography.buttonSm
                                    .copyWith(color: AppColors.error)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final day = _kDays[dt.weekday - 1];
    final mon = _kMonths[dt.month - 1];
    return '$day, $mon ${dt.day} · ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingDetailSheet — full booking information in a bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDetailSheet extends ConsumerStatefulWidget {
  final BookingModel booking;
  final bool showCancelButton;
  const _BookingDetailSheet({
    required this.booking,
    required this.showCancelButton,
  });

  @override
  ConsumerState<_BookingDetailSheet> createState() =>
      _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet> {
  bool _cancelling = false;

  static const List<String> _kMonths = [
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
  static const List<String> _kDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _fullDate(DateTime dt) {
    return '${_kDays[dt.weekday - 1]}, ${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final start = b.slotStartTime;
    final end = b.slotEndTime;
    final now = DateTime.now();
    final isPast = start != null && start.isBefore(now);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E), // matches AppColors.surface area
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppGradients.avatar,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  b.trainerName.isNotEmpty
                      ? b.trainerName[0].toUpperCase()
                      : '?',
                  style: AppTypography.h2.copyWith(color: AppColors.onPrimary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.trainerName, style: AppTypography.h3),
                  Text('Personal Trainer',
                      style: AppTypography.helper
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),
          _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: start != null ? _fullDate(start) : 'Date TBC'),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.schedule_rounded,
              label: start != null
                  ? '${_time(start)}${end != null ? " – ${_time(end)}" : ""}'
                  : 'Time TBC'),
          const SizedBox(height: 10),
          if (start != null && end != null)
            _DetailRow(
                icon: Icons.timer_outlined,
                label: '${end.difference(start).inMinutes} minute session'),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Booking ID: ${b.id.substring(0, 8).toUpperCase()}'),

          const SizedBox(height: 24),

          // Countdown or completion message
          if (start != null && !isPast) ...[
            _CountdownBanner(sessionTime: start),
            const SizedBox(height: 20),
          ],

          if (widget.showCancelButton &&
              b.status == BookingStatus.confirmed &&
              !isPast) ...[
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/trainer/${b.trainerId}');
                  },
                  child: Container(
                    height: 46,
                    decoration: AppDecorations.outlinedButton,
                    child: Center(
                      child: Text('Reschedule',
                          style: AppTypography.button
                              .copyWith(color: AppColors.primary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _cancelling ? null : _confirmCancel,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: AppRadius.inputBR,
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.30)),
                    ),
                    child: Center(
                      child: _cancelling
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : Text('Cancel Booking',
                              style: AppTypography.button
                                  .copyWith(color: AppColors.error)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CancelDialog(trainerName: widget.booking.trainerName),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(
            bookingId: widget.booking.id,
            slotId: widget.booking.slotId,
            cancelledBy: 'user',
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled.', style: AppTypography.helper),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on BookingError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: AppTypography.helper),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountdownBanner
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  final DateTime sessionTime;
  const _CountdownBanner({required this.sessionTime});

  String _label() {
    final diff = sessionTime.difference(DateTime.now());
    if (diff.inDays > 1) return 'in ${diff.inDays} days';
    if (diff.inDays == 1) return 'tomorrow';
    if (diff.inHours > 0) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes} minutes';
    return 'starting soon';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.inputBR,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Your session is ${_label()}',
            style: AppTypography.helper.copyWith(color: AppColors.primary),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Support widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

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

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: AppRadius.inputBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.caption),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: AppColors.textMuted, size: 42),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTypography.h4
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              // Warm empty state — one of the approved signature use cases.
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.signature.copyWith(fontSize: 14)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: AppDecorations.primaryButton,
                    child: Text(actionLabel!, style: AppTypography.button),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _CancelDialog extends StatelessWidget {
  final String trainerName;
  const _CancelDialog({required this.trainerName});

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modalBR),
        title: Text('Cancel booking?', style: AppTypography.h4),
        content: Text(
          'Your session with $trainerName will be cancelled and the time slot '
          'will be released for other users.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep it',
                style: AppTypography.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel booking',
                style: AppTypography.button.copyWith(color: AppColors.error)),
          ),
        ],
      );
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}
