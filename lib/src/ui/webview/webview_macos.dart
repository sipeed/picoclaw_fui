import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:remixicon/remixicon.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewMacOS extends StatefulWidget {
  final String url;
  final VoidCallback? onGoToDashboard;

  const WebViewMacOS({super.key, required this.url, this.onGoToDashboard});

  @override
  State<WebViewMacOS> createState() => _WebViewMacOSState();
}

class _WebViewMacOSState extends State<WebViewMacOS> {
  WebViewController? _controller;
  bool _isReady = false;
  bool _isError = false;

  final List<String> _actionOrder = ['back', 'forward', 'reload'];
  Offset? _actionsOffset;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();
  bool _dragActive = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isReady = false);
          },
          onPageFinished: (_) async {
            try {
              await _controller!.runJavaScript(
                "document.addEventListener('contextmenu',function(e){e.preventDefault();});",
              );
            } catch (_) {}
            if (mounted)
              setState(() {
                _isReady = true;
                _isError = false;
              });
          },
          onWebResourceError: (_) {
            if (mounted)
              setState(() {
                _isReady = true;
                _isError = true;
              });
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      );
    _controller!.loadRequest(Uri.parse(widget.url));
  }

  void _snapActionsToEdge() {
    if (_actionsOffset == null) return;
    try {
      final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final actionBox =
          _actionsKey.currentContext?.findRenderObject() as RenderBox?;
      final actionW = actionBox?.size.width ?? 80.0;
      final actionH = actionBox?.size.height ?? 56.0;
      final maxX = (box.size.width - actionW).clamp(0.0, double.infinity);
      final maxY = (box.size.height - actionH).clamp(0.0, double.infinity);
      final dx = _actionsOffset!.dx.clamp(0.0, maxX);
      final dy = _actionsOffset!.dy.clamp(0.0, maxY);

      double minDist = dx;
      String edge = 'left';
      if ((maxX - dx).abs() < minDist) {
        minDist = (maxX - dx).abs();
        edge = 'right';
      }
      if (dy < minDist) {
        minDist = dy;
        edge = 'top';
      }
      if ((maxY - dy).abs() < minDist) {
        minDist = (maxY - dy).abs();
        edge = 'bottom';
      }

      double finalDx = dx;
      double finalDy = dy;
      switch (edge) {
        case 'left':
          finalDx = 0.0;
          finalDy = dy.clamp(0.0, maxY);
          break;
        case 'right':
          finalDx = maxX;
          finalDy = dy.clamp(0.0, maxY);
          break;
        case 'top':
          finalDy = 0.0;
          finalDx = dx.clamp(0.0, maxX);
          break;
        case 'bottom':
          finalDy = maxY;
          finalDx = dx.clamp(0.0, maxX);
          break;
      }
      setState(() => _actionsOffset = Offset(finalDx, finalDy));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildAction(String key) {
      Icon icon;
      String tooltip;
      VoidCallback? handler;
      switch (key) {
        case 'back':
          icon = Icon(Remix.arrow_left_s_line, color: colorScheme.secondary);
          tooltip = l10n.back;
          handler = () => _controller?.goBack();
          break;
        case 'forward':
          icon = Icon(Remix.arrow_right_s_line, color: colorScheme.secondary);
          tooltip = l10n.forward;
          handler = () => _controller?.goForward();
          break;
        case 'reload':
        default:
          icon = Icon(Remix.refresh_line, color: colorScheme.secondary);
          tooltip = l10n.refresh;
          handler = () => _controller?.reload();
          break;
      }
      return IconButton(icon: icon, tooltip: tooltip, onPressed: handler);
    }

    final Widget inner = Material(
      key: _actionsKey,
      color: colorScheme.surface.withAlpha(
        ((0.7).clamp(0.0, 1.0) * 255).round(),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _actionOrder.map(buildAction).toList(),
        ),
      ),
    );

    final Widget actionsGroup = AnimatedScale(
      scale: _dragActive ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          boxShadow: _dragActive
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
        child: inner,
      ),
    );

    final draggable = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragActive = true),
        onPanUpdate: (details) {
          try {
            final box =
                _stackKey.currentContext?.findRenderObject() as RenderBox?;
            if (box != null) {
              final local = box.globalToLocal(details.globalPosition);
              final actionBox =
                  _actionsKey.currentContext?.findRenderObject() as RenderBox?;
              final actionW = actionBox?.size.width ?? 80.0;
              final actionH = actionBox?.size.height ?? 56.0;
              final maxX = (box.size.width - actionW).clamp(
                0.0,
                double.infinity,
              );
              final maxY = (box.size.height - actionH).clamp(
                0.0,
                double.infinity,
              );
              setState(
                () => _actionsOffset = Offset(
                  local.dx.clamp(0.0, maxX),
                  local.dy.clamp(0.0, maxY),
                ),
              );
            }
          } catch (_) {}
        },
        onPanEnd: (_) {
          setState(() => _dragActive = false);
          _snapActionsToEdge();
        },
        child: actionsGroup,
      ),
    );

    final Widget actionsBar = _actionsOffset != null
        ? AnimatedPositioned(
            left: _actionsOffset!.dx,
            top: _actionsOffset!.dy,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: draggable,
          )
        : Container(
            alignment: Alignment.topRight,
            margin: const EdgeInsets.only(top: 12, right: 12),
            child: draggable,
          );

    return Stack(
      key: _stackKey,
      children: [
        SizedBox.expand(child: WebViewWidget(controller: _controller!)),
        actionsBar,
        if (_isError)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(
                ((0.45).clamp(0.0, 1.0) * 255).round(),
              ),
              child: Center(
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Web content failed to load',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() => _isError = false);
                                _initWebView();
                              },
                              child: const Text('Retry'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: widget.onGoToDashboard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                foregroundColor: colorScheme.onSurface,
                              ),
                              child: const Text('Back'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
