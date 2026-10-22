import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum OrbMode {
  /// Violet: the week is filling up.
  work,

  /// Lime: time off, draining back toward work.
  weekend,

  /// Grey: nothing to count.
  paused,
}

/// The glossy glass sphere with liquid that fills as the week goes by.
class Orb extends StatefulWidget {
  const Orb({
    super.key,
    required this.size,
    required this.fill,
    this.mode = OrbMode.work,
    this.onTap,
    this.semanticLabel,
    this.still,
    this.dark,
  });

  final double size;

  /// 0 (empty) to 1 (full).
  final double fill;
  final OrbMode mode;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// No wave motion. Defaults to true for small orbs and with reduced motion.
  final bool? still;

  /// Dark glass regardless of theme, for dark backgrounds.
  final bool? dark;

  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb> with TickerProviderStateMixin {
  // 18 s fits three front waves (6 s) and two back waves (9 s), so the loop
  // is seamless.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _pressed = false;

  static final _wobbleX = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.06), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.96), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.02), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1), weight: 40),
  ]);
  static final _wobbleY = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.94), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.04), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 0.98), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.98, end: 1), weight: 40),
  ]);

  bool get _still => widget.still ?? (widget.size < 80 || context.reduceMotion);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(Orb old) {
    super.didUpdateWidget(old);
    _syncMotion();
  }

  void _syncMotion() {
    if (_still) {
      _wave.stop();
      _spin.stop();
    } else {
      if (!_wave.isAnimating) _wave.repeat();
      if (!_spin.isAnimating) _spin.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _spin.dispose();
    _wobble.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    if (!context.reduceMotion) _wobble.forward(from: 0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = widget.size;
    final dark = widget.dark ?? t.isDark;
    final glow = dark
        ? const Color(0x99000000)
        : widget.mode == OrbMode.weekend
        ? const Color(0x596EA000)
        : const Color(0x593C1E8C);

    // The shadow reaches well past the sphere. Paint it on a layer big
    // enough to hold it: Impeller clips a layer to its bounds, which turned
    // the shadow into a grey box. Layout still takes only [size].
    final margin = size * 0.4;
    final canvas = size + margin * 2;
    Widget orb = SizedBox.square(
      dimension: size,
      child: OverflowBox(
        maxWidth: canvas,
        maxHeight: canvas,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.fill.clamp(0, 1)),
            duration: context.reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 1200),
            curve: Motion.spring,
            builder: (context, fill, _) => CustomPaint(
              size: Size.square(canvas),
              painter: _OrbPainter(
                wave: _wave,
                spin: _spin,
                fill: fill.clamp(0, 1.04),
                palette: _palettes[widget.mode]!,
                dark: dark,
                glow: glow,
                margin: margin,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.mode == OrbMode.paused && !_still) {
      orb = Stack(
        clipBehavior: Clip.none,
        children: [
          orb,
          Positioned(
            right: size * 0.06,
            top: size * 0.04,
            child: _Snore(size: size, color: t.ink2),
          ),
        ],
      );
    }

    orb = AnimatedBuilder(
      animation: _wobble,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _wobbleX.evaluate(_wobble),
          _wobbleY.evaluate(_wobble),
          1,
        ),
        child: child,
      ),
      child: orb,
    );

    if (widget.onTap == null) {
      return Semantics(image: true, label: widget.semanticLabel, child: orb);
    }
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: _tap,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _tap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: Motion.mid,
          curve: Motion.spring,
          child: orb,
        ),
      ),
    );
  }
}

/// Liquid colors: highlight at the surface, main and deep.
typedef _Palette = ({Color surface, Color main, Color deep});

