// lib/core/theme/app_background.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial rewrite — wired to theme.dart, all colors from AppColors — Sconl Peter
//   • Replaced hardcoded Color literals with AppColors throughout
//   • Added BackgroundType enum — 6 background modes (2 active, 4 placeholder)
//   • Added ParticleStyle enum — 5 particle behaviours
//   • Added GradientStyle enum — 4 gradient animation modes
//   • Config block added at top per codespace Rule 7
// ─────────────────────────────────────────────────────────────────────────────

// HOW TO USE:
//
//   Simplest — just drop it around your Scaffold body:
//
//     AppBackground(child: YourScreen())
//
//   With options:
//
//     AppBackground(
//       type:           BackgroundType.meshParticle,  // default
//       particleStyle:  ParticleStyle.drift,          // default
//       gradientStyle:  GradientStyle.pulse,          // default
//       particleCount:  40,                           // default
//       child:          YourScreen(),
//     )
//
//   Placeholder types (render a solid branded background + TODO label):
//
//     AppBackground(type: BackgroundType.aurora,    child: ...)
//     AppBackground(type: BackgroundType.noise,     child: ...)
//     AppBackground(type: BackgroundType.topography,child: ...)
//     AppBackground(type: BackgroundType.grid,      child: ...)

import 'dart:math';
import 'package:flutter/material.dart';

import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK — all tunable defaults live here
// ─────────────────────────────────────────────────────────────────────────────

// ── Particle defaults ─────────────────────────────────────────────────────────

// How many particles are drawn by default. Raise for denser fields,
// lower for performance on weaker devices.
const int kDefaultParticleCount = 40;

// Default radius range for particles. Min and max are chosen by the painter —
// this drives the noise passed to each one.
const double kParticleRadiusMin = 2.0;
const double kParticleRadiusMax = 8.0;

// Base opacity for all particle types. 0.18 is subtle enough to feel like
// depth rather than a UI distraction.
const int kParticleAlpha = 46; // ~18% of 255

// Orbit radius for the OrbitParticle style — how far each particle
// circles from its base position.
const double kOrbitRadius = 30.0;

// How many constellation connections each node draws to its nearest neighbours.
const int kConstellationConnections = 3;

// ── Gradient defaults ─────────────────────────────────────────────────────────

// How much the pulse gradient shifts toward the brand accent at its peak.
// 0.0 = stays at background. 1.0 = fully transitions to primary color.
// 0.35 is subtle and professional — you feel it, you don't see it.
const double kPulseGradientPeak = 0.35;

// Sweep gradient rotation speed multiplier. Higher = faster spin.
const double kSweepSpeedMultiplier = 1.0;

// ── Animation durations ───────────────────────────────────────────────────────

// Gradient pulse cycle. 8s feels organic — like breathing.
const Duration kDefaultGradientDuration = Duration(seconds: 8);

// Particle cycle. 6s keeps motion alive without feeling restless.
const Duration kDefaultParticleDuration = Duration(seconds: 6);

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// ENUMS — the public API for switching modes
// ─────────────────────────────────────────────────────────────────────────────

/// The overall background visual type.
///
/// [meshParticle]  — animated gradient + floating particle field. Default.
/// [constellation] — connected node network drifting slowly across the screen.
/// [aurora]        — PLACEHOLDER: slow flowing horizontal light bands.
/// [noise]         — PLACEHOLDER: animated grain/noise texture overlay.
/// [topography]    — PLACEHOLDER: subtle contour / topographic line patterns.
/// [grid]          — PLACEHOLDER: subtle animated dot-grid or line-grid.
enum BackgroundType {
  meshParticle,
  constellation,
  aurora,        // placeholder
  noise,         // placeholder
  topography,    // placeholder
  grid,          // placeholder
}

/// Controls how particles move within [BackgroundType.meshParticle].
///
/// [drift]  — particles float upward with a gentle sine sway. Original behaviour.
/// [orbit]  — each particle orbits a fixed anchor point in a circle.
/// [pulse]  — particles stay in place and grow/shrink rhythmically.
/// [rain]   — particles fall downward, reset to top when they exit.
/// [snow]   — slow diagonal drift, randomised speed per particle.
enum ParticleStyle {
  drift,
  orbit,
  pulse,
  rain,
  snow,
}

/// Controls how the background gradient animates.
///
/// [pulse]  — lerps between background and a lighter brand tone. Default.
/// [sweep]  — the gradient slowly rotates its alignment around 360°.
/// [mesh]   — uses the static dual-radial mesh from AppGradients. No animation.
/// [solid]  — flat AppColors.background. No gradient at all.
enum GradientStyle {
  pulse,
  sweep,
  mesh,
  solid,
}


