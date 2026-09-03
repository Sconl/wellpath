// lib/spaces/space_site/screen_home/space_site_shared.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// SpaceSite — Shared UI Primitives
// ─────────────────────────────────────────────────────────────────────────────
// MOVED from: lib/spaces/space_site/space_site_shared.dart
// The widgets/ subfolder has been deleted; this file lives directly at
// the screen_home root alongside section_core/, section_context/, section_connect/.
//
// EXPORTS
//   SiteSectionHeader         — 4-part section opener (eyebrow/headline/subline)
//   SitePageHero              — reusable page hero with optional typing animation
//   PrimaryAttentionButton    — periodic gradient-border CTA (ai button effect)
//   SiteGradientButton        — standard gradient pill button
//   SiteOutlineButton         — standard outline pill button
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SiteSectionHeader
// ─────────────────────────────────────────────────────────────────────────────

class SiteSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String? subline;
  final double headlineFontSize;
  final double maxSublineWidth;
  final TextAlign alignment;

  const SiteSectionHeader({
    super.key,
    required this.eyebrow,
    required this.headline,
    this.subline,
    this.headlineFontSize = 32,
    this.maxSublineWidth  = 520,
    this.alignment        = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis = alignment == TextAlign.left
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    return Column(crossAxisAlignment: crossAxis, children: [
      Text(eyebrow.toUpperCase(), style: AppTypography.overline),
      SizedBox(height: AppSpacing.sm),
      Text(headline, textAlign: alignment,
          style: AppTypography.h2.copyWith(fontSize: headlineFontSize)),
      if (subline != null) ...[
        SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxSublineWidth),
          child: Text(subline!, textAlign: alignment,
              style: AppTypography.bodySmall.copyWith(height: 1.65)),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SitePageHero
// ─────────────────────────────────────────────────────────────────────────────
//
// Used by all marketing sub-pages (About, Features, Pricing) and also
// embedded inside SectionCoreHero for the landing page.
//
// PARAMETERS
//   showEyebrow   — render the eyebrow overline (default true).
//                   Set false when the parent already shows a badge pill.
//   showSubline   — render the subline paragraph (default true).
//                   Set false when the parent handles subline separately.
//   showAnimation — when false or typingConfig is null, shows staticHeadline.
//                   Controlled per-screen by AdminFeatureFlags.

class SitePageHero extends StatelessWidget {
  final String eyebrow;
  final String staticHeadline;
  final String subline;
  final TypingTextConfig? typingConfig;
  final bool showAnimation;
  final bool showEyebrow;
  final bool showSubline;
  final double maxSublineWidth;

  const SitePageHero({
    super.key,
    required this.eyebrow,
    required this.staticHeadline,
    required this.subline,
    this.typingConfig,
    this.showAnimation   = true,
    this.showEyebrow     = true,
    this.showSubline     = true,
    this.maxSublineWidth = 620,
  });

  @override
  Widget build(BuildContext context) {
    final useAnim = showAnimation && typingConfig != null;

    return Column(children: [
      if (showEyebrow) ...[
        Text(eyebrow.toUpperCase(), style: AppTypography.overline),
        SizedBox(height: AppSpacing.md),
      ],

      // Headline — animated or static
      if (useAnim)
        TypingHeadline(config: typingConfig!)
      else
        ShaderMask(
          shaderCallback: (b) => AppGradients.button.createShader(
            // DESCENDER FIX: extend bounds 16px so g, y, p, q get gradient color
            Rect.fromLTRB(b.left, b.top, b.right, b.bottom + 16),
          ),
          blendMode: BlendMode.srcIn,
          child: Text(
            staticHeadline,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(
              fontSize:   typingConfig?.fontSize ?? 44,
              height:     1.15,
              fontWeight: typingConfig?.fontWeight ?? FontWeight.w800,
              color:      AppColors.textPrimary,
            ),
          ),
        ),

      if (showSubline) ...[
        SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxSublineWidth),
          child: Text(
            subline,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
                height: 1.7, color: AppColors.textSecondary),
          ),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryAttentionButton
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryAttentionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final Duration triggerInterval;
  final double arcFraction;
  final Duration loopDuration;
  final Duration activeDuration;

  const PrimaryAttentionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.padding         = null,
    this.fontSize        = 15,
    this.triggerInterval = const Duration(seconds: 5),
    this.arcFraction     = 0.55,
    this.loopDuration    = const Duration(milliseconds: 1600),
    this.activeDuration  = const Duration(milliseconds: 2200),
  });

  @override
  Widget build(BuildContext context) {
    // Multi-color "AI button" gradient: primary → tertiary → secondary → back
    final attentionGradient = LinearGradient(colors: [
      AppColors.primary,
      AppColors.tertiary,
      AppColors.secondary,
      AppColors.primaryLight,
      AppColors.primary,
    ]);

    return AnimatedGradientBorder(
      isActive:         false,
      triggerMode:      BorderTriggerMode.periodic,
      triggerInterval:  triggerInterval,
      activeDuration:   activeDuration,
      loopDuration:     loopDuration,
      borderRadius:     AppRadius.pillBR,
      strokeWidth:      2.2,
      arcFraction:      arcFraction,
      gradient:         attentionGradient,
      showStaticBorder: false,
      child: SiteGradientButton(
        label:   label,
        onTap:   onTap,
        padding: padding,
        fontSize: fontSize,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SiteGradientButton
// ─────────────────────────────────────────────────────────────────────────────

class SiteGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  const SiteGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.padding,
    this.fontSize = 15,
  });

  @override
  State<SiteGradientButton> createState() => _SiteGradientButtonState();
}

class _SiteGradientButtonState extends State<SiteGradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final pad = widget.padding ??
        EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding:  pad,
          decoration: BoxDecoration(
            gradient:     _hovered ? AppGradients.buttonHover : AppGradients.button,
            borderRadius: AppRadius.pillBR,
            boxShadow:    _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
          ),
          child: Text(widget.label,
              style: AppTypography.button.copyWith(fontSize: widget.fontSize)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SiteOutlineButton
// ─────────────────────────────────────────────────────────────────────────────

class SiteOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;

  const SiteOutlineButton({
    super.key, required this.label, required this.onTap, this.fontSize = 15});

  @override
  State<SiteOutlineButton> createState() => _SiteOutlineButtonState();
}

class _SiteOutlineButtonState extends State<SiteOutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding:  EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color:        _hovered ? AppColors.tint10(AppColors.primary) : Colors.transparent,
            borderRadius: AppRadius.pillBR,
            border:       Border.all(
              color: AppColors.primary,
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          child: Text(widget.label,
            style: AppTypography.button.copyWith(
                color: AppColors.primary, fontSize: widget.fontSize)),
        ),
      ),
    );
  }
}