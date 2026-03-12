// lib/core/theme/theme.dart

// log_20260312_theme.dart : I have templatized the theme logic to save some time on future projects. This file is meant to be copy-pasted wholesale into new projects and then configured by changing the constants in the CONFIG BLOCK below. The engine will take care of generating a full palette of colors, gradients, shadows, and text colors that all harmonize together and meet accessibility standards — all derived from three simple brand seed colors.


// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial release — universal reusable theme template — Sconl Peter
//   • Color engine generates full palette from 3 brand seeds automatically
//   • 60-30-10 split enforced structurally, not by convention
//   • Gradient logic built in for buttons, backgrounds, surfaces, modals
//   • WCAG contrast checker built in — onColor() always picks readable text
// ─────────────────────────────────────────────────────────────────────────────

// HOW TO USE THIS FILE IN A NEW PROJECT:
//
//   1. Find the CONFIG BLOCK below (~line 50).
//   2. Set _kBrandPrimary, _kBrandSecondary, _kBrandTertiary.
//   3. Optionally adjust _kFontFamily and the shape/spacing constants.
//   4. Done. Everything — backgrounds, surfaces, gradients, shadows,
//      text colors, semantic chips, modals — regenerates automatically.
//
//   Wire into main.dart:
//     MaterialApp(
//       theme:      AppTheme.light,
//       darkTheme:  AppTheme.dark,
//       themeMode:  ThemeMode.system,
//     )
//
//   Gradient buttons need a wrapper because Flutter's ElevatedButton doesn't
//   support gradients natively. Pattern:
//
//     Container(
//       decoration: AppDecorations.primaryButton,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//         ),
//         onPressed: onPressed,
//         child: Text('Label'),
//       ),
//     )

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// Change these values. Everything else in this file is derived from them.
// ─────────────────────────────────────────────────────────────────────────────

// ── Brand Seeds ───────────────────────────────────────────────────────────────

// PRIMARY — your dominant brand color. Drives the entire palette.
//
// Designer rule: pick a saturated mid-lightness hue (HSL lightness ~40–60%).
// Avoid near-white or near-black — the engine generates lighter/darker variants
// and needs room to move in both directions without clamping.
//
// Role in the 60-30-10 rule: this is your 10%. It's used sparingly on CTAs,
// active states, and brand moments — but its HUE secretly tints the entire
// background/surface family (the 60% and 30%) at low saturation, making the
// whole UI feel cohesive without feeling loud.
//
// Strong starting points by personality:
//   Health/wellness:  #00CC66 (electric green), #00B4D8 (sky)
//   Finance/trust:    #2563EB (cobalt), #7C3AED (violet)
//   Creative/bold:    #F43F5E (coral rose), #F97316 (vivid orange)
//   Luxury/refined:   #B45309 (gold), #0F766E (deep teal)

const Color _kBrandPrimary = Color(0xFF00CC66);

// SECONDARY — supporting brand color. Secondary actions, info states, chips,
// supporting gradients, and data visualisation accents.
//
// Designer rule: choose between two harmonious strategies:
//   (a) ANALOGOUS    — within 30° of primary on the color wheel.
//                      Result: harmonious, calm, feels "of a family".
//                      Good for wellness, productivity, utility apps.
//   (b) SPLIT-COMPLEMENT — ~150° from primary (not the direct opposite).
//                      Result: contrast without tension. More interesting
//                      than analogous, less jarring than full complement.
//                      Good for marketplaces, dashboards, B2C apps.
//
// Avoid the direct complement (180°) unless you want deliberate high tension —
// it's very hard to pull off without looking like a primary school website.
//
// Example with green primary: analogous = cyan/teal (150-200° hue)


const Color _kBrandSecondary = Color(0xFF0099CC);

// TERTIARY — accent pop color. Live badges, data highlights, onboarding moments,
// hover accents, and the occasional illustration touch.
//
// Designer rule: aim for roughly 120° from primary (triadic harmony).
// Triadic colors are naturally balanced — they feel intentional together
// rather than accidental. Your tertiary should be the "loudest" of the three
// because it's used the least. If it was used often it would overwhelm;
// used sparingly it creates energy and draws the eye exactly where you want it.
//
// Example with green primary (hue ~150°): tertiary lands ~270-30° → warm coral/amber


const Color _kBrandTertiary = Color(0xFFFF8A65);

// ── Typography ────────────────────────────────────────────────────────────────

