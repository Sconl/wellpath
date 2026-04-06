// lib/features/home/widgets/trainer_card.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Horizontal-scroll card for trainer discovery strip.
//            Photo → initials fallback. Up to two specialty chips.
//            Tap handler delegated to parent — card is pure display.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../core/style/app_theme.dart';
import '../data/trainer_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kCardWidth = 172.0;
const double _kPhotoHeight = 108.0;
const double _kAvatarRadius = 28.0;
const double _kCardPadding = 10.0;

// ── Specialty chips ──
const int _kMaxSpecialtyChips = 2; // avoids overflow in narrow cards

// ─────────────────────────────────────────────────────────────────────────────
// TrainerCard
// ─────────────────────────────────────────────────────────────────────────────

class TrainerCard extends StatelessWidget {
  final TrainerModel trainer;
  final VoidCallback onTap;

  const TrainerCard({
    super.key,
    required this.trainer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kCardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo / initials fallback ─────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
              child: trainer.photoUrl != null && trainer.photoUrl!.isNotEmpty
                  ? Image.network(
                      trainer.photoUrl!,
                      width: _kCardWidth,
                      height: _kPhotoHeight,
                      fit: BoxFit.cover,
                      // Network failures should never leave a blank box —
                      // the initials fallback keeps the card usable.
                      errorBuilder: (_, __, ___) => _InitialsFallback(
                        trainer: trainer,
                        width: _kCardWidth,
                        height: _kPhotoHeight,
                      ),
                    )
                  : _InitialsFallback(
                      trainer: trainer,
                      width: _kCardWidth,
                      height: _kPhotoHeight,
                    ),
            ),

            // ── Details ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(_kCardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  if (trainer.specialties.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: trainer.specialties
                          .take(_kMaxSpecialtyChips)
                          .map(_SpecialtyChip.new)
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // "View profile" affordance
                  Text(
                    'View profile →',
                    style: AppTypography.helper.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InitialsFallback
// ─────────────────────────────────────────────────────────────────────────────

class _InitialsFallback extends StatelessWidget {
  final TrainerModel trainer;
  final double width;
  final double height;

  const _InitialsFallback({
    required this.trainer,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Center(
        child: CircleAvatar(
          radius: _kAvatarRadius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            trainer.initials,
            style: AppTypography.h4.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecialtyChip
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.inputBR,
      ),
      child: Text(
        label,
        style: AppTypography.helper.copyWith(color: AppColors.primary),
      ),
    );
  }
}
