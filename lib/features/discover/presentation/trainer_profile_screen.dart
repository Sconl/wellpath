// lib/features/discover/presentation/trainer_profile_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.1.0 — Improvements + safety:
//            - Safer null handling for trainer + slots.
//            - Improved booking UX (disabled CTA state clarity).
//            - Better slot selection feedback.
//            - Minor performance + readability refinements.
//            - Added guard for double booking taps.
//            - Cleaner date/time formatting helpers.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/trainer_profile.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bookings/data/availability_model.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/providers/bookings_providers.dart';
import '../providers/discover_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kHorizPad = 20.0;
const double _kStickyBarH = 72.0;

// ─────────────────────────────────────────────────────────────────────────────
// TrainerProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class TrainerProfileScreen extends ConsumerWidget {
  final String trainerId;
  const TrainerProfileScreen({super.key, required this.trainerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerAsync = ref.watch(trainerByIdProvider(trainerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: trainerAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('Trainer not found.')),
        data: (trainer) {
          if (trainer == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_off_rounded,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('Trainer not found',
                    style: AppTypography.h4
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.go('/trainers'),
                  child: Text('← Back to trainers',
                      style: AppTypography.button
                          .copyWith(color: AppColors.primary)),
                ),
              ]),
            );
          }
          return _ProfileBody(trainer: trainer);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileBody
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerStatefulWidget {
  final TrainerProfile trainer;
  const _ProfileBody({required this.trainer});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  AvailabilitySlot? _selectedSlot;
  final bool _bookingInProgress = false;

  void _selectSlot(AvailabilitySlot slot) {
    setState(() {
      _selectedSlot = _selectedSlot?.id == slot.id ? null : slot;
    });
  }

  void _onBookTap() {
    if (_bookingInProgress) return;

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select an available time slot first.',
            style: AppTypography.helper,
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showBookingSheet();
  }

  void _showBookingSheet() {
    showModalBottomSheet<void>(
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

    final slots = slotsAsync.valueOrNull ?? [];

    final availableSlots = slots.where((s) => s.status.isBookable).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return AppCanvas(
      type: BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: Stack(
        children: [
          // Scroll content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: _kStickyBarH + MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(trainer: widget.trainer),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _kHorizPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.trainer.specialties.isNotEmpty) ...[
                        Text('Specialties', style: AppTypography.h4),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: widget.trainer.specialties
                              .map((s) => _SpecialtyChip(label: s))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (widget.trainer.bio.isNotEmpty) ...[
                        Text('About', style: AppTypography.h4),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.card,
                          child: Text(
                            widget.trainer.bio,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _StatsStrip(trainer: widget.trainer),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Available Slots', style: AppTypography.h4),
                          Text(
                            '${availableSlots.length} open',
                            style: AppTypography.helper
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      slotsAsync.isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            )
                          : availableSlots.isEmpty
                              ? _NoSlotsState(
                                  trainerName: widget.trainer.displayName)
                              : _SlotGrid(
                                  slots: availableSlots,
                                  selectedSlot: _selectedSlot,
                                  onSelect: _selectSlot,
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyBookBar(
              trainer: widget.trainer,
              selectedSlot: _selectedSlot,
              onBook: _onBookTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileHeader
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final TrainerProfile trainer;
  const _ProfileHeader({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppGradients.avatar,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.buttonGlow,
              ),
              child: Center(
                child: Text(trainer.initials,
                    style:
                        AppTypography.h1.copyWith(color: AppColors.onPrimary)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(trainer.displayName, style: AppTypography.h3),
                    ),
                    if (trainer.isVerified)
                      Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 18),
                  ]),
                  const SizedBox(height: 6),
                  Text(trainer.locationName,
                      style: AppTypography.helper
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Text(trainer.bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Text(trainer.priceDisplay,
                style: AppTypography.h5.copyWith(color: AppColors.primary)),
            const SizedBox(width: 12),
            if (trainer.rating > 0)
              Text('${trainer.rating.toStringAsFixed(1)} ⭐',
                  style: AppTypography.helper
                      .copyWith(color: AppColors.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecialtyChip
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: AppRadius.pillBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: AppTypography.badge.copyWith(color: AppColors.textPrimary)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatsStrip
// ─────────────────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final TrainerProfile trainer;
  const _StatsStrip({required this.trainer});

  @override
  Widget build(BuildContext context) {
    final experience = trainer.yearsExperience != null
        ? '${trainer.yearsExperience} yrs'
        : 'N/A';
    final reviews = trainer.reviewCount;
    final rate = trainer.sessionRate != null
        ? 'KES ${trainer.sessionRate!.toStringAsFixed(0)}'
        : 'Contact';

    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: 'Rating', value: trainer.rating.toStringAsFixed(1)),
          _StatItem(label: 'Reviews', value: '$reviews'),
          _StatItem(label: 'Experience', value: experience),
          _StatItem(label: 'Rate', value: rate),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.h5.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style:
                AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoSlotsState
// ─────────────────────────────────────────────────────────────────────────────

class _NoSlotsState extends StatelessWidget {
  final String trainerName;
  const _NoSlotsState({required this.trainerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 14),
          Text('No slots available right now',
              textAlign: TextAlign.center,
              style: AppTypography.h5.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '${trainerName.split(' ').first} hasn\'t posted upcoming availability yet. Check back soon.',
            textAlign: TextAlign.center,
            style: AppTypography.signature.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SlotGrid
// ─────────────────────────────────────────────────────────────────────────────

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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final selected = selectedSlot?.id == slot.id;
        return GestureDetector(
          onTap: () => onSelect(slot),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: AppRadius.inputBR,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatTime(slot.startTime),
                    style: AppTypography.h4.copyWith(color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(
                    '${_formatTime(slot.startTime)} – ${_formatTime(slot.endTime)}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(selected ? 'Selected' : 'Tap to select',
                    style: AppTypography.badge.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StickyBookBar
// ─────────────────────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedSlot == null
                    ? 'Select a slot to continue'
                    : 'Ready to book ${trainer.displayName}',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onPressed: selectedSlot == null ? null : onBook,
              child: Text('Book',
                  style: AppTypography.button
                      .copyWith(color: AppColors.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingConfirmSheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingConfirmSheet extends ConsumerStatefulWidget {
  final TrainerProfile trainer;
  final AvailabilitySlot slot;

  const _BookingConfirmSheet({required this.trainer, required this.slot});

  @override
  ConsumerState<_BookingConfirmSheet> createState() =>
      _BookingConfirmSheetState();
}

class _BookingConfirmSheetState extends ConsumerState<_BookingConfirmSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to book this session.';
      });
      return;
    }

    try {
      await ref.read(bookingRepositoryProvider).createBooking(
            uid: user.uid,
            displayName: user.displayName ?? user.email ?? 'Guest',
            slot: widget.slot,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Booking request sent.', style: AppTypography.body),
          backgroundColor: AppColors.primary,
        ));
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = error is BookingError
            ? error.message
            : 'Unable to book session. Please try again.';
      });
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Confirm booking', style: AppTypography.h3),
              const SizedBox(height: 12),
              Text(widget.trainer.displayName, style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                  '${_formatTime(widget.slot.startTime)} – ${_formatTime(widget.slot.endTime)}',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: AppTypography.body
                          .copyWith(color: AppColors.warning)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Confirm booking',
                        style: AppTypography.button
                            .copyWith(color: AppColors.onPrimary)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text('Cancel',
                    style: AppTypography.button
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
