// lib/core/style/app_motion.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// AppMotion — Central Animation & Motion System
// ─────────────────────────────────────────────────────────────────────────────
//
// Single source of truth for all animation behaviour in the app.
// Sits at the same level as app_theme, app_branding, app_canvas.
//
// EXPORTS
//   AppMotionDefaults     — global timing, easing, and sizing constants
//   TypingTextConfig      — configurable typing/deleting headline animation
//   TypingHeadline        — widget: animated typing headline (shader-masked)
//   AnimatedGradientBorder— widget: animated gradient arc traveling the card edge
//   AppPageTransitions    — GoRouter page transition builders
//   AppLoader             — branded loading spinner
//
// DEPENDENCY CHAIN
//   app_branding → app_theme → app_motion   (no circular dependency)
//
// USAGE
//   Typing headline:
//     TypingHeadline(config: myTypingTextConfig)
//
//   Animated border (wrap any hoverable card):
//     AnimatedGradientBorder(
//       isActive: _hovered || _focused,
//       borderRadius: AppRadius.cardBR,
//       child: myCard,
//     )
//
//   Page transitions:
//     GoRoute(pageBuilder: (ctx, state) =>
//       AppPageTransitions.fadeSlide(ctx, state, const MyScreen()))
//
//   Loader:
//     AppLoader()
//     AppLoader.small()
//     AppLoader.large()
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_branding.dart';
import 'app_theme.dart';
import 'app_decorations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ── Typing animation defaults ─────────────────────────────────────────────────
const Duration _kTypingInterval       = Duration(milliseconds: 72);
const Duration _kDeletingInterval     = Duration(milliseconds: 42);
const Duration _kHoldAfterTyped       = Duration(milliseconds: 1550);
const Duration _kHoldAfterCleared     = Duration(milliseconds: 260);
const Duration _kCursorBlink          = Duration(milliseconds: 700);
const Duration _kTickDuration         = Duration(milliseconds: 40);
const double   _kTypingFontSize       = 56;
const FontWeight _kTypingFontWeight   = FontWeight.w800;
const double   _kCursorWidth          = 4;
const double   _kCursorHeight         = 44;
const double   _kCursorBottomPadding  = 6;
const double   _kHeadlineBlockHeight  = 104;

// ── Animated gradient border defaults ─────────────────────────────────────────
// arcFraction — fraction of the perimeter the traveling gradient arc covers.
// 0.30 = 30% of the perimeter at any moment. Adjust for wider/narrower arcs.
const double   _kBorderArcFraction  = 0.30;
const double   _kBorderStrokeWidth  = 1.5;
const Duration _kBorderLoopDuration = Duration(milliseconds: 2200);
const Duration _kBorderFadeDuration = Duration(milliseconds: 240);

// ── Page transition defaults ──────────────────────────────────────────────────
const Duration _kPageTransitionDuration = Duration(milliseconds: 280);

// ── Loader defaults ───────────────────────────────────────────────────────────
const double _kLoaderSizeSm = 20.0;
const double _kLoaderSizeMd = 32.0;
const double _kLoaderSizeLg = 48.0;
const double _kLoaderStroke =  2.5;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// AppMotionDefaults — global timing constants (mirrors AppDurations contract)
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppMotionDefaults {
  // Re-expose AppDurations for single-import convenience
  static const Duration fast   = AppDurations.fast;
  static const Duration normal = AppDurations.normal;
  static const Duration slow   = AppDurations.slow;

  // Specific motion durations
  static const Duration pageTransition    = _kPageTransitionDuration;
  static const Duration borderFade        = _kBorderFadeDuration;
  static const Duration borderLoop        = _kBorderLoopDuration;

  // Easing curves used consistently across the app
  static const Curve easeInOut  = Curves.easeInOut;
  static const Curve easeOut    = Curves.easeOut;
  static const Curve spring     = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
}


