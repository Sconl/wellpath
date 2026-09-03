// lib/core/style/app_canvas.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v2.1 — Added showDepthMesh parameter.
//          When true, renders 4 subtle radial-gradient zones that create
//          perceived depth — a near highlight (top), mid-ground ambient
//          (centre-left), and far-field tint (bottom-right). These zones
//          make parallax translation feel 3-D rather than flat.
//          All colors derived from AppColors/AppGradients — no hardcoded values.
//          meshIntensity controls overall opacity of depth zones (default 1.0).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';

import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const bool kDefaultShowParticles = false;
const bool kDefaultShowGradient  = true;

const int    kDefaultParticleCount = 40;
const double kParticleRadiusMin    = 2.0;
const double kParticleRadiusMax    = 8.0;
const int    kParticleAlpha        = 46;

const double kOrbitRadius              = 30.0;
const int    kConstellationConnections = 3;

const double kPulseGradientPeak    = 0.35;
const double kSweepSpeedMultiplier = 1.0;

const Duration kDefaultGradientDuration = Duration(seconds: 8);
const Duration kDefaultParticleDuration = Duration(seconds: 6);

// Depth-mesh zone intensities (alpha fractions, 0–1)
// Keep these very subtle — they layer on top of the gradient.
const double _kDepthNearAlpha   = 0.06;  // subtle top highlight
const double _kDepthMidAlpha    = 0.04;  // faint mid-ground tint
const double _kDepthFarAlpha    = 0.05;  // distant corner darkening
const double _kDepthAccentAlpha = 0.03;  // warm accent whisper

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum BackgroundType { meshParticle, constellation, aurora, noise, topography, grid }
enum ParticleStyle  { drift, orbit, pulse, rain, snow }
enum GradientStyle  { pulse, sweep, mesh, solid }


// ─────────────────────────────────────────────────────────────────────────────
// AppCanvas
// ─────────────────────────────────────────────────────────────────────────────

class AppCanvas extends StatefulWidget {
  final Widget child;
  final BackgroundType type;
  final ParticleStyle particleStyle;
  final GradientStyle gradientStyle;
  final int particleCount;
  final bool showParticles;
  final bool showGradient;

  /// When true, adds subtle radial-gradient depth zones that make parallax
  /// scrolling feel more three-dimensional. Keep meshIntensity ≤ 1.0.
  final bool showDepthMesh;

  /// Scales all depth-zone opacities. 1.0 = defaults above. 0 = invisible.
  final double meshIntensity;

  final Duration gradientDuration;
  final Duration particleDuration;

  const AppCanvas({
    super.key,
    required this.child,
    this.type             = BackgroundType.constellation,
    this.particleStyle    = ParticleStyle.rain,
    this.gradientStyle    = GradientStyle.pulse,
    this.particleCount    = kDefaultParticleCount,
    this.showParticles    = kDefaultShowParticles,
    this.showGradient     = kDefaultShowGradient,
    this.showDepthMesh    = false,
    this.meshIntensity    = 1.0,
    this.gradientDuration = kDefaultGradientDuration,
    this.particleDuration = kDefaultParticleDuration,
  });

  @override
  State<AppCanvas> createState() => _AppCanvasState();
}

class _AppCanvasState extends State<AppCanvas> with TickerProviderStateMixin {

  late final AnimationController _gradientCtrl;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this, duration: widget.gradientDuration)..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this, duration: widget.particleDuration)..repeat();
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaceholder(widget.type)) {
      return _PlaceholderCanvas(type: widget.type, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [

            // Layer 1 — gradient
            widget.showGradient
                ? _GradientLayer(
                    gradientStyle: widget.gradientStyle,
                    progress:      _gradientCtrl.value,
                  )
                : Container(color: AppColors.background),

            // Layer 2 — depth mesh zones (subtle radial gradients)
            if (widget.showDepthMesh)
              _DepthMeshOverlay(intensity: widget.meshIntensity),

            // Layer 3 — particles
            if (widget.showParticles &&
                widget.type == BackgroundType.meshParticle)
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(
                    progress:      _particleCtrl.value,
                    style:         widget.particleStyle,
                    count:         widget.particleCount,
                    particleColor: AppColors.primary,
                  ),
                ),
              ),

            if (widget.showParticles &&
                widget.type == BackgroundType.constellation)
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConstellationPainter(
                    progress:  _particleCtrl.value,
                    nodeCount: widget.particleCount,
                    nodeColor: AppColors.primary,
                    lineColor: AppColors.secondary,
                  ),
                ),
              ),

            // Layer 4 — content
            widget.child,
          ],
        );
      },
    );
  }

  bool _isPlaceholder(BackgroundType t) =>
      t == BackgroundType.aurora     ||
      t == BackgroundType.noise      ||
      t == BackgroundType.topography ||
      t == BackgroundType.grid;
}


