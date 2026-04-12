// lib/features/site/home/widgets/site_shared.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Site — Shared UI Primitives
// ─────────────────────────────────────────────────────────────────────────────
// Reusable atoms used across all Site sections:
//   SiteSectionHeader   — 4-part section header (eyebrow + headline + subline)
//   SiteGradientButton  — primary gradient pill button
//   SiteOutlineButton   — secondary outline pill button
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SiteSectionHeader
// ─────────────────────────────────────────────────────────────────────────────
//
// Every Site section opens with this 4-part header:
//   eyebrow  → AppTypography.overline  (fontAccent, uppercase, muted)
//   headline → AppTypography.h2        (fontDisplay, bold, textPrimary)
//   subline  → AppTypography.bodySmall (fontText, light, textSecondary)
//
// [maxSublineWidth] constrains the subline so it never stretches uncomfortably
// wide on large viewports. Default 520 works for most section sublines.

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
    return Column(
      crossAxisAlignment: alignment == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        // ── Eyebrow ─────────────────────────────────────────────────────────
        Text(eyebrow.toUpperCase(), style: AppTypography.overline),

        SizedBox(height: AppSpacing.sm),

        // ── Headline ─────────────────────────────────────────────────────────
        Text(
          headline,
          textAlign: alignment,
          style: AppTypography.h2.copyWith(fontSize: headlineFontSize),
        ),

        // ── Subline (optional) ────────────────────────────────────────────────
        if (subline != null) ...[
          SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxSublineWidth),
            child: Text(
              subline!,
              textAlign: alignment,
              style: AppTypography.bodySmall.copyWith(height: 1.65),
            ),
          ),
        ],
      ],
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
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: pad,
          decoration: BoxDecoration(
            gradient: _hovered ? AppGradients.buttonHover : AppGradients.button,
            borderRadius: AppRadius.pillBR,
            boxShadow: _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
          ),
          child: Text(
            widget.label,
            style: AppTypography.button.copyWith(fontSize: widget.fontSize),
          ),
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
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 15,
  });

  @override
  State<SiteOutlineButton> createState() => _SiteOutlineButtonState();
}

class _SiteOutlineButtonState extends State<SiteOutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.tint10(AppColors.primary)
                : Colors.transparent,
            borderRadius: AppRadius.pillBR,
            border: Border.all(
              color: AppColors.primary,
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTypography.button.copyWith(
              color: AppColors.primary,
              fontSize: widget.fontSize,
            ),
          ),
        ),
      ),
    );
  }
}