import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/core/background_service.dart';
import 'package:picoclaw_flutter_ui/src/core/app_theme.dart';
import 'package:picoclaw_flutter_ui/src/ui/dashboard_page.dart';
import 'package:picoclaw_flutter_ui/src/ui/config_page.dart';
import 'package:picoclaw_flutter_ui/src/ui/webview_page.dart';
import 'package:remixicon/remixicon.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'dart:io';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Single Instance Check (Windows only)
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "picoclaw_flutter_ui_instance_key",
      onSecondWindow: (newArgs) {
        windowManager.show();
        windowManager.focus();
      },
    );
  }

  // Initialize Window Manager
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    minimumSize: Size(850, 650),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

  if (Platform.isAndroid) {
    await initializeBackgroundService();
  }

  final service = ServiceManager();
  await service.init();
  
  runApp(
    ChangeNotifierProvider.value(
      value: service,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceManager>();
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PicoClaw',
      theme: AppTheme.getTheme(service.currentThemeMode),
      darkTheme: AppTheme.getTheme(service.currentThemeMode),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TrayListener, WindowListener {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    if (!Platform.isAndroid && !Platform.isIOS) {
       _initTray();
    }
  }

  Future<void> _initTray() async {
    // Standardizing on the provided .ico for Windows tray and process
    try {
      await trayManager.setIcon(
        Platform.isWindows ? 'assets/icon.ico' : 'assets/app_icon.png',
      );
    } catch (e) {
      debugPrint('Tray icon error: $e');
    }
    
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<ServiceManager>();
    
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: l10n.showWindow,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'start_service',
          label: l10n.run,
          disabled: service.status == ServiceStatus.running,
        ),
        MenuItem(
          key: 'stop_service',
          label: l10n.stop,
          disabled: service.status == ServiceStatus.stopped,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: l10n.exit,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    await trayManager.setToolTip(l10n.appTitle);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final service = context.read<ServiceManager>();
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'start_service') {
      service.start();
    } else if (menuItem.key == 'stop_service') {
      service.stop();
    } else if (menuItem.key == 'exit_app') {
      service.stop();
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-init tray when status changes to update menu (disabled states)
    context.watch<ServiceManager>();
    _initTray(); 
    
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Row(
        children: [
          if (isWide && !isPortrait)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              child: NavigationRail(
                extended: false, 
                minWidth: 104, // Slightly wider for better spacing
                backgroundColor: Colors.transparent, 
                indicatorColor: colorScheme.secondary.withOpacity(0.08), // Very subtle indicator
                indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), 
                unselectedIconTheme: IconThemeData(color: colorScheme.onSurface.withOpacity(0.4), size: 24),
                selectedIconTheme: IconThemeData(color: colorScheme.secondary, size: 24),
                unselectedLabelTextStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4), 
                  fontSize: 10, 
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                  height: 2.2,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: colorScheme.secondary, 
                  fontWeight: FontWeight.w700, 
                  fontSize: 10, 
                  letterSpacing: 1.2,
                  height: 2.2,
                ),
                labelType: NavigationRailLabelType.all,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                leading: const SizedBox(height: 48), 
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Remix.command_line), // More tech/minimal
                    selectedIcon: Icon(Remix.command_fill),
                    label: Text('DASHBOARD'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Remix.earth_line), // Clean world icon
                    selectedIcon: Icon(Remix.earth_fill),
                    label: Text('NETWORK'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Remix.equalizer_2_line), // More tech setting icon
                    selectedIcon: Icon(Remix.equalizer_2_fill),
                    label: Text('PRESETS'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageTransitionSwitcher(
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return SharedAxisTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.vertical,
                  child: child,
                );
              },
              child: IndexedStack(
                key: ValueKey<int>(_selectedIndex),
                index: _selectedIndex,
                children: [
                  const DashboardPage(),
                  Consumer<ServiceManager>(
                    builder: (context, service, _) => WebViewPage(
                      url: service.webUrl,
                      onGoToDashboard: () => setState(() => _selectedIndex = 0),
                    ),
                  ),
                  const ConfigPage(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isWide || isPortrait)
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Status'),
                NavigationDestination(icon: Icon(Icons.language), label: 'Web'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            )
          : null,
    );
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }
}

