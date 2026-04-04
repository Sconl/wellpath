// lib/features/home/home_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v3.0.0 — Full dashboard redesign.
//   v3.1.0 — Replaced _ActivityCard with _NearbyMapCard (Mapbox embed).
//   v3.2.0 — Replaced direct Mapbox widget usage with AppMapWidget.
//   v3.3.0 — Full dual-engine system. _NearbyMapCard now uses AppMapWidget
//            from lib/core/maps/app_map_widget.dart. All mapbox_maps_flutter
//            imports removed from this file — zero SDK coupling.
//            Works on mobile (Mapbox) and web (flutter_map + OSM) with no
//            changes to this file. The engine is selected at compile time.
//
//   Navigation: AppNavShell drives all nav.
//   Background: AppBackground (meshParticle + drift + pulse).
//   FAB: AppFab — "Book Session" → /discover.
//
//   5 Dashboard Cards:
//   ┌─────────────────────────────────────────────────────────────────────────┐
//   │ Card 1 _NearbyMapCard       Map preview — local gyms. Tap → /discover.  │
//   │ Card 2 _BookingCalendarCard Month calendar; confirmed sessions ringed.   │
//   │ Card 3 _WellnessRingsCard   Rings: workout / water / sleep + log strip. │
//   │ Card 4 _NextSessionCard     Next booking, countdown, reschedule link.    │
//   │ Card 5 _GoalsCard           Streak + workout pips + weight progress bar. │
//   └─────────────────────────────────────────────────────────────────────────┘
//
//   Responsive (content-column width via LayoutBuilder):
//   ≥ 900 px   Row[Card1(55%) | Card2(45%)] + Row[Card3 | Card4(44%) | Card5]
//   550-899px  Card1 / Row[Card2 | Card3] / Row[Card4 | Card5]
//   < 550 px   Card1 / Card2 / Row[Card3 | Card4] / Card5
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/maps/app_map_widget.dart';
import '../../core/navigation/app_nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_branding.dart';
import '../../core/theme/app_background.dart';
import '../../core/widgets/app_fab.dart';
import '../auth/providers/auth_providers.dart';
import './providers/home_providers.dart';
import './widgets/quick_log_sheet.dart';
import '../wellness/data/wellness_log_model.dart';
import '../bookings/data/booking_model.dart';
import '../discover/providers/discover_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kHorizPad  = 24.0;
const double _kVertPad   = 24.0;
const double _kCardGap   = 14.0;
const double _kBreakWide = 900.0;   // content-column width breakpoints
const double _kBreakMid  = 550.0;

// ── Card 1 — Nearby Map ──
const double _kMapCardMapH    = 200.0;   // height of the embedded map
const double _kMapCardPadding = 20.0;

// Mapbox dark style (mobile). Ignored on web — OSM tiles used automatically.
const String _kMapStyle    = 'mapbox://styles/mapbox/dark-v11';
const double _kHomeMapZoom = 13.5;   // slightly wider than discover (14) for overview

// Fallback coords as plain doubles — not SDK types, fully const-safe.
const double _kFallbackLat = -4.0435;   // Mombasa CBD
const double _kFallbackLng = 39.6682;

// ── Ring / animation ──
const double _kRingSize   = 64.0;
const double _kRingStroke = 6.5;

