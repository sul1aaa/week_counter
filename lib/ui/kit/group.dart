import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'buttons.dart';
import 'pressable.dart';

/// Inset grouped list: rounded card with hairlines between rows.
class Group extends StatelessWidget {
  const Group({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.color,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  /// Defaults to the surface color; sheets pass their card color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.only(
                  left: _hasIcon(child) || _hasIcon(children[i - 1]) ? 56 : 16,
                ),
                child: Divider(height: 0.5, thickness: 0.5, color: t.line),
              ),
            child,
          ],
        ],
      ),
    );
  }

  static bool _hasIcon(Widget w) => w is GroupRow && w.icon != null;
}

/// One row of a [Group]: optional icon tile, title and subtitle, value,
/// chevron when tappable.
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = true,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Replaces the icon tile, e.g. a flag.
  final Widget? leading;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  /// Shows a check mark, for single-choice lists.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              IconTile(icon: icon!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.body),
                  if (subtitle != null) Text(subtitle!, style: t.footnote),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.body.copyWith(color: t.ink2),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (selected) ...[
              const SizedBox(width: 12),
              Icon(Icons.check_rounded, color: t.violetInk),
            ] else if (onTap != null && chevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: t.ink3),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) {
      return MergeSemantics(child: content);
    }
    return Pressable(onTap: onTap, highlight: t.surface2, child: content);
  }
}

/// Small grey heading above a [Group].
class GroupHeader extends StatelessWidget {
  const GroupHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: t.footnote.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Section heading in display type: "October", "Upcoming holidays".
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: context.tokens.sectionTitle),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
