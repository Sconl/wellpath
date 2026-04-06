// lib/core/style/app_theme.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial release — universal reusable theme template — Sconl Peter
//   • Color engine generates full palette from 3 brand seeds automatically
//   • 60-30-10 split enforced structurally, not by convention
//   • Gradient logic built in for buttons, backgrounds, surfaces, modals
//   • WCAG contrast checker built in — onColor() always picks readable text
//   • Fixed deprecated Color channel APIs: .red/.green/.blue/.alpha replaced
//     with .r/.g/.b/.a (Flutter 3.27+ Color API uses double 0.0–1.0 channels)
//   • Fixed _luminance() parameter type int → double to match new channel API
//   • Removed unused darkContrast local variable from onColor()
//   • Replaced all withOpacity() calls with withValues(alpha:) throughout
//   • saturate() and desaturate() are intentional template utilities — kept
//     with ignore comments; they exist for future screen colour decisions
//   • Brand color seeds moved to app_branding.dart — engine reads BrandColors
//   • Font family moved to app_branding.dart — engine reads BrandCopy
//   • import 'app_branding.dart' added — dependency direction now correct
//   • AppDecorations, AppShadows, AppTextStyles extracted → app_decorations.dart
//   • File path updated: lib/core/theme/ → lib/core/style/
//   • AppTypography updated for 5-font role system: Hero / Display / Text /
//     Accent / Signature. Each text style is now explicitly assigned a font role.
//     Swap fonts in app_branding.dart CONFIG BLOCK — nothing changes here.
//   • AppTypography._f() gains optional `font` parameter — defaults to fontText
//   • AppTypography.signature added — emotional moments style using fontSignature
//   • textTheme base updated from fontFamily to BrandCopy.fontText
// ─────────────────────────────────────────────────────────────────────────────

// HOW TO USE THIS FILE IN A NEW PROJECT:
//
//   1. Open app_branding.dart (above this in the dependency chain).
//   2. Set BrandColors.primary/secondary/tertiary.
//   3. Set each font role constant (kFontHero through kFontSignature).
//   4. Done — everything here regenerates from those inputs automatically.
//
//   Shape/spacing/depth constants below are the only things to configure
//   in THIS file. Those are layout decisions, not brand decisions.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_branding.dart'; // BrandColors (seeds) + BrandCopy (font roles + copy)


// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────
//
// Font roles live in app_branding.dart. This block contains only shape,
// spacing, and depth constants — layout and visual structure decisions.

// ── Spacing ───────────────────────────────────────────────────────────────────
const double _kSpacingBase = 4.0;

// ── Shape ─────────────────────────────────────────────────────────────────────
const double _kRadiusInput = 10.0;
const double _kRadiusCard  = 14.0;
const double _kRadiusModal = 20.0;
const double _kRadiusPill  = 50.0;

// ── Depth / Surface Steps ─────────────────────────────────────────────────────
const double _kDarkSurfaceStep           = 0.065;
const double _kLightSurfaceStep          = 0.040;
const double _kDarkBackgroundSaturation  = 0.22;
const double _kLightBackgroundSaturation = 0.08;

// +12° on the end stop gives buttons depth and warmth — simulates a light
// source at the top-left corner without needing an actual light layer.
const double _kGradientHueShift = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// COLOR ENGINE
// ─────────────────────────────────────────────────────────────────────────────

abstract class _Engine {

  static HSLColor _hsl(Color c) => HSLColor.fromColor(c);