// ── Routes ──
const String _kDiscover    = '/discover';
const String _kBookings    = '/bookings';
const String _kAvailability = '/availability';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  final bool isTrainerView;
  const HomeScreen({super.key, this.isTrainerView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);

    return userAsync.when(
      loading: () => _LoadingScaffold(),
      error:   (_, __) => _ErrorScaffold(),
      data: (user) {
        if (user == null) return _LoadingScaffold();
        return AppNavShell(
          currentRoute:  '/home',
          isTrainerView: isTrainerView,
          displayName:   user.displayName,
          photoUrl:      user.photoUrl,
          child: _ScreenBody(user: user, isTrainerView: isTrainerView),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScreenBody
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenBody extends ConsumerWidget {
  final UserModel user;
  final bool      isTrainerView;
  const _ScreenBody({required this.user, required this.isTrainerView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBackground(
      type:          BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: SafeArea(
        child: Stack(
          children: [
            isTrainerView
                ? _TrainerDashboard(user: user)
                : _UserDashboard(user: user),

            Positioned(
              right:  kFabMarginRight,
              bottom: kFabMarginBottom,
              child: isTrainerView
                  ? AppFab(
                      icon:    Icons.event_available_rounded,
                      label:   'Add Availability',
                      tooltip: 'Add new time slots for clients to book',
                      onPressed: () => context.go(_kAvailability),
                    )
                  : AppFab(
                      icon:    Icons.add_circle_outline_rounded,
                      label:   'Book Session',
                      tooltip: 'Find and book a session with a certified trainer',
                      onPressed: () => context.go(_kDiscover),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UserDashboard
// ─────────────────────────────────────────────────────────────────────────────

class _UserDashboard extends ConsumerWidget {
  final UserModel user;
  const _UserDashboard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs     = ref.watch(todayWellnessLogsProvider).valueOrNull ?? [];
    final bookings = ref.watch(upcomingBookingsProvider).valueOrNull  ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: _kHorizPad, vertical: _kVertPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashHeader(user: user),
          const SizedBox(height: _kCardGap + 4),
          _CardGrid(logs: logs, bookings: bookings),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerDashboard
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerDashboard extends ConsumerWidget {
  final UserModel user;
  const _TrainerDashboard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(trainerBookingsProvider).valueOrNull ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: _kHorizPad, vertical: _kVertPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashHeader(user: user, isTrainer: true),
          const SizedBox(height: _kCardGap + 4),
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth >= _kBreakMid;
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 5,
                          child: _BookingCalendarCard(bookings: bookings)),
                      const SizedBox(width: _kCardGap),
                      Expanded(
                        flex: 5,
                        child: Column(children: [
                          _NextSessionCard(bookings: bookings),
                          const SizedBox(height: _kCardGap),
                          _TrainerStatsCard(bookings: bookings),
                        ]),
                      ),
                    ],
                  )
                : Column(children: [
                    _BookingCalendarCard(bookings: bookings),
                    const SizedBox(height: _kCardGap),
                    _NextSessionCard(bookings: bookings),
                    const SizedBox(height: _kCardGap),
                    _TrainerStatsCard(bookings: bookings),
                  ]);
          }),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DashHeader
// ─────────────────────────────────────────────────────────────────────────────

class _DashHeader extends ConsumerWidget {
  final UserModel user;
  final bool      isTrainer;
  const _DashHeader({required this.user, this.isTrainer = false});

  static const double _kShowSearch = 520.0;
  static const double _kShowLabel  = 380.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour      = DateTime.now().hour;
    final timeWord  = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    final firstName = user.displayName.trim().split(' ').first;
    final ctaRoute  = isTrainer ? _kAvailability : _kDiscover;
    final ctaLabel  = isTrainer ? 'My Schedule'  : 'Find Trainer';

    return LayoutBuilder(builder: (ctx, box) {
      final w          = box.maxWidth;
      final showSearch = w >= _kShowSearch;
      final showLabel  = w >= _kShowLabel;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const HamburgerButton(),
          const SizedBox(width: 6),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $firstName!',
                  style:    AppTypography.h2.copyWith(height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isTrainer
                      ? 'Your clients are counting on you'
                      : 'Good $timeWord — check your activity',
                  style:    AppTypography.helper,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (showSearch) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => context.go(_kDiscover),
              child: Container(
                width:   200,
                height:  38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: AppRadius.pillBR,
                  border:       Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isTrainer ? 'Search clients...' : 'Trainers, exercises...',
                      style:    AppTypography.helper
                          .copyWith(color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
          ],

          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go(ctaRoute),
            child: showLabel
                ? Container(
                    height:  38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: AppDecorations.primaryButton,
                    child: Center(
                        child: Text(ctaLabel, style: AppTypography.buttonSm)),
                  )
                : Container(
                    width:  38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient:  AppGradients.button,
                      shape:     BoxShape.circle,
                      boxShadow: AppShadows.buttonGlow,
                    ),
                    child: Icon(
                      isTrainer
                          ? Icons.event_available_rounded
                          : Icons.search_rounded,
                      size:  18,
                      color: AppColors.onPrimary,
                    ),
                  ),
          ),

          const SizedBox(width: 4),
          IconButton(
            onPressed:   () => ref.read(authRepositoryProvider).signOut(),
            icon:        const Icon(Icons.logout_outlined, size: 17),
            color:       AppColors.textMuted,
            tooltip:     'Sign out',
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardGrid — 5-card responsive layout
// ─────────────────────────────────────────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  final List<WellnessLog>  logs;
  final List<BookingModel> bookings;
  const _CardGrid({required this.logs, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth;

      if (w >= _kBreakWide) {
        return Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(flex: 55, child: _NearbyMapCard()),
            const SizedBox(width: _kCardGap),
            Expanded(
                flex: 45,
                child: _BookingCalendarCard(bookings: bookings)),
          ]),
          const SizedBox(height: _kCardGap),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 28, child: _WellnessRingsCard(logs: logs)),
            const SizedBox(width: _kCardGap),
            Expanded(
                flex: 44,
                child: _NextSessionCard(bookings: bookings)),
            const SizedBox(width: _kCardGap),
            Expanded(flex: 28, child: _GoalsCard(logs: logs)),
          ]),
        ]);
      }

      if (w >= _kBreakMid) {
        return Column(children: [
          const _NearbyMapCard(),
          const SizedBox(height: _kCardGap),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _BookingCalendarCard(bookings: bookings)),
            const SizedBox(width: _kCardGap),
            Expanded(child: _WellnessRingsCard(logs: logs)),
          ]),
          const SizedBox(height: _kCardGap),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _NextSessionCard(bookings: bookings)),
            const SizedBox(width: _kCardGap),
            Expanded(child: _GoalsCard(logs: logs)),
          ]),
        ]);
      }

      return Column(children: [
        const _NearbyMapCard(),
        const SizedBox(height: _kCardGap),
        _BookingCalendarCard(bookings: bookings),
        const SizedBox(height: _kCardGap),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _WellnessRingsCard(logs: logs)),
          const SizedBox(width: _kCardGap),
          Expanded(child: _NextSessionCard(bookings: bookings)),
        ]),
        const SizedBox(height: _kCardGap),
        _GoalsCard(logs: logs),
      ]);
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD 1 — _NearbyMapCard
//
// Embedded map preview — gestures disabled (AbsorbPointer) so the card
// doesn't intercept the parent SingleChildScrollView's scroll events.
// Gym pins refresh reactively when nearbyGymsProvider loads.
// Location re-centres when userLocationProvider resolves.
// Tap anywhere → /discover (full interactive map + gym list).
// ═════════════════════════════════════════════════════════════════════════════

