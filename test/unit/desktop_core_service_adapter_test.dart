import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/native/desktop_core_service_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'desktop-core-adapter-test',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeExecutable(String name, String body) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString('#!/bin/sh\n$body\n');
    await Process.run('chmod', ['+x', file.path]);
    return file.path;
  }

  test(
    'getCoreVersion extracts the semantic version from bannered output',
    () async {
      if (Platform.isWindows) {
        return;
      }

      final corePath = await writeExecutable(
        'picoclaw',
        "printf '\\033[36mPicoClaw Banner\\033[0m\\n'\n"
            "printf 'version: 0.24.1-beta.2+build.7\\n'",
      );

      final adapter = DesktopCoreServiceAdapter(
        binaryName: 'picoclaw',
        port: 18800,
        configuredPath: corePath,
      );

      expect(await adapter.getCoreVersion(), '0.24.1-beta.2+build.7');
    },
  );

  test(
    'getCoreVersion resolves the core binary instead of a configured launcher',
    () async {
      if (Platform.isWindows) {
        return;
      }

      await writeExecutable('picoclaw', "printf '0.24.1\\n'");
      final launcherPath = await writeExecutable(
        'picoclaw-launcher',
        "printf 'launcher 9.9.9\\n'",
      );

      final adapter = DesktopCoreServiceAdapter(
        binaryName: 'picoclaw',
        port: 18800,
        configuredPath: launcherPath,
      );

      expect(await adapter.getCoreVersion(), '0.24.1');
    },
  );
}
