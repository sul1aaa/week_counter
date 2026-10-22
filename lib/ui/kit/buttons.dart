import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

enum ButtonKind {
  /// Ink on light, white on dark: the main action.
  primary,
  secondary,
  lime,
  ghost,

  /// Near-black in both themes, for use on the lime flood.
  ink,
}

/// Full-width pill button, 50 pt tall.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = ButtonKind.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final ButtonKind kind;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = switch (kind) {
      ButtonKind.primary => (t.inverse, t.onInverse),
      ButtonKind.secondary => (t.surface2, t.ink),
      ButtonKind.lime => (Tokens.lime, const Color(0xFF111111)),
      ButtonKind.ghost => (Colors.transparent, t.ink),
      ButtonKind.ink => (const Color(0xFF111111), const Color(0xFFF5F5F5)),
    };
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: kind == ButtonKind.ghost ? 44 : 50,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Fonts.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.17,
                    color: fg,
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

/// Small pill showing a value such as a time; tappable to edit it.
class ValuePill extends StatelessWidget {
  const ValuePill({
    super.key,
    required this.text,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
    this.error = false,
  });

  final String text;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = error
        ? (t.danger.withValues(alpha: 0.14), t.danger)
        : selected
        ? (t.violetSoft, t.violetInk)
        : (t.surface2, t.ink);
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: AnimatedContainer(
        duration: Motion.fast,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: Fonts.text,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            fontFeatures: Fonts.tabular,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Rounded square with an icon, used in list rows and inline cards.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 28,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? t.surface2,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.58, color: foreground ?? t.ink),
    );
  }
}

/// The main action pinned to the bottom of a screen, over a fade.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.bg.withAlpha(0), t.bg, t.bg],
          stops: const [0, 0.28, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: children,
        ),
      ),
    );
  }
}
