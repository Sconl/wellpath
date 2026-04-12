// lib/features/site/home/widgets/site_features.dart
import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_motion.dart';
import '../../site_config.dart';
import 'site_shared.dart';

const double _kWideBreakpoint = 700.0;

class SiteFeatureHighlights extends StatelessWidget {
  final SiteFeaturesConfig config;
  const SiteFeatureHighlights({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow:  config.eyebrow,
        headline: config.heading,
        subline:  config.subheading,
      ),
      SizedBox(height: AppSpacing.xxl),
      LayoutBuilder(builder: (_, constraints) {
        final cols = constraints.maxWidth > _kWideBreakpoint ? 2 : 1;
        return _FeatureGrid(columns: cols, features: config.features);
      }),
    ]);
  }
}

class _FeatureGrid extends StatelessWidget {
  final int columns;
  final List<SiteFeature> features;
  const _FeatureGrid({required this.columns, required this.features});

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: features.map((f) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _FeatureCard(feature: f),
        )).toList(),
      );
    }
    final rows = (features.length / columns).ceil();
    return Column(
      children: List.generate(rows, (row) {
        final start = row * columns;
        final end   = (start + columns).clamp(0, features.length);
        final items = features.sublist(start, end);
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left:  e.key == 0 ? 0 : AppSpacing.sm,
                  right: e.key == items.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: _FeatureCard(feature: e.value),
              ),
            )).toList(),
          ),
        );
      }),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final SiteFeature feature;
  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  Color get _accent => widget.feature.useSecondaryAccent
      ? AppColors.secondary
      : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedGradientBorder(
        isActive:     _hovered,
        borderRadius: AppRadius.cardBR,
        gradient:     widget.feature.useSecondaryAccent
            ? LinearGradient(colors: [AppColors.secondary, AppColors.primary])
            : null, // defaults to AppGradients.button
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.all(AppSpacing.lg),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceMid : AppColors.surface,
            borderRadius: AppRadius.cardBR,
            boxShadow: _hovered
                ? [BoxShadow(
                    color: _accent.withAlpha(30),
                    blurRadius: 20, spreadRadius: 1)]
                : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: _accent.withAlpha(_hovered ? 40 : 20),
                borderRadius: AppRadius.cardBR,
              ),
              child: Icon(widget.feature.icon, size: 26, color: _accent),
            ),
            SizedBox(height: AppSpacing.md),
            Text(widget.feature.title,
                style: AppTypography.h4.copyWith(fontSize: 17)),
            SizedBox(height: AppSpacing.sm),
            Text(widget.feature.body,
                style: AppTypography.bodySmall.copyWith(height: 1.65)),
          ]),
        ),
      ),
    );
  }
}