// ─────────────────────────────────────────────────────────────────────────────
// TypingTextConfig
// ─────────────────────────────────────────────────────────────────────────────
//
// Fully configurable data class for the typing headline animation.
// All timing and sizing parameters are overridable with production defaults.
//
// [phrases]             — phrases to cycle; must not be empty.
// [typingInterval]      — delay between each character typed.
// [deletingInterval]    — delay between each character erased.
// [holdAfterTyped]      — pause when the phrase is fully typed.
// [holdAfterCleared]    — pause when the phrase is fully erased.
// [cursorBlinkDuration] — half-period of the blinking cursor.
// [tickDuration]        — timer resolution; lower = smoother, higher CPU.
// [fontSize]            — headline font size in logical pixels.
// [fontWeight]          — headline font weight.
// [cursorWidth]         — cursor bar width in px.
// [cursorHeight]        — cursor bar height in px.
// [cursorBottomPadding] — nudge cursor to sit flush with text baseline.
// [headlineBlockHeight] — fixed outer height; prevents layout jumps.

class TypingTextConfig {
  final List<String> phrases;
  final Duration typingInterval;
  final Duration deletingInterval;
  final Duration holdAfterTyped;
  final Duration holdAfterCleared;
  final Duration cursorBlinkDuration;
  final Duration tickDuration;
  final double fontSize;
  final FontWeight fontWeight;
  final double cursorWidth;
  final double cursorHeight;
  final double cursorBottomPadding;
  final double headlineBlockHeight;

  const TypingTextConfig({
    required this.phrases,
    this.typingInterval      = _kTypingInterval,
    this.deletingInterval    = _kDeletingInterval,
    this.holdAfterTyped      = _kHoldAfterTyped,
    this.holdAfterCleared    = _kHoldAfterCleared,
    this.cursorBlinkDuration = _kCursorBlink,
    this.tickDuration        = _kTickDuration,
    this.fontSize            = _kTypingFontSize,
    this.fontWeight          = _kTypingFontWeight,
    this.cursorWidth         = _kCursorWidth,
    this.cursorHeight        = _kCursorHeight,
    this.cursorBottomPadding = _kCursorBottomPadding,
    this.headlineBlockHeight = _kHeadlineBlockHeight,
  });
}


// ─────────────────────────────────────────────────────────────────────────────
// TypingHeadline — animated typing + deleting headline widget
// ─────────────────────────────────────────────────────────────────────────────
//
// Cycles through [config.phrases], typing then deleting each one.
// Text is rendered through a ShaderMask so it receives the brand gradient.
// Wrapped in a fixed-height SizedBox to prevent layout jumps between phrases.

class TypingHeadline extends StatefulWidget {
  final TypingTextConfig config;
  const TypingHeadline({super.key, required this.config});

  @override
  State<TypingHeadline> createState() => _TypingHeadlineState();
}

