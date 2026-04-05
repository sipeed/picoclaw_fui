import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:picoclaw_flutter_ui/src/core/ui_constants.dart';

/// AdaptiveActionBar
/// - Displays [content] and action widgets provided in [actions].
/// - On narrow screens or portrait orientation the actions are shown
///   in a bottom horizontal bar. On wide/landscape screens the actions
///   are shown in a vertical side bar.
class AdaptiveActionBar extends StatelessWidget {
  final Widget content;
  final List<Widget> actions; // expect action widgets
  final double breakpoint;

  const AdaptiveActionBar({
    super.key,
    required this.content,
    required this.actions,
    this.breakpoint = kAdaptiveBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isWide = constraints.maxWidth >= breakpoint;
        final orientation = MediaQuery.of(context).orientation;
        final useBottom = !isWide || orientation == Orientation.portrait;
        final shellColor = theme.colorScheme.surface;
        final overlayStyle = _systemUiOverlayStyleFor(shellColor);

        if (useBottom) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: ColoredBox(
              color: shellColor,
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(child: content),
                    Material(
                      elevation: 0,
                      color: shellColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: _ActionPanel(
                          actions: actions,
                          isBottom: true,
                          shellColor: shellColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: ColoredBox(
              color: shellColor,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(child: content),
                    _ActionPanel(
                      actions: actions,
                      isBottom: false,
                      shellColor: shellColor,
                      scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  SystemUiOverlayStyle _systemUiOverlayStyleFor(Color backgroundColor) {
    final backgroundBrightness = ThemeData.estimateBrightnessForColor(
      backgroundColor,
    );
    final useDarkIcons = backgroundBrightness == Brightness.light;

    return SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarDividerColor: backgroundColor,
      statusBarIconBrightness: useDarkIcons
          ? Brightness.dark
          : Brightness.light,
      systemNavigationBarIconBrightness: useDarkIcons
          ? Brightness.dark
          : Brightness.light,
      statusBarBrightness: useDarkIcons ? Brightness.light : Brightness.dark,
    );
  }
}

class _ActionPanel extends StatefulWidget {
  final List<Widget> actions;
  final bool isBottom;
  final Color shellColor;
  final Color? scaffoldBackgroundColor;

  const _ActionPanel({
    Key? key,
    required this.actions,
    required this.isBottom,
    required this.shellColor,
    this.scaffoldBackgroundColor,
  }) : super(key: key);

  @override
  _ActionPanelState createState() => _ActionPanelState();
}

class _ActionPanelState extends State<_ActionPanel> {
  late List<Widget> _wrappedActions;

  @override
  void initState() {
    super.initState();
    _wrappedActions = _wrap(widget.actions);
  }

  @override
  void didUpdateWidget(covariant _ActionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.actions, widget.actions)) {
      _wrappedActions = _wrap(widget.actions);
    }
  }

  List<Widget> _wrap(List<Widget> actions) {
    return actions
        .map(
          (a) => SizedBox(
            width: kActionButtonSize,
            height: kActionButtonSize,
            child: Center(child: a),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBottom) {
      return RepaintBoundary(
        child: Material(
          elevation: 0,
          color: widget.shellColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _wrappedActions,
            ),
          ),
        ),
      );
    }

    final scaffoldBg =
        widget.scaffoldBackgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    return RepaintBoundary(
      child: Container(
        width: kSideBarWidth,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: scaffoldBg,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _wrappedActions
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
