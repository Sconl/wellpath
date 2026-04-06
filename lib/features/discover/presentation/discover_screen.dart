// lib/features/discover/presentation/discover_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Hybrid Discovery screen.
//   v1.1.0 — Replaced google_maps_flutter with mapbox_maps_flutter.
//   v1.2.0 — Replaced direct Mapbox widget usage with AppMapWidget dual-engine
//            system (lib/core/maps/app_map_widget.dart).
//            Now compiles for both mobile (Mapbox) and web (flutter_map + OSM)
//            without any changes to this file. The map implementation is
//            selected at compile time by Dart's conditional export.
//            All MapboxMap / MapWidget / MapInitOptions / ResourceOptions
//            references removed — this file has zero map SDK imports.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/maps/app_map_widget.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/navigation/app_nav.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/place_model.dart';
import '../providers/discover_providers.dart';
import 'widgets/gym_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kBreakHybrid     = 720.0;   // map+list side-by-side above this
const double _kMapHeightMobile = 280.0;   // stacked map height on mobile
const double _kListPadH        = 16.0;
const double _kListPadV        = 16.0;
const double _kCardGap         = 10.0;
const double _kSearchBarH      = 44.0;
const double _kFilterChipH     = 34.0;
const double _kMapFraction     = 0.46;    // map takes 46% of width in hybrid

// ── Map ──
// Mapbox dark style (mobile). Ignored on web — OSM is used automatically.
const String _kMapStyle    = 'mapbox://styles/mapbox/dark-v11';
const double _kDefaultZoom = 14.0;

// ── Copy ──
const String _kSearchHint    = 'Search gyms & trainers...';
const String _kEmptyGyms     = 'No gyms found nearby.\nTry expanding your search area.';
const String _kEmptyTrainers = 'Trainers are coming soon.\nBe the first to sign up!';
const String _kLocationBanner = 'Showing results near Mombasa CBD';

