// lib/core/style/app_motion.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// FIXES in this version
//   • AnimatedGradientBorder: painter → foregroundPainter so the arc renders
//     ON TOP of the widget (was behind the card/button fill, invisible).
//   • TypingHeadline: shader bounds extended downward by 16 px so descenders
//     (g, y, p, q) receive gradient color instead of clipping to white.
//   • Removed unused imports (app_branding, app_decorations).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

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
const double   _kHeadlineBlockHeight  = 120; // increased from 104 to accommodate descenders

// Animated gradient border
const double   _kBorderArcFraction    = 0.30;
const double   _kBorderStrokeWidth    = 1.5;
const Duration _kBorderLoopDuration   = Duration(milliseconds: 2200);
const Duration _kBorderFadeDuration   = Duration(milliseconds: 240);
const Duration _kBorderTriggerInterval = Duration(seconds: 5);
const Duration _kBorderActiveDuration  = Duration(milliseconds: 2000);

// Animated gradient surface
const Duration _kSurfaceGradientDuration = Duration(seconds: 5);

// Page transitions
const Duration _kPageTransitionDuration = Duration(milliseconds: 280);

// Parallax
const double   _kParallaxFactor    = 0.30;
const double   _kParallaxMaxOffset = 200.0;

// Loader
const double _kLoaderSizeSm = 20.0;
const double _kLoaderSizeMd = 32.0;
const double _kLoaderSizeLg = 48.0;
const double _kLoaderStroke =  2.5;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// AppMotionDefaults
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppMotionDefaults {
  static const Duration fast           = AppDurations.fast;
  static const Duration normal         = AppDurations.normal;
  static const Duration slow           = AppDurations.slow;
  static const Duration pageTransition = _kPageTransitionDuration;
  static const Duration borderFade     = _kBorderFadeDuration;
  static const Duration borderLoop     = _kBorderLoopDuration;
  static const Curve easeInOut         = Curves.easeInOut;
  static const Curve easeOut           = Curves.easeOut;
  static const Curve spring            = Curves.easeOutBack;
  static const Curve decelerate        = Curves.decelerate;
}