// ─────────────────────────────────────────────────────────────────────────────
// AppBackground — the public widget
// ─────────────────────────────────────────────────────────────────────────────

/// WellPath's animated background widget.
///
/// All visual parameters have sensible defaults — drop [AppBackground] around
/// any Scaffold body for the full effect with zero configuration.
///
/// All colors are derived from [AppColors] so the background automatically
/// updates when the brand seeds in theme.dart change.
class AppBackground extends StatefulWidget {
  final Widget child;

  /// Overall background type. See [BackgroundType] for options.
  final BackgroundType type;

  /// Particle movement style. Only applies to [BackgroundType.meshParticle].
  final ParticleStyle particleStyle;

  /// Gradient animation mode. Applies to all types that show a gradient.
  final GradientStyle gradientStyle;

  /// Number of particles / nodes to render. See [kDefaultParticleCount].
  final int particleCount;

  /// Gradient animation cycle duration.
  final Duration gradientDuration;

  /// Particle animation cycle duration.
  final Duration particleDuration;

  const AppBackground({
    super.key,
    required this.child,
    this.type            = BackgroundType.meshParticle,
    this.particleStyle   = ParticleStyle.drift,
    this.gradientStyle   = GradientStyle.pulse,
    this.particleCount   = kDefaultParticleCount,
    this.gradientDuration = kDefaultGradientDuration,
    this.particleDuration = kDefaultParticleDuration,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with TickerProviderStateMixin {

  late final AnimationController _gradientCtrl;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    _gradientCtrl = AnimationController(
      vsync: this,
      duration: widget.gradientDuration,
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: widget.particleDuration,
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
    // Placeholder types get a simple branded base + a debug label.
    // Remove the label and build out the painter when implementing each one.
    if (_isPlaceholder(widget.type)) {
      return _PlaceholderBackground(type: widget.type, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 — gradient background
            _GradientLayer(
              gradientStyle: widget.gradientStyle,
              progress:      _gradientCtrl.value,
            ),

            // Layer 2 — particle / node field
            if (widget.type == BackgroundType.meshParticle)
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

            if (widget.type == BackgroundType.constellation)
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConstellationPainter(
                    progress:     _particleCtrl.value,
                    nodeCount:    widget.particleCount,
                    nodeColor:    AppColors.primary,
                    lineColor:    AppColors.secondary,
                  ),
                ),
              ),

            // Layer 3 — caller's content always on top
            widget.child,
          ],
        );
      },
    );
  }

  bool _isPlaceholder(BackgroundType t) =>
      t == BackgroundType.aurora      ||
      t == BackgroundType.noise       ||
      t == BackgroundType.topography  ||
      t == BackgroundType.grid;
}


// ─────────────────────────────────────────────────────────────────────────────
// _GradientLayer — paints the background gradient
// ─────────────────────────────────────────────────────────────────────────────

class _GradientLayer extends StatelessWidget {
  final GradientStyle gradientStyle;
  final double progress; // 0.0 – 1.0 from the animation controller