  static Color lighten(Color c, double amount) {
    final h = _hsl(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color darken(Color c, double amount) {
    final h = _hsl(c);
    return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  // Template utilities — retained for future screen colour decisions.
  // ignore: unused_element
  static Color saturate(Color c, double amount) {
    final h = _hsl(c);
    return h.withSaturation((h.saturation + amount).clamp(0.0, 1.0)).toColor();
  }

  // ignore: unused_element
  static Color desaturate(Color c, double amount) {
    final h = _hsl(c);
    return h.withSaturation((h.saturation - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color rotateHue(Color c, double degrees) {
    final h = _hsl(c);
    return h.withHue((h.hue + degrees) % 360.0).toColor();
  }

  static Color fromHSL(double hue, double sat, double light) {
    return HSLColor.fromAHSL(1.0, hue, sat, light).toColor();
  }

  // Flutter 3.27+: .r/.g/.b/.a return double 0.0–1.0.
  static Color mix(Color a, Color b, double t) {
    int ch(double av, double bv) =>
        ((av + (bv - av) * t) * 255.0).round().clamp(0, 255);
    return Color.fromARGB(ch(a.a, b.a), ch(a.r, b.r), ch(a.g, b.g), ch(a.b, b.b));
  }

  // WCAG linearisation — .r/.g/.b are already 0.0–1.0, no division needed.
  static double _luminance(Color c) {
    double lin(double s) =>
        s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  static double contrastRatio(Color fg, Color bg) {
    final l1 = _luminance(fg);
    final l2 = _luminance(bg);
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  static Color onColor(Color bg) {
    final darkText      = mix(darken(bg, 0.65), const Color(0xFF000000), 0.55);
    final whiteContrast = contrastRatio(const Color(0xFFFFFFFF), bg);
    return whiteContrast >= 4.5 ? const Color(0xFFFFFFFF) : darkText;
  }

  // ── Dark mode background family ───────────────────────────────────────────

  static Color get darkBackground =>
      fromHSL(_hsl(BrandColors.primary).hue, _kDarkBackgroundSaturation, 0.050);

  static Color get darkBackgroundAlt =>
      fromHSL(_hsl(BrandColors.primary).hue, _kDarkBackgroundSaturation, 0.072);

  static Color get darkSurface =>
      fromHSL(_hsl(BrandColors.primary).hue, _kDarkBackgroundSaturation,
          0.050 + _kDarkSurfaceStep);

  static Color get darkSurfaceMid =>
      fromHSL(_hsl(BrandColors.primary).hue, _kDarkBackgroundSaturation,
          0.050 + _kDarkSurfaceStep * 2);

  static Color get darkSurfaceLit =>
      fromHSL(_hsl(BrandColors.primary).hue, _kDarkBackgroundSaturation,
          0.050 + _kDarkSurfaceStep * 3);

  // ── Accent variants ───────────────────────────────────────────────────────

  static Color get primaryLight => lighten(BrandColors.primary, 0.15);
  static Color get primaryDark  => darken(BrandColors.primary, 0.15);
  static Color get primaryDeep  => darken(BrandColors.primary, 0.30);

  static Color get secondaryLight => lighten(BrandColors.secondary, 0.15);
  static Color get secondaryDark  => darken(BrandColors.secondary, 0.15);

  static Color get tertiaryLight => lighten(BrandColors.tertiary, 0.15);
  static Color get tertiaryDark  => darken(BrandColors.tertiary, 0.15);

  // ── Light mode family ─────────────────────────────────────────────────────

  static Color get lightBackground =>
      fromHSL(_hsl(BrandColors.primary).hue, _kLightBackgroundSaturation, 0.970);

  static Color get lightSurface =>
      fromHSL(_hsl(BrandColors.primary).hue, _kLightBackgroundSaturation + 0.04,
          0.970 - _kLightSurfaceStep);

  static Color get lightSurfaceMid =>
      fromHSL(_hsl(BrandColors.primary).hue, _kLightBackgroundSaturation + 0.07,
          0.970 - _kLightSurfaceStep * 2);

  static Color get lightPrimary {
    Color c = BrandColors.primary;
    for (int i = 0; i < 30; i++) {
      if (contrastRatio(c, lightBackground) >= 4.5) return c;
      c = darken(c, 0.02);
    }
    return c;
  }

  // ── Gradient color lists ───────────────────────────────────────────────────

  static List<Color> get buttonColors => [
    BrandColors.primary,
    darken(rotateHue(BrandColors.primary, _kGradientHueShift), 0.12),
  ];

  static List<Color> get buttonHoverColors => [
    lighten(rotateHue(BrandColors.primary, -_kGradientHueShift * 0.5), 0.12),
    BrandColors.primary,
  ];

  static List<Color> get heroColors => [
    primaryLight, BrandColors.primary, darkBackground,
  ];

  static List<Color> get surfaceColors => [darkSurfaceLit, darkSurface];

  static List<Color> get secondaryButtonColors => [
    BrandColors.secondary,
    darken(rotateHue(BrandColors.secondary, _kGradientHueShift), 0.12),
  ];
}


// ─────────────────────────────────────────────────────────────────────────────
// APP COLORS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {

  static Color get background    => _Engine.darkBackground;
  static Color get backgroundAlt => _Engine.darkBackgroundAlt;

  static Color get surface       => _Engine.darkSurface;
  static Color get surfaceMid    => _Engine.darkSurfaceMid;
  static Color get surfaceLit    => _Engine.darkSurfaceLit;

  static Color get primary      => BrandColors.primary;
  static Color get primaryLight => _Engine.primaryLight;
  static Color get primaryDark  => _Engine.primaryDark;
  static Color get primaryDeep  => _Engine.primaryDeep;

  static Color get secondary      => BrandColors.secondary;
  static Color get secondaryLight => _Engine.secondaryLight;
  static Color get secondaryDark  => _Engine.secondaryDark;

  static Color get tertiary      => BrandColors.tertiary;
  static Color get tertiaryLight => _Engine.tertiaryLight;
  static Color get tertiaryDark  => _Engine.tertiaryDark;

  static Color get lightBackground => _Engine.lightBackground;
  static Color get lightSurface    => _Engine.lightSurface;
  static Color get lightSurfaceMid => _Engine.lightSurfaceMid;
  static Color get lightPrimary    => _Engine.lightPrimary;

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x8AFFFFFF);
  static const Color textMuted     = Color(0x3DFFFFFF);
  static const Color textHint      = Color(0x61FFFFFF);

  static Color get lightTextPrimary   => _Engine.darken(BrandColors.primary, 0.62);
  static Color get lightTextSecondary => _Engine.mix(
    lightTextPrimary, const Color(0xFF888888), 0.5,
  );

  static Color get onPrimary   => _Engine.onColor(BrandColors.primary);
  static Color get onSecondary => _Engine.onColor(BrandColors.secondary);
  static Color get onTertiary  => _Engine.onColor(BrandColors.tertiary);

  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error   = Color(0xFFFF5252);
  static const Color info    = Color(0xFF40C4FF);

  static Color get live => BrandColors.tertiary;

  static const Color border        = Color(0x1FFFFFFF);
  static const Color borderStrong  = Color(0x33FFFFFF);
  static Color get borderFocused   => BrandColors.primary;
  static const Color borderError   = Color(0xFFFF5252);

  static const Color scrim       = Color(0xCC000000);
  static const Color transparent = Color(0x00000000);

  static Color tint10(Color c) => c.withValues(alpha: 0.10);
  static Color tint20(Color c) => c.withValues(alpha: 0.20);
  static Color tint30(Color c) => c.withValues(alpha: 0.30);
}


// ─────────────────────────────────────────────────────────────────────────────
// APP GRADIENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppGradients {

  static LinearGradient get primary => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: _Engine.heroColors, stops: const [0.0, 0.35, 1.0],
  );

  static LinearGradient get button => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: _Engine.buttonColors,
  );

  static LinearGradient get buttonHover => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: _Engine.buttonHoverColors,
  );

  static LinearGradient get secondary => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: _Engine.secondaryButtonColors,
  );

  static LinearGradient get avatar => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primaryDark],
  );

  static LinearGradient get surface => LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: _Engine.surfaceColors,
  );

  static RadialGradient get meshPrimary => RadialGradient(
    center: const Alignment(-0.65, -0.35), radius: 1.3,
    colors: [AppColors.primary.withValues(alpha: 0.18), Colors.transparent],
  );

  static RadialGradient get meshSecondary => RadialGradient(
    center: const Alignment(0.75, 0.55), radius: 1.0,
    colors: [AppColors.secondary.withValues(alpha: 0.09), Colors.transparent],
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// APP SPACING
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppSpacing {
  static double get xs   => _kSpacingBase * 1;
  static double get sm   => _kSpacingBase * 2;
  static double get md   => _kSpacingBase * 4;
  static double get lg   => _kSpacingBase * 6;
  static double get xl   => _kSpacingBase * 8;
  static double get xxl  => _kSpacingBase * 12;
  static double get xxxl => _kSpacingBase * 16;

  static EdgeInsets get pagePadding  => EdgeInsets.symmetric(horizontal: md, vertical: lg);
  static EdgeInsets get cardPadding  => EdgeInsets.all(md);
  static EdgeInsets get inputPadding => EdgeInsets.symmetric(horizontal: md, vertical: sm + 4);
  static EdgeInsets get chipPadding  => EdgeInsets.symmetric(horizontal: sm, vertical: xs - 1);
  static EdgeInsets get listTilePad  => EdgeInsets.symmetric(horizontal: md, vertical: sm);
}


// ─────────────────────────────────────────────────────────────────────────────
// APP RADIUS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppRadius {
  static double get xs    => _kSpacingBase;
  static double get sm    => _kSpacingBase * 2;
  static double get input => _kRadiusInput;
  static double get card  => _kRadiusCard;
  static double get modal => _kRadiusModal;
  static double get pill  => _kRadiusPill;

  static BorderRadius get inputBR    => BorderRadius.circular(input);
  static BorderRadius get cardBR     => BorderRadius.circular(card);
  static BorderRadius get modalBR    => BorderRadius.circular(modal);
  static BorderRadius get pillBR     => BorderRadius.circular(pill);
  static BorderRadius get modalTopBR => BorderRadius.vertical(top: Radius.circular(modal));
}


