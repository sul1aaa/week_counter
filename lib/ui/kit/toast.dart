import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass.dart';

OverlayEntry? _current;

/// A glass notice that drops in at the top and goes away by itself.
void showToast(BuildContext context, String text) {
  _current?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      text: text,
      onDone: () {
        if (_current == entry) _current = null;
        entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.text, required this.onDone});

  final String text;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 260),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2800), () async {
      await _show.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final curve = CurvedAnimation(parent: _show, curve: Motion.ios);
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 8,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(curve),
          child: Semantics(
            liveRegion: true,
            child: Glass(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  widget.text,
                  style: t.callout.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
