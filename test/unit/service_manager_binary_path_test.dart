import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServiceManager service;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ServiceManager();
    tempDir = await Directory.systemTemp.createTemp(
      'service-manager-binary-path-test',
    );
  });

  tearDown(() async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      await service.updateConfig(
        '127.0.0.1',
        18800,
        binaryPath: '',
        arguments: '',
        publicMode: false,
      );
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeExecutable(String name, String version) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(
      '#!/bin/sh\n'
      "printf 'version: $version\\n'\n",
    );
    await Process.run('chmod', ['+x', file.path]);
    return file.path;
  }

  test('getCoreVersion uses the configured desktop binary path', () async {
    if (Platform.isWindows || Platform.isAndroid) {
      return;
    }

    final firstCorePath = await writeExecutable('picoclaw-first', '1.2.3');
    final secondCorePath = await writeExecutable('picoclaw-second', '2.0.0');

    await service.updateConfig(
      '127.0.0.1',
      18800,
      binaryPath: firstCorePath,
      arguments: '',
      publicMode: false,
    );
    expect(await service.getCoreVersion(), '1.2.3');

    await service.updateConfig(
      '127.0.0.1',
      18800,
      binaryPath: secondCorePath,
      arguments: '',
      publicMode: false,
    );
    expect(await service.getCoreVersion(), '2.0.0');
  });
}
