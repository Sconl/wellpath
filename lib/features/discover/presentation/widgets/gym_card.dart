// lib/features/discover/presentation/widgets/gym_card.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Card for a single gym result in the Discovery list.
//            Rating stars, open/closed badge, address, tap-to-open in Maps.
//   v1.1.0 — Fixed undefined_getter: AppShadows.cardSelected doesn't exist in
//            app_theme.dart. Replaced with inline selected shadow derived from
//            AppColors.primary — consistent with the theme engine's approach
//            of using the brand color for glow states.
//          — Fixed prefer_const_constructors lint on TextStyle inside _RatingRow.
//          — Removed google_maps_flutter import — map package is now Mapbox.
//            Deep-link for "open in Maps" still uses the standard Maps URL
//            scheme which works cross-platform regardless of map display SDK.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/place_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kCardPadding  = 16.0;
const double _kIconBoxSize  = 48.0;
const double _kIconSize     = 22.0;
const double _kStarSize     = 12.0;
const double _kBadgePadH    = 8.0;
const double _kBadgePadV    = 3.0;

// ── Selected state shadow ──
// AppShadows.cardSelected doesn't exist in app_theme.dart — we use a
// primary-tinted glow inline instead, matching the button glow pattern.
const double _kSelectedShadowBlur    = 14.0;
const double _kSelectedShadowAlpha   = 0.22;

// ── Google Maps deep-link ──
// Opens the place by place_id — resolves the correct business listing in Maps.
const String _kMapsDeepLinkBase = 'https://www.google.com/maps/place/?q=place_id:';

// ─────────────────────────────────────────────────────────────────────────────
// GymCard
// ─────────────────────────────────────────────────────────────────────────────

class GymCard extends StatelessWidget {
  final PlaceModel    place;
  final bool          isSelected;   // highlighted when its pin is tapped on the map
  final VoidCallback? onTap;

  const GymCard({
    super.key,
    required this.place,
    this.isSelected = false,
    this.onTap,
  });

  Future<void> _openInMaps() async {
    final uri = Uri.parse('$_kMapsDeepLinkBase${place.placeId}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    // Selected shadow — primary-tinted glow. Derived from the brand color
    // the same way AppShadows.buttonGlow is, just lighter.
    final selectedShadow = [
      BoxShadow(
        color:      AppColors.primary.withValues(alpha: _kSelectedShadowAlpha),
        blurRadius: _kSelectedShadowBlur,
        offset:     const Offset(0, 4),
      ),
    ];

    return GestureDetector(
      onTap: onTap ?? _openInMaps,
      child: AnimatedContainer(
        duration:   const Duration(milliseconds: 200),
        padding:    const EdgeInsets.all(_kCardPadding),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: AppRadius.cardBR,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? selectedShadow : AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Icon box ──────────────────────────────────────────────────
            Container(
              width:  _kIconBoxSize,
              height: _kIconBoxSize,
              decoration: BoxDecoration(
                color:        AppColors.primary.withValues(alpha: 0.10),
                borderRadius: AppRadius.inputBR,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size:  _kIconSize,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            // ── Details ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + open/closed badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: AppTypography.h5.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _OpenBadge(isOpen: place.isOpen),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Address
                  Text(
                    place.shortAddress,
                    style: AppTypography.helper.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Rating
                  if (place.rating != null)
                    _RatingRow(
                      rating: place.rating!,
                      count:  place.userRatingsTotal,
                    ),
                ],
              ),
            ),

            // ── Navigation arrow ──────────────────────────────────────────
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size:  12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OpenBadge
// ─────────────────────────────────────────────────────────────────────────────

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.success : AppColors.error;
    final label = isOpen ? 'Open' : 'Closed';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _kBadgePadH,
        vertical:   _kBadgePadV,
      ),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBR,
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(
          color:      color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RatingRow — star icons + numeric rating + review count
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int?   count;
  const _RatingRow({required this.rating, this.count});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final halfStar  = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(5, (i) {
          IconData icon;
          if (i < fullStars) {
            icon = Icons.star_rounded;
          } else if (i == fullStars && halfStar) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          return Icon(icon, size: _kStarSize, color: AppColors.warning);
        }),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.helper.copyWith(
            color:      AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 3),
          Text(
            '($count)',
            style: AppTypography.helper.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}