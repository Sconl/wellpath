// lib/core/style/app_decorations.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Created — AppDecorations, AppShadows, AppTextStyles extracted from
//     app_theme.dart to give component-level styles their own home. Zero logic
//     changes — this is a pure relocation. All values and behavior identical.
// ─────────────────────────────────────────────────────────────────────────────

// WHAT LIVES HERE:
//
//   AppShadows     — reusable BoxShadow lists for cards, buttons, modals, inputs
//   AppDecorations — reusable BoxDecorations for cards, buttons, chips, banners
//   AppTextStyles  — semantic text style aliases (screenTitle, cardTitle, etc.)
//
// WHAT DOESN'T LIVE HERE:
//
//   Core color, gradient, spacing, radius, and typography primitives stay in
//   app_theme.dart — this file composes them into higher-level component styles.
//
// IMPORT PATTERN:
//
//   Anything that previously imported only app_theme.dart and used
//   AppDecorations, AppShadows, or AppTextStyles now needs both:
//     import 'app_theme.dart';
//     import 'app_decorations.dart';
//
//   Or wherever these files end up relative to the importing file:
//     import 'package:wellpath/core/style/app_theme.dart';
//     import 'package:wellpath/core/style/app_decorations.dart';

import 'package:flutter/material.dart';

import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────
//
// No standalone config values in this file — all visual constants (radii,
// spacing, colors, gradients) come from app_theme.dart's config block.
// If you find yourself wanting to hardcode a value here, it belongs in
// app_theme.dart's CONFIG BLOCK instead.

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// APP SHADOWS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppShadows {

  static List<BoxShadow> get card => [
    BoxShadow(
      color:      AppColors.background.withValues(alpha: 0.55),
      blurRadius: 20,
      offset:     const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get modal => [
    BoxShadow(
      color:      Colors.black.withValues(alpha: 0.50),
      blurRadius: 40,
      offset:     const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get buttonGlow => [
    BoxShadow(
      color:      AppColors.primaryDeep.withValues(alpha: 0.55),
      blurRadius: 24,
      offset:     const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get buttonGlowHover => [
    BoxShadow(
      color:      AppColors.primaryDeep.withValues(alpha: 0.70),
      blurRadius: 32,
      offset:     const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get secondaryGlow => [
    BoxShadow(
      color:      AppColors.secondaryDark.withValues(alpha: 0.50),
      blurRadius: 24,
      offset:     const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get inputFocus => [
    BoxShadow(
      color:        AppColors.primary.withValues(alpha: 0.18),
      blurRadius:   12,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> get successGlow => [
    BoxShadow(
      color:      AppColors.success.withValues(alpha: 0.28),
      blurRadius: 16,
      offset:     const Offset(0, 4),
    ),
  ];
}


// ─────────────────────────────────────────────────────────────────────────────
// APP DECORATIONS
// ─────────────────────────────────────────────────────────────────────────────
//
// BoxDecorations for component surfaces. These are the building blocks for
// manual gradient buttons and custom-painted cards that go beyond what
// Flutter's ThemeData widget themes can express natively.
//
// Gradient button pattern (ElevatedButton doesn't support gradients natively):
//
//   Container(
//     decoration: AppDecorations.primaryButton,
//     child: ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.transparent,
//         shadowColor:     Colors.transparent,
//       ),
//       onPressed: onPressed,
//       child: Text('Label'),
//     ),
//   )

abstract class AppDecorations {

  static BoxDecoration get card => BoxDecoration(
    color:        AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.border),
  );

  static BoxDecoration get cardElevated => BoxDecoration(
    gradient:     AppGradients.surface,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.border),
  );

  static BoxDecoration get modal => BoxDecoration(
    color:        AppColors.surfaceLit,
    borderRadius: BorderRadius.circular(AppRadius.modal),
    border:       Border.all(color: AppColors.borderStrong),
    boxShadow:    AppShadows.modal,
  );

  static BoxDecoration get popup => BoxDecoration(
    color:        AppColors.surfaceMid,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.border),
    boxShadow:    AppShadows.card,
  );

  static BoxDecoration get primaryButton => BoxDecoration(
    gradient:     AppGradients.button,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    boxShadow:    AppShadows.buttonGlow,
  );

  static BoxDecoration get primaryButtonHover => BoxDecoration(
    gradient:     AppGradients.buttonHover,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    boxShadow:    AppShadows.buttonGlowHover,
  );

  static BoxDecoration get secondaryButton => BoxDecoration(
    gradient:     AppGradients.secondary,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    boxShadow:    AppShadows.secondaryGlow,
  );

  static BoxDecoration get outlinedButton => BoxDecoration(
    color:        Colors.transparent,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    border:       Border.all(color: AppColors.primary, width: 1.5),
  );

  static BoxDecoration get avatar => BoxDecoration(
    gradient:     AppGradients.avatar,
    borderRadius: BorderRadius.circular(AppRadius.card),
  );

  static BoxDecoration get chip => BoxDecoration(
    color:        AppColors.tint10(AppColors.primary),
    borderRadius: BorderRadius.circular(AppSpacing.sm),
    border:       Border.all(color: AppColors.tint20(AppColors.primary)),
  );

  static BoxDecoration get successBanner => BoxDecoration(
    color:        AppColors.tint10(AppColors.success),
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.tint20(AppColors.success)),
  );

  static BoxDecoration get errorBanner => BoxDecoration(
    color:        AppColors.tint10(AppColors.error),
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.tint20(AppColors.error)),
  );

  static BoxDecoration get warningBanner => BoxDecoration(
    color:        AppColors.tint10(AppColors.warning),
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.tint20(AppColors.warning)),
  );

  static BoxDecoration get infoBanner => BoxDecoration(
    color:        AppColors.tint10(AppColors.info),
    borderRadius: BorderRadius.circular(AppRadius.card),
    border:       Border.all(color: AppColors.tint20(AppColors.info)),
  );

  static BoxDecoration get screenBackground => BoxDecoration(
    color: AppColors.background,
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// APP TEXT STYLES — semantic aliases
// ─────────────────────────────────────────────────────────────────────────────
//
// Named for their use context, not their visual properties. Use these in
// widgets rather than calling AppTypography directly — it makes intent clear
// and means a single update here applies across all usages.

abstract class AppTextStyles {
  static TextStyle get screenTitle    => AppTypography.h2;
  static TextStyle get sectionHeader  => AppTypography.overline;
  static TextStyle get cardTitle      => AppTypography.h4;
  static TextStyle get cardSubtitle   => AppTypography.bodySmall;
  static TextStyle get metricValue    => AppTypography.h3.copyWith(
    color: AppColors.primary, fontWeight: FontWeight.w700,
  );
  static TextStyle get metricLabel    => AppTypography.caption;
  static TextStyle get authHeading    => AppTypography.h2;
  static TextStyle get authSubheading => AppTypography.bodySmall;
  static TextStyle get link           => AppTypography.bodySmall.copyWith(
    color: AppColors.primary, fontWeight: FontWeight.w500,
  );
  static TextStyle get errorText      => AppTypography.helper.copyWith(
    color: AppColors.error,
  );
  static TextStyle get successText    => AppTypography.helper.copyWith(
    color: AppColors.success,
  );
  static TextStyle get warningText    => AppTypography.helper.copyWith(
    color: AppColors.warning,
  );
  static TextStyle get timestamp      => AppTypography.caption;
  static TextStyle get notifTitle     => AppTypography.body.copyWith(
    fontWeight: FontWeight.w700,
  );
  static TextStyle get notifBody      => AppTypography.bodySmall;
  static TextStyle get statusLive     => AppTypography.badge.copyWith(
    color: AppColors.live, letterSpacing: 1,
  );
}