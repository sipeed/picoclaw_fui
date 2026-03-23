import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceManager>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Let themed scaffoldBackground show through
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Text(
              l10n.run.toUpperCase(),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              _buildStatusIndicator(context, service.status),
              const SizedBox(width: 24),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // High-Impact Control Center
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: service.status == ServiceStatus.running
                              ? colorScheme.error.withAlpha(
                                  ((0.08).clamp(0.0, 1.0) * 255).round(),
                                )
                              : colorScheme.secondary.withAlpha(
                                  ((0.12).clamp(0.0, 1.0) * 255).round(),
                                ),
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: service.status == ServiceStatus.running
                                ? service.stop
                                : service.start,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 32,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: service.status == ServiceStatus.running
                                      ? colorScheme.error.withAlpha(
                                          ((0.2).clamp(0.0, 1.0) * 255).round(),
                                        )
                                      : colorScheme.secondary.withAlpha(
                                          ((0.3).clamp(0.0, 1.0) * 255).round(),
                                        ),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    service.status == ServiceStatus.running
                                        ? Remix.stop_circle_fill
                                        : Remix.play_circle_fill,
                                    size: 42,
                                    color:
                                        service.status == ServiceStatus.running
                                        ? colorScheme.error
                                        : colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 20),
                                  Flexible(
                                    child: Text(
                                      service.status == ServiceStatus.running
                                          ? 'STOP SERVICE'
                                          : 'LAUNCH SERVICE',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color:
                                            service.status ==
                                                ServiceStatus.running
                                            ? colorScheme.error
                                            : colorScheme.secondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Glassmorphism Status Card
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withAlpha(
                      ((0.4).clamp(0.0, 1.0) * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.onSurface.withAlpha(
                        ((0.08).clamp(0.0, 1.0) * 255).round(),
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Primary info
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withAlpha(
                                        ((0.1).clamp(0.0, 1.0) * 255).round(),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Remix.link_m,
                                      color: colorScheme.secondary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'ENDPOINT',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: colorScheme.onSurface.withAlpha(
                                          ((0.5).clamp(0.0, 1.0) * 255).round(),
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () =>
                                    launchUrl(Uri.parse(service.webUrl)),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    service.webUrl,
                                    style: GoogleFonts.firaCode(
                                      fontSize: 20,
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.webAdmin,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withAlpha(
                                    ((0.4).clamp(0.0, 1.0) * 255).round(),
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right side: QR Tile
                      Container(
                        width: 160,
                        height: 180, // Fixed height instead of stretching
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withAlpha(
                            ((0.03).clamp(0.0, 1.0) * 255).round(),
                          ),
                          border: Border(
                            left: BorderSide(
                              color: colorScheme.onSurface.withAlpha(
                                ((0.05).clamp(0.0, 1.0) * 255).round(),
                              ),
                            ),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    ((0.1).clamp(0.0, 1.0) * 255).round(),
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: service.webUrl,
                              version: QrVersions.auto,
                              size: 80.0,
                              gapless: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Logs Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.logs.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Divider(
                        color: colorScheme.onSurface.withAlpha(
                          ((0.1).clamp(0.0, 1.0) * 255).round(),
                        ),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${service.logs.length} EVENTS',
                      style: GoogleFonts.firaCode(
                        fontSize: 10,
                        color: colorScheme.onSurface.withAlpha(
                          ((0.4).clamp(0.0, 1.0) * 255).round(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 500, child: LogView()),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ServiceStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label;
    switch (status) {
      case ServiceStatus.running:
        color = const Color(0xFF10B981); // Modern Emerald
        label = 'ACTIVE';
        break;
      case ServiceStatus.starting:
        color = const Color(0xFFF59E0B); // Modern Amber
        label = 'SYNCING';
        break;
      case ServiceStatus.stopped:
        color = colorScheme.onSurface.withAlpha(
          ((0.3).clamp(0.0, 1.0) * 255).round(),
        );
        label = 'IDLE';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(((0.08).clamp(0.0, 1.0) * 255).round()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withAlpha(((0.2).clamp(0.0, 1.0) * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                if (status == ServiceStatus.running)
                  BoxShadow(
                    color: color.withAlpha(
                      ((0.6).clamp(0.0, 1.0) * 255).round(),
                    ),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        // If user scrolls up by more than 50px, disable auto-scroll
        if (position.pixels < position.maxScrollExtent - 50) {
          if (_shouldAutoScroll) setState(() => _shouldAutoScroll = false);
        } else {
          if (!_shouldAutoScroll) setState(() => _shouldAutoScroll = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_shouldAutoScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _handleDirectionalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtTop = position.pixels <= position.minScrollExtent;
    final isAtBottom = position.pixels >= position.maxScrollExtent;

    // When at top and press UP, or at bottom and press DOWN, unfocus to let parent handle it
    if ((event.logicalKey == LogicalKeyboardKey.arrowUp && isAtTop) ||
        (event.logicalKey == LogicalKeyboardKey.arrowDown && isAtBottom)) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.select<ServiceManager, List<String>>((s) => s.logs);
    final colorScheme = Theme.of(context).colorScheme;

    // Use jumpTo instead of animateTo for zero-cost positioning on every frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Focus(
        focusNode: _focusNode,
        autofocus: false,
        onKeyEvent: (node, event) {
          _handleDirectionalKey(event);
          return KeyEventResult.ignored; // Let parent handle navigation
        },
        child: SelectionArea(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: logs.length,
            addAutomaticKeepAlives:
                false, // Performance: don't keep off-screen items alive
            addRepaintBoundaries:
                true, // Performance: isolate each log entry repaint
            itemBuilder: (context, index) => RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  logs[index],
                  style: TextStyle(
                    fontFamily: GoogleFonts.firaCode().fontFamily,
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
