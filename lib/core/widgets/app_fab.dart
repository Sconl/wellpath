// lib/core/widgets/app_fab.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Full rewrite — custom circular→pill hover animation
//   • v2 — overflow fix: Row(mainAxisSize: max) + Expanded for label
//   • v2 — mousetracker fix: onEnter/onExit setState deferred via
//     addPostFrameCallback
//   • v3 — label truncation fix: TextPainter runs at initState before Google
//     Fonts has loaded from network/cache. The measurement uses system fallback
//     font metrics (narrower than Poppins) → expanded width is too small →
//     the label clips mid-word. Fix: _kLabelMeasurementBuffer (28px) added to
//     the TextPainter result to account for the Poppins/fallback metric delta.
// ─────────────────────────────────────────────────────────────────────────────

// HOW TO USE ON ANY PAGE:
//
//   Scaffold(
//     body: Stack(
//       children: [
//         AppBackground(child: SafeArea(child: YourContent())),
//         Positioned(
//           right:  kFabMarginRight,
//           bottom: kFabMarginBottom,
//           child: AppFab(
//             icon:      Icons.add,
//             label:     'Add Session',
//             tooltip:   'Book a new training session with a trainer',
//             onPressed: () => context.push('/book'),
//           ),
//         ),
//       ],
//     ),
//   )
//
//   For a dialog (recommended for chat / complex flows):
//     AppFab(
//       icon:      Icons.chat_bubble_outline,
//       label:     'Feedback',
//       tooltip:   'Chat with our AI assistant',
//       onPressed: () => showDialog(
//         context: context,
//         barrierColor: AppColors.scrim,
//         builder: (_) => const DeveloperFeedbackChat(page: 'landing'),
//       ),
//     )
//
//   For a simple bottom sheet:
//     AppFab(
//       icon:         Icons.filter_list,
//       label:        'Filter',
//       tooltip:      'Filter trainers by specialty',
//       sheetBuilder: (context) => MyFilterSheet(),
//     )

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../style/app_theme.dart';
import '../style/app_decorations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ── FAB geometry ──────────────────────────────────────────────────────────────

/// Diameter of the circular resting state. Also the height of the expanded
/// pill. Border-radius = kFabSize / 2 ensures a perfect pill at all widths.
const double kFabSize = 56.0;

/// Icon size drawn inside the kFabSize × kFabSize icon box.
const double kFabIconSize = 22.0;

/// Padding between icon box right edge and label text left edge.
const double kFabLabelLeadingPad = 0.0;

/// Padding between label text right edge and the pill's right edge.
const double kFabLabelTrailingPad = 20.0;

/// Extra width added to the TextPainter measurement to compensate for the
/// delta between the Google Font (Poppins) metrics and the system fallback
/// font metrics used at measurement time (before the font has loaded).
/// Without this, the expanded pill is too narrow and the label clips mid-word.
/// 28px covers the Poppins/system-fallback difference for labels up to ~20 chars.
const double _kLabelMeasurementBuffer = 28.0;

// ── FAB positioning ───────────────────────────────────────────────────────────

/// Distance from right screen edge to the FAB right edge. Use on every page.
const double kFabMarginRight = 28.0;

/// Distance from bottom screen edge to the FAB bottom edge. Use on every page.
const double kFabMarginBottom = 28.0;

// ── FAB animation ─────────────────────────────────────────────────────────────

/// Circular → pill transition duration.
const Duration kFabHoverDuration = Duration(milliseconds: 220);

/// Easing curve. easeOutCubic starts fast, decelerates into the expanded state.
const Curve kFabHoverCurve = Curves.easeOutCubic;

/// Icon scale on press — tactile click feedback.
const double kFabPressScale = 0.88;

// ── Tooltip ───────────────────────────────────────────────────────────────────

/// How long before the tooltip appears on hover. The expanded label is the
/// primary affordance — tooltip is for lingering hover / screen readers only.
const Duration kFabTooltipWait = Duration(milliseconds: 1400);

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// AppFab
// ─────────────────────────────────────────────────────────────────────────────

