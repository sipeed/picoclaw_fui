import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/ui/widgets/adaptive_action_bar.dart';

void main() {
  testWidgets('uses bottom actions when narrow', (WidgetTester tester) async {
    final widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: AdaptiveActionBar(
          content: const SizedBox.expand(),
          actions: const [
            Icon(Icons.audiotrack),
            Icon(Icons.bolt),
            Icon(Icons.cake),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Expect bottom Row present by finding Row with Icon children
    expect(find.byType(Row), findsWidgets);
    expect(find.byIcon(Icons.audiotrack), findsOneWidget);
  });

  testWidgets('uses side actions when wide', (WidgetTester tester) async {
    final widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: AdaptiveActionBar(
          content: const SizedBox.expand(),
          actions: const [
            Icon(Icons.audiotrack),
            Icon(Icons.bolt),
            Icon(Icons.cake),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Expect Column present for the side actions
    expect(find.byType(Column), findsWidgets);
    expect(find.byIcon(Icons.cake), findsOneWidget);
  });
}
