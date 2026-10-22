import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../domain/awards.dart';
import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/award_copy.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/award_badge.dart';
import '../kit/buttons.dart';
import '../kit/pressable.dart';
import '../kit/glass.dart';
import '../kit/orb.dart';
import '../kit/strike.dart';
import '../theme/tokens.dart';

/// "Weekend!": the orb pops, lime floods the bottom of the screen and
/// confetti flies. Shown once when time off starts.
class CelebrateScreen extends StatefulWidget {
  const CelebrateScreen({
    super.key,
    required this.controller,
    required this.block,
    this.award,
  });

  final AppController controller;
  final OffBlock block;

  /// An award earned as this time off started.
  final String? award;

  /// Resolves to the award to show when the person taps its badge.
  static Future<String?> open(
    BuildContext context,
    AppController controller,
    OffBlock block, {
    String? award,
  }) {
    HapticFeedback.heavyImpact();
    return Navigator.of(context).push(
      PageRouteBuilder<String>(
        fullscreenDialog: true,
        transitionDuration: Motion.fast,
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) =>
            CelebrateScreen(controller: controller, block: block, award: award),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<CelebrateScreen> createState() => _CelebrateScreenState();
}

class _CelebrateScreenState extends State<CelebrateScreen>
    with TickerProviderStateMixin {
  static const _length = 2000.0;

  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  late final _Confetti _confetti = _Confetti(this);
  final _orbKey = GlobalKey();
  bool _started = false;

  late final _spot = _between(0, 1200, Motion.out);
  late final _flood = _between(620, 1520, Motion.out);
  late final _orbFade = ReverseAnimation(_between(520, 780));
  // The orb grows a little, then pops.
  late final _orbScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.14), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.14, end: 0), weight: 60),
  ]).animate(_between(260, 780));
  late final _badge = _between(1400, 2000, Motion.spring);
  final _letters = <Animation<double>>[];

  Animation<double> _between(
    double fromMs,
    double toMs, [
    Curve curve = Curves.linear,
  ]) => CurvedAnimation(
    parent: _timeline,
    curve: Interval(
      fromMs / _length,
      math.min(toMs, _length) / _length,
      curve: curve,
    ),
  );

  /// Letters drop in one after another.
  Animation<double> _letter(int i) {
    while (_letters.length <= i) {
      final start = 520 + _letters.length * 45.0;
      _letters.add(_between(math.min(start, _length - 300), start + 700));
    }
    return _letters[i];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _timeline.value = 1;
      return;
    }
    _timeline.forward();
    if (!widget.controller.prefs.confetti) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      final box = _orbKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null
          ? Offset(size.width / 2, size.height * 0.3)
          : box.localToGlobal(box.size.center(Offset.zero));
      _confetti.start(size, origin);
    });
  }

  @override
  void dispose() {
    _timeline.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final now = widget.controller.clock();
    final block = widget.block;
    final start = block.offStart ?? now;
    final belated = now.difference(start) > const Duration(minutes: 2);
    final back = block.offEnd;
    final title = switch (block.kind) {
      BlockKind.weekend => l10n.celebrateWeekend,
      BlockKind.longWeekend => l10n.celebrateLongWeekend,
      BlockKind.holiday => l10n.celebrateHoliday,
      BlockKind.daysOff => l10n.celebrateDaysOff,
    };
    final body = belated
        ? l10n.celebrateLateBody(l10n.shortWhen(start, now))
        : back == null
        ? l10n.celebrateBodyOpen
        : l10n.celebrateBody(l10n.humanDuration(back.difference(now)));
    final weeks = widget.controller.prefs.weeks;
    final next = nextWeeklyAward(weeks);
    final width = media.size.width;
    final titleSize = (width * 0.17).clamp(48, 76).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Spotlights from the top.
            Positioned(
              left: -width * 0.2,
              right: -width * 0.2,
              top: -media.size.height * 0.1,
              height: media.size.height * 0.7,
              child: FadeTransition(opacity: _spot, child: const _Spotlights()),
            ),
            // Lime floods in from below.
            Positioned(
              left: -width * 0.04,
              right: -width * 0.04,
              bottom: 0,
              height: media.viewPadding.bottom + 200,
              child: AnimatedBuilder(
                animation: _flood,
                builder: (context, child) => FractionalTranslation(
                  translation: Offset(0, (1 - _flood.value) * 1.2),
                  child: child,
                ),
                child: const _Flood(),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ConfettiPainter(_confetti)),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 200),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 132,
                              child: Center(
                                child: FadeTransition(
                                  opacity: _orbFade,
                                  child: ScaleTransition(
                                    key: _orbKey,
                                    scale: _orbScale,
                                    child: const Orb(
                                      size: 120,
                                      fill: 1,
                                      mode: OrbMode.weekend,
                                      still: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              (belated
                                      ? l10n.celebrateLateEyebrow
                                      : weeks > 0
                                      ? l10n.celebrateWeeks(
                                          l10n.weeksCount(weeks),
                                        )
                                      : l10n.celebrateEyebrow)
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: Fonts.mono,
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.26,
                                color: Tokens.lime,
                              ),
                            ),
                            const SizedBox(height: 14),
                            StrikeText(
                              l10n.celebrateWas,
                              style: const TextStyle(
                                fontFamily: Fonts.display,
                                fontSize: 20,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8C8984),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              header: true,
                              label: title,
                              excludeSemantics: true,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final (i, letter)
                                        in title.split('').indexed)
                                      _Letter(
                                        letter: letter,
                                        size: titleSize,
                                        animation: _letter(i),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                body,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: Fonts.text,
                                  fontSize: 17,
                                  height: 23 / 17,
                                  color: Color(0xFFBDBBB6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _Reveal(
                              animation: _badge,
                              child: widget.award != null
                                  ? Pressable(
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(widget.award),
                                      child: _Badge(
                                        leading: AwardBadge(
                                          award: awardById(widget.award!),
                                          mark: awardCopy(
                                            l10n.localeName,
                                            widget.award!,
                                          ).mark,
                                          size: 48,
                                        ),
                                        title: l10n.awardNew(
                                          awardCopy(
                                            l10n.localeName,
                                            widget.award!,
                                          ).name,
                                        ),
                                        subtitle: awardCopy(
                                          l10n.localeName,
                                          widget.award!,
                                        ).why,
                                      ),
                                    )
                                  : _Badge(
                                      leading: const Icon(
                                        Icons.emoji_events_rounded,
                                        color: Colors.white,
                                      ),
                                      title: l10n.celebrateWeeks(
                                        l10n.weeksCount(weeks),
                                      ),
                                      subtitle: next == null
                                          ? l10n.celebrateAllDone
                                          : l10n.celebrateNext(
                                              l10n.weeksCount(
                                                next.weeks! - weeks,
                                              ),
                                              awardCopy(
                                                l10n.localeName,
                                                next.id,
                                              ).name,
                                            ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: media.padding.top + 2,
              right: 16,
              child: GlassButton(
                icon: Icons.close_rounded,
                label: l10n.close,
                dark: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: media.viewPadding.bottom + 8,
              child: AppButton(
                label: l10n.celebrateCta,
                kind: ButtonKind.ink,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spotlights extends StatelessWidget {
  const _Spotlights();

  @override
  Widget build(BuildContext context) {
    RadialGradient spot(Alignment center, double radius, Color color) =>
        RadialGradient(
          center: center,
          radius: radius,
          colors: [color, color.withAlpha(0)],
        );
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: spot(
              const Alignment(0, -1),
              0.6,
              const Color(0x59C8F53C),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: spot(
              const Alignment(-0.5, -1),
              0.45,
              const Color(0x597C4DF0),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: spot(
              const Alignment(0.5, -1),
              0.45,
              const Color(0x4D7C4DF0),
            ),
          ),
        ),
      ],
    );
  }
}

class _Flood extends StatelessWidget {
  const _Flood();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 28, child: CustomPaint(painter: _WaveTopPainter())),
        const Expanded(child: ColoredBox(color: Tokens.lime)),
      ],
    );
  }
}

class _WaveTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Scaled from the prototype's 800 × 60 wave.
    final path = Path()
      ..moveTo(0, h * 0.5)
      ..cubicTo(w * 0.125, 0, w * 0.25, 0, w * 0.375, h * 0.5)
      ..cubicTo(w * 0.5, h, w * 0.625, h, w * 0.75, h * 0.5)
      ..cubicTo(w * 0.83, h * 0.15, w * 0.92, 0, w, h * 0.33)
      ..lineTo(w, h + 1)
      ..lineTo(0, h + 1)
      ..close();
    canvas.drawPath(path, Paint()..color = Tokens.lime);
  }

  @override
  bool shouldRepaint(_WaveTopPainter old) => false;
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.letter,
    required this.size,
    required this.animation,
  });

  final String letter;
  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      letter,
      style: TextStyle(
        fontFamily: Fonts.display,
        fontSize: size,
        height: 0.95,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.055 * size,
        color: Colors.white,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = Motion.spring.transform(animation.value);
        return Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..translateByDouble(0, 40 * (1 - v), 0, 1)
              ..rotateZ(8 * math.pi / 180 * (1 - v))
              ..scaleByDouble(0.6 + 0.4 * v, 0.6 + 0.4 * v, 1, 1),
            child: child,
          ),
        );
      },
      child: text,
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Opacity(
      opacity: animation.value.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - animation.value)),
        child: child,
      ),
    ),
    child: child,
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: Fonts.text,
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: Fonts.text,
                    fontSize: 13,
                    height: 18 / 13,
                    color: Tokens.widgetInk2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.random,
  }) : rotation = random.nextDouble() * 2 * math.pi,
       spin = (random.nextDouble() - 0.5) * 0.35,
       w = 5 + random.nextDouble() * 7,
       h = 8 + random.nextDouble() * 10,
       shape = random.nextDouble() < 0.25
           ? 1
           : random.nextDouble() < 0.5
           ? 2
           : 0,
       flip = random.nextDouble() * 2 * math.pi;

  final math.Random random;
  double x, y, vx, vy, rotation, spin, flip;
  final double w, h;

  /// 0 rectangle, 1 square, 2 thin strip.
  final int shape;
  final Color color;
  double life = 0;
}