const _palettes = <OrbMode, _Palette>{
  OrbMode.work: (
    surface: Color(0xFFFF8AD8),
    main: Color(0xFF9B6BFF),
    deep: Color(0xFF5B2FD6),
  ),
  OrbMode.weekend: (
    surface: Color(0xFF6FF2C7),
    main: Color(0xFFE4FF7A),
    deep: Color(0xFF9EDB00),
  ),
  OrbMode.paused: (
    surface: Color(0xFFE6E3DD),
    main: Color(0xFFC9C6C0),
    deep: Color(0xFF9C9890),
  ),
};

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.wave,
    required this.spin,
    required this.fill,
    required this.palette,
    required this.dark,
    required this.glow,
    required this.margin,
  }) : super(repaint: Listenable.merge([wave, spin]));

  final Animation<double> wave;
  final Animation<double> spin;
  final double fill;
  final _Palette palette;
  final bool dark;

  /// Drop shadow color. It is clipped to outside the sphere, like a CSS
  /// box-shadow, so it never shows through the glass.
  final Color glow;

  /// Room around the sphere for the shadow.
  final double margin;

  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    canvas.translate(margin, margin);
    final size = Size.square(canvasSize.width - margin * 2);
    final w = size.width;
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = w / 2;
    final k = w / 220;

    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(w))
        ..addOval(rect),
    );
    canvas.drawCircle(
      center + Offset(0, 24 * k),
      r - 12 * k,
      Paint()
        ..color = glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25 * k),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Glass body.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.34, -0.94),
          end: const Alignment(0.34, 0.94),
          colors: dark
              ? [_white.withValues(alpha: 0.14), const Color(0x147864C8)]
              : [_white.withValues(alpha: 0.55), const Color(0x40DCD7F0)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 1.06,
          colors: dark
              ? [_white.withValues(alpha: 0.28), _white.withValues(alpha: 0.04)]
              : [
                  _white.withValues(alpha: 0.55),
                  _white.withValues(alpha: 0.08),
                ],
          stops: const [0, 0.55],
        ).createShader(rect),
    );
    if (!dark) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 1.4),
            radius: 1.3,
            colors: [
              _white.withValues(alpha: 0.35),
              _white.withValues(alpha: 0),
            ],
            stops: const [0, 0.6],
          ).createShader(rect),
      );
    }

    // Liquid: a back wave and a front wave drifting the opposite way.
    final top = (1 - fill) * w - 0.06 * w;
    final liquidBottom = top + 1.2 * w;
    // SVG gradients span the shape's own bounds, so the surface colour sits
    // right on each wave's crests.
    Paint liquid(double svgTop, double baseline) => Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.surface, palette.main, palette.deep],
            stops: const [0, 0.18, 1],
          ).createShader(
            Rect.fromLTRB(
              0,
              svgTop + (baseline - 10.5) * w / 200,
              w,
              liquidBottom,
            ),
          );
    // Over the 18 s loop the front wave travels three periods left and the
    // back wave two periods right.
    final phase = wave.value;
    canvas.saveLayer(rect, Paint()..color = _white.withValues(alpha: 0.55));
    canvas.drawPath(
      _wavePath(w, top - 0.036 * w, 28, 1 - (phase * 2) % 1, liquidBottom),
      liquid(top - 0.036 * w, 28),
    );
    canvas.restore();
    canvas.drawPath(
      _wavePath(w, top, 22, (phase * 3) % 1, liquidBottom),
      liquid(top, 22),
    );

    // Iridescent sheen. The prototype soft-lights it; a faint plain overlay
    // gives the same tint on both light and dark glass.
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0x26FF8AD8),
            Color(0x007C4DF0),
            Color(0x1A6FF2C7),
            Color(0x00C8F53C),
            Color(0x26FF8AD8),
          ],
          stops: const [0, 0.3, 0.5, 0.72, 1],
          transform: GradientRotation(spin.value * 2 * math.pi),
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = RadialGradient(
          radius: math.sqrt2 / 2,
          colors: const [Color(0xFF000000), Color(0x00000000)],
          stops: const [0.3, 0.72],
        ).createShader(rect),
    );
    canvas.restore();

    if (!dark) {
      // Soft shade at the bottom of the glass.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x00000000), Color(0x14000000)],
            stops: [0, 0.72, 1],
          ).createShader(rect),
      );
    }
    canvas.restore();

    // Rim.
    canvas.drawCircle(
      center,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _white.withValues(alpha: dark ? 0.14 : 0.6),
    );

    // Highlights. The gradient is drawn on a unit circle and stretched, so
    // it fills the ellipse like CSS `radial-gradient(ellipse …)`, whose
    // default size reaches the corners: the 70% stop lands at the rim.
    canvas.save();
    canvas.translate(0.35 * w, 0.21 * w);
    canvas.rotate(-24 * math.pi / 180);
    canvas.scale(0.17 * w, 0.11 * w);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [_white.withValues(alpha: 0.95), _white.withValues(alpha: 0)],
          stops: const [0, 0.99],
        ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)),
    );
    canvas.restore();
    _ellipse(
      canvas,
      Rect.fromLTWH(0.72 * w, 0.79 * w, 0.12 * w, 0.07 * w),
      -30,
      Paint()
        ..color = _white.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.01 * w),
    );
  }

  /// The prototype's SVG wave: a 800 × 240 box stretched over 2w × 1.2w,
  /// made of cubic curves that meet the baseline vertically, which gives
  /// the rounded, slightly leaning crests. [baseline] is in SVG units;
  /// [shift] is how far along one period the wave has drifted.
  Path _wavePath(
    double w,
    double svgTop,
    double baseline,
    double shift,
    double bottom,
  ) {
    final sx = w / 400, sy = w / 200;
    final y = svgTop + baseline * sy;
    final rise = 14 * sy;
    final period = 200 * sx;
    var x = -0.5 * w - shift * period;
    final path = Path()
      ..moveTo(x, bottom)
      ..lineTo(x, y);
    for (var i = 0; i < 5; i++, x += period) {
      path
        ..cubicTo(
          x + 50 * sx,
          y - rise,
          x + 100 * sx,
          y - rise,
          x + 100 * sx,
          y,
        )
        ..cubicTo(
          x + 100 * sx,
          y + rise,
          x + 150 * sx,
          y + rise,
          x + period,
          y,
        );
    }
    return path
      ..lineTo(x, bottom)
      ..close();
  }

  void _ellipse(Canvas canvas, Rect box, double degrees, Paint paint) {
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.translate(-box.width / 2, -box.height / 2);
    canvas.drawOval(Offset.zero & box.size, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.fill != fill ||
      old.palette != palette ||
      old.dark != dark ||
      old.glow != glow ||
      old.margin != margin;
}

/// The "z" floating over a resting orb.
class _Snore extends StatefulWidget {
  const _Snore({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_Snore> createState() => _SnoreState();
}

class _SnoreState extends State<_Snore> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final wave = math.sin(_float.value * math.pi);
          return Opacity(
            opacity: 0.4 + 0.6 * wave,
            child: Transform.translate(
              offset: Offset(0, -8 * wave),
              child: child,
            ),
          );
        },
        child: Text(
          'z',
          style: TextStyle(
            fontFamily: Fonts.display,
            fontSize: widget.size * 0.1,
            height: 1,
            fontWeight: FontWeight.w700,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
