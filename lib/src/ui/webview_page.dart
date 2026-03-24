import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_wv;
import 'dart:io';
import 'dart:async';

class WebViewPage extends StatefulWidget {
  final String url;
  final VoidCallback? onGoToDashboard;
  const WebViewPage({super.key, required this.url, this.onGoToDashboard});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  // Mobile
  WebViewController? _mobileController;

  // Windows specific
  win_wv.WebviewController? _winController;
  bool _winReady = false;
  bool _winError = false;
  int _winBlankCount = 0;
  StreamSubscription? _winLoadingSub;
  StreamSubscription? _winLoadErrorSub;

  // Pending scroll aggregation to avoid flooding executeScript calls.
  double _pendingScrollDy = 0.0;
  bool _scrollScheduled = false;

  bool _isLoading = true;
  // Action order for draggable controls. Values: 'back','forward','reload'
  final List<String> _actionOrder = ['back', 'forward', 'reload'];
  // Offset for draggable actions group in the WebView stack (local coordinates).
  Offset? _actionsOffset;
  final GlobalKey _webviewStackKey = GlobalKey();
  // Key to measure the actions group's size so snapping clamps correctly.
  final GlobalKey _actionsKey = GlobalKey();
  // Whether dragging the whole group requires a long press to start.
  // Default: require long press on touch platforms, allow direct drag on desktop.
  final bool _dragRequiresLongPress = Platform.isAndroid || Platform.isIOS;
  bool _dragActive = false; // true while in long-press dragging session

