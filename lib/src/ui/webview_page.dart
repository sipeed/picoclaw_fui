import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:picoclaw_flutter_ui/src/ui/webview/webview_android.dart';
import 'package:picoclaw_flutter_ui/src/ui/webview/webview_linux.dart';
import 'package:picoclaw_flutter_ui/src/ui/webview/webview_macos.dart';
import 'package:picoclaw_flutter_ui/src/ui/webview/webview_windows.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'dart:io';

class WebViewPage extends StatefulWidget {
  final String url;
  final VoidCallback? onGoToDashboard;
  const WebViewPage({super.key, required this.url, this.onGoToDashboard});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

// Provide a lightweight getter on the widget to expose a webview-friendly URL.
// This avoids adding widget parameters while keeping the logic local to UI code.
extension WebViewPageWebviewUrl on WebViewPage {
  String get webviewUrl {
    try {
      final u = Uri.parse(url);
      if (u.host == '0.0.0.0') return u.replace(host: '127.0.0.1').toString();
    } catch (_) {}
    return url;
  }
}

class _WebViewPageState extends State<WebViewPage> {
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

    if (Platform.isWindows) {
      return WebViewWindows(
        url: widget.webviewUrl,
        onGoToDashboard: widget.onGoToDashboard,
      );
    }

    if (Platform.isMacOS) {
      return WebViewMacOS(
        url: widget.webviewUrl,
        onGoToDashboard: widget.onGoToDashboard,
      );
    }

    if (Platform.isLinux) {
      return WebViewLinux(
        url: widget.webviewUrl,
        onGoToDashboard: widget.onGoToDashboard,
      );
    }

    if (Platform.isAndroid) {
      return WebViewAndroid(url: widget.webviewUrl);
    }

    return const Center(
      child: Text('Platform not supported for embedded WebView'),
    );
  }
}
