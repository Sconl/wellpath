// lib/features/bookings/presentation/trainer_profile_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Trainer profile with:
//            - Hero section: avatar/photo, name, rating, specialties, price.
//            - Bio card.
//            - Day picker (next kSlotWindowDays — shows days that have slots).
//            - Slot list for selected day.
//            - SlotSelectionSheet modal on slot tap.
//            - Real-time slot stream via availableSlotsProvider.
//            Reached via GoRouter /trainer/:id.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/trainer_profile.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_theme.dart';
import '../data/availability_model.dart';
import '../providers/bookings_providers.dart';
import 'widgets/slot_selection_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kHorizPad = 20.0;
const double _kHeroH = 240.0;
const double _kDayChipW = 62.0;
const double _kDayChipH = 72.0;
const double _kStarSize = 13.0;

const List<String> _kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─────────────────────────────────────────────────────────────────────────────
// TrainerProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class TrainerProfileScreen extends ConsumerStatefulWidget {
  final String trainerId;
  const TrainerProfileScreen({super.key, required this.trainerId});

  @override
  ConsumerState<TrainerProfileScreen> createState() =>
      _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends ConsumerState<TrainerProfileScreen> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(trainerProfileProvider(widget.trainerId));
    final slotsAsync = ref.watch(availableSlotsProvider(widget.trainerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppCanvas(
        type: BackgroundType.meshParticle,
        particleStyle: ParticleStyle.drift,
        gradientStyle: GradientStyle.pulse,
        child: profileAsync.when(
          loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => _ErrorBody(onBack: () => context.pop()),
          data: (profile) {
            if (profile == null) {
              return _ErrorBody(onBack: () => context.pop());
            }
            // Group slots by date for the day picker.
            final slots = slotsAsync.valueOrNull ?? [];
            final byDate = groupSlotsByDate(slots);
            final sortedDays = byDate.keys.toList()..sort();

            // Auto-select first available day.
            final effectiveDay =
                _selectedDay != null && byDate.containsKey(_selectedDay)
                    ? _selectedDay!
                    : (sortedDays.isNotEmpty ? sortedDays.first : null);

            final daySlots = effectiveDay != null
                ? (byDate[effectiveDay] ?? [])
                : <AvailabilitySlot>[];

            return CustomScrollView(
              slivers: [
                // ── Hero app bar ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: _kHeroH,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textPrimary, size: 18),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeroSection(profile: profile),
                  ),
                ),

                // ── Content ───────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _kHorizPad, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Bio card
                      if (profile.bio.isNotEmpty) ...[
                        _SectionCard(
                          title: 'About',
                          child: Text(profile.bio,
                              style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary, height: 1.6)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Specialties
                      if (profile.specialties.isNotEmpty) ...[
                        _SectionCard(
                          title: 'Specialties',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.specialties
                                .map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.10),
                                      borderRadius: AppRadius.inputBR,
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25)),
                                    ),
                                    child: Text(s,
                                        style: AppTypography.chip.copyWith(
                                            color: AppColors.primary)),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Book a session header
                      Text('Book a Session', style: AppTypography.h3),
                      const SizedBox(height: 12),

                      // Day picker
                      if (slotsAsync.isLoading)
                        Center(
                            child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ))
                      else if (sortedDays.isEmpty)
                        _NoSlotsState(
                          trainerName: profile.displayName,
                        )
                      else ...[
                        _DayPicker(
                          days: sortedDays,
                          slotCounts: {
                            for (final e in byDate.entries)
                              e.key: e.value.length
                          },
                          selectedDay: effectiveDay,
                          onDaySelected: (d) =>
                              setState(() => _selectedDay = d),
                        ),
                        const SizedBox(height: 16),

                        // Slot list for selected day
                        ...daySlots.map((slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SlotCard(
                                slot: slot,
                                profile: profile,
                              ),
                            )),
                      ],

                      const SizedBox(height: 96),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeroSection
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final TrainerProfile profile;
  const _HeroSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kHorizPad, 60, _kHorizPad, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppGradients.avatar,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppShadows.buttonGlow,
                  ),
                  child: Center(
                    child: Text(
                      profile.initials,
                      style:
                          AppTypography.h1.copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(profile.displayName,
                              style: AppTypography.h2),
                        ),
                        if (profile.isVerified)
                          Icon(Icons.verified_rounded,
                              color: AppColors.primary, size: 16),
                      ]),
                      const SizedBox(height: 4),
                      Text(profile.locationName,
                          style: AppTypography.helper
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        // Rating stars
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < profile.rating.floor()
                                      ? Icons.star_rounded
                                      : (i < profile.rating
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded),
                                  color: AppColors.warning,
                                  size: _kStarSize,
                                )),
                        const SizedBox(width: 6),
                        Text(
                          '${profile.rating.toStringAsFixed(1)} '
                          '(${profile.reviewCount} reviews)',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ]),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Price badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: AppRadius.pillBR,
                  boxShadow: AppShadows.buttonGlow,
                ),
                child: Text(profile.priceDisplay,
                    style: AppTypography.chip
                        .copyWith(color: AppColors.onPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DayPicker — horizontal scroll of day chips
// ─────────────────────────────────────────────────────────────────────────────

class _DayPicker extends StatelessWidget {
  final List<DateTime> days;
  final Map<DateTime, int> slotCounts;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _DayPicker({
    required this.days,
    required this.slotCounts,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: _kDayChipH + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final day = days[i];
          final count = slotCounts[day] ?? 0;
          final selected = selectedDay == day;
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: _kDayChipW,
              height: _kDayChipH,
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.button : null,
                color: selected ? null : AppColors.surface,
                borderRadius: AppRadius.inputBR,
                border: Border.all(
                  color: selected ? Colors.transparent : AppColors.border,
                ),
                boxShadow: selected ? AppShadows.buttonGlow : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : _kDays[day.weekday - 1],
                    style: AppTypography.caption.copyWith(
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: AppTypography.h4.copyWith(
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count ${count == 1 ? "slot" : "slots"}',
                    style: AppTypography.badge.copyWith(
                      color: selected
                          ? AppColors.onPrimary.withValues(alpha: 0.80)
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SlotCard — individual bookable slot row
// ─────────────────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final AvailabilitySlot slot;
  final TrainerProfile profile;
  const _SlotCard({required this.slot, required this.profile});

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card.copyWith(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          // Time column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatTime(slot.startTime),
                  style: AppTypography.h4.copyWith(color: AppColors.primary)),
              Text('${slot.durationMinutes} min',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(width: 16),
          // Type + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.sessionType.label, style: AppTypography.h5),
                Text(slot.locationDisplay,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Price + CTA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(slot.priceDisplay,
                  style: AppTypography.h5.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: AppDecorations.primaryButton,
                child: Text('Book', style: AppTypography.buttonSm),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SlotSelectionSheet(
        slot: slot,
        profile: profile,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionCard
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: AppDecorations.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h4),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoSlotsState
// ─────────────────────────────────────────────────────────────────────────────

class _NoSlotsState extends StatelessWidget {
  final String trainerName;
  const _NoSlotsState({required this.trainerName});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.card,
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded,
                color: AppColors.textMuted, size: 36),
            const SizedBox(height: 12),
            Text('No slots available right now',
                textAlign: TextAlign.center,
                style:
                    AppTypography.h5.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            // Warm empty state — signature font approved use case.
            Text(
              '${trainerName.split(' ').first} hasn\'t posted upcoming '
              'availability yet. Check back soon.',
              textAlign: TextAlign.center,
              style: AppTypography.signature.copyWith(fontSize: 13),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBody
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final VoidCallback onBack;
  const _ErrorBody({required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                color: AppColors.textMuted, size: 42),
            const SizedBox(height: 16),
            Text('Trainer not found',
                style:
                    AppTypography.h4.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: AppDecorations.outlinedButton,
                child: Text('Go Back',
                    style: AppTypography.button
                        .copyWith(color: AppColors.primary)),
              ),
            ),
          ],
        ),
      );
}
