import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'device_feedback_models.dart';
import 'picoclaw_channel.dart';

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
    // 默认允许上传，用户仍可在设置中手动关闭。
    return prefs.getBool(_prefsUploadAllowedKey) ?? true;
  }

  Future<bool> hasUploadConsentChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefsUploadAllowedKey);
  }

  Future<void> ensureDefaultConsentApplied() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_prefsUploadAllowedKey)) {
      return;
    }

    await prefs.setBool(_prefsUploadAllowedKey, true);
    if (Platform.isAndroid) {
      await PicoClawChannel.setUmengAnalyticsConsent(true);
    }
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

  Future<DeviceFeedbackUploadResult> uploadDeviceReport({
    required String appKey,
    String channel = _defaultChannel,
  }) async {
    debugPrint('[Umeng] === uploadDeviceReport START ===');

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

    try {
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

      debugPrint('[Umeng] Step 5: Processing result - success=$success');

      if (success) {
        debugPrint('[Umeng] Step 6: Marking as uploaded...');
        await markUploaded();
        debugPrint('[Umeng] === uploadDeviceReport SUCCESS ===');
      } else {
        debugPrint('[Umeng] === uploadDeviceReport FAILED: $message ===');
      }

      return DeviceFeedbackUploadResult(
        success: success,
        message: message,
        uploadedAt: success ? now : null,
        deviceInfo: info,
      );
    } on TimeoutException catch (e) {
      debugPrint('[Umeng] ERROR: TimeoutException - $e');
      return DeviceFeedbackUploadResult(
        success: false,
        message: 'Upload timed out.',
        deviceInfo: info,
      );
    } catch (e) {
      debugPrint('[Umeng] ERROR: Exception - $e');
      return DeviceFeedbackUploadResult(
        success: false,
        message: 'Upload failed: $e',
        deviceInfo: info,
      );
    }
  }
}
