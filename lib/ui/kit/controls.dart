import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'buttons.dart';
import 'pressable.dart';

/// iOS 26 switch: a wide track with a capsule knob.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedContainer(
            duration: Motion.mid,
            curve: Motion.out,
            width: 64,
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? t.ink : t.surface3,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: Motion.mid,
              curve: Motion.ios,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 38,
                height: 24,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control with a sliding highlight.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final index = segments.indexWhere((s) => s.$1 == selected);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositioned(
                  duration: Motion.mid,
                  curve: Motion.ios,
                  left: width * index,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.isDark ? t.surface3 : t.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final (value, label) in segments)
                    Expanded(
                      child: Semantics(
                        selected: value == selected,
                        child: Pressable(
                          scale: 1,
                          onTap: () => onChanged(value),
                          child: Center(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: Fonts.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: value == selected ? t.ink : t.ink2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

enum InlineTone { violet, lime, warn }

/// A tappable notice card: icon tile, title, one line of detail.
class InlineCard extends StatelessWidget {
  const InlineCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tone = InlineTone.violet,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final InlineTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = switch (tone) {
      InlineTone.violet => (t.violetSoft, t.violetInk),
      InlineTone.lime => (t.limeSoft, t.limeInk),
      InlineTone.warn => (t.danger.withValues(alpha: 0.14), t.danger),
    };
    final card = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconTile(icon: icon, size: 36, background: bg, foreground: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.callout.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) Text(subtitle!, style: t.footnote),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 20, color: t.ink3),
        ],
      ),
    );
    if (onTap == null) return MergeSemantics(child: card);
    return Pressable(onTap: onTap, scale: 0.985, child: card);
  }
}
