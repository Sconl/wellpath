// lib/features/discover/presentation/widgets/trainer_card.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. TrainerProfile-based card for the Trainers and Discover
//            screens. Replaces the old home/widgets/trainer_card.dart which
//            used the legacy TrainerModel type.
//            Tap → GoRouter /trainer/:id (TrainerProfileScreen).
//            Displays: avatar initials, name, location, rating, specialties (3),
//            verified badge, price. Full-width horizontal layout.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/trainer_profile.dart';
import '../../../../core/style/app_decorations.dart';
import '../../../../core/style/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kAvatarSize       = 52.0;
const double _kCardPadding      = 16.0;
const int    _kMaxSpecialties   = 3;
const double _kStarSize         = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// TrainerCard
// ─────────────────────────────────────────────────────────────────────────────

class TrainerCard extends StatelessWidget {
  final TrainerProfile trainer;

  // onTap is optional — defaults to navigating to /trainer/:id.
  // Pass a custom handler only when embedding in contexts where GoRouter
  // navigation isn't appropriate (e.g. a preview sheet).
  final VoidCallback? onTap;

  const TrainerCard({super.key, required this.trainer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/trainer/${trainer.id}'),
      child: Container(
        padding:    const EdgeInsets.all(_kCardPadding),
        decoration: AppDecorations.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            _Avatar(trainer: trainer),
            const SizedBox(width: 14),

            // ── Details ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + verified badge
                  Row(children: [
                    Expanded(
                      child: Text(
                        trainer.displayName,
                        style: AppTypography.h5
                            .copyWith(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trainer.isVerified) ...[
                      const SizedBox(width: 5),
                      Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 14),
                    ],
                  ]),

                  const SizedBox(height: 2),

                  // Location
                  Text(
                    trainer.locationName,
                    style: AppTypography.helper
                        .copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Rating stars
                  if (trainer.rating > 0)
                    _RatingRow(
                        rating: trainer.rating,
                        reviewCount: trainer.reviewCount),

                  const SizedBox(height: 8),

                  // Specialty chips (max 3)
                  if (trainer.specialties.isNotEmpty)
                    Wrap(
                      spacing:    5,
                      runSpacing: 4,
                      children: trainer.specialties
                          .take(_kMaxSpecialties)
                          .map((s) => _SpecialtyChip(label: s))
                          .toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Price + CTA ───────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trainer.priceKes != null
                      ? 'KES ${trainer.priceKes!.toStringAsFixed(0)}'
                      : 'Contact',
                  style: AppTypography.h5
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'per session',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: AppDecorations.primaryButton,
                  child: Text('View →',
                      style: AppTypography.badge
                          .copyWith(color: AppColors.onPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final TrainerProfile trainer;
  const _Avatar({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  _kAvatarSize,
      height: _kAvatarSize,
      decoration: BoxDecoration(
        gradient:     AppGradients.avatar,
        borderRadius: BorderRadius.circular(14),
        boxShadow:    AppShadows.buttonGlow,
      ),
      child: trainer.photoUrl != null && trainer.photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                trainer.photoUrl!,
                width:  _kAvatarSize,
                height: _kAvatarSize,
                fit:    BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(trainer: trainer),
              ),
            )
          : _Initials(trainer: trainer),
    );
  }
}

class _Initials extends StatelessWidget {
  final TrainerProfile trainer;
  const _Initials({required this.trainer});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      trainer.initials,
      style: AppTypography.h4.copyWith(color: AppColors.onPrimary),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _RatingRow
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int    reviewCount;
  const _RatingRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(children: [
      ...List.generate(5, (i) => Icon(
        i < full
            ? Icons.star_rounded
            : (i == full && half)
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
        color: AppColors.warning,
        size:  _kStarSize,
      )),
      const SizedBox(width: 5),
      Text(
        '${rating.toStringAsFixed(1)} ($reviewCount)',
        style: AppTypography.caption
            .copyWith(color: AppColors.textSecondary),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecialtyChip
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColors.primary.withValues(alpha: 0.10),
      borderRadius: AppRadius.pillBR,
      border:       Border.all(
          color: AppColors.primary.withValues(alpha: 0.22)),
    ),
    child: Text(label,
        style: AppTypography.badge.copyWith(color: AppColors.primary)),
  );
}