// lib/features/home/widgets/wellness_summary_card.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Three circular progress rings for workout/water/sleep.
//            Target values use the constants from wellness_log_model.dart.
//            Will be replaced with user goal values (Week 5 Feature 2 goals).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../wellness/data/wellness_log_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Ring dimensions ──
const double _kRingSize        = 72.0;
const double _kRingStrokeWidth = 7.0;

// ─────────────────────────────────────────────────────────────────────────────
// WellnessSummaryCard
//
// Pass the full day's log list — this widget does the aggregation internally.
// Keeps the provider simple (just return all today's logs) and the widget
// self-contained enough to test with a fixed list.
// ─────────────────────────────────────────────────────────────────────────────

class WellnessSummaryCard extends StatelessWidget {
  final List<WellnessLog> logs;

  const WellnessSummaryCard({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final workoutMins  = _sumType(WellnessType.workout);
    final waterGlasses = _sumType(WellnessType.water);
    final sleepHours   = _sumType(WellnessType.sleep);

    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                "Today's Progress",
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // If all three are logged, show a subtle checkmark
              if (_allTargetsMet(workoutMins, waterGlasses, sleepHours))
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size:  16,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Three rings ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressRing(
                label:    WellnessType.workout.displayLabel,
                unit:     WellnessType.workout.unit,
                value:    workoutMins,
                target:   kDefaultWorkoutTargetMins,
                color:    AppColors.primary,
              ),
              _ProgressRing(
                label:    WellnessType.water.displayLabel,
                unit:     WellnessType.water.unit,
                value:    waterGlasses,
                target:   kDefaultWaterTargetGlasses,
                color:    AppColors.secondary,
              ),
              _ProgressRing(
                label:    WellnessType.sleep.displayLabel,
                unit:     WellnessType.sleep.unit,
                value:    sleepHours,
                target:   kDefaultSleepTargetHours,
                color:    AppColors.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _sumType(WellnessType type) =>
      logs.where((l) => l.type == type).fold(0.0, (acc, l) => acc + l.value);

  bool _allTargetsMet(double w, double water, double s) =>
      w    >= kDefaultWorkoutTargetMins    &&
      water >= kDefaultWaterTargetGlasses  &&
      s    >= kDefaultSleepTargetHours;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressRing
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double target;
  final Color  color;

  const _ProgressRing({
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp so a 180-minute workout doesn't render a double-ring.
    final progress = (value / target).clamp(0.0, 1.0);

    // One decimal place for sleep (0.5-hr steps), whole number for the others.
    final displayValue = (unit == 'hr' && value % 1 != 0)
        ? value.toStringAsFixed(1)
        : value.toInt().toString();

    return Column(
      children: [
        SizedBox(
          width:  _kRingSize,
          height: _kRingSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track — always full, just dimmed
              CircularProgressIndicator(
                value:       1.0,
                strokeWidth: _kRingStrokeWidth,
                color:       color.withOpacity(0.12),
                strokeCap:   StrokeCap.round,
              ),
              // Foreground progress
              CircularProgressIndicator(
                value:       progress,
                strokeWidth: _kRingStrokeWidth,
                color:       color,
                strokeCap:   StrokeCap.round,
              ),
              // Centre: value display
              Text(
                displayValue,
                style: AppTypography.h5.copyWith(color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          unit,
          style: AppTypography.helper.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTypography.helper.copyWith(
            color:      AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}