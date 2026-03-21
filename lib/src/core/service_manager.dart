import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'picoclaw_channel.dart';

enum ServiceStatus { stopped, running, starting }

class ServiceManager extends ChangeNotifier {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal() {
    // Process monitoring: register signal handlers where supported.
    if (!kIsWeb) {
      try {
        ProcessSignal.sigint.watch().listen((_) => stop());
      } catch (_) {}

      // SIGTERM is not supported on Windows; guard with try/catch as well.
      try {
        if (!Platform.isWindows) {
          ProcessSignal.sigterm.watch().listen((_) => stop());
        }
      } catch (_) {}
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

  // Android 原生服务状态
  int _nativePid = -1;
  String _healthStatus = '';
  String _healthUptime = '';
  bool _autoStart = false;

  int get nativePid => _nativePid;
  String get healthStatus => _healthStatus;
  String get healthUptime => _healthUptime;
  bool get autoStart => _autoStart;

  // Android 状态轮询定时器
  Timer? _androidPollingTimer;

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

    // Android: 初始化时同步原生服务状态
    if (Platform.isAndroid) {
      _port = 18800; // Android 使用 Web Console 端口
      _host = '127.0.0.1';
      try {
        _autoStart = await PicoClawChannel.getAutoStart();
        await _syncAndroidServiceStatus();
      } catch (_) {}
      _startAndroidPolling();
    }

    notifyListeners();
  }

  /// Android: 同步原生服务状态
  Future<void> _syncAndroidServiceStatus() async {
    try {
      final status = await PicoClawChannel.getServiceStatus();
      final isRunning = status['isRunning'] as bool? ?? false;
      final lastLog = status['lastLog'] as String? ?? '';
      _nativePid = status['pid'] as int? ?? -1;

      final oldStatus = _status;
      _status = isRunning ? ServiceStatus.running : ServiceStatus.stopped;

      if (lastLog.isNotEmpty) {
        _addLog(lastLog);
      }

      // 如果服务正在运行，检查健康状态
      if (isRunning) {
        try {
          final health = await PicoClawChannel.checkHealth();
          final isHealthy = health['isHealthy'] as bool? ?? false;
          _healthStatus = isHealthy ? 'Healthy' : 'Starting...';
          _healthUptime = health['uptime'] as String? ?? '';
          if (health['pid'] != null && (health['pid'] as int) > 0) {
            _nativePid = health['pid'] as int;
          }
        } catch (_) {
          _healthStatus = 'Starting...';
        }
      } else {
        _healthStatus = '';
        _healthUptime = '';
      }

      if (oldStatus != _status) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to sync Android service status: $e');
    }
  }

  /// Android: 启动状态轮询
  void _startAndroidPolling() {
    _androidPollingTimer?.cancel();
    _androidPollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _syncAndroidServiceStatus(),
    );
  }

  /// Android: 设置开机自启
  Future<void> setAutoStart(bool enabled) async {
    if (Platform.isAndroid) {
      await PicoClawChannel.setAutoStart(enabled);
      _autoStart = enabled;
      notifyListeners();
    }
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

    // Android: 通过 MethodChannel 启动原生前台服务
    if (Platform.isAndroid) {
      try {
        await PicoClawChannel.startService();
        _addLog('Starting PicoClaw native service...');
        // 延迟同步状态，等待服务启动
        Future.delayed(const Duration(seconds: 2), () {
          _syncAndroidServiceStatus();
        });
      } catch (e) {
        _status = ServiceStatus.stopped;
        _addLog('Failed to start native service: $e');
        notifyListeners();
      }
      return;
    }

    // 桌面平台：保持原有的 Process.start 逻辑
    try {
      // 1. Cleanup existing process/port conflicts
      if (Platform.isWindows) {
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
      } else if (Platform.isLinux) {
        await stop();
      }

      // 2. Resolve binary path
      String exePath = _binaryPath;
      if (exePath.isEmpty) {
        if (Platform.isMacOS) {
          final appExecutable = File(Platform.resolvedExecutable);
          final bundledBinary =
              '${appExecutable.parent.path}${Platform.pathSeparator}picoclaw';
          if (File(bundledBinary).existsSync()) {
            exePath = bundledBinary;
          } else {
            exePath = 'picoclaw';
          }
        } else {
          exePath = 'picoclaw';
          if (Platform.isWindows) exePath += '.exe';
        }
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
    // Android: 通过 MethodChannel 停止原生服务
    if (Platform.isAndroid) {
      try {
        await PicoClawChannel.stopService();
        _status = ServiceStatus.stopped;
        _addLog('Stopping PicoClaw native service...');
        notifyListeners();
      } catch (e) {
        _addLog('Failed to stop native service: $e');
      }
      return;
    }

    // 桌面平台
    if (_process != null) {
      _process!.kill();
      _status = ServiceStatus.stopped;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _androidPollingTimer?.cancel();
    super.dispose();
  }
}
