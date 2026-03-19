import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum ServiceStatus { stopped, running, starting }

class ServiceManager extends ChangeNotifier {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal() {
    // Process monitoring
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      ProcessSignal.sigint.watch().listen((_) => stop());
      ProcessSignal.sigterm.watch().listen((_) => stop());
    }
  }

  Process? _process;
  ServiceStatus _status = ServiceStatus.stopped;
  final List<String> _logs = [];

  ServiceStatus get status => _status;
  List<String> get logs => List.unmodifiable(_logs);

  String _host = '127.0.0.1';
  int _port = 18800;
  String _binaryPath = '';
  String _arguments = '';

  // Theme state
  AppThemeMode _currentThemeMode = AppThemeMode.carbon;
  AppThemeMode get currentThemeMode => _currentThemeMode;

  String get webUrl => 'http://$_host:$_port';
  String get binaryPath => _binaryPath;
  String get arguments => _arguments;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('host') ?? '127.0.0.1';
    _port = prefs.getInt('port') ?? 18800;
    _binaryPath = prefs.getString('binaryPath') ?? '';
    _arguments = prefs.getString('arguments') ?? '';

    // Load theme
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _currentThemeMode = AppThemeMode.values[themeIndex];

    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _currentThemeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> updateConfig(
    String host,
    int port, {
    String? binaryPath,
    String? arguments,
  }) async {
    _host = host;
    _port = port;
    if (binaryPath != null) _binaryPath = binaryPath;
    if (arguments != null) _arguments = arguments;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', host);
    await prefs.setInt('port', port);
    if (binaryPath != null) await prefs.setString('binaryPath', binaryPath);
    if (arguments != null) await prefs.setString('arguments', arguments);
    notifyListeners();
  }

  Timer? _notifyTimer;
  final List<String> _pendingLogs = [];

  void _addLog(String log) {
    if (log.isEmpty) return;

    // Split combined logs to prevent UI stutter from single large text blocks
    final lines = log.split(RegExp(r'[\r\n]+')).where((l) => l.isNotEmpty);
    _pendingLogs.addAll(lines.map((l) => l.trim()));

    // Throttled notification: notify at most every 100ms
    if (_notifyTimer == null || !_notifyTimer!.isActive) {
      _notifyTimer = Timer(const Duration(milliseconds: 100), () {
        if (_pendingLogs.isNotEmpty) {
          _logs.addAll(_pendingLogs);
          _pendingLogs.clear();

          // Keep memory footprint low
          if (_logs.length > 500) {
            _logs.removeRange(0, _logs.length - 500);
          }
          notifyListeners();
        }
      });
    }
  }

  Future<void> start() async {
    if (_status != ServiceStatus.stopped) return;

    _status = ServiceStatus.starting;
    notifyListeners();

    try {
      // 1. Cleanup existing process/port conflicts
      if (Platform.isWindows) {
        // Find and kill process by port on Windows
        try {
          final result = await Process.run('cmd', [
            '/c',
            'netstat -ano | findstr :$_port',
          ]);
          if (result.stdout.toString().isNotEmpty) {
            final lines = result.stdout.toString().split('\n');
            for (var line in lines) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 5) {
                final pid = parts.last;
                await Process.run('taskkill', ['/F', '/PID', pid]);
                _addLog(
                  'Cleaned up existing process on port $_port (PID: $pid)',
                );
              }
            }
          }
        } catch (_) {}
      } else if (Platform.isAndroid || Platform.isLinux) {
        // On Android/Linux, we can't easily kill by port without root/shell.
        // However, we can try to kill by name if possible, or just re-try.
        // For Android, we primarily rely on the foreground service keeping our lifecycle synced.
        await stop();
      }

      // 2. Resolve binary path
      String exePath = _binaryPath;
      if (exePath.isEmpty) {
        exePath = 'picoclaw';
        if (Platform.isWindows) exePath += '.exe';
      }

      final List<String> args = ['-port', _port.toString()];
      if (_host == '0.0.0.0') {
        args.add('-public');
      }

      if (_arguments.isNotEmpty) {
        args.addAll(_arguments.split(' ').where((s) => s.isNotEmpty));
      }

      _process = await Process.start(exePath, args);

      _status = ServiceStatus.running;
      _addLog('Service started on $webUrl');

      // Use LineSplitter to efficiently handle line breaks and avoid UI blocking
      // with large output blocks.
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            _addLog(line);
          });

      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            _addLog('ERROR: $line');
          });

      _process!.exitCode.then((exitCode) {
        _status = ServiceStatus.stopped;
        _addLog('Service stopped with exit code $exitCode');
        _process = null;
        notifyListeners();
      });
    } catch (e) {
      _status = ServiceStatus.stopped;
      _addLog('Failed to start service: $e');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      _status = ServiceStatus.stopped;
      notifyListeners();
    }
  }
}