class _TypingHeadlineState extends State<TypingHeadline>
    with SingleTickerProviderStateMixin {

  late final AnimationController _cursorCtrl;
  Timer? _timer;

  int _phraseIndex = 0;
  int _charIndex   = 0;
  bool _deleting   = false;
  Duration _elapsed = Duration.zero;
  String _displayed = '';

  TypingTextConfig get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _cursorCtrl = AnimationController(vsync: this, duration: _cfg.cursorBlinkDuration)
      ..repeat(reverse: true);
    _timer = Timer.periodic(_cfg.tickDuration, (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final phrase = _cfg.phrases[_phraseIndex];
    _elapsed += _cfg.tickDuration;

    setState(() {
      if (!_deleting) {
        if (_charIndex < phrase.length) {
          if (_elapsed >= _cfg.typingInterval) {
            _charIndex++;
            _displayed = phrase.substring(0, _charIndex);
            _elapsed = Duration.zero;
          }
        } else if (_elapsed >= _cfg.holdAfterTyped) {
          _deleting = true;
          _elapsed  = Duration.zero;
        }
      } else {
        if (_charIndex > 0) {
          if (_elapsed >= _cfg.deletingInterval) {
            _charIndex--;
            _displayed = phrase.substring(0, _charIndex);
            _elapsed = Duration.zero;
          }
        } else if (_elapsed >= _cfg.holdAfterCleared) {
          _deleting     = false;
          _phraseIndex  = (_phraseIndex + 1) % _cfg.phrases.length;
          _charIndex    = 0;
          _displayed    = '';
          _elapsed      = Duration.zero;
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cfg.headlineBlockHeight,
      child: Center(
        child: ShaderMask(
          shaderCallback: (b) => AppGradients.button.createShader(b),
          blendMode: BlendMode.srcIn,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Typed text ─────────────────────────────────────────────
              Text(
                _displayed,
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(
                  fontSize: _cfg.fontSize,
                  height: 1.1,
                  fontWeight: _cfg.fontWeight,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              // ── Blinking cursor ────────────────────────────────────────
              FadeTransition(
                opacity: _cursorCtrl,
                child: Padding(
                  padding: EdgeInsets.only(bottom: _cfg.cursorBottomPadding),
                  child: Container(
                    width: _cfg.cursorWidth,
                    height: _cfg.cursorHeight,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(_cfg.cursorWidth / 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AnimatedGradientBorder
// ─────────────────────────────────────────────────────────────────────────────
//
// Wraps any widget and paints a gradient arc that travels around the border
// edge on hover/focus. The arc smoothly fades in/out when [isActive] changes.
//
// HOW IT WORKS
//   A CustomPainter computes the full RRect path of the card border, then uses
//   PathMetric to extract an arc-length segment. The arc start position is
//   driven by a looping AnimationController, so the arc continuously travels
//   the perimeter. A second controller fades the arc in/out.
//
//   The gradient is created from the full widget bounds as the Rect, so it
//   appears consistent regardless of which part of the border is painted.
//
// PARAMETERS
//   [isActive]         — show/animate the border (hover or focus state).
//   [borderRadius]     — must match your card's own corner radius exactly.
//   [strokeWidth]      — arc stroke thickness in logical pixels (default 1.5).
//   [gradient]         — override the gradient; defaults to AppGradients.button.
//   [arcFraction]      — 0.0–1.0, fraction of perimeter the arc covers (def 0.30).
//   [loopDuration]     — time for one full revolution (default 2.2s).
//   [fadeDuration]     — enter/exit fade duration (default 240ms).
//   [showStaticBorder] — render a dim static border beneath the arc (def true).
//   [staticBorderColor]— color of the static border (def AppColors.border).
//
// USAGE
//   MouseRegion(
//     onEnter: (_) => setState(() => _hovered = true),
//     onExit:  (_) => setState(() => _hovered = false),
//     child: AnimatedGradientBorder(
//       isActive:     _hovered,
//       borderRadius: AppRadius.cardBR,
//       child: myCard,
//     ),
//   )

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final Gradient? gradient;
  final double arcFraction;
  final Duration loopDuration;
  final Duration fadeDuration;
  final bool showStaticBorder;
  final Color staticBorderColor;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    required this.isActive,
    required this.borderRadius,
    this.strokeWidth      = _kBorderStrokeWidth,
    this.gradient,
    this.arcFraction      = _kBorderArcFraction,
    this.loopDuration     = _kBorderLoopDuration,
    this.fadeDuration     = _kBorderFadeDuration,
    this.showStaticBorder = true,
    this.staticBorderColor = AppColors.border,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with TickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final AnimationController _loopCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: widget.fadeDuration);
    _loopCtrl = AnimationController(vsync: this, duration: widget.loopDuration);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    if (widget.isActive) _activate();
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder old) {
    super.didUpdateWidget(old);
    if (widget.isActive == old.isActive) return;
    if (widget.isActive) {
      _activate();
    } else {
      _deactivate();
    }
  }

  void _activate() {
    _loopCtrl.repeat();
    _fadeCtrl.forward();
  }

  void _deactivate() {
    _fadeCtrl.reverse().whenComplete(() {
      if (!widget.isActive) _loopCtrl.stop();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppGradients.button;
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnim, _loopCtrl]),
      builder: (context, child) => CustomPaint(
        painter: _GradientBorderPainter(
          loopT: _loopCtrl.value,
          opacity: _fadeAnim.value,
          arcFraction: widget.arcFraction,
          strokeWidth: widget.strokeWidth,
          gradient: gradient,
          borderRadius: widget.borderRadius,
          staticColor: widget.staticBorderColor,
          showStatic: widget.showStaticBorder,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double loopT;
  final double opacity;
  final double arcFraction;
  final double strokeWidth;
  final Gradient gradient;
  final BorderRadius borderRadius;
  final Color staticColor;
  final bool showStatic;

  const _GradientBorderPainter({
    required this.loopT,
    required this.opacity,
    required this.arcFraction,
    required this.strokeWidth,
    required this.gradient,
    required this.borderRadius,
    required this.staticColor,
    required this.showStatic,
  });

  RRect _rrect(Size size) {
    final inset = strokeWidth / 2;
    return borderRadius.toRRect(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect  = _rrect(size);

    // ── Static dim border (always at base opacity) ───────────────────────────
    if (showStatic) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color       = staticColor
          ..style       = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    if (opacity <= 0.0) return;

    // ── Build the perimeter path ─────────────────────────────────────────────
    final path    = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric  = metrics.first;
    final total   = metric.length;
    final arcLen  = total * arcFraction.clamp(0.0, 1.0);
    final start   = (loopT * total) % total;

    // ── Extract the arc segment (handles wrap-around) ────────────────────────
    Path arc;
    final end = start + arcLen;
    if (end <= total) {
      arc = metric.extractPath(start, end);
    } else {
      arc = metric.extractPath(start, total);
      final wrapped = metric.extractPath(0, end % total);
      arc.addPath(wrapped, Offset.zero);
    }

    // ── Gradient paint ───────────────────────────────────────────────────────
    final shader = gradient.createShader(bounds);
    final arcPaint = Paint()
      ..shader      = shader
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.6  // slightly thicker than static border
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // ── Composit with opacity via saveLayer ──────────────────────────────────
    canvas.saveLayer(
      bounds,
      Paint()..color = Color.fromARGB(
        (255 * opacity.clamp(0.0, 1.0)).round(), 255, 255, 255),
    );
    canvas.drawPath(arc, arcPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.loopT != loopT || old.opacity != opacity;
}


// ─────────────────────────────────────────────────────────────────────────────
// AppPageTransitions — GoRouter page transition builders
// ─────────────────────────────────────────────────────────────────────────────
//
// USAGE (in GoRouter route definitions):
//   GoRoute(
//     path: '/about',
//     pageBuilder: (ctx, state) =>
//       AppPageTransitions.fadeSlide(ctx, state, const AboutScreen()),
//   )

abstract class AppPageTransitions {
  /// Subtle upward fade — default for most page navigations.
  static Page<void> fadeSlide(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = _kPageTransitionDuration,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        final fade  = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end:   Offset.zero,
        ).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// Horizontal slide — for sibling screens at the same nav level.
  static Page<void> slide(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = _kPageTransitionDuration,
    bool fromRight    = true,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide  = Tween<Offset>(
          begin: Offset(fromRight ? 0.06 : -0.06, 0),
          end:   Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child:   SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// Plain fade — for modal-style overlays and dialogs.
  static Page<void> fade(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = _kPageTransitionDuration,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AppLoader — branded loading indicator
// ─────────────────────────────────────────────────────────────────────────────
//
// USAGE
//   AppLoader()             — medium, default (32px)
//   AppLoader.small()       — 20px, inline use
//   AppLoader.large()       — 48px, full-screen gates
//   AppLoader(size: 24, strokeWidth: 2.0)  — custom

class AppLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Gradient? gradient;

  const AppLoader({
    super.key,
    this.size        = _kLoaderSizeMd,
    this.strokeWidth = _kLoaderStroke,
    this.gradient,
  });

  const AppLoader.small({super.key, this.gradient})
      : size        = _kLoaderSizeSm,
        strokeWidth = _kLoaderStroke - 0.5;

  const AppLoader.large({super.key, this.gradient})
      : size        = _kLoaderSizeLg,
        strokeWidth = _kLoaderStroke + 0.5;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppGradients.button;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _LoaderPainter(
          progress: _ctrl.value,
          strokeWidth: widget.strokeWidth,
          gradient: gradient,
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;

  const _LoaderPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect   = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color       = AppColors.border
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Gradient arc
    final shader = gradient.createShader(rect);
    final arcPaint = Paint()
      ..shader      = shader
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;

    const sweepAngle = math.pi * 1.4; // ~252°
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 2 * math.pi - math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) => old.progress != progress;
}