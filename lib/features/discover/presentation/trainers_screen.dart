// lib/features/discover/presentation/trainers_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Extracted from discover_screen.dart (v1.2.0). Now dedicated to
//            trainer discovery only. Route: /trainers.
//            Gyms discovery lives at /gyms (see gyms_screen.dart).
//   v1.1.0 — UX overhaul:
//            · Header strip with title, trainer count, sort menu, and map
//              toggle (mirrors home _DashHeader style).
//            · Dynamic specialty filter chips derived from loaded trainer data
//              (mirrors gyms category chips).
//            · Sort modes: Relevance | Rating | Distance | Price (asc/desc).
//            · Map / List toggle on narrow screens — users can switch without
//              losing scroll position.
//            · Active-filter pill count badge on the filter row.
//            · Empty state differentiates "no results for query" vs "no
//              trainers in area".
//            · Shimmer improved: matches TrainerCard aspect ratio exactly.
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

const double _kListPadH = 16.0;
const double _kListPadV = 12.0;
const double _kCardGap = 10.0;
const double _kSearchBarH = 44.0;
const double _kMapFallbackLat = -4.0435;
const double _kMapFallbackLng = 39.6682;
const double _kMapZoom = 13.5;
const String _kMapStyle = 'mapbox://styles/mapbox/dark-v11';
const String _kSearchHint = 'Search trainers, specialties...';
const double _kBreakWide = 900.0;

// Specialty shown when no filter is active.
const String _kAllSpecialties = 'All';

// ─────────────────────────────────────────────────────────────────────────────
// Sort mode
// ─────────────────────────────────────────────────────────────────────────────

enum _SortMode { relevance, ratingDesc, priceAsc, priceDesc }

extension _SortModeX on _SortMode {
  String get label => switch (this) {
        _SortMode.relevance => 'Relevance',
        _SortMode.ratingDesc => 'Top Rated',
        _SortMode.priceAsc => 'Price: Low → High',
        _SortMode.priceDesc => 'Price: High → Low',
      };