class AppFab extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final WidgetBuilder? sheetBuilder;
  final Color? sheetBackgroundColor;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppFab({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.onPressed,
    this.sheetBuilder,
    this.sheetBackgroundColor,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AppFab> createState() => _AppFabState();
}

class _AppFabState extends State<AppFab> {
  bool _hovered = false;
  bool _pressed = false;
  late final double _expandedWidth;

  @override
  void initState() {
    super.initState();
    _expandedWidth = _measureExpandedWidth(widget.label);
  }

  double _measureExpandedWidth(String label) {
    // TextPainter measures synchronously at initState time, before the Google
    // Font (Poppins) has loaded. The measurement uses system fallback font
    // metrics which are narrower than Poppins — leading to the label clipping.
    // _kLabelMeasurementBuffer compensates for this delta.
    final tp = TextPainter(
      text: TextSpan(text: label, style: AppTypography.buttonSm),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return kFabSize +
        kFabLabelLeadingPad +
        tp.width +
        kFabLabelTrailingPad +
        _kLabelMeasurementBuffer;
  }

  void _setHovered(bool hovered) {
    // Defer to avoid re-entrant setState during mouse event processing —
    // fixes the mouse_tracker.dart:199 assertion.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hovered = hovered;
          if (!hovered) _pressed = false;
        });
      }
    });
  }

  void _handleTap(BuildContext context) {
    if (widget.sheetBuilder != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            widget.sheetBackgroundColor ?? AppColors.lightBackground,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modalTopBR),
        builder: widget.sheetBuilder!,
      );
      return;
    }
    widget.onPressed?.call();
  }

  BoxDecoration _decoration(bool hovered, bool pressed) => BoxDecoration(
        color: widget.backgroundColor,
        gradient: widget.backgroundColor != null
            ? null
            : (hovered ? AppGradients.buttonHover : AppGradients.button),
        borderRadius: BorderRadius.circular(kFabSize / 2),
        boxShadow: pressed
            ? []
            : (hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow),
      );

  @override
  Widget build(BuildContext context) {
    final fg = widget.foregroundColor ?? AppColors.onPrimary;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: false,
        verticalOffset: kFabSize / 2 + 12,
        waitDuration: kFabTooltipWait,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              _handleTap(context);
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: kFabHoverDuration,
              curve: kFabHoverCurve,
              height: kFabSize,
              width: _hovered ? _expandedWidth : kFabSize,
              decoration: _decoration(_hovered, _pressed),
              clipBehavior: Clip.antiAlias,
              child: Row(
                // mainAxisSize.max fills the container exactly at every
                // animation frame — prevents overflow during the transition.
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Icon — LEFT side ─────────────────────────────────────
                  // Fixed kFabSize × kFabSize box. As Positioned.right anchors
                  // the right edge, the container expands LEFTWARD — this icon
                  // box moves left with the growing left edge.
                  SizedBox(
                    width: kFabSize,
                    height: kFabSize,
                    child: Center(
                      child: AnimatedScale(
                        duration: kFabHoverDuration,
                        curve: Curves.easeOutBack,
                        scale: _pressed ? kFabPressScale : 1.0,
                        child: Icon(widget.icon, size: kFabIconSize, color: fg),
                      ),
                    ),
                  ),

                  // ── Label — RIGHT side ───────────────────────────────────
                  // Expanded absorbs all width beyond the icon box.
                  // At rest (container = 56px): 0px remains → label invisible.
                  // Expanded: (expandedWidth − 56px) remains → label visible.
                  Expanded(
                    child: AnimatedOpacity(
                      duration: kFabHoverDuration,
                      curve: kFabHoverCurve,
                      opacity: _hovered ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: kFabLabelLeadingPad,
                          right: kFabLabelTrailingPad,
                        ),
                        child: Text(
                          widget.label,
                          style: AppTypography.buttonSm.copyWith(color: fg),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFeedbackSheet — simple text-input bottom sheet (non-AI fallback)
// ─────────────────────────────────────────────────────────────────────────────

const String _kFeedbackTitle = 'Send a Message';
const String _kFeedbackSubtitle =
    'Share a bug, idea, or anything on your mind.';
const String _kFeedbackHint = 'Type your message here...';
const String _kFeedbackCancel = 'Cancel';
const String _kFeedbackSend = 'Send';
const String _kFeedbackSuccess = 'Thanks — message sent.';
const String _kFeedbackEmpty = 'Please write a message before sending.';
const String _kFeedbackError = 'Something went wrong. Please try again.';
const int _kFeedbackMaxLines = 4;

class AppFeedbackSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String inputHint;
  final String cancelLabel;
  final String sendLabel;
  final Future<void> Function(String message)? onSend;

  const AppFeedbackSheet({
    super.key,
    this.title = _kFeedbackTitle,
    this.subtitle = _kFeedbackSubtitle,
    this.inputHint = _kFeedbackHint,
    this.cancelLabel = _kFeedbackCancel,
    this.sendLabel = _kFeedbackSend,
    this.onSend,
  });

  @override
  State<AppFeedbackSheet> createState() => _AppFeedbackSheetState();
}

class _AppFeedbackSheetState extends State<AppFeedbackSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_kFeedbackEmpty)));
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await widget.onSend?.call(msg);
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text(_kFeedbackSuccess)));
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(const SnackBar(content: Text(_kFeedbackError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md + 4,
        right: AppSpacing.md + 4,
        top: AppSpacing.md + 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md + 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title,
                style: AppTypography.h4
                    .copyWith(color: AppColors.lightTextPrimary)),
            IconButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              icon: Icon(Icons.close,
                  color: AppColors.lightTextSecondary, size: 20),
            ),
          ]),
          SizedBox(height: AppSpacing.xs + 2),
          Text(widget.subtitle,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.lightTextSecondary)),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            maxLines: _kFeedbackMaxLines,
            autofocus: true,
            style:
                AppTypography.body.copyWith(color: AppColors.lightTextPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.lightSurface,
              hintText: widget.inputHint,
              hintStyle: AppTypography.input
                  .copyWith(color: AppColors.lightTextSecondary),
              border: OutlineInputBorder(
                  borderRadius: AppRadius.inputBR,
                  borderSide: BorderSide(color: AppColors.lightSurfaceMid)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputBR,
                  borderSide: BorderSide(color: AppColors.lightSurfaceMid)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputBR,
                  borderSide:
                      BorderSide(color: AppColors.lightPrimary, width: 1.5)),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              child: Text(widget.cancelLabel,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.lightTextSecondary)),
            ),
            SizedBox(width: AppSpacing.sm),
            Container(
              decoration: AppDecorations.primaryButton,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 3),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBR),
                ),
                onPressed: _sending ? null : _handleSend,
                child: _sending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onPrimary))
                    : Text(widget.sendLabel, style: AppTypography.buttonSm),
              ),
            ),
          ]),
          SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