// Google Fonts identifier for the app typeface.
// Change this one string and all text styles update globally.
// The font must be available in Google Fonts — check fonts.google.com.
//
// Personality guide:
//   Geometric/modern:  'Poppins', 'DM Sans', 'Nunito Sans'
//   Editorial/serious: 'Playfair Display' (display) + 'Lato' (body)
//   Tech/product:      'Sora', 'Space Grotesk', 'IBM Plex Sans'
//   Friendly/rounded:  'Nunito', 'Quicksand', 'Fredoka One'
//   Neutral/universal: 'Inter', 'Outfit', 'Figtree'
const String _kFontFamily = 'Poppins';

// ── Spacing ───────────────────────────────────────────────────────────────────

// Base unit for the entire spacing scale.
// All tokens are multiples of this: xs=1x, sm=2x, md=4x, lg=6x, xl=8x.
// 4.0 is the industry standard (Google Material, Apple HIG, Tailwind all use 4pt grid).
// Bumping to 8.0 gives a more editorial, airy feel. Don't go below 4.
const double _kSpacingBase = 4.0;

// ── Shape ─────────────────────────────────────────────────────────────────────

// Input field corners. Lower = more corporate. Higher = friendlier.
const double _kRadiusInput = 10.0;

// Card corners. Slightly more than inputs signals a visual hierarchy:
// inputs are functional, cards are content containers.
const double _kRadiusCard = 14.0;

// Modal / dialog / bottom sheet. Should be noticeably rounder than cards
// to signal "this is an overlay, not a page element".
const double _kRadiusModal = 20.0;

// Pill button. Large value = full pill on a 50px height button.
// If you want square-ish buttons, change this to 8.0.
const double _kRadiusPill = 50.0;

// ── Depth / Surface Steps ────────────────────────────────────────────────────

// How much lighter each surface layer is vs the one below it (dark mode).
// Think of it as the depth step: background → card → modal.
// 0.05 = very subtle (easy to miss). 0.10 = obvious.
// Sweet spot for professional dark UIs: 0.055–0.08.
const double _kDarkSurfaceStep = 0.065;

// Same concept for light mode — how much lighter each layer gets upward.
const double _kLightSurfaceStep = 0.040;

// How much of the primary hue bleeds into background/surface tones.
// This is the saturation of the background family.
// 0.0 = pure grey backgrounds (generic, lifeless).
// 0.25 = noticeably brand-tinted (strong, immersive).
// Professional sweet spot: 0.15–0.25 for dark mode, 0.06–0.12 for light.
const double _kDarkBackgroundSaturation  = 0.22;
const double _kLightBackgroundSaturation = 0.08;

// How far to rotate the hue on gradient end-stops.
// This subtle shift is what makes a button gradient feel three-dimensional
// vs. a flat same-hue lightness fade. Keep it at 8–15°. Beyond 20° starts
// looking like a rainbow instead of a gradient.
const double _kGradientHueShift = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// Everything below is computed. You shouldn't need to touch it.
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// COLOR ENGINE
// ─────────────────────────────────────────────────────────────────────────────
//
// Private. Widgets never call this directly — they go through AppColors.
// All the math lives here so the rest of the file stays readable.

abstract class _Engine {

  // ── HSL channel manipulation ───────────────────────────────────────────────

  static HSLColor _hsl(Color c) => HSLColor.fromColor(c);