// ─────────────────────────────────────────────────────────────────────────────
// APP DURATIONS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppDurations {
  static const Duration fast    = Duration(milliseconds: 150);
  static const Duration normal  = Duration(milliseconds: 280);
  static const Duration slow    = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 60);
}


// ─────────────────────────────────────────────────────────────────────────────
// APP TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────
//
// Each text style is explicitly assigned a font role from BrandCopy.
// Swap a font in app_branding.dart's CONFIG BLOCK — every style using that
// role updates automatically. Nothing changes here.
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ FONT ROLE → TEXT STYLES ASSIGNED                                        │
// │                                                                         │
// │ fontHero      → brandBold, brandLight                                   │
// │                 The typographic brand identity. Used when the app       │
// │                 introduces itself — splash, marketing moments.           │
// │                                                                         │
// │ fontDisplay   → h1, h2, h3, h4, h5                                     │
// │                 Page/section structure. Every screen heading.           │
// │                                                                         │
// │ fontText      → bodyLarge, body, bodySmall, button, buttonSm,           │
// │                 input, inputLabel, helper                               │
// │                 The workhorse — anything the user reads or interacts    │
// │                 with at length. Should be the most readable font.       │
// │                                                                         │
// │ fontAccent    → caption, overline, chip, badge                          │
// │                 Data precision layer. Small labels, numbers, metadata,  │
// │                 status indicators. Adds contrast vs body copy.          │
// │                                                                         │
// │ fontSignature → signature                                               │
// │                 Emotional layer. NOT a system style — call it only for  │
// │                 greetings, milestones, encouragement, empty states.      │
// │                 Target <3% of visible UI text. Overuse kills the effect. │
// └─────────────────────────────────────────────────────────────────────────┘

