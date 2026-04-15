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
import '../../../core/models/trainer_profile.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/navigation/app_nav.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/discover_providers.dart';
import 'widgets/trainer_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kListPadH = 16.0;
const double _kListPadV = 16.0;
const double _kCardGap = 10.0;
const double _kSearchBarH = 44.0;

const double _kMapFallbackLat = -4.0435;
const double _kMapFallbackLng = 39.6682;
const double _kMapZoom = 13.5;
const String _kMapStyle = 'mapbox://styles/mapbox/dark-v11';

// ── Copy ──
const String _kSearchHint = 'Search trainers...';
const String _kEmptyTrainers = 'No trainers found.\nTry adjusting your search.';

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
      error: (_, __) => _LoadingScaffold(),
      data: (user) => AppNavShell(
        currentRoute: '/discover',
        isTrainerView: false,
        displayName: user?.displayName ?? '',
        photoUrl: user?.photoUrl,
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
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<TrainerProfile> _filtered(List<TrainerProfile> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((t) =>
            t.displayName.toLowerCase().contains(q) ||
            t.specialties.any((s) => s.toLowerCase().contains(q)) ||
            t.bio.toLowerCase().contains(q) ||
            t.locationName.toLowerCase().contains(q))
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(allTrainersProvider);

    final trainers = trainersAsync.valueOrNull ?? [];
    final filtered = _filtered(trainers, _searchCtrl.text);

    return Column(children: [
      // ── Search bar ─────────────────────────────────────────────────────
      _SearchFilterBar(
        controller: _searchCtrl,
        onSearch: (q) => setState(() {}),
      ),

      // ── Map + list split ───────────────────────────────────────────────
      Expanded(
        child: LayoutBuilder(builder: (ctx, box) {
          final wide = box.maxWidth >= 900;
          if (wide) {
            return Row(children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: _DiscoverMapPane(trainers: filtered),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  child: _ResultList(
                    trainersAsync: trainersAsync,
                    filtered: filtered,
                  ),
                ),
              ),
            ]);
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 280,
                child: _DiscoverMapPane(trainers: filtered),
              ),
            ),
            Expanded(
              child: _ResultList(
                trainersAsync: trainersAsync,
                filtered: filtered,
              ),
            ),
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
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  const _SearchFilterBar({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Search field ────────────────────────────────────────────────
          SizedBox(
            height: _kSearchBarH,
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: _kSearchHint,
                hintStyle:
                    AppTypography.body.copyWith(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => onSearch(''),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceMid,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _DiscoverMapPane extends StatefulWidget {
  final List<TrainerProfile> trainers;
  const _DiscoverMapPane({required this.trainers});

  @override
  State<_DiscoverMapPane> createState() => _DiscoverMapPaneState();
}

class _DiscoverMapPaneState extends State<_DiscoverMapPane> {
  AppMapController? _mapController;
  late AppLatLng _centre;
  List<AppMapPin> _pins = [];

  @override
  void initState() {
    super.initState();
    _updateMapState();
  }

  @override
  void didUpdateWidget(covariant _DiscoverMapPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trainers != widget.trainers) {
      _updateMapState();
    }
  }

  void _updateMapState() {
    final trainers = widget.trainers;
    if (trainers.isNotEmpty) {
      _centre = AppLatLng(trainers.first.lat, trainers.first.lng);
      _pins = trainers
          .map((t) => AppMapPin(id: t.id, lat: t.lat, lng: t.lng))
          .toList();
    } else {
      _centre = const AppLatLng(_kMapFallbackLat, _kMapFallbackLng);
      _pins = const [];
    }

    if (_mapController != null) {
      _mapController!.setPins(_pins);
    }
  }

  void _onMapReady(AppMapController controller) {
    _mapController = controller;
    controller.setPins(_pins);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox.expand(
          child: AppMapWidget(
            initialLat: _centre.lat,
            initialLng: _centre.lng,
            initialZoom: _kMapZoom,
            styleUri: _kMapStyle,
            initialPins: _pins,
            onMapReady: _onMapReady,
          ),
        ),
      ),
    );
  }
}

/*
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
        height:   34.0,
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
*/
// _ResultList
// ─────────────────────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  final AsyncValue<List<TrainerProfile>> trainersAsync;
  final List<TrainerProfile> filtered;

  const _ResultList({
    required this.trainersAsync,
    required this.filtered,
  });

  @override
  Widget build(BuildContext context) {
    if (trainersAsync.isLoading) return _ShimmerList();

    if (filtered.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        message: _kEmptyTrainers,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(_kListPadH, _kListPadV, _kListPadH, 8),
          child: Text(
            '${filtered.length} trainer${filtered.length == 1 ? "" : "s"} found',
            style:
                AppTypography.helper.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(_kListPadH, 0, _kListPadH, 96),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
            itemBuilder: (ctx, i) {
              final trainer = filtered[i];
              return TrainerCard(
                trainer: trainer,
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
  late Animation<double> _anim;

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
      builder: (_, __) {
        final shimmer =
            Color.lerp(AppColors.surfaceMid, AppColors.border, _anim.value)!;
        return ListView.separated(
          padding: const EdgeInsets.all(_kListPadH),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
          itemBuilder: (_, __) => _ShimmerCard(color: shimmer),
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
      height: 86,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(color: color, borderRadius: AppRadius.inputBR)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4))),
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
  final String message;
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
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
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
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}
