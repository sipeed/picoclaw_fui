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
  late final WebViewController? _mobileController;
  
  // Windows specific
  final _winController = win_wv.WebviewController();
  bool _winReady = false;

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
      await _winController.initialize();
      // Ensure it's focused on load
      await _winController.setBackgroundColor(Colors.transparent);
      await _winController.loadUrl(widget.url);
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

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceManager>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          ? MouseRegion(
              onEnter: (_) {
                 // Try to focus WebView when mouse enters
              },
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    // Manual focus trigger or event forwarding if needed
                  }
                },
                child: win_wv.Webview(_winController),
              ),
            )
          : const Center(child: CircularProgressIndicator());
    }

    if (Platform.isAndroid || Platform.isIOS) {
       return Stack(
        children: [
          WebViewWidget(controller: _mobileController!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return Center(child: Text('Platform not supported for embedded WebView'));
  }
}
