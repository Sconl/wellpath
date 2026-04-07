// lib/features/discover/presentation/trainers_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Extracted from discover_screen.dart (v1.2.0). Now dedicated to
//            trainer discovery only. Route: /trainers.
//            Gyms discovery lives at /gyms (see gyms_screen.dart).
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
const double _kListPadV = 16.0;
const double _kCardGap = 10.0;
const double _kSearchBarH = 44.0;
const double _kMapFallbackLat = -4.0435;
const double _kMapFallbackLng = 39.6682;
const double _kMapZoom = 13.5;
const String _kMapStyle = 'mapbox://styles/mapbox/dark-v11';
const String _kSearchHint = 'Search trainers, specialties...';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TrainerProfile> _filtered(List<TrainerProfile> all, String q) {
    if (q.trim().isEmpty) return all;
    final lower = q.toLowerCase();
    return all
        .where((t) =>
            t.displayName.toLowerCase().contains(lower) ||
            t.specialties.any((s) => s.toLowerCase().contains(lower)) ||
            t.bio.toLowerCase().contains(lower) ||
            t.locationName.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(allTrainersProvider);
    final trainers = trainersAsync.valueOrNull ?? [];
    final filtered = _filtered(trainers, _searchCtrl.text);

    return Column(children: [
      _SearchBar(
        controller: _searchCtrl,
        onSearch: (_) => setState(() {}),
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
                  child: _TrainerMapPane(trainers: filtered),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  child: _ResultList(
                      trainersAsync: trainersAsync, filtered: filtered),
                ),
              ),
            ]);
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                  height: 280, child: _TrainerMapPane(trainers: filtered)),
            ),
            Expanded(
              child:
                  _ResultList(trainersAsync: trainersAsync, filtered: filtered),
            ),
          ]);
        }),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchBar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  const _SearchBar({required this.controller, required this.onSearch});

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
  const _ResultList({required this.trainersAsync, required this.filtered});

  @override
  Widget build(BuildContext context) {
    if (trainersAsync.isLoading) return _ShimmerList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              'No trainers found.\nTry adjusting your search.',
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
          '${filtered.length} trainer${filtered.length == 1 ? "" : "s"} found',
          style: AppTypography.helper.copyWith(color: AppColors.textSecondary),
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(_kListPadH, 0, _kListPadH, 96),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
          itemBuilder: (ctx, i) => TrainerCard(trainer: filtered[i]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShimmerList
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
          itemBuilder: (_, __) => Container(
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
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: AppRadius.inputBR)),
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
                              color: shimmer,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          height: 10,
                          width: 140,
                          decoration: BoxDecoration(
                              color: shimmer,
                              borderRadius: BorderRadius.circular(4))),
                    ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}