  @override
  void initState() {
    super.initState();
    final service = context.read<ServiceManager>();
    if (service.status == ServiceStatus.running) {
      _initControllers();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<ServiceManager>();
    // Initialize controllers if service becomes running and controllers are not initialized yet
    if (service.status == ServiceStatus.running) {
      if (Platform.isAndroid || Platform.isIOS) {
        if (_mobileController == null) {
          _initControllers();
        }
      } else if (Platform.isWindows) {
        if (_winController == null) {
          _initControllers();
        }
      }
    }
  }

  void _initControllers() {
    if (Platform.isAndroid || Platform.isIOS) {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onProgress: (int progress) {
              if (progress < 100) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (String url) async {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (err) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        );

      // Load the URL, replacing 0.0.0.0 with 127.0.0.1 for local access
      final targetUrl = widget.url.replaceFirst('0.0.0.0', '127.0.0.1');
      _mobileController!.loadRequest(Uri.parse(targetUrl));
    } else if (Platform.isWindows) {
      _initWindowsWebView();
    }
  }

  Future<void> _initWindowsWebView() async {
    try {
      _winController ??= win_wv.WebviewController();
      await _winController!.initialize();
      // Ensure it's focused on load
      // Use an opaque background to avoid GPU/transparent compositing issues
      await _winController!.setBackgroundColor(Colors.white);

      // Disable context menu via script for consistent UX
      try {
        await _winController!.addScriptToExecuteOnDocumentCreated(
          "document.addEventListener('contextmenu', function(e){e.preventDefault();});",
        );
      } catch (_) {}

      // Listen for loading state and errors to detect blank/frozen views
      // Save subscriptions so we can cancel them on reinit/dispose to avoid leaks
      _winLoadingSub?.cancel();
      _winLoadErrorSub?.cancel();
      _winLoadingSub = _winController!.loadingState.listen((state) {
        if (!mounted) return;
        if (state == win_wv.LoadingState.loading) {
          setState(() => _isLoading = true);
        } else if (state == win_wv.LoadingState.navigationCompleted) {
          // navigationCompleted may not guarantee meaningful paint; probe DOM
          Future.microtask(() async {
            try {
              // Try to query document.readyState and body length via ExecuteScript
              final ready = await _winController!.executeScript(
                'document.readyState',
              );
              final bodyLenRaw = await _winController!.executeScript(
                'document.body ? document.body.innerText.length : 0',
              );
              String readyStr = ready.toString().replaceAll('"', '');
              final len =
                  int.tryParse(
                    (bodyLenRaw ?? '0').toString().replaceAll('"', ''),
                  ) ??
                  0;
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _winReady = len > 0 && readyStr == 'complete';
                });
              }
              // Track consecutive blank observations and attempt recovery
              if (len == 0) {
                _winBlankCount++;
                // First, try a soft recovery by reloading
                if (_winBlankCount >= 2) {
                  try {
                    await _winController?.reload();
                  } catch (_) {}
                }
                // If reload didn't help after several tries, fully reinit the controller
                if (_winBlankCount >= 4) {
                  if (mounted) {
                    await _reinitWindowsWebView();
                  }
                  return;
                }

                // schedule a delayed re-check; if content appears, reset counter
                Future.delayed(const Duration(milliseconds: 400), () async {
                  try {
                    final len2 =
                        int.tryParse(
                          (await _winController!.executeScript(
                            'document.body ? document.body.innerText.length : 0',
                          )).toString().replaceAll('"', ''),
                        ) ??
                        0;
                    if (mounted) {
                      if (len2 > 0) {
                        _winBlankCount = 0;
                        setState(() => _winReady = true);
                      }
                    }
                  } catch (_) {}
                });
              } else {
                _winBlankCount = 0;
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _winReady =
                      true; // fallback to true to show view; user can reload if blank
                });
              }
            }
          });
        }
      });

      _winLoadErrorSub = _winController!.onLoadError.listen((err) {
        if (!mounted) return;
        // Mark not ready and allow user to reload
        setState(() {
          _isLoading = false;
          _winReady = false;
          _winError = true;
        });
      });

      await _winController!.loadUrl(widget.url);
      if (mounted) {
        setState(() {
          _winReady = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Failed to init
    }
  }

  Future<void> _reinitWindowsWebView() async {
    // Cancel subscriptions and dispose previous controller to avoid leaks
    try {
      await _winLoadingSub?.cancel();
    } catch (_) {}
    _winLoadingSub = null;
    try {
      await _winLoadErrorSub?.cancel();
    } catch (_) {}
    _winLoadErrorSub = null;

    try {
      await _winController?.dispose();
    } catch (_) {}
    _winController = win_wv.WebviewController();
    setState(() {
      _winReady = false;
      _isLoading = true;
      _winError = false;
      _winBlankCount = 0;
    });
    await _initWindowsWebView();
  }

  @override
  void dispose() {
    // Cancel subscriptions and dispose controller to avoid resource leaks
    try {
      _winLoadingSub?.cancel();
    } catch (_) {}
    _winLoadingSub = null;
    try {
      _winLoadErrorSub?.cancel();
    } catch (_) {}
    _winLoadErrorSub = null;
    try {
      _winController?.dispose();
    } catch (_) {}
    _winController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceManager>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Top action bar buttons
    Widget buildWebViewActions({
      required VoidCallback? onBack,
      required VoidCallback? onForward,
      required VoidCallback? onReload,
      bool canBack = true,
      bool canForward = true,
    }) {
      // Build draggable icons according to current order
      Widget buildAction(String key, int index) {
        Icon icon;
        String tooltip;
        VoidCallback? handler;
        bool enabled = true;

        switch (key) {
          case 'back':
            icon = Icon(
              Remix.arrow_left_s_line,
              color: canBack
                  ? colorScheme.secondary
                  : colorScheme.onSurface.withAlpha(
                      ((0.2).clamp(0.0, 1.0) * 255).round(),
                    ),
            );
            tooltip = l10n.back;
            handler = canBack ? onBack : null;
            enabled = canBack;
            break;
          case 'forward':
            icon = Icon(
              Remix.arrow_right_s_line,
              color: canForward
                  ? colorScheme.secondary
                  : colorScheme.onSurface.withAlpha(
                      ((0.2).clamp(0.0, 1.0) * 255).round(),
                    ),
            );
            tooltip = l10n.forward;
            handler = canForward ? onForward : null;
            enabled = canForward;
            break;
          case 'reload':
          default:
            icon = Icon(Remix.refresh_line, color: colorScheme.secondary);
            tooltip = l10n.refresh;
            handler = onReload;
            enabled = true;
            break;
        }

        // Return a simple IconButton for group-only dragging.
        return IconButton(
          icon: icon,
          tooltip: tooltip,
          onPressed: enabled ? handler : null,
        );
      }

      // The actions group widget (material container with icon buttons)
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
            children: List<Widget>.generate(
              _actionOrder.length,
              (i) => buildAction(_actionOrder[i], i),
            ),
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
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
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

      // Wrap in GestureDetector so the user can drag the whole group with mouse or touch.
      final draggable = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          // For platforms where long-press is required, enable drag only
          // while a long-press session is active. For desktop we allow
          // direct pan updates (mouse drag) via onPanUpdate.
          onPanStart: (details) {
            if (!_dragRequiresLongPress) {
              setState(() => _dragActive = true);
            }
          },
          onPanUpdate: (details) {
            if (_dragRequiresLongPress && !_dragActive) return;
            try {
              final box =
                  _webviewStackKey.currentContext?.findRenderObject()
                      as RenderBox?;
              if (box != null) {
                final local = box.globalToLocal(details.globalPosition);
                final actionBox =
                    _actionsKey.currentContext?.findRenderObject()
                        as RenderBox?;
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
                final dx = local.dx.clamp(0.0, maxX);
                final dy = local.dy.clamp(0.0, maxY);
                setState(() => _actionsOffset = Offset(dx, dy));
              }
            } catch (_) {}
          },
          onPanEnd: (details) {
            if (!_dragRequiresLongPress) {
              setState(() => _dragActive = false);
              _snapActionsToEdge();
            }
          },
          onLongPressStart: _dragRequiresLongPress
              ? (details) {
                  setState(() => _dragActive = true);
                  try {
                    final box =
                        _webviewStackKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (box != null) {
                      final local = box.globalToLocal(details.globalPosition);
                      final actionBox =
                          _actionsKey.currentContext?.findRenderObject()
                              as RenderBox?;
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
                      final dx = local.dx.clamp(0.0, maxX);
                      final dy = local.dy.clamp(0.0, maxY);
                      setState(() => _actionsOffset = Offset(dx, dy));
                    }
                  } catch (_) {}
                }
              : null,
          onLongPressMoveUpdate: _dragRequiresLongPress
              ? (details) {
                  try {
                    final box =
                        _webviewStackKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (box != null) {
                      final local = box.globalToLocal(details.globalPosition);
                      final actionBox =
                          _actionsKey.currentContext?.findRenderObject()
                              as RenderBox?;
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
                      final dx = local.dx.clamp(0.0, maxX);
                      final dy = local.dy.clamp(0.0, maxY);
                      setState(() => _actionsOffset = Offset(dx, dy));
                    }
                  } catch (_) {}
                }
              : null,
          onLongPressEnd: _dragRequiresLongPress
              ? (details) {
                  setState(() => _dragActive = false);
                  _snapActionsToEdge();
                }
              : null,
          child: actionsGroup,
        ),
      );

      // If offset is set, position absolutely; otherwise align top-right with margin.
      if (_actionsOffset != null) {
        return AnimatedPositioned(
          left: _actionsOffset!.dx,
          top: _actionsOffset!.dy,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: draggable,
        );
      }

      return Container(
        alignment: Alignment.topRight,
        margin: const EdgeInsets.only(top: 12, right: 12),
        child: draggable,
      );
    }

    if (service.status != ServiceStatus.running) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withAlpha(
                    ((0.05).clamp(0.0, 1.0) * 255).round(),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Remix.error_warning_line,
                  size: 64,
                  color: colorScheme.secondary.withAlpha(
                    ((0.5).clamp(0.0, 1.0) * 255).round(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.notStarted.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.startHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha(
                    ((0.6).clamp(0.0, 1.0) * 255).round(),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: widget.onGoToDashboard,
                  icon: const Icon(Remix.arrow_left_line),
                  label: Text(
                    l10n.goToDashboard.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If running but controller not initialized, initialization happens
    // from initState or service events — avoid calling init from build().

    // Windows: use webview_windows package
    if (Platform.isWindows) {
      return _winReady
          ? Stack(
              key: _webviewStackKey,
              children: [
                // WebView area
                MouseRegion(
                  onEnter: (_) {},
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent &&
                          _winController != null) {
                        final dy = event.scrollDelta.dy;
                        if (dy == 0.0) return;
                        if (!_winReady) return;
                        _pendingScrollDy += dy;
                        if (_scrollScheduled) return;
                        _scrollScheduled = true;
                        final px = event.position.dx;
                        final py = event.position.dy;
                        Future.delayed(
                          const Duration(milliseconds: 16),
                          () async {
                            final toSend = _pendingScrollDy;
                            _pendingScrollDy = 0.0;
                            _scrollScheduled = false;
                            try {
                              final js =
                                  "(function(){try{const delta=$toSend;const px=$px;const py=$py;const dpr=window.devicePixelRatio||1;const x=px/dpr;const y=py/dpr;let el=document.elementFromPoint(x,y)||document.scrollingElement||document.documentElement;function findScrollableAncestor(e){while(e){try{const s=getComputedStyle(e);if(e.scrollHeight>e.clientHeight&&(s.overflowY==='auto'||s.overflowY==='scroll'))return e}catch(_){ } e=e.parentElement;}return null;}const anc=findScrollableAncestor(el)||document.scrollingElement||document.documentElement;try{if(anc){try{anc.scrollTop+=delta;}catch(_){ }try{const ev=new WheelEvent('wheel',{deltaY:delta,clientX:Math.round(x),clientY:Math.round(y),bubbles:true,cancelable:true});anc.dispatchEvent(ev);}catch(_){ }return 'dispatched';}return 'no-ancestor';}catch(e){return 'err:'+e.toString();}}catch(e){return 'err:'+e.toString();}})();";
                              await _winController!.executeScript(js);
                            } catch (e) {
                              // ignore: avoid_print
                            }
                          },
                        );
                      }
                    },
                    onPointerDown: (event) {
                      // Block right-click context menu
                      if (event.kind == PointerDeviceKind.mouse &&
                          event.buttons == kSecondaryMouseButton) {
                        // do nothing, just block
                      }
                    },
                    child: win_wv.Webview(_winController!),
                  ),
                ),
                // Top action bar (Windows controller lacks canGoBack/canGoForward; call navigation methods directly)
                buildWebViewActions(
                  onBack: () {
                    _winController?.goBack();
                  },
                  onForward: () {
                    _winController?.goForward();
                  },
                  onReload: () => _winController?.reload(),
                  canBack: true,
                  canForward: true,
                ),
                // Error overlay
                if (_winError)
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
                                      onPressed: _reinitWindowsWebView,
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
            )
          : const Center(child: CircularProgressIndicator());
    }

    // macOS and Linux: embedded WebView not yet supported, open in external browser
    if (Platform.isMacOS || Platform.isLinux) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withAlpha(
                    ((0.05).clamp(0.0, 1.0) * 255).round(),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Remix.computer_line,
                  size: 64,
                  color: colorScheme.secondary.withAlpha(
                    ((0.5).clamp(0.0, 1.0) * 255).round(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'External Browser Required'.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Embedded WebView is not supported on ${Platform.isMacOS ? 'macOS' : 'Linux'} yet. Please use the external admin panel.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha(
                    ((0.6).clamp(0.0, 1.0) * 255).round(),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(widget.url)),
                  icon: const Icon(Remix.external_link_line),
                  label: Text(
                    'Open Admin Panel'.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onGoToDashboard,
                child: Text(l10n.goToDashboard),
              ),
            ],
          ),
        ),
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return Stack(
        key: _webviewStackKey,
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
            child: Listener(
              onPointerDown: (event) {
                if (event.kind == PointerDeviceKind.mouse &&
                    event.buttons == kSecondaryMouseButton) {
                  // Block right-click context menu
                }
              },
              child: _mobileController == null
                  ? Container(
                      color: Colors.grey[200],
                      width: double.infinity,
                      height: double.infinity,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.web, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Initializing WebView...'),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.expand(
                      child: WebViewWidget(controller: _mobileController!),
                    ),
            ),
          ),
          _isLoading
              ? Container(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  width: double.infinity,
                  height: double.infinity,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink(),
          // Top action bar
          buildWebViewActions(
            onBack: () async {
              if (_mobileController != null &&
                  await _mobileController!.canGoBack()) {
                _mobileController!.goBack();
              }
            },
            onForward: () async {
              if (_mobileController != null &&
                  await _mobileController!.canGoForward()) {
                _mobileController!.goForward();
              }
            },
            onReload: () => _mobileController?.reload(),
            canBack: true,
            canForward: true,
          ),
        ],
      );
    }

    return Center(child: Text('Platform not supported for embedded WebView'));
  }

  // Snap the actions group to the nearest edge of the webview stack.
  void _snapActionsToEdge() {
    if (_actionsOffset == null) return;
    try {
      final box =
          _webviewStackKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final w = box.size.width;
      final h = box.size.height;
      final actionBox =
          _actionsKey.currentContext?.findRenderObject() as RenderBox?;
      final actionW = actionBox?.size.width ?? 80.0;
      final actionH = actionBox?.size.height ?? 56.0;
      final maxX = (w - actionW).clamp(0.0, double.infinity);
      final maxY = (h - actionH).clamp(0.0, double.infinity);
      final dx = _actionsOffset!.dx.clamp(0.0, maxX);
      final dy = _actionsOffset!.dy.clamp(0.0, maxY);

      double leftDist = dx;
      double rightDist = (maxX - dx).abs();
      double topDist = dy;
      double bottomDist = (maxY - dy).abs();

      // Find minimum distance
      double minDist = leftDist;
      String edge = 'left';
      if (rightDist < minDist) {
        minDist = rightDist;
        edge = 'right';
      }
      if (topDist < minDist) {
        minDist = topDist;
        edge = 'top';
      }
      if (bottomDist < minDist) {
        minDist = bottomDist;
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
}