  const _GradientLayer({
    required this.gradientStyle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    switch (gradientStyle) {

      // ── Pulse — lerps from Abyss base toward a lighter brand tone ──────────
      // progress drives how much of the primary hue bleeds into the background.
      // At 0.0 you're at the raw background. At kPulseGradientPeak you're at
      // the lightest surface tone. Feels like the screen is breathing.
      case GradientStyle.pulse:
        final gradientStart = Color.lerp(
          AppColors.background,
          AppColors.surfaceMid,
          progress * kPulseGradientPeak,
        )!;
        final gradientEnd = Color.lerp(
          AppColors.backgroundAlt,
          AppColors.primaryDeep,
          progress * kPulseGradientPeak * 0.6,
        )!;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
          ),
        );

      // ── Sweep — gradient alignment rotates slowly around a full circle ─────
      // The alignment pair traces a circle, so the light source appears to
      // rotate around the screen. Subtle at kSweepSpeedMultiplier = 1.0.
      case GradientStyle.sweep:
        final angle = progress * 2 * pi * kSweepSpeedMultiplier;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(cos(angle), sin(angle)),
              end:   Alignment(-cos(angle), -sin(angle)),
              colors: [
                AppColors.background,
                AppColors.surfaceLit,
                AppColors.primaryDeep,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        );

      // ── Mesh — static dual-radial from AppGradients. No animation. ─────────
      // Uses the same mesh pattern as AppDecorations.screenBackground.
      // Good for screens that need a calmer, non-animated feel.
      case GradientStyle.mesh:
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.background),
            Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),
            Container(decoration: BoxDecoration(gradient: AppGradients.meshSecondary)),
          ],
        );

      // ── Solid — flat brand background, zero animation. ─────────────────────
      // Use when the content itself is visually busy and a clean base is better.
      case GradientStyle.solid:
        return Container(color: AppColors.background);
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ParticlePainter — draws the floating particle field
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
      case ParticleStyle.drift:   _paintDrift(canvas, size);  break;
      case ParticleStyle.orbit:   _paintOrbit(canvas, size);  break;
      case ParticleStyle.pulse:   _paintPulse(canvas, size);  break;
      case ParticleStyle.rain:    _paintRain(canvas, size);   break;
      case ParticleStyle.snow:    _paintSnow(canvas, size);   break;
    }
  }

  Paint _paint(double alpha) => Paint()
    ..color = particleColor.withAlpha((kParticleAlpha * alpha).round().clamp(0, 255));

  // ── Drift — upward float with sine sway. Original WellPath behaviour. ──────
  // Each particle travels from bottom to top over one cycle. The sine on dx
  // gives it that organic, unhurried side-to-side motion.
  void _paintDrift(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final dx     = (size.width / count) * i + sin(progress * pi * 2 + i) * 40;
      final dy     = (size.height * progress + i * (size.height / count)) % size.height;
      final radius = kParticleRadiusMin + (sin(progress * pi + i).abs() * (kParticleRadiusMax - kParticleRadiusMin));
      canvas.drawCircle(Offset(dx, dy), radius, _paint(1.0));
    }
  }

  // ── Orbit — each particle circles a fixed anchor in its grid cell. ─────────
  // Anchors are evenly distributed. Phase offset per particle (i * 0.8 rad)
  // staggers them so they don't all hit the same point simultaneously.
  void _paintOrbit(Canvas canvas, Size size) {
    final cols = sqrt(count.toDouble()).ceil();
    final rows = (count / cols).ceil();
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (int i = 0; i < count; i++) {
      final col     = i % cols;
      final row     = i ~/ cols;
      final anchorX = cellW * col + cellW / 2;
      final anchorY = cellH * row + cellH / 2;
      final phase   = progress * 2 * pi + i * 0.8;
      final dx      = anchorX + cos(phase) * kOrbitRadius;
      final dy      = anchorY + sin(phase) * kOrbitRadius;
      final radius  = kParticleRadiusMin + sin(phase * 0.5).abs() * (kParticleRadiusMax - kParticleRadiusMin);
      canvas.drawCircle(Offset(dx, dy), radius, _paint(1.0));
    }
  }

  // ── Pulse — particles stay in place and breathe in/out. ───────────────────
  // The phase offset per particle (i * pi / count * 4) creates a wave effect
  // across the field — particles swell and shrink in a rolling wave pattern.
  void _paintPulse(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final dx    = (size.width  / count) * i + (i % 5) * 15.0;
      final dy    = (size.height / count) * (count - i) + (i % 3) * 20.0;
      final phase = progress * 2 * pi + i * pi / count * 4;
      // Radius breathes between min and max
      final radius = kParticleRadiusMin + (sin(phase).abs() * (kParticleRadiusMax - kParticleRadiusMin));
      // Opacity pulses inversely — smaller = more transparent for depth
      final alpha  = 0.3 + sin(phase).abs() * 0.7;
      canvas.drawCircle(Offset(dx % size.width, dy % size.height), radius, _paint(alpha));
    }
  }

  // ── Rain — particles fall straight down, teleporting back to top. ──────────
  // Each particle has its own speed offset (i * 0.07) so they don't all
  // reset at the same frame. Slight horizontal scatter via (i * 37 % width).
  void _paintRain(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final speedOffset = (i * 0.07) % 1.0;
      final dx     = (i * (size.width / count) + i * 37) % size.width;
      final dy     = (size.height * ((progress + speedOffset) % 1.0));
      final radius = kParticleRadiusMin + (i % 3) * 1.0;
      // Fade in near top, fade out near bottom — avoids hard teleport flash
      final alpha  = sin((dy / size.height) * pi).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(dx, dy), radius, _paint(alpha));
    }
  }

  // ── Snow — slow diagonal drift, each particle at a different speed. ─────────
  // The combination of horizontal drift + vertical sink + gentle sine sway
  // reads as floating snow or ash — organic and calming.
  void _paintSnow(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final speed  = 0.2 + (i * 0.03) % 0.8;
      final sway   = sin(progress * pi * 2 + i * 1.3) * 20;
      final startX = (i * (size.width / count) + i * 23) % size.width;
      final dx     = (startX + sway + progress * size.width * 0.15) % size.width;
      final dy     = (size.height * ((progress * speed + i * 0.1) % 1.0));
      final radius = kParticleRadiusMin + (sin(i.toDouble()).abs() * (kParticleRadiusMax - kParticleRadiusMin) * 0.5);
      canvas.drawCircle(Offset(dx, dy), radius, _paint(0.6 + sin(progress * pi + i).abs() * 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress || old.style != style;
}


// ─────────────────────────────────────────────────────────────────────────────
// _ConstellationPainter — [BackgroundType.constellation]
// ─────────────────────────────────────────────────────────────────────────────
//
// Draws a slowly drifting node network — nodes are connected to their
// kConstellationConnections nearest neighbours by faint lines.
// The whole field drifts slightly over time using sine offsets.
// Uses secondary color for lines to hint at depth distinct from nodes.

class _ConstellationPainter extends CustomPainter {
  final double progress;
  final int nodeCount;
  final Color nodeColor;
  final Color lineColor;

  // Fixed base positions are seeded from index — deterministic so the network
  // doesn't change shape between repaints, only drifts.
  late final List<Offset> _basePositions;

  _ConstellationPainter({
    required this.progress,
    required this.nodeCount,
    required this.nodeColor,
    required this.lineColor,
  }) {
    // Base positions computed once from a cheap deterministic scatter.
    // Using prime multipliers gives good distribution without a Random instance.
    _basePositions = List.generate(nodeCount, (i) {
      final bx = ((i * 127 + 43) % 1000) / 1000.0;
      final by = ((i * 311 + 97) % 1000) / 1000.0;
      return Offset(bx, by);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = nodeColor.withAlpha(kParticleAlpha + 20);
    final linePaint = Paint()
      ..color = lineColor.withAlpha((kParticleAlpha * 0.5).round())
      ..strokeWidth = 0.6;

    // Current positions = base + slow sine drift
    final positions = _basePositions.map((base) {
      final dx = base.dx + sin(progress * 2 * pi + base.dy * 10) * 0.03;
      final dy = base.dy + cos(progress * 2 * pi + base.dx * 10) * 0.02;
      return Offset(dx * size.width, dy * size.height);
    }).toList();

    // Draw connections first (behind nodes)
    for (int i = 0; i < positions.length; i++) {
      // Sort other nodes by distance to i, draw the k nearest
      final others = List<int>.generate(positions.length, (j) => j)
        ..remove(i)
        ..sort((a, b) {
          final da = (positions[a] - positions[i]).distance;
          final db = (positions[b] - positions[i]).distance;
          return da.compareTo(db);
        });

      for (int k = 0; k < kConstellationConnections && k < others.length; k++) {
        final j    = others[k];
        final dist = (positions[j] - positions[i]).distance;
        // Fade the line based on distance — further connections are more transparent
        final maxDist = size.width * 0.25;
        if (dist < maxDist) {
          final alpha = ((1.0 - dist / maxDist) * (kParticleAlpha * 0.5)).round().clamp(0, 255);
          canvas.drawLine(
            positions[i],
            positions[j],
            linePaint..color = lineColor.withAlpha(alpha),
          );
        }
      }
    }

    // Draw nodes on top
    for (final pos in positions) {
      canvas.drawCircle(pos, kParticleRadiusMin + 1, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.progress != progress;
}


// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderBackground — renders for unimplemented BackgroundType values
// ─────────────────────────────────────────────────────────────────────────────
//
// Shows a branded base (so the app doesn't break) plus a subtle debug label
// in the bottom-right corner so you know which type needs implementing.
// Remove the Positioned label block when you implement the real painter.

class _PlaceholderBackground extends StatelessWidget {
  final BackgroundType type;
  final Widget child;

  const _PlaceholderBackground({
    required this.type,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Branded solid base — app is usable even with placeholder types
        Container(color: AppColors.background),
        Container(decoration: BoxDecoration(gradient: AppGradients.meshPrimary)),

        // TODO label — remove this Positioned block when implementing the type
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
              'BG: ${type.name} — not yet implemented',
              style: AppTypography.caption.copyWith(
                color:    AppColors.warning,
                fontSize: 9,
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}