import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'core_service_adapter.dart';

final RegExp _ansiEscapePattern = RegExp(
  r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])',
);
final RegExp _semanticVersionPattern = RegExp(
  r'(?<!\d)v?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)(?!\d)',
);

class DesktopCoreServiceAdapter implements CoreServiceAdapter {
  final String binaryName;
  final int port;
  Process? _proc;
  String _lastLog = '';
  final String? configuredPath;
  void Function(String)? _logHandler;

  DesktopCoreServiceAdapter({
    required this.binaryName,
    required this.port,
    this.configuredPath,
  });
  String? _lastErrorCode;

  bool _isLauncherPath(String path) {
    final baseName = p.basename(path).toLowerCase();
    return baseName == 'picoclaw-launcher' ||
        baseName == 'picoclaw-launcher.exe';
  }

  String? _extractSemanticVersion(String output) {
    final sanitized = output
        .replaceAll('\r', '')
        .replaceAll(_ansiEscapePattern, '');
    for (final line in sanitized.split('\n')) {
      if (!line.toLowerCase().contains('version')) continue;
      final match = _semanticVersionPattern.firstMatch(line);
      if (match != null) return match.group(1);
    }
    return _semanticVersionPattern.firstMatch(sanitized)?.group(1);
  }

  Future<String?> _resolveFromDirectory(
    String dir, {
    required bool preferLauncher,
  }) async {
    if (preferLauncher) {
      final launcherCandidates = [
        p.join(dir, 'picoclaw-launcher'),
        p.join(dir, 'picoclaw-launcher.exe'),
      ];
      for (final cand in launcherCandidates) {
        if (await File(cand).exists()) return cand;
      }
    }

    final vfile = File(p.join(dir, 'version.txt'));
    if (await vfile.exists()) {
      final lines = await vfile.readAsLines();
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;
        final name = parts[0];
        if (name == binaryName) {
          final cand = p.join(dir, name);
          if (await File(cand).exists()) return cand;
        }
      }
      final platformToken = Platform.isWindows
          ? 'windows'
          : Platform.isMacOS
          ? 'macos'
          : 'linux';
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;
        final name = parts[0].toLowerCase();
        if (name.contains(platformToken)) {
          final cand = p.join(dir, parts[0]);
          if (await File(cand).exists()) return cand;
        }
      }
    }

    final direct = p.join(dir, binaryName);
    if (await File(direct).exists()) return direct;

    return null;
  }

  Future<String?> _resolveConfiguredPath({required bool preferLauncher}) async {
    if (configuredPath == null || configuredPath!.isEmpty) {
      return null;
    }

    final configuredFile = File(configuredPath!);
    if (!await configuredFile.exists()) {
      return null;
    }

    if (preferLauncher || !_isLauncherPath(configuredFile.path)) {
      return configuredFile.path;
    }

    return _resolveFromDirectory(
      configuredFile.parent.path,
      preferLauncher: false,
    );
  }

  Future<String?> _resolveCoreExePath() async {
    final configured = await _resolveConfiguredPath(preferLauncher: false);
    if (configured != null) return configured;

    final binDir = p.join(Directory.current.path, 'app', 'bin');
    final fromBinDir = await _resolveFromDirectory(
      binDir,
      preferLauncher: false,
    );
    if (fromBinDir != null) return fromBinDir;

    final repoRoot = await _findRepoRoot();
    if (repoRoot != null) {
      final fromRepoBin = await _resolveFromDirectory(
        p.join(repoRoot, 'app', 'bin'),
        preferLauncher: false,
      );
      if (fromRepoBin != null) return fromRepoBin;
    }

    final exeDir = p.dirname(Platform.resolvedExecutable);
    final fromExeDir = await _resolveFromDirectory(
      exeDir,
      preferLauncher: false,
    );
    if (fromExeDir != null) return fromExeDir;

    final fromNestedExeDir = await _resolveFromDirectory(
      p.join(exeDir, 'bin'),
      preferLauncher: false,
    );
    if (fromNestedExeDir != null) return fromNestedExeDir;

    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final dir in pathEnv.split(Platform.isWindows ? ';' : ':')) {
      final resolved = await _resolveFromDirectory(dir, preferLauncher: false);
      if (resolved != null) return resolved;
    }

    return null;
  }

  Future<String?> _findRepoRoot() async {
    try {
      var dir = Directory.current;
      while (true) {
        final pub = File(p.join(dir.path, 'pubspec.yaml'));
        if (await pub.exists()) return dir.path;
        if (dir.parent.path == dir.path) break;
        dir = dir.parent;
      }
    } catch (_) {}

    try {
      var dir = Directory(p.dirname(Platform.resolvedExecutable));
      while (true) {
        final pub = File(p.join(dir.path, 'pubspec.yaml'));
        if (await pub.exists()) return dir.path;
        if (dir.parent.path == dir.path) break;
        dir = dir.parent;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveExePath() async {
    final configured = await _resolveConfiguredPath(preferLauncher: true);
    if (configured != null) return configured;

    final binDir = p.join(Directory.current.path, 'app', 'bin');
    final fromBinDir = await _resolveFromDirectory(
      binDir,
      preferLauncher: true,
    );
    if (fromBinDir != null) return fromBinDir;

    final repoRoot = await _findRepoRoot();
    if (repoRoot != null) {
      final fromRepoBin = await _resolveFromDirectory(
        p.join(repoRoot, 'app', 'bin'),
        preferLauncher: true,
      );
      if (fromRepoBin != null) return fromRepoBin;
    }

    final exeDir = p.dirname(Platform.resolvedExecutable);
    final fromExeDir = await _resolveFromDirectory(
      exeDir,
      preferLauncher: true,
    );
    if (fromExeDir != null) return fromExeDir;

    final fromNestedExeDir = await _resolveFromDirectory(
      p.join(exeDir, 'bin'),
      preferLauncher: true,
    );
    if (fromNestedExeDir != null) return fromNestedExeDir;

    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final dir in pathEnv.split(Platform.isWindows ? ';' : ':')) {
      final resolved = await _resolveFromDirectory(dir, preferLauncher: true);
      if (resolved != null) return resolved;
    }
    return null;
  }

  Future<void> _preCleanup(int port) async {
    if (Platform.isWindows) {
      try {
        final result = await Process.run('cmd', [
          '/c',
          'netstat -ano | findstr :$port',
        ]);
        if (result.stdout.toString().isNotEmpty) {
          final lines = result.stdout.toString().split('\n');
          for (var line in lines) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 5) {
              final pid = parts.last;
              await Process.run('taskkill', ['/F', '/PID', pid]);
            }
          }
        }
      } catch (_) {}
    } else if (Platform.isMacOS) {
      // On macOS, use lsof to find and kill any process on the port.
      // BSD xargs does not support -r; empty input causes kill to print usage
      // but exits 1, which is silently ignored by the outer catch.
      try {
        await Process.run('sh', ['-c', "lsof -ti tcp:$port | xargs kill -9"]);
      } catch (_) {}
    } else if (Platform.isLinux) {
      // On Linux we attempt to kill any process listening on the port using lsof if available
      try {
        await Process.run('sh', [
          '-c',
          "lsof -ti tcp:$port | xargs -r kill -9",
        ]);
      } catch (_) {}
    }
  }

  Future<void> _pipe(Process proc) async {
    proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
      l,
    ) {
      _appendLog(l);
    });
    proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
      l,
    ) {
      _appendLog('ERR: $l');
    });
    proc.exitCode.then((c) {
      _appendLog('Exit:$c');
      _proc = null;
    });
  }

  void _appendLog(String line) {
    if (line.isEmpty) return;
    _lastLog = ('$_lastLog\n$line').trim();
    if (_lastLog.length > 200 * 1024) {
      _lastLog = _lastLog.substring(_lastLog.length - 200 * 1024);
    }
    // Forward to registered handler for real-time UI updates
    try {
      _logHandler?.call(line);
    } catch (_) {}
  }

  @override
  Future<bool> startService({int? port, String? args}) async {
    if (_proc != null) return true;
    final usedPort = port ?? this.port;
    await _preCleanup(usedPort);

    final exe = await _resolveExePath();
    if (exe == null) {
      _lastErrorCode = 'core.binary_missing';
      _appendLog(
        'Core binary not found. Place the platform binary into app/bin/ and ensure app/bin/version.txt lists it, or set the binary path in settings.',
      );
      return false;
    }
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['+x', exe]);
      } catch (_) {}
    }

    final argsList = <String>[];
    argsList.addAll(['-port', (usedPort).toString()]);
    if (args != null && args.isNotEmpty) {
      argsList.addAll(args.split(' ').where((s) => s.isNotEmpty));
    }
    _appendLog('Starting with args: $argsList');

    try {
      // Use normal start mode so we can read stdout/stderr and observe exitCode.
      // detachedWithStdio can make `exitCode` unavailable and causes
      // `Bad state: Process is detached` when accessing it.
      _proc = await Process.start(exe, argsList);
      _pipe(_proc!);
      _appendLog('Service started (pid=${_proc!.pid})');

      // Short-window confirmation: wait briefly to detect immediate exits.
      final startedOk = await Future.any([
        _proc!.exitCode.then((c) {
          _appendLog('Process exited early with code $c');
          _proc = null;
          _lastErrorCode = 'core.start_failed_immediate_exit';
          return false;
        }),
        Future.delayed(const Duration(milliseconds: 700), () => true),
      ]);

      if (!startedOk) {
        return false;
      }

      return true;
    } catch (e) {
      _lastErrorCode = 'core.start_failed';
      _appendLog('Failed to start service: $e');
      _proc = null;
      return false;
    }
  }

  @override
  Future<bool> stopService() async {
    if (_proc == null) return true;
    try {
      _proc!.kill(ProcessSignal.sigkill);
      _proc = null;
      _appendLog('Service stopped');
      return true;
    } catch (e) {
      _lastErrorCode = 'core.stop_failed';
      _appendLog('Failed to stop service: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'isRunning': _proc != null,
      'pid': _proc?.pid ?? -1,
      'lastLog': _lastLog,
    };
  }

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final uri = Uri.parse('http://127.0.0.1:$port/health');
      final client = HttpClient();
      final req = await client.getUrl(uri);
      final resp = await req.close().timeout(const Duration(seconds: 2));
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      final data = jsonDecode(body) as Map<String, dynamic>;
      return {
        'isHealthy': data['isHealthy'] ?? false,
        'uptime': data['uptime'] ?? '',
        'pid': data['pid'] ?? (_proc?.pid ?? -1),
        'error': data['error'] ?? '',
      };
    } catch (_) {
      return {
        'isHealthy': _proc != null,
        'uptime': '',
        'pid': _proc?.pid ?? -1,
        'error': 'health check failed',
      };
    }
  }

  @override
  Future<String> getCoreVersion() async {
    final exe = await _resolveCoreExePath();
    if (exe == null) return 'unknown';

    try {
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', exe]);
      }

      final result = await Process.run(exe, const ['version']);
      if (result.exitCode != 0) return 'unknown';

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return 'unknown';
      return _extractSemanticVersion(output) ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  @override
  Future<bool> setAutoStart(bool enabled) async => true;

  @override
  Future<bool> getAutoStart() async => false;

  @override
  String? getLastErrorCode() => _lastErrorCode;

  @override
  Future<bool> validateBinary([String? path]) async {
    try {
      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          final s = await f.length();
          if (s > 0) return true;
          _lastErrorCode = 'core.invalid_binary';
          return false;
        }
        _lastErrorCode = 'core.binary_missing';
        return false;
      }

      final exe = await _resolveExePath();
      if (exe == null) {
        _lastErrorCode = 'core.binary_missing';
        return false;
      }
      final f = File(exe);
      if (!await f.exists()) {
        _lastErrorCode = 'core.binary_missing';
        return false;
      }
      final s = await f.length();
      if (s == 0) {
        _lastErrorCode = 'core.invalid_binary';
        return false;
      }
      return true;
    } catch (e) {
      _lastErrorCode = 'core.invalid_binary';
      return false;
    }
  }

  @override
  void setLogHandler(void Function(String)? handler) {
    _logHandler = handler;
  }

  @override
  Future<String> getWorkspacePath() async => '';

  @override
  Future<bool> setWorkspacePath(String path) async => false;
}
