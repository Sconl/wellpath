// lib/features/wellness/presentation/wellness_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Full Wellness dashboard:
//            - Animated today's rings (workout / water / sleep).
//            - 7-day weekly bar chart (per type).
//            - Log history list with delete + edit gesture.
//            - Weekly goals summary with progress bars.
//            - Quick-log FAB for each wellness type.
//            - All backed by todayWellnessLogsProvider & wellnessHistoryProvider.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_nav.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/wellness_log_model.dart';
import '../../dashboard/providers/home_providers.dart';
import '../../dashboard/widgets/quick_log_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kHorizPad = 20.0;
const double _kCardGap = 16.0;
const double _kRingSize = 72.0;
const double _kRingStroke = 7.0;
const double _kBarMaxH = 80.0;

// ─────────────────────────────────────────────────────────────────────────────
// WellnessScreen
// ─────────────────────────────────────────────────────────────────────────────

class WellnessScreen extends ConsumerWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);
    return userAsync.when(
      loading: () => _LoadingScaffold(),
      error: (_, __) => _LoadingScaffold(),
      data: (user) {
        if (user == null) return _LoadingScaffold();
        return AppNavShell(
          currentRoute: '/wellness',
          isTrainerView: false,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          child: _WellnessBody(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WellnessBody
// ─────────────────────────────────────────────────────────────────────────────

class _WellnessBody extends ConsumerWidget {
  const _WellnessBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWellnessLogsProvider).valueOrNull ?? [];
    final allLogs = ref.watch(wellnessHistoryProvider).valueOrNull ?? [];

    return AppCanvas(
      type: BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_kHorizPad, 20, _kHorizPad, 120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ─────────────────────────────────────────────────
              Row(children: [
                const HamburgerButton(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Wellness', style: AppTypography.h2),
                    Text('Track your daily health habits',
                        style: AppTypography.helper.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
                // Date pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMid,
                    borderRadius: AppRadius.pillBR,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _todayLabel(),
                    style: AppTypography.badge.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ]),

              const SizedBox(height: _kCardGap + 4),

              // ── Today's Rings ──────────────────────────────────────────
              _TodayRingsCard(logs: today),

              const SizedBox(height: _kCardGap),

              // ── Quick Log Strip ────────────────────────────────────────
              _QuickLogStrip(),

              const SizedBox(height: _kCardGap),

              // ── Weekly Overview Chart ──────────────────────────────────
              _WeeklyChartCard(allLogs: allLogs),

              const SizedBox(height: _kCardGap),

              // ── Weekly Goals Progress ──────────────────────────────────
              _WeeklyGoalsCard(allLogs: allLogs),

              const SizedBox(height: _kCardGap),

              // ── Recent Logs ────────────────────────────────────────────
              _RecentLogsCard(logs: allLogs),
            ]),
          ),
        ]),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _TodayRingsCard
// ═════════════════════════════════════════════════════════════════════════════

class _TodayRingsCard extends StatefulWidget {
  final List<WellnessLog> logs;
  const _TodayRingsCard({required this.logs});
  @override
  State<_TodayRingsCard> createState() => _TodayRingsCardState();
}

class _TodayRingsCardState extends State<_TodayRingsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  double _sum(WellnessType t) =>
      widget.logs.where((l) => l.type == t).fold(0.0, (s, l) => s + l.value);

  @override
  Widget build(BuildContext context) {
    final workout = _sum(WellnessType.workout);
    final water = _sum(WellnessType.water);
    final sleep = _sum(WellnessType.sleep);

    final allMet = workout >= kDefaultWorkoutTargetMins &&
        water >= kDefaultWaterTargetGlasses &&
        sleep >= kDefaultSleepTargetHours;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardElevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Today's Progress", style: AppTypography.h4),
          if (allMet)
            Row(children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
              const SizedBox(width: 5),
              Text('All goals met!',
                  style: AppTypography.badge.copyWith(color: AppColors.success)),
            ]),
        ]),
        const SizedBox(height: 6),
        Text('Keep it up — you\'re on a roll 💪',
            style: AppTypography.helper.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Column(children: [
            _RingDetailRow(
              icon: Icons.fitness_center_rounded,
              label: 'Workout',
              value: workout,
              target: kDefaultWorkoutTargetMins,
              unit: 'min',
              color: AppColors.primary,
              anim: _anim.value,
            ),
            const SizedBox(height: 16),
            _RingDetailRow(
              icon: Icons.water_drop_rounded,
              label: 'Water Intake',
              value: water,
              target: kDefaultWaterTargetGlasses,
              unit: 'glasses',
              color: AppColors.secondary,
              anim: _anim.value,
            ),
            const SizedBox(height: 16),
            _RingDetailRow(
              icon: Icons.bedtime_rounded,
              label: 'Sleep',
              value: sleep,
              target: kDefaultSleepTargetHours,
              unit: 'hours',
              color: AppColors.tertiary,
              anim: _anim.value,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _RingDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, unit;
  final double value, target, anim;
  final Color color;
  const _RingDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0.0, 1.0) * anim;
    final display = unit == 'hours' && value % 1 != 0
        ? value.toStringAsFixed(1)
        : value.toInt().toString();
    final met = value >= target;

    return Row(children: [
      // Ring
      SizedBox(
        width: _kRingSize,
        height: _kRingSize,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: _kRingStroke,
            color: color.withValues(alpha: 0.10),
            strokeCap: StrokeCap.round,
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: _kRingStroke,
            color: color,
            strokeCap: StrokeCap.round,
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(display,
                style: AppTypography.h4.copyWith(color: color, height: 1.0)),
            Text(unit,
                style: AppTypography.caption
                    .copyWith(color: color.withValues(alpha: 0.7), fontSize: 9)),
          ]),
        ]),
      ),
      const SizedBox(width: 16),

      // Info
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: AppTypography.h5),
            if (met) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
            ],
          ]),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(progress * 100).toInt()}% complete',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            Text('Goal: ${target.toInt()} $unit',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ]),
        ]),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _QuickLogStrip
