import 'package:flutter/material.dart';

import '../../domain/awards.dart';
import '../theme/tokens.dart';

/// A metal badge with coloured enamel and a stamped mark. Locked badges are
/// flat and grey.
class AwardBadge extends StatelessWidget {
  const AwardBadge({
    super.key,
    required this.award,
    required this.mark,
    required this.size,
    this.locked = false,
  });

  final Award award;
  final String mark;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BadgePainter(
          shape: _shapes[award.shape]!,
          enamel: _enamels[award.enamel]!,
          mark: mark,
          locked: locked,
          lockedFill: t.surface2,
          lockedRim: t.surface3,
          lockedInk: t.ink2,
          markColor: award.enamel == Enamel.violet
              ? Colors.white
              : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

const _enamels = <Enamel, List<Color>>{
  Enamel.violet: [Color(0xFFB9A0FF), Color(0xFF7C4DF0), Color(0xFF4A22B8)],
  Enamel.lime: [Color(0xFFF0FFB8), Color(0xFFC8F53C), Color(0xFF7FB800)],
  Enamel.silver: [Color(0xFFFFFFFF), Color(0xFFC9CCD3), Color(0xFF8A8F99)],
};

Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

/// Outlines on a 100 × 100 grid.
final _shapes = <AwardShape, Path>{
  AwardShape.circle: Path()
    ..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 46)),
  AwardShape.hex: _polygon(const [
    Offset(50, 3),
    Offset(91, 26.5),
    Offset(91, 73.5),
    Offset(50, 97),
    Offset(9, 73.5),
    Offset(9, 26.5),
  ]),
  AwardShape.shield: Path()
    ..moveTo(50, 4)
    ..cubicTo(64, 12, 78, 15, 90, 15)
    ..lineTo(90, 49)
    ..cubicTo(90, 75, 73, 90, 50, 97)
    ..cubicTo(27, 90, 10, 75, 10, 49)
    ..lineTo(10, 15)
    ..cubicTo(22, 15, 36, 12, 50, 4)
    ..close(),
  AwardShape.octagon: _polygon(const [
    Offset(32, 4),
    Offset(68, 4),
    Offset(96, 32),
    Offset(96, 68),
    Offset(68, 96),
    Offset(32, 96),
    Offset(4, 68),
    Offset(4, 32),
  ]),
  AwardShape.star: _polygon(const [
    Offset(50, 3),
    Offset(61, 20),
    Offset(81, 15),
    Offset(80, 35),
    Offset(97, 46),
    Offset(83, 61),
    Offset(89, 80),
    Offset(69, 83),
    Offset(63, 103),
    Offset(50, 88),
    Offset(37, 103),
    Offset(31, 83),
    Offset(11, 80),
    Offset(17, 61),
    Offset(3, 46),
    Offset(20, 35),
    Offset(19, 15),
    Offset(39, 20),
  ]),
};

class _BadgePainter extends CustomPainter {
  _BadgePainter({
    required this.shape,
    required this.enamel,
    required this.mark,
    required this.locked,
    required this.lockedFill,
    required this.lockedRim,
    required this.lockedInk,
    required this.markColor,
  });

  final Path shape;
  final List<Color> enamel;
  final String mark;
  final bool locked;
  final Color lockedFill;
  final Color lockedRim;
  final Color lockedInk;
  final Color markColor;

  static const _box = Rect.fromLTWH(0, 0, 100, 100);

  @override
  void paint(Canvas canvas, Size size) {
    // The grid is 108 wide with a 4-unit margin, as in the prototype.
    final k = size.width / 108;
    canvas.save();
    canvas.scale(k);
    canvas.translate(4, 4);

    if (locked) {
      canvas.drawPath(shape, Paint()..color = lockedFill);
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = lockedRim,
      );
    } else {
      final metal = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFC7CAD1),
          Color(0xFFF4F5F7),
          Color(0xFF8D929C),
          Color(0xFFDADDE2),
        ],
        stops: [0, 0.35, 0.55, 0.8, 1],
      ).createShader(_box);
      canvas.drawPath(
        shape.shift(const Offset(0, 10 / 1.8)),
        Paint()
          ..color = const Color(0x2E000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawPath(shape, Paint()..shader = metal);

      final inner = shape.transform(
        (Matrix4.identity()
              ..translateByDouble(50, 50, 0, 1)
              ..scaleByDouble(0.82, 0.82, 1, 1)
              ..translateByDouble(-50, -50, 0, 1))
            .storage,
      );
      canvas.drawPath(
        inner,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(-0.6, -1),
            end: const Alignment(0.6, 1),
            colors: enamel,
            stops: const [0, 0.45, 1],
          ).createShader(_box),
      );
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..shader = metal,
      );
      // A soft diagonal shine across the face.
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawLine(
        const Offset(14, 30),
        const Offset(86, 70),
        Paint()
          ..strokeWidth = 16
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(_box),
      );
      canvas.restore();
    }

    final text = TextPainter(
      text: TextSpan(
        text: mark,
        style: TextStyle(
          fontFamily: Fonts.display,
          fontSize: mark.length > 2 ? 24 : 32,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: locked ? lockedInk : markColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(50 - text.width / 2, 50 - text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.mark != mark ||
      old.locked != locked ||
      old.shape != shape ||
      old.lockedFill != lockedFill ||
      old.markColor != markColor;
}