class _NearbyMapCard extends ConsumerStatefulWidget {
  const _NearbyMapCard();

  @override
  ConsumerState<_NearbyMapCard> createState() => _NearbyMapCardState();
}

class _NearbyMapCardState extends ConsumerState<_NearbyMapCard> {
  // Abstract controller — no SDK type referenced anywhere in this widget.
  AppMapController? _mapController;

  void _onMapReady(AppMapController ctrl) {
    _mapController = ctrl;
    _pinGyms(ref.read(nearbyGymsProvider).valueOrNull ?? []);
  }

  Future<void> _pinGyms(List<dynamic> gyms) async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    final pins = gyms.map((g) => AppMapPin(
      id:  g.placeId as String,
      lat: g.lat     as double,
      lng: g.lng     as double,
    )).toList();
    await ctrl.setPins(pins);
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final gymsAsync     = ref.watch(nearbyGymsProvider);

    // Re-centre map when GPS resolves.
    ref.listen(userLocationProvider, (_, next) {
      final loc = next.value;
      if (loc != null) _mapController?.animateTo(loc.lat, loc.lng);
    });

    // Re-pin when gyms finish loading.
    ref.listen(nearbyGymsProvider, (_, next) {
      _pinGyms(next.valueOrNull ?? []);
    });

    final gyms = gymsAsync.valueOrNull ?? [];
    final countLabel = gymsAsync.isLoading
        ? 'Finding gyms near you...'
        : gyms.isEmpty
            ? 'No gyms found nearby'
            : '${gyms.length} gym${gyms.length == 1 ? "" : "s"} near you';

    final centre = locationAsync.value ??
        const AppLatLng(_kFallbackLat, _kFallbackLng);