// ═════════════════════════════════════════════════════════════════════════════

class _QuickLogStrip extends ConsumerWidget {
  const _QuickLogStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = [
      (WellnessType.workout, Icons.fitness_center_rounded, 'Log Workout', AppColors.primary),
      (WellnessType.water, Icons.water_drop_rounded, 'Log Water', AppColors.secondary),
      (WellnessType.sleep, Icons.bedtime_rounded, 'Log Sleep', AppColors.tertiary),
    ];

    return Row(
      children: types.map((t) {
        final (type, icon, label, color) = t;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: type != WellnessType.sleep ? 10 : 0),
            child: GestureDetector(
              onTap: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => QuickLogSheet(type: type),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: AppRadius.inputBR,
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Column(children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(height: 6),
                  Text(label,
                      style: AppTypography.caption.copyWith(color: color),
                      textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _WeeklyChartCard — 7-day bar chart per wellness type
// ═════════════════════════════════════════════════════════════════════════════

class _WeeklyChartCard extends StatefulWidget {
  final List<WellnessLog> allLogs;
  const _WeeklyChartCard({required this.allLogs});
  @override
  State<_WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<_WeeklyChartCard>
    with SingleTickerProviderStateMixin {
  WellnessType _selected = WellnessType.workout;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _switchType(WellnessType t) {
    setState(() => _selected = t);
    _ctrl.forward(from: 0);
  }

  List<double> _weeklyData() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return widget.allLogs
          .where((l) =>
              l.type == _selected &&
              l.timestamp.year == day.year &&
              l.timestamp.month == day.month &&
              l.timestamp.day == day.day)
          .fold(0.0, (s, l) => s + l.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _weeklyData();
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final typeConfig = {
      WellnessType.workout: (
        AppColors.primary,
        Icons.fitness_center_rounded,
        'Workout',
        'min'
      ),
      WellnessType.water: (
        AppColors.secondary,
        Icons.water_drop_rounded,
        'Water',
        'gl'
      ),
      WellnessType.sleep: (
        AppColors.tertiary,
        Icons.bedtime_rounded,
        'Sleep',
        'hr'
      ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('7-Day Overview', style: AppTypography.h4),
          // Type switcher
          Row(children: WellnessType.values.map((t) {
            final (color, icon, _, _) = typeConfig[t]!;
            final sel = t == _selected;
            return GestureDetector(
              onTap: () => _switchType(t),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: sel ? color.withValues(alpha: 0.15) : AppColors.surfaceMid,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel ? color : AppColors.border,
                    width: sel ? 1.5 : 1.0,
                  ),
                ),
                child: Icon(icon,
                    size: 14, color: sel ? color : AppColors.textMuted),
              ),
            );
          }).toList()),
        ]),

        const SizedBox(height: 6),
        Builder(builder: (_) {
          final (color, _, label, unit) = typeConfig[_selected]!;
          final total = _weeklyData().fold(0.0, (a, b) => a + b);
          return Text(
            '${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)} $unit this week',
            style: AppTypography.helper.copyWith(color: color),
          );
        }),

        const SizedBox(height: 20),

        // Bar chart
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final (color, _, label, unit) = typeConfig[_selected]!;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = now.subtract(Duration(days: 6 - i));
                final isToday = i == 6;
                final val = data[i];
                final ratio = maxVal > 0 ? (val / maxVal * _anim.value) : 0.0;
                final barH = (_kBarMaxH * ratio).clamp(4.0, _kBarMaxH);
                final dayIdx = (day.weekday - 1) % 7;

                return Expanded(
                  child: Column(children: [
                    // Value label on top
                    if (val > 0)
                      Text(
                        val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: isToday ? color : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                    const SizedBox(height: 4),
                    // Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: barH,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isToday
                              ? color
                              : val > 0
                                  ? color.withValues(alpha: 0.40)
                                  : AppColors.surfaceMid,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Day label
                    Text(
                      dayLabels[dayIdx],
                      style: AppTypography.caption.copyWith(
                        color: isToday ? color : AppColors.textMuted,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 10,
                      ),
                    ),
                  ]),
                );
              }),
            );
          },
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _WeeklyGoalsCard
// ═════════════════════════════════════════════════════════════════════════════

class _WeeklyGoalsCard extends StatefulWidget {
  final List<WellnessLog> allLogs;
  const _WeeklyGoalsCard({required this.allLogs});
  @override
  State<_WeeklyGoalsCard> createState() => _WeeklyGoalsCardState();
}

class _WeeklyGoalsCardState extends State<_WeeklyGoalsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  double _weeklySum(WellnessType t) {
    final cut = DateTime.now().subtract(const Duration(days: 7));
    return widget.allLogs
        .where((l) => l.type == t && l.timestamp.isAfter(cut))
        .fold(0.0, (s, l) => s + l.value);
  }

  // How many distinct days had at least one workout in last 7 days
  int get _workoutDays {
    final cut = DateTime.now().subtract(const Duration(days: 7));
    return widget.allLogs
        .where((l) => l.type == WellnessType.workout && l.timestamp.isAfter(cut))
        .map((l) => DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day))
        .toSet()
        .length;
  }

  @override
  Widget build(BuildContext context) {
    const workoutTarget = 5.0;   // sessions per week
    const waterTarget = kDefaultWaterTargetGlasses * 7;
    const sleepTarget = kDefaultSleepTargetHours * 7;

    final workoutVal = _workoutDays.toDouble();
    final waterVal = _weeklySum(WellnessType.water);
    final sleepVal = _weeklySum(WellnessType.sleep);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Weekly Goals', style: AppTypography.h4),
          Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 17),
        ]),
        const SizedBox(height: 16),

        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Column(children: [
            _GoalProgressRow(
              icon: Icons.fitness_center_rounded,
              label: 'Workout Days',
              value: workoutVal,
              target: workoutTarget,
              unit: 'days',
              color: AppColors.primary,
              anim: _anim.value,
            ),
            const SizedBox(height: 14),
            _GoalProgressRow(
              icon: Icons.water_drop_rounded,
              label: 'Water Intake',
              value: waterVal,
              target: waterTarget,
              unit: 'glasses',
              color: AppColors.secondary,
              anim: _anim.value,
            ),
            const SizedBox(height: 14),
            _GoalProgressRow(
              icon: Icons.bedtime_rounded,
              label: 'Sleep',
              value: sleepVal,
              target: sleepTarget,
              unit: 'hours',
              color: AppColors.tertiary,
              anim: _anim.value,
            ),
          ]),
        ),

        const SizedBox(height: 16),
        // Workout pip dots
        Row(children: [
          Text('Workout days  ', style: AppTypography.caption),
          ...List.generate(5, (i) => Container(
            width: 14, height: 14,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: i < _workoutDays ? AppColors.primary : AppColors.surfaceMid,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
          )),
          Text('$_workoutDays / 5',
              style: AppTypography.caption.copyWith(color: AppColors.primary)),
        ]),
      ]),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  final IconData icon;
  final String label, unit;
  final double value, target, anim;
  final Color color;
  const _GoalProgressRow({
    required this.icon, required this.label, required this.unit,
    required this.value, required this.target,
    required this.color, required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / target * anim).clamp(0.0, 1.0);
    final display = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    final targetDisplay = target % 1 == 0 ? target.toInt().toString() : target.toStringAsFixed(1);
    final met = value >= target;

    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: AppTypography.h5),
            Row(children: [
              if (met) Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 3),
              Text('$display / $targetDisplay $unit',
                  style: AppTypography.caption.copyWith(
                    color: met ? AppColors.success : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(
                met ? AppColors.success : color,
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _RecentLogsCard — scrollable history of log entries
// ═════════════════════════════════════════════════════════════════════════════

class _RecentLogsCard extends ConsumerWidget {
  final List<WellnessLog> logs;
  const _RecentLogsCard({required this.logs});

  static const _limit = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = logs
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final display = recent.take(_limit).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Recent Activity', style: AppTypography.h4),
        Text('${logs.length} entries',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 12),

      if (display.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: AppDecorations.card,
          child: Column(children: [
            Icon(Icons.self_improvement_rounded,
                size: 36, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No logs yet',
                style: AppTypography.h5.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Use the quick-log buttons above to track your habits.',
                style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ]),
        )
      else
        Container(
          decoration: AppDecorations.card,
          child: Column(
            children: display.asMap().entries.map((e) {
              final i = e.key;
              final log = e.value;
              return Column(children: [
                _LogEntryTile(log: log),
                if (i < display.length - 1)
                  Divider(height: 1, color: AppColors.border,
                      indent: 56, endIndent: 16),
              ]);
            }).toList(),
          ),
        ),
    ]);
  }
}

class _LogEntryTile extends StatelessWidget {
  final WellnessLog log;
  const _LogEntryTile({required this.log});

  static const _typeConfig = {
    WellnessType.workout: (
      Icons.fitness_center_rounded,
      'Workout',
      'min',
    ),
    WellnessType.water: (
      Icons.water_drop_rounded,
      'Water',
      'glasses',
    ),
    WellnessType.sleep: (
      Icons.bedtime_rounded,
      'Sleep',
      'hours',
    ),
  };

  Color _typeColor(WellnessType t) => switch (t) {
        WellnessType.workout => AppColors.primary,
        WellnessType.water => AppColors.secondary,
        WellnessType.sleep => AppColors.tertiary,
      };

  String _timeLabel() {
    final diff = DateTime.now().difference(log.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, unit) = _typeConfig[log.type]!;
    final color = _typeColor(log.type);
    final display = log.value % 1 == 0
        ? log.value.toInt().toString()
        : log.value.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: AppTypography.h5.copyWith(color: AppColors.textPrimary)),
            Text(_timeLabel(),
                style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ]),
        ),
        Text(
          '$display $unit',
          style: AppTypography.h5.copyWith(color: color),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}