import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'picoclaw_channel.dart';
import '../native/core_service_adapter_factory.dart';
import '../native/core_service_adapter.dart';

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

  final CoreServiceAdapter _adapter = CoreServiceAdapterFactory.create();
  String? _lastErrorCode;

  String? get lastErrorCode => _lastErrorCode ?? _adapter.getLastErrorCode();

  ServiceStatus _status = ServiceStatus.stopped;
  final List<String> _logs = [];

  ServiceStatus get status => _status;
  List<String> get logs => List.unmodifiable(_logs);

  String _host = '127.0.0.1';
  int _port = 18800;
  String _binaryPath = '';
  String _arguments = '';
  bool _publicMode = false;

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
  String get host => _host;
  int get port => _port;
  String get binaryPath => _binaryPath;
  String get arguments => _arguments;
  bool get publicMode => _publicMode;

  /// 获取本机可公开的网络IP，以太网优先，其次WiFi
  Future<String?> getDeviceIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? wifiIp;
      String? anyIp;
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('loopback') || name.contains('lo')) continue;

        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip.isEmpty || ip == '127.0.0.1' || ip.startsWith('169.254.')) {
            continue;
          }

          // 保存任何有效的IP作为备选
          anyIp ??= ip;

          // 以太网优先 (支持更多命名方式)
          if (name.contains('eth') ||
              name.startsWith('en') ||
              name.contains('ethernet') ||
              name.contains('ens') || // Linux systemd 命名
              name.contains('enp')) {
            // Linux PCI 命名
            return ip;
          }
          // WiFi次之 (支持更多命名方式)
          if (wifiIp == null &&
              (name.contains('wlan') ||
                  name.contains('wifi') ||
                  name.contains('wl') ||
                  name.startsWith('wlp') || // Linux PCI WiFi
                  name.startsWith('wlo'))) {
            // Linux onboard WiFi
            wifiIp = ip;
          }
        }
      }

      // 如果没有找到以太网或WiFi，返回任何可用的IP
      return wifiIp ?? anyIp;
    } catch (e) {
      debugPrint('Failed to get device IP: $e');
      return null;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('host') ?? '127.0.0.1';
    _port = prefs.getInt('port') ?? 18800;
    _binaryPath = prefs.getString('binaryPath') ?? '';
    _arguments = prefs.getString('arguments') ?? '';
    _publicMode = prefs.getBool('publicMode') ?? false;

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

    // Register log handler so adapters can forward runtime logs to us
    try {
      _adapter.setLogHandler(_addLog);
    } catch (_) {}

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
    bool? publicMode,
  }) async {
    _host = host;
    _port = port;
    // On Windows and Android prefer the built-in `app/bin` layout and do not
    // accept a custom binary path from callers.
    if (!(Platform.isWindows || Platform.isAndroid)) {
      if (binaryPath != null) _binaryPath = binaryPath;
    }
    if (arguments != null) _arguments = arguments;
    if (publicMode != null) _publicMode = publicMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', host);
    await prefs.setInt('port', port);
    if (!(Platform.isWindows || Platform.isAndroid)) {
      if (binaryPath != null) await prefs.setString('binaryPath', binaryPath);
    }
    if (arguments != null) await prefs.setString('arguments', arguments);
    await prefs.setBool('publicMode', _publicMode);
    notifyListeners();
  }

  /// Validate the configured or provided binary path via adapter.
  Future<bool> validateBinary([String? path]) async {
    String? checkPath;
    if (path != null && path.isNotEmpty) {
      checkPath = path;
    } else if (_binaryPath.isNotEmpty) {
      checkPath = _binaryPath;
    }

    final ok = await _adapter.validateBinary(checkPath);
    _lastErrorCode = _adapter.getLastErrorCode();
    notifyListeners();
    return ok;
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

          // Keep memory footprint low (max 500 log entries)
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

    // 构建启动参数
    // 公共模式开启时：添加 -public，服务监听所有接口
    // 公共模式关闭时：不传 -public，服务仅监听本地接口（默认行为）
    String launchArgs = _arguments;
    // Use simple token logic (split by spaces and dedupe) instead of regex.
    // _arguments is initialized to '' and loaded with `?? ''` in init(), so it's non-null.
    final tokens = launchArgs.split(' ').where((t) => t.isNotEmpty).toList();

    if (_publicMode && !tokens.contains('-public')) {
      tokens.add('-public');
    }
    if (!tokens.contains('-no-browser')) {
      tokens.add('-no-browser');
    }

    launchArgs = tokens.join(' ');
    try {
      final ok = await _adapter.startService(port: _port, args: launchArgs);

      if (ok) {
        if (Platform.isAndroid) {
          // Android: keep original behavior — log and defer health check to native side
          _addLog('Starting PicoClaw native service...');
          Future.delayed(const Duration(seconds: 2), () {
            _syncAndroidServiceStatus();
          });
        } else {
          // Desktop: consider service running immediately
          _status = ServiceStatus.running;
          _addLog('Service started on $webUrl');
        }
      } else {
        _status = ServiceStatus.stopped;
        final code = _adapter.getLastErrorCode();
        _addLog('Failed to start service: ${code ?? 'unknown'}');
      }
      notifyListeners();
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
        await _adapter.stopService();
        _status = ServiceStatus.stopped;
        _addLog('Stopping PicoClaw native service...');
        notifyListeners();
      } catch (e) {
        _addLog('Failed to stop native service: $e');
      }
      return;
    }

    // Desktop
    try {
      await _adapter.stopService();
      _status = ServiceStatus.stopped;
      notifyListeners();
    } catch (e) {
      _addLog('Failed to stop service: $e');
    }
  }

  @override
  void dispose() {
    _androidPollingTimer?.cancel();
    super.dispose();
  }
}
