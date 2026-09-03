// lib/features/gyms/presentation/gyms_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Gym discovery screen mirroring DiscoverScreen layout:
//            - AppMapWidget with gym pins.
//            - Search + category filter chips.
//            - Gym list with GymListCard (rating, open/closed, amenity pills).
//            - Responsive: wide = side-by-side map+list, narrow = stacked.
//            - Tap card → GymDetailSheet bottom sheet.
//            - Sample data from kSampleGyms (swap for Firestore later).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/maps/app_map_widget.dart';
import '../../../core/models/app_lat_lng.dart';
import '../../../core/navigation/app_nav.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/gym_model.dart';
import '../providers/gym_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kListPadH = 16.0;
const double _kListPadV = 16.0;
const double _kCardGap = 10.0;
const double _kSearchBarH = 44.0;
const double _kMapFallbackLat = -4.0435;
const double _kMapFallbackLng = 39.6682;
const double _kMapZoom = 13.0;
const String _kMapStyle = 'mapbox://styles/mapbox/dark-v11';

// Category filter chips
const _kCategories = [
  'All',
  'Weights & Cardio',
  'CrossFit',
  'Yoga & Wellness',
  'Combat Sports',
  'Boutique Studio',
  'Hotel Gym & Spa',
];

// ─────────────────────────────────────────────────────────────────────────────
// GymsScreen
// ─────────────────────────────────────────────────────────────────────────────