abstract class AppTypography {

  // ── Hero role — brand identity moments ────────────────────────────────────
  // These styles carry the brand's visual signature. Use for splash screens,
  // the app's "face" moments, and large marketing statements. Not for UI chrome.
  static TextStyle get brandBold  => _f(FontWeight.w700, 36, font: BrandCopy.fontHero, ls: -1.5);
  static TextStyle get brandLight => _f(FontWeight.w300, 36, font: BrandCopy.fontHero, ls: -1.5,
    color: AppColors.textSecondary);

  // ── Display role — app structure and hierarchy ─────────────────────────────
  // Page titles, section headers, modal titles, card headers. These define the
  // visual skeleton of each screen. Should be confident and legible at a glance.
  static TextStyle get h1 => _f(FontWeight.w700, 28, font: BrandCopy.fontDisplay, ls: -0.5);
  static TextStyle get h2 => _f(FontWeight.w700, 22, font: BrandCopy.fontDisplay, ls: -0.3);
  static TextStyle get h3 => _f(FontWeight.w600, 18, font: BrandCopy.fontDisplay);
  static TextStyle get h4 => _f(FontWeight.w600, 15, font: BrandCopy.fontDisplay);
  static TextStyle get h5 => _f(FontWeight.w600, 13, font: BrandCopy.fontDisplay);