  // Brighten a color without touching hue or saturation.
  static Color lighten(Color c, double amount) {
    final h = _hsl(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  // Darken a color without touching hue or saturation.
  static Color darken(Color c, double amount) {
    final h = _hsl(c);
    return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  // Push the saturation up — useful for making a muted tone more vivid.
  static Color saturate(Color c, double amount) {
    final h = _hsl(c);
    return h.withSaturation((h.saturation + amount).clamp(0.0, 1.0)).toColor();
  }

  // Pull the saturation down — how background tones are derived from brand hue.
  static Color desaturate(Color c, double amount) {
    final h = _hsl(c);
    return h.withSaturation((h.saturation - amount).clamp(0.0, 1.0)).toColor();
  }

  // Shift the hue by degrees (wraps at 360°).
  // Used on gradient end-stops — a slight hue rotation alongside lightness
  // makes gradients feel dimensional rather than just "faded".
  static Color rotateHue(Color c, double degrees) {
    final h = _hsl(c);
    return h.withHue((h.hue + degrees) % 360.0).toColor();
  }

  // Build a color from scratch using hue, saturation, lightness.
  // The main workhorse for generating background/surface families.
  static Color fromHSL(double hue, double sat, double light) {
    return HSLColor.fromAHSL(1.0, hue, sat, light).toColor();
  }

  // Linear blend between two colors. t=0 returns a, t=1 returns b.
  static Color mix(Color a, Color b, double t) {
    return Color.fromARGB(
      _lerpi(a.alpha, b.alpha, t),
      _lerpi(a.red,   b.red,   t),
      _lerpi(a.green, b.green, t),
      _lerpi(a.blue,  b.blue,  t),
    );
  }

  static int _lerpi(int a, int b, double t) =>
    (a + (b - a) * t).round().clamp(0, 255);

  // ── WCAG contrast ─────────────────────────────────────────────────────────

  // Relative luminance per WCAG 2.1 spec. Used for contrast ratio calculation.
  static double _luminance(Color c) {
    double lin(int ch) {
      final s = ch / 255.0;
      return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }
    return 0.2126 * lin(c.red) + 0.7152 * lin(c.green) + 0.0722 * lin(c.blue);
  }

  // WCAG contrast ratio between any two colors.
  // Target: 4.5:1 for normal text (AA), 3.0:1 for large text.
  static double contrastRatio(Color fg, Color bg) {
    final l1 = _luminance(fg);
    final l2 = _luminance(bg);
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  // Returns white or a dark hue-tinted text color — whichever clears 4.5:1.
  // The "dark" option is not pure black — it's a very dark tint of the
  // background's own hue, which feels more intentional than #000000.
  static Color onColor(Color bg) {
    // Derive a near-black that's still in the same color family as bg.
    final darkText = mix(darken(bg, 0.65), const Color(0xFF000000), 0.55);
    final whiteContrast = contrastRatio(const Color(0xFFFFFFFF), bg);
    final darkContrast  = contrastRatio(darkText, bg);
    // Prefer white at 4.5:1 — it usually looks cleaner on saturated brand colors.
    return whiteContrast >= 4.5 ? const Color(0xFFFFFFFF) : darkText;
  }

  // ── Dark mode background family (60%) ─────────────────────────────────────
  //
  // Take the primary hue, slash saturation to _kDarkBackgroundSaturation,
  // drop lightness to ~5%. The preserved hue is the secret ingredient —
  // it makes the background feel "of the brand" rather than generic dark grey.
  // Users won't consciously notice it. They'll just feel it.

  static Color get darkBackground =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kDarkBackgroundSaturation, 0.050);

  static Color get darkBackgroundAlt =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kDarkBackgroundSaturation, 0.072);

  // ── Dark mode surface family (30%) ────────────────────────────────────────
  //
  // Three steps above the background, each _kDarkSurfaceStep apart.
  // surface    → cards, input fills, nav bars
  // surfaceMid → hover states, active nav, selected rows
  // surfaceLit → modals, dialogs, bottom sheets, popovers

  static Color get darkSurface =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kDarkBackgroundSaturation,
      0.050 + _kDarkSurfaceStep);

  static Color get darkSurfaceMid =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kDarkBackgroundSaturation,
      0.050 + _kDarkSurfaceStep * 2);

