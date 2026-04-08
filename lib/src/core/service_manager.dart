import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'device_feedback_models.dart';
import 'firebase_device_reporter.dart';
import 'picoclaw_channel.dart';
import 'umeng_device_reporter.dart';
import '../native/core_service_adapter_factory.dart';
import '../native/core_service_adapter.dart';

enum ServiceStatus { stopped, running, starting }

class ServiceManager extends ChangeNotifier {
  static const List<Duration> _deviceFeedbackRetryDelays = [
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];
  static const String _rawAnalyticsProvider = String.fromEnvironment(
    'PICOCLAW_ANALYTICS_PROVIDER',
    defaultValue: 'firebase',
  );
  static final DeviceFeedbackProvider _deviceFeedbackProvider =
      DeviceFeedbackProvider.fromEnvironmentValue(_rawAnalyticsProvider);
  static const String _firebaseProjectId = String.fromEnvironment(
    'PICOCLAW_FIREBASE_PROJECT_ID',
    defaultValue: 'picoclaw-analytics',
  );
  static const String _firebaseApiKey = String.fromEnvironment(
    'PICOCLAW_FIREBASE_API_KEY',
  );
  static const String _firebaseAppId = String.fromEnvironment(
    'PICOCLAW_FIREBASE_APP_ID',
  );
  static const String _firebaseMessagingSenderId = String.fromEnvironment(
    'PICOCLAW_FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _firebaseStorageBucket = String.fromEnvironment(
    'PICOCLAW_FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );
  static const String _umengAppKey = String.fromEnvironment(
    'PICOCLAW_UMENG_APP_KEY',
  );
  static const String _umengChannel = String.fromEnvironment(
    'PICOCLAW_UMENG_CHANNEL',
    defaultValue: 'official',
  );

  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal() {
    if (!kIsWeb) {
      try {
        ProcessSignal.sigint.watch().listen((_) => stop());
      } catch (_) {}
      try {
        if (!Platform.isWindows) {
          ProcessSignal.sigterm.watch().listen((_) => stop());
        }
      } catch (_) {}
    }
  }

  final CoreServiceAdapter _adapter = CoreServiceAdapterFactory.create();
  final FirebaseDeviceReporter _firebaseReporter = FirebaseDeviceReporter();
  final UmengDeviceReporter _umengReporter = UmengDeviceReporter();
  String? _lastErrorCode;
  String? _lastDeviceFeedbackSyncMessage;
  Future<DeviceFeedbackUploadResult>? _deviceFeedbackUploadTask;
  Timer? _deviceFeedbackRetryTimer;
  int _deviceFeedbackRetryAttempt = 0;

  String? get lastErrorCode => _lastErrorCode ?? _adapter.getLastErrorCode();
  String? get lastDeviceFeedbackSyncMessage => _lastDeviceFeedbackSyncMessage;
  bool get isDeviceFeedbackUploadInProgress =>
      _deviceFeedbackUploadTask != null;

  ServiceStatus _status = ServiceStatus.stopped;
  final List<String> _logs = [];

  ServiceStatus get status => _status;
  List<String> get logs => List.unmodifiable(_logs);

  String _host = '127.0.0.1';
  int _port = 18800;
  String _binaryPath = '';
  String _arguments = '';
  bool _publicMode = false;
  String _workspacePath = '';

  int _nativePid = -1;
  String _healthStatus = '';
  String _healthUptime = '';
  bool _autoStart = false;

  int get nativePid => _nativePid;
  String get healthStatus => _healthStatus;
  String get healthUptime => _healthUptime;
  bool get autoStart => _autoStart;

  Timer? _nativePollingTimer;

  AppThemeMode _currentThemeMode = AppThemeMode.carbon;
  AppThemeMode get currentThemeMode => _currentThemeMode;
  DeviceFeedbackProvider get deviceFeedbackProvider => _deviceFeedbackProvider;
  bool get isDeviceFeedbackEnabled => switch (_deviceFeedbackProvider) {
    DeviceFeedbackProvider.none => false,
    DeviceFeedbackProvider.firebase => Platform.isAndroid || Platform.isIOS,
    DeviceFeedbackProvider.umeng => Platform.isAndroid,
  };

  String get webUrl => 'http://$_host:$_port';
  String get host => _host;
  int get port => _port;
  String get binaryPath => _binaryPath;
  String get arguments => _arguments;
  bool get publicMode => _publicMode;
  String get workspacePath => _workspacePath;

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

          anyIp ??= ip;

          if (name.contains('eth') ||
              name.startsWith('en') ||
              name.contains('ethernet') ||
              name.contains('ens') ||
              name.contains('enp')) {
            return ip;
          }
          if (wifiIp == null &&
              (name.contains('wlan') ||
                  name.contains('wifi') ||
                  name.contains('wl') ||
                  name.startsWith('wlp') ||
                  name.startsWith('wlo'))) {
            wifiIp = ip;
          }
        }
      }

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

    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _currentThemeMode = AppThemeMode.values[themeIndex];

    if (Platform.isAndroid) {
      _port = 18800;
      _host = '127.0.0.1';
      try {
        _autoStart = await PicoClawChannel.getAutoStart();
        _workspacePath = await _adapter.getWorkspacePath();
        await _syncNativeServiceStatus();
      } catch (_) {}
      _startNativePolling();
    }

    try {
      _adapter.setLogHandler(_addLog);
    } catch (_) {}

    if (_deviceFeedbackProvider == DeviceFeedbackProvider.umeng) {
      try {
        await _umengReporter.ensureDefaultConsentApplied();
      } catch (_) {}
    }

    // 自动上报设备反馈（如果用户已同意且满足条件）
    unawaited(_autoUploadDeviceFeedbackIfNeeded());

    notifyListeners();
  }

  Future<bool> setWorkspacePath(String value) async {
    final ok = await _adapter.setWorkspacePath(value);
    if (ok) {
      _workspacePath = value;
      notifyListeners();
    }
    return ok;
  }

  Future<void> _autoUploadDeviceFeedbackIfNeeded() async {
    try {
      final isAllowed = await isDeviceFeedbackAllowed();
      final shouldUpload = await shouldAutoUploadDeviceFeedbackReport();

      if (isAllowed && shouldUpload) {
        triggerDeviceFeedbackUploadInBackground();
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> _syncNativeServiceStatus() async {
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

  void _startNativePolling() {
    _nativePollingTimer?.cancel();
    _nativePollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _syncNativeServiceStatus(),
    );
  }

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

  Future<Map<String, String>> getDeviceFeedbackDeviceInfo() async {
    switch (_deviceFeedbackProvider) {
      case DeviceFeedbackProvider.firebase:
        return _firebaseReporter.collectSafeDeviceInfo();
      case DeviceFeedbackProvider.umeng:
        return _umengReporter.collectSafeDeviceInfo();
      case DeviceFeedbackProvider.none:
        return const {};
    }
  }

  Future<bool> isDeviceFeedbackAllowed() async {
    switch (_deviceFeedbackProvider) {
      case DeviceFeedbackProvider.firebase:
        return _firebaseReporter.isUploadAllowed();
      case DeviceFeedbackProvider.umeng:
        return _umengReporter.isUploadAllowed();
      case DeviceFeedbackProvider.none:
        return false;
    }
  }

  Future<bool> shouldAskForDeviceFeedbackUpload() async {
    return false;
  }

  Future<bool> shouldAutoUploadDeviceFeedbackReport() async {
    switch (_deviceFeedbackProvider) {
      case DeviceFeedbackProvider.firebase:
        return _firebaseReporter.shouldUpload();
      case DeviceFeedbackProvider.umeng:
        return _umengReporter.shouldUpload();
      case DeviceFeedbackProvider.none:
        return false;
    }
  }

  Future<void> setDeviceFeedbackUploadAllowed(bool allowed) async {
    if (!allowed) {
      _resetDeviceFeedbackRetryState();
    }
    switch (_deviceFeedbackProvider) {
      case DeviceFeedbackProvider.firebase:
        await _firebaseReporter.setUploadAllowed(allowed);
        return;
      case DeviceFeedbackProvider.umeng:
        await _umengReporter.setUploadAllowed(allowed);
        return;
      case DeviceFeedbackProvider.none:
        return;
    }
  }

  Future<DeviceFeedbackUploadResult> uploadDeviceFeedbackReport() async {
    final ongoingTask = _deviceFeedbackUploadTask;
    if (ongoingTask != null) {
      return ongoingTask;
    }

    _lastDeviceFeedbackSyncMessage = 'Syncing device feedback in background...';
    notifyListeners();

    final task = _uploadDeviceFeedbackReportInternal();
    _deviceFeedbackUploadTask = task;

    try {
      return await task;
    } finally {
      if (identical(_deviceFeedbackUploadTask, task)) {
        _deviceFeedbackUploadTask = null;
        notifyListeners();
      }
    }
  }

  void triggerDeviceFeedbackUploadInBackground() {
    if (!isDeviceFeedbackEnabled || isDeviceFeedbackUploadInProgress) {
      return;
    }
    _deviceFeedbackRetryTimer?.cancel();
    _deviceFeedbackRetryTimer = null;
    unawaited(uploadDeviceFeedbackReport());
  }

  Future<DeviceFeedbackUploadResult>
  _uploadDeviceFeedbackReportInternal() async {
    late final DeviceFeedbackUploadResult result;
    switch (_deviceFeedbackProvider) {
      case DeviceFeedbackProvider.firebase:
        if (_firebaseApiKey.trim().isEmpty) {
          result = const DeviceFeedbackUploadResult(
            success: false,
            message: 'Missing PICOCLAW_FIREBASE_API_KEY build configuration.',
          );
          break;
        }
        if (_firebaseAppId.trim().isEmpty) {
          result = const DeviceFeedbackUploadResult(
            success: false,
            message: 'Missing PICOCLAW_FIREBASE_APP_ID build configuration.',
          );
          break;
        }
        if (_firebaseMessagingSenderId.trim().isEmpty) {
          result = const DeviceFeedbackUploadResult(
            success: false,
            message:
                'Missing PICOCLAW_FIREBASE_MESSAGING_SENDER_ID build configuration.',
          );
          break;
        }
        result = await _firebaseReporter.uploadDeviceReport(
          appId: _firebaseAppId,
          projectId: _firebaseProjectId,
          apiKey: _firebaseApiKey,
          messagingSenderId: _firebaseMessagingSenderId,
          storageBucket: _firebaseStorageBucket.isEmpty
              ? null
              : _firebaseStorageBucket,
        );
        break;
      case DeviceFeedbackProvider.umeng:
        if (_umengAppKey.trim().isEmpty) {
          result = const DeviceFeedbackUploadResult(
            success: false,
            message: 'Missing PICOCLAW_UMENG_APP_KEY build configuration.',
          );
          break;
        }
        result = await _umengReporter.uploadDeviceReport(
          appKey: _umengAppKey,
          channel: _umengChannel,
        );
        break;
      case DeviceFeedbackProvider.none:
        result = const DeviceFeedbackUploadResult(
          success: false,
          message: 'Device feedback provider is disabled.',
        );
        break;
    }
    _lastDeviceFeedbackSyncMessage = result.message;
    if (result.success) {
      _resetDeviceFeedbackRetryState(notify: false);
    } else {
      await _scheduleDeviceFeedbackRetryIfNeeded(result);
    }
    _addLog(
      result.success
          ? 'Device feedback sync succeeded.'
          : 'Device feedback sync failed: ${result.message}',
    );
    if (!result.success) {
      debugPrint('Device feedback sync failed: ${result.message}');
    }
    return result;
  }

  Future<void> _scheduleDeviceFeedbackRetryIfNeeded(
    DeviceFeedbackUploadResult result,
  ) async {
    if (!_shouldRetryDeviceFeedback(result.message)) {
      _resetDeviceFeedbackRetryState(notify: false);
      return;
    }
    if (!await isDeviceFeedbackAllowed()) {
      _resetDeviceFeedbackRetryState(notify: false);
      return;
    }
    if (_deviceFeedbackRetryAttempt >= _deviceFeedbackRetryDelays.length) {
      _lastDeviceFeedbackSyncMessage =
          '${result.message} Auto retry stopped for now.';
      return;
    }

    final delay = _deviceFeedbackRetryDelays[_deviceFeedbackRetryAttempt];
    _deviceFeedbackRetryAttempt += 1;
    _deviceFeedbackRetryTimer?.cancel();
    _lastDeviceFeedbackSyncMessage =
        '${result.message} Retrying silently in ${delay.inSeconds}s.';
    _deviceFeedbackRetryTimer = Timer(delay, () {
      _deviceFeedbackRetryTimer = null;
      if (!isDeviceFeedbackEnabled || isDeviceFeedbackUploadInProgress) {
        return;
      }
      unawaited(uploadDeviceFeedbackReport());
    });
  }

  bool _shouldRetryDeviceFeedback(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('missing picoclaw_') ||
        normalized.contains('provider is disabled') ||
        normalized.contains('projectid is empty') ||
        normalized.contains('apikey is empty') ||
        normalized.contains('appid is empty') ||
        normalized.contains('messagingsenderid is empty') ||
        normalized.contains('appkey is empty') ||
        normalized.contains('not supported on this platform') ||
        normalized.contains('only supported on android')) {
      return false;
    }
    return true;
  }

  void _resetDeviceFeedbackRetryState({bool notify = true}) {
    _deviceFeedbackRetryTimer?.cancel();
    _deviceFeedbackRetryTimer = null;
    _deviceFeedbackRetryAttempt = 0;
    if (notify) {
      notifyListeners();
    }
  }

  Future<Map<String, String>> getFirebaseDeviceInfo() {
    return getDeviceFeedbackDeviceInfo();
  }

  Future<bool> isFirebaseUploadAllowed() {
    return isDeviceFeedbackAllowed();
  }

  Future<bool> shouldAskForFirebaseUpload() {
    return shouldAskForDeviceFeedbackUpload();
  }

  Future<bool> shouldAutoUploadFirebaseDeviceReport() {
    return shouldAutoUploadDeviceFeedbackReport();
  }

  Future<void> setFirebaseUploadAllowed(bool allowed) {
    return setDeviceFeedbackUploadAllowed(allowed);
  }

  Future<DeviceFeedbackUploadResult> uploadFirebaseDeviceReport() {
    return uploadDeviceFeedbackReport();
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

    final lines = log.split(RegExp(r'[\r\n]+')).where((l) => l.isNotEmpty);
    _pendingLogs.addAll(lines.map((l) => l.trim()));

    if (_notifyTimer == null || !_notifyTimer!.isActive) {
      _notifyTimer = Timer(const Duration(milliseconds: 100), () {
        if (_pendingLogs.isNotEmpty) {
          _logs.addAll(_pendingLogs);
          _pendingLogs.clear();

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
            _syncNativeServiceStatus();
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
    try {
      await _adapter.stopService();
      _status = ServiceStatus.stopped;
      _addLog('Stopping PicoClaw native service...');
      notifyListeners();
    } catch (e) {
      _addLog('Failed to stop native service: $e');
    }
  }

  @override
  void dispose() {
    _nativePollingTimer?.cancel();
    super.dispose();
  }
}
