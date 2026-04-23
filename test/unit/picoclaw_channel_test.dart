import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/core/picoclaw_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.sipeed.picoclaw/picoclaw');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getCoreVersion returns the native version string', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getCoreVersion') return '0.24.1';
          return null;
        });

    expect(await PicoClawChannel.getCoreVersion(), '0.24.1');
  });

  test('getCoreVersion falls back to unknown on native failure', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'ERR', message: 'boom');
        });

    expect(await PicoClawChannel.getCoreVersion(), 'unknown');
  });
}