  // ── Text role — the workhorse, everything the user lives in ───────────────
  // Body copy, forms, buttons, inputs. Should be the most readable font in
  // the set. If this font changes, it reshapes the feel of the entire app.
  static TextStyle get bodyLarge => _f(FontWeight.w400, 16, font: BrandCopy.fontText, h: 1.6);
  static TextStyle get body      => _f(FontWeight.w400, 14, font: BrandCopy.fontText, h: 1.6);
  static TextStyle get bodySmall => _f(FontWeight.w300, 13, font: BrandCopy.fontText, h: 1.5,
    color: AppColors.textSecondary);

  static TextStyle get button   => _f(FontWeight.w700, 15, font: BrandCopy.fontText, ls: 0.3,
    color: AppColors.onPrimary);
  static TextStyle get buttonSm => _f(FontWeight.w700, 13, font: BrandCopy.fontText, ls: 0.3,
    color: AppColors.onPrimary);
  static TextStyle get input      => _f(FontWeight.w400, 14, font: BrandCopy.fontText);
  static TextStyle get inputLabel => _f(FontWeight.w300, 13, font: BrandCopy.fontText,
    color: AppColors.textSecondary);
  static TextStyle get helper     => _f(FontWeight.w300, 12, font: BrandCopy.fontText,
    color: AppColors.textSecondary);

  // ── Accent role — data precision layer ────────────────────────────────────
  // Small labels, metadata, timestamps, tags, stats, status badges. The Accent
  // font should feel slightly different from Text — tighter, sharper, or more
  // technical — so it reads as "system info" rather than "narrative content".
  static TextStyle get caption  => _f(FontWeight.w300, 11, font: BrandCopy.fontAccent,
    color: AppColors.textMuted);
  static TextStyle get overline => _f(FontWeight.w700, 10, font: BrandCopy.fontAccent, ls: 2.5,
    color: AppColors.textMuted);
  static TextStyle get chip     => _f(FontWeight.w600, 10, font: BrandCopy.fontAccent,
    color: AppColors.primary);
  static TextStyle get badge    => _f(FontWeight.w700, 9, font: BrandCopy.fontAccent, ls: 0.5);

  // ── Signature role — emotional moments only ───────────────────────────────
  // Greetings, milestone unlocks, encouragement text, warm empty states.
  // This style should appear rarely — target <3% of visible UI text.
  // Call it explicitly at the specific emotional moment; never use it as a
  // default or body replacement. Overuse destroys the effect entirely.
  //
  // Example call sites:
  //   "Welcome back, Alex 👋"       → onboarding greeting
  //   "You crushed it today"        → workout completion
  //   "Nothing here yet…"           → warm empty state
  //   "Goal reached. Keep going."   → milestone unlock
  static TextStyle get signature => _f(FontWeight.w400, 18, font: BrandCopy.fontSignature, h: 1.5,
    color: AppColors.textSecondary);

  // _f — the internal style builder.
  // font defaults to fontText — the system workhorse. Override per style above.
  static TextStyle _f(
    FontWeight w,
    double size, {
    String? font,
    double? ls,
    double? h,
    Color? color,
  }) =>
      GoogleFonts.getFont(
        font ?? BrandCopy.fontText,
        fontWeight:    w,
        fontSize:      size,
        letterSpacing: ls,
        height:        h,
        color:         color ?? AppColors.textPrimary,
      );
}


