// lib/features/site/home/widgets/site_trusted_strip.dart
import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../site_config.dart';

const double _kChipWidth  = 134.0;
const double _kChipGap    = 14.0;
const double _kStripHeight = 44.0;

class SiteTrustedStrip extends StatefulWidget {
  final SiteTrustedConfig config;
  const SiteTrustedStrip({super.key, required this.config});

  @override
  State<SiteTrustedStrip> createState() => _SiteTrustedStripState();
}

class _SiteTrustedStripState extends State<SiteTrustedStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  double get _cycleWidth =>
      widget.config.logos.length * (_kChipWidth + _kChipGap);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.config.scrollDuration)
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final logoColor = AppColors.primary.withAlpha(135);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(widget.config.label,
              style: AppTypography.overline.copyWith(color: AppColors.textMuted)),
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          height: _kStripHeight,
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(55),
            borderRadius: AppRadius.cardBR,
          ),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final shift = -_cycleWidth * _ctrl.value;
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0, maxWidth: double.infinity,
                  child: Transform.translate(
                    offset: Offset(shift, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(2, (_) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.config.logos.map((name) => Padding(
                          padding: const EdgeInsets.only(right: _kChipGap),
                          child: SizedBox(
                            width: _kChipWidth, height: _kStripHeight,
                            child: Center(
                              child: Text(name,
                                maxLines: 1, overflow: TextOverflow.fade,
                                softWrap: false, textAlign: TextAlign.center,
                                style: AppTypography.overline.copyWith(
                                  color: logoColor, fontSize: 12,
                                  letterSpacing: 1.2, fontWeight: FontWeight.w700,
                                )),
                            ),
                          ),
                        )).toList(),
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}