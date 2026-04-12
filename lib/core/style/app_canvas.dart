// lib/core/style/app_canvas.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial rewrite — wired to theme.dart, all colors from AppColors — Sconl Peter
//   • Replaced hardcoded Color literals with AppColors throughout
//   • Added BackgroundType enum — 6 background modes (2 active, 4 placeholder)
//   • Added ParticleStyle enum — 5 particle behaviours
//   • Added GradientStyle enum — 4 gradient animation modes
//   • Config block added at top per codespace Rule 7
//   • Added showParticles and showGradient boolean toggles for per-page control
//   • Confirmed compatible with app_branding → app_theme dependency chain.
//     This file imports only app_theme.dart — AppColors and AppGradients
//     resolve correctly because app_theme.dart reads BrandColors upstream.
//   • File renamed: app_background.dart → app_canvas.dart
//   • Class renamed: AppBackground → AppCanvas (matches file name)
//   • File path updated: lib/core/theme/ → lib/core/style/
// ─────────────────────────────────────────────────────────────────────────────

// HOW TO USE:
//
//   Simplest:
//     AppCanvas(child: YourScreen())
//
//   Full options:
//     AppCanvas(
//       type:          BackgroundType.meshParticle,
//       particleStyle: ParticleStyle.drift,
//       gradientStyle: GradientStyle.pulse,
//       child:         YourScreen(),
//     )
//
//   Per-page motion toggles:
//     AppCanvas(showParticles: false, child: ...)        // gradient only
//     AppCanvas(showGradient: false, child: ...)         // solid base + particles
//     AppCanvas(showParticles: false, showGradient: false, child: ...) // plain branded bg
//
//   Placeholder types (branded base + debug label):
//     AppCanvas(type: BackgroundType.aurora,     child: ...)
//     AppCanvas(type: BackgroundType.noise,      child: ...)
//     AppCanvas(type: BackgroundType.topography, child: ...)
//     AppCanvas(type: BackgroundType.grid,       child: ...)

import 'dart:math';
import 'package:flutter/material.dart';

import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ── Per-page toggle defaults ──────────────────────────────────────────────────
const bool kDefaultShowParticles = false;
const bool kDefaultShowGradient  = true;

// ── Particle defaults ─────────────────────────────────────────────────────────
const int    kDefaultParticleCount = 40;
const double kParticleRadiusMin    = 2.0;
const double kParticleRadiusMax    = 8.0;

// ~18% opacity — subtle enough to feel like depth without distracting from content.
const int kParticleAlpha = 46;

const double kOrbitRadius              = 30.0;
const int    kConstellationConnections = 3;

// ── Gradient defaults ─────────────────────────────────────────────────────────
// 0.35 peak — you feel the pulse, you don't consciously see it.
const double kPulseGradientPeak    = 0.35;
const double kSweepSpeedMultiplier = 1.0;

// ── Animation durations ───────────────────────────────────────────────────────
// 8s gradient + 6s particle feel organic — like breathing, not restless.
const Duration kDefaultGradientDuration = Duration(seconds: 8);
const Duration kDefaultParticleDuration = Duration(seconds: 6);

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// The overall background visual type.
///
/// [meshParticle]  — animated gradient + floating particle field. Default.
/// [constellation] — connected node network drifting slowly.
/// [aurora]        — PLACEHOLDER: slow flowing horizontal light bands.
/// [noise]         — PLACEHOLDER: animated grain/noise texture overlay.
/// [topography]    — PLACEHOLDER: subtle contour / topographic line patterns.
/// [grid]          — PLACEHOLDER: animated dot-grid or line-grid.
enum BackgroundType { meshParticle, constellation, aurora, noise, topography, grid }

/// Controls how particles move within [BackgroundType.meshParticle].
///
/// [drift]  — upward float with gentle sine sway. Original WellPath behaviour.
/// [orbit]  — each particle orbits a fixed anchor in a circle.
/// [pulse]  — particles stay in place and grow/shrink rhythmically.
/// [rain]   — particles fall downward, reset at top when they exit.
/// [snow]   — slow diagonal drift, randomised speed per particle.
enum ParticleStyle { drift, orbit, pulse, rain, snow }