// ─────────────────────────────────────────────────────────────────────────────
// DiscoverScreen
// ─────────────────────────────────────────────────────────────────────────────

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);

    return userAsync.when(
      loading: () => _LoadingScaffold(),
      error:   (_, __) => _LoadingScaffold(),
      data: (user) => AppNavShell(
        currentRoute:  '/discover',
        isTrainerView: false,
        displayName:   user?.displayName ?? '',
        photoUrl:      user?.photoUrl,
        child: const _DiscoverBody(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DiscoverBody
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverBody extends ConsumerStatefulWidget {
  const _DiscoverBody();

  @override
  ConsumerState<_DiscoverBody> createState() => _DiscoverBodyState();
}

class _DiscoverBodyState extends ConsumerState<_DiscoverBody> {
  // The only map reference in this entire file — the abstract controller.
  // No Mapbox types, no flutter_map types. This file is engine-agnostic.
  AppMapController? _mapController;

  String?              _selectedPlaceId;
  final _searchCtrl  = TextEditingController();
  final _itemKeys    = <String, GlobalKey>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Map ready ─────────────────────────────────────────────────────────────

  void _onMapReady(AppMapController ctrl) {
    _mapController = ctrl;
    // Pin whatever gyms are already loaded when the map first renders.
    final gyms = ref.read(nearbyGymsProvider).valueOrNull ?? [];
    _refreshPins(gyms);
  }

  // ── Pin management ────────────────────────────────────────────────────────

  Future<void> _refreshPins(List<PlaceModel> gyms) async {
    final ctrl = _mapController;
    if (ctrl == null) return;

    final pins = gyms.map((g) => AppMapPin(
      id:       g.placeId,
      lat:      g.lat,
      lng:      g.lng,
      selected: g.placeId == _selectedPlaceId,
    )).toList();

    await ctrl.setPins(pins);
  }

  // ── Card / pin interaction ────────────────────────────────────────────────

  Future<void> _onCardTapped(PlaceModel place) async {
    setState(() => _selectedPlaceId = place.placeId);

    final gyms = ref.read(nearbyGymsProvider).valueOrNull ?? [];
    await _refreshPins(gyms);

    // Fly map to the selected gym — zoom in one extra level for context.
    await _mapController?.animateTo(
      place.lat,
      place.lng,
      zoom: _kDefaultZoom + 1,
    );

    // Scroll the list so the selected card is visible.
    final key = _itemKeys[place.placeId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeOut,
      );
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<PlaceModel> _filtered(List<PlaceModel> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q))
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filterState   = ref.watch(discoverFilterProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final gymsAsync     = ref.watch(nearbyGymsProvider);

    // Refresh pins whenever the gym list loads or changes.
    ref.listen(nearbyGymsProvider, (_, next) {
      _refreshPins(next.valueOrNull ?? []);
    });

    // Fly map to GPS location once it resolves.
    ref.listen(userLocationProvider, (_, next) {
      final loc = next.value;
      if (loc != null) {
        _mapController?.animateTo(loc.lat, loc.lng);
      }
    });

    final centre = locationAsync.value ??
        const AppLatLng(kFallbackLat, kFallbackLng);

    final gyms     = gymsAsync.valueOrNull ?? [];
    final filtered = _filtered(gyms, filterState.query);

    return Column(children: [
      // ── Search + filter bar ───────────────────────────────────────────
      _SearchFilterBar(
        controller: _searchCtrl,
        filter:     filterState.filter,
        onSearch:   (q) =>
            ref.read(discoverFilterProvider.notifier).setQuery(q),
        onFilter:   (f) =>
            ref.read(discoverFilterProvider.notifier).setFilter(f),
      ),

      // ── Fallback location banner ──────────────────────────────────────
      if (locationAsync.value?.isFallback == true) _LocationBanner(),

      // ── Map + list — hybrid or stacked ───────────────────────────────
      Expanded(
        child: LayoutBuilder(builder: (ctx, box) {
          final wide = box.maxWidth >= _kBreakHybrid;

          // AppMapWidget — one import, correct engine selected at compile time.
          final mapWidget = AppMapWidget(
            key:        const ValueKey('discover-map'),
            initialLat: centre.lat,
            initialLng: centre.lng,
            initialZoom: _kDefaultZoom,
            styleUri:   _kMapStyle,
            onMapReady: _onMapReady,
          );

          final listWidget = _ResultList(
            gymsAsync:  gymsAsync,
            filtered:   filtered,
            filter:     filterState.filter,
            selectedId: _selectedPlaceId,
            itemKeys:   _itemKeys,
            onCardTap:  _onCardTapped,
          );

          if (wide) {
            return Row(children: [
              SizedBox(
                  width: box.maxWidth * _kMapFraction,
                  child: mapWidget),
              Expanded(child: listWidget),
            ]);
          }
          return Column(children: [
            SizedBox(height: _kMapHeightMobile, child: mapWidget),
            Expanded(child: listWidget),
          ]);
        }),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchFilterBar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController        controller;
  final DiscoverFilter               filter;
  final ValueChanged<String>         onSearch;
  final ValueChanged<DiscoverFilter> onFilter;

  const _SearchFilterBar({
    required this.controller,
    required this.filter,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Search field ────────────────────────────────────────────────
          SizedBox(
            height: _kSearchBarH,
            child: TextField(
              controller: controller,
              onChanged:  onSearch,
              style:      AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:   _kSearchHint,
                hintStyle:  AppTypography.body.copyWith(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap:  () => onSearch(''),
                        child:  Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMuted),
                      )
                    : null,
                filled:       true,
                fillColor:    AppColors.surfaceMid,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide:   BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide:   BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide:   BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Filter chips ────────────────────────────────────────────────
          Row(children: [
            _FilterChip(
              label:    'Gyms Nearby',
              icon:     Icons.fitness_center_rounded,
              selected: filter == DiscoverFilter.gyms,
              onTap:    () => onFilter(DiscoverFilter.gyms),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label:    'Trainers',
              icon:     Icons.person_rounded,
              selected: filter == DiscoverFilter.trainers,
              onTap:    () => onFilter(DiscoverFilter.trainers),
              badge:    'Soon',
            ),
          ]),

          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final VoidCallback onTap;
  final String?      badge;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height:   _kFilterChipH,
        padding:  const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceMid,
          borderRadius: AppRadius.pillBR,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size:  14,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.helper.copyWith(
                color:      selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:        AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillBR,
                ),
                child: Text(badge!,
                    style: AppTypography.badge.copyWith(
                        color: AppColors.warning)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocationBanner
// ─────────────────────────────────────────────────────────────────────────────

class _LocationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:   AppColors.warning.withValues(alpha: 0.10),
      child: Row(children: [
        Icon(Icons.location_off_outlined, size: 14, color: AppColors.warning),
        const SizedBox(width: 8),
        Text(
          _kLocationBanner,
          style: AppTypography.helper.copyWith(color: AppColors.warning),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResultList
// ─────────────────────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  final AsyncValue<List<PlaceModel>> gymsAsync;
  final List<PlaceModel>             filtered;
  final DiscoverFilter               filter;
  final String?                      selectedId;
  final Map<String, GlobalKey>       itemKeys;
  final ValueChanged<PlaceModel>     onCardTap;

  const _ResultList({
    required this.gymsAsync,
    required this.filtered,
    required this.filter,
    required this.selectedId,
    required this.itemKeys,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (filter == DiscoverFilter.trainers) {
      return const _EmptyState(
        icon:    Icons.person_search_rounded,
        message: _kEmptyTrainers,
      );
    }

    if (gymsAsync.isLoading) return _ShimmerList();

    if (filtered.isEmpty) {
      return const _EmptyState(
        icon:    Icons.search_off_rounded,
        message: _kEmptyGyms,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              _kListPadH, _kListPadV, _kListPadH, 8),
          child: Text(
            '${filtered.length} gym${filtered.length == 1 ? "" : "s"} nearby',
            style: AppTypography.helper.copyWith(
                color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                _kListPadH, 0, _kListPadH, 96),
            itemCount:        filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
            itemBuilder: (ctx, i) {
              final place = filtered[i];
              itemKeys[place.placeId] ??= GlobalKey();
              return KeyedSubtree(
                key:   itemKeys[place.placeId],
                child: GymCard(
                  place:      place,
                  isSelected: place.placeId == selectedId,
                  onTap:      () => onCardTap(place),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShimmerList — skeleton loading state
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerList extends StatefulWidget {
  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:   (_, __) {
        final shimmer =
            Color.lerp(AppColors.surfaceMid, AppColors.border, _anim.value)!;
        return ListView.separated(
          padding:          const EdgeInsets.all(_kListPadH),
          itemCount:        5,
          separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
          itemBuilder:      (_, __) => _ShimmerCard(color: shimmer),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Color color;
  const _ShimmerCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:     86,
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color, borderRadius: AppRadius.inputBR)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:  MainAxisAlignment.center,
            children: [
              Container(
                  height: 14,
                  width:  double.infinity,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(
                  height: 10,
                  width:  140,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
        child: CircularProgressIndicator(color: AppColors.primary)),
  );
}