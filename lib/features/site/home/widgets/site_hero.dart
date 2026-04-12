// lib/features/site/home/widgets/site_hero.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Site — SiteHero
// ─────────────────────────────────────────────────────────────────────────────
// Hero section: badge → typing headline → subline → CTAs → microcopy.
// [TypingHeadline] is imported from app_motion.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_motion.dart';
import '../../site_config.dart';
import 'site_shared.dart';

class SiteHero extends StatelessWidget {
  final SiteHeroConfig config;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const SiteHero({
    super.key,
    required this.config,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Badge pill ────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.tint10(AppColors.primary),
            borderRadius: AppRadius.pillBR,
            border: Border.all(color: AppColors.tint20(AppColors.primary)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              config.badge,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ]),
        ),

        SizedBox(height: AppSpacing.md),

        // ── Typing headline (from app_motion) ─────────────────────────────
        TypingHeadline(config: config.headline),

        SizedBox(height: AppSpacing.sm),

        // ── Subline ───────────────────────────────────────────────────────
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            config.subline,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              height: 1.65, color: AppColors.textSecondary),
          ),
        ),

        SizedBox(height: AppSpacing.lg + AppSpacing.xs),

        // ── CTA row ───────────────────────────────────────────────────────
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            SiteGradientButton(label: config.primaryCtaLabel,   onTap: onPrimary),
            SiteOutlineButton(label:  config.secondaryCtaLabel, onTap: onSecondary),
          ],
        ),

        SizedBox(height: AppSpacing.lg),

        // ── Microcopy ─────────────────────────────────────────────────────
        Text(
          config.microcopy,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}