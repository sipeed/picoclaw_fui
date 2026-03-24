import 'package:flutter/services.dart';

/// PicoClaw 原生 MethodChannel 客户端。
/// 仅在 Android 平台可用，用于与 Kotlin 原生服务层通信。
class PicoClawChannel {
  static const _channel = MethodChannel('io.picoclaw.client/picoclaw');

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
}
