import 'dart:async';
import 'package:flutter/services.dart';

import 'core_service_adapter.dart';

class AndroidCoreServiceAdapter implements CoreServiceAdapter {
  static const MethodChannel _channel = MethodChannel(
    'com.sipeed.picoclaw/picoclaw',
  );
  String? _lastErrorCode;
  // Stored log handler (not used on Android native adapter, but kept for API compatibility)
  // ignore: unused_field
  void Function(String)? _logHandler;

  @override
  Future<bool> startService({int? port, String? args}) async {
    try {
      final Map<String, Object?> params = {
        'port': port ?? 18800,
        'args': args ?? '',
      };
      final result = await _channel.invokeMethod<bool>('startService', params);
      return result ?? false;
    } catch (_) {
      _lastErrorCode = 'core.start_failed';
      return false;
    }
  }

  @override
  Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } catch (_) {
      _lastErrorCode = 'core.stop_failed';
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getServiceStatus() async {
    final res = await _channel.invokeMethod<dynamic>('getServiceStatus');
    return Map<String, dynamic>.from(res as Map);
  }

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    final res = await _channel.invokeMethod<dynamic>('checkHealth');
    return Map<String, dynamic>.from(res as Map);
  }

  @override
  Future<bool> setAutoStart(bool enabled) async {
    try {
      final r = await _channel.invokeMethod<bool>('setAutoStart', {
        'enabled': enabled,
      });
      return r ?? false;
    } catch (_) {
      _lastErrorCode = 'core.set_autostart_failed';
      return false;
    }
  }

  @override
  Future<bool> getAutoStart() async {
    try {
      final r = await _channel.invokeMethod<bool>('getAutoStart');
      return r ?? false;
    } catch (_) {
      _lastErrorCode = 'core.get_autostart_failed';
      return false;
    }
  }

  @override
  String? getLastErrorCode() => _lastErrorCode;

  @override
  void setLogHandler(void Function(String)? handler) {
    _logHandler = handler;
  }

  @override
  Future<bool> validateBinary([String? path]) async {
    // Android packages native service inside the app; assume valid.
    // If needed, native side can expose a validation method via MethodChannel.
    try {
      return true;
    } catch (e) {
      _lastErrorCode = 'core.binary_missing';
      return false;
    }
  }
}
