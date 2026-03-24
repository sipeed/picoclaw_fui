import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'core_service_adapter.dart';

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

  Future<String?> _resolveExePath() async {
    if (configuredPath != null && configuredPath!.isNotEmpty) {
      final f = File(configuredPath!);
      if (await f.exists()) return f.path;
    }
    final binDir = p.join(Directory.current.path, 'app', 'bin');
    // Prefer the launcher binary when present (picoclaw-launcher / picoclaw-launcher.exe)
    final launcherCandidates = [
      p.join(binDir, 'picoclaw-launcher'),
      p.join(binDir, 'picoclaw-launcher.exe'),
    ];
    for (final cand in launcherCandidates) {
      if (await File(cand).exists()) return cand;
    }
    final vfile = File(p.join(binDir, 'version.txt'));
    if (await vfile.exists()) {
      for (final line in await vfile.readAsLines()) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;
        final name = parts[0];
        if (name == binaryName) {
          final cand = p.join(binDir, name);
          if (await File(cand).exists()) return cand;
        }
      }
      final platformToken = Platform.isWindows
          ? 'windows'
          : Platform.isMacOS
          ? 'macos'
          : 'linux';
      for (final line in await vfile.readAsLines()) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;
        final name = parts[0].toLowerCase();
        if (name.contains(platformToken)) {
          final cand = p.join(binDir, parts[0]);
          if (await File(cand).exists()) return cand;
        }
      }
    }
    // If not found relative to the current working directory, attempt to locate
    // the repository root (by looking for `pubspec.yaml`) and check its `app/bin`.
    Future<String?> findRepoRoot() async {
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
    final repoRoot = await findRepoRoot();
    if (repoRoot != null) {
      final altBin = p.join(repoRoot, 'app', 'bin');
      final altV = File(p.join(altBin, 'version.txt'));
      if (await altV.exists()) {
        for (final line in await altV.readAsLines()) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.isEmpty) continue;
          final name = parts[0];
          if (name == binaryName) {
            final cand = p.join(altBin, name);
            if (await File(cand).exists()) return cand;
          }
        }
        final platformToken = Platform.isWindows
            ? 'windows'
            : Platform.isMacOS
            ? 'macos'
            : 'linux';
        for (final line in await altV.readAsLines()) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.isEmpty) continue;
          final name = parts[0].toLowerCase();
          if (name.contains(platformToken)) {
            final cand = p.join(altBin, parts[0]);
            if (await File(cand).exists()) return cand;
          }
        }
      }
      // Also prefer launcher in altBin
      final altLauncher1 = p.join(altBin, 'picoclaw-launcher');
      final altLauncher2 = p.join(altBin, 'picoclaw-launcher.exe');
      if (await File(altLauncher1).exists()) return altLauncher1;
      if (await File(altLauncher2).exists()) return altLauncher2;
      final direct = p.join(altBin, binaryName);
      if (await File(direct).exists()) return direct;
    }
    final exeDir = p.dirname(Platform.resolvedExecutable);
    // Check for launcher in exeDir first
    final cLauncher1 = p.join(exeDir, 'picoclaw-launcher');
    final cLauncher2 = p.join(exeDir, 'picoclaw-launcher.exe');
    if (await File(cLauncher1).exists()) return cLauncher1;
    if (await File(cLauncher2).exists()) return cLauncher2;
    final c1 = p.join(exeDir, binaryName);
    if (await File(c1).exists()) return c1;
    final c2 = p.join(exeDir, 'bin', binaryName);
    if (await File(c2).exists()) return c2;

    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final dir in pathEnv.split(Platform.isWindows ? ';' : ':')) {
      final pLauncher = p.join(
        dir,
        Platform.isWindows ? 'picoclaw-launcher.exe' : 'picoclaw-launcher',
      );
      if (await File(pLauncher).exists()) return pLauncher;
      final pth = p.join(dir, binaryName);
      if (await File(pth).exists()) return pth;
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
}
