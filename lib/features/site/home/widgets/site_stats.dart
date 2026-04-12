// lib/features/site/home/widgets/site_stats.dart
import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../site_config.dart';
import 'site_shared.dart';

class SiteStatsStrip extends StatelessWidget {
  final SiteStatsConfig config;
  const SiteStatsStrip({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow:  config.eyebrow,
        headline: config.heading,
        subline:  config.subheading,
        maxSublineWidth: 560,
      ),
      SizedBox(height: AppSpacing.xl),
      Container(
        padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: config.stats.asMap().entries.map((entry) {
            final stat   = entry.value;
            final isLast = entry.key == config.stats.length - 1;
            return Expanded(child: Row(children: [
              Expanded(child: _StatCell(stat: stat)),
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

class _StatCell extends StatelessWidget {
  final SiteStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ShaderMask(
        shaderCallback: (b) => AppGradients.button.createShader(b),
        blendMode: BlendMode.srcIn,
        child: Text(stat.value,
            style: AppTypography.h1.copyWith(
                fontSize: 36, fontWeight: FontWeight.w800)),
      ),
      SizedBox(height: AppSpacing.xs),
      Text(stat.label, textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(fontSize: 12, height: 1.4)),
    ]);
  }
}