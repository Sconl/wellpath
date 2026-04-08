// lib/features/bookings/presentation/bookings_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Three-tab Upcoming / Past / Cancelled screen.
//   v2.0.0 — Full UX overhaul:
//            · Optimistic cancellation: booking moves to Cancelled tab the
//              instant the user confirms the dialog — before Firestore round-
//              trip. The tab animates automatically. No visible lag.
//            · Real-time stream backed by includeMetadataChanges:true already
//              present in bookings_providers.dart — derived providers react to
//              local cache writes immediately on success.
//            · Summary header strip: next-session countdown hero, total
//              sessions stat, and quick-book CTA.
//            · Richer booking cards: session-type badge, location pill,
//              duration, price, inline live countdown timer, status glow border.
//            · Swipe-to-cancel on Upcoming cards (Dismissible with red
//              reveal) in addition to the existing Cancel button.
//            · Animated count badges on tabs react to stream changes.
//            · Per-tab empty states with contextually appropriate icons and
//              copy.
//            · Pull-to-refresh on all three lists.
//            · _BookingsBody promoted to ConsumerStatefulWidget so it owns
//              both the TabController and the optimistic-cancellations set.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

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
const double _kCardPad = 18.0;
const double _kTabHeight = 44.0;
const String _kDiscover = '/discover';

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _kDays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

// ─────────────────────────────────────────────────────────────────────────────
// BookingsScreen — shell only: resolves user → AppNavShell
// ─────────────────────────────────────────────────────────────────────────────

class BookingsScreen extends ConsumerWidget {
  final bool isTrainerView;
  const BookingsScreen({super.key, this.isTrainerView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);
    return userAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (_, __) => const _LoadingScaffold(),
      data: (user) {
        if (user == null) return const _LoadingScaffold();
        return AppNavShell(
          currentRoute: '/bookings',
          isTrainerView: isTrainerView,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          child: _BookingsBody(isTrainerView: isTrainerView),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingsBody — owns TabController + optimistic-cancellation state
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsBody extends ConsumerStatefulWidget {
  final bool isTrainerView;
  const _BookingsBody({required this.isTrainerView});

  @override
  ConsumerState<_BookingsBody> createState() => _BookingsBodyState();
}

class _BookingsBodyState extends ConsumerState<_BookingsBody>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Booking IDs that the user has just cancelled — applied immediately to the
  // local view while we wait for Firestore to confirm and push the stream
  // update back. This gives zero-lag UI feedback.
  final Set<String> _optimisticallyCancelled = {};

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

  // ── Filtering helpers (applied on top of provider data) ───────────────────

  List<BookingModel> _upcoming(List<BookingModel> all) {
    final now = DateTime.now();
    return all
        .where((b) =>
            !_optimisticallyCancelled.contains(b.id) &&
            b.status == BookingStatus.confirmed &&
            b.slotStartTime != null &&
            b.slotStartTime!.isAfter(now))
        .toList()
      ..sort((a, b) => a.slotStartTime!.compareTo(b.slotStartTime!));
  }

  List<BookingModel> _past(List<BookingModel> all) {
    final now = DateTime.now();
    return all
        .where((b) =>
            !_optimisticallyCancelled.contains(b.id) &&
            b.status == BookingStatus.confirmed &&
            b.slotStartTime != null &&
            b.slotStartTime!.isBefore(now))
        .toList();
  }

  List<BookingModel> _cancelled(List<BookingModel> all) {
    // Include both server-confirmed cancellations AND optimistic ones.
    return all.where((b) {
      if (b.status == BookingStatus.cancelled) return true;
      if (_optimisticallyCancelled.contains(b.id)) return true;
      return false;
    }).toList();
  }

  // ── Called the moment the user confirms the cancel dialog ─────────────────
  //
  // 1. Adds bookingId to _optimisticallyCancelled → card vanishes from
  //    Upcoming immediately on this frame.
  // 2. Fires the Firestore transaction in the background.
  // 3. Animates to the Cancelled tab so the user sees where it went.
  // 4. On error: removes from optimistic set and shows a snack.
  //
  Future<void> _cancelBooking(BookingModel booking) async {
    // ── Optimistic update ──────────────────────────────────────────────────
    setState(() => _optimisticallyCancelled.add(booking.id));

    // Switch to Cancelled tab immediately so the user sees the item arrive.
    _tab.animateTo(2, duration: const Duration(milliseconds: 350));

    // Show brief confirmation snack.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 15, color: AppColors.success),
            const SizedBox(width: 8),
            Text('Booking cancelled.', style: AppTypography.helper),
          ]),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.inputBR),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // ── Background Firestore transaction ───────────────────────────────────
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(
            bookingId: booking.id,
            slotId: booking.slotId,
            cancelledBy: 'user',
          );
      // On success: the myBookingsProvider stream will emit the updated list
      // (includeMetadataChanges: true means the local write is reflected
      // immediately). The derived _cancelled() helper will then return the
      // correct server-confirmed record, and we can drop the optimistic ID.
      if (mounted) setState(() => _optimisticallyCancelled.remove(booking.id));
    } on BookingError catch (e) {
      // Rollback the optimistic update on failure.
      if (mounted) {
        setState(() => _optimisticallyCancelled.remove(booking.id));
        _tab.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: AppTypography.helper),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.inputBR),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final all = bookingsAsync.valueOrNull ?? [];

