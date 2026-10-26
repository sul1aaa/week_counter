import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens from the «Выходные» prototype: Wabi neutrals with lime and
/// violet accents, in light and dark.
@immutable
class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.inverse,
    required this.onInverse,
    required this.limeInk,
    required this.limeSoft,
    required this.violetInk,
    required this.violetSoft,
    required this.danger,
    required this.glass,
    required this.glassLine,
    required this.glassShadow,
    required this.scrim,
    required this.sheet,
    required this.sheetCard,
    required this.widgetBg,
  });

  static const light = Tokens(
    brightness: Brightness.light,
    bg: Color(0xFFF2F1EE),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE8E6E1),
    surface3: Color(0xFFDCD9D3),
    ink: Color(0xFF111111),
    ink2: Color(0xFF5C5A55),
    ink3: Color(0xFF767470),
    line: Color(0x14111111),
    inverse: Color(0xFF111111),
    onInverse: Color(0xFFFFFFFF),
    limeInk: Color(0xFF3F5A00),
    limeSoft: Color(0xFFE9FBB0),
    violetInk: Color(0xFF5B2FD6),
    violetSoft: Color(0xFFE6DDFD),
    danger: Color(0xFFC4321F),
    glass: Color(0xB8FAFAF8),
    glassLine: Color(0xB3FFFFFF),
    glassShadow: Color(0x1F000000),
    scrim: Color(0x52000000),
    sheet: Color(0xFFF2F1EE),
    sheetCard: Color(0xFFFFFFFF),
    widgetBg: Color(0xFF111111),
  );

  static const dark = Tokens(
    brightness: Brightness.dark,
    bg: Color(0xFF000000),
    surface: Color(0xFF151515),
    surface2: Color(0xFF232323),
    surface3: Color(0xFF2E2E2E),
    ink: Color(0xFFF5F5F5),
    ink2: Color(0xFFA3A19C),
    ink3: Color(0xFF6E6C68),
    line: Color(0x17FFFFFF),
    inverse: Color(0xFFF5F5F5),
    onInverse: Color(0xFF111111),
    limeInk: Color(0xFFC8F53C),
    limeSoft: Color(0xFF26300A),
    violetInk: Color(0xFFB9A0FF),
    violetSoft: Color(0xFF241A3D),
    danger: Color(0xFFFF6B57),
    glass: Color(0x9E262626),
    glassLine: Color(0x1FFFFFFF),
    glassShadow: Color(0x80000000),
    scrim: Color(0x8C000000),
    sheet: Color(0xFF1C1C1E),
    sheetCard: Color(0xFF2A2A2A),
    widgetBg: Color(0xFF1C1C1E),
  );

  // The same in both themes.
  static const lime = Color(0xFFC8F53C);
  static const violet = Color(0xFF7C4DF0);
  static const widgetInk = Color(0xFFF5F5F5);
  static const widgetInk2 = Color(0xFFA3A19C);

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color inverse;
  final Color onInverse;
  final Color limeInk;
  final Color limeSoft;
  final Color violetInk;
  final Color violetSoft;
  final Color danger;
  final Color glass;
  final Color glassLine;
  final Color glassShadow;
  final Color scrim;
  final Color sheet;
  final Color sheetCard;
  final Color widgetBg;

  bool get isDark => brightness == Brightness.dark;

  /// Transparent status and navigation bars over [bg], as on iOS. Replaces
  /// MaterialApp's default, which paints Android's navigation bar black.
  /// Android 7 can't draw dark navigation buttons and keeps its black bar.
  SystemUiOverlayStyle get systemBars {
    final icons = isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: icons,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
    );
  }

  @override
  Tokens copyWith() => this;

  @override
  Tokens lerp(Tokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// Font families and the type ramp.
abstract final class Fonts {
  static const display = 'Inter Tight';
  static const text = 'Inter';
  static const mono = 'JetBrains Mono';

  static const tabular = [FontFeature.tabularFigures()];
}

/// Motion curves and durations.
abstract final class Motion {
  static const ios = Cubic(0.32, 0.72, 0, 1);
  static const out = Cubic(0.2, 0.8, 0.2, 1);
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const fast = Duration(milliseconds: 180);
  static const mid = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 500);
}

extension TokensContext on BuildContext {
  Tokens get tokens => Theme.of(this).extension<Tokens>()!;

  /// True when the user asked the system to reduce motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Text styles from the prototype, colored with [Tokens].
extension TypeRamp on Tokens {
  TextStyle get largeTitle => TextStyle(
    fontFamily: Fonts.display,
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.85,
    color: ink,
  );

  TextStyle get navTitle => TextStyle(
    fontFamily: Fonts.text,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.34,
    color: ink,
  );

  TextStyle get body => TextStyle(
    fontFamily: Fonts.text,
    fontSize: 17,
    height: 22 / 17,
    letterSpacing: -0.34,
    color: ink,
  );

  TextStyle get callout => TextStyle(
    fontFamily: Fonts.text,
    fontSize: 15,
    height: 20 / 15,
    color: ink2,
  );

  TextStyle get footnote => TextStyle(
    fontFamily: Fonts.text,
    fontSize: 13,
    height: 18 / 13,
    color: ink2,
  );

  TextStyle get sectionTitle => TextStyle(
    fontFamily: Fonts.display,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.66,
    color: ink,
  );

  TextStyle get mono => TextStyle(
    fontFamily: Fonts.mono,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.13,
    color: ink2,
  );
}
