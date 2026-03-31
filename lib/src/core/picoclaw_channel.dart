import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// PicoClaw 原生 MethodChannel 客户端。
/// 仅在 Android 平台可用，用于与 Kotlin 原生服务层通信。
class PicoClawChannel {
  static const _channel = MethodChannel('com.sipeed.picoclaw/picoclaw');

  /// 启动 PicoClaw 前台服务
  static Future<bool> startService({int port = 18800, String args = ''}) async {
    final result = await _channel.invokeMethod<bool>('startService', {
      'port': port,
      'args': args,
    });
    return result ?? false;
  }

  /// 停止 PicoClaw 前台服务
  static Future<bool> stopService() async {
    final result = await _channel.invokeMethod<bool>('stopService');
    return result ?? false;
  }

  /// 获取服务状态
  static Future<Map<String, dynamic>> getServiceStatus() async {
    final result = await _channel.invokeMethod<Map>('getServiceStatus');
    if (result == null) return {'isRunning': false, 'pid': -1, 'lastLog': ''};
    return Map<String, dynamic>.from(result);
  }

  /// 检查 /health 端点
  static Future<Map<String, dynamic>> checkHealth() async {
    final result = await _channel.invokeMethod<Map>('checkHealth');
    if (result == null) {
      return {'isHealthy': false, 'error': 'No response'};
    }
    return Map<String, dynamic>.from(result);
  }

  /// 读取 config.json 内容
  static Future<String> getConfig() async {
    final result = await _channel.invokeMethod<String>('getConfig');
    return result ?? '';
  }

  /// 保存 config.json 内容
  static Future<bool> saveConfig(String content) async {
    final result = await _channel.invokeMethod<bool>('saveConfig', {
      'content': content,
    });
    return result ?? false;
  }

  /// 获取完整日志
  static Future<String> getFullLog() async {
    final result = await _channel.invokeMethod<String>('getFullLog');
    return result ?? '';
  }

  /// 设置开机自启
  static Future<bool> setAutoStart(bool enabled) async {
    final result = await _channel.invokeMethod<bool>('setAutoStart', {
      'enabled': enabled,
    });
    return result ?? false;
  }

  /// 获取开机自启设置
  static Future<bool> getAutoStart() async {
    final result = await _channel.invokeMethod<bool>('getAutoStart');
    return result ?? false;
  }

  /// 获取 config.json 文件路径
  static Future<String> getConfigPath() async {
    final result = await _channel.invokeMethod<String>('getConfigPath');
    return result ?? '';
  }

  /// 获取 Pico Channel token
  static Future<String> getPicoToken() async {
    final result = await _channel.invokeMethod<String>('getPicoToken');
    return result ?? '';
  }

  /// 获取安全的设备信息（避免敏感标识符）
  static Future<Map<String, String>> getSafeDeviceInfo() async {
    final result = await _channel.invokeMethod<Map>('getSafeDeviceInfo');
    if (result == null) return const {};
    return result.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static Future<bool> setUmengAnalyticsConsent(bool enabled) async {
    final result = await _channel.invokeMethod<bool>(
      'setUmengAnalyticsConsent',
      {'enabled': enabled},
    );
    return result ?? false;
  }

  static Future<Map<String, dynamic>> uploadUmengDeviceReport(
    Map<String, Object?> payload,
  ) async {
    debugPrint('[PicoClawChannel] === uploadUmengDeviceReport START ===');
    debugPrint(
      '[PicoClawChannel] Calling native method with payload keys: ${payload.keys.toList()}',
    );

    try {
      final result = await _channel
          .invokeMethod<Map>('uploadUmengDeviceReport', payload)
          .timeout(const Duration(seconds: 8));

      debugPrint('[PicoClawChannel] Native method returned');

      if (result == null) {
        debugPrint('[PicoClawChannel] ERROR: Native returned null');
        return const {
          'success': false,
          'message': 'No response from native Umeng bridge.',
        };
      }

      final mappedResult = Map<String, dynamic>.from(result);
      debugPrint(
        '[PicoClawChannel] Result: success=${mappedResult['success']}, message=${mappedResult['message']}',
      );
      debugPrint('[PicoClawChannel] === uploadUmengDeviceReport END ===');
      return mappedResult;
    } catch (e) {
      debugPrint('[PicoClawChannel] ERROR: Exception caught: $e');
      debugPrint('[PicoClawChannel] === uploadUmengDeviceReport FAILED ===');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }
}