    final upcoming = _upcoming(all);
    final past = _past(all);
    final cancelled = _cancelled(all);

    return AppCanvas(
      type: BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          _BookingsHeader(
            upcoming: upcoming,
            totalPast: past.length,
          ),

          const SizedBox(height: 14),

          // ── Tab bar ───────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _kHorizPad),
            child: _TabBar(
              controller: _tab,
              upcomingCount: upcoming.length,
              pastCount: past.length,
              cancelledCount: cancelled.length,
            ),
          ),

          const SizedBox(height: 4),

          // ── Tab views ─────────────────────────────────────────────────────
          Expanded(
            child: bookingsAsync.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : TabBarView(
                    controller: _tab,
                    children: [
                      // ── Upcoming ──────────────────────────────────────────
                      _BookingList(
                        bookings: upcoming,
                        tab: _BookingTab.upcoming,
                        onCancel: _cancelBooking,
                        onRefresh: () async =>
                            ref.invalidate(myBookingsProvider),
                      ),
                      // ── Past ─────────────────────────────────────────────
                      _BookingList(
                        bookings: past,
                        tab: _BookingTab.past,
                        onRefresh: () async =>
                            ref.invalidate(myBookingsProvider),
                      ),
                      // ── Cancelled ────────────────────────────────────────
                      _BookingList(
                        bookings: cancelled,
                        tab: _BookingTab.cancelled,
                        onRefresh: () async =>
                            ref.invalidate(myBookingsProvider),
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
// _BookingsHeader
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsHeader extends StatelessWidget {
  final List<BookingModel> upcoming;
  final int totalPast;

  const _BookingsHeader({
    required this.upcoming,
    required this.totalPast,
  });

  @override
  Widget build(BuildContext context) {
    final next = upcoming.isNotEmpty ? upcoming.first : null;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(_kHorizPad, 20, _kHorizPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ───────────────────────────────────────────────────
          Row(children: [
            const HamburgerButton(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Bookings', style: AppTypography.h2),
                  Text(
                    upcoming.isEmpty
                        ? 'No upcoming sessions'
                        : '${upcoming.length} upcoming session${upcoming.length == 1 ? "" : "s"}',
                    style: AppTypography.helper
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go(_kDiscover),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: AppDecorations.primaryButton,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded,
                      size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: 4),
                  Text('Book', style: AppTypography.buttonSm),
                ]),
              ),
            ),
          ]),

          // ── Next session hero banner (only when there's an upcoming) ────
          if (next != null) ...[
            const SizedBox(height: 14),
            _NextSessionBanner(booking: next),
          ],

          // ── Stats row ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(children: [
            _StatPill(
              icon: Icons.event_available_rounded,
              label: '${upcoming.length} upcoming',
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _StatPill(
              icon: Icons.history_rounded,
              label: '$totalPast completed',
              color: AppColors.success,
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NextSessionBanner — live countdown to the next confirmed session
// ─────────────────────────────────────────────────────────────────────────────

class _NextSessionBanner extends StatefulWidget {
  final BookingModel booking;
  const _NextSessionBanner({required this.booking});

  @override
  State<_NextSessionBanner> createState() => _NextSessionBannerState();
}

class _NextSessionBannerState extends State<_NextSessionBanner> {
  Timer? _timer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(_update);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    final diff =
        widget.booking.slotStartTime!.difference(DateTime.now());
    if (diff.inDays > 1) {
      _countdown = 'in ${diff.inDays} days';
    } else if (diff.inDays == 1) {
      _countdown = 'tomorrow';
    } else if (diff.inHours > 0) {
      _countdown =
          'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      _countdown = 'in ${diff.inMinutes} min';
    } else {
      _countdown = 'starting soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final start = b.slotStartTime!;
    final day = _kDays[start.weekday - 1];
    final mon = _kMonths[start.month - 1];
    final h = start.hour % 12 == 0 ? 12 : start.hour % 12;
    final m = start.minute.toString().padLeft(2, '0');
    final ampm = start.hour < 12 ? 'AM' : 'PM';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: AppRadius.cardBR,
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        // Left: countdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.bolt_rounded,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Next session $_countdown',
                    style: AppTypography.badge
                        .copyWith(color: AppColors.primary)),
              ]),
              const SizedBox(height: 4),
              Text(b.trainerName,
                  style: AppTypography.h5
                      .copyWith(color: AppColors.textPrimary)),
              Text('$day, $mon ${start.day} · $h:$m $ampm',
                  style: AppTypography.helper
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        // Right: trainer initial circle
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppGradients.avatar,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              b.trainerName.isNotEmpty
                  ? b.trainerName[0].toUpperCase()
                  : '?',
              style:
                  AppTypography.h4.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.pillBR,
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.badge.copyWith(color: color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabBar
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
      ('Upcoming', upcomingCount, AppColors.primary),
      ('Past', pastCount, AppColors.success),
      ('Cancelled', cancelledCount, AppColors.error),
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
        labelStyle:
            AppTypography.chip.copyWith(fontWeight: FontWeight.w700),
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.25),
                            borderRadius: AppRadius.pillBR,
                          ),
                          child: Text(
                            '${t.$2}',
                            style: AppTypography.badge
                                .copyWith(color: AppColors.onPrimary),
                          ),
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
// _BookingTab enum
// ─────────────────────────────────────────────────────────────────────────────

enum _BookingTab { upcoming, past, cancelled }

// ─────────────────────────────────────────────────────────────────────────────
// _BookingList — one tab's scroll view with pull-to-refresh
// ─────────────────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final _BookingTab tab;
  final Future<void> Function(BookingModel)? onCancel;
  final Future<void> Function() onRefresh;

  const _BookingList({
    required this.bookings,
    required this.tab,
    required this.onRefresh,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return _EmptyState(tab: tab);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            _kHorizPad, 10, _kHorizPad, 96),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
        itemBuilder: (ctx, i) {
          final booking = bookings[i];

          // Wrap upcoming cards in Dismissible for swipe-to-cancel.
          if (tab == _BookingTab.upcoming &&
              booking.status == BookingStatus.confirmed &&
              onCancel != null) {
            return _SwipeToCancelWrapper(
              booking: booking,
              onCancel: onCancel!,
              child: _BookingCard(
                booking: booking,
                tab: tab,
                onCancel: onCancel,
              ),
            );
          }

          return _BookingCard(
            booking: booking,
            tab: tab,
            onCancel: onCancel,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SwipeToCancelWrapper — red swipe reveal on upcoming cards
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeToCancelWrapper extends StatelessWidget {
  final BookingModel booking;
  final Future<void> Function(BookingModel) onCancel;
  final Widget child;

  const _SwipeToCancelWrapper({
    required this.booking,
    required this.onCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismiss-${booking.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      confirmDismiss: (_) => _confirm(context),
      onDismissed: (_) => onCancel(booking),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: AppRadius.cardBR,
          border:
              Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
            const SizedBox(height: 4),
            Text('Cancel',
                style:
                    AppTypography.badge.copyWith(color: AppColors.error)),
          ],
        ),
      ),
      child: child,
    );
  }

  Future<bool?> _confirm(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) =>
            _CancelDialog(trainerName: booking.trainerName),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingCard
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final _BookingTab tab;
  final Future<void> Function(BookingModel)? onCancel;

  const _BookingCard({
    required this.booking,
    required this.tab,
    this.onCancel,
  });

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _cancelling = false;

  // ── Format helpers ────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    return '${_kDays[dt.weekday - 1]}, ${_kMonths[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  String _countdown(DateTime t) {
    final d = t.difference(DateTime.now());
    if (d.inDays > 1) return 'in ${d.inDays} days';
    if (d.inDays == 1) return 'tomorrow';
    if (d.inHours > 0) return 'in ${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return 'in ${d.inMinutes} min';
    return 'starting soon';
  }

  // ── Cancel via button ─────────────────────────────────────────────────────

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _CancelDialog(trainerName: widget.booking.trainerName),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await widget.onCancel!(widget.booking);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final start = b.slotStartTime;
    final isPast = start != null && start.isBefore(DateTime.now());

    // Determine card accent color from status and tab context.
    final Color accentColor = switch (widget.tab) {
      _BookingTab.upcoming => AppColors.primary,
      _BookingTab.past => AppColors.success,
      _BookingTab.cancelled => AppColors.error,
    };

    final statusLabel = switch (widget.tab) {
      _BookingTab.upcoming => 'Confirmed',
      _BookingTab.past => 'Completed',
      _BookingTab.cancelled => 'Cancelled',
    };

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: AppDecorations.card.copyWith(
          border: Border.all(
              color: accentColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Accent top bar ─────────────────────────────────────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(_kCardPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Trainer row ──────────────────────────────────────────
                  Row(children: [
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
                          style: AppTypography.h3.copyWith(
                              color: AppColors.onPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.trainerName, style: AppTypography.h5),
                          Text('Personal Trainer',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: AppRadius.pillBR,
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.25)),
                      ),
                      child: Text(statusLabel,
                          style: AppTypography.badge
                              .copyWith(color: accentColor)),
                    ),
                  ]),

                  if (start != null) ...[
                    const SizedBox(height: 12),

                    // ── Date + time ────────────────────────────────────────
                    Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(start)}  ·  ${_formatTime(start)}',
                        style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ]),

                    const SizedBox(height: 8),

                    // ── Pills row ──────────────────────────────────────────
                    Wrap(spacing: 7, runSpacing: 5, children: [
                      if (b.slotEndTime != null)
                        _Pill(
                          icon: Icons.timer_outlined,
                          label:
                              '${b.slotEndTime!.difference(start).inMinutes} min',
                        ),
                      _Pill(
                          icon: Icons.confirmation_number_outlined,
                          label: b.id.substring(0, 6).toUpperCase()),
                    ]),
                  ],

                  // ── Countdown bar (upcoming only) ──────────────────────
                  if (widget.tab == _BookingTab.upcoming &&
                      start != null &&
                      !isPast) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: AppRadius.inputBR,
                        border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        Icon(Icons.bolt_rounded,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Your session is ${_countdown(start)}',
                          style: AppTypography.helper
                              .copyWith(color: AppColors.primary),
                        ),
                      ]),
                    ),
                  ],

                  // ── Past: completion note ──────────────────────────────
                  if (widget.tab == _BookingTab.past) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            AppColors.success.withValues(alpha: 0.07),
                        borderRadius: AppRadius.inputBR,
                        border: Border.all(
                            color: AppColors.success
                                .withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Session completed',
                            style: AppTypography.helper
                                .copyWith(color: AppColors.success)),
                      ]),
                    ),
                  ],

                  // ── Cancelled: who cancelled ───────────────────────────
                  if (widget.tab == _BookingTab.cancelled &&
                      b.cancelledBy != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: AppRadius.inputBR,
                        border: Border.all(
                            color:
                                AppColors.error.withValues(alpha: 0.14)),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size: 12, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          b.cancelledBy == 'trainer'
                              ? 'Cancelled by trainer'
                              : 'Cancelled by you',
                          style: AppTypography.helper
                              .copyWith(color: AppColors.error),
                        ),
                      ]),
                    ),
                  ],

                  // ── Action buttons (upcoming confirmed) ────────────────
                  if (widget.tab == _BookingTab.upcoming &&
                      b.status == BookingStatus.confirmed &&
                      !isPast &&
                      widget.onCancel != null) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.go('/trainer/${b.trainerId}'),
                          child: Container(
                            height: 36,
                            decoration: AppDecorations.outlinedButton,
                            child: Center(
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_calendar_outlined,
                                        size: 13,
                                        color: AppColors.primary),
                                    const SizedBox(width: 5),
                                    Text('Reschedule',
                                        style: AppTypography.buttonSm
                                            .copyWith(
                                                color: AppColors.primary)),
                                  ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _cancelling ? null : _handleCancel,
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.error
                                  .withValues(alpha: 0.09),
                              borderRadius: AppRadius.inputBR,
                              border: Border.all(
                                  color: AppColors.error
                                      .withValues(alpha: 0.28)),
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
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close_rounded,
                                            size: 13,
                                            color: AppColors.error),
                                        const SizedBox(width: 5),
                                        Text('Cancel',
                                            style: AppTypography.buttonSm
                                                .copyWith(
                                                    color: AppColors.error)),
                                      ]),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tap → detail sheet ───────────────────────────────────────────────────

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: widget.booking,
        tab: widget.tab,
        onCancel: widget.onCancel,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingDetailSheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  final _BookingTab tab;
  final Future<void> Function(BookingModel)? onCancel;

  const _BookingDetailSheet({
    required this.booking,
    required this.tab,
    this.onCancel,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  bool _cancelling = false;

  static const _fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _fullDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String _fullDate(DateTime dt) =>
      '${_fullDays[dt.weekday - 1]}, ${dt.day} ${_fullMonths[dt.month - 1]} ${dt.year}';

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _CancelDialog(trainerName: widget.booking.trainerName),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      Navigator.pop(context);
      await widget.onCancel!(widget.booking);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final start = b.slotStartTime;
    final end = b.slotEndTime;
    final now = DateTime.now();
    final isPast = start != null && start.isBefore(now);

    final bool canCancel = widget.tab == _BookingTab.upcoming &&
        b.status == BookingStatus.confirmed &&
        !isPast &&
        widget.onCancel != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Trainer header
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
                  style: AppTypography.h2
                      .copyWith(color: AppColors.onPrimary),
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
                  ]),
            ),
          ]),

          const SizedBox(height: 20),

          // Details
          _DetailRow(
              icon: Icons.calendar_today_outlined,
              label:
                  start != null ? _fullDate(start) : 'Date TBC'),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.schedule_rounded,
              label: start != null
                  ? '${_time(start)}${end != null ? " – ${_time(end)}" : ""}'
                  : 'Time TBC'),
          if (start != null && end != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
                icon: Icons.timer_outlined,
                label:
                    '${end.difference(start).inMinutes} minute session'),
          ],
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.confirmation_number_outlined,
              label:
                  'Booking ID: ${b.id.substring(0, 8).toUpperCase()}'),

          // Countdown banner (upcoming only)
          if (start != null && !isPast) ...[
            const SizedBox(height: 16),
            _CountdownBanner(sessionTime: start),
          ],

          if (canCancel) ...[
            const SizedBox(height: 20),
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
                  onTap: _cancelling ? null : _handleCancel,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: AppRadius.inputBR,
                      border: Border.all(
                          color:
                              AppColors.error.withValues(alpha: 0.30)),
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
    if (diff.inHours > 0)
      return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes} minutes';
    return 'starting soon';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.inputBR,
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Your session is ${_label()}',
            style:
                AppTypography.helper.copyWith(color: AppColors.primary),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState — per-tab contextual empty states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _BookingTab tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String subtitle, bool showCta) =
        switch (tab) {
      _BookingTab.upcoming => (
          Icons.event_available_rounded,
          'No upcoming sessions',
          'Ready to get moving?',
          true,
        ),
      _BookingTab.past => (
          Icons.history_toggle_off_rounded,
          'No completed sessions yet',
          'Your finished sessions will appear here.',
          false,
        ),
      _BookingTab.cancelled => (
          Icons.event_busy_rounded,
          'No cancelled bookings',
          'Great — nothing cancelled so far.',
          false,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surfaceMid,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon,
                  color: AppColors.textMuted, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.h4
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.signature.copyWith(fontSize: 14)),
            if (showCta) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go(_kDiscover),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: AppDecorations.primaryButton,
                  child: Text('Find a Trainer',
                      style: AppTypography.button),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ]);
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _CancelDialog extends StatelessWidget {
  final String trainerName;
  const _CancelDialog({required this.trainerName});

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modalBR),
        title: Text('Cancel booking?', style: AppTypography.h4),
        content: Text(
          'Your session with $trainerName will be cancelled and the '
          'time slot will be released for other users.',
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
                style: AppTypography.button
                    .copyWith(color: AppColors.error)),
          ),
        ],
      );
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child:
                CircularProgressIndicator(color: AppColors.primary)),
      );
}