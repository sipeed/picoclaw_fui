import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'webview_nav_bar.dart';

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
            if (mounted) {
              setState(() {
                _isReady = true;
                _isError = false;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _isReady = true;
                _isError = true;
              });
            }
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      );
    _controller!.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SizedBox.expand(child: WebViewWidget(controller: _controller!)),
        Positioned.fill(
          child: DraggableWebNavBar(
            onBack: () => _controller?.goBack(),
            onForward: () => _controller?.goForward(),
            onReload: () => _controller?.reload(),
          ),
        ),
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
