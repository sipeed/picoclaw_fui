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
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('opens and closes the about dialog from settings', (
    WidgetTester tester,
  ) async {
    await pumpConfigPage(tester);

    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About PicoClaw Flutter UI'), findsOneWidget);
    expect(
      find.text(
        'A cross-platform Flutter client for managing the PicoClaw service.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('About PicoClaw Flutter UI'), findsNothing);
  });

  testWidgets('shows project info and official links in the about dialog', (
    WidgetTester tester,
  ) async {
    await pumpConfigPage(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('PicoClaw Flutter UI'), findsOneWidget);
    expect(find.text('PicoClaw Official'), findsOneWidget);
    expect(find.text('Sipeed Official'), findsOneWidget);
  });

  testWidgets('launches both official links from the about dialog', (
    WidgetTester tester,
  ) async {
    final launchedUris = <Uri>[];

    await pumpConfigPage(
      tester,
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
      await pumpConfigPage(tester, launcher: (_) async => false);

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
