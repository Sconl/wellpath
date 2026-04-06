// lib/features/auth/presentation/widgets/auth_widgets.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Full rewrite. Private _T class removed.
//            All GoogleFonts.poppins() calls → AppTypography.*
//            All Color literals → AppColors.*
//            All magic radii/spacing → AppRadius.* / AppSpacing.*
//            WellPathButton gradients → AppGradients.button / buttonHover
//            WellPathButton text color → AppColors.onPrimary (WCAG-computed)
//            WellPathDivider → AppColors.border + AppTypography.helper
//   v1.1.0 — Import path corrected: app_theme.dart is 4 levels up from
//            lib/features/auth/presentation/widgets/ (widgets → presentation
//            → auth → features → lib → core/theme).
// ─────────────────────────────────────────────────────────────────────────────
//
// SHARED COMPONENTS:
//   WellPathLogo      — split-weight "Well" bold / "Path" light wordmark
//   WellPathField     — themed TextFormField with password toggle + focus chain
//   WellPathButton    — hover-aware gradient CTA button
//   WellPathDivider   — "OR" divider between form sections

import 'package:flutter/material.dart';

// Import path: this file is at lib/features/auth/presentation/widgets/
// ../../../../ steps back to lib/, then core/theme/app_theme.dart
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WellPathLogo
// ─────────────────────────────────────────────────────────────────────────────

class WellPathLogo extends StatelessWidget {
  final double    fontSize;
  final TextAlign textAlign;

  const WellPathLogo({
    super.key,
    this.fontSize  = 36,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: [
        TextSpan(
          text: 'Well',
          style: AppTypography.brandBold.copyWith(
            fontSize:      fontSize,
            letterSpacing: 3,
            color:         AppColors.textPrimary,
          ),
        ),
        TextSpan(
          text: 'Path',
          // The split between bold/light IS the brand signature —
          // textSecondary (~54% white) on the light half creates the
          // weight contrast without changing hue.
          style: AppTypography.brandLight.copyWith(
            fontSize:      fontSize,
            letterSpacing: 3,
            color:         AppColors.textSecondary,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WellPathField
// ─────────────────────────────────────────────────────────────────────────────

class WellPathField extends StatefulWidget {
  final TextEditingController       controller;
  final String                      label;
  final bool                        obscureText;
  final TextInputType?              keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction?            textInputAction;
  final VoidCallback?               onEditingComplete;
  final Widget?                     prefixIcon;
  final bool                        autofocus;
  final FocusNode?                  focusNode;

  const WellPathField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText        = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onEditingComplete,
    this.prefixIcon,
    this.autofocus          = false,
    this.focusNode,
  });

  @override
  State<WellPathField> createState() => _WellPathFieldState();
}

class _WellPathFieldState extends State<WellPathField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:        widget.controller,
      focusNode:         widget.focusNode,
      obscureText:       _obscured,
      keyboardType:      widget.keyboardType,
      validator:         widget.validator,
      textInputAction:   widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      autofocus:         widget.autofocus,
      style:             AppTypography.input,
      decoration: InputDecoration(
        labelText:  widget.label,
        labelStyle: AppTypography.inputLabel,
        filled:     true,
        fillColor:  AppColors.surface,
        prefixIcon: widget.prefixIcon,
        // Visibility toggle rendered only on password fields
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size:  20,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
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
          borderSide:   const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle:     AppTypography.helper.copyWith(color: AppColors.error),
        contentPadding: AppSpacing.inputPadding,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WellPathButton
// ─────────────────────────────────────────────────────────────────────────────

class WellPathButton extends StatefulWidget {
  final String        label;
  final VoidCallback? onPressed;
  final bool          isLoading;
  final double        height;

  const WellPathButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height    = 50,
  });

  @override
  State<WellPathButton> createState() => _WellPathButtonState();
}

class _WellPathButtonState extends State<WellPathButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration:  AppDurations.fast,
          height:    widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // AppGradients encodes the hue-shift trick from the color engine
            gradient:     _hovered ? AppGradients.buttonHover : AppGradients.button,
            borderRadius: AppRadius.pillBR,
            boxShadow:    _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
          ),
          child: widget.isLoading
              ? SizedBox(
                  width:  22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color:       AppColors.onPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.label,
                  // AppTypography.button sets color: AppColors.onPrimary
                  // which is WCAG-computed — always readable on brand gradient
                  style: AppTypography.button,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WellPathDivider
// ─────────────────────────────────────────────────────────────────────────────

class WellPathDivider extends StatelessWidget {
  final String label;
  const WellPathDivider({super.key, this.label = 'OR'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(label, style: AppTypography.helper),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}