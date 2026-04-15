// lib/spaces/space_site/screen_home/section_core/section_core_hero.dart
//
// QP CANON: screen_home › section_core — blocks: core_identity, core_value, core_action
//
// ADMIN WIRING
//   Accepts AdminFeatureFlags so motion toggles (typing animation,
//   attention button, card border animation) are controlled by the admin plane.

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_motion.dart';
import '../../../../core/admin/admin_schema.dart';
import '../../space_site_shared.dart';
import '../../space_site_config.dart';

class SectionCoreHero extends StatelessWidget {
  final SiteHeroConfig config;
  final AdminFeatureFlags   flags;
  final VoidCallback        onPrimary;
  final VoidCallback        onSecondary;

  const SectionCoreHero({
    super.key,
    required this.config,
    required this.flags,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // ── core_identity: badge pill ────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color:        AppColors.tint10(AppColors.primary),
            borderRadius: AppRadius.pillBR,
            border:       Border.all(color: AppColors.tint20(AppColors.primary)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle)),
            SizedBox(width: AppSpacing.xs),
            Text(config.badge,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ),

        SizedBox(height: AppSpacing.md),

        // ── core_value: headline — animated or static ────────────────────
        // flags.enableTypingAnimation controls this per admin toggle.
        SitePageHero(
          eyebrow:        '',          // eyebrow shown by badge pill above
          staticHeadline: config.headline.phrases.isNotEmpty
              ? config.headline.phrases.first
              : '',
          subline:        config.subline,
          typingConfig:   config.headline,
          showAnimation:  flags.enableTypingAnimation,
          // Don't render the eyebrow + subline again — we embed this inline
          showEyebrow:    false,
          showSubline:    false,
        ),

        SizedBox(height: AppSpacing.sm),

        // ── core_value: subline ──────────────────────────────────────────
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(config.subline,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
                height: 1.65, color: AppColors.textSecondary)),
        ),

        SizedBox(height: AppSpacing.lg + AppSpacing.xs),

        // ── core_action: CTA buttons ─────────────────────────────────────
        // Primary uses PrimaryAttentionButton when flag is on, plain gradient
        // button otherwise. Secondary is always the outline button.
        Wrap(
          spacing:   AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            flags.enableAttentionButton
                ? PrimaryAttentionButton(
                    label: config.primaryCtaLabel,
                    onTap: onPrimary,
                  )
                : SiteGradientButton(
                    label: config.primaryCtaLabel,
                    onTap: onPrimary,
                  ),
            SiteOutlineButton(
              label: config.secondaryCtaLabel,
              onTap: onSecondary,
            ),
          ],
        ),

        SizedBox(height: AppSpacing.lg),

        // ── core_action: microcopy ────────────────────────────────────────
        Text(config.microcopy,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(fontSize: 12)),
      ],
    );
  }
}