// ─────────────────────────────────────────────────────────────────────────────
// TypingTextConfig
// ─────────────────────────────────────────────────────────────────────────────

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
// TypingHeadline
// ─────────────────────────────────────────────────────────────────────────────
//
// DESCENDER FIX
//   The shaderCallback rect is expanded 16 px downward so characters with
//   descenders (g, y, p, q, j) receive gradient color all the way to their
//   lowest pixel rather than snapping to the boundary gradient stop color.
//   The SizedBox height is also increased (via headlineBlockHeight default
//   120 → was 104) so the outer container doesn't clip the descenders.

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
          _deleting    = false;
          _phraseIndex = (_phraseIndex + 1) % _cfg.phrases.length;
          _charIndex   = 0;
          _displayed   = '';
          _elapsed     = Duration.zero;
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
          // DESCENDER FIX: extend bounds 16px downward so the gradient covers
          // the full visual extent of descender characters (g, y, p, q, j).
          shaderCallback: (b) => AppGradients.button.createShader(
            Rect.fromLTRB(b.left, b.top, b.right, b.bottom + 16),
          ),
          blendMode: BlendMode.srcIn,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayed,
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(
                  fontSize:   _cfg.fontSize,
                  height:     1.1,
                  fontWeight: _cfg.fontWeight,
                  color:      AppColors.textPrimary,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              FadeTransition(
                opacity: _cursorCtrl,
                child: Padding(
                  padding: EdgeInsets.only(bottom: _cfg.cursorBottomPadding),
                  child: Container(
                    width:  _cfg.cursorWidth,
                    height: _cfg.cursorHeight,
                    decoration: BoxDecoration(
                      color:        AppColors.textPrimary,
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
// BorderTriggerMode
// ─────────────────────────────────────────────────────────────────────────────

enum BorderTriggerMode { interactive, periodic }


// ─────────────────────────────────────────────────────────────────────────────
// AnimatedGradientBorder
// ─────────────────────────────────────────────────────────────────────────────
//
// FOREGROUND PAINTER FIX
//   Previously used `painter` (paints BEHIND child). The card and button fills
//   completely covered the arc, making it invisible.
//   Fixed: now uses `foregroundPainter` (paints ON TOP of child). The arc
//   appears over the widget's surface, traveling along its border edge.
//
//   This affects: step cards (hover), feature cards (hover),
//   testimonial cards (hover), and PrimaryAttentionButton (periodic).

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
  final BorderTriggerMode triggerMode;
  final Duration triggerInterval;
  final Duration activeDuration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    required this.borderRadius,
    this.isActive           = false,
    this.strokeWidth        = _kBorderStrokeWidth,
    this.gradient,
    this.arcFraction        = _kBorderArcFraction,
    this.loopDuration       = _kBorderLoopDuration,
    this.fadeDuration       = _kBorderFadeDuration,
    this.showStaticBorder   = true,
    this.staticBorderColor  = AppColors.border,
    this.triggerMode        = BorderTriggerMode.interactive,
    this.triggerInterval    = _kBorderTriggerInterval,
    this.activeDuration     = _kBorderActiveDuration,
  });

  @override
  State<AnimatedGradientBorder> createState() =>
      _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with TickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final AnimationController _loopCtrl;
  late final Animation<double>   _fadeAnim;
  Timer? _periodicTimer;
  bool _cycleRunning = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: widget.fadeDuration);
    _loopCtrl = AnimationController(vsync: this, duration: widget.loopDuration);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    if (widget.triggerMode == BorderTriggerMode.periodic) {
      _startPeriodicTrigger();
    } else if (widget.isActive) {
      _activate();
    }
  }

  void _startPeriodicTrigger() {
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) { _runCycle(); }
    });
    _periodicTimer = Timer.periodic(widget.triggerInterval, (_) {
      if (mounted && !_cycleRunning) { _runCycle(); }
    });
  }

  void _runCycle() {
    if (_cycleRunning) return;
    _cycleRunning = true;
    _activate();
    Future.delayed(widget.activeDuration, () {
      if (mounted) {
        _deactivate();
        _cycleRunning = false;
      }
    });
  }

  void _activate() {
    _loopCtrl.repeat();
    _fadeCtrl.forward();
  }

  void _deactivate() {
    _fadeCtrl.reverse().whenComplete(() {
      if (mounted) { _loopCtrl.stop(); }
    });
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder old) {
    super.didUpdateWidget(old);
    if (widget.triggerMode == BorderTriggerMode.periodic) return;
    if (widget.isActive == old.isActive) return;
    if (widget.isActive) {
      _activate();
    } else {
      _deactivate();
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
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
        // FOREGROUND PAINTER — arc renders ON TOP of child content.
        foregroundPainter: _GradientBorderPainter(
          loopT:        _loopCtrl.value,
          opacity:      _fadeAnim.value,
          arcFraction:  widget.arcFraction,
          strokeWidth:  widget.strokeWidth,
          gradient:     gradient,
          borderRadius: widget.borderRadius,
          staticColor:  widget.staticBorderColor,
          showStatic:   widget.showStaticBorder,
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

    if (showStatic) {
      canvas.drawRRect(rrect, Paint()
        ..color       = staticColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);
    }
    if (opacity <= 0.0) return;

    final path    = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric  = metrics.first;
    final total   = metric.length;
    final arcLen  = total * arcFraction.clamp(0.0, 1.0);
    final start   = (loopT * total) % total;
    final end     = start + arcLen;

    Path arc;
    if (end <= total) {
      arc = metric.extractPath(start, end);
    } else {
      arc = metric.extractPath(start, total);
      arc.addPath(metric.extractPath(0, end % total), Offset.zero);
    }

    final arcPaint = Paint()
      ..shader      = gradient.createShader(bounds)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.6
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

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
// AnimatedGradientSurface
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedGradientSurface extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Duration duration;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const AnimatedGradientSurface({
    super.key,
    required this.child,
    this.colors,
    this.duration     = _kSurfaceGradientDuration,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  State<AnimatedGradientSurface> createState() =>
      _AnimatedGradientSurfaceState();
}

class _AnimatedGradientSurfaceState extends State<AnimatedGradientSurface>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors ??
        [AppColors.primaryDeep, AppColors.primary, AppColors.primaryDark];
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t     = _anim.value;
        final begin = Alignment.lerp(Alignment.topLeft, Alignment.centerRight, t * 0.4)!;
        final end   = Alignment.lerp(Alignment.bottomRight, Alignment.centerLeft, t * 0.4)!;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin, end: end, colors: c,
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: widget.borderRadius,
            border:       widget.border,
            boxShadow:    widget.boxShadow,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// ParallaxConfig
// ─────────────────────────────────────────────────────────────────────────────

class ParallaxConfig {
  final double factor;
  final double maxOffset;
  final Axis direction;
  final Curve curve;
  final bool enabled;

  const ParallaxConfig({
    this.factor    = _kParallaxFactor,
    this.maxOffset = _kParallaxMaxOffset,
    this.direction = Axis.vertical,
    this.curve     = Curves.linear,
    this.enabled   = true,
  });

  static const background    = ParallaxConfig(factor: 0.30);
  static const midground     = ParallaxConfig(factor: 0.55);
  static const foreground    = ParallaxConfig(factor: 0.80);
  static const heroBackground = ParallaxConfig(factor: 0.15, maxOffset: 80);
}


// ─────────────────────────────────────────────────────────────────────────────
// ParallaxLayer
// ─────────────────────────────────────────────────────────────────────────────

class ParallaxLayer extends StatelessWidget {
  final Widget child;
  final ScrollController scrollController;
  final ParallaxConfig config;

  const ParallaxLayer({
    super.key,
    required this.child,
    required this.scrollController,
    this.config = ParallaxConfig.background,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.enabled) return child;

    return AnimatedBuilder(
      animation: scrollController,
      builder: (_, innerChild) {
        final rawOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final pixelOffset = (rawOffset * config.factor)
            .clamp(0.0, config.maxOffset);
        final translate = config.direction == Axis.vertical
            ? Offset(0, -pixelOffset)
            : Offset(-pixelOffset, 0);

        return Transform.translate(offset: translate, child: innerChild);
      },
      child: child,
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AppPageTransitions
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppPageTransitions {
  static Page<void> fadeSlide(
    BuildContext context, GoRouterState state, Widget child,
    {Duration duration = _kPageTransitionDuration}) {
    return CustomTransitionPage<void>(
      key: state.pageKey, child: child,
      transitionDuration: duration, reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        final fade  = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04), end: Offset.zero).animate(fade);
        return FadeTransition(opacity: fade,
            child: SlideTransition(position: slide, child: child));
      },
    );
  }

  static Page<void> slide(
    BuildContext context, GoRouterState state, Widget child,
    {Duration duration = _kPageTransitionDuration, bool fromRight = true}) {
    return CustomTransitionPage<void>(
      key: state.pageKey, child: child,
      transitionDuration: duration, reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        final c = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final s = Tween<Offset>(
          begin: Offset(fromRight ? 0.06 : -0.06, 0),
          end: Offset.zero).animate(c);
        return FadeTransition(opacity: c,
            child: SlideTransition(position: s, child: child));
      },
    );
  }

  static Page<void> fade(
    BuildContext context, GoRouterState state, Widget child,
    {Duration duration = _kPageTransitionDuration}) {
    return CustomTransitionPage<void>(
      key: state.pageKey, child: child,
      transitionDuration: duration, reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AppLoader
// ─────────────────────────────────────────────────────────────────────────────

class AppLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Gradient? gradient;

  const AppLoader({super.key,
    this.size = _kLoaderSizeMd, this.strokeWidth = _kLoaderStroke, this.gradient});
  const AppLoader.small({super.key, this.gradient})
      : size = _kLoaderSizeSm, strokeWidth = _kLoaderStroke - 0.5;
  const AppLoader.large({super.key, this.gradient})
      : size = _kLoaderSizeLg, strokeWidth = _kLoaderStroke + 0.5;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppGradients.button;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.size),
        painter: _LoaderPainter(
          progress: _ctrl.value, strokeWidth: widget.strokeWidth, gradient: gradient),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  const _LoaderPainter({required this.progress, required this.strokeWidth, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final rect   = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;
    canvas.drawCircle(center, radius, Paint()
      ..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 2 * math.pi - math.pi / 2, math.pi * 1.4, false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style  = PaintingStyle.stroke
        ..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) => old.progress != progress;
}