// lib/core/widgets/wellpath_background.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// WellPathBackground — Reusable animated gradient + particle field backdrop.
//
// Usage:
//   WellPathBackground(
//     child: YourScreenContent(),
//   )
//
// Drop this around any Scaffold body (or replace the body entirely) to get
// WellPath's signature dark-green animated gradient with floating particles.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public wrapper widget
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in WellPath's animated gradient background with a subtle
/// floating-particle field layered on top.
///
/// The gradient slowly pulses between deep-forest-black and WellPath green,
/// and 40 semi-transparent circles drift upward in a looping animation.
class WellPathBackground extends StatefulWidget {
  /// The content rendered above the animated background.
  final Widget child;

  /// Cycle duration for the gradient pulse.  Defaults to 8 seconds.
  final Duration gradientDuration;

  /// Cycle duration for the particle drift.  Defaults to 6 seconds.
  final Duration particleDuration;

  const WellPathBackground({
    super.key,
    required this.child,
    this.gradientDuration = const Duration(seconds: 8),
    this.particleDuration = const Duration(seconds: 6),
  });

  @override
  State<WellPathBackground> createState() => _WellPathBackgroundState();
}

class _WellPathBackgroundState extends State<WellPathBackground>
    with TickerProviderStateMixin {
  late final AnimationController _gradientController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _gradientController = AnimationController(
      vsync: this,
      duration: widget.gradientDuration,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: widget.particleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, _) {
        final gradientStart = Color.lerp(
          const Color(0xFF031F1C),
          const Color(0xFF00B85C),
          _gradientController.value,
        )!;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1 — animated gradient ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradientStart, const Color(0xFF00110A)],
                ),
              ),
            ),

            // ── Layer 2 — floating particles ──────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(_particleController.value),
                ),
              ),
            ),

            // ── Layer 3 — caller's content ────────────────────────────────
            widget.child,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal particle painter  (private — not exported)
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00CC66).withAlpha(50);
    for (int i = 0; i < 40; i++) {
      final dx =
          (size.width / 40) * i + sin(progress * pi * 2 + i) * 40;
      final dy = (size.height * progress + i * 50) % size.height;
      final radius = (5 + sin(progress * pi + i) * 3).abs();
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}