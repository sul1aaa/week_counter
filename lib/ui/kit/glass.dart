import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

/// Frosted iOS 26 glass: blurred, slightly saturated backdrop with a
/// hairline rim.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.shadow = true,
    this.blur = 24,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool shadow;
  final double blur;

  static final _saturate = ColorFilter.matrix(_saturation(1.4));

  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      i * r + s, i * g, i * b, 0, 0, //
      i * r, i * g + s, i * b, 0, 0, //
      i * r, i * g, i * b + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceTransparency = MediaQuery.highContrastOf(context);
    return CustomPaint(
      painter: shadow
          ? _OutsideShadowPainter(borderRadius, t.glassShadow)
          : null,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          enabled: !reduceTransparency,
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
            inner: _saturate,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: reduceTransparency ? t.surface : t.glass,
              borderRadius: borderRadius,
              border: Border.all(color: t.glassLine, width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round 44 pt glass button for navigation bars.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.solid = false,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Plain surface fill instead of glass, for use inside sheets.
  final bool solid;

  /// White on translucent white, for dark screens.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final iconWidget = Icon(icon, size: 24, color: dark ? Colors.white : t.ink);
    final Widget body;
    if (dark) {
      body = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: iconWidget,
      );
    } else if (solid) {
      body = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: t.surface2, shape: BoxShape.circle),
        child: iconWidget,
      );
    } else {
      body = SizedBox.square(
        dimension: 44,
        child: Glass(shadow: false, child: Center(child: iconWidget)),
      );
    }
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        semanticLabel: label,
        child: body,
      ),
    );
  }
}

/// A drop shadow painted only outside the shape, like a CSS box-shadow, so
/// it doesn't darken the glass from behind.
class _OutsideShadowPainter extends CustomPainter {
  const _OutsideShadowPainter(this.radius, this.color);

  final BorderRadius radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = radius.toRRect(Offset.zero & size);
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(64))
        ..addRRect(shape),
    );
    canvas.drawRRect(
      shape.shift(const Offset(0, 8)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OutsideShadowPainter old) =>
      old.radius != radius || old.color != color;
}