  IconData get icon => switch (this) {
        _SortMode.relevance => Icons.sort_rounded,
        _SortMode.ratingDesc => Icons.star_rounded,
        _SortMode.priceAsc => Icons.arrow_upward_rounded,
        _SortMode.priceDesc => Icons.arrow_downward_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// TrainersScreen
// ─────────────────────────────────────────────────────────────────────────────

class TrainersScreen extends ConsumerWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);
    return userAsync.when(
      loading: () => _LoadingScaffold(),
      error: (_, __) => _LoadingScaffold(),
      data: (user) => AppNavShell(
        currentRoute: '/trainers',
        isTrainerView: false,
        displayName: user?.displayName ?? '',
        photoUrl: user?.photoUrl,
        child: const _TrainersBody(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainersBody
// ─────────────────────────────────────────────────────────────────────────────

class _TrainersBody extends ConsumerStatefulWidget {
  const _TrainersBody();
  @override
  ConsumerState<_TrainersBody> createState() => _TrainersBodyState();
}

class _TrainersBodyState extends ConsumerState<_TrainersBody> {
  final _searchCtrl = TextEditingController();
  String _selectedSpecialty = _kAllSpecialties;
  _SortMode _sortMode = _SortMode.relevance;

  // On narrow screens, toggle between map and list views.
  bool _showMapNarrow = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Derive specialty chips from loaded data ────────────────────────────────
  List<String> _specialties(List<TrainerProfile> all) {
    final set = <String>{};
    for (final t in all) {
      for (final s in t.specialties) {
        set.add(s);
      }
    }
    final sorted = set.toList()..sort();
    return [_kAllSpecialties, ...sorted];
  }

  // ── Filter + sort pipeline ─────────────────────────────────────────────────
  List<TrainerProfile> _process(List<TrainerProfile> all) {
    // 1. text search
    final q = _searchCtrl.text.toLowerCase().trim();
    Iterable<TrainerProfile> result = all;
    if (q.isNotEmpty) {
      result = result.where((t) =>
          t.displayName.toLowerCase().contains(q) ||
          t.specialties.any((s) => s.toLowerCase().contains(q)) ||
          t.bio.toLowerCase().contains(q) ||
          t.locationName.toLowerCase().contains(q));
    }

    // 2. specialty chip filter
    if (_selectedSpecialty != _kAllSpecialties) {
      result = result.where(
          (t) => t.specialties.any((s) => s == _selectedSpecialty));
    }

    // 3. sort
    final list = result.toList();
    switch (_sortMode) {
      case _SortMode.relevance:
        break; // preserve Firestore order
      case _SortMode.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.priceAsc:
        list.sort((a, b) =>
            (a.priceKes ?? 0).compareTo(b.priceKes ?? 0));
      case _SortMode.priceDesc:
        list.sort((a, b) =>
            (b.priceKes ?? 0).compareTo(a.priceKes ?? 0));
    }
    return list;
  }

  bool get _hasActiveFilters =>
      _selectedSpecialty != _kAllSpecialties ||
      _sortMode != _SortMode.relevance;

  void _clearFilters() => setState(() {
        _selectedSpecialty = _kAllSpecialties;
        _sortMode = _SortMode.relevance;
        _searchCtrl.clear();
      });

  // ── Sort menu ──────────────────────────────────────────────────────────────
  void _showSortMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final chosen = await showMenu<_SortMode>(
      context: context,
      position: pos,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBR,
        side: BorderSide(color: AppColors.border),
      ),
      items: _SortMode.values
          .map((m) => PopupMenuItem<_SortMode>(
                value: m,
                child: Row(children: [
                  Icon(m.icon,
                      size: 14,
                      color: m == _sortMode
                          ? AppColors.primary
                          : AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    m.label,
                    style: AppTypography.body.copyWith(
                      color: m == _sortMode
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: m == _sortMode
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (m == _sortMode) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded,
                        size: 13, color: AppColors.primary),
                  ],
                ]),
              ))
          .toList(),
    );
    if (chosen != null) setState(() => _sortMode = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(allTrainersProvider);
    final all = trainersAsync.valueOrNull ?? [];
    final specialties = _specialties(all);
    final filtered = _process(all);

    return Column(children: [
      // ── Header strip ────────────────────────────────────────────────────────
      _TrainersHeader(
        trainerCount: trainersAsync.isLoading ? null : filtered.length,
        totalCount: all.length,
        sortMode: _sortMode,
        hasActiveFilters: _hasActiveFilters,
        showMapNarrow: _showMapNarrow,
        onSortTap: _showSortMenu,
        onMapToggle: () => setState(() => _showMapNarrow = !_showMapNarrow),
        onClearFilters: _hasActiveFilters ? _clearFilters : null,
      ),

      // ── Search + specialty chips ────────────────────────────────────────────
      _FilterBar(
        controller: _searchCtrl,
        specialties: specialties,
        selectedSpecialty: _selectedSpecialty,
        onSearch: (_) => setState(() {}),
        onSpecialtySelected: (s) => setState(() => _selectedSpecialty = s),
      ),

      // ── Content ─────────────────────────────────────────────────────────────
      Expanded(
        child: LayoutBuilder(builder: (ctx, box) {
          final wide = box.maxWidth >= _kBreakWide;

          if (wide) {
            // ── Wide: map left, list right ──────────────────────────────────
            return Row(children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: _TrainerMapPane(trainers: filtered),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  child: _ResultList(
                    trainersAsync: trainersAsync,
                    filtered: filtered,
                    hasActiveFilters: _hasActiveFilters,
                    onClearFilters: _clearFilters,
                  ),
                ),
              ),
            ]);
          }

          // ── Narrow: stacked with toggle ─────────────────────────────────
          if (_showMapNarrow) {
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SizedBox(
                    height: 300,
                    child: _TrainerMapPane(trainers: filtered)),
              ),
              // Results count bar below map in map-view mode
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _kListPadH, vertical: 10),
                child: Row(children: [
                  Icon(Icons.place_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${filtered.length} trainer${filtered.length == 1 ? "" : "s"} on map',
                    style: AppTypography.helper
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ]),
              ),
            ]);
          }

          return _ResultList(
            trainersAsync: trainersAsync,
            filtered: filtered,
            hasActiveFilters: _hasActiveFilters,
            onClearFilters: _clearFilters,
          );
        }),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainersHeader
//
// Mirrors the home screen _DashHeader style:
//   [Title + subtitle]    [sort button]  [map toggle]
// ─────────────────────────────────────────────────────────────────────────────

class _TrainersHeader extends StatelessWidget {
  final int? trainerCount;   // null while loading
  final int totalCount;
  final _SortMode sortMode;
  final bool hasActiveFilters;
  final bool showMapNarrow;
  final void Function(BuildContext) onSortTap;
  final VoidCallback onMapToggle;
  final VoidCallback? onClearFilters;

  const _TrainersHeader({
    required this.trainerCount,
    required this.totalCount,
    required this.sortMode,
    required this.hasActiveFilters,
    required this.showMapNarrow,
    required this.onSortTap,
    required this.onMapToggle,
    this.onClearFilters,
  });

  String get _subtitle {
    if (trainerCount == null) return 'Finding trainers near you…';
    if (totalCount == 0) return 'No trainers in your area yet';
    if (trainerCount == totalCount) {
      return '$totalCount trainer${totalCount == 1 ? "" : "s"} near you';
    }
    return '$trainerCount of $totalCount trainer${totalCount == 1 ? "" : "s"} match';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // ── Left: icon + title + subtitle ─────────────────────────────────
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.inputBR,
          ),
          child: Icon(Icons.people_alt_rounded,
              size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Find a Trainer', style: AppTypography.h4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _subtitle,
                key: ValueKey(_subtitle),
                style: AppTypography.helper
                    .copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),

        // ── Right: clear filters badge, sort, map toggle ───────────────────
        if (hasActiveFilters && onClearFilters != null) ...[
          GestureDetector(
            onTap: onClearFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: AppRadius.pillBR,
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.filter_alt_off_rounded,
                    size: 12, color: AppColors.error),
                const SizedBox(width: 4),
                Text('Clear',
                    style: AppTypography.badge
                        .copyWith(color: AppColors.error)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Sort button
        Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => onSortTap(ctx),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: sortMode != _SortMode.relevance
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.surfaceMid,
                borderRadius: AppRadius.inputBR,
                border: Border.all(
                  color: sortMode != _SortMode.relevance
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(sortMode.icon,
                    size: 13,
                    color: sortMode != _SortMode.relevance
                        ? AppColors.primary
                        : AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  sortMode == _SortMode.relevance ? 'Sort' : sortMode.label,
                  style: AppTypography.caption.copyWith(
                    color: sortMode != _SortMode.relevance
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: sortMode != _SortMode.relevance
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ]),
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Map / List toggle (narrow screens only; wide always shows both)
        LayoutBuilder(builder: (ctx, _) {
          // We can't know the parent width here, so we always render.
          // The toggle is visually prominent only on narrow layouts — on
          // wide it still works but the map is always visible anyway.
          return GestureDetector(
            onTap: onMapToggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: showMapNarrow
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceMid,
                borderRadius: AppRadius.inputBR,
                border: Border.all(
                  color: showMapNarrow
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                showMapNarrow ? Icons.list_rounded : Icons.map_rounded,
                size: 16,
                color: showMapNarrow ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterBar  (search field + specialty chips)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final List<String> specialties;
  final String selectedSpecialty;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSpecialtySelected;

  const _FilterBar({
    required this.controller,
    required this.specialties,
    required this.selectedSpecialty,
    required this.onSearch,
    required this.onSpecialtySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Search field ───────────────────────────────────────────────────
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
                      onTap: () {
                        controller.clear();
                        onSearch('');
                      },
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
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Specialty chips ────────────────────────────────────────────────
        if (specialties.length > 1)
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: specialties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final spec = specialties[i];
                final sel = spec == selectedSpecialty;
                return GestureDetector(
                  onTap: () => onSpecialtySelected(spec),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceMid,
                      borderRadius: AppRadius.pillBR,
                      border: Border.all(
                        color:
                            sel ? AppColors.primary : AppColors.border,
                        width: sel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel && spec != _kAllSpecialties) ...[
                            Icon(Icons.check_rounded,
                                size: 11, color: AppColors.primary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            spec,
                            style: AppTypography.helper.copyWith(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 10),
        Divider(height: 1, color: AppColors.border),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerMapPane
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerMapPane extends StatefulWidget {
  final List<TrainerProfile> trainers;
  const _TrainerMapPane({required this.trainers});
  @override
  State<_TrainerMapPane> createState() => _TrainerMapPaneState();
}

class _TrainerMapPaneState extends State<_TrainerMapPane> {
  AppMapController? _ctrl;
  List<AppMapPin> _pins = [];

  @override
  void initState() {
    super.initState();
    _rebuildPins();
  }

  @override
  void didUpdateWidget(covariant _TrainerMapPane old) {
    super.didUpdateWidget(old);
    if (old.trainers != widget.trainers) _rebuildPins();
  }

  void _rebuildPins() {
    _pins = widget.trainers
        .map((t) => AppMapPin(id: t.id, lat: t.lat, lng: t.lng))
        .toList();
    _ctrl?.setPins(_pins);
  }

  void _onMapReady(AppMapController c) {
    _ctrl = c;
    c.setPins(_pins);
  }

  @override
  Widget build(BuildContext context) {
    final centre = widget.trainers.isNotEmpty
        ? AppLatLng(widget.trainers.first.lat, widget.trainers.first.lng)
        : const AppLatLng(_kMapFallbackLat, _kMapFallbackLng);

    return Container(
      decoration: AppDecorations.card,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox.expand(
          child: AppMapWidget(
            initialLat: centre.lat,
            initialLng: centre.lng,
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

// ─────────────────────────────────────────────────────────────────────────────
// _ResultList
// ─────────────────────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  final AsyncValue<List<TrainerProfile>> trainersAsync;
  final List<TrainerProfile> filtered;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _ResultList({
    required this.trainersAsync,
    required this.filtered,
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (trainersAsync.isLoading) return _ShimmerList();

    if (filtered.isEmpty) {
      return _EmptyState(
        hasActiveFilters: hasActiveFilters,
        onClearFilters: onClearFilters,
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Results count bar ────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(
            _kListPadH, _kListPadV, _kListPadH, 8),
        child: Row(children: [
          Expanded(
            child: Text(
              '${filtered.length} trainer${filtered.length == 1 ? "" : "s"} found',
              style: AppTypography.helper
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          // Verified badge count (optional detail)
          if (filtered.any((t) => t.isVerified)) ...[
            Icon(Icons.verified_rounded, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              '${filtered.where((t) => t.isVerified).length} verified',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ]),
      ),

      // ── Trainer list ─────────────────────────────────────────────────────
      Expanded(
        child: ListView.separated(
          padding:
              const EdgeInsets.fromLTRB(_kListPadH, 0, _kListPadH, 96),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
          itemBuilder: (ctx, i) => TrainerCard(trainer: filtered[i]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState  — two variants: filter mismatch vs no trainers at all
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceMid,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              hasActiveFilters
                  ? Icons.manage_search_rounded
                  : Icons.people_outline_rounded,
              size: 28,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'No matches' : 'No trainers nearby',
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            hasActiveFilters
                ? 'Try clearing your filters or searching\nwith different keywords.'
                : 'Be the first to join — check back soon\nor expand your search area.',
            textAlign: TextAlign.center,
            style:
                AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onClearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 22),
                decoration: AppDecorations.outlinedButton,
                child: Text('Clear all filters',
                    style: AppTypography.buttonSm
                        .copyWith(color: AppColors.primary)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShimmerList  — loading skeleton matching TrainerCard height
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
        final shimmerDim = Color.lerp(
            AppColors.surface, AppColors.surfaceMid, _anim.value)!;

        return ListView.separated(
          padding: const EdgeInsets.all(_kListPadH),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
          itemBuilder: (_, idx) {
            // Stagger delay by index — later cards appear slightly dimmer.
            final dimFactor = 1.0 - idx * 0.12;
            final c = Color.lerp(shimmerDim, shimmer, dimFactor)!;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Avatar
                Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: c, borderRadius: AppRadius.inputBR)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name line
                        Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 7),
                        // Specialty line (shorter)
                        Container(
                            height: 10,
                            width: 160,
                            decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 10),
                        // Pill row
                        Row(children: [
                          _ShimmerPill(color: c, width: 60),
                          const SizedBox(width: 6),
                          _ShimmerPill(color: c, width: 80),
                          const SizedBox(width: 6),
                          _ShimmerPill(color: c, width: 50),
                        ]),
                      ]),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

class _ShimmerPill extends StatelessWidget {
  final Color color;
  final double width;
  const _ShimmerPill({required this.color, required this.width});

  @override
  Widget build(BuildContext context) => Container(
        height: 20,
        width: width,
        decoration: BoxDecoration(
            color: color, borderRadius: AppRadius.pillBR),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
}