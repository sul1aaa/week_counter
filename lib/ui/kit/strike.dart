import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A word that gets crossed out: the line draws itself left to right.
class StrikeText extends StatefulWidget {
  const StrikeText(
    this.text, {
    super.key,
    required this.style,
    this.delay = const Duration(milliseconds: 380),
  });

  final String text;
  final TextStyle style;
  final Duration delay;

  @override
  State<StrikeText> createState() => _StrikeTextState();
}

class _StrikeTextState extends State<StrikeText>
    with SingleTickerProviderStateMixin {
  static const _draw = Duration(milliseconds: 420);

  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: widget.delay + _draw,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _line,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _draw).inMilliseconds,
      1,
      curve: Motion.out,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_line.isAnimating || _line.isCompleted) return;
    if (context.reduceMotion) {
      _line.value = 1;
    } else {
      _line.forward();
    }
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _StrikePainter(
        progress: _progress,
        color: widget.style.color ?? context.tokens.ink3,
      ),
      child: Text(widget.text, style: widget.style),
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter({required this.progress, required this.color})
    : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value == 0) return;
    final y = size.height * 0.54;
    final width = (size.width + 4) * progress.value;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-2, y - 1.25, width, 2.5),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.color != color || old.progress != progress;
}

/// Splits "a ~~b~~ c" into spans with "b" struck through in [strike].
List<TextSpan> strikeSpans(String text, Color strike) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'~~(.+?)~~');
  var last = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: strike,
          decoration: TextDecoration.lineThrough,
          decorationColor: strike,
          decorationThickness: 2,
        ),
      ),
    );
    last = match.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// [text] without the `~~` markers, for screen readers.
String plainText(String text) => text.replaceAll('~~', '');