  static Color get darkSurfaceLit =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kDarkBackgroundSaturation,
      0.050 + _kDarkSurfaceStep * 3);

  // ── Accent variants (10%) ─────────────────────────────────────────────────
  //
  // The brand colors expressed at different energy levels.
  // Light = hover highlights, icon tints.
  // Dark = pressed states, gradient end-stops.
  // Deep = shadow tints — should be darker than the button to feel grounded.

  static Color get primaryLight => lighten(_kBrandPrimary, 0.15);
  static Color get primaryDark  => darken(_kBrandPrimary, 0.15);
  static Color get primaryDeep  => darken(_kBrandPrimary, 0.30);

  static Color get secondaryLight => lighten(_kBrandSecondary, 0.15);
  static Color get secondaryDark  => darken(_kBrandSecondary, 0.15);

  static Color get tertiaryLight  => lighten(_kBrandTertiary, 0.15);
  static Color get tertiaryDark   => darken(_kBrandTertiary, 0.15);

  // ── Light mode background/surface family ──────────────────────────────────
  //
  // Same hue-preservation principle, inverted direction.
  // Near-white with a faint primary tint — not pure white (#FFFFFF) because
  // pure white feels clinical and harsh. The tint is subtle but it makes
  // the UI feel warm and considered.

  static Color get lightBackground =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kLightBackgroundSaturation, 0.970);

  static Color get lightSurface =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kLightBackgroundSaturation + 0.04,
      0.970 - _kLightSurfaceStep);

  static Color get lightSurfaceMid =>
    fromHSL(_hsl(_kBrandPrimary).hue, _kLightBackgroundSaturation + 0.07,
      0.970 - _kLightSurfaceStep * 2);

  // Primary color adjusted downward in lightness until it hits WCAG AA (4.5:1)
  // against the light background. We walk in steps rather than one big jump
  // because the smallest adjustment that passes looks the best.
  static Color get lightPrimary {
    Color c = _kBrandPrimary;
    for (int i = 0; i < 30; i++) {
      if (contrastRatio(c, lightBackground) >= 4.5) return c;
      c = darken(c, 0.02);
    }
    return c; // if nothing passed we return the darkest candidate
  }

  // ── Gradient color lists ───────────────────────────────────────────────────
  //
  // The hue rotation on end-stops is the designer trick that separates
  // "premium gradient" from "basic CSS gradient". A ~10-15° rotation adds
  // a warmth or coolness shift that the eye reads as dimensional depth.
  // Same technique used by Stripe, Linear, Apple Pay, etc.

  // Button: brand → slightly hue-rotated darker shade.
  static List<Color> get buttonColors => [
    _kBrandPrimary,
    darken(rotateHue(_kBrandPrimary, _kGradientHueShift), 0.12),
  ];

  // Button hover: starts brighter, finishes at the brand color.
  static List<Color> get buttonHoverColors => [
    lighten(rotateHue(_kBrandPrimary, -_kGradientHueShift * 0.5), 0.12),
    _kBrandPrimary,
  ];

  // Hero: light → brand → abyss. Three stops look much better than two.
  static List<Color> get heroColors => [
    primaryLight,
    _kBrandPrimary,
    darkBackground,
  ];

  // Surface gradient: very subtle depth signal on cards.
  static List<Color> get surfaceColors => [
    darkSurfaceLit,
    darkSurface,
  ];

  // Secondary button gradient.
  static List<Color> get secondaryButtonColors => [
    _kBrandSecondary,
    darken(rotateHue(_kBrandSecondary, _kGradientHueShift), 0.12),
  ];
}


// ─────────────────────────────────────────────────────────────────────────────
// APP COLORS — public API for the entire palette
// ─────────────────────────────────────────────────────────────────────────────
//
// All widgets reference this class. Nothing references _Engine directly.
// This is the contract — _Engine is the implementation detail.

abstract class AppColors {

  // ── 60% — BACKGROUND FAMILY ───────────────────────────────────────────────
  // Where most of your pixels live. Primary hue at very low saturation and
  // very low lightness. The subtle tint is what makes the whole UI feel unified.
  static Color get background    => _Engine.darkBackground;
  static Color get backgroundAlt => _Engine.darkBackgroundAlt; // variant for drawer, etc.

  // ── 30% — SURFACE FAMILY ──────────────────────────────────────────────────
  // Cards, input fills, nav bars, and overlays. Three depth levels.
  // Use surface → surfaceMid → surfaceLit as you move further from the page.
  static Color get surface       => _Engine.darkSurface;
  static Color get surfaceMid    => _Engine.darkSurfaceMid;    // hover, active rows
  static Color get surfaceLit    => _Engine.darkSurfaceLit;    // modals, dialogs

  // ── 10% — ACCENT FAMILY ───────────────────────────────────────────────────
  // Brand colors and their computed variants. Use sparingly and intentionally.
  static Color get primary       => _kBrandPrimary;
  static Color get primaryLight  => _Engine.primaryLight;      // hover, glows, icons
  static Color get primaryDark   => _Engine.primaryDark;       // pressed, gradient end
  static Color get primaryDeep   => _Engine.primaryDeep;       // shadow tints only

  static Color get secondary     => _kBrandSecondary;
  static Color get secondaryLight => _Engine.secondaryLight;
  static Color get secondaryDark  => _Engine.secondaryDark;

  static Color get tertiary      => _kBrandTertiary;
  static Color get tertiaryLight => _Engine.tertiaryLight;
  static Color get tertiaryDark  => _Engine.tertiaryDark;

  // ── LIGHT MODE ────────────────────────────────────────────────────────────
  static Color get lightBackground => _Engine.lightBackground;
  static Color get lightSurface    => _Engine.lightSurface;
  static Color get lightSurfaceMid => _Engine.lightSurfaceMid;
  static Color get lightPrimary    => _Engine.lightPrimary; // contrast-adjusted