    return GestureDetector(
      onTap: () => context.go(_kDiscover),
      child: Container(
        decoration: AppDecorations.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Card header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  _kMapCardPadding, _kMapCardPadding,
                  _kMapCardPadding, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding:    const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: AppRadius.inputBR,
                      ),
                      child: Icon(Icons.place_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trainers Near You',
                            style: AppTypography.h4.copyWith(
                                color: AppColors.textPrimary)),
                        Text(countLabel,
                            style: AppTypography.helper.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ]),
                  GestureDetector(
                    onTap: () => context.go(_kDiscover),
                    child: Text('View all →',
                        style: AppTypography.helper.copyWith(
                            color: AppColors.primary)),
                  ),
                ],
              ),
            ),

            // ── Embedded map ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(AppRadius.card),
                bottomRight: Radius.circular(AppRadius.card),
              ),
              child: SizedBox(
                height: _kMapCardMapH,
                child: Stack(children: [

                  // AbsorbPointer prevents the map from consuming scroll events.
                  // The GestureDetector above the Stack still receives taps on
                  // the card itself, routing the user to /discover.
                  AbsorbPointer(
                    child: AppMapWidget(
                      key:        const ValueKey('home-map'),
                      initialLat: centre.lat,
                      initialLng: centre.lng,
                      initialZoom: _kHomeMapZoom,
                      styleUri:   _kMapStyle,
                      onMapReady: _onMapReady,
                    ),
                  ),

                  // Loading overlay while gyms are fetching.
                  if (gymsAsync.isLoading)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.surface.withValues(alpha: 0.55),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                    ),

                  // "Tap to explore" hint pill — communicates interactivity.
                  Positioned(
                    bottom: 12,
                    left:   0,
                    right:  0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color:        AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: AppRadius.pillBR,
                          boxShadow:    AppShadows.card,
                          border:       Border.all(color: AppColors.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.touch_app_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Tap to explore gyms & trainers',
                              style: AppTypography.badge.copyWith(
                                  color: AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD 2 — _BookingCalendarCard
// ═════════════════════════════════════════════════════════════════════════════

class _BookingCalendarCard extends StatefulWidget {
  final List<BookingModel> bookings;
  const _BookingCalendarCard({required this.bookings});
  @override
  State<_BookingCalendarCard> createState() => _BookingCalendarCardState();
}

class _BookingCalendarCardState extends State<_BookingCalendarCard> {
  late DateTime _month;
  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _month = DateTime(_today.year, _today.month);
  }

  Set<int> get _booked => widget.bookings
      .where((b) =>
          b.slotStartTime != null &&
          b.slotStartTime!.year  == _month.year &&
          b.slotStartTime!.month == _month.month)
      .map((b) => b.slotStartTime!.day)
      .toSet();

  static const _mn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  void _prev() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final days    = DateUtils.getDaysInMonth(_month.year, _month.month);
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1;
    final booked  = _booked;

    return Container(
      padding:    const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Training Calendar', style: AppTypography.h4),
          Row(children: [
            _CalBtn(icon: Icons.chevron_left_rounded,  onTap: _prev),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.go(_kBookings),
              child: Text('${_mn[_month.month - 1]} ${_month.year}',
                  style: AppTypography.h5
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            _CalBtn(icon: Icons.chevron_right_rounded, onTap: _next),
          ]),
        ]),

        const SizedBox(height: 14),

        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: AppTypography.caption
                              .copyWith(fontSize: 10)),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics:    const NeverScrollableScrollPhysics(),
          itemCount:  leading + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:  7,
            childAspectRatio: 1,
            mainAxisSpacing:  4,
            crossAxisSpacing: 0,
          ),
          itemBuilder: (_, i) {
            if (i < leading) return const SizedBox();
            final day     = i - leading + 1;
            final isToday = _month.year  == _today.year  &&
                            _month.month == _today.month &&
                            day           == _today.day;
            final hasBook = booked.contains(day);

            return GestureDetector(
              onTap: hasBook ? () => context.go(_kBookings) : null,
              child: Center(
                child: Container(
                  width:  27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary
                        : Colors.transparent,
                    shape:  BoxShape.circle,
                    border: hasBook && !isToday
                        ? Border.all(
                            color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Text(
                      '$day',
                      style: AppTypography.caption.copyWith(
                        color: isToday
                            ? AppColors.onPrimary
                            : hasBook
                                ? AppColors.primary
                                : AppColors.textMuted,
                        fontWeight: isToday || hasBook
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (hasBook && !isToday)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          width:  4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Row(children: [
          _CalLegend(
              color: AppColors.primary, dot: false, label: 'Today'),
          const SizedBox(width: 14),
          _CalLegend(
              color: AppColors.primary,
              dot:   true,
              label: 'Session booked'),
          const Spacer(),
          Text('${booked.length} this month',
              style: AppTypography.caption
                  .copyWith(color: AppColors.primary)),
        ]),
      ]),
    );
  }
}

class _CalBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _CalBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width:  26,
      height: 26,
      decoration: BoxDecoration(
        color:        AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    ),
  );
}

class _CalLegend extends StatelessWidget {
  final Color  color;
  final bool   dot;
  final String label;
  const _CalLegend(
      {required this.color, required this.dot, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width:  dot ? 8 : 14,
      height: dot ? 8 : 6,
      decoration: BoxDecoration(
        color:        color,
        shape:        dot ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: dot ? null : BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: 5),
    Text(label, style: AppTypography.caption),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD 3 — _WellnessRingsCard
// ═════════════════════════════════════════════════════════════════════════════

class _WellnessRingsCard extends StatefulWidget {
  final List<WellnessLog> logs;
  const _WellnessRingsCard({required this.logs});
  @override
  State<_WellnessRingsCard> createState() => _WellnessRingsCardState();
}

class _WellnessRingsCardState extends State<_WellnessRingsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _sum(WellnessType t) =>
      widget.logs.where((l) => l.type == t).fold(0.0, (s, l) => s + l.value);

  @override
  Widget build(BuildContext context) {
    final workout = _sum(WellnessType.workout);
    final water   = _sum(WellnessType.water);
    final sleep   = _sum(WellnessType.sleep);
    final allMet  = workout >= kDefaultWorkoutTargetMins &&
                    water   >= kDefaultWaterTargetGlasses &&
                    sleep   >= kDefaultSleepTargetHours;

    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Today's Progress", style: AppTypography.h5),
          if (allMet)
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 15),
        ]),

        const SizedBox(height: 18),

        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Column(children: [
            _RingRow(
                label:  'Workout',
                value:  workout,
                target: kDefaultWorkoutTargetMins,
                unit:   'min',
                color:  AppColors.primary,
                anim:   _anim.value),
            const SizedBox(height: 14),
            _RingRow(
                label:  'Water',
                value:  water,
                target: kDefaultWaterTargetGlasses,
                unit:   'gl',
                color:  AppColors.secondary,
                anim:   _anim.value),
            const SizedBox(height: 14),
            _RingRow(
                label:  'Sleep',
                value:  sleep,
                target: kDefaultSleepTargetHours,
                unit:   'hr',
                color:  AppColors.tertiary,
                anim:   _anim.value),
          ]),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: WellnessType.values.map((t) {
            final icon = switch (t) {
              WellnessType.workout => Icons.fitness_center_rounded,
              WellnessType.water   => Icons.water_drop_rounded,
              WellnessType.sleep   => Icons.bedtime_rounded,
            };
            return GestureDetector(
              onTap: () => showModalBottomSheet<bool>(
                context:            context,
                isScrollControlled: true,
                backgroundColor:    Colors.transparent,
                builder:            (_) => QuickLogSheet(type: t),
              ),
              child: Tooltip(
                message: 'Log ${WellnessTypeX(t).displayLabel}',
                child: Container(
                  padding:    const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color:        AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                    border:       Border.all(color: AppColors.border),
                  ),
                  child: Icon(icon, size: 14, color: AppColors.primary),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _RingRow extends StatelessWidget {
  final String label;
  final double value, target, anim;
  final String unit;
  final Color  color;
  const _RingRow({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0.0, 1.0) * anim;
    final display  = unit == 'hr' && value % 1 != 0
        ? value.toStringAsFixed(1)
        : value.toInt().toString();

    return Row(children: [
      SizedBox(
        width:  _kRingSize,
        height: _kRingSize,
        child:  Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value:       1,
            strokeWidth: _kRingStroke,
            color:       color.withValues(alpha: 0.10),
            strokeCap:   StrokeCap.round,
          ),
          CircularProgressIndicator(
            value:       progress,
            strokeWidth: _kRingStroke,
            color:       color,
            strokeCap:   StrokeCap.round,
          ),
          Text(display, style: AppTypography.h5.copyWith(color: color)),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: AppTypography.h5),
          Text('${target.toInt()} $unit target',
              style: AppTypography.caption),
        ]),
      ),
      Text('${(progress * 100).toInt()}%',
          style: AppTypography.helper.copyWith(color: color)),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD 4 — _NextSessionCard
// ═════════════════════════════════════════════════════════════════════════════

class _NextSessionCard extends StatelessWidget {
  final List<BookingModel> bookings;
  const _NextSessionCard({required this.bookings});

  BookingModel? get _next {
    final now  = DateTime.now();
    final list = bookings
        .where((b) =>
            b.slotStartTime != null &&
            b.slotStartTime!.isAfter(now) &&
            b.status == BookingStatus.confirmed)
        .toList()
      ..sort((a, b) => a.slotStartTime!.compareTo(b.slotStartTime!));
    return list.isEmpty ? null : list.first;
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;
    return Container(
      padding:    const EdgeInsets.all(20),
      decoration: AppDecorations.cardElevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Next Session', style: AppTypography.h4),
          GestureDetector(
            onTap: () => context.go(_kBookings),
            child: Text('All →',
                style: AppTypography.helper.copyWith(
                    color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 16),
        if (next == null)
          _EmptySession(context: context)
        else
          _SessionDetail(booking: next),
      ]),
    );
  }
}

class _SessionDetail extends StatelessWidget {
  final BookingModel booking;
  const _SessionDetail({required this.booking});

  static const _mo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _dy = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  String _countdown(DateTime t) {
    final d = t.difference(DateTime.now());
    if (d.inDays > 0)    return 'in ${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0)   return 'in ${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return 'in ${d.inMinutes}m';
    return 'Starting soon';
  }

  @override
  Widget build(BuildContext context) {
    final start = booking.slotStartTime!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width:  46,
          height: 46,
          decoration: BoxDecoration(
            gradient:     AppGradients.avatar,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              booking.trainerName.isNotEmpty
                  ? booking.trainerName[0].toUpperCase()
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
              Text(booking.trainerName, style: AppTypography.h4),
              Text('Personal Trainer', style: AppTypography.caption),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color:        AppColors.success.withValues(alpha: 0.12),
            borderRadius: AppRadius.pillBR,
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Text('Confirmed',
              style: AppTypography.badge.copyWith(
                  color: AppColors.success)),
        ),
      ]),

      const SizedBox(height: 14),

      Wrap(spacing: 8, runSpacing: 6, children: [
        _InfoPill(
          icon:  Icons.calendar_today_outlined,
          label: '${_dy[start.weekday - 1]}, ${_mo[start.month - 1]} ${start.day}',
        ),
        _InfoPill(icon: Icons.schedule_rounded, label: _fmt(start)),
      ]),

      const SizedBox(height: 12),

      Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color:        AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.inputBR,
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          Icon(Icons.timer_outlined, size: 13, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(_countdown(start),
              style: AppTypography.helper.copyWith(
                  color: AppColors.primary)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go(_kBookings),
            child: Text('Reschedule',
                style: AppTypography.caption.copyWith(
                  color:      AppColors.textMuted,
                  decoration: TextDecoration.underline,
                )),
          ),
        ]),
      ),
    ]);
  }
}

class _EmptySession extends StatelessWidget {
  final BuildContext context;
  const _EmptySession({required this.context});

  @override
  Widget build(BuildContext _) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.calendar_today_outlined,
          color: AppColors.textMuted, size: 30),
      const SizedBox(height: 10),
      Text('No upcoming sessions',
          style: AppTypography.h5.copyWith(
              color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Text('Book a certified trainer to kickstart your journey.',
          style: AppTypography.bodySmall),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () => context.go(_kDiscover),
        child: Container(
          padding:    const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: AppDecorations.primaryButton,
          child: Text('Find a Trainer', style: AppTypography.buttonSm),
        ),
      ),
    ],
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color:        AppColors.surfaceMid,
      borderRadius: AppRadius.inputBR,
      border:       Border.all(color: AppColors.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.textMuted),
      const SizedBox(width: 5),
      Text(label, style: AppTypography.caption),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD 5 — _GoalsCard
// ═════════════════════════════════════════════════════════════════════════════

class _GoalsCard extends StatefulWidget {
  final List<WellnessLog> logs;
  const _GoalsCard({required this.logs});
  @override
  State<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends State<_GoalsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _streak {
    final now = DateTime.now();
    return widget.logs
        .where((l) => now.difference(l.timestamp).inDays < 30)
        .map((l) =>
            DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day))
        .toSet()
        .length;
  }

  int get _weeklyWorkouts {
    final cut = DateTime.now().subtract(const Duration(days: 7));
    return widget.logs
        .where((l) =>
            l.type == WellnessType.workout && l.timestamp.isAfter(cut))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    const startKg  = 80.0;
    const curKg    = 75.4;
    const goalKg   = 70.0;
    const progress = (startKg - curKg) / (startKg - goalKg);

    final streak   = _streak;
    final workouts = _weeklyWorkouts;

    return Container(
      padding:    const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('My Goals', style: AppTypography.h4),
          Icon(Icons.emoji_events_rounded,
              color: AppColors.warning, size: 17),
        ]),

        const SizedBox(height: 16),

        Row(children: [
          Expanded(
            child: _GoalStat(
                value: '$streak',
                label: 'Day\nStreak',
                color: AppColors.primary),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _GoalStat(
                value: '$workouts/5',
                label: 'Weekly\nSessions',
                color: AppColors.secondary),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _GoalStat(
                value: '${(progress * 100).toInt()}%',
                label: 'Weight\nGoal',
                color: AppColors.tertiary),
          ),
        ]),

        const SizedBox(height: 18),
        Text('Weight Loss Progress', style: AppTypography.h5),
        const SizedBox(height: 8),

        AnimatedBuilder(
          animation: _anim,
          builder:   (_, __) => Column(children: [
            Align(
              alignment: Alignment(progress * 2 - 1, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient:     AppGradients.button,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${curKg}kg',
                    style: AppTypography.badge.copyWith(
                        color: AppColors.onPrimary)),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value:           progress * _anim.value,
                minHeight:       8,
                backgroundColor: AppColors.surfaceMid,
                valueColor:
                    AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${startKg.toInt()}kg',
                    style: AppTypography.caption),
                Text('${goalKg.toInt()}kg goal',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.primary)),
              ],
            ),
          ]),
        ),

        const SizedBox(height: 16),

        Row(children: [
          Text('This week  ', style: AppTypography.caption),
          ...List.generate(
            5,
            (i) => Container(
              width:  13,
              height: 13,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color:  i < workouts
                    ? AppColors.primary
                    : AppColors.surfaceMid,
                shape:  BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _GoalStat extends StatelessWidget {
  final String value, label;
  final Color  color;
  const _GoalStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTypography.h3.copyWith(color: color)),
    const SizedBox(height: 2),
    Text(label,
        textAlign: TextAlign.center, style: AppTypography.caption),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// TRAINER: _TrainerStatsCard
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerStatsCard extends StatelessWidget {
  final List<BookingModel> bookings;
  const _TrainerStatsCard({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final upcoming = bookings
        .where((b) =>
            b.slotStartTime != null &&
            b.slotStartTime!.isAfter(DateTime.now()))
        .length;

    return Container(
      padding:    const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick Stats', style: AppTypography.h4),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _GoalStat(
                value: '$upcoming',
                label: 'Upcoming\nSessions',
                color: AppColors.primary),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _GoalStat(
                value: '0',
                label: 'Pending\nRequests',
                color: AppColors.warning),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _GoalStat(
                value: '${bookings.length}',
                label: 'Total\nBooked',
                color: AppColors.secondary),
          ),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go(_kAvailability),
          child: Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: AppDecorations.outlinedButton,
            child: Center(
              child: Text('Manage Availability',
                  style: AppTypography.buttonSm.copyWith(
                      color: AppColors.primary)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility scaffolds
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
        child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

class _ErrorScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Error loading profile.\nPlease sign out and try again.',
          textAlign: TextAlign.center,
          style:     TextStyle(color: Colors.white70),
        ),
      ),
    ),
  );
}