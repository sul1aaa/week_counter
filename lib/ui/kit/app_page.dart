import 'package:flutter/cupertino.dart';

import '../theme/tokens.dart';

/// A scrolling page with an iOS large title. The compact title and a soft
/// fade appear in the bar once the content scrolls under it.
class AppPage extends StatefulWidget {
  const AppPage({
    super.key,
    required this.children,
    this.title,
    this.largeTitle = true,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onRefresh,
    this.barAlways = false,
    this.titleOnScroll = false,
    this.bottomPadding,
    this.controller,
  });

  final List<Widget> children;
  final String? title;
  final bool largeTitle;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;

  /// Keep the fade behind the bar even at the top of the page.
  final bool barAlways;

  /// Without a large title, show the compact one only after scrolling.
  final bool titleOnScroll;

  /// Space after the content; defaults to room for the floating tab bar.
  final double? bottomPadding;
  final ScrollController? controller;

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  late final ScrollController _scroll = widget.controller ?? ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    if (widget.controller == null) _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scroll.hasClients && _scroll.offset > 8;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pad = MediaQuery.paddingOf(context);
    final title = widget.title;
    return ColoredBox(
      color: t.bg,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: pad.top + 52)),
              if (widget.onRefresh != null)
                CupertinoSliverRefreshControl(onRefresh: widget.onRefresh),
              if (widget.largeTitle && title != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Semantics(
                      header: true,
                      child: Text(title, style: t.largeTitle),
                    ),
                  ),
                ),
              if (widget.subtitle != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Text(widget.subtitle!, style: t.callout),
                  ),
                ),
              SliverList.list(children: widget.children),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: widget.bottomPadding ?? pad.bottom + 104,
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: NavBar(
              title: title,
              showTitle:
                  _scrolled || !(widget.largeTitle || widget.titleOnScroll),
              titleIsDuplicate: widget.largeTitle,
              showFade: _scrolled || widget.barAlways,
              leading: widget.leading,
              trailing: widget.trailing,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top bar: round buttons at the sides, a centered title.
class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    this.title,
    this.showTitle = true,
    this.titleIsDuplicate = false,
    this.showFade = true,
    this.leading,
    this.trailing,
  });

  final String? title;
  final bool showTitle;

  /// The large title already says the same, so screen readers skip this one.
  final bool titleIsDuplicate;
  final bool showFade;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final top = MediaQuery.paddingOf(context).top;
    Widget titleText = AnimatedOpacity(
      opacity: showTitle ? 1 : 0,
      duration: Motion.fast,
      child: Text(
        title ?? '',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.navTitle,
      ),
    );
    if (titleIsDuplicate) titleText = ExcludeSemantics(child: titleText);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -24,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: showFade ? 1 : 0,
              duration: Motion.fast,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [t.bg, t.bg, t.bg.withAlpha(0)],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 2, 16, 8),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44),
                  child: leading ?? const SizedBox(),
                ),
                const SizedBox(width: 8),
                Expanded(child: titleText),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44),
                  child: trailing ?? const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