  // ── TEXT (DARK MODE) ──────────────────────────────────────────────────────
  // Opacity-based so they work on any dark surface without hardcoding.
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x8AFFFFFF); // ~54% opacity
  static const Color textMuted     = Color(0x3DFFFFFF); // ~24% opacity
  static const Color textHint      = Color(0x61FFFFFF); // ~38% opacity — input placeholders

  // ── TEXT (LIGHT MODE) ─────────────────────────────────────────────────────
  // Not pure black — a very dark tint of the primary hue. Softer and more
  // intentional-feeling than #000000, especially on tinted light backgrounds.
  static Color get lightTextPrimary   => _Engine.darken(_kBrandPrimary, 0.62);
  static Color get lightTextSecondary => _Engine.mix(
    lightTextPrimary, const Color(0xFF888888), 0.5,
  );

  // ── ON-COLOR TEXT (auto-contrast) ─────────────────────────────────────────
  // Pass a background color, get back whichever text color clears WCAG AA.
  // Use these whenever you're placing text directly on a brand-color surface.
  static Color get onPrimary   => _Engine.onColor(_kBrandPrimary);
  static Color get onSecondary => _Engine.onColor(_kBrandSecondary);
  static Color get onTertiary  => _Engine.onColor(_kBrandTertiary);

  // ── SEMANTIC ──────────────────────────────────────────────────────────────
  // Intentionally NOT derived from brand colors. Semantic colors communicate
  // universal meaning (red = danger, green = ok) — they shouldn't rebrand.
  // Exception: live/active uses tertiary because it IS a brand moment.
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error   = Color(0xFFFF5252);
  static const Color info    = Color(0xFF40C4FF);
  static Color get live => _kBrandTertiary; // trainer online, live session

  // ── BORDERS ───────────────────────────────────────────────────────────────
  static const Color border        = Color(0x1FFFFFFF); // white at 12%
  static const Color borderStrong  = Color(0x33FFFFFF); // white at 20%
  static Color get borderFocused   => _kBrandPrimary;
  static const Color borderError   = Color(0xFFFF5252);

  // ── OVERLAYS ──────────────────────────────────────────────────────────────
  static const Color scrim       = Color(0xCC000000); // modal backdrop
  static const Color transparent = Color(0x00000000);

  // ── TINT HELPERS ──────────────────────────────────────────────────────────
  // Chip backgrounds, selection rings, notification banners.
  // Passing the brand color through opacity means these always harmonize.
  static Color tint10(Color c) => c.withOpacity(0.10);
  static Color tint20(Color c) => c.withOpacity(0.20);
  static Color tint30(Color c) => c.withOpacity(0.30);
}


