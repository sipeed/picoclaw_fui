import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_wv;
import 'dart:io';

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
  

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final service = context.read<ServiceManager>();
    if (service.status == ServiceStatus.running) {
      _initControllers();
    }
  }

  void _initControllers() {
    if (Platform.isAndroid || Platform.isIOS) {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } else if (Platform.isWindows) {
      _initWindowsWebView();
    }
  }

  Future<void> _initWindowsWebView() async {
    try {
      _winController ??= win_wv.WebviewController();
      await _winController!.initialize();
      // Ensure it's focused on load
      await _winController!.setBackgroundColor(Colors.transparent);

      // Disable context menu via script for consistent UX
      try {
        await _winController!.addScriptToExecuteOnDocumentCreated(
          "document.addEventListener('contextmenu', function(e){e.preventDefault();});",
        );
      } catch (_) {}

      // Listen for loading state and errors to detect blank/frozen views
      _winController!.loadingState.listen((state) {
        if (!mounted) return;
        if (state == win_wv.LoadingState.loading) {
          setState(() => _isLoading = true);
        } else if (state == win_wv.LoadingState.navigationCompleted) {
          setState(() {
            _isLoading = false;
            _winReady = true;
          });
        }
      });

      _winController!.onLoadError.listen((err) {
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
    try {
      await _winController?.dispose();
    } catch (_) {}
    _winController = win_wv.WebviewController();
    setState(() {
      _winReady = false;
      _isLoading = true;
      _winError = false;
    });
    await _initWindowsWebView();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceManager>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // 顶部操作栏按钮
    Widget buildWebViewActions({
      required VoidCallback? onBack,
      required VoidCallback? onForward,
      required VoidCallback? onReload,
      bool canBack = true,
      bool canForward = true,
    }) {
      return Container(
        alignment: Alignment.topRight,
        margin: const EdgeInsets.only(top: 12, right: 12),
        child: Material(
          color: colorScheme.surface.withAlpha(((0.7).clamp(0.0, 1.0) * 255).round()),
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Remix.arrow_left_s_line,
                  color: canBack
                      ? colorScheme.secondary
                      : colorScheme.onSurface.withAlpha(((0.2).clamp(0.0, 1.0) * 255).round()),
                ),
                tooltip: l10n.goToDashboard,
                onPressed: canBack ? onBack : null,
              ),
              IconButton(
                icon: Icon(
                  Remix.arrow_right_s_line,
                  color: canForward
                      ? colorScheme.secondary
                      : colorScheme.onSurface.withAlpha(((0.2).clamp(0.0, 1.0) * 255).round()),
                ),
                tooltip: l10n.goToDashboard,
                onPressed: canForward ? onForward : null,
              ),
              IconButton(
                icon: Icon(Remix.refresh_line, color: colorScheme.secondary),
                tooltip: 'Refresh',
                onPressed: onReload,
              ),
            ],
          ),
        ),
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
                  color: colorScheme.secondary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Remix.error_warning_line,
                  size: 64,
                  color: colorScheme.secondary.withOpacity(0.5),
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
                  color: colorScheme.onSurface.withOpacity(0.6),
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

    // If running but controller not initialized (e.g. just started)
    if (Platform.isWindows && !_winReady && _isLoading) {
      _initWindowsWebView();
    }

    if (Platform.isWindows) {
      return _winReady
          ? Stack(
              children: [
                // WebView 区域
                MouseRegion(
                  onEnter: (_) {},
                  child: Listener(
                    onPointerSignal: (event) {},
                    onPointerDown: (event) {
                      // 屏蔽右键菜单
                      if (event.kind == PointerDeviceKind.mouse &&
                          event.buttons == kSecondaryMouseButton) {
                        // do nothing, just block
                      }
                    },
                    child: win_wv.Webview(_winController!),
                  ),
                ),
                // 顶部操作栏 (Windows 控制器没有 canGoBack/canGoForward 接口，直接调用导航方法)
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
                      color: Colors.black.withAlpha(((0.45).clamp(0.0, 1.0) * 255).round()),
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
                                      child: const Text('Back'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.surfaceVariant,
                                        foregroundColor: colorScheme.onSurface,
                                      ),
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

    if (Platform.isAndroid || Platform.isIOS) {
      return Stack(
        children: [
          Listener(
            onPointerDown: (event) {
              if (event.kind == PointerDeviceKind.mouse &&
                  event.buttons == kSecondaryMouseButton) {
                // 屏蔽右键菜单
              }
            },
            child: _mobileController == null
                ? const SizedBox()
                : WebViewWidget(controller: _mobileController!),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          // 顶部操作栏
          buildWebViewActions(
            onBack: () async {
              if (_mobileController != null &&
                  await _mobileController!.canGoBack())
                _mobileController!.goBack();
            },
            onForward: () async {
              if (_mobileController != null &&
                  await _mobileController!.canGoForward())
                _mobileController!.goForward();
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
}
