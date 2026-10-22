import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../kit/pressable.dart';
import '../kit/strike.dart';
import '../theme/tokens.dart';

/// Up to three lines of the week, side by side; the next card peeks in.
class JokeCarousel extends StatelessWidget {
  const JokeCarousel({super.key, required this.lines, required this.onMore});

  final List<String> lines;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.jokesLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth * 0.84;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: _SnapPhysics(extent: cardWidth + 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, line) in lines.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Container(
                      width: cardWidth,
                      constraints: const BoxConstraints(minHeight: 128),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Semantics(
                              label: plainText(line),
                              excludeSemantics: true,
                              child: Text.rich(
                                TextSpan(children: strikeSpans(line, t.ink3)),
                                style: TextStyle(
                                  fontFamily: Fonts.display,
                                  fontSize: 19,
                                  height: 25 / 19,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.38,
                                  color: t.ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 24,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ExcludeSemantics(
                                    child: Text(
                                      '${i + 1} / ${lines.length}',
                                      style: t.mono.copyWith(fontSize: 12),
                                    ),
                                  ),
                                ),
                                if (i == 0)
                                  Pressable(
                                    onTap: onMore,
                                    scale: 0.9,
                                    semanticLabel: l10n.jokesMore,
                                    child: SizedBox.square(
                                      dimension: 44,
                                      child: Icon(
                                        Icons.refresh_rounded,
                                        color: t.ink2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Snaps a horizontal list so a card's left edge lines up with the padding.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.extent, super.parent});

  final double extent;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(extent: extent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var page = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    final target = (page.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
