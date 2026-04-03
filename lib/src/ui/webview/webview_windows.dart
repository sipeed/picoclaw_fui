import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_windows/webview_windows.dart' as win_wv;
import 'dart:async';
import 'webview_nav_bar.dart';

class WebViewWindows extends StatefulWidget {
  final String url;
  final VoidCallback? onGoToDashboard;

  const WebViewWindows({super.key, required this.url, this.onGoToDashboard});

  @override
  State<WebViewWindows> createState() => _WebViewWindowsState();
}

class _WebViewWindowsState extends State<WebViewWindows> {
  win_wv.WebviewController? _controller;
  bool _winReady = false;
  bool _winError = false;
  int _winBlankCount = 0;
  StreamSubscription? _winLoadingSub;
  StreamSubscription? _winLoadErrorSub;

  double _pendingScrollDy = 0.0;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _initWebView(widget.url);
  }

  Future<void> _initWebView(String url) async {
    try {
      _controller ??= win_wv.WebviewController();
      await _controller!.initialize();
      await _controller!.setBackgroundColor(Colors.white);

      try {
        await _controller!.addScriptToExecuteOnDocumentCreated(
          "document.addEventListener('contextmenu', function(e){e.preventDefault();});",
        );
      } catch (_) {}

      _winLoadingSub?.cancel();
      _winLoadErrorSub?.cancel();
      _winLoadingSub = _controller!.loadingState.listen((state) {
        if (!mounted) return;
        if (state == win_wv.LoadingState.loading) {
          // loading started
        } else if (state == win_wv.LoadingState.navigationCompleted) {
          Future.microtask(() async {
            try {
              final ready = await _controller!.executeScript(
                'document.readyState',
              );
              final bodyLenRaw = await _controller!.executeScript(
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
                  _winReady = len > 0 && readyStr == 'complete';
                });
              }
              if (len == 0) {
                _winBlankCount++;
                if (_winBlankCount >= 2) {
                  try {
                    await _controller?.reload();
                  } catch (_) {}
                }
                if (_winBlankCount >= 4) {
                  if (mounted) await _reinitWebView();
                  return;
                }
                Future.delayed(const Duration(milliseconds: 400), () async {
                  try {
                    final len2 =
                        int.tryParse(
                          (await _controller!.executeScript(
                            'document.body ? document.body.innerText.length : 0',
                          )).toString().replaceAll('"', ''),
                        ) ??
                        0;
                    if (mounted && len2 > 0) {
                      _winBlankCount = 0;
                      setState(() => _winReady = true);
                    }
                  } catch (_) {}
                });
              } else {
                _winBlankCount = 0;
              }
            } catch (_) {
              if (mounted) {
                setState(() {
                  _winReady = true; // fallback; user can reload if blank
                });
              }
            }
          });
        }
      });

      _winLoadErrorSub = _controller!.onLoadError.listen((err) {
        if (!mounted) return;
        setState(() {
          _winReady = false;
          _winError = true;
        });
      });

      await _controller!.loadUrl(url);
      if (mounted) {
        setState(() {
          _winReady = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _reinitWebView() async {
    try {
      await _winLoadingSub?.cancel();
    } catch (_) {}
    _winLoadingSub = null;
    try {
      await _winLoadErrorSub?.cancel();
    } catch (_) {}
    _winLoadErrorSub = null;
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = win_wv.WebviewController();
    setState(() {
      _winReady = false;
      _winError = false;
      _winBlankCount = 0;
    });
    await _initWebView(widget.url);
  }

  @override
  void dispose() {
    try {
      _winLoadingSub?.cancel();
    } catch (_) {}
    _winLoadingSub = null;
    try {
      _winLoadErrorSub?.cancel();
    } catch (_) {}
    _winLoadErrorSub = null;
    try {
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_winReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        MouseRegion(
          onEnter: (_) {},
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent && _controller != null) {
                final dy = event.scrollDelta.dy;
                if (dy == 0.0 || !_winReady) return;
                _pendingScrollDy += dy;
                if (_scrollScheduled) return;
                _scrollScheduled = true;
                final px = event.position.dx;
                final py = event.position.dy;
                Future.delayed(const Duration(milliseconds: 16), () async {
                  final toSend = _pendingScrollDy;
                  _pendingScrollDy = 0.0;
                  _scrollScheduled = false;
                  try {
                    final js =
                        "(function(){try{const delta=$toSend;const px=$px;const py=$py;const dpr=window.devicePixelRatio||1;const x=px/dpr;const y=py/dpr;let el=document.elementFromPoint(x,y)||document.scrollingElement||document.documentElement;function findScrollableAncestor(e){while(e){try{const s=getComputedStyle(e);if(e.scrollHeight>e.clientHeight&&(s.overflowY==='auto'||s.overflowY==='scroll'))return e}catch(_){ } e=e.parentElement;}return null;}const anc=findScrollableAncestor(el)||document.scrollingElement||document.documentElement;try{if(anc){try{anc.scrollTop+=delta;}catch(_){ }try{const ev=new WheelEvent('wheel',{deltaY:delta,clientX:Math.round(x),clientY:Math.round(y),bubbles:true,cancelable:true});anc.dispatchEvent(ev);}catch(_){ }return 'dispatched';}return 'no-ancestor';}catch(e){return 'err:'+e.toString();}}catch(e){return 'err:'+e.toString();}})();";
                    await _controller!.executeScript(js);
                  } catch (_) {}
                });
              }
            },
            onPointerDown: (event) {
              if (event.kind == PointerDeviceKind.mouse &&
                  event.buttons == kSecondaryMouseButton) {
                // Block right-click context menu
              }
            },
            child: win_wv.Webview(_controller!),
          ),
        ),
        Positioned.fill(
          child: DraggableWebNavBar(
            onBack: () => _controller?.goBack(),
            onForward: () => _controller?.goForward(),
            onReload: () => _controller?.reload(),
          ),
        ),
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
                              onPressed: _reinitWebView,
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
