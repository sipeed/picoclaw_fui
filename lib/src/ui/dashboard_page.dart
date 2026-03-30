import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:picoclaw_flutter_ui/src/ui/widgets/tv_focusable.dart';
import 'umeng_test_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _deviceIp;

  @override
  void initState() {
    super.initState();
    _loadDeviceIp();
  }

  Future<void> _loadDeviceIp() async {
    final service = context.read<ServiceManager>();
    final ip = await service.getDeviceIpAddress();
    if (mounted) {
      setState(() => _deviceIp = ip);
    }
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当公共模式从关闭变为开启时，重新获取IP
    final service = context.read<ServiceManager>();
    if (service.publicMode && _deviceIp == null) {
      _loadDeviceIp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceManager>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // 二维码数据：公共模式开启时使用设备IP，否则使用内部地址(webUrl)
    final qrData = (service.publicMode && _deviceIp != null)
        ? 'http://$_deviceIp:${service.webUrl.split(':').last}'
        : service.webUrl;

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
                        child: TVFocusable(
                          onTap: service.status == ServiceStatus.running
                              ? service.stop
                              : service.start,
                          borderRadius: BorderRadius.circular(24),
                          focusBorderColor:
                              service.status == ServiceStatus.running
                              ? colorScheme.error
                              : colorScheme.secondary,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 32,
                            ),
                            decoration: BoxDecoration(
                              color: service.status == ServiceStatus.running
                                  ? colorScheme.error.withAlpha(
                                      ((0.06).clamp(0.0, 1.0) * 255).round(),
                                    )
                                  : colorScheme.secondary.withAlpha(
                                      ((0.08).clamp(0.0, 1.0) * 255).round(),
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
                                  color: service.status == ServiceStatus.running
                                      ? colorScheme.error
                                      : colorScheme.secondary,
                                ),
                                const SizedBox(width: 20),
                                Flexible(
                                  child: Text(
                                    service.status == ServiceStatus.running
                                        ? l10n.stopService
                                        : l10n.launchService,
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
                    ],
                  ),
                ),
                // Glassmorphism Status Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 窄屏时垂直布局，宽屏时水平布局
                    final isNarrow = constraints.maxWidth < 600;

                    Widget infoSection = _buildInfoSection(
                      context,
                      service,
                      colorScheme,
                      l10n,
                    );

                    Widget qrSection = _buildQrSection(
                      context,
                      qrData,
                      colorScheme,
                    );

                    return Container(
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
                      child: isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                infoSection,
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: colorScheme.onSurface.withAlpha(
                                    ((0.05).clamp(0.0, 1.0) * 255).round(),
                                  ),
                                ),
                                Center(child: qrSection),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: infoSection),
                                Container(
                                  width: 1,
                                  height: 240,
                                  color: colorScheme.onSurface.withAlpha(
                                    ((0.05).clamp(0.0, 1.0) * 255).round(),
                                  ),
                                ),
                                qrSection,
                              ],
                            ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Hint at bottom center
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withAlpha(0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          service.publicMode
                              ? l10n.publicModeHint
                              : l10n.localModeHint,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withAlpha(
                              ((0.7).clamp(0.0, 1.0) * 255).round(),
                            ),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    ServiceManager service,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Padding(
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
                  l10n.endpoint,
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
          // 公共模式状态指示器
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                service.publicMode ? Icons.public : Icons.lock_outline,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  service.publicMode ? l10n.publicModeEnabled : l10n.localMode,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Endpoint 显示地址：公共模式开启时使用设备IP，否则使用内部地址
          Builder(
            builder: (context) {
              // 公共模式开启但无法获取IP时显示警告
              if (service.publicMode && _deviceIp == null) {
                return TVFocusable(
                  onTap: null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.webUrl,
                          style: GoogleFonts.firaCode(
                            fontSize: 20,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.unableToGetDeviceIp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.error,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
              final displayUrl = (service.publicMode && _deviceIp != null)
                  ? 'http://$_deviceIp:${service.webUrl.split(':').last}'
                  : service.webUrl;
              return TVFocusable(
                onTap: () => launchUrl(Uri.parse(displayUrl)),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    displayUrl,
                    style: GoogleFonts.firaCode(
                      fontSize: 20,
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
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
          const SizedBox(height: 24),
          // 临时测试按钮 - 友盟测试
          TVFocusable(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UmengTestPage()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.error.withAlpha(
                  ((0.1).clamp(0.0, 1.0) * 255).round(),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withAlpha(
                    ((0.3).clamp(0.0, 1.0) * 255).round(),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Remix.bug_line, size: 18, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    '友盟上报测试',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(
    BuildContext context,
    String qrData,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 200,
      height: 240,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withAlpha(
          ((0.03).clamp(0.0, 1.0) * 255).round(),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            data: qrData,
            version: QrVersions.auto,
            size: 140.0,
            gapless: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ServiceStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;
    switch (status) {
      case ServiceStatus.running:
        color = const Color(0xFF10B981); // Modern Emerald
        label = l10n.statusActive;
        break;
      case ServiceStatus.starting:
        color = const Color(0xFFF59E0B); // Modern Amber
        label = l10n.statusSyncing;
        break;
      case ServiceStatus.stopped:
        color = colorScheme.onSurface.withAlpha(
          ((0.3).clamp(0.0, 1.0) * 255).round(),
        );
        label = l10n.statusIdle;
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
