import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:picoclaw_flutter_ui/src/ui/config_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpConfigPage(
    WidgetTester tester, {
    ExternalUrlLauncher? launcher,
    Future<AboutInfo> Function()? aboutInfoLoader,
    bool settle = true,
  }) async {
    final service = ServiceManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<ServiceManager>.value(
        value: service,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ConfigPage(
              externalUrlLauncher: launcher ?? ((_) async => true),
              aboutInfoLoader: aboutInfoLoader,
            ),
          ),
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('opens and closes the about dialog from settings', (
    WidgetTester tester,
  ) async {
    await pumpConfigPage(
      tester,
      aboutInfoLoader: () async =>
          const AboutInfo(appVersion: '1.0.0', coreVersion: 'core-1.0.0'),
    );

    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsWidgets);
    expect(
      find.text(
        'PicoClaw is a cross-platform Flutter app for managing the PicoClaw service.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('PicoClaw'), findsNothing);
  });

  testWidgets('shows PicoClaw branding and both version rows', (
    WidgetTester tester,
  ) async {
    await pumpConfigPage(
      tester,
      aboutInfoLoader: () async =>
          const AboutInfo(appVersion: '1.2.3', coreVersion: 'core-9.8.7'),
    );

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsWidgets);
    expect(find.text('PicoClaw'), findsOneWidget);
    expect(find.text('PicoClaw Flutter UI'), findsNothing);
    expect(find.text('PicoClaw version'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('PicoClaw Core version'), findsOneWidget);
    expect(find.text('core-9.8.7'), findsOneWidget);
    expect(find.text('PicoClaw Official'), findsOneWidget);
    expect(find.text('Sipeed Official'), findsOneWidget);
  });

  testWidgets('shows loading indicator while about info is still loading', (
    WidgetTester tester,
  ) async {
    final aboutInfoCompleter = Completer<AboutInfo>();

    await pumpConfigPage(
      tester,
      aboutInfoLoader: () => aboutInfoCompleter.future,
      settle: false,
    );

    await tester.tap(find.text('About'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('PicoClaw version'), findsNothing);
    expect(find.text('PicoClaw Core version'), findsNothing);

    aboutInfoCompleter.complete(
      const AboutInfo(appVersion: '1.0.0', coreVersion: 'core-1.0.0'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('PicoClaw version'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('PicoClaw Core version'), findsOneWidget);
    expect(find.text('core-1.0.0'), findsOneWidget);
  });

  testWidgets('shows localized fallback text when a version is unavailable', (
    WidgetTester tester,
  ) async {
    await pumpConfigPage(
      tester,
      aboutInfoLoader: () async => const AboutInfo(
        appVersion: '',
        coreVersion: 'unknown',
      ),
    );

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(AlertDialog)))!;
    expect(find.text(l10n.aboutVersionUnavailable), findsNWidgets(2));
  });

  testWidgets('uses production about loader when no override is provided', (
    WidgetTester tester,
  ) async {
    await pumpConfigPage(tester);

    await tester.tap(find.text('About'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('launches both official links from the about dialog', (
    WidgetTester tester,
  ) async {
    final launchedUris = <Uri>[];

    await pumpConfigPage(
      tester,
      aboutInfoLoader: () async =>
          const AboutInfo(appVersion: '1.0.0', coreVersion: 'core-1.0.0'),
      launcher: (uri) async {
        launchedUris.add(uri);
        return true;
      },
    );

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PicoClaw Official'));
    await tester.pump();
    await tester.tap(find.text('Sipeed Official'));
    await tester.pump();

    expect(
      launchedUris,
      containsAll(<Uri>[
        Uri.parse('https://picoclaw.io'),
        Uri.parse('https://sipeed.com'),
      ]),
    );
  });

  testWidgets(
    'shows feedback and keeps the dialog open when link launch fails',
    (WidgetTester tester) async {
      await pumpConfigPage(
        tester,
        aboutInfoLoader: () async =>
            const AboutInfo(appVersion: '1.0.0', coreVersion: 'core-1.0.0'),
        launcher: (_) async => false,
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PicoClaw Official'));
      await tester.pump();

      expect(find.text("Couldn't open the official link."), findsOneWidget);
      expect(find.text('Sipeed Official'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    },
  );
}
