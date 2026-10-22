import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass.dart';

/// Opens a floating iOS 26 sheet: rounded card with a grabber, a centered
/// title and a close button. Drag down to dismiss.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  required WidgetBuilder builder,
}) {
  final t = context.tokens;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: t.scrim,
    elevation: 0,
    sheetAnimationStyle: const AnimationStyle(
      duration: Motion.slow,
      reverseDuration: Duration(milliseconds: 300),
    ),
    builder: (context) => AppSheet(title: title, child: builder(context)),
  );
}

class AppSheet extends StatelessWidget {
  const AppSheet({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final media = MediaQuery.of(context);
    final safeBottom = media.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + media.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.sheet,
          borderRadius: BorderRadius.circular(38),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 40,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: t.surface3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        style: t.navTitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    icon: Icons.close_rounded,
                    label: MaterialLocalizations.of(context).closeButtonLabel,
                    solid: true,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  (safeBottom - 8).clamp(0, double.infinity) + 8,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
