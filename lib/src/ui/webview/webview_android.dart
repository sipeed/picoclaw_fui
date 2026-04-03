import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'webview_nav_bar.dart';

class WebViewAndroid extends StatefulWidget {
  final String url;

  const WebViewAndroid({super.key, required this.url});

  @override
  State<WebViewAndroid> createState() => _WebViewAndroidState();
}

class _WebViewAndroidState extends State<WebViewAndroid> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onProgress: (progress) {
            if (progress < 100 && mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
          onUrlChange: (_) {
            if (mounted && _isLoading) setState(() => _isLoading = false);
          },
        ),
      );
    _controller!.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: _controller == null
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
                    child: WebViewWidget(controller: _controller!),
                  ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            width: double.infinity,
            height: double.infinity,
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned.fill(
          child: DraggableWebNavBar(
            onBack: () => _controller?.goBack(),
            onForward: () => _controller?.goForward(),
            onReload: () => _controller?.reload(),
          ),
        ),
      ],
    );
  }
}
