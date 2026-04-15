// lib/spaces/space_site/screen_home/section_context/section_context_stats.dart
//
// QP CANON: SECTION CONTEXT — block context_stats
//
// Renamed from: widgets/site_stats.dart

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../space_site_config.dart';
import '../../space_site_shared.dart';

class SectionContextStats extends StatelessWidget {
  final SiteStatsConfig config;
  const SectionContextStats({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow:         config.eyebrow,
        headline:        config.heading,
        subline:         config.subheading,
        maxSublineWidth: 560,
      ),
      SizedBox(height: AppSpacing.xl),
      Container(
        padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: AppRadius.cardBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: config.stats.asMap().entries.map((entry) {
            final stat   = entry.value;
            final isLast = entry.key == config.stats.length - 1;
            return Expanded(child: Row(children: [
              Expanded(child: _CountingStatCell(stat: stat)),
              if (!isLast)
                Container(
                  width: 1, height: 40, color: AppColors.border,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
            ]));
          }).toList(),
        ),
      ),
    ]);
  }
}

class _CountingStatCell extends StatefulWidget {
  final SpaceSiteStat stat;
  const _CountingStatCell({required this.stat});

  @override
  State<_CountingStatCell> createState() => _CountingStatCellState();
}

class _CountingStatCellState extends State<_CountingStatCell>
    with SingleTickerProviderStateMixin {

  static const Duration _kStartDelay    = Duration(milliseconds: 1400);
  static const Duration _kCountDuration = Duration(milliseconds: 1600);

  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _kCountDuration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(_kStartDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final current = (_anim.value * widget.stat.numericValue).round();
        final label   = _anim.isCompleted
            ? widget.stat.display
            : '$current${widget.stat.suffix}';
        return Column(children: [
          ShaderMask(
            shaderCallback: (b) => AppGradients.button.createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(label, style: AppTypography.h1.copyWith(
                fontSize: 36, fontWeight: FontWeight.w800)),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(widget.stat.label, textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(fontSize: 12, height: 1.4)),
        ]);
      },
    );
  }
}