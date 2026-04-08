// lib/features/discover/presentation/trainer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/trainer_profile.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
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
    return SizedBox(
      height: _kHeroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary
                        .withValues(alpha: 0.25),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: _kHorizPad,
            bottom: 0,
            right: _kHorizPad,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Container(
                  width: _kAvatarRadius * 2,
                  height: _kAvatarRadius * 2,
                  decoration: BoxDecoration(
                    gradient: AppGradients.avatar,
                    borderRadius:
                        BorderRadius.circular(22),
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
                                    color:
                                        AppColors.onPrimary),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(trainer.displayName,
                          style: AppTypography.h2),
                      Text(
                        'Certified Personal Trainer',
                        style: AppTypography.helper
                            .copyWith(
                                color: AppColors
                                    .textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(trainer.locationName,
                          style: AppTypography.caption),
                      const SizedBox(height: 6),
                      Text(
                        '${trainer.rating.toStringAsFixed(1)} ★',
                        style: AppTypography.helper,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: trainer.yearsExperience != null
                ? '${trainer.yearsExperience}yr'
                : '—',
            label: 'Experience',
          ),
        ),
        Expanded(
          child: _StatCell(
            value: trainer.sessionRate != null
                ? 'KES ${trainer.sessionRate!.toInt()}'
                : 'Varies',
            label: 'Rate',
          ),
        ),
        Expanded(
          child: _StatCell(
            value: '${trainer.reviewCount}',
            label: 'Reviews',
          ),
        ),
        Expanded(
          child: _StatCell(
            value: trainer.rating
                .toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
      ],
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
        Text(value, style: AppTypography.h4),
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
      children:
          specialties.map((s) => Chip(label: Text(s))).toList(),
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
// SLOTS
// ─────────────────────────────────────────────────────────────

class _SlotsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Text('No slots available');
    }

    return Wrap(
      spacing: 8,
      children: slots.map((slot) {
        final selected =
            selectedSlot?.id == slot.id;

        return ChoiceChip(
          label: Text(
              '${slot.startTime.hour}:${slot.startTime.minute.toString().padLeft(2, '0')}'),
          selected: selected,
          onSelected: (_) => onSelect(slot),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final hasSlot = selectedSlot != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: hasSlot ? onBook : null,
        child: const Text('Book Now'),
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