// ─────────────────────────────────────────────────────────────────────────────
// _DepthMeshOverlay
// ─────────────────────────────────────────────────────────────────────────────
//
// Four radial gradient zones create a subtle depth map:
//
//   NEAR ZONE   (top-left)    — bright primary highlight: simulates a light
//                               source in the foreground, closest to viewer.
//   MID ZONE    (centre-left) — surfaceLit tint: mid-ground ambient scatter.
//   FAR ZONE    (bottom-right) — primaryDeep: far-field darkening.
//   ACCENT ZONE (top-right)   — secondary whisper: atmospheric colour cast.
//
// Parallax moves the canvas beneath the content. Because each zone is at a
// different canvas position, the parallax translation appears to move distinct
// "depth layers" — making the effect perceivably 3-D.
//
// All alphas are intentionally very low. The effect should be felt, not seen.

class _DepthMeshOverlay extends StatelessWidget {
  final double intensity;
  const _DepthMeshOverlay({required this.intensity});

  int _alpha(double fraction) =>
      (255 * fraction * intensity.clamp(0.0, 1.0)).round().clamp(0, 255);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Near zone — top-left light source
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.8),
              radius: 1.1,
              colors: [
                AppColors.primaryLight.withAlpha(_alpha(_kDepthNearAlpha)),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Mid-ground zone — centre-left ambient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.2, 0.1),
              radius: 0.75,
              colors: [
                AppColors.surfaceLit.withAlpha(_alpha(_kDepthMidAlpha)),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Far zone — bottom-right depth darkening
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.85, 0.90),
              radius: 1.2,
              colors: [
                AppColors.primaryDeep.withAlpha(_alpha(_kDepthFarAlpha)),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Accent zone — top-right atmospheric cast
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.75, -0.65),
              radius: 0.85,
              colors: [
                AppColors.secondary.withAlpha(_alpha(_kDepthAccentAlpha)),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _GradientLayer
// ─────────────────────────────────────────────────────────────────────────────

class _GradientLayer extends StatelessWidget {
  final GradientStyle gradientStyle;
  final double progress;

  const _GradientLayer({required this.gradientStyle, required this.progress});

  @override
  Widget build(BuildContext context) {
    switch (gradientStyle) {

      case GradientStyle.pulse:
        final start = Color.lerp(
          AppColors.background, AppColors.surfaceMid,
          progress * kPulseGradientPeak,
        )!;
        final end = Color.lerp(
          AppColors.backgroundAlt, AppColors.primaryDeep,
          progress * kPulseGradientPeak * 0.6,
        )!;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [start, end],
            ),
          ),
        );

      case GradientStyle.sweep:
        final angle = progress * 2 * pi * kSweepSpeedMultiplier;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment(cos(angle), sin(angle)),
              end:    Alignment(-cos(angle), -sin(angle)),
              colors: [AppColors.background, AppColors.surfaceLit, AppColors.primaryDeep],
              stops:  const [0.0, 0.6, 1.0],
            ),
          ),
        );

      case GradientStyle.mesh:
        return Stack(fit: StackFit.expand, children: [
          Container(color: AppColors.background),
          Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),
          Container(decoration: BoxDecoration(gradient: AppGradients.meshSecondary)),
        ]);

      case GradientStyle.solid:
        return Container(color: AppColors.background);
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ParticlePainter — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  final ParticleStyle style;
  final int count;
  final Color particleColor;

  _ParticlePainter({
    required this.progress, required this.style,
    required this.count, required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case ParticleStyle.drift: _paintDrift(canvas, size); break;
      case ParticleStyle.orbit: _paintOrbit(canvas, size); break;
      case ParticleStyle.pulse: _paintPulse(canvas, size); break;
      case ParticleStyle.rain:  _paintRain(canvas, size);  break;
      case ParticleStyle.snow:  _paintSnow(canvas, size);  break;
    }
  }

  Paint _paint(double alpha) => Paint()
    ..color = particleColor.withAlpha((kParticleAlpha * alpha).round().clamp(0, 255));

  void _paintDrift(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final dx = (size.width / count) * i + sin(progress * pi * 2 + i) * 40;
      final dy = (size.height * progress + i * (size.height / count)) % size.height;
      final r  = kParticleRadiusMin + sin(progress * pi + i).abs() * (kParticleRadiusMax - kParticleRadiusMin);
      canvas.drawCircle(Offset(dx, dy), r, _paint(1.0));
    }
  }

  void _paintOrbit(Canvas canvas, Size size) {
    final cols = sqrt(count.toDouble()).ceil();
    final rows = (count / cols).ceil();
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (int i = 0; i < count; i++) {
      final ax = cellW * (i % cols) + cellW / 2;
      final ay = cellH * (i ~/ cols) + cellH / 2;
      final ph = progress * 2 * pi + i * 0.8;
      final r  = kParticleRadiusMin + sin(ph * 0.5).abs() * (kParticleRadiusMax - kParticleRadiusMin);
      canvas.drawCircle(Offset(ax + cos(ph) * kOrbitRadius, ay + sin(ph) * kOrbitRadius), r, _paint(1.0));
    }
  }

  void _paintPulse(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final dx = (size.width / count) * i + (i % 5) * 15.0;
      final dy = (size.height / count) * (count - i) + (i % 3) * 20.0;
      final ph = progress * 2 * pi + i * pi / count * 4;
      canvas.drawCircle(
        Offset(dx % size.width, dy % size.height),
        kParticleRadiusMin + sin(ph).abs() * (kParticleRadiusMax - kParticleRadiusMin),
        _paint(0.3 + sin(ph).abs() * 0.7));
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final so = (i * 0.07) % 1.0;
      final dx = (i * (size.width / count) + i * 37) % size.width;
      final dy = size.height * ((progress + so) % 1.0);
      canvas.drawCircle(Offset(dx, dy), kParticleRadiusMin + (i % 3) * 1.0,
          _paint(sin((dy / size.height) * pi).clamp(0.0, 1.0)));
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final speed = 0.2 + (i * 0.03) % 0.8;
      final sway  = sin(progress * pi * 2 + i * 1.3) * 20;
      final sx    = (i * (size.width / count) + i * 23) % size.width;
      final dx    = (sx + sway + progress * size.width * 0.15) % size.width;
      final dy    = size.height * ((progress * speed + i * 0.1) % 1.0);
      final r     = kParticleRadiusMin + sin(i.toDouble()).abs() * (kParticleRadiusMax - kParticleRadiusMin) * 0.5;
      canvas.drawCircle(Offset(dx, dy), r, _paint(0.6 + sin(progress * pi + i).abs() * 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress || old.style != style;
}


// ─────────────────────────────────────────────────────────────────────────────
// _ConstellationPainter — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _ConstellationPainter extends CustomPainter {
  final double progress;
  final int nodeCount;
  final Color nodeColor;
  final Color lineColor;
  late final List<Offset> _basePositions;

  _ConstellationPainter({
    required this.progress, required this.nodeCount,
    required this.nodeColor, required this.lineColor,
  }) {
    _basePositions = List.generate(nodeCount, (i) => Offset(
      ((i * 127 + 43) % 1000) / 1000.0,
      ((i * 311 + 97) % 1000) / 1000.0,
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()..color = nodeColor.withAlpha(kParticleAlpha + 20);
    final linePaint = Paint()
      ..color       = lineColor.withAlpha((kParticleAlpha * 0.5).round())
      ..strokeWidth = 0.6;

    final positions = _basePositions.map((base) => Offset(
      (base.dx + sin(progress * 2 * pi + base.dy * 10) * 0.03) * size.width,
      (base.dy + cos(progress * 2 * pi + base.dx * 10) * 0.02) * size.height,
    )).toList();

    for (int i = 0; i < positions.length; i++) {
      final others = List<int>.generate(positions.length, (j) => j)
        ..remove(i)
        ..sort((a, b) => (positions[a] - positions[i]).distance
            .compareTo((positions[b] - positions[i]).distance));
      for (int k = 0; k < kConstellationConnections && k < others.length; k++) {
        final dist    = (positions[others[k]] - positions[i]).distance;
        final maxDist = size.width * 0.25;
        if (dist < maxDist) {
          canvas.drawLine(positions[i], positions[others[k]],
            linePaint..color = lineColor.withAlpha(
              ((1.0 - dist / maxDist) * (kParticleAlpha * 0.5)).round().clamp(0, 255)));
        }
      }
    }
    for (final pos in positions) {
      canvas.drawCircle(pos, kParticleRadiusMin + 1, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) => old.progress != progress;
}


// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderCanvas — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderCanvas extends StatelessWidget {
  final BackgroundType type;
  final Widget child;
  const _PlaceholderCanvas({required this.type, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(color: AppColors.background),
      Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),
      Positioned(right: 12, bottom: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:        AppColors.tint10(AppColors.warning),
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border:       Border.all(color: AppColors.tint20(AppColors.warning)),
          ),
          child: Text('Canvas: ${type.name} — not yet implemented',
            style: AppTypography.caption.copyWith(color: AppColors.warning, fontSize: 9)),
        )),
      child,
    ]);
  }
}