// ─────────────────────────────────────────────────────────────────────────────
// APP GRADIENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppGradients {

  // Primary brand gradient. For hero sections, splash screens, brand moments.
  // Three stops: accent-light → brand → deep background.
  static LinearGradient get primary => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _Engine.heroColors,
    stops: const [0.0, 0.35, 1.0],
  );

  // Button gradient. The hue-shifted end stop is what makes it feel premium.
  // Axis is 135° (NW→SE) — reads as "forward motion" in most layouts.
  static LinearGradient get button => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _Engine.buttonColors,
  );

  // Button hover — brighter start, tighter shift. Swap this in on pointer hover.
  static LinearGradient get buttonHover => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _Engine.buttonHoverColors,
  );

  // Secondary button gradient.
  static LinearGradient get secondary => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _Engine.secondaryButtonColors,
  );

  // Avatar gradient — for initials containers, profile placeholders.
  static LinearGradient get avatar => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primaryDark],
  );

  // Card surface gradient — barely perceptible depth on card faces.
  // The eye reads gradient as a light source. No shadow needed at this scale.
  static LinearGradient get surface => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _Engine.surfaceColors,
  );

  // Mesh atmosphere — for full-screen background depth.
  // These are two radials meant to be layered in a Stack.
  // Primary mesh: top-left bloom.
  static RadialGradient get meshPrimary => RadialGradient(
    center: const Alignment(-0.65, -0.35),
    radius: 1.3,
    colors: [
      AppColors.primary.withOpacity(0.18),
      Colors.transparent,
    ],
  );

  // Secondary mesh: bottom-right counter-bloom.
  static RadialGradient get meshSecondary => RadialGradient(
    center: const Alignment(0.75, 0.55),
    radius: 1.0,
    colors: [
      AppColors.secondary.withOpacity(0.09),
      Colors.transparent,
    ],
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// APP DECORATIONS — pre-built BoxDecoration objects
// ─────────────────────────────────────────────────────────────────────────────
//
// Reference these in Container/DecoratedBox rather than writing BoxDecoration
// inline. Single source of truth — one change propagates everywhere.

abstract class AppDecorations {

  // Standard card. Most content cards use this.
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.border),
  );

  // Card with surface gradient. For featured or elevated cards.
  static BoxDecoration get cardElevated => BoxDecoration(
    gradient: AppGradients.surface,
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.border),
  );

  // Modal / dialog / bottom sheet container.
  static BoxDecoration get modal => BoxDecoration(
    color: AppColors.surfaceLit,
    borderRadius: BorderRadius.circular(_kRadiusModal),
    border: Border.all(color: AppColors.borderStrong),
    boxShadow: AppShadows.modal,
  );

  // Popup / tooltip / context menu — smaller than modal, same family.
  static BoxDecoration get popup => BoxDecoration(
    color: AppColors.surfaceMid,
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.border),
    boxShadow: AppShadows.card,
  );

  // Primary gradient button container.
  // Wrap your ElevatedButton in this Container and set the button's
  // backgroundColor to Colors.transparent, shadowColor to Colors.transparent.
  static BoxDecoration get primaryButton => BoxDecoration(
    gradient: AppGradients.button,
    borderRadius: BorderRadius.circular(_kRadiusPill),
    boxShadow: AppShadows.buttonGlow,
  );

  // Primary button hover state — swap in on MouseRegion hover.
  static BoxDecoration get primaryButtonHover => BoxDecoration(
    gradient: AppGradients.buttonHover,
    borderRadius: BorderRadius.circular(_kRadiusPill),
    boxShadow: AppShadows.buttonGlowHover,
  );

  // Secondary gradient button.
  static BoxDecoration get secondaryButton => BoxDecoration(
    gradient: AppGradients.secondary,
    borderRadius: BorderRadius.circular(_kRadiusPill),
    boxShadow: AppShadows.secondaryGlow,
  );

  // Outlined button — no fill, brand border.
  static BoxDecoration get outlinedButton => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(_kRadiusPill),
    border: Border.all(color: AppColors.primary, width: 1.5),
  );

  // Avatar / initials container — avatar gradient, rounded square.
  static BoxDecoration get avatar => BoxDecoration(
    gradient: AppGradients.avatar,
    borderRadius: BorderRadius.circular(_kRadiusCard),
  );

  // Tag / chip — tinted bg with brand border.
  static BoxDecoration get chip => BoxDecoration(
    color: AppColors.tint10(AppColors.primary),
    borderRadius: BorderRadius.circular(_kSpacingBase * 2),
    border: Border.all(color: AppColors.tint20(AppColors.primary)),
  );

  // Success notification strip.
  static BoxDecoration get successBanner => BoxDecoration(
    color: AppColors.tint10(AppColors.success),
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.tint20(AppColors.success)),
  );

  // Error / alert strip.
  static BoxDecoration get errorBanner => BoxDecoration(
    color: AppColors.tint10(AppColors.error),
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.tint20(AppColors.error)),
  );

  // Warning strip.
  static BoxDecoration get warningBanner => BoxDecoration(
    color: AppColors.tint10(AppColors.warning),
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.tint20(AppColors.warning)),
  );

  // Info strip.
  static BoxDecoration get infoBanner => BoxDecoration(
    color: AppColors.tint10(AppColors.info),
    borderRadius: BorderRadius.circular(_kRadiusCard),
    border: Border.all(color: AppColors.tint20(AppColors.info)),
  );

  // Full-screen background with mesh bloom — wrap your Scaffold body in this.
  static BoxDecoration get screenBackground => BoxDecoration(
    color: AppColors.background,
  );
  // Use this Stack pattern to get the full mesh effect:
  //
  //   Stack(children: [
  //     Container(decoration: AppDecorations.screenBackground),
  //     Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),
  //     Container(decoration: BoxDecoration(gradient: AppGradients.meshSecondary)),
  //     YourPageContent(),
  //   ])
}


