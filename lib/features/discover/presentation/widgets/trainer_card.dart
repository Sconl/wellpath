// lib/features/discover/presentation/widgets/trainer_card.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Card for a single trainer result in the Discovery list.
//            Rating stars, specialties, bio preview, tap to view profile.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/trainer_profile.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kCardPadding = 16.0;
const double _kIconBoxSize = 48.0;
const double _kStarSize = 12.0;
const double _kBadgePadH = 8.0;
const double _kBadgePadV = 3.0;

// ── Selected state shadow ──
const double _kSelectedShadowBlur = 14.0;
const double _kSelectedShadowAlpha = 0.22;

// ─────────────────────────────────────────────────────────────────────────────
// TrainerCard
// ─────────────────────────────────────────────────────────────────────────────

class TrainerCard extends StatelessWidget {
  final TrainerProfile trainer;
  final bool isSelected;

  const TrainerCard({
    super.key,
    required this.trainer,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = isSelected
        ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _kSelectedShadowAlpha),
              blurRadius: _kSelectedShadowBlur,
            ),
          ]
        : null;

    return GestureDetector(
      onTap: () => context.go('/trainer/${trainer.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(_kCardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.inputBR,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: shadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Container(
            width: _kIconBoxSize,
            height: _kIconBoxSize,
            decoration: BoxDecoration(
              gradient: AppGradients.avatar,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.buttonGlow,
            ),
            child: Center(
              child: Text(
                trainer.initials,
                style: AppTypography.h3.copyWith(color: AppColors.onPrimary),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Name + rating
              Row(children: [
                Expanded(
                  child: Text(trainer.displayName, style: AppTypography.h4),
                ),
                if (trainer.isVerified)
                  Icon(Icons.verified_rounded,
                      color: AppColors.primary, size: 16),
              ]),

              const SizedBox(height: 4),

              // Rating
              _RatingRow(rating: trainer.rating, count: trainer.reviewCount),

              const SizedBox(height: 6),

              // Location
              Text(trainer.locationName,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),

              const SizedBox(height: 6),

              // Specialties
              if (trainer.specialties.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: trainer.specialties
                      .take(3)
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _kBadgePadH, vertical: _kBadgePadV),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: AppRadius.pillBR,
                          ),
                          child: Text(s,
                              style: AppTypography.badge
                                  .copyWith(color: AppColors.primary)),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 6),

              // Bio preview
              if (trainer.bio.isNotEmpty)
                Text(
                  trainer.bio.length > 80
                      ? '${trainer.bio.substring(0, 80)}...'
                      : trainer.bio,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RatingRow
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int count;

  const _RatingRow({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ...List.generate(
          5,
          (i) => Icon(
                i < rating.floor()
                    ? Icons.star_rounded
                    : (i < rating
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded),
                color: AppColors.warning,
                size: _kStarSize,
              )),
      const SizedBox(width: 6),
      Text(
        '${rating.toStringAsFixed(1)} ($count)',
        style: const TextStyle(
            color: Color(0xFF8B8B8B),
            fontSize: 11,
            fontWeight: FontWeight.w500),
      ),
    ]);
  }
}