/// Controls how the background gradient animates.
///
/// [pulse]  — lerps between background and lighter brand tone. Default.
/// [sweep]  — gradient alignment slowly rotates around 360°.
/// [mesh]   — static dual-radial mesh from AppGradients. No animation.
/// [solid]  — flat AppColors.background. No gradient.
enum GradientStyle { pulse, sweep, mesh, solid }


// ─────────────────────────────────────────────────────────────────────────────
// AppCanvas
// ─────────────────────────────────────────────────────────────────────────────

/// WellPath's animated visual canvas widget.
///
/// Drop around any Scaffold body for the full effect with zero configuration.
/// Use [showParticles] and [showGradient] for per-page motion control.
///
/// All colors derive from AppColors → BrandColors in app_branding.dart.
/// Change the brand seeds there and the canvas regenerates automatically.
class AppCanvas extends StatefulWidget {
  final Widget child;
  final BackgroundType type;
  final ParticleStyle particleStyle;
  final GradientStyle gradientStyle;
  final int particleCount;

  /// Set false to skip the particle layer on this page. Gradient still renders.
  final bool showParticles;

  /// Set false to render a plain solid background. Use on visually dense pages.
  final bool showGradient;

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
      vsync: this, duration: widget.gradientDuration,
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this, duration: widget.particleDuration,
    )..repeat();
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

            // Layer 1 — gradient or solid fallback
            widget.showGradient
                ? _GradientLayer(
                    gradientStyle: widget.gradientStyle,
                    progress:      _gradientCtrl.value,
                  )
                : Container(color: AppColors.background),

            // Layer 2 — particle field (skipped entirely when showParticles is
            // false — no wasted CustomPaint per frame with nothing to draw)
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

            // Layer 3 — content always on top
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
        // Lerps from the dark base toward a lighter brand tone on each cycle.
        // At progress 0.0 → dark base. At kPulseGradientPeak → surfaceMid.
        // Feels like the screen is breathing.
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
        // Gradient alignment traces a circle — light source appears to rotate.
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
        // Static dual-radial bloom — calmer, for content-heavy pages.
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.background),
            Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),
            Container(decoration: BoxDecoration(gradient: AppGradients.meshSecondary)),
          ],
        );

      case GradientStyle.solid:
        return Container(color: AppColors.background);
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ParticlePainter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  final ParticleStyle style;
  final int count;
  final Color particleColor;

  _ParticlePainter({
    required this.progress,
    required this.style,
    required this.count,
    required this.particleColor,
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
    ..color = particleColor.withAlpha(
        (kParticleAlpha * alpha).round().clamp(0, 255));

  void _paintDrift(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final dx     = (size.width / count) * i + sin(progress * pi * 2 + i) * 40;
      final dy     = (size.height * progress + i * (size.height / count)) % size.height;
      final radius = kParticleRadiusMin +
          (sin(progress * pi + i).abs() * (kParticleRadiusMax - kParticleRadiusMin));
      canvas.drawCircle(Offset(dx, dy), radius, _paint(1.0));
    }
  }

  void _paintOrbit(Canvas canvas, Size size) {
    final cols  = sqrt(count.toDouble()).ceil();
    final rows  = (count / cols).ceil();
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (int i = 0; i < count; i++) {
      final anchorX = cellW * (i % cols) + cellW / 2;
      final anchorY = cellH * (i ~/ cols) + cellH / 2;
      final phase   = progress * 2 * pi + i * 0.8;
      final radius  = kParticleRadiusMin +
          sin(phase * 0.5).abs() * (kParticleRadiusMax - kParticleRadiusMin);
      canvas.drawCircle(
        Offset(anchorX + cos(phase) * kOrbitRadius,
               anchorY + sin(phase) * kOrbitRadius),
        radius, _paint(1.0),
      );
    }
  }

  void _paintPulse(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final dx    = (size.width  / count) * i + (i % 5) * 15.0;
      final dy    = (size.height / count) * (count - i) + (i % 3) * 20.0;
      final phase = progress * 2 * pi + i * pi / count * 4;
      canvas.drawCircle(
        Offset(dx % size.width, dy % size.height),
        kParticleRadiusMin + sin(phase).abs() * (kParticleRadiusMax - kParticleRadiusMin),
        _paint(0.3 + sin(phase).abs() * 0.7),
      );
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final speedOffset = (i * 0.07) % 1.0;
      final dx    = (i * (size.width / count) + i * 37) % size.width;
      final dy    = size.height * ((progress + speedOffset) % 1.0);
      final alpha = sin((dy / size.height) * pi).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(dx, dy),
          kParticleRadiusMin + (i % 3) * 1.0, _paint(alpha));
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final speed  = 0.2 + (i * 0.03) % 0.8;
      final sway   = sin(progress * pi * 2 + i * 1.3) * 20;
      final startX = (i * (size.width / count) + i * 23) % size.width;
      final dx     = (startX + sway + progress * size.width * 0.15) % size.width;
      final dy     = size.height * ((progress * speed + i * 0.1) % 1.0);
      final radius = kParticleRadiusMin +
          sin(i.toDouble()).abs() * (kParticleRadiusMax - kParticleRadiusMin) * 0.5;
      canvas.drawCircle(Offset(dx, dy), radius,
          _paint(0.6 + sin(progress * pi + i).abs() * 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress || old.style != style;
}


// ─────────────────────────────────────────────────────────────────────────────
// _ConstellationPainter
// ─────────────────────────────────────────────────────────────────────────────

class _ConstellationPainter extends CustomPainter {
  final double progress;
  final int nodeCount;
  final Color nodeColor;
  final Color lineColor;
  late final List<Offset> _basePositions;

  _ConstellationPainter({
    required this.progress,
    required this.nodeCount,
    required this.nodeColor,
    required this.lineColor,
  }) {
    // Prime multipliers give good distribution without a Random instance.
    _basePositions = List.generate(nodeCount, (i) => Offset(
      ((i * 127 + 43) % 1000) / 1000.0,
      ((i * 311 + 97) % 1000) / 1000.0,
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = nodeColor.withAlpha(kParticleAlpha + 20);
    final linePaint = Paint()
      ..color       = lineColor.withAlpha((kParticleAlpha * 0.5).round())
      ..strokeWidth = 0.6;

    final positions = _basePositions.map((base) {
      return Offset(
        (base.dx + sin(progress * 2 * pi + base.dy * 10) * 0.03) * size.width,
        (base.dy + cos(progress * 2 * pi + base.dx * 10) * 0.02) * size.height,
      );
    }).toList();

    for (int i = 0; i < positions.length; i++) {
      final others = List<int>.generate(positions.length, (j) => j)
        ..remove(i)
        ..sort((a, b) => (positions[a] - positions[i])
            .distance
            .compareTo((positions[b] - positions[i]).distance));

      for (int k = 0; k < kConstellationConnections && k < others.length; k++) {
        final dist    = (positions[others[k]] - positions[i]).distance;
        final maxDist = size.width * 0.25;
        if (dist < maxDist) {
          canvas.drawLine(
            positions[i], positions[others[k]],
            linePaint..color = lineColor.withAlpha(
              ((1.0 - dist / maxDist) * (kParticleAlpha * 0.5)).round().clamp(0, 255),
            ),
          );
        }
      }
    }

    for (final pos in positions) {
      canvas.drawCircle(pos, kParticleRadiusMin + 1, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.progress != progress;
}


// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderCanvas
// ─────────────────────────────────────────────────────────────────────────────
//
// Branded base so the app doesn't break while types are unimplemented.
// Remove the debug Positioned label when implementing each type.

class _PlaceholderCanvas extends StatelessWidget {
  final BackgroundType type;
  final Widget child;

  const _PlaceholderCanvas({required this.type, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.background),
        Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),

        // Debug label — remove this Positioned block when implementing the type
        Positioned(
          right:  12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        AppColors.tint10(AppColors.warning),
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border:       Border.all(color: AppColors.tint20(AppColors.warning)),
            ),
            child: Text(
              'Canvas: ${type.name} — not yet implemented',
              style: AppTypography.caption.copyWith(color: AppColors.warning, fontSize: 9),
            ),
          ),
        ),

        child,
      ],
    );
  }
}