import 'package:flutter/material.dart';
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
        final isWide = constraints.maxWidth >= breakpoint;
        final orientation = MediaQuery.of(context).orientation;
        final useBottom = !isWide || orientation == Orientation.portrait;

        if (useBottom) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(child: content),
                Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actions.map((a) => _wrapAction(a)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return SafeArea(
            child: Row(
              children: [
                Expanded(child: content),
                Container(
                  width: kSideBarWidth,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: actions
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _wrapAction(a),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _wrapAction(Widget w) {
    return SizedBox(
      width: kActionButtonSize,
      height: kActionButtonSize,
      child: Center(child: w),
    );
  }
}