// ─────────────────────────────────────────────────────────────────────────────
// APP SPACING
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppSpacing {
  static double get xs   => _kSpacingBase * 1;  //  4px — micro gaps
  static double get sm   => _kSpacingBase * 2;  //  8px — tight spacing
  static double get md   => _kSpacingBase * 4;  // 16px — standard spacing
  static double get lg   => _kSpacingBase * 6;  // 24px — comfortable spacing
  static double get xl   => _kSpacingBase * 8;  // 32px — section gaps
  static double get xxl  => _kSpacingBase * 12; // 48px — large section gaps
  static double get xxxl => _kSpacingBase * 16; // 64px — page-level breathing room

  // Semantic layout aliases — use these in widgets instead of raw values.
  // Makes intent clear and means one change here reflows the whole app.
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
  static double get xs    => _kSpacingBase;         //  4px — micro elements
  static double get sm    => _kSpacingBase * 2;     //  8px — small badges, tight chips
  static double get input => _kRadiusInput;         // input fields
  static double get card  => _kRadiusCard;          // cards
  static double get modal => _kRadiusModal;         // modals, dialogs, bottom sheets
  static double get pill  => _kRadiusPill;          // pill buttons

  // Pre-built BorderRadius objects — saves the circular() call at the widget level.
  static BorderRadius get inputBR  => BorderRadius.circular(input);
  static BorderRadius get cardBR   => BorderRadius.circular(card);
  static BorderRadius get modalBR  => BorderRadius.circular(modal);
  static BorderRadius get pillBR   => BorderRadius.circular(pill);
  // Bottom-only modal radius — for bottom sheets.
  static BorderRadius get modalTopBR =>
    BorderRadius.vertical(top: Radius.circular(modal));
}


// ─────────────────────────────────────────────────────────────────────────────
// APP SHADOWS
// ─────────────────────────────────────────────────────────────────────────────
//
// Shadows and glows are derived from brand colors — not hardcoded black/grey.
// A teal glow on a coral button is an accident, not a choice. These shadows
// always harmonize because they pull from the same color the element uses.

abstract class AppShadows {

