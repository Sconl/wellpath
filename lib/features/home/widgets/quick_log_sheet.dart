// lib/features/home/widgets/quick_log_sheet.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Modal bottom sheet for one-tap wellness logging.
//            Slider-based input with per-type ranges/steps/defaults.
//            Animated gradient save button (matches WellPathButton pattern).
//            Returns `true` on success so callers can update a local snackbar.
//
// USAGE:
//   final saved = await showModalBottomSheet<bool>(
//     context:             context,
//     isScrollControlled:  true,
//     backgroundColor:     Colors.transparent,
//     builder:             (_) => QuickLogSheet(type: WellnessType.workout),
//   );
//   if (saved == true) ScaffoldMessenger.of(context).showSnackBar(...);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/style/app_decorations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../wellness/data/wellness_log_model.dart';
import '../providers/home_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Sheet layout ──
const double _kSheetPadding = 24.0;
const double _kHandleWidth = 40.0;
const double _kHandleHeight = 4.0;
const double _kSaveButtonH = 50.0;
const double _kSheetRadius = 24.0;

// ── Per-type slider config ──
// Step size drives the slider divisions. Keep steps coarse enough that a
// finger can land accurately on a touch screen.
const _kTypeConfigs = <WellnessType, _SliderConfig>{
  WellnessType.workout: _SliderConfig(
    icon: Icons.fitness_center_rounded,
    label: 'Log Workout',
    unit: 'minutes',
    min: 5.0,
    max: 180.0,
    defaultVal: 30.0,
    step: 5.0,
  ),
  WellnessType.water: _SliderConfig(
    icon: Icons.water_drop_rounded,
    label: 'Log Water',
    unit: 'glasses',
    min: 1.0,
    max: 16.0,
    defaultVal: 1.0,
    step: 1.0,
  ),
  WellnessType.sleep: _SliderConfig(
    icon: Icons.bedtime_rounded,
    label: 'Log Sleep',
    unit: 'hours',
    min: 1.0,
    max: 12.0,
    defaultVal: 7.0,
    step: 0.5, // half-hour precision for sleep is practical
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// QuickLogSheet
// ─────────────────────────────────────────────────────────────────────────────

class QuickLogSheet extends ConsumerStatefulWidget {
  final WellnessType type;

  const QuickLogSheet({super.key, required this.type});

  @override
  ConsumerState<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<QuickLogSheet> {
  late double _value;
  bool _loading = false;
  String? _error;

  _SliderConfig get _config => _kTypeConfigs[widget.type]!;

  @override
  void initState() {
    super.initState();
    _value = _config.defaultVal;
  }

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return; // should be unreachable behind the auth guard

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(wellnessLogRepositoryProvider).addLog(
            uid: uid,
            type: widget.type,
            value: _value,
          );
      // Pop before setState — widget may be gone already
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Don't log the full exception to the UI — no stack traces for users.
      setState(() {
        _loading = false;
        _error = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        _kSheetPadding,
        _kSheetPadding,
        _kSheetPadding,
        _kSheetPadding + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_kSheetRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          Center(
            child: Container(
              width: _kHandleWidth,
              height: _kHandleHeight,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(_kHandleHeight / 2),
              ),
            ),
          ),

          // ── Title ─────────────────────────────────────────────────────
          Row(
            children: [
              Icon(_config.icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                _config.label,
                style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Large value readout ────────────────────────────────────────
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _displayValue(),
                    style: AppTypography.h1.copyWith(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: '  ${_config.unit}',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Slider ────────────────────────────────────────────────────
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.12),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.10),
              trackHeight: 4,
            ),
            child: Slider(
              value: _value,
              min: _config.min,
              max: _config.max,
              // divisions drives snap-to-step behaviour — critical for
              // usability on mobile (no free-dragging to an arbitrary float)
              divisions: ((_config.max - _config.min) / _config.step).round(),
              onChanged: _loading ? null : (v) => setState(() => _value = v),
            ),
          ),

          // ── Min / Max labels ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatEndpoint(_config.min),
                  style: AppTypography.helper.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  _formatEndpoint(_config.max),
                  style: AppTypography.helper.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Error banner (only shown on write failure) ─────────────────
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: AppDecorations.errorBanner,
              child: Text(
                _error!,
                style: AppTypography.helper.copyWith(color: AppColors.error),
              ),
            ),
          ],

          // ── Save button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: _kSaveButtonH,
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _GradientSaveButton(onTap: _save),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Show one decimal only for sleep (0.5-step precision). Whole numbers
  // everywhere else — "30 minutes" reads better than "30.0 minutes".
  String _displayValue() {
    if (widget.type == WellnessType.sleep && _value % 1 != 0) {
      return _value.toStringAsFixed(1);
    }
    return _value.toInt().toString();
  }

  String _formatEndpoint(double v) {
    if (widget.type == WellnessType.sleep && v % 1 != 0) {
      return '${v.toStringAsFixed(1)} ${_config.unit}';
    }
    return '${v.toInt()} ${_config.unit}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientSaveButton — hover-animated, matches WellPathButton
//
// We can't reuse WellPathButton directly here because that widget lives in
// auth/presentation/widgets — importing it would create a feature→feature
// coupling. This mirrors the pattern using the same theme tokens.
// If WellPathButton moves to core/widgets in a future refactor, replace this.
// ─────────────────────────────────────────────────────────────────────────────

class _GradientSaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GradientSaveButton({required this.onTap});
  @override
  State<_GradientSaveButton> createState() => _GradientSaveButtonState();
}

class _GradientSaveButtonState extends State<_GradientSaveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: _hovered ? AppGradients.buttonHover : AppGradients.button,
            borderRadius: AppRadius.pillBR,
            boxShadow:
                _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
          ),
          child: Text('Save Log', style: AppTypography.button),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SliderConfig — immutable value object per wellness type
// ─────────────────────────────────────────────────────────────────────────────

class _SliderConfig {
  final IconData icon;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double defaultVal;
  final double step;

  const _SliderConfig({
    required this.icon,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.defaultVal,
    required this.step,
  });
}