/// Confetti physics, stepped by elapsed time so it falls the same at any
/// refresh rate.
class _Confetti extends ChangeNotifier {
  _Confetti(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  final _random = math.Random();
  final particles = <_Particle>[];
  Duration _last = Duration.zero;
  late Size _size;
  late Offset _origin;
  var _burst = 0;

  static const _colors = [
    Color(0xFFC8F53C),
    Color(0xFF8B5CF6),
    Color(0xFFFFFFFF),
    Color(0xFFB9A0FF),
    Color(0xFFE4FF7A),
    Color(0xFFD9D7D2),
    Color(0xFF6FF2C7),
  ];

  void start(Size size, Offset origin) {
    _size = size;
    _origin = origin;
    _ticker.start();
  }

  void _add(Offset from, int count, double a0, double a1, double speed) {
    final n = (count * (_size.width < 400 ? 0.6 : 1)).round();
    for (var i = 0; i < n; i++) {
      final angle = a0 + _random.nextDouble() * (a1 - a0);
      final v = speed * (0.45 + _random.nextDouble() * 0.75);
      particles.add(
        _Particle(
          x: from.dx,
          y: from.dy,
          vx: math.cos(angle) * v,
          vy: math.sin(angle) * v,
          color: _colors[i % _colors.length],
          random: _random,
        ),
      );
    }
  }

  void _tick(Duration elapsed) {
    if (_burst == 0 && elapsed > const Duration(milliseconds: 380)) {
      _burst = 1;
      _add(_origin, 160, 0, 2 * math.pi, 13);
    }
    if (_burst == 1 && elapsed > const Duration(milliseconds: 900)) {
      _burst = 2;
      final y = _size.height * 0.55;
      _add(Offset(-10, y), 70, -math.pi * 0.42, -math.pi * 0.18, 19);
      _add(
        Offset(_size.width + 10, y),
        70,
        -math.pi * 0.82,
        -math.pi * 0.58,
        19,
      );
    }
    final dt = ((elapsed - _last).inMicroseconds / 16667).clamp(0.25, 3.0);
    _last = elapsed;
    final drag = math.pow(0.985, dt).toDouble();
    for (final p in particles) {
      p.vy += 0.32 * dt;
      p.vx *= drag;
      p.vy *= drag;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
      p.flip += 0.12 * dt;
      p.life += dt;
    }
    particles.removeWhere((p) => p.y > _size.height + 40 || p.life > 260);
    if (elapsed > const Duration(milliseconds: 6500) ||
        (_burst == 2 && particles.isEmpty)) {
      _ticker.stop();
      particles.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.confetti) : super(repaint: confetti);

  final _Confetti confetti;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in confetti.particles) {
      if (p.x < -40 || p.x > size.width + 40 || p.y < -40) continue;
      paint.color = p.color.withValues(
        alpha: (1 - p.life / 260).clamp(0.0, 1.0),
      );
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.scale(1, math.cos(p.flip).abs() + 0.08);
      final rect = switch (p.shape) {
        2 => Rect.fromCenter(
          center: Offset.zero,
          width: p.w * 0.4,
          height: p.h * 1.6,
        ),
        1 => Rect.fromCenter(
          center: Offset.zero,
          width: p.w * 0.8,
          height: p.w * 0.8,
        ),
        _ => Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
      };
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
