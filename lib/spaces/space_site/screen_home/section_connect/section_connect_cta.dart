// lib/spaces/space_site/screen_home/section_connect/section_connect_cta.dart
//
// QP CANON: SECTION CONNECT — block connect_cta
// Split from: widgets/site_cta_footer.dart

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../../../core/style/app_motion.dart';
import '../../space_site_config.dart';
import '../../space_site_shared.dart';

class SectionConnectCta extends StatelessWidget {
  final SiteCtaConfig config;
  final VoidCallback onTap;

  const SectionConnectCta({super.key, required this.config, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientSurface(
      borderRadius: AppRadius.cardBR,
      border:       Border.all(color: AppColors.borderStrong),
      boxShadow:    AppShadows.buttonGlow,
      colors: [
        AppColors.primaryDeep,
        AppColors.primary.withAlpha(220),
        AppColors.primaryDark,
      ],
      duration: const Duration(seconds: 6),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
        child: Column(children: [
          // 4-part header adapted for dark gradient surface
          Text(config.eyebrow.toUpperCase(),
            style: AppTypography.overline.copyWith(
                color: AppColors.primary.withAlpha(180))),
          SizedBox(height: AppSpacing.sm),
          Text(config.heading,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(fontSize: 34, height: 1.2)),
          SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(config.subheading,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                  height: 1.6, color: AppColors.textSecondary)),
          ),
          SizedBox(height: AppSpacing.xl),
          // Primary CTA uses attention animation
          PrimaryAttentionButton(
            label:           config.buttonLabel,
            onTap:           onTap,
            padding:         EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
            fontSize:        16,
            triggerInterval: const Duration(seconds: 7),
          ),
        ]),
      ),
    );
  }
}