// ─────────────────────────────────────────────────────────────────────────────
// APP THEME — ThemeData (dark + light)
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {

  // ── DARK ──────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    return ThemeData.dark(useMaterial3: true).copyWith(
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        brightness:              Brightness.dark,
        primary:                 AppColors.primary,
        onPrimary:               AppColors.onPrimary,
        primaryContainer:        AppColors.primaryDeep,
        onPrimaryContainer:      AppColors.primaryLight,
        secondary:               AppColors.secondary,
        onSecondary:             AppColors.onSecondary,
        secondaryContainer:      AppColors.surfaceLit,
        onSecondaryContainer:    AppColors.textPrimary,
        tertiary:                AppColors.tertiary,
        onTertiary:              AppColors.onTertiary,
        error:                   AppColors.error,
        onError:                 Colors.white,
        surface:                 AppColors.surface,
        onSurface:               AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceLit,
        outline:                 AppColors.border,
        outlineVariant:          AppColors.borderStrong,
        scrim:                   AppColors.scrim,
        shadow:                  AppColors.background,
      ),

      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: AppBarTheme(
        backgroundColor:        AppColors.background,
        foregroundColor:        AppColors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            false,
        systemOverlayStyle:     SystemUiOverlayStyle.light,
        titleTextStyle:         AppTypography.h3,
        iconTheme:              const IconThemeData(color: Colors.white),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      AppColors.surface,
        selectedItemColor:    AppColors.primary,
        unselectedItemColor:  AppColors.textMuted,
        elevation:            0,
        type:                 BottomNavigationBarType.fixed,
        selectedLabelStyle:   AppTypography.chip,
        unselectedLabelStyle: AppTypography.caption,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor:  AppColors.tint20(AppColors.primary),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppTypography.chip.copyWith(color: AppColors.primary)
              : AppTypography.caption,
        ),
      ),

      cardTheme: CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        margin:    EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBR,
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation:       0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 7,
          ),
          shape:       RoundedRectangleBorder(borderRadius: AppRadius.pillBR),
          textStyle:   AppTypography.button,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side:            BorderSide(color: AppColors.primary, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 7,
          ),
          shape:       RoundedRectangleBorder(borderRadius: AppRadius.pillBR),
          textStyle:   AppTypography.button.copyWith(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:       AppTypography.bodySmall.copyWith(color: AppColors.primary),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:             true,
        fillColor:          AppColors.surface,
        contentPadding:     AppSpacing.inputPadding,
        labelStyle:         AppTypography.inputLabel,
        floatingLabelStyle: AppTypography.inputLabel.copyWith(color: AppColors.primary),
        hintStyle:          AppTypography.input.copyWith(color: AppColors.textHint),
        errorStyle:         AppTypography.helper.copyWith(color: AppColors.error),
        helperStyle:        AppTypography.helper,
        prefixIconColor:    AppColors.textMuted,
        suffixIconColor:    AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.borderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: Color(0xFFFF5252)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tint10(AppColors.primary),
        selectedColor:   AppColors.tint20(AppColors.primary),
        labelStyle:      AppTypography.chip,
        side:            BorderSide(color: AppColors.tint20(AppColors.primary)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: AppSpacing.chipPadding,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 1, space: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:  AppColors.surfaceLit,
        elevation:        0,
        shape:            RoundedRectangleBorder(borderRadius: AppRadius.modalBR),
        titleTextStyle:   AppTypography.h3,
        contentTextStyle: AppTypography.body,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:      AppColors.surfaceMid,
        modalBackgroundColor: AppColors.surfaceMid,
        elevation:            0,
        shape:                RoundedRectangleBorder(borderRadius: AppRadius.modalTopBR),
        dragHandleColor:      AppColors.borderStrong,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.surfaceLit,
        contentTextStyle: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        behavior:         SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        actionTextColor: AppColors.primary,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:              AppColors.primary,
        linearTrackColor:   AppColors.surface,
        circularTrackColor: AppColors.surface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.tint20(AppColors.primary)
              : AppColors.surface,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor:        AppColors.primary,
        inactiveTrackColor:      AppColors.surface,
        thumbColor:              AppColors.primary,
        overlayColor:            AppColors.tint10(AppColors.primary),
        valueIndicatorColor:     AppColors.primary,
        valueIndicatorTextStyle: AppTypography.badge.copyWith(color: AppColors.onPrimary),
      ),

      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        selectedTileColor: AppColors.tint10(AppColors.primary),
        iconColor:         AppColors.textMuted,
        textColor:         AppColors.textPrimary,
        subtitleTextStyle: AppTypography.bodySmall,
        titleTextStyle:    AppTypography.body,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBR),
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),

      tabBarTheme: TabBarThemeData(
        labelColor:           AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:           AppTypography.chip.copyWith(fontSize: 13),
        unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 13),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor:  AppColors.border,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation:       0,
        shape:           const CircleBorder(),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor:       AppColors.surfaceMid,
        headerBackgroundColor: AppColors.surface,
        headerForegroundColor: AppColors.textPrimary,
        dayStyle:              AppTypography.bodySmall,
        todayBorder:           BorderSide(color: AppColors.primary),
        todayForegroundColor:  WidgetStateProperty.all(AppColors.primary),
        dayForegroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.textPrimary,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modalBR),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceMid,
        hourMinuteColor: WidgetStateColor.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.tint20(AppColors.primary)
              : AppColors.surface,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textPrimary,
        ),
        dialHandColor:       AppColors.primary,
        dialBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modalBR),
      ),

      // fontText as base — the copyWith() below overrides most styles with the
      // correct font role per style. Anything not overridden gets fontText,
      // which is correct (it's the system workhorse default).
      textTheme: GoogleFonts.getTextTheme(
        BrandCopy.fontText,
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge:   AppTypography.h1.copyWith(fontSize: 32),
        displayMedium:  AppTypography.h1,
        displaySmall:   AppTypography.h2,
        headlineLarge:  AppTypography.h2,
        headlineMedium: AppTypography.h3,
        headlineSmall:  AppTypography.h4,
        titleLarge:     AppTypography.h4,
        titleMedium:    AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        titleSmall:     AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        bodyLarge:      AppTypography.bodyLarge,
        bodyMedium:     AppTypography.body,
        bodySmall:      AppTypography.bodySmall,
        labelLarge:     AppTypography.button,
        labelMedium:    AppTypography.chip,
        labelSmall:     AppTypography.caption,
      ),
    );
  }

  // ── LIGHT ─────────────────────────────────────────────────────────────────

  static ThemeData get light {
    return ThemeData.light(useMaterial3: true).copyWith(
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        brightness:  Brightness.light,
        primary:     AppColors.lightPrimary,
        onPrimary:   _Engine.onColor(AppColors.lightPrimary),
        secondary:   AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary:    AppColors.tertiary,
        onTertiary:  AppColors.onTertiary,
        surface:     AppColors.lightBackground,
        onSurface:   AppColors.lightTextPrimary,
        error:       AppColors.error,
        onError:     Colors.white,
        outline:     AppColors.lightSurfaceMid,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      appBarTheme: AppBarTheme(
        backgroundColor:    AppColors.lightBackground,
        foregroundColor:    AppColors.lightTextPrimary,
        elevation:          0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle:     AppTypography.h3.copyWith(color: AppColors.lightTextPrimary),
        iconTheme:          IconThemeData(color: AppColors.lightTextPrimary),
      ),

      cardTheme: CardThemeData(
        color:     AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBR,
          side:         BorderSide(color: AppColors.lightSurfaceMid),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: _Engine.onColor(AppColors.lightPrimary),
          elevation:       0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 7,
          ),
          shape:       RoundedRectangleBorder(borderRadius: AppRadius.pillBR),
          textStyle:   AppTypography.button.copyWith(
            color: _Engine.onColor(AppColors.lightPrimary),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side:            BorderSide(color: AppColors.lightPrimary, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 7,
          ),
          shape:       RoundedRectangleBorder(borderRadius: AppRadius.pillBR),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:             true,
        fillColor:          AppColors.lightSurface,
        contentPadding:     AppSpacing.inputPadding,
        labelStyle:         AppTypography.inputLabel.copyWith(color: AppColors.lightTextSecondary),
        floatingLabelStyle: AppTypography.inputLabel.copyWith(color: AppColors.lightPrimary),
        hintStyle:          AppTypography.input.copyWith(color: AppColors.lightTextSecondary),
        errorStyle:         AppTypography.helper.copyWith(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.lightSurfaceMid),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.lightSurfaceMid),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: Color(0xFFFF5252)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.lightSurfaceMid, thickness: 1, space: 0,
      ),

      iconTheme: IconThemeData(color: AppColors.lightTextSecondary, size: 22),

      textTheme: GoogleFonts.getTextTheme(
        BrandCopy.fontText,
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge:   AppTypography.h1.copyWith(fontSize: 32, color: AppColors.lightTextPrimary),
        displayMedium:  AppTypography.h1.copyWith(color: AppColors.lightTextPrimary),
        headlineLarge:  AppTypography.h2.copyWith(color: AppColors.lightTextPrimary),
        headlineMedium: AppTypography.h3.copyWith(color: AppColors.lightTextPrimary),
        headlineSmall:  AppTypography.h4.copyWith(color: AppColors.lightTextPrimary),
        bodyLarge:      AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
        bodyMedium:     AppTypography.body.copyWith(color: AppColors.lightTextPrimary),
        bodySmall:      AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
        labelLarge:     AppTypography.button,
        labelMedium:    AppTypography.chip.copyWith(color: AppColors.lightPrimary),
        labelSmall:     AppTypography.caption.copyWith(color: AppColors.lightTextSecondary),
      ),
    );
  }
}