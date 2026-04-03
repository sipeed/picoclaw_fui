import 'package:flutter/material.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:remixicon/remixicon.dart';

/// Floating draggable nav-bar (back / forward / reload) for WebView pages.
///
/// Usage — place as a [Positioned.fill] child inside the parent [Stack]:
/// ```dart
/// Stack(children: [
///   webviewWidget,
///   Positioned.fill(child: DraggableWebNavBar(
///     onBack:    () => controller.goBack(),
///     onForward: () => controller.goForward(),
///     onReload:  () => controller.reload(),
///   )),
/// ])
/// ```
/// Only the pill itself absorbs pointer events; the surrounding transparent
/// area passes through to the WebView below.
class DraggableWebNavBar extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onReload;

  const DraggableWebNavBar({
    super.key,
    this.onBack,
    this.onForward,
    this.onReload,
  });

  @override
  State<DraggableWebNavBar> createState() => _DraggableWebNavBarState();
}

class _DraggableWebNavBarState extends State<DraggableWebNavBar> {
  // null = not yet positioned (default top-right derived from constraints)
  Offset? _offset;
  bool _isDragging = false;

  // Cached from LayoutBuilder so gesture callbacks can access container size
  // without a GlobalKey + findRenderObject() (avoids hasSize crash).
  BoxConstraints? _constraints;

  // Pill size estimate: 3 × IconButton(48×48) + Padding(h:4, v:2)
  static const double _pillW = 152.0;
  static const double _pillH = 52.0;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Offset _clamp(Offset o) {
    if (_constraints == null) return o;
    final maxX = (_constraints!.maxWidth - _pillW).clamp(0.0, double.infinity);
    final maxY = (_constraints!.maxHeight - _pillH).clamp(0.0, double.infinity);
    return Offset(o.dx.clamp(0.0, maxX), o.dy.clamp(0.0, maxY));
  }

  void _ensureOffset() {
    if (_offset != null || _constraints == null) return;
    final maxX = (_constraints!.maxWidth - _pillW).clamp(0.0, double.infinity);
    _offset = Offset((maxX - 12.0).clamp(0.0, maxX), 12.0);
  }

  // ---------------------------------------------------------------------------
  // Gesture handlers — use delta so the pill moves WITH the finger instead of
  // jumping to the finger's absolute position (avoids globalToLocal crash).
  // ---------------------------------------------------------------------------

  void _handlePanStart(DragStartDetails _) {
    _ensureOffset();
    setState(() => _isDragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_offset == null) return;
    setState(
      () => _offset = _clamp(
        Offset(_offset!.dx + details.delta.dx, _offset!.dy + details.delta.dy),
      ),
    );
  }

  void _handlePanEnd(DragEndDetails _) {
    // Compute snap target directly (no setState) then animate in one rebuild.
    _computeSnapOffset();
    setState(() => _isDragging = false);
  }

  /// Sets [_offset] to the nearest-edge snap position WITHOUT calling setState.
  /// The caller must trigger a rebuild so the animation uses the correct duration.
  void _computeSnapOffset() {
    if (_offset == null || _constraints == null) return;
    final maxX = (_constraints!.maxWidth - _pillW).clamp(0.0, double.infinity);
    final maxY = (_constraints!.maxHeight - _pillH).clamp(0.0, double.infinity);
    final dx = _offset!.dx.clamp(0.0, maxX);
    final dy = _offset!.dy.clamp(0.0, maxY);

    final dLeft = dx;
    final dRight = maxX - dx;
    final dTop = dy;
    final dBottom = maxY - dy;

    double finalDx, finalDy;
    if (dLeft <= dRight && dLeft <= dTop && dLeft <= dBottom) {
      finalDx = 0.0;
      finalDy = dy.clamp(0.0, maxY);
    } else if (dRight <= dTop && dRight <= dBottom) {
      finalDx = maxX;
      finalDy = dy.clamp(0.0, maxY);
    } else if (dTop <= dBottom) {
      finalDx = dx.clamp(0.0, maxX);
      finalDy = 0.0;
    } else {
      finalDx = dx.clamp(0.0, maxX);
      finalDy = maxY;
    }
    _offset = Offset(finalDx, finalDy);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Cache for gesture callbacks — direct field write, no setState needed.
        _constraints = constraints;

        final maxX = (constraints.maxWidth - _pillW).clamp(
          0.0,
          double.infinity,
        );
        final maxY = (constraints.maxHeight - _pillH).clamp(
          0.0,
          double.infinity,
        );

        // Clamp stored offset into current bounds (handles window resize).
        final effective = _offset != null
            ? Offset(_offset!.dx.clamp(0.0, maxX), _offset!.dy.clamp(0.0, maxY))
            : Offset((maxX - 12.0).clamp(0.0, maxX), 12.0);

        final pill = Material(
          color: colorScheme.surface.withAlpha(
            ((0.7).clamp(0.0, 1.0) * 255).round(),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Remix.arrow_left_s_line,
                    color: colorScheme.secondary,
                  ),
                  tooltip: l10n.back,
                  onPressed: widget.onBack,
                ),
                IconButton(
                  icon: Icon(
                    Remix.arrow_right_s_line,
                    color: colorScheme.secondary,
                  ),
                  tooltip: l10n.forward,
                  onPressed: widget.onForward,
                ),
                IconButton(
                  icon: Icon(Remix.refresh_line, color: colorScheme.secondary),
                  tooltip: l10n.refresh,
                  onPressed: widget.onReload,
                ),
              ],
            ),
          ),
        );

        final animatedPill = AnimatedScale(
          scale: _isDragging ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              boxShadow: _isDragging
                  ? [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: pill,
          ),
        );

        final draggable = MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: animatedPill,
          ),
        );

        // Always AnimatedPositioned — no Positioned↔AnimatedPositioned type
        // switch in the Stack (type switching causes assertion failures).
        //
        // Duration.zero during drag  → immediate response to finger movement.
        // 220 ms after release       → smooth snap-to-edge animation.
        return Stack(
          children: [
            AnimatedPositioned(
              left: effective.dx,
              top: effective.dy,
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: draggable,
            ),
          ],
        );
      },
    );
  }
}
