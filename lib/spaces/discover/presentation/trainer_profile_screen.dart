// lib/features/discover/presentation/trainer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/trainer_profile.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bookings/data/availability_model.dart';
import '../../bookings/providers/bookings_providers.dart';
import '../../../core/navigation/app_nav.dart';
import '../providers/discover_providers.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────

const double _kHorizPad = 20.0;
const double _kStickyBarH = 80.0;
const double _kAvatarRadius = 44.0;
const double _kHeroHeight = 260.0;
const double _kSectionGap = 24.0;

const _kDaysFull = [
  'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
];
const _kDaysShort = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
const _kMonths = [
  'Jan','Feb','Mar','Apr','May','Jun',
  'Jul','Aug','Sep','Oct','Nov','Dec'
];
const _kMonthsFull = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December'
];

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class TrainerProfileScreen extends ConsumerWidget {
  final String trainerId;
  const TrainerProfileScreen({super.key, required this.trainerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerAsync = ref.watch(trainerByIdProvider(trainerId));
    final currentUserAsync = ref.watch(firestoreUserProvider);

    return AppNavShell(
      currentRoute: '/trainers',
      isTrainerView: false,
      displayName: currentUserAsync.value?.displayName ?? '',
      photoUrl: currentUserAsync.value?.photoUrl,
      child: trainerAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('Trainer not found.')),
        data: (trainer) {
          if (trainer == null) {
            return const Center(child: Text('Trainer not found'));
          }
          return _ProfileBody(trainer: trainer);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROFILE BODY
// ─────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerStatefulWidget {
  final TrainerProfile trainer;
  const _ProfileBody({required this.trainer});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  AvailabilitySlot? _selectedSlot;

  void _selectSlot(AvailabilitySlot slot) {
    setState(() {
      _selectedSlot =
          _selectedSlot?.id == slot.id ? null : slot;
    });
  }

  void _onBookTap() {
    final user = ref.read(authStateProvider).value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book')),
      );
      return;
    }

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a slot first')),
      );
      return;
    }

    _showBookingSheet();
  }

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingConfirmSheet(
        trainer: widget.trainer,
        slot: _selectedSlot!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync =
        ref.watch(trainerSlotsProvider(widget.trainer.id));

    final slots = slotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const <AvailabilitySlot>[],
    );

    final availableSlots = slots
        .where((s) => s.status.isBookable)
        .toList()
      ..sort((a, b) =>
          a.startTime.compareTo(b.startTime));

    return AppCanvas(
      type: BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: _kStickyBarH +
                      MediaQuery.of(context).padding.bottom +
                      16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _HeroHeader(trainer: widget.trainer),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          _kHorizPad,
                          _kSectionGap,
                          _kHorizPad,
                          0),
                      child:
                          _StatsStrip(trainer: widget.trainer),
                    ),

                    if (widget.trainer.specialties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _kHorizPad,
                            _kSectionGap,
                            _kHorizPad,
                            0),
                        child: _SpecialtiesSection(
                          specialties:
                              widget.trainer.specialties,
                        ),
                      ),

                    if (widget.trainer.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _kHorizPad,
                            _kSectionGap,
                            _kHorizPad,
                            0),
                        child: _BioSection(
                          bio: widget.trainer.bio,
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          _kHorizPad,
                          _kSectionGap,
                          _kHorizPad,
                          0),
                      child: _SlotsSection(
                        slotsAsync: slotsAsync,
                        slots: availableSlots,
                        selectedSlot: _selectedSlot,
                        onSelect: _selectSlot,
                        trainerName:
                            widget.trainer.displayName,
                      ),
                    ),

                    const SizedBox(height: _kSectionGap),
                  ],
                ),
              ),
            ),

            _StickyBookBar(
              trainer: widget.trainer,
              selectedSlot: _selectedSlot,
              onBook: _onBookTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HERO HEADER
// ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final TrainerProfile trainer;
  const _HeroHeader({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Background gradient ──────────────────────────
        Container(
          height: _kHeroHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                AppColors.background,
              ],
            ),
          ),
        ),

        // ── Back button ──────────────────────────────────
        Positioned(
          top: 10,
          left: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/trainers');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background
                      .withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),

        // ── Profile card at bottom ───────────────────────
        Positioned(
          left: _kHorizPad,
          right: _kHorizPad,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar + name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: _kAvatarRadius * 2,
                    height: _kAvatarRadius * 2,
                    decoration: BoxDecoration(
                      gradient: AppGradients.avatar,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary
                            .withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: trainer.photoUrl != null &&
                            trainer.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(20),
                            child: Image.network(
                              trainer.photoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              trainer.initials,
                              style: AppTypography.h2
                                  .copyWith(
                                      color: AppColors
                                          .onPrimary),
                            ),
                          ),
                  ),

                  const SizedBox(width: 14),

                  // Name + title + verified badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                trainer.displayName,
                                style: AppTypography.h2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons
                                        .verified_rounded,
                                    size: 10,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: AppTypography
                                        .caption
                                        .copyWith(
                                      fontSize: 9,
                                      color:
                                          AppColors.primary,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Certified Personal Trainer',
                          style: AppTypography.helper
                              .copyWith(
                                  color: AppColors
                                      .textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location + rating row
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trainer.locationName,
                      style: AppTypography.caption
                          .copyWith(
                              color:
                                  AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: const Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    trainer.rating.toStringAsFixed(1),
                    style: AppTypography.helper
                        .copyWith(
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${trainer.reviewCount})',
                    style: AppTypography.caption
                        .copyWith(
                            color:
                                AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS STRIP
// ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final TrainerProfile trainer;
  const _StatsStrip({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
          child: _StatCell(
            value: trainer.yearsExperience != null
                ? '${trainer.yearsExperience}yr'
                : '—',
            label: 'Experience',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatCell(
            value: trainer.sessionRate != null
                ? 'KES ${trainer.sessionRate!.toInt()}'
                : 'Varies',
            label: 'Per Session',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatCell(
            value: '${trainer.reviewCount}',
            label: 'Reviews',
          ),
        ),
        _StatDivider(),
        Expanded(
          child: _StatCell(
            value: trainer.rating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
      ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.h4
                .copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPECIALTIES
// ─────────────────────────────────────────────────────────────

class _SpecialtiesSection extends StatelessWidget {
  final List<String> specialties;
  const _SpecialtiesSection({required this.specialties});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specialties
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Text(s,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BIO
// ─────────────────────────────────────────────────────────────

class _BioSection extends StatelessWidget {
  final String bio;
  const _BioSection({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Text(bio, style: AppTypography.body);
  }
}

// ─────────────────────────────────────────────────────────────
// SLOTS  (calendar / planner layout)
// ─────────────────────────────────────────────────────────────

class _SlotsSection extends StatefulWidget {
  final AsyncValue<List<AvailabilitySlot>> slotsAsync;
  final List<AvailabilitySlot> slots;
  final AvailabilitySlot? selectedSlot;
  final ValueChanged<AvailabilitySlot> onSelect;
  final String trainerName;

  const _SlotsSection({
    required this.slotsAsync,
    required this.slots,
    required this.selectedSlot,
    required this.onSelect,
    required this.trainerName,
  });

  @override
  State<_SlotsSection> createState() => _SlotsSectionState();
}

class _SlotsSectionState extends State<_SlotsSection> {
  DateTime? _focusedDay;

  // ── helpers ──────────────────────────────────────────────

  DateTime _dayOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  Map<DateTime, List<AvailabilitySlot>> _groupByDay(
      List<AvailabilitySlot> slots) {
    final map = <DateTime, List<AvailabilitySlot>>{};
    for (final s in slots) {
      final key = _dayOnly(s.startTime);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $amPm';
  }

  String _periodLabel(int hour) {
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  IconData _periodIcon(int hour) {
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_cloudy_outlined;
    return Icons.nights_stay_outlined;
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (widget.slotsAsync is AsyncLoading) {
      return _buildLoadingShimmer();
    }

    if (widget.slots.isEmpty) {
      return _buildEmptyState();
    }

    final grouped = _groupByDay(widget.slots);
    final days = grouped.keys.toList()..sort();

    // Default to first day if nothing focused yet
    _focusedDay ??= days.first;
    // Guard: if focused day no longer has slots, reset
    if (!grouped.containsKey(_focusedDay)) {
      _focusedDay = days.first;
    }

    final daySlots = grouped[_focusedDay]!
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Group time-slots by period (Morning / Afternoon / Evening)
    final Map<String, List<AvailabilitySlot>> byPeriod = {};
    for (final s in daySlots) {
      final label = _periodLabel(s.startTime.hour);
      byPeriod.putIfAbsent(label, () => []).add(s);
    }
    const periodOrder = ['Morning', 'Afternoon', 'Evening'];

    // Max slots in any day — used to scale the pip bar
    final maxSlots = grouped.values
        .map((l) => l.length)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section heading ──────────────────────────────
        Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Availability', style: AppTypography.h4),
          ],
        ),
        const SizedBox(height: 14),

        // ── Day-selector strip ───────────────────────────
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = days[i];
              final isFocused = _focusedDay == day;
              final slotCount = grouped[day]!.length;

              return GestureDetector(
                onTap: () =>
                    setState(() => _focusedDay = day),
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 58,
                  decoration: BoxDecoration(
                    color: isFocused
                        ? AppColors.primary
                        : AppColors.primary
                            .withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: isFocused
                          ? AppColors.primary
                          : AppColors.primary
                              .withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _kDaysShort[day.weekday - 1],
                          style:
                              AppTypography.caption.copyWith(
                            color: isFocused
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${day.day}',
                          style: AppTypography.h4.copyWith(
                            color: isFocused
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _kMonths[day.month - 1],
                          style:
                              AppTypography.caption.copyWith(
                            fontSize: 9,
                            color: isFocused
                                ? AppColors.onPrimary
                                    .withValues(alpha: 0.75)
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Availability fill bar
                        SizedBox(
                          width: 28,
                          height: 4,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(
                                  color: isFocused
                                      ? AppColors.onPrimary
                                          .withValues(
                                              alpha: 0.25)
                                      : AppColors.primary
                                          .withValues(
                                              alpha: 0.15),
                                ),
                                FractionallySizedBox(
                                  widthFactor: (slotCount /
                                          maxSlots)
                                      .clamp(0.1, 1.0),
                                  child: Container(
                                    color: isFocused
                                        ? AppColors.onPrimary
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
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

        const SizedBox(height: 20),

        // ── Selected day label ───────────────────────────
        Row(
          children: [
            Text(
              '${_kDaysFull[_focusedDay!.weekday - 1]}, '
              '${_focusedDay!.day} '
              '${_kMonthsFull[_focusedDay!.month - 1]}',
              style: AppTypography.helper.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${daySlots.length} slot${daySlots.length == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Time slots grouped by period ─────────────────
        for (final period in periodOrder)
          if (byPeriod.containsKey(period)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _periodIcon(byPeriod[period]!
                        .first.startTime.hour),
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    period.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  byPeriod[period]!.map((slot) {
                final selected =
                    widget.selectedSlot?.id == slot.id;
                return GestureDetector(
                  onTap: () => widget.onSelect(slot),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 180),
                    curve: Curves.easeOut,
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary
                              .withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary
                                .withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors
                                    .primary
                                    .withValues(
                                        alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(
                                    0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected
                              ? Icons
                                  .check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 13,
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors
                                  .textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(
                              slot.startTime),
                          style: AppTypography.helper
                              .copyWith(
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors
                                    .textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 58,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color:
                AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No availability right now',
            style: AppTypography.body
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text('Check back soon',
              style: AppTypography.caption),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STICKY BAR
// ─────────────────────────────────────────────────────────────

class _StickyBookBar extends StatelessWidget {
  final TrainerProfile trainer;
  final AvailabilitySlot? selectedSlot;
  final VoidCallback onBook;

  const _StickyBookBar({
    required this.trainer,
    required this.selectedSlot,
    required this.onBook,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final hasSlot = selectedSlot != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: hasSlot
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Slot summary pill (only when a slot is picked)
          if (hasSlot) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_kDaysFull[selectedSlot!.startTime.weekday - 1]}, '
                    '${selectedSlot!.startTime.day} '
                    '${_kMonths[selectedSlot!.startTime.month - 1]}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(selectedSlot!.startTime),
                        style: AppTypography.helper.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Book button
          Expanded(
            flex: hasSlot ? 1 : 2,
            child: ElevatedButton(
              onPressed: hasSlot ? onBook : null,
              child: Text(
                  hasSlot ? 'Book Session' : 'Select a Time'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOOKING SHEET
// ─────────────────────────────────────────────────────────────

class _BookingConfirmSheet extends ConsumerStatefulWidget {
  final TrainerProfile trainer;
  final AvailabilitySlot slot;

  const _BookingConfirmSheet({
    required this.trainer,
    required this.slot,
  });

  @override
  ConsumerState<_BookingConfirmSheet> createState() =>
      _BookingConfirmSheetState();
}

class _BookingConfirmSheetState
    extends ConsumerState<_BookingConfirmSheet> {
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    await ref.read(bookingRepositoryProvider).createBooking(
          uid: user.uid,
          displayName: user.displayName ?? 'Guest',
          slot: widget.slot,
        );

    ref.invalidate(
        trainerSlotsProvider(widget.trainer.id));

    if (mounted) {
      Navigator.pop(context);
      context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Confirm Booking',
              style: AppTypography.h3),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}