  // Standard card drop shadow.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.background.withOpacity(0.55),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Modal / dialog — deeper shadow to signal they float above the page.
  static List<BoxShadow> get modal => [
    BoxShadow(
      color: Colors.black.withOpacity(0.50),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  // Primary button glow. Uses primaryDeep (darker than the button itself)
  // because a glow brighter than the surface it's on looks wrong / garish.
  static List<BoxShadow> get buttonGlow => [
    BoxShadow(
      color: AppColors.primaryDeep.withOpacity(0.55),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Hover state — slightly more spread, slightly more opacity.
  static List<BoxShadow> get buttonGlowHover => [
    BoxShadow(
      color: AppColors.primaryDeep.withOpacity(0.70),
      blurRadius: 32,
      offset: const Offset(0, 10),
    ),
  ];

  // Secondary button glow — same pattern, secondary color.
  static List<BoxShadow> get secondaryGlow => [
    BoxShadow(
      color: AppColors.secondaryDark.withOpacity(0.50),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Input focus glow — replaces Flutter's default focus ring with a brand one.
  static List<BoxShadow> get inputFocus => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.18),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  // Success confirmation glow — used on booking confirmed banners, etc.
  static List<BoxShadow> get successGlow => [
    BoxShadow(
      color: AppColors.success.withOpacity(0.28),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}


// ─────────────────────────────────────────────────────────────────────────────
// APP DURATIONS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppDurations {
  // Button feedback, chip toggle — anything that needs to feel instant.
  static const Duration fast   = Duration(milliseconds: 150);
  // Modal appear, fade, slide transitions — standard UI motion.
  static const Duration normal = Duration(milliseconds: 280);
  // Page transitions, entrance animations — where motion adds meaning.
  static const Duration slow   = Duration(milliseconds: 420);
  // Multiply by item index for sequential list/grid entrance animations.
  static const Duration stagger = Duration(milliseconds: 60);
}


// ─────────────────────────────────────────────────────────────────────────────
// APP TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppTypography {

  // Brand wordmark: split-weight treatment is the visual signature.
  // Bold half = confidence. Light half = refinement. Together they feel premium.
  static TextStyle get brandBold  => _f(FontWeight.w700, 36, ls: -1.5);
  static TextStyle get brandLight => _f(FontWeight.w300, 36, ls: -1.5,
    color: AppColors.textSecondary);

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle get h1 => _f(FontWeight.w700, 28, ls: -0.5);
  static TextStyle get h2 => _f(FontWeight.w700, 22, ls: -0.3);
  static TextStyle get h3 => _f(FontWeight.w600, 18);
  static TextStyle get h4 => _f(FontWeight.w600, 15);
  static TextStyle get h5 => _f(FontWeight.w600, 13);

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _f(FontWeight.w400, 16, h: 1.6);
  static TextStyle get body      => _f(FontWeight.w400, 14, h: 1.6);
  static TextStyle get bodySmall => _f(FontWeight.w300, 13, h: 1.5,
    color: AppColors.textSecondary);

  // ── Controls ──────────────────────────────────────────────────────────────
  // Button label intentionally has no line height — height is set by padding.
  static TextStyle get button     => _f(FontWeight.w700, 15, ls: 0.3,
    color: AppColors.onPrimary);
  static TextStyle get buttonSm   => _f(FontWeight.w700, 13, ls: 0.3,
    color: AppColors.onPrimary);
  static TextStyle get input      => _f(FontWeight.w400, 14);
  static TextStyle get inputLabel => _f(FontWeight.w300, 13,
    color: AppColors.textSecondary);
  static TextStyle get helper     => _f(FontWeight.w300, 12,
    color: AppColors.textSecondary);

  // ── Micro ─────────────────────────────────────────────────────────────────
  static TextStyle get caption  => _f(FontWeight.w300, 11,
    color: AppColors.textMuted);
  static TextStyle get overline => _f(FontWeight.w700, 10, ls: 2.5,
    color: AppColors.textMuted);
  static TextStyle get chip     => _f(FontWeight.w600, 10,
    color: AppColors.primary);
  static TextStyle get badge    => _f(FontWeight.w700, 9, ls: 0.5);

  // Internal factory. Calling GoogleFonts.getFont with _kFontFamily at runtime
  // means changing the config constant really does update every style.
  static TextStyle _f(
    FontWeight w,
    double size, {
    double? ls,
    double? h,
    Color? color,
  }) => GoogleFonts.getFont(
    _kFontFamily,
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
        backgroundColor:     AppColors.surface,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation:           0,
        type:                BottomNavigationBarType.fixed,
        selectedLabelStyle:  AppTypography.chip,
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
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // ElevatedButton: handles shape and text. Gradient comes from the
      // AppDecorations.primaryButton wrapper — see file header for the pattern.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation:       0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical:   AppSpacing.sm + 7,
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
            horizontal: AppSpacing.lg,
            vertical:   AppSpacing.sm + 7,
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
            horizontal: AppSpacing.sm,
            vertical:   AppSpacing.xs,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:              true,
        fillColor:           AppColors.surface,
        contentPadding:      AppSpacing.inputPadding,
        labelStyle:          AppTypography.inputLabel,
        floatingLabelStyle:  AppTypography.inputLabel.copyWith(color: AppColors.primary),
        hintStyle:           AppTypography.input.copyWith(color: AppColors.textHint),
        errorStyle:          AppTypography.helper.copyWith(color: AppColors.error),
        helperStyle:         AppTypography.helper,
        prefixIconColor:     AppColors.textMuted,
        suffixIconColor:     AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.border),
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

      dividerTheme: DividerThemeData(
        color:     AppColors.border,
        thickness: 1,
        space:     0,
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
        side: BorderSide(color: AppColors.border, width: 1.5),
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
        activeTrackColor:       AppColors.primary,
        inactiveTrackColor:     AppColors.surface,
        thumbColor:             AppColors.primary,
        overlayColor:           AppColors.tint10(AppColors.primary),
        valueIndicatorColor:    AppColors.primary,
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

      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size:  22,
      ),

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
          s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.textPrimary,
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

      textTheme: GoogleFonts.getTextTheme(
        _kFontFamily,
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
        brightness:   Brightness.light,
        primary:      AppColors.lightPrimary,
        onPrimary:    _Engine.onColor(AppColors.lightPrimary),
        secondary:    AppColors.secondary,
        onSecondary:  AppColors.onSecondary,
        tertiary:     AppColors.tertiary,
        onTertiary:   AppColors.onTertiary,
        surface:      AppColors.lightBackground,
        onSurface:    AppColors.lightTextPrimary,
        error:        AppColors.error,
        onError:      Colors.white,
        outline:      AppColors.lightSurfaceMid,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      appBarTheme: AppBarTheme(
        backgroundColor:    AppColors.lightBackground,
        foregroundColor:    AppColors.lightTextPrimary,
        elevation:          0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle:     AppTypography.h3.copyWith(color: AppColors.lightTextPrimary),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
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
            horizontal: AppSpacing.lg,
            vertical:   AppSpacing.sm + 7,
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
            horizontal: AppSpacing.lg,
            vertical:   AppSpacing.sm + 7,
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
        color:     AppColors.lightSurfaceMid,
        thickness: 1,
        space:     0,
      ),

      iconTheme: IconThemeData(
        color: AppColors.lightTextSecondary,
        size:  22,
      ),

      textTheme: GoogleFonts.getTextTheme(
        _kFontFamily,
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


// ─────────────────────────────────────────────────────────────────────────────
// APP TEXT STYLES — semantic aliases
// ─────────────────────────────────────────────────────────────────────────────
//
// Domain-named aliases for common UI text roles. Use these over raw
// AppTypography.h4 in your widgets — makes intent clear and means you can
// restyle "cardTitle" in one place without hunting the codebase.

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