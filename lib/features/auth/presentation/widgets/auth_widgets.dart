// lib/features/auth/presentation/widgets/auth_widgets.dart
//
// Shared auth-screen widgets.
// Exports: WellPathLogo, WellPathField (with focusNode), WellPathButton, WellPathDivider

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _T {
  static const surface  = Color(0xFF0A1F12);
  static const primary  = Color(0xFF00CC66);
  static const primaryL = Color(0xFF00FF99);
  static const primaryD = Color(0xFF009944);
  static const border   = Color(0x33FFFFFF);
  static const txtPri   = Colors.white;
  static const txtSec   = Colors.white54;
  static const err      = Colors.redAccent;
  static const rField   = 10.0;
  static const rButton  = 50.0;
  static const sm       = 8.0;
  static const md       = 16.0;
}

// ── WellPathLogo ─────────────────────────────────────────────────────────────

class WellPathLogo extends StatelessWidget {
  final double fontSize;
  final TextAlign textAlign;

  const WellPathLogo({
    super.key,
    this.fontSize = 36,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Well',
            style: GoogleFonts.poppins(
              color: _T.txtPri,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          TextSpan(
            text: 'Path',
            style: GoogleFonts.poppins(
              color: _T.txtPri,
              fontSize: fontSize,
              fontWeight: FontWeight.w300,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── WellPathField ─────────────────────────────────────────────────────────────
// FIX: added focusNode parameter — was missing, caused undefined_named_parameter
// errors on every field usage in signup_screen.dart and login_screen.dart.

class WellPathField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final Widget? prefixIcon;
  final bool autofocus;
  final FocusNode? focusNode; // ← the fix

  const WellPathField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onEditingComplete,
    this.prefixIcon,
    this.autofocus = false,
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
      style: GoogleFonts.poppins(
        color: _T.txtPri,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.poppins(
          color: _T.txtSec,
          fontSize: 13,
          fontWeight: FontWeight.w300,
        ),
        filled:     true,
        fillColor:  _T.surface,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _T.txtSec,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.rField),
          borderSide: const BorderSide(color: _T.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.rField),
          borderSide: const BorderSide(color: _T.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.rField),
          borderSide: const BorderSide(color: _T.err),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.rField),
          borderSide: const BorderSide(color: _T.err, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(
          color: _T.err,
          fontSize: 12,
          fontWeight: FontWeight.w300,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: _T.md, vertical: 14),
      ),
    );
  }
}

// ── WellPathButton ────────────────────────────────────────────────────────────

class WellPathButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const WellPathButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 50,
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
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [_T.primaryL, _T.primary]
                  : [_T.primary,  _T.primaryD],
            ),
            borderRadius: BorderRadius.circular(_T.rButton),
            boxShadow: [
              BoxShadow(
                color: _T.primary.withAlpha(_hovered ? 100 : 50),
                blurRadius: _hovered ? 24 : 12,
                spreadRadius: _hovered ? 2 : 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    color: _hovered ? const Color(0xFF001A0A) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── WellPathDivider ───────────────────────────────────────────────────────────

class WellPathDivider extends StatelessWidget {
  final String label;
  const WellPathDivider({super.key, this.label = 'OR'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _T.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _T.sm),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: _T.txtSec,
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _T.border, thickness: 1)),
      ],
    );
  }
}