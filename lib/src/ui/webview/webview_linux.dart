import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewLinux extends StatelessWidget {
  final String url;
  final VoidCallback? onGoToDashboard;

  const WebViewLinux({super.key, required this.url, this.onGoToDashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
              'Embedded WebView is not supported on Linux yet. Please use the external admin panel.',
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
                onPressed: () => launchUrl(Uri.parse(url)),
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
              onPressed: onGoToDashboard,
              child: Text(l10n.goToDashboard),
            ),
          ],
        ),
      ),
    );
  }
}
