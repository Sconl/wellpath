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

const double _kHorizPad = 20.0;
const double _kStickyBarH = 72.0;

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
        loading: () => const Center(child: CircularProgressIndicator()),
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

// ─────────────────────────────────────────────

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
      _selectedSlot = _selectedSlot?.id == slot.id ? null : slot;
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
    final slotsAsync = ref.watch(trainerSlotsProvider(widget.trainer.id));

    final slots = slotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const <AvailabilitySlot>[],
    );

    final availableSlots = slots.where((s) => s.status.isBookable).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(trainer: widget.trainer),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: _kHorizPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Slots',
                              style: AppTypography.h4),
                          const SizedBox(height: 10),

                          Builder(
                            builder: (_) {
                              if (slotsAsync.isLoading &&
                                  slots.isEmpty) {
                                return const Center(
                                    child:
                                        CircularProgressIndicator());
                              }

                              if (slotsAsync.hasError &&
                                  slots.isEmpty) {
                                return const Text(
                                    'Failed to load slots');
                              }

                              if (availableSlots.isEmpty) {
                                return _NoSlotsState(
                                  trainerName:
                                      widget.trainer.displayName,
                                );
                              }

                              return _SlotGrid(
                                slots: availableSlots,
                                selectedSlot: _selectedSlot,
                                onSelect: _selectSlot,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final TrainerProfile trainer;
  const _ProfileHeader({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/trainers'),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(trainer.displayName,
                style: AppTypography.h3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  final AvailabilitySlot? selectedSlot;
  final ValueChanged<AvailabilitySlot> onSelect;

  const _SlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSelect,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final selected = selectedSlot?.id == slot.id;

            return GestureDetector(
              onTap: () => onSelect(slot),
              child: Container(
                width: width,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surface,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(_formatTime(slot.startTime)),
                    const SizedBox(height: 4),
                    Text(_formatTime(slot.endTime)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: selectedSlot == null ? null : onBook,
        child: const Text('Book'),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _NoSlotsState extends StatelessWidget {
  final String trainerName;
  const _NoSlotsState({required this.trainerName});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No slots available'));
  }
}

// ─────────────────────────────────────────────

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

    ref.invalidate(trainerSlotsProvider(widget.trainer.id));

    if (mounted) {
      Navigator.pop(context);
      context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmBooking,
        child: const Text('Confirm Booking'),
      ),
    );
  }
}