class GymsScreen extends ConsumerWidget {
  const GymsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);
    return userAsync.when(
      loading: () => _LoadingScaffold(),
      error: (_, __) => _LoadingScaffold(),
      data: (user) => AppNavShell(
        currentRoute: '/gyms',
        isTrainerView: false,
        displayName: user?.displayName ?? '',
        photoUrl: user?.photoUrl,
        child: const _GymsBody(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GymsBody
// ─────────────────────────────────────────────────────────────────────────────

class _GymsBody extends ConsumerStatefulWidget {
  const _GymsBody();
  @override
  ConsumerState<_GymsBody> createState() => _GymsBodyState();
}

class _GymsBodyState extends ConsumerState<_GymsBody> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GymModel> _applyFilter(List<GymModel> gyms) {
    if (_selectedCategory == 'All') return gyms;
    return gyms.where((g) => g.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(ref.watch(filteredGymsProvider));

    return Column(children: [
      _GymSearchBar(
        controller: _searchCtrl,
        selectedCategory: _selectedCategory,
        onSearch: (q) {
          ref.read(gymSearchQueryProvider.notifier).state = q;
          setState(() {});
        },
        onCategorySelected: (c) => setState(() => _selectedCategory = c),
      ),
      Expanded(
        child: LayoutBuilder(builder: (ctx, box) {
          final wide = box.maxWidth >= 900;
          if (wide) {
            return Row(children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: _GymMapPane(gyms: filtered),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  child: _GymResultList(gyms: filtered),
                ),
              ),
            ]);
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(height: 260, child: _GymMapPane(gyms: filtered)),
            ),
            Expanded(child: _GymResultList(gyms: filtered)),
          ]);
        }),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GymSearchBar
// ─────────────────────────────────────────────────────────────────────────────

class _GymSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String selectedCategory;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onCategorySelected;

  const _GymSearchBar({
    required this.controller,
    required this.selectedCategory,
    required this.onSearch,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: _kSearchBarH,
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search gyms, amenities...',
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
                  borderRadius: AppRadius.pillBR, borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBR,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _kCategories[i];
              final sel = cat == selectedCategory;
              return GestureDetector(
                onTap: () => onCategorySelected(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceMid,
                    borderRadius: AppRadius.pillBR,
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: sel ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: AppTypography.helper.copyWith(
                        color:
                            sel ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
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
// _GymMapPane
// ─────────────────────────────────────────────────────────────────────────────

class _GymMapPane extends StatefulWidget {
  final List<GymModel> gyms;
  const _GymMapPane({required this.gyms});
  @override
  State<_GymMapPane> createState() => _GymMapPaneState();
}

class _GymMapPaneState extends State<_GymMapPane> {
  AppMapController? _ctrl;
  List<AppMapPin> _pins = [];

  @override
  void initState() {
    super.initState();
    _rebuildPins();
  }

  @override
  void didUpdateWidget(covariant _GymMapPane old) {
    super.didUpdateWidget(old);
    if (old.gyms != widget.gyms) _rebuildPins();
  }

  void _rebuildPins() {
    _pins = widget.gyms
        .map((g) => AppMapPin(id: g.id, lat: g.lat, lng: g.lng))
        .toList();
    _ctrl?.setPins(_pins);
  }

  void _onMapReady(AppMapController c) {
    _ctrl = c;
    c.setPins(_pins);
  }

  @override
  Widget build(BuildContext context) {
    final centre = widget.gyms.isNotEmpty
        ? AppLatLng(widget.gyms.first.lat, widget.gyms.first.lng)
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
// _GymResultList
// ─────────────────────────────────────────────────────────────────────────────

class _GymResultList extends StatelessWidget {
  final List<GymModel> gyms;
  const _GymResultList({required this.gyms});

  @override
  Widget build(BuildContext context) {
    if (gyms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.fitness_center_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              'No gyms found.\nTry adjusting your search.',
              textAlign: TextAlign.center,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding:
            const EdgeInsets.fromLTRB(_kListPadH, _kListPadV, _kListPadH, 8),
        child: Text(
          '${gyms.length} gym${gyms.length == 1 ? "" : "s"} found',
          style: AppTypography.helper.copyWith(color: AppColors.textSecondary),
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(_kListPadH, 0, _kListPadH, 96),
          itemCount: gyms.length,
          separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
          itemBuilder: (ctx, i) => GymListCard(
            gym: gyms[i],
            onTap: () => _showDetail(ctx, gyms[i]),
          ),
        ),
      ),
    ]);
  }

  void _showDetail(BuildContext ctx, GymModel gym) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GymDetailSheet(gym: gym),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GymListCard
// ─────────────────────────────────────────────────────────────────────────────

class GymListCard extends StatelessWidget {
  final GymModel gym;
  final VoidCallback? onTap;
  const GymListCard({super.key, required this.gym, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: AppRadius.inputBR,
            ),
            child: Icon(Icons.fitness_center_rounded,
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),

          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(gym.name,
                      style: AppTypography.h5
                          .copyWith(color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _OpenBadge(isOpen: gym.isOpen),
              ]),
              const SizedBox(height: 3),
              Text(gym.shortAddress,
                  style: AppTypography.helper
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.pillBR,
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.20)),
                ),
                child: Text(gym.category,
                    style: AppTypography.badge
                        .copyWith(color: AppColors.secondary)),
              ),
              const SizedBox(height: 6),
              if (gym.rating != null)
                _RatingRow(rating: gym.rating!, count: gym.userRatingsTotal),
              const SizedBox(height: 8),
              // Amenity pills (first 3)
              Wrap(spacing: 5, runSpacing: 4, children: [
                ...gym.amenities.take(3).map((a) => _AmenityPill(label: a)),
                if (gym.amenities.length > 3)
                  _AmenityPill(
                      label: '+${gym.amenities.length - 3} more', muted: true),
              ]),
            ]),
          ),

          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded,
              size: 14, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBR,
      ),
      child: Text(isOpen ? 'Open' : 'Closed',
          style: AppTypography.badge
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? count;
  const _RatingRow({required this.rating, this.count});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(children: [
      ...List.generate(5, (i) {
        final icon = i < full
            ? Icons.star_rounded
            : (i == full && half)
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, size: 12, color: AppColors.warning);
      }),
      const SizedBox(width: 5),
      Text(rating.toStringAsFixed(1),
          style: AppTypography.helper.copyWith(
              color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      if (count != null) ...[
        const SizedBox(width: 3),
        Text('($count)',
            style: AppTypography.helper.copyWith(color: AppColors.textMuted)),
      ],
    ]);
  }
}

class _AmenityPill extends StatelessWidget {
  final String label;
  final bool muted;
  const _AmenityPill({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: AppRadius.pillBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style: AppTypography.caption.copyWith(
                color: muted ? AppColors.textMuted : AppColors.textSecondary)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _GymDetailSheet
// ─────────────────────────────────────────────────────────────────────────────

class _GymDetailSheet extends StatelessWidget {
  final GymModel gym;
  const _GymDetailSheet({required this.gym});

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${gym.name}, ${gym.shortAddress}')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callGym() async {
    if (gym.phone == null) return;
    final uri = Uri.parse('tel:${gym.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

            // Header
            Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.fitness_center_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gym.name, style: AppTypography.h3),
                      const SizedBox(height: 2),
                      Row(children: [
                        _OpenBadge(isOpen: gym.isOpen),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.10),
                            borderRadius: AppRadius.pillBR,
                          ),
                          child: Text(gym.category,
                              style: AppTypography.badge
                                  .copyWith(color: AppColors.secondary)),
                        ),
                      ]),
                    ]),
              ),
            ]),

            const SizedBox(height: 18),

            // Info rows
            _SheetRow(icon: Icons.place_outlined, label: gym.fullAddress),
            if (gym.openHours != null) ...[
              const SizedBox(height: 10),
              _SheetRow(icon: Icons.access_time_rounded, label: gym.openHours!),
            ],
            if (gym.phone != null) ...[
              const SizedBox(height: 10),
              _SheetRow(icon: Icons.phone_outlined, label: gym.phone!),
            ],
            if (gym.rating != null) ...[
              const SizedBox(height: 10),
              _SheetRow(
                icon: Icons.star_rounded,
                label: '${gym.rating!.toStringAsFixed(1)} / 5.0'
                    '${gym.userRatingsTotal != null ? " · ${gym.userRatingsTotal} reviews" : ""}',
              ),
            ],

            const SizedBox(height: 16),

            // Amenities
            Text('Amenities', style: AppTypography.h5),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ...gym.amenities.map((a) => _AmenityPill(label: a)),
            ]),

            const SizedBox(height: 24),

            // Action buttons
            Row(children: [
              if (gym.phone != null)
                Expanded(
                  child: GestureDetector(
                    onTap: _callGym,
                    child: Container(
                      height: 46,
                      decoration: AppDecorations.outlinedButton,
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.phone_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Call',
                              style: AppTypography.button
                                  .copyWith(color: AppColors.primary)),
                        ]),
                      ),
                    ),
                  ),
                ),
              if (gym.phone != null) const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openInMaps,
                  child: Container(
                    height: 46,
                    decoration: AppDecorations.primaryButton,
                    child: Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.directions_rounded,
                            size: 15, color: AppColors.onPrimary),
                        const SizedBox(width: 6),
                        Text('Directions',
                            style: AppTypography.button
                                .copyWith(color: AppColors.onPrimary)),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SheetRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary)),
        ),
      ]);
}

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}
