import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'device_feedback_models.dart';
import 'picoclaw_channel.dart';

/// 错误类型枚举
enum UmengErrorType {
  configError,
  notInitialized,
  networkError,
  sdkError,
  timeout,
  unknown,
}

class UmengDeviceReporter {
  static const _prefsInstallIdKey = 'umeng_install_id';
  static const _prefsLastSystemVersionKey = 'umeng_last_system_version';
  static const _prefsUploadAllowedKey = 'umeng_upload_allowed';
  static const _defaultChannel = 'official';

  final Uuid _uuid = const Uuid();

  Future<Map<String, String>> collectSafeDeviceInfo() async {
    if (Platform.isAndroid) {
      try {
        final info = await PicoClawChannel.getSafeDeviceInfo();
        return {
          'platform': info['platform'] ?? 'android',
          'deviceModel': info['deviceModel'] ?? 'unknown',
          'systemVersion': info['osVersion'] ?? 'unknown',
        };
      } catch (e) {
        debugPrint('Failed to read Android device info: $e');
      }
    }

    return {
      'platform': Platform.operatingSystem,
      'deviceModel': Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 'desktop'
          : 'unknown',
      'systemVersion': Platform.operatingSystemVersion,
    };
  }

  Future<String> getOrCreateInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsInstallIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _uuid.v4();
    await prefs.setString(_prefsInstallIdKey, generated);
    return generated;
  }

  Future<bool> isUploadAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    // 默认不允许上传，直到用户明确同意（用于隐私合规）
    return prefs.getBool(_prefsUploadAllowedKey) ?? false;
  }

  Future<bool> hasUploadConsentChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefsUploadAllowedKey);
  }

  Future<void> setUploadAllowed(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsUploadAllowedKey, allowed);
    if (Platform.isAndroid) {
      await PicoClawChannel.setUmengAnalyticsConsent(allowed);
    }
  }

  Future<bool> shouldUpload() async {
    if (!await isUploadAllowed()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentInfo = await collectSafeDeviceInfo();
    final currentVersion = currentInfo['systemVersion'] ?? 'unknown';
    final lastVersion = prefs.getString(_prefsLastSystemVersionKey);

    return lastVersion == null || lastVersion != currentVersion;
  }

  Future<void> markUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    final currentInfo = await collectSafeDeviceInfo();
    await prefs.setString(
      _prefsLastSystemVersionKey,
      currentInfo['systemVersion'] ?? 'unknown',
    );
  }

  /// 解析错误类型
  UmengErrorType _parseErrorType(String? errorType) {
    switch (errorType) {
      case 'CONFIG_ERROR':
        return UmengErrorType.configError;
      case 'NOT_INITIALIZED':
        return UmengErrorType.notInitialized;
      case 'NETWORK_ERROR':
        return UmengErrorType.networkError;
      case 'SDK_ERROR':
        return UmengErrorType.sdkError;
      case 'TIMEOUT':
        return UmengErrorType.timeout;
      default:
        return UmengErrorType.unknown;
    }
  }

  /// 检查错误是否可重试
  bool _isRetryableError(UmengErrorType errorType) {
    switch (errorType) {
      case UmengErrorType.networkError:
      case UmengErrorType.timeout:
        return true;
      case UmengErrorType.configError:
      case UmengErrorType.notInitialized:
      case UmengErrorType.sdkError:
      case UmengErrorType.unknown:
        return false;
    }
  }

  /// 执行单次上报请求
  Future<DeviceFeedbackUploadResult> _doUploadRequest({
    required String installId,
    required Map<String, String> info,
    required String channel,
    required String now,
  }) async {
    debugPrint('[Umeng] Step 4: Calling native channel...');
    final result = await PicoClawChannel.uploadUmengDeviceReport({
      'installId': installId,
      'platform': info['platform'] ?? 'unknown',
      'deviceModel': info['deviceModel'] ?? 'unknown',
      'systemVersion': info['systemVersion'] ?? 'unknown',
      'clientType': 'picoclaw_flutter_ui',
      'updatedAt': now,
      'channel': channel.trim().isEmpty ? _defaultChannel : channel.trim(),
    });

    final success = result['success'] == true;
    final message = result['message']?.toString() ?? 'Unknown Umeng error.';
    final errorTypeStr = result['errorType']?.toString();
    final errorType = _parseErrorType(errorTypeStr);

    if (success) {
      debugPrint('[Umeng] Step 5: Processing result - success=true');
    } else {
      debugPrint(
        '[Umeng] Step 5: Processing result - success=false, errorType=$errorType',
      );
    }

    return DeviceFeedbackUploadResult(
      success: success,
      message: message,
      uploadedAt: success ? now : null,
      deviceInfo: info,
    );
  }

  Future<DeviceFeedbackUploadResult> uploadDeviceReport({
    required String appKey,
    String channel = _defaultChannel,
  }) async {
    return await _uploadDeviceReport(
      appKey: appKey,
      channel: channel,
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
    );
  }

  Future<DeviceFeedbackUploadResult> _uploadDeviceReport({
    required String appKey,
    required String channel,
    required int maxRetries,
    required Duration retryDelay,
  }) async {
    debugPrint(
      '[Umeng] === uploadDeviceReport START (maxRetries=$maxRetries) ===',
    );

    // 1. 基础检查
    if (!Platform.isAndroid) {
      debugPrint(
        '[Umeng] ERROR: Umeng device reporting is only supported on Android',
      );
      return const DeviceFeedbackUploadResult(
        success: false,
        message: 'Umeng device reporting is only supported on Android.',
      );
    }
    if (appKey.trim().isEmpty) {
      debugPrint('[Umeng] ERROR: appKey is empty');
      return const DeviceFeedbackUploadResult(
        success: false,
        message: 'Umeng appKey is empty.',
      );
    }
    debugPrint('[Umeng] Platform: Android, appKey configured');

    // 2. 准备数据
    debugPrint('[Umeng] Step 1: Getting install ID...');
    final installId = await getOrCreateInstallId();
    debugPrint('[Umeng] Install ID: $installId');

    debugPrint('[Umeng] Step 2: Collecting device info...');
    final info = await collectSafeDeviceInfo();
    debugPrint(
      '[Umeng] Device info: platform=${info['platform']}, model=${info['deviceModel']}',
    );

    final now = DateTime.now().toUtc().toIso8601String();
    debugPrint('[Umeng] Step 3: Preparing payload...');

    // 3. 重试逻辑
    int attempt = 0;
    DeviceFeedbackUploadResult? lastResult;

    while (attempt < maxRetries) {
      attempt++;
      debugPrint('[Umeng] Attempt $attempt/$maxRetries...');

      try {
        lastResult = await _doUploadRequest(
          installId: installId,
          info: info,
          channel: channel,
          now: now,
        );

        if (lastResult.success) {
          debugPrint('[Umeng] Step 6: Marking as uploaded...');
          await markUploaded();
          debugPrint('[Umeng] === uploadDeviceReport SUCCESS ===');
          return lastResult;
        }

        // 检查是否可重试
        final errorType = _parseErrorType(lastResult.message);
        if (!_isRetryableError(errorType) || attempt >= maxRetries) {
          debugPrint(
            '[Umeng] Non-retryable error or max retries reached: ${lastResult.message}',
          );
          break;
        }

        debugPrint('[Umeng] Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      } on TimeoutException catch (e) {
        debugPrint('[Umeng] ERROR: TimeoutException - $e');
        lastResult = DeviceFeedbackUploadResult(
          success: false,
          message: 'Upload timed out.',
          deviceInfo: info,
        );

        if (attempt >= maxRetries) break;
        await Future.delayed(retryDelay);
      } catch (e, stackTrace) {
        debugPrint('[Umeng] ERROR: Exception - $e');
        lastResult = DeviceFeedbackUploadResult(
          success: false,
          message: 'Upload failed: $e',
          deviceInfo: info,
        );
        break; // 未知错误不重试
      }
    }

    debugPrint(
      '[Umeng] === uploadDeviceReport FAILED: ${lastResult?.message} ===',
    );
    return lastResult ??
        DeviceFeedbackUploadResult(
          success: false,
          message: 'Unknown error',
          deviceInfo: info,
        